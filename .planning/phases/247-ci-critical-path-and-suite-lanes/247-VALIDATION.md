---
phase: "247"
slug: "ci-critical-path-and-suite-lanes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-26"
---

# Phase 247 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `247-RESEARCH.md` § Validation Architecture.

---

## Historical live evidence — B3

B3 squash SHA: 89add23ede29b7840e6cfa29cd70eb3c8ea59ae2
B3 CI-02 verdict: PASS
B3 CI-02 requirement: met
B3 CI-03 verdict: MISS
B3 CI-03 requirement: unmet

Five selected attempt-1 main successes at 89add23e: 40433193088, 40434036118, 40434884357, 40436597341, 40437416932. Median 444 s; fixed first-three ratios and the excluded failed run are in `247-MEASUREMENT.md`. Coverage is automated and green; numeric CI-03 acceptance remains MISS.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 local; CI matrix 1.15.8 / 1.17.3 / 1.20.4); `node:test` via tsx for TS; bash `bin/ci-test-partitions --self-test` harness |
| **Config file** | `test/test_helper.exs` (pointer comment only); `examples/threadline_phoenix/e2e/package.json` `test:unit` |
| **Quick run command** | `DB_PORT=<ephemeral> mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` + `bin/ci-test-partitions --self-test` + touched tsx unit tests |
| **Full suite command** | `mix verify.test` on an ephemeral `postgres:16` container (never the shared PG14 on 5432); phase gate `mix ci.all` (CI=true) |
| **Estimated runtime** | quick ~60 s; full ~6 min |

---

## Sampling Rate

- **After every task commit:** quick run command
- **After every plan wave:** `mix verify.test` on ephemeral PG16 + `mix verify.credo` + `mix format --check-formatted`
- **Before `/gsd-verify-work`:** `mix ci.all` green, then the live main-run measurements below
- **Max feedback latency:** 120 seconds (local); live CI measurements are batch evidence, not per-task feedback

---

## Per-Task Verification Map

Filled by the planner/executor per task; requirement-level map:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Test Coverage | Requirement Gate |
|-------------|----------|-----------|-------------------|-------------|---------------|-------------------|
| CI-01 | slow-specs ranking, cap 20, retry sum, skip exclusion, malformed → warning exit 0 | unit | `npm --prefix examples/threadline_phoenix/e2e run test:unit` | ✅ | ✅ green | Verified in main-run evidence (`247-OBSERVATION.md`) |
| CI-01 | timings step in every leg, `always()`, guard, step summary, `browser-timings-…` artifact; `test:unit` wires both TS tests | contract | `mix test test/threadline/browser_journey_evidence_contract_test.exs` | ✅ | ✅ green | Verified in main-run evidence (`247-OBSERVATION.md`) |
| CI-02 | matrix == inventory `votingProjects`; check names; retired name; needs exemption; job ids; time-to-red | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ | ✅ green | **PASS** — 444 s median / 5 runs (≤ 540 s) |
| CI-02 | `bin/browser-full-projects` resolves `${{ matrix.project }}`, fails closed | contract + mutation | `mix test test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` | ✅ | ✅ green | **PASS** — 444 s median / 5 runs (≤ 540 s) |
| CI-02 | receipt merges N files; missing leg → not executed; duplicates rejected | unit | `npm --prefix examples/threadline_phoenix/e2e run test:unit` | ✅ | ✅ green | **PASS** — receipt validated both browser legs on PR #96 and the five main runs |
| CI-02 | download-artifact SHA pin + node24 | contract | `mix test test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs` | ✅ | ✅ green | **PASS** — PR #96 checks green |
| CI-02 | measurement script (attempt-1 wall, median) | contract (fake gh) | `mix test test/threadline/measure_main_ci_contract_test.exs` | ✅ | ✅ green | **PASS** — 444 s median / 5 attempt-1 main runs (≤ 540 s) |
| CI-03 | scope=toolchain filtering, exactly-once, summary count, `--ingest-weights` | self-test | `bin/ci-test-partitions --self-test` | ✅ | ✅ green | **OPEN / MISS** — seven of nine first-three ratios exceed 1.15; see `247-MEASUREMENT.md` |
| CI-03 | D-09 no-dodging + no-silent-unclassified; env var min/latest only; CONTRIBUTING sentence | contract | `mix test test/threadline/repo_contract_scope_contract_test.exs` | ✅ | ✅ green | **OPEN / MISS** — partition-ratio gate remains unmet |
| CI-03 | default excludes unchanged | contract | `mix test test/threadline/zero_skips_contract_test.exs` | ✅ | ✅ green | **OPEN / MISS** — partition-ratio gate remains unmet |
| CI-03 | per-lane partition max/min measurement | live measurement | `bin/measure-main-ci --since 29abf5653a0e1c31b70d73d71a3f6c552d9b9712 --count 5 --ratios --format json` (recorded in `247-MEASUREMENT.md`) | n/a | ✅ measured | **MISS** — current 1.20–1.42; latest 1.43–1.58; min 1.57–1.61 (target ≤ 1.15) |
| CI-04 | hang / hang_ignore_term killed within budget, 124, no leftover process | self-test | `bin/ci-test-partitions --self-test` and `/bin/bash bin/ci-test-partitions --self-test` | ✅ | ✅ green | Verified on main min lane (`247-08-SUMMARY.md`) |
| CI-04 | monitor names `file:line` + stack for test-body and `setup_all` hangs | integration | `mix test test/threadline/partition_monitor_test.exs` | ✅ | ✅ green | Verified on main min lane; focused local suite passed |

