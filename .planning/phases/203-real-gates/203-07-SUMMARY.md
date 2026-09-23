---
phase: 203-real-gates
plan: 07
subsystem: code-quality
status: complete
tags: [credo, gate-02, gate-05, contract-test]
requires: [203-06]
provides:
  - "The whole tree has no mechanical Credo findings under full defaults. What remains is Nesting 30, CyclomaticComplexity 16, and the single Logger finding deferred to Plan 10 (D-09)"
  - "Threadline.Test.Repo has @moduledoc false. This was the only finding the Plan 10 ModuleDoc delta would surface"
  - "Threadline.SourceCommentLocationContractTest pins the stale-location half of GATE-05"
affects: [203-09, 203-10]
tech-stack:
  added: []
  patterns:
    - "Source-scan contract over comments only via Code.string_to_quoted_with_comments/1, with a non-empty guard and a detector-sanity test"
key-files:
  created:
    - test/threadline/source_comment_location_contract_test.exs
  modified:
    - test/support/repo.ex
    - test/support/data_case.ex
    - test/support/storage_schema_case.ex
    - test/threadline/community_health_render_contract_test.exs
    - test/threadline/dep_floor_guard_test.exs
    - test/threadline/dialyzer_ignore_contract_test.exs
    - test/threadline/export_queue/task_adapter_test.exs
    - test/threadline/incident_playbook_doc_contract_test.exs
    - test/threadline/operator_surface/auth_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - test/threadline/operator_surface/coverage_mix_test.exs
    - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
    - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
    - test/threadline/operator_surface/refute_partition_test.exs
    - test/threadline/operator_surface/stress_fixtures_test.exs
    - test/threadline/operator_surface/ui_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/retention/pruner_test.exs
    - test/threadline/row_history_focus_evidence_contract_test.exs
    - test/threadline/storage_schema_integration_test.exs
decisions:
  - "StringSigils fixes use ~s with a delimiter that does not appear in the content (| for the bash script lines, () for test names), never ~S. Byte equality was proven by evaluation"
  - "GATE-05 is left unchecked in REQUIREMENTS.md. The moduledoc half is enforced only once Plan 10 wires the ModuleDoc delta, so Plan 10 closes it"
metrics:
  duration: "~6 min"
  completed: 2026-09-22
plan_base: 9bace4f70991aae5af156daf395a140395970daa
plan_head_before: 9bace4f70991aae5af156daf395a140395970daa
actuals:
  tokens: 5300
  tasks: 2
  commits: 15
---

# Phase 203 Plan 07: Test Mechanical Credo Sweep and GATE-05 Contract Summary

This plan fixed the last 24 mechanical Credo findings in test/, across 22 files. `Threadline.Test.Repo` now has `@moduledoc false`. A new comment-only source scan fails whenever a `lib/` comment cites a `name.ex:NN` location. Under Credo's full defaults, the only findings left in the tree are Nesting 30, CyclomaticComplexity 16, and one Logger finding. The Nesting and CyclomaticComplexity sets are the same findings, by file and scope, as before this plan.

Plan base SHA: `9bace4f70991aae5af156daf395a140395970daa` (also recorded in `.git/gsd-203-07-base`).

## Histogram (whole tree, Credo full defaults, `--strict`)

| Check | Before | After |
|---|---|---|
| MapJoin | 6 | 0 |
| AliasOrder | 4 | 0 |
| StringSigils | 4 | 0 |
| ExpensiveEmptyEnumCheck | 4 | 0 |
| FilterFilter | 2 | 0 |
| MaxLineLength | 1 | 0 |
| PreferImplicitTry | 1 | 0 |
| RedundantWithClauseResult | 1 | 0 |
| UnlessWithElse | 1 | 0 |
| MissedMetadataKeyInLoggerConfig | 1 | 1 (Plan 10, D-09) |
| Nesting | 30 | 30 (identical set) |
| CyclomaticComplexity | 16 | 16 (identical set) |

The Task 1 jq gate prints `true`. The structural set, listed as `filename check scope`, diffs clean before and after.

## StringSigils byte-equality proof

The two sites in `row_history_focus_evidence_contract_test.exs` are line 41, `printf '%s\\0' ...`, and line 42, `if [[ "${#{@flag}:-}" == "#{@control}" ]]`. Both became `~s|...|`. `grep` found no `|` in either line, and escapes and interpolation still work. To check the result, the full `<>`-joined script expression was evaluated in its old and new forms with `elixir /tmp/rh_proof.exs`, with `@flag` and `@control` bound to their real values:

```
old_bytes=262 new_bytes=262 equal=true
sha256_old=63b85508c0b45069f920a52568786e9e8789b0b055a7c7ac20b911723ed7b9f0
sha256_new=63b85508c0b45069f920a52568786e9e8789b0b055a7c7ac20b911723ed7b9f0
```

The rendered script still contains the literal `\0` and `{\"visible\":false}`. The two test names converted to `~s(...)`, in `coverage_doc_contract_test.exs` and `coverage_mix_test.exs`, were also compared with `==` and are both `true`. No `~S` was introduced, and the plan-base acceptance check exits 0.

## GATE-05 contract

