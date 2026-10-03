# Phase 229: Adopter API and Health Additions - Context

**Gathered:** 2026-10-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Additive adopter-facing API and CLI work, released together in one 0.12.0 CHANGELOG section:

- `Threadline.history/3` takes an optional `:limit` cap (QRY-01, QRY-02).
- `mix threadline.health.coverage` gains `--strict` (HLTH-01) and `--all-schemas` (HLTH-02).
- A new `:unresolved_legacy_keys` warning finding (HLTH-03).
- Documentation that malformed `:trigger_capture` config raises (HLTH-04).

Every default behavior stays unchanged. The phase does not consolidate `history`/`row_history` (v1.45), add a backfill generator (a durable anti-feature), or add an `:invalid_config` finding code.

How the decisions were reached: four parallel advisor researchers (one per area), then a single roll-up confirm. The maintainer accepted the whole recommended set on 2026-10-02.

</domain>

<decisions>
## Implementation Decisions

### A. `history/3` `:limit` (QRY-01, QRY-02)
- **D-01:** Validate in `history/3` **before any DB access** (before `RowKey.match!`), using a new private validator in `Threadline.Query`.
  - Message is the exact `Threadline.Evidence` wording: `":limit must be a positive integer, got: #{inspect(v)}"` (precedent `lib/threadline/evidence.ex:313-317`).
  - **`limit: nil` is accepted** and means unbounded. Unlike Evidence, which rejects an explicit nil, this keeps `limit: opts[:limit]` pass-through working.
  - `0`, negatives, floats, booleans and strings raise `ArgumentError`.
  - Do not generalise `Cursors.timeline_page_size!/1`; that is a refactor v1.45 owns.
  - No NimbleOptions; it is not a direct dependency.
- **D-02:** Apply the cap inside `history_query/3` (its only caller is `history/3`) via a `maybe_limit/2` placed after both `order_by`s.
  - SQL evaluates LIMIT after the `:scope_query_fn` WHERE, so the cap counts only in-scope rows.
  - Document that `scope_query_fn` should only add predicates, because a limit it sets is overridden.
  - Do not pass `:limit` into the scope params.
- **D-03:** Docs:
  - Add a `:limit` bullet to both @docs (`lib/threadline.ex` Options and `lib/threadline/query.ex`, which gains an Options section and the example `Threadline.history(MyApp.User, 42, repo: MyApp.Repo, limit: 20)`).
  - The wording says "returns at most n **most recent** changes (`captured_at desc, id desc`); `:limit` caps, it does not page — use `row_history_page/4` for keyset paging".
  - No new `@spec` (a contract decision for v1.45). No required guide churn; the contract pins are substring-only.
  - CHANGELOG entry goes under an additions heading, not Breaking: "additive; default unchanged (unbounded)".
- **D-04:** Tests:
  - An example test comparing against an **independently computed** `captured_at desc, id desc` ordering, with a deliberate `captured_at` tie. Comparing no-limit vs `limit: nil` alone is tautological and not sufficient.
  - Equality of no-limit, `limit: nil` and `limit: count + 5`.
  - `limit: count`, `limit: 1`, and a limit falling inside the tie group.
  - Limit plus scope, reusing the "applies support scope" fixture in `test/threadline/query_test.exs`.
  - Rejection cases `0`, `-1`, `1.0`, `"5"`, `true`, each with an asserted message.
  - A `PropertyRuns.db` prefix property: `history(limit: n) == Enum.take(history(), n)` for n in `1..len+2`, reusing `RowHistoryGenerators.history_gen/0`, so no new generator registration is needed.

### B. `--strict` (HLTH-01)
- **D-05:** `--strict` fails **only on in-scope `:error`-severity findings**. Uncovered tables never fail it; that is `mix threadline.verify_coverage`'s positive-list job.
  - The moduledoc, guides and the strict status line must say this loudly and point to `verify_coverage`.
  - Failing on uncovered tables would be a scope change (a possible future `--fail-on-uncovered`, deferred).
- **D-06:** Exit 1 via `exit({:shutdown, 1})`, the same as `verify_coverage.ex:83-85`.
  - No split exit codes and no `System.halt`.
  - `Mix.raise` remains for usage and config errors only.
- **D-07:** After the normal output, print one gate status line to **stderr** via `Mix.shell().error/1`:
  - on failure: `strict: FAILED — N error finding(s) (uncovered tables are not gated; use mix threadline.verify_coverage)`
  - on pass: `strict: passed (W warning(s) not gated)`
  - Exact wording is at Claude's discretion, but the meaning must be preserved.
  - With `--json`, stdout stays exactly one pure JSON document.
  - **No new `strict`/`status` JSON key.** The key set is pinned at `test/threadline/operator_surface/coverage_mix_test.exs:72-75`, and a flag-dependent shape is undesirable.
