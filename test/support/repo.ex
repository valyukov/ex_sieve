defmodule ExSieve.Repo do
  use Ecto.Repo,
    otp_app: :ex_sieve,
    adapter: Ecto.Adapters.Postgres
end
