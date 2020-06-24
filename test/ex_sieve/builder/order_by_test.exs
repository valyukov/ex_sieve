defmodule ExSieve.Builder.OrderByTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExSieve.{Comment, Post, User}
  alias ExSieve.Builder.OrderBy
  alias ExSieve.Node.{Sort, Attribute}

  def order_by_build(queryable, sorts) do
    case OrderBy.build(queryable, sorts) do
      {:ok, query} -> query
      err -> err
    end
  end

  describe "ExSieve.Builder.OrderBy.build/3" do
    test "return Ecto.Query with order by asc id" do
      sorts = [%Sort{direction: :asc, attribute: %Attribute{name: :id, parent: [], type: :id}}]

      original = Comment |> order_by(asc: :id) |> inspect()
      built = Comment |> order_by_build(sorts) |> inspect()
      assert original == built
    end

    test "return Ecto.Query order by asc id and post body" do
      sorts = [
        %Sort{direction: :asc, attribute: %Attribute{name: :id, parent: [], type: :id}},
        %Sort{direction: :desc, attribute: %Attribute{name: :body, parent: [:comments], type: :string}}
      ]

      base = from(from(p in Post, join: c in assoc(p, :comments), as: :comments))
      original = base |> order_by([p], asc: :id) |> order_by([comments: c], desc: field(c, :body)) |> inspect()
      built = base |> order_by_build(sorts) |> inspect()

      assert original == built
    end

    test "correctly handle nested relations" do
      sorts = [%Sort{direction: :desc, attribute: %Attribute{name: :body, parent: [:posts, :comments], type: :string}}]

      base =
        User
        |> join(:inner, [u], p in assoc(u, :posts), as: :posts)
        |> join(:inner, [posts: p], c in assoc(p, :comments), as: :posts_comments)

      original = base |> order_by([posts_comments: pc], desc: pc.body) |> inspect()

      built = base |> order_by_build(sorts) |> inspect()

      assert original == built
    end
  end
end