- **D-08:** Scope:
  - `--schema=NAME` gates that schema; the default is `"public"`, and the docs must say so.
  - `--all-schemas` gates the union of all schemas.
  - `--strict` composes with `--json`, `--schema` and `--all-schemas`.
- **D-09:** Matrix test {clean, warning-only, error} × {non-strict, `--strict`} × {table, `--json`}:
  - Uses the `verify_coverage_task_test.exs` pattern: `async: false`, a dedicated schema with `on_exit` drop, `Mix.Task.reenable`, and `with_io` + `catch_exit`.
  - Error fixture: `ALTER TABLE … DISABLE TRIGGER`, which yields `:capture_trigger_disabled`.
  - Warning fixture: a no-args trigger and/or `:unresolved_legacy_keys`.
  - On the failing JSON cell, assert that `Jason.decode!(stdout)` succeeds.
  - Assert an error in another schema does not fail `--strict --schema=X`.
  - Researcher pre-check (the ROADMAP asked for it): **no existing test pins per-severity exit codes** for `health.coverage`, so the matrix is the baseline.
- **D-10:** Doc rewording ("viewer by default; `--strict` turns `:error` findings into exit 1"):
  - moduledoc and code comment in `lib/mix/tasks/threadline.health.coverage.ex`
  - `guides/domain-reference.md` (~267)
  - `guides/operator-surface.md` (~409-413)
  - `guides/configuration-and-commands.md` (~109)
  - add a GitHub Actions snippet `- run: mix threadline.health.coverage --strict` to `guides/production-checklist.md` next to `verify_coverage`
  - rename the "exits 0" test in `coverage_mix_test.exs` to say "without --strict"
  - update the pinned `OptionParser` spec string in `test/threadline/operator_surface/coverage_doc_contract_test.exs` (~244-248) in the same commit
  - add doc-contract assertions for the strict sentence and the "uncovered not gated" sentence

### C. `--all-schemas` (HLTH-02)
- **D-11:** **Task-only.** No new public `Health` multi-schema API; `trigger_coverage(schema: :all)` is deferred to v1.45's API contract.
  - Implement with private (`@doc false`) helpers: one batched catalog query for tables and one for triggers across schemas (no per-schema loop: 200 tenants would mean 400 round trips with no consistent snapshot).
  - Classify with a pure `classify/3` extracted from `trigger_coverage/1`, which `trigger_coverage/1` itself then calls, so per-table semantics match `--schema=NAME` by construction.
- **D-12:** Schema enumeration:
  - Include every schema with tables in `pg_tables`, except `information_schema` and `pg\_%` (reuse the `CoverageSchemas.available/1` predicate).
  - **Exclude extension-member schemas** via `pg_depend` (`classid = 'pg_namespace'::regclass`, `deptype = 'e'`). **Never** filter on `pg_extension.extnamespace`, which would drop `public`.
  - This exclusion is unverified against real Timescale/PostGIS. The plan MUST include a fixture test that creates a schema inside an extension.
  - Union with the schemas of any findings, so a finding never disappears.
  - Omit schemas with zero reportable rows and zero findings, and document that.
  - The storage schema stays included.
  - Per-table exclusions are identical to `--schema` (the 3 `@audit_tables` plus `expected_uncovered_tables`).
- **D-13:** JSON is an envelope:
  ```json
  {"schemas": {"<name>": <exact single-schema payload>, ...},
   "summary": {"schemas": K, "covered": n, "uncovered": n, "expected_uncovered": n,
               "error_findings": n, "warning_findings": n}}
  ```
  - `schemas` is encoded in sorted key order with `Jason.OrderedObject`; plain maps over 32 keys come out in hash order.
  - Findings are computed once with no `:schema` option, grouped by schema, and live only inside each schema's payload.
  - Output without the flag stays **byte-identical**. A golden test asserts `.schemas.public == <--schema=public payload>`.
- **D-14:** The table has a leading `SCHEMA` column (kubectl `-A` analog), then:
  - a per-schema rollup (`SCHEMA COVERED UNCOVERED EXPECTED FINDINGS`)
  - a grand total `Coverage: … across K schemas`
  - the unchanged FINDINGS section (already prints `schema.table`)

  No paging or condensing; a `--summary` flag is a possible later addition.
