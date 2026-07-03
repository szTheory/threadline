# Phase 190: Storage Schema Confidence and Host-Schema Truth - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 190 proves or fixes Threadline's configurable PostgreSQL `storage_schema` story beyond the default `threadline` schema. The phase must make `storage_schema: "audit"` trustworthy across Threadline-owned capture, query, semantics, evidence, governance, export, retention, and operator-relevant paths; repair or narrow generated migration SQL; and make non-public host-table assumptions explicit.

This phase owns executable proof and fixes for `SCHEMA-01`, `SCHEMA-02`, `SCHEMA-03`, and `SCHEMA-04`. It may edit storage-schema helpers, Ecto schema prefixes, generated migration SQL, trigger SQL generation, query/repo-prefix plumbing, focused tests, operator-relevant coverage/redaction behavior, and docs/contracts needed to make current public behavior true.

This phase does not add new operator product scope, public component APIs, compliance packs, runtime destructive redaction, WAL/CDC, external pilots, broad CI optimization, or a new storage backend. It should not change capture/query/auth semantics except where current storage-schema or host-schema behavior is false or misleading.

</domain>

<decisions>
## Implementation Decisions

### Custom-Schema Proof Bar

- **D-190-01:** Use a layered custom-schema proof bar. A `storage_schema: "audit"` claim is closed only when real PostgreSQL integration proof installs Threadline-owned tables/functions in `audit`, keeps sentinel data in default `threadline`, and proves the selected path mutates or returns only `audit` rows.
- **D-190-02:** The core gate is targeted DB integration proof, not browser E2E. Source/string contracts remain required for identifier validation, generated migration SQL, and trigger SQL, but they are not sufficient for `SCHEMA-01` or `SCHEMA-02`.
- **D-190-03:** Broad example/browser proof is optional release confidence. Use narrow operator smoke only for direct LiveView/controller/Mix-task reads that targeted Ecto tests cannot cover cleanly.
- **D-190-04:** The proof matrix must cover capture, timeline/query, semantic action linking, evidence records, export jobs/status/download, retention runs, saved views where relevant, and operator-relevant reads. Any path not fixed must be explicitly documented and test-locked as unsupported.
- **D-190-05:** Tests should include sentinel or isolation behavior that would fail if any path silently reads from or writes to `threadline` while the requested/configured storage schema is `audit`.

### Ecto Prefix Contract

- **D-190-06:** Storage schema resolution is `storage_schema:` per-call opts over `config :threadline, :storage_schema`, defaulting to `"threadline"`. This gives normal adopters a configure-once path while preserving explicit, testable overrides.
- **D-190-07:** Remove fixed `@schema_prefix "threadline"` from Threadline-owned Ecto schemas. Ecto query prefix precedence means repo `prefix:` is only a fallback for query reads/joins when a schema already declares `@schema_prefix`; keeping fixed prefixes risks split-brain behavior where writes can land in `audit` while reads still hit `threadline`.
- **D-190-08:** All Threadline-owned Repo reads, writes, joins, bulk operations, preloads, background jobs, and operator reads must execute with `StorageSchema.repo_opts/1` or an explicit equivalent resolved prefix.
- **D-190-09:** Async/export/retention behavior must be deliberate. Either jobs use the global configured storage schema by contract, or they persist/pass the resolved storage schema so a later config change cannot silently move a queued job.
- **D-190-10:** Add static and runtime contracts that fail on omitted prefix plumbing: no owned schema may reintroduce fixed `@schema_prefix "threadline"`, and representative generated query SQL or DB behavior must prove joins/preloads use `"audit"` under the custom schema.

### Migration Identifier Contract

