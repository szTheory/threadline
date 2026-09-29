---
phase: 210-pk-agnostic-capture
fixed_at: 2026-09-25T23:31:35Z
review_path: .planning/phases/210-pk-agnostic-capture/210-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 210: Code Review Fix Report

**Fixed at:** 2026-09-25T23:31:35Z
**Source review:** .planning/phases/210-pk-agnostic-capture/210-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (WR-01..WR-04; IN-01 and IN-02 were out of scope per `fix_scope: critical_warning`)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### WR-01: `redaction_check_sql/2`'s "first offending column" pick has no `ORDER BY`

**Files modified:** `lib/threadline/capture/primary_key_sql.ex`, `test/threadline/capture/trigger_migrate_time_errors_test.exs`
**Commit:** `adfca9b6`
**Applied fix:** Rewrote the `SELECT k INTO col FROM unnest(keys) AS k WHERE k = ANY(...) LIMIT 1` query to use `unnest(keys) WITH ORDINALITY AS u(k, ord) ... ORDER BY ord LIMIT 1`, matching the ordering discipline the rest of `primary_key_sql.ex` already uses (`array_agg`/`string_agg ... ORDER BY ord`). Added a real-PostgreSQL test with a composite primary key `(post_id, tag_id)` where both columns are redacted via `mask: ["tag_id", "post_id"]` (declared in the opposite order from the key), asserting the refusal names `post_id` (first in key order) and not `tag_id`.

### WR-02: HINT/paste-ready snippets built with `chr(34) ||` don't escape embedded double quotes

**Files modified:** `lib/threadline/capture/primary_key_sql.ex`, `test/threadline/capture/trigger_migrate_time_errors_test.exs`
**Commit:** `adfca9b6`
**Applied fix:** Changed the `string_agg(chr(34) || a.attname || chr(34), ...)` column-list builder to `string_agg(chr(34) || replace(a.attname::text, chr(34), chr(34) || chr(34)) || chr(34), ...)`, doubling any embedded `"` before wrapping. Added a real-PostgreSQL test with a table `pk_quoted_col` whose qualifying unique index covers a column literally named `weird"col`, asserting the HINT snippet contains the correctly escaped `"weird""col", "tag_id"` and never the broken `"weird"col"`.

### WR-03: `primary_key:` overrides can't declare a column that requires quoting, unlike detected keys

**Files modified:** `lib/threadline/capture/trigger_capture_config.ex`, `guides/configuration-and-commands.md`, `test/threadline/capture/trigger_capture_config_test.exs`
**Commit:** `154ac7b5`
**Applied fix:** `210-CONTEXT.md` D-15 explicitly locks the strict bare-identifier regex (reused from the identifier/NAME-01 check) for declared `primary_key:` overrides, so per the task's guidance this was **not** loosened. Instead: (1) the `ArgumentError` raised when a declared column fails `StorageSchema.validate_identifier!/2` now appends a "Known limitation" sentence explaining that a legally-quoted Postgres identifier (mixed case, hyphen, space, leading digit) cannot be declared via `primary_key:` even though the same name is captured correctly when auto-detected, and points to the guide; (2) `guides/configuration-and-commands.md` gained a new "Known limitation: `primary_key:` only accepts bare identifiers" section spelling out the gap and the workaround (rename the column, or use a real PK/unique index over bare-identifier columns). A new config-load test asserts the refusal message for a hyphenated column name (`"post-id"`) contains both `"Known limitation"` and the guide path. This finding is recorded as **"fixed: documented"** rather than a behavioral change, matching the task's D-15 guidance.

### WR-04: `mix threadline.gen.triggers`'s private `table_token/1` duplicates `Naming.table_token/1`

**Files modified:** `lib/mix/tasks/threadline.gen.triggers.ex`
**Commit:** `710bf647`
**Applied fix:** Deleted the mix task's private `table_token/1` (two clauses duplicating `Naming.table_token/1`'s logic) and updated its one call site in `warn_shared_legacy_names/2` to call `Naming.table_token/1` directly, restoring the single-owner intent `Naming.table_token/1`'s own doc comment states. No new test was needed: existing `mix threadline.gen.triggers` migration tests already exercise `warn_shared_legacy_names/2`'s output, and the change is a pure delegation with no behavior change (verified: `Naming.qualified/1` and the local non-`public` branch were already provably identical).

## Verification

Run from the main checkout (no isolated worktree — this session's `pin.sh` guard (#4254) hard-fails on any cwd other than the orchestrator-pinned root, which a worktree checkout would fail every time; edits and commits therefore happened directly on `milestone/v1.42` in `/Users/<user>/projects/threadline`).

- `mix compile --warnings-as-errors` — clean, no warnings.
- `mix format --check-formatted` — clean (one new test file was reformatted by `mix format` before commit).
- `mix credo --strict` — `3741 mods/funs, found no issues.`
- `mix test` (full suite) — `9 properties, 2066 tests, 0 failures, 1 excluded`.
- `mix test test/threadline/release_artifact_contract_test.exs` — `19 tests, 0 failures` (confirms no planning IDs such as `WR-01`/`D-15` leaked into `lib/`; all such references live only in comments inside `test/`, `guides/`, and the refusal-message rationale, which the contract test does not scan).

No findings were skipped. IN-01 and IN-02 were out of scope for this run (`fix_scope: critical_warning`) and were not touched.

---

_Fixed: 2026-09-25T23:31:35Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
