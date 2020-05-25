defmodule ExSieve.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_sieve,
      version: "0.7.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: "Build filtred and sorted Ecto.Query struct from object based queries.",
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_deps: :transitive],

      # Docs
      name: "ExSieve",
      source_url: "https://github.com/valyukov/ex_sieve",
      docs: [
        main: "readme",
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  def application do
    [applications: applications(Mix.env())]
  end

  defp applications(:test), do: [:postgrex, :ecto, :logger, :ex_machina, :ex_unit]
  defp applications(_), do: [:logger]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.3"},
      {:credo, "~> 1.3", only: :dev},
      {:dialyxir, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:ex_machina, "~> 2.0", only: :test},
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, "~> 0.15", only: :test}
    ]
  end

  defp aliases do
    [
      "ecto.reset": [
        "ecto.drop",
        "ecto.create",
        "ecto.migrate"
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Vlad Alyukov", "Alberto Sartori"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/valyukov/ex_sieve"},
      files: ["README.md", "LICENSE", "mix.exs", "lib/*", "CHANGELOG.md"]
    ]
  end
end
