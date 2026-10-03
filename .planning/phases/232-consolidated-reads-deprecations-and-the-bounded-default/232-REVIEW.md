---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
reviewed: 2026-10-03T00:00:00Z
depth: standard
files_reviewed: 41
files_reviewed_list:
  - examples/threadline_phoenix/priv/scripts/incident_replay.exs
  - examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs
  - lib/threadline.ex
  - lib/threadline/export.ex
  - lib/threadline/investigation.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/page.ex
  - lib/threadline/query.ex
  - lib/threadline/query/cursors.ex
  - lib/threadline/query/history_limit.ex
  - lib/threadline/query/legacy_opts.ex
  - lib/threadline/query/row_reads.ex
  - lib/threadline/telemetry.ex
  - mix.exs
  - test/support/keyset_model.ex
  - test/support/row_history.ex
  - test/threadline/actor_reads_doc_contract_test.exs
  - test/threadline/audit_indexing_doc_contract_test.exs
  - test/threadline/continuity_brownfield_test.exs
  - test/threadline/deprecation_parity_test.exs
  - test/threadline/facade_naming_contract_test.exs
  - test/threadline/facade_only_references_contract_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/incident_playbook_doc_contract_test.exs
  - test/threadline/investigation_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/row_history_component_test.exs
  - test/threadline/page_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/action_hydration_test.exs
  - test/threadline/query/as_of_property_test.exs
  - test/threadline/query/cursors_property_test.exs
  - test/threadline/query/row_key_composite_test.exs
  - test/threadline/query/row_key_legacy_test.exs
  - test/threadline/query/row_key_override_test.exs
  - test/threadline/query/row_key_read_test.exs
  - test/threadline/query/row_key_types_test.exs
  - test/threadline/query_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/row_history_test.exs
  - test/threadline/telemetry_registry_contract_test.exs
  - test/threadline/upgrade_backfill_test.exs
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 232: Code Review Report

**Reviewed:** 2026-10-03
**Depth:** standard
**Files Reviewed:** 41
**Status:** issues_found

## Summary

Reviewed the consolidated `row_history/3` read path, the new `Threadline.Page`
cursor contract, the `RowReads`/`LegacyOpts`/`Cursors` helper modules, the
deprecated-delegate shims in `Threadline.`/`Threadline.Query`/
`Threadline.Investigation`, the truncation-telemetry wiring, and the forced
operator-UI call-site edits in `actor_live.ex`, `row_history_component.ex`,
and `timeline_live.ex`.

The bounded-default/cursor/telemetry machinery (`RowReads`, `Cursors`,
`HistoryLimit`, `LegacyOpts`, `Threadline.Page`) is internally consistent and
matches the 232-CONTEXT.md locked decisions (D-01 through D-19) closely —
`has_more` exactness (D-08), the `cursor: :start`/`nil` rule (D-07), the
exact-201-row truncation probe (D-14), and the arity-collision avoidance for
the new `row_history/2,3` vs. the retired `/4` clause (D-12) are all
implemented as specified.

One genuine logic bug was found in the forced `actor_live.ex` cursor-tracking
edit: `next-page` now sets `prev_cursor` to a value that, when the user
subsequently scrolls back up, re-fetches and re-prepends content already on
screen. This was not present before this phase (the old handler never touched
`prev_cursor` on a forward page load) and is not covered by
`actor_live_test.exs`.

## Critical Issues

### CR-01: `next-page` in actor_live.ex sets `prev_cursor` to a value that causes duplicate re-fetch on scroll-up

**File:** `lib/threadline/operator_surface/live/actor_live.ex:341`

**Issue:** On `mount`/`set_window`, `prev_cursor` is (correctly) always `nil`
— there is nothing "newer" than the first page, since the view starts at the
most recent transaction. The `"next-page"` handler (fired by
`phx-viewport-bottom`, loading an older page and appending it at the bottom
via `stream(:transactions, page.entries, at: -1)`) now also does:

```elixir
|> assign(:prev_cursor, newer_boundary_cursor(page.entries))
```

`newer_boundary_cursor/1` returns the cursor of the *newly-fetched older
page's own first (newest) entry* — i.e., the boundary between the
already-displayed top content and the newly-appended bottom content. This
makes `prev_cursor` non-`nil` after the very first scroll-down, which flips
`has_newer={@prev_cursor != nil}` to `true` in the pager
(`actor_live.ex:283`) even though nothing newer than what's already on
screen actually exists.

