---
phase: 221-ci-names-and-order
plan: 01
status: complete
subsystem: ci-contracts
tags: [ci, contracts, alls-green, measurement]
requires: []
provides:
  - "required_gate_errors/1 (SC-4 gate wiring contract, rules gate-if/gate-step/gate-inputs/gate-jobs-input/gate-name/job-ids)"
  - "@ci_job_ids frozen 14-id literal (SC-3 id pin)"
  - "time-to-red.py collect/order/check with frozen NAME_HISTORY (D-13, D-14)"
  - "10 committed run JSONs for the D-06 order"
affects: [221-02, 221-03, 221-04]
tech-stack:
  added: []
  patterns:
    - "gate mutation harness where each control mutates the whole %{path => text} map, so a control can add a second workflow file"
    - "offline order regeneration from committed raw run JSON through importlib reuse of the 219 arithmetic"
key-files:
  created:
    - .planning/phases/221-ci-names-and-order/tools/time-to-red.py
    - .planning/phases/221-ci-names-and-order/raw/ci/runs/ (10 run JSONs)
    - .planning/phases/221-ci-names-and-order/deferred-items.md
  modified:
    - test/threadline/ci_workflow_parity_contract_test.exs
decisions:
  - "required_gate_errors/1 is split into gate_if/gate_step/gate_step_shape/gate_input/gate_jobs_input/gate_name/gate_job_id helpers so credo's complexity check passes. The rules are the same as the RESEARCH Pattern 3 probe."
  - "The gate test's control list mutates the whole workflows map (an `on_ci` wrapper for ci.yml edits), so the zz-spoof.yml control fits the same loop."
metrics:
  duration: "about 30 min"
  completed: 2026-09-28
estimate:
  tokens: 90000
  tasks: 3
actuals:
  tokens: 122000  # chars/4 over the whole diff; the 10 raw JSONs are about 117k of it, code alone about 5k
  tasks: 3
  commits: 3
plan_head_before: 9ca4399693e131f44ac0e9a1537423ca1c768822
plan_head_after: d98b68c97af7ab988cc6705c5eec82595cac2e09
---

# Phase 221 Plan 01: CI required gate contract and time-to-red tool Summary

`required_gate_errors/1` now pins the `CI required` aggregate from parsed YAML: `if: always()`, a single alls-green step at a full SHA, a `with` allowlist of exactly `jobs: ${{ toJSON(needs) }}`, one `CI required` job across all workflows, and a frozen 14-id set. There is a mutation control for every rule. `time-to-red.py` reproduces the D-06 order offline from 10 committed runs.

## What was built

- **Task 1 (tracer, c005baa8):** `@ci_job_ids` (frozen sorted `~w(...)` literal, not derived from any other attribute), `gate_norm/1` and `required_gate_errors/1` next to `voting_lane_errors/1`, with the D-11/D-12 comment. The new test `CI required gate wiring cannot be made vacuous (SC-4)` sits in the `voting lanes and PostgreSQL images (LANE-01)` describe block. It has the `delete if: always()` control and the `${{ always() }}` positive control. The tracer gate was checked against the real ci.yml: with `if: always()` deleted, the suite printed `43 tests, 1 failure` and `rule=gate-if: ci-required must run \`if: always()\`, got nil`. ci.yml was restored with `git checkout -- .github/workflows/ci.yml` and `git status --porcelain .github` printed nothing.
- **Task 2 (a8a53c3f):** controls for step `if: false` and `uses` replaced by `run: echo ok` (the uses line is matched by a 40-hex regex, not a hard-coded SHA) → gate-step. Quoted `"allowed-skips"` → gate-inputs. `jobs: '{}'` → gate-jobs-input. A `.github/workflows/zz-spoof.yml` with a second `CI required` job → gate-name. `verify-format` renamed to `verify-fmt` everywhere → job-ids. Positive controls: the `# allowed-skips` comment line and `${{ always() }}`. A fail-closed control: unparseable ci.yml → yaml-parse. The 3 contract files ran at 72 tests, 0 failures.
- **Task 3 (d98b68c9):** `time-to-red.py` (stdlib only; loads 219 `summarize-ci.py` via `spec_from_file_location` and leaves it unedited). It contains `RUNS`, `RENAME_SHA = None`, `ERA_BOUNDARY_RUN = None`, `NAME_HISTORY` (the 14 pre-221 names plus the 3 removed in 218-04) and `job_id/1`, with `collect`/`order`/`check`. `collect` copied 5 runs from 219 raw data and fetched 5 with read-only `gh api` GETs in the 219 schema. `order` output:

