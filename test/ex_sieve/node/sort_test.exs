defmodule ExSieve.Node.SortTest do
  use ExUnit.Case, async: true

  alias ExSieve.{Comment, Config}
  alias ExSieve.Node.{Sort, Attribute}

  setup do
    {:ok, config: %Config{ignore_errors: false}}
  end

  describe "Sort.extract/2" do
    test "return list(Sort.t) for String.t value", %{config: config} do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: :post}}
      assert [sort] == Sort.extract("post_body asc", Comment, config)
    end

    test "return list(Sort.t) for list(String.t) value", %{config: config} do
      sort = %Sort{direction: :asc, attribute: %Attribute{name: :body, parent: :post}}
      assert [sort] == Sort.extract(["post_body asc"], Comment, config)
    end

    test "return {:error, :direction_not_found}", %{config: config} do
      assert [{:error, :direction_not_found}] == Sort.extract("post_body_asc", Comment, config)
    end

    test "return {:error, :attribute_not_found}", %{config: config} do
      assert [{:error, :attribute_not_found}] == Sort.extract("tid asc", Comment, config)
    end
  end
end
