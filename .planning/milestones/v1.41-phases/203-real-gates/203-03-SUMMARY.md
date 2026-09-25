---
phase: 203-real-gates
plan: 03
subsystem: code quality / credo gate
status: complete
tags: [gate-01, gate-02, credo, alias-usage, mechanical-sweep]
requires: [203-02]
provides:
  - "0 Design.AliasUsage findings in lib/ and in *_contract_test.exs under Credo full defaults"
affects: [203-04, 203-05, 203-06, 203-07]
tech-stack:
  added: []
  patterns:
    - "One refactor commit per file for mechanical Credo sweeps (blame-ignorable)"
    - "Alias only Credo-flagged code references; interpolations inside sigils count as code, the surrounding string data is never edited"
key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.incident.ex
    - lib/threadline/continuity.ex
    - lib/threadline/evidence/proof.ex
    - lib/threadline/export/cleanup_task.ex
    - lib/threadline/export_queue/oban.ex
    - lib/threadline/export_queue/task_adapter.ex
    - lib/threadline/health.ex
    - lib/threadline/health/coverage_schemas.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/retention/pruner.ex
    - test/threadline/adoption_pilot_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - test/threadline/operator_surface/exports_doc_contract_test.exs
    - test/threadline/operator_surface/policy_show_doc_contract_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
decisions:
  - "Pre-existing AliasOrder findings in timeline_live.ex and copy_contract_test.exs were absorbed by the rewritten alias blocks; Plan 06 expects one fewer lib AliasOrder site and Plan 07 one fewer test site"
  - "Unflagged same-module references in the same scope (auth.ex %ActorRef{} pattern, timeline_live.ex from(v in SavedView)) were shortened along with the flagged ones so an alias is never half-applied inside one module"
metrics:
  duration: 15min
  completed: 2026-09-22
  tasks: 2
  files: 22
commits: 22
plan_head_before: 79b002a25b29568485fcf7d6f049b32093dba4d5
actuals:
  tokens: 7300
  tasks: 2
  commits: 22
---

# Phase 203 Plan 03: AliasUsage sweep in lib/ and contract tests Summary

The 53 `Design.AliasUsage` findings in `lib/` (24 across 12 files) and in `*_contract_test.exs` (29 across 10 files) are now fixed. There are 22 single-file `refactor(203-03)` commits, with no config change and no `credo:disable` comment.

Plan base SHA: `79b002a25b29568485fcf7d6f049b32093dba4d5` (also stored in the git dir as `gsd-203-03-base`).

## Counts (measured live with `mix credo --strict --config-file deps/credo/.credo.exs --format json`)

| Measure | Before | After |
|---------|--------|-------|
| AliasUsage, all | 356 | 303 |
| AliasUsage, lib/ | 24 | 0 |
| AliasUsage, *_contract_test.exs | 29 | 0 |
| AliasOrder, all | 11 | 9 |
| Total findings | 484 | 429 |

Remaining AliasUsage: 303, owned by Plans 04 and 05.

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | Alias sweep in 12 lib files | 5cce5915, 50a3105c, ff1e2972, 4f9180b5, 41ecf0fa, bad65243, f7a348ff, be53ee18, dff51f7f, 3bccea12, c0e97e16, cac01506 | 12 lib files, one per commit |
| 2 | Alias sweep in 10 contract tests | 4c920206, 5f7ab174, 363e0c7f, 0111d1a3, 94cb0cbd, da0f13cb, f62d6002, cc0b89eb, 7e00059d, 64a82c81 | 10 contract tests, one per commit |

### Commit SHA list (future `.git-blame-ignore-revs` candidates; not committed here)

```
5cce5915 lib/mix/tasks/threadline.incident.ex
50a3105c lib/threadline/continuity.ex
ff1e2972 lib/threadline/evidence/proof.ex
4f9180b5 lib/threadline/export/cleanup_task.ex
41ecf0fa lib/threadline/export_queue/oban.ex
bad65243 lib/threadline/export_queue/task_adapter.ex
f7a348ff lib/threadline/health.ex
be53ee18 lib/threadline/health/coverage_schemas.ex
dff51f7f lib/threadline/operator_surface/auth.ex
3bccea12 lib/threadline/retention/pruner.ex
c0e97e16 lib/threadline/operator_surface/live/timeline_live.ex
cac01506 lib/threadline/operator_surface/style.ex
4c920206 test/threadline/adoption_pilot_doc_contract_test.exs
5f7ab174 test/threadline/getting_started_saas_doc_contract_test.exs
363e0c7f test/threadline/operator_surface_doc_contract_test.exs
0111d1a3 test/threadline/readme_doc_contract_test.exs
94cb0cbd test/threadline/release_artifact_contract_test.exs
da0f13cb test/threadline/operator_surface/policy_show_doc_contract_test.exs
f62d6002 test/threadline/operator_surface/coverage_doc_contract_test.exs
cc0b89eb test/threadline/operator_surface/exports_doc_contract_test.exs
7e00059d test/threadline/operator_surface/copy_contract_test.exs
64a82c81 test/threadline/operator_surface/rendered_output_contract_test.exs
```

