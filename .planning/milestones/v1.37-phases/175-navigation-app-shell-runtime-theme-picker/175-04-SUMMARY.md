---
phase: 175-navigation-app-shell-runtime-theme-picker
plan: 04
subsystem: operator-surface
tags: [pager, pagination, accessibility, nav, keyset, wave-4, red-green, role-status]

# Dependency graph
requires:
  - phase: 175-01
    provides: "pager_test.exs Wave-0 RED target (this plan turns all 4 GREEN)"
  - phase: 175-03
    provides: "UI.page_header adopted across pages — Timeline/Actor/Exports/Retention pages the pager threads into"
provides:
  - "Internal UI.pager/1: de-emphasized Older/Newer time-axis controls + a role=status aria-live=polite range caption over the EXISTING keyset engine; hide-at-zero, disable-not-hide, capped 10,000+ deep total"
  - "Timeline next-only pager (older_event=next-page; cursor stays in socket assign per D-19) and Actor bidirectional pager (prev-page/next-page) over the existing events — no engine change"
  - "Honest 'Showing latest N' cap captions on Exports (100) and Retention (40) in role=status regions; Coverage/Redaction get no pager (D-20)"
  - "query.ex doc note: the (captured_at, id) keyset tiebreaker is currently backed only by the single-column capture-layer index; the composite (captured_at, id) index is DEFERRED capture-layer perf debt (D-15/Q1, T-175-10 accepted)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pager/1 controls emit the host page's EXISTING next-page/prev-page events (phx-click) — pagination is a presentation layer over the keyset engine, not a new engine"
    - "Honest range caption: reuse the capped 10_001 -> '10,000+' path (never a fabricated/exact deep total) inside a role=status aria-live=polite live region"
    - "Boundary controls disabled-not-hidden (D-18) and visibly muted (--tl-color-muted + reduced opacity), avoiding the 'disabled-looks-enabled' footgun"

key-files:
  created:
    - .planning/phases/175-navigation-app-shell-runtime-theme-picker/175-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/query.ex

key-decisions:
  - "[175-04]: pager_test.exs (the binding RED target) calls the component with shown/match_count/has_older/has_newer attrs — these are the authoritative signature, not the planner's interface guess (newer_event/older_enabled/etc). Built pager/1 to that contract, layering optional older_event/newer_event phx-click attrs (defaults next-page/prev-page) for adoption so the standalone render in the test exercises both controls."
  - "[175-04]: newer_event attr is :any (not :string) so Timeline (next-only) can pass nil to omit the Newer control entirely while Actor passes 'prev-page'; the :if={@newer_event} guard drops the Newer button only when nil, otherwise renders it disabled at a boundary (D-18)."
  - "[175-04]: Actor has no computed deep total (keyset-only stream), so its pager passes match_count = shown = length(inserts); the disabled/enabled Older control is the honest 'more exists' signal. Timeline passes the real @match_count (capped). No COUNT(*) introduced (T-175-09 held)."
  - "[175-04]: Exports/Retention cap captions hardcode the literal limits (100/40) with a source comment pointing at @default_limit — @default_limit is a module attribute, not an assign, and `unquote` is illegal inside ~H; the literal is the simplest honest render."
  - "[175-04]: query.ex D-15 reframe is a DOC NOTE only on timeline_order/1 — no migration, no query-logic change. The composite (captured_at, id) index is deferred capture-layer perf debt; the capture layer is byte-for-byte untouched (T-175-10 accepted)."

requirements-completed: [NAV-02]

# Metrics
duration: ~12min
completed: 2026-06-17
---

# Phase 175 Plan 04: Internal Pager + Honest Cap Captions Summary

**Built one internal de-emphasized `UI.pager/1` (Older/Newer time-axis controls + a `role="status" aria-live="polite"` range caption) over the EXISTING keyset engine — hide-at-zero, disable-not-hide, capped "10,000+" — adopted it next-only on Timeline and bidirectionally on Actor (cursor stays in assign), added honest "Showing latest N" cap captions on Exports/Retention, and documented the `(captured_at, id)` keyset tiebreaker as deferred capture-layer perf debt — turning the final 4 NAV-02 Wave-0 RED targets GREEN with zero new `--tl-*` token and the capture layer untouched.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-06-17
- **Tasks:** 2
- **Files modified:** 7 (1 SUMMARY created)