*Coverage status: ✅ green · ❌ red · ⚠️ flaky. Requirement Gate records live acceptance separately; CI-03 remains unmet.*

---

## Wave 0 Requirements

- [x] `examples/threadline_phoenix/e2e/support/slow-specs.test.ts` + `test:unit` wiring (also for `operator-ci-evidence.test.ts`)
- [x] `test/threadline/repo_contract_scope_contract_test.exs`
- [x] `test/threadline/partition_monitor_test.exs` (runtime-built sandbox fixtures, never committed `*_test.exs` fixtures)
- [x] measurement script + fake-`gh` contract test
- [x] fake-mix support for `--formatter X` pairs and `hang` / `hang_ignore_term` behaviors

---

## Live-CI Verifications (automated reads, maintainer-granted writes)

| Behavior | Requirement | Why live | Instructions |
|----------|-------------|----------|--------------|
| ≥20 slowest specs in summary/artifact on main | CI-01 | needs a real main run | read job summary / `gh run download` the `browser-timings-*` artifact |
| median ci.yml wall ≤ 9 min over 5 attempt-1 main runs | CI-02 | measurement on main | measurement script over the 5 runs at/after the split head |
| partition max/min ≤ 1.15 over 3 runs per lane | CI-03 | measurement on main | parse the script's report table from 3 consecutive runs |
| monitor works on Elixir 1.15.8 / OTP 26 | CI-04 | min lane only in CI | any PR run of the min lane with the formatter attached |
| PR #89 shape reproduced red, module named, ≪ 20 min | CI-04 | synthetic live run | throwaway-branch PR with `Process.sleep(:infinity)` in a `setup_all` (push = maintainer grant) |

**Observed:** CI-01 summary and timing artifacts were present in main-run evidence (`247-OBSERVATION.md`). CI-02 passed at 444 s median over the five B3 attempt-1 successes. CI-03 was measured and missed its all-nine ratio rule; it remains an unmet phase requirement. CI-04 was exercised on the min lane, including a synthetic `setup_all` hang repro that was named and terminated in 525 s (`247-08-SUMMARY.md`).

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all formerly missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] Automated verification coverage is complete (`nyquist_compliant: true`); CI-03 remains a measured MISS and the phase requirement is not complete.

**Approval:** validation map audited; no human UAT required by repository policy.

## CI-03 Gap-Closure Sampling (executed, 247-14/15)

The existing CI-01, CI-02 and CI-04 rows above retain their executed evidence. These rows record executed checks; coverage is complete while the numeric requirement remains unmet.

| Plan | Behavior | Automated check | Gate |
|------|----------|-----------------|------|
| 247-14 | Three distinct successful attempt-1 main artifacts per min/latest/current lane produce path-sorted, exact-inventory weights; bad TSVs, wrong output and interrupted ingest fail safely | `bin/ci-test-partitions --self-test` plus `mix test test/threadline/ci_topology_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` on ephemeral PostgreSQL | PASS; 12 TSVs per lane from three recorded B2 runs; 206/206/269 exact files |
| 247-14 | Unset/current/min/latest route to the intended file and assign every eligible test exactly once with N=4, colocation and watchdog unchanged | Both Bash self-tests; local full and `THREADLINE_CI_LANE=min THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned` on ephemeral PostgreSQL | PASS; both Bash self-tests, 44 focused contracts, full/scoped execution and runtime assignment mutation |
| 247-15 | Exact candidate preserves required CI, browser timing/receipt and named hang coverage before landing | `CI=true mix ci.all`, `bin/ci-test-partitions --self-test`, PR required checks and `bin/verify-branch-protection` | PASS; exact-head ci.all, PR #96 17/17, main squash tree and sole required context |
| 247-15 | First three qualifying post-squash main runs each have min/current/latest max/min ≤ 1.15; five-run wall median remains ≤ 540 s | `bin/measure-main-ci --since <new-squash-sha> --count 5 --ratios --format json`; compare all nine values and median | CI-02 PASS at 444 s; CI-03 MISS on fixed nine values; unmet |

