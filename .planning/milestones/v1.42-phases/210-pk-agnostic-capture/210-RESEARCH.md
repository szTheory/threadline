# Phase 210: PK-Agnostic Capture - Research

**Researched:** 2026-09-25
**Domain:** PostgreSQL trigger-backed capture (PL/pgSQL), migrate-time DO blocks, Ecto migrations
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Fallback semantics: legacy and unresolvable keys (CAP-04)**
- **D-01:** "Resolve fully or store `{}`". The shared `table_pk` fragment behaves as follows:
  - **No arguments (`TG_NARGS = 0`, a trigger installed by 0.10.x):**
    - If `v_row ? 'id'`, store the byte-identical legacy `jsonb_build_object('id', v_row ->> 'id')`.
    - Otherwise store `'{}'::jsonb`. This replaces today's `{"id": null}`.
  - **With arguments:** build the key column by column from `TG_ARGV`. The key is **all or nothing**: if any `v_row ->> TG_ARGV[i]` IS NULL, set `v_table_pk := '{}'` and exit the loop. Never store a partial composite key.
  - Always end with `coalesce(v_table_pk, '{}'::jsonb)`. `table_pk` is NOT NULL, and a trigger error would abort the host write.
  - **Reversibility:** one-way. The function body is frozen into adopters' migrations.
- **D-02:** Missing column and NULL value are not distinguished per row. `->>` returns NULL for both, and PK and override columns are NOT NULL. The cause, such as a column renamed or dropped after migrate, is a per-table health concern for Phase 212 `:pk_drift`.
- **D-03:** No per-row `pg_index` slow path for legacy triggers on non-`id` tables.
  - This overrides the fallback in `.planning/research/ARCHITECTURE.md` Pattern 1.
  - The slow path measured about 2x per row, and it contradicts SC5's "trigger body contains no catalog lookup".
  - Phase verification must state explicitly that the `{"id":null}` → `{}` change affects only rows that never had a usable identity. This is not a regression of SC4.
  - Rows with a meaningful key are unchanged.
- **D-04:** Hand-offs to later phases. Record these in the plan SUMMARY so 211 and 212 pick them up:
  - Phases 211 and 212 must treat both `{}` and `{"id":null}` as "unresolved". Legacy per-table redaction functions are frozen and keep writing `{"id":null}` until they are regenerated.
  - Phase 211 read matching must use `=` equality, never `@>`, because `x @> '{}'` is true for every row. `RowKey` must never build an empty map.
  - Phase 212: a legacy no-arg trigger on a table whose PK is not exactly `(id)` is an **error-level** finding, detected from the catalog (`tgargs`, `pg_index`) rather than by scanning `audit_changes`.

**Trigger-body PK extraction and CAP-06 benchmark**
- **D-05:** Compute `v_row := to_jsonb(NEW|OLD)` **once**, then build the key with a PL/pgSQL `FOR i IN 0 .. TG_NARGS - 1 LOOP` of `jsonb_build_object(TG_ARGV[i], v_row ->> TG_ARGV[i])`. The legacy path is guarded by the explicit `TG_NARGS = 0` branch from D-01.
  - `jsonb_object_agg(unnest(TG_ARGV))` is **rejected**. It runs one SPI statement per row and measured +14–17% on INSERT/DELETE, PG 14.17.
  - The single-arg fast path is **rejected**. It gave no measurable gain and added one more branch to test.
  - A scratch benchmark measured the loop at 0.94–1.01x of the 0.10.x baseline.
- **D-06:** All four function bodies share one Elixir-generated fragment: global and per-table, each with and without `changed_from`.
  - Per-table redaction functions also read `TG_ARGV`. PK literals are never written into function bodies: that would force migrate-time `CREATE FUNCTION` and break frozen-SQL migrations.
  - Keep `v_data_after` and the other markers `RedactionPresenter.validate_threadline_shape/1` requires (`redaction_presenter.ex:~216`): `audit_transactions`, `audit_changes`, `threadline.actor_ref`, `v_data_after`, `TG_TABLE_NAME`.
  - Keep the redaction statements byte-stable, because the presenter parses them with regexes.
- **D-07:** CAP-06 benchmark: a new in-server A/B bulk benchmark, `bench/pk_capture_bench.exs`.
  - **Baseline:** a `bench/fixtures/` copy of the **0.10.2** `install_function` SQL, taken from `git show v0.10.2:lib/threadline/capture/trigger_sql.ex`. Do not use the current file, which Phase 209 already changed. Install baseline and new body as two differently named functions in the same database.
  - **Workload:** `INSERT … SELECT generate_series(1, 50k–100k)`, then UPDATE all rows, then DELETE all rows.
  - **Timing:** per-row time from `clock_timestamp()` inside the server, over 5 alternating A/B reps. Report medians.
  - **Shapes:** single bigint `id`, with the new body given `('id')` args and compared against the baseline; and a 2-column composite, run on the new body only and reported against single-PK.
  - **Sensitivity control:** a per-row `pg_index` variant must come out at about 2x. This proves the bench can see a regression.
  - **Pass bar:** for each operation, the new median is ≤ 1.10x the baseline median.
  - **Recording:** results go into a before/after table in `210-VERIFICATION.md` and a committed `bench/baselines/pk_capture_bench.md`, with commit SHA, PG version and machine, following `bench_helper.exs` `write_metadata`. Add the script to the `verify.bench` alias (`mix.exs:~217`).
  - **Not a CI gate:** shared runners are too noisy for a 10% bar.
  - `bench/audit_capture_bench.exs` must **not** serve as the reference. Round-trips dominate it, and its delete scenario never fires the trigger after the first iteration.
- **D-08:** The durable SC5 guard is a generated-SQL assertion in the default `mix test`.
  - Extract **only the function bodies**, the text between the `$threadline_trigger$`-style delimiters, from all four generators, with and without `changed_from`.
  - Refute `~r/\bpg_(index|attribute|class|namespace|constraint|trigger)\b|pg_catalog|information_schema|TG_RELID|regclass|to_reg\w+|\bEXECUTE\b/i`.
  - Also assert that the legacy branch extracts only `'id'`.
  - Migrate-time DO blocks may use the catalog, so they are excluded by scope rather than by loosening the regex.

**Migrate-time resolution and validation (CAP-03, CAP-05, CONF-01 enforcement)**
- **D-09:** Each table gets **one DO block** that resolves the key, validates it, and then runs `EXECUTE format('CREATE OR REPLACE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON <quoted qualified literal> FOR EACH ROW EXECUTE FUNCTION <quoted fn literal>(%s)', …)`.
  - The args are built with `string_agg(quote_literal(attname), ', ' ORDER BY ord)`.
  - Any `RAISE` rolls the whole migration back before a host write.
  - The existing Phase 209 `function_owner_guard` and `drop_function_if_unused` blocks stay separate and unchanged.
  - Table and function are fully quoted literals built in Elixir. Never use `regclass::text`, which drops the schema when it is on `search_path`.
  - Phase 209's ≤63-byte literal checks apply.
  - Verified on PG 14.17: `CREATE OR REPLACE TRIGGER` replaces the args of an existing no-arg trigger.
  - `ON "schema"."table"` must stay a literal inside the `format()` string so that Phase 209's rerun detection still scans it.
  - **Reversibility:** one-way. Frozen migration SQL.
- **D-10:** PK resolution from `pg_index` where `indisprimary`:
  - Take only the **first `indnkeyatts`** entries of `indkey`, so INCLUDE columns are excluded.
  - Use `unnest(indkey::int2[]) WITH ORDINALITY`, never `indkey[1]`, because the array is 0-based.
  - TG_ARGV follows PK position order.
  - Deferrable PKs are **not** refused. The immediate-index rule applies only to overrides.
