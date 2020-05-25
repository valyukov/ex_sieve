defmodule ExSieve.Builder do
  @moduledoc false

  alias ExSieve.Builder.{Join, OrderBy, Where}
  alias ExSieve.Node.{Grouping, Sort}

  @spec call(Ecto.Queryable.t(), Grouping.t(), list(Sort.t())) :: Ecto.Query.t()
  def call(query, grouping, sorts) do
    query
    |> Join.build(grouping, sorts)
    |> Where.build(grouping)
    |> OrderBy.build(sorts)
  end
end
