defmodule ExSieve.Node.AttributeTest do
  use ExUnit.Case

  alias ExSieve.{Node.Attribute, Config, Post, Comment, User}

  describe "ExSieve.Node.Attribute.extract/3" do
    test "return Attribute with parent belongs_to" do
      assert %Attribute{parent: [:post], name: :body, type: :string} ==
               Attribute.extract("post_body_eq", Comment, %Config{})
    end

    test "return Attribute with has_many parent" do
      assert %Attribute{parent: [:comments], name: :id, type: :id} ==
               Attribute.extract("comments_id_in", Post, %Config{})
    end

    test "return Attribute without parent" do
      assert %Attribute{name: :id, parent: [], type: :id} == Attribute.extract("id_eq", Comment, %Config{})
    end

    test "return Attributes for schema with similar fields names" do
      assert %Attribute{name: :published, parent: [], type: :boolean} ==
               Attribute.extract("published_eq", Post, %Config{})

      assert %Attribute{name: :published_at, parent: [], type: :naive_datetime} ==
               Attribute.extract("published_at_eq", Post, %Config{})
    end

    test "return Attribute with belongs_to parent" do
      assert %Attribute{name: :name, parent: [:user], type: :string} ==
               Attribute.extract("user_name_cont_all", Comment, %Config{})
    end

    test "return Attribute with nested parents" do
      assert %Attribute{name: :body, parent: [:posts, :comments], type: :string} ==
               Attribute.extract("posts_comments_body_cont", User, %Config{})
    end

    test "return {:error, :attribute_not_found}" do
      assert {:error, :attribute_not_found} == Attribute.extract("tid_eq", Comment, %Config{})
    end

    test "return {:error, :attribute_not_found} when parent attribute doesn't exist" do
      assert {:error, :attribute_not_found} == Attribute.extract("post_tid", Comment, %Config{})
    end

    test "return {:error, :attribute_not_found} for not filterable field" do
      assert {:error, :attribute_not_found} == Attribute.extract("inserted_at_eq", Comment, %Config{})
    end

    test "return {:error, :attribute_not_found} for not filterable field in assoc" do
      assert {:error, :attribute_not_found} == Attribute.extract("comments_inserted_at_eq", User, %Config{})
    end

    test "return {:error, :attribute_not_found} for not filterable assoc" do
      assert {:error, :attribute_not_found} == Attribute.extract("addresses_street_eq", User, %Config{})
    end

    test "return {:error, :too_deep} when max_depth is exceeded" do
      assert {:error, :too_deep} == Attribute.extract("posts_comments_body_cont", User, %Config{max_depth: 0})
      assert {:error, :too_deep} == Attribute.extract("posts_comments_body_cont", User, %Config{max_depth: 1})
      assert %Attribute{} = Attribute.extract("posts_comments_body_cont", User, %Config{max_depth: 2})
      assert %Attribute{} = Attribute.extract("posts_comments_body_cont", User, %Config{max_depth: :full})
    end
  end
end
