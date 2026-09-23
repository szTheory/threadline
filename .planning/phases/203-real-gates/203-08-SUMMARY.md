---
phase: 203-real-gates
plan: 08
subsystem: code-quality
status: complete
tags: [credo, gate-02, structural-debt, struct-07]
requires: [203-07]
provides:
  - "lib/ has zero live Credo Nesting and CyclomaticComplexity findings under full defaults (both plan jq gates print true)"
  - "30 per-site `# credo:disable-for-next-line Credo.Check.Refactor.<Check>` lines in lib/, each directly below a `# Structural debt: <reason>` line (D-31 form)"
  - "4 Nesting sites flattened in place (no function created, extracted or split)"
affects: [203-09, 203-10, 204]
tech-stack:
  added: []
  patterns:
    - "Per-site structural-debt filing: `# Structural debt: <reason>` immediately above `# credo:disable-for-next-line Credo.Check.Refactor.<Check>`, with no phase number or requirement ID in packaged source (D-31)"
key-files:
  created: []
  modified:
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/threadline.export.ex
    - lib/mix/tasks/threadline.install.ex
    - lib/mix/tasks/threadline.verify_coverage.ex
    - lib/threadline/audit.ex
    - lib/threadline/change_diff.ex
    - lib/threadline/critic_trust/krippendorff_alpha.ex
    - lib/threadline/critic_trust/measure.ex
    - lib/threadline/critic_trust/rank_metrics.ex
    - lib/threadline/evidence.ex
    - lib/threadline/export/cleanup_task.ex
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/mechanical_checker.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/policy/redaction_presenter.ex
    - lib/threadline/query.ex
    - lib/threadline/query/filter_params.ex
    - lib/threadline/retention/policy.ex
    - lib/threadline/storage/local.ex
decisions:
  - "D-31 (maintainer, blocking-human checkpoint): the per-site line reads `# Structural debt: <reason>`. It carries no phase number and no requirement ID. The Phase 204 / STRUCT-07 successor is named only in the test-resident register that Plan 09 creates"
  - "release_artifact_contract_test.exs was left untouched and gained no exemption. The source was changed to meet the contract"
  - "GATE-02 is left unchecked in REQUIREMENTS.md. test/ still has 12 structural findings (Plan 09), and the gate wiring lands in Plans 09/10"
metrics:
  duration: "~45 min of execution, split by a blocking-human checkpoint (2026-09-22 → 2026-09-23)"
  completed: 2026-09-23
plan_base: 759bf33a804c2fe95935eb035c2d70453f1dc201
plan_head_before: 759bf33a804c2fe95935eb035c2d70453f1dc201
actuals:
  tokens: 6200
  tasks: 2
  commits: 32
---

# Phase 203 Plan 08: lib Structural Credo Findings Filed or Flattened Summary

Plan 07 left 34 structural Credo findings in lib/: 19 Nesting and 15 CyclomaticComplexity. This plan clears all of them. 4 Nesting sites were flattened in place. The other 30 are filed per site: a `# credo:disable-for-next-line` comment, directly below a `# Structural debt: <reason>` line that says which extraction or split Phase 204 has to do. Under Credo full defaults, lib/ now has no live Nesting or CyclomaticComplexity findings. The first draft of the per-site wording broke the release artifact contract, and a maintainer decision (D-31) set the final wording.

Plan base SHA: `759bf33a804c2fe95935eb035c2d70453f1dc201` (also recorded in `.git/gsd-203-08-base`).

## Tally

| Outcome | Nesting | CyclomaticComplexity | Total |
|---|---|---|---|
| Filed (per-site disable + `# Structural debt:` line) | 15 | 15 | 30 |
| Flattened in place | 4 | 0 | 4 |
| **lib/ sites handled** | **19** | **15** | **34** |

