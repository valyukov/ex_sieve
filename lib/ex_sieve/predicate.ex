defmodule ExSieve.Predicate do
  @moduledoc false

  import ExSieve.CustomPredicate, only: [custom_predicates: 0]

  @true_values [1, true, "1", "T", "t", "true", "TRUE"]

  @type predicate_spec :: {
          prediate_name :: atom(),
          allowed_types :: :all | [Ecto.Type.primitive()],
          allowed_values :: :all | [any()],
          all_any_combinators :: [:all | :any]
        }

  @builtin_predicates_specs [
    {:eq, :all, :all, [:any]},
    {:not_eq, :all, :all, [:all]},
    {:cont, [:string], :all, [:all, :any]},
    {:not_cont, [:string], :all, [:all, :any]},
    {:lt, :all, :all, []},
    {:lteq, :all, :all, []},
    {:gt, :all, :all, []},
    {:gteq, :all, :all, []},
    {:in, :all, :all, []},
    {:not_in, :all, :all, []},
    {:matches, [:string], :all, [:all, :any]},
    {:does_not_match, [:string], :all, [:all, :any]},
    {:start, [:string], :all, [:any]},
    {:not_start, [:string], :all, [:all]},
    {:end, [:string], :all, [:any]},
    {:not_end, [:string], :all, [:all]},
    {true, [:boolean], @true_values, []},
    {:not_true, [:boolean], @true_values, []},
    {false, [:boolean], @true_values, []},
    {:not_false, [:boolean], @true_values, []},
    {:present, [:string], @true_values, []},
    {:blank, [:string], @true_values, []},
    {:null, :all, @true_values, []},
    {:not_null, :all, @true_values, []}
  ]

  @basic_predicates Enum.map(@builtin_predicates_specs, &(&1 |> elem(0) |> Atom.to_string()))

  @all_any_predicates Enum.flat_map(@builtin_predicates_specs, fn {predicate, _, _, all_any} ->
                        Enum.map(all_any, &"#{predicate}_#{&1}")
                      end)

  @builtin_predicates Enum.sort_by(@basic_predicates ++ @all_any_predicates, &byte_size/1, &>=/2)

  @predicates @builtin_predicates ++ (custom_predicates() |> Keyword.keys() |> Enum.map(&Atom.to_string/1))

  @predicate_aliases_map :ex_sieve
                         |> Application.get_env(:predicate_aliases, %{})
                         |> Map.new(fn {pred_alias, pred} -> {to_string(pred_alias), to_string(pred)} end)
                         |> Enum.reject(fn {pred_alias, _} -> pred_alias in @predicates end)
                         |> Enum.reject(fn {_, pred} -> pred not in @predicates end)
                         |> Map.new()

  @spec all() :: [String.t()]
  def all, do: @predicates

  @spec builtin() :: [String.t()]
  def builtin, do: @builtin_predicates

  @spec basic :: [String.t()]
  def basic, do: @basic_predicates

  @spec composite :: [String.t()]
  def composite, do: @all_any_predicates

  @spec specs :: [predicate_spec()]
  def specs, do: @builtin_predicates_specs

  @spec aliases_map :: %{optional(String.t()) => String.t()}
  def aliases_map, do: @predicate_aliases_map
end
