defmodule ThreadlinePhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :threadline_phoenix,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      hex: [ignore_advisories: Enum.map(hex_audit_ignores(), & &1.id)]
    ]
  end

  def hex_audit_ignores do
    [
      %{
        id: "EEF-CVE-2026-95105",
        reason:
          "cloak 1.1.4 AES-CTR does not authenticate ciphertext, so bit-flipped ciphertext can be accepted. The example stores secrets with AES-GCM and has no CTR reader or legacy CTR data.",
        reachability:
          "test/threadline/cloak_advisory_reachability_contract_test.exs proves the live vault has exactly one AES-GCM cipher with tag AES.GCM.V1 and scans example lib/config/priv sources for CTR readers or legacy ciphertext; the tracked initial vault at b50e51e4 also used GCM.",
        review_by: ~D[2027-01-06]
      },
      %{
        id: "EEF-CVE-2026-94206",
        reason:
          "cloak_ecto 1.3.0 PBKDF2 uses an iteration count that no longer meets the advisory's security guidance. The example's encrypted field uses Cloak.Ecto.Binary and does not derive keys with PBKDF2.",
        reachability:
          "test/threadline/cloak_advisory_reachability_contract_test.exs proves the live encrypted field uses Cloak.Ecto.Binary with ThreadlinePhoenix.Vault and scans example lib/config/priv sources for Cloak.Ecto.PBKDF2.",
        review_by: ~D[2027-01-06]
      }
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ThreadlinePhoenix.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:threadline, path: "../.."},
      {:phoenix, "~> 1.8.5"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:oban, "~> 2.19"},
      {:gettext, "~> 0.26"},
      {:swoosh, "~> 1.16"},
      {:heroicons, "~> 0.5"},
      {:phoenix_storybook, "~> 1.2.0", only: [:dev, :test]},
      {:sigra, "~> 0.2"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "compile", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["test"],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
