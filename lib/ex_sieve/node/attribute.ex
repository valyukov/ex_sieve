defmodule ExSieve.Node.Attribute do
  @moduledoc false

  defstruct name: nil, parent: nil

  alias ExSieve.Node.Attribute

  @type t :: %__MODULE__{}

  @spec extract(key :: String.t(), module | %{related: module}) :: t() | {:error, :attribute_not_found}
  def extract(key, module) do
    extract(key, module, {:name, get_name(module, key)}, [])
  end

  defp extract(key, module, {:name, nil}, parents) do
    extract(key, module, {:assoc, get_assoc(module, key)}, parents)
  end

  defp extract(_, _, {:name, name}, parents), do: %Attribute{parent: Enum.reverse(parents), name: name}

  defp extract(_, _, {:assoc, nil}, _), do: {:error, :attribute_not_found}

  defp extract(key, module, {:assoc, assoc}, parents) do
    key = String.replace_prefix(key, "#{assoc}_", "")
    module = get_assoc_module(module, assoc)
    extract(key, module, {:name, get_name(module, key)}, [assoc | parents])
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
    |> find_field(key)
  end

  defp get_name(%{related: module}, key), do: get_name(module, key)

  defp get_name(module, key) do
    :fields
    |> module.__schema__()
    |> find_field(key)
  end

  defp find_field(fields, key) do
    fields
    |> Enum.sort_by(&String.length(to_string(&1)), &>=/2)
    |> Enum.find(&String.starts_with?(key, to_string(&1)))
  end
end