- **D-190-11:** Support any validated single PostgreSQL identifier as `storage_schema`, recommend lowercase snake_case for operator ergonomics, and double-quote the validated identifier in every generated raw SQL reference.
- **D-190-12:** Runtime helpers and generated migrations must share identifier semantics. Threadline must not mix quoted and unquoted storage-schema references, rely on PostgreSQL case folding, or rely on `search_path` for Threadline-owned objects.
- **D-190-13:** `storage_schema` is one identifier segment, not `schema.table`. Valid examples include `audit`, `threadline`, `AuditLog`, and `_audit1`; invalid examples include `bad-name`, `foo.bar`, `threadline;drop schema public`, and empty values. Tightening length and `pg_*` handling is allowed if tests/docs lock the final contract.
- **D-190-14:** Generated migrations freeze the configured schema at generation time. Docs should tell adopters to set `storage_schema` before `mix threadline.install`; changing it later requires deliberate migration work, not a runtime-only config edit.
- **D-190-15:** Ecto.Migration `prefix:` helpers may be used for future table/index cleanup, but they do not replace the raw-SQL quote contract for `CREATE SCHEMA`, PL/pgSQL functions, triggers, and explicit DDL.

### Non-Public Host-Table Boundary

- **D-190-16:** Treat non-public host tables as supported by explicit schema-qualified identity, not by implicit `search_path`. `support.tickets` must work where Threadline claims host-schema support.
- **D-190-17:** The Phase 190 host-schema proof/fix should cover trigger generation, selected-schema coverage/verification, redaction drift inspection, timeline filtering by `table_schema` + `table`, and continuity readiness. Defaults remain `public`; do not introduce all-schema polling.
- **D-190-18:** Keep Threadline storage schema and captured host table schema separate in API, docs, tests, and UI. `storage_schema: "audit"` controls Threadline-owned tables; `table_schema: "support"` or `--schema=support` identifies host tables being audited.
- **D-190-19:** Bare table names remain public-schema shorthand where already supported. Schema-qualified names such as `support.tickets` are the non-public host-table path and must avoid duplicate table-name ambiguity where possible.
- **D-190-20:** If row-history schema mapping cannot fully disambiguate duplicate table names across host schemas in this phase, document and test-lock the exact limit rather than implying broad support.

### Operator And DX Guidance

- **D-190-21:** User-facing CLI/UI copy should stay operator/JTBD focused: "Storage schema", "Host schema", "Audit coverage for support", and "Redaction drift for support.tickets" are acceptable; leaking Ecto prefix internals into operator copy is not.
- **D-190-22:** Coverage/redaction UI changes, if needed, should reuse existing controls and design-system patterns: native schema selector, readable table labels, status chips, actionable next-step copy, dark/light/system parity, and existing accessibility/focus behavior.
- **D-190-23:** Developer DX should prefer one calm happy path: configure `storage_schema: "audit"`, run generated migrations, generate triggers for `support.tickets` when needed, then verify with named commands. Avoid requiring adopters to understand Ecto prefix precedence to use the library correctly.
- **D-190-24:** Errors and docs should be explicit when behavior is unsupported or misconfigured. Silent fallback to `threadline` or `public` is worse than a clear failure.

### Claude's Discretion

