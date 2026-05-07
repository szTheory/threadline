---
phase: 64-raw-timeline-browse-and-filter-form
plan: "02"
subsystem: operator-surface
tags:
  - liveview
  - testing
  - integration-test
  - browse
dependency_graph:
  requires:
    - "64-01 (TimelineLive module + router edit — test file targets this module)"
  provides:
    - "test/threadline/operator_surface/live/timeline_live_test.exs"
  affects:
    - "CI: mix test test/threadline/operator_surface/ (post-wave merge)"
    - "BROWSE-01, BROWSE-02, BROWSE-03 runtime verification"
tech_stack:
  added: []
  patterns:
    - "Phoenix.LiveViewTest integration test with test-local Router + Endpoint + Layouts harness"
    - "Separate ExUnit module per endpoint for scope-thread testing (Case 10)"
    - "seed_change!/seed_changes! helpers for DB fixture setup"
key_files:
  created:
    - test/threadline/operator_surface/live/timeline_live_test.exs
  modified: []
decisions:
  - "Case 10 scope_thread extracted to a separate ExUnit module (TimelineLiveScopedTest) with its own @endpoint pointing to the ScopedEndpoint — Phoenix.LiveViewTest.live/3 uses @endpoint module attribute, not a kwarg option, so the only correct way to test a different endpoint in the same file is a separate module."
  - "Case 13 uses refute_patch(lv, 50) which is the LV 1.0+ API — the assertion proves one Apply == one history entry (BROWSE-03)."
  - "Case 9 seeds 51 rows (page_size + 1) to guarantee @cursor != nil so phx-viewport-bottom renders (BLOCKER 2 fix from Plan 01 spec)."
  - "Cases 4, 12 use patched_path = assert_patch(lv) (string return shape, not tuple) matching LV ~> 1.0 API (WARNING 2 fix)."
  - "default-window auto-patch drained with _ = assert_patch(lv) before form submit in Cases 2, 4, 12, 13 to prevent spurious assert_patch failures."
metrics:
  duration: "~3 minutes"
  completed: "2026-05-07"
  tasks_completed: 1
  files_created: 1
  files_modified: 0
---

# Phase 64 Plan 02: LiveView Integration Test for TimelineLive — Summary

LiveView integration test suite for `Threadline.OperatorSurface.Live.TimelineLive` covering all BROWSE-01/02/03 runtime-verifiable behaviors via Phoenix.LiveViewTest, with 13 test cases across 2 ExUnit modules.

## What Was Built

### Test File

**`test/threadline/operator_surface/live/timeline_live_test.exs`** — 466 lines, 13 test cases.

The file is structured as:
- **5 helper modules** at the file scope (Layouts, Router, Endpoint, ScopedRouter, ScopedEndpoint) — all `TimelineLiveTest`-namespaced
- **`Threadline.OperatorSurface.Live.TimelineLiveTest`** — 12 test cases with `@endpoint` pointing to the main Endpoint
- **`Threadline.OperatorSurface.Live.TimelineLiveScopedTest`** — 1 test case (Case 10) with `@endpoint` pointing to ScopedEndpoint

### Test Cases Shipped

| Case | Name | Requirement | Key Assertion |
|------|------|-------------|---------------|
| 1 | default_window | BROWSE-03 + D-09 | URL replaced with 24h from/to; form has all 6 filter inputs |
| 2 | filter_parity | BROWSE-02 | All five filter keys appear in canonical URL after submit |
| 3 | url_round_trip | BROWSE-03 | Pasted URL + seeded row renders matching results |
| 4 | anonymous | BROWSE-02 + D-07 | actor_id stripped from URL when actor_kind=anonymous |
| 5 | correlation_id_too_long | BROWSE-02 + D-10 | "256 UTF-8 bytes" literal error renders |
| 6 | datetime_normalization | F-2 + Pattern 3 | 16-char datetime-local parses without filter-error |
| 7 | unknown_table_hint | D-08 | Page renders hint copy when table unknown |
| 8 | phx_change_prohibition | D-04 + F-6 | No phx-change= attr on filter form |
| 9 | viewport_bottom_present | BROWSE-01 + D-11 | phx-viewport-bottom and phx-update="stream" present with 51 seeded rows |
| 10 | scope_thread | BROWSE-01 | Scoped mount (authorize_fn returns {:ok, scope}) renders without crash |
| 11 | url_paste_echoes_form_fields | BROWSE-03 / WARNING 1 | value= attrs echo pasted URL params (filters_raw hydration) |
| 12 | unknown_param_dropped | BROWSE-02 / WARNING 5 | foo= stripped from canonical URL after allowlist enforcement |
| 13 | apply_one_history_entry | BROWSE-03 / WARNING 5 | One submit = one assert_patch; refute_patch(lv, 50) proves no second patch |

