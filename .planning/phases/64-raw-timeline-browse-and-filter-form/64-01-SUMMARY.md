---
phase: 64-raw-timeline-browse-and-filter-form
plan: "01"
subsystem: operator_surface
tags:
  - liveview
  - timeline
  - filter-form
  - infinite-scroll
  - url-as-state
dependency_graph:
  requires:
    - lib/threadline/query.ex
    - lib/threadline/health.ex
    - lib/threadline/semantics/actor_ref.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/router.ex
  provides:
    - Threadline.OperatorSurface.Live.TimelineLive
    - live("/", TimelineLive, :index) route in operator surface router
    - CSS namespace extensions for timeline toolbar/form/filter UI
    - Inline ← Timeline back-links in TransactionLive and ActorLive
  affects:
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex
tech_stack:
  added:
    - TimelineLive LiveView with push_patch URL-as-state, phx-viewport-bottom infinite scroll
    - scope_aware_opts/1 helper (Phase 65 controller reuse point)
    - filters_raw_from_params/1 for URL-echo form hydration
  patterns:
    - File-scope Code.ensure_loaded?(Phoenix.LiveView) gate (Sentry idiom)
    - Cursor-in-assigns, never in URL (keyset pagination contract)
    - Native HTML widgets only: datetime-local, select, text inputs
    - push_patch with replace: true for default-window redirect
key_files:
  created:
    - lib/threadline/operator_surface/live/timeline_live.ex (408 lines)
  modified:
    - lib/threadline/operator_surface/router.ex (+1 line)
    - lib/threadline/operator_surface/style.ex (+88 lines, 216 total)
    - lib/threadline/operator_surface/live/transaction_live.ex (+1 line)
    - lib/threadline/operator_surface/live/actor_live.ex (+13 lines)
decisions:
  - scope_aware_opts/1 uses bracket-form socket.assigns[:threadline_scope] (may be nil when :authorize_fn returns :ok/true)
  - String.to_existing_atom/1 only for actor_kind URL params (no atom-table leak)
  - Fully-qualified Threadline.Health.trigger_coverage and Threadline.Query.validate_timeline_filters! for grep-pinned Plan 03 doc-contract test
  - timeline-rows container renders unconditionally; empty-state is :if= inside the container
metrics:
  duration: "~7 minutes"
  completed_date: "2026-05-07"
  tasks_completed: 4
  files_count: 5
---

# Phase 64 Plan 01: TimelineLive Core + Router + Style + Back-links Summary

Ship `Threadline.OperatorSurface.Live.TimelineLive` at surface root `/audit` with full `Threadline.Query.timeline/2` filter parity, URL-as-state via `push_patch`, `phx-viewport-bottom` infinite scroll, `:authorize_fn`-scope threading, and inline `← Timeline` back-links on TransactionLive and ActorLive.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create TimelineLive | 9c0e8b1 | lib/threadline/operator_surface/live/timeline_live.ex (new, 408 lines) |
| 2 | Wire live("/", TimelineLive, :index) into router | 3e6b2d1 | lib/threadline/operator_surface/router.ex (+1) |
| 3 | Extend Style CSS with toolbar/form/button-cluster/filter rules | ed576be | lib/threadline/operator_surface/style.ex (+88) |
| 4 | Add ← Timeline back-links to TransactionLive and ActorLive | 09ff7ae | transaction_live.ex (+1), actor_live.ex (+13) |
| 4b | Format fixes after mix format | 850616f | timeline_live.ex, actor_live.ex (format only) |

## scope_aware_opts/1 Signature (Phase 65 Reuse Point)

```elixir
defp scope_aware_opts(socket) do
  base = [repo: socket.assigns.repo, page_size: @page_size]

  case socket.assigns.scope do
    nil   -> base
    scope -> Keyword.merge(base, scope_to_query_opts(scope))
  end
end

# Phase 64 passthrough — extension point for v1.19+ scope-derived predicates.
defp scope_to_query_opts(_scope), do: []
```

Phase 65's export controller will call `scope_aware_opts(socket)` verbatim to source `repo:` and `page_size:` and merge any future scope-derived predicates in a single spot.

## Canonical Query-String Ordering (build_canonical_query/1)

Keys are ordered by their position in `@filter_keys`:
```
@filter_keys ~w(from to table actor_kind actor_id correlation_id)
```

So `?from=...&to=...&table=...&actor_kind=...&actor_id=...&correlation_id=...` is the canonical form. Empty strings and `actor_id` on anonymous actors are scrubbed before encoding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Safety] Used fully-qualified module names for grep-pinned calls**
- **Found during:** Task 1 verification
- **Issue:** Aliases `Health.trigger_coverage` and `Query.validate_timeline_filters!` would fail Plan 03 grep-contract assertions that check for `Threadline.Health.trigger_coverage` and `Threadline.Query.validate_timeline_filters!`
- **Fix:** Used fully-qualified `Threadline.Health.trigger_coverage` and `Threadline.Query.validate_timeline_filters!` in the implementation
- **Files modified:** lib/threadline/operator_surface/live/timeline_live.ex
- **Commit:** 9c0e8b1

**2. [Rule 2 - Safety] Removed @actor_kinds attribute and Health alias**
- **Found during:** Task 1 compile
- **Issue:** `@actor_kinds` module attribute defined but never used (render template uses inline `~w(...)` literal); `alias Threadline.Health` unused since fully-qualified form was adopted
- **Fix:** Removed both; compile passes with `--warnings-as-errors`
- **Files modified:** lib/threadline/operator_surface/live/timeline_live.ex
- **Commit:** 9c0e8b1

**3. [Rule 1 - Bug] String.to_atom/1 in normalize_params/1**
- **Found during:** Task 1 verification (F-1 prohibition check)
- **Issue:** `normalize_params/1` used `String.to_atom(key)` to convert @filter_keys keys; @filter_keys are fixed compile-time strings so all atoms already exist in the atom table
- **Fix:** Changed to `String.to_existing_atom(key)` — safe since all six keys exist as atoms
- **Files modified:** lib/threadline/operator_surface/live/timeline_live.ex
- **Commit:** 9c0e8b1

## Known Stubs

None. All filter fields are wired to URL params and query execution. The `scope_to_query_opts/1` function returns `[]` intentionally — this is a documented Phase 64 passthrough, not a stub (the comment in the source says "Phase 64 passthrough — extension point for v1.19+ scope-derived predicates").

## Threat Flags

None. This plan adds read-only LiveView UI surface. All data access goes through the existing `Threadline.Query.timeline_page/2` with the same auth contract (`:authorize_fn`, `:threadline_scope`) that v1.17 shipped. No new network endpoints, no new auth paths, no new file access patterns.

## Verification Commands That Passed

```bash
mix compile --warnings-as-errors  # clean
mix verify.compile_no_optional    # LV-absent compile stays green
mix verify.format                 # formatter clean after style fix
mix verify.credo                  # 0 issues, 532 mods/funs
mix test test/threadline/operator_surface/  # 21 tests, 0 failures
mix verify.test                   # 301 tests, 0 failures (1 excluded)
```

## Self-Check: PASSED