Downstream agents may choose the exact file/test organization, helper names, and whether to use SQL shape assertions, sentinel rows, or both for individual paths. They should preserve the locked contracts above: layered real-DB proof, no fixed owned-schema prefix, quoted generated identifiers, explicit host-schema identity, and no scope expansion.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` — Phase 190 goal, success criteria, and v1.39 sequencing.
- `.planning/REQUIREMENTS.md` — `SCHEMA-01`, `SCHEMA-02`, `SCHEMA-03`, `SCHEMA-04`, v1.39 invariants, and out-of-scope boundaries.
- `.planning/PROJECT.md` — current v1.39 posture, storage-schema trust decision, and project/product invariants.
- `.planning/STATE.md` — active phase state, v1.39 decisions, and residual ownership.
- `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md` — authority hierarchy, triage taxonomy, and no-scope-creep rules inherited by Phase 190.
- `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` — ranked storage-schema finding that routes this work to Phase 190.

### Storage Schema And Migration Code

- `lib/threadline/storage_schema.ex` — storage-schema validation, quoting, qualification, host-table parsing, and repo prefix helper.
- `lib/threadline/capture/migration.ex` — generated capture migration content currently interpolates unquoted storage schema.
- `lib/threadline/semantics/migration.ex` — generated semantics migration content currently interpolates unquoted storage schema.
- `lib/threadline/governance/migration.ex` — generated governance migration content currently interpolates unquoted storage schema.
- `lib/threadline/capture/trigger_sql.ex` — trigger/function SQL generation already uses storage helper for owned storage and qualified host tables.
- `lib/mix/tasks/threadline.gen.triggers.ex` — trigger migration generator and host table parsing entrypoint.
- `lib/mix/tasks/threadline.install.ex` — install task if present; planner should inspect before implementation.

### Owned Ecto Schemas And Storage Paths

- `lib/threadline/capture/audit_transaction.ex` — owned Ecto schema with current fixed prefix and transaction/action association behavior.
- `lib/threadline/capture/audit_change.ex` — owned Ecto schema with current fixed prefix and change/transaction association behavior.
- `lib/threadline/semantics/audit_action.ex` — owned Ecto schema with current fixed prefix and semantic action behavior.
- `lib/threadline/governance/evidence_record.ex` — owned Ecto schema for evidence records.
- `lib/threadline/governance/retention_run.ex` — owned Ecto schema for retention run metadata.
- `lib/threadline/governance/export_job.ex` — owned Ecto schema for queued export jobs.
- `lib/threadline/governance/saved_view.ex` — owned Ecto schema for saved operator filter views.
- `lib/threadline.ex` — public `record_action/2` and top-level query/export delegators.
- `lib/threadline/audit.ex` — audited transaction helper and action linkage updates.
- `lib/threadline/query.ex` — timeline/history/as-of/actor/correlation query paths and existing `storage_schema:` opts.
- `lib/threadline/evidence.ex` — evidence write/read helpers and existing storage opts use.
- `lib/threadline/export.ex` — export read/count/stream paths.
- `lib/threadline/export/orchestrator.ex` — export job fetch/update paths.
- `lib/threadline/export/cleanup_task.ex` — export cleanup paths.
- `lib/threadline/retention.ex` — retention purge and retention run tracking.
- `lib/threadline/retention/pruner.ex` — retention run pruning/update path.

### Host-Schema Coverage, Policy, And Operator Surfaces

- `lib/threadline/health.ex` — trigger coverage by selected host schema.
- `lib/threadline/health/coverage_schemas.ex` — user-facing schema validation and available-schema listing.
- `lib/threadline/policy/redaction_presenter.ex` — redaction drift presenter with selected host schema query.
- `lib/mix/tasks/threadline.health.coverage.ex` — coverage viewer CLI and `--schema` behavior.
- `lib/mix/tasks/threadline.verify_coverage.ex` — positive-list coverage gate and `--schema` behavior.
- `lib/mix/tasks/threadline.policy.show.ex` — redaction policy CLI; currently defaults/pins public unless extended.
- `lib/threadline/continuity.ex` — continuity readiness path; inspect for public-schema assumptions.
- `lib/threadline/operator_surface/live/coverage_live.ex` — selected host-schema coverage UI and schema picker.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` — redaction drift UI; inspect for public-schema assumptions.
- `lib/threadline/operator_surface/live/timeline_live.ex` — timeline saved views, export job creation, and preloads.
- `lib/threadline/operator_surface/live/export_status_live.ex` — export status reads/updates.
- `lib/threadline/operator_surface/live/evidence_live.ex` — evidence operator reads.
- `lib/threadline/operator_surface/live/retention_history_live.ex` — retention history reads and prune action audit.
- `lib/threadline/operator_surface/live/start_live.ex` — operator home warnings and saved views.
- `lib/threadline/operator_surface/controllers/export_controller.ex` — export download job fetch.
- `guides/operator-surface.md` — operator coverage/redaction/schema docs and row-history schema mapping.
- `guides/domain-reference.md` — domain model, trigger coverage, redaction drift, continuity, and operational language.

### Existing Tests And Proof Surfaces

