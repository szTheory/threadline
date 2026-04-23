defmodule Threadline.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/szTheory/threadline"

  def cli do
    # Run the whole CI chain in :test so `test` picks up config/test.exs (Postgres, repo).
    [preferred_envs: ["ci.all": :test]]
  end

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
      {:plug, "~> 1.15"},
      {:telemetry, "~> 1.2"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "verify.format": ["format --check-formatted"],
      "verify.credo": ["credo --strict"],
      "verify.test": ["test"],
      "ci.all": ["verify.format", "verify.credo", "compile --warnings-as-errors", "verify.test"]
    ]
  end

  defp doc_source_ref do
    case Version.parse(@version) do
      {:ok, %Version{pre: []}} -> "v#{@version}"
      _ -> "main"
    end
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/#{doc_source_ref()}/CHANGELOG.md"
      },
      files: ~w(lib guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
    ]
  end

  defp docs do
    [
      main: "Threadline",
      source_ref: doc_source_ref(),
      source_url: @source_url,
      extras: [
        "README.md",
        "guides/domain-reference.md",
        "CONTRIBUTING.md",
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Overview: ~r/README/,
        Reference: ~r{^guides/},
        Project: ~r/(CONTRIBUTING|CHANGELOG)/
      ],
      groups_for_modules: [
        "Core API": [
          Threadline,
          Threadline.Semantics.ActorRef,
          Threadline.Semantics.AuditContext
        ],
        Integration: [
          Threadline.Plug,
          Threadline.Job,
          Threadline.Health,
          Threadline.Telemetry
        ],
        Schemas: [
          Threadline.Semantics.AuditAction,
          Threadline.Capture.AuditTransaction,
          Threadline.Capture.AuditChange
        ],
        "Mix Tasks": [
          Mix.Tasks.Threadline.Install,
          Mix.Tasks.Threadline.Gen.Triggers
        ]
      ]
    ]
  end
end
