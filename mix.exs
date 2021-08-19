defmodule ExSieve.Mixfile do
  use Mix.Project

  @version "0.8.1"

  def project do
    [
      app: :ex_sieve,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: "Build filtred and sorted Ecto.Query struct from object based queries.",
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive],

      # Docs
      name: "ExSieve",
      source_url: "https://github.com/valyukov/ex_sieve",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.3"},
      {:credo, "~> 1.3", only: :dev},
      {:dialyxir, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:ecto_sql, "~> 3.0", only: [:dev, :test]},
      {:ex_machina, "~> 2.0", only: :test},
      {:postgrex, "~> 0.15", only: :test},
      {:excoveralls, "~> 0.10", only: :test}
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

  defp docs do
    [
      main: "ExSieve",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/ex_sieve",
      source_url: "https://github.com/valyukov/ex_sieve",
      extras: []
    ]
  end
end
