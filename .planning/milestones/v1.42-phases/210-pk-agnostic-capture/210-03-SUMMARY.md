---
phase: 210-pk-agnostic-capture
plan: 03
subsystem: capture
tags: [postgresql, plpgsql, ecto-migration, trigger, primary-key, validation]

requires:
  - phase: 210-pk-agnostic-capture
    provides: "Plan 01's PrimaryKeySQL.create_trigger_block/3 DO-block PK resolver and Plan 02's proof that pre-0.11 no-argument triggers keep capturing exactly as before"
provides:
  - "Threadline.Capture.PrimaryKeySQL.create_trigger_block/3: migrate-time refusal branches for a PK-less table (with a paste-ready config/config.exs HINT), a primary-key column type outside a stable-text-form allowlist, and a detected primary-key column listed in mask or exclude"
  - "Threadline.Capture.Naming.table_token/1: the one shared implementation of the bare-for-public/schema.table-otherwise token, used by both TriggerSQL.function_owner_guard/2 and PrimaryKeySQL's HINT text"
  - "PrimaryKeySQL.qualifying_index_predicate/0: the shared boolean predicate a stand-in unique index must satisfy, exposed for a future primary_key: config override to reuse"
  - "TriggerSQL.create_trigger/3's :redacted_columns option and the ARRAY[...]::text[] literal it emits"
  - "mix threadline.gen.triggers wires exclude ++ mask from each table's own config into :redacted_columns, so the DO-block redaction check can never drift from what the per-table function itself strips or masks"
  - "test/threadline/capture/trigger_migrate_time_errors_test.exs: real-PG proof of every refusal shape and the nothing-is-applied invariant"
affects: [211-read-side-pk-agnostic, 212-health-and-drift, 213-upgrade-guide]

actuals:
  tokens: 9557
  tasks: 3
  commits: 3
  plan_head_before: 43c1a3f66eb9f3970cceeffac861d094d20956e4

tech-stack:
  added: []
  patterns:
    - "A single migrate-time DO block resolves, validates and installs in one pass: any RAISE EXCEPTION anywhere in the block rolls the whole migration back before the final EXECUTE format(...) that installs the trigger, so no partial state is ever applied"
    - "A HINT built as a concatenated SQL expression (chr(34) || ... || ...), never format(), because USING HINT = expression is not itself a format string and the Elixir map snippet it renders starts with a literal %{"
    - "A recursive CTE over pg_type following typbasetype while typtype = 'd' resolves a domain to its base type once per key column, so a domain over an allowed base type is accepted and a domain over a disallowed one is refused with the same message as the disallowed type itself"
    - "The DO-block redaction check reuses the exact exclude ++ mask list gen.triggers already computed for the table's per-table function, passed through as one keyword option, so the two can never independently drift"

key-files:
  created:
    - test/threadline/capture/trigger_migrate_time_errors_test.exs
  modified:
    - lib/threadline/capture/primary_key_sql.ex
    - lib/threadline/capture/naming.ex
    - lib/threadline/capture/trigger_sql.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - test/threadline/capture/collision_free_emission_test.exs
    - test/threadline/mix/trigger_migration_property_test.exs
    - test/support/legacy_trigger_sql.ex

key-decisions:
  - "Naming.table_token/1 is now the single shared implementation of the bare-for-public/schema.table-otherwise token; TriggerSQL.function_owner_guard/2's private tables_option_token/1 delegates to it instead of keeping its own copy, per the plan's explicit instruction to share the helper"
  - "qualifying_index_predicate/0 is exposed (not private) so a later primary_key: config override can reuse the identical boolean conditions a stand-in unique index must satisfy, without redefining them"
  - "The no-qualifying-index HINT uses a literal placeholder column ('\"column_name\"') rather than leaving the primary_key: list empty, so the snippet stays syntactically paste-ready even when the adopter still has to pick real column names"
  - "Primary key resolution, type-check and redaction-check all happen inside one DO block, in that order, reusing the same declared keys/col/coltype variables — no separate helper functions per check, so a RAISE at any stage rolls back before the trigger is ever installed"

