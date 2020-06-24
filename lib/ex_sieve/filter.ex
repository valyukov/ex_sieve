defmodule ExSieve.Filter do
  @moduledoc false

  alias ExSieve.{Builder, Config, Node}

  @spec filter(Ecto.Queryable.t(), %{(binary | atom) => term}, Config.t()) :: ExSieve.result() | {:error, any()}
  def filter(queryable, params, %Config{} = config) do
    case extract_schema(queryable) do
      {:ok, schema} ->
        params
        |> Node.call(schema, config)
        |> result(queryable, config)

      err ->
        err
    end
  end

  defp result({:error, reason}, _queryable, _config), do: {:error, reason}

  defp result({:ok, groupings, sorts}, queryable, config) do
    case Builder.call(queryable, groupings, sorts, config) do
      {:ok, result} -> result
      err -> err
    end
  end

  defp extract_schema(%Ecto.Query{from: %{source: {_, module}}}), do: extract_schema(module)

  defp extract_schema(schema) when is_atom(schema) do
    cond do
      function_exported?(schema, :__schema__, 1) -> {:ok, schema}
      true -> {:error, :invalid_query}
    end
  end
end
