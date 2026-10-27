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
| CI-02 | matrix == inventory `votingProjects`; check names; retired name; needs exemption; job ids; time-to-red | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ | ✅ green | **PASS** — 468 s median / 5 runs (≤ 540 s) |
| CI-02 | `bin/browser-full-projects` resolves `${{ matrix.project }}`, fails closed | contract + mutation | `mix test test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` | ✅ | ✅ green | **PASS** — 468 s median / 5 runs (≤ 540 s) |
| CI-02 | receipt merges N files; missing leg → not executed; duplicates rejected | unit | `npm --prefix examples/threadline_phoenix/e2e run test:unit` | ✅ | ✅ green | **PASS** — receipt validated both browser legs on PR #95 and the five main runs |
| CI-02 | download-artifact SHA pin + node24 | contract | `mix test test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs` | ✅ | ✅ green | **PASS** — PR #95 checks green |
| CI-02 | measurement script (attempt-1 wall, median) | contract (fake gh) | `mix test test/threadline/measure_main_ci_contract_test.exs` | ✅ | ✅ green | **PASS** — 468 s median / 5 attempt-1 main runs (≤ 540 s) |
| CI-03 | scope=toolchain filtering, exactly-once, summary count, `--ingest-weights` | self-test | `bin/ci-test-partitions --self-test` | ✅ | ✅ green | **OPEN / MISS** — all 3 lane ratios exceed 1.15; see `247-MEASUREMENT.md` |
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

**Observed:** CI-01 summary and timing artifacts were present in main-run evidence (`247-OBSERVATION.md`). CI-02 passed at 468 s median over five attempt-1 runs. CI-03 was measured and missed in all three lanes; it remains an unmet phase requirement. CI-04 was exercised on the min lane, including a synthetic `setup_all` hang repro that was named and terminated in 525 s (`247-08-SUMMARY.md`).

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all formerly missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] Automated verification coverage is complete (`nyquist_compliant: true`); CI-03 remains a measured MISS and the phase requirement is not complete.

**Approval:** validation map audited; no human UAT required by repository policy.

## CI-03 Gap-Closure Sampling (planned, 247-14/15)

The existing CI-01, CI-02 and CI-04 rows above retain their executed evidence. These rows specify the new checks and remain planned until the corresponding SUMMARY and main-run receipts exist.

| Plan | Behavior | Automated check | Gate |
|------|----------|-----------------|------|
| 247-14 | Three distinct successful attempt-1 main artifacts per min/latest/current lane produce path-sorted, exact-inventory weights; bad TSVs, wrong output and interrupted ingest fail safely | `bin/ci-test-partitions --self-test` plus `mix test test/threadline/ci_topology_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` on ephemeral PostgreSQL | Planned; source run IDs and artifact counts in 247-14-SUMMARY.md |
| 247-14 | Unset/current/min/latest route to the intended file and assign every eligible test exactly once with N=4, colocation and watchdog unchanged | Both Bash self-tests; local full and `THREADLINE_CI_LANE=min THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned` on ephemeral PostgreSQL | Planned; mutation controls must fail on wrong routing or incomplete inventory |
| 247-15 | Exact candidate preserves required CI, browser timing/receipt and named hang coverage before landing | `CI=true mix ci.all`, `bin/ci-test-partitions --self-test`, PR required checks and `bin/verify-branch-protection` | Planned; no new human verification |
| 247-15 | First three qualifying post-squash main runs each have min/current/latest max/min ≤ 1.15; five-run wall median remains ≤ 540 s | `bin/measure-main-ci --since <new-squash-sha> --count 5 --ratios --format json`; compare all nine values and median | Planned; any miss is recorded as MISS with IDs and values, never as PASS |

## Validation Evidence

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
