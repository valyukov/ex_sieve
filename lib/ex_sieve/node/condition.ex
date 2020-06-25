defmodule ExSieve.Node.Condition do
  @moduledoc false

  alias ExSieve.Config
  alias ExSieve.Builder.Where
  alias ExSieve.Node.{Attribute, Condition}

  defstruct values: nil, attributes: nil, predicate: nil, combinator: nil

  @type t :: %__MODULE__{}

  @typep values :: String.t() | integer | list(String.t() | integer)

  @spec extract(String.t() | atom, values, module(), Config.t()) ::
          t | {:error, :predicate_not_found | :value_is_empty | :attribute_not_found}
  def extract(key, values, module, config) do
    with {:ok, attributes} <- extract_attributes(key, module, config),
         {:ok, predicate} <- get_predicate(key),
         {:ok, values} <- prepare_values(values) do
      %Condition{
        attributes: attributes,
        predicate: predicate,
        combinator: get_combinator(key),
        values: values
      }
    end
  end

  defp extract_attributes(key, module, config) do
    key
    |> String.split(~r/_(and|or)_/)
    |> Enum.reduce_while({:ok, []}, fn attr_key, {:ok, acc} ->
      case Attribute.extract(attr_key, module, config) do
        {:error, _} = err -> {:halt, err}
        attribute -> {:cont, {:ok, [attribute | acc]}}
      end
    end)
  end

  defp get_predicate(key) do
    Where.predicates()
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
