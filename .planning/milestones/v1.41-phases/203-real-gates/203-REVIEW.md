---
phase: 203-real-gates
reviewed: 2026-09-23T00:00:00Z
depth: standard
files_reviewed: 132
files_reviewed_list:
  - .credo.exs
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - guides/adoption-pilot-backlog.md
  - guides/configuration-and-commands.md
  - guides/evaluating-threadline.md
  - lib/mix/tasks/critic.measure.ex
  - lib/mix/tasks/critic.synth.ex
  - lib/mix/tasks/threadline.evidence.show.ex
  - lib/mix/tasks/threadline.export.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/mix/tasks/threadline.incident.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/mix/tasks/threadline.policy.show.ex
  - lib/mix/tasks/threadline.verify_coverage.ex
  - lib/threadline.ex
  - lib/threadline/application.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_change.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/continuity.ex
  - lib/threadline/critic_trust/krippendorff_alpha.ex
  - lib/threadline/critic_trust/measure.ex
  - lib/threadline/critic_trust/rank_metrics.ex
  - lib/threadline/evidence.ex
  - lib/threadline/evidence/proof.ex
  - lib/threadline/export/cleanup_task.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/export_queue/oban.ex
  - lib/threadline/export_queue/task_adapter.ex
  - lib/threadline/health.ex
  - lib/threadline/health/coverage_schemas.ex
  - lib/threadline/integrations/sigra.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/mechanical_checker.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/session_plug.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/query.ex
  - lib/threadline/query/filter_params.ex
  - lib/threadline/query/scope.ex
  - lib/threadline/retention/policy.ex
  - lib/threadline/retention/pruner.ex
  - lib/threadline/semantics/actor_ref.ex
  - lib/threadline/storage/local.ex
  - mix.exs
  - test/mix/tasks/threadline.evidence_show_test.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/mix/tasks/threadline/export_test.exs
  - test/support/data_case.ex
  - test/support/getting_started_fixtures.ex
  - test/support/repo.ex
  - test/support/storage_schema_case.ex
  - test/support/stress_router_prod_compile.exs
  - test/threadline/adoption_pilot_doc_contract_test.exs
  - test/threadline/audit_transaction_test.exs
  - test/threadline/capture/trigger_context_test.exs
  - test/threadline/capture/trigger_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/code_walkthrough_doc_contract_test.exs
  - test/threadline/community_health_render_contract_test.exs
  - test/threadline/continuity_brownfield_test.exs
  - test/threadline/credo_config_contract_test.exs
  - test/threadline/dep_floor_guard_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/export/cleanup_test.exs
  - test/threadline/export/orchestrator_test.exs
  - test/threadline/export_queue/oban_test.exs
  - test/threadline/export_queue/task_adapter_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/health_test.exs
  - test/threadline/how_threadline_works_doc_contract_test.exs
  - test/threadline/incident_playbook_doc_contract_test.exs
  - test/threadline/layer_boundary_contract_test.exs
  - test/threadline/no_warn_undefined_contract_test.exs
  - test/threadline/operator_surface/auth_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/card_nesting_regression_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
  - test/threadline/operator_surface/coverage_mix_test.exs
  - test/threadline/operator_surface/critic_trust_test.exs
  - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/coverage_live_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/policy_redaction_live_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/policy_show_doc_contract_test.exs
  - test/threadline/operator_surface/policy_show_mix_test.exs
  - test/threadline/operator_surface/refute_partition_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
  - test/threadline/operator_surface/row_history_component_test.exs
  - test/threadline/operator_surface/skip_link_test.exs
  - test/threadline/operator_surface/stress_fixtures_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface/ui_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/filter_params_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/retention/pruner_test.exs
  - test/threadline/row_history_focus_evidence_contract_test.exs
  - test/threadline/source_comment_location_contract_test.exs
  - test/threadline/storage/s3_test.exs
  - test/threadline/storage_schema_integration_test.exs
  - test/threadline/verify_coverage_task_test.exs
findings:
  critical: 0
  warning: 2
  info: 7
  total: 9
status: issues_found
---

# Phase 203: Code Review Report

**Reviewed:** 2026-09-23
**Depth:** standard
**Files Reviewed:** 132
**Status:** issues_found

## Summary

I reviewed the full `1ffd1ad0..HEAD` diff for all 132 files, using rename detection for the two module moves. I also ran the gates myself. `mix credo --strict` reported no issues (69 checks, 288 files). `mix verify.xref_cycles` reported "No cycles found". Counting per-site disables gave 26 Nesting and 16 CyclomaticComplexity, which matches `@register`, and each one has a non-empty `# Structural debt:` line directly above it.

