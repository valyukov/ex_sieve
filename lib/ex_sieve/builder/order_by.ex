defmodule ExSieve.Builder.OrderBy do
  @moduledoc false
  import Ecto.Query

  alias ExSieve.Node.Sort

  @spec build(Ecto.Queryable.t(), list(Sort.t())) :: {:ok, Ecto.Query.t()}
  def build(query, sorts) do
    {:ok,
     Enum.reduce(sorts, query, fn
       %Sort{direction: direction, attribute: %{name: name, parent: parent}}, query ->
         order_by(query, ^[{direction, dynamic_sort(parent, name)}])
     end)}
  end

  defp dynamic_sort([], name), do: dynamic([p], field(p, ^name))
  defp dynamic_sort([parent], name), do: dynamic([{^parent, p}], field(p, ^name))

  defp dynamic_sort(parents, name) do
    parent = parents |> Enum.join("_") |> String.to_atom()
    dynamic([{^parent, p}], field(p, ^name))
  end
end