`test/threadline/source_comment_location_contract_test.exs` (async) has three tests:
- **Non-empty scan set:** the `lib/**/*.ex` glob must not be empty.
- **No citations:** fails if any comment matches `~r/[A-Za-z0-9_.\/-]+\.exs?:\d+(?:-\d+)?/`. Offenders are reported sorted by `{path, line}`.
- **Detector sanity:** flags `see auth.ex:21-27` and `foo.exs:9`, and passes `` see `TimelineLive.safe_validate/1` `` and `Phase 204 (STRUCT-07)`. The test source also self-guards against containing any reference to the planning directory.

RED evidence: I stubbed the matcher to return `false` and ran the file. The result was 3 tests, 1 failure (detector sanity). I restored the matcher and got 3 tests, 0 failures. As a mutation check, I ran the matcher over the pre-Plan-06 versions of `export_controller.ex` and `timeline_live.ex` from `671112d1`. It flags both historical sites, `timeline_live.ex:366-373` and `auth.ex:21-27`.

## Tasks

| Task | Name | Commits |
|---|---|---|
| 1 | Resolve the test mechanical findings and add the Repo moduledoc | fbff2a4b … f1459883 (14 commits) |
| 2 | Pin GATE-05 with a comment-location contract | a514be36 |

## Commits (`.git-blame-ignore-revs` candidate set)

- fbff2a4b refactor(203-07): resolve AliasOrder, ModuleDoc findings in test/support
- 0232df37 refactor(203-07): resolve FilterFilter findings in test/threadline/community_health_render_contract_test.exs
- adb28d08 refactor(203-07): resolve PreferImplicitTry findings in test/threadline/dialyzer_ignore_contract_test.exs
- 163fa31a refactor(203-07): resolve ExpensiveEmptyEnumCheck findings in test/threadline/incident_playbook_doc_contract_test.exs
- 486ba9c1 refactor(203-07): resolve MapJoin findings in test/threadline/public_surface_contract_test.exs
- e09a4ecc refactor(203-07): resolve FilterFilter findings in test/threadline/release_artifact_contract_test.exs
- 274f86af refactor(203-07): resolve StringSigils findings in test/threadline/row_history_focus_evidence_contract_test.exs
- e234d4f6 refactor(203-07): resolve MapJoin findings in test/threadline/operator_surface/copy_contract_test.exs
- 5679ad6c refactor(203-07): resolve StringSigils findings in test/threadline/operator_surface/coverage_doc_contract_test.exs
- fc32929b refactor(203-07): resolve RedundantWithClauseResult findings in test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
- 5f4d914a refactor(203-07): resolve MapJoin, AliasOrder findings in test/threadline
- 6fc7affc refactor(203-07): resolve MaxLineLength, StringSigils, MapJoin, ExpensiveEmptyEnumCheck, UnlessWithElse findings in test/threadline/operator_surface
- 02eae7c4 refactor(203-07): resolve AliasOrder findings in test/threadline/export_queue
- f1459883 refactor(203-07): resolve ExpensiveEmptyEnumCheck findings in test/threadline/retention

a514be36 (the contract test) is new code, so it is not a blame-ignore candidate.

## Verification

- Task 1 test set (row_history, operator_surface, export_queue, retention, and the contract files): 926 tests, 0 failures.
- `mix test test/threadline/source_comment_location_contract_test.exs`: 3 tests, 0 failures.
- `mix test` (full suite, DB_PORT=5433): 1702 tests, 0 failures, 1 excluded. That is 1699 plus the 3 new tests. The clean_checkout timeout flake did not appear.
- `mix compile --warnings-as-errors` (dev and test): clean. `mix verify.format`: exit 0.
- `head -3 test/support/repo.ex | grep -c "@moduledoc false"` → 1. `grep -c '\.planning'` on the new contract → 0. `git show --stat a514be36` lists only the contract file.
- No `# credo:disable` was added.

## Deviations from Plan

None that change scope. Notes:
- **AliasOrder with multi-aliases:** Credo orders a `Threadline.{Evidence, ...}` group by its first expanded name, `Threadline.Evidence`. So in `storage_schema_integration_test.exs` it sits after `Threadline.Capture.{...}` and before `Threadline.Governance.RetentionRun`. The change is a reorder only.
- **MaxLineLength in `auth_test.exs`:** the long line was a comment that quotes a goal, not an expression. The comment was wrapped onto two lines, and no code or string changed.
- **UnlessWithElse in `refute_partition_test.exs`:** this became `if File.exists?(...)` with the branches swapped. The explanatory comment moved with the `:ok` branch.
- **RedundantWithClauseResult in `operator_surface_fixture_contract_test.exs`:** the `with` has no `else`, so returning `validate_references(...)` directly gives the same result.
- **ExpensiveEmptyEnumCheck:** `length(x) > 0` and `length(x) >= 1` became `x != []`. The `refute_partition` site is guarded by `is_list/1` first, so the meaning is unchanged.
- **Commit grouping (D-28):** `auth_test.exs` and `coverage_mix_test.exs` are not contract tests, so they went into the operator_surface directory batch.
- **REQUIREMENTS.md:** GATE-02 and GATE-05 are left unchecked. GATE-02 closes in Plans 09/10. The GATE-05 facts now hold (no stale citations, 0 missing moduledocs), but the moduledoc half is only gate-enforced once Plan 10 wires the ModuleDoc delta, so Plan 10 marks GATE-05.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/threadline/source_comment_location_contract_test.exs and all 22 modified files.
- FOUND: all 15 commits (`git rev-list --count 9bace4f7..HEAD` = 15 before this docs commit).
