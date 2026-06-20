---
phase: 175-navigation-app-shell-runtime-theme-picker
reviewed: 2026-06-17T00:00:00Z
depth: deep
files_reviewed: 22
files_reviewed_list:
  - lib/threadline/operator_surface/components/surface_header.ex
  - lib/threadline/operator_surface/ui.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/query.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/page_header_test.exs
  - test/threadline/operator_surface/pager_test.exs
  - test/threadline/operator_surface/skip_link_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/surface_header_csp_test.exs
  - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
findings:
  critical: 1
  warning: 6
  info: 3
  total: 10
status: resolved
resolution:
  resolved_at: 2026-06-17
  fixed:
    - CR-01
    - WR-01
    - WR-02
    - WR-03
    - WR-04
    - WR-05
    - WR-06
  deferred:
    - IN-01
    - IN-02
    - IN-03
  deferred_reason: >-
    Info-level items accepted/deferred: cosmetic class-name scoping (IN-01),
    a readability nit in the class-list idiom (IN-02), and a documented
    intentional desktop <details> override (IN-03). None affect correctness,
    a11y guarantees, or the locked design contract.
---

# Phase 175: Code Review Report

**Reviewed:** 2026-06-17
**Depth:** deep
**Files Reviewed:** 22
**Status:** resolved (CR-01 + WR-01..WR-06 fixed 2026-06-17; IN-01/IN-02/IN-03 deferred/accepted)

## Summary

Phase 175 (navigation, app shell, runtime theme picker) successfully clears the headline invariants: a source scan finds **zero** remaining inline `on*=` handlers anywhere under `lib/threadline/operator_surface/`, no JavaScript or localStorage was introduced, the capture layer is untouched, and no new `--tl-*` tokens were defined (token-parity holds). The `<input type=checkbox>`+JS nav was cleanly replaced by native `<details>/<summary>` keyed on `[open]`, the theme picker is a zero-JS `<form>` with an explicit `_csrf_token`, and the new `pager/1` honors its locked contract (hide-at-zero, disable-not-hide, capped deep total). HEEx auto-escaping neutralizes the XSS surface on breadcrumb labels/titles and `href` interpolation (actor type/id, table name) — no injection found.

However, the new `pager/1` is **wired incorrectly on the actor page**: it derives its total from a LiveView stream's `.inserts` field, which only contains the *current render cycle's* rows, not the cumulative set in the DOM. After paging the caption reports a false total. A related but milder version affects the timeline pager's `shown` value. Several supporting findings concern caption honesty, a test that now self-validates against stylesheet text, and minor a11y/labelling drift.

## Critical Issues

### CR-01: Actor pager reports a false "of N matching changes" total (stream `.inserts` is per-cycle, not cumulative)

**File:** `lib/threadline/operator_surface/live/actor_live.ex:185-192`
**Issue:** The pager is fed `shown={length(@streams.transactions.inserts)}` AND `match_count={length(@streams.transactions.inserts)}`. In Phoenix LiveView, `@streams.<name>.inserts` is the list of items queued for the *current* render diff — on initial mount it equals the first page, but after a `next-page`/`prev-page` event (`stream(:transactions, page.entries, at: -1|0)`) it contains only the just-appended page. So once the operator pages, the caption renders e.g. "Showing 25 of 25 matching changes" while dozens of rows remain visible above, and simultaneously `has_older={@next_cursor != nil}` keeps the "Older" control enabled — a self-contradicting state (caption says complete; control says more exist). The `match_count` total is simply wrong: it can never exceed one page, defeating the pager's stated purpose ("an honest end-of-stream signal", ui.ex:240-251). This is a correctness defect in operator-facing data, not a style nit.

**Fix:** Track real counts in assigns rather than reading them off `.inserts`. Maintain a running `shown` accumulator and pass a true total. Minimal version (caps unknown total, but stops lying):
```elixir
# in mount/handle_event, maintain an accumulator:
|> assign(:shown_count, length(page.entries))            # mount
# on next-page:
|> update(:shown_count, &(&1 + length(page.entries)))
# in render — use the assign, and use a real match total if actor_history exposes one:
<UI.pager
  shown={@shown_count}
  match_count={@total_matches || @shown_count}
  has_older={@next_cursor != nil}
  has_newer={@prev_cursor != nil}
  older_event="next-page"
  newer_event="prev-page"
/>
```
If `actor_history/2` cannot cheaply return a total, prefer omitting `match_count` semantics (or render "Showing N+ matching changes") over emitting a number known to be wrong.

**Resolution (FIXED, commit 14ff2d7):** `actor_live` now maintains a cumulative `shown_count` assign (initialized at mount and on window reset, accumulated on `next-page`/`prev-page`). `pager/1`'s `match_count` is now optional (`default: nil`); on the actor page it is passed `match_count={nil}`, which renders an honest count-free caption "Showing N matching changes" (no fabricated total) while still rendering the controls. Both caption branches are locked in `pager_test.exs`.

