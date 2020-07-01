# ExSieve

![CI](https://github.com/valyukov/ex_sieve/workflows/CI/badge.svg?branch=master) [![Hex Version](http://img.shields.io/hexpm/v/ex_sieve.svg?style=flat)](https://hex.pm/packages/ex_sieve) [![Coverage Status](https://coveralls.io/repos/github/valyukov/ex_sieve/badge.svg?branch=master)](https://coveralls.io/github/valyukov/ex_sieve?branch=master) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/ex_sieve)


ExSieve is a filtering solution for Phoenix/Ecto. It builds `Ecto.Query` structs from a [ransack](https://github.com/activerecord-hackery/ransack) inspired query language.

## Installation

Add `ex_sieve` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sieve, "~> 0.8.0"},
  ]
end
```

## Nice to have

- Add advanced search documentation
- Configure predicate aliases
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

For more details on the used query language and query examples see the
[official documentation](https://hexdocs.pm/ex_sieve/ExSieve.html#module-examples).

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
