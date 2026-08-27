# Credo full-default histogram and per-file concentration (GREEN-02)

**Captured:** 2026-08-27
**Captured by:** Phase 198 Plan 01, Task 2
**Purpose:** size Phase 203 (GATE-01 / GATE-02) — how much work is actually behind
"turn the credo gate on for real". This artifact is a **measurement**, not a gate. Per
DECOUPLE-01, no CI gate may ever read it.

## Header — the measurement conditions

| Field | Value |
|---|---|
| Credo version | `1.7.18` (`mix credo --version`) |
| Config source (measurement) | `/tmp/198-full-default.credo.exs` — **outside the repository working tree** |
| Config source (baseline) | the repo's own `.credo.exs` |
| Baseline issue count (`baseline_count`) | **0** |
| Full-default issue count | **377** |
| Full-default > baseline? | **Yes — 377 > 0.** The `--config-file` flag was honored. |
| Baseline command | `mix credo --strict --format json` (exit 0) |
| Measurement command | `mix credo --strict --config-file /tmp/198-full-default.credo.exs --format json` (exit 30) |
| Raw JSON artifact | `.planning/audits/198-credo-full-default.json` |
| `.credo.exs` content hash before | `a5f0e0df907a7ca5c57ab777b8a49a43bcd5cef3` |
| `.credo.exs` content hash after | `a5f0e0df907a7ca5c57ab777b8a49a43bcd5cef3` (identical) |
| `git diff --exit-code .credo.exs` | exits **0** |
| Distinct files with at least one finding | 99 |

### `baseline_count` is zero, and that is the finding

The repo's `.credo.exs` enables exactly two checks:

```elixir
checks: %{
  enabled: [
    {Credo.Check.Readability.ModuleDoc, []},
    {Credo.Check.Design.TagTODO, [exit_status: 0]}
  ]
}
```

`enabled:` **replaces** Credo's default check set rather than adding to it, so the
`Run Credo (strict)` CI lane runs 2 checks, not 108 — and both currently find nothing
(`TagTODO` additionally carries `exit_status: 0`, so it could not fail the build even if
it did fire). A green credo lane on `origin/main` is therefore not evidence of code
quality. `baseline_count = 0` is the numeric statement of that vacuity.

### How the external config was produced (and why `.credo.exs` was never touched)

`mix credo.gen.config` writes to `.credo.exs` **in the current working directory** and
refuses to overwrite an existing file. It was invoked once from the repository root to
confirm that behavior; it printed:

```
File exists: .credo.exs, aborted.
```

and wrote nothing (`git diff --exit-code .credo.exs` exits 0 immediately after; content
hash unchanged).

The stock full-default template was therefore taken from its own source of truth:
`deps/credo/.credo.exs`, which is the exact file `Credo.CLI.Command.GenConfig` embeds at
compile time (`@default_config_file File.read!(".credo.exs")`,
`deps/credo/lib/credo/cli/command/gen.config.ex:5`). It was copied to
`/tmp/198-full-default.credo.exs` — verified byte-identical, sha256
`c6e520ba4ec015413057fbad1f7ce2af12eac335ab185a5e2ff5e8d07309a105` — and only then edited
in `/tmp`:

- `strict: false` → `strict: true`
- `included:` narrowed to `["lib/", "test/", "config/"]`
- `excluded:` gained `~r"/examples/"` alongside the stock `/_build/`, `/deps/`, `/node_modules/`

**Scope caveat, stated so the comparison is not oversold:** the baseline run is scoped to
`lib/` + `test/` (the repo config); the measurement run adds `config/`. `config/`
contributed **0** of the 377 findings, so the scope difference does not affect the
comparison. All 108 default checks are active in the measurement config.

**`--config-file` was passed as a named flag**, never as a bare positional path (a
positional argument to `mix credo` means "analyze only this path" and silently ignores the
intended config — RESEARCH Pitfall 4). The 0 → 377 jump is the executed proof the flag was
honored.

## Per-check histogram (full default, all 377 findings)

`jq '.issues | group_by(.check) | map({check: .[0].check, count: length}) | sort_by(-.count)'`

| Check | Count |
|---|---|
| `Credo.Check.Design.AliasUsage` | 279 |
| `Credo.Check.Refactor.Nesting` | 21 |
| `Credo.Check.Refactor.MapJoin` | 17 |
| `Credo.Check.Refactor.CyclomaticComplexity` | 16 |
| `Credo.Check.Readability.AliasOrder` | 11 |
| `Credo.Check.Readability.PreferImplicitTry` | 6 |
| `Credo.Check.Warning.ExpensiveEmptyEnumCheck` | 6 |
| `Credo.Check.Refactor.NegatedConditionsWithElse` | 5 |
| `Credo.Check.Refactor.RedundantWithClauseResult` | 4 |
| `Credo.Check.Refactor.CondStatements` | 3 |
| `Credo.Check.Readability.StringSigils` | 2 |
| `Credo.Check.Refactor.RejectReject` | 2 |
| `Credo.Check.Readability.MaxLineLength` | 1 |
| `Credo.Check.Readability.ParenthesesOnZeroArityDefs` | 1 |
| `Credo.Check.Readability.WithSingleClause` | 1 |
| `Credo.Check.Refactor.UnlessWithElse` | 1 |
| `Credo.Check.Warning.MissedMetadataKeyInLoggerConfig` | 1 |
| **Total** | **377** |

