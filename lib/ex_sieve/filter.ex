defmodule ExSieve.Filter do
  @moduledoc false

  alias ExSieve.{Builder, Config, Node, Utils}

  @spec filter(Ecto.Queryable.t(), %{(binary | atom) => term}, defaults :: Keyword.t(), options :: map) ::
          ExSieve.result()
  def filter(queryable, params, defaults \\ [], options \\ %{}) do
    with {:ok, schema} <- Utils.extract_schema(queryable),
         config <- Config.new(defaults, options, schema),
         {:ok, groupings, sorts} <- Node.call(params, schema, config),
         {:ok, result} <- Builder.call(queryable, groupings, sorts, config) do
      result
    end
  end
end
