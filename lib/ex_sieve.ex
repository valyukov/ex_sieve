defmodule ExSieve do
  @moduledoc """
  `ExSieve` is meant to be `use`d by a module implementing `Ecto.Repo` behaviour.

  When used, optional configuration parameters can be provided.
  For details about cofngiuration parameters see `t:ExSieve.Config.t/0`.

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
      @behaviour ExSieve

      @ex_sieve_defaults unquote(opts)

      def filter(queryable, params, options \\ %{}) do
        ExSieve.Filter.filter(queryable, params, @ex_sieve_defaults, options)
      end
    end
  end

  @type result :: Ecto.Query.t() | error()

  @type error ::
          {:error, :invalid_query}
          | {:error, {:too_deep, key :: String.t()}}
          | {:error, {:predicate_not_found, key :: String.t()}}
          | {:error, {:attribute_not_found, key :: String.t()}}
          | {:error, {:direction_not_found, invalid_direction :: String.t()}}
          | {:error, {:value_is_empty, key :: String.t()}}
          | {:error, {:invalid_type, field :: String.t()}}
          | {:error, {:invalid_value, {field :: String.t(), value :: any()}}}

  @doc """
  Filters the given query based on params.

  Returns the query with the added filters or an `{}:error, error}` tuple.

  In order to avoid duplicated joins being sent to database only named bindings should be used
  and the binding name should correspond to the related table one.

  ## Examples

      Repo.filter(User, %{"name_cont" => "foo"})

      Repo.filter(from(u in User), %{"name_cont" => "foo"})

      Repo.filter(from(u in User), %{"name_cont" => "foo"})

      User
      |> join(:inner, [u], p in assoc(u, :posts), as: :posts)
      |> preload(:posts)
      |> Repo.filter(%{"name_cont" => "foo"})

      # WARNING: this will result in a duplicated join
      User
      |> join(:inner, [u], p in assoc(u, :posts), as: :posts_dup)
      |> Repo.filter(%{"posts_title_cont" => "foo"})

  """
  @callback filter(Ecto.Queryable.t(), params :: %{(binary | atom) => term}, options :: %{atom => term}) :: result()
end