- **D-11 (HIGH-IMPACT, maintainer-accepted 2026-09-25):** PK column types are checked against an **allowlist**. Any other type makes the migration `RAISE EXCEPTION` naming the column and its type.
  - **Allowed:** `int2`/`int4`/`int8`; `text`/`varchar`/`bpchar`/`citext`; `uuid`; `date`; `timestamp` (without time zone); enums (`typtype = 'e'`); and domains over these, resolved through `typbasetype`.
  - **Refused**, among others: `timestamptz`, whose text depends on the session TimeZone; `numeric`, which keeps its scale; floats; json/jsonb; arrays; bytea.
  - Consequence: a `(id, inserted_at timestamptz)` partitioned table cannot be regenerated. Its legacy trigger keeps capturing under D-01, and Phase 213's upgrade guide must say so.
  - Widening the list later is non-breaking.
  - The same allowlist applies to override columns.
  - **Reversibility:** costly. Tightening later would break adopters; widening is cheap.
- **D-12:** CAP-05, a PK column appearing in `mask` or `exclude`, is checked in **both** places:
  - **Override columns** are checked at config validation (D-15), so `mix threadline.gen.triggers` and config load fail early.
  - **Detected PK columns** are checked inside the DO block against an `ARRAY[...]::text[]` literal of the table's mask ∪ exclude columns. The literal is emitted only when the table has redaction rules, and it comes from the same config that builds the per-table function; a test pins that they agree.
  - `except_columns` overlap is harmless and is not refused.
- **D-13:** Error style follows Phase 209: a `threadline:` prefix, then MESSAGE, DETAIL and HINT.
  - **No PK and no override (CAP-03):**
    - The message names the qualified table.
    - The HINT contains a **paste-ready `config/config.exs` snippet** (`config :threadline, :trigger_capture, tables: %{"<table>" => [primary_key: [...]]}`) plus the `mix threadline.gen.triggers --tables <table>` command.
    - When a qualifying unique index already exists, the DO block fills that index's real column names into the snippet. Otherwise the HINT says to create a unique index over NOT NULL columns first.
  - **Override index mismatch:** the error names the declared columns and each unique index considered, with the reason it was disqualified: partial, deferrable, nullable column, expression, or column-set mismatch.
  - **Override on a table that has a PK:** the HINT says to remove `primary_key:` from the table's `:trigger_capture` entry, because Threadline discovers `(…)` automatically.
  - Exact wording is at Claude's discretion.

**`primary_key:` override surface (CONF-01, HIGH-IMPACT, maintainer-accepted 2026-09-25)**
- **D-14:** The override is declared **only** in config: `config :threadline, :trigger_capture, tables: %{"posts_tags" => [primary_key: ["post_id", "tag_id"]]}`.
  - There is **no `--primary-key` CLI flag**. A flag would live only in the migration, where reads can't see it, and it would be lost on regenerate.
  - Tables resolve through the existing `capture_tables_by_pair!` / `Naming.qualified` path, so `"posts_tags"` and `"public.posts_tags"` are the same table on the gen side and the read side.
  - **Reversibility:** one-way. It is published config API.
- **D-15:** Accepted value: a **non-empty list** of strings or atoms, normalized to strings.
  - Reject a bare string or atom with a "use a list, e.g. [\"code\"]" message.
  - Reject empty lists, empty names, names containing NUL, names over 63 bytes (reuse the NAME-01 identifier check), duplicates, non-lists, and overlap with `mask`/`exclude`.
  - Validate the **raw** list before `normalize_columns/1`, which silently runs `Enum.uniq` and drops blanks, so it would hide exactly these errors.
  - Validation is a private `validate_primary_key!` in `TriggerCaptureConfig.normalize_table_entry`, run after `RedactionPolicy.validate!`. It raises `ArgumentError`, which the existing gen-task rescue (`gen.triggers.ex:~286`) wraps into `Mix.raise`.
- **D-16:** Column order and comparison:
  - Declared order becomes the TG_ARGV emission order, so regenerated SQL is byte-stable.
  - **Every comparison is set equality**: the index match here, and `:pk_drift` in Phase 212. Order carries no meaning because jsonb objects are unordered.