Only **17 of 108** default checks fire at all. 91 default checks are already clean.

### The same histogram restricted to `lib/` (the shipped library)

| Check | Count |
|---|---|
| `Credo.Check.Design.AliasUsage` | 23 |
| `Credo.Check.Refactor.Nesting` | 19 |
| `Credo.Check.Refactor.CyclomaticComplexity` | 15 |
| `Credo.Check.Refactor.MapJoin` | 12 |
| `Credo.Check.Readability.AliasOrder` | 6 |
| `Credo.Check.Readability.PreferImplicitTry` | 6 |
| `Credo.Check.Refactor.NegatedConditionsWithElse` | 5 |
| `Credo.Check.Refactor.RedundantWithClauseResult` | 4 |
| `Credo.Check.Refactor.CondStatements` | 3 |
| `Credo.Check.Refactor.RejectReject` | 2 |
| `Credo.Check.Warning.ExpensiveEmptyEnumCheck` | 2 |
| `Credo.Check.Readability.ParenthesesOnZeroArityDefs` | 1 |
| `Credo.Check.Readability.WithSingleClause` | 1 |
| `Credo.Check.Warning.MissedMetadataKeyInLoggerConfig` | 1 |
| **Total (`lib/`)** | **100** |

## Sizing implication for Phase 203

Three numbers do most of the work:

- **`Credo.Check.Design.AliasUsage` is 279 of 377 (74%)**, and **256 of those 279 are in
  `test/`** — only 23 are in `lib/`. `AliasUsage` is the most commonly disabled default
  check in Elixir projects precisely because it fires on fully-qualified calls in test
  setup. Disabling it (or scoping the gate to `lib/`) is the single largest lever.
- **Excluding `AliasUsage` leaves 98 findings total, 77 of them in `lib/`.** That is a
  tractable, hand-fixable body of work — not a multi-phase ratchet.
- **`config/` contributes 0.** Widening scope to `config/` is free.

Split by tree:

| Tree | Findings |
|---|---|
| `lib/` | 100 |
| `test/` | 277 |
| `config/` | 0 |
| **Total** | **377** |

Phase 203 does **not** face a 377-item backlog. The honest sizing is: pick a check set,
and the residual is between **77** (`lib/` only, `AliasUsage` off) and **377** (everything
on, everywhere). The `Refactor.*` cluster in `lib/` — `Nesting` 19,
`CyclomaticComplexity` 15, `MapJoin` 12 — is the genuine code-quality signal and is where
a ratchet floor is worth setting.

## Per-file concentration (all 377 findings, 99 files, descending)

`jq '.issues | group_by(.filename) | map({filename: .[0].filename, count: length}) | sort_by(-.count)'`

