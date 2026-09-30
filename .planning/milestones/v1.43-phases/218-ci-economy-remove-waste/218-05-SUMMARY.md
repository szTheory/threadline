---
phase: 218-ci-economy-remove-waste
plan: 05
subsystem: ci
status: complete
tags: [ci, flake-detection, github-actions, econ-01]
requires: ["218-02", "218-04"]
provides:
  - "bin/ci-sha-gate (run | skip | broken-upstream), shared with Browser-full in 218-07"
  - "classify-flake-run outcomes inconclusive, broken-upstream and skip, plus a reason= output"
  - "a weekly Flake Detection lane with a bounded budget (15 repeats, timeout(1) 55m, step 58, job 70)"
affects: ["218-06", "218-07", "218-08"]
tech-stack:
  added: []
  patterns:
    - "gate step with an id, and every heavy step carrying if: steps.gate.outputs.decision == 'run'"
    - "timeout(1) wrapper so a budget expiry still writes exit_code (124/137)"
    - "fake-gh decision table through the GH_BIN seam"
key-files:
  created:
    - bin/ci-sha-gate
    - test/threadline/ci_sha_gate_contract_test.exs
  modified:
    - bin/classify-flake-run
    - test/threadline/flake_classifier_contract_test.exs
    - .github/workflows/flake-detection.yml
    - mix.exs
    - CONTRIBUTING.md
    - .github/workflows/branch-protection.yml
    - .github/workflows/community-health.yml
decisions:
  - "verify.flake itself moves to 15 repeats, so CI and local use share one entrypoint. Longer local soaks use mix test --repeat-until-failure N"
  - "Only schedule honors the green-SHA skip. workflow_dispatch and push always run"
  - "inconclusive and broken-upstream end red and file the tracking issue. Only pass and skip end green, and skip needs a prior pass on the same SHA (orchestrator resolution 1, RESEARCH P1)"
  - "Clean-iteration count on a budget expiry is the header count minus one, because the last iteration whose header printed was cut off"
  - "The raw-log upload runs only when the gate decided run; a gated-off run has no log"
metrics:
  duration: "about 15 min"
  completed: 2026-09-27
  tasks: 2
  files: 9
actuals:
  tokens: 13078
  tasks: 2
  commits: 2
plan_head_before: df79918bd716520b27e6a7e67cea51693919d9c0
plan_head_after: 7bfafd8bca1231a419fff2a78af4083bbe64e391
---

# Phase 218 Plan 05: Bounded weekly Flake Detection with a green-SHA gate Summary

Flake Detection now runs weekly (Monday 07:00 UTC) plus on demand. It soaks 15 repeats under a 55 min `timeout(1)` budget, with a 58 min step timeout and a 70 min job timeout. A budget expiry is classified `inconclusive`, not `unknown`. The new `bin/ci-sha-gate` skips a scheduled run on a SHA this workflow already proved green, reports `broken-upstream` when ci.yml is red on the SHA with no green re-run, and runs the suite on any API error.

## What was built

**Task 1 (tracer), commit 037c889b.** The lane is now bounded and weekly:
- `flake-detection.yml` has the weekly cron `0 7 * * 1` plus `workflow_dispatch`.
- The header records the D-01 arithmetic from run 35967937335: 288 s + 15 × 165 s = 2,763 s, about 46 min.
- The repeat step runs `timeout --signal=TERM --kill-after=60s 55m mix verify.flake`, so a budget expiry still writes `exit_code=124` (or 137 after the kill).
- `bin/classify-flake-run` maps 124/137 to `inconclusive` when at least one header was printed, and to `unknown` with the reason "timed out before the suite started" when none was. Every arm now writes `reason=` to GITHUB_OUTPUT, and stdout is still the bare token.
- `verify.flake` runs 15 repeats. CONTRIBUTING names the four non-pass outcomes: broken, flaky, inconclusive and broken-upstream.
- The daily branch-protection and community-health cadence comments now name the weekly lane. Only comments changed; both `cron:` lines are byte-identical.

**Task 2, commit 7bfafd8b.** `bin/ci-sha-gate` plus its wiring:
- **Gate script.** It validates `--sha` against `^[0-9a-f]{7,40}$` and `--workflow`/`--upstream` against `^[A-Za-z0-9._-]+\.ya?ml$` before building a URL; a bad value exits 2. It queries `runs?head_sha=S&status=success|failure&per_page=1` and reads only a numeric `total_count`. `run` is the default arm, so a gh or jq failure falls through to it.
- **Classifier.** It checks `GATE_DECISION` (broken-upstream or skip) before the exit code.
- **Workflow.**
  - The job has `actions: read`.
  - The gate step (`id: gate`) runs right after checkout.
  - setup-beam, the deps cache, deps.get, compile and the repeat step each carry `if: steps.gate.outputs.decision == 'run'`, as does the upload step.
  - The issue step and the fail step also exclude `skip`.

## TDD evidence

**Task 1 RED** (tests written before any script or workflow change): `17 tests, 7 failures`. Excerpts:

