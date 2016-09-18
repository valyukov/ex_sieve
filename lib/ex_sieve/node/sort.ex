defmodule ExSieve.Node.Sort do
  @moduledoc false

  defstruct attribute: nil, direction: nil

  @type t :: %__MODULE__{}

  alias ExSieve.Node.{Sort, Attribute}

  @directions ~w(desc asc)

  @spec extract(String.t | list(String.t), atom) :: list(t | {:error, :attribute_not_found | :direction_not_found})
  def extract(value, schema) when is_bitstring(value) do
    value |> build(schema) |> List.wrap
  end
  def extract(values, schema) do
    values |> Enum.map(&build(&1, schema))
  end

  defp build(value, schema) do
    value |> Attribute.extract(schema) |> result(parse_direction(value))
  end

  defp result(_attribute, nil), do: {:error, :direction_not_found}
  defp result({:error, reason}, _direction), do: {:error, reason}
  defp result(attribute, direction), do: %Sort{attribute: attribute, direction: String.to_atom(direction)}

  defp parse_direction(value) do
    value |> String.split(~r/\s+/) |> Enum.find(&Enum.member?(@directions, &1))
  end
end
