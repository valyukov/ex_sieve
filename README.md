# ExSieve

![CI](https://github.com/valyukov/ex_sieve/workflows/CI/badge.svg?branch=master) [![Hex Version](http://img.shields.io/hexpm/v/ex_sieve.svg?style=flat)](https://hex.pm/packages/ex_sieve) [![Coverage Status](https://coveralls.io/repos/github/valyukov/ex_sieve/badge.svg?branch=master)](https://coveralls.io/github/valyukov/ex_sieve?branch=master) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/ex_sieve)


ExSieve is a filtering solution for Phoenix/Ecto. It builds `Ecto.Query` structs from a [ransack](https://github.com/activerecord-hackery/ransack) inspired query language.

## Installation

Add `ex_sieve` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sieve, "~> 0.7.0"},
  ]
end
```

## Nice to have

- Add advanced search documentation
- Custom query function (fragments or custom query functions)
- Demo project

## Ecto internals currently used

- `Ecto.Query.Builder.Join.join/10` function needed beacuse dynamic joins are not available

- `%Ecto.Query{from: %{source: {_, module}}}`
  Ecto.query struct internal structure, needed for extracting the main `Ecto.Schema` of the query


## Usage

Setup your application repo, using `ExSieve`

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use ExSieve
end
```

and use the provided `c:ExSieve.filter/3` callback for filtering entries based on query parameters


```elixir
def index(conn, %{"q"=> params}) do
  posts = MyApp.Repo.filter(MyApp.Post, params)

  render conn, :index, posts: posts
end
```

### Examples

In the following we assume these schemas are defined in your application:

```elixir
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
```

```elixir
defmodule MyApp.Comment do
  use Ecto.Schema

  schema "comments" do
    belongs_to :post, MyApp.Post

    field :body

    timestamps()
  end
end
```

#### Simple query

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
SELECT posts.* FROM posts INNER JOIN comments ON posts.id = comments.post_id \
  WHERE posts.id IN (1, 2) \
  OR (posts.title ILIKE '%text%' AND posts.body ILIKE '%text%') \
  OR comments.body == "body" \
  ORDER BY posts.title DESC, posts.inserted_at ASC;
```

#### Grouping queries

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
SELECT posts.* FROM posts INNER JOIN comments ON posts.id = comments.post_id \
  WHERE posts.id IN (1, 2) \
  AND ( \
    (posts.title ILIKE '%text%' AND posts.body ILIKE '%text%') \
    OR comments.body == "body") \
  ORDER BY posts.title DESC, posts.inserted_at ASC;
```

### Supported predicates

#### Base predicates
```
eq
not_eq
cont
not_cont
lt
lteq
gt
gteq
in
not_in
matches
does_not_match
start
not_start
end
not_end
true
not_true
false
not_false
present
blank
null
not_null
```

#### Composite predicates
```
eq_any
not_eq_all
cont_all
cont_any
not_cont_all
not_cont_any
matches_all
matches_any
does_not_match_all
does_not_match_any
start_any
not_start_all
end_any
not_end_all
```

#### Combinators
```
or
and
```

You can read more about predicates on [ransack wiki page](https://github.com/activerecord-hackery/ransack/wiki/Basic-Searching).

## Contributing

First, you'll need to build the test database.

```elixir
DB_PASSWORD=<db_password> MIX_ENV=test mix ecto.reset
```

This task assumes you have postgres installed and that your current user can create / drop databases.
If you'd prefer to use a different user, you can specify it with the environment variable `DB_USER`.

When the database is built, you can run the tests.

```elixir
mix test
```
and

```elixir
mix credo
```
