defmodule ExSieve.Config do
  defstruct ignore_errors: true, max_depth: :full, except_predicates: nil, only_predicates: nil

  @typedoc """
  `ExSieve` configuration options:
    * `ignore_errors`
    * `max_depth`
    * `except_predicates`
    * `only_predicates`
  """
  @type t :: %__MODULE__{
          ignore_errors: boolean(),
          max_depth: non_neg_integer() | :full,
          except_predicates: [String.t() | :basic | :composite] | nil,
          only_predicates: [String.t() | :basic | :composite] | nil
        }

  @keys [:ignore_errors, :max_depth, :except_predicates, :only_predicates]

  @doc false
  @spec new(Keyword.t(), call_options :: map, schema :: module()) :: ExSieve.Config.t()
  def new(defaults, call_options, schema) do
    defaults = normalize_options(defaults)
    call_options = normalize_options(call_options)
    schema_options = schema |> options_from_schema() |> normalize_options()

    opts =
      defaults
      |> Map.merge(schema_options)
      |> Map.merge(call_options)
      |> Map.take(@keys)

    struct(ExSieve.Config, opts)
  end

  defp options_from_schema(schema) do
    cond do
      function_exported?(schema, :__ex_sieve_options__, 0) -> apply(schema, :__ex_sieve_options__, [])
      true -> %{}
    end
  end

  defp normalize_options(options) when is_list(options) or is_map(options) do
    Map.new(options, fn
      {key, val} when is_atom(key) -> {key, val}
      {key, val} when is_bitstring(key) -> {String.to_existing_atom(key), val}
    end)
  end
end
