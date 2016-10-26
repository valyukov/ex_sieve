defmodule ExSieve.Node do
  @moduledoc false

  alias ExSieve.Node.{Grouping, Sort}
  alias ExSieve.{Config, Utils}

  @typep error :: {:error, :attribute_not_found | :predicat_not_found | :direction_not_found}

  @spec call(%{(atom | binary) => term}, atom, Config.t) :: {:ok, Grouping.t, list(Sort.t)} | error
  def call(params_with_sort, schema, config) do
    params_with_sort = stringify_keys(params_with_sort)
    {params, sorts} = extract_sorts(params_with_sort, schema)
    grouping = Grouping.extract(params, schema, config)
    result(grouping, Utils.get_error(sorts, config))
  end

  defp extract_sorts(params, schema) do
    {sorts, params} = Map.pop(params, "s", [])
    {params, sorts |> Sort.extract(schema)}
  end

  defp result({:error, reason}, _sorts), do: {:error, reason}
  defp result(_grouping, {:error, reason}), do: {:error, reason}
  defp result(grouping, sorts), do: {:ok, grouping, sorts}

  defp stringify_keys(nil), do: nil
  defp stringify_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end
  defp stringify_keys([head | rest]) do
    [stringify_keys(head) | stringify_keys(rest)]
  end
  defp stringify_keys(not_a_map) do
    not_a_map
  end
end