- **D-15:** `--schema` + `--all-schemas` raises via `Mix.raise` **before** the repo starts.
  - Detected with `Keyword.has_key?`, so an explicit `--schema=public` also conflicts.
  - Message: `threadline.health.coverage: --schema and --all-schemas cannot be used together. Use --schema=NAME for one schema or --all-schemas for every schema.`
- **D-16:** **The task raises on unknown or invalid switches.** Today the third element of `OptionParser.parse` is discarded, so a typo like `--stict` or `--all-schema` silently passes CI.
  - CHANGELOG lists this under Fixed.
  - Accepted by the maintainer as part of this phase.
- **D-17:** Telemetry: emit exactly **one** `[:threadline, :health, :checked]` event per `--all-schemas` run, with grand totals, not N events. Its metadata is `%{}`, so N events would read as N full checks.
  - The 14-event registry is unchanged.

### D. `:unresolved_legacy_keys` (HLTH-03) and fail-fast doc (HLTH-04)
- **D-18:** New **public** `Threadline.Health.legacy_key_findings/1`.
  - Same `:repo`/`:schema` options as `trigger_findings/1`; returns `[Finding.t()]` sorted `{schema, table, code}`.
  - Accepted by the maintainer as the one new public surface this phase. It must be callable from a release or remote console, where there is no `mix`.
  - Fold it into the 1.0 API contract inventory (v1.45).
  - **`trigger_findings/1` is untouched.** It stays a zero-grant catalog check: `pgbouncer_topology_test.exs:50-77` pins that a role with no grants gets the same findings as the owner.
  - **Only `mix threadline.health.coverage` calls it**, concatenating it with the trigger findings. `verify_coverage` stays catalog-only, which keeps the data scan out of the CI gate.
  - **No new telemetry event.** `findings_checked` keeps counting only `trigger_findings/1`.
- **D-19:** Probe per table; never a global `GROUP BY`, which would mean a seq scan plus detoasting `data_after` on 100M rows.
  - Drive the probes from `TriggerCatalog.threadline_triggers/1`, probing only tables whose current trigger records key args (regenerated tables).
  - Legacy no-args tables already get `:legacy_trigger_no_pk_args`, and they surface the new finding after regeneration.
  - The predicate mirrors the guide's backfill predicate exactly and is served by `audit_changes_row_history_idx`:
  ```sql
  SELECT count(*) FROM (
    SELECT 1 FROM <StorageSchema-qualified audit_changes>
    WHERE table_schema = $1 AND table_name = $2
      AND table_pk = ANY (ARRAY['{"id": null}', '{}']::jsonb[])
      AND op IN ('insert', 'update')
      AND data_after ?& $3::text[]
      AND NOT EXISTS (SELECT 1 FROM unnest($3::text[]) k WHERE data_after ->> k IS NULL)
    LIMIT 10001
  ) s
  ```
  - `$3` is the trigger's key columns in key order.
  - The count is capped at 10,000 ("at least 10000"), reusing the `export.ex` 10,000+ convention.
  - `{"id": null}` is never a resolved key by construction (`primary_key_sql.ex:35-47,164`).
- **D-20:** Timeout safety:
  - All probes run in one `repo.transaction` with `SET LOCAL statement_timeout` (default 15s, option `:statement_timeout`; PgBouncer-safe).
  - On cancel (typically a missing row-history index), the task prints a one-line hint pointing to `guides/upgrading-to-0.11.md#step-4-add-the-row-history-index` and carries on.
  - A timeout never fails `--strict`.
  - The planner decides whether the public function raises or returns a sentinel. Either way, its moduledoc must document the behavior.
- **D-21:** **Count only rows the backfill can fix.** DELETE rows and rows whose key columns were redacted are excluded, and documented once with a link to `#what-cannot-be-recovered`.
  - Running the guide's SQL therefore always drives the warning to zero.
  - Tables with only unrecoverable rows produce no finding.
  - Dropped tables produce no finding (no trigger, so no key columns), which is intended and documented.
- **D-22:** Use `StorageSchema.table("audit_changes", opts)` for the qualified name. Never rely on an unprefixed or `search_path` lookup; that is a past defect class.
  - Exclude the storage schema's own tables.
  - `Finding.schema`/`table` is the host table.
  - `:schema` filters by host schema.
- **D-23:** Finding fields:
  - `severity: :warning`
  - `details: %{"unresolved_count" => n, "capped" => boolean, "key_columns" => [...]}`
  - message (use "at least 10000" when capped): `"<schema>.<table> has N INSERT/UPDATE audit rows captured before its trigger was regenerated with no resolved primary key; history/3 cannot find them by key. Run the backfill in guides/upgrading-to-0.11.md#step-6-optional-backfill-unresolved-primary-keys."`
