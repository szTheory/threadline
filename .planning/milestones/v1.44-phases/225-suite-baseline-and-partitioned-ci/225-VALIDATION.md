---
phase: "225"
slug: "suite-baseline-and-partitioned-ci"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-30"
---

# Phase 225 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 locally; 1.15.8 / .tool-versions / 1.20.4 across the CI lanes) |
| **Config file** | `test/test_helper.exs` + `config/test.exs` |
| **Quick run command** | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/flake_classifier_contract_test.exs` |
| **Full suite command** | `mix ci.all` (runs unpartitioned `mix verify.test`, D-08); `mix verify.test_partitioned` for the partitioned path |
| **Estimated runtime** | quick: seconds; full suite: ~4–5 min locally |

---

## Sampling Rate

- **After every task commit:** Run the quick contract tests, plus the targeted test file(s) the task changed.
- **After every plan wave:** Run `mix ci.all`.
- **Before `/gsd-verify-work`:** `mix ci.all` green, plus:
  - `bin/ci-test-partitions --self-test` green;
  - the D-18 `--repeat-until-failure 200` proof on the three SUITE-03 files;
  - `check-citations.py --self-test` and the check on `225-BASELINE.md`;
  - at least 2 cited CI runs of the partitioned step, after a push granted by the maintainer (D-14c).
- **Max feedback latency:** ~60 s for the quick command.

---

## Per-Task Verification Map

Plans fill this table in. Every row must name one of the following:

| Task | Requirement | Behavior | Test Type | Automated Command | Status |
|------|-------------|----------|-----------|-------------------|--------|
| 225-01 T1 | SUITE-01 | Checker copied and widened; timing script formula and inclusive verdict | script self-tests | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py --self-test`; `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --self-test` | ⬜ |
| 225-01 T1 | SUITE-01 | Before figures reproduced from run 36730596489 (288/291/267 s, proxy 20) | CI evidence | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36730596489` | ⬜ |
| 225-01 T2 | SUITE-01 | Every figure in the baseline doc is cited | doc check | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py .planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` | ⬜ |
| 225-02 T1 | SUITE-03 | Emitting-process filter; unrelated emitter dropped (D-17) | unit + mutation control | `mix test test/threadline/telemetry_helpers_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs` | ⬜ |
| 225-02 T2 | SUITE-03 | The three files are async and isolated, 200 repeats | unit, repeated | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/telemetry_helpers_test.exs --repeat-until-failure 200` | ⬜ |
| 225-03 T1 | SUITE-02 | The partition gate fails closed (runtime) | script self-test | `bin/ci-test-partitions --self-test` | ⬜ |
| 225-03 T1 | SUITE-02 | The partitioned suite is green locally | integration | `mix verify.test_partitioned` | ⬜ |
| 225-03 T2 | SUITE-02 | Partition step shape, mutation controls, parity pins | contract | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs` | ⬜ |
| 225-03 T3 | SUITE-02 | Flake Detection budget re-derived; full local gate | contract + gate | `mix test test/threadline/flake_classifier_contract_test.exs`; `mix ci.all` | ⬜ |
| 225-04 T2-T3 | SUITE-02 | CI shows at least 30% step gain and at most 10% more billed minutes over at least 2 runs | CI evidence | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36730596489 <after-1> <after-2>` | ⬜ |
| 225-04 T3 | SUITE-03 | No new flake over a cited Flake Detection run | CI evidence | the dispatched Flake Detection run's classifier outcome | ⬜ |
| 225-02, 225-03, 225-04 | SUITE-06 | Suite wall clock before and after | measured | median of 3 plain `mix test` runs, plus the timing script | ⬜ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `bin/ci-test-partitions` (D-09), with `--self-test` (D-10)
- [ ] `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py` (D-14a)
- [ ] `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py` and `fixtures/`, copied from 222 with the phase range widened to cover 224–230 (D-14b)
- [ ] `test/support/telemetry_helpers.ex`: `attach_telemetry!/1` (D-16)
- No framework install is needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CI "after" runs | SUITE-02, SUITE-03 | A push, PR or dispatch needs an explicit named grant from the maintainer (D-14c) | The maintainer grants the push and dispatch; the agent then runs the timing script and cites the run IDs |

*Everything else is automated.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
