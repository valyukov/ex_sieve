defmodule ExSieve.Builder.OrderBy do
  @moduledoc false
  import Ecto.Query

  alias ExSieve.Node.Sort

  @spec build(Ecto.Queryable.t(), list(Sort.t())) :: Ecto.Query.t()
  def build(query, sorts) do
    Enum.reduce(sorts, query, fn
      %Sort{direction: direction, attribute: %{name: name, parent: parent}}, query ->
        order_by(query, ^[{direction, dynamic_sort(parent, name)}])
    end)
  end

  defp dynamic_sort(:query, name), do: dynamic([p], field(p, ^name))
  defp dynamic_sort(parent, name), do: dynamic([{^parent, p}], field(p, ^name))
end
