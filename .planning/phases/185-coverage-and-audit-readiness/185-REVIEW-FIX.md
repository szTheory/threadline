---
phase: 185
fixed_at: 2026-06-29T20:50:06Z
review_path: .planning/phases/185-coverage-and-audit-readiness/185-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 185: Code Review Fix Report

**Fixed at:** 2026-06-29T20:50:06Z
**Source review:** .planning/phases/185-coverage-and-audit-readiness/185-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: Selected-schema fetch failures can show rows from a different schema

**Status:** fixed: requires human verification
**Files modified:** `lib/threadline/operator_surface/live/coverage_live.ex`
**Commit:** 2ae671fe
**Applied fix:** Track the schema that produced the selected-schema snapshot and preserve last-good rows only when a failing refresh is for that same schema; cross-schema or first-load failures now use an empty error snapshot.

### CR-02: Schema list/validation failures can crash `/audit/coverage`

**Status:** fixed: requires human verification
**Files modified:** `lib/threadline/operator_surface/live/coverage_live.ex`
**Commit:** dd33e21b
**Applied fix:** Wrapped schema listing and validation in safe helpers so catalog/repo failures render an error snapshot and form error instead of raising out of `handle_params/3`.

### WR-01: Refresh bypasses the schema validation boundary

**Status:** fixed: requires human verification
**Files modified:** `lib/threadline/operator_surface/live/coverage_live.ex`
**Commit:** 63535b47
**Applied fix:** Disabled the refresh control when `@form_error` is present and made the server-side refresh handler return without calling coverage fetch while an invalid schema error is active.

### WR-02: Stale/invalid contract tests are source-grep checks, not behavior guards

**Status:** fixed
**Files modified:** `test/threadline/operator_surface/live/coverage_live_test.exs`, `test/threadline/operator_surface/coverage_doc_contract_test.exs`
**Commit:** 6e0fb15e
**Applied fix:** Added LiveView behavior tests for same-schema refresh failure preservation and cross-schema failure isolation, and removed the stale source-grep assertions from the doc contract test.

### WR-03: Operator docs still use retired dashboard/table-coverage framing

**Status:** fixed
**Files modified:** `guides/operator-surface.md`, `guides/production-checklist.md`, `test/threadline/operator_surface/coverage_doc_contract_test.exs`
**Commit:** 699e29de
**Applied fix:** Reworded Coverage docs around selected-schema audit readiness and expected gaps, removed retired dashboard wording, and extended the doc contract to reject dashboard framing in the Coverage sections.

### WR-04: Browser focus proof forces focus programmatically

**Status:** fixed
**Files modified:** `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts`
**Commit:** a42cb3e8
**Applied fix:** Replaced `locator.focus()` with keyboard tab navigation plus a max-step guard, keeping focus-ring assertions tied to naturally reached controls.

## Verification

- `mix format --check-formatted` for touched Elixir source/test files
- `mix test test/threadline/operator_surface/live/coverage_live_test.exs`
- `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs`
- `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs`
- `npm test -- --list tests/operator-coverage-readiness.spec.ts` from `examples/threadline_phoenix/e2e`
- `mix verify.example_browser operator-coverage-readiness.spec.ts --grep "keeps focus visible" --project=chromium`

---

_Fixed: 2026-06-29T20:50:06Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
