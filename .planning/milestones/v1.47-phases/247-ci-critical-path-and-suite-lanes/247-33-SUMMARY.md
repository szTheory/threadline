---
phase: 247-ci-critical-path-and-suite-lanes
plan: 33
subsystem: ci-partitioning
status: superseded
executed: false
superseded_by: 247-36
decision: D-32
tags: [ci, tail-queue, B6, superseded, D-29, D-30, D-32]
requires:
  - phase: 247-32
    provides: "247-B6-PREDICTION.md gate FAIL (the precondition this plan never passed)"
provides: []
affects: ["247-36 (the D-32 landing, preflight and cohort plan that replaces this one)"]
actuals:
  tokens: 0
  tasks: 0
  commits: 0
hosted_runs_spent: 0
---

# Phase 247 Plan 33: superseded, never run

**This plan was never executed. Its precondition required `gate` PASS in `247-B6-PREDICTION.md`, and that round-1 pre-registration computed FAIL (247-32: worst 8 s/claim replay min 1.101 and latest 1.107, against 1.08). The maintainer then chose escalation option 2, recorded as D-32 in 247-CONTEXT.md: a current-lane-only tail queue. D-32 is executed by Plans 247-34..36. 247-36 replaces this plan.**

## Why superseded rather than revised

- 247-33 is wired to round 1 throughout.
  - Its precondition, its PR-body facts and all three verify blocks read `247-B6-PREDICTION.md`, using round 1's `gate_components` keys.
  - It writes stop records to `247-B6-ESCALATION.md`, which already holds round 1's prediction-stage escalation.
- Its allowed land-diff list omits `test/threadline/query/row_key_read_test.exs`, which 247-31 changed. A scope proof run from it would have failed.
- Revising a planned record after its gate failed would blur the pre-registration chain. Superseding it keeps the chain append-only: 247-32 (gate FAIL) → D-32 → 247-34 (runner) → 247-35 (`247-B6-PREDICTION-2.md`) → 247-36 (landing and cohort).

## What did not happen

- No land branch, push, PR, merge, workflow dispatch or main run. 0 hosted runs.
- No file listed in this plan's `files_modified` was written by it.
- `247-33-PLAN.md` is kept byte-unchanged, as the historical plan.

## Where the work went

| Item in 247-33 | Now in |
|---|---|
| Precondition on the prediction gate | 247-36 Task 1, reading `247-B6-PREDICTION-2.md` |
| Landing, exact-head local gate, `ci:` PR, P8 preflight | 247-36 Task 1, with per-lane K, the D-33 per-lane preflight bounds and the corrected six-path allowed diff |
| B6 cohort under the B5/D-29 rules | 247-36 Task 2 |
| B6-GATE-JSON, continuity, SEED-006 | 247-36 Task 3 |
| ROADMAP/REQUIREMENTS/STATE and the append-only phase records | 247-37 (or 247-35 Task 3 on a prediction-2 gate FAIL) |
| D-30 escalation on a miss | D-32's pre-decided option-1 fallback in `247-B6-ESCALATION-2.md`, with SEED-009 |
