defmodule Shopifex.MixProject do
  use Mix.Project

  def project do
    [
      app: :shopifex,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Shopifex.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash_postgres, [github: "ash-project/ash_postgres", override: true]},
      {:ash, [github: "ash-project/ash", override: true]},
      {:ash_money, "~> 0.1.9"},
      {:ash_admin, "~> 0.11"},
      {:ash_archival, "~> 1.0"},

      # required for ash_money
      {:ex_money_sql, "~> 1.11"},

      # testing
      {:smokestack, "~> 0.9"},
      {:faker, "~> 0.18"}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
