---
phase: 211-read-side-agreement
plan: 03
subsystem: database
tags: [postgres, ecto, indexing, migrations, mix-task]

requires:
  - phase: 211-01
    provides: "Threadline.Query.RowKey / where_row/2 whole-map table_pk equality (history_query/3, as_of_query/4, row_history_query/3)"
  - phase: 211-02
    provides: "Composite-key read path proven; the same where_row/2 predicate this index serves"
provides:
  - "Threadline.Capture.RowHistoryIndexSQL: index_name/0, create_sql/1, create_concurrently_sql/1, drop_concurrently_sql/1 — one SQL source for both the install template and the generator"
  - "audit_changes_row_history_idx in the install template (new installs) and via mix threadline.gen.row_history_index (existing adopters)"
  - "EXPLAIN proof that history/3, as_of/4 and row_history_query/3 all use the index under enable_seqscan = off"
affects: [212-detection-and-adopter-twins, 213-upgrade-guide]

actuals:
  tokens: 6445
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Shared SQL-fragment module (Threadline.Capture.RowHistoryIndexSQL) consumed by both the install template and a Mix generator, so DDL cannot drift between an adopter's new-install path and upgrade path"
    - "CREATE INDEX CONCURRENTLY IF NOT EXISTS + @disable_ddl_transaction + @disable_migration_lock for a non-blocking existing-adopter migration, with an INVALID-index recovery comment in the generated file"

key-files:
  created:
    - lib/threadline/capture/row_history_index_sql.ex
    - lib/mix/tasks/threadline.gen.row_history_index.ex
    - priv/repo/migrations/20260925000000_threadline_row_history_index.exs
    - test/threadline/query/row_history_index_explain_test.exs
    - test/mix/tasks/threadline/gen_row_history_index_test.exs
  modified:
    - lib/threadline/capture/migration.ex
    - test/threadline/storage_schema_migration_contract_test.exs
    - mix.exs
    - test/threadline/public_surface_contract_test.exs
    - guides/configuration-and-commands.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "D-09/D-10/D-11/D-12 executed verbatim from 211-CONTEXT.md: install template gets a blocking IF NOT EXISTS (safe on an empty new table); the generator gets a non-blocking CONCURRENTLY IF NOT EXISTS; audit_changes_table_name_idx is kept because filter_by_table/2 filters by table_name alone."
  - "The EXPLAIN test seeds ~9000 rows (4 noise tables x 1000 keys, plus 1000 keys x 5 history-depth rows for the target table) so the composite index's selectivity genuinely beats audit_changes_table_name_idx under real ANALYZE statistics, rather than relying solely on enable_seqscan = off to force the choice."
  - "Ecto.Adapters.SQL.explain/4's :prefix option does not apply a schema prefix to the query (it only forwards to sql_call); the fix is Ecto.Query.put_query_prefix(query, storage_schema) before calling explain/3. Documented here since the plan text's exact call signature does not work as written."

requirements-completed: [IDX-01]

coverage:
  - id: D1
    description: "New installs create audit_changes_row_history_idx via the install template, for both the default and mixed-case storage schema, alongside audit_changes_table_name_idx"
    requirement: IDX-01
    verification:
      - kind: unit
        ref: "test/threadline/storage_schema_migration_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix threadline.gen.row_history_index writes a non-blocking CONCURRENTLY migration for existing adopters, is idempotent on rerun, rejects unknown flags, and its SQL matches the install template's shared source; up/down/up leaves exactly one valid index in a non-default storage schema"
    requirement: IDX-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/threadline/gen_row_history_index_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "EXPLAIN of history/3, as_of/4 and row_history_query/3's real queries all name audit_changes_row_history_idx under enable_seqscan = off, scoped to a rolled-back transaction; no assertion on timing"
    requirement: IDX-01
    verification:
      - kind: unit
        ref: "test/threadline/query/row_history_index_explain_test.exs"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-09-26
status: complete
---

# Phase 211 Plan 03: Row-History Index Summary

**`audit_changes_row_history_idx` ships from one shared SQL source to both new installs (blocking `IF NOT EXISTS` in the install template) and existing adopters (`mix threadline.gen.row_history_index`, non-blocking `CONCURRENTLY`), with an EXPLAIN-based test proving all three read paths (`history`, `as_of`, `row_history_query`) actually use it.**

## Performance

- **Duration:** 45 min
- **Tasks:** 3 (1 tracer, 1 auto, 1 auto/tdd)
- **Files modified:** 11

## Accomplishments

- `Threadline.Capture.RowHistoryIndexSQL` is the single DDL source for `audit_changes_row_history_idx` (index name, blocking create, concurrent create, concurrent drop), consumed by both the install template and the new generator so the column list cannot drift.
- The install template (`Threadline.Capture.Migration.migration_content/0`) now creates the index for new installs, honoring the configured (including mixed-case) storage schema, with `audit_changes_table_name_idx` kept per D-11.
- `mix threadline.gen.row_history_index` gives existing adopters a non-blocking `CREATE INDEX CONCURRENTLY IF NOT EXISTS` migration with `@disable_ddl_transaction true`/`@disable_migration_lock true`, rerun detection, an INVALID-index recovery comment, and a raw-SQL fallback in its `@moduledoc`. It is registered as adopter-public in `mix.exs`, both exhaustive task lists in `public_surface_contract_test.exs`, and `guides/configuration-and-commands.md`.
- `row_history_index_explain_test.exs` proves, under `enable_seqscan = off` scoped to a rolled-back transaction, that `history_query/3`, `as_of_query/4`, and `row_history_query/3` all produce plans naming `audit_changes_row_history_idx` — never asserting on timing (D-12).

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — shared index SQL → test-repo migration → EXPLAIN shows history uses the index** - `c68c4485` (feat)
2. **Task 2: Expand — install template creates the index; as_of and row_history_query EXPLAIN; contract pin** - `b4b4a2b6` (feat)
3. **Task 3: Expand — mix threadline.gen.row_history_index for existing adopters** - `00547160` (test/RED), `9b459a1c` (feat/GREEN), `a94dfd45` (docs: public-surface registration)

