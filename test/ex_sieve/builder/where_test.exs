defmodule ExSieve.Builder.WhereTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExSieve.{Post, Config}
  alias ExSieve.Builder.Where
  alias ExSieve.Node.Grouping

  describe "ExSieve.Builder.Where.build/3" do
    test "return Ecto.Query for where comments" do
      params = %{"m" => "or", "comments_body_eq" => "test", "id_eq" => 1}
      groupping = params |> Grouping.extract(Post, %Config{ignore_errors: true})

      base = from(from p in Post, join: c in assoc(p, :comments))
      ecto = base |> where([p, c], field(p, :id) == ^1 or field(c, :body) == ^"test") |> inspect
      query = base |> Where.build(groupping, [query: 0, comments: 1]) |> inspect

      assert ecto == query
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
      groupping = params |> Grouping.extract(Post, %Config{ignore_errors: true})

      common = from(from p in Post, join: c in assoc(p, :comments), join: u in assoc(p, :user))
      ecto =
        common
        |> where([p, c, u], c.body == ^"test" and ((ilike(u.name, "%1%") or ilike(u.name, "%2%")) and c.user_id in [1]))
        |> inspect

      query = common |> Where.build(groupping, [query: 0, comments: 1, user: 2]) |> inspect

      assert ecto == query
    end

    test "return Ecto.Query with cast datetime" do
      datetime = Ecto.DateTime.utc |> Ecto.DateTime.to_iso8601
      params = %{"inserted_at_gteq" => datetime}

      groupping = params |> Grouping.extract(Post, %Config{ignore_errors: true})

      ecto = Post |> where([p], field(p, :inserted_at) >= ^datetime) |> inspect
      query = Post |> Where.build(groupping, [query: 0]) |> inspect

      assert ecto == query
    end
  end
end
