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
      {:igniter, "~> 0.3"},
      {:ash, "~> 3.0"},
      {:ash_postgres, "~> 2.0"},
      {:ash_money, "~> 0.1"},
      {:ash_admin, "~> 0.11"},
      {:ash_archival, "~> 1.0"},
      {:ex_money_sql, "~> 1.0"},
      {:picosat_elixir, "~> 0.2"},

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