- **D-24:** `Finding` moduledoc and docs:
  - Add the code to the `Finding.code()` union and the Codes list.
  - The opening line names both `trigger_findings/1` and `legacy_key_findings/1`.
  - Add "the code list may grow in any minor release; match with a catch-all clause".
  - Add `LegacyKeyFindings.codes/0` and extend `test/threadline/health_findings_doc_contract_test.exs` to iterate over `TriggerFindings.codes() ++ LegacyKeyFindings.codes()`.
  - Add the code to `guides/domain-reference.md`.
  - The new code breaks no consumer; nothing `case`s on `f.code`.
- **D-25:** HLTH-04: the canonical sentence goes in the Failure-mode cell of the `trigger_capture` row in `guides/configuration-and-commands.md` (~22): "Malformed configuration raises `ArgumentError` (the health and coverage tasks stop with `Mix.raise`); it is never reported as a health finding."
  - Echo it in one line of the `Finding` moduledoc.
  - Pin it in a doc-contract test.
- **D-26:** Fixtures:
  - Extend `test/threadline/upgrade_backfill_test.exs`, which uses the frozen `LegacyTriggerSQL` 0.10.2 trigger with the real `{"id": null}` shape. Cover:
    - the finding is present after regeneration and before backfill
    - it is absent after the guide's marker-extracted SQL runs
    - DELETE rows remain but are not counted
  - Add a focused direct-insert test covering:
    - the `{}` variant
    - the cap (planner may expose an `@doc false` cap option)
    - a non-default storage schema via `StorageSchemaCase.with_storage_schema("audit", …)`
    - `:schema` filtering
    - a table whose trigger has no key args yields nothing
  - Plain `async: false`, no SQL Sandbox (repo convention).

### Cross-cutting
- **D-27:** One CHANGELOG "Unreleased" section covers all of it:
  - additions: `:limit`, `--strict`, `--all-schemas`, `legacy_key_findings/1` and the new code
  - Fixed: unknown switches now raise
  - no Breaking entries
- **D-28:** VERIFICATION.md reports suite wall clock before and after (ROADMAP success criterion 5). Compare against the phase-225 partitioned baseline.

### Claude's Discretion
- Exact stderr status-line wording, and column widths and padding in the `--all-schemas` table.
- Whether the timed-out legacy probe surfaces as a raise or a sentinel in the public function (D-20).
- Module and file split (e.g. `lib/threadline/health/legacy_key_findings.ex`, location of the batched catalog helper).
- Whether to add an optional incident-playbook sentence about `limit:` with a matching contract assertion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and prior research
- `.planning/REQUIREMENTS.md` — QRY-01, QRY-02, HLTH-01..04 (locked WHAT), and the anti-features table (no `gen.backfill`, no `:invalid_config`).
- `.planning/ROADMAP.md` §Phase 229 — success criteria 1-5.
- `.planning/research/FEATURES.md` §B (history `:limit`), §C (`--strict`, `:invalid_config`, `--all-schemas`), §D (backfill generator vs health signal).
- `.planning/PROJECT.md` — v1.45 "1.0 API Contract" consolidation; do not pre-empt it.

### Code
- `lib/threadline/query.ex` (~396-441) — `history/3`, `history_query/3`, `where_row/2`, `row_history_query/3`.
- `lib/threadline.ex` (~76-95) — public `history/3` docs.
- `lib/threadline/evidence.ex` (~313-317, ~345-346) — `validate_limit!/1` and `maybe_limit` precedent.
- `lib/threadline/query/cursors.ex` (~137-143) — `timeline_page_size!/1` (do not generalise).
- `lib/mix/tasks/threadline.health.coverage.ex` — the task being extended.
- `lib/mix/tasks/threadline.verify_coverage.ex` (~83-85) — `exit({:shutdown, 1})` precedent; stays catalog-only.
- `lib/threadline/health.ex`, `lib/threadline/health/finding.ex`, `lib/threadline/health/trigger_findings.ex`, `lib/threadline/health/trigger_catalog.ex`, `lib/threadline/health/coverage_schemas.ex`.
- `lib/threadline/storage_schema.ex` — `StorageSchema.table/2`, `@threadline_tables`.
- `lib/threadline/capture/primary_key_sql.ex`, `lib/threadline/capture/row_history_index_sql.ex` — key resolution and the row-history index.
- `lib/threadline/telemetry.ex`, `guides/telemetry.md` — 14-event registry (unchanged this phase).

