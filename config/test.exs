use Mix.Config

config :ex_sieve, ecto_repos: [ExSieve.Repo]

config :ex_sieve, ExSieve.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "ex_sieve_test",
  username: System.get_env("DB_USER") || System.get_env("USER"),
  password: System.get_env("DB_PASSWORD")

config :logger, :console, level: :error
