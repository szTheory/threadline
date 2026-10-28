---
phase: 247-ci-critical-path-and-suite-lanes
plan: 19
subsystem: ci
status: halted
halt_reason: Six-run cap exhausted with four successful attempt-1 main runs and two failed exclusions; complete-five reconciliation precondition unmet
requires:
  - phase: 247-18
    provides: Exact green PR 97 candidate and protected-main squash
provides:
  - Canonical insufficient-sample payload and identical incomplete report projections
  - Fixed first-three nine ratios, six-run chronology and two retained failed exclusions
  - Evidence-backed stop and concrete local-diagnosis scope recommendation
affects: [247-verification, milestone-scope-decision]
key-files:
  created: [.planning/phases/247-ci-critical-path-and-suite-lanes/247-B4-INCOMPLETE.json]
  modified: [.planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md, .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md, .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md, .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md]
requirements-completed: []
requirements-unmet: [CI-02, CI-03]
coverage:
  - id: bounded-incomplete-protocol
    description: Six-run cap and exclusions remain visible without fabricating a five-success sample
    requirement: CI-02
    verification:
      - {kind: integration, ref: 'bin/measure-main-ci --since 02d115a32e4479f353d284c04fc838ba58938d16 --count 5 --ratios --format json; live/persisted/incomplete-report reconciliation', status: pass}
    human_judgment: false
  - id: fixed-first-three-ratios
    description: All nine fixed printed ratios remain bound to the actual successful main runs; min misses are retained
    requirement: CI-03
    verification:
      - {kind: integration, ref: '247-B4-INCOMPLETE.json ratios[0:3] and identical B4-INCOMPLETE report projections', status: pass}
    human_judgment: false
  - id: complete-five-gate
    description: Complete-five B4 gate and its negative controls await a valid sample and new scope/budget
    verification:
      - {kind: other, ref: '247-19-PLAN.md Task 2 precondition unmet; not executed', status: unknown}
    human_judgment: false
actuals: {tokens: 6000, tasks: 1, commits: 1}
completed: 2026-10-27
---

# Phase 247 Plan 19 — Designed Stop at the Six-Run Cap

**B4 is INCOMPLETE: four qualifying successes and two failed exclusions exhausted the authorized window. CI-03 is a measured MISS; no complete-five CI-02 PASS is claimed.**

## Execution and exact head

Live GitHub PR #97 state/head/merge commit, fetched main and source-tree checks reconfirmed tested head 4ff7af655315a927eb5a62e14cb2abc7e72d4ab8 and main squash 02d115a32e4479f353d284c04fc838ba58938d16 before spending. Main remained fixed throughout. Automatic push completed before optional dispatches. Used six total main runs and five extra serial dispatches; no attempt/job retry and no seventh run.

- Qualifying successes: 40449332597, 40450141708, 40450801580, 40451533079.
- Failed exclusions: 40452150109 and 40452833440.
- Raw canonical count-5 response: state insufficient, found 4, median_wall_s null.
- Fixed current ratios: 1.12 / 1.11 / 1.12.
- Fixed latest ratios: 1.10 / 1.04 / 1.12.
- Fixed min ratios: 1.24 / 1.28 / 1.27 — all three MISS the unchanged 1.15 limit.

The full six-run chronology, dispatch times, exact head, conclusions, four successful walls and exclusions are in LANDING and both report projections. `247-B4-INCOMPLETE.json` is unedited canonical stdout. `247-B4-MEASUREMENT.json` and complete B4-GATE-JSON blocks are deliberately absent. SEED-006 remains closed with its historical complete B3 444 s bound; no B4 median replaces it.

## Failures and diagnosis

Run 40452150109 min job 122017125177, partition 3, seed 675682: scoped row-history fixture failed `audit_changes_transaction_id_fkey` during child insertion after parent insertion. Same Repo options and per-partition databases rule out the simple cross-partition cleanup theory, but do not establish why the parent was absent. Newly observed and unresolved.

Run 40452833440 min job 122019295198, partition 1, seed 856063: Export.Orchestrator setup `File.rm_rf!("priv/threadline_exports")` failed with “file already exists.” Static replay places orchestrator in min partition 1, export controller in 4 and cleanup/local storage in 2; the checkout-shared path is exposed across processes. This is a concrete isolation risk, not a captured competing-writer root cause or a verified fix.

Two independent researchers checked all 36 fixed first-three timing TSVs and cost/guide constraints. Min partition 3 pre-module intervals recur at 20.469 / 18.940 / 17.227 s; active-only min ratios are 1.140 / 1.165 / 1.127. Startup remains in acceptance. All six current/latest full ratios pass. No additional optimizer/weight/threshold change is justified from these artifacts. Recommended next scope: bounded local diagnosis of fixture isolation and the pre-module interval, then one reviewed candidate and an explicit new sampling budget decision. Do not spend more runs trying to obtain a favorable cohort.

## Verification

- All ten named artifacts, two correctly ranked top-20 arrays, full 31-journey receipt and three four-TSV families validated for each of the four qualifying successes.
- A fresh canonical count-5 read exactly equals the saved insufficient payload.
- Live PR/main identity, six-run/five-dispatch cap, chronological success IDs, both failure IDs/reasons and both identical incomplete projections reconcile. No complete artifact or false PASS exists; SEED-006's old complete bound is retained. Check exited 0.
- B3 failed 40435657557 and initial PR failed 40446515239 remain separately retained; neither was retried or reclassified.
- Task 2 complete-five reconciliation and 13 prepared mutation controls were NOT run: the five-success precondition is unmet. The incomplete-mode check does not substitute for that gate.

## Task status and commit

Task 1 reached its explicitly designed INCOMPLETE branch after the cap. Task 2 is blocked by the missing fifth success. Evidence commit is the reachable `docs(247-19): preserve bounded incomplete B4 evidence and failed exclusions` commit. This halted SUMMARY is a stop record, not a plan/phase completion claim.

## Deviations

Used an explicitly named INCOMPLETE artifact and projections rather than a misleading complete measurement artifact. Added the two observed failures to deferred-items.md. Source, weights, thresholds and fixture behavior stayed frozen during sampling. No further paid CI or new fix loop is authorized by this receipt.

## Self-Check: PASSED

The bounded stop, raw evidence and incomplete projections are verified and committed. Full-five acceptance and reconciliation remain unexecuted. Phase 247 must remain pending; this self-check verifies the stop record only.