## Warnings

### WR-01: Timeline pager `shown` understates the rendered count after paging

**File:** `lib/threadline/operator_surface/live/timeline_live.ex:422`
**Issue:** Same `.inserts` semantics as CR-01, but milder: `match_count={@match_count}` IS a true total (assigned from the count query at line 178), so only `shown={length(@streams.changes.inserts)}` is wrong. After one `next-page` append it reports the size of the latest page (e.g. 50) instead of the cumulative number of rows in the DOM, so the caption reads "Showing 50 of 12,431" even when 150 rows are visible. The pre-existing `timeline_command` `shown_count` (line 344) has the same flaw, so this is a propagation of an existing weakness into the new pager rather than a fresh regression — but it still mis-informs keyboard/SR users, who are the pager's explicit audience.
**Fix:** Accumulate a real shown count in an assign (`assign(:shown_count, 0)` at mount, `update(:shown_count, &(&1 + length(page.entries)))` on `next-page`, `reset` it on filter change) and pass `shown={@shown_count}`.

**Resolution (FIXED, commit 3c02504):** `timeline_live` now tracks a cumulative `shown_count` assign (0 at mount, set to the page size on filter-change/reset in `handle_params`, accumulated on `next-page`) wired into both `<UI.pager>` and the `timeline_command` status region. `match_count` stays the true capped total from the count query.

### WR-02: Breadcrumb test's `aria-current` count is satisfied by the inline stylesheet, not by a nav element

**File:** `test/threadline/operator_surface/breadcrumb_test.exs:137,144-148`
**Issue:** `aria_current_count/1` runs `~r/aria-current="page"/` over the *entire* rendered page. The page embeds the full operator stylesheet inline via `<Style.css />`, and that CSS contains the literal selector `.threadline-ui .tl-shell-nav__item[aria-current="page"]` (`style.ex:664`). So the regex always matches exactly once from the stylesheet text alone. On the actor page the LiveView passes `current={nil}` (actor_live.ex:101), meaning **no** nav link actually emits `aria-current` — yet the assertion `aria_current_count(html) == 1` still passes. The test therefore guarantees nothing about real "you are here" state and would not catch a future regression that drops (or doubles) the genuine nav indicator.
**Fix:** Strip the `<style>...</style>` block before counting, or scope the count to the nav landmark, e.g.:
```elixir
defp aria_current_count(html) do
  html
  |> String.replace(~r/<style.*?<\/style>/s, "")
  |> then(&Regex.scan(~r/aria-current="page"/, &1))
  |> length()
end
```

**Resolution (FIXED, commit 0ed4c9a):** `aria_current_count/1` now strips the inlined `<style>...</style>` block before scanning, so the count reflects only real DOM attributes. Combined with WR-03 (below) the drill-down page now yields exactly one genuine nav `aria-current="page"` (the Timeline link); the breadcrumb segment carries none.

### WR-03: Drill-down pages now render no active shell-nav indicator

**File:** `lib/threadline/operator_surface/live/actor_live.ex:101`, `lib/threadline/operator_surface/live/transaction_live.ex:98`, `lib/threadline/operator_surface/live/row_history_live.ex:47`
**Issue:** These three pages changed `current={:timeline}` → `current={nil}`. With `nil`, `nav_link/1` (surface_header.ex:123-124) emits neither `tl-shell-nav__item--active` nor `aria-current="page"` on any item, so the shell navigation shows no "you are here" affordance while viewing a drill-down. The breadcrumb compensates for the back-link, but the global nav loses its current-section signal entirely. This is plausibly an intentional design call (a transaction is not a top-level nav item), but it is a behavioral change that WR-02's test fails to verify, so it should be confirmed intentional rather than silently shipped.
**Fix:** If drill-downs should keep their originating section highlighted, restore `current={:timeline}`. If the no-highlight behavior is intended, document it and fix WR-02 so the test actually asserts zero genuine nav `aria-current` on these pages.

**Resolution (FIXED, commit 0ed4c9a):** Per locked decision D-14, drill-downs keep their originating Timeline section highlighted: `current={:timeline}` was restored on `transaction_live`, `actor_live`, and `row_history_live`. The breadcrumb test (WR-02) now asserts exactly one genuine nav `aria-current="page"` on these pages.

### WR-04: Cap captions hardcode the limit as literal text instead of interpolating `@default_limit`

**File:** `lib/threadline/operator_surface/live/export_status_live.ex:262`, `lib/threadline/operator_surface/live/retention_history_live.ex:165`
**Issue:** Captions read `Showing latest 100 export jobs` and `Showing latest 40 retention runs` as hardcoded strings, while the actual cap is `@default_limit` (100 and 40 respectively, defined at line 16 / line 15). The inline comments even say "N = @default_limit (100)" — yet the value is duplicated as a literal. If `@default_limit` is ever tuned, the user-facing caption silently lies about the real cap. This is exactly the "honest cap" promise (D-20) undermined by a magic number.
**Fix:** Interpolate the constant: `Showing latest <%= @default_limit %> export jobs (most recent first).` Expose `@default_limit` as a module attribute reference in the assign or call `assign(socket, :default_limit, @default_limit)` so the template can read it.