Each commit touches exactly one file (`git show --stat`: 22 of 22 commits have a single file).

## Aliases introduced

- `Ecto.Adapters.SQL` as `SQL`: continuity.ex, cleanup_task.ex, health.ex, coverage_schemas.ex, pruner.ex
- `Threadline.Semantics.ActorRef`: threadline.incident.ex, proof.ex, auth.ex (timeline_live.ex already had it)
- `Threadline.Export.Orchestrator`: oban.ex (inside `ObanWorker`), task_adapter.ex
- `Threadline.Governance.ExportJob` and `Threadline.Governance.SavedView`: timeline_live.ex
- `Threadline.OperatorSurface.Fonts`: style.ex
- `Mix.Tasks.Release.Pins`: 5 doc-contract tests (the only code is the `#{...}` interpolation inside the `~s` pin; the literal text is unchanged)
- `Mix.Tasks.Threadline.Policy.Show`, `Mix.Tasks.Threadline.Health.Coverage`, `Threadline.OperatorSurface.Exports.Filename`: the matching doc-contract tests
- `...CopyContractTest.Auth` and `...RenderedOutputContractTest.Auth` inside each nested `Router` module (the `scope "/"` has no alias prefix, so resolution is unchanged; each file's own tests pass)
- copy_contract_test.exs: `Threadline.Capture.AuditChange`, `Threadline.Capture.AuditTransaction`, and `Threadline.Test.Repo` are now explicit (they match the aliases `use Threadline.DataCase` already injects). The existing `Presentation` alias now covers line 291.
- rendered_output_contract_test.exs: `Threadline.OperatorSurface.StressFixtures` and `Threadline.OperatorSurface.Style`

**`as:` names chosen:** none. No short name collided in scope.

## Pre-existing AliasOrder sites absorbed

- `lib/threadline/operator_surface/live/timeline_live.ex:16`: the block was rewritten into full alphabetical order. Plan 06's lib AliasOrder count drops by one.
- `test/threadline/operator_surface/copy_contract_test.exs:95`: the block was rewritten (`Presentation`, `UI`, `Unsupported` order). Plan 07's test AliasOrder count drops by one.

AliasOrder sites still open (9): lib `threadline.ex`, `coverage_live.ex`, `export_status_live.ex`, `retention_history_live.ex`, `start_live.ex`; test `support/data_case.ex`, `support/storage_schema_case.ex`, `export_queue/task_adapter_test.exs`, `storage_schema_integration_test.exs`.

## Verification

- `mix compile --force --warnings-as-errors`: clean (106 files)
- Task 1 jq gate (lib AliasUsage == 0): `true`
- Task 1 test set (style_contract, timeline_live, health, cleanup, oban, pruner, auth): 159 tests, 0 failures
- Per-file tests run before each commit included incident_test (4), continuity_brownfield (6), proof_test (5), task_adapter_test (4), health_test plus public_surface_contract (50), style, brandbook, component, rendered_output and stress_router (108), and timeline_live plus the exports, timeline_browse and release_artifact contracts (118). All had 0 failures.
- Task 2 test set (10 contract files): 171 tests, 0 failures, 0 compile warnings
- Task 2 jq gate (lib and contract AliasUsage == 0, and no AliasOrder outside the pre-existing set): `true`
- `mix verify.format`: exit 0
- `grep -rnE "credo:(disable|enable)" lib test`: no output
- Full `mix test`: 1699 tests, 1 failure, 1 excluded. See the environmental note below.

## Deviations from Plan

**1. [Rule 1 - consistency] Shortened unflagged same-scope references to the newly aliased module**
- **Found during:** Task 1
- **Issue:** Credo flagged only some references. `%Threadline.Semantics.ActorRef{}` (auth.ex:126) and `from(v in Threadline.Governance.SavedView` (timeline_live.ex:52) were left fully qualified in the same module that now aliases the name.
- **Fix:** Shortened them in the same per-file commit. This is still a pure alias change with no behavior change.
- **Commits:** dff51f7f, c0e97e16

No other deviations.

## Environmental note (not caused by this plan)

`Threadline.CleanCheckoutContractTest` "committed checkout verifier ..." (test/threadline/clean_checkout_contract_test.exs:255) hit its 120 s `@tag timeout` in the full run and again in isolation. Running `bin/verify-clean-checkout` directly exits 0 and prints `CLEAN_CHECKOUT_VERIFIED`, but takes 2m14s at 5% CPU. The time goes to a network-bound `deps.get` in a fresh clone, so this is fetch latency, not a code defect. The plan touched no file involved in that verifier.

## Threat model

- T-203-08: only Credo-flagged code references were aliased. Each contract file got its own commit and its own test run, and no string, heredoc or sigil literal text changed.
- T-203-09: there is no `.credo.exs` change and no `credo:disable`. The gate was measured against upstream defaults.
- T-203-10: auth.ex has alias-only edits, and auth_test passed with 30 tests and 0 failures.

## Self-Check: PASSED

All 22 commits exist in `git log 79b002a2..HEAD`, and all 22 modified files exist.
