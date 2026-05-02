defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :postgrex, :ecto_sql]
    ]
  end

  defp deps do
    [
      {:threadline, path: ".."},
      {:benchee, "~> 1.3"},
      {:benchee_html, "~> 1.0"},
      {:benchee_markdown, "~> 0.3"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"}
    ]
  end
end
