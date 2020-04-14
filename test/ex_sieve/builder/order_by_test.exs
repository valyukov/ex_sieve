defmodule ExSieve.Builder.OrderByTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExSieve.{Comment, Post}
  alias ExSieve.Builder.OrderBy
  alias ExSieve.Node.{Sort, Attribute}

  describe "ExSieve.Builder.OrderBy.build/3" do
    test "return Ecto.Query with order by asc id" do
      sorts = [%Sort{direction: :asc, attribute: %Attribute{name: :id, parent: :query}}]

      original = Comment |> order_by(asc: :id) |> inspect()
      built = Comment |> OrderBy.build(sorts) |> inspect()
      assert original == built
    end

    test "return Ecto.Query order by asc id and post body" do
      sorts = [
        %Sort{direction: :asc, attribute: %Attribute{name: :id, parent: :query}},
        %Sort{direction: :desc, attribute: %Attribute{name: :body, parent: :comments}}
      ]

      base = from(from(p in Post, join: c in assoc(p, :comments), as: :comments))
      original = base |> order_by([p], asc: :id) |> order_by([comments: c], desc: field(c, :body)) |> inspect()
      built = base |> OrderBy.build(sorts) |> inspect()

      assert original == built
    end
  end
end
