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

  When `use` is called, a `c:ExSieve.filter/3` function is defined in the Repo.

  This function can and used for filtering entries based on query parameters

      def index(conn, %{"q"=> params}) do
        posts = MyApp.Repo.filter(MyApp.Post, params)
        render conn, :index, posts: posts
      end

  Options can be overridden by setting on per-schema basis (see `ExSieve.Schema`)
  or on single `c:ExSieve.filter/3` calls.

  ## Examples

  In the following we assume these schemas are defined in your application:

      defmodule MyApp.Post do
        use Ecto.Schema

        schema "posts" do
          has_many :comments, MyApp.Comment

          field :title
          field :body
          field :published, :boolean

          timestamps()
        end
      end


      defmodule MyApp.Comment do
        use Ecto.Schema

        schema "comments" do
          belongs_to :post, MyApp.Post

          field :body

          timestamps()
        end
      end

  ### Simple query

  Given this json representation of the query

  ```json
  {
    "m": "or",
    "id_in": [1, 2],
    "title_and_body_cont": "text",
    "comments_body_eq": "body",
    "s": ["title desc", "inserted_at asc"]
  }
  ```

  the following SQL query is sent to the database

  ```sql
  SELECT posts.* FROM posts INNER JOIN comments ON posts.id = comments.post_id
    WHERE posts.id IN (1, 2)
    OR (posts.title ILIKE '%text%' AND posts.body ILIKE '%text%')
    OR comments.body == "body"
    ORDER BY posts.title DESC, posts.inserted_at ASC;
  ```

  ### Grouping queries

  Query fields can be nested for obtaining more advanced filters.

  Given this json representation of the query

  ```json
  {
    "m": "and",
    "id_in": [1, 2],
    "g": [
      {
        "m": "or",
        "c": {
          "title_and_body_cont": "text",
          "comments_body_eq": "body"
        }
      }
    ],
    "s": ["title desc", "inserted_at asc"]
  }
  ```

  the following SQL query is sent to the database

  ```sql
  SELECT posts.* FROM posts INNER JOIN comments ON posts.id = comments.post_id
    WHERE posts.id IN (1, 2)
    AND (
      (posts.title ILIKE '%text%' AND posts.body ILIKE '%text%')
      OR comments.body == "body")
    ORDER BY posts.title DESC, posts.inserted_at ASC;
  ```

  ## Supported predicates

  ### Base predicates

    * `eq`
    * `not_eq`
    * `cont`
    * `not_cont`
    * `lt`
    * `lteq`
    * `gt`
    * `gteq`
    * `in`
    * `not_in`
    * `matches`
    * `does_not_match`
    * `start`
    * `not_start`
    * `end`
    * `not_end`
    * `true`
    * `not_true`
    * `false`
    * `not_false`
    * `present`
    * `blank`
    * `null`
    * `not_null`

  ### Composite predicates

    * `eq_any`
    * `not_eq_all`
    * `cont_all`
    * `cont_any`
    * `not_cont_all`
    * `not_cont_any`
    * `matches_all`
    * `matches_any`
    * `does_not_match_all`
    * `does_not_match_any`
    * `start_any`
    * `not_start_all`
    * `end_any`
    * `not_end_all`

  ### Combinators

    * `or`
    * `and`

  ## Custom predicates

  ExSieve allows to define user-specific predicates.

  These predicates must be defined at compile time with the `:custom_predicates` key
  of the `:ex_sieve` application environment. It should be a keyword list that maps
  predicate_names (atom) to `Ecto.Query.API.fragment/1` strings.

      config :ex_sieve,
        custom_predicates: [
          has_key: "? \\\\? ?",
          less_than_6: "? < 6",
          key_is: "(? ->> ?) = ?"
        ]

  The first argument given to the fragment is the field while next ones are the values
  given in the query string.

  Given this json representation of the query

  ```json
  {
    "metadata_has_key": "tag",
    "score_less_than_6": true,
    "metadata_key_is: ["status", "approved"]
  }
  ```

  the following SQL query is sent to the database

  ```sql
  SELECT posts.* FROM posts
    WHERE posts.metadata ? 'tag'
    AND posts.score < 6
    AND (posts.metadata ->> 'status') = 'approved';
  ```

  ## Notes

  ### LIKE injection

  `LIKE` queries can suffer of [LIKE injection](https://github.blog/2015-11-03-like-injection/) attacks.

  For this reason all predicates which result in a `LIKE` query (`cont`, `not_cont`, `start`, `not_start`, `end`, `not_end`
  and their composite predicates) are properly escaped.

  Some exceptions are  `matches`, `does_not_match` and their composite predicates that allows `%`, `_` and `\\` chars in the value.
  You should be very careful when allowing an external user to use these predicates.

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
          | {:error, {:too_few_values, {key :: String.t(), arity :: non_neg_integer()}}}

  @doc """
  Filters the given query based on params.

  Returns the query with the added filters or an error tuple.

  For details about available options see `t:ExSieve.Config.t/0`.

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
