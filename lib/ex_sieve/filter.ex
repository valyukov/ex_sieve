defmodule ExSieve.Filter do
  @moduledoc false

  alias ExSieve.{Builder, Config, Node, Utils}

  @spec filter(Ecto.Queryable.t(), %{(binary | atom) => term}, defaults :: Keyword.t(), options :: map) ::
          ExSieve.result() | {:error, any()}
  def filter(queryable, params, defaults \\ [], options \\ %{}) do
    case Utils.extract_schema(queryable) do
      {:ok, schema} ->
        config = Config.new(defaults, options, schema)

        params
        |> Node.call(schema, config)
        |> result(queryable, config)

      {:error, _} = err ->
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
end
