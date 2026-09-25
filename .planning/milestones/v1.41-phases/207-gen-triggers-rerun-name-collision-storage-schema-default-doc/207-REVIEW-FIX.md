---
phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
fixed_at: 2026-09-24T23:51:54Z
review_path: .planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 207: Code Review Fix Report

**Fixed at:** 2026-09-24T23:51:54Z
**Source review:** .planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (CR-01, WR-01, WR-02, WR-03; IN-01..05 out of scope)
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Orphan `DROP FUNCTION` can fail the migration, or drop another table's live function, because of PostgreSQL identifier truncation

**Files modified:** `lib/threadline/capture/trigger_sql.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `test/threadline/capture/trigger_rerun_test.exs`
**Commit:** 35ec16b8
**Status:** fixed: requires human verification (logic change)
**Applied fix:** Followed the orchestrator decision. Added `TriggerSQL.per_table_function_fits?/1`, which checks that `threadline_capture_changes_<suffix>` is at most 63 bytes. The generator emits the default-mode orphan `DROP FUNCTION IF EXISTS` only when the name fits (new private `orphan_function_drop/1`). There is no `Mix.raise` on long names. Added one sentence to the moduledoc's Rerunning section saying the drop is skipped for names over 63 bytes.

**The real pre-fix failure differs from the review's description.** `StorageSchema.quote_ident/1` has rejected identifiers over 63 bytes since a837aaca, which first shipped in 0.10.0. As a result:
- Before the fix, `drop_orphan_function_for_table/1` raised `ArgumentError ... at most 63 bytes` **at generation time** for every default-mode table whose suffix is longer than 36 bytes, with or without a collision. On this code the generator could not produce a migration for such a table at all, so the PostgreSQL-level failures in the review could not be reached through the generator. On 0.10.1, default mode never computed the per-table name, so this is still a regression, and a broader one than reported.
- The current generator cannot install a per-table function for a long name either: it also raises `ArgumentError`, both before and after this fix. A colliding live per-table function can therefore only exist if 0.9.x or earlier installed it, when PostgreSQL silently truncated the name, or if someone wrote it by hand.

**Regression tests.** Four tests in the new `describe` in `trigger_rerun_test.exs`. The table names are `customer_subscription_billing_events_2024` and `_2025`: 41 bytes each, sharing a 36-byte prefix, so both function names truncate to the same 63-byte identifier. Each test generates a migration with the real task and applies every `execute` in its `up` against the database.
1. The two names really collide after truncation, and the trigger names stay within 63 bytes. This is a precondition check.
2. **Per-table already installed:** a legacy per-table trigger is installed on `_2025` with a truncated function name, then `--tables _2024` is generated and applied in default mode. Afterwards `_2024` uses the global function, `_2025` still uses its function, and capture works.
3. **Default table listed first in one run:** with the same legacy trigger installed, `--tables _2024,_2025` is generated and applied. Both tables are re-pointed to the global function. The leftover truncated function is not dropped (asserted), because the generator cannot tell it apart from another table's function.
4. **Default first, then per-table in one run** (`_2025` set to `store_changed_from` through `:trigger_capture`). The task raises the existing `ArgumentError` before writing any file, so a migration that drops B's function and then points B's trigger at it can never be emitted. This passes both before and after the fix. It pins the existing guard.

**Proof the tests fail before the fix.** I ran the file against the unfixed code: 9 tests, 2 failures. Tests 2 and 3 failed with `ArgumentError ... at most 63 bytes, got: "threadline_capture_changes_customer_subscription_billing_events_2024"` in `generate!`. After the fix: 9 tests, 0 failures.

**Deferred (out of scope under the orchestrator decision):** two tables that both use per-table functions and whose suffixes share their first 36 bytes still collide on the per-table function name. On the current code the generator refuses both with `ArgumentError`, because `quote_ident` enforces 63 bytes. On 0.9.x and earlier, PostgreSQL silently truncated both names to the same function. The review's longer-term suggestion is still open: a clear `Mix.raise` for long names, or a hashed or shortened function name. It needs its own decision because it changes public behaviour. A related minor point: a legacy truncated per-table function whose table returns to default mode is now left in place rather than dropped. It is harmless and non-capturing.

### WR-01: CHANGELOG attributes the wrong error to the "both pending" case for reruns with a different table set

**Files modified:** `CHANGELOG.md`
**Commit:** 917418ff
**Applied fix:** The Fixed bullet now says `migration name ... is duplicated` happens when the rerun listed the same tables and both migrations were pending together. Otherwise the error is `trigger "threadline_audit_<table>" ... already exists`, which covers two cases: the first migration was already applied, or the rerun listed a different set of tables (for example `posts` after `posts,users`).

### WR-02: Docs say a rerun always gets a numbered name, but a rerun with a different table set does not

**Files modified:** `lib/mix/tasks/threadline.gen.triggers.ex`, `guides/production-checklist.md`, `guides/domain-reference.md`, `CHANGELOG.md`
**Commit:** 292c0173
**Applied fix:** All four places now say the name is numbered only when the table-derived name is already taken, and that a rerun for a different table set keeps an un-numbered name. Every `@rerun_doc_phrases` phrase is still present, including "replaces the trigger in place". `test/mix/tasks/threadline/gen_triggers_test.exs` passes after the edit (15 tests, 0 failures).

### WR-03: CHANGELOG implies first-run output is unchanged, but every generated migration now changes body and needs PostgreSQL 14

**Files modified:** `CHANGELOG.md`
**Commit:** 660e2ad3
**Applied fix:** Added a paragraph after the gen.triggers highlight. It says that every generated trigger migration, first runs included, now uses `CREATE OR REPLACE TRIGGER`, which needs PostgreSQL 14 or later (the supported floor) and no longer applies on PostgreSQL 13 or older. It also says each default-trigger table drops a leftover per-table capture function, and that PostgreSQL prints a harmless NOTICE during `mix ecto.migrate` on a table that has none. "Breaking changes: None" is unchanged.

## Verification

- **Where it ran:** the fixes were edited and committed in an isolated worktree (`workflow.use_worktrees: true`). The per-fix checks ran there, using the main checkout's `deps` and a throwaway build root under `/tmp`. The final gates below ran in the **main checkout** after the fast-forward to 660e2ad3, so they can be reproduced from the current tree.
- `mix compile --warnings-as-errors`: clean (main checkout).
- `mix format --check-formatted`: clean (main checkout).
- Phase test files (`gen_triggers_test.exs`, `trigger_rerun_test.exs`, `trigger_sql_storage_schema_test.exs`, `trigger_migration_test.exs`, `storage_schema_test.exs`): 56 tests, 0 failures (worktree). The full suite below covers them again.
- Full `mix test`: **1843 tests, 0 failures, 1 excluded** (main checkout). This matches the 0-failure baseline. An earlier full-suite run in the worktree showed 37 failures, all in export, storage and Dialyzer-slice tests unrelated to triggers. They came from the worktree environment (shared deps path, a separate build root, untracked files missing). None appear in the main-checkout run.

---

_Fixed: 2026-09-24T23:51:54Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
