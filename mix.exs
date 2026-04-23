defmodule Threadline.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/szTheory/threadline"

  def project do
    [
      app: :threadline,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      name: "Threadline",
      description: "Audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL",
      source_url: @source_url,
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix]]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:carbonite, "~> 0.16"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "verify.format": ["format --check-formatted"],
      "verify.credo": ["credo --strict"],
      "verify.test": ["test"],
      "ci.all": ["verify.format", "verify.credo", "verify.test"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "Threadline",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