| File | Count |
|---|---|
| `test/threadline/operator_surface/live/timeline_live_test.exs` | 25 |
| `test/threadline/operator_surface/live/start_live_test.exs` | 20 |
| `test/threadline/operator_surface/live/retention_history_live_test.exs` | 19 |
| `test/threadline/export/cleanup_test.exs` | 16 |
| `test/threadline/health_test.exs` | 15 |
| `test/threadline/operator_surface/transaction_live_test.exs` | 15 |
| `test/threadline/operator_surface/copy_contract_test.exs` | 14 |
| `test/threadline/operator_surface/coverage_mix_test.exs` | 14 |
| `test/threadline/operator_surface/stress_router_test.exs` | 12 |
| `test/threadline/export/orchestrator_test.exs` | 10 |
| `test/threadline/operator_surface/live/row_history_live_test.exs` | 10 |
| `lib/threadline/operator_surface/live/timeline_live.ex` | 9 |
| `test/threadline/storage/s3_test.exs` | 8 |
| `test/threadline/verify_coverage_task_test.exs` | 8 |
| `lib/threadline/operator_surface/live/export_status_live.ex` | 7 |
| `test/mix/tasks/threadline.evidence_show_test.exs` | 7 |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | 7 |
| `test/threadline/export_queue/oban_test.exs` | 6 |
| `test/threadline/operator_surface/live/actor_live_test.exs` | 6 |
| `lib/threadline/operator_surface/auth.ex` | 5 |
| `lib/threadline/operator_surface/exports/filter_params.ex` | 5 |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | 5 |
| `test/threadline/operator_surface/policy_show_mix_test.exs` | 5 |
| `test/threadline/operator_surface/row_history_component_test.exs` | 5 |
| `lib/mix/tasks/threadline.gen.triggers.ex` | 4 |
| `lib/threadline/capture/trigger_sql.ex` | 4 |
| `test/mix/tasks/threadline.incident_test.exs` | 4 |
| `test/threadline/continuity_brownfield_test.exs` | 4 |
| `test/threadline/operator_surface/skip_link_test.exs` | 4 |
| `lib/threadline/export/cleanup_task.ex` | 3 |
| `lib/threadline/export_queue/oban.ex` | 3 |
| `lib/threadline/operator_surface/mechanical_checker.ex` | 3 |
| `lib/threadline/query.ex` | 3 |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | 3 |
| `test/threadline/operator_surface/exports_doc_contract_test.exs` | 3 |
| `test/threadline/operator_surface/exports_mix_parity_test.exs` | 3 |
| `lib/mix/tasks/critic.measure.ex` | 2 |
| `lib/mix/tasks/threadline.incident.ex` | 2 |
| `lib/threadline/audit.ex` | 2 |
| `lib/threadline/critic_trust/krippendorff_alpha.ex` | 2 |
| `lib/threadline/health.ex` | 2 |
| `lib/threadline/health/coverage_schemas.ex` | 2 |
| `lib/threadline/operator_surface/live/stress_live.ex` | 2 |
| `lib/threadline/operator_surface/live/transaction_live.ex` | 2 |
| `lib/threadline/operator_surface/presentation.ex` | 2 |
| `lib/threadline/policy/redaction_presenter.ex` | 2 |
| `lib/threadline/retention/pruner.ex` | 2 |
| `test/support/getting_started_fixtures.ex` | 2 |
| `test/threadline/audit_transaction_test.exs` | 2 |
| `test/threadline/capture/trigger_context_test.exs` | 2 |
| `test/threadline/capture/trigger_test.exs` | 2 |
| `test/threadline/operator_surface/breadcrumb_test.exs` | 2 |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | 2 |
| `test/threadline/operator_surface/refute_partition_test.exs` | 2 |
| `test/threadline/operator_surface/ui_test.exs` | 2 |
| `test/threadline/retention/pruner_test.exs` | 2 |
| `lib/mix/tasks/threadline.evidence.show.ex` | 1 |
| `lib/mix/tasks/threadline.export.ex` | 1 |
| `lib/mix/tasks/threadline.install.ex` | 1 |
| `lib/mix/tasks/threadline.policy.show.ex` | 1 |
| `lib/mix/tasks/threadline.verify_coverage.ex` | 1 |
| `lib/threadline.ex` | 1 |
| `lib/threadline/application.ex` | 1 |
| `lib/threadline/change_diff.ex` | 1 |
| `lib/threadline/continuity.ex` | 1 |
| `lib/threadline/critic_trust/measure.ex` | 1 |
| `lib/threadline/critic_trust/rank_metrics.ex` | 1 |
| `lib/threadline/evidence.ex` | 1 |
| `lib/threadline/evidence/proof.ex` | 1 |
| `lib/threadline/export/orchestrator.ex` | 1 |
| `lib/threadline/export_queue/task_adapter.ex` | 1 |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | 1 |
| `lib/threadline/operator_surface/live/actor_live.ex` | 1 |
| `lib/threadline/operator_surface/live/coverage_live.ex` | 1 |
| `lib/threadline/operator_surface/live/row_history_component.ex` | 1 |
| `lib/threadline/operator_surface/live/start_live.ex` | 1 |
| `lib/threadline/operator_surface/router.ex` | 1 |
| `lib/threadline/operator_surface/session_plug.ex` | 1 |
| `lib/threadline/operator_surface/style.ex` | 1 |
| `lib/threadline/retention.ex` | 1 |
| `lib/threadline/retention/policy.ex` | 1 |
| `lib/threadline/semantics/actor_ref.ex` | 1 |
| `lib/threadline/storage/local.ex` | 1 |
| `test/mix/tasks/threadline/export_test.exs` | 1 |
| `test/support/data_case.ex` | 1 |
| `test/support/storage_schema_case.ex` | 1 |
| `test/support/stress_router_prod_compile.exs` | 1 |
| `test/threadline/dep_floor_guard_test.exs` | 1 |
| `test/threadline/export_queue/task_adapter_test.exs` | 1 |
| `test/threadline/incident_playbook_doc_contract_test.exs` | 1 |
| `test/threadline/operator_surface/auth_test.exs` | 1 |
| `test/threadline/operator_surface/card_nesting_regression_test.exs` | 1 |
| `test/threadline/operator_surface/controllers/export_controller_test.exs` | 1 |
| `test/threadline/operator_surface/data_state_mapping_wave0_test.exs` | 1 |
| `test/threadline/operator_surface/live/export_status_live_test.exs` | 1 |
| `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | 1 |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | 1 |
| `test/threadline/operator_surface/stress_fixtures_test.exs` | 1 |
| `test/threadline/storage_schema_integration_test.exs` | 1 |
| **Total** | **377** |

## Prohibition check

`.credo.exs` was **never modified**, not even temporarily. The external config lived at
`/tmp/198-full-default.credo.exs` for the whole task.

```
$ git diff --exit-code .credo.exs
$ echo $?
0
```
