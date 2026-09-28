# Phase 210: PK-Agnostic Capture - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Triggers record the table's real primary key in `audit_changes.table_pk`, whatever the key's name, type or column count. This covers non-`id` integer, uuid and text keys, composite keys (including PK indexes with INCLUDE columns), and PK-less tables that declare `primary_key:` in config. Three constraints hold throughout:

- No per-row catalog cost.
- 0.10.x installs are not broken.
- The host write never fails.

Requirements: CAP-01..CAP-06 and CONF-01. For CONF-01, the capture and validation side lands here and the read side is proven in Phase 211.

Out of scope, owned by later phases:

- Read-side `history`/`as_of`/`RowKey` and the row-history index belong to Phase 211.
- Health findings (`:pk_drift`, legacy no-arg triggers) and the adopter twins belong to Phase 212.
- The upgrade guide belongs to Phase 213.

Already locked by milestone research and not re-litigated here:

- PK columns are resolved **at migrate time** by a generated DO block that reads `pg_index`.
- The columns are passed to the capture function as **trigger arguments (`TG_ARGV`)**.
- `table_pk` is encoded as `{column_name: text}` for every arity.

</domain>

<decisions>
## Implementation Decisions

### Fallback semantics: legacy and unresolvable keys (CAP-04)
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

### Trigger-body PK extraction and CAP-06 benchmark
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

### Migrate-time resolution and validation (CAP-03, CAP-05, CONF-01 enforcement)
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

### `primary_key:` override surface (CONF-01, HIGH-IMPACT, maintainer-accepted 2026-09-25)
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §Phase 210 — goal, SC1–SC5, research flag; §Phase 211/212 for downstream dependents
- `.planning/REQUIREMENTS.md` — CAP-01..CAP-06, CONF-01; HLTH-* and READ-* for hand-off coherence

### Milestone research (v1.42)
- `.planning/research/ARCHITECTURE.md` — Pattern 1 (migrate-time DO block → TG_ARGV). **Its legacy `pg_index` slow path is overridden by D-03.** Also Pattern 2 (the `{col: text}` shape) and the phase-210 row of the build order
- `.planning/research/STACK.md` — the TG_ARGV vs runtime lookup benchmark and the Ecto `field_source` notes
- `.planning/research/PITFALLS.md` — Pitfall 3 (`{"id":null}` collision identity), Pitfall 6 (a no-PK NULL aggregate aborts the host write), Pitfall 14, and the performance-traps table
- `.planning/research/SUMMARY.md` — the cross-research decision table
- `.planning/research/FEATURES.md` — the prior-art comparison (supa_audit, Carbonite, PaperTrail)

### Prior phase decisions
- `.planning/phases/209-collision-free-emission/209-CONTEXT.md` — frozen DO-block style (quoted literals, `RAISE WARNING` vs `EXCEPTION` with HINT, the ≤63-byte check, `to_regclass` on quoted literals), orphan-safe drop, owner guard, and the rerun-detection `ON` clause scan
- `.planning/phases/208-identifier-foundation/` — `Threadline.Capture.Naming`, `StorageSchema.validate_identifier!`, MigrationsPath

### Project
- `prompts/audit-lib-domain-model-reference.md` — capture-layer responsibilities
- `prompts/threadline-elixir-oss-dna.md` — named verify entrypoints and honest default tests

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/threadline/capture/trigger_sql.ex`: four function bodies (around lines 261, 312, 417 and 475) currently hardcode `jsonb_build_object('id', to_jsonb(NEW|OLD) ->> 'id')` at 12 sites (275–501). Replace them with the shared D-05 fragment. `create_trigger/3` (~216) becomes the D-09 DO block. `function_owner_guard/2` and `drop_function_if_unused/2` (~124–196) stay.
- `lib/threadline/capture/trigger_capture_config.ex`: `normalize_table_entry/1` is where `primary_key` joins `exclude`/`mask`/… Note that `normalize_columns/1` silently dedups.
- `lib/threadline/capture/redaction_policy.ex`: `validate!/1` handles redaction validation. The mask/exclude lists feed D-12.
- `lib/threadline/capture/naming.ex` + `StorageSchema.validate_identifier!`: identifier checks for override column names and DO-block literals.
- `lib/mix/tasks/threadline.gen.triggers.ex`: migration assembly, `capture_tables_by_pair!`, and the config-error rescue at ~286.
- `bench/bench_helper.exs` (`write_metadata`) and the `verify.bench` alias (`mix.exs:~217`).

### Established Patterns
- Frozen migration SQL: every emitted statement is permanent in adopters' repos. Prefer readable, fully quoted DO blocks (Phase 209).
- `RedactionPresenter.validate_threadline_shape/1` depends on body markers and regex-parsed redaction statements.
- CI PostgreSQL matrix: PG 14 (compat lane) and PG 16 (current lane, `.github/workflows/ci.yml:~290-300`). Real-PG tests must pass on both.
- Zero human verification: the benchmark is a recorded, automated run, not a UAT step.

### Integration Points
- Global function refresh: `gen.triggers` must emit `CREATE OR REPLACE FUNCTION threadline_capture_changes()` with the new body whenever a default-mode table is included, so un-regenerated no-arg triggers keep working (D-01).
- Phase 211 consumes the `table_pk` encoding and the `primary_key` loader output. Phase 212 consumes `tgargs`, for `:pk_drift` and the legacy-trigger findings.

</code_context>

<specifics>
## Specific Ideas

- The flagship case for the HINT snippet is a Phoenix `many_to_many` join table (`posts_tags`) with no PK but a unique `(post_id, tag_id)` index. It should be a copy-paste fix.
- Required real-PG tests:
  - frozen 0.10.x SQL on an `id` table stores byte-identical output;
  - frozen 0.10.x SQL on a uuid `code`-keyed table stores `{}` and the insert succeeds;
  - a composite TG_ARGV trigger followed by `RENAME COLUMN` stores `{}` and the insert succeeds;
  - a PK with INCLUDE columns captures only the key columns;
  - `CREATE OR REPLACE TRIGGER` swaps the args of a no-arg trigger on PG 14 and 16.

</specifics>

<deferred>
## Deferred Ideas

- Widening the PK type allowlist (`timestamptz` via a fixed UTC rendering, `numeric`) is a future phase if adopters ask. Doing it would require read-side encoding parity.
- A `--primary-key` CLI flag is rejected, not deferred (D-14).
- Capture for tables with no PK and no qualifying unique index remains out of scope for the milestone.

</deferred>

---

*Phase: 210-pk-agnostic-capture*
*Context gathered: 2026-09-25*
