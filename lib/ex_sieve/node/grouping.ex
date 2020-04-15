defmodule ExSieve.Node.Grouping do
  @moduledoc false

  defstruct conditions: nil, combinator: nil, groupings: []

  @type t :: %__MODULE__{}

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.{Condition, Grouping}

  @combinators ~w(or and)

  @spec extract(%{binary => term}, atom, Config.t()) :: t | {:error, :predicate_not_found | :value_is_empty}
  def extract(%{"m" => m, "g" => g, "c" => conditions}, schema, config) when m in @combinators do
    conditions
    |> do_extract(schema, config, String.to_atom(m))
    |> result(extract_groupings(g, schema, config))
  end

  def extract(%{"m" => m, "c" => conditions}, schema, config) when m in @combinators do
    conditions |> do_extract(schema, config, String.to_atom(m)) |> result([])
  end

  def extract(%{"c" => conditions}, schema, config) do
    conditions |> do_extract(schema, config) |> result([])
  end

  def extract(%{"m" => m} = conditions, schema, config) when m in @combinators do
    conditions |> Map.delete("m") |> do_extract(schema, config, String.to_atom(m))
  end

  def extract(%{"g" => g}, schema, config) do
    %Grouping{combinator: :and, conditions: []} |> result(extract_groupings(g, schema, config))
  end

  def extract(%{"g" => g, "m" => m}, schema, config) when m in @combinators do
    %Grouping{combinator: String.to_atom(m), conditions: []} |> result(extract_groupings(g, schema, config))
  end

  def extract(params, schema, config), do: params |> do_extract(schema, config)

  defp result({:error, reason}, _groupings), do: {:error, reason}
  defp result(_grouping, {:error, reason}), do: {:error, reason}
  defp result(grouping, groupings), do: %Grouping{grouping | groupings: groupings}

  defp do_extract(params, schema, config, combinator \\ :and) do
    case extract_conditions(params, schema, config) do
      {:error, reason} -> {:error, reason}
      conditions -> %Grouping{combinator: combinator, conditions: conditions}
    end
  end

  defp extract_groupings(groupings, schema, config) do
    groupings |> Enum.map(&extract(&1, schema, config)) |> Utils.get_error(config)
  end

  defp extract_conditions(params, schema, config) do
    params |> Enum.map(&extract_condition(&1, schema)) |> Utils.get_error(config)
  end

  defp extract_condition({key, value}, schema), do: Condition.extract(key, value, schema)
end
