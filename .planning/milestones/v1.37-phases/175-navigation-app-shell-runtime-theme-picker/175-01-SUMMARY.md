---
phase: 175-navigation-app-shell-runtime-theme-picker
plan: 01
subsystem: testing
tags: [exunit, phoenix-liveview, liveviewtest, csp, accessibility, nav, operator-surface, wave-0, red-green]

# Dependency graph
requires:
  - phase: 174-form-components
    provides: "UI component contract-test idioms (rendered_to_string standalone render) and the formless-pages CI guard pattern"
provides:
  - "surface_header_csp_test.exs — standing CSP source-string guard for Plans 02–04 (no inline on*= handlers; theme form posts /theme + _csrf_token)"
  - "page_header_test.exs — NAV-01 one-<h1>-per-page render contract for the future UI.page_header (RED target for Plan 03)"
  - "breadcrumb_test.exs — NAV-01 Breadcrumb landmark + single aria-current contract, driven through the actor drill-down LiveView (RED target for Plan 03)"
  - "pager_test.exs — NAV-02 hide-at-zero / disable-not-hide / role=status caption / 10,000+ cap contract for the future UI.pager (RED target for Plan 04)"
  - "skip_link_test.exs — NAV-04/D-26 GREEN regression lock: all 10 operator pages render <main id=tl-main tabindex=-1>"
