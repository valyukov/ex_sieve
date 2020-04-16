defmodule ExSieve.Config do
  @moduledoc """
  A `ExSieve.Config` can be created with a `ignore_errors` true or false
  ```
  %ExSieve.Config{
    ignore_errors: true
  }
  ```
  """
  @defaults [
    ignore_errors: true,
    except_predicates: nil,
    only_predicates: nil,
    except_attributes: nil,
    only_attributes: nil
  ]

  defstruct @defaults

  @type t :: %__MODULE__{}

  @doc false
  @spec new(Keyword.t(), map | Keyword.t()) :: ExSieve.Config.t()
  def new(defaults, options \\ %{}) do
    %ExSieve.Config{
      ignore_errors: option_value(:ignore_errors, options, defaults),
      except_predicates: option_value(:except_predicates, options, defaults),
      only_predicates: option_value(:only_predicates, options, defaults),
      except_attributes: option_value(:except_attributes, options, defaults),
      only_attributes: option_value(:only_attributes, options, defaults)
    }
  end

  defp option_value(key, options, defaults) when is_map(options) do
    option_value(key, options, defaults, [&Map.fetch(options, &1), &Map.fetch(options, Atom.to_string(&1))])
  end

  defp option_value(key, options, defaults) when is_list(options) do
    option_value(key, options, defaults, [&Keyword.fetch(options, &1)])
  end

  defp option_value(key, _options, defaults, getters) do
    Enum.reduce_while(
      getters ++
        [
          &Keyword.fetch(defaults, &1),
          &Keyword.fetch(@defaults, &1)
        ],
      :error,
      fn fun, _ ->
        case fun.(key) do
          {:ok, value} -> {:halt, value}
          :error -> {:cont, :error}
        end
      end
    )
  end
end
