defmodule ExSieve.Builder.Join do
  @moduledoc false
  alias Ecto.Query.Builder.Join
  alias ExSieve.Node.{Grouping, Sort}

  @spec build(Ecto.Queryable.t(), Grouping.t(), list(Sort.t())) :: Ecto.Query.t()
  def build(query, grouping, sorts) do
    relations = build_relations(grouping, sorts)
    Enum.reduce(relations, query, &apply_join/2)
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

  defp do_apply_join({parent, relation} = pr, query) do
    query
    |> Macro.escape()
    |> Join.build(:inner, join_binding(parent), expr(relation), nil, nil, join_as(pr), nil, nil, __ENV__)
    |> elem(0)
    |> Code.eval_quoted()
    |> elem(0)
  end

  defp join_binding(nil), do: [Macro.var(:query, __MODULE__)]

  defp join_binding(parent), do: [{String.to_atom(parent), Macro.var(:query, __MODULE__)}]

  defp join_as({nil, relation}), do: relation

  defp join_as({parent, relation}), do: :"#{parent}_#{relation}"

  defp expr(relation) do
    quote do
      unquote(Macro.var(relation, __MODULE__)) in assoc(query, unquote(relation))
    end
  end
end
