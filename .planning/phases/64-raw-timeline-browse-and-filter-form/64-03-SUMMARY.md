---
phase: 64-raw-timeline-browse-and-filter-form
plan: "03"
subsystem: operator-surface
tags:
  - doc-contract
  - testing
  - browse
  - aria
  - filter-parity
dependency_graph:
  requires:
    - "64-01 (TimelineLive, router wiring, back-links, style)"
    - "64-02 (LV integration tests)"
  provides:
    - "BROWSE-04 doc-contract CI guard"
    - "filter-key parity assertion against @allowed_timeline_filter_keys"
    - "ARIA label regression protection"
    - "phx-change prohibition enforcement at source level"
    - "← Timeline back-link presence guard on sibling LVs"
  affects: []
tech_stack:
  added: []
  patterns:
    - "Pure ExUnit.Case async:true + File.read!/1 + String.contains?/2 — no LiveViewTest, no DB, no Phoenix import"
    - "Regex.run extraction of @allowed_timeline_filter_keys literal from query.ex source (NOT compiled module attribute)"
    - "MapSet parity comparison after actor_kind+actor_id→actor_ref collapse and :repo deletion"
key_files:
  created:
    - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
  modified: []
decisions:
  - "Used explicit individual assert per ARIA label (not a loop) so CI output pinpoints exactly which label regressed — mirrors plan verification grep expectation"
  - "Added a third ← Timeline back-link test that asserts occurrence count >= 2 in actor_live.ex, matching the :not_found + actor-header double-presence requirement from D-02"
  - "Test file NOT wrapped in Code.ensure_loaded?(Phoenix.LiveView) — doc-contract tests read source files and have no Phoenix dependency, matching the un-gated shape of test/threadline/operator_surface_doc_contract_test.exs"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-07"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
---

# Phase 64 Plan 03: BROWSE-04 Doc-Contract Test Summary

One new test file — `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` — 153 lines, 9 test cases. Pure source-reading assertions; no LiveViewTest, no DB, no Phoenix import.

## What Was Built

### Test file: `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs`

Module: `Threadline.OperatorSurface.TimelineBrowseDocContractTest`

Mirrors the shape of `test/threadline/operator_surface_doc_contract_test.exs` exactly: `use ExUnit.Case, async: true`, pure `File.read!/1` + `String.contains?/2`, no Phoenix scaffolding.

## Seven Assertion Areas Covered

### 1. Route Literal (BROWSE-04)
Asserts `lib/threadline/operator_surface/router.ex` contains `live("/", TimelineLive, :index)`. Any future router refactor that drops the literal fails CI.

### 2. ARIA Labels (BROWSE-04)
Six individual assertions — one per label — against `lib/threadline/operator_surface/live/timeline_live.ex`:
- `aria-label="from"`
- `aria-label="to"`
- `aria-label="table"`
- `aria-label="actor kind"`
- `aria-label="actor id"`
- `aria-label="correlation id"`

### 3. Filter-Key Parity (BROWSE-04 — LOAD-BEARING)
**The regex used to extract `@allowed_timeline_filter_keys` from source:**
```elixir
Regex.run(~r/@allowed_timeline_filter_keys\s+~w\(([^)]+)\)a/, query_src)
```
This reads the SOURCE literal at `lib/threadline/query.ex:36`, not the compiled module attribute. The test then:
1. Splits the block into keys, builds a `MapSet`, deletes `"repo"` (socket-injected, not URL-supplied)
2. Scans `name="filter[…]"` from the LV source into a second `MapSet`
3. Collapses `actor_kind` + `actor_id` → `actor_ref` in the form keys
4. Asserts the two `MapSet`s are equal: `{from, to, table, actor_ref, correlation_id}`

Any future divergence between the form's `name="filter[…]"` inputs and the lib allowlist fails CI.

### 4. File-Scope Gate (BROWSE-04)
Asserts `String.split("\n") |> hd()` of `timeline_live.ex` equals exactly `"if Code.ensure_loaded?(Phoenix.LiveView) do"`. The v1.17 optional-Phoenix-deps invariant cannot be silently removed.

### 5. Native Widgets (D-09 / BROWSE-03)
Asserts `type="datetime-local"` and `<select` + `name="filter[actor_kind]"` are present. No custom date-picker or dropdown widgets allowed.

### 6. `phx-change` Prohibition (D-04 / F-6 / Pitfall 3)
`refute String.contains?(live_src, "phx-change=")` — per-keystroke URL patching inflates browser history. This assertion enforces the source-level prohibition; the integration test (Plan 02) enforces the runtime behavior.

### 7. `← Timeline` Back-Links (D-02)
Three assertions:
- `transaction_live.ex` contains `← Timeline` (1 occurrence)
- `actor_live.ex` contains `← Timeline` (at least 1 occurrence)
- `actor_live.ex` contains `← Timeline` at least TWICE (`:not_found` branch + `actor-header` success branch)

## Verification Commands Passed

```bash
# 1. Doc-contract test itself (9 tests, 0 failures)
mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs --warnings-as-errors
# → 9 tests, 0 failures

# 2. Compile_no_optional stays green (test has no Phoenix dependency)
mix verify.compile_no_optional
# → exits 0

# 3. Format clean
mix verify.format
# → exits 0

# 4. Full operator-surface suite (43 tests, 0 failures)
mix test test/threadline/operator_surface/
# → 43 tests, 0 failures
```

## Notes for Phase 65

Phase 65 (export controller) will be able to reuse these assertions:

1. **Route literal assertion**: Phase 65 adds a new controller route. A similar doc-contract test can assert the export route literal in router.ex using the same `File.read!/1 + String.contains?/2` pattern.

2. **Filter-key parity assertion**: Phase 65's export controller uses the same `validate_timeline_filters!/1` literal and the same `@allowed_timeline_filter_keys` allowlist. The same regex extraction from `lib/threadline/query.ex:36` can be reused verbatim in Phase 65's doc-contract to assert the export controller's accepted filter parameter names match the allowlist.

3. **`scope_aware_opts/1` helper**: Phase 65 will call `scope_aware_opts/1` from the TimelineLive module (per the plan's "Phase 65 will reuse verbatim" note). A doc-contract test can assert the helper's presence in `timeline_live.ex` source as a guard against accidental deletion.

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | BROWSE-04 doc-contract test | 91a0400 | test/threadline/operator_surface/timeline_browse_doc_contract_test.exs (new, 153 lines) |

## Deviations from Plan

**1. [Rule 1 - Style] Individual ARIA assertions instead of loop**
- **Found during:** Task 1 verification
- **Issue:** Plan verification checks use `grep -q 'aria-label="from"'` against the test file itself, requiring the literal string to appear in the file. A `for` loop with string interpolation satisfies the runtime assertion but not the grep verification.
- **Fix:** Replaced the loop with six explicit `assert String.contains?(live_src, ~s|aria-label="…"|)` calls.
- **Files modified:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs`
- **Commit:** 91a0400 (part of initial commit)

**2. [Rule 2 - Coverage] Added third ← Timeline test for ActorLive occurrence count**
- **Found during:** Task 1 design
- **Issue:** Plan specifies ActorLive must have ← Timeline in BOTH the `:not_found` branch AND the `actor-header` branch, but only two test cases (one per file) were listed in the plan scaffold.
- **Fix:** Added a third test asserting `occurrences >= 2` in `actor_live.ex` to enforce the dual-placement requirement from D-02.
- **Files modified:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs`
- **Commit:** 91a0400 (part of initial commit)

## Self-Check

Files exist:
- `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` — FOUND

Commits exist:
- `91a0400` — FOUND

## Self-Check: PASSED
