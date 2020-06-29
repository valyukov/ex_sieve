defmodule ExSieve.Node.Sort do
  @moduledoc false

  defstruct attribute: nil, direction: nil

  @type t :: %__MODULE__{}

  alias ExSieve.Config
  alias ExSieve.Node.{Attribute, Sort}

  @directions ~w(desc asc)

  @spec extract(String.t() | list(String.t()), module(), Config.t()) ::
          list(
            t()
            | {:error, {:attribute_not_found, key :: String.t()}}
            | {:error, {:direction_not_found, invalid_direction :: String.t()}}
          )
  def extract(value, schema, %Config{} = config) when is_bitstring(value) do
    value
    |> build(schema, config)
    |> List.wrap()
  end

  def extract(values, schema, config), do: Enum.map(values, &build(&1, schema, config))

  defp build(value, schema, config) do
    value
    |> Attribute.extract(schema, config)
    |> result(parse_direction(value))
  end

  defp result(_attribute, {:error, invalid_dir}), do: {:error, {:direction_not_found, invalid_dir}}
  defp result({:error, reason}, _direction), do: {:error, reason}
  defp result(attribute, {:ok, direction}), do: %Sort{attribute: attribute, direction: String.to_atom(direction)}

  defp parse_direction(value) do
    case String.split(value, ~r/\s+/) do
      [_, direction] when direction in @directions -> {:ok, direction}
      [_, invalid_direction] -> {:error, invalid_direction}
      _ -> {:error, value}
    end
  end
end
