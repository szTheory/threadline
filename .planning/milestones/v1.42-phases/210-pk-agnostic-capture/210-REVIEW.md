---
phase: 210-pk-agnostic-capture
reviewed: 2026-09-25T22:08:05Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - lib/threadline/capture/primary_key_sql.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/capture/trigger_capture_config.ex
  - lib/threadline/capture/naming.ex
  - lib/threadline/storage_schema.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
  - mix.exs
  - bench/pk_capture_bench.exs
  - bench/fixtures/threadline_capture_changes_v0_10_2.sql
  - bench/README.md
  - bench/baselines/pk_capture_bench.md
  - guides/configuration-and-commands.md
  - CHANGELOG.md
  - test/support/legacy_trigger_sql.ex
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/threadline/capture/collision_free_emission_test.exs
  - test/threadline/capture/legacy_trigger_pk_fallback_test.exs
  - test/threadline/capture/trigger_body_invariants_test.exs
  - test/threadline/capture/trigger_capture_config_test.exs
  - test/threadline/capture/trigger_migrate_time_errors_test.exs
  - test/threadline/capture/trigger_pk_override_test.exs
  - test/threadline/capture/trigger_pk_shapes_test.exs
  - test/threadline/capture/trigger_sql_storage_schema_test.exs
  - test/threadline/mix/trigger_migration_property_test.exs
  - test/threadline/mix/trigger_migration_test.exs
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 210: Code Review Report

**Reviewed:** 2026-09-25T22:08:05Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Phase 210 replaces the `id`-only trigger key assumption with a migrate-time
`pg_index` lookup (`PrimaryKeySQL`) that resolves a table's real primary key
(or a config-declared `primary_key:` override) and passes it to a
catalog-free, per-row PL/pgSQL fragment via `TG_ARGV`. The core mechanism is
sound: identifier interpolation into generated SQL is consistently routed
through `StorageSchema.validate_identifier!`/`quote_ident`/`quote_literal`,
the row-key fragment never does a catalog lookup or dynamic SQL per row (and
is pinned by `trigger_body_invariants_test.exs`), the NULL/missing-column
"all or nothing" semantics for composite keys are correctly implemented and
well covered by real-Postgres tests (`trigger_pk_shapes_test.exs`,
`legacy_trigger_pk_fallback_test.exs`), and the type-allowlist and
redaction-overlap refusals are exercised against a wide combination of
Postgres types, index shapes (partial, deferrable, expression, nullable,
INCLUDE, subset/superset), and schema-qualified/partitioned tables.

I did not find a BLOCKER-level correctness, security, or data-loss defect.
I found four WARNING-level issues — two are genuine gaps between what the
code's own doc comments promise and what the SQL actually guarantees, one is
an unintended asymmetry between detected and declared primary keys, and one
is duplicated logic introduced in this same phase — plus two INFO-level
quality notes. None of these need to block a ship, but the two ordering
claims should either be fixed with an explicit `ORDER BY` or have their doc
comments softened, since they are asserted as behavior in code comments a
future maintainer will rely on.

## Warnings

### WR-01: `redaction_check_sql/2`'s "first offending column" pick has no `ORDER BY`

**File:** `lib/threadline/capture/primary_key_sql.ex:393-411`

**Issue:** The doc comment says this block "refuses the migration, naming
the first offending column in key order":

```elixir
# Emitted only when the table has redaction rules: a detected
# primary-key column listed in the table's mask or exclude refuses the
# migration, naming the first offending column in key order. ...
```

But the query that picks the reported column has no `ORDER BY`:

```sql
SELECT k INTO col FROM unnest(keys) AS k WHERE k = ANY(#{array_literal}) LIMIT 1;
```

