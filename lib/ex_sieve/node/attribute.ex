defmodule ExSieve.Node.Attribute do
  @moduledoc false

  defstruct name: nil, parent: nil, type: nil

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.Attribute

  @type t :: %__MODULE__{}

  @spec extract(String.t(), atom, Config.t()) :: t | {:error, :attribute_not_found}
  def extract(key, module, config) do
    only = config.only_attributes
    except = config.except_attributes

    case get_name(module, key, only, except) || get_assoc_name(module, key, only, except) do
      nil -> {:error, :attribute_not_found}
      {_assoc, nil} -> {:error, :attribute_not_found}
      {assoc, name} -> %Attribute{parent: String.to_atom(assoc), name: String.to_atom(name)}
      name -> %Attribute{parent: :query, name: String.to_atom(name)}
    end
  end

  defp get_assoc_name(module, key, only, except) do
    case get_assoc(module, key) do
      nil ->
        nil

      assoc ->
        key = String.replace_prefix(key, "#{assoc}_", "")
        only = filter_only_except_for_assoc(assoc, only)
        except = filter_only_except_for_assoc(assoc, except)
        {assoc, get_name(module.__schema__(:association, String.to_atom(assoc)), key, only, except)}
    end
  end

  defp get_assoc(module, key) do
    :associations
    |> module.__schema__()
    |> find_field(key)
  end

  defp get_name(%{related: module}, key, only, except), do: get_name(module, key, only, except)

  defp get_name(module, key, only, except) do
    :fields
    |> module.__schema__()
    |> find_field(key, only, except)
  end

  defp find_field(fields, key, only \\ nil, except \\ nil) do
    fields
    |> Enum.map(&Atom.to_string/1)
    |> Utils.filter(only, except)
    |> Enum.sort_by(&String.length/1, &>=/2)
    |> Enum.find(&String.starts_with?(key, &1))
  end

  defp filter_only_except_for_assoc(prefix, list) when is_list(list) do
    list
    |> Enum.filter(&String.starts_with?(&1, "#{prefix}_"))
    |> Enum.map(&String.replace_prefix(&1, "#{prefix}_", ""))
  end

  defp filter_only_except_for_assoc(_, _), do: nil
end
