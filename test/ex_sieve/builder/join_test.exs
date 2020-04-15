defmodule ExSieve.Builder.JoinTest do
  use ExUnit.Case
  import Ecto.Query

  alias ExSieve.Post
  alias ExSieve.Builder.Join

  describe "ExSieve.Builder.Join.build/2" do
    test "return Ecto.Query post join with comments" do
      original = Post |> join(:inner, [p], c in assoc(p, :comments), as: :comments) |> inspect()
      built = Post |> Join.build([:comments]) |> inspect()

      assert original == built
    end

    test "return Ecto.Query post and user join with comments" do
      original =
        Post
        |> join(:inner, [p], c in assoc(p, :comments), as: :comments)
        |> join(:inner, [p], c in assoc(p, :user), as: :user)
        |> inspect()

      built = Post |> Join.build([:comments, :user]) |> inspect()

      assert original == built
    end
  end
end
