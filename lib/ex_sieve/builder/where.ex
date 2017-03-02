defmodule ExSieve.Builder.Where do
  @moduledoc false
  alias Ecto.Query.Builder.Filter
  alias ExSieve.Node.{Attribute, Grouping, Condition}

  @true_values [1, '1', 'T', 't', true, 'true', 'TRUE']

  @spec build(Ecto.Queryable.t, Grouping.t, Macro.t) :: Ecto.Query.t
  def build(query, grouping, binding) do
    exprs = grouping |> List.wrap |> groupings_expr
    :where
    |> Filter.build(:and, Macro.escape(query), binding, exprs, __ENV__)
    |> Code.eval_quoted
    |> elem(0)
  end

  defp grouping_expr(%Grouping{conditions: []}) do
    []
  end
  defp grouping_expr(%Grouping{combinator: combinator, conditions: conditions}) do
    conditions |> Enum.map(&condition_expr/1) |> combinator_expr(combinator)
  end

  defp condition_expr(%Condition{attributes: attrs, values: vals, predicat: predicat, combinator: combinator}) do
    attrs
    |> Enum.map(&predicat_expr(predicat, &1, vals))
    |> combinator_expr(combinator)
  end

  defp groupings_expr(groupings), do: groupings_expr(groupings, [], nil)
  defp groupings_expr([%{groupings: []} = parent], [], nil), do: grouping_expr(parent)
  defp groupings_expr([%{groupings: []} = parent | tail], acc, combinator_acc) do
    groupings_expr(tail, acc ++ [grouping_expr(parent)], combinator_acc)
  end
  defp groupings_expr([%{combinator: combinator, groupings: children} = parent|tail], acc, combinator_acc) do
    children_exprs = groupings_expr(children, acc ++ [grouping_expr(parent)], combinator)
    groupings_expr(tail, children_exprs, combinator_acc)
  end
  defp groupings_expr([], acc, nil), do: acc
  defp groupings_expr([], acc, combinator), do: combinator_expr(acc, combinator)

  defp combinator_expr(exprs, combinator, acc \\ [])
  defp combinator_expr([first_expr, second_expr|tail], combinator, acc) do
    tail_exprs = combinator_expr(tail, combinator, quote do
                                   unquote(combinator)(unquote_splicing([first_expr, second_expr]))
    end)
    combinator_expr([tail_exprs], combinator, acc)
  end
  defp combinator_expr([expr], _combinator, []),
    do: expr
  defp combinator_expr([expr], combinator, acc),
    do: quote(do: unquote(combinator)(unquote(expr), unquote(acc)))
  defp combinator_expr([], _combinator, acc),
    do: acc

  defp field_expr(%Attribute{name: name, parent: parent}) do
    quote do: field(unquote(Macro.var(parent, Elixir)), unquote(name))
  end

  for basic_predicat <- Condition.basic_predicates do
    for {name, combinator} <- [all: :and, any: :or] do
      basic_predicat = basic_predicat |> String.to_atom
      predicat = "#{basic_predicat}_#{name}" |> String.to_atom
      defp predicat_expr(unquote(predicat), attribute, values) do
        values
        |> Enum.map(&predicat_expr(unquote(basic_predicat), attribute, List.wrap(&1)))
        |> combinator_expr(unquote(combinator))
      end
    end
  end

  defp predicat_expr(:eq, attribute, [value|_]) do
    quote(do: unquote(field_expr(attribute)) == ^unquote(value))
  end
  defp predicat_expr(:not_eq, attribute, [value|_]) do
    quote do: unquote(field_expr(attribute)) != ^unquote(value)
  end
  defp predicat_expr(:cont, attribute, [value|_]) do
    quote do: ilike(unquote(field_expr(attribute)), unquote("%#{value}%"))
  end
  defp predicat_expr(:not_cont, attribute, [value|_]) do
    quote do: not(ilike(unquote(field_expr(attribute)), unquote("%#{value}%")))
  end
  defp predicat_expr(:lt, attribute, [value|_]) do
    quote do: unquote(field_expr(attribute)) < ^unquote(value)
  end
  defp predicat_expr(:lteq, attribute, [value|_]) do
    quote do: unquote(field_expr(attribute)) <= ^unquote(value)
  end
  defp predicat_expr(:gt, attribute, [value|_]) do
    quote do: unquote(field_expr(attribute)) > ^unquote(value)
  end
  defp predicat_expr(:gteq, attribute, [value|_]) do
    quote do: unquote(field_expr(attribute)) >= ^unquote(value)
  end
  defp predicat_expr(:in, attribute, values) do
    quote do: unquote(field_expr(attribute)) in unquote(values)
  end
  defp predicat_expr(:not_in, attribute, values) do
    quote do: not(unquote(field_expr(attribute)) in unquote(values))
  end
  defp predicat_expr(:matches, attribute, [value|_]) do
    quote do: ilike(unquote(field_expr(attribute)), unquote(value))
  end
  defp predicat_expr(:does_not_match, attribute, [value|_]) do
    quote do: not(ilike(unquote(field_expr(attribute)), unquote(value)))
  end
  defp predicat_expr(:start, attribute, [value|_]) do
    quote do: ilike(unquote(field_expr(attribute)), unquote("#{value}%"))
  end
  defp predicat_expr(:not_start, attribute, [value|_]) do
    quote do: not(ilike(unquote(field_expr(attribute)), unquote("#{value}%")))
  end
  defp predicat_expr(:end, attribute, [value|_]) do
    quote do: ilike(unquote(field_expr(attribute)), unquote("%#{value}%"))
  end
  defp predicat_expr(:not_end, attribute, [value|_]) do
    quote do: not(ilike(unquote(field_expr(attribute)), unquote("%#{value}%")))
  end
  defp predicat_expr(:true, attribute, [value|_]) when value in @true_values do
    predicat_expr(:not_eq, attribute, [true])
  end
  defp predicat_expr(:not_true, attribute, [value|_]) when value in @true_values do
    predicat_expr(:not_eq, attribute, [true])
  end
  defp predicat_expr(:false, attribute, [value|_]) when value in @true_values do
    predicat_expr(:eq, attribute, [false])
  end
  defp predicat_expr(:not_false, attribute, [value|_]) when value in @true_values do
    predicat_expr(:not_eq, attribute, [false])
  end
  defp predicat_expr(:present, attribute, [value|_] = values) when value in @true_values do
    quote(do: not(unquote(predicat_expr(:blank, attribute, values))))
  end
  defp predicat_expr(:blank, attribute, [value|_]) when value in @true_values do
    quote(do: is_nil(unquote(field_expr(attribute))) or unquote(field_expr(attribute)) == ^'')
  end
  defp predicat_expr(:null, attribute, [value|_]) when value in @true_values do
    quote(do: is_nil(unquote(field_expr(attribute))))
  end
  defp predicat_expr(:not_null, attribute, [value|_] = values) when value in @true_values do
    quote(do: not(unquote(predicat_expr(:null, attribute, values))))
  end
end
