---
phase: 247-ci-critical-path-and-suite-lanes
plan: 21
subsystem: testing
tags: [ci, partition-replay, evidence-provenance, python]
requires:
  - phase: 247-20
    provides: typed local canary receipt and bounded stop outcome
provides:
  - Source-bound replay of fixed B3, B4, failed-exclusion, and diagnostic evidence
  - Independently reviewed local disposition with machine-checked projection
affects: [CI-02, CI-03, 247-verification]
actuals:
  tokens: 76420
  tasks: 2
  commits: 2
  plan_head_before: c357a142bfb56238e4a7553c53266daf44d08a6d
  plan_head_after: dccc5789f594d522cd0fe26f6924dafc28f104da
tech-stack:
  added: []
  patterns:
    - Standard-library Python validates exact source revisions and frozen TSV cohorts offline.
    - Historical printed total ratios remain separate from component and body diagnostics.
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-FROZEN-REPLAY.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-DIAGNOSIS.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-21-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md
key-decisions:
  - "Keep B3 training, B4 holdout, failed exclusions, and the off-main diagnostic in distinct roles."
  - "Treat local replay VALID as provenance/arithmetic validity only; it does not change CI-02 INCOMPLETE, CI-03 MISS, or historical cause UNPROVEN."
  - "Stop after the INVALID local canary and frozen replay; no new samples, fitting, tuning, or hosted run."
patterns-established:
  - "Record source-head classifier, weights, colocation, formula, and blob hashes alongside each frozen timing cohort."
requirements-completed: [CI-02, CI-03]
coverage:
  - id: D1
    description: "Offline replay of the frozen B3/B4/diagnostic partitions with source, artifact, assignment, and arithmetic provenance"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "replay_frozen_evidence.py --self-test"
        status: pass
      - kind: integration
        ref: "replay_frozen_evidence.py --verify 247-FROZEN-REPLAY.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Reviewed stop decision preserves the invalid canary and incomplete historical acceptance gates"
    requirement: CI-02
    verification:
      - kind: other
        ref: "replay_frozen_evidence.py --verify 247-FROZEN-REPLAY.json --report 247-LOCAL-DIAGNOSIS.md --validation 247-VALIDATION.md"
        status: pass
    human_judgment: false
duration: "about 10 min; exact start timestamp was not captured"
completed: 2026-10-27
status: complete
---

# Phase 247 Plan 21: Frozen evidence replay and reviewed stop decision Summary

**A source-bound replay decomposes 96 frozen partition rows and an independent review confirms the local canary is INVALID while CI-02 remains incomplete and CI-03 misses.**

## Performance

- **Duration:** About 10 minutes; exact start timestamp was not captured.
- **Started:** Not captured.
- **Completed:** 2026-10-27.
- **Tasks:** 2 completed.
- **Files modified:** 6 plan artifacts, including this summary.
- **Measured commits:** 2 task commits from the persisted plan ledger.

## Accomplishments

- Added a dependency-free replay tool that binds each successful run to its exact git source blobs, run metadata, artifact hashes, lane, partition, and exact-once inventory. It keeps B3 as training, B4 as a four-success holdout, failed attempts as exclusions, and diagnostic `40504321590` as off-main evidence.
- Replayed 96 lane/partition rows with source-classified observed costs, committed-weight predictions, standardized current-formula costs, weight errors, active residuals, and canonical printed total ratios. Failed exclusions are never timing samples; diagnostic ratios are labeled as saved lane aggregates.
- Produced an independently reviewed diagnostic decision and appended actual receipts without altering historical validation. The replay is provenance-valid; the Plan 20 canary remains INVALID after one warmup, CI-02 remains INCOMPLETE, CI-03 remains MISS, the historical cause remains UNPROVEN, and phase status remains 2/4.

## Task Commits

1. **Task 1: Replay frozen run/partition evidence through source-bound components** — `a0edce1a` (`feat`).
2. **Task 2: Reconcile canary and replay into an independently reviewed stop decision** — `dccc5789` (`docs`).

## Files Created/Modified

- `tools/replay_frozen_evidence.py` — standard-library replay, mutation self-test, and evidence/report verifier.
- `247-FROZEN-REPLAY.json` — frozen cohort, source and artifact provenance, components, exclusions, and printed-ratio values.
- `247-LOCAL-DIAGNOSIS.md` — bounded decision with reviewer receipt and input hashes.
- `247-VALIDATION.md` — append-only Plan 20/21 execution receipts; prior validation and Nyquist partial status remain intact.
- `247-21-SUMMARY.md` — this execution summary.

## Independent Review

Codex subagent `replay_reviewer` reviewed the diagnosis against raw canary/replay, canonical B3/B4/diagnostic evidence, and exact-version source links. It independently checked all 96 arithmetic rows and printed-ratio bindings, found no factual or inference errors, and passed the stop decision. Its nonblocking clarity note is addressed by explicitly labeling diagnostic printed-ratio sources as lane aggregates.

## Verification

- `replay_frozen_evidence.py --self-test` — passed source-hash and arithmetic mutation controls.
- `replay_frozen_evidence.py --verify 247-FROZEN-REPLAY.json` — passed source, metadata, artifact, identity, assignment and component recomputation.
- `replay_frozen_evidence.py --verify ... --report ... --validation ...` — passed reviewer/body-hash and decision projection checks.
- No ExUnit suite, browser suite, canary runtime, CI workflow, or additional timing series was run.

## Deviations from Plan

None. The replay tool and report projection were refined to bind per-row canonical printed ratios and independently reviewed body/artifact hashes. These refinements did not add or resample evidence.

## Issues Encountered

The first replay self-test found that diagnostic current/latest timings are available as exact cached run artifacts while the diagnostic JSON embeds only min timings. The replay was adjusted to require and use the exact cached artifacts and to compare min rows byte-for-byte with the canonical embedded TSV. The independent reviewer also noted missing per-row printed-ratio values; the replay rows now bind each value to the canonical per-run lane arrays, or label the diagnostic lane aggregate explicitly.

## Next Phase Readiness

This plan closes only its bounded local diagnostic task. Phase acceptance remains open at 2/4. Any later causal candidate, CI run budget, or main measurement cohort requires a separate scope decision.

## Self-Check: PASSED

All four plan artifacts and this summary exist. Task commits `a0edce1a` and `dccc5789` are ancestors of HEAD. The stub scan found no placeholder/TODO patterns, `git diff --check` passed, and parent-owned `.planning/STATE.md` remains untouched by this plan.

---
*Phase: 247-ci-critical-path-and-suite-lanes*
*Completed: 2026-10-27*
