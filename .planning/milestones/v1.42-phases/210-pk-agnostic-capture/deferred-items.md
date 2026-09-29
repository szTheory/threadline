# Phase 210 — Deferred Items

Out-of-scope discoveries logged during plan execution, per the executor's scope-boundary rule (only auto-fix issues directly caused by the current task's own changes).

## 210-04

- `test/threadline/capture/legacy_trigger_pk_fallback_test.exs` (created in Plan 02, not touched by Plan 04) fails `mix format --check-formatted` as of this plan's final verification. Pre-existing drift, unrelated to Plan 04's files; not fixed here to stay in scope. Fix in a later plan or a standalone formatting pass.
  - **Resolved in 210-05**: `mix format` applied, committed standalone as `style(210): format legacy_trigger_pk_fallback_test`.
  status: acknowledged
