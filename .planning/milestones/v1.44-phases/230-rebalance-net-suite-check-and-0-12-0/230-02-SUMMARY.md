---
phase: 230-rebalance-net-suite-check-and-0-12-0
plan: "02"
subsystem: testing
tags: [ci, timing, suite-health, ci-job-timing, ci-test-partitions]

requires:
  - phase: 225-suite-baseline-and-partitioned-ci
    provides: "SUITE-01 pinned baseline (846s step sum, run 36730596489, local 137.0s median) and the ci-job-timing.py comparator tool"
  - phase: 230-rebalance-net-suite-check-and-0-12-0
    provides: "230-01's REBAL_AFTER commit and local wall-clock after-figure (151.59s), reused here under D-08's tree-unchanged rule"
provides:
  - "Proven D-06 gate formula (all three lanes hit, summed Run tests seconds <= 930.6, each lane <= its SUITE-01 figure, equality passes, missing/miss = INVALID)"
  - "D-09 milestone suite-time table for phases 224-230 plus the SUITE-06 verdict row, every cell cited to its phase's own evidence doc"
  - "D-07 serial-equivalent work disclosure with per-phase attribution and per-lane partition-Seconds breakdowns"
  - "D-08 local context figure (151.59s reused from plan 01) against SUITE-01's 137.0s"
affects: [230-03, 230-04]

actuals:
  tokens: 3643
  tasks: 2
  commits: 2
  plan_head_before: "79f1c8c7981bdd306c41308264d9f44964cfda5a"
  plan_head_after: "1cf8ae05838c0766b91fa082209d0e1333b4bf72"

tech-stack:
  added: []
  patterns:
    - "SUITE-06 gate formula fixed before measurement: equality passes, missing step/partition-report/cache-miss is INVALID (blocks landing like a FAIL), never silently a pass"
    - "Serial-equivalent work (sum of per-partition Seconds across all 3 lanes) is disclosed per phase with honest attribution, never gated on, never re-baselined, never called noise even when it decreases unexpectedly"

key-files:
  created: []
  modified:
    - .planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md

key-decisions:
  - "225's partitioned after-run cited for the serial-equivalent Δ-chain is 36808706517 (the cache-hit run), not 36810081717 (cache miss) — only a cache-hit run is a valid D-06/D-07 comparator"
  - "224 and 229 CI cells read local-only per the plan's explicit instruction, since neither phase published its own completed CI run (224's own after-run never happened before 225 pushed; 229 never dispatched CI)"
  - "224's local before/after cells record the published 2-run swing check verbatim rather than fabricating a 3-run median the source evidence never computed"
  - "226's serial-equivalent total (1508s) decreased versus 225's (1588s) despite 226 adding pure property tests — stated plainly with attribution to partition-weight rebalancing and shared-runner variance, not re-baselined and not called noise"

requirements-completed: [SUITE-06]

coverage:
  - id: D1
    description: "The D-06 gate formula (all three lanes Build cache: hit, summed Run tests seconds <= 930.6, each lane <= its own SUITE-01 figure, equality passes, missing/miss = INVALID) is written down in 230-EVIDENCE.md before any measurement it will judge"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "grep acceptance criteria: ### Gate (D-06) section present, names all three conditions + equality rule + INVALID rule"
        status: pass
    human_judgment: false
  - id: D2
    description: "ci-job-timing.py --cache-state reproduces SUITE-01's exact 846s step sum (288/291/267) on run 36730596489, proving the comparator before it is relied on"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "python3 .../ci-job-timing.py 36730596489 --cache-state | grep 288/291/267 (Task 1 verify, acceptance criteria)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Per-lane partition-Seconds sums are extracted from a real partitioned run (228's after-run 37018812221) via read-only gh api job-log calls, proving the D-07 serial-equivalent extraction method on real data"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "gh api repos/szTheory/threadline/actions/jobs/<id>/logs --allow-escape-sequences, ANSI-stripped, summed (Method proof section, 230-EVIDENCE.md)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The D-09 milestone suite-time table is complete for phases 224-230 plus a SUITE-06 verdict row, in ascending phase order, every numeric cell citing its source doc; 224/229 marked local-only, 230/verdict marked pending for plan 04"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "exact header grep + per-phase row grep (224-230) + SUITE-06 verdict grep + ascending-order awk/sort check (Task 2 verify, acceptance criteria)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Serial-equivalent work is disclosed per phase (224->230) with numbered deltas and plain-language attribution against SUITE-01's 846s serial figure, never gated on and never re-baselined"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "### Serial-equivalent work (D-07) section, 230-EVIDENCE.md (manually inspected against each cited run's gh api job logs)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The D-08 local context figure (median of 3 sequential mix test runs at the final commit, or the reused plan-01 figure if the tree is unchanged) is reported against SUITE-01's local 137.0s with the standard noise-floor caveat"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "### Local context (D-08) section, 230-EVIDENCE.md; git diff --quiet 77cb5c86..HEAD -- test lib config mix.exs mix.lock confirmed tree-unchanged, reused 151.59s"
        status: pass
    human_judgment: false
  - id: D7
    description: "bin/ci-test-partitions is unchanged by this plan (no echo added to the runner); the comparator reads only its existing report() output and ci-job-timing.py's existing modes"
    requirement: "SUITE-06"
    verification:
      - kind: unit
        ref: "git diff 4a04e4f3..HEAD -- bin/ (empty)"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-10-02
