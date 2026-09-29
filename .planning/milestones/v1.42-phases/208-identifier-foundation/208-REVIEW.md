---
phase: 208-identifier-foundation
reviewed: 2026-09-25T14:20:04Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/threadline/capture/naming.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/continuity.ex
  - lib/threadline/mix/migrations_path.ex
  - lib/threadline/mix/trigger_migration.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/storage_schema.ex
  - mix.exs
  - release-please-config.json
  - CHANGELOG.md
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/mix/tasks/threadline/install_test.exs
  - test/support/custom_priv_repo.ex
  - test/threadline/capture/naming_property_test.exs
  - test/threadline/capture/naming_test.exs
  - test/threadline/changelog_contract_test.exs
  - test/threadline/mix/migrations_path_test.exs
  - test/threadline/mix/trigger_migration_test.exs
  - test/threadline/storage_schema_test.exs
findings:
  critical: 1
  warning: 4
  info: 6
  total: 11
status: issues_found
---

# Phase 208: Code Review Report

**Reviewed:** 2026-09-25T14:20:04Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

I reviewed the phase 208 diff (`fd128c67..HEAD`) against the frozen identifier format in 208-CONTEXT.md, decisions D-01 to D-12.

**The format itself matches the decisions.**
- All eight D-05 golden hashes were recomputed independently with `shasum -a 256` and agree.
- `trigger_name/1` is the legacy name cut to 63 bytes (D-02).
- `function_name/1` applies the three D-03 legacy conditions and the 23-byte stem plus `_` plus hash12.
- `migration_name/2` follows D-06: uniq, sort and join the qualified names, trim the trailing `_`, and put the ordinal after the hash.
- The release-please flip is the first commit of the phase (`28beadd9 ci(release)`, D-12).
- The phase's 8 test files pass: 127 tests and 7 properties, 0 failures.

**One real defect is on the path that D-02 was designed to protect.** The rerun matcher misses overflowed trigger names written by releases before 0.10.0. A reproduction is under CR-01. The remaining findings are robustness and accuracy gaps.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Rerun detection misses overflowed trigger names from releases before 0.10.0, so rolling back a regenerated migration drops live capture

**File:** `lib/threadline/mix/trigger_migration.ex:80-83`, `lib/mix/tasks/threadline.gen.triggers.ex:215-218`, `test/threadline/mix/trigger_migration_test.exs` (test "finds a trigger name cut to 63 bytes, and not a name that extends it")

**Issue:** The pieces involved:
- `gen.triggers` now passes the trigger name cut to 63 bytes (`Naming.trigger_name(pair)`) to `rerun?/2`.
- `rerun?/2` compiles `escape(name) <> "(?![A-Za-z0-9_])"`, so a match must not run on into more identifier characters.
- Releases up to and including v0.9.0 wrote the trigger name unquoted and uncut: `CREATE TRIGGER threadline_audit_#{table_name}` in `v0.9.0:lib/threadline/capture/trigger_sql.ex:145`. Those releases had no 63-byte validation; `StorageSchema`'s check first ships in v0.10.0.

For such a table, the adopter's migration contains the full name, for example 67 bytes for a 50-byte table. PostgreSQL stored that trigger under the 63-byte cut name. The cut name is followed by more identifier characters in that source, so the negative lookahead rejects the match.

Reproduced:

```
t = String.duplicate("t", 50)
src = "execute \"CREATE TRIGGER threadline_audit_#{t}\nAFTER ... ON #{t}\""
TriggerMigration.rerun?(Naming.trigger_name(t), [src])  #=> false
```

**Consequence:** The table is treated as a first run, so the new migration's `down` emits `DROP TRIGGER IF EXISTS "<cut>" ON ...`. Rolling back the regenerated migration then removes the trigger that the earlier, still-applied migration installed. Capture silently stops, which means lost audit rows.

Overflowed 0.x installs are exactly the case D-02 exists to serve. The CHANGELOG also claims "a rerun for that table is recognised" (CHANGELOG.md, Changed section). The new test asserts the dangerous direction: `refute TriggerMigration.rerun?(trigger, [longer])`. D-11 accepts false positives as the conservative direction; this is a false negative.

**Fix:** When the name is at the 63-byte cap, compare the cut of every candidate token instead of requiring an exact boundary:

```elixir
def rerun?(trigger_name, sources) when byte_size(trigger_name) < 63 do
  trigger = Regex.compile!(Regex.escape(trigger_name) <> "(?![A-Za-z0-9_])")
  Enum.any?(sources, &Regex.match?(trigger, &1))
end

def rerun?(trigger_name, sources) do
  # A 63-byte name is what PostgreSQL stored for any longer name with this prefix.
  prefix = Regex.compile!(Regex.escape(trigger_name) <> "[A-Za-z0-9_]*")
  Enum.any?(sources, &Regex.match?(prefix, &1))
end
```

Then invert the `longer` assertion in the test, and add a regression test that uses the v0.9.0 unquoted, uncut form.

## Warnings

### WR-01: `Naming.pair/1` accepts any map, so unvalidated input reaches derived names

**File:** `lib/threadline/capture/naming.ex:71`

**Issue:** `pair(%{schema: _, table: _} = pair)` trusts every map as "already validated". Nothing enforces that. Two consequences:
- `Naming.function_name(%{schema: "x y", table: "z"})` returns `"threadline_capture_changes_x y_z_61ad124925c3"`, which is not a valid identifier (reproduced).
- A map with an over-63-byte table yields a legacy function name longer than 63 bytes.

