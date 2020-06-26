defmodule ExSieve.Node do
  @moduledoc false

  alias ExSieve.Node.{Grouping, Sort}
  alias ExSieve.{Config, Utils}

  @type error ::
          {:error, {:too_deep, key :: String.t()}}
          | {:error, {:predicate_not_found, key :: String.t()}}
          | {:error, {:attribute_not_found, key :: String.t()}}
          | {:error, {:direction_not_found, invalid_direction :: String.t()}}
          | {:error, {:value_is_empty, key :: String.t()}}

  @spec call(%{(atom | binary) => term}, atom, Config.t()) :: {:ok, Grouping.t(), list(Sort.t())} | error
  def call(params_with_sort, schema, config) do
    params_with_sort = stringify_keys(params_with_sort)
    {params, sorts} = extract_sorts(params_with_sort, schema, config)

    with sorts when is_list(sorts) <- Utils.get_error(sorts, config),
         %Grouping{} = grouping <- Grouping.extract(params, schema, config) do
      {:ok, grouping, sorts}
    end
  end

  defp extract_sorts(params, schema, config) do
    {sorts, params} = Map.pop(params, "s", [])
    {params, Sort.extract(sorts, schema, config)}
  end

  defp stringify_keys(nil), do: nil
  defp stringify_keys(%{__struct__: _struct} = value), do: value
  defp stringify_keys(%{} = map), do: Map.new(map, fn {k, v} -> {to_string(k), stringify_keys(v)} end)
  defp stringify_keys([head | rest]), do: [stringify_keys(head) | stringify_keys(rest)]
  defp stringify_keys(not_a_map), do: not_a_map
end
