defmodule ExSieve.Builder.OrderBy do
  @moduledoc false
  alias Ecto.Query.Builder.OrderBy
  alias ExSieve.Node.Sort

  @spec build(Ecto.Queryable.t, list(Sort.t), Macro.t) :: Ecto.Query.t
  def build(query, sorts, binding) do
    query
    |> Macro.escape
    |> OrderBy.build(binding, Enum.map(sorts, &expr/1), __ENV__)
    |> Code.eval_quoted
    |> elem(0)
  end

  defp expr(%{direction: direction, attribute: %{name: name, parent: parent}}) do
    parent = Macro.var(parent, Elixir)
    quote do: {unquote(direction), field(unquote(parent), unquote(name))}
  end
end
