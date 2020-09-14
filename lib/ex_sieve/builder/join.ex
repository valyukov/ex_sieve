defmodule ExSieve.Builder.Join do
  @moduledoc false
  import Ecto.Query
  alias ExSieve.Node.{Grouping, Sort}

  @spec build(Ecto.Queryable.t(), Grouping.t(), list(Sort.t())) :: {:ok, Ecto.Query.t()}
  def build(query, grouping, sorts) do
    relations = build_relations(grouping, sorts)
    {:ok, Enum.reduce(relations, query, &apply_join/2)}
  end

  defp build_relations(grouping, sorts) do
    sorts_parents = Enum.map(sorts, & &1.attribute.parent)

    grouping
    |> get_grouping_conditions()
    |> Enum.flat_map(& &1.attributes)
    |> Enum.map(& &1.parent)
    |> Enum.concat(sorts_parents)
    |> all_possible_relations()
    |> Enum.concat()
    |> Enum.uniq()
    |> Enum.sort(&(length(&1) <= length(&2)))
    |> to_parent_relation_tuple()
  end

  defp get_grouping_conditions(groupings, acc \\ [])

  defp get_grouping_conditions(%Grouping{} = grouping, acc), do: get_grouping_conditions([grouping], acc)

  defp get_grouping_conditions([%Grouping{conditions: conditions, groupings: []} | t], acc) do
    get_grouping_conditions(t, acc ++ conditions)
  end

  defp get_grouping_conditions([%Grouping{conditions: conditions, groupings: groupings} | t], acc) do
    get_grouping_conditions(t ++ groupings, acc ++ conditions)
  end

  defp get_grouping_conditions([], acc), do: acc

  defp all_possible_relations(parents) do
    Enum.map(parents, fn parent_list ->
      {relations, _} =
        Enum.map_reduce(parent_list, [], fn el, acc ->
          acc = [el | acc]
          {acc, acc}
        end)

      relations
    end)
  end

  defp to_parent_relation_tuple(parents) do
    Enum.map(parents, fn parent_list ->
      case parent_list do
        [] -> {nil, :query}
        [head] -> {nil, head}
        [head | tail] -> {tail |> Enum.reverse() |> Enum.join("_"), head}
      end
    end)
  end

  defp apply_join(parent_relation, query) do
    binding_name = join_as(parent_relation)

    case Ecto.Query.has_named_binding?(query, binding_name) do
      true -> query
      false -> do_apply_join(parent_relation, query)
    end
  end

  defp do_apply_join(parent_relation, query) do
    as = join_as(parent_relation)
    query |> Macro.escape() |> join_build(parent_relation, as) |> elem(0)
  end

  defp join_build(query, {nil, relation}, as) do
    Code.eval_quoted(
      quote do
        join(unquote(query), :inner, [p], a in assoc(p, unquote(relation)), as: unquote(as))
      end
    )
  end

  defp join_build(query, {string, relation}, as) do
    parent = String.to_atom(string)

    Code.eval_quoted(
      quote do
        join(unquote(query), :inner, [{unquote(parent), p}], a in assoc(p, unquote(relation)), as: unquote(as))
      end
    )
  end

  defp join_as({nil, relation}), do: relation

  defp join_as({parent, relation}), do: :"#{parent}_#{relation}"
end
