defmodule ExSieve.Builder do
  @moduledoc false

  alias ExSieve.Builder.{Join, OrderBy, Where}
  alias ExSieve.Node.{Grouping, Sort}

  @spec call(Ecto.Queryable.t(), Grouping.t(), list(Sort.t())) :: Ecto.Query.t()
  def call(query, grouping, sorts) do
    relations = build_relations(grouping, sorts)
    binding = build_binding(relations)

    query
    |> join(relations)
    |> where(grouping, binding)
    |> order_by(sorts)
  end

  defp join(query, relations), do: Join.build(query, relations)

  defp where(query, groupings, binding), do: Where.build(query, groupings, binding)

  defp order_by(query, sorts), do: OrderBy.build(query, sorts)

  defp build_binding(relations) do
    relations
    |> List.insert_at(0, :query)
    |> Enum.map(&Macro.var(&1, __MODULE__))
  end

  defp build_relations(grouping, sorts) do
    sorts_parents = Enum.map(sorts, & &1.attribute.parent)

    grouping
    |> List.wrap()
    |> get_grouping_conditions()
    |> Enum.flat_map(& &1.attributes)
    |> Enum.map(& &1.parent)
    |> Enum.concat(sorts_parents)
    |> Enum.uniq()
    |> List.delete(:query)
  end

  defp get_grouping_conditions(groupings, acc \\ [])

  defp get_grouping_conditions([%Grouping{conditions: conditions, groupings: []} | t], acc) do
    get_grouping_conditions(t, acc ++ conditions)
  end

  defp get_grouping_conditions([%Grouping{conditions: conditions, groupings: groupings} | t], acc) do
    get_grouping_conditions(t ++ groupings, acc ++ conditions)
  end

  defp get_grouping_conditions([], acc), do: acc
end