If the user then scrolls back to the top and `phx-viewport-top="prev-page"`
fires, `handle_event("prev-page", ...)` calls `Threadline.actor_history` with
`cursor: {:before, socket.assigns.prev_cursor}`. Per `Cursors.actor_history_window/3`,
a `{:before, cursor}` walk fetches every row *newer* than that cursor — which
is exactly the entire already-displayed top page (and, after further
scrolling, every previously-loaded older page too, since `prev_cursor` is
reset to each new batch's own start on every `next-page` call). The result
is re-fetched and re-prepended (`stream(..., at: 0)`) duplicate rows, and a
wasted/incorrect DB round trip triggered by viewport-top on content that
never moved.

Before this phase, the equivalent handler never assigned `:prev_cursor` on a
forward (`next-page`) load — confirmed by diffing against the pre-phase
version (`git show 30016de7:lib/.../actor_live.ex`), which left `prev_cursor`
untouched in that branch. The forced D-09 call-site rewrite introduced this
line; it is not required by the `Threadline.Page`/`cursor:` contract and
breaks the "newer" boundary invariant.

**Fix:** Drop the new `prev_cursor` reassignment in the `"next-page"` handler
— it should stay whatever it already was (`nil`, since nothing above the
top has changed):

```elixir
{:noreply,
 socket
 |> assign(:actor_summaries, actor_summaries)
 |> assign(:next_cursor, page.cursor)
 |> Phoenix.Component.update(:shown_count, &(&1 + length(page.entries)))
 |> stream(:transactions, page.entries, at: -1)}
```

and remove the now-unused `newer_boundary_cursor/1` helper (or keep it only
if a legitimate future caller needs it). Add a regression test to
`actor_live_test.exs` that scrolls down twice then asserts
`has_newer`/`prev_cursor` stays `nil` and that `"prev-page"` is a no-op in
that state.

## Warnings

### WR-01: `RowReads.list/3`'s explicit `limit: n` path silently returns fewer than `n` rows with no truncation signal, by design — but this is easy to misread as a bug fix target

**File:** `lib/threadline/query/row_reads.ex:63-66`

**Issue:** Not a functional defect — this matches the locked D-14 behavior
("fires only when the implicit default cap truncated, never for an explicit
`limit: n`") — but the code gives no indication *why* an explicit-`limit`
caller gets zero truncation observability even when the true row count also
exceeds `n`. A future contributor "fixing" this by adding a symmetric
`emit_row_history_truncated` call for the explicit branch would silently
violate D-14's `measurements: %{limit: 200}` contract (hardcoded to the
default cap, not the caller's `n`) and the registry contract test.

**Fix:** Add a one-line comment at `list/3`'s `{:ok, n}` clause cross-referencing
D-14 explicitly (e.g. "Explicit `limit: n` never fires truncation telemetry —
see 232-CONTEXT.md D-14; only the implicit 200-row default does.") so the
intentional asymmetry survives the next reader.

### WR-02: `Threadline.Query.row_history_scope_opts/3`'s `:surface` default of `:row_history` is shared between the bounded (`row_history/3`) and unbounded-legacy (`history/3`, deprecated `row_history/4`) read paths

**File:** `lib/threadline/query.ex:672-679`

**Issue:** `row_history_scope_opts/3` is used both by the new
`RowReads.list`/`RowReads.page` path (via `Investigation.row_history` →
`RowReads.list` → `Query.row_history_scope_opts`) and, through
`history_query/3`, by the deprecated unbounded `history/3`/`Query.history/3`.
Both get `surface: :row_history` unless the caller overrides it. A
`:scope_query_fn` configured to apply row-limiting or auditing logic keyed
on `surface: :row_history` cannot distinguish "bounded 200-row default read"
traffic from "unbounded legacy `history/3`" traffic — which matters because
an adopter relying on `scope_query_fn` for defense-in-depth rate limiting
would reasonably want to treat these differently (one is capped by Threadline
itself, the other is not).

**Fix:** This is a minor observability gap, not a correctness bug (both
paths already have independent `:limit` validation), but worth a short
`guides/` note or a distinct `:surface` value (e.g. `:row_history_legacy`)
for the deprecated path if adopters are expected to key `scope_query_fn`
decisions on `:surface`.

## Info

### IN-01: `Threadline.Investigation.row_history_page/4`'s doc references the retired `cursor: nil` first-page convention without flagging that it diverges from every other paged read in the same module

**File:** `lib/threadline/investigation.ex:56-71`

**Issue:** `row_history_page/4`'s moduledoc says "An absent or `nil` `:cursor`
here still means 'first page'" — correct per D-07/D-11 — but a reader
skimming only this function (not the surrounding `actor_window_page`/
`correlation_bundle_page` siblings, which repeat the same caveat) could
reasonably assume the behavior generalizes to `row_history/3` itself, which
raises on `cursor: nil`. The three `_page` functions each repeat the caveat
independently rather than cross-linking a single explanation.

**Fix:** Low-value cleanup only — consider a single shared `@moduledoc`
paragraph or doc fragment the three deprecated `_page` functions reference,
so the "absent/nil cursor means :start here, unlike the new functions"
caveat has one source of truth instead of three near-duplicate paragraphs.

---

_Reviewed: 2026-10-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