`TriggerMigration.resolve_name/2`'s spec now advertises map input. Phase 209 will emit these names into SQL, and the format is one-way. A single careless caller would therefore bake an invalid name into adopters' migrations.

**Fix:** Revalidate cheaply in the map clause:

```elixir
def pair(%{schema: s, table: t}),
  do: %{schema: StorageSchema.validate_identifier!(s, :host_schema),
        table: StorageSchema.validate_identifier!(t, :host_table)}
```

The alternative is a guard that restricts maps to a struct produced by `parse_table_identifier/1`.

### WR-02: `mix threadline.install` still silently ignores positional arguments

**File:** `lib/mix/tasks/threadline.install.ex:56-64` (the same pattern is in `lib/mix/tasks/threadline.gen.triggers.ex:171-188`)

**Issue:** `{opts, _rest, invalid}` discards `_rest`. `mix threadline.install priv/audit/migrations` or `mix threadline.install MyApp.AuditRepo` therefore still writes to the default directory without a word. The CHANGELOG's "Breaking changes" entry and the moduledoc both say the task now rejects what it does not recognise. That is only true for flags.

**Fix:** Also raise when `_rest != []`:

```elixir
if rest != [], do: Mix.raise("Unexpected arguments: #{inspect(rest)}. Did you mean --migrations-path or --repo?")
```

### WR-03: A configured-but-unloadable default repo silently falls back to `priv/repo/migrations`, now in `gen.triggers` too

**File:** `lib/threadline/mix/migrations_path.ex:49-58`

**Issue:** `rescue _ -> @default` swallows every error from `repo.config()`, including an `UndefinedFunctionError` from a misspelled or uncompiled `:ecto_repos` entry. D-08 kept this for `install`. `gen.triggers` now inherits it, so the CONF-02 guarantee ("the same directory `ecto.migrate` reads") can silently fail again. The trigger migration lands in `priv/repo/migrations`, which a custom-`:priv` repo never reads. The adopter believes capture is installed when it is not.

**Fix:** At minimum, emit `Mix.shell().error/1` naming the repo and the fallback directory before returning `@default`. Better, narrow the rescue to the umbrella or no-app case and `Mix.raise` for a configured repo that fails to load, matching the explicit `--repo` path.

### WR-04: `--repo` validation is skipped on `--dry-run`

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:156-167, 199-200`

**Issue:** `MigrationsPath.resolve/1` only runs inside `write_migration!/3`. `--dry-run --repo A --repo B` and `--dry-run --repo Does.Not.Exist` therefore both succeed. A dry run should surface the same argument errors the real run would hit.

**Fix:** Resolve the path in `run/1` right after `parse_opts!/1`, then pass it into `write_migration!/3`.

## Info

### IN-01: Cut trigger names widen the accepted `rerun?` false positive

**File:** `lib/threadline/mix/trigger_migration.ex:80`

**Issue:** Two long tables that share the first 46 bytes of their suffix now share a 63-byte cut trigger name. Generating for the second table is then reported as a rerun, and its `down` omits the `DROP TRIGGER`. This is the conservative direction D-11 accepts. It is worth listing among the Phase 209 NAME-03 inputs next to the `public.a_b` / `a.b` case.

**Fix:** Track it in the Phase 209 rerun rewrite, which matches on the `ON` clause.

### IN-02: `Naming.suffix/1` duplicates `StorageSchema.host_table_suffix/1`, and `TriggerSQL` keeps its own function-name builder

**File:** `lib/threadline/capture/naming.ex:82-88`, `lib/threadline/storage_schema.ex:165-173`, `lib/threadline/capture/trigger_sql.ex:168-170`

**Issue:** There are three derivations of the same legacy suffix or name. A golden test asserts that `suffix` and `host_table_suffix` agree, but only for the golden rows.

**Fix:** Delegate one to the other. In Phase 209, have `per_table_function_base/1` call `Naming`.

### IN-03: The property "names are deterministic" is partly tautological

**File:** `test/threadline/capture/naming_property_test.exs:46-55`

**Issue:** `assert f(pair) == f(pair)` cannot fail for a pure function. Only the bare-versus-`public.` half of the property carries signal.

**Fix:** Drop the self-equality assertions, or compare against a stored literal. The golden test already does the latter.

### IN-04: `migration_name/2` de-duplicates for the hash but not for the readable part

**File:** `lib/threadline/capture/naming.ex:115-137`

**Issue:** `--tables posts,public.posts` gives `threadline_triggers_posts_posts`. `gen.triggers` also emits the trigger statements twice. The duplicates are harmless because the statements are `CREATE OR REPLACE`, but the input is surprising.

**Fix:** Run `Enum.uniq_by(&qualified/1)` on the pairs in `gen.triggers` before naming and spec building. Alternatively, reject duplicates with a `--tables` error.

### IN-05: `StorageSchema.validate!/1` still labels every failure "storage schema"

**File:** `lib/threadline/storage_schema.ex:59-60, 114`

**Issue:** The docstring says the function validates "a schema, table, or function name". `quote_ident/1` and `function/2` route through it, so any non-storage identifier that reaches them unvalidated reports "storage schema". The phase avoids this on the current paths, but the label contradicts D-10's intent for future callers.

**Fix:** Narrow the docstring to the storage schema. Alternatively, give `quote_ident/2` an optional role.

### IN-06: `--migrations-path=` (empty) is accepted

**File:** `lib/threadline/mix/migrations_path.ex:29`

**Issue:** An empty string is truthy in the `cond`, so migrations are written into the current directory.

**Fix:** Treat `""` as a usage error: `Mix.raise("--migrations-path must not be empty")`.

---

_Reviewed: 2026-09-25T14:20:04Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
