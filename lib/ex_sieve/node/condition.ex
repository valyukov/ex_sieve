defmodule ExSieve.Node.Condition do
  @moduledoc false

  alias ExSieve.{Config, Utils}
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

  @spec extract(String.t() | atom, values, atom, Config.t()) ::
          t | {:error, :predicate_not_found | :value_is_empty | :attribute_not_found}
  def extract(key, values, module, config) do
    with {:ok, attributes} <- extract_attributes(key, module),
         {:ok, predicate} <- get_predicate(key, config),
         {:ok, values} <- prepare_values(values) do
      %Condition{
        attributes: attributes,
        predicate: predicate,
        combinator: get_combinator(key),
        values: values
      }
    end
  end

  defp extract_attributes(key, module) do
    key
    |> String.split(~r/_(and|or)_/)
    |> Enum.reduce_while({:ok, []}, fn attr_key, {:ok, acc} ->
      case Attribute.extract(attr_key, module) do
        {:error, _} = err -> {:halt, err}
        attribute -> {:cont, {:ok, [attribute | acc]}}
      end
    end)
  end

  defp get_predicate(key, config) do
    @predicates
    |> Utils.filter(config.only_predicates, config.except_predicates)
    |> Enum.sort_by(&byte_size/1, &>=/2)
    |> Enum.find(&String.ends_with?(key, &1))
    |> case do
      nil -> {:error, :predicate_not_found}
      predicate -> {:ok, String.to_atom(predicate)}
    end
  end

  defp get_combinator(key) do
    cond do
      String.contains?(key, "_or_") -> :or
      String.contains?(key, "_and_") -> :and
      :otherwise -> :and
    end
  end

  defp prepare_values(values) when is_list(values) do
    values
    |> Enum.all?(&match?({:ok, _val}, prepare_values(&1)))
    |> if do
      {:ok, values}
    else
      {:error, :value_is_empty}
    end
  end

  defp prepare_values(""), do: {:error, :value_is_empty}
  defp prepare_values(value), do: {:ok, List.wrap(value)}
end