**Behavior preservation (lib):** I traced every behavior-bearing rewrite and found no regressions:
- `Threadline.Query.FilterParams` and `Threadline.Query.Scope` are renames only. Apart from the Credo rewrites, the diffs are identical. All callers are retargeted: `Query.maybe_apply_scope/2`, the orchestrator, timeline_live, start_live, export_status_live and export_controller. No stale reference remains in `lib/`, `test/`, `examples/`, `guides/`, `priv/` or `README.md`. The old names survive only in `CHANGELOG.md`, which the `@renamed_modules` exemption covers.
- `collapse_actor_ref/1`: the nested `case` became a `with`/`else`. It still produces the same three results: `:ok`, `unknown actor kind`, and `missing actor id`.
- `Storage.Local.put/2`: `File.cp/2` and `File.write/2` both return `:ok | {:error, _}`, so the `with` fall-through gives the same `{:error, reason}` as before.
- `timeline_filter_context/1`: the new `with`/`else` handles both `{:error, message}` sources the same way the old nested `case` did.
- `transaction_live` `as_of`: nil, `""`, a parse failure and a valid ISO string all map to the same values as before.
- Krippendorff `weighted_sum`: `a*b/c*w` associates left, so the floating-point operation order is unchanged.
- `timeline_live` `page_opts`: it is now computed before `Task.async` instead of inside it. It is still derived from the same immutable socket, so the result is the same.
- `threadline.install`: the priv-path layout change produces the same path.
- The remaining with-clause, PreferImplicitTry (function-level `rescue`) and `cond`→`if` rewrites are equivalent.
- `@compile no_warn_undefined` removal: compile with warnings-as-errors and xref both pass.
- CI: the xref step was added inside the existing matrix job, and no `id:` changed.

**Contract tests:** each one has a non-empty-scan guard and fails closed on a parse error. Two parts of the gate surface are still unpinned, so they could drift silently (WR-01, WR-02). The rest are narrower-than-documented scopes (Info).

## Warnings

### WR-01: The credo config-shape contract does not pin `files:`, `plugins:` or `requires:`, so the gate can still be quietly shrunk

**File:** `test/threadline/credo_config_contract_test.exs:241-253` (and `.credo.exs:21-44`)
**Issue:** The moduledoc says the config is pinned "so the default check set can never be replaced or quietly shrunk". But `project_config/0` is only checked for `strict == true`, the `checks` keys, `disabled == []` and `extra == @deltas`. Other edits to the config still pass every test. For example:
- `files: %{included: ["lib/"]}` drops the whole `test/` tree from the gate.
- `excluded: [~r"/operator_surface/"]` exempts a subtree.
- A `plugins:` entry can inject or alter checks.

None of these touch `enabled:` or `disabled:`, and each one shrinks what the gate lints just as effectively. Per-check `files:` in a delta is already blocked by the exact `@deltas` match. The top-level `files:` is not.
**Fix:** Pin the non-`checks` scaffolding against the upstream file the header already cites:
```elixir
test "non-checks scaffolding equals upstream except strict" do
  {%{configs: [upstream]}, _} = Code.eval_file(@upstream_config)
  config = project_config()
  assert config.files == upstream.files
  assert config.plugins == [] and config.requires == []
  assert config.name == "default"
  assert Map.drop(config, [:checks, :strict]) == Map.drop(upstream, [:checks, :strict])
end
```

### WR-02: The new `mix verify.xref_cycles` CI step is not pinned by any contract test

**File:** `.github/workflows/ci.yml:351-352`; `test/threadline/ci_topology_contract_test.exs:50-55, 90-105`
**Issue:** The topology contract only pins the xref step in `mix.exs`: the alias body and its position inside `ci.all`. GitHub Actions never runs `ci.all`. The `verify-test` job runs its steps one by one. So deleting or `if:`-gating the "Verify no compile-connected xref cycles" step in `ci.yml` would turn off the GATE-04 cycle gate in CI with every test still green. The only remaining protection would be a maintainer running `ci.all` locally. This is the same kind of hole as the "vacuous gate" finding that Phase 203 exists to close.
**Fix:** Add a `ci.yml` assertion that uses the existing `workflow_step/2` helper:
```elixir
test "verify-test job runs the xref cycle gate before the suite" do
  yaml = read_rel!([".github", "workflows", "ci.yml"])
  step = workflow_step(yaml, "Verify no compile-connected xref cycles")
  assert step =~ "run: mix verify.xref_cycles"
  refute step =~ "if:"
  {xref, _} = :binary.match(yaml, "run: mix verify.xref_cycles")
  {tests, _} = :binary.match(yaml, "run: mix verify.test")
  assert xref < tests
end
```

## Info

### IN-01: The source-comment location contract only scans `lib/`, and stale citations remain in reviewed test files

