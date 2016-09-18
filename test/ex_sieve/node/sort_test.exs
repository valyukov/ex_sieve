defmodule ExSieve.Node.SortTest do
  use ExUnit.Case, async: true

  alias ExSieve.Comment
  alias ExSieve.Node.{Sort, Attribute}

  describe "Sort.extract/2" do
    test "return list(Sort.t) for String.t value" do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: :post}}
      assert [sort] == Sort.extract("post_body asc", Comment)
    end

    test "return list(Sort.t) for list(String.t) value" do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: :post}}
      assert [sort] == Sort.extract(["post_body asc"], Comment)
    end

    test "return {:error, :direction_not_found}" do
      assert [{:error, :direction_not_found}] == Sort.extract("post_body_asc", Comment)
    end

    test "return {:error, :attribute_not_found}" do
      assert [{:error, :attribute_not_found}] == Sort.extract("tid asc", Comment)
    end
  end
end
