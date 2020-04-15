defmodule ExSieve.Node.ConditionTest do
  use ExUnit.Case

  alias ExSieve.Config
  alias ExSieve.{Node.Condition, Comment}

  setup do
    {:ok, config: %Config{ignore_errors: false}}
  end

  describe "ExSieve.Node.Condition.extract/3" do
    test "return Condition with without combinator", %{config: config} do
      condition = Condition.extract("post_id_eq", 1, Comment, config)
      assert condition.values == [1]
      assert condition.combinator == :and
      assert condition.predicate == :eq
      assert length(condition.attributes) == 1
    end

    test "return Condition with combinator or", %{config: config} do
      condition = Condition.extract("post_id_or_id_cont", 1, Comment, config)
      assert condition.values == [1]
      assert condition.combinator == :or
      assert condition.predicate == :cont
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator and", %{config: config} do
      condition = Condition.extract("post_id_and_id_in", 1, Comment, config)
      assert condition.values == [1]
      assert condition.combinator == :and
      assert condition.predicate == :in
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator cont_all", %{config: config} do
      condition = Condition.extract("post_id_and_id_cont_all", [1, 2], Comment, config)
      assert condition.values == [1, 2]
      assert condition.combinator == :and
      assert condition.predicate == :cont_all
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator gteq", %{config: config} do
      condition = Condition.extract("post_id_gteq", 2, Comment, config)
      assert condition.values == [2]
      assert condition.combinator == :and
      assert condition.predicate == :gteq
      assert length(condition.attributes) == 1
    end

    test "return Condition for predicate in only" do
      config = %Config{ignore_errors: false, only_predicates: ["eq"]}
      assert %Condition{} = Condition.extract("post_id_eq", 1, Comment, config)
    end

    test "return Condition for predicate not in except" do
      config = %Config{ignore_errors: false, except_predicates: ["cont"]}
      assert %Condition{} = Condition.extract("body_not_cont", 1, Comment, config)
    end

    test "return {:error, :predicate_not_found}", %{config: config} do
      assert {:error, :predicate_not_found} == Condition.extract("post_id_and_id", 1, Comment, config)
    end

    test "return {:error, :predicate_not_found} for excluded predicate" do
      config = %Config{ignore_errors: false, except_predicates: ["eq"]}
      assert {:error, :predicate_not_found} == Condition.extract("post_id_eq", 1, Comment, config)
    end

    test "return {:error, :predicate_not_found} for predicate not in only" do
      config = %Config{ignore_errors: false, only_predicates: ["eq"]}
      assert {:error, :predicate_not_found} == Condition.extract("post_id_in", 1, Comment, config)
    end

    test "return {:error, :attribute_not_found}", %{config: config} do
      assert {:error, :attribute_not_found} == Condition.extract("tid_eq", 1, Comment, config)
    end

    test "return {:error, :value_is_empty}", %{config: config} do
      assert {:error, :value_is_empty} == Condition.extract("id_eq", "", Comment, config)
    end
  end
end