## Historical pre-gap validation evidence

Commands run in this audit:

- `DB_HOST=127.0.0.1 DB_PORT=56481 mix test test/threadline/browser_journey_evidence_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/measure_main_ci_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/partition_monitor_test.exs` — 212 tests, 0 failures; log: `/tmp/threadline-247-validation-mix.log`.
- `npm --prefix examples/threadline_phoenix/e2e run test:unit` — 39 tests, 0 failures; log: `/tmp/threadline-247-validation-ts.log`.
- `bin/ci-test-partitions --self-test` — passed; log: `/tmp/threadline-247-validation-selftest-bash5.log`. The sandboxed attempt failed because sandbox policy denied `ps`; the unrestricted rerun passed.
- `/bin/bash bin/ci-test-partitions --self-test` — passed; log: `/tmp/threadline-247-validation-selftest-bash32.log`. The sandboxed attempt failed because sandbox policy denied `ps`; the unrestricted rerun passed.

The authoritative CI-03 numeric measurement is recorded in `247-MEASUREMENT.md`. Test coverage is green; the CI-03 gate is not.

## Validation Audit 2026-10-26

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Gap execution validation evidence (2026-10-27)

44 focused topology/scope contracts green; both Bash self-tests green including wrong-lane/missing/duplicate/stale data, unsafe output, interrupted rename and assignment-mutation controls. Full local partitions: 269 files, 32 properties + 3381 tests, zero failures; min/toolchain: 206 files, 32 properties + 2561 tests, zero failures. Exact tested land ci.all: root3381/32, example132, Dialyzer0, slice17, browser418passed/56configuredskips. Fresh prior-phase regression: 33 files, 1 property +785 tests, zero failures. No missing automated verification or human-only item; the known numeric MISS is preserved.

## Validation Audit 2026-10-27

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Plans audited | 15 |
| Numeric gates unmet | 1 |

## CI-03 gap execution — Plans 247-16 through 247-19

Plans 16–18 are executed and verified; Plan 19 reached its designed six-run stop. B3 remains historical, including failed run 40435657557. Current B4 acceptance is CI-02 INCOMPLETE (4/5 successes) and CI-03 MISS (three min ratios); the raw incomplete payload and matching report projections below are authoritative for this new head.

| Plan | Behavior and failure signal | Automated verification | Acceptance state |
|---|---|---|---|
| 247-16 Task 1 | Long async wall duration is a lower bound on modeled partition cost; removing that bound fails the synthetic assignment control. B3 min TSVs strictly ingest to 206 selected files and four runner processes without omissions. | `bin/ci-test-partitions --self-test` and `/bin/bash bin/ci-test-partitions --self-test` | Passed: long-async behavior/mutation and strict min ingestion; predictions are not live acceptance. |
| 247-16 Task 2 | Three lane files come from the same three successful B3 attempt-1 main runs; exact inventories are current 269/min 206/latest 206. Existing-assignment RMS falls from about 35.7 to 7.0 s min, 29.3 to 7.1 s latest and 17.6 to 14.5 s current when the longest async file is floored. Model-fit or predicted-ratio failure stops before landing. | Both shell self-tests; `mix test test/threadline/ci_topology_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` on ephemeral PostgreSQL 16; full and min/toolchain `mix verify.test_partitioned`; `mix verify.format`; `mix verify.credo` | Passed: model fit, exact 269/206 inventories, full/scoped suites, both Bash self-tests, format and Credo. |
| 247-17 Tasks 1–2 | Modal has hidden and focus has returned to the exact Show Modal opener before the unchanged toast Close keyboard Enter. The focused case and entire motion spec pass in desktop/mobile with retries disabled; the previous failed run stays named. | `mix verify.example_browser operator-motion.spec.ts --project=desktop-chromium --project=mobile-chromium --retries=0` with focused `-g` case first, ephemeral PostgreSQL 16 | Passed: focused 2/2 and complete 24/24 motion tests without retries; historical failure retained. |
| 247-18 Tasks 1–2 | Combined source passes full local `CI=true mix ci.all`, both shell self-tests, repo hygiene and branch-protection readback; the exact tested SHA has green PR lane/browser/receipt/required checks before SHA-guarded squash. Recorded PR number/head/squash must equal live GitHub metadata and protected main's source tree. | Local named gates, `gh pr view <recorded-number> --json state,headRefOid,mergeCommit`, exact source-tree comparison and required-context readback | Passed: exact 4ff7af65 local/hosted gate, guarded PR 97 squash 02d115a3 and protected-main readback. |
| 247-19 Task 1 | Plan 18's recorded B4 identity is rechecked before spending. First three qualifying successful attempt-1 main runs at that head supply all nine ratios; first five supply wall median. Failed/cancelled attempts are listed; total new-head runs are capped at six. | Live PR/main precondition plus `bin/measure-main-ci --since <new-squash-sha> --count 5 --ratios --format json` saved unchanged as B4 JSON; both reports receive identical B4 gate blocks | HALTED: six runs yielded four successes and two failed exclusions; INCOMPLETE branch reconciled, no seventh run. |
| 247-19 Task 2 | A fresh canonical reader response, persisted B4 JSON and B4 records in BOTH MEASUREMENT/VALIDATION agree on exact head, five chronological IDs/events/walls, median, first-three nine ratios, exclusions and derived numeric PASS/MISS. | Inline Python reconciliation in 247-19-PLAN.md; independent `gh` PR/main identity check and SEED-006 bound on CI-02 pass | BLOCKED / unverified: full-five precondition unmet; complete reconciliation and 13 negative controls were not executed. No PASS inferred. |

