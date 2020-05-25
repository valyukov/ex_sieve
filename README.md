# ExSieve

![CI](https://github.com/valyukov/ex_sieve/workflows/CI/badge.svg?branch=master) [![Hex Version](http://img.shields.io/hexpm/v/ex_sieve.svg?style=flat)](https://hex.pm/packages/ex_sieve) [![Coverage Status](https://coveralls.io/repos/github/valyukov/ex_sieve/badge.svg?branch=master)](https://coveralls.io/github/valyukov/ex_sieve?branch=master) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/ex_sieve)


ExSieve is filttering solution for Phoenix/Ecto. It builds `Ecto.Query` struct from [ransack](https://github.com/activerecord-hackery/ransack) inspired query language.

## Installation

  1. Add `ex_sieve` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sieve, "~> 0.1.0"},
  ]
end
```

or use this:

```elixir
def deps do
  [
    {:ex_sieve, github: "valyukov/ex_sieve"},
  ]
end
```
if you want to stick to mainstream


## Status
This is a work in progress, here's what is done right now:

- [WIP] Phoenix search form helpers
- [ ] Add advanced search documentation
- [ ] Custom query function (fragments or custom query functions)
- [ ] Demo project

## Uasage

First, setup your application repo:

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app
  use ExSieve
end
```

```elixir
defmodule MyApp.Post do
  use Ecto.Schema

  schema "posts" do
    has_many :comments, MyApp.Comment

    field :title
    field :body
    field :published, :boolean

    timestamps
  end
end
```

```elixir
defmodule MyApp.Comment do
  use Ecto.Schema

  schema "comments" do
    belongs_to :post, MyApp.Post

    field :body

    timestamps
  end
end
```

```elixir
def index(conn, %{"q"=> params}) do
  posts = MyApp.Post |> MyApp.Repo.filter(params)

  render conn, :index, posts: posts
end
```

Simple query:

```json
{
  "m": "or",
  "q": {
    "id_in": [1,2],
    "title_and_body_cont": "text",
    "comments_body_eq": "body",
    "sort": ["title desc", "inserted_at asc"]
}

```
this is how query translate to the next SQL:
```sql
SELECT posts.* FROM posts INNER JOIN comments ON posts.id = comments.post_id \
  WHERE posts.id IN (1, 2) \
  OR (posts.title ILIKE '%text%' AND posts.body ILIKE '%text%') \
  OR comments.body == "body" \
  ORDER BY posts.title DESC, posts.inserted_at ASC;
```

Full list of supported predicates:

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
### All predicates
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
eq_any
eq_all
not_eq_any
not_eq_all
cont_any
cont_all
not_cont_any
not_cont_all
lt_any
lt_all
lteq_any
lteq_all
gt_any
gt_all
gteq_any
gteq_all
in_any
in_all
not_in_any
not_in_all
matches_any
matches_all
does_not_match_any
does_not_match_all
start_any
start_all
not_start_any
not_start_all
end_any
end_all
not_end_any
not_end_all
true_any
true_all
not_true_any
not_true_all
false_any
false_all
not_false_any
not_false_all
present_any
present_all
blank_any
blank_all
null_any
null_all
not_null_any
not_null_all
```

#### Combinators
```
or
and
```

Example query key value with combinator:

```json
{
  "q": {
    "title_or_body_cont": "text",
    "inserted_at_and_updated_at_gteq": "2016-09-16T21:32:06"
   }
}
```

Also, you can read more about predicates on [ransack wiki page](https://github.com/activerecord-hackery/ransack/wiki/Basic-Searching)


### Advanced query
 Documentating in progress.

## Contributing

First, you'll need to build the test database.

```elixir
MIX_ENV=test mix ecto.reset
```

This task assumes you have postgres installed and that your current user can create / drop databases. If you'd prefer to use a different user, you can specify it with the environment variable `DB_USER`.

When the database built, you can now run the tests.

```elixir
mix test
```
and

```elixir
mix credo
```
