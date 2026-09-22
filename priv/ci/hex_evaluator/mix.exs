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
      threadline_dep(),
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"}
    ]
  end

  # Two resolution modes, deliberately kept separate (202 D-07) because they
  # answer different questions:
  #
  #   rehearsal (default) — "does the tree under test install?" `:threadline`
  #     resolves from `threadline_rehearsal`, a throwaway local registry built
  #     by `bin/with-rehearsal-registry` out of THIS tree's `mix hex.build`
  #     tarball. Nothing here ever touches hex.pm, so it is usable as a
  #     PRE-publish gate.
  #
  #   published — "did the thing we just published install?" Set only by
  #     `release.yml` AFTER `mix hex.publish`, resolving the exact version from
  #     hexpm.
  #
  # No threadline version literal lives in this file (D-08). The published
  # requirement is `==`, not `~>`, on purpose: `~> 0.9.0` is precisely what let
  # a stale 0.9.0 keep passing this fixture forever, and `~> 0.10.0` would drift
  # onto 0.10.1 the same way.
  defp threadline_dep do
    case System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal") do
      "rehearsal" ->
        {:threadline, ">= 0.0.0", repo: "threadline_rehearsal"}

      "published" ->
        # fetch_env! — not get_env/2. Published mode must die loudly rather
        # than silently falling back to rehearsing, which would report a green
        # smoke test for a release nobody actually installed.
        {:threadline, "== " <> System.fetch_env!("THREADLINE_PUBLISHED_VERSION"), repo: "hexpm"}

      other ->
        raise """
        THREADLINE_HEX_EVALUATOR_MODE must be "rehearsal" or "published", got: #{inspect(other)}

          rehearsal (default) — resolve :threadline from the local
            threadline_rehearsal registry built by bin/with-rehearsal-registry
          published — resolve the exact THREADLINE_PUBLISHED_VERSION from hexpm
        """
    end
  end
end