**Plan metadata:** pending (this commit)

_Note: Task 3 is `tdd="true"`; the RED commit's 5 assertions failed for the planned behavior (no file written, no error raised, no index toggled), never on a compile or fixture crash. No REFACTOR commit was needed — GREEN's implementation needed no cleanup._

## Files Created/Modified

- `lib/threadline/capture/row_history_index_sql.ex` - shared DDL: `index_name/0`, `create_sql/1`, `create_concurrently_sql/1`, `drop_concurrently_sql/1`
- `priv/repo/migrations/20260925000000_threadline_row_history_index.exs` - test-repo migration dogfooding the concurrent adopter path
- `test/threadline/query/row_history_index_explain_test.exs` - EXPLAIN proof for `history`, `as_of`, and `row_history_query`
- `lib/threadline/capture/migration.ex` - install template now emits the index
- `test/threadline/storage_schema_migration_contract_test.exs` - pins the index for default and mixed-case (`AuditLog`) schemas
- `lib/mix/tasks/threadline.gen.row_history_index.ex` - the existing-adopter generator
- `test/mix/tasks/threadline/gen_row_history_index_test.exs` - generator behavior tests (write-once, rerun, bad flag, SQL parity, up/down/up)
- `mix.exs` - registers the task in `groups_for_modules` "Mix Tasks"
- `test/threadline/public_surface_contract_test.exs` - both exhaustive public-task lists updated
- `guides/configuration-and-commands.md` - command table updated (ten -> eleven tasks)
- `.planning/REQUIREMENTS.md` - IDX-01 checked off, traceability table updated

## Decisions Made

See `key-decisions` in frontmatter. The one implementation-level finding not covered by a locked D-decision: `Ecto.Adapters.SQL.explain/4`'s `opts` (including `:prefix`) are forwarded to the low-level SQL call, not used to plan the query with a schema prefix — the query must already carry the prefix via `Ecto.Query.put_query_prefix/2` before being passed to `explain/3`. The plan text's literal `explain(Repo, :all, query, prefix: "threadline")` call does not apply the prefix; this was corrected during Task 1 (see `row_history_index_explain_test.exs`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `explain/4`'s `:prefix` option does not schema-qualify the query**

- **Found during:** Task 1
- **Issue:** The plan's literal call, `Ecto.Adapters.SQL.explain(Repo, :all, query, prefix: "threadline")`, produced a plan against the bare `"audit_changes"` relation (no schema), which does not exist outside the `search_path`, and PostgreSQL raised `undefined_table`.
- **Fix:** Apply the prefix to the query struct itself first — `query |> Ecto.Query.put_query_prefix("threadline") |> then(&Ecto.Adapters.SQL.explain(Repo, :all, &1))` — since `explain/4`'s `to_sql/3` call path never merges `opts[:prefix]` into query planning the way `Repo.all/2` does.
- **Files modified:** `test/threadline/query/row_history_index_explain_test.exs`
- **Verification:** All three EXPLAIN tests pass and each plan's text contains `audit_changes_row_history_idx`.
- **Committed in:** `c68c4485` (Task 1's tracer commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug fix, no scope creep; the fix stays entirely inside the test file's own query-building helper).
**Impact on plan:** None on delivered scope. The must-have truths, artifacts, and prohibitions in the plan frontmatter are all satisfied as written.

## Issues Encountered

**`StorageSchemaCase.prepare_storage_schema!/2` does not apply `Threadline.Capture.Migration` content to a real schema** (noted per Task 2's conditional instruction). It builds a non-`"threadline"` storage schema (such as `"audit"`) with `CREATE TABLE ... (LIKE threadline.<table> INCLUDING ALL)`, which copies the *current* index set — including `audit_changes_row_history_idx` once the test-repo migration installed it — rather than re-running the install template's DDL. This was exploited deliberately in `gen_row_history_index_test.exs`'s up/down/up test: the first `up` against a freshly `prepare_storage_schema!("audit")`-built schema is a genuine "index already exists" no-op case, because `LIKE ... INCLUDING ALL` had already copied it in.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

IDX-01 is complete and checked off in `.planning/REQUIREMENTS.md`. CONF-01 (read half) and READ-04 (transaction-page row-link guard for composite keys) remain for 211-04, along with docs/guide/CHANGELOG updates and the `mix ci.all` gate per the ROADMAP. No blockers identified for 211-04.

---
*Phase: 211-read-side-agreement*
*Completed: 2026-09-26*

## Self-Check: PASSED

All created files verified present on disk; all 5 task commit hashes verified present in git log.
