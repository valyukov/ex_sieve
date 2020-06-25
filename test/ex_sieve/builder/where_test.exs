defmodule ExSieve.Builder.WhereTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExSieve.{Config, Post, User}
  alias ExSieve.Builder.Where
  alias ExSieve.Node.Grouping

  def where_build(queryable, grouping, config \\ %Config{ignore_errors: true}, inspect? \\ true) do
    case {inspect?, Where.build(queryable, grouping, config)} do
      {true, {:ok, query}} -> inspect(query)
      {_, {:ok, query}} -> query
      {_, err} -> err
    end
  end

  defp ex_sieve_post_query(params, nested, ignore_errors \\ true, inspect? \\ true)

  defp ex_sieve_post_query(params, _nested = false, ignore_errors, inspect?) do
    case Grouping.extract(params, Post, %Config{ignore_errors: ignore_errors}) do
      {:error, _} = err -> {nil, err}
      grouping -> {Post, where_build(Post, grouping, %Config{ignore_errors: ignore_errors}, inspect?)}
    end
  end

  defp ex_sieve_post_query(params, _nested = true, ignore_errors, inspect?) do
    params = Map.new(params, fn {key, value} -> {"posts_#{key}", value} end)

    case Grouping.extract(params, User, %Config{ignore_errors: ignore_errors}) do
      {:error, _} = err ->
        {nil, err}

      grouping ->
        base = from(u in User, join: p in assoc(u, :posts), as: :posts)
        {base, where_build(base, grouping, %Config{ignore_errors: ignore_errors}, inspect?)}
    end
  end

  describe "ExSieve.Builder.Where.build/3" do
    test "return Ecto.Query for where comments" do
      params = %{"m" => "or", "comments_body_eq" => "test", "id_eq" => 1}
      grouping = Grouping.extract(params, Post, %Config{ignore_errors: true})

      base = from(from(p in Post, join: c in assoc(p, :comments), as: :comments))
      ecto = base |> where([p, c], field(c, :body) == ^"test" or field(p, :id) == ^1) |> inspect()

      assert ecto == where_build(base, grouping)
    end

    test "return Ecto.Query for advanced grouping" do
      params = %{
        "m" => "and",
        "c" => %{"comments_body_eq" => "test"},
        "g" => [
          %{
            "m" => "and",
            "comments_user_id_in" => 1,
            "user_name_cont_any" => ["1", "2"]
          }
        ]
      }

      grouping = params |> Grouping.extract(Post, %Config{ignore_errors: true})

      common =
        from(from(p in Post, join: c in assoc(p, :comments), as: :comments, join: u in assoc(p, :user), as: :user))

      ecto =
        common
        |> where(
          [p, c, u],
          c.body == ^"test" and (c.user_id in ^[1] and (ilike(u.name, ^"%1%") or ilike(u.name, ^"%2%")))
        )
        |> inspect

      assert ecto == where_build(common, grouping)
    end

    test "return Ecto.Query with cast datetime" do
      datetime = NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()
      params = %{"inserted_at_gteq" => datetime}

      grouping = Grouping.extract(params, Post, %Config{ignore_errors: true})

      ecto = Post |> where([p], field(p, :inserted_at) >= ^datetime) |> inspect()

      assert ecto == where_build(Post, grouping)
    end

    test "return Ecto.Query for nested relations" do
      params = %{"m" => "or", "posts_comments_body_eq" => "test", "id_eq" => 1}
      grouping = Grouping.extract(params, User, %Config{ignore_errors: true})

      base =
        User
        |> join(:inner, [u], p in assoc(u, :posts), as: :posts)
        |> join(:inner, [posts: p], c in assoc(p, :comments), as: :posts_comments)

      ecto =
        base
        |> where([u, posts_comments: c], field(u, :id) == ^1 or field(c, :body) == ^"test")
        |> inspect()

      assert ecto == where_build(base, grouping)
    end

    test "discard params with invalid type" do
      params = %{"published_start" => "foo", "title_cont" => "bar"}
      grouping = Grouping.extract(params, Post, %Config{ignore_errors: true})

      ecto = Post |> where([p], true and ilike(field(p, :title), ^"%bar%")) |> inspect()

      assert ecto == where_build(Post, grouping)
    end

    test "discard params with invalid value" do
      params = %{"published_true" => "foo", "title_cont" => "bar"}
      grouping = Grouping.extract(params, Post, %Config{ignore_errors: true})

      ecto = Post |> where([p], true and ilike(field(p, :title), ^"%bar%")) |> inspect()

      assert ecto == where_build(Post, grouping)
    end
  end

  describe "basic predicates" do
    test ":eq" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_eq" => 1}, false)
      query = base |> where([p], field(p, :id) == ^1) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_eq" => 1}, true)
      query = base |> where([posts: p], field(p, :id) == ^1) |> inspect()
      assert query == ex_sieve
    end

    test ":not_eq" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_not_eq" => 1}, false)
      query = base |> where([p], field(p, :id) != ^1) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_not_eq" => 1}, true)
      query = base |> where([posts: p], field(p, :id) != ^1) |> inspect()
      assert query == ex_sieve
    end

    test ":cont" do
      {base, ex_sieve} = ex_sieve_post_query(%{"body_cont" => "f%o_o"}, false)
      query = base |> where([p], ilike(field(p, :body), ^"%f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"body_cont" => "f%o_o"}, true)
      query = base |> where([posts: p], ilike(field(p, :body), ^"%f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_cont" => 1}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"id_cont" => 1}, false, false, false)
      assert {:error, _} = ex_sieve
    end

    test ":not_cont" do
      {base, ex_sieve} = ex_sieve_post_query(%{"body_not_cont" => "f%o_o"}, false)
      query = base |> where([p], not ilike(field(p, :body), ^"%f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"body_not_cont" => "f%o_o"}, true)
      query = base |> where([posts: p], not ilike(field(p, :body), ^"%f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_not_cont" => 1}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"id_not_cont" => 1}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":lt" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_lt" => 100}, false)
      query = base |> where([p], field(p, :id) < ^100) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_lt" => 100}, true)
      query = base |> where([posts: p], field(p, :id) < ^100) |> inspect()
      assert query == ex_sieve
    end

    test ":lteq" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_lteq" => 100}, false)
      query = base |> where([p], field(p, :id) <= ^100) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_lteq" => 100}, true)
      query = base |> where([posts: p], field(p, :id) <= ^100) |> inspect()
      assert query == ex_sieve
    end

    test ":gt" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_gt" => 100}, false)
      query = base |> where([p], field(p, :id) > ^100) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_gt" => 100}, true)
      query = base |> where([posts: p], field(p, :id) > ^100) |> inspect()
      assert query == ex_sieve
    end

    test ":gteq" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_gteq" => 100}, false)
      query = base |> where([p], field(p, :id) >= ^100) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_gteq" => 100}, true)
      query = base |> where([posts: p], field(p, :id) >= ^100) |> inspect()
      assert query == ex_sieve
    end

    test ":in" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_in" => [1, 2, 3]}, false)
      query = base |> where([p], field(p, :id) in ^[1, 2, 3]) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_in" => [1, 2, 3]}, true)
      query = base |> where([posts: p], field(p, :id) in ^[1, 2, 3]) |> inspect()
      assert query == ex_sieve
    end

    test ":not_in" do
      {base, ex_sieve} = ex_sieve_post_query(%{"id_not_in" => [1, 2, 3]}, false)
      query = base |> where([p], field(p, :id) not in ^[1, 2, 3]) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"id_not_in" => [1, 2, 3]}, true)
      query = base |> where([posts: p], field(p, :id) not in ^[1, 2, 3]) |> inspect()
      assert query == ex_sieve
    end

    test ":matches" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_matches" => "f%o"}, false)
      query = base |> where([p], ilike(field(p, :title), ^"f%o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_matches" => "f%o"}, true)
      query = base |> where([posts: p], ilike(field(p, :title), ^"f%o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_matches" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_matches" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":does_not_match" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_does_not_match" => "f%o"}, false)
      query = base |> where([p], not ilike(field(p, :title), ^"f%o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_does_not_match" => "f%o"}, true)
      query = base |> where([posts: p], not ilike(field(p, :title), ^"f%o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_at_does_not_match" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_at_does_not_match" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":start" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_start" => "f%o_o"}, false)
      query = base |> where([p], ilike(field(p, :title), ^"f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_start" => "f%o_o"}, true)
      query = base |> where([posts: p], ilike(field(p, :title), ^"f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_start" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_start" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":not_start" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_start" => "f%o_o"}, false)
      query = base |> where([p], not ilike(field(p, :title), ^"f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_start" => "f%o_o"}, true)
      query = base |> where([posts: p], not ilike(field(p, :title), ^"f\\%o\\_o%")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_not_start" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_not_start" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":end" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_end" => "f%o_o"}, false)
      query = base |> where([p], ilike(field(p, :title), ^"%f\\%o\\_o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_end" => "f%o_o"}, true)
      query = base |> where([posts: p], ilike(field(p, :title), ^"%f\\%o\\_o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_end" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_end" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":not_end" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_end" => "f%o_o"}, false)
      query = base |> where([p], not ilike(field(p, :title), ^"%f\\%o\\_o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_end" => "f%o_o"}, true)
      query = base |> where([posts: p], not ilike(field(p, :title), ^"%f\\%o\\_o")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_not_end" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_not_end" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test ":true" do
      {base, ex_sieve} = ex_sieve_post_query(%{"published_true" => true}, false)
      query = base |> where([p], field(p, :published) == ^true) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_true" => 1}, true)
      query = base |> where([posts: p], field(p, :published) == ^true) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_true" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_true" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_true" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":not_true" do
      {base, ex_sieve} = ex_sieve_post_query(%{"published_not_true" => "true"}, false)
      query = base |> where([p], field(p, :published) != ^true) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_not_true" => "T"}, true)
      query = base |> where([posts: p], field(p, :published) != ^true) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_true" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_not_true" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_not_true" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":false" do
      {base, ex_sieve} = ex_sieve_post_query(%{"published_false" => "t"}, false)
      query = base |> where([p], field(p, :published) == ^false) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_false" => "1"}, true)
      query = base |> where([posts: p], field(p, :published) == ^false) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_false" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_false" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_false" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":not_false" do
      {base, ex_sieve} = ex_sieve_post_query(%{"published_not_false" => true}, false)
      query = base |> where([p], field(p, :published) != ^false) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_not_false" => "TRUE"}, true)
      query = base |> where([posts: p], field(p, :published) != ^false) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_false" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_not_false" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_not_false" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":blank" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_blank" => true}, false)
      query = base |> where([p], is_nil(field(p, :title)) or field(p, :title) == ^"") |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_blank" => true}, true)
      query = base |> where([posts: p], is_nil(field(p, :title)) or field(p, :title) == ^"") |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_blank" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_blank" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_blank" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":present" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_present" => true}, false)
      query = base |> where([p], not (is_nil(field(p, :title)) or field(p, :title) == ^"")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_present" => true}, true)
      query = base |> where([posts: p], not (is_nil(field(p, :title)) or field(p, :title) == ^"")) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"published_present" => true}, false)
      assert inspect(base) == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"published_present" => true}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_present" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":null" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_null" => true}, false)
      query = base |> where([p], is_nil(field(p, :title))) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_null" => true}, true)
      query = base |> where([posts: p], is_nil(field(p, :title))) |> inspect()
      assert query == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_null" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end

    test ":not_null" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_null" => true}, false)
      query = base |> where([p], not is_nil(field(p, :title))) |> inspect()
      assert query == ex_sieve

      {base, ex_sieve} = ex_sieve_post_query(%{"title_not_null" => true}, true)
      query = base |> where([posts: p], not is_nil(field(p, :title))) |> inspect()
      assert query == ex_sieve

      {_base, ex_sieve} = ex_sieve_post_query(%{"title_not_null" => "foo"}, false, false, false)
      assert {:error, {:invalid_value, _}} = ex_sieve
    end
  end

  describe "all/any predicates" do
    test "cont_all" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_cont_all" => ["foo", "bar"]}, false)
      query = base |> where([p], ilike(field(p, :title), ^"%foo%") and ilike(field(p, :title), ^"%bar%")) |> inspect()
      assert query == ex_sieve
    end

    test "cont_any" do
      {base, ex_sieve} = ex_sieve_post_query(%{"title_cont_any" => ["foo", "bar"]}, false)
      query = base |> where([p], ilike(field(p, :title), ^"%foo%") or ilike(field(p, :title), ^"%bar%")) |> inspect()
      assert query == ex_sieve
    end

    test "invalid_type" do
      {_, ex_sieve} = ex_sieve_post_query(%{"id_cont_any" => [1, 2]}, false, false, false)
      assert {:error, {:invalid_type, _}} = ex_sieve
    end

    test "invalid predicate" do
      {_, ex_sieve} = ex_sieve_post_query(%{"id_lt_all" => [1, 2]}, false, false, false)
      assert {:error, :predicate_not_found} = ex_sieve
    end
  end
end