requirements-completed: [CAP-03, CAP-05]

coverage:
  - id: D1
    description: "A PK-less join table (the posts_tags flagship case) refuses at migrate time with a threadline: message naming the qualified table and primary_key:, and a HINT with a paste-ready config/config.exs snippet and the mix threadline.gen.triggers command to rerun; nothing is applied (no trigger, no schema_migrations row, host writes keep succeeding without capture)"
    requirement: "CAP-03"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#a PK-less join table (the flagship posts_tags case)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A PK-less table with no qualifying unique index gets a HINT to create one over NOT NULL columns first; a partial, deferrable, expression, or nullable-column index never qualifies as a stand-in"
    requirement: "CAP-03"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#a PK-less table with no qualifying unique index"
        status: pass
    human_judgment: false
  - id: D3
    description: "Error messages and HINTs name tables by their qualified form (billing.pk_less_invoices) and mixed-case tables in their exact case (public.PkLess)"
    requirement: "CAP-03"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#a PK-less schema-qualified table, a PK-less mixed-case table"
        status: pass
    human_judgment: false
  - id: D4
    description: "A primary-key column type outside the stable-text-form allowlist (timestamptz, numeric, double precision, jsonb, integer[], bytea, a domain over timestamptz) refuses, naming the column and its format_type text; every allowlisted type (smallint, integer, bigint, text, varchar, char, citext, uuid, date, timestamp without time zone, enum, a domain over integer) is accepted and captured"
    requirement: "CAP-03"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#a primary key column type outside the allowlist, a primary key column type inside the allowlist"
        status: pass
    human_judgment: false
  - id: D5
    description: "A table keyed by (id bigint, inserted_at timestamptz) that still has a 0.10.x no-argument trigger has its regeneration refused (naming inserted_at) and keeps capturing %{\"id\" => ...} under the legacy branch after the refused migration rolls back"
    requirement: "CAP-03"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#a table with a frozen 0.10.2 no-argument trigger and an unsupported-type key column"
        status: pass
    human_judgment: false
  - id: D6
    description: "A detected primary-key column listed in the table's mask or exclude refuses the migration naming the column; the same column in except_columns is accepted; comparison is exact and case-sensitive"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#a detected primary key column listed in mask or exclude"
        status: pass
    human_judgment: false
  - id: D7
    description: "TriggerSQL.create_trigger/3's :redacted_columns option emits no array when empty and an ARRAY[...]::text[] literal in declaration order when non-empty; mix threadline.gen.triggers wires the table's own exclude ++ mask into it so the DO-block check is pinned to the same rules the per-table function enforces"
    requirement: "CAP-05"
    verification:
      - kind: integration
        ref: "test/threadline/capture/trigger_migrate_time_errors_test.exs#the redaction literal in TriggerSQL.create_trigger/3"
      - kind: integration
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs (create_trigger comparisons updated with redacted_columns)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Every pre-existing fixture and comparison in the full capture/mix/gen.triggers suite updated for the new refusal behavior; full suite (2027 tests) and mix compile --warnings-as-errors stay green"
    verification:
      - kind: integration
        ref: "mix test"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-09-25
status: complete
---

# Phase 210 Plan 03: PK-Agnostic Capture — Migrate-Time Refusals Summary

**A PK-less table, a primary-key column type with no stable text form, and a detected key column listed in `mask`/`exclude` all now refuse the migration inside the same `DO` block — before any host write — with a `threadline:`-prefixed message and, for the PK-less case, a paste-ready `config/config.exs` HINT; proven end to end on real PostgreSQL in `trigger_migrate_time_errors_test.exs`, closing the intermediate PK-less-table state Plan 01 left.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-09-25T20:43:00Z
- **Completed:** 2026-09-25T21:07:00Z
- **Tasks:** 3
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments

