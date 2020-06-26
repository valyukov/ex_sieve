defmodule ExSieve.Node.Attribute do
  @moduledoc false

  defstruct name: nil, parent: nil, type: nil

  alias ExSieve.{Config, Utils}
  alias ExSieve.Node.Attribute

  @type t :: %__MODULE__{}

  @spec extract(key :: String.t(), module | %{related: module}, Config.t()) ::
          t()
          | {:error, {:attribute_not_found, key :: String.t()}}
          | {:error, {:too_deep, key :: String.t()}}

  def extract(key, module, config) do
    extract(key, module, {:name, get_name_and_type(module, key)}, [], config)
  end

  defp extract(key, module, {:name, nil}, parents, %Config{max_depth: md} = config) do
    if md == :full or (is_integer(md) and length(parents) < md) do
      extract(key, module, {:assoc, get_assoc(module, key)}, parents, config)
    else
      {:error, {:too_deep, Utils.rebuild_key(key, parents)}}
    end
  end

  defp extract(_, _, {:name, {name, type}}, parents, _config) do
    %Attribute{parent: Enum.reverse(parents), name: name, type: type}
  end

  defp extract(key, _, {:assoc, nil}, parents, _), do: {:error, {:attribute_not_found, Utils.rebuild_key(key, parents)}}

  defp extract(key, module, {:assoc, assoc}, parents, config) do
    key = String.replace_prefix(key, "#{assoc}_", "")
    module = get_assoc_module(module, assoc)
    extract(key, module, {:name, get_name_and_type(module, key)}, [assoc | parents], config)
  end

  defp get_assoc_module(module, assoc) do
    case module.__schema__(:association, assoc) do
      %{related: module} -> module
      module -> module
    end
  end

  defp get_assoc(%{related: module}, key), do: get_assoc(module, key)

  defp get_assoc(module, key) do
    :associations
    |> module.__schema__()
    |> Utils.filter_list(nil, not_filterable_fields(module))
    |> find_field(key)
  end

  defp get_name_and_type(%{related: module}, key), do: get_name_and_type(module, key)

  defp get_name_and_type(module, key) do
    :fields
    |> module.__schema__()
    |> Utils.filter_list(nil, not_filterable_fields(module))
    |> find_field(key)
    |> case do
      nil -> nil
      field -> {field, :type |> module.__schema__(field) |> Ecto.Type.type()}
    end
  end

  defp find_field(fields, key) do
    fields
    |> Enum.sort_by(&String.length(to_string(&1)), &>=/2)
    |> Enum.find(&String.starts_with?(key, to_string(&1)))
  end

  defp not_filterable_fields(schema) do
    schema
    |> function_exported?(:__ex_sieve_not_filterable_fields__, 0)
    |> case do
      true -> apply(schema, :__ex_sieve_not_filterable_fields__, [])
      false -> nil
    end
  end
end
