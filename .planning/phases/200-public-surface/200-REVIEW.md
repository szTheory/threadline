---
phase: 200-public-surface
reviewed: 2026-09-13T04:28:13Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - examples/threadline_phoenix/e2e/critic/label.test.ts
  - examples/threadline_phoenix/e2e/critic/label.ts
  - examples/threadline_phoenix/e2e/critic/label_web.ts
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 200: Code Review Report

**Reviewed:** 2026-09-13T04:28:13Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The exact three-file iteration-3 scope was reviewed at standard depth. Both previous pair-mode findings are resolved: pair and single sessions now preserve existing round evidence in either order, generated CLI and web commands retain `--pairs`, and a single pre-dispatch guard protects both terminal and web round-2 entry points from missing, untracked, or modified round-1 evidence.

The regression pass found two other defects. Reconciliation's human r1/r2 choice has no effect on the emitted golden item, corrupting adjudicated oracle results. The new executable test file is also absent from every configured test command, so normal project and CI test runs do not execute it.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Reconciliation ignores the human's selected verdict

**File:** `examples/threadline_phoenix/e2e/critic/label.ts:906-958`

**Issue:** When r1 and r2 disagree, the UI asks the reviewer to keep r1, keep r2, or drop. The `choice === "1"` and `choice === "2"` branches append the same `GoldenItem`: both retain the original r1 and r2 verdicts, set only `kept: true`, and record no adjudicated choice. Thus choosing r2 produces exactly the same file as choosing r1. Existing trust measurement consumes the r1 verdict from a kept item, so a stated "Kept r2 verdict" is subsequently evaluated as r1. This silently corrupts the human-authored oracle for both single and pair disagreements.

**Fix:** Add an explicit resolved/adjudicated verdict (and pair margin) to `GoldenItem`, populate it from the chosen round, and make all golden-set consumers use that field. Alternatively normalize the selected value into the canonical verdict field while retaining both raw rounds only as provenance. Extract the two branches into one helper and add tests asserting that choices 1 and 2 serialize different canonical outcomes.

## Warnings

### WR-01: The new executable label tests are not included in any test command

**File:** `examples/threadline_phoenix/e2e/critic/label.test.ts:1-147`

**Issue:** The new Node test file covers the append and round-2 gate fixes, but no package script or CI command references it. The e2e package's `test` script runs Playwright, whose tests live under the configured Playwright test directory, while `test:paths` invokes only `support/operator-surface-paths.test.ts`. Consequently the new regression tests can remain green locally when run explicitly yet never execute during the project's normal test workflows.

**Fix:** Add `critic/label.test.ts` to the `tsx --test` script (or introduce a unit-test script that discovers both Node test files) and invoke that script from CI. Keep Playwright and Node unit tests separate so `npm test` or an explicit CI aggregate reliably exercises both.

---

_Reviewed: 2026-09-13T04:28:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