- `test/threadline/storage_schema_test.exs` — storage schema helper contracts.
- `test/threadline/storage_schema_migration_contract_test.exs` — generated migration SQL contracts to update.
- `test/threadline/capture/trigger_sql_storage_schema_test.exs` — trigger SQL storage-schema and host-table contracts.
- `test/threadline/query_test.exs` — query behavior and candidate custom-schema coverage.
- `test/threadline/evidence_test.exs` — evidence behavior and candidate storage-schema coverage.
- `test/threadline/retention_test.exs` — retention behavior and candidate storage-schema coverage.
- `test/threadline/verify_coverage_task_test.exs` — coverage CLI behavior.
- `test/threadline/verify_coverage_policy_test.exs` — coverage policy behavior.
- `test/threadline/policy/redaction_presenter_test.exs` — redaction drift classification.
- `test/threadline/policy/redaction_presenter_catalog_test.exs` — redaction catalog behavior.
- `test/threadline/operator_surface/live/coverage_live_test.exs` — coverage UI behavior.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` — redaction UI behavior.
- `test/threadline/operator_surface/live/evidence_live_test.exs` — evidence UI behavior.
- `test/threadline/operator_surface/live/export_status_live_test.exs` — export status UI behavior.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` — retention UI behavior.

### Prompt Corpus

- `prompts/audit-lib-domain-model-reference.md` — canonical Threadline product thesis, personas, JTBD, capture/semantics/operations separation, and operational confidence language.
- `prompts/threadline-elixir-oss-dna.md` — verification-as-product-surface, doc contracts, examples, pitfalls ledger, and release/documentation habits.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — lessons from Carbonite, PaperTrail, ExAudit, django-auditlog, django-simple-history, Logidze, Audited, Envers, JaVers, and Audit.NET.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — Ecto prefixes, migrations, database constraints, testing against real DB, and multi-tenancy cautions.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — library configuration, HexDocs, examples, and upgrade/migration guidance.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — release/runtime config, deliberate migrations, DB observability, and SRE posture.
- `brandbook/index.html` — newer brand and voice reference if user-facing copy is touched; prefer it over older prompt-era brand material.

### External Primary References Used During Discussion