Plan 16's long-async control is non-vacuous: on the B3 min/latest partition-4 data, the old 0.292 additive model charges the 79–105 s `deps_audit_gate_test.exs` about 23–31 s, and therefore predicts a much shorter partition than was observed. The revised objective is `sync_sum + max(0.292 * async_sum, longest_async_wall)`, preserving four bins and colocation. The three-run fixed B3 sample is used only for model diagnosis and weight refresh; Plan 19 must obtain a fresh exact-head sample to decide the requirement.


## Gap planning verification — Plans 16–19 (2026-10-27)

Independent plan check passed after one revision. The revision split exact-head landing from measurement and added merged-PR/squash identity and persisted/live/report reconciliation gates. All four new plans pass `verify plan-structure`; all eight `<automated>` commands pass Bash syntax checks and the embedded reconciliation Python compiles. Verify-command path and failure-direction probes have no findings for the new plans. Decision coverage is 19/19; post-planning coverage is 23/23 (four requirements plus nineteen decisions); duplicate threat IDs: zero. `git diff --check` passes. These are planning checks only: no candidate implementation, browser run, landing or new numeric measurement was performed. CI-03 remains unmet.


## B4 bounded outcome — INCOMPLETE

B4 measurement: INCOMPLETE

The exact PR #97 candidate `4ff7af655315a927eb5a62e14cb2abc7e72d4ab8` landed as main `02d115a32e4479f353d284c04fc838ba58938d16`. The authorized six-run window is exhausted: four successful attempt-1 runs and two failed exclusions, using the merge push and five serial dispatches. Source and acceptance limits stayed fixed; no attempt/job was retried and no seventh run was dispatched.

CI-02 on B4 is **INCOMPLETE**: five qualifying successes were required and only four exist. The canonical reader reports `median_wall_s: null`; no five-run PASS is inferred. Historical B3 CI-02 PASS at 444 s remains historical; SEED-006 retains that last complete bound.

CI-03 is **MISS** on the fixed first-three successful runs: all six current/latest ratios pass, while all three min ratios exceed 1.15. Startup remains part of the accepted full-wall measurement.

| Qualifying run | Event | Wall s |
|---|---|---:|
| 40449332597 | push | 454 |
| 40450141708 | workflow_dispatch | 423 |
| 40450801580 | workflow_dispatch | 468 |
| 40451533079 | workflow_dispatch | 404 |

| Lane | First / second / third printed ratios |
|---|---|
| current | 1.12 / 1.11 / 1.12 |
| min | 1.24 / 1.28 / 1.27 |
| latest | 1.10 / 1.04 / 1.12 |

### Failed exclusions and follow-up

- 40452150109, min job 122017125177, partition 3, seed 675682: `Threadline.OperatorSurface.RowHistoryLiveScopedTest` at `row_history_live_test.exs:361`, `audit_changes_transaction_id_fkey` during child insertion after parent insertion. Source triage confirms parent/child use the same Repo options and each partition has its own database; it does not establish why the parent row was absent. Do not label a root cause or patch colocation from that evidence.
- 40452833440, min job 122019295198, partition 1, seed 856063: `Threadline.Export.OrchestratorTest` at `export/orchestrator_test.exs:239`, setup line 177, `File.rm_rf!("priv/threadline_exports")` failed with “file already exists.” The fixture uses a checkout-shared directory. A read-only replay maps orchestrator to min partition 1, export controller to partition 4, and cleanup/local-storage tests to partition 2. This demonstrates cross-process shared-path exposure; further diagnosis must capture the competing writer/cleanup before claiming the failure cause or a fix.

