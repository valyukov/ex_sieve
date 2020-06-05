defmodule ExSieve.Builder.JoinTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExSieve.{Post, User}
  alias ExSieve.Builder.Join
  alias ExSieve.Node.{Attribute, Condition, Grouping, Sort}

  @types %{
    body: :string,
    name: :string,
    title: :string
  }

  defp sample_grouping(attrs) do
    %Grouping{
      conditions: [
        %Condition{
          attributes:
            Enum.map(attrs, fn {name, parent} -> %Attribute{name: name, parent: parent, type: Map.get(@types, name)} end),
          combinator: :and,
          predicate: :eq,
          values: ["foo"]
        }
      ],
      combinator: :and,
      groupings: []
    }
  end

  describe "ExSieve.Builder.Join.build/2" do
    test "return Ecto.Query post join with comments" do
      grouping = sample_grouping(body: [:comments])

      original = Post |> join(:inner, [p], c in assoc(p, :comments), as: :comments) |> inspect()
      built = Post |> Join.build(grouping, []) |> inspect()

      assert original == built
    end

    test "return Ecto.Query post and user join with comments" do
      grouping = sample_grouping(body: [:comments], name: [:user])

      original =
        Post
        |> join(:inner, [p], c in assoc(p, :comments), as: :comments)
        |> join(:inner, [p], c in assoc(p, :user), as: :user)
        |> inspect()

      built = Post |> Join.build(grouping, []) |> inspect()

      assert original == built
    end

    test "correctly handle nested relations" do
      sorts = [%Sort{direction: :asc, attribute: %Attribute{name: :title, parent: [:posts], type: :string}}]
      grouping = sample_grouping(body: [:posts, :comments], body: [:comments])

      original =
        User
        |> join(:inner, [u], p in assoc(u, :posts), as: :posts)
        |> join(:inner, [u], c in assoc(u, :comments), as: :comments)
        |> join(:inner, [posts: p], c in assoc(p, :comments), as: :posts_comments)
        |> inspect()

      built = User |> Join.build(grouping, sorts) |> inspect()

      assert original == built
    end

    test "work with from queries" do
      grouping = sample_grouping(name: [])

      original = from(u in User) |> (&Ecto.Adapters.SQL.to_sql(:all, ExSieve.Repo, &1)).()
      built = User |> Join.build(grouping, []) |> (&Ecto.Adapters.SQL.to_sql(:all, ExSieve.Repo, &1)).()

      assert original == built
    end

    test "work with existent joins" do
      grouping = sample_grouping(title: [:posts])

      original =
        User
        |> join(:inner, [u], p in assoc(u, :posts), as: :posts)
        |> inspect()

      built = User |> Join.build(grouping, []) |> inspect()

      assert original == built
    end
  end
end
