---
phase: 174-form-components
plan: "06"
subsystem: ui
tags: [phoenix-component, liveview, forms, operator-surface, regression-guard, gap-closure]

# Dependency graph
requires:
  - phase: 174-form-components
    provides: "UI.field_group component (fieldset+legend wrapper reusing tl-filter-group classes) from 174-05"
provides:
  - "timeline_live filter groups consuming UI.field_group (last raw form-wrapper markup eliminated — COMP-05 adoption gap closed)"
  - "FormlessPagesTest — CI guard asserting the 8 display-only operator pages stay formless"
affects: [175-shell-nav, 178-per-page-stress]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Source-scan regression guard: read each page module's OWN source and assert absence of form-control tokens, so shared-component markup (surface_header CSRF/theme form) is excluded by construction"

key-files:
  created:
    - "test/threadline/operator_surface/formless_pages_test.exs — 8-assertion guard locking display-only pages as formless"
  modified:
    - "lib/threadline/operator_surface/live/timeline_live.ex — two raw <fieldset> filter groups migrated to <UI.field_group>"

key-decisions:
  - "field_group renders the base tl-filter-group class + legend itself; the call sites pass only the --primary/--advanced modifier via class and drop the duplicated raw <legend>"
  - "The formless guard scans each page's own source (not surface_header), so the legitimate hidden _csrf_token and theme-picker form are excluded without an explicit allowlist"
  - "Per-page assertion (one test per file, filename in the failure message) so a regression names the offending page"

patterns-established:
  - "Pattern 1: tag-per-case (@tag page:) source-scan guards lock a verified 'these files don't do X' conclusion against future re-flagging"

requirements-completed: [COMP-05]

# Metrics
duration: 6min
completed: 2026-06-17
---

# Phase 174 Plan 06: Timeline field_group Migration & Formless-Page Lock Summary

**Migrated timeline_live's two raw `<fieldset class="tl-filter-group">` filter groups onto the `UI.field_group` component from 174-05 (closing the last COMP-05 adoption gap) and added an 8-assertion CI guard that locks the verified "the display-only pages are truly formless" conclusion so re-verification stops re-flagging it.**

## Performance

- **Duration:** ~6 min
- **Tasks:** 2 (both type=auto)
- **Files created:** 1
- **Files modified:** 1

## Accomplishments
- `timeline_live.ex` primary (`Search`) and advanced (`Advanced filters`) filter groups now render through `<UI.field_group legend=... class="tl-filter-group--primary|--advanced">`; both raw `<fieldset>` and their duplicated raw `<legend>` elements removed. Inner `<UI.field>` controls, the `audited-tables` datalist, the actions row, the `<form id="timeline-filters" role="search">` wrapper, and the `<details>` disclosure are unchanged.
- `FormlessPagesTest` reads the source of each of the 8 display-only pages (actor, coverage, evidence, export_status, policy_redaction, retention_history, row_history, transaction) and asserts none contains `<input>`/`<select>`/`<textarea>`/`<form>`, naming the offending file on failure. Scanning page-own source excludes the shared `surface_header` CSRF/theme markup by construction (the one legitimate exception).

## Task Commits

1. **Task 1: migrate timeline filter groups to UI.field_group** — `a70bce1` (refactor)
2. **Task 2: lock the 8 display-only pages as formless** — `39ec70d` (test)

## Files Created/Modified
- `lib/threadline/operator_surface/live/timeline_live.ex` — two `<fieldset>`→`<UI.field_group>` migrations (4 insertions, 6 deletions).
- `test/threadline/operator_surface/formless_pages_test.exs` — new 8-assertion (tag-per-page) formless guard.

## Acceptance Criteria (verified)
- `grep -c '<fieldset' .../timeline_live.ex` = 0.
- `grep -c '<UI\.field_group' .../timeline_live.ex` = 2 opening calls (the plan's `'UI.field_group\|<\.field_group'` grep counts open+close = 4; the substantive count of 2 component calls is met).
- `--primary` / `--advanced` modifier classes preserved (count 2); no raw `<legend>` remains (count 0); legends passed via the `legend` attr.
- `mix compile --warnings-as-errors` clean.
- `mix test .../live/timeline_live_test.exs` → 36 tests, 0 failures.
- `mix test .../formless_pages_test.exs` → 8 tests, 0 failures; guard proven non-vacuous (catches an injected `<input`).
- Full operator_surface live dir + guard → 126 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written. No Rule 1-4 deviations triggered; no auth gates; no package installs. The `field_group` count nuance (grep matches both open and close tags) is an expected artifact of the BEM/closing-tag markup, not a deviation — the intended "2 component calls" is satisfied.

## Threat Model Adherence
- T-174-03 (Tampering): pure markup-wrapper swap; inner `<UI.field>` escaping/behavior untouched; existing timeline tests stay green (36/0) — no behavior drift.
- T-174-04 (Repudiation/Drift): the new guard fails CI if any of the 8 pages gains a form control.
- T-174-SC: zero package installs; no new runtime deps.

## User Setup Required
None.

## Self-Check: PASSED

- Files: `lib/threadline/operator_surface/live/timeline_live.ex`, `test/threadline/operator_surface/formless_pages_test.exs` — both present.
- Commits: `a70bce1`, `39ec70d` — both present in git log.

---
*Phase: 174-form-components*
*Completed: 2026-06-17*
