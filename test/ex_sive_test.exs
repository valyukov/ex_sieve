defmodule ExSieveTest do
  use ExSieve.TestCase

  import Ecto.Query

  alias ExSieve.{Repo, Comment, Config, User}

  setup do
    {:ok, config: %Config{ignore_errors: false}}
  end

  describe "ExSieve.filter/3" do
    test "return ordered by id and body", %{config: config} do
      [%{body: body} | _] = insert_pair(:post)

      ids = Comment |> ExSieve.filter(%{"post_body_in" => [body], "s" => "post_id desc"}, config) |> ids

      ecto_ids =
        Comment
        |> join(:inner, [c], p in assoc(c, :post))
        |> where([c, p], p.body in ^[body])
        |> order_by([c, p], desc: :post_id)
        |> ids

      assert ids == ecto_ids
    end

    test "broken query fields doesn't affect to query object" do
      config = %Config{ignore_errors: true}

      [%{body: body} | _] = insert_pair(:post)

      ids = Comment |> ExSieve.filter(%{"post_body" => [body], "s" => "post_id desc"}, config) |> ids
      ecto_ids = Comment |> order_by([c], desc: :post_id) |> ids
      assert ids == ecto_ids
    end

    test "broken sort fields doesn't affect to query object" do
      config = %Config{ignore_errors: true}

      [%{body: body} | _] = insert_pair(:post)

      ids = Comment |> ExSieve.filter(%{"post_body_in" => [body], "s" => "posts desc"}, config) |> ids

      ecto_ids =
        Comment
        |> join(:inner, [c], p in assoc(c, :post))
        |> where([c, p], p.body in ^[body])
        |> ids

      assert ids == ecto_ids
    end

    test "return users with custom type field", %{config: config} do
      insert_pair(:user)

      ids = User |> ExSieve.filter(%{"cash_lteq" => %Money{amount: 1000}}, config) |> ids
      ecto_ids = User |> ids
      assert ids == ecto_ids
    end
  end

  defp ids(query), do: query |> Repo.all() |> Enum.map(& &1.id)
end
