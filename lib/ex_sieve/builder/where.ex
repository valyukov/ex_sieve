defmodule ExSieve.Builder.Where do
  @moduledoc false
  import Ecto.Query

  alias ExSieve.Node.{Attribute, Condition, Grouping}

  @true_values [1, true, "1", "T", "t", "true", "TRUE"]

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

  defp parent_name([parent]), do: parent

  defp parent_name(parents), do: parents |> Enum.join("_") |> String.to_atom()

  defp dynamic_predicate(:eq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) == ^value)
  end

  defp dynamic_predicate(:eq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) == ^value)
  end

  defp dynamic_predicate(:not_eq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) != ^value)
  end

  defp dynamic_predicate(:not_eq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) != ^value)
  end

  defp dynamic_predicate(:cont, %Attribute{parent: [], name: name, type: type}, [value | _]) when type in [:string] do
    dynamic([p], ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:cont, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:not_cont, %Attribute{parent: [], name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([p], not ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:not_cont, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp dynamic_predicate(:lt, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) < ^value)
  end

  defp dynamic_predicate(:lt, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) < ^value)
  end

  defp dynamic_predicate(:lteq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) <= ^value)
  end

  defp dynamic_predicate(:lteq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) <= ^value)
  end

  defp dynamic_predicate(:gt, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) > ^value)
  end

  defp dynamic_predicate(:gt, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) > ^value)
  end

  defp dynamic_predicate(:gteq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) >= ^value)
  end

  defp dynamic_predicate(:gteq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) >= ^value)
  end

  defp dynamic_predicate(:in, %Attribute{parent: [], name: name}, values) do
    dynamic([p], field(p, ^name) in ^values)
  end

  defp dynamic_predicate(:in, %Attribute{parent: parent, name: name}, values) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) in ^values)
  end

  defp dynamic_predicate(:not_in, %Attribute{parent: [], name: name}, values) do
    dynamic([p], field(p, ^name) not in ^values)
  end

  defp dynamic_predicate(:not_in, %Attribute{parent: parent, name: name}, values) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) not in ^values)
  end

  defp dynamic_predicate(:matches, %Attribute{parent: [], name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([p], ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:matches, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:does_not_match, %Attribute{parent: [], name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([p], not ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:does_not_match, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^value))
  end

  defp dynamic_predicate(:start, %Attribute{parent: [], name: name, type: type}, [value | _]) when type in [:string] do
    dynamic([p], ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:start, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:not_start, %Attribute{parent: [], name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([p], not ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:not_start, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"#{value}%"))
  end

  defp dynamic_predicate(:end, %Attribute{parent: [], name: name, type: type}, [value | _]) when type in [:string] do
    dynamic([p], ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(:end, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(:not_end, %Attribute{parent: [], name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([p], not ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(:not_end, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when type in [:string] do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"%#{value}"))
  end

  defp dynamic_predicate(true, %Attribute{type: type} = attribute, [value | _])
       when value in @true_values and type == :boolean do
    dynamic_predicate(:eq, attribute, [true])
  end

  defp dynamic_predicate(:not_true, %Attribute{type: type} = attribute, [value | _])
       when value in @true_values and type == :boolean do
    dynamic_predicate(:not_eq, attribute, [true])
  end

  defp dynamic_predicate(false, %Attribute{type: type} = attribute, [value | _])
       when value in @true_values and type == :boolean do
    dynamic_predicate(:eq, attribute, [false])
  end

  defp dynamic_predicate(:not_false, %Attribute{type: type} = attribute, [value | _])
       when value in @true_values and type == :boolean do
    dynamic_predicate(:not_eq, attribute, [false])
  end

  defp dynamic_predicate(:blank, %Attribute{parent: [], name: name, type: type}, [value | _])
       when value in @true_values and type in [:string] do
    dynamic([p], is_nil(field(p, ^name)) or field(p, ^name) == ^"")
  end

  defp dynamic_predicate(:blank, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when value in @true_values and type in [:string] do
    dynamic([{^parent_name(parent), p}], is_nil(field(p, ^name)) or field(p, ^name) == ^"")
  end

  defp dynamic_predicate(:null, %Attribute{parent: [], name: name}, [value | _]) when value in @true_values do
    dynamic([p], is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:null, %Attribute{parent: parent, name: name}, [value | _]) when value in @true_values do
    dynamic([{^parent_name(parent), p}], is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:not_null, %Attribute{parent: [], name: name}, [value | _]) when value in @true_values do
    dynamic([p], not is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:not_null, %Attribute{parent: parent, name: name}, [value | _]) when value in @true_values do
    dynamic([{^parent_name(parent), p}], not is_nil(field(p, ^name)))
  end

  defp dynamic_predicate(:present, %Attribute{parent: [], name: name, type: type}, [value | _])
       when value in @true_values and type in [:string] do
    dynamic([p], not (is_nil(field(p, ^name)) or field(p, ^name) == ^""))
  end

  defp dynamic_predicate(:present, %Attribute{parent: parent, name: name, type: type}, [value | _])
       when value in @true_values and type in [:string] do
    dynamic([{^parent_name(parent), p}], not (is_nil(field(p, ^name)) or field(p, ^name) == ^""))
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

  defp dynamic_predicate(_predicate, _attribute, _values), do: dynamic(true)
end