- **D-17:** The override is emitted as a **literal array** in the table's DO block, which then:
  - skips the `pg_index` PK lookup;
  - refuses if the table already has a PK (`indisprimary`), even when the override equals it;
  - refuses a missing or dropped declared column, matched by `attname`, never by attnum;
  - refuses unless some index is `indisunique AND indisvalid AND indisready AND indimmediate AND indpred IS NULL AND indexprs IS NULL`, has no `0` in its key attnums, and its first `indnkeyatts` key columns **equal the declared set** exactly (no subset, no superset, INCLUDE columns don't count), with every column `attnotnull`;
  - then passes the declared columns as TG_ARGV.
- **D-18:** The runtime read side (Phase 211) resolves a key in this order:
  1. The `primary_key:` override for the qualified table, read through the same `TriggerCaptureConfig.load()` loader. Precedent: the redaction drift viewer already reads this config at runtime.
  2. `__schema__(:primary_key)` mapped through `field_source`.
  3. Otherwise raise.

  This phase only guarantees that the loader exposes `primary_key`. Docs and HINT snippets must say **`config/config.exs`**, not `dev.exs`/`test.exs`, or prod `history` cannot see the override.

### Claude's Discretion
- Helper names and module split in `TriggerSQL`, such as the PK fragment builder and the DO-block builder.
- The exact MESSAGE, DETAIL and HINT wording, within D-13's required content.
- Test file layout. `trigger_pk_shapes_test.exs` is named by SC1. The frozen 0.10.x SQL fixture may live under `test/support/` or `test/fixtures/`. The bench keeps its own copy because it is a separate Mix project.
- Whether to also reject unknown keys, or near-misses of `primary_key` such as `primary_keys:` or `pk:`, in table entries. It is recommended, but it must not break existing configs. A migrate-time error already catches the PK-less case.
- Whether benchmark rows are 50k or 100k, and whether the composite shape also gets a baseline comparison.
- Real-PG migration tests should run generated migrations through `Ecto.Migrator.up/4`/`down/4`, per the Phase 209 note, to prove atomicity.

### Deferred Ideas (OUT OF SCOPE)
- Widening the PK type allowlist (`timestamptz` via a fixed UTC rendering, `numeric`) is a future phase if adopters ask. Doing it would require read-side encoding parity.
- A `--primary-key` CLI flag is rejected, not deferred (D-14).
- Capture for tables with no PK and no qualifying unique index remains out of scope for the milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| CAP-01 | A table whose single-column primary key is not named `id` (integer, uuid or text) is captured with its real key in `table_pk`. | Pattern 1 (shared PK fragment) + verified TG_ARGV loop spike; test target `trigger_pk_shapes_test.exs` |
| CAP-02 | A table with a composite primary key is captured with every key column in `table_pk`, with no configuration. | Pattern 3 (D-10 `indnkeyatts`/`WITH ORDINALITY`) — verified locally against a real INCLUDE-column composite PK |
| CAP-03 | Migrating triggers for a table with no primary key and no `primary_key:` override fails at migrate time, before any host write. The message names the table and the override option. | Pattern 2 (DO block) + D-13 error-style reuse of `function_owner_guard/2`'s `threadline:`/HINT idiom |
| CAP-04 | Triggers installed before 0.11.0 keep capturing exactly as before until the adopter regenerates them. A host write never fails because of a missing or changed key; the key falls back to `{}` rather than raising. | Pattern 1 `TG_NARGS = 0` branch — verified locally; reuses `Threadline.Test.LegacyTriggerSQL` fixture harness (Phase 209) |
| CAP-05 | Configuring a primary-key column in `mask` or `exclude` is refused before any capture, with a message naming the column. | D-12 two-checkpoint design (config validation + DO-block `ARRAY[...]::text[]` literal check) |
| CAP-06 | Per-row trigger overhead after the change is measured and stays within noise of 0.10.x on the reference benchmark. It must not reintroduce a per-row catalog lookup. | D-07 benchmark design (Wave 0 gap: `bench/pk_capture_bench.exs`) + D-08 static-invariant regex test (Wave 0 gap) |
| CONF-01 | An adopter can declare `primary_key: [...]` for a table without a primary key. It is validated for empty lists, invalid names, duplicates and overlap with redaction, and enforced at migrate time against a qualifying unique index. History reads for that table use the same declared columns (capture/validation half only — read side is Phase 211). | D-14/D-15/D-16/D-17 (config surface, validation, override DO-block matching); Standard Stack table maps each decision to the exact module/function that needs to change |
</phase_requirements>

## Summary

This phase has almost no open technical questions — 210-CONTEXT.md already carries 18 maintainer-accepted decisions (D-01..D-18) with specific PG-version verifications and benchmark numbers. The research task here is narrower than usual: (1) confirm the three research-flagged spike claims against the actual local environment rather than trusting the numbers as given, (2) map the decisions onto the actual current shape of `lib/threadline/capture/trigger_sql.ex`, `trigger_capture_config.ex`, `gen.triggers.ex` and the Phase 209 test harnesses so the planner can write concrete task diffs, and (3) surface the places where CONTEXT.md's decisions require code that doesn't exist yet (the DO-block PK resolver, the `primary_key:` config key, the allowlist check) versus code that already exists and only needs a body swap (`create_trigger/3`, the four SQL renderers).

All three research-flagged spikes were reproduced locally on **PostgreSQL 14.17** (matches CONTEXT.md's "Verified on PG 14.17" citation and this repo's CI min-lane pg14 image) with a throwaway `threadline_pk_spike` database, now dropped:
- `CREATE OR REPLACE TRIGGER` on PG 14.17 does replace trigger arguments in place (`tgnargs` went 0 → 2 on the same trigger name, confirming D-09 without relying on CONTEXT.md's own claim).
- `unnest(indkey::int2[]) WITH ORDINALITY` filtered by `ord.n <= indnkeyatts` correctly excludes an `INCLUDE` column from a composite PK index (confirmed D-10's ordinality/indnkeyatts approach against a real `PRIMARY KEY (post_id, tag_id) INCLUDE (sort_order)` index).
- The D-01/D-05 all-or-nothing `TG_ARGV` loop (`FOR i IN 0 .. TG_NARGS - 1 LOOP ... IF (v_row ->> TG_ARGV[i]) IS NULL THEN v_table_pk := '{}'; EXIT; END IF ...`) behaves exactly as specified: a row with every declared column present produces the full key object, a row with any declared column NULL produces `{}`.

The TG_ARGV-loop-vs-`jsonb_object_agg` perf claim (+14–17% for the aggregate form) and the CAP-06 A/B benchmark numbers were not independently re-measured here — CONTEXT.md's D-05/D-07 already specify the benchmark design in enough detail (fixture source, workload, timing method, pass bar) that this is an execution task for the plan, not a research question.

**Primary recommendation:** Treat this phase as "wire CONTEXT.md's D-01..D-18 into the existing four-renderer `TriggerSQL` module and the existing DO-block idiom Phase 209 established," not as new design work. The planner's main job is sequencing: build the shared PK fragment and DO-block PK resolver first (they gate everything else), then the four SQL body edits, then the config validation, then the benchmark and static-invariant tests.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PK column discovery (pg_index, indnkeyatts, type allowlist) | Migrate-time DO block (generated SQL, runs once per `mix ecto.migrate`) | — | CAP-06/Pitfall 14 forbid a per-row catalog lookup; resolution must happen once, at DDL time, not in the trigger body |
| PK value extraction per row (`table_pk` write) | Capture layer (trigger body, PL/pgSQL) | — | Runs on every INSERT/UPDATE/DELETE; must be branch-free relative to today's baseline (SC5) |
| `primary_key:` override declaration | Config (`config :threadline, :trigger_capture`) | Migrate-time DO block (validates the override against the catalog) | CONTEXT.md D-14: config, not a CLI flag, so the read side (Phase 211) can see it too |
| `primary_key:` override validation (shape: non-empty list, no NUL, ≤63 bytes, no dup, no redaction overlap) | Elixir (`TriggerCaptureConfig.normalize_table_entry`) | — | Fails at `mix threadline.gen.triggers` / config-load time, before any SQL is generated (D-15) |
| PK-column-in-redaction-list rejection | Elixir (override columns, at config validation) AND migrate-time DO block (detected PK columns) | — | D-12: two different sources of PK columns need two different checkpoints; neither alone covers both |
| Legacy (0.10.x) trigger fallback semantics | Capture layer (trigger body, `TG_NARGS = 0` branch) | — | The legacy trigger's SQL is already frozen into adopters' migrations; only the *shared* global function body Phase 210 replaces can add this branch (D-01) |
| CAP-06 benchmark | Dev/bench tooling (`bench/pk_capture_bench.exs`), not CI | — | D-07: shared CI runners are too noisy for a 10% bar; benchmark is a recorded artifact, not a gate |
| `:pk_drift` / legacy-trigger health findings | Out of scope — Phase 212 | Capture layer emits the catalog facts (`tgargs`) Phase 212 reads | D-04: this phase only needs to leave `tgargs` in a shape Phase 212 can compare against `pg_index` |
| Read-side `RowKey`, `history`/`as_of` PK matching | Out of scope — Phase 211 | Capture layer (`table_pk` encoding) is what Phase 211 depends on | D-18 lists the read-order Phase 211 will implement; this phase only guarantees the config loader exposes `primary_key` |

## Standard Stack

No new dependencies. This phase is entirely PL/pgSQL generated by Elixir string-building code plus Ecto migration plumbing that already exists in this codebase (`Threadline.Capture.TriggerSQL`, `Threadline.Capture.Naming`, `Threadline.StorageSchema`, `Threadline.Capture.RedactionPolicy`, `Threadline.Capture.TriggerCaptureConfig`, `Mix.Tasks.Threadline.Gen.Triggers`).

### Core (existing, modified by this phase)
| Module | Current role | Phase 210 change |
|--------|--------------|-------------------|
| `Threadline.Capture.TriggerSQL` | Four PL/pgSQL body renderers (`global_install_function_sql_legacy/1`, `per_table_install_sql_legacy/3`, `per_table_install_sql_redacted/7`, `global_capture_function_sql_redacted/4`) plus `create_trigger/3` (currently emits a plain `CREATE OR REPLACE TRIGGER ... FUNCTION x()` with no args) | Replace all 12 sites of `jsonb_build_object('id', to_jsonb(NEW\|OLD) ->> 'id')` (lines 275, 280, 286, 340, 346, 352, 432, 438, 445, 489, 494, 501) with the shared D-05 PK fragment; replace `create_trigger_sql/2`'s plain `CREATE OR REPLACE TRIGGER` with the D-09 DO block |
| `Threadline.Capture.TriggerCaptureConfig` | `normalize_table_entry/1` already handles `:exclude`, `:mask`, `:mask_placeholder`, `:store_changed_from`, `:except_columns` via `put_if_present` + `normalize_columns/1` | Add `primary_key:` handling — CONTEXT.md D-15 requires validating the **raw** list *before* `normalize_columns/1` runs (that function silently `Enum.uniq`s and drops blanks, hiding exactly the errors D-15 requires) |
| `Threadline.Capture.RedactionPolicy` | `validate!/1` checks exclude/mask overlap and placeholder shape | D-12 requires an override-column vs. mask/exclude overlap check too — likely a new `validate_primary_key!` in `TriggerCaptureConfig` calling into or alongside `RedactionPolicy.validate!` (D-15 says "run after `RedactionPolicy.validate!`") |
| `Threadline.Capture.Naming` + `Threadline.StorageSchema.validate_identifier!/3` | Identifier validation (regex `^[A-Za-z_][A-Za-z0-9_]*$`, ≤63 bytes) already exists and is reused by D-15's "reuse the NAME-01 identifier check" | No change — reuse as-is for override column names |
| `Mix.Tasks.Threadline.Gen.Triggers` | `capture_tables_by_pair!/1`, config-error rescue at line ~286 (`rescue e in ArgumentError -> Mix.raise(...)`) | The new `primary_key:` validation raising `ArgumentError` is automatically wrapped into `Mix.raise` by the existing rescue pattern — no gen-task change needed for that error path, but `build_table_capture_spec/4` needs a `primary_key` branch to pass the override into `TriggerSQL.create_trigger/3` |

### Package Legitimacy Audit

Not applicable — no new packages (npm/pip/cargo/hex) are introduced by this phase. All work is PL/pgSQL string generation and Elixir standard library / existing internal modules.

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────── generation time (mix threadline.gen.triggers, no DB PK facts) ───────────────┐
│  gen.triggers.ex                                                                              │
│    reads config :threadline, :trigger_capture, tables: %{"t" => [primary_key: [...]]}         │
│    -> TriggerCaptureConfig.load() -> normalize_table_entry (NEW: primary_key validation)      │
│    -> TriggerSQL.create_trigger(table, mode, primary_key: override_or_nil)                    │
│         emits ONE literal array (if override) or nothing (if not) into the DO block text      │
└───────────────────────────────────────────┬───────────────────────────────────────────────────┘
                                             │ frozen .exs migration file (text, committed to host repo)
┌──────────────── migrate time (mix ecto.migrate, runs the DO block once) ─────────────────────┴┐
│  DO block (NEW, one per table, replaces plain create_trigger_sql/2):                          │
│    IF override given:                                                                          │
│      refuse if table already has indisprimary PK                                               │
│      refuse if any declared column missing (by attname)                                         │
│      refuse unless a matching unique/immediate/non-partial/NOT-NULL index exists (set equality) │
│    ELSE:                                                                                         │
│      SELECT pg_index WHERE indisprimary; take first indnkeyatts entries via                     │
│        unnest(indkey::int2[]) WITH ORDINALITY, ORDER BY ordinality                              │
│      refuse (RAISE EXCEPTION, table+option named, paste-ready HINT) if no PK found              │
│      refuse if any PK column type is outside the D-11 allowlist                                 │
│      refuse if any PK/override column is in mask ∪ exclude (ARRAY[...]::text[] literal)         │
│    EXECUTE format('CREATE OR REPLACE TRIGGER %I AFTER ... FOR EACH ROW EXECUTE FUNCTION          │
│                     <fn>(%s)', trigger_name, string_agg(quote_literal(attname), ', '))          │
│  A RAISE anywhere rolls the whole migration back — no host write ever happens against a          │
│  half-resolved PK.                                                                               │
└───────────────────────────────────────────┬───────────────────────────────────────────────────┘
┌──────────────── write time (trigger body, every INSERT/UPDATE/DELETE) ───────────────────────┴┐
│  v_row := to_jsonb(NEW|OLD)    -- computed ONCE, reused for PK + data_after + diff              │
│  IF TG_NARGS = 0 THEN            -- legacy (pre-0.11 install, no regenerate yet)                │
│    v_table_pk := v_row ? 'id' ? jsonb_build_object('id', v_row->>'id') : '{}'::jsonb            │
│  ELSE                            -- regenerated trigger, D-09/D-10/D-17 resolved the columns    │
│    FOR i IN 0..TG_NARGS-1 LOOP                                                                  │
│      IF (v_row ->> TG_ARGV[i]) IS NULL THEN v_table_pk := '{}'::jsonb; EXIT; END IF;            │
│      v_table_pk := coalesce(v_table_pk,'{}') || jsonb_build_object(TG_ARGV[i], v_row->>TG_ARGV[i]);│
│    END LOOP;                                                                                     │
│  END IF;                                                                                          │
│  -- always: coalesce(v_table_pk, '{}'::jsonb) before INSERT INTO audit_changes                  │
│  -- no pg_catalog, no EXECUTE, no TG_RELID lookup anywhere in this block (SC5 regex gate)        │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

No new top-level modules are implied by CONTEXT.md beyond what already exists. Likely internal split within `lib/threadline/capture/trigger_sql.ex` (Claude's Discretion per CONTEXT.md):

```
lib/threadline/capture/
├── trigger_sql.ex            # existing; four renderers gain the shared PK fragment,
│                              #   create_trigger/3 becomes the DO-block builder
├── trigger_capture_config.ex # existing; gains validate_primary_key!/1
├── redaction_policy.ex       # existing; unchanged (D-15 calls it a stage, not a change)
└── naming.ex                 # existing; unchanged, reused for override column identifier checks
```

### Pattern 1: Shared PK-extraction fragment, single source across four renderers

**What:** One Elixir-generated PL/pgSQL fragment (function or private helper returning a string) implementing the `TG_NARGS = 0` legacy branch plus the `TG_ARGV` loop, interpolated into all four SQL bodies (`global_install_function_sql_legacy`, `per_table_install_sql_legacy`, `per_table_install_sql_redacted`, `global_capture_function_sql_redacted`) at their DELETE/INSERT/UPDATE branches, replacing today's 12 call sites of `jsonb_build_object('id', to_jsonb(NEW|OLD) ->> 'id')`.

**When to use:** Every capture-function body, with and without `changed_from`.

**Verified-locally example (PL/pgSQL, confirmed on PG 14.17):**
```sql
-- Source: local spike, threadline_pk_spike DB, 2026-09-25 (see Summary)
v_row := to_jsonb(NEW);                          -- or OLD, once per branch
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
Local spike output: a two-arg trigger (`'code','opt_col'`) inserting a row with `opt_col = NULL` produced `table_pk={}` (NOTICE observed); a row with both columns present produced the full two-key object. This matches D-01's "all or nothing" requirement exactly.

### Pattern 2: Migrate-time DO block replaces `create_trigger_sql/2`'s plain statement

**What:** `create_trigger/3`'s private `create_trigger_sql/2` (trigger_sql.ex:230-239) currently returns a bare `CREATE OR REPLACE TRIGGER ... FOR EACH ROW EXECUTE FUNCTION #{function_invocation}` string with no argument list. D-09 replaces this with a `DO $$ ... EXECUTE format('CREATE OR REPLACE TRIGGER %I ... FUNCTION %s(%s)', ...) $$;` block that resolves PK columns (or validates the override) before installing the trigger.

**When to use:** Both `:default` and `:per_table` modes — the DO block is orthogonal to which function the trigger calls.

**Verified-locally example (PL/pgSQL, confirmed on PG 14.17):**
```sql
-- Source: local spike, confirms D-09's "CREATE OR REPLACE TRIGGER replaces args of an
-- existing no-arg trigger" against the exact PG version cited in CONTEXT.md
CREATE OR REPLACE TRIGGER spike_trg
AFTER INSERT ON spike_t
FOR EACH ROW EXECUTE FUNCTION spike_fn();          -- tgnargs=0, tgargs=\x (empty) after this

CREATE OR REPLACE TRIGGER spike_trg
AFTER INSERT ON spike_t
FOR EACH ROW EXECUTE FUNCTION spike_fn('id', 'v');  -- tgnargs=2, tgargs=\x6964007600 after this
```
`pg_trigger.tgargs` is a `bytea` of NUL-separated argument strings; the second call's `\x6964007600` decodes to `"id\0v\0"`, confirming the replace-in-place semantics D-09 depends on.

### Pattern 3: PK column discovery excluding INCLUDE columns

**What:** `pg_index.indnkeyatts` gives the count of true key columns (excluding any `INCLUDE` columns appended to `indkey`). D-10 requires taking only the first `indnkeyatts` entries via `unnest(indkey::int2[]) WITH ORDINALITY`, filtering `ord.n <= indnkeyatts`, never indexing `indkey[1]` (0-based array pitfall).

**Verified-locally example (confirmed on PG 14.17, against a real `PRIMARY KEY (post_id, tag_id) INCLUDE (sort_order)`):**
```sql
-- Source: local spike, threadline_pk_spike DB, 2026-09-25
SELECT i.indnkeyatts, i.indkey, array_agg(a.attname ORDER BY ord.n)
FROM pg_index i
JOIN pg_class c ON c.oid = i.indrelid
CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS ord(attnum, n)
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = ord.attnum
WHERE c.relname = 'posts_tags' AND i.indisprimary AND ord.n <= i.indnkeyatts
GROUP BY i.indnkeyatts, i.indkey;
-- result: indnkeyatts=2 | indkey="1 2 3" | array_agg={post_id,tag_id}
-- sort_order (attnum 3, the INCLUDE column) is correctly excluded.
```

### Pattern 4: Frozen migration SQL — one-way decisions

**What:** Every DO block and PL/pgSQL fragment emitted here is copied byte-for-byte into an adopter's committed migration file. This is Phase 209's established idiom (`function_owner_guard/2`, `drop_function_if_unused/2` are already frozen DO blocks) and CONTEXT.md explicitly marks D-01, D-09, D-14, D-11 as "Reversibility: one-way" or "costly."

**When to use:** Any change to the generated SQL text — including whitespace-insignificant changes to variable names inside a DO block — should be treated as a compatibility decision, not a refactor, once any adopter has run `mix ecto.migrate` against it. Within this phase (pre-release), this constraint matters mainly for how tests are structured: fixture SQL (`test/support/legacy_trigger_sql.ex`) must never be regenerated from current code, only hand-frozen once.

### Anti-Patterns to Avoid

- **Per-row `pg_index` lookup in the trigger body (any table shape):** D-03 explicitly overrides ARCHITECTURE.md Pattern 1's per-row slow-path fallback for legacy triggers on non-`id` tables. Measured ~2x per-row cost (both in `.planning/research/ARCHITECTURE.md` "Headline findings" #2 and independently in the Performance Traps table of `PITFALLS.md`). SC5 also gates on a static regex that forbids `pg_index|pg_attribute|pg_class|pg_namespace|pg_constraint|pg_trigger|pg_catalog|information_schema|TG_RELID|regclass|to_reg\w+|EXECUTE` appearing anywhere inside the four function bodies' delimited text.
- **`jsonb_object_agg(unnest(TG_ARGV))` instead of the explicit loop:** D-05 measured +14–17% on INSERT/DELETE (PG 14.17) because it runs one SPI statement per row versus the loop's zero.
- **Single-arg fast path (`TG_NARGS = 1` special case):** D-05 rejects this — no measurable gain, adds a branch to test.
- **`->>`  distinguishing missing-column vs. NULL-value:** D-02 — both return SQL NULL, so `table_pk` cannot and does not distinguish them. This is intentional; don't add code to disambiguate (that's Phase 212's `:pk_drift` job, from the catalog, not from `audit_changes` rows).
- **`regclass::text` for the qualified table literal in the DO block:** D-09 explicitly forbids this — it drops the schema qualifier when the schema is on `search_path`, breaking rerun detection's `ON` clause text scan (Phase 209).
- **Baking PK column names as literals directly into `CREATE FUNCTION` text:** D-06 forbids this — it would force migrate-time `CREATE FUNCTION` (function bodies must stay static across tables so a rerun's frozen-SQL comparison and the redaction presenter's regex parsing keep working). PK columns travel only as `TG_ARGV`, read inside a shared, table-agnostic function body.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting a table's real primary key at DDL time | A custom Elixir-side schema introspection via `Ecto.Adapters.SQL.query!` at **generation** time | A DO block querying `pg_index`/`pg_attribute` at **migrate** time, inside the migration itself | Generation-time introspection needs a live DB connection matching the target environment and freezes dev's schema into a migration that may run against a different staging/prod schema (`PITFALLS.md` Pitfall 14) |
| Validating a unique index qualifies as a natural key | Hand-rolled boolean checks scattered across the DO block | One conjunctive `WHERE` clause against `pg_index`: `indisunique AND indisvalid AND indisready AND indimmediate AND indpred IS NULL AND indexprs IS NULL`, no `0` in key attnums, every key column `attnotnull` (D-17) | REPLICA IDENTITY's own rules for what makes a valid natural key already encode exactly this; reinventing it risks accepting a partial or deferrable index that silently produces wrong `table_pk` data |
| Column-order-independent comparison of the override vs. an index's columns | String-joining sorted column lists and comparing text | Set equality via `MapSet`/array containment both ways (D-16) — declared order is preserved separately for TG_ARGV emission order, only comparison uses sets | jsonb objects (and hence `table_pk` matching in Phase 211/212) are unordered; conflating "same columns" with "same order" would falsely reject a valid override whose declared order doesn't match the index's storage order |

**Key insight:** Every "clever" shortcut this phase considered and rejected (runtime catalog lookup, `jsonb_object_agg`, baked literals, generation-time introspection) was rejected because it violates one of the phase's three hard constraints (no per-row cost / don't break 0.10.x / never fail the host write) — not because a library exists to replace it. There is no external library for this domain; the "don't hand-roll" discipline here is about staying inside PostgreSQL's own catalog and REPLICA IDENTITY semantics rather than re-deriving equivalent logic ad hoc.

## Runtime State Inventory

Not applicable — this is not a rename/refactor/migration-of-strings phase. It adds new trigger-body logic and a new config key; it does not rename any existing identifier, database, or stored value. (The one existing-data effect — pre-0.11 `{"id": null}` rows are unaffected by this phase's code; only *new* writes to legacy no-arg triggers get `{}` instead — is a write-time behavior change, not a runtime-state migration, and CONTEXT.md D-03 already documents it belongs in phase verification language, not a migration task.)

## Common Pitfalls

### Pitfall 1: Conflating "missing column" with "NULL value" when debugging `{}` results
**What goes wrong:** A developer sees `table_pk = {}` for a row and assumes the PK columns are misconfigured, when actually one declared column legitimately holds NULL (e.g., a nullable secondary column mistakenly included in an override).
**Why it happens:** `->>` returns SQL NULL for both a missing key and a NULL value (D-02); the trigger body cannot and must not try to tell them apart.
**How to avoid:** Rely on the migrate-time validation (D-17: override columns must be `attnotnull`) to make "declared PK column is nullable" impossible for overrides at install time. For the legacy branch and drift after a schema change, this is explicitly Phase 212's `:pk_drift` job — the plan should not add ad-hoc debugging aids here.
**Warning signs:** `table_pk = {}` rows appearing on a table that has a PK — this is a Phase 212 concern, but the phase 210 plan's tests should include a real-PG case (`RENAME COLUMN` after trigger install per CONTEXT.md's specific-ideas list) proving the write still succeeds rather than raising.

### Pitfall 2: Regressing SC4 by conflating `{"id":null}` removal with a general fallback change
**What goes wrong:** A test author might assert that "no row should ever get `{"id":null}`" broadly, breaking legacy triggers that have a real `id` column and correctly keep storing `jsonb_build_object('id', ...)`.
**Why it happens:** The D-01 change is narrow — only the *shape* of the "unresolvable" sentinel changes (`{"id":null}` → `{}`), and only for legacy (`TG_NARGS = 0`) triggers on tables where `v_row ? 'id'` is false. A legacy trigger on an `id`-keyed table is byte-identical to before.
**How to avoid:** Test both cases explicitly: (a) frozen 0.9/0.10.x SQL on an `id` table stores identical output to before, (b) frozen 0.9/0.10.x SQL on a non-`id`-keyed table (e.g., a `uuid code` PK) stores `{}` not `{"id":null}`. CONTEXT.md's "Specific Ideas" section already lists both as required real-PG tests.
**Warning signs:** Any test asserting global absence of `id` PK behavior instead of the narrow legacy-non-id-table case.

### Pitfall 3: `@>` used anywhere in this phase's code or tests for `table_pk` matching
**What goes wrong:** `x @> '{}'` is true for **every** jsonb value `x`, so any equality check written with `@>` against an empty-object sentinel would match every row in the table, not just unresolved ones.
**Why it happens:** `@>` (containment) is the historical operator used elsewhere in the codebase for `table_pk` matching (`lib/threadline/query.ex`), and it's the "obvious" choice for partial-match semantics.
**How to avoid:** D-04 is explicit: "Phase 211 read matching must use `=` equality, never `@>`." This phase (210) does not itself do PK matching (that's Phase 211/212), but any capture-layer test written here that checks "is this table_pk resolved" must also use `=` or a length/emptiness check (`v_table_pk = '{}'::jsonb`), never `@>`, to avoid writing a test helper that would mislead Phase 211/212 authors who copy it.
**Warning signs:** Any `@>` in phase 210's own test assertions against `table_pk`.

### Pitfall 4: PK type allowlist gaps silently downgrading capture instead of failing loud
**What goes wrong:** A table with a `timestamptz` or `numeric` PK column (D-11: explicitly refused) needs its *legacy* trigger to keep working (D-01's `TG_NARGS = 0` branch), which only checks `v_row ? 'id'` — it has no type awareness at all. If someone later "fixes" the legacy branch to also validate types, capture would silently stop working on tables that were fine before.
**Why it happens:** The type allowlist (D-11) is a **migrate-time** gate on the DO block, not a **write-time** gate on the trigger body. The trigger body has no type introspection whatsoever — it works on any type because `->>` always coerces to text.
**How to avoid:** Keep the allowlist check exclusively inside the DO block (`RAISE EXCEPTION` naming the column and type per D-11); never let it leak into the shared PL/pgSQL fragment from Pattern 1, which must remain type-agnostic.
**Warning signs:** Any type-checking logic appearing inside `global_install_function_sql_legacy` / the four renderer bodies rather than in the DO block.

### Pitfall 5: Static SC5 regex over the wrong text span
**What goes wrong:** D-08's regex (`\bpg_(index|attribute|class|namespace|constraint|trigger)\b|pg_catalog|information_schema|TG_RELID|regclass|to_reg\w+|\bEXECUTE\b`) is meant to scan **only the function body text** between the `$threadline_trigger$` delimiters — but the DO block (migrate-time PK resolution) legitimately contains all of those tokens (`pg_index`, `to_regclass`, `EXECUTE format(...)`). Running the regex over the whole generated migration file (DO block included) would produce a false failure.
**Why it happens:** Both the trigger-body SQL and the DO-block SQL are generated by the same module and may end up concatenated in test fixtures or migration output.
**How to avoid:** D-08 is explicit that the extraction must isolate "only the function bodies, the text between the `$threadline_trigger$`-style delimiters" — write the extraction regex/parse to anchor on those delimiters specifically, and exclude everything else by scope rather than trying to loosen the forbidden-token regex.
**Warning signs:** A static-invariant test failing on `EXECUTE` inside a DO block, or (worse) silently passing because the extraction accidentally captured nothing.

## Code Examples

### Verified: composite PK excluding INCLUDE columns (D-10)
```sql
-- Source: local spike against real PG 14.17, 2026-09-25 (see Summary and Pattern 3)
CREATE TABLE posts_tags (
  post_id bigint NOT NULL,
  tag_id  bigint NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  CONSTRAINT posts_tags_pkey PRIMARY KEY (post_id, tag_id) INCLUDE (sort_order)
);
-- pg_index.indnkeyatts = 2, indkey = "1 2 3" (3 entries: PK cols + 1 INCLUDE col)
-- filtering unnest(...) WITH ORDINALITY by ord.n <= indnkeyatts correctly returns
-- only {post_id, tag_id}, in PK-declaration order.
```

### Verified: trigger argument replacement in place (D-09)
```sql
-- Source: local spike against real PG 14.17, 2026-09-25 (see Pattern 2)
-- tgnargs=0 before; tgnargs=2 (tgargs decodes to "id\0v\0") after re-running
-- CREATE OR REPLACE TRIGGER with a non-empty argument list on the same trigger name.
```

### Verified: all-or-nothing TG_ARGV loop (D-01/D-05)
```sql
-- Source: local spike against real PG 14.17, 2026-09-25 (see Pattern 1)
-- Two-column trigger args ('code', 'opt_col'); row with opt_col NULL -> table_pk={};
-- row with both present -> table_pk={"code":"abc","opt_col":"present"}.
```

### Existing pattern this phase reuses verbatim: DO-block guard style (Phase 209)
```elixir
# Source: lib/threadline/capture/trigger_sql.ex:168-195 (function_owner_guard/2, unchanged by this phase)
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
    ...
  BEGIN
    ...
    IF others IS NOT NULL THEN
      RAISE EXCEPTION 'threadline: ...'
        USING HINT = format('...');
    END IF;
  END $$;
  """
end
```
This is the exact `threadline:` MESSAGE/DETAIL/HINT idiom D-13 requires the new DO block to follow — the planner should point tasks at this function as the literal template for the new PK-resolution DO block, not describe it from scratch.

## State of the Art

| Old Approach (0.10.x, current code) | New Approach (this phase) | When Changed | Impact |
|--------------------------------------|----------------------------|---------------|--------|
| `jsonb_build_object('id', to_jsonb(NEW\|OLD) ->> 'id')` hardcoded at 12 sites | Shared PL/pgSQL fragment: `TG_NARGS = 0` legacy branch + `TG_ARGV` loop | This phase | Any table's real PK is captured, not just `id`; legacy installs unaffected until regenerated |
| `create_trigger_sql/2` emits a bare `CREATE OR REPLACE TRIGGER ... FUNCTION f()` (no args) | DO block resolves PK (or validates override) at migrate time, then `EXECUTE format(...)` with `%s` args | This phase | Trigger arguments carry the resolved PK columns; migrate-time failure instead of silent `{"id":null}` |
| No `primary_key:` config key exists | `config :threadline, :trigger_capture, tables: %{"t" => [primary_key: [...]]}}`, validated in `TriggerCaptureConfig` | This phase | PK-less tables (Phoenix join tables) become capturable without a CLI flag |
| ARCHITECTURE.md Pattern 1's original fallback: per-row `pg_index` lookup when `TG_ARGV` is absent | D-03 explicitly forbids this; legacy fallback is `TG_NARGS = 0` branch only, no catalog lookup ever | Decided during discuss-phase (2026-09-25), before this research | ~2x per-row cost avoided; SC5 depends on this |

**Deprecated/outdated:**
- The "runtime `pg_index` lookup per row" idea documented in `.planning/research/ARCHITECTURE.md` Pattern 1 and `PITFALLS.md` Pitfall 6's "How to avoid" bullet ("Look up PK columns at run time... If the cost is unacceptable, bake the key in with TG_ARGV") is superseded by D-03/D-09: the milestone research left this as a fallback option, but CONTEXT.md's maintainer-accepted decisions closed it off entirely — there is no runtime lookup fallback in this phase's design.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The D-05 perf numbers for `jsonb_object_agg(unnest(TG_ARGV))` (+14–17% on INSERT/DELETE, PG 14.17) and the D-07 CAP-06 benchmark's specific pass/fail numbers were not independently re-measured in this research session — they are taken as already-verified from CONTEXT.md's own "maintainer-accepted 2026-09-25" spike work | Summary, Anti-Patterns | Low: CONTEXT.md's benchmark design (D-07) is itself the phase's own verification step, executed and recorded during plan execution, not assumed at research time — any drift shows up in the phase's own `bench/pk_capture_bench.exs` run, not silently |
| A2 | The exact module/function split for the shared PK fragment and DO-block builder inside `trigger_sql.ex` is left to "Claude's Discretion" per CONTEXT.md, and this research assumes a private-function split within the existing module (no new module file) is the lowest-risk choice, since it matches how `function_owner_guard/2` and `drop_function_if_unused/2` are already organized | Recommended Project Structure | Low: purely a code-organization choice with no external contract; a planner or executor moving these into a new file is a trivial follow-up, not a behavior risk |

**If this table is empty:** N/A — two low-risk assumptions logged above; neither requires user confirmation before planning proceeds, since both are execution-detail assumptions already scoped as "Claude's Discretion" in the locked CONTEXT.md.

## Open Questions

1. **Exact wording of the four DO-block error messages (D-13)**
   - What we know: CONTEXT.md D-13 fixes the required *content* (table name, `primary_key:` option, paste-ready `config/config.exs` snippet, `mix threadline.gen.triggers --tables <table>` command, per-index disqualification reasons) and the `threadline:` MESSAGE/DETAIL/HINT format Phase 209 established.
   - What's unclear: The literal string templates aren't written yet.
   - Recommendation: Leave to the plan/execution step, following the `function_owner_guard/2` template verbatim for structure (see Code Examples). Not a planning blocker.

2. **Whether the composite-PK benchmark shape (D-07 "2-column composite, run on the new body only") needs its own committed baseline row or just a comparison against the single-PK number**
   - What we know: D-07 says "run on the new body only, reported against single-PK" — i.e., no separate 0.10.x baseline exists for composite keys (0.10.x never supported them correctly).
   - What's unclear: Exact `bench/baselines/pk_capture_bench.md` table shape for this row.
   - Recommendation: Follow `bench_helper.exs`'s existing `write_metadata` pattern (commit SHA, PG version, machine) and format the composite row as "vs. single-PK new-body" rather than "vs. 0.10.x baseline" — this is an execution-time formatting detail, not a design question.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | All capture/migration work, real-PG tests | ✓ | 14.17 (Homebrew, local) | — |
| PostgreSQL 16 (CI current lane) | CI matrix parity (`.github/workflows/ci.yml`: min lane pg14/elixir 1.15/otp26/ubuntu-22.04, current lane pg16/elixir 1.17.3/otp27/ubuntu-24.04) | Not probed locally (no local PG16 instance) | — | CI itself provides PG16 coverage; local spikes here used PG14.17 only, matching CONTEXT.md's own D-09 citation |
| Elixir / OTP / Node (`.tool-versions`) | Compiling and running `mix` tasks/tests | ✓ | elixir 1.17.3-otp-27, erlang 27.3.4.15, nodejs 22.14.0 | — |
| `bench/` Mix project (separate from root, per `mix.exs verify.bench` alias) | CAP-06 benchmark (D-07) | ✓ (existing `bench/bench_helper.exs`, `bench/audit_capture_bench.exs` pattern to follow) | — | — |

**Missing dependencies with no fallback:** None — everything the phase needs is already present in the dev environment.

**Missing dependencies with fallback:** PG16 was not locally probed; CI's own matrix (already configured, unchanged by this phase) provides that coverage, so no local fallback action is needed.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (existing), real-PG `DataCase`-style tests per Phase 209 patterns (`Threadline.Test.Repo`, `Threadline.Test.MigrationHarness`, `Threadline.Test.LegacyTriggerSQL`) |
| Config file | `config/test.exs` (existing; `hostname: DB_HOST env or localhost`, `database: threadline_test`) |
| Quick run command | `mix test test/threadline/capture/trigger_pk_shapes_test.exs` |
| Full suite command | `mix verify.test` (part of `mix ci.all`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CAP-01 | Non-`id` int/uuid/text single-column PK captured with real key | real-PG unit | `mix test test/threadline/capture/trigger_pk_shapes_test.exs` | ❌ Wave 0 (named by SC1) |
| CAP-02 | Composite PK (incl. INCLUDE-column index) captured with every key column, no config | real-PG unit | `mix test test/threadline/capture/trigger_pk_shapes_test.exs` | ❌ Wave 0 (same file, additional cases) |
| CAP-03 | No PK + no override fails at migrate time, names table + option | real-PG migration | `mix test test/threadline/capture/trigger_migrate_time_errors_test.exs` (or similar; name at Claude's discretion) | ❌ Wave 0 |
| CAP-04 | Legacy (pre-0.11) trigger keeps capturing; unresolvable key stores `{}` not a raised error | real-PG (frozen SQL fixture) | `mix test test/threadline/capture/legacy_trigger_pk_fallback_test.exs` (reuses `Threadline.Test.LegacyTriggerSQL`) | ❌ Wave 0 — but `test/support/legacy_trigger_sql.ex` fixture helper already exists (Phase 209) |
| CAP-05 | PK column in mask/exclude refused before capture, names the column | unit (config validation) + real-PG migration | `mix test test/threadline/capture/trigger_capture_config_test.exs` and a migrate-time test | Config test file likely exists already (extend); migrate-time test ❌ Wave 0 |
| CAP-06 | Per-row overhead within noise of 0.10.x baseline; no catalog lookup in trigger body | benchmark (not CI-gated) + static-invariant unit test | `mix run bench/pk_capture_bench.exs` (manual/dev, recorded) + `mix test` (static regex assertion, D-08) | Benchmark script ❌ Wave 0 (new file); static-invariant test ❌ Wave 0 |
| CONF-01 (capture/validation half) | `primary_key:` config validated (empty/invalid/dup/overlap rejected), enforced at migrate time against qualifying index | unit (config) + real-PG migration | `mix test test/threadline/capture/trigger_capture_config_test.exs` + migration test | ❌ Wave 0 for the `primary_key` validation cases specifically |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/capture/` (scoped to this phase's new/changed files)
- **Per wave merge:** `mix verify.test` (full suite, matches Phase 209's gate discipline)
- **Phase gate:** `mix ci.all` green (format, credo, test, dialyzer, browser lane per Phase 209's own gate) before `/gsd-verify-work`; `mix verify.bench` run and results recorded per D-07 (not a CI gate, but a required phase-verification artifact)

### Wave 0 Gaps
- [ ] `test/threadline/capture/trigger_pk_shapes_test.exs` — covers CAP-01, CAP-02 (named explicitly by SC1)
- [ ] A migrate-time error test file (name at Claude's discretion) — covers CAP-03, CAP-05 (migrate-time half), CONF-01 (migrate-time half)
- [ ] Extension of the existing legacy-regeneration test pattern (`test/threadline/capture/legacy_trigger_regeneration_test.exs`, Phase 209) or a new file — covers CAP-04, reusing `Threadline.Test.LegacyTriggerSQL` (already has `v0_9_create_trigger/2`, `v0_10_0_create_trigger/3`, `v0_10_2_create_trigger/3` — no new historical-form fixture needed, but a uuid/text-PK table fixture is new)
- [ ] `bench/pk_capture_bench.exs` — new benchmark file per D-07, following `bench/audit_capture_bench.exs`'s `Bench.Helper.setup()` / `Benchee.run` pattern; needs a `bench/fixtures/` copy of the 0.10.2 `install_function` SQL from `git show v0.10.2:lib/threadline/capture/trigger_sql.ex` (D-07 explicitly forbids using the current, already-Phase-209-changed file)
- [ ] A static-invariant test (D-08) extracting only the text between `$threadline_trigger$` delimiters from all four generators (with/without `changed_from`) and asserting the forbidden-token regex — likely extends the existing "generated SQL invariants" describe block added in 209-06 (`test/mix/tasks/threadline/gen_triggers_test.exs` or wherever that lives)
- [ ] Config-validation test coverage for `primary_key:` in `TriggerCaptureConfig` — extend existing config test file with D-15's specific rejection cases (bare string/atom, empty list, empty name, NUL, >63 bytes, duplicates, non-list, mask/exclude overlap)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Out of scope — capture layer has no auth surface |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Yes | Every identifier this phase writes into generated SQL (override PK column names) goes through `StorageSchema.validate_identifier!/3` (existing, regex `^[A-Za-z_][A-Za-z0-9_]*$`, ≤63 bytes) before interpolation — never raw string concatenation of user config into SQL without validation |
| V6 Cryptography | No | — |
| V11 (Business logic/DB) — SQL injection via generated migrations | Yes | Table/column/function names are validated identifiers, then quoted via `StorageSchema.quote_ident/1` or embedded through `format('%I', ...)`/`quote_literal(...)` inside the DO block (never raw string interpolation of a config value into `EXECUTE`) — this is the exact discipline Phase 209's `function_owner_guard/2` and `drop_function_if_unused/2` already established and this phase must follow verbatim |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Adopter-controlled `primary_key:` column names reaching raw SQL text | Tampering | `StorageSchema.validate_identifier!/3` (regex + byte-length) before any interpolation; D-15 requires this validation to run on the config value at load/gen time, not deferred to the DO block |
| A migration silently capturing the wrong table's data via name collision (redaction rule crossover) | Tampering, Information Disclosure | Not new to this phase — Phase 209's `function_owner_guard/2` already guards this; this phase's DO block must not bypass or duplicate that guard, just compose with it in the same migration |
| A crafted mask/exclude config allowing a PK column to be redacted, silently corrupting `table_pk`-based history lookups | Tampering, Repudiation (audit-trail integrity) | D-12's two-checkpoint overlap check (config-validation for overrides, DO-block `ARRAY[...]::text[]` literal check for detected PK columns) — this is itself the security control; a gap here would let an adopter accidentally destroy row-identity in their own audit trail |
| A trigger error aborting a host write (denial of the host's own transaction) | Denial of Service | D-01's `coalesce(v_table_pk, '{}'::jsonb)` and the "resolve fully or store `{}`" all-or-nothing rule — `audit_changes.table_pk` is `NOT NULL`, so any code path that could produce SQL NULL for it would abort the host's INSERT/UPDATE/DELETE; this is the single highest-severity failure mode named in `PITFALLS.md` Pitfall 6 ("An audit library taking down a production INSERT is the worst failure this domain has") |

## Sources

### Primary (HIGH confidence)
- Local PostgreSQL 14.17 spike (`threadline_pk_spike` database, created and dropped this session) — `CREATE OR REPLACE TRIGGER` argument replacement, `pg_index`/`indnkeyatts`/`WITH ORDINALITY` composite-PK-with-INCLUDE resolution, and the D-01/D-05 all-or-nothing TG_ARGV loop, all reproduced directly against real PG rather than taken on citation.
- `/Users/<user>/projects/threadline/lib/threadline/capture/trigger_sql.ex` (read in full this session) — current shape of all four SQL renderers, `create_trigger/3`, `function_owner_guard/2`, `drop_function_if_unused/2`.
- `/Users/<user>/projects/threadline/lib/threadline/capture/trigger_capture_config.ex`, `redaction_policy.ex`, `naming.ex`, `/Users/<user>/projects/threadline/lib/mix/tasks/threadline.gen.triggers.ex`, `/Users/<user>/projects/threadline/lib/threadline/storage_schema.ex` (all read in full this session).
- `/Users/<user>/projects/threadline/test/support/legacy_trigger_sql.ex`, `test/support/migration_harness.ex` (read in full this session) — existing real-PG test harness patterns this phase's tests should reuse.
- `/Users/<user>/projects/threadline/.planning/phases/209-collision-free-emission/209-06-SUMMARY.md` (read in full) — current gate status and DO-block idiom established by the immediate predecessor phase.
- `/Users/<user>/projects/threadline/.github/workflows/ci.yml` (lines 280-310 read this session) — confirmed PG 14/PG 16 matrix (min lane: elixir 1.15/otp26/pg14/ubuntu-22.04; current lane: elixir 1.17.3/otp27/pg16/ubuntu-24.04).
- `/Users/<user>/projects/threadline/bench/bench_helper.exs`, `bench/audit_capture_bench.exs` (read in full this session) — existing benchmark harness pattern (`Bench.Helper.setup/0`, `Benchee.run`, `write_metadata`) the new `bench/pk_capture_bench.exs` should follow.

### Secondary (MEDIUM confidence)
- `.planning/phases/210-pk-agnostic-capture/210-CONTEXT.md` — 18 maintainer-accepted decisions (D-01..D-18) with specific benchmark numbers and PG-14.17 verification claims; treated as authoritative per the "already locked, not re-litigated" framing in the CONTEXT.md itself, with three of its verifiable claims independently reproduced this session (see Primary sources).
- `.planning/research/ARCHITECTURE.md`, `.planning/research/PITFALLS.md` — milestone-level research; explicitly superseded in places by CONTEXT.md's D-03 (no per-row pg_index fallback) and D-10 (indnkeyatts/WITH ORDINALITY refinement not present in the original architecture doc).

### Tertiary (LOW confidence)
- None used without a HIGH/MEDIUM-confidence cross-check in this research pass.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; every module cited was read in full this session
- Architecture: HIGH — DO-block and PL/pgSQL fragment patterns directly reproduced against local PostgreSQL 14.17, matching the exact version CONTEXT.md cites
- Pitfalls: HIGH — drawn from milestone-level `PITFALLS.md` (itself probed against real PG during milestone research) plus this session's own spikes; the one MEDIUM-risk area (exact benchmark numbers for the `jsonb_object_agg` rejection) is explicitly flagged in Assumptions Log A1 as not independently re-measured, though it is not a planning blocker since D-07 makes the benchmark itself part of phase execution

**Research date:** 2026-09-25
**Valid until:** Effectively pinned to this milestone (v1.42) — the phase's own frozen migration SQL becomes a compatibility contract the moment it ships, so this research does not "go stale" on a calendar basis the way a fast-moving library's docs would; treat as valid through Phase 213 (upgrade guide) unless CONTEXT.md's decisions are re-opened.