`unnest()` over an array is not guaranteed by the SQL standard to preserve
array order without `WITH ORDINALITY ... ORDER BY ord`, and this project's
own `create_trigger_block` docs elsewhere are careful to add
`WITH ORDINALITY ... ORDER BY ord` specifically because "`indkey` is 0-based"
ordering must be preserved (see the `array_agg` and `string_agg` calls a few
lines above in the same module, all of which do order explicitly). This one
query is the exception. In practice PostgreSQL's `unnest` over a plain array
literal is stable today, but relying on that instead of an explicit
`ORDER BY ordinality` is exactly the kind of implicit-ordering assumption
this module otherwise takes pains to avoid, and a planner change (or a
future rewrite of this fragment to a JOIN-based form) could silently name a
different column than "first in key order" without any test catching it —
no existing test declares more than one redacted key column, so this
ordering claim is untested.

**Fix:**
```sql
SELECT k INTO col
  FROM unnest(keys) WITH ORDINALITY AS u(k, ord)
 WHERE k = ANY(#{array_literal})
 ORDER BY ord
 LIMIT 1;
```

### WR-02: HINT/paste-ready snippets built with `chr(34) ||` don't escape embedded double quotes

**File:** `lib/threadline/capture/primary_key_sql.ex:170-184`

**Issue:** The no-primary-key HINT builds a manually double-quoted column
list for the paste-ready `primary_key:` suggestion:

```sql
SELECT string_agg(chr(34) || a.attname || chr(34), ', ' ORDER BY k.ord)
  INTO idx_cols
  ...
```

