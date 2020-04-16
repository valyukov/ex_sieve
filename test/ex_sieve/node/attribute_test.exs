defmodule ExSieve.Node.AttributeTest do
  use ExUnit.Case

  alias ExSieve.Config
  alias ExSieve.{Node.Attribute, Post, Comment}

  setup do
    {:ok, config: %Config{ignore_errors: false}}
  end

  describe "ExSieve.Node.Attribute.extract/2" do
    test "return Attribute with parent belongs_to", %{config: config} do
      assert %Attribute{parent: :post, name: :body} == Attribute.extract("post_body_eq", Comment, config)
    end

    test "return Attribute with has_many parent", %{config: config} do
      assert %Attribute{parent: :comments, name: :id} == Attribute.extract("comments_id_in", Post, config)
    end

    test "return Attribute without parent", %{config: config} do
      assert %Attribute{name: :id, parent: :query} == Attribute.extract("id_eq", Comment, config)
    end

    test "return Attributes for schema with similar fields names", %{config: config} do
      assert %Attribute{name: :published, parent: :query} == Attribute.extract("published_eq", Post, config)
      assert %Attribute{name: :published_at, parent: :query} == Attribute.extract("published_at_eq", Post, config)
    end

    test "return Attribute with belongs_to parent", %{config: config} do
      assert %Attribute{name: :name, parent: :user} == Attribute.extract("user_name_cont_all", Comment, config)
    end

    test "return Attribute for attribute in only" do
      config = %Config{ignore_errors: false, only_attributes: ["id"]}
      assert %Attribute{} = Attribute.extract("id_eq", Post, config)
    end

    test "return Attribute for attribute not in except" do
      config = %Config{ignore_errors: false, except_attributes: ["title"]}
      assert %Attribute{} = Attribute.extract("body_not_cont", Post, config)
    end

    test "return Attribute for assoc attribute in only" do
      config = %Config{ignore_errors: false, only_attributes: ["post_id"]}
      assert %Attribute{} = Attribute.extract("post_id_eq", Comment, config)
    end

    test "return {:error, :attribute_not_found}", %{config: config} do
      assert {:error, :attribute_not_found} == Attribute.extract("tid_eq", Comment, config)
    end

    test "return {:error, :attribute_not_found} when parent attribute doesn't exist", %{config: config} do
      assert {:error, :attribute_not_found} == Attribute.extract("post_tid", Comment, config)
    end

    test "return {:error, :attribute_not_found} for excluded attribute" do
      config = %Config{ignore_errors: false, except_attributes: ["body"]}
      assert {:error, :attribute_not_found} == Attribute.extract("body_eq", Comment, config)
    end

    test "return {:error, :attribute_not_found} for excluded assoc attribute" do
      config = %Config{ignore_errors: false, except_attributes: ["post_title"]}
      assert {:error, :attribute_not_found} == Attribute.extract("post_title_eq", Comment, config)
    end

    test "return {:error, :attribute_not_found} for attribute not in only" do
      config = %Config{ignore_errors: false, only_attributes: ["body"]}
      assert {:error, :attribute_not_found} == Attribute.extract("title_eq", Post, config)
    end
  end
end
