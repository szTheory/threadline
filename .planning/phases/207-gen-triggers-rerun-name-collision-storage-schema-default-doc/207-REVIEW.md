---
phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
reviewed: 2026-09-24T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/mix/migration_version.ex
  - lib/threadline/mix/trigger_migration.ex
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/threadline/capture/trigger_rerun_test.exs
  - test/threadline/capture/trigger_sql_storage_schema_test.exs
  - test/threadline/mix/trigger_migration_test.exs
  - test/threadline/storage_schema_test.exs
  - CHANGELOG.md
  - guides/audit-indexing.md
  - guides/domain-reference.md
  - guides/how-threadline-works.md
  - guides/production-checklist.md
findings:
  critical: 1
  warning: 3
  info: 5
  total: 9
status: issues_found
---

# Phase 207: Code Review Report

**Reviewed:** 2026-09-24
**Depth:** standard (diff `4454661b..HEAD`)
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The name and module resolver (`TriggerMigration.resolve_name/2`) is sound. It builds
the name and the module from the same parts list, so they cannot diverge. It checks
both sets, the loop always terminates, and the first-run name and module stay
byte-identical, including for mixed-case tables. `Regex.escape` plus the right-hand
negative lookahead in `rerun?/2` handles both the quoted form and the legacy unquoted
form, and it rejects `posts_archive`. Identifiers in the new orphan drop are quoted
through `StorageSchema.function/2`. The generated `up` puts the drop after that
table's `CREATE OR REPLACE TRIGGER`. `down` is split per table, and the tests cover
the mixed-set case. The 52 phase tests pass locally. I checked the doc-default guard
for a vacuous pass: it currently matches 10 correct claims and 0 offenders, and its
separate known-offender test pins the matcher.

The main defect is a regression in the new orphan `DROP FUNCTION`. It is emitted on
every run, and on long table names it runs into PostgreSQL's 63-byte identifier
truncation. A migration that 0.10.1 applied cleanly can now fail. I reproduced this
against the local PG instance. The rest are accuracy problems in the CHANGELOG and
the docs: which error appears when, and "a rerun always gets a numbered name".

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Orphan `DROP FUNCTION` can fail the migration, or drop another table's live function, because of PostgreSQL identifier truncation (regression)

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:260-262`, `lib/threadline/capture/trigger_sql.ex:97-100`
**Issue:** `"threadline_capture_changes_"` is 27 bytes. For any table suffix longer than
36 bytes, PostgreSQL silently truncates the per-table function name to 63 bytes. Two
tables whose suffixes share their first 36 bytes therefore share one per-table
function name. This is realistic for yearly or partition-style tables, e.g.
`customer_subscription_billing_events_2024` / `_2025`. Their trigger names are still
distinct up to a 46-byte suffix, so before this phase such a pair worked when one table
used the default trigger and the other used a per-table function. Because D-05 emits
the orphan drop for **every** default-mode table on **every** run, a first run now
fails too:

- Table B (per-table) is already installed. Generating table A (default) emits a
  `DROP FUNCTION IF EXISTS` whose name truncates to B's live function. The migration
  aborts with `cannot drop function ... because other objects depend on it`. I
  reproduced this on the local `threadline_test` DB inside a rolled-back transaction.
- A and B are in the same `--tables` list with A first: `function_ups` creates B's
  function, then A's orphan drop removes it, because B's trigger does not exist yet.
  B's `CREATE OR REPLACE TRIGGER` then fails with "function does not exist".

The change is meant to make generated migrations apply, and here it makes a previously
appliable migration fail.
**Fix:** Emit the orphan drop only when the full function name fits in 63 bytes. Also
reject name collisions at generation time instead of letting PostgreSQL truncate
silently. For example:
```elixir
# TriggerSQL
@max_ident 63
def per_table_function_fits?(table_name),
  do: byte_size("threadline_capture_changes_" <> StorageSchema.host_table_suffix(table_name)) <= @max_ident

# gen.triggers trigger_ups, default branch
{t, %{needs_per_table: false}} ->
  drop =
    if TriggerSQL.per_table_function_fits?(t),
      do: "\n\n    execute #{inspect(TriggerSQL.drop_orphan_function_for_table(t))}",
      else: ""
  "    execute #{inspect(TriggerSQL.create_trigger(t))}" <> drop
```
Better still, `Mix.raise` when a generated trigger or function name would exceed 63
bytes, because the pre-existing per-table/per-table collision has the same root cause.
Add a regression test with two 40+ character table names that share a prefix.

## Warnings

### WR-01: CHANGELOG attributes the wrong error to the "both pending" case for reruns with a different table set

**File:** `CHANGELOG.md:85-91`
**Issue:** The Fixed bullet says the pre-fix rerun failed with `migration name
threadline_triggers_<tables> is duplicated` "when both trigger migrations were pending
together". That only happens when the rerun used the **same** table set. The guides
and D-06 explicitly cover a rerun with a different set, e.g. `posts,users` then
`posts`. That gives distinct names (`threadline_triggers_posts_users`,
`threadline_triggers_posts`), so `ensure_no_duplication!` passes. On a fresh or CI
database the first migration applies and the second fails with `trigger
"threadline_audit_posts" ... already exists`. The entry is meant to let adopters
search their error and land here, so it should say which error goes with which case.
**Fix:** Reword along these lines: "…failed with `migration name … is duplicated` when
the rerun listed the same tables and both migrations were pending together (…), and
otherwise with `trigger "threadline_audit_<table>" … already exists`."

### WR-02: Docs say a rerun always gets a numbered name, but a rerun with a different table set does not

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:42-44`, `guides/production-checklist.md:45`, `guides/domain-reference.md:55`, `CHANGELOG.md:40-41`
**Issue:** `resolve_name/2` adds an ordinal only when the table-derived name is taken
(D-01). A rerun for `posts` after `posts,users` writes an un-numbered
`threadline_triggers_posts` and is still a rerun: its `down` omits the drops and
carries the rollback comment. All four docs say "It writes a new migration with a
numbered name". An operator looking for a `_2` file to confirm the rerun, or to delete
it per the CHANGELOG's Required action, will not find one.
**Fix:** Say "a new migration, numbered (for example `threadline_triggers_posts_2`)
when the table-derived name is already taken". Keep the phrases asserted by
`@rerun_doc_phrases` in `gen_triggers_test.exs` intact.

