defmodule Threadline.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/szTheory/threadline"

  def cli do
    # Run the whole CI chain in :test so `test` picks up config/test.exs (Postgres, repo).
    # Topology tasks need `test/support` (Threadline.Test.Repo) on the compile path.
    [
      preferred_envs: [
        "ci.all": :test,
        "verify.release": :dev,
        "verify.test": :test,
        "verify.topology": :test,
        "threadline.verify_topology": :test,
        "verify.example": :test
      ]
    ]
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
      {:nimble_csv, "~> 1.2"},
      {:plug, "~> 1.15"},
      {:telemetry, "~> 1.2"},
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:phoenix_html, "~> 4.0", optional: true},
      {:phoenix_pubsub, "~> 2.1", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:lazy_html, "~> 0.1.0", only: :test}
    ]
  end

  defp aliases do
    [
      "verify.format": ["format --check-formatted"],
      "verify.credo": ["credo --strict"],
      "verify.test": ["test"],
      "verify.threadline": ["threadline.verify_coverage"],
      "verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
      "verify.release": &verify_release/1,
      "verify.topology": ["threadline.verify_topology"],
      "verify.example": &verify_example/1,
      "verify.bench": &verify_bench/1,
      "verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
      "ci.all": [
        "verify.format",
        "verify.credo",
        "compile --warnings-as-errors",
        "verify.compile_no_optional",
        "verify.test",
        "verify.threadline",
        "verify.example",
        "verify.doc_contract"
      ]
    ]
  end

  defp verify_bench(_args) do
    cmd =
      "bash -lc 'set -euo pipefail && cd bench && mix deps.get && MIX_ENV=test mix run scripts/seed_audit_changes.exs && MIX_ENV=test mix run audit_capture_bench.exs && MIX_ENV=test mix run timeline_query_bench.exs && MIX_ENV=test mix run redaction_and_changed_from_bench.exs'"

    case Mix.shell().cmd(cmd) do
      0 -> :ok
      status -> Mix.raise("verify.bench failed (#{status})")
    end
  end

  defp verify_release(_args) do
    ensure_clean_tree!()

    [
      "bin/verify-release-shape",
      "mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs",
      "MIX_ENV=dev mix docs",
      "mix hex.build"
    ]
    |> Enum.each(&run_release_step!/1)
  end

  defp verify_example(_args) do
    # Decline interactive Hex re-auth when nested `mix deps.get` runs without cached Hex token.
    cmd =
      "bash -lc 'set -euo pipefail && cd examples/threadline_phoenix && printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create --quiet -r ThreadlinePhoenix.Repo && mix test'"

    case Mix.shell().cmd(cmd, env: [{"MIX_ENV", "test"}]) do
      0 -> :ok
      status -> Mix.raise("verify.example failed (#{status})")
    end
  end

  defp ensure_clean_tree! do
    case Mix.shell().cmd("git diff --quiet HEAD --") do
      0 ->
        :ok

      _ ->
        Mix.raise(
          "verify.release requires a clean working tree so the validated artifact matches the taggable tree"
        )
    end
  end

  defp run_release_step!(command) do
    cmd = "bash -lc 'set -euo pipefail && #{command}'"

    case Mix.shell().cmd(cmd) do
      0 -> :ok
      status -> Mix.raise("verify.release failed while running #{command} (#{status})")
    end
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
        "guides/performance.md",
        "guides/domain-reference.md",
        "guides/operator-surface.md",
        "guides/upgrade-path.md",
        "guides/brownfield-continuity.md",
        "guides/production-checklist.md",
        "guides/incident-playbook.md",
        "guides/getting-started-saas.md",
        "guides/adoption-pilot-backlog.md",
        "guides/audit-indexing.md",
        "guides/integrations/sigra.md",
        "CONTRIBUTING.md",
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Overview: ~r/README/,
        Integrations: ~r{^guides/integrations/},
        Reference: ~r{^guides/},
        Project: ~r/(CONTRIBUTING|CHANGELOG)/
      ],
      groups_for_modules: [
        "Core API": [
          Threadline,
          Threadline.Export,
          Threadline.Retention,
          Threadline.Retention.Policy,
          Threadline.Semantics.ActorRef,
          Threadline.Semantics.AuditContext
        ],
        Integration: [
          Threadline.Plug,
          Threadline.Job,
          Threadline.Health,
          Threadline.Continuity,
          Threadline.Telemetry
        ],
        Integrations: [
          Threadline.Integrations.Sigra
        ],
        "Operator Surface": [
          Threadline.OperatorSurface.Router,
          Threadline.OperatorSurface.Auth
        ],
        Schemas: [
          Threadline.Semantics.AuditAction,
          Threadline.Capture.AuditTransaction,
          Threadline.Capture.AuditChange
        ],
        "Mix Tasks": [
          Mix.Tasks.Threadline.Install,
          Mix.Tasks.Threadline.Gen.Triggers,
          Mix.Tasks.Threadline.VerifyCoverage,
          Mix.Tasks.Threadline.Continuity,
          Mix.Tasks.Threadline.Retention.Purge,
          Mix.Tasks.Threadline.Export,
          Mix.Tasks.Threadline.Incident,
          Mix.Tasks.Threadline.VerifyTopology
        ]
      ]
    ]
  end
end
