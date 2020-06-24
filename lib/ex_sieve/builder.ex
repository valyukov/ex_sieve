defmodule ExSieve.Builder do
  @moduledoc false

  alias ExSieve.Config
  alias ExSieve.Builder.{Join, OrderBy, Where}
  alias ExSieve.Node.{Grouping, Sort}

  @spec call(Ecto.Queryable.t(), Grouping.t(), list(Sort.t()), Config.t()) :: {:ok, Ecto.Query.t()} | {:error, any()}
  def call(query, grouping, sorts, config) do
    with {:ok, query} <- Join.build(query, grouping, sorts),
         {:ok, query} <- Where.build(query, grouping, config),
         {:ok, query} <- OrderBy.build(query, sorts) do
      {:ok, query}
    end
  end
end