**File:** `test/threadline/source_comment_location_contract_test.exs:20,38-44`; `test/threadline/operator_surface/live/timeline_live_test.exs:1422`; `test/threadline/operator_surface/exports_mix_parity_test.exs:144`
**Issue:** The contract exists to stop comments that cite `file:line`. Two comments in files this phase touched still do it:
- `timeline_live_test.exs:1422` says "The mount/3 helper at timeline_live.ex:30-35 pattern-matches `{:covered, name}`". Those lines are now the mount comment and scope assigns. This phase's alias additions shifted them further.
- `exports_mix_parity_test.exs:144` cites `lib/threadline/export.ex:434`, which is now unrelated transaction-map code.

Scoping to `lib/` matches D-20, but the rationale in the moduledoc applies equally to `test/`.
**Fix:** Widen `@lib_glob` to `{lib,test}/**/*.{ex,exs}`, excluding this file and `credo_config_contract_test.exs`, whose sanity strings are literals and not comments anyway. Rewrite the two comments to cite `TimelineLive.mount/3` and `Threadline.Export` symbols.

### IN-02: The location regex only recognises `.ex` and `.exs`

**File:** `test/threadline/source_comment_location_contract_test.exs:22`
**Issue:** `~r/[A-Za-z0-9_.\/-]+\.exs?:\d+(?:-\d+)?/` does not match `foo.heex:12`, `app.js:40`, `ci.yml:374` or `style.css:10`. It also ignores HEEx `<%!-- --%>` comments inside `~H` sigils, because they are string content. All of these go stale in the same way.
**Fix:** Use `~r/[A-Za-z0-9_.\/-]+\.[a-z]{1,5}:\d+(?:-\d+)?/` and add a detector-sanity case for `.heex` and `.yml`.

### IN-03: The no_warn_undefined contract does not cover `Code.put_compiler_option/2` or non-`lib` sources

**File:** `test/threadline/no_warn_undefined_contract_test.exs:31-63`
**Issue:** The moduledoc promises the suppression "can be removed but never relocated". But `Code.put_compiler_option(:no_warn_undefined, ...)` in `mix.exs`, `config/*.exs` or `test/support/*.ex` has the same effect and is not scanned. Also, `project_options` and `config_options` read the same keyword list, so one of the two loop iterations adds nothing.
**Fix:** Add `mix.exs`, `config/**/*.exs` and `test/support/**/*.ex` to the text scan (the needle is already assembled at runtime). Drop the duplicate `Mix.Project.config()` read.

### IN-04: The layer-boundary contract checks only one inversion direction

**File:** `test/threadline/layer_boundary_contract_test.exs:5-11,55-66`
**Issue:** The moduledoc describes capture, semantics and query/export all sitting under the surface. The test only forbids `OperatorSurface` references from outside the surface. A Capture→Query or Capture→Export dependency, which would be an inversion inside the lower layers, is not guarded. This matches D-15's scope, but the docstring promises more than the test checks.
**Fix:** Narrow the moduledoc to what is actually asserted, or add a second needle set (for example, `lib/threadline/capture/**` must not contain `Threadline.Query` or `Threadline.Export`).

### IN-05: The old module names are no longer refuted in guides

**File:** `test/threadline/code_walkthrough_doc_contract_test.exs:80`; `test/threadline/how_threadline_works_doc_contract_test.exs:78`
**Issue:** Retargeting the refutes to `Threadline.Query.Scope` (D-11) is correct, but it drops the refute of the now-dead `Threadline.OperatorSurface.Scope`. The public-surface reference validator catches dead module names only for the subjects it owns. These two guides are protected only if both are in `reference_subjects`.
**Fix:** Keep both names in each refute list, or assert that both guides are in the public-surface reference subjects.

### IN-06: The `if not x` → `if x` swaps turn a crash on a nil assign into a silent no-op

**File:** `lib/threadline/operator_surface/live/export_status_live.ex:134,407`; `lib/threadline/operator_surface/live/retention_history_live.ex:118,375,386`
**Issue:** `not nil` raises `ArgumentError`, but `if nil` takes the else branch. Before this change, a missing `:threadline_exports_enabled` or `:threadline_policy_enabled` assign crashed the LiveView. Now it silently skips refresh and fetches. `Auth` always assigns both keys as booleans, so this cannot happen in practice today. It is still a semantic change in commits labelled "No behavior change" (D-28).
**Fix:** No code change is needed. Note it in the SUMMARY, or match strictly with `if socket.assigns[:threadline_exports_enabled] == true`.

### IN-07: `transaction_live` `as_of` still crashes on a non-binary param (pre-existing; the flatten was a chance to fix it)

**File:** `lib/threadline/operator_surface/live/transaction_live.ex:59-64`
**Issue:** `?as_of[x]=1` makes `params["as_of"]` a map. The map passes `str not in [nil, ""]`, and then `DateTime.from_iso8601/1` raises `FunctionClauseError`, which crashes the LiveView process. The old nested `case` had the same behavior.
**Fix:** `with str when is_binary(str) and str != "" <- params["as_of"], ...`

---

_Reviewed: 2026-09-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
