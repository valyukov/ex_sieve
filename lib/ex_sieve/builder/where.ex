defmodule ExSieve.Builder.Where do
  @moduledoc false
  import Ecto.Query
  import ExSieve.CustomPredicate

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.{Attribute, Condition, Grouping}

  @true_values [1, true, "1", "T", "t", "true", "TRUE"]

  # {basic_predicate, allowed_types | :all, allowed_values | :all, all_any_combinators}
  @predicates_opts [
    {:eq, :all, :all, [:any]},
    {:not_eq, :all, :all, [:all]},
    {:cont, [:string], :all, [:all, :any]},
    {:not_cont, [:string], :all, [:all, :any]},
    {:lt, :all, :all, []},
    {:lteq, :all, :all, []},
    {:gt, :all, :all, []},
    {:gteq, :all, :all, []},
    {:in, :all, :all, []},
    {:not_in, :all, :all, []},
    {:matches, [:string], :all, [:all, :any]},
    {:does_not_match, [:string], :all, [:all, :any]},
    {:start, [:string], :all, [:any]},
    {:not_start, [:string], :all, [:all]},
    {:end, [:string], :all, [:any]},
    {:not_end, [:string], :all, [:all]},
    {true, [:boolean], @true_values, []},
    {:not_true, [:boolean], @true_values, []},
    {false, [:boolean], @true_values, []},
    {:not_false, [:boolean], @true_values, []},
    {:present, [:string], @true_values, []},
    {:blank, [:string], @true_values, []},
    {:null, :all, @true_values, []},
    {:not_null, :all, @true_values, []}
  ]

  @basic_predicates Enum.map(@predicates_opts, &elem(&1, 0))
  @basic_predicates_str Enum.map(@basic_predicates, &Atom.to_string/1)

  @all_any_predicates Enum.flat_map(@predicates_opts, fn {predicate, _, _, all_any} ->
                        Enum.map(all_any, &:"#{predicate}_#{&1}")
                      end)
  @all_any_predicates_str Enum.map(@all_any_predicates, &Atom.to_string/1)

  @predicates_str @basic_predicates_str ++ @all_any_predicates_str

  @spec predicates() :: [String.t()]
  def predicates, do: @predicates_str

  @spec basic_predicates :: [String.t()]
  def basic_predicates, do: @basic_predicates_str

  @spec composite_predicates :: [String.t()]
  def composite_predicates, do: @all_any_predicates_str

  @spec build(Ecto.Queryable.t(), Grouping.t(), Config.t()) ::
          {:ok, Ecto.Query.t()}
          | {:error, {:predicate_not_found, predicate :: atom()}}
          | {:error, {:invalid_type, field :: String.t()}}
          | {:error, {:invalid_value, {field :: String.t(), value :: any()}}}

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

  # composite predicates
  for {basic_predicate, _, _, all_any} <- @predicates_opts do
    for extension <- all_any do
      predicate = :"#{basic_predicate}_#{extension}"
      combinator = Keyword.get([all: :and, any: :or], extension)

      defp dynamic_predicate(unquote(predicate), attribute, values, config) do
        values
        |> Enum.map(&dynamic_predicate(unquote(basic_predicate), attribute, List.wrap(&1), config))
        |> combine(unquote(combinator), config)
      end
    end
  end

  # base predicates
  defp dynamic_predicate(predicate, attribute, values, _config) do
    case validate_dynamic(predicate, attribute, values) do
      :ok -> build_dynamic(predicate, attribute, values)
      {:error, _} = err -> err
    end
  end

  for {predicate, allowed_types, allowed_values, _} <- @predicates_opts do
    unless allowed_types == :all do
      defp validate_dynamic(unquote(predicate), %Attribute{type: type} = attr, _)
           when type not in unquote(allowed_types) do
        {:error, {:invalid_type, Utils.rebuild_key(attr)}}
      end
    end

    unless allowed_values == :all do
      defp validate_dynamic(unquote(predicate), attr, [value | _]) when value not in unquote(allowed_values) do
        {:error, {:invalid_value, {Utils.rebuild_key(attr), value}}}
      end
    end
  end

  defp validate_dynamic(_predicate, _attribute, _values), do: :ok

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
    dynamic([p], ilike(field(p, ^name), ^"%#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:cont, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"%#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:not_cont, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"%#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:not_cont, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"%#{escape_like_value(value)}%"))
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
    dynamic([p], ilike(field(p, ^name), ^"#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:start, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:not_start, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:not_start, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"#{escape_like_value(value)}%"))
  end

  defp build_dynamic(:end, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], ilike(field(p, ^name), ^"%#{escape_like_value(value)}"))
  end

  defp build_dynamic(:end, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], ilike(field(p, ^name), ^"%#{escape_like_value(value)}"))
  end

  defp build_dynamic(:not_end, %Attribute{parent: [], name: name}, [value | _]) do
    dynamic([p], not ilike(field(p, ^name), ^"%#{escape_like_value(value)}"))
  end

  defp build_dynamic(:not_end, %Attribute{parent: parent, name: name}, [value | _]) do
    dynamic([{^parent_name(parent), p}], not ilike(field(p, ^name), ^"%#{escape_like_value(value)}"))
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

  for {cp, frag} <- custom_predicates() do
    arity = ExSieve.CustomPredicate.Utils.get_arity(frag)

    value_names = Enum.map(1..arity, &quote(do: unquote(Macro.var(:"v#{&1}", __MODULE__))))
    value_names_pinned = Enum.map(1..arity, &quote(do: ^unquote(Macro.var(:"v#{&1}", __MODULE__))))
    values = quote do: [unquote_splicing(value_names) | _]

    defp build_dynamic(unquote(cp), %Attribute{parent: [], name: name}, unquote(values)) do
      dynamic([p], unquote(cp)(field(p, ^name), unquote_splicing(value_names_pinned)))
    end
  end

  defp build_dynamic(predicate, _attribute, _values), do: {:error, {:predicate_not_found, predicate}}

  defp escape_like_value(value), do: Regex.replace(~r/([\%_])/, value, ~S(\\\1))
end