## Implementation Notes

### Case 10 — Scope Thread
Case 10 required a separate `TimelineLiveScopedTest` ExUnit module with its own `@endpoint` set to `TimelineLiveTest.ScopedEndpoint`. This is because `Phoenix.LiveViewTest.live/3` resolves the endpoint from the `@endpoint` module attribute at compile time — there is no runtime `endpoint:` keyword argument. A separate module with a dedicated `@endpoint` is the standard pattern for testing against multiple endpoints in the same file.

### Case 13 — refute_patch/2 Arity
`refute_patch/2` is available in LV 1.1.30 (verified in deps). The call site is `refute_patch(lv, 50)` with a 50ms timeout. If a future LV version removes this API, the fallback is `refute_receive {:phoenix, :patch, _}, 50`.

### Default-Window Patch Drain
Cases 2, 4, 12, and 13 mount `/audit` with no params, which triggers the default 24h window `push_patch` from `handle_params/3`. Before submitting the form, each case drains this auto-patch with `_ = assert_patch(lv)` so the subsequent `assert_patch` after form submit corresponds only to the user action.

### Seed Helper Design
- `seed_change!/1` inserts one `AuditTransaction` + one `AuditChange` in `Threadline.Test.Repo`
- `seed_changes!/2` calls `seed_change!` N times (used in Case 9 to seed 51 rows for cursor trigger)
- The `occurred_at` defaults to `DateTime.utc_now()` so seeded rows fall within the default 24h window

## Deviations from Plan

### Auto-fixed Issues

**[Rule 1 - Bug] Case 10 restructured as separate ExUnit module**
- **Found during:** Task 1 (implementation)
- **Issue:** Initial implementation used `Phoenix.LiveViewTest.live/3` with an `endpoint:` keyword argument, which does not exist in the LV 1.x API. `live/3` is a macro that uses `@endpoint` from the call site's module attribute.
- **Fix:** Extracted Case 10 into `TimelineLiveScopedTest`, a separate ExUnit module with `@endpoint Threadline.OperatorSurface.TimelineLiveTest.ScopedEndpoint`. The ScopedEndpoint mounts the surface with `authorize_fn: fn _ -> {:ok, %{tenant: "t1"}} end` so `:threadline_scope` is populated.
- **Files modified:** `test/threadline/operator_surface/live/timeline_live_test.exs`
- **Commits:** 4905550 (initial), e433486 (fix)

## Verification

Automated checks from the plan all pass (verified in worktree):

```bash
test -f test/threadline/operator_surface/live/timeline_live_test.exs \
  && head -1 ... | grep -q 'if Code.ensure_loaded?(Phoenix.LiveView) do' \
  && grep -q 'defmodule Threadline.OperatorSurface.Live.TimelineLiveTest' ... \
  && grep -q 'threadline_operator_surface("/audit")' ... \
  # ... all 18 grep checks pass
```

Post-merge verification (requires Plan 01's TimelineLive to be merged):
```bash
mix test test/threadline/operator_surface/live/timeline_live_test.exs --warnings-as-errors
mix verify.compile_no_optional
mix verify.format
mix verify.test
```

## Known Stubs

None — the test file does not render data; it references modules that will exist once Plan 01 is merged.

## Threat Flags

None — test file only; no new network endpoints or security-relevant surface introduced.

## Self-Check: PASSED

- test/threadline/operator_surface/live/timeline_live_test.exs: FOUND
- .planning/phases/64-raw-timeline-browse-and-filter-form/64-02-SUMMARY.md: FOUND
- commit 4905550: FOUND
- commit e433486: FOUND
