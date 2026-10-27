---
phase: "247"
slug: "ci-critical-path-and-suite-lanes"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-26"
---

# Phase 247 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `247-RESEARCH.md` § Validation Architecture.

---

## Latest live evidence — B3

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

## Planned CI-03 gap closure — Plans 247-16 through 247-19

These are pending checks for the appended gap plans, not executed results. The B3 receipt above remains the authoritative observed state: CI-02 PASS at 444 s median and CI-03 MISS on seven of nine fixed first-three ratios. The historical failed motion-fixture run 40435657557 remains excluded.

| Plan | Behavior and failure signal | Automated verification | Acceptance state |
|---|---|---|---|
| 247-16 Task 1 | Long async wall duration is a lower bound on modeled partition cost; removing that bound fails the synthetic assignment control. B3 min TSVs strictly ingest to 206 selected files and four runner processes without omissions. | `bin/ci-test-partitions --self-test` and `/bin/bash bin/ci-test-partitions --self-test` | Pending; local prediction is never a CI-03 PASS. |
| 247-16 Task 2 | Three lane files come from the same three successful B3 attempt-1 main runs; exact inventories are current 269/min 206/latest 206. Existing-assignment RMS falls from about 35.7 to 7.0 s min, 29.3 to 7.1 s latest and 17.6 to 14.5 s current when the longest async file is floored. Model-fit or predicted-ratio failure stops before landing. | Both shell self-tests; `mix test test/threadline/ci_topology_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` on ephemeral PostgreSQL 16; full and min/toolchain `mix verify.test_partitioned`; `mix verify.format`; `mix verify.credo` | Pending; prove exact-once execution and preserve watchdog/ratio warning. |
| 247-17 Tasks 1–2 | Modal has hidden and focus has returned to the exact Show Modal opener before the unchanged toast Close keyboard Enter. The focused case and entire motion spec pass in desktop/mobile with retries disabled; the previous failed run stays named. | `mix verify.example_browser operator-motion.spec.ts --project=desktop-chromium --project=mobile-chromium --retries=0` with focused `-g` case first, ephemeral PostgreSQL 16 | Pending; no production UI or worker-setting change. |
| 247-18 Tasks 1–2 | Combined source passes full local `CI=true mix ci.all`, both shell self-tests, repo hygiene and branch-protection readback; the exact tested SHA has green PR lane/browser/receipt/required checks before SHA-guarded squash. Recorded PR number/head/squash must equal live GitHub metadata and protected main's source tree. | Local named gates, `gh pr view <recorded-number> --json state,headRefOid,mergeCommit`, exact source-tree comparison and required-context readback | Pending; standing grant must still apply. |
| 247-19 Task 1 | Plan 18's recorded B4 identity is rechecked before spending. First three qualifying successful attempt-1 main runs at that head supply all nine ratios; first five supply wall median. Failed/cancelled attempts are listed; total new-head runs are capped at six. | Live PR/main precondition plus `bin/measure-main-ci --since <new-squash-sha> --count 5 --ratios --format json` saved unchanged as B4 JSON; both reports receive identical B4 gate blocks | Pending; incomplete sample requests a concrete spend decision. |
| 247-19 Task 2 | A fresh canonical reader response, persisted B4 JSON and B4 records in BOTH MEASUREMENT/VALIDATION agree on exact head, five chronological IDs/events/walls, median, first-three nine ratios, exclusions and derived numeric PASS/MISS. | Inline Python reconciliation in 247-19-PLAN.md; independent `gh` PR/main identity check and SEED-006 bound on CI-02 pass | Pending; CI-03 is met only if all nine values are <= 1.15, CI-02 only if median <= 540 s. A miss stays open. |

Plan 16's long-async control is non-vacuous: on the B3 min/latest partition-4 data, the old 0.292 additive model charges the 79–105 s `deps_audit_gate_test.exs` about 23–31 s, and therefore predicts a much shorter partition than was observed. The revised objective is `sync_sum + max(0.292 * async_sum, longest_async_wall)`, preserving four bins and colocation. The three-run fixed B3 sample is used only for model diagnosis and weight refresh; Plan 19 must obtain a fresh exact-head sample to decide the requirement.


## Gap planning verification — Plans 16–19 (2026-10-27)

Independent plan check passed after one revision. The revision split exact-head landing from measurement and added merged-PR/squash identity and persisted/live/report reconciliation gates. All four new plans pass `verify plan-structure`; all eight `<automated>` commands pass Bash syntax checks and the embedded reconciliation Python compiles. Verify-command path and failure-direction probes have no findings for the new plans. Decision coverage is 19/19; post-planning coverage is 23/23 (four requirements plus nineteen decisions); duplicate threat IDs: zero. `git diff --check` passes. These are planning checks only: no candidate implementation, browser run, landing or new numeric measurement was performed. CI-03 remains unmet.
