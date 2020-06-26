defmodule ExSieve.Node.SortTest do
  use ExUnit.Case, async: true

  alias ExSieve.{Comment, Config, User}
  alias ExSieve.Node.{Sort, Attribute}

  describe "Sort.extract/3" do
    test "return list(Sort.t) for String.t value" do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: [:post], type: :string}}
      assert [sort] == Sort.extract("post_body asc", Comment, %Config{})
    end

    test "return list(Sort.t) for list(String.t) value" do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: [:post], type: :string}}
      assert [sort] == Sort.extract(["post_body asc"], Comment, %Config{})
    end

    test "correctly handle nested relations" do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: [:posts, :comments], type: :string}}
      assert [sort] == Sort.extract(["posts_comments_body asc"], User, %Config{})
    end

    test "return {:error, :direction_not_found}" do
      assert [{:error, {:direction_not_found, "foo"}}] == Sort.extract("post_body foo", Comment, %Config{})
    end

    test "return {:error, :attribute_not_found}" do
      assert [{:error, {:attribute_not_found, "tid"}}] == Sort.extract("tid asc", Comment, %Config{})
    end
  end
end