### WR-03: CHANGELOG implies first-run output is unchanged, but every generated migration now changes body and needs PostgreSQL 14

**File:** `CHANGELOG.md:36-44`, `CHANGELOG.md:46-48`
**Issue:** The highlight says "a first run is named as before", and nothing else
describes first runs. Every newly generated trigger migration, first run included, now
emits `CREATE OR REPLACE TRIGGER` and an extra `DROP FUNCTION IF EXISTS`. That DROP
prints a NOTICE on every `mix ecto.migrate`, and the migration is a syntax error on
PostgreSQL 13 and older, where the 0.10.1 output applied. The documented floor is 14
(D-03), so "Breaking changes: None" is defensible and I am not re-litigating it. The
entry should still disclose it: adopters who diff generated output, or who run a
sub-floor PG in some environment, get no warning.
**Fix:** Add one sentence to the highlight: "Every generated trigger migration,
including a first run, now uses `CREATE OR REPLACE TRIGGER` (PostgreSQL 14+, the
supported floor) and drops a leftover per-table capture function; on a table without
one PostgreSQL prints a harmless NOTICE."

## Info

### IN-01: A table re-enabled after an explicit drop-trigger migration is classified as a rerun, and its generated comment is false

**File:** `lib/threadline/mix/trigger_migration.ex:79-83`, `lib/mix/tasks/threadline.gen.triggers.ex:166-171`
**Issue:** The docs tell operators that "to stop capturing a table, write a migration
that drops its trigger". That migration contains `threadline_audit_<t>`, so a later
`gen.triggers` run for the same table counts as a rerun (D-06, locked). Its `down`
keeps the trigger, and the comment says it "replaced the audit trigger … in place",
although the previous state had no trigger. Rollback fails safe (capture stays on).
The comment and the task's info line are still misleading in this documented path.
**Fix:** No behaviour change is needed under D-06. Consider softening the comment to
"This table already appears in an earlier trigger migration…" so it stays true in this
case.

### IN-02: A default→per-table rerun leaks the per-table function after a full rollback chain

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:269-282`
**Issue:** M1 installs `posts` on the default trigger. M2, a rerun, installs a
per-table function. Rolling back M2 keeps the trigger (by design). Rolling back M1
drops only the trigger, because M1's `down` has no function drop for a default-mode
table. `threadline_capture_changes_posts` is left orphaned. It is harmless, and any
later default-mode run removes it through the orphan drop.
**Fix:** Optionally add `drop_orphan_function_for_table(t)` after `drop_trigger(t)` in
first-run `down` for default-mode tables. It is idempotent and non-cascading.

### IN-03: "Rolling back a rerun … no longer leaves the table uncaptured" is unconditional, but detection only sees the scanned directory

**File:** `CHANGELOG.md:92`, `lib/threadline/mix/trigger_migration.ex:28-37`
**Issue:** `rerun?/2` sees only `.exs` files under `priv/repo/migrations`. Suppose the
original trigger migration was squashed into `structure.sql`, deleted, or lives in
another migrations path (the deferred W3 case). The rerun is then treated as a first
run, and its `down` drops the trigger. That is the old behaviour the CHANGELOG says is
fixed.
**Fix:** Qualify the claim ("when the earlier trigger migration is still in
`priv/repo/migrations`"), or mention it in the moduledoc's Rerunning section.

### IN-04: The doc-default guard is line-scoped and its non-vacuity floor is loose

**File:** `test/threadline/storage_schema_test.exs:13-21,99-102,134-147`
**Issue:** Claims are only found on lines that also contain `storage schema` or
`storage_schema`. A claim wrapped onto the next line, or phrased as "the schema
defaults to …", is missed. The `correct >= 3` floor sits well below today's 10
matches, so the matcher could lose most of its coverage without the test noticing.
`@documented_default_files` is built with `Path.wildcard` at compile time relative to
the cwd. That is fine under `mix test` from the root, but it is fragile.
**Fix:** Raise the floor to the current count or pin it per file, and consider
matching over paragraphs instead of single lines.

### IN-05: The production checklist says a rolled-back redaction removal is reported as `Drift detected`, which only holds if config was also reverted

**File:** `guides/production-checklist.md:45`
**Issue:** If the operator rolls back the rerun migration but leaves the config
without redaction, config and the deployed trigger agree (both unredacted), and the
view shows `Config matches deployed`. The flag appears only once the redaction config
is restored. That is the usual code-revert case, but the sentence reads as
unconditional.
**Fix:** "…which `/audit/policy/redaction` and `mix threadline.policy.show` report as
`Drift detected` once the redaction config is restored."

---

_Reviewed: 2026-09-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
