defmodule ExSieve.Builder.Join do
  @moduledoc false
  alias Ecto.Query.Builder.Join

  @spec build(Ecto.Queryable.t(), Macro.t()) :: Ecto.Query.t()
  def build(query, relations) do
    Enum.reduce(relations, query, &apply_join/2)
  end

  @spec apply_join(Macro.t(), Ecto.Queryable.t()) :: Ecto.Query.t() | no_return
  defp apply_join(relation, query) do
    query
    |> Macro.escape()
    |> Join.build(:inner, [Macro.var(:query, __MODULE__)], expr(relation), nil, nil, relation, nil, nil, __ENV__)
    |> elem(0)
    |> Code.eval_quoted()
    |> elem(0)
  end

  defp expr(relation) do
    quote do
      unquote(Macro.var(relation, __MODULE__)) in assoc(query, unquote(relation))
    end
  end
end
