defmodule HexEvaluator.MixProject do
  use Mix.Project

  def project do
    [
      app: :hex_evaluator,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HexEvaluator.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:threadline, "~> 0.9.0"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