I cross-checked this against the tree. At 203-07 close the whole tree had Nesting 30 and CyclomaticComplexity 16. Now 12 structural findings remain, all in test/ (Plan 09's scope): Nesting 11 and CyclomaticComplexity 1. So lib/ had 19 and 15. `grep -rn 'credo:disable' lib` gives 30 lines: 15 Nesting and 15 CyclomaticComplexity. (The continuation brief said "20 Nesting / 14 CyclomaticComplexity". The tree shows 15/15 filed plus 4 flattened, and this summary uses the measured numbers.)

## Per-site table

Line is the reported construct line, which sits directly below its disable. Line numbers are live at HEAD after the D-31 sweep.

| Path | Line | Check | Outcome | Reason |
|---|---|---|---|---|
| `lib/mix/tasks/critic.measure.ex` | 346 | CyclomaticComplexity | filed | complexity 13 — split valid_adjudication?/4 per check |
| `lib/mix/tasks/threadline.export.ex` | 40 | CyclomaticComplexity | filed | complexity 13 — split run/1 option parsing from dispatch |
| `lib/mix/tasks/threadline.install.ex` | 103 | Nesting | filed | priv case inside app-env case — extract priv-path resolution |
| `lib/mix/tasks/threadline.verify_coverage.ex` | 127 | Nesting | filed | fn inside nested case — extract the table-name validator |
| `lib/threadline/audit.ex` | 87 | Nesting | filed | case inside transaction fn inside with — extract the transaction body |
| `lib/threadline/change_diff.ex` | 113 | CyclomaticComplexity | filed | complexity 11 — split primary_map/2 op normalization out |
| `lib/threadline/critic_trust/krippendorff_alpha.ex` | 46 | Nesting | filed | if inside reduce fn — extract the coincidence accumulator |
| `lib/threadline/critic_trust/krippendorff_alpha.ex` | 141 | Nesting | filed | diagonal if inside reduce fn — extract the expected term |
| `lib/threadline/critic_trust/measure.ex` | 58 | CyclomaticComplexity | filed | cyclomatic complexity 18 — split measure_lens/4 into per-metric steps |
| `lib/threadline/critic_trust/rank_metrics.ex` | 36 | Nesting | filed | cond inside for-reduce — extract the pairwise win score |
| `lib/threadline/evidence.ex` | 288 | CyclomaticComplexity | filed | complexity 10 — split validate_subject!/1 normalization out |
| `lib/threadline/export/cleanup_task.ex` | 66 | Nesting | filed | lock if inside checkout fn — extract the locked cleanup body |
| `lib/threadline/export/orchestrator.ex` | 22 | CyclomaticComplexity | filed | complexity 12 — split run/2 into load, stream, persist |
| `lib/threadline/operator_surface/auth.ex` | 131 | Nesting | filed | mismatch if inside nested case — extract the actor reconciliation |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | 40 | Nesting | filed | owner if inside nested case — extract the ownership check |
| `lib/threadline/operator_surface/live/actor_live.ex` | 48 | Nesting | filed | history case inside if in mount/3 — extract last-activity lookup |
| `lib/threadline/operator_surface/live/export_status_live.ex` | 467 | CyclomaticComplexity | filed | complexity 11 — split export_workflow_summary/1 per state |
| `lib/threadline/operator_surface/live/row_history_component.ex` | 155 | Nesting | filed | if inside find_value fn inside case — extract the key matcher |
| `lib/threadline/operator_surface/live/stress_live.ex` | 1269 | CyclomaticComplexity | filed | complexity 10 — split refute_brand_lines/1 into a copy table |
| `lib/threadline/operator_surface/live/stress_live.ex` | 1315 | CyclomaticComplexity | filed | complexity 13 — split refute_color_accent/2 into a rung table |
| `lib/threadline/operator_surface/live/timeline_live.ex` | 175 | Nesting | filed | nesting 4 in handle_params/3 — extract the filtered-page load |
| `lib/threadline/operator_surface/live/timeline_live.ex` | 1019 | Nesting | filed | if inside find_value fn inside case — extract the key matcher |
| `lib/threadline/operator_surface/mechanical_checker.ex` | 638 | Nesting | filed | scale if inside case inside flat_map fn — extract the prop check |
| `lib/threadline/operator_surface/presentation.ex` | 206 | CyclomaticComplexity | filed | complexity 17 — replace status_label/1 case with a lookup |
| `lib/threadline/operator_surface/router.ex` | 58 | CyclomaticComplexity | filed | complexity 12 — split the macro's option validation out |
| `lib/threadline/policy/redaction_presenter.ex` | 322 | Nesting | filed | nested placeholder case — extract the placeholder check |
| `lib/threadline/query.ex` | 481 | CyclomaticComplexity | filed | complexity 13 — split actor_history/2 query from pagination |
| `lib/threadline/query/filter_params.ex` | 50 | CyclomaticComplexity | filed | complexity 10 — split filters_raw_from_params/1 per field |
| `lib/threadline/query/filter_params.ex` | 144 | CyclomaticComplexity | filed | complexity 11 — split collapse_actor_ref/1 per actor case |
| `lib/threadline/retention/policy.ex` | 50 | CyclomaticComplexity | filed | cyclomatic complexity 33 — split resolve!/1 per option group |
| `lib/threadline/query/filter_params.ex` | collapse_actor_ref/1 | Nesting | flattened (59bc3b02) | nested case(safe_actor_kind)/case(ActorRef.new) inside cond → one with/else, same error mapping (3 → 2) |
| `lib/threadline/storage/local.ex` | put/2 | Nesting | flattened (332a42ab) | if + two nested cases inside with → final with clause `:ok <- if(..., do: File.cp, else: File.write)`, same return shapes (3 → 2) |
| `lib/threadline/operator_surface/live/export_status_live.ex` | timeline_filter_context/1 | Nesting | flattened (4aa723e9) | case(FilterParams.parse)/case(safe_validate) inside if → one with/else; both error arms already returned the same map (3 → 2) |
| `lib/threadline/operator_surface/live/transaction_live.ex` | handle_params/3 as_of | Nesting | flattened (4115fd39) | nested cases inside if → guarded with/else; nil, "" and unparsable still yield nil (3 → 2) |

## Checkpoint: D-31 per-site wording (blocking-human decision)

- **Found:** The original D-27 per-site line was `# Phase 204 (STRUCT-07): <reason>`. With that wording in all 30 lib sites, the full suite ran 1702 tests with 5 failures, all in `test/threadline/release_artifact_contract_test.exs`. Its `:phase_prose` rule bans `Phase \d+` in packaged source, and 22 of the 30 sites are packaged. A `STRUCT-07` tag would also leak a planning requirement ID into the Hex package.
- **Decision (maintainer, recorded as D-31 in 203-CONTEXT.md, commit 84b5ad5c):** Reword every per-site line to `# Structural debt: <reason>`. Reason text and indentation stay the same, and the line stays directly above its disable. Only the test-resident register (Plan 09) names the Phase 204 / STRUCT-07 successor. The release contract gets no change and no exemption. The 203-07 detector-sanity sample text is left alone.
- **Resolution:** A single sweep commit, 40f6df19 `refactor(203-08): reword structural-debt successor lines (D-31)`, touches 26 lib files and replaces 30 lines. The release contract is green again: 19 tests, 0 failures.

## Commits (plan base 759bf33a..HEAD, oldest first)

- 59bc3b02 refactor(203-08): flatten nested case in lib/threadline/query/filter_params.ex
- 332a42ab refactor(203-08): flatten nested case in lib/threadline/storage/local.ex
- c85e2b98 refactor(203-08): file structural Credo findings to Phase 204 in lib/mix/tasks/critic.measure.ex
- 99525a7e refactor(203-08): file structural Credo findings to Phase 204 in lib/mix/tasks/threadline.export.ex
- 1ee89a25 refactor(203-08): file structural Credo findings to Phase 204 in lib/mix/tasks/threadline.install.ex
- 149fa6da refactor(203-08): file structural Credo findings to Phase 204 in lib/mix/tasks/threadline.verify_coverage.ex
- 7628712e refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/audit.ex
- 473cf425 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/change_diff.ex
- 117762c4 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/critic_trust/krippendorff_alpha.ex
- 583e9c3a refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/critic_trust/measure.ex
- c0c8fd8c refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/critic_trust/rank_metrics.ex
- 05bc005d refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/evidence.ex
- f82ddf5c refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/export/cleanup_task.ex
- b19ce9fe refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/export/orchestrator.ex
- 0b2aa239 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/policy/redaction_presenter.ex
- bfc5d6b9 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/query.ex
- c44b4aab refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/query/filter_params.ex
- c909c65f refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/retention/policy.ex
- 4aa723e9 refactor(203-08): flatten nested case in lib/threadline/operator_surface/live/export_status_live.ex
- 4115fd39 refactor(203-08): flatten nested case in lib/threadline/operator_surface/live/transaction_live.ex
- 31d7488e refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/auth.ex
- 534f9c9b refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/controllers/export_controller.ex
- dc956ae4 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/live/actor_live.ex
- 40b3d11e refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/live/export_status_live.ex
- f3653ab2 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/live/row_history_component.ex
- d5175fdb refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/live/stress_live.ex
- 85a139c3 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/live/timeline_live.ex
- e8532413 refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/mechanical_checker.ex
- b173d49e refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/presentation.ex
- 590dfe8c refactor(203-08): file structural Credo findings to Phase 204 in lib/threadline/operator_surface/router.ex
- 84b5ad5c docs(203): record D-31 — durable per-site structural-debt wording (orchestrator, at the checkpoint)
- 40f6df19 refactor(203-08): reword structural-debt successor lines (D-31)

The "to Phase 204" wording in the subject lines comes from before D-31. Commit messages are not packaged. Only the source-line wording changed.

## Verification

- `grep -rn "Phase 204" lib` returns nothing. `grep -rn "STRUCT-07" lib` returns nothing.
- Adjacency: `grep -rn -B1 'credo:disable' lib | grep -c 'Structural debt: '` = 30 = `grep -rn 'credo:disable' lib | wc -l`.
- Task 1 jq gate (non-surface lib has no structural findings): `true`. Task 2 jq gate (all of lib has no structural findings): `true`.
- `mix compile --warnings-as-errors --force`: clean. `mix verify.format`: exit 0.
- `DB_PORT=5433 mix test test/threadline/release_artifact_contract_test.exs`: 19 tests, 0 failures.
- `DB_PORT=5433 mix test` (full suite): **1702 tests, 0 failures, 1 excluded** (116.6 s). The clean_checkout timeout flake did not appear.
- Before the checkpoint: 267 targeted tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Layout-only changes so each disable sits directly above the reported construct**
- **Found during:** Tasks 1 and 2
- **Issue:** `credo:disable-for-next-line` only suppresses the line right after it. At three sites the reported line was a continuation line or shared an expression, so no disable could sit directly above the reported line.
- **Fix:**
  - `threadline.install.ex`: the case branches now call `Path.join` directly.
  - `krippendorff_alpha.ex`: `weighted_sum` became an `if ... * w` form.
  - `timeline_live.ex` `handle_params/3`: `page_opts` (from `scope_aware_opts/1`, a pure read of socket assigns and app env) is bound before `Task.async`, so the call fits on one line.
  - No function was created, extracted or split.
- **Commits:** 1ee89a25, 117762c4, 85a139c3

**2. [Rule 3 - Blocking] filter_params.ex:144 filed at complexity 11**
- **Found during:** Task 1
- **Issue:** After the collapse_actor_ref/1 flatten (59bc3b02), the function still reports CyclomaticComplexity 11.
- **Fix:** Filed per site like the others ("split collapse_actor_ref/1 per actor case"). Getting it under the threshold would need a function split, which is out of scope here.
- **Commit:** c44b4aab

**3. [Checkpoint - D-31] Per-site wording changed from `# Phase 204 (STRUCT-07):` to `# Structural debt:`**
- See the checkpoint section above. This was a maintainer decision, not an auto-fix.
- **Commit:** 40f6df19

## Known Stubs

None.

## Deferred / Out of Scope

- 12 structural findings in test/ (Nesting 11, CyclomaticComplexity 1) belong to Plan 09. So does the test-resident register that names Phase 204 / STRUCT-07.
- `MissedMetadataKeyInLoggerConfig` (1) belongs to Plan 10 (D-09).
- GATE-01, GATE-02 and GATE-05 stay unchecked in REQUIREMENTS.md.

## Self-Check: PASSED

- FOUND: all 28 modified lib files (`git diff --name-only 759bf33a HEAD -- lib` lists 28).
- FOUND: all 32 commits (`git rev-list --count 759bf33a..HEAD` = 32 before this docs commit), including 40f6df19.
