defmodule ExSieve.Node.ConditionTest do
  use ExUnit.Case

  alias ExSieve.{Node.Condition, Comment, User}

  describe "ExSieve.Node.Condition.extract/3" do
    test "return Condition with without combinator" do
      condition = Condition.extract("post_id_eq", 1, Comment)
      assert condition.values == [1]
      assert condition.combinator == :and
      assert condition.predicate == :eq
      assert length(condition.attributes) == 1
    end

    test "return Condition with combinator or" do
      condition = Condition.extract("post_id_or_id_cont", 1, Comment)
      assert condition.values == [1]
      assert condition.combinator == :or
      assert condition.predicate == :cont
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator and" do
      condition = Condition.extract("post_id_and_id_in", 1, Comment)
      assert condition.values == [1]
      assert condition.combinator == :and
      assert condition.predicate == :in
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator cont_all" do
      condition = Condition.extract("post_id_and_id_cont_all", [1, 2], Comment)
      assert condition.values == [1, 2]
      assert condition.combinator == :and
      assert condition.predicate == :cont_all
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator gteq" do
      condition = Condition.extract("post_id_gteq", 2, Comment)
      assert condition.values == [2]
      assert condition.combinator == :and
      assert condition.predicate == :gteq
      assert length(condition.attributes) == 1
    end

    test "return {:error, :predicate_not_found}" do
      assert {:error, :predicate_not_found} == Condition.extract("post_id_and_id", 1, Comment)
    end

    test "return {:error, :attribute_not_found}" do
      assert {:error, :attribute_not_found} == Condition.extract("tid_eq", 1, Comment)
      assert {:error, :attribute_not_found} == Condition.extract("posts_comments_foo_eq", 1, User)
    end

    test "return {:error, :value_is_empty}" do
      assert {:error, :value_is_empty} == Condition.extract("id_eq", "", Comment)
    end
  end
end
