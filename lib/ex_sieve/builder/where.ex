defmodule ExSieve.Builder.Where do
  @moduledoc false
  import Ecto.Query

  alias ExSieve.Node.{Attribute, Condition, Grouping}

  @true_values [1, '1', 'T', 't', true, 'true', 'TRUE', "1", "T", "t", "true", "TRUE"]

  @spec build(Ecto.Queryable.t(), Grouping.t()) :: Ecto.Query.t()
  def build(query, %Grouping{combinator: combinator} = grouping) when combinator in ~w(and or)a do
    where(query, ^dynamic_grouping(grouping))
  end

  defp dynamic_grouping(%Grouping{conditions: conditions, groupings: groupings, combinator: combinator}) do
    conditions
    |> Enum.map(fn
      %Condition{attributes: attrs, values: vals, predicate: predicate, combinator: combinator} ->
        attrs
        |> Enum.map(fn attr -> dynamic_predicate(predicate, attr, vals) end)
        |> combine(combinator)
    end)
    |> Kernel.++(Enum.map(groupings, &dynamic_grouping/1))
    |> combine(combinator)
  end

  defp combine([], _), do: dynamic(true)

  defp combine([dynamic], _), do: dynamic

  defp combine([dyn | dynamics], :and) do
    Enum.reduce(dynamics, dyn, fn dyn, acc -> dynamic(^acc and ^dyn) end)
  end

  defp combine([dyn | dynamics], :or) do
    Enum.reduce(dynamics, dyn, fn dyn, acc -> dynamic(^acc or ^dyn) end)
  end

  defp dynamic_predicate(:eq, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], field(p, ^name) == ^value)
  end

  defp dynamic_predicate(:eq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], field(p, ^name) == ^value)
  end

  defp dynamic_predicate(:not_eq, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], field(p, ^name) != ^value)
  end

  defp dynamic_predicate(:not_eq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], field(p, ^name) != ^value)
  end

  defp dynamic_predicate(:cont, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:cont, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:not_cont, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:not_cont, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], not ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:lt, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], field(p, ^name) < ^value)
  end

  defp dynamic_predicate(:lt, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], field(p, ^name) < ^value)
  end

  defp dynamic_predicate(:lteq, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], field(p, ^name) <= ^value)
  end

  defp dynamic_predicate(:lteq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], field(p, ^name) <= ^value)
  end

  defp dynamic_predicate(:gt, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], field(p, ^name) > ^value)
  end

  defp dynamic_predicate(:gt, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], field(p, ^name) > ^value)
  end

  defp dynamic_predicate(:gteq, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], field(p, ^name) >= ^value)
  end

  defp dynamic_predicate(:gteq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], field(p, ^name) >= ^value)
  end

  defp dynamic_predicate(:in, %Attribute{parent: :query, name: name}, values) do
    dynamic([p], field(p, ^name) in ^values)
  end

  defp dynamic_predicate(:in, %Attribute{parent: parent, name: name}, values) do
    dynamic([{^parent, p}], field(p, ^name) in ^values)
  end

  defp dynamic_predicate(:not_in, %Attribute{parent: :query, name: name}, values) do
    dynamic([p], field(p, ^name) not in ^values)
  end

  defp dynamic_predicate(:not_in, %Attribute{parent: parent, name: name}, values) do
    dynamic([{^parent, p}], field(p, ^name) not in ^values)
  end

  defp dynamic_predicate(:matches, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:matches, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:does_not_match, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:does_not_match, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], not ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:start, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:start, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:not_start, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:not_start, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], not ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:end, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(:end, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(:not_end, %Attribute{parent: :query, name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(:not_end, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent, p}], not ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(true, attribute, [value | _]) when value in @true_values do
    dynamic_predicate(:eq, attribute, [true])
  end

  defp dynamic_predicate(:not_true, attribute, [value | _]) when value in @true_values do
    dynamic_predicate(:not_eq, attribute, [true])
  end

  defp dynamic_predicate(false, attribute, [value | _]) when value in @true_values do
    dynamic_predicate(:eq, attribute, [false])
  end

  defp dynamic_predicate(:not_false, attribute, [value | _]) when value in @true_values do
    dynamic_predicate(:not_eq, attribute, [false])
  end

  defp dynamic_predicate(:blank, %Attribute{parent: :query, name: name}, [value | _]) when value in @true_values do
    dynamic([p], is_nil(field(p, ^name)) or field(p, ^name) == ^"")
  end

  defp dynamic_predicate(:blank, %Attribute{parent: parent, name: name}, [value | _]) when value in @true_values do
    dynamic([{^parent, p}], is_nil(field(p, ^name)) or field(p, ^name) == ^"")
  end

  defp dynamic_predicate(:null, %Attribute{parent: :query, name: name}, [value | _]) when value in @true_values do
    dynamic([p], is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:null, %Attribute{parent: parent, name: name}, [value | _]) when value in @true_values do
    dynamic([{^parent, p}], is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:not_null, %Attribute{parent: :query, name: name}, [value | _]) when value in @true_values do
    dynamic([p], not is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:not_null, %Attribute{parent: parent, name: name}, [value | _]) when value in @true_values do
    dynamic([{^parent, p}], not is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:present, %Attribute{parent: :query, name: name}, [value | _]) when value in @true_values do
    dynamic([p], not (is_nil(field(p, ^name)) or field(p, ^name) == ^""))
  end

  defp dynamic_predicate(:present, %Attribute{parent: parent, name: name}, [value | _]) when value in @true_values do
    dynamic([{^parent, p}], not (is_nil(field(p, ^name)) or field(p, ^name) == ^""))
  end

  for basic_predicate <- Condition.basic_predicates() do
    for {name, combinator} <- [all: :and, any: :or] do
      predicate = String.to_atom("#{basic_predicate}_#{name}")
      basic_predicate = String.to_atom(basic_predicate)

      defp dynamic_predicate(unquote(predicate), attribute, values) do
        values
        |> Enum.map(&dynamic_predicate(unquote(basic_predicate), attribute, List.wrap(&1)))
        |> combine(unquote(combinator))
      end
    end
  end
end
