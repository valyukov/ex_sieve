defmodule ExSieve.Node.GroupingTest do
  use ExUnit.Case

  alias ExSieve.{Node.Grouping, Comment, Config}

  setup do
    {:ok, config: %Config{ignore_errors: false}}
  end

  describe "Grouping.extract/3" do
    test "return Grouping with combinator or", %{config: config} do
      params = %{"m" => "or", "post_body_eq" => "test", "id_in" => 1}
      groupping = Grouping.extract(params, Comment, config)
      assert length(groupping.conditions) == 2
      assert groupping.combinator == :or
    end

    test "return Grouping with default combinator and", %{config: config} do
      params = %{"post_body_eq" => "test", "id_in" => 1}
      groupping = Grouping.extract(params, Comment, config)
      assert length(groupping.conditions) == 2
      assert groupping.combinator == :and
    end

    test "return Grouping with combinator and", %{config: config} do
      params = %{"m" => "and", "post_body_eq" => "test", "id_in" => 1}
      groupping = Grouping.extract(params, Comment, config)
      assert length(groupping.conditions) == 2
      assert groupping.combinator == :and
    end

    test "return Grouping with nested groupings", %{config: config} do
      conditions = %{"post_body_eq" => "test", "id_in" => 1}
      params = %{"m" => "and", "c" => conditions, "g" => [%{"m" => "or", "c" => conditions}]}
      groupping = Grouping.extract(params, Comment, config)
      assert length(groupping.conditions) == 2
      assert length(groupping.groupings) == 1
      assert length(groupping.groupings |> List.first |> Map.get(:conditions)) == 2
      assert length(groupping.groupings |> List.first |> Map.get(:groupings)) == 0
      assert groupping.groupings |> List.first |> Map.get(:combinator) == :or
      assert groupping.combinator == :and
    end

    test "return Grouping with only nested groupings", %{config: config} do
      conditions = %{"post_body_eq" => "test", "id_in" => 1}
      params = %{"g" => [%{"m" => "or", "c" => conditions}]}
      groupping = Grouping.extract(params, Comment, config)
      assert length(groupping.conditions) == 0
      assert length(groupping.groupings) == 1
      assert groupping.combinator == :and

      assert length(groupping.groupings |> List.first |> Map.get(:conditions)) == 2
      assert length(groupping.groupings |> List.first |> Map.get(:groupings)) == 0
      assert groupping.groupings |> List.first |> Map.get(:combinator) == :or
    end


    test "return {:error, :predicat_not_found}", %{config: config} do
      assert {:error, :predicat_not_found} == Grouping.extract(%{"post_id_and_id" => 1}, Comment, config)
    end

    test "return {:error, :attribute_not_found}", %{config: config} do
      assert {:error, :attribute_not_found} == Grouping.extract(%{"tid_eq" => 1}, Comment, config)
    end

    test "return nil when attribute not found and ignore_errors is true" do
      empty_grouping = %Grouping{conditions: [], combinator: :and}
      assert empty_grouping == Grouping.extract(%{"tid_eq" => 1}, Comment, %Config{ignore_errors: true})
    end

    test "return empty grouping when predicat not found and ignore_errors is true" do
      empty_grouping = %Grouping{conditions: [], combinator: :and}
      assert empty_grouping == Grouping.extract(%{"post_id_and_id" => 1}, Comment, %Config{ignore_errors: true})
    end
  end
end
