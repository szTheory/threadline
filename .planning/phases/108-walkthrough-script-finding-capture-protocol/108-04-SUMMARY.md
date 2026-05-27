---
phase: 108-walkthrough-script-finding-capture-protocol
plan: 04
subsystem: testing
tags: [walkthrough, runbook, WALK-03, operator-incidents, maintainer]

# Dependency graph
requires:
  - phase: 108-walkthrough-script-finding-capture-protocol
    provides: WALKTHROUGH §0–§3 install/onboarding/daily-use (Plan 03)
provides:
  - WALKTHROUGH.md §4 four WALK-03 operator incident playbooks
  - ROADMAP Phase 108/109 four-incident traceability (D-108-02e)
affects:
  - 108-05-PLAN.md
  - 109-maintainer-walkthrough-dry-run

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Four distinct manifest heroes — close #4521 and delete #4518 kept separate (D-108-02a)"
    - "Operator surface route tables per incident with demo_last_tuesday footnote"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/WALKTHROUGH.md
    - .planning/ROADMAP.md

key-decisions:
  - "agent2 user_id inlined in WALK-03-02 with Appendix A pointer — not yet in Demo.Manifest @user_emails map"

patterns-established:
  - "WALK-03-01..04 step IDs with §4 checkpoint table for Phase 109 observe-only discipline"

requirements-completed: [WALK-03]

# Metrics
duration: 15min
completed: 2026-05-27
---

# Phase 108 Plan 04: WALKTHROUGH §4 Operator Incidents Summary

**Four WALK-03 incident playbooks (#4521 close, leaving-agent window, org Y retention, #4518 delete) with operator-surface-only resolution paths and ROADMAP traceability aligned to four incidents**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-27T18:13:09Z
- **Completed:** 2026-05-27T18:28:09Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Authored WALKTHROUGH §4 with four distinct steps `WALK-03-01` through `WALK-03-04` using D-108-03b skeleton
- Documented operator surface tables, `walk-acme-4521-close` / `walk-retention-offboarded-co` filters, `[REDACTED]` expected outcome for #4521, and `2026-05-20T14:30:00Z` time anchors
- Linked Verify sections to `demo_contract_test.exs` describe names without embedding asserts
- Amended ROADMAP Phase 108 goal/success criteria and Phase 109 RUN-02 from three scenarios to four WALK-03 operator incidents

## Task Commits

Each task was committed atomically:

1. **Task 1: §4 four incident playbooks** - `cedf21e` (feat)
2. **Task 2: ROADMAP four-incident traceability** - `4d5cac8` (docs)

**Plan metadata:** see `docs(108-04): complete operator incidents plan` commit below

## Files Created/Modified

- `examples/threadline_phoenix/WALKTHROUGH.md` - §4 operator incidents with checkpoint table
- `.planning/ROADMAP.md` - Four-incident wording in Phase 108/109 success criteria; plans 4/5 complete

## Decisions Made

- Inlined `agent2@acme.example.com` UUID (`33123cc4-da21-5674-b030-e168cee90521`) in WALK-03-02 with Appendix A deferral — persona exists in seed/DEMO_USERS but not yet in `Demo.Manifest.@user_emails`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 108-05-PLAN.md (WALKTHROUGH §5 evidence exercises + appendices + doc contract test)
- §4 complete; incidents 1 (#4521) and 4 (#4518) use distinct tickets and actors per D-108-02a

## Self-Check: PASSED

Verification results:

| Check | Result |
|-------|--------|
| `grep WALK-03-01..04` in WALKTHROUGH.md | PASS |
| `grep walk-acme-4521-close walk-retention-offboarded-co [REDACTED]` | PASS |
| No raw SQL / IEx / Repo.all instructions in §4 | PASS |
| ROADMAP Phase 108 mentions four WALK-03 incidents | PASS |
| ROADMAP Phase 109 RUN-02 references four incidents | PASS |
| `git log --grep=108-04` ≥1 commit | PASS (`cedf21e`, `4d5cac8`) |
| §4 complete before Plan 05 §5 | PASS |
| #4521 vs #4518 distinct in incidents 1 and 4 | PASS |

---
*Phase: 108-walkthrough-script-finding-capture-protocol*
*Completed: 2026-05-27*
