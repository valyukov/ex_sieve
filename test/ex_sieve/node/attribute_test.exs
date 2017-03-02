defmodule ExSieve.Node.AttributeTest do
  use ExUnit.Case

  alias ExSieve.{Node.Attribute, Post, Comment}

  describe "ExSieve.Node.Attribute.extract/2" do
    test "return Attribute with parent belongs_to" do
      assert %Attribute{parent: :post, name: :body} == Attribute.extract("post_body_eq", Comment)
    end

    test "return Attribute with has_many parent" do
      assert %Attribute{parent: :comments, name: :id} == Attribute.extract("comments_id_in", Post)
    end

    test "return Attribute without parent" do
      assert %Attribute{name: :id, parent: :query} == Attribute.extract("id_eq", Comment)
    end

    test "return Attributes for schema with similar fields names" do
      assert %Attribute{name: :published, parent: :query} == Attribute.extract("published_eq", Post)
      assert %Attribute{name: :published_at, parent: :query} == Attribute.extract("published_at_eq", Post)
    end

    test "return Attribute with belongs_to parent" do
      assert %Attribute{name: :name, parent: :user} == Attribute.extract("user_name_cont_all", Comment)
    end

    test "return {:error, :attribute_not_found}" do
      assert {:error, :attribute_not_found} == Attribute.extract("tid_eq", Comment)
    end

    test "return {:error, :attribute_not_found} when parent attribute doesn't exist" do
      assert {:error, :attribute_not_found} == Attribute.extract("post_tid", Comment)
    end
  end
end
