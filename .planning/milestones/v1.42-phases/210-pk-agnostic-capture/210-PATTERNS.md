# Phase 210: PK-Agnostic Capture - Pattern Map

**Mapped:** 2026-09-25
**Files analyzed:** 9 (4 modified existing modules, 1 new config validation function inside an existing module, 1 new bench script, 1 new bench fixture, 2+ new test files, 1 extended test file)
**Analogs found:** 9 / 9 — this phase modifies existing modules more than it creates new files; every "new" unit of work has a same-file sibling to copy.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/capture/trigger_sql.ex` (shared PK fragment, `create_trigger_sql/2` → DO block) | service (SQL generator) | transform (Elixir string → PL/pgSQL text) | itself: `function_owner_guard/2` (lines 168-195) and `drop_function_if_unused/2` (lines 124-149) | exact — same module, same DO-block idiom already established by Phase 209 |
| `lib/threadline/capture/trigger_sql.ex` (12-site PK extraction swap in the 4 renderers) | service (SQL generator) | transform | itself: `data_after_redaction_statements/4` (lines 590-614) — an existing per-branch fragment interpolated into all 4 renderers via `#{...}` | exact — identical "one Elixir-built fragment interpolated into 4 bodies" shape as the existing redaction fragment |
| `lib/threadline/capture/trigger_capture_config.ex` (`validate_primary_key!/1`, wired into `normalize_table_entry/1`) | config / validation | CRUD (validate-then-normalize) | itself: `normalize_table_entry/1`'s existing `put_if_present(:except_columns, normalize_columns(...))` path (lines 60-67) + `Threadline.Capture.RedactionPolicy.validate!/1` (whole file) | exact — same function, same file; RedactionPolicy is the direct template for "raise ArgumentError naming the bad value" |
| `lib/mix/tasks/threadline.gen.triggers.ex` (`build_table_capture_spec/4` gains a `primary_key` branch; passed to `TriggerSQL.create_trigger/3`) | route / CLI task (Mix task) | request-response (CLI invocation → migration file) | itself: `build_table_capture_spec/4` (lines 358-385) — already reads `entry` keys and builds `opts` passed to `TriggerSQL` | exact — same function, same pattern (`Keyword.get(entry, :key, default)`) |
| `test/threadline/capture/trigger_pk_shapes_test.exs` (new — CAP-01, CAP-02) | test (real-PG unit) | request-response (migrate + write + assert) | `test/threadline/capture/trigger_redaction_test.exs` (whole file, esp. `describe "per-table capture with exclude and mask"` lines 40-71) | exact — same DataCase/real-PG harness shape, same "install then INSERT/UPDATE and assert stored JSON" pattern |
| `test/threadline/capture/trigger_migrate_time_errors_test.exs` (new — CAP-03, CAP-05 migrate half, CONF-01 migrate half) | test (real-PG migration) | request-response | `test/mix/tasks/threadline/gen_triggers_test.exs` `describe "--tables validation"` (~line 394) and `describe "shared capture function advisory"` (line 670) | exact — same "run the Mix task / migrator, assert `Mix.raise`/`RAISE EXCEPTION` message content" pattern |
| `test/threadline/capture/legacy_trigger_pk_fallback_test.exs` (new — CAP-04, extends legacy harness) | test (real-PG, frozen SQL fixture) | request-response | `test/support/legacy_trigger_sql.ex` (whole file) + `test/threadline/capture/legacy_trigger_regeneration_test.exs` | exact — `LegacyTriggerSQL` already exists and is the named reuse target; only a new uuid/text-PK table fixture is genuinely new |
| static-invariant test extending `describe "generated SQL invariants"` (D-08, SC5 regex) | test (unit, string assertion) | transform | `test/mix/tasks/threadline/gen_triggers_test.exs:618-658` (`describe "generated SQL invariants"`) | exact — same describe block family; extend with a `$threadline_trigger$`-delimiter extraction + forbidden-token regex |
| `bench/pk_capture_bench.exs` (new, D-07) + `bench/fixtures/` 0.10.2 copy | utility (bench script) | batch (bulk INSERT/UPDATE/DELETE timing) | `bench/audit_capture_bench.exs` + `bench/bench_helper.exs` (`Bench.Helper.setup/0`, `write_metadata`) | role-match — explicitly named by D-07 as the harness pattern to follow; CONTEXT.md also explicitly says *not* to use `audit_capture_bench.exs`'s workload as the reference numbers, only its harness shape |