Both newly observed failures remain failed, excluded and unresolved. Failed initial PR run 40446515239 and historical B3 failed run 40435657557 remain separately recorded and were not retried. CI-01 timing artifacts, both browser projects, full 31-journey receipts and CI-04 guards were verified on the exact green PR and four qualifying main successes; they do not erase the two failed attempts.

### Residual diagnosis and scope recommendation

All three min misses have partition 3 slowest. Its pre-first-module boot intervals are 20.469 / 18.940 / 17.227 s; min active-only ratios are 1.140 / 1.165 / 1.127. The first p3 active wall is 145.075 s versus a 145.070 s observed sync-module sum. These intervals recur; the artifacts do not establish their cause. Current and latest pass all six full-wall ratios. Both independent researchers recommend no further optimizer, weight, N=4, inventory, or threshold change from this evidence.

Stop paid sampling at this cap. Recommended next scope is a bounded local diagnosis of fixture isolation (shared export directory and the separate row-history FK failure), then a concrete reviewed candidate and a new sampling budget decision. Do not spend more runs trying to obtain a favorable sample or waive the fixed 1.15 / 540 s limits silently.

The unchanged canonical count-5 reader payload is `247-B4-INCOMPLETE.json`. No complete `247-B4-MEASUREMENT.json` or B4-GATE-JSON block is produced. Plan 19 Task 2's complete-five reconciliation and its mutation controls cannot run because their sample precondition is unmet. The incomplete payload, both projections, six-run chronology and two exclusions are reconciled separately; this is not a substitute PASS.

<!-- B4-INCOMPLETE-JSON-BEGIN -->
{
  "schema": "threadline.phase247-b4-incomplete/1",
  "squash_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
  "state": "INCOMPLETE",
  "required_successes": 5,
  "found_successes": 4,
  "total_runs": 6,
  "run_cap": 6,
  "extra_dispatches": 5,
  "runs": [
    {
      "id": 40449332597,
      "event": "push",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 454
    },
    {
      "id": 40450141708,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 423
    },
    {
      "id": 40450801580,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 468
    },
    {
      "id": 40451533079,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "wall_s": 404
    }
  ],
  "first_three_ratios": {
    "current": [
      1.12,
      1.11,
      1.12
    ],
    "min": [
      1.24,
      1.28,
      1.27
    ],
    "latest": [
      1.1,
      1.04,
      1.12
    ]
  },
  "excluded": [
    {
      "id": 40452150109,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "reason": "failure"
    },
    {
      "id": 40452833440,
      "event": "workflow_dispatch",
      "head_sha": "02d115a32e4479f353d284c04fc838ba58938d16",
      "reason": "failure"
    }
  ],
  "ci02_verdict": "INCOMPLETE",
  "ci03_verdict": "MISS"
}
<!-- B4-INCOMPLETE-JSON-END -->


## B4 validation audit result

Independent Nyquist audit: Plans 16–18 have green behavioral coverage. Plan 19 bounded-INCOMPLETE protocol was exercised and reconciled; its complete-five gate is blocked by the exhausted sample/budget precondition, not a missing test file. `nyquist_compliant: false` records that prescribed verification remains unexecuted. No substitute tests or manual UAT are requested. CI-02 remains INCOMPLETE and CI-03 MISS. New tests cannot manufacture the missing qualifying sample; further fixture diagnosis and sampling are a scope/budget decision.

## Validation Audit 2026-10-27

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 0 |
| Escalated | 1 |
| Incomplete-protocol checks passed | 1 |


## B4 prior-phase regression gate

Fresh scoped regression from Phase 244–246 VERIFICATION references: 19 existing test files, 558 tests, zero failures (29.6 s), run via `mix test <collected files>` under the canonical GSD 600-second one-shot timeout. Pinned current toolchain and task-owned loopback PostgreSQL 16; temporary npm cache; HEAD held fixed throughout. This prior-phase gate does not resolve the two excluded min-lane fixture failures or manufacture the missing fifth B4 success.

## Local-only gap validation map — Plans 247-20/21 (planned)

This section is a plan-specific map, not executed evidence. The historical green coverage above remains green, and the B3/B4 Nyquist partial status remains **`nyquist_compliant: false`**: Plan 19's five-success reconciliation still cannot run from four successes and an exhausted six-run cap. B4 CI-02 is **INCOMPLETE**, CI-03 is **MISS**, and Phase 247 remains **2/4**. The one off-main diagnostic 40504321590 is separate; its 1/1 budget is spent. Local canary/replay checks can yield diagnostic evidence only.

