defmodule ExSieve do
  @moduledoc """
  ExSieve is a object query translator to Ecto.Query.
  """

  alias ExSieve.Config

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
      @behaviour ExSieve

      @ex_sieve_defaults unquote(opts)

      def filter(queryable, params, options \\ %{}) do
        ExSieve.Filter.filter(queryable, params, @ex_sieve_defaults, options)
      end
    end
  end

  @typep error :: :invalid_query | :attribute_not_found | :predicate_not_found | :direction_not_found | :value_is_empty
  @type result :: Ecto.Query.t() | {:error, error}

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