## Accomplishments

- **Built `UI.pager/1`** (`ui.ex`, `@doc false`): a `<nav class="tl-pager" aria-label="Timeline pagination">` rendered only when `match_count > 0` (hide-at-zero, D-16); a "Newer" `<button>` (omitted when `newer_event == nil`, else rendered with `disabled={!@has_newer}`), a `<span class="tl-pager__range" role="status" aria-live="polite">` "Showing {shown} of {total} matching changes" caption, and an "Older" `<button disabled={!@has_older}>`. Copy is time-axis "Older"/"Newer" (D-17), never "Next/Previous" or page numbers. A private `pager_total/1` caps `>= 10_001` at "10,000+" (never an exact deep total, T-175-09) and renders thousands separators below the cap.
- **De-emphasized `.tl-pager` styles** (`style.ex`): control gap `--tl-space-2`, range caption at the Label role (`--tl-font-size-label`, `--tl-color-muted`, tabular-nums), and a muted/`opacity:0.55` disabled state on `.tl-pager__control[disabled]` so a boundary control reads as visibly inactive (PAGE-02 "disabled-looks-enabled" footgun avoided). **Zero new `--tl-*` token** — brand-token parity stays green.
- **Timeline adoption** (next-only): `<UI.pager>` after the change list with `older_event="next-page"`, `has_older={@cursor != nil}`, `newer_event={nil}`, `shown={length(@streams.changes.inserts)}`, `match_count={@match_count}`. Infinite scroll (`phx-viewport-bottom`) stays primary; the cursor stays in the socket assign, never the URL (D-19, T-175-08).
- **Actor adoption** (bidirectional): `<UI.pager>` after the transactions stream with `newer_event="prev-page"`/`has_newer={@prev_cursor != nil}` and `older_event="next-page"`/`has_older={@next_cursor != nil}`. Reuses the existing prev-page/next-page handlers and the `phx-viewport-top/bottom` infinite scroll.
- **Exports + Retention honest cap captions** (D-20): a `role="status" aria-live="polite"` "Showing latest 100 / 40 … (most recent first)" caption near the list/table — NOT a keyset pager (recent-only, low-volume). Coverage and Redaction got no pager.
- **query.ex D-15 doc note**: a comment on `timeline_order/1` documenting that `ORDER BY captured_at DESC, id DESC` is backed only by the single-column capture-layer `(captured_at)` index, that the composite `(captured_at, id)` index is DEFERRED capture-layer perf debt (Q1 resolution), and that ties are rare (microsecond timestamp + random UUID PK). No migration, no query-logic change.

## Task Commits

Each task was committed atomically:

