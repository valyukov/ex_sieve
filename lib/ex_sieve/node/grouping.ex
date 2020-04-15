defmodule ExSieve.Node.Grouping do
  @moduledoc false

  defstruct conditions: nil, combinator: nil, groupings: []

  @type t :: %__MODULE__{}

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.{Condition, Grouping}

  @combinators ~w(or and)

  @spec extract(%{binary => term}, atom, Config.t()) :: t | {:error, :predicate_not_found | :value_is_empty}
  def extract(params, schema, config) do
    {combinator, params} = Map.pop(params, "m", "and")
    {grouping, params} = Map.pop(params, "g", [])
    conditions = Map.get(params, "c", params)

    conditions
    |> do_extract(schema, config, valid_combinator(combinator))
    |> result(extract_groupings(grouping, schema, config))
  end

  defp valid_combinator(combinator) when combinator in @combinators, do: String.to_atom(combinator)
  defp valid_combinator(_combinator), do: :and

  defp result({:error, reason}, _groupings), do: {:error, reason}
  defp result(_grouping, {:error, reason}), do: {:error, reason}
  defp result(grouping, groupings), do: %Grouping{grouping | groupings: groupings}

  defp do_extract(conditions, schema, config, combinator) do
    case extract_conditions(conditions, schema, config) do
      {:error, reason} -> {:error, reason}
      conditions -> %Grouping{combinator: combinator, conditions: conditions}
    end
  end

  defp extract_groupings(groupings, schema, config) do
    groupings |> Enum.map(&extract(&1, schema, config)) |> Utils.get_error(config)
  end

  defp extract_conditions(conditions, schema, config) do
    conditions
    |> Enum.map(fn {key, value} -> Condition.extract(key, value, schema) end)
    |> Utils.get_error(config)
  end
end
