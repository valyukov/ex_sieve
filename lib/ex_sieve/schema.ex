defmodule ExSieve.Schema do
  @moduledoc """
  `ExSieve.Schema` is meant to be `use`d by a module using `Ecto.Schema`.

  When used, optional configuration parameters specific for the schema
  can be provided. For details about cofngiuration parameters see
  `t:ExSieve.Config.t/0`.

      defmodule MyApp.User do
        use ExSieve.Schema
      end

      defmodule MyApp.USer do
        use ExSieve.Schema, max_depth: 0
      end

  When using `ExSieve.Schema`, the list of not filterable schema fields can be
  specified with the `@ex_sieve_not_filterable_fields` module attribute.

      defmodule MyApp.User do
        use Ecto.Schema
        use ExSieve.Schema

        @ex_sieve_not_filterable_fields [:name, :inserted_at, :comments]

        schema "users" do
          has_many :comments, ExSieve.Comment
          has_many :posts, ExSieve.Post

          field :name
          field :cash, Money.Ecto.Type

          timestamps()
        end
      end

  Filters for fields that are in the list are ignored (an error is returned
  if `ignore_errors` is `false`). By default all fields are filterable.
  """

  defmacro __using__(opts) do
    quote do
      def __ex_sieve_options__, do: unquote(opts)

      @before_compile unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :ex_sieve_not_filterable_fields, accumulate: false)
      Module.put_attribute(__MODULE__, :ex_sieve_not_filterable_fields, :all)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __ex_sieve_not_filterable_fields__, do: @ex_sieve_not_filterable_fields
    end
  end
end