| Plan/task | Behavior and negative control | Automated command from source root | Evidence to add after execution | Threat ref |
|---|---|---|---|---|
| 247-20 Task 1 | Exact 1.15.8/26.2.5.21 native canary uses the copied unchanged formatter and a fixed A/B case; lost/swapped events, wrong hashes/runtime, malformed TSV, timeout and extra arm fail closed. At most two warmups, three A/B–B/A–A/B pairs and two controls; each child ≤15 s, overall ≤150 s. | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --self-test && python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.json` | `247-LOCAL-CANARY.json`: image/source/formatter hashes, raw arm rows, typed semantic/no-signal/invalid status; record command exit and actual attempt count. | T-247-41, T-247-42 |
| 247-20 Task 2 | Machine projection keeps pre-event boot, post-event wall, historical cause and main gates distinct; altered or omitted arm/report field fails. | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.md` | `247-LOCAL-CANARY.md`: event table, status, limits and local stop; record command exit. | T-247-41 |
| 247-21 Task 1 | B3 training, B4 holdout/failures and diagnostic remain separate; altered run/head/attempt, source classifier/weight, TSV lane/inventory, formula or ratio fails. One offline pass, no fitted parameter. | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --self-test && python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-FROZEN-REPLAY.json` | `247-FROZEN-REPLAY.json`: all cohort IDs, source/input hashes, component rows, exclusions and printed-ratio authority; record command exit. | T-247-43 |
| 247-21 Task 2 | Independent automated review and machine projection preserve CI-02 INCOMPLETE, CI-03 MISS and historical cause UNPROVEN; dropped exclusion, changed status or absent review fails. | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-FROZEN-REPLAY.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-DIAGNOSIS.md --validation .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md` | `247-LOCAL-DIAGNOSIS.md` and this section: reviewer identity, `source: automated-review`, checked hashes, findings/disposition and actual command exit. | T-247-44 |

Execution fills the evidence cells with actual receipt hashes, command results and reviewer findings. An INVALID/no-signal local result is retained as the bounded outcome; it does not trigger replacement samples, a new hosted run or a change to the main acceptance thresholds.

## Plans 247-20/21 actual receipts (append-only)

Plan 20's recorded local series stopped after one async warmup (2,578 ms). The canary is **INVALID**: the parser rejected valid negative monotonic timestamps; registration events and a valid formatter TSV were absent. Zero pairs and zero controls ran. The original Docker preflight receipt remains **PREFLIGHT**. Plan 21 did not invoke the canary or any test suite.

| Plan/check | Actual command or evidence | Result |
|---|---|---|
| 247-20 actual canary | Immutable command/attempt receipt in `247-LOCAL-CANARY.json` and `247-LOCAL-CANARY.md` | INVALID; 1 warmup, 0 pairs, 0 controls; no replacement |
| 247-21 source/arithmetic mutation checks | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --self-test` | PASS; both source-hash and arithmetic mutations were rejected |
| 247-21 frozen replay pass | Single `--run` against the exact cached B3/B4 artifacts; wrote `247-FROZEN-REPLAY.json` | VALID replay provenance; 96 run/lane/partition rows; no new timing sample |
| 247-21 evidence recheck | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-FROZEN-REPLAY.json` | PASS; source snapshots, metadata, artifact hashes, identities and components recomputed |
| 247-21 decision projection | `python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-FROZEN-REPLAY.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-DIAGNOSIS.md --validation .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md` | PASS after independent review receipt; body hash and checked evidence hashes validated |

Run roles and failures remain separated: B3 is training; B4 has four holdout successes and two failed exclusions; diagnostic `40504321590` is off-main and separate; the initial PR failure and B3 failure remain exclusions. Printed total ratios remain acceptance evidence. CI-02 is **INCOMPLETE**, CI-03 **MISS**, historical AMD64 cause **UNPROVEN**, and Phase 247 remains **2/4**. Existing historical validation and Nyquist partial coverage above are unchanged.

Independent review receipt: Codex subagent `replay_reviewer`, `source: automated-review`, PASS. Reviewed diagnosis body SHA-256 `6981c057ef061d5fc25b57fc71bdbc70c80c952bd77b982cae36e935be76ccec`; final replay SHA-256 `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1`. Reviewer independently checked all 96 arithmetic rows and printed-ratio bindings and found no factual or inference errors. Diagnostic ratios are explicitly labeled as saved lane aggregates.

## Local tool repair and final validation

Fresh post-repair checks passed: signed-clock/parser/stderr/producer mutation self-test; deterministic trace-only inheritance, delivery and occurrence-order test (no ExUnit started); saved canary verification/projection; frozen replay source/arithmetic/valid-schema payload mutation self-test; saved 96-row replay/report/validation verification. Original canary, preflight and replay bytes remain unchanged. See 247-LOCAL-TOOLS-FIX-SUMMARY.md for commands, hashes and commits. Final independent review: zero critical, one inherited deferred warning, zero info.