- `PrimaryKeySQL.create_trigger_block/3` now resolves the table's primary key, and when it has none, searches for a qualifying stand-in unique index (`indisunique AND indisvalid AND indisready AND indimmediate AND indpred IS NULL AND indexprs IS NULL`, no `0` among its key attnums, every key column `attnotnull`) before raising — with a HINT that fills in the index's real column names as a paste-ready `config :threadline, :trigger_capture` snippet, or says to create such an index first when none qualifies
- Every resolved key column's type is checked against an allowlist (`smallint`/`integer`/`bigint`; `text`/`varchar`/`char`/`citext`; `uuid`; `date`; `timestamp` without time zone; enums; and domains over any of these, resolved through a recursive walk over `typbasetype`); a column outside it refuses naming the column and its `format_type` text
- A detected primary-key column listed in the table's `mask` or `exclude` refuses, naming the column; `except_columns` overlap is harmless; comparison is exact and case-sensitive (`mask: ["Code"]` does not match column `code`)
- `TriggerSQL.create_trigger/3` gained a `:redacted_columns` option; `mix threadline.gen.triggers` now wires each table's own `exclude ++ mask` into it for both default and per-table trigger modes, so the DO-block redaction check is pinned to the exact set of columns the table's own function redacts
- `Naming.table_token/1` is now the single shared implementation of the "bare for public, schema.table otherwise" token, used by both `TriggerSQL.function_owner_guard/2` and the new HINT text
- `test/threadline/capture/trigger_migrate_time_errors_test.exs` (22 tests, real PostgreSQL): every refusal shape (no PK with and without a qualifying index, partial/deferrable/expression/nullable-column indexes that don't qualify, schema-qualified and mixed-case table names, every refused and accepted key type including `citext`, an enum, and two domains, a legacy no-argument trigger on an unsupported-type key, and mask/exclude on a detected key column), plus the nothing-is-applied invariant (no trigger, no per-table function, no `schema_migrations` row) and the `TriggerSQL.create_trigger/3` redaction-literal unit tests

## Task Commits

Each task was committed atomically:

1. **Task 1: A PK-less join table refuses at migrate time with a paste-ready config fix, and nothing is applied** — `33d94991` (feat)
2. **Task 2: Key column type allowlist with domain resolution; unsupported types refuse, legacy triggers keep capturing** — `74a3741b` (feat)
3. **Task 3: A detected key column in mask or exclude refuses; the DO-block redaction list is pinned to the function's rules; suite green** — `a240bdb3` (feat)

**Plan metadata:** (this commit)

## Exact Refusal Text (as PostgreSQL returned it)

**No primary key (`posts_tags`, a qualifying unique index exists):**
```
MESSAGE: threadline: public.posts_tags has no primary key, so its audit rows could not be told apart. Declare one with the primary_key: option.
DETAIL: The unique index posts_tags_post_id_tag_id_index could be used instead.
HINT: Add to config/config.exs: config :threadline, :trigger_capture, tables: %{"posts_tags" => [primary_key: ["post_id", "tag_id"]]}, then run: mix threadline.gen.triggers --tables posts_tags
```

**Unsupported key type (`pk_type_tstz.id timestamptz`):**
```
MESSAGE: threadline: primary key column id of public.pk_type_tstz has type timestamp with time zone, which has no stable text form for audit keys
HINT: Supported types: smallint, integer, bigint, text, varchar, char, citext, uuid, date, timestamp without time zone, enum types, and domains over these. Triggers installed by earlier releases keep capturing this table until it is regenerated.
```

**Key column in `mask` (`pk_masked_code.code`):**
```
MESSAGE: threadline: primary key column code of public.pk_masked_code is listed in mask or exclude
HINT: Remove code from this table's :mask or :exclude in config/config.exs; redacting a key column would erase row identity from the audit trail.
```

## Files Created/Modified

- `lib/threadline/capture/primary_key_sql.ex` — `create_trigger_block/3` gains the no-PK refusal (with qualifying-index search and HINT), the type-allowlist check (recursive `typbasetype` walk), and the mask/exclude check (`:redacted_columns` opt); new `qualifying_index_predicate/0` (shared), `redaction_check_sql/2`, `redacted_columns_array_sql/1`, `sql_string_literal/1` (private)
- `lib/threadline/capture/naming.ex` — new `table_token/1`, the shared "bare for public, schema.table otherwise" token
- `lib/threadline/capture/trigger_sql.ex` — `function_owner_guard/2`'s private `tables_option_token/1` now delegates to `Naming.table_token/1`
- `lib/mix/tasks/threadline.gen.triggers.ex` — `trigger_ups/1` passes `redacted_columns: exclude ++ mask` (from the same spec that builds the per-table function) to `TriggerSQL.create_trigger/3` for both default and per-table modes
- `test/threadline/capture/trigger_migrate_time_errors_test.exs` — new, 22 real-PG tests covering every refusal shape and edge case from the plan's `<behavior>` and `must_haves.truths`
- `test/mix/tasks/threadline/gen_triggers_test.exs` — `create_trigger` comparisons for `test_redaction_users`, `billing.invoices`, and `posts` (both "table spelling" tests) updated to pass the matching `redacted_columns:` opt
- `test/threadline/capture/collision_free_emission_test.exs` — the partitioned fixture (`audited_events`) given `PRIMARY KEY (id)` (a PK-less table is now refused, which is this phase's intended behavior); its partition insert now also asserts `table_pk == %{"id" => <text>}`
- `test/threadline/mix/trigger_migration_property_test.exs` — `generated/1` helper fixed to build its `execute` line with `printable_limit: :infinity, limit: :infinity` (see Deviations)
- `test/support/legacy_trigger_sql.ex` — `migration_source/3`'s `executes/1` helper fixed the same way

## Decisions Made

- `Naming.table_token/1` is the single shared implementation of the "bare for public, schema.table otherwise" token; `TriggerSQL.function_owner_guard/2`'s private `tables_option_token/1` now delegates to it, per the plan's explicit instruction that both modules must use one implementation
- `qualifying_index_predicate/0` is public (not private), exposing the boolean conditions a stand-in unique index must satisfy, so a future `primary_key:` config override match can reuse the identical predicate without redefining it
- The no-qualifying-index HINT branch uses a literal placeholder column (`"column_name"`) inside the `primary_key: [...]` snippet rather than an empty list, so the snippet stays syntactically valid Elixir even before the adopter fills in real column names
- Primary-key resolution, the type-allowlist check, and the mask/exclude check all run inside one `DO` block in that order, reusing the same declared `keys`/`col`/`coltype` variables — no separate SQL-generating helper per check — so any `RAISE` at any stage rolls the whole migration back before the trigger is ever installed
- `PrimaryKeySQL`'s doc comments were written without planning decision IDs (`D-09`, `D-11`, `D-12`, `D-13`) or `CAP-xx` cross-references from the start of Task 3's docstring pass, and the ones introduced during Tasks 1–2 were rewritten as durable domain rationale once `ReleaseArtifactContractTest` caught them (see Deviations)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test-fixture `inspect/1` calls without `printable_limit: :infinity` truncated the now-larger DO-block SQL, breaking rerun-detection tests**
- **Found during:** Task 2, running the wider capture/mix suite after adding the no-PK and type-allowlist refusal branches (which made the generated DO-block text exceed 4096 bytes)
- **Issue:** `test/support/legacy_trigger_sql.ex`'s `migration_source/3` (`executes/1` helper) and `test/threadline/mix/trigger_migration_property_test.exs`'s `generated/1` helper both built their `execute "..."` lines with plain `inspect(sql)`. Elixir's default binary `inspect/1` truncates a string over 4096 bytes and appends `<> ...`, corrupting the fixture text. This silently broke 4 `TriggerMigrationTest` tests and 1 `TriggerMigrationPropertyTest` property (0 successful runs) once the DO block's real-PG SQL grew past that limit — a pre-existing test-helper gap, not a production bug (the real generator's `execute_line/1` in `gen.triggers.ex` already used `printable_limit: :infinity, limit: :infinity`, matching PostgreSQL's own uncapped string handling).
- **Fix:** Both helpers now call `inspect(sql, printable_limit: :infinity, limit: :infinity)`, matching the production `execute_line/1` idiom.
- **Files modified:** `test/support/legacy_trigger_sql.ex`, `test/threadline/mix/trigger_migration_property_test.exs`
- **Verification:** `mix test test/threadline/mix/trigger_migration_test.exs test/threadline/mix/trigger_migration_property_test.exs` — 32 tests/properties, 0 failures (were 5 failing before the fix)
- **Committed in:** `74a3741b` (Task 2 commit)

**2. [Rule 1 - Bug] Doc comments referencing planning decision IDs leaked into packaged source, violating the CLAUDE.md packaged-vocabulary contract**
- **Found during:** Task 3, running `mix verify.test` (full suite) after all three tasks' code was in place
- **Issue:** `test/threadline/release_artifact_contract_test.exs` failed 2 tests: `primary_key_sql.ex`'s doc comments referenced `D-09`, `D-11`, `D-12`, `D-13` and `CAP-03`/`CAP-05` (introduced during Tasks 1–2's docstring writing), which the packaged-source contract test flags as planning vocabulary that must not ship in `lib/`.
- **Fix:** Rewrote the four flagged doc comments (module doc for `create_trigger_block/3`, the `:redacted_columns` option doc, the `redaction_check_sql/2` comment, and the `qualifying_index_predicate/0` comment) as durable domain rationale — describing *why* each refusal exists (rows could never be told apart; no stable text form for an audit key; redacting a key column would erase row identity) instead of citing decision IDs.
- **Files modified:** `lib/threadline/capture/primary_key_sql.ex`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` — 19 tests, 0 failures; full suite (`mix test`) re-run afterward — 2027 tests, 0 failures, 1 excluded
- **Committed in:** `a240bdb3` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking test-helper bug, 1 CLAUDE.md packaged-vocabulary violation)
**Impact on plan:** Both fixes were necessary to get the plan's own verification commands (and the wider suite) to green; neither touched the refusal behavior itself. No scope creep.

## TDD Gate Compliance

This plan's tasks carry `tdd="true"`, but `workflow.tdd_mode` is not enabled in `.planning/config.json` for this repository (same as Plans 01 and 02), so the formal RED/GREEN/REFACTOR commit-gate sequence was not enforced. Each task was committed as a single commit containing both its tests and implementation. Test-first discipline was followed in practice: Task 1's `posts_tags` tests were written and run against the unmodified `create_trigger_block/3` first (confirmed red — the pre-Task-1 code installed a zero-argument trigger instead of raising), then the refusal branch was implemented and the same tests turned green. Tasks 2 and 3 extended the same test file incrementally, running the full file after each addition before moving to the next behavior.

## Issues Encountered

None beyond the two deviations above, both resolved within the same task's verification pass.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- CAP-03 and CAP-05's migrate-time halves are both closed: a PK-less table, an unsupported key type, and a redacted key column all refuse before any host write, with actionable `config/config.exs` guidance for the PK-less case.
- `qualifying_index_predicate/0` and the type-check fragment are already factored for reuse by a `primary_key:` config override (CONF-01, D-14 through D-18 in `210-CONTEXT.md`), which is out of this plan's scope but was the next logical extension the CONTEXT.md anticipated.
- Phase 211 (read side) and Phase 212 (health/drift) hand-offs from Plans 01–02 (unresolved-key sentinel is both `{}` and `{"id": null}`; `table_pk` comparisons must use `=` never `@>`; a legacy no-argument trigger on a non-`(id)` table is an error-level catalog-detected finding) are unchanged by this plan.
- Full suite (`mix test`): 2027 tests, 0 failures, 1 excluded. `mix compile --warnings-as-errors` clean. `mix format --check-formatted` clean on all files this plan touched.
- No blockers.

---
*Phase: 210-pk-agnostic-capture*
*Completed: 2026-09-25*
