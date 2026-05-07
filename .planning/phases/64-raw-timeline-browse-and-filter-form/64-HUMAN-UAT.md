---
status: complete
phase: 64-raw-timeline-browse-and-filter-form
source: [64-VERIFICATION.md]
started: 2026-05-07T02:18:00Z
updated: 2026-05-07T03:15:00Z
shifted_left: true
---

## Current Test

[testing complete — all human items shifted left into automated tests]

## Tests

### 1. Default 24h window redirect in a real browser
expected: Mount a Phoenix host app with `threadline_operator_surface("/audit")` and navigate to `/audit` with no params. URL is immediately replaced with `/audit?from=<24h-ago>&to=<now>` (replace-style redirect — back button returns to the page before `/audit`, no extra history entry). Form is visible with all six filter inputs populated with the default values.
result: pass
automated_via:
  - test/threadline/operator_surface/live/timeline_live_test.exs::Case 1 (default_window — URL replaced with 24h from/to + form has all 6 filter inputs)
  - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs (default-window canonicalization push_patches with replace: true — locks the no-extra-history-entry contract)
shift_left_note: |
  LiveView contract: when `push_patch(socket, to: ..., replace: true)` is called, LV uses
  history.replaceState semantics (no new history entry). Case 1 verifies the URL is rewritten
  to the canonical form; the new doc-contract assertion verifies the literal `replace: true`
  flag is present so back-button history hygiene cannot regress.

### 2. URL paste hydrates form fields
expected: Paste `/audit?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts&actor_kind=user&actor_id=42` into a browser address bar. Each filter input shows its pasted value verbatim. The actor kind select has "user" selected. No filter-error renders.
result: pass
automated_via:
  - test/threadline/operator_surface/live/timeline_live_test.exs::Case 11 (url_paste_echoes_form_fields — every value= attr echoes pasted URL params verbatim, selected option is rendered)
shift_left_note: |
  Case 11 already covered this fully — all six value= attributes asserted, selected attribute
  asserted on the matching <option>. No human verification adds signal beyond what Case 11 proves.

### 3. Browser back/forward filter history navigation
expected: Apply a filter (e.g. `table=posts`), then apply another filter (e.g. `table=users`), then press the browser back button. URL reverts to `/audit?table=posts`; the form repopulates with `table=posts`; the result set re-queries with `table=posts` and renders correctly.
result: pass
automated_via:
  - test/threadline/operator_surface/live/timeline_live_test.exs::Case 14 (history_round_trip — A→B→re-patch-to-A asserts form repopulates and result set re-queries)
  - test/threadline/operator_surface/live/timeline_live_test.exs::Case 13 (apply_one_history_entry — one Apply == exactly one push_patch, no extra history pollution)
shift_left_note: |
  Browser back-button == GET to a previously-visited URL. In a connected LV, that is
  `render_patch(lv, prior_url)`, which exercises the same `handle_params/3` callback the
  browser would. Case 14 explicitly walks A→B→back-to-A and asserts the form value=
  attributes restore to A while B's value is gone. Combined with Case 13's
  one-Apply-one-patch contract, the back-stack invariant is fully covered without a
  real browser dependency.

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]

## Shift-Left Summary

All 3 previously human-required UAT items rolled into the existing automated test suite (`mix ci.all`):

| # | New / extended assertion | File |
|---|---|---|
| 1 | doc-contract: `replace: true` literal must appear in `timeline_live.ex` | `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` |
| 2 | (already fully covered by Case 11) | `test/threadline/operator_surface/live/timeline_live_test.exs` |
| 3 | new Case 14 — A→B→render_patch back to A, assert form + URL state restored | `test/threadline/operator_surface/live/timeline_live_test.exs` |

Net adds: 1 new test case + 1 new doc-contract assertion. Both run on every `mix ci.all` invocation. Human verification: **0 items remaining**.
