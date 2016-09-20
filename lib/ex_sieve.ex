defmodule ExSieve do
  @moduledoc """
  ExSieve is a object query translator to Ecto.Query.
  """

  alias ExSieve.{Builder, Node, Config}

  @doc """
  ExSieve is meant to be `use`d by a Ecto.Repo.

  When `use`d, an optional default for `ignore_erros` can be provided.
  If `ignore_erros` is not provided, a default of `true` will be used.

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app
        use ExSieve
      end

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app
        use ExSieve, ignore_erros: true
      end

    When `use` is called, a `filter` function is defined in the Repo.
  """

  defmacro __using__(opts) do
    quote do
      @ex_sieve_defaults unquote(opts)

      def filter(queryable, params, options \\ []) do
        ExSieve.filter(queryable, params, Config.new(@ex_sieve_defaults, options))
      end
    end
  end

  @typep error :: :attribute_not_found | :predicat_not_found | :direction_not_found | :value_is_empty
  @type result :: Ecto.Query.t | {:error, error}

  @spec filter(Ecto.Queryable.t, %{binary => term}, Config.t) :: result
  def filter(queryable, params, %Config{} = config) do
    params
    |> Node.call(extract_schema(queryable), config)
    |> result(queryable)
  end

  defp result({:error, reason}, _queryable), do: {:error, reason}
  defp result({:ok, groupings, sorts}, queryable), do: Builder.call(queryable, groupings, sorts)

  defp extract_schema(%{from: {_, schema}}), do: schema
  defp extract_schema(schema), do: schema
end
