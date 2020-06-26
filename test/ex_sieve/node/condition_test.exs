defmodule ExSieve.Node.ConditionTest do
  use ExUnit.Case

  alias ExSieve.Config
  alias ExSieve.{Node.Condition, Comment, User}

  describe "ExSieve.Node.Condition.extract/4" do
    test "return Condition with without combinator" do
      condition = Condition.extract("post_id_eq", 1, Comment, %Config{})
      assert condition.values == [1]
      assert condition.combinator == :and
      assert condition.predicate == :eq
      assert length(condition.attributes) == 1
    end

    test "return Condition with combinator or" do
      condition = Condition.extract("post_id_or_id_cont", 1, Comment, %Config{})
      assert condition.values == [1]
      assert condition.combinator == :or
      assert condition.predicate == :cont
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator and" do
      condition = Condition.extract("post_id_and_id_in", 1, Comment, %Config{})
      assert condition.values == [1]
      assert condition.combinator == :and
      assert condition.predicate == :in
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator cont_all" do
      condition = Condition.extract("post_id_and_id_cont_all", [1, 2], Comment, %Config{})
      assert condition.values == [1, 2]
      assert condition.combinator == :and
      assert condition.predicate == :cont_all
      assert length(condition.attributes) == 2
    end

    test "return Condition with combinator gteq" do
      condition = Condition.extract("post_id_gteq", 2, Comment, %Config{})
      assert condition.values == [2]
      assert condition.combinator == :and
      assert condition.predicate == :gteq
      assert length(condition.attributes) == 1
    end

    test "return Condition for predicate in only" do
      config = %Config{ignore_errors: false, only_predicates: ["eq"]}
      assert %Condition{} = Condition.extract("post_id_eq", 1, Comment, config)

      config = %Config{ignore_errors: false, only_predicates: [:basic]}
      assert %Condition{} = Condition.extract("post_id_eq", 1, Comment, config)

      config = %Config{ignore_errors: false, only_predicates: [:composite, "eq"]}
      assert %Condition{} = Condition.extract("post_id_eq", 1, Comment, config)
    end

    test "return Condition for predicate not in except" do
      config = %Config{ignore_errors: false, except_predicates: ["cont"]}
      assert %Condition{} = Condition.extract("body_not_cont", ["foo"], Comment, config)

      config = %Config{ignore_errors: false, except_predicates: [:basic]}
      assert %Condition{} = Condition.extract("body_not_cont_all", ["foo", "bar"], Comment, config)

      config = %Config{ignore_errors: false, except_predicates: [:basic, "cont_all"]}
      assert %Condition{} = Condition.extract("body_not_cont_all", ["foo", "bar"], Comment, config)
    end

    test "return {:error, :predicate_not_found}" do
      assert {:error, {:predicate_not_found, "post_id_and_id"}} ==
               Condition.extract("post_id_and_id", 1, Comment, %Config{})
    end

    test "return {:error, :predicate_not_found} for excluded predicate" do
      config = %Config{ignore_errors: false, except_predicates: ["eq"]}
      assert {:error, {:predicate_not_found, "post_id_eq"}} == Condition.extract("post_id_eq", 1, Comment, config)

      config = %Config{ignore_errors: false, except_predicates: [:composite]}

      assert {:error, {:predicate_not_found, "body_not_cont_all"}} ==
               Condition.extract("body_not_cont_all", ["foo", "bar"], Comment, config)
    end

    test "return {:error, :predicate_not_found} for predicate not in only" do
      config = %Config{ignore_errors: false, only_predicates: ["eq"]}
      assert {:error, {:predicate_not_found, "post_id_in"}} == Condition.extract("post_id_in", 1, Comment, config)

      config = %Config{ignore_errors: false, only_predicates: [:composite]}
      assert {:error, {:predicate_not_found, "body_cont"}} == Condition.extract("body_cont", "foo", Comment, config)
    end

    test "return {:error, :attribute_not_found}" do
      assert {:error, {:attribute_not_found, "tid_eq"}} == Condition.extract("tid_eq", 1, Comment, %Config{})

      assert {:error, {:attribute_not_found, "posts_comments_foo_eq"}} ==
               Condition.extract("posts_comments_foo_eq", 1, User, %Config{})
    end

    test "return {:error, :value_is_empty}" do
      assert {:error, {:value_is_empty, "id_eq"}} == Condition.extract("id_eq", "", Comment, %Config{})
    end
  end
end