## Pattern Assignments

### `lib/threadline/capture/trigger_sql.ex` — shared PK fragment (D-01/D-05)

**Analog:** same file, `data_after_redaction_statements/4` (lines 588-614) — the existing precedent for "one private function returns a PL/pgSQL fragment string, interpolated via `#{...}` into all four renderer bodies at the same three branches (DELETE/INSERT/UPDATE)."

**Interpolation pattern to copy** (lines 431-457, the redacted per-table renderer's IF/ELSIF/ELSE — this is the exact shape the new PK fragment replaces `jsonb_build_object('id', ...)` inside):
```elixir
IF TG_OP = 'DELETE' THEN
  v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));
  v_data_after     := NULL;
  ...
ELSIF TG_OP = 'INSERT' THEN
  v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
  v_data_after     := to_jsonb(NEW);
#{redact_after_new}
  ...
ELSE
  v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
  ...
END IF;
```
**12 exact replacement sites** (all `jsonb_build_object('id', (to_jsonb(NEW|OLD) ->> 'id'))`):
- `global_install_function_sql_legacy/1`: lines 275, 280, 286
- `per_table_install_sql_legacy/3`: lines 340, 346, 352
- `per_table_install_sql_redacted/7`: lines 432, 438, 445
- `global_capture_function_sql_redacted/4`: lines 489, 494, 501

Each site should become two statements: `v_row := to_jsonb(NEW|OLD);` (once per branch, reused for `v_data_after` too per the research doc's Pattern 1) followed by a call to the new shared fragment-builder function, e.g. `#{pk_extraction_sql("v_row")}`. Declare `v_row jsonb;` alongside the existing `v_table_pk jsonb;` in each renderer's `DECLARE` block (all four already declare `v_table_pk`, e.g. line 269, 320, 425, 483).

**Fragment content to generate** (verified locally in RESEARCH.md Pattern 1, PG 14.17):
```sql
IF TG_NARGS = 0 THEN
  IF v_row ? 'id' THEN
    v_table_pk := jsonb_build_object('id', v_row ->> 'id');
  ELSE
    v_table_pk := '{}'::jsonb;
  END IF;
ELSE
  v_table_pk := '{}'::jsonb;
  FOR i IN 0 .. TG_NARGS - 1 LOOP
    IF (v_row ->> TG_ARGV[i]) IS NULL THEN
      v_table_pk := '{}'::jsonb;
      EXIT;
    END IF;
    v_table_pk := coalesce(v_table_pk, '{}'::jsonb)
                  || jsonb_build_object(TG_ARGV[i], v_row ->> TG_ARGV[i]);
  END LOOP;
END IF;
```
Loop variable `i` needs `DECLARE i int;` added alongside `v_row`/`v_table_pk` in all four bodies.

**Helper-string pattern to copy** (how existing fragments build reusable literal arrays, for `mask_array_sql_fragment/1` and `except_array_sql_fragment/1`, lines 621-627 and 635-641) — same `Enum.map_join(cols, ", ", &sql_string_literal/1)` idiom applies if the DO-block override array (D-17, `ARRAY[...]::text[]`) is built the same way.

---

### `lib/threadline/capture/trigger_sql.ex` — DO-block PK resolver replacing `create_trigger_sql/2` (D-09/D-10/D-11/D-12/D-17)

**Analog:** same file, `function_owner_guard/2` (lines 168-195) — this is the literal template CONTEXT.md D-13 names ("the planner should point tasks at this function as the literal template ... not describe it from scratch").

**Imports/module pattern** (lines 1-5, unchanged):
```elixir
alias Threadline.Capture.{Naming, RedactionPolicy}
alias Threadline.StorageSchema
```

**DO-block error/guard pattern to copy verbatim in structure** (lines 168-195):
```elixir
def function_owner_guard(table_name, opts \\ []) do
  function_literal = per_table_function_name(table_name, opts)
  owner_literal = StorageSchema.qualified_host_table(table_name)
  owner_token = tables_option_token(table_name)

  """
  -- threadline: fail if another table's trigger uses this table's capture function
  DO $$
  DECLARE
    fn       regprocedure := to_regprocedure('#{function_literal}()');
    owner    regclass     := to_regclass('#{owner_literal}');
    others   text;
    retables text;
  BEGIN
    ...
    IF others IS NOT NULL THEN
      RAISE EXCEPTION 'threadline: triggers on % also use the capture function of #{Naming.qualified(table_name)} and may now apply another table''s redaction rules', others
        USING HINT = format('Regenerate those tables in the same command: mix threadline.gen.triggers --tables #{owner_token},%s (or regenerate %s first).', retables, retables);
    END IF;
  END $$;
  """
end
```
Apply this exact shape (comment header naming what the block does, `DECLARE`, catalog `SELECT INTO`, a `RAISE EXCEPTION ... USING HINT = format(...)` on failure) to the new PK-resolution DO block that replaces `create_trigger_sql/2` (lines 230-239):
```elixir
defp create_trigger_sql(table_name, function_invocation) do
  trigger_name = Naming.trigger_name(table_name)
  host_table = StorageSchema.qualified_host_table(table_name)

  """
  CREATE OR REPLACE TRIGGER #{StorageSchema.quote_ident(trigger_name)}
  AFTER INSERT OR UPDATE OR DELETE ON #{host_table}
  FOR EACH ROW EXECUTE FUNCTION #{function_invocation}
  """
end
```
This function currently emits a bare, argument-less `CREATE OR REPLACE TRIGGER`. It becomes the D-09 DO block: `EXECUTE format('CREATE OR REPLACE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON <quoted literal> FOR EACH ROW EXECUTE FUNCTION <quoted literal>(%s)', ..., string_agg(quote_literal(attname), ', ' ORDER BY ord))`. Reuse `StorageSchema.qualified_host_table/1` and `StorageSchema.quote_ident/1` exactly as `function_owner_guard/2` and the current `create_trigger_sql/2` already do — do **not** use `regclass::text` (explicitly forbidden by D-09, and `qualified_host_table/1`/`quote_ident/1` are the existing safe primitives).

**Drop-function DO-block pattern for reference on the "check catalog, act conditionally, never cascade" shape** (lines 124-149, `drop_function_if_unused/2`) — same `to_regprocedure`/`IF ... IS NULL THEN RETURN`/`EXECUTE format(...)` idiom applies to the "does this table already have a PK?" check (D-17's "refuses if the table already has a PK").

---

### `lib/threadline/capture/trigger_capture_config.ex` — `validate_primary_key!/1` (D-15)

**Analog:** `Threadline.Capture.RedactionPolicy.validate!/1` (whole file, 72 lines) — the direct template for "validate a list-shaped config value, raise `ArgumentError` naming the offending value."

**Imports pattern** (line 4, already present):
```elixir
alias Threadline.Capture.RedactionPolicy
```

**Validation pattern to copy** (RedactionPolicy `validate_placeholder!/1`, lines 46-62):
```elixir
def validate_placeholder!(placeholder) when is_binary(placeholder) do
  if placeholder == "" do
    raise ArgumentError, "placeholder must not be empty"
  end

  if String.length(placeholder) > @max_placeholder_length do
    raise ArgumentError,
          "placeholder exceeds max length (#{@max_placeholder_length})"
  end

  if String.contains?(placeholder, <<0>>) or
       Enum.any?(1..31, &String.contains?(placeholder, <<&1>>)) do
    raise ArgumentError, "placeholder must not contain control characters"
  end

  :ok
end
```
Apply the same "each rule is its own `if`/`raise ArgumentError` with a message naming the value" style to `validate_primary_key!/1`'s rules: bare string/atom rejected, empty list, empty name, NUL, >63 bytes (delegate to `StorageSchema.validate_identifier!/3`, see Naming/StorageSchema section below), duplicates, non-list, overlap with mask/exclude.

**Overlap-check pattern to copy** (RedactionPolicy `validate!/1`, lines 17-29 — the intersection check is the direct template for D-12's mask/exclude overlap):
```elixir
def validate!(opts) when is_map(opts) do
  exclude = normalize_columns(Map.get(opts, :exclude, Map.get(opts, "exclude", [])))
  mask = normalize_columns(Map.get(opts, :mask, Map.get(opts, "mask", [])))
  intersection = MapSet.intersection(MapSet.new(exclude), MapSet.new(mask))

  if MapSet.size(intersection) > 0 do
    sample = intersection |> MapSet.to_list() |> List.first()
    cols = intersection |> MapSet.to_list() |> Enum.sort() |> Enum.join(", ")

    raise ArgumentError,
          "exclude and mask overlap on columns: #{cols}. " <>
            "Column #{inspect(sample)} cannot be both excluded and masked."
  end
  ...
```

**Wiring pattern into `normalize_table_entry/1`** (lines 57-71, the function that must gain the `primary_key:` branch):
```elixir
defp normalize_table_entry(entry) when is_list(entry) do
  normalized =
    []
    |> put_if_present(:exclude, normalize_columns(Keyword.get(entry, :exclude, [])))
    |> put_if_present(:mask, normalize_columns(Keyword.get(entry, :mask, [])))
    |> put_if_present(:mask_placeholder, Keyword.get(entry, :mask_placeholder))
    |> put_if_present(:store_changed_from, Keyword.get(entry, :store_changed_from))
    |> put_if_present(
      :except_columns,
      normalize_columns(Keyword.get(entry, :except_columns, []))
    )

  RedactionPolicy.validate!(normalized)
  normalized
end
```
**Critical divergence from the existing pattern (per D-15):** every existing `:except_columns`/`:exclude`/`:mask` key is normalized with `normalize_columns/1` (which silently `Enum.uniq`s and drops blanks) *before* validation runs. D-15 explicitly requires `primary_key:` to be validated on the **raw** `Keyword.get(entry, :primary_key)` value first (catching dup/blank/non-list errors), and only normalized (`Enum.map(&to_string/1)`) after `validate_primary_key!/1` passes. Do not reuse `normalize_columns/1` before validation for this key — that is the one place this analog must NOT be copied as-is.

D-15 also specifies ordering: "run after `RedactionPolicy.validate!`" — so the new `validate_primary_key!(entry)` call belongs after the existing `RedactionPolicy.validate!(normalized)` line, still inside `normalize_table_entry/1`.

---

### `lib/threadline/capture/naming.ex` + `lib/threadline/storage_schema.ex` — identifier reuse (D-15 "reuse the NAME-01 identifier check")

**Analog:** `StorageSchema.validate_identifier!/3` (lines 67-88 of `storage_schema.ex`) — already the ≤63-byte / regex identifier check used everywhere else in this phase's dependency chain (`per_table_function_name/2` in `trigger_sql.ex` line 251-256 calls it directly).

**Reuse pattern** (from `trigger_sql.ex` lines 251-256, the existing call site to copy for override column names):
```elixir
defp per_table_function_name(table_name, opts) do
  table_name
  |> Naming.function_name()
  |> StorageSchema.validate_identifier!(:derived)
  |> StorageSchema.function(opts)
end
```
Apply `StorageSchema.validate_identifier!(col, :primary_key_override)` (or similar new `role` atom) per declared override column inside `validate_primary_key!/1`. No changes needed to `naming.ex` or `storage_schema.ex` themselves — call sites only.

---

### `lib/mix/tasks/threadline.gen.triggers.ex` — `build_table_capture_spec/4` gains `primary_key` (D-13/D-14)

**Analog:** same file, same function (lines 358-385).

**Pattern to copy** (lines 358-364, reading a config-entry key into a local):
```elixir
defp build_table_capture_spec(pair, cli_store_changed_from, cli_except_columns, capture_tables) do
  entry = Map.get(capture_tables, Naming.qualified(pair), [])

  exclude = Keyword.get(entry, :exclude, [])
  mask = Keyword.get(entry, :mask, [])
  cfg_store_changed_from = Keyword.get(entry, :store_changed_from, false)
  cfg_except = Keyword.get(entry, :except_columns, [])
  ...
```
Add `primary_key = Keyword.get(entry, :primary_key)` alongside these, then thread it into the `opts` passed to `TriggerSQL.install_function_for_table/2` and — new — into `TriggerSQL.create_trigger/3`'s opts (currently `create_trigger/3` at lines 216-228 doesn't receive per-table redaction opts at all; it will need a `primary_key:` opt added to its call sites at lines 450-451).

**Error-wrapping pattern already in place, reusable unchanged** (lines 283-288, `config_key_qualified!/1` and the `rescue e in ArgumentError -> Mix.raise(...)` idiom, D-13's required mechanism):
```elixir
defp config_key_qualified!(key) do
  key |> StorageSchema.parse_table_identifier() |> Naming.qualified()
rescue
  e in ArgumentError ->
    Mix.raise("config :threadline, :trigger_capture tables: " <> Exception.message(e))
end
```
`TriggerCaptureConfig.load()` is already called inside `capture_tables_by_pair!/1` (line 180), which is inside the CLI's own top-level flow — any `ArgumentError` the new `validate_primary_key!/1` raises during `TriggerCaptureConfig.load()` is **already** caught by an existing rescue in this file (per RESEARCH.md's confirmation "no gen-task change needed for that error path"). Verify which rescue clause currently wraps `TriggerCaptureConfig.load()` itself (it's called at line 180, not inside `config_key_qualified!/1`) — if uncaught, add a matching `rescue e in ArgumentError -> Mix.raise(...)` around that call site following the exact same idiom.

---

### `test/threadline/capture/trigger_pk_shapes_test.exs` (new, CAP-01/CAP-02)

**Analog:** `test/threadline/capture/trigger_redaction_test.exs` (whole file; `describe "per-table capture with exclude and mask"`, lines 40-71).

**Setup/assert pattern to copy:**
```elixir
describe "per-table capture with exclude and mask" do
  setup do
    # ... installs the trigger with specific opts, e.g.
    # exclude: ["password"], mask: ["email"]
  end

  test "INSERT omits excluded keys and masks email" do
    # ... perform Repo.insert, then assert on the stored audit_changes row
  end

  test "UPDATE masks changed_from for masked column and omits exclude from data_after" do
    ...
  end
end
```
Use the same `DataCase`/real-PG harness (see `test/support/data_case.ex`, `test/support/migration_harness.ex`) already used by this file and by `trigger_changed_from_test.exs`/`trigger_context_test.exs`/`trigger_rerun_test.exs` in the same directory. New cases here should install triggers via `TriggerSQL.create_trigger/3` with a `primary_key:` override or against tables with non-`id`/composite/INCLUDE-column PKs (see RESEARCH.md Code Examples for the exact `posts_tags` INCLUDE-column DDL to reuse in a migration fixture), then assert the stored `table_pk` jsonb shape with `==`, never `@>` (Pitfall 3 — the `@>` ban applies to this phase's own test assertions too).

---

### `test/threadline/capture/trigger_migrate_time_errors_test.exs` (new, CAP-03/CAP-05/CONF-01 migrate half)

**Analog:** `test/mix/tasks/threadline/gen_triggers_test.exs`, `describe "--tables validation"` (~line 394) and `describe "shared capture function advisory"` (line 670).

**Pattern to copy** (lines 670-687, running the task and asserting on `shell_errors()`/migration content):
```elixir
describe "shared capture function advisory" do
  test "names a table an earlier migration covers that shared the old function name",
       %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)

    write_earlier_migration!(tmp, [
      LegacyTriggerSQL.v0_10_2_create_trigger("public", "billing_invoices")
    ])

    run_triggers(tmp, ["--tables", "billing.invoices"])

    assert [warning] = shell_errors()
    assert warning =~ "public.billing_invoices"
    ...
```
For CAP-03/CAP-05/CONF-01, the assertion target is the migrate-time `RAISE EXCEPTION` inside the generated DO block, not a Mix-task-time `Mix.raise`. Since D-09 says "Real-PG migration tests should run generated migrations through `Ecto.Migrator.up/4`/`down/4`" (CONTEXT.md Claude's Discretion), pattern the actual migrate step on `test/support/migration_harness.ex` rather than only the `gen.triggers` CLI shell-output assertions — read that support file before writing this test file (not excerpted here; role-match confirmed by RESEARCH.md's Validation Architecture table, which names this exact file as reused).

---

### `test/threadline/capture/legacy_trigger_pk_fallback_test.exs` (new, CAP-04)

**Analog:** `test/support/legacy_trigger_sql.ex` (whole file, reused verbatim per its own moduledoc contract) + `test/threadline/capture/legacy_trigger_regeneration_test.exs`.

**Fixture functions already available, call unchanged:**
```elixir
def v0_9_create_trigger(table, function_ref \\ "threadline_capture_changes()") ...
def v0_10_0_create_trigger(schema, table, function_ref \\ nil) ...
def v0_10_2_create_trigger(schema, table, function_ref \\ nil) ...
def migration_source(module, up_sqls, down_sqls) ...
```
These only cover the **trigger statement**, not the pre-210 **function body** (the `jsonb_build_object('id', ...)` logic being replaced). For CAP-04's "frozen 0.10.x SQL on a uuid `code`-keyed table stores `{}`" test, the plan needs a frozen copy of the pre-210 function body too — CONTEXT.md/RESEARCH.md's own guidance for the *separate* bench fixture (`git show v0.10.2:lib/threadline/capture/trigger_sql.ex`) is the right source; consider whether `test/support/legacy_trigger_sql.ex` should gain a frozen function-body renderer, or whether the test should call the **current, pre-this-phase** `TriggerSQL.global_install_function_sql_legacy/1`-equivalent captured as a string fixture before the phase's edits land. Either way, do not regenerate this fixture from the post-210 module (Pattern 4, Anti-Patterns: frozen migration SQL is a one-way compatibility contract).

---

### `test/mix/tasks/threadline/gen_triggers_test.exs` — extend `describe "generated SQL invariants"` (D-08, SC5)

**Analog:** same file, same describe block (lines 618-658).

**Pattern to copy** (the delimiter-scoped extraction + forbidden-token regex idiom):
```elixir
for [quoted] <- Regex.scan(~r/"(?:[^"]|"")*"/, sql) do
  identifier =
    quoted |> binary_part(1, byte_size(quoted) - 2) |> String.replace(~s(""), ~s("))

  assert byte_size(identifier) <= 63,
         "#{Path.basename(file)} #{fun} quotes a #{byte_size(identifier)}-byte " <>
           "identifier: #{identifier}"
end
```
D-08 needs an analogous `Regex.scan`/extraction step, but anchored on `$threadline_trigger$ ... $threadline_trigger$` delimiters (Pitfall 5: the DO block's own catalog SQL must be excluded by scope, not by loosening the forbidden-token regex). Extract only the delimited function-body text, then:
```elixir
refute body =~ ~r/\bpg_(index|attribute|class|namespace|constraint|trigger)\b|pg_catalog|information_schema|TG_RELID|regclass|to_reg\w+|\bEXECUTE\b/i
```
`statement_kind/1` (lines 661-668) already classifies statements by substring match (`CREATE OR REPLACE FUNCTION` → `:function`, etc.) — reuse this to select which statements to extract function-body text from before applying the regex.

---

### `bench/pk_capture_bench.exs` + `bench/fixtures/` (new, D-07)

**Analog:** `bench/audit_capture_bench.exs` + `bench/bench_helper.exs`.

Not read in full this pass (role-match only, per Early-Stopping guidance — D-07 already fully specifies fixture source, workload, timing method and pass bar in CONTEXT.md, so this is an execution detail, not a pattern-discovery question). Read `bench/bench_helper.exs`'s `write_metadata` function and `bench/audit_capture_bench.exs`'s `Bench.Helper.setup/0` / `Benchee.run` structure directly before writing this file — CONTEXT.md D-07 explicitly forbids using `audit_capture_bench.exs`'s *workload* as the reference (round-trip-dominated, delete scenario doesn't refire the trigger), but its *harness shape* (setup helper, metadata writer, `verify.bench` alias wiring at `mix.exs:~217`) is the correct analog to copy.

## Shared Patterns

### `threadline:`-prefixed error style (MESSAGE/DETAIL/HINT)
**Source:** `lib/threadline/capture/trigger_sql.ex:168-195` (`function_owner_guard/2`)
**Apply to:** Every new `RAISE EXCEPTION` in the D-09 DO block (CAP-03 no-PK error, D-17 override-mismatch errors, D-11 type-allowlist error, D-12 PK-in-redaction error) and every new `ArgumentError` raised by `validate_primary_key!/1` (wrapped into `Mix.raise` by the existing gen-task rescue idiom).
```elixir
RAISE EXCEPTION 'threadline: <MESSAGE>'
  USING HINT = format('<paste-ready snippet or command>');
```

### Fragment-interpolated-into-four-renderers idiom
**Source:** `lib/threadline/capture/trigger_sql.ex` — `data_after_redaction_statements/4` (588-614), `changed_fields_except_array_sql/2` (629-633), `mask_array_sql_fragment/1` (621-627)
**Apply to:** The new shared PK-extraction fragment (D-05/D-06) and the new mask∪exclude `ARRAY[...]::text[]` literal (D-12) — both must be single private functions called identically from all four renderers, never duplicated per-renderer.

### Config validation: raise `ArgumentError` naming the bad value, called from `normalize_table_entry/1`
**Source:** `lib/threadline/capture/redaction_policy.ex` (whole file) + `lib/threadline/capture/trigger_capture_config.ex:57-76`
**Apply to:** `validate_primary_key!/1` (D-15) — same raise style, same "run before the silently-mutating normalizer" lesson (this phase's one required divergence from the existing `normalize_columns/1`-first pattern).

### Real-PG test harness (`DataCase`, `MigrationHarness`, `Ecto.Migrator.up/4`)
**Source:** `test/support/data_case.ex`, `test/support/migration_harness.ex` (referenced, not read in full — role-match confirmed via RESEARCH.md Validation Architecture table and existing sibling test files in `test/threadline/capture/`)
**Apply to:** All new real-PG test files (`trigger_pk_shapes_test.exs`, `trigger_migrate_time_errors_test.exs`, `legacy_trigger_pk_fallback_test.exs`).

## No Analog Found

None — every file this phase touches has a same-module or same-directory sibling with the exact idiom needed. The two lowest-confidence spots (flagged above, not blocking):

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `legacy_trigger_pk_fallback_test.exs`'s pre-210 function-body fixture | test fixture | file-I/O (frozen SQL snapshot) | `test/support/legacy_trigger_sql.ex` only freezes the trigger-creation statement, not the function body being changed this phase; the plan must decide whether to extend that support file or snapshot the string a different way (see that section above) |
| `bench/pk_capture_bench.exs` exact Benchee/timing structure | utility (bench script) | batch | Not read in full per early-stopping; D-07 already specifies every design parameter in CONTEXT.md, so the remaining gap is copy-the-harness-shape, not find-the-pattern |

## Metadata

**Analog search scope:** `lib/threadline/capture/`, `lib/mix/tasks/threadline.gen.triggers.ex`, `lib/threadline/storage_schema.ex`, `test/threadline/capture/`, `test/mix/tasks/threadline/`, `test/support/`, `bench/`
**Files scanned:** `trigger_sql.ex` (647 lines, full), `trigger_capture_config.ex` (92 lines, full), `redaction_policy.ex` (72 lines, full), `storage_schema.ex` (identifier/quoting sections), `threadline.gen.triggers.ex` (lines 150-460+), `legacy_trigger_sql.ex` (71 lines, full), `gen_triggers_test.exs` (targeted greps + lines 618-687), `trigger_redaction_test.exs` (targeted grep)
**Pattern extraction date:** 2026-09-25
