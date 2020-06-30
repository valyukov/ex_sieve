defmodule ExSieve.CustomPredicate do
  defmodule Utils do
    @spec get_arity(binary) :: integer
    def get_arity(fragment) do
      not_escaped = ~r/\?/ |> Regex.scan(fragment) |> List.flatten() |> length()
      escaped = ~r/\\\?/ |> Regex.scan(fragment) |> List.flatten() |> length()

      not_escaped - escaped - 1
    end
  end

  @custom_predicates Application.get_env(:ex_sieve, :custom_predicates, [])

  for {cp, frag} <- @custom_predicates do
    arity = Utils.get_arity(frag)

    arg_names = Enum.map(1..arity, &Macro.var(:"arg#{&1}", __MODULE__))

    defmacro unquote(cp)(field, unquote_splicing(arg_names)) do
      {:fragment, [], [unquote(frag), field, unquote_splicing(arg_names)]}
    end
  end

  @spec custom_predicates :: keyword(String.t())
  def custom_predicates, do: @custom_predicates
end