If a real column name itself contains a double quote (legal in Postgres via
`CREATE TABLE t ("weird""col" ...)`), this produces `"weird"col"` — not
valid Elixir/config syntax, and not what an operator should paste into
`config/config.exs`. This is advisory text only (never executed as SQL), so
it cannot cause SQL injection, but it can hand an adopter a broken
copy-paste snippet for that edge case, which undermines the "paste-ready"
guarantee the docstring makes ("its `HINT` gives a paste-ready
`config/config.exs` snippet"). Low real-world likelihood, but cheap to fix
and currently untested for this case.

**Fix:** Double any embedded `"` before wrapping, e.g.
`chr(34) || replace(a.attname, chr(34), chr(34) || chr(34)) || chr(34)`, or
build the equivalent via `quote_literal`/`format('%L', ...)` consistently
with the rest of the file.

### WR-03: `primary_key:` overrides can't declare a column that requires quoting, unlike detected keys

**File:** `lib/threadline/capture/trigger_capture_config.ex:141-167`, `lib/threadline/storage_schema.ex:79-89`

**Issue:** A declared `primary_key:` column name is validated via
`StorageSchema.validate_identifier!(str, :primary_key_column)`, which
requires the name to match `^[A-Za-z_][A-Za-z0-9_]*$` (the same regex used
for schema/table identifiers that get bare-word-quoted). This is stricter
than what PostgreSQL itself allows for a legally-quoted identifier: a column
like `"1code"`, `"post-id"`, or `"post id"` is valid Postgres DDL and would
be *detected* automatically and captured correctly if it were a real primary
key (the `pk_mixed_case` test proves the *detected* path handles arbitrary
quoted names, including mixed case, via `pg_attribute.attname` with no regex
check at all — see `primary_key_sql.ex:144` and its type-check FOREACH,
neither of which validates `col` against this regex). But the exact same
column name, if it needed to be *declared* via `primary_key:` because the
table has no real primary key, would be rejected at config-load time before
ever reaching the database, with no way to work around it (there is no
quoting escape hatch in `primary_key:`).

This is a real functional gap — an adopter with an oddly-but-legally-named
key column on a PK-less join table cannot use the declared-override path at
all — and it is not documented as a known limitation in `guides/configuration-and-commands.md`,
the mix task's `@moduledoc`, or the CHANGELOG.

**Fix:** Either loosen `validate_primary_key_name!/2` to accept any
non-empty, NUL-free, untrimmed-equal string up to 63 bytes (matching what
the detected path already tolerates, since the DO block always emits these
names through `quote_literal`/`ANY()`, never as bare SQL identifiers), or
explicitly document the identifier restriction as a known limitation of
`primary_key:`.

### WR-04: `mix threadline.gen.triggers`'s private `table_token/1` duplicates the new `Naming.table_token/1` instead of reusing it

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:410-411`, `lib/threadline/capture/naming.ex:89-101`

**Issue:** This phase adds `Naming.table_token/1` specifically so that
"`TriggerSQL.function_owner_guard/2` and `PrimaryKeySQL`'s no-primary-key
HINT... both modules print the same token for one table" (doc comment on
`Naming.table_token/1`). But `Mix.Tasks.Threadline.Gen.Triggers` — also
touched in this phase (see `warn_shared_legacy_names/2`) — defines its own
private helper with the identical name and near-identical logic instead of
calling the shared one:

```elixir
defp table_token(%{schema: "public", table: table}), do: table
defp table_token(pair), do: Naming.qualified(pair)
```

Functionally these currently agree (`Naming.qualified/1` for a non-`public`
pair equals `Naming.table_token/1`'s non-`public` branch), but the two
implementations can now drift independently — a future change to one
"shared token" format (the stated purpose of introducing `Naming.table_token/1`)
would silently miss this third call site, defeating the "single owner"
intent documented on `Naming`.

**Fix:** Delete the local `table_token/1` in the mix task and call
`Naming.table_token/1` at its one call site in `warn_shared_legacy_names/2`.

## Info

### IN-01: Dead `coalesce(v_table_pk, '{}'::jsonb)` inside the composite-key loop

**File:** `lib/threadline/capture/primary_key_sql.ex:46`

**Issue:** In the `TG_NARGS > 0` branch of `row_key_statements/0`:

```sql
v_table_pk := '{}'::jsonb;
FOR i IN 0 .. TG_NARGS - 1 LOOP
  IF (v_row ->> TG_ARGV[i]) IS NULL THEN
    v_table_pk := '{}'::jsonb;
    EXIT;
  END IF;
  v_table_pk := coalesce(v_table_pk, '{}'::jsonb)
                || jsonb_build_object(TG_ARGV[i], v_row ->> TG_ARGV[i]);
END LOOP;
```

`v_table_pk` is initialized to `'{}'::jsonb` immediately before the loop and
is never assigned anything but a non-null `jsonb` value inside the loop, so
the `coalesce(v_table_pk, '{}'::jsonb)` on the accumulation line can never
see a NULL `v_table_pk` and is unreachable dead code. It's harmless (costs a
few extra bytes per generated function body, emitted into every trigger
function this library writes), but it reads as a defensive check against a
state that cannot occur, which can mislead a future maintainer into thinking
`v_table_pk` might legitimately go NULL mid-loop.

**Fix:** Drop the `coalesce(...)` on that line; keep the one after the
`FOR`/`IF` block (`primary_key_sql.ex:50`), which does guard a real
(`TG_NARGS = 0`, no `id` column) path.

### IN-02: `key_type_check_sql/1` type check runs before, not after, `redaction_check_sql/2` in both branches

**File:** `lib/threadline/capture/primary_key_sql.ex:188-189, 287-288`

**Issue:** Both `detected_trigger_block/3` and `override_trigger_block/4`
run the type-allowlist `FOREACH` before the mask/exclude overlap check. This
means a primary-key column that is both an unsupported type (e.g.
`timestamptz`) *and* listed in `:mask`/`:exclude` will always be refused for
its type first, and an adopter fixing the reported type error will only
discover the redaction conflict on the next migration attempt. Purely
cosmetic (the migration is refused either way, nothing is installed), but
worth a one-line comment noting the check order is deliberate (or swapping
it) so a future refactor doesn't accidentally treat the ordering as
insignificant when it affects which error message ships first.

**Fix:** No code change required; consider a short comment above
`key_type_check_sql(qualified)` explaining that it intentionally precedes
the redaction check, or swap the order if a redaction conflict should
surface first.

---

_Reviewed: 2026-09-25T22:08:05Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