### Guides
- `guides/upgrading-to-0.11.md` — Step 4 index anchor, Step 6 backfill SQL and anchor, `#what-cannot-be-recovered`.
- `guides/configuration-and-commands.md`, `guides/domain-reference.md`, `guides/operator-surface.md`, `guides/production-checklist.md`.

### Tests to extend or update
- `test/threadline/operator_surface/coverage_mix_test.exs`, `test/threadline/operator_surface/coverage_doc_contract_test.exs`.
- `test/threadline/verify_coverage_task_test.exs` (exit-capture pattern).
- `test/threadline/health_findings_doc_contract_test.exs`, `test/threadline/pgbouncer_topology_test.exs` (must stay green unchanged).
- `test/threadline/upgrade_backfill_test.exs`, `test/support/property_runs.ex`, `test/threadline/query_test.exs`.

### Project DNA
- `prompts/threadline-elixir-oss-dna.md` — named verify entrypoints, doc contract tests, honest default tests.
- `prompts/audit-lib-domain-model-reference.md` — domain language.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Evidence.validate_limit!/1` / `maybe_limit/2`: the message and shape to mirror for `history/3`.
- `CoverageSchemas.available/1` / `validate/2`: the schema predicate and edge validation for `--all-schemas` and `--schema`.
- `TriggerCatalog.threadline_triggers/1`: already decodes `tgargs` into key columns, and drives the legacy-key probes.
- `Threadline.Test.LegacyTriggerSQL` (0.10.2 trigger) and the `upgrade_backfill_test.exs` marker-extracted guide SQL: the pre-0.11 fixture.
- `PropertyRuns.db` + `RowHistoryGenerators.history_gen/0`: the `:limit` prefix property.
- `StorageSchemaCase.with_storage_schema/2`: the prefix-correctness test.

### Established Patterns
- Error-fails, warning-never-fails gate split (`verify_coverage`).
- Additive JSON keys only. Default output must stay byte-identical.
- `Mix.raise` for usage and config errors. `exit({:shutdown, 1})` for gate results.
- No SQL Sandbox; DB tests are `async: false` with committed transactions.
- Every storage-table query must be prefix-qualified (past `Repo.all(AuditChange)` defect class).

### Integration Points
- `health.coverage` `run/1`: option parsing (strict + invalid-switch raise + mutual exclusion before the repo starts), then findings concatenation (`trigger_findings ++ legacy_key_findings`), then render, then the strict gate.
- `trigger_coverage/1`: extract the pure classifier, shared with the batched all-schemas path.

</code_context>

<specifics>
## Specific Ideas

- kubectl `-A` is the model for `--all-schemas` (a SCHEMA column), but unlike kubectl, conflicting flags error instead of silently overriding.
- golangci-lint, sobelow and verify_coverage-style "issues → exit 1" gating; stdout stays machine-pure under `--json`.
- Rails `audited`/PaperTrail/Logidze/Carbonite all ship backfill as docs plus SQL; Threadline adds the detector they lack, kept cheap (index-bound, capped, time-limited) and clearable.

</specifics>

<deferred>
## Deferred Ideas

- **Coverage/findings exclusion mismatch:** coverage excludes 3 Threadline tables but findings exclude all 7 `@threadline_tables`, so `threadline_export_jobs`, `threadline_retention_runs`, `threadline_saved_views` and `threadline_evidence_records` show as "uncovered" today. Extension-member tables (e.g. `spatial_ref_sys`, pg_partman `part_config`) do too. Fixing this changes default output and needs its own backlog item and scope decision.
- **v1.45 API contract:** consider an umbrella `Health.findings/1` with a single telemetry event; a public multi-schema coverage API; a `@spec` for `history/3`'s opts; `:limit` on `timeline/2`, `actor_history/2` and `row_history`.
- **`actor_history/2` validation:** it already accepts an **unvalidated** `:limit` (`lib/threadline/query.ex:534`). `limit: 0` yields `LIMIT 1` with page math on 0, and negative values reach SQL. Fix as part of v1.45.
- **Separate exit codes** (1 = findings, 2 = usage) across all mix tasks: only as a coordinated later change.
- **`--fail-on-uncovered`** for `health.coverage`: only if a future requirement asks for it.
- **`--summary` condensed output** for `--all-schemas` with very many schemas: additive later if adopters ask.

</deferred>

---

*Phase: 229-adopter-api-and-health-additions*
*Context gathered: 2026-10-02*
