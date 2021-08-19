defmodule ExSieve.TestCase do
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using(opts) do
    quote do
      alias ExSieve.Repo

      use ExUnit.Case, unquote(opts)

      import Ecto.Query
      import ExSieve.Factory
    end
  end

  setup do
    Sandbox.mode(ExSieve.Repo, :manual)

    :ok = Sandbox.checkout(ExSieve.Repo)
  end
end

ExUnit.start()

apps = [:postgrex, :ecto, :ex_machina]
Enum.map(apps, &Application.ensure_all_started/1)

ExSieve.Repo.start_link()
