defmodule ExSieve.Node.GroupingTest do
  use ExUnit.Case

  alias ExSieve.{Node.Grouping, Comment, Config}

  setup do
    {:ok, config: %Config{ignore_errors: false}}
  end

  describe "Grouping.extract/3" do
    test "return Grouping with combinator or and implicit conditions", %{config: config} do
      params = %{"m" => "or", "post_body_eq" => "test", "id_in" => 1}
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert grouping.combinator == :or
    end

    test "return Grouping with combinator or and explicit conditions", %{config: config} do
      params = %{"m" => "or", "c" => %{"post_body_eq" => "test", "id_in" => 1}}
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert grouping.combinator == :or
    end

    test "return Grouping with default combinator and", %{config: config} do
      params = %{"post_body_eq" => "test", "id_in" => 1}
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert grouping.combinator == :and
    end

    test "return Grouping with combinator and", %{config: config} do
      params = %{"m" => "and", "post_body_eq" => "test", "id_in" => 1}
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert grouping.combinator == :and
    end

    test "return Grouping with nested groupings and explicit conditions", %{config: config} do
      conditions = %{"post_body_eq" => "test", "id_in" => 1}
      params = %{"m" => "and", "c" => conditions, "g" => [%{"m" => "or", "c" => conditions}]}
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert length(grouping.groupings) == 1
      assert length(grouping.groupings |> List.first() |> Map.get(:conditions)) == 2
      assert length(grouping.groupings |> List.first() |> Map.get(:groupings)) == 0
      assert grouping.groupings |> List.first() |> Map.get(:combinator) == :or
      assert grouping.combinator == :and
    end

    test "return Grouping with nested groupings and implicit conditions", %{config: config} do
      conditions = %{"post_body_eq" => "test", "id_in" => 1}
      params = Map.put(conditions, "g", [%{"m" => "or", "c" => conditions}])
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert length(grouping.groupings) == 1
      assert length(grouping.groupings |> List.first() |> Map.get(:conditions)) == 2
      assert length(grouping.groupings |> List.first() |> Map.get(:groupings)) == 0
      assert grouping.groupings |> List.first() |> Map.get(:combinator) == :or
      assert grouping.combinator == :and
    end

    test "return Grouping with nested groupings and implicit nested conditions", %{config: config} do
      conditions = %{"post_body_eq" => "test", "id_in" => 1}
      params = Map.put(conditions, "g", [Map.put(conditions, "m", "or")])
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 2
      assert length(grouping.groupings) == 1
      assert length(grouping.groupings |> List.first() |> Map.get(:conditions)) == 2
      assert length(grouping.groupings |> List.first() |> Map.get(:groupings)) == 0
      assert grouping.groupings |> List.first() |> Map.get(:combinator) == :or
      assert grouping.combinator == :and
    end

    test "return Grouping with only nested groupings", %{config: config} do
      conditions = %{"post_body_eq" => "test", "id_in" => 1}
      params = %{"g" => [%{"m" => "or", "c" => conditions}]}
      grouping = Grouping.extract(params, Comment, config)
      assert length(grouping.conditions) == 0
      assert length(grouping.groupings) == 1
      assert grouping.combinator == :and

      assert length(grouping.groupings |> List.first() |> Map.get(:conditions)) == 2
      assert length(grouping.groupings |> List.first() |> Map.get(:groupings)) == 0
      assert grouping.groupings |> List.first() |> Map.get(:combinator) == :or
    end

    test "return {:error, :predicate_not_found}", %{config: config} do
      assert {:error, {:predicate_not_found, "post_id_and_id"}} ==
               Grouping.extract(%{"post_id_and_id" => 1}, Comment, config)
    end

    test "return {:error, :attribute_not_found}", %{config: config} do
      assert {:error, {:attribute_not_found, "tid_eq"}} == Grouping.extract(%{"tid_eq" => 1}, Comment, config)
    end

    test "return nil when attribute not found and ignore_errors is true" do
      empty_grouping = %Grouping{conditions: [], combinator: :and}
      assert empty_grouping == Grouping.extract(%{"tid_eq" => 1}, Comment, %Config{ignore_errors: true})
    end

    test "return empty grouping when predicate not found and ignore_errors is true" do
      empty_grouping = %Grouping{conditions: [], combinator: :and}
      assert empty_grouping == Grouping.extract(%{"post_id_and_id" => 1}, Comment, %Config{ignore_errors: true})
    end
  end
end