**Resolution (FIXED, commit 43d1044):** Both `export_status_live` and `retention_history_live` now expose `@default_limit` via an assign and interpolate it in the caption instead of the hardcoded `100`/`40` literals.

### WR-05: Cap caption renders even when zero rows are present

**File:** `lib/threadline/operator_surface/live/retention_history_live.ex:163-166` (and the analogous export caption at `export_status_live.ex:260-263`)
**Issue:** The "Showing latest 40 retention runs (most recent first)." caption is unconditional inside the enabled branch — it is not guarded by a row-count check. When there are fewer than 40 runs (or zero), the caption over-claims ("latest 40") against an empty or short table, which is misleading for a `role="status" aria-live="polite"` region whose entire job is honesty about volume.
**Fix:** Either reword to a count-true form ("Showing the most recent runs (newest first).") or guard/parameterize it with the actual rendered count, e.g. `Showing the latest <%= min(@default_limit, @runs_count) %> retention runs`.

**Resolution (FIXED, commit 43d1044):** Both captions now report the actual rendered count (`jobs_count` / `runs_count`, refreshed on poll) with correct singular/plural and only show the `@default_limit` figure once the cap is actually reached — never over-claiming "latest N" against a short or empty table.

### WR-06: `pager/1` hardcodes `aria-label="Timeline pagination"` on non-timeline pages

**File:** `lib/threadline/operator_surface/ui.ex:275`
**Issue:** The pager's `<nav>` landmark is always labelled `"Timeline pagination"`, but it is also mounted on the actor-activity page (actor_live.ex:185), where it paginates an actor's transactions, not the timeline. Screen-reader landmark navigation will announce a "Timeline pagination" region on a page that has no timeline, which is confusing and arguably inaccurate.
**Fix:** Add an `attr(:label, :string, default: "Pagination")` (or `"Timeline pagination"` as the timeline default) and have each caller pass an accurate label, e.g. `label="Actor activity pagination"` on the actor page.

**Resolution (FIXED, commit 674bd3b):** Added `attr(:label, :string, default: "Timeline pagination")` to `pager/1`, rendered as `aria-label={@label}`. The actor page passes `label="Actor activity pagination"`. Default and override are locked in `pager_test.exs`.

## Info

> **All Info-level findings (IN-01, IN-02, IN-03) are DEFERRED / ACCEPTED (2026-06-17).**
> They are cosmetic/readability items or a documented intentional trade-off with no
> effect on correctness, accessibility guarantees, or the locked design contract.
> Not actioned in this fix pass; may be revisited opportunistically in a later phase.

### IN-01: `breadcrumb_trail/1` reuses the transaction-specific class on generic pages

**File:** `lib/threadline/operator_surface/ui.ex:225`
**Issue:** The shared breadcrumb landmark hardcodes `class="tl-transaction__breadcrumbs"`, but `page_header/1` is now used on coverage, evidence, redaction, retention, exports, row-history, etc. — pages that are not transactions. The styling works, but the class name now misrepresents its scope and couples generic chrome to a transaction-specific token.
**Fix:** Rename to a neutral token (e.g. `tl-page__breadcrumbs`) and update the stylesheet selector, or alias it.

### IN-02: `page_header/1` mixes `++`/`if` list-building inline in the class attribute

**File:** `lib/threadline/operator_surface/ui.ex:204`
**Issue:** `["tl-page__header"] ++ if(@variant == "display", do: ["tl-home__hero"], else: []) ++ List.wrap(@class)` is correct but dense and harder to scan than the list-with-falsy-entries idiom used elsewhere in this module (e.g. the `button/1` class list). Minor consistency/readability nit.
**Fix:** `class={["tl-page__header", @variant == "display" && "tl-home__hero", @class]}` (HEEx drops `false`/`nil` entries and flattens lists).

### IN-03: Desktop force-shows the nav panel while `<details>` reports "collapsed" to AT

**File:** `lib/threadline/operator_surface/style.ex:3623-3632`
**Issue:** At `min-width: 768px` the `<summary>` toggle is `display:none` and `.tl-shell-nav__panel` is forced to `display:grid` regardless of the `[open]` attribute. A `<details>` element without `open` still exposes a collapsed disclosure state to assistive tech even though its content is visually shown. Because the summary is hidden and the content is always visible on desktop, the practical impact is low, but the native disclosure semantics and the visual state are technically out of sync.
**Fix:** Optional — consider rendering `<details open>` (or toggling `open` by viewport is not possible in pure CSS, so this is an accepted trade-off); at minimum document the intentional desktop override so a future reviewer doesn't "fix" it by removing the force-show rule.

---

_Reviewed: 2026-06-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
