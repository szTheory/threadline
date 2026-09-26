# Upgrading to 0.11.0

This guide is the full 0.10.x -> 0.11.0 procedure. `guides/upgrade-path.md`
gives the summary and points here for the steps.

## Who this guide is for

Use this guide if your host application is on any Threadline `0.10.x`
release and you are moving to `0.11.0`. It assumes you have already worked
through [Getting started with Phoenix SaaS](getting-started-saas.md) and have
a running install with triggers on at least one table.

## Before you start

Read the `CHANGELOG.md` `[0.11.0]` entry (or, before that heading is retitled
at release time, the `## Unreleased -- highlights` block) for the full list of
breaking changes and required action. If any of your audited tables use
per-table capture settings -- redaction (`mask` or `exclude`) or
`store_changed_from` -- read the [Security note](../CHANGELOG.md) before you
regenerate anything: it covers an install shape where two such tables could
end up sharing one capture function.

## Step 1: Bump the dependency

Raise your host `mix.exs` `:threadline` requirement so it resolves to the
`0.11` line, then fetch it:

```bash
mix deps.get
```

## Step 2: Regenerate triggers

Regenerate every audited table's trigger so it resolves and records the
table's real primary key:

```bash
mix threadline.gen.triggers --tables <every audited table>
```

**Tables that shared a capture function must be regenerated together in one `mix threadline.gen.triggers --tables` run.** Releases up to 0.10.2 could give
two tables one capture function -- a table in `public` and a same-named table
in another schema, for example `public.billing_invoices` and
`billing.invoices`, or two long table names that begin with the same 36
bytes. Regenerate both together:

```bash
mix threadline.gen.triggers --tables billing_invoices,billing.invoices
```

If you regenerate only one of a shared pair, `mix ecto.migrate` refuses the
unsafe order and applies nothing, naming the other tables whose triggers
still use that function. Delete the refused migration file, then generate the
suggested command instead.

