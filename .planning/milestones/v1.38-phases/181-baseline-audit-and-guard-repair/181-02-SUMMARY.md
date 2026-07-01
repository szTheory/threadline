---
phase: 181-baseline-audit-and-guard-repair
plan: 02
subsystem: testing
tags: [operator-ui, guardrails, playwright, source-contracts, audit]

requires:
  - phase: 181-01
    provides: rendered baseline audit, screenshot inventory, stale rendered failure evidence
provides:
  - Guard repair ledger with exact stale scan classifications
  - Repair-now ownership for stale E2E/demo-seed assertion drift
  - Source-test prose cleanup ownership for stale Wave-0 RED wording
  - Retained guard rationale for local screenshot skips and stress bad-param fixtures
affects: [181-03, 181-04, 181-05, 181-06, 181-07, 181-08, 181-09, 181-10, 181-11, 183, 184, 185, 186, 187]

tech-stack:
  added: []
  patterns:
    - Classification ledger before repair: repair-now, intentional guard, later-phase owner, false-positive fixture, retired with rationale
    - Guard repairs bounded by D-181-04 through D-181-06 before page polish

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md
  modified: []

key-decisions:
  - "181-03 owns stale E2E/demo-seed discovery and copy assertion repair; Timeline/Coverage page polish remains deferred to 184/185."
  - "181-04 owns active source-test prose that still says RED today/RED until after the guarded behavior landed."
  - "Local screenshot skips and stress bad-param strings are intentional guards/fixtures, not defects."

patterns-established:
  - "Every stale guard finding records file path, line or selector family, classification, action, and owner before any repair changes a ratchet."
  - "Plan 02 classifies repair scope only; product UI, route, data-testid, dependency, and screenshot baseline changes remain prohibited."

requirements-completed: [BASE-01, BASE-02]

duration: 4 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 02: Stale Guard Finding Ledger Summary

**Guard repair ledger that classifies stale E2E, source-contract prose, retained skips, bad-param fixtures, and later-phase ownership before any ratchet repair.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-26T13:14:51Z
- **Completed:** 2026-06-26T13:19:10Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `181-GUARD-REPAIR.md` with 20 grouped findings covering all primary stale-scan hits plus additional old demo-seed selector/copy families exposed by Plan 01.
- Classified retained Playwright `test.skip` entries as local-only/project-filtering guards and classified `not-real` stress strings as invalid-param fixtures.
- Preserved D-181-04 through D-181-06 boundaries: repair accepted invariant drift only, defer page polish, and avoid weakening route/data-testid/auth/export/stress ratchets.

## Task Commits

1. **Task 1: Build the stale guard finding ledger** - `88357c6` (docs)

## Files Created/Modified

- `181-GUARD-REPAIR.md` - Guard repair ledger with scan evidence, classification vocabulary, finding table, retained guard rationale, retired/reworded contract families, and owner boundaries.

## Verification

| Check | Result |
|---|---|
| Primary stale guard scan | PASS: `rg -n "RED today\|RED until\|removed contract\|stale selector\|#4521\|not-real\|test\\.skip\|skip\\(" ...` returned the expected 27 matches across 10 files. |
| Ledger classification check | PASS: `test -s 181-GUARD-REPAIR.md && rg -n "repair-now\|intentional guard\|later-phase owner\|false-positive fixture\|retired with rationale\|D-181-04\|D-181-05\|D-181-06" ...` matched all required policy/classification terms. |
| Acceptance: retained skips | PASS: ledger explains local-only screenshot and project-filtering skips as intentional guards. |
| Acceptance: bad-param fixtures | PASS: ledger classifies `not-real` stress URL strings as false-positive fixtures, not production selectors. |
| Acceptance: no UI polish | PASS: `git diff --name-only 88357c6^ 88357c6` contains only `181-GUARD-REPAIR.md`. |

## Decisions Made

- Treat the stale rendered E2E failures from Plan 01 as `repair-now` for 181-03, not as permission for Timeline or Coverage page redesign.
- Treat old Wave-0 RED comments/failure text in active source tests as `repair-now` for 181-04 source-prose cleanup.
- Retain local visual screenshot skips, desktop-only stress screenshot filtering, and bad-param stress fixtures as intentional guardrail shape.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The scan hits are the planned ledger findings, not blockers for this doc-only task.

## Known Stubs

None. Stub scan only found the quoted stale assertion text `Coverage inspection is not available` inside the ledger.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-03` stale E2E selector repair. The ledger gives repair executors exact owners for E2E drift, source-test prose cleanup, route/auth/stress contracts, ledger/projection freshness, and bounded screenshot work without reopening product UI polish scope.

## Self-Check: PASSED

- Found `181-GUARD-REPAIR.md`.
- Found task commit `88357c6` in git history.
- Verified the task commit changed only the guard repair ledger.
- Working tree was clean before summary closeout.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
