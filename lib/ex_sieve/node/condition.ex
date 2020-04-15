defmodule ExSieve.Node.Condition do
  @moduledoc false

  alias ExSieve.Node.{Attribute, Condition}

  defstruct values: nil, attributes: nil, predicate: nil, combinator: nil

  @type t :: %__MODULE__{}

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
                       not_null)

  @all_any_predicates Enum.flat_map(@basic_predicates, &["#{&1}_any", "#{&1}_all"])
  @predicates @basic_predicates ++ @all_any_predicates

  @spec predicates :: list(String.t())
  def predicates, do: @predicates

  @spec basic_predicates :: list(String.t())
  def basic_predicates, do: @basic_predicates

  @typep values :: String.t() | integer | list(String.t() | integer)

  @spec extract(String.t() | atom, values, atom) :: t | {:error, :predicate_not_found | :value_is_empty}
  def extract(key, values, module) do
    with attributes <- extract_attributes(key, module),
         predicate <- get_predicate(key),
         combinator <- get_combinator(key),
         values <- prepare_values(values),
         do: build_condition(attributes, predicate, combinator, values)
  end

  defp prepare_values(values) when is_list(values) do
    result =
      Enum.all?(values, fn
        value when is_bitstring(value) -> String.length(value) >= 1
        _ -> true
      end)

    if result do
      values
    else
      {:error, :value_is_empty}
    end
  end

  defp prepare_values(""), do: {:error, :value_is_empty}
  defp prepare_values(value) when is_bitstring(value), do: List.wrap(value)
  defp prepare_values(value), do: List.wrap(value)

  defp build_condition({:error, reason}, _predicate, _combinator, _values), do: {:error, reason}
  defp build_condition(_attributes, _predicate, _combinator, {:error, reason}), do: {:error, reason}
  defp build_condition(_attributes, {:error, reason}, _combinator, _values), do: {:error, reason}

  defp build_condition(attributes, predicate, combinator, values) do
    %Condition{
      attributes: attributes,
      predicate: predicate,
      combinator: combinator,
      values: values
    }
  end

  defp extract_attributes(key, module) do
    key
    |> String.split(~r/_(and|or)_/)
    |> Enum.map(&Attribute.extract(&1, module))
    |> validate_attributes
  end

  defp validate_attributes(attributes, acc \\ [])

  defp validate_attributes([{:error, reason} | _tail], _acc), do: {:error, reason}

  defp validate_attributes([attribute | tail], acc), do: validate_attributes(tail, acc ++ [attribute])

  defp validate_attributes([], acc), do: acc

  defp get_combinator(key) do
    cond do
      key |> String.contains?("_or_") -> :or
      key |> String.contains?("_and_") -> :and
      :otherwise -> :and
    end
  end

  defp get_predicate(key) do
    case @predicates |> Enum.sort_by(&byte_size/1, &>=/2) |> Enum.find(&String.ends_with?(key, &1)) do
      nil -> {:error, :predicate_not_found}
      predicate -> String.to_atom(predicate)
    end
  end
end