The observed canary remains INVALID: one warmup, zero pairs, zero controls. The repaired tool was not used for another timing series. The replay's B3/B4 payload pins detect later substitution but cannot independently prove original archive/member authenticity; diagnostic payloads are checked against saved manifest digests. This qualification supersedes any broader reading of “VALID replay provenance” above.

The generic regression gate discovered 19 prior-phase test files but resolves to `true` (exit 0): it has no Elixir detector and workflow.test_command is unset. No new prior-phase test pass is claimed. The earlier 558-test source regression remains historical. This local-only delta changes no lib/test/bin/workflow source; fresh checks target the added evidence tools and repository hygiene. Nyquist remains partial (`nyquist_compliant: false`), with Plan 19's full-five controls and Plan 20's semantic observations unexecuted. CI-02 INCOMPLETE, CI-03 MISS, phase 2/4.

## Plan 247-22 incremental continuation — actual validation

This continuation adds evidence for Plan 22 without changing the prior B3/B4 cohorts or the Nyquist status. Task 1's behavioral coverage is green for the mocked/synthetic contract; Task 2's exact scope decision is recorded; Task 3's receipt is verifiable but terminal `INVALID`, so the observed semantic requirement remains partial. No new implementation or test file was created during this audit.

| Plan/task | Observable behavior and coverage | Executed command / evidence | Actual result |
|---|---|---|---|
| 247-22 Task 1 | Synthetic child-output → event/TSV parser → validation receipt → `--verify`/report projection and negative mutations; mocked CLI, binding, timeout, stop, and reservation behaviors. This covers the harness contract without claiming a live ExUnit observation. | `python3 -B -m unittest -v test_exunit_boundary_probe` (from `tools/`); `python3 -B .../exunit_boundary_probe.py --self-test` | PASS, 13 mocked tests; synthetic round-trip PASS. Exact-version trace-only self-test also PASS: `elixir .../exunit_boundary_case.exs --trace-self-test` (no ExUnit started). |
| 247-22 Task 2 | Only an explicit maintainer choice opens the bounded local series; scope is fixed and excludes hosted CI, retries, replacement samples, and acceptance changes. | Decision assertion against `247-LOCAL-CANARY-VALIDATION-DECISION.md` (one recognized `Decision:` line and required cap/no-replacement language) | PASS. Recorded choice: `authorize-one-local-series`, dated 2026-10-27, with the stated bounded scope. |
| 247-22 Task 3 | Raw receipt/report consistency, terminal stopping, and evidence projection; this does not establish a successful semantic boundary or historical CI cause. | `python3 -B .../exunit_boundary_probe.py --verify .../247-LOCAL-CANARY-VALIDATION.json --report .../247-LOCAL-CANARY-VALIDATION.md`; preparation review in `247-22-PREPARATION-REVIEW.md` and independent review in `247-LOCAL-CANARY-VALIDATION.md` | Verifier PASS for a terminal **INVALID** receipt with one attempted async warmup; the child failed during compilation after 407 ms. No event/TSV records, pairs, or controls ran. Independent report review found the projection consistent, with a warning for missing owned Docker container name/ID. |
| 247-22 historical immutability | Plan 20 canary, original preflight, and Plan 21 replay remain byte-identical. | SHA-256 assertions for the three pinned artifacts | PASS, 3/3 unchanged. |

### Plan 247-22 remaining gaps and interpretation

- The Task 1 tests verify mocked and synthetic behavior, not Docker image inspection, container lifecycle, or a real ExUnit run. No such commands were run as part of this validation audit.
- Task 3 did not reach the A/B schedule or controls. The terminal compile failure is an actual invalid observation; it supplies no semantic signal. The missing container identity is an additional provenance limitation.
- A native ARM64 local receipt cannot identify the historical AMD64 minimum-lane cause. B3 remains training; B4 has four successes and two failed exclusions, with a null five-run median. Diagnostic run `40504321590` is off main. CI-02 remains **INCOMPLETE**, CI-03 remains **MISS** at fixed min ratios 1.24/1.28/1.27, CI-01 and CI-04 remain verified, and Phase 247 remains **2/4**.
- Plan 19's complete-five reconciliation remains unexecutable under its exhausted sample cap. Therefore `nyquist_compliant: false` is retained; this continuation does not convert the phase to Nyquist-compliant or close CI-02/CI-03.

