---
phase: 240-connected-investigation-and-recovery
plan: "02"
subsystem: ui
tags: [phoenix-liveview, saved-search, canonical-url, playwright]

# Dependency graph
requires:
  - phase: 240-connected-investigation-and-recovery
    provides: Canonical Timeline row-history context and scoped investigation routes.
provides:
  - Actor and correlation pivots re-enter Timeline through supported filters and normal host authorization.
  - Actor-owned saved searches persist and restore only committed supported filters, with actionable mutation errors and confirmed deletion.
  - Canonical local search URLs share applied filters without scope, tenant, cursor, draft, or saved-record identity.
affects: [240-03, 240-04, operator-ui]

# Actuals (#2632)
actuals:
  tokens: 10557
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Assign share URLs from the committed FilterParams allowlist and canonical query order.
    - Scope SavedView list and mutation operations to the current identifiable ActorRef.
    - Keep long saved-search names and summaries inside a responsive local collection with visible actions.

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/timeline_live/filters.ex
    - lib/threadline/operator_surface/live/timeline_live/helpers.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/style/04_controls.css
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/live/actor_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - .planning/phases/240-connected-investigation-and-recovery/240-02-PLAN.md

key-decisions:
  - "Treat a shared URL as a canonical filter definition; the receiving host recomputes results and authorization."
  - "Persist only committed supported filters and keep SavedView ownership tied to the current identifiable ActorRef."
  - "Require an explicit confirmation before deletion and retain an actionable error when a mutation fails."

patterns-established:
  - "Canonical applied filters: derive local share paths from FilterParams.canonical_query/1 after route validation."
  - "Truthful destructive actions: request opens a named confirmation; only the confirmation event attempts deletion."

requirements-completed: [UII-05, UII-06]
coverage:
  - id: D1
    description: Actor and correlation pivots use supported Timeline filters and preserve normal route authorization and scope.
    requirement: UII-05
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/live/timeline_live_test.exs#Timeline actor and correlation pivots use their supported routes and filters
        status: pass
      - kind: integration
        ref: test/threadline/operator_surface/live/actor_live_test.exs#actor evidence opens Timeline with only the supported actor filters
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#actor and correlation pivots re-enter Timeline with only their supported filters
        status: pass
    human_judgment: false
  - id: D2
    description: Saved searches are actor-isolated and restore only committed, supported filters with truthful mutation outcomes.
    requirement: UII-06
    verification:
      - kind: integration
        ref: mix test test/threadline/operator_surface/live/timeline_live_test.exs
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#saved searches keep canonical sharing, long summaries, and destructive actions reachable
        status: pass
    human_judgment: false
  - id: D3
    description: The share control emits a canonical local URL for applied filters only, and receiver access is recomputed by the host.
    requirement: UII-06
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/live/timeline_live_test.exs#saved searches show the approved empty copy and share only canonical applied filters
        status: pass
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#real host denial under Acme support is distinct from busy and disabled
        status: pass
    human_judgment: false
  - id: D4
    description: Long saved-search names and summaries keep Apply and Delete reachable on narrow layouts and at actual 200% browser zoom.
    requirement: UII-06
    verification:
      - kind: e2e
        ref: examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts#saved search actions stay in bounds at verified 200% browser zoom
        status: pass
    human_judgment: false

# Metrics
duration: 29min
completed: 2026-10-10
status: complete
---

# Phase 240 Plan 02: Connected investigation and recovery Summary

**Timeline pivots, actor-owned saved searches, and canonical share URLs now preserve the applied investigation query and host boundaries.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-10-10T11:15:32Z
- **Completed:** 2026-10-10T11:44:54Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Actor and correlation links now use supported filters and return through the normal Timeline route, preserving host authorization and scope.
- Saved searches are isolated to the current identifiable `ActorRef`, persist validated committed filters only, restore through normal query validation, and report failures without implying success. Deletion requires an explicit named confirmation.
- The Timeline shares a canonical local URL for applied filters only. Scope, tenant, cursor, draft values, saved-record identity, and arbitrary URL values are excluded; the receiving host determines access and recomputes results.
- Long names and filter summaries remain inside the saved-search collection with reachable Apply/Delete controls, including at actual desktop 200% browser zoom.
- Pagination keeps the applied URL stable while appending rows and reporting truthful result counts.

## Task Commits

1. **Tasks 1–3: Supported pivots, actor-owned saved searches, and canonical sharing** - `1906f0d3` (`feat`)

## Files Created/Modified

- `timeline_live.ex`, `timeline_live/filters.ex`, and `timeline_live/helpers.ex` - actor-scoped saved-search actions, canonical applied search URL, and concise filter summaries.
- `actor_live.ex` - canonical ordering for the Open Timeline actor link.
- `04_controls.css` - responsive saved-search layout and local wrapping for long values.
- Timeline and actor LiveView tests - ownership, committed-filter persistence, canonical sharing, confirmation, pivots, and failure boundaries.
- `operator-route-states.spec.ts` - desktop/mobile saved-search and pivot journeys, real 200% zoom, and deterministic pagination.
- `240-02-PLAN.md` - records the responsive stylesheet in the plan file inventory.

## Decisions Made

- Keep shared URLs as local query definitions. The recipient host reparses the supported filters, reapplies scope, and authorizes access.
- Save only the committed query assigned through validated route handling; do not persist draft form values or host scope.
- Keep the confirmation modal open on delete failure and scope the delete lookup to the current actor.

## Deviations from Plan

### Auto-fixed Issues

**1. Added the responsive stylesheet to the plan inventory**
- **Found during:** Final plan-to-diff review
- **Issue:** Saved-search overflow behavior required a stylesheet change that the plan inventory did not list.
- **Fix:** Added `lib/threadline/operator_surface/style/04_controls.css` to `files_modified` and Task 3's file list.
- **Verification:** Actual desktop 200% zoom browser test passed and `git diff --check` passed for all Plan 240-02 files.
- **Committed in:** Plan metadata commit.

**Total deviations:** 1 auto-fixed (plan inventory correction)
**Impact on plan:** The stylesheet change implements the planned responsive overflow contract; no database or dependency changes were introduced.

## Issues Encountered

- The final broad repository `git diff --check` identified trailing spaces in an unrelated uncommitted Phase 239 review artifact. That file was preserved; the scoped Phase 240-02 diff check passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs` - 79 tests, 0 failures.
- `mix format --check-formatted` on all modified Elixir source and test files - passed.
- `npm run typecheck` in the Phoenix example E2E package - passed.
- `operator-route-states.spec.ts` on desktop and mobile Chromium - 13 passed, 19 intentionally skipped, 0 failed. The actual 200% zoom scenario runs on desktop Chromium only.
- Scoped `git diff --check` for all Plan 240-02 implementation and plan files - passed.

## Next Phase Readiness

Plan 240-02 is complete. Continue with Plan 240-04 in Wave 2, then Plan 240-03 in Wave 3. Full `mix ci.all` remains a phase-close gate on PostgreSQL 15 or newer; this environment uses PostgreSQL 14.17.

---
*Phase: 240-connected-investigation-and-recovery*
*Completed: 2026-10-10*