A table whose primary-key type is outside the supported set --
`timestamptz`, `numeric`, a float, `json`/`jsonb`, an array, or `bytea` --
makes the migration fail naming the column. Remove that table from
`--tables`, delete the refused migration file, and regenerate the rest. That
table keeps its existing trigger and captures exactly as it did before; see
[What changed that you may notice](#what-changed-that-you-may-notice) below.

See the [Security note](../CHANGELOG.md) for the full shared-function
mechanism, its impact, and the fix.

## Step 3: Migrate

```bash
mix ecto.migrate
```

## Step 4: Add the row-history index

```bash
mix threadline.gen.row_history_index
mix ecto.migrate
```

This builds `audit_changes_row_history_idx` with
`CREATE INDEX CONCURRENTLY IF NOT EXISTS`, so it never blocks writes to
`audit_changes` while it builds. If the concurrent build is interrupted --
the migration killed, the connection dropped, a duplicate detected -- it
leaves an INVALID index behind, and `IF NOT EXISTS` then treats that INVALID
index as already present and skips it on a retry. Drop it first, then
rerun:

```sql
DROP INDEX CONCURRENTLY IF EXISTS <storage_schema>.audit_changes_row_history_idx;
```

```bash
mix ecto.migrate
```

A fresh install from `mix threadline.install` already has this index, so
running this task there writes a migration that is a no-op.

## Step 5: Verify coverage

```bash
mix threadline.verify_coverage
mix threadline.health.coverage
```

Confirm there are no error findings for tables you expect to be covered.
Each finding names its fix:

| Code | Severity | Fix |
| --- | --- | --- |
| `legacy_trigger_no_pk_args` | warning | The trigger was installed before it recorded key columns. Regenerate it: `mix threadline.gen.triggers --tables <table>`, then `mix ecto.migrate`. |
| `pk_drift` | error | The recorded key no longer matches the table's expected key. Regenerate: `mix threadline.gen.triggers --tables <table>`, then `mix ecto.migrate`. A legacy trigger with no arguments on a table whose real key is not `id` reports this code too -- the fix is the same regenerate-and-migrate, or a `primary_key:` override naming a unique index over supported-type columns if the table has no usable primary key. |
| `shared_capture_function` | error | Regenerate every table that shares the function together, in one `--tables` run, then `mix ecto.migrate`. |
| `duplicate_capture_trigger` | error | More than one Threadline trigger fires on the table. Drop the extra trigger(s) the finding names, then regenerate and migrate. |
| `capture_trigger_disabled` | error | The trigger is disabled or replica-only. `ALTER TABLE ... ENABLE TRIGGER` (or `ENABLE ALWAYS TRIGGER` to keep firing for replica sessions too). |

A table whose key type was refused in Step 2 keeps its legacy trigger, which
still records exactly what it always did, so `trigger_coverage` still counts
it as covered. `trigger_findings` does report it, under the `pk_drift` row
above, unless its key column happens to be named `id` -- a legacy
no-argument trigger records `id` by convention, so a real key of any other
name (`recorded_at`, for example) is exactly the case that row's "on a table
whose real key is not `id`" describes. That finding is expected here and the
fix is the same regenerate-and-migrate once the column type gains support,
not a sign that something else is wrong.

## Step 6 (optional): Backfill unresolved primary keys

Backfilling is optional. It fills in the real key, from `data_after`, for
INSERT and UPDATE rows that were captured before you regenerated a table's
trigger -- rows whose `table_pk` is still `{"id": null}` or `{}`. It never
touches DELETE rows or rows where a key column is missing from `data_after`
(see [What cannot be recovered](#what-cannot-be-recovered)).

Parameters used below, substitute your own values:

- `<storage_schema>` -- the configured storage schema (`public` by default).
- `<host_schema>` / `<host_table>` -- the audited table's schema and name.
- `<key_col>` (or `<key_col_1>`, `<key_col_2>`, ...) -- the columns the
  regenerated trigger records, in primary-key order, or your `primary_key:`
  override's columns in the order you declared them. For a key of more than
  two columns, add one more `jsonb_build_object` pair, one more entry in the
  `?&` array, and one more `IS NOT NULL` guard per column, in key order.
- `<batch_size>` -- rows touched per run, for example `5000`.

Single-column key:

<!-- threadline:backfill-sql:start -->
```sql
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object('<key_col>', data_after ->> '<key_col>')
WHERE id IN (
  SELECT id
  FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>'
    AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ? '<key_col>'
    AND data_after ->> '<key_col>' IS NOT NULL
  LIMIT <batch_size>
);
```
<!-- threadline:backfill-sql:end -->

Composite key:

<!-- threadline:backfill-sql-composite:start -->
```sql
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object(
  '<key_col_1>', data_after ->> '<key_col_1>',
  '<key_col_2>', data_after ->> '<key_col_2>'
)
WHERE id IN (
  SELECT id
  FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>'
    AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ?& array['<key_col_1>', '<key_col_2>']
    AND data_after ->> '<key_col_1>' IS NOT NULL
    AND data_after ->> '<key_col_2>' IS NOT NULL
  LIMIT <batch_size>
);
```
<!-- threadline:backfill-sql-composite:end -->

**Batch pattern.** Run the statement repeatedly until it reports `UPDATE 0`.
Each run is one short transaction touching at most `<batch_size>` rows, so it
is safe to stop and resume at any point. It is also safe to rerun, or to run
two overlapping copies: each run only selects rows that are still
unresolved, and two runs computing the same row's key from the same
`data_after` always write the identical value. Run it only for tables you
have already regenerated -- a table whose key type was refused in Step 2
keeps writing unresolved keys, so backfilling it has nothing to resolve to.

**Before and after, for a non-`id`-keyed table.** Before the backfill,
`Threadline.history/3` does not return the table's pre-upgrade INSERT and
UPDATE rows when you query by the real key, because those rows are still
recorded as `{"id": null}`. After the backfill, the same `history/3` call
returns them alongside the rows captured after you regenerated the trigger.

## What cannot be recovered

Some rows cannot be given a real key by any backfill, because the value was
never stored:

- **DELETE rows.** Releases before 0.11 stored no row image for DELETE, so
  `data_after` is `NULL` for them. There is nothing to derive a key from.
- **Rows whose key columns were masked or excluded by redaction.** The
  column's value was never written to `audit_changes` in the first place.

Both stay unresolved after any backfill, by construction.

## What changed that you may notice

A table whose primary-key type is outside the supported set keeps its legacy
trigger after you regenerate everything else; it captures exactly as before,
with no primary key recorded until Threadline supports that type.

`table_pk` values of `{"id": null}` (written before 0.11) and `{}` (written
by 0.11 when a key cannot be resolved) both mean "unresolved" -- match both
if you query `audit_changes` directly.

`Threadline.history/3` and `Threadline.as_of/4` now raise `ArgumentError` for
a key that is wrong, `nil`, or cannot be cast to the key field's type, and
take a keyword list or map for a composite key.

`Threadline.Health.trigger_coverage/1` no longer counts a disabled or
replica-only trigger as covered, so a `verify_coverage` gate that passed
before this change can fail on upgrade. Fix with `ALTER TABLE ... ENABLE TRIGGER` (or `ENABLE ALWAYS TRIGGER`).

The `primary_key:` override for a table with no usable primary key lives in
`config/config.exs` under `config :threadline, :trigger_capture, tables:
%{...}`, and needs a qualifying unique index over `NOT NULL` columns. A key
column listed in a table's `mask` or `exclude` is refused, whether it comes
from a real primary key or a `primary_key:` override.

A fresh install already has the row-history index from Step 4.

See the [Security note](../CHANGELOG.md) for the shared-capture-function
issue this release fixes.

## Rolling back

Trigger migrations generated by 0.10.x end their `down` with a function drop
that cascades. Rolling one of those back after you upgrade can drop a
sibling table's live trigger along with it, if the two ever shared a
function. Do not roll back a pre-0.11 trigger migration as generated --
regenerate forward instead. If you must roll one back, edit its `down` first
so it drops its own triggers (`DROP TRIGGER ...`, no cascade), then runs the
rollback-cleanup SQL below in place of its function drop.

<!-- threadline:rollback-cleanup-sql:start -->
```sql
DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT p.oid, format('%I.%I', n.nspname, p.proname) AS qualified
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = '<storage_schema>'
      AND p.proname LIKE 'threadline\_capture\_changes\_%'
      AND NOT EXISTS (
        SELECT 1 FROM pg_trigger t WHERE t.tgfoid = p.oid AND t.tgparentid = 0
      )
  LOOP
    EXECUTE format('DROP FUNCTION %s', fn.qualified);
  END LOOP;
END $$;
```
<!-- threadline:rollback-cleanup-sql:end -->

This loops over every per-table capture function in `<storage_schema>` whose
name matches `threadline_capture_changes_<table>` and drops only the ones no
trigger references anymore, never with `CASCADE`. It never touches the
global `threadline_capture_changes` function, which has no such suffix and
so never matches the pattern. Because it only drops functions nothing uses,
it is safe to run in any order relative to other cleanup.

Migrations generated by 0.11 roll back safely as generated -- their `down`
never cascades.

## Next steps

- [Return to the canonical first-hour adoption path](getting-started-saas.md).
- [Review support lanes and future minor upgrades](upgrade-path.md).
