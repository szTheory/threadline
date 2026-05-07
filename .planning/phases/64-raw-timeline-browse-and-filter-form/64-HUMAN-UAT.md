---
status: partial
phase: 64-raw-timeline-browse-and-filter-form
source: [64-VERIFICATION.md]
started: 2026-05-07T02:18:00Z
updated: 2026-05-07T02:18:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Default 24h window redirect in a real browser
expected: Mount a Phoenix host app with `threadline_operator_surface("/audit")` and navigate to `/audit` with no params. URL is immediately replaced with `/audit?from=<24h-ago>&to=<now>` (replace-style redirect — back button returns to the page before `/audit`, no extra history entry). Form is visible with all six filter inputs populated with the default values.
result: [pending]

### 2. URL paste hydrates form fields
expected: Paste `/audit?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts&actor_kind=user&actor_id=42` into a browser address bar. Each filter input shows its pasted value verbatim. The actor kind select has "user" selected. No filter-error renders.
result: [pending]

### 3. Browser back/forward filter history navigation
expected: Apply a filter (e.g. `table=posts`), then apply another filter (e.g. `table=users`), then press the browser back button. URL reverts to `/audit?table=posts`; the form repopulates with `table=posts`; the result set re-queries with `table=posts` and renders correctly.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
