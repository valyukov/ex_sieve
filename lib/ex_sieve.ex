defmodule ExSieve do
  @moduledoc """
  ExSieve is a object query translator to Ecto.Query.

  ExSieve is meant to be `use`d by a Ecto.Repo.

  When `use`d, an optional keyword list defining default configuration values can be provided.
  If no options are given the default ones are used.
  For a detailed explanation of configuration parameters please see the documentation of the
  `ExSieve.Config` module.

      defmodule MyApp.Repo do
        use Ecto.Repo,
          otp_app: :my_app,
          adapter: Ecto.Adapters.Postgres

        use ExSieve,
          ignore_erros: true
      end

    When `use` is called, a `filter` callback is defined in the Repo.
  """

  alias ExSieve.{Builder, Config, Node}

  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour ExSieve

      @ex_sieve_defaults unquote(opts)

      def filter(queryable, params, options \\ %{}) do
        ExSieve.filter(queryable, params, Config.new(@ex_sieve_defaults, options))
      end
    end
  end

  @type error :: :attribute_not_found | :predicate_not_found | :direction_not_found | :value_is_empty
  @type result :: Ecto.Query.t() | {:error, error}

  @type parameters :: %{optional(String.t()) => String.t() | [String.t()] | parameters()}

  @doc """
  Add filters to the query based on input parameters.

  An optional third argument can be given to override default configuration parameters.

  ## Examples

      iex> params = %{"title_eq" => "foo", "id_in" => [1, 2]}
      iex> MyApp.Repo.filter(MyApp.Post, params, only_predicates: ["eq"]) |> inspect()
      "#Ecto.Query<from p0 in MyApp.Post, where: p0.title == ^\\"foo\\">"

      iex> %{"title_eq" => "foo", "id_in" => [1, 2]}
      iex> MyApp.Repo.filter(MyApp.Post, params, except_predicates: ["eq"]) |> inspect()
      "#Ecto.Query<from p0 in MyApp.Post, where: p0.id in ^[1, 2]>"

      iex> %{"title_eq" => "foo", "id_in" => [1, 2]}
      iex> MyApp.Repo.filter(MyApp.Post, params, only_predicates: ["eq"], except_predicates: ["eq"]) |> inspect()
      "#Ecto.Query<from p0 in MyApp.Post, where: p0.title == ^\\"foo\\">"

      iex> %{"title_eq" => "foo", "user_id_in" => [1, 2]}
      iex> MyApp.Repo.filter(MyApp.Post, params, only_attributes: ["user_id"]) |> inspect()
      "#Ecto.Query<from p0 in MyApp.Post, where: p0.user_id in ^[1, 2]>"

      iex> %{"title_eq" => "foo", "user_id_in" => [1, 2]}
      iex> MyApp.Repo.filter(MyApp.Post, params, except_attributes: ["user_id"]) |> inspect()
      "#Ecto.Query<from p0 in ExSieve.Post, where: p0.title == ^\\"foo\\">"

      iex> %{"title_eq" => "foo", "user_id_in" => [1, 2]}
      iex> MyApp.Repo.filter(MyApp.Post, params, only_attributes: ["user_id"], except_attributes: ["user_id"]) |> inspect()
      "#Ecto.Query<from p0 in MyApp.Post, where: p0.user_id in ^[1, 2]>"

  """
  @callback filter(queryable :: Ecto.Queryable.t(), parameters(), config :: %{optional(atom) => term()}) :: result()

  @doc false
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