```
4) test Test 1c: ... exit 137 (killed after the grace period) with 2 headers -> inconclusive
   Assertion with == failed
   code:  assert output == "inconclusive"
   left:  "flaky"
   right: "inconclusive"

7) test Test 1c: ... exit 124 with 0 headers -> unknown, timed out before the suite started
   Assertion with =~ failed
   code:  assert gh_output =~ ~r/^reason=.*timed out before the suite started/m
   left:  "classification=unknown\n"

6) test Test 5: bounded weekly lane shape ... the committed workflow is weekly plus dispatch ...
   left:  ["exactly one cron: and it must be weekly (one fixed day of week)",
           "repeat step must run mix verify.flake under the timeout(1) budget",
           "repeat step timeout-minutes (nil) must be below the job's (180)"]
```

The exit-137 row shows the defect this plan fixes: before the change, a killed run was classified `flaky`.

GREEN: `17 tests, 0 failures`.

**Task 2 RED:** `41 tests, 23 failures`. All 21 gate rows failed with `:enoent` (`bin/ci-sha-gate` did not exist yet), and both `GATE_DECISION` classifier rows failed:

```
** (ErlangError) Erlang error: :enoent:
  * 1st argument: invalid port name
  code: r = gate(t, event: "schedule", upstream: true, up_success: count(3))
```

GREEN: `41 tests, 0 failures`. After the Test 5 gate-wiring block was added: `43 tests, 0 failures`.

## Verification

- `mix test test/threadline/ci_sha_gate_contract_test.exs test/threadline/flake_classifier_contract_test.exs`: 43 tests, 0 failures.
- Full `mix test` at 7bfafd8b: `9 properties, 2438 tests, 0 failures, 3 excluded`.
- `actionlint -shellcheck=`: clean. `shellcheck bin/ci-sha-gate bin/classify-flake-run`: clean.
- `mix verify.format`: exit 0. `mix verify.credo`: no issues.
- `bin/verify-repo-hygiene`: clean.
- All plan acceptance greps pass:
  - the `verify.flake` alias at 15, the weekly cron, the timeout wrapper and `2,763` each match once;
  - `nightly flake` matches 0 times in both files, and the cron diff is empty;
  - the gate `if:` matches 6 times and `actions: read` once;
  - `GH_BIN=false` gives `decision=run` with exit 0, and `--workflow ../x` exits 2;
  - both commits contain exactly the planned files.
- Tracer gate: `<verify>` was re-run end to end after Task 1 and passed before Task 2 started.

## Deviations from Plan

None needed a Rule 1-4 fix. Some small choices were within the plan's discretion:

1. **Stale wording fixed in files already being edited.** Three phrases still described the old nightly lane: "120-minute nightly job" in the classifier header and the workflow's classify comment, "a nightly failure is invisible", and "each night" in the issue body. They now say scheduled / weekly / each run.
2. **Reworded the permissions comment.** The acceptance check wants `actions: read` to match exactly once, so the explanatory comment above `permissions:` says "the actions scope (read)" instead of repeating the literal.
3. **More test coverage than the plan listed.** The gate test adds a `missing GITHUB_REPOSITORY` exit-2 row, an empty-response row, a "green upstream alone never skips" row and a "non-schedule events never query their own workflow" row. The classifier test adds a `GATE_DECISION=run` fall-through row. All sit inside the `<behavior>` scope.
4. **Upload-step comment.** "Always uploaded" became "uploaded whenever the suite ran", to match the new `if:`.

## Environment note (not a code defect)

The first full `mix test` run reported `2438 tests, 1 failure`. A `mix test --failed` rerun then crashed on `FATAL 53300 too_many_connections`. At that point another local project's test run (the `rindle_test` database) held 99 connections to the shared local Postgres. The run waited for those connections to drop below 40 and then ran the full suite again: 0 failures. The failing test in the first run was not captured. The likely cause is connection exhaustion from the other project, but that is inference.

## Hand-offs

- No pushes, PRs, workflow dispatches or GitHub writes were made. The first real exercise of the gate and the timeout wrapper on a hosted runner is the 218-08 dispatch, after the maintainer pushes.
- The `timeout(1)` wrapper was not run locally: this plan's tests assert its presence in the workflow, not its runtime behaviour. On ubuntu-24.04 it is GNU coreutils `timeout`.
- **For 218-06:** the issue body's `*)` arm still says "unknown / no header" for every non-broken, non-flaky outcome, including `inconclusive` and `broken-upstream`. It also still points to the log artifact, which a `broken-upstream` run does not upload. The plan moved the truthful issue text and close-on-pass to 218-06; the `reason=` output it needs is now available from the classify step's GITHUB_OUTPUT.

- **ECON-01 left Pending in REQUIREMENTS.md, on purpose.** Its last clause ("the report no longer falsely says 'no header'") is the issue-text fix in 218-06, which also lists ECON-01. Mark ECON-01 complete when 218-06 lands.

## Threat surface

All three threats in the register are mitigated:
- **T-218-09:** skip requires `schedule` plus an exact same-workflow `head_sha` success, and non-proofs end red.
- **T-218-10:** regex validation happens before the URL is built, and the jq type check guards `total_count`.
- **T-218-11:** the job permissions are exactly actions/contents read plus issues write.

No new surface beyond the register.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: bin/ci-sha-gate (executable), test/threadline/ci_sha_gate_contract_test.exs
- FOUND: commits 037c889b, 7bfafd8b
