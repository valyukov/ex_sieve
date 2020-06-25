defmodule ExSieve.Utils do
  @moduledoc false

  alias ExSieve.Config

  @spec get_error(list(any), Config.t()) :: list(any) | {:error, atom}
  def get_error(items, %Config{ignore_errors: true}), do: Enum.reject(items, &match?({:error, _}, &1))
  def get_error(items, %Config{ignore_errors: false}), do: Enum.find(items, items, &match?({:error, _}, &1))

  @spec extract_schema(Ecto.Queryable.t()) :: {:ok, module()} | {:error, :invalid_query}
  def extract_schema(queryable) do
    queryable
    |> Ecto.Queryable.to_query()
    |> do_extract_schema()
  rescue
    _ -> {:error, :invalid_query}
  end

  @spec filter_list([any()], [any()], [any()]) :: [any()]
  def filter_list(list, only, except) do
    cond do
      is_list(only) -> list -- list -- only
      is_list(except) -> list -- except
      true -> list
    end
  end

  defp do_extract_schema(%Ecto.Query{from: %{source: {_, schema}}}) when not is_nil(schema), do: {:ok, schema}
  defp do_extract_schema(_), do: {:error, :invalid_query}
end
