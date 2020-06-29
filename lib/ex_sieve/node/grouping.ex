defmodule ExSieve.Node.Grouping do
  @moduledoc false

  defstruct conditions: nil, combinator: nil, groupings: []

  @type t :: %__MODULE__{}

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.{Condition, Grouping}

  @combinators ~w(or and)

  @spec extract(%{binary => term}, atom, Config.t()) ::
          t()
          | {:error, {:attribute_not_found, key :: String.t()}}
          | {:error, {:predicate_not_found, key :: String.t()}}
          | {:error, {:value_is_empty, key :: String.t()}}
  def extract(params, schema, config) do
    {combinator, params} = Map.pop(params, "m", "and")
    {grouping, params} = Map.pop(params, "g", [])
    conditions = Map.get(params, "c", params)

    with %Grouping{} = extracted <- do_extract(conditions, schema, config, valid_combinator(combinator)),
         groupings when is_list(groupings) <- extract_groupings(grouping, schema, config) do
      %Grouping{extracted | groupings: groupings}
    end
  end

  defp valid_combinator(combinator) when combinator in @combinators, do: String.to_atom(combinator)
  defp valid_combinator(_combinator), do: :and

  defp do_extract(conditions, schema, config, combinator) do
    case extract_conditions(conditions, schema, config) do
      {:error, _} = err -> err
      conditions -> %Grouping{combinator: combinator, conditions: conditions}
    end
  end

  defp extract_groupings(groupings, schema, config) do
    groupings |> Enum.map(&extract(&1, schema, config)) |> Utils.get_error(config)
  end

  defp extract_conditions(conditions, schema, config) do
    conditions
    |> Enum.map(fn {key, value} -> Condition.extract(key, value, schema, config) end)
    |> Utils.get_error(config)
  end
end
