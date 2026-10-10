---
phase: 242-export-and-retention-operations
plan: "01"
subsystem: exports
tags: [elixir, phoenix-liveview, postgres, actor-ownership, export-download]
requires: []
provides:
  - Actor-owned export history distinguishes loading, empty, read failure, and persisted lifecycle state.
  - Timeline export jobs preserve only committed supported filters and return to a canonical local Timeline URL.
  - Accepted queue feedback remains visible after navigation; ready downloads use the existing protected request-time controller.
affects: [242-02, export-operations]
actuals:
  tokens: 6362
  tasks: 2
  commits: 2
  plan_head_before: 37645c5eed4a78de586e550fca6b4e5f16e115f6
  plan_head_after: 3a53de27f0cdee02f2ac06aebab4f42c6b62507b
tech-stack:
  added: []
  patterns:
    - Persisted actor-owned jobs remain the source of export status; delivery stays request-time authorized.
    - Render read failures separately from successful empty history and provide an explicit refresh action.
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/export_status_live/components.ex
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
key-decisions:
  - "Keep ExportJob actor ownership as the status authority and retain controller checks for current owner, status, expiry, and storage availability."
  - "Persist only committed FilterParams-supported fields and reconstruct local Timeline returns with an unfiltered fallback."
  - "No dependency added; preserve intentional repeat export requests."
requirements-completed: [UIO-01]
coverage:
  - id: D1
    description: "A committed supported Timeline search can be queued, downloaded through the protected endpoint, and reopened with the same canonical filters."
    requirement: UIO-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs"
        status: pass
      - kind: e2e
        ref: "Playwright operator-route-states.spec.ts — desktop-chromium and mobile-chromium"
        status: pass
    human_judgment: false
  - id: D2
    description: "Export history read errors, successful empty history, persisted lifecycle states, and safe local return links remain distinct."
    requirement: UIO-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs"
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-10-10
status: complete
---

# Phase 242 Plan 01: Export Journey and Lifecycle Summary

**Committed Timeline filters now flow through actor-owned export jobs to a protected download and a canonical local return search, with truthful history and queue feedback.**

## Performance

- **Duration:** 24 minutes
- **Started:** 2026-10-10T20:40:00Z
- **Completed:** 2026-10-10T21:04:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- The Timeline stores only committed, validated supported filters on an export job. Unsupported fields and arbitrary return URLs do not enter saved context; empty searches return to the local base Timeline.
- Export history distinguishes loading, successful empty history, unreadable history, and persisted job states. A read failure can be retried and never appears as an empty result.
- The mounted desktop and mobile journey queues from Timeline, confirms the accepted message, receives an attachment response from the protected download route, and reopens the same supported query.
- The existing controller remains responsible for current actor ownership, job status, expiry, and storage availability at download time. No dependency was added.

## Task Commits

1. **Task 1: Tracer: export one committed search, download its artifact, and return** — `224018e3` (`feat(242-01): complete committed export journey`)
2. **Task 2: Complete export state and delivery failure distinctions** — `3a53de27` (`fix(242-01): distinguish export lifecycle and read failures`)

Plan metadata and phase state updates are being reconciled by the root executor.

## Files Created/Modified

- `lib/threadline/operator_surface/live/timeline_live.ex` — Saves supported committed filters and shows approved adapter acceptance/failure feedback.
- `lib/threadline/operator_surface/live/export_status_live.ex` — Separates export-history loading, errors, empty state, and visible navigation feedback.
- `lib/threadline/operator_surface/live/export_status_live/components.ex` — Builds safe local source-return links and protects download usability claims.
- `test/threadline/operator_surface/live/export_status_live_test.exs` — Covers empty/read-failure states, committed filters, safe source returns, and lifecycle copy.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` — Adds the mounted queue, protected download, and return journey.

## Decisions Made

- Preserved the existing actor-owned ExportJob model and controller's request-time delivery checks.
- Kept return navigation local and reconstructed it only from validated, committed supported filter fields.
- Added no package or architectural dependency.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve accepted queue feedback across navigation**
- **Found during:** Task 1 mounted journey
- **Issue:** Timeline set the approved `put_flash` message before navigating to Exports, but ExportStatusLive did not render flash messages, so operators could not see that queue acceptance had occurred.
- **Fix:** Render the existing info and error flashes on the Exports page with status/alert semantics.
- **Files modified:** `lib/threadline/operator_surface/live/export_status_live.ex`
- **Verification:** Desktop and mobile mounted journey pass and assert the exact approved success copy.
- **Committed in:** `224018e3`

**2. [Rule 1 - Test fixture] Open the Timeline filter drawer before queueing**
- **Found during:** Task 1 mounted journey
- **Issue:** The new browser test looked for Queue export before opening the existing Filters drawer where that control lives.
- **Fix:** Open Filters before locating and clicking Queue export.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`
- **Verification:** Both desktop and mobile Chromium projects pass.
- **Committed in:** `224018e3`

**Total deviations:** 2 auto-fixed. Both were required to make the acceptance journey truthful and executable; no scope or dependency changes were introduced.

## Verification

- `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs` — **59 tests, no errors**.
- Mounted browser journey on `desktop-chromium` and `mobile-chromium` — **2 passed**. The direct local Playwright invocation used the existing cached Chromium because the standard Mix wrapper stalled during redundant package/browser setup in an empty runner cache; no lockfile or dependency was changed by the successful run.
- `mix format --check-formatted` on the four touched Elixir files — passed.
- `git diff --check` on the five task files — passed. A full-tree check still reports pre-existing trailing whitespace in unrelated `239-REVIEW.md`.

## Issues Encountered

The first browser attempt could not launch Chromium in the sandbox because macOS Mach port registration was denied. The rerun used the approved local browser execution path. Its first completed journey exposed the missing Exports flash render; after that fix and the drawer interaction correction, both projects passed.

## User Setup Required

None.

## Next Phase Readiness

The committed-search export-to-download path and the persisted history distinctions are ready for the remaining Phase 242 retention-operations plan.

---
*Phase: 242-export-and-retention-operations*
*Completed: 2026-10-10*

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Both task commit hashes are ancestors of the current HEAD.
- The plan ledger measures two task commits from the recorded base through `3a53de27`.
