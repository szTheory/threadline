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

| Requirement | Behavior | Test Type | Automated Command |
|-------------|----------|-----------|-------------------|
| SUITE-01 | Every figure in the baseline doc is cited | script self-test + doc check | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py --self-test` and `... check-citations.py .planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` |
| SUITE-02 | The partition gate fails closed (runtime) | script self-test | `bin/ci-test-partitions --self-test` |
| SUITE-02 | The partition step's shape and its mutation controls | contract | `mix test test/threadline/ci_topology_contract_test.exs` |
| SUITE-02 | Parity pins updated, with mutation inputs kept intact | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` |
| SUITE-02 | Flake Detection budget re-derived | contract | `mix test test/threadline/flake_classifier_contract_test.exs` |
| SUITE-02 | The partitioned suite is green locally | integration | `mix verify.test_partitioned` |
| SUITE-02 | CI shows ≥30% wall-clock gain and ≤10% more runner-minutes | CI evidence | `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.sh <run-id>` on the before and after runs |
| SUITE-03 | The three files are async and isolated | unit + mutation control | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs --repeat-until-failure 200` |
| SUITE-06 | Suite wall clock before and after | measured | the median of 3 plain `mix test` runs, plus the timing script |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `bin/ci-test-partitions` (D-09), with `--self-test` (D-10)
- [ ] `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.sh` (D-14a)
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
