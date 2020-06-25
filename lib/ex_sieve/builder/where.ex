defmodule ExSieve.Builder.Where do
  @moduledoc false
  import Ecto.Query

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.{Attribute, Condition, Grouping}

  @true_values [1, true, "1", "T", "t", "true", "TRUE"]

  @basic_predicates ~w(eq
                       not_eq
                       cont
                       not_cont
                       lt
                       lteq
                       gt
                       gteq
                       in
                       not_in
                       matches
                       does_not_match
                       start
                       not_start
                       end
                       not_end
                       true
                       not_true
                       false
                       not_false
                       present
                       blank
                       null
                       not_null)a

  @all_any_predicates Enum.flat_map(@basic_predicates, &[:"#{&1}_any", :"#{&1}_all"])
  @predicates @basic_predicates ++ @all_any_predicates
  @predicates_str Enum.map(@predicates, &Atom.to_string/1)

  @spec predicates() :: [String.t()]
  def predicates, do: @predicates_str

  @spec build(Ecto.Queryable.t(), Grouping.t(), Config.t()) :: {:ok, Ecto.Query.t()} | {:error, any()}
  def build(query, %Grouping{combinator: combinator} = grouping, config) when combinator in ~w(and or)a do
    case dynamic_grouping(grouping, config) do
      {:error, _} = err -> err
      where_clause -> {:ok, where(query, ^where_clause)}
    end
  end

  defp dynamic_grouping(%Grouping{conditions: conditions, groupings: groupings, combinator: combinator}, config) do
    conditions
    |> Enum.map(fn
      %Condition{attributes: attrs, values: vals, predicate: predicate, combinator: combinator} ->
        attrs
        |> Enum.map(fn attr -> dynamic_predicate(predicate, attr, vals, config) end)
        |> combine(combinator, config)
    end)
    |> Kernel.++(Enum.map(groupings, &dynamic_grouping(&1, config)))
    |> combine(combinator, config)
  end

  defp combine(dynamics, combinator, config) do
    case Utils.get_error(dynamics, config) do
      {:error, _} = err -> err
      dynamics -> combine(dynamics, combinator)
    end
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

  for basic_predicate <- @basic_predicates do
    for {name, combinator} <- [all: :and, any: :or] do
      predicate = :"#{basic_predicate}_#{name}"

      defp dynamic_predicate(unquote(predicate), attribute, values, config) do
        values
        |> Enum.map(&dynamic_predicate(unquote(basic_predicate), attribute, List.wrap(&1), config))
        |> combine(unquote(combinator), config)
      end
    end
  end

  defp dynamic_predicate(predicate, attribute, values, _config) do
    case validate_dynamic(predicate, attribute, values) do
      :ok -> build_dynamic(predicate, attribute, values)
      {:error, _} = err -> err
    end
  end

  defp validate_dynamic(predicate, %Attribute{type: type} = attr, _)
       when (predicate in [
               :cont,
               :not_cont,
               :matches,
               :does_not_match,
               :start,
               :not_start,
               :end,
               :not_end,
               :blank,
               :present
             ] and type not in [:string]) or
              (predicate in [true, :not_true, false, :not_false] and type not in [:boolean]) do
    {:error, {:invalid_type, attr}}
  end

  defp validate_dynamic(predicate, attr, [value | _])
       when predicate in [true, :not_true, false, :not_false, :blank, :null, :not_null, :present] and
              value not in @true_values do
    {:error, {:invalid_value, attr}}
  end

  defp validate_dynamic(predicate, _attribute, _values) when predicate in @predicates, do: :ok

  defp build_dynamic(:eq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) == ^value)
  end

  defp build_dynamic(:eq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) == ^value)
  end

  defp build_dynamic(:not_eq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) != ^value)
  end

  defp build_dynamic(:not_eq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) != ^value)
  end

  defp build_dynamic(:cont, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp build_dynamic(:cont, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp build_dynamic(:not_cont, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp build_dynamic(:not_cont, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"%#{value}%"))
  end

  defp build_dynamic(:lt, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) < ^value)
  end

  defp build_dynamic(:lt, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) < ^value)
  end

  defp build_dynamic(:lteq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) <= ^value)
  end

  defp build_dynamic(:lteq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) <= ^value)
  end

  defp build_dynamic(:gt, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) > ^value)
  end

  defp build_dynamic(:gt, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) > ^value)
  end

  defp build_dynamic(:gteq, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], field(p, ^name) >= ^value)
  end

  defp build_dynamic(:gteq, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) >= ^value)
  end

  defp build_dynamic(:in, %Attribute{parent: [], name: name}, values) do
    dynamic([p], field(p, ^name) in ^values)
  end

  defp build_dynamic(:in, %Attribute{parent: parent, name: name}, values) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) in ^values)
  end

  defp build_dynamic(:not_in, %Attribute{parent: [], name: name}, values) do
    dynamic([p], field(p, ^name) not in ^values)
  end

  defp build_dynamic(:not_in, %Attribute{parent: parent, name: name}, values) do
    dynamic([{^parent_name(parent), p}], field(p, ^name) not in ^values)
  end

  defp build_dynamic(:matches, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^value))
  end

  defp build_dynamic(:matches, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^value))
  end

  defp build_dynamic(:does_not_match, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^value))
  end

  defp build_dynamic(:does_not_match, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^value))
  end

  defp build_dynamic(:start, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"#{value}%"))
  end

  defp build_dynamic(:start, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"#{value}%"))
  end

  defp build_dynamic(:not_start, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"#{value}%"))
  end

  defp build_dynamic(:not_start, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"#{value}%"))
  end

  defp build_dynamic(:end, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"%#{value}"))
  end

  defp build_dynamic(:end, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"%#{value}"))
  end

  defp build_dynamic(:not_end, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"%#{value}"))
  end

  defp build_dynamic(:not_end, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"%#{value}"))
  end

  defp build_dynamic(true, attribute, _value), do: build_dynamic(:eq, attribute, [true])

  defp build_dynamic(:not_true, attribute, _value), do: build_dynamic(:not_eq, attribute, [true])

  defp build_dynamic(false, attribute, _value), do: build_dynamic(:eq, attribute, [false])

  defp build_dynamic(:not_false, attribute, _value), do: build_dynamic(:not_eq, attribute, [false])

  defp build_dynamic(:blank, %Attribute{parent: [], name: name}, _value) do
    dynamic([p], is_nil(field(p, ^name)) or field(p, ^name) == ^"")
  end

  defp build_dynamic(:blank, %Attribute{parent: parent, name: name}, _value) do
    dynamic([{^parent_name(parent), p}], is_nil(field(p, ^name)) or field(p, ^name) == ^"")
  end

  defp build_dynamic(:null, %Attribute{parent: [], name: name}, _value) do
    dynamic([p], is_nil(field(p, ^name)))
  end

  defp build_dynamic(:null, %Attribute{parent: parent, name: name}, _value) do
    dynamic([{^parent_name(parent), p}], is_nil(field(p, ^name)))
  end

  defp build_dynamic(:not_null, %Attribute{parent: [], name: name}, _value) do
    dynamic([p], not is_nil(field(p, ^name)))
  end

  defp build_dynamic(:not_null, %Attribute{parent: parent, name: name}, _value) do
    dynamic([{^parent_name(parent), p}], not is_nil(field(p, ^name)))
  end

  defp build_dynamic(:present, %Attribute{parent: [], name: name}, _value) do
    dynamic([p], not (is_nil(field(p, ^name)) or field(p, ^name) == ^""))
  end

  defp build_dynamic(:present, %Attribute{parent: parent, name: name}, _value) do
    dynamic([{^parent_name(parent), p}], not (is_nil(field(p, ^name)) or field(p, ^name) == ^""))
  end

  defp build_dynamic(_predicate, _attribute, _values), do: {:error, :predicate_not_found}
end