| id | p50 s | max s | n |
|---|---|---|---|
| verify-release-shape | 8 | 11 | 10 |
| verify-repo-hygiene | 8 | 43 | 10 |
| verify-format | 17 | 23 | 10 |
| verify-deps-audit | 36 | 41 | 10 |
| verify-compile-no-optional | 59 | 61 | 10 |
| verify-hex-evaluator | 70 | 100 | 10 |
| verify-pgbouncer-topology | 77 | 126 | 10 |
| verify-credo | 78 | 83 | 10 |
| verify-bump-rehearsal | 151 | 171 | 10 |
| verify-dialyzer | 158 | 188 | 10 |
| verify-test (min lane) | 342 | 390 | 10 |
| verify-capture | 391 | 466 | 10 |
| verify-example-browser | 565 | 638 | 10 |

This matches D-06 and every RESEARCH nearest-rank figure. `check` prints `no @time_to_red_order literal` and exits 2, as expected until plan 02 adds the literal.

## Verification

- `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/release_control_plane_contract_test.exs`: 72 tests, 0 failures
- `mix format --check-formatted`: clean
- `time-to-red.py order | tail -1` equals the exact D-06 literal; the raw directory holds 10 JSON files
- `bin/verify-repo-hygiene`: 4106 tracked text files clean. The username grep over the phase directory and a home-path grep over the tool and raw JSON printed nothing.
- `git status --porcelain` of the 218 and 219 phase directories printed nothing (the frozen tools are untouched)
- `mix verify.credo` exits 8, but only on **two findings that were already there** (see Deferred Issues). No credo finding comes from this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `gate_step_errors/1` tripped credo's cyclomatic complexity check (11 > 9)**
- **Found during:** Task 2 (`mix verify.credo` acceptance)
- **Issue:** Task 1 committed the probed Pattern 3 step checks in a single function
- **Fix:** split it into `gate_step_shape_errors/1`, `gate_input_errors/1` and `gate_jobs_input_errors/1`, with the rules and messages unchanged
- **Files modified:** test/threadline/ci_workflow_parity_contract_test.exs
- **Commit:** a8a53c3f

### Notes

- Task 2 is marked `tdd="true"`, but Task 1 had already implemented every rule. So there was no failing-first step: each control proves its rule red inside the harness itself, and the harness asserts the named `rule=` fragment and `refute mutated == workflows`.

## Deferred Issues

- `mix verify.credo` is red at the plan base (9ca43996). It reports two `nested too deep` findings in `every_lane_step_error/3` and `image_scan_units/1` in the parity test file. They came from unlanded 220 commits and are outside this plan's scope. The details are in `deferred-items.md`. The plan's acceptance line `mix format --check-formatted && mix verify.credo exits 0` cannot hold until those two findings are fixed. They must be fixed before landing, because the `verify-credo` CI lane runs the same check.

## Known Stubs

None. `RENAME_SHA` and `ERA_BOUNDARY_RUN` are `None` by design: plan 04 sets them at landing.

## Threat Flags

None. T-221-01 through T-221-05 are mitigated as planned. The tool only issues GET requests.

## Self-Check: PASSED

- FOUND: test/threadline/ci_workflow_parity_contract_test.exs (`defp required_gate_errors(`, `@ci_job_ids`)
- FOUND: .planning/phases/221-ci-names-and-order/tools/time-to-red.py
- FOUND: 10 files in .planning/phases/221-ci-names-and-order/raw/ci/runs/
- FOUND: c005baa8, a8a53c3f, d98b68c9
