---
phase: 247-ci-critical-path-and-suite-lanes
plan: 03
subsystem: ci
tags: [github-actions, playwright, ci-observability, gh-cli, contract-tests]
status: complete

requires: []
provides:
  - "CI-01: slowest browser specs (top 20 + per-project/per-file totals + unattributed) in the verify-example-browser job summary and a 14-day `browser-timings-all-<run_id>` artifact"
  - "test:unit runs all three e2e TS unit test files"
  - "bin/measure-main-ci: read-only attempt-1 reader for the D-08 median and the D-12 partition max/min ratios"
affects: [247-05, 247-07, 247-10, "Land B1", "D-08 live read", "D-12 live read"]

actuals:
  tokens: 11550
  tasks: 3
  commits: 3
plan_head_before: ab63f2ab83ba3dfb1fe06886ca292676dc31e50f
plan_head_after: 2d74d00a61eaa47bd3c85b2cb75eaee1f7190151

tech-stack:
  added: []
  patterns:
    - "Fail-soft diagnostic CI step: always() + file-exists guard, script prints ::warning:: and never sets exitCode"
    - "Pure rule-list contract (slow_specs_errors/2) with one String.replace mutation control per rule plus a scope control"
    - "Closed symbolic gh_read boundary measured from /attempts/1 only"

key-files:
  created:
    - examples/threadline_phoenix/e2e/support/slow-specs.ts
    - examples/threadline_phoenix/e2e/support/slow-specs.test.ts
    - bin/measure-main-ci
    - test/threadline/measure_main_ci_contract_test.exs
  modified:
    - examples/threadline_phoenix/e2e/package.json
    - .github/workflows/ci.yml
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/partition_weights.txt

key-decisions:
  - "247-03: bin/measure-main-ci reports median_wall_s null when state is insufficient, so a partial median can never be read as the D-08 number"
  - "247-03: a head equal to --since is treated as identical without a compare API call; compare results are cached per head sha"
  - "247-03: slow-specs unattributed_ms is stats.duration minus summed results and is documented as negative under parallel workers"

patterns-established:
  - "Read loops in gh-calling bash scripts read from fd 3 so a gh child cannot consume the loop's stdin"

requirements-completed: []

coverage:
  - id: D1
    description: "slow-specs.ts renders top-20 table, totals and timings JSON; fail-soft on missing/malformed/oversized reports"
    requirement: CI-01
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/e2e/support/slow-specs.test.ts (npm --prefix examples/threadline_phoenix/e2e run test:unit, 32 pass)"
        status: pass
  - id: D2
    description: "ci.yml timings step and upload pinned in browser_journey_evidence_contract_test.exs with mutation controls"
    requirement: CI-01
    verification:
      - kind: unit
        ref: "test/threadline/browser_journey_evidence_contract_test.exs (CI-01 describe block)"
        status: pass
  - id: D3
    description: "bin/measure-main-ci attempt-1 median, exclusions, insufficient state, ratios, closed gh boundary"
    requirement: CI-02
    verification:
      - kind: unit
        ref: "test/threadline/measure_main_ci_contract_test.exs (9 tests)"
        status: pass
  - id: D4
    description: "CI-01 step summary visible on a real main run after Land B1"
    requirement: CI-01
    verification:
      - kind: other
        ref: "backstop: read after Land B1"
        status: unknown

duration: ~10min
completed: 2026-10-26
---

# Phase 247 Plan 03: Slowest browser specs and main-CI measurement reader Summary

**Every browser E2E run now writes its 20 slowest Playwright specs to the job summary, with per-project and per-file totals and a 14-day timings JSON artifact. The run can never fail because of it. A committed, read-only `bin/measure-main-ci` reads attempt-1 timings from GitHub to produce the D-08 median and the D-12 partition ratios.**

## Performance

- **Started:** 2026-10-26T14:33Z (approx.)
- **Completed:** 2026-10-26T14:43Z
- **Tasks:** 3
- **Files modified:** 8 (4 created, 4 modified)

## Accomplishments

- `slow-specs.ts` (node built-ins only) walks the existing Playwright JSON report. It sums durations across retries, flags retried tests, and skips skipped or never-run tests. It drops and counts tests whose project name is unsafe, escapes `|` and newlines, caps titles at 160 characters, and refuses reports over 20 MiB. Every failure path prints `::warning::slow-specs:` and exits 0.
- `verify-example-browser` has two new steps after the Playwright run: `Summarize slowest browser specs` (`if: always()`, guarded on the report file and on tsx existing) and `Upload browser spec timings` (pinned upload-artifact v7.0.2, `if-no-files-found: warn`, 14 days). The reporter config is unchanged.
- `test:unit` now runs `operator-surface-paths`, `operator-ci-evidence` and `slow-specs`. Before this, nothing ran the evidence tests.
- The browser contract pins seven rules: step, always, fail-soft, guard, artifact, retention and test-unit-wiring. Each rule has a mutation control that turns it red, plus a scope control: moving the step out of the browser job fails the contract.
- `bin/measure-main-ci` measures wall and job times from `/attempts/1` only. Cancelled or failed attempt-1 runs are excluded and listed, and runs before `--since` are not selected. If fewer than `--count` runs qualify, it returns `state: insufficient` with a null median. `--ratios` parses the `| max/min |` row from ANSI-coloured, timestamp-prefixed job logs.

