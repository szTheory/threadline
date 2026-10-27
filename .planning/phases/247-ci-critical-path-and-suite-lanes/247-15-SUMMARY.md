---
phase: 247-ci-critical-path-and-suite-lanes
plan: 15
subsystem: ci
status: complete
tags: [landing, measurement, gap-closure, ci-02, ci-03]
requires:
  - phase: 247-14
    provides: "Reviewed lane-specific weights, strict ingestion and routing"
provides:
  - "PR 96 exact-head green landing to main 89add23e"
  - "Five qualifying attempt-1 main walls: median 444 s, CI-02 PASS"
  - "Fixed nine first-three lane ratios: CI-03 MISS, requirement remains unmet"
affects: [247-verification, 247-follow-up-gaps, SEED-006]
tech-stack:
  added: []
  patterns: [immutable-tested-head, attempt-1-evidence, first-five-successes-with-explicit-exclusions]
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B3-MEASUREMENT.json
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LANDING.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-MEASUREMENT.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/deferred-items.md
    - .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
key-decisions:
  - "Keep 540 s and 1.15 fixed; report MISS and unmet for CI-03"
  - "Freeze source during measurement; retain failed motion-fixture run as an exclusion, not a rerun"
  - "Synchronize the existing accessibility test with modal dismissal/focus restoration; no assertion weakened"
requirements-completed: []
requirements-evidence:
  CI-01: preserved
  CI-02: PASS
  CI-03: MISS
  CI-04: preserved
coverage:
  - id: exact-head-gate
    description: "The isolated reviewed candidate passes the full local CI gate"
    verification:
      - kind: integration
        ref: "mix ci.all at 9fa28fad plus runner self-test/hygiene/branch protection"
        status: pass
    human_judgment: false
  - id: protected-main-landing
    description: "Exact-head PR and protected main retain all coverage and receipt topology"
    verification:
      - kind: e2e
        ref: "PR 96 run 40432374330, 17/17 green, receipt31; squash 89add23e tree equality"
        status: pass
    human_judgment: false
  - id: ci-02-median
    description: "Five qualifying main runs retain wall median at or below 540 s"
    requirement: CI-02
    verification:
      - kind: other
        ref: "247-B3-MEASUREMENT.json, median444 s over five attempt-1 successes"
        status: pass
    human_judgment: false
  - id: ci-03-ratios
    description: "Every first-three lane ratio must be at or below 1.15"
    requirement: CI-03
    verification:
      - kind: other
        ref: "247-MEASUREMENT.md: current1.13/1.24/1.15, min1.36/1.35/1.28, latest1.36/1.30/1.30"
        status: fail
    human_judgment: false
actuals:
  tokens: 10735
  tasks: 3
  commits: 6
duration: 104min
completed: 2026-10-27
---

# Phase 247 Plan 15 Summary

**The lane-weight candidate landed green on main; the five-run median is 444 s, while CI-03 still fails its unchanged all-nine ratio gate.**

Completed 2026-10-27T02:29:47.711127+00:00. All three execution tasks are complete; numeric acceptance is not. Phase 247 stays open and requirement markers remain pending re-verification.

## Task outcomes

1. **Exact-head local gate:** source and isolated land non-planning trees match. Land head `9fa28fad40ac0fb1ca3b83e48ce95a3845df698f` passed `CI=true mix ci.all`, runner self-test, hygiene and read-only branch protection. Root: 32 properties +3381 tests /0 failures; example132/0; Dialyzer0; live slice17/0; browser418 passed/56 configured skips. Required context remains exactly CI required@15368.
2. **Standing-grant landing:** PR #96, first CI run 40432374330 at the exact tested head, all17 checks green and receipt31 named journeys. Both browser timing artifacts and all three partition timing families present. SHA-guarded squash produced main `89add23ede29b7840e6cfa29cd70eb3c8ea59ae2`; its non-planning tree equals the tested candidate. Automatic main push run 40433193088 completed green before any additional dispatch.
3. **Honest measurement:** the canonical read-only reader selected five successful attempt-1 runs at the same main squash: 40433193088/423 s, 40434036118/471 s, 40434884357/451 s, 40436597341/442 s, 40437416932/444 s. Sorted423/442/444/451/471, median444 ≤540: **CI-02 PASS**. First-three ratios current1.13/1.24/1.15, min1.36/1.35/1.28, latest1.36/1.30/1.30: **CI-03 MISS**, seven of nine exceed1.15. All five qualifying runs have17 successful jobs,31-journey receipts and all required timing artifact families. Six total runs were serial; failed40435657557 is explicitly excluded, not rerun. Dispatch stopped at five successes.

## Automated evidence gate

Ran Plan15's live `bin/measure-main-ci --since <B3 squash> --count 5 --ratios --format json` plus its jq completeness/numeric checks and exact standalone-line comparisons in both MEASUREMENT.md and VALIDATION.md. **Exit0**, final marker `Plan 247-15 measured-evidence consistency gate: PASS (PASS MISS; numeric MISS remains unmet)`. Both files say CI-02 PASS/met and CI-03 MISS/unmet. This checks measurement/report consistency and does not turn the numeric MISS into a pass.

## Task Commits

1. **docs(247-15): make gap plan execution references machine independent** — `9c783673`
2. **test(247-15): await modal focus restoration before toast keyboard dismissal** — `b35750bd`
3. **docs(247-15): record review of modal focus synchronization fix** — `417be739`
4. **docs(247-15): prove the exact green lane-weight landing candidate** — `43cfd153`
5. **docs(247-15): verify PR 96 landing and the first green main run** — `9d3ae895`
6. **docs(247-15): record fixed-threshold main measurements and the remaining miss** — `bd640de1`

## Deviations and issues

- Gap plans contained machine-local execution references; changed to portable HOME references after hygiene rejected the initial candidate.
- Fresh landing checkout lacked the existing PLT cache; restored it and reran the full unchanged-head gate. No dependency/source change.
- A local full gate exposed a pre-existing modal/toast focus race in the accessibility evidence test. A controlled delayed-animation-frame probe reproduced the original failure with focus on Show Modal. Awaiting modal hidden and opener focus made that same probe green. Added four test-only lines (b35750bd), independently reviewed, then both projects passed the focused case with retries disabled and the complete amended-head gate passed. All temporary diagnostics were removed. No production UI change, new retry or weakened assertion.
- During the fixed-head main window, run40435657557 failed the same unsynchronized pattern in the unchanged motion fixture, mobile job121963594493 / operator-motion.spec.ts:275. The plan explicitly excludes failed attempts from the first-five-successes median. Kept the source fixed, retained the failure and diagnosis in deferred-items.md, obtained later distinct qualifying runs, and never reran its workflow attempt/job.
- Updated SEED-006's already-defined measured-median reopen baseline from historical B2 468 s to current B3 444 s with new run IDs/critical-path description; the acceptance thresholds are unchanged.

## Remaining gap and next step

Min/latest partition4 is consistently slowest despite equal predicted loads; absolute runner times also vary. The evidence supports a remaining assignment-model residual alongside runner variation. Keep CI-03 unmet and plan a research-backed follow-up; do not relax1.15 or replace first-three samples. Include the deferred motion-fixture synchronization issue in follow-up triage. No human UAT is needed.

## Self-Check: PASSED

All planned execution/evidence tasks and files verified, exact-head local/PR/main gates preserved, all five successful attempt1 runs and failed exclusion retained, nine ratios checked, and both requirement-state lines agree with computed fixed-threshold verdicts. This is execution close-out only: **phase247 is not complete**.