1. **Task 1: add internal pager/1 + de-emphasized styles** — `1a230bd` (feat)
2. **Task 2: adopt pager on Timeline/Actor + cap captions + D-15 doc note** — `ac6f762` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/ui.ex` — new `pager/1` (+ private `pager_total/1`); `newer_event` attr is `:any` to permit `nil` (timeline next-only).
- `lib/threadline/operator_surface/style.ex` — `.tl-pager` / `.tl-pager__range` / `.tl-pager__control[disabled]` styles on existing tokens (no new token).
- `lib/threadline/operator_surface/live/timeline_live.ex` — next-only pager after the change list.
- `lib/threadline/operator_surface/live/actor_live.ex` — bidirectional pager after the transactions stream.
- `lib/threadline/operator_surface/live/export_status_live.ex` — "Showing latest 100" cap caption.
- `lib/threadline/operator_surface/live/retention_history_live.ex` — "Showing latest 40" cap caption.
- `lib/threadline/query.ex` — D-15 keyset perf-debt doc note on `timeline_order/1`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Component signature reconciled to the binding test contract**
- **Found during:** Task 1
- **Issue:** The plan's `<interfaces>` described a `pager/1` signature (`newer_event`/`older_enabled`/`shown`/`total`/`capped`). The actual Wave-0 RED target `pager_test.exs` invokes the component as `<UI.pager shown={N} match_count={N} has_older={bool} has_newer={bool} />`. The test is the binding contract.
- **Fix:** Built `pager/1` with the test's attrs (`shown`, `match_count`, `has_older`, `has_newer`) and layered optional `older_event`/`newer_event` phx-click attrs (defaults `"next-page"`/`"prev-page"`) for live adoption. The standalone test render (no event attrs) therefore exercises both controls and the caption.
- **Files modified:** `lib/threadline/operator_surface/ui.ex`
- **Commit:** `1a230bd`

**2. [Rule 3 - Blocking] `newer_event` attr widened from `:string` to `:any`**
- **Found during:** Task 2 (`mix compile --warnings-as-errors`)
- **Issue:** Timeline is next-only and passes `newer_event={nil}` to omit the Newer control; with `attr :newer_event, :string` Phoenix emitted a `must be a :string, got: nil` warning, failing the warnings-as-errors gate.
- **Fix:** Changed the attr type to `:any` (default still `"prev-page"`); the `:if={@newer_event}` guard drops the Newer button only when nil.
- **Files modified:** `lib/threadline/operator_surface/ui.ex`
- **Commit:** `ac6f762`

**3. [Rule 3 - Blocking] Cap-caption limit literals instead of `unquote(@default_limit)`**
- **Found during:** Task 2 (`mix compile`)
- **Issue:** Initial drafts used `<%= unquote(@default_limit) %>` to reference each page's module attribute; `unquote` is illegal outside `quote`, and `@default_limit` is a compile-time module attribute (not a render assign).
- **Fix:** Rendered the literals (100 / 40) with a source comment pointing at `@default_limit`. The captions stay honest about the cap.
- **Files modified:** `export_status_live.ex`, `retention_history_live.ex`
- **Commit:** `ac6f762`

### Scope decisions (documented, not auto-fixes)

**4. Actor pager passes `match_count = shown` (no deep total computed).** The actor history view is a keyset-only stream with no `COUNT(*)`; introducing one would violate T-175-09. The enabled/disabled Older control is the honest "more exists" signal. Timeline passes the real capped `@match_count`.

## TDD Gate Compliance

Tasks are `type="auto"` (not `tdd="true"`); the RED targets were authored in Plan 01. The RED → GREEN signal was honoured: `pager_test.exs` was confirmed RED at start (4 failures, `UI.pager/1` undefined) and GREEN after Task 1.

## Verification

- `mix test test/threadline/operator_surface/pager_test.exs` — GREEN (all 4 NAV-02 Wave-0 RED targets now GREEN).
- `mix test test/threadline/operator_surface/ test/threadline/brandbook_token_parity_test.exs` — **500 tests, 0 failures** (was 4 PagerTest failures; brand-token parity GREEN).
- `mix test test/threadline/operator_surface/transaction_live_test.exs` — GREEN (16 tests).
- `mix verify.test` — **1008 tests, 0 failures** (1 excluded). No NAV lock regressed (CSP/skip-link/page_header/breadcrumb stay green).
- `mix verify.credo` — no issues (2038 mods/funs).
- `mix format --check-formatted` — clean.
- `mix compile --warnings-as-errors` — clean.
- `git diff --quiet lib/threadline/capture/` — **capture layer byte-for-byte UNTOUCHED**; no migration added; no query logic changed (D-15 is a doc note only).
- **Not run here:** `mix ci.all`'s Playwright `verify.example_browser` (browser harness). The pager reuses existing keyset events and adds no JS; recommend running it at `/gsd:verify-work`.

## Known Stubs

None. The pager is wired to real assigns on Timeline (`@match_count`, `@cursor`) and Actor (`@next_cursor`, `@prev_cursor`, stream inserts); the cap captions reflect the real `@default_limit` cap; the query.ex change is documentation only.

## Threat Flags

None. No new network endpoint, auth path, or schema change. The pager emits the existing trusted `next-page`/`prev-page` events; the cursor stays in the socket assign (T-175-08); the capped count path is reused (T-175-09); the unbacked keyset tiebreaker is documented and accepted (T-175-10).

## Self-Check: PASSED

All 7 modified files present on disk; commits `1a230bd` and `ac6f762` verified in git log; SUMMARY.md created.

---
*Phase: 175-navigation-app-shell-runtime-theme-picker*
*Completed: 2026-06-17*
