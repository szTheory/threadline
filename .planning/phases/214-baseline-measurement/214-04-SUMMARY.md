---
phase: 214-baseline-measurement
plan: 04
subsystem: planning-baseline
tags: [ci, baseline, gap-closure, base-02, wall-time]
status: complete
gap_closure: true

requires:
  - phase: 214-baseline-measurement (plans 01-03)
    provides: raw/ci run data, summarize-ci.py, facts.json, check-project-baseline.sh, verify-phase.sh
provides:
  - Offline `wall` step in measure-base02.sh (raw/ci -> facts.json wall-time p50s with run IDs)
  - Wall-time assertions and a stale-wording guard in check-project-baseline.sh
  - Corrected CI wall-time bullet in PROJECT.md `## Current Milestone`
  - Stale-wall negative fixture and reason-asserting negative checks in verify-phase.sh
affects: [phase-214-verification, ci-economy phases citing the wall-time baseline]

actuals:
  tokens: 6041
  tasks: 2
  commits: 2
plan_head_before: 28238181dcf4b9a0913413a7778d348f94dadbad

tech-stack:
  added: []
  patterns:
    - "Baseline prose facts are derived offline into facts.json and asserted from it (value + run ID), never hard-coded in the checker"
    - "Negative fixtures are single-cause and the gate asserts the named MISSING reason, not just a non-zero exit"

key-files:
  created:
    - .planning/phases/214-baseline-measurement/tools/fixtures/project-stale-wall.md
  modified:
    - .planning/phases/214-baseline-measurement/tools/measure-base02.sh
    - .planning/phases/214-baseline-measurement/raw/base02/facts.json
    - .planning/phases/214-baseline-measurement/tools/check-project-baseline.sh
    - .planning/PROJECT.md
    - .planning/phases/214-baseline-measurement/tools/fixtures/project-bad-streak.md
    - .planning/phases/214-baseline-measurement/tools/verify-phase.sh

key-decisions:
  - "CI wall-time baseline in PROJECT.md is stated as summarize-ci.py p50 values with run IDs (PR 10.5, push 10.7, Browser-full push 18.0, nightly 14.5 min), enforced by check-project-baseline.sh from facts.json"

requirements-completed: [BASE-02]

metrics:
  duration: ~10 min
  completed: 2026-09-26
---

# Phase 214 Plan 04: CI wall-time baseline gap closure Summary

PROJECT.md's CI wall-time bullet now states the measured summarize-ci.py p50s with run IDs: PR 10.5 min (run 34758417725), push 10.7 min (run 34755997103), Browser-full 18.0 min per push (run 35780709940) and 14.5 min nightly (run 34932091760). The values come from facts.json, which the new offline `measure-base02.sh wall` step fills, and the checker enforces them. This closes 214-VERIFICATION gap G2.

## What was done

- **Task 1 (tracer), commit 313db847.** Added `step_wall` to `measure-base02.sh`. It runs the four summarize-ci.py commands against the committed raw/ci data, with no network or gh call. It parses the p50 rows and fails closed if any row is missing. ci.yml seconds are converted with the same `fmt_min` rule summarize-ci.py uses. The step merges 10 new keys plus `.commands` entries and `wall_regenerate` into facts.json. It is idempotent: two runs gave the same shasum `fb3a1005`. Every pre-existing key is unchanged (`. * old == .` holds). The step writes no raw/base02 file, and the header comment now says so. `check-project-baseline.sh` gained a `# --- CI wall time (gap G2) ---` section. It has four `expect` lines, each carrying a value and a run ID, and a `stale_wall_wording` guard against `PR ~9 min` / `~17 min on every push`. In PROJECT.md only the one bullet line changed (numstat `1 1`), and Out of Scope is byte-identical to ff8e53e9.
- **Task 2, commit 6d494efc.** Created `fixtures/project-stale-wall.md`: the current milestone region with only the wall bullet reverted. The old bullet was taken from `git show ff8e53e9` and the new one from the current PROJECT.md, never retyped. In `project-bad-streak.md` the wall bullet was updated so that fixture now fails only on flake labels. `verify-phase.sh` gained `run_fails_with <label> <reason> <cmd...>`, which requires a non-zero exit AND a fixed-string reason in the output. It replaces `run_fails`, which is now unused and removed. There is a new stale-wall check.

## Verification

- `bash .planning/phases/214-baseline-measurement/tools/verify-phase.sh`: 12 PASS, `verify-phase: all checks passed`, exit 0. That includes both reason-asserted negative fixtures.
- Stale fixture fails with exactly the four wall labels and two `stale_wall_wording` lines, and no other label. The bad-streak fixture fails only with `flake_fast_fail_first` / `flake_fast_fail_streak`.
- Mutation proof: `PR 10.4 min` gives `MISSING: ci_wall_pr_p50:`, exit 1. Forbidden-text proof: `PR ~9 min` gives `MISSING: stale_wall_wording:`, exit 1.
- `git diff --quiet ff8e53e9 -- mix.exs mix.lock .github test lib` exits 0. Plans 214-01..03 and 214-BASELINE.md are unchanged since 266c86cc. The added lines contain no machine-local path.

## Deviations from Plan

None. The plan was executed as written. The tracer gate was run too: the `<verify>` command was re-run end-to-end, it passed, and only then did Task 2 start.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: tools/fixtures/project-stale-wall.md, tools/measure-base02.sh, raw/base02/facts.json, tools/check-project-baseline.sh, tools/verify-phase.sh
- FOUND: commits 313db847, 6d494efc