- `https://ecto.hexdocs.pm/Ecto.Schema.html` — `@schema_prefix` behavior and schema prefix semantics.
- `https://ecto.hexdocs.pm/Ecto.Repo.html` — repo operation `:prefix` behavior.
- `https://github.com/elixir-ecto/ecto/blob/master/guides/howtos/Multi%20tenancy%20with%20query%20prefixes.md` — Ecto query prefix precedence and prefix tradeoffs.
- `https://ecto-sql.hexdocs.pm/Ecto.Migration.html` — Ecto migration prefix behavior for tables/indexes.
- `https://www.postgresql.org/docs/current/sql-syntax-lexical.html` — quoted identifier behavior and case folding.
- `https://www.postgresql.org/docs/current/ddl-schemas.html` — PostgreSQL schemas and `search_path` considerations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.StorageSchema.get/1`, `quote_ident/1`, `qualify/2`, `table/2`, `function/2`, and `repo_opts/1` already provide the right central seam for storage-schema resolution and quoting.
- `Threadline.StorageSchema.parse_table_identifier/1`, `qualified_host_table/1`, and `host_table_suffix/1` already support `support.tickets`-style host table identifiers.
- `Threadline.Capture.TriggerSQL` already emits quoted storage functions/tables and qualified host-table triggers for many paths.
- `Threadline.Query.storage_opts/2` already accepts a `storage_schema:` override, but fixed owned-schema prefixes can defeat it for query reads and joins.
- `Threadline.Health.trigger_coverage/1` already accepts `schema:` for host table coverage.
- `Threadline.Health.CoverageSchemas` already validates user-facing host schema names and lists available schemas.
- `Threadline.Policy.RedactionPresenter.build/1` already accepts a selected host schema internally.
- Existing doc-contract and source-contract tests are a good pattern for locking public docs and generated SQL.

### Established Patterns

- Threadline treats verification as a product surface through named `mix verify.*` and `mix ci.*` entrypoints.
- Public docs are guarded by doc contracts when they make adoption promises.
- Operator surfaces should remain host-owned, read-only where appropriate, and fail closed.
- Recent UI work established dark/light/system design-system parity; Phase 190 should reuse existing operator controls rather than create new UI patterns.
- Planning authority from Phase 189 says executable proof beats stale prose, and residuals should be visible rather than relabeled green.

### Integration Points

- Generated install migrations must use the same quote/qualify semantics as runtime helpers.
- Owned Ecto schema modules must stop forcing `threadline` so repo/query prefixes can work.
- Public APIs that already accept opts should propagate `storage_schema:` consistently.
- Operator LiveViews/controllers and background job code that call `StorageSchema.repo_opts()` without opts need review against the final global-vs-explicit contract.
- Host-schema support must connect trigger generation, coverage, redaction drift, continuity, timeline filters, and operator copy without confusing it with Threadline-owned storage.

</code_context>

<specifics>
## Specific Ideas

- User selected all four gray areas and requested subagent-backed research across architecture, SWE, DevOps/SRE, ecosystem prior art, DX, API consumer perspective, JTBD, and UI/UX where applicable.
- Four advisor researchers were used:
  - Custom-schema proof bar: recommended layered proof with a real PostgreSQL `audit` integration gate.
  - Ecto prefix contract: recommended global default plus per-call override, and removal of fixed `@schema_prefix "threadline"` from owned schemas.
  - Migration identifier contract: recommended fully quoted validated identifiers everywhere while recommending lowercase snake_case.
  - Non-public host-table boundary: recommended explicit schema-qualified support for `support.tickets` across already schema-aware surfaces while keeping defaults public and avoiding all-schema polling.
- The recommendations are coherent: quote schema identifiers so generated SQL and runtime agree; remove fixed owned prefixes so Ecto can actually target the resolved schema; prove with real `audit` DB isolation; and handle host schemas through explicit table identity rather than search-path magic.
- Example happy path to preserve in docs/tests:
  - `config :threadline, storage_schema: "audit"`
  - `mix threadline.install`
  - `mix threadline.gen.triggers --tables support.tickets`
  - `mix threadline.verify_coverage --schema=support`
  - `mix threadline.policy.show --schema=support`
  - Timeline/query filters use `table_schema: "support"` and `table: "tickets"` where needed.
- Example failure mode to test: `threadline` and `audit` both contain plausible rows, but a custom-schema call must return only the `audit` rows.
- External ecosystem lessons to preserve:
  - Copy Carbonite's explicit audit-prefix/migration/query seriousness, not hidden magic.
  - Copy PaperTrail-style explicit prefix API ergonomics where useful, but avoid opt-in capture as the correctness model.
  - Avoid ExAudit-style opaque/process-local footguns.
  - Avoid Logidze-style connection-local/search-path surprises under pooling.
  - Keep audit storage SQL-native and operator-readable.

</specifics>

<deferred>
## Deferred Ideas

- A broad all-schema operator coverage/redaction scan is deferred. Phase 190 should keep selected-schema behavior and no all-schema polling.
- A full Ecto.Migration DSL rewrite is deferred. It may be useful later, but Phase 190's contract is quoted raw SQL plus focused fixes.
- Broad browser/example E2E for every storage-schema path is deferred unless planning finds a small high-value smoke. Targeted real-DB proof is the authority.
- Per-request multi-tenant Threadline storage is deferred. The phase supports one configured storage schema with explicit per-call override for tests/advanced callers, not arbitrary tenant storage routing.
- Full duplicate table-name row-history disambiguation across host schemas may be deferred only if documented and test-locked; planner should try to resolve it if the blast radius is small.
- No todo artifacts matched Phase 190, so none were folded or reviewed.

</deferred>

---

*Phase: 190-storage-schema-confidence-and-host-schema-truth*
*Context gathered: 2026-07-01*