affects: [175-02, 175-03, 175-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Source-string CSP contract (File.read! + String.contains? + broad on*= regex) as the standing gate across implementation waves"
    - "Wave 0 RED scaffold idiom: assert the TARGET markup against not-yet-built components/labels so each implementation task has a RED->GREEN signal"
    - "Self-contained per-test LiveView harness (Layouts + Router + Endpoint, DataCase) mounting every operator page at its simplest reachable URL"

key-files:
  created:
    - test/threadline/operator_surface/surface_header_csp_test.exs
    - test/threadline/operator_surface/page_header_test.exs
    - test/threadline/operator_surface/breadcrumb_test.exs
    - test/threadline/operator_surface/pager_test.exs
    - test/threadline/operator_surface/skip_link_test.exs
  modified: []

key-decisions:
  - "CSP guard asserts both specific handlers (onclick/onchange) and a broad on*= regex + an explicit handler list, so a new inline handler in any future form cannot slip past Plans 02–04 (mitigates T-175-01)."
  - "breadcrumb_test drives the real actor drill-down LiveView (which renders the trail today) rather than a pure component render, giving a genuine RED->GREEN signal against the live 'Investigation path' -> 'Breadcrumb' relabel; a legacy-landmark fallback keeps the aria-current assertion honest while RED."
  - "skip_link_test mounts each page at its simplest reachable state (drill-downs at non-existent ids -> not-found state still wraps <main>), and follows the Timeline mount live_redirect one hop, so the GREEN lock needs no elaborate fixtures."

patterns-established:
  - "Wave 0 RED/GREEN test scaffolds precede implementation waves; expected failures are documented in each file's @moduledoc."
  - "Standing CSP source-string gate is reusable across every shell/form change in the phase."

requirements-completed: [NAV-01, NAV-02, NAV-03, NAV-04]

# Metrics
duration: 14min
completed: 2026-06-17
---

# Phase 175 Plan 01: Navigation Wave 0 Test Scaffolds Summary

**Five ExUnit/LiveViewTest scaffolds locking NAV-01..04 — a source-string CSP guard plus page-header, breadcrumb, pager (RED targets for Plans 02–04) and an all-pages skip-link tabindex regression lock (GREEN today).**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-06-17T18:50:30Z
- **Completed:** 2026-06-17
- **Tasks:** 2
- **Files modified:** 5 (all created)

## Accomplishments
- Stood up the phase's standing CSP guard: `surface_header_csp_test.exs` reads `surface_header.ex` as a string and fails while any inline `on*=` handler remains, while locking the `/theme` POST + `_csrf_token` as GREEN regressions.
- Created the NAV-01 render contracts (`page_header_test.exs`, `breadcrumb_test.exs`) that Plans 02–03 turn GREEN: exactly one `<h1 class="tl-page__title">` per page, a `<nav aria-label="Breadcrumb">` trail rooted at "Timeline", and exactly one `aria-current="page"` across a drill-down page.
- Created the NAV-02 pager contract (`pager_test.exs`): hide-at-zero, disable-not-hide on boundaries, a `role="status" aria-live="polite"` "Showing N of … matching changes" caption, and the "10,000+" deep-total cap.
- Locked NAV-04/D-26 as a GREEN regression: `skip_link_test.exs` mounts all 10 operator pages and asserts `<main id="tl-main" tabindex="-1">`.

## Task Commits

Each task was committed atomically:

1. **Task 1: CSP guard + page_header + breadcrumb scaffolds** — `1a05f5b` (test)
2. **Task 2: pager + skip-link scaffolds** — `bd5dfb1` (test)

## Files Created/Modified
- `test/threadline/operator_surface/surface_header_csp_test.exs` — NAV-03/NAV-04 CSP source-string guard (no inline handlers; theme form posts /theme + _csrf_token).
- `test/threadline/operator_surface/page_header_test.exs` — NAV-01 one-`<h1>`-per-page render contract for the future `UI.page_header`.
- `test/threadline/operator_surface/breadcrumb_test.exs` — NAV-01 Breadcrumb landmark + single `aria-current` via the actor drill-down LiveView harness.
- `test/threadline/operator_surface/pager_test.exs` — NAV-02 hide-at-zero / disable-not-hide / status caption / 10,000+ cap render contract for the future `UI.pager`.
- `test/threadline/operator_surface/skip_link_test.exs` — NAV-04/D-26 all-pages `<main tabindex="-1">` regression lock.

## RED/GREEN State (as designed)

Combined run: **20 tests, 9 failures** — matches the planned Wave 0 split.

- **GREEN today (11):** skip_link (10 pages) + CSP `/theme`+`_csrf_token` lock (1). These are regression locks and must stay green.
- **RED today (9, expected):** CSP inline-handler refute (1, RED until Plan 02), page_header (2, RED until Plan 03 builds `UI.page_header`), breadcrumb (2, RED until Plan 03 relabels "Investigation path" → "Breadcrumb"), pager (4, RED until Plan 04 builds `UI.pager`).

## Decisions Made
- CSP guard combines specific (`onclick=`/`onchange=`) + explicit-list + broad-regex assertions to mitigate T-175-01 (a loosely-written guard missing a new handler).
- breadcrumb_test drives the live actor drill-down (real RED→GREEN against the on-page relabel) with a legacy-landmark fallback so the `aria-current` count assertion inspects the right region while still RED.
- skip_link_test mounts pages at their simplest reachable state and follows the Timeline canonicalization `live_redirect`, avoiding fragile per-page fixtures.

## Deviations from Plan

None - plan executed exactly as written. The plan permitted either a component render or a LiveView mount for breadcrumb_test; the LiveView-mount option was chosen for a more honest RED→GREEN signal.

## Issues Encountered
- A `#{base}` token inside the CSP test's `@moduledoc` was parsed as string interpolation (compile error). Rewrote the doc/message prose to avoid interpolation. Resolved before the Task 1 commit.
- Timeline mount returns `{:error, {:live_redirect, ...}}` because it canonicalizes its URL with default window params. Added a one-hop redirect-follow helper in skip_link_test. Resolved before the Task 2 commit.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plans 02–04 now each have an automated RED target to turn GREEN: Plan 02 (CSP handler removal), Plan 03 (page_header + breadcrumb relabel), Plan 04 (pager).
- The CSP source-string guard is the standing gate for every shell/form change in the phase.
- skip_link_test stands as a regression lock so no future page can silently drop the skip-link focus target.

## Self-Check: PASSED

All 5 test files present; commits `1a05f5b` and `bd5dfb1` verified in git log.

---
*Phase: 175-navigation-app-shell-runtime-theme-picker*
*Completed: 2026-06-17*
