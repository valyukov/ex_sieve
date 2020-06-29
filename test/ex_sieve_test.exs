defmodule ExSieveTest do
  use ExSieve.TestCase

  import Ecto.Query

  alias ExSieve.{Repo, Comment, User}

  describe "ExSieve.Filter.filter/3" do
    test "return ordered by id and body" do
      config = [ignore_errors: false]

      [%{body: body} | _] = insert_pair(:post)

      ids = Comment |> ExSieve.Filter.filter(%{"post_body_in" => [body], "s" => "post_id desc"}, config) |> ids

      ecto_ids =
        Comment
        |> join(:inner, [c], p in assoc(c, :post))
        |> where([c, p], p.body in ^[body])
        |> order_by([c, p], desc: :post_id)
        |> ids

      assert ids == ecto_ids
    end

    test "broken query fields doesn't affect to query object" do
      config = [ignore_errors: true]

      [%{body: body} | _] = insert_pair(:post)

      ids = Comment |> ExSieve.Filter.filter(%{"post_body" => [body], "s" => "post_id desc"}, config) |> ids
      ecto_ids = Comment |> order_by([c], desc: :post_id) |> ids
      assert ids == ecto_ids
    end

    test "broken sort fields doesn't affect to query object" do
      config = [ignore_errors: true]

      [%{body: body} | _] = insert_pair(:post)

      ids = Comment |> ExSieve.Filter.filter(%{"post_body_in" => [body], "s" => "posts desc"}, config) |> ids

      ecto_ids =
        Comment
        |> join(:inner, [c], p in assoc(c, :post))
        |> where([c, p], p.body in ^[body])
        |> ids

      assert ids == ecto_ids
    end

    test "return users with custom type field" do
      config = [ignore_errors: false]
      insert_pair(:user)
      ids = User |> ExSieve.Filter.filter(%{"cash_lteq" => %Money{amount: 1000}}, config) |> ids()
      assert ids == ids(User)
    end

    test "return error with invalid queries" do
      assert {:error, :invalid_query} = ExSieve.Filter.filter(InvalidUser, %{})
    end
  end

  defp ids(query), do: query |> Repo.all() |> Enum.map(& &1.id)
end