status: complete
---

# Phase 230 Plan 02: Net-suite check (SUITE-06) Summary

**Fixed the D-06 gate formula before measurement, proved the ci-job-timing.py/ci-test-partitions comparator pipeline on real CI runs (SUITE-01's exact 846s, 228's partition-Seconds extraction), and assembled the D-09 milestone suite-time table for phases 224-230 — leaving exactly one row (the fresh pre-landing CI run) for plan 04 to fill and gate on.**

## Performance

- **Duration:** ~1h
- **Started:** 2026-10-02T22:20:00Z (approx)
- **Completed:** 2026-10-02T23:20:00Z (approx)
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Wrote the SUITE-06 gate formula (`### Gate (D-06)`) before any measurement it will judge: all three lanes `Build cache: hit`, summed `Run tests` seconds ≤ 930.6 (846 + 10%), each lane ≤ its own SUITE-01 figure (min ≤288, current ≤291, latest ≤267), equality passes, a missing step/partition-report/cache-miss is INVALID (blocks landing exactly like a FAIL, never silently a pass)
- Proved `ci-job-timing.py --cache-state` reproduces SUITE-01's exact figures (288/291/267, sum 846, run 36730596489) and ran it again on 228's after-run (37018812221) to prove the comparator on a second real run
- Extracted per-lane partition-Seconds sums from 37018812221 via read-only `gh api .../jobs/<id>/logs --allow-escape-sequences` (ANSI-stripped), proving the D-07 serial-equivalent extraction method on real data: min 601s, current 488s, latest 555s, total 1644s
- Assembled the `### Milestone suite-time table (D-09)` with one row per phase 224-230 plus a SUITE-06 verdict row — every cell copied verbatim from each phase's own published evidence doc; 224 and 229 CI cells correctly read local-only (neither phase published a completed CI run), 230 and the verdict row read pending for plan 04
- Disclosed `### Serial-equivalent work (D-07)` across the chain SUITE-01 → 225 → 226 → 227 → 228, with per-phase attribution (partitioning overhead, pure-property growth, DB-backed property growth, telemetry growth) stated plainly even where the number unexpectedly decreased (226), never called noise and never re-baselined
- Recorded `### Local context (D-08)`: reused plan 01's after-figure (151.59s, tree unchanged since `77cb5c86`) against SUITE-01's local 137.0s baseline with the repo's standard 52-56s noise-floor caveat, plus `mix verify.test_partitioned`'s partition table as a labelled balance sanity check only
- Confirmed `bin/` is byte-unchanged since the plan 01 BASE sha — no echo was added to `bin/ci-test-partitions`, per the Don't Hand-Roll decision

## Task Commits

1. **Task 1: Tracer — prove the comparator end to end on SUITE-01 and one partitioned run, write the gate formula** - `57f9af6e` (docs)
2. **Task 2: Assemble the D-09 milestone table, disclose serial-equivalent work, record D-08 local context** - `1cf8ae05` (docs)

## Files Created/Modified

- `.planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md` - `## SUITE-06 net suite time` section appended: `### Gate (D-06)`, `### Method proof`, `### Milestone suite-time table (D-09)`, `### Serial-equivalent work (D-07)`, `### Local context (D-08)`

## Decisions Made

- 225's cited after-run for the serial-equivalent chain is 36808706517 (cache hit), not 36810081717 (cache miss) — only a cache-hit run is a valid D-06/D-07 comparator.
- 224's local before/after cells record the published 2-run swing check verbatim (231.0s/243.2s before, 282.5s/187.7s after) rather than fabricating a 3-run median the source evidence never computed.
- 226's serial-equivalent total (1508s) decreased from 225's (1588s) despite 226 adding pure property tests. Stated plainly with attribution to partition-weight rebalancing and shared-runner variance on this particular run, not re-baselined and not labelled noise — the test-count growth is real and visible in the attribution text even though this one serial-equivalent sample happened to drop.
- 224 and 229 CI cells read "local-only (no CI run this phase)" per the plan's explicit instruction — 224's own after-run never completed before 225 pushed the branch, and 229 never dispatched a CI run.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The SUITE-06 section of 230-EVIDENCE.md is complete except for the one fresh pre-landing CI row, which plan 04 fills using the same `ci-job-timing.py --cache-state` tool and the exact gate formula recorded here (`### Gate (D-06)`).
- Plan 04's merge gate must check: all three lanes `Build cache: hit`, summed `Run tests` seconds ≤ 930.6, each lane ≤ its SUITE-01 figure (min ≤288, current ≤291, latest ≤267). If invalid or failing, do not land (D-10) — diagnose cache state, then test content, then partition weights, and re-measure.
- No blockers.

## Self-Check: PASSED

- `grep -q '^## SUITE-06 net suite time' .planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md` — FOUND
- `git log --oneline --all --grep="230-02"` returns 2 commits (57f9af6e, 1cf8ae05) — FOUND
- All plan-level `<verification>` commands re-run clean during task execution (ci-job-timing.py reproduces 846s; D-09 table header/rows/verdict present; `bin/verify-repo-hygiene` clean; ascending-order check passes)
- `git diff 4a04e4f38ea5d36f313e1b1e7ffdfbdd4fc799dc -- bin/` is empty — FOUND (no runner change)

---
*Phase: 230-rebalance-net-suite-check-and-0-12-0*
*Completed: 2026-10-02*
