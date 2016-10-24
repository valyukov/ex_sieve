defmodule ExSieve.UtilsTest do
  use ExUnit.Case
  
  alias ExSieve.Utils

  describe "ExSieve.Utils.stringify_keys/1" do
    test "return Map" do
      params = %{foo: "foo", bar: "bar"}
      result = %{"foo" => "foo", "bar" => "bar"}
      assert Utils.stringify_keys(params) == result 
    end

    test "return Map deep" do
      params = %{foo: "foo", bar: "bar", baz: %{quiz: "quiz"}}
      result = %{"foo" => "foo", "bar" => "bar", "baz" => %{"quiz" => "quiz"}}
      assert Utils.stringify_keys(params) == result 
    end

    test "return Map lst" do
      params = [%{foo: "foo"}, %{bar: "bar"}]
      result = [%{"foo" => "foo"}, %{"bar" => "bar"}]
      assert Utils.stringify_keys(params) == result 
    end

    test "return Map as string" do
      params = %{"foo" => "foo", "bar" => "bar"}
      result = %{"foo" => "foo", "bar" => "bar"}
      assert Utils.stringify_keys(params) == result 
    end

    test "return nil" do
      assert Utils.stringify_keys(nil) == nil 
    end

    test "return value if not map passed" do
      value = "String"
      assert Utils.stringify_keys(value) == value 
    end
  
  end
end