## Task Commits

1. **Task 1: slow-specs.ts tracer + ci.yml wiring** - `632bc0c5` (feat). Tracer gate: the end-to-end verify was re-run and passed before expanding.
2. **Task 2: CI-01 contract pins with mutation controls** - `7b2dfef5` (test)
3. **Task 3: bin/measure-main-ci + fake-gh contract** - `2d74d00a` (feat)

## Verification

- `npm --prefix examples/threadline_phoenix/e2e run test:unit`: 32 pass, 0 fail, and the `slow-specs` suite line is present.
- On ephemeral postgres:16, these files ran together with 121 tests and 0 failures: `browser_journey_evidence_contract_test.exs`, `measure_main_ci_contract_test.exs`, `main_ci_observer_contract_test.exs`, `ci_topology_contract_test.exs`, `ci_workflow_parity_contract_test.exs` and `ci_action_pin_contract_test.exs`.
- `mix compile --warnings-as-errors`, `mix verify.format` and `mix verify.credo` (no issues) all pass. `shellcheck bin/measure-main-ci` is clean.
- Mutations of the measurement script, made by hand and then reverted, turned the contract red each time: reading the bare run object gave 7 failures, a wrong even-count median gave 1, and dropping the ancestry filter gave 1.
- `bin/measure-main-ci --since nothex` exits 1 with no gh call. Running the slow-specs CLI on a missing report exits 0 and prints `::warning::`.

## Decisions Made

- `median_wall_s` is null unless `state == "measured"`, so a partial median is never mistaken for the D-08 figure.
- When the head equals `--since`, the script treats it as identical and makes no compare call. Compare results are cached per head sha in a plain string, because macOS `/bin/bash` 3.2 has no associative arrays.
- `run(args, env)` in slow-specs.ts returns its warning lines. The tests use this to check fail-soft behaviour without spawning a process.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] gh child processes could consume the selection loop's stdin**
- **Found during:** Task 3
- **Issue:** the `while read` loops fed by a here-string share stdin with `gh` subprocesses, so a gh call could swallow the remaining candidate lines.
- **Fix:** both loops now read from fd 3 (`read ... <&3` / `3<<<`, `3< <(...)`).
- **Files modified:** bin/measure-main-ci
- **Commit:** 2d74d00a

**2. [Rule 3 - Blocking] `declare -A` is unavailable on macOS bash 3.2**
- **Found during:** Task 3
- **Fix:** replaced the associative cache with a line-based `sha status` string that is looked up via awk.
- **Commit:** 2d74d00a

Additions beyond the plan: rule `timings-fail-soft` (the step carries no `continue-on-error`), a second `test-unit-wiring` control (dropping `operator-ci-evidence.test.ts`), and the scope control. All of these tighten the plan's prohibitions. No existing assertion was changed.

## Requirements

The plan lists CI-01 and CI-02. Neither is marked complete in REQUIREMENTS.md yet. The CI-01 wiring has landed, but its must-have backstop (the summary seen on a real main run after Land B1) is still open. CI-02 is the measured median, and this plan ships only the tool that measures it. The phase verifier should close both after the live reads.

## Known Stubs

None.

## Threat Flags

None. The surfaces match the plan's threat model: T-247-05/06 are mitigated in slow-specs.ts and covered by tests, and T-247-07 is mitigated in bin/measure-main-ci and covered by the fake-gh contract.

## Next Phase Readiness

- 247-10 rewrites the `--project` literals and the artifact name to `browser-timings-${{ matrix.project }}-…`. The contract's `name: browser-timings-` prefix rule already allows that form.
- 247-05 adds the `max/min` row that `--ratios` parses. 247-07 owns `@moduletag :repo_contract` for the new contract test.

## Self-Check: PASSED

- FOUND: examples/threadline_phoenix/e2e/support/slow-specs.ts, slow-specs.test.ts, bin/measure-main-ci, test/threadline/measure_main_ci_contract_test.exs
- FOUND commits: 632bc0c5, 7b2dfef5, 2d74d00a (ancestors of HEAD)
