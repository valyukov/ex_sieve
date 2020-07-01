use Mix.Config

config :ex_sieve,
  custom_predicates: [
    has_key: "? \\? ?",
    not_liked: "(? ->> 'score') :: int < 6",
    key_is: "(? ->> ?) = ?"
  ],
  predicate_aliases: [
    m: :matches,
    e: :eq,
    f: :foo,
    hk: :has_key
  ]

config :ex_sieve, ecto_repos: [ExSieve.Repo]

config :ex_sieve, ExSieve.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ex_sieve_test",
  username: System.get_env("DB_USER") || System.get_env("USER"),
  password: System.get_env("DB_PASSWORD")

config :logger, :console, level: :error