Scoped commands run in this audit: the 13 mocked Python unittests, Python synthetic self-test, Elixir trace-only self-test, saved Plan 22 receipt/report verifier, explicit decision-record assertion, and the three historical hash assertions. No full `mix test`, CI command, hosted operation, Docker command, preflight, or observed series was run here.

## Plans 247-23/25 incremental continuation — actual validation

This continuation maps the new Plan 23–25 test and evidence surface without claiming a fresh Elixir suite, semantic canary, or timing measurement. `status: validated` records that the verification map is current; `nyquist_compliant: false` remains because required semantic and numeric evidence is pending technical work, not user UAT.

| Plan/task | Observable behavior and coverage | Executed command / evidence | Actual result |
|---|---|---|---|
| 247-23 Task 1 | Mocked producer/runner behavior covers compile failure and missing marker, CID collision/missing/malformed/mismatched/reused identity, verified-ID-only cleanup, forged status, and report projection. These controls exercise harness behavior, not Elixir runtime semantics. | `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py`; `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --self-test` | PASS: 25 tests, 0 failures; synthetic round-trip PASS. |
| 247-23 Task 2 / 247-25 Task 2 | Saved terminal receipt and generated report can be consumed by the CLI verifier; this is receipt/report integrity only. The verifier's INVALID path does not recompute the failure reason. | `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-PREFLIGHT.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.md` | PASS (INVALID; 0 attempted arms). Raw warning and strict producer classification were independently compared in `247-RECHECK-DISPOSITION.md`; verification pass alone does not establish reason correctness. |
| 247-24 Task 1 | One bounded recheck authorization is recorded against reviewed source hashes; its decision assertion and hash checks are historical plan evidence, not re-run here. | `247-24-SUMMARY.md` and `247-LOCAL-CANARY-RECHECK-AUTHORIZATION.md` | Recorded PASS in Plan 24 summary. No additional authorization or execution occurred in this audit. |
| 247-25 Task 1 | Authorized native ARM64 compile preflight, owned container identity and cleanup, and strict warning gate. | Raw `247-LOCAL-CANARY-RECHECK-PREFLIGHT.json`, reservation, and Plan 25 summary | Actual preflight: child exit 0 and compile marker present, but unused `mode` warning on stderr caused strict INVALID; 0 ExUnit arms, no series receipt, no retry. Owned CID inspection/removal succeeded. This is a real terminal failure, not semantic coverage. |
| 247-25 evidence limits | Runtime semantic behavior, event/TSV production, and timing provenance. | `247-RECHECK-DISPOSITION.md` | Unverified/partial: no ExUnit arms ran; raw preflight lacks start/end/elapsed fields. CR-05 remains open. |
| Phase numeric acceptance | Main wall median and per-lane partition ratios. | Existing `247-B4-INCOMPLETE.json` and `247-RECHECK-DISPOSITION.md` | Unchanged: CI-02 INCOMPLETE (4 successes; `median_wall_s=null`), CI-03 MISS (min ratios 1.24/1.28/1.27), Phase 247 2/4. Plan 25 adds no CI measurement. |

The saved preflight report and receipt verified, but that check confirms only the recorded INVALID envelope and ownership predicates. It does not prove the strict warning reason by itself, establish semantic ExUnit behavior, or establish elapsed-time compliance. Historical B3/B4 cohorts and earlier receipt results remain historical. No implementation/test files were changed; no Docker, Elixir/Mix, network, install, CI, full suite, or new observation was run during this audit.

### Validation Audit 2026-10-27 — Plans 247-23/25

| Metric | Count |
|---|---|
| Gaps found | 4 |
| Harness/evidence checks green | 2 |
| Escalated or still technically unresolved | 2 |
| Plans audited | 3 |
| Numeric gates unmet | 2 |

Disposition: mocked controls and saved receipt/report verification are green for their bounded contracts. The semantic runtime requirement remains partial after the authorized preflight stopped before ExUnit; elapsed-time provenance is absent; CI-02 and CI-03 remain unresolved at the values above. No manual UAT is required or requested. Keep `nyquist_compliant: false` until technical evidence closes the outstanding requirements.

## Offline repair validation — 2026-10-27

Source repair 8c9f1541 is covered by 37 Python tests, synthetic round-trip, immutable old receipt/report checks and a host-only warning-free compile-smoke (Elixir 1.17.3/OTP 27.3.4.15, no ExUnit events). Tests pin forged verdict/projection rejection, monotonic timing and reservation consistency, shared/absolute deadlines, stderr preservation and producer-bound legacy compatibility. All 14 saved evidence files retain their hashes. No Docker, pinned semantic observation or hosted run was performed. Production and prior-phase regression results remain historical; CI-02/03 and Nyquist compliance remain incomplete. See 247-OFFLINE-REPAIR.md and its clean independent review.
