defmodule ExSieve.Utils do
  @moduledoc false

  alias ExSieve.Config
  alias ExSieve.Node.Attribute

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

  @spec filter_list([any()], any(), any()) :: [any()]
  def filter_list(list, only, except) do
    cond do
      is_list(only) -> list -- list -- only
      is_list(except) -> list -- except
      true -> list
    end
  end

  @spec rebuild_key(Attribute.t()) :: String.t()
  def rebuild_key(%Attribute{name: name, parent: parents}), do: rebuild_key(to_string(name), parents)

  @spec rebuild_key(key :: String.t(), parents :: [atom() | String.t()]) :: String.t()
  def rebuild_key(key, []), do: key |> String.split() |> Enum.at(0)

  def rebuild_key(key, parents) do
    parents
    |> Enum.reverse()
    |> Enum.map(&to_string/1)
    |> Enum.join("_")
    |> Kernel.<>("_#{key}")
    |> rebuild_key([])
  end

  defp do_extract_schema(%Ecto.Query{from: %{source: {_, schema}}}) when not is_nil(schema), do: {:ok, schema}
  defp do_extract_schema(_), do: {:error, :invalid_query}
end
