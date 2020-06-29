defmodule ExSieve.Config do
  defstruct ignore_errors: true, max_depth: :full, except_predicates: nil, only_predicates: nil

  @typedoc """
  `ExSieve` configuration options:

    * `:ignore_errors` - when `true` recoverable errors are ignored. Recoverable
    errors include for instance missing attribute or missing predicate, in that
    case the query is returned without taking into account the filter causing the
    error. Defaults to `true`

    * `:max_depth` - the maximum level of nested relations that can be queried.
    Defaults to `:full` meaning no limit

    * `:only_predicates` - a list of allowed predicates. The list can contain `:basic`
    and `:composite`, in that case all corresponding predicates are added to the list.
    When not given or when `nil` no limit is applied. Defaults to `nil`

    * `:except_predicates` - a list of excluded predicates. The list can contain `:basic`
    and `:composite`, in that case all corresponding predicates are added to the list.
    When not given or when `nil` no limit is applied. If both `:only_predicates` and
    `:except_predicates` are given `:only_predicates` takes precedence and
    `:except_predicates` is ignored. Defaults to `nil`
  """
  @type t :: %__MODULE__{
          ignore_errors: boolean(),
          max_depth: non_neg_integer() | :full,
          except_predicates: [String.t() | :basic | :composite] | nil,
          only_predicates: [String.t() | :basic | :composite] | nil
        }

  @keys [:ignore_errors, :max_depth, :except_predicates, :only_predicates]

  @doc false
  @spec new(Keyword.t(), call_options :: map, schema :: module()) :: __MODULE__.t()
  def new(defaults, call_options, schema) do
    defaults = normalize_options(defaults)
    call_options = normalize_options(call_options)
    schema_options = schema |> options_from_schema() |> normalize_options()

    opts =
      defaults
      |> Map.merge(schema_options)
      |> Map.merge(call_options)
      |> Map.take(@keys)

    struct(__MODULE__, opts)
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
