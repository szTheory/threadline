defmodule Threadline.MixProject do
  use Mix.Project

  @version "0.9.0"
  @source_url "https://github.com/szTheory/threadline"

  def cli do
    # Run the whole CI chain in :test so `test` picks up config/test.exs (Postgres, repo).
    # Topology tasks need `test/support` (Threadline.Test.Repo) on the compile path.
    [
      preferred_envs: [
        "ci.all": :test,
        "verify.doc_contract": :test,
        "verify.release": :dev,
        "verify.test": :test,
        # `test.reset` runs `ecto.drop -r Threadline.Test.Repo`, and that repo only
        # exists on the :test compile path (see elixirc_paths/1) — without this it
        # fails with `Could not load Threadline.Test.Repo, error: :nofile`.
        "test.reset": :test,
        "test.setup": :test,
        "verify.mechanical": :test,
        "verify.critic_trust": :test,
        "verify.capture": :test,
        "verify.topology": :test,
        "threadline.verify_topology": :test,
        "verify.example": :test,
        "verify.hex_evaluator": :test
      ]
    ]
  end

  def project do
    [
      app: :threadline,
      version: @version,
      # Support contract: Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current,
      # PostgreSQL 14 min / 16 current. The floor is honored by the CI `min` lane (full
      # suite on 1.15/OTP26/PG14) — NOT by raising this requirement. Do not bump "~> 1.15"
      # to a newer minor: that would strand 1.15 adopters (D-14).
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
      extra_applications: [:logger],
      mod: {Threadline.Application, []}
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
      {:oban, "~> 2.15", optional: true},
      {:ex_aws, "~> 2.4", optional: true},
      {:ex_aws_s3, "~> 2.4", optional: true},
      {:hackney, "~> 1.18", optional: true},
      {:sweet_xml, "~> 0.7", optional: true},
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
      "verify.doc_contract": [
        "test test/threadline/readme_doc_contract_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/audit_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/evaluating_threadline_doc_contract_test.exs test/threadline/adoption_evidence_playbook_doc_contract_test.exs test/threadline/release_distribution_doc_contract_test.exs test/threadline/evidence_cli_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/semver_adopter_doc_contract_test.exs test/threadline/integrations/phx_gen_auth_doc_contract_test.exs test/threadline/production_checklist_doc_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/forward_only_gate_doc_contract_test.exs"
      ],
      "verify.release": &verify_release/1,
      "verify.topology": ["threadline.verify_topology"],
      "verify.example": &verify_example/1,
      "verify.example_browser": &verify_example_browser/1,
      "verify.example_browser_light": &verify_example_browser_light/1,
      "verify.operator_stress": &verify_operator_stress/1,
      # Deterministic mechanical gate (Phase 194, MECH-03). Pure-Elixir arithmetic over
      # the committed Tier A scorecard JSON — NO browser, NO network, NO LLM. A MODE-A
      # violation or MODE-B ratchet regression blocks the change. Folded into ci.all
      # BEFORE verify.example_browser (fail fast, no browser cost).
      "verify.mechanical": ["test test/threadline/operator_surface/mechanical_checker_test.exs"],
      # Critic trust gate (Phase 195, CRITIC-03). Pure-Elixir guard over the committed
      # design-system-ledger.json critic_trust block and golden-set.json — NO browser,
      # NO network, NO LLM. Asserts validated lenses meet the bar; seeds validated:false
      # until Plan 04 lands the real α gate. Folded into ci.all BEFORE verify.mechanical.
      "verify.critic_trust": ["test test/threadline/operator_surface/critic_trust_test.exs"],
      # Local-only adversarial critic runner (Phase 195, RUNNER-04). Requires ANTHROPIC_API_KEY
      # (maintainer-local only — never committed, never in CI). Excluded from ci.all (same
      # precedent as verify.flake). When ANTHROPIC_API_KEY is absent, exits 0 with a skip
      # message so contributors without a key are unaffected. See CONTRIBUTING.md.
      "verify.ui_critique": &verify_ui_critique/1,
      "verify.capture": &verify_capture/1,
      "verify.phase177_uat": &verify_phase177_uat/1,
      "verify.hex_evaluator": &verify_hex_evaluator/1,
      "verify.bench": &verify_bench/1,
      "verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
      # Flake detection: re-run the suite until a failure surfaces (each repeat
      # uses a fresh seed). Opt-in / nightly — not part of `ci.all` so per-PR CI
      # stays fast. See the "Deterministic tests" section in CONTRIBUTING.md.
      "verify.flake": ["test --repeat-until-failure 50"],
      # Prepare a fresh clone's test environment, then run the suite (Phase 198, D-04).
      # The example app's deps are fetched because the library suite itself shells into
      # examples/threadline_phoenix (test/threadline/operator_surface/stress_router_test.exs)
      # and cannot boot that router without them. Everything else the suite needs —
      # creating and migrating the test database — test/test_helper.exs already does.
      "test.setup": ["cmd --cd examples/threadline_phoenix mix deps.get", "test"],
      # Restore a recreate-by-default posture (Phase 198, D-04). Threadline's effective
      # default is --keepdb with NO staleness check, which is exactly how a database
      # predating the storage-schema migration produced ~81 misleading failures. Only the
      # drop is needed here: test/test_helper.exs already calls storage_up/1 and runs the
      # migrator on the next run, and its D-03 tripwire catches the stale case.
      "test.reset": ["ecto.drop --quiet -r Threadline.Test.Repo", "test.setup"],
      "ci.all": [
        "verify.format",
        "verify.credo",
        "compile --warnings-as-errors",
        "verify.compile_no_optional",
        "verify.test",
        "verify.threadline",
        "verify.example",
        "verify.doc_contract",
        # Deterministic critic trust gate (reads committed ledger + golden JSON, no browser, no LLM).
        # Runs BEFORE verify.mechanical so a ratchet tamper or lens-trust gap fails fast.
        "verify.critic_trust",
        # Deterministic mechanical gate (reads committed scorecard JSON, no browser).
        # Runs BEFORE the browser lane so a token/contrast/ratchet violation fails fast.
        "verify.mechanical",
        # Browser e2e last (slowest; needs Node + Playwright) so `mix ci.all`
        # locally runs the same gate CI does, including the operator surface.
        "verify.example_browser"
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

  defp verify_example_browser(args) do
    script = Path.expand("examples/threadline_phoenix/e2e/run-e2e.sh")

    env =
      System.get_env()
      |> Enum.map(fn {k, v} -> {k, v} end)
      |> Kernel.++([
        {"DB_HOST", System.get_env("DB_HOST") || "localhost"},
        {"DB_PORT", System.get_env("DB_PORT") || "5432"},
        {"THREADLINE_E2E", "1"}
      ])

    case System.cmd("bash", [script | args], env: env, into: IO.stream(:stdio, :line)) do
      {_output, 0} -> :ok
      {_output, status} -> Mix.raise("verify.example_browser failed (#{status})")
    end
  end

  # Light-lane affordance proof (Phase 168, A11Y-02 part 2). Sets
  # THREADLINE_E2E_THEME=system so run-e2e.sh recompiles the example operator
  # mount to the :system lane and runs ONLY the colorScheme:"light" project
  # (scoped to operator-accessibility.spec.ts) — proving the affordances are
  # mode-independent under the light branch. The default (dark) browser lane
  # stays `verify.example_browser`.
  defp verify_example_browser_light(args) do
    script = Path.expand("examples/threadline_phoenix/e2e/run-e2e.sh")

    env =
      System.get_env()
      |> Enum.map(fn {k, v} -> {k, v} end)
      |> Kernel.++([
        {"DB_HOST", System.get_env("DB_HOST") || "localhost"},
        {"DB_PORT", System.get_env("DB_PORT") || "5432"},
        {"THREADLINE_E2E", "1"},
        {"THREADLINE_E2E_THEME", "system"}
      ])

    case System.cmd("bash", [script | args], env: env, into: IO.stream(:stdio, :line)) do
      {_output, 0} -> :ok
      {_output, status} -> Mix.raise("verify.example_browser_light failed (#{status})")
    end
  end

  # Source contract: defp verify_operator_stress(args), do: verify_example_browser(["operator-stress.spec.ts" | args])
  defp verify_operator_stress(args),
    do: verify_example_browser(["operator-stress.spec.ts" | args])

  # Tier A deterministic capture-lane regeneration (Phase 194, MECH-04). Runs BOTH
  # theme projects so a single `mix verify.capture` reproduces all 120 committed
  # scorecards (66 Band-1 + 54 Band-2). Local-only regeneration — deliberately NOT
  # in ci.all (CI gates the committed scorecard JSON via verify.mechanical, Plan 03).
  defp verify_capture(args),
    do:
      verify_example_browser([
        "--project=tier-a-capture",
        "--project=tier-a-capture-light",
        "operator-tier-a-capture.spec.ts" | args
      ])

  # Targeted runner for the Phase 177 UAT browser spec (viewport reflow + motion +
  # reconnect CSS contract). Convenience for local runs; CI runs it as part of the
  # full verify.example_browser suite (and verify.example_browser_light for the
  # light/system theme lane). Mirrors verify.operator_stress.
  defp verify_phase177_uat(args),
    do: verify_example_browser(["operator-phase-177-uat.spec.ts" | args])

  # Local-only adversarial critic runner (Phase 195, RUNNER-04).
  # Requires ANTHROPIC_API_KEY (maintainer-local; never CI).
  # When the key is absent (empty or unset), prints a skip notice and returns :ok
  # so `mix verify.ui_critique` exits 0 on any contributor machine. See CONTRIBUTING.md.
  # NOT in ci.all — the same local-only precedent as verify.flake.
  defp verify_ui_critique(args) do
    case System.get_env("ANTHROPIC_API_KEY") do
      key when is_nil(key) or key == "" ->
        IO.puts(
          "mix verify.ui_critique: ANTHROPIC_API_KEY not set — skipping (local-only, requires maintainer key)"
        )

        :ok

      _key ->
        e2e_dir = Path.expand("examples/threadline_phoenix/e2e")

        env =
          System.get_env()
          |> Enum.map(fn {k, v} -> {k, v} end)

        # `--` separates npm's own args from the ones forwarded to run.ts. Without it
        # npm v7+ swallows leading `--flags` (e.g. --dry-run, --page, --golden) as its
        # own config instead of forwarding them to the score subcommand.
        case System.cmd("npm", ["run", "critic:score", "--" | args],
               cd: e2e_dir,
               env: env,
               into: IO.stream(:stdio, :line)
             ) do
          {_output, 0} -> :ok
          {_output, status} -> Mix.raise("verify.ui_critique failed (#{status})")
        end
    end
  end

  defp verify_hex_evaluator(_args) do
    cmd =
      "bash -lc 'set -euo pipefail && cd priv/ci/hex_evaluator && printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create --quiet -r HexEvaluator.Repo && mix ecto.migrate --quiet && mix test'"

    case Mix.shell().cmd(cmd, env: [{"MIX_ENV", "test"}]) do
      0 -> :ok
      status -> Mix.raise("verify.hex_evaluator failed (#{status})")
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
      keywords: ["audit", "phoenix", "ecto", "postgres", "history", "security", "telemetry"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/#{doc_source_ref()}/CHANGELOG.md"
      },
      files:
        ~w(lib priv/fonts guides brandbook/favicon.svg .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
    ]
  end

  defp docs do
    [
      main: "Threadline",
      source_ref: doc_source_ref(),
      source_url: @source_url,
      favicon: "brandbook/favicon.svg",
      before_closing_head_tag: &before_closing_head_tag/1,
      before_closing_body_tag: &before_closing_body_tag/1,
      extras: [
        "README.md",
        "guides/how-threadline-works.md",
        "guides/code-walkthrough.md",
        "guides/integration-contracts.md",
        "guides/performance.md",
        "guides/domain-reference.md",
        "guides/operator-surface.md",
        "guides/upgrade-path.md",
        "guides/brownfield-continuity.md",
        "guides/production-checklist.md",
        "guides/incident-playbook.md",
        "guides/getting-started-saas.md",
        "guides/adoption-pilot-backlog.md",
        "guides/adoption-evidence-playbook.md",
        "guides/evaluating-threadline.md",
        "guides/local-docker-dx.md",
        "guides/audit-indexing.md",
        "guides/integrations/sigra.md",
        "guides/integrations/phx-gen-auth.md",
        "CONTRIBUTING.md",
        "CHANGELOG.md"
      ],
      # Routing sidebar lanes (Phase 191, D-191-16). Intent VERBS — the sidebar
      # lane names equal the README `## Start here` intent columns. Order is
      # load-bearing: ExDoc groups each extra by FIRST matching regex, so
      # Overview (README) and Integrations (guides/integrations/**) precede the
      # verb lanes to keep the two integration guides out of a verb lane. Each
      # lane uses an explicit per-file regex (not a greedy `^guides/`); every one
      # of the 21 extras lands in exactly one lane.
      groups_for_extras: [
        Overview: ~r/README/,
        Integrations: ~r{^guides/integrations/},
        Evaluate:
          ~r{^guides/(evaluating-threadline|how-threadline-works|code-walkthrough|domain-reference)\.md$},
        Adopt:
          ~r{^guides/(getting-started-saas|production-checklist|brownfield-continuity|integration-contracts|local-docker-dx|upgrade-path)\.md$},
        Operate:
          ~r{^guides/(operator-surface|incident-playbook|performance|audit-indexing|adoption-evidence-playbook)\.md$},
        Contribute: ~r{^(CONTRIBUTING|CHANGELOG)\.md$|^guides/adoption-pilot-backlog\.md$}
      ],
      groups_for_modules: [
        "Core API": [
          Threadline,
          Threadline.Audit,
          Threadline.ChangeDiff,
          Threadline.Export,
          Threadline.Investigation,
          Threadline.Query,
          Threadline.Retention,
          Threadline.Retention.Policy,
          Threadline.Semantics.ActorRef,
          Threadline.Semantics.AuditContext
        ],
        Evidence: [
          Threadline.Evidence,
          Threadline.Evidence.Proof,
          Threadline.Evidence.Subject
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
        "Operator Surface (Optional In-Tree)": [
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
          Mix.Tasks.Threadline.VerifyTopology,
          Mix.Tasks.Threadline.Evidence.Show,
          Mix.Tasks.Threadline.Health.Coverage,
          Mix.Tasks.Threadline.Policy.Show
        ]
      ]
    ]
  end

  defp before_closing_head_tag(:html) do
    """
    <style>
      .threadline-mermaid {
        margin: 1.5rem 0;
        max-width: 100%;
        overflow-x: auto;
        text-align: center;
      }

      .threadline-mermaid svg {
        display: inline-block;
        height: auto;
        max-width: 100%;
      }

      body.dark .threadline-mermaid {
        color-scheme: dark;
      }
    </style>
    """
  end

  defp before_closing_head_tag(:epub), do: ""

  defp before_closing_body_tag(:html) do
    """
    <script id="threadline-mermaid-script"
            defer
            src="https://cdn.jsdelivr.net/npm/mermaid@11.16.0/dist/mermaid.min.js"
            integrity="sha384-T/0lMUdJpd2S1ZHtRiofG3htU3xPCrFVeAQ1UUE2TJwlEJSV5NUwn30kP28n238E"
            crossorigin="anonymous"></script>
    <script>
      (() => {
        let graphSequence = 0;
        let renderQueue = Promise.resolve();

        const currentTheme = () =>
          document.body.classList.contains("dark") ? "dark" : "default";

        const renderDiagrams = async () => {
          if (!window.mermaid) return;

          const theme = currentTheme();

          window.mermaid.initialize({
            startOnLoad: false,
            securityLevel: "strict",
            theme,
            darkMode: theme === "dark"
          });

          const diagrams = document.querySelectorAll("pre > code.mermaid");

          for (const code of diagrams) {
            const sourceBlock = code.parentElement;
            const source = sourceBlock.dataset.threadlineMermaidSource || code.textContent;
            const rendered = sourceBlock.nextElementSibling;

            sourceBlock.dataset.threadlineMermaidSource = source;

            if (
              sourceBlock.dataset.threadlineMermaidTheme === theme &&
              rendered?.classList.contains("threadline-mermaid")
            ) {
              continue;
            }

            if (rendered?.classList.contains("threadline-mermaid")) rendered.remove();
            sourceBlock.hidden = false;

            try {
              const id = `threadline-mermaid-${++graphSequence}`;
              const {svg, bindFunctions} = await window.mermaid.render(id, source);
              const container = document.createElement("div");

              container.className = "threadline-mermaid";
              container.dataset.mermaidTheme = theme;
              container.innerHTML = svg;
              sourceBlock.after(container);
              if (bindFunctions) bindFunctions(container);

              sourceBlock.dataset.threadlineMermaidTheme = theme;
              sourceBlock.hidden = true;
            } catch (error) {
              sourceBlock.hidden = false;
              console.warn("Threadline docs could not render a Mermaid diagram", error);
            }
          }
        };

        const scheduleRender = () => {
          renderQueue = renderQueue.then(renderDiagrams, renderDiagrams);
        };

        window.addEventListener("exdoc:loaded", scheduleRender);

        const mermaidScript = document.getElementById("threadline-mermaid-script");
        mermaidScript.addEventListener("load", scheduleRender);

        if (document.readyState === "loading") {
          document.addEventListener("DOMContentLoaded", scheduleRender, {once: true});
        } else {
          scheduleRender();
        }

        new MutationObserver((mutations) => {
          if (mutations.some((mutation) => mutation.attributeName === "class")) {
            scheduleRender();
          }
        }).observe(document.body, {attributes: true, attributeFilter: ["class"]});
      })();
    </script>
    """
  end

  defp before_closing_body_tag(:epub), do: ""
end
