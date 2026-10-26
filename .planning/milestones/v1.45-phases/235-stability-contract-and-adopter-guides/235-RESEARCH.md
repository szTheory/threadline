# Phase 235: Stability Contract and Adopter Guides - Research

**Researched:** 2026-10-06  
**Domain:** Elixir library compatibility contracts, Ecto/PostgreSQL trigger migrations, redaction threat modeling, adopter documentation  
**Confidence:** HIGH for existing code paths and PostgreSQL behavior; MEDIUM for editorial recommendations and cross-project convention comparisons

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 — Carry forward the settled 1.x stability policy; do not reopen it.** `guides/stability.md` must explain the Elixir API tier and 1.x deprecation policy; the additive-only database contract for tables, columns, indexes, trigger-function naming, and `threadline.actor_ref`; the narrow security/correctness exception that may require trigger regeneration in a 1.x minor; the operator-surface boundary (HTML/CSS/LiveView internals are not API, while the router macro, options, and documented mount routes are); and the six-month security/correctness backport window for 0.12.x. It must also carry Phase 234 D-51: option `@type` names are stable and option lists are additive; runtime-neutral spec changes are minor or patch with a changelog note, and any narrowing that may warn Dialyzer users is called out.
- **D-02 — Preserve the stable struct-field subset and additive JSONB promise.** `AuditChange`, `AuditTransaction`, and `AuditAction` each document only their selected stable field subset. Their `t` types may gain fields, but the documented stable subset cannot silently shrink. `data_after`, `changed_fields`, and `changed_from` promise additive keys/shapes; they do not promise byte-stable JSON serialization. Pin each documented field set against `__schema__(:fields)`.
- **D-03 — Treat the database catalog and public sets as distinct contracts.** Use live PostgreSQL catalog assertions for required column names, types, nullability, and shipped indexes on `audit_transactions`, `audit_changes`, and `audit_actions`; use literal pins for `threadline.actor_ref` and the trigger-function naming scheme. Pin CSV/JSON export headers (with and without action metadata), `Health.Finding` codes, each Mix task's accepted flags, and `threadline_operator_surface/2` options and documented routes. Removal or rename must fail; additions must require a deliberate pin update. Prefer these focused assertions over byte snapshots or a production registry created only for tests.
- **D-04 — Make eligibility a pre-install decision aid.** Provide one concise matrix with columns for shape, support status, required conditions, and operational caveat/evidence. Answer whether the adopter can install before requiring them to understand Threadline internals. Cite the exact public option/name and the test or implementation evidence behind conditional claims.
- **D-05 — Adopt the maintainer's choice 1 (scope amendment): validate configured redaction columns at migration time.** Generated trigger migrations reject every `mask:` or `exclude:` name absent from the selected table before trigger DDL is installed or replaced. Test both invalid option paths and a valid-column control, including evidence that a rejected migration leaves no partially installed trigger. Database-aware existence validation belongs at migration time, where the table catalog is available; shape-only configuration validation cannot establish column membership.
- **D-06 — Describe exactly when that new check takes effect.** Trigger installation migrations are host-owned. Existing installed trigger definitions are not rewritten by adding validation to source; an adopter with an affected configuration must regenerate and run the trigger migration for that table. The check does not redact or repair already captured rows. Keep the error actionable so the adopter can identify the invalid option/column and table without exposing row data.
- **D-07 — Keep the threat guide proof-led and bounded to tested paths.** For every redaction claim, name the exact property test or health check and the data path it proves. `RedactionLeakPropertyTest` covers the generated per-table trigger path across stored rows/change records, diffs, and exports. `RedactionPolicyPropertyTest` validates policy shape. `RedactionPresenterTest` and `mix threadline.policy.show` compare configured and deployed policy; they do not validate column existence and do not create a health finding. Never present those checks as evidence for a guarantee they do not prove.
- State the residual plaintext locations required by DOCS-02: host source tables, WAL/logical decoding, replication slots, backups, superuser access, rows captured before a rule changed, and host logs. Also explain that Threadline cannot control copies made downstream from exports. Qualify every guarantee by its path, timing, and evidence; do not use unscoped absolutes.
- Keep the guide scoped to generated per-table trigger capture. The global redacted `TriggerSQL.install_function` path is not emitted by `gen.triggers`; direct `TriggerSQL.create_trigger/3` use can also bypass the generated path's redacted-primary-key guard. Neither path is covered by this migration-specific fix or by `RedactionLeakPropertyTest`; do not imply otherwise. Track both as separate follow-up gaps.
- **D-08 — Organize around three reader jobs, not implementation modules.** The stability guide answers “what can change in a 1.x upgrade?”; the table-shapes guide answers “will this table work before I install?”; the redaction guide answers “what is protected, what proves it, and where can plaintext remain?” Keep each claim near its evidence and use the domain nouns consistently.
- Use direct, answer-first headings, short qualified statements, minimal examples, and links to the canonical guide/test rather than copying long install instructions. Use the current Threadline Brand Book voice: precise, composed, clear, and calm. Explain backend details only where they change an adopter's installation or a security decision.
- This phase has no user-facing operator UI. Apply documentation accessibility through readable structure, descriptive links, explicit conditions, and examples that do not rely on color or screenshots; dark/light styling, hover/focus states, and graphic motifs do not apply here.
- **D-09 — Keep contract tests durable and attributable.** Prefer narrow tests with named fixtures and literal expected sets. Keep mutation controls for removal/rename and document-claim drift where they materially prove the gate. Reuse existing contract-test patterns; do not add a generic framework or hidden-test bypass. Continue to use named `mix verify.*` / `mix ci.*` entrypoints in contributor-facing instructions.

### the agent's Discretion

- Exact guide filenames/heading hierarchy where requirements do not already lock them; exact phrasing and error text; test module/file grouping; whether shared assertions live in an existing contract test or a focused sibling; and plan/wave split.
- Implement catalog validation in the existing migration-time SQL path that best matches the established code. Preserve the public host-owned migration boundary and avoid application-startup checks.
- Choose exact examples and evidence-link format. Keep examples executable against supported current APIs and avoid duplicating the README's golden install path.

### Deferred Ideas (OUT OF SCOPE)

- Exercise or remove the global redacted `TriggerSQL.install_function` path separately; `gen.triggers` does not emit it, so it is outside the selected migration guard and current redaction property proof.
- Close the direct `TriggerSQL.create_trigger/3` redacted-primary-key guard bypass in separately scoped work.
- Revisit causal ordering for `audit_changes`, capture fidelity for `numeric`/`timestamptz`, redaction history cleanup, retention, RLS, partitioning policy, and operator UI only when their owning requirement/phase calls for them.
- No repo-local `prompt.txt` was found. The user's inline prompt plus the current Threadline brand book and prompt/prior-art files are the applicable source material.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONTRACT-01 | An adopter can read `guides/stability.md` to learn what 1.x promises. | Preserve locked API/deprecation/database/operator/backport commitments and Phase 234 spec/type additivity in a prose contract with claim-level document tests. |
| CONTRACT-02 | A schema-snapshot test pins audit table columns, types, nullability, and shipped indexes. | Query PostgreSQL catalogs live and assert named required facts independently from literal public-name pins. |
| CONTRACT-03 | A test pins `threadline.actor_ref` and trigger-function naming literals. | Use explicit expected strings and source-use coverage so global rename/removal fails. |
| CONTRACT-04 | Additive-only allowlists pin export headers, health codes, Mix task flags, and operator router options/routes. | Use focused explicit-set contract tests patterned after `telemetry_registry_contract_test.exs`; require deliberate updates for new entries. |
| CONTRACT-05 | Three schema moduledocs list stable fields and additive JSONB key/shape semantics. | Keep an adopter-selected subset per schema; assert it remains included by `__schema__(:fields)` and separately test docs contain the additive, not byte-serialization, promise. |
| DOCS-01 | A supported-table-shapes guide lets an adopter decide before install if tables qualify. | Matrix should cite capture config, naming, key-shape, PK override, partition, and migration test evidence, and include all required caveats. |
| DOCS-02 | A redaction threat model explains bounded guarantees and plaintext locations. | Add generated-migration catalog guard, real PostgreSQL regressions, and evidence-linked threat prose with the stated trigger/previous-row/export limits. |
</phase_requirements>

## Summary

Phase 235 is a compatibility and proof-boundary phase, not a new product subsystem. Keep the existing trigger-backed capture boundary and encode three kinds of contract separately: live database facts (catalog), deliberate public allowlists (literal expected sets), and statements an adopter can read (guide/module docs). This decomposition makes a schema fact test the database's actual shape while a public API pin guards intentional names and options; broad snapshots conflate those jobs and create brittle noise. [VERIFIED: `.planning/phases/235-stability-contract-and-adopter-guides/235-CONTEXT.md`, D-01–D-09; `test/threadline/telemetry_registry_contract_test.exs`; `test/threadline/storage_schema_migration_contract_test.exs`]

For the redaction amendment, extend the existing generated per-table migration `DO` block in `PrimaryKeySQL`, where `tbl` is already resolved as a `regclass` and the block already has catalog-backed validation before its final dynamic trigger statement. Validate `exclude` and `mask` independently, and perform the check before trigger DDL. Keep values as escaped SQL string literals using the existing array-literal helper or safely bound values; do not interpolate a configured name as an SQL identifier. A failure should raise naming table, option, and offending column, without row data. The host migration's normal PostgreSQL transaction must leave no partial function/trigger/migration record; prove that through the existing real migration harness, not by asserting generated SQL text alone. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:120-197,209-296,365-430`; `test/threadline/capture/trigger_migrate_time_errors_test.exs`; Ecto SQL migration anatomy]

**Primary recommendation:** plan small contracts around live Postgres catalog shape, explicit additive allowlists, schema-doc field subsets, and three answer-first adopter guides. Add one migration-time check against `pg_attribute` to the detected-key and `primary_key:` override paths, then test invalid `exclude`, invalid `mask`, valid configured columns, and full rollback through generated host migrations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Trigger installation and redaction column validation | Database / Storage | API / Backend | The actual table columns are only knowable at migration execution; check PostgreSQL's catalog before replacing the row trigger. |
| Compatibility and public-surface contracts | API / Backend | Database / Storage | Elixir schemas, option lists, exports, tasks, and router macro are library-level contracts; DB table shapes are a separate catalog contract. |
| Adopter guides and threat model | API / Backend | — | These are versioned library documentation and test contracts, not operator UI. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | Project support floor: `~> 1.15`; runtime in this environment: OTP 27 | Compile-time contracts, ExUnit, task and verification entrypoints | Existing library and CI conventions; this phase adds no runtime dependency. [VERIFIED: `.planning/PROJECT.md`; `mix.exs`] |
| Ecto SQL / Postgrex | Ecto SQL 3.x project stack | Host-owned migration execution and SQL/catalog access | Existing migrations are emitted as host migration source and use `execute`; Ecto runs migrations transactionally by default. [VERIFIED: `.planning/PROJECT.md`; [Ecto migration anatomy](https://ecto-sql.hexdocs.pm/3.14.0/migration_anatomy.html)] |
| PostgreSQL | Existing project floor ≥14; generated trigger syntax requires PG14+ | Catalog queries, row triggers, migrations, and contract test database | PostgreSQL is the source of truth for table shape and trigger behavior; this phase introduces no database extension. [VERIFIED: `.planning/PROJECT.md`; `lib/threadline/capture/trigger_sql.ex`] |

### Supporting

| Library / facility | Purpose | When to Use |
|--------------------|---------|-------------|
| ExUnit + current `Threadline.DataCase` / `MigrationHarness` | Fast unit/document contracts and real-Postgres migration examples | Use async tests for pure text/set contracts; use non-async DB integration tests for migration/catalog behavior. [VERIFIED: existing test modules cited below] |
| PostgreSQL system catalogs (`pg_attribute`, `pg_index`, `pg_class`, `pg_trigger`) | Live catalog checks and trigger installation validation | Use in the generated migration and live-schema contract tests; `pg_attribute` associates a column name with relation OID and exposes dropped-column state. [CITED: [PostgreSQL `pg_attribute`](https://www.postgresql.org/docs/current/catalog-pg-attribute.html)] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Live catalog contract assertions | Checked-in SQL dump or byte-for-byte snapshot | A dump is easy to diff but can include irrelevant formatting/environment state; catalog assertions can focus on the promised facts and run on the exact supported DB. Use catalogs as D-03 decides. |
| Explicit allowlists | Generic test-only registry or deriving expected sets from production code | Derivation can mirror the same bug and cannot force intentional review of additions. Literal pins make removals fail and additions require review. |
| Generated migration-time validation | Config-shape validation at app/task startup or docs-only warning | Shape validation cannot establish table membership; docs alone leave a typo fail-open. Migration time is the first seam with the selected relation's catalog. |
| `pg_attribute` relation/name lookup | `information_schema.columns` | `information_schema` can be more portable, but this product is PostgreSQL-specific and the migration already uses PostgreSQL catalogs and resolved `regclass`; matching the existing catalog seam is simpler and handles schema identity directly. |

## Migration Guard Research

### Precise seam and SQL shape

`TriggerSQL.create_trigger/3` delegates to `PrimaryKeySQL.create_trigger_block/3`; that function has two branches: detected primary key and configured `primary_key:` override. Both branches currently compute `redacted_columns` and append `redaction_check_sql` after key-type validation and before `EXECUTE format(...)`, with `tbl` already bound to the selected relation. [VERIFIED: `lib/threadline/capture/trigger_sql.ex:224-234`; `lib/threadline/capture/primary_key_sql.ex:112-126,209-215,365-423`]

Add a separate helper for option/name existence rather than overloading the existing redacted-primary-key guard. For each non-empty option set, find any configured name for which no valid attribute exists on `tbl`. The catalog predicate should scope to the resolved relation and exclude system/dropped attributes, following the existing override check's pattern. The source catalog describes `attname`, `attrelid`, `attnum`, and `attisdropped`; using `tbl` avoids searching `search_path` by a bare table name. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:132,250-260`; [PostgreSQL `pg_attribute`](https://www.postgresql.org/docs/current/catalog-pg-attribute.html)]

Pseudocode for the SQL decision, not a final API contract:

```sql
SELECT configured.name
  INTO missing
  FROM unnest(<escaped configured names>) AS configured(name)
 WHERE NOT EXISTS (
       SELECT 1 FROM pg_attribute a
        WHERE a.attrelid = tbl
          AND a.attname = configured.name
          AND a.attnum > 0
          AND NOT a.attisdropped
 )
 LIMIT 1;
IF missing IS NOT NULL THEN
  RAISE EXCEPTION 'threadline: :mask column % of % does not exist', missing, '<qualified table>';
END IF;
```

The eventual SQL must distinguish `:exclude` from `:mask` in the actionable error, run each option check independently, and keep the configured values as values. Existing helpers double embedded single quotes when emitting text arrays; reuse this safe literal path or move to a bound runtime query only if the generated migration structure supports it. Table identifiers already come from `StorageSchema.qualified_host_table/1` and existing identifier validation; do not reintroduce raw identifier interpolation. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:122,409,425-430`; `lib/threadline/storage_schema.ex`; `lib/threadline/capture/trigger_capture_config.ex`]

The check must be emitted in both migration branches, before the trigger `EXECUTE`; the `primary_key:` override already has existence lookup for declared key columns, but that does not validate arbitrary mask/exclude columns. Keep this as database-aware validation. Do not move it into `TriggerCaptureConfig.load/1`, which is configuration normalization and has no database relation handle. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:120-197,209-296`; `lib/threadline/capture/trigger_capture_config.ex:12-38`]

### Atomic failure and rollout

Ecto SQL documents that migrations execute in a transaction by default; PostgreSQL also executes trigger effects within the initiating transaction, rolling back the statement/trigger effects on error. The generated migration may have created or replaced a function before the table-specific `DO` block, so the integration test must assert the whole migration rolls back: no Threadline trigger, no orphaned per-table function, no `schema_migrations` version row, and existing host writes still work. Existing migration refusal tests already assert these outcomes for neighboring validation failures. Do not disable the DDL transaction. [CITED: [Ecto migration anatomy](https://ecto-sql.hexdocs.pm/3.14.0/migration_anatomy.html); [PostgreSQL trigger behavior](https://www.postgresql.org/docs/current/trigger-definition.html)]; [VERIFIED: `test/threadline/capture/trigger_migrate_time_errors_test.exs:1-10,615-626`]

Adopter rollout remains explicit: source changes do not mutate already-installed host triggers. An adopter with a currently misspelled rule must correct config, regenerate the migration with `mix threadline.gen.triggers --tables ...`, then run `mix ecto.migrate`. This validation does not redact or rewrite earlier `audit_changes`; if the prior trigger captured values under the typo, those rows remain as stored. [VERIFIED: `lib/mix/tasks/threadline.gen.triggers.ex` (Rerunning section); `lib/threadline/capture/migration.ex`; CONTEXT D-06]

### Regression test design

Extend `TriggerMigrateTimeErrorsTest` or create a focused sibling only if test ownership becomes unclear. It already provisions real PostgreSQL fixtures, generates the host migration, calls the migrator, and checks absence of trigger/function/schema-migration row after refusal. [VERIFIED: `test/threadline/capture/trigger_migrate_time_errors_test.exs:1-10,50-75`]

Required cases:

1. A table with valid PK plus `exclude: ["missing_name"]`: migration raises, message identifies `exclude`, missing name, and qualified table; no trigger/function/migration row remains.
2. Same control for `mask: ["missing_name"]` to kill a mutant that only validates `exclude`.
3. Valid `exclude` and `mask` columns: migration succeeds, trigger exists, and a write demonstrates existing redaction semantics still work. Keep the test independent from “column list is syntactically valid” policy validation.
4. Exercise the configured `primary_key:` override path for column validation, either as a second invalid case or a deliberate matrix where invalid options are tested in both key-discovery paths. The locked minimum is invalid `mask`, invalid `exclude`, and valid control; implementing only one trigger branch would leave the feature incomplete.

The valid control matters because an over-broad catalog predicate could reject valid mixed-case/quoted columns or use the wrong schema. Include a schema-qualified fixture where practical; compare against `attname` exactly. Do not assert only generated SQL contains an error string. Existing error tests use `assert_raise(Postgrex.Error, ...)` with actual migration execution, which is the right level. [VERIFIED: `test/threadline/capture/trigger_migrate_time_errors_test.exs`; `test/threadline/capture/trigger_pk_override_test.exs`]

### Deliberate exclusions

This change covers generated per-table trigger migrations only. `TriggerSQL.install_function/1` has a global redacted SQL renderer and is not emitted by `mix threadline.gen.triggers`; `RedactionLeakPropertyTest` explicitly excludes it. Direct `TriggerSQL.create_trigger/3` can be used without `redacted_columns`, bypassing the redacted-primary-key guard. Leave both as separately tracked gaps and scope all docs/tests to the generated path. Do not infer column-existence health coverage from `RedactionPresenterTest`, `mix threadline.policy.show`, or `RedactionPolicyPropertyTest`; those prove policy agreement/shape, not table membership. [VERIFIED: `lib/threadline/capture/trigger_sql.ex:22-35,224-234`; `test/threadline/capture/redaction_leak_property_test.exs:26-28`; CONTEXT D-07]

## Architecture Patterns

### Contract ownership map

| Claim | Source of truth | Contract style |
|-------|-----------------|----------------|
| Audit storage columns/types/nullability/indexes | Running PostgreSQL DB | Catalog query with named tables and required tuples; compare required set as subset so a future additive column/index requires an explicit expected-set update. |
| GUC and trigger function naming | Public SQL/API contract | Literal strings plus assertions that production source uses them. |
| Export columns, health finding codes, task flags, router options/routes | Public API/options | Literal allowlists that assert observed ⊇ promised; error if removals occur, and report additions for intentional pin review. |
| Stable Ecto schema fields | Moduledoc + Ecto schema metadata | Each docs-selected field subset must be present in `__schema__(:fields)`; do not freeze all fields. |
| JSONB compatibility | Documented shape/key semantics | Assert promise text and key examples only; JSON object ordering/serialization bytes are explicitly not a contract. |
| Prose claims | Guide copy | Focused doc-contract tests for required topics, option names, evidence links, and scoped language; mutation controls should remove a required term/claim to show the guard is live. |

Ecto schemas describe the current field list, but pinning equality against the entire list would make additive `t` growth fail, contradicting D-02. Pin selected stable subsets with `Enum.all?(&(&1 in schema.__schema__(:fields)))`; additions are allowed, removal/rename of a promised field fails. JSONB is an application data contract about additive keys/shapes, not raw JSON bytes: canonical serialization order and whitespace should not be promised. [VERIFIED: CONTEXT D-02, D-03; `lib/threadline/capture/audit_change.ex`; `lib/threadline/capture/audit_transaction.ex`; `lib/threadline/audit_action.ex`]

### Supported table-shape matrix findings

The guide should put support decision first and conditions beside it. Keep the table short, and cite exact public option and a test/implementation source in the evidence column.

| Shape | Research guidance for the guide | Evidence / qualification |
|-------|---------------------------------|--------------------------|
| Single/composite and non-`id` primary key | Supported when the DB primary key uses the accepted key-type set; trigger args carry each key in PK order. | Existing key-resolution and shape tests. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:368-395`; `test/threadline/capture/trigger_pk_shapes_test.exs`] |
| No primary key | Supported only with `primary_key: [...]` in `config :threadline, :trigger_capture, tables:` and an exact-set, valid, immediate unique index over all non-null declared columns. No subset/superset, expression, partial, or nullable key set. | `PrimaryKeySQL` override validation and `trigger_pk_override_test.exs`; existing code documents the literal conditions. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:202-296`; `test/threadline/capture/trigger_pk_override_test.exs`] |
| Schema-qualified relation | Supported as `schema.table`; catalog resolution uses schema-qualified table token and `regclass`. | Naming and qualified-host-table helpers; cross-schema test fixture. [VERIFIED: `lib/threadline/capture/naming.ex`; `test/threadline/capture/trigger_pk_shapes_test.exs`] |
| Long table/schema identifiers | Supported through deterministic safe derived names; PostgreSQL default identifier ceiling is 63 bytes, not 63 characters. State exact generated function/trigger/migration behavior rather than claiming source names are unlimited. | `Naming` caps/derives names and tests pin behavior; PostgreSQL lexical docs confirm 63-byte default. [VERIFIED: `lib/threadline/capture/naming.ex`; [PostgreSQL lexical structure](https://www.postgresql.org/docs/current/sql-syntax-lexical.html)] |
| `char(n)` primary key | Supported, with caveat that `char(n)` comparison/padding can affect identity when key/table config changes; use exact implementation/test wording and avoid implying it behaves like `text`. | Existing key-type fixture covers `char`; cite the test and state the observed padding caveat narrowly. [VERIFIED: `test/threadline/capture/trigger_migrate_time_errors_test.exs`; CONTEXT D-04] |
| Partitioned table | Supported for row capture; PostgreSQL clones the parent row trigger on existing partitions and keeps clones on attached/new partitions. Threadline's physical leaf relation is recorded in captured row data. | Threadline partition test plus PostgreSQL CREATE TRIGGER documentation; note leaf-table evidence explicitly. [VERIFIED: `test/threadline/capture/trigger_pk_shapes_test.exs:351-430`; [PostgreSQL CREATE TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html)] |
| Unlogged table | Accepted, but its data/capture durability follows unlogged-table crash behavior and can be lost after crash. Do not frame acceptance as durable capture. | Phase CONTEXT D-04 fixes this caveat; source/test evidence must be checked before turning it into a stronger claim. [ASSUMED pending direct code/test citation] |
| View | Unsupported by this capture design: it requires a row-level `AFTER` trigger; PostgreSQL view row triggers are `INSTEAD OF`, while `AFTER` row triggers apply to tables/foreign tables. | PostgreSQL trigger matrix and generated DDL. [CITED: [PostgreSQL CREATE TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html)] |

Exact accepted key-type text from the implementation (preserve the caveats when copying this to the guide):

> DATA_38B1A7D2_START `Supported types: smallint, integer, bigint, text, varchar, char, citext, uuid, date, timestamp without time zone, enum types, and domains over these.` DATA_38B1A7D2_END

The implementation maps those SQL names to PostgreSQL catalog names as follows:

> DATA_F061C4A9_START `typname IN ('int2', 'int4', 'int8', 'text', 'varchar', 'bpchar', 'citext', 'uuid', 'date', 'timestamp')` DATA_F061C4A9_END

Both strings are verbatim from `lib/threadline/capture/primary_key_sql.ex:390,394` and should be cited by the guide contract. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:390-394`]

`char(n)` caveat and physical-leaf persistence deserve a final targeted source check during execution because they are user-visible details not established by the documentation reference alone. The plan should preserve the exact qualification from current test/code evidence rather than extrapolate from PostgreSQL semantics. [ASSUMED]

### Redaction proof model

The threat guide should group claims by data path and name the evidence adjacent to each statement:

| Path / statement | Evidence that can support it | Limits to state |
|------------------|------------------------------|-----------------|
| Generated per-table trigger omits configured excluded column from audit stored row payload and excludes it from changed fields | `RedactionLeakPropertyTest` through stored `audit_changes` and `audit_transactions` reads | Test is generated per-table path; masked column name may still appear in `changed_fields`, which reveals a value-change side channel. |
| Masked values are placeholders through stored change, diff, CSV/JSON/NDJSON exports | `RedactionLeakPropertyTest` | Qualify by the tested generated trigger + listed export paths. No downstream export consumer guarantee. |
| Configuration shape/overlap and placeholder validation | `RedactionPolicyPropertyTest` | This does not query the table catalog and does not prove a column exists. |
| Configured/deployed policy comparison | `RedactionPresenterTest` / `mix threadline.policy.show` | Reports policy drift; is not a column-name validation or health finding. |
| Invalid configured mask/exclude column refused before trigger install | New migration regression tests | Only migrations generated and applied after code/config correction; existing host migrations and earlier rows are untouched. |

List plaintext locations as explicit residual surfaces: source tables, WAL/logical decoding and replication slots, backups/PITR archives, superuser access, host application logs, rows recorded before rule changes, and copies made by downstream export consumers. PostgreSQL docs establish WAL stores database changes, logical decoding reads WAL, backups may include WAL archives, and superusers bypass permission checks; phrase each as possible deployment-dependent location, not as a claim every installation retains a readable copy. [CITED: [PostgreSQL logical decoding](https://www.postgresql.org/docs/current/logicaldecoding.html), [continuous archiving](https://www.postgresql.org/docs/current/continuous-archiving.html), [role attributes](https://www.postgresql.org/docs/current/role-attributes.html); CONTEXT D-07]

### Documentation UX and prior art

Recommend one landing guide per reader job, with an answer-first summary, conditions/evidence near the claim, then a short link to canonical install/config details. The shape guide is a decision aid; stability is reference; redaction is a security/threat-model explanation. Diátaxis distinguishes how-to guides (practical directions for an already competent user) from reference material (complete facts for doing work); this phase's three reader jobs justify separate pages rather than a monolithic guide organized by modules. [CITED: [Diátaxis start here](https://www.diataxis.fr/start-here/)]

Use the Threadline brand book voice: precise, composed, calm, and evidence-oriented; terms should be “AuditTransaction,” “AuditChange,” “AuditAction,” “ActorRef,” and “AuditContext” consistently with `AGENTS.md`. Accessibility here is structural: descriptive links, clear headings, explicit conditions, and text alternatives; no UI color or screenshot evidence is relevant. [VERIFIED: `prompts/Threadline Brand Book.txt`; `prompts/audit-lib-domain-model-reference.md`; `AGENTS.md`; CONTEXT D-08]

Carbonite is useful only as adjacent Elixir prior art for a trigger-backed audit approach, not as evidence for Threadline's API promise or threat guarantees. Do not make comparative claims about Carbonite unless the exact current code/doc page is inspected; the scope decisions are already fixed. [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Discover actual configured redaction columns | App-start registry, cached schema map, or hand-maintained list | Migration-time `pg_attribute` existence query scoped by resolved `tbl` | Only the selected database relation is authoritative at migration time; catalog data already powers key validation. |
| Track storage schema promises | Production schema registry solely for tests or full SQL snapshot | Test-only live catalog query with explicit expected required facts | D-03 explicitly chooses focused DB assertions; no runtime registry is needed. |
| Track public API additions | Dynamic reflection-only expected result | Explicit allowlist contracts | Reflection sees current surface but cannot distinguish intentional addition from accidental contract drift. |
| State redaction's threat boundary | Broad “all data is redacted” prose | Evidence-linked, path-qualified claims and a residual plaintext inventory | Redaction is a transform on selected generated-trigger paths; other copies and privilege levels remain. |

**Key insight:** these contracts protect different boundaries. The database catalog proves physical persistence, explicit sets protect named public promises, and property tests prove only the paths they execute. Treating them as one snapshot or one sweeping security claim weakens attribution.

## Common Pitfalls

### Pitfall 1: validating policy syntax but not table membership

**What goes wrong:** `:mask` or `:exclude` has correct list shape but a typo silently means the SQL policy cannot touch the intended column.  
**Why it happens:** current `RedactionPolicy` works without a connection and checks overlap/placeholder syntax, not actual relation columns.  
**How to avoid:** query the relation catalog in each generated trigger migration branch, before trigger DDL.  
**Warning signs:** error behavior differs between detected-PK and `primary_key:` tables; config is accepted even though the column does not exist. [VERIFIED: `lib/threadline/capture/redaction_policy.ex`; `lib/threadline/capture/primary_key_sql.ex:120-126,209-215`]

### Pitfall 2: unqualified names or unsafe SQL construction

**What goes wrong:** a same-named table in another schema passes validation, a dropped/system column appears valid, or a configured string changes generated SQL.  
**Why it happens:** catalog queries omit `attrelid`/dropped-column filtering or interpolate a name as an identifier.  
**How to avoid:** use existing resolved `regclass` (`tbl`), require `attnum > 0 AND NOT attisdropped`, compare exact catalog name, and quote configured values as SQL values.  
**Warning signs:** a test passes only on `public`, or a name containing `'` breaks generated SQL. [VERIFIED: `lib/threadline/capture/primary_key_sql.ex:132,252-260,425-430`; [PostgreSQL `pg_attribute`](https://www.postgresql.org/docs/current/catalog-pg-attribute.html)]

### Pitfall 3: only testing emitted SQL

**What goes wrong:** tests pass while the target Postgres rejects syntax, transaction rollback leaves state, or the wrong trigger branch runs.  
**How to avoid:** apply generated migration on real PostgreSQL; assert trigger/function/migration-table state after failure and a valid-column control. Preserve non-async DB fixture cleanup and host migration harness patterns. [VERIFIED: `test/threadline/capture/trigger_migrate_time_errors_test.exs`; `test/threadline/capture/trigger_pk_shapes_test.exs`]

### Pitfall 4: claiming historical rows are repaired

**What goes wrong:** an adopter assumes deploy-time validation retroactively removes data already captured with incorrect config.  
**How to avoid:** explicitly say regenerate and run host-owned migration for each affected table; previous trigger definitions and rows already captured remain as-is. [VERIFIED: `lib/mix/tasks/threadline.gen.triggers.ex` (Rerunning); CONTEXT D-06]

### Pitfall 5: broad redaction guarantees or wrong proof attribution

**What goes wrong:** readers infer global path/direct API coverage, downstream export control, or a health finding that does not exist.  
**How to avoid:** name `RedactionLeakPropertyTest` only for generated per-table trigger/storage/diff/export paths, `RedactionPolicyPropertyTest` for shape semantics, presenter/task for configured/deployed comparison, and new migration tests for column membership. Explicitly note the global installer and direct guard bypass. [VERIFIED: `test/threadline/capture/redaction_leak_property_test.exs:26-42`; CONTEXT D-07]

### Pitfall 6: freezing whole Ecto schemas or serialized JSON bytes

**What goes wrong:** harmless additive schema field/key changes become failures or undocumented promise growth happens.  
**How to avoid:** pin a deliberately selected stable field subset; ensure it's contained in live `__schema__(:fields)`. Describe JSONB as additive key/shape semantics and explicitly decline byte-stable encoding. [VERIFIED: CONTEXT D-02; phase requirement CONTRACT-05]

## Code Examples

### Existing generated trigger path (orientation only)

```elixir
TriggerSQL.create_trigger(table, :per_table, redacted_columns: redacted_columns)
```

This call currently delegates to `PrimaryKeySQL.create_trigger_block/3`; generated source supplies per-table policy and a host migration applies it. For the new guard, evolve the SQL block, not application startup. The exact discrete values in the example are quoted from `lib/threadline/capture/trigger_sql.ex:220-234`: `:per_table` and `:redacted_columns`. [VERIFIED: `lib/threadline/capture/trigger_sql.ex:220-234`]

### Catalog predicate shape

```sql
WHERE a.attrelid = tbl
  AND a.attname = configured_name
  AND a.attnum > 0
  AND NOT a.attisdropped
```

Bind `tbl` to the existing `regclass`, use exact `attname` equality, and keep values away from SQL identifier interpolation. PostgreSQL's `pg_attribute` documentation describes the relation and dropped status fields; current `primary_key:` override code already uses the same live-catalog membership pattern. [CITED: [PostgreSQL `pg_attribute`](https://www.postgresql.org/docs/current/catalog-pg-attribute.html); VERIFIED: `lib/threadline/capture/primary_key_sql.ex:132,252-260`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit; ExUnitProperties for existing redaction properties |
| Config file | `mix.exs`, `test/test_helper.exs`, `config/test.exs` |
| Quick run command | `mix test test/threadline/capture/trigger_migrate_time_errors_test.exs` |
| Full suite command | `mix ci.all` (canonical full verification); `mix verify.test` for test suite only |

### Phase requirements → test map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CONTRACT-01 | Required stability statements stay present | Doc contract | `mix test test/threadline/stability_doc_contract_test.exs` | ❌ Wave 0/new |
| CONTRACT-02 | Three storage table schemas and shipped indexes match PG catalog contract | DB integration | `mix test test/threadline/storage_schema_migration_contract_test.exs` or focused new contract file | Existing file; extend or sibling |
| CONTRACT-03 | GUC and trigger function naming literals stay pinned | Unit/source contract | `mix test test/threadline/capture/naming_contract_test.exs` | ❌ new |
| CONTRACT-04 | Export/health/task/router public sets remain additive | Contract | `mix test test/threadline/public_allowlists_contract_test.exs` | ❌ new, or focused siblings |
| CONTRACT-05 | Stable field subsets remain in schema and JSONB promise remains documented | Doc/schema contract | `mix test test/threadline/schema_stability_contract_test.exs` | ❌ new |
| DOCS-01 | Support matrix claims/options/name evidence stay in guide | Doc contract | `mix test test/threadline/supported_table_shapes_doc_contract_test.exs` | ❌ new |
| DOCS-02 | Redaction proof links, plaintext inventory, scoped statements, and migration failures | Doc + DB integration | `mix test test/threadline/redaction_threat_model_doc_contract_test.exs test/threadline/capture/trigger_migrate_time_errors_test.exs` | ❌ doc contract new; migration tests exist |

Do not create each suggested path verbatim if repository naming conventions make another structure clearer; keep tests narrow and named for the contract. Avoid a generic registry/framework. Tests are automatically included in `mix verify.test` and `mix ci.all`; no special alias should be needed. [VERIFIED: `mix.exs:144-150,233-266`; `AGENTS.md`]

### Sampling rate and mutation controls

- Per implementation task: focused test file(s) above.
- Per wave: `mix verify.test`.
- Phase gate: `mix ci.all`, plus independent prose review against code/tests as the judgment-check lane.
- Record a mutation for each meaningful contract class: delete/rename a promised DB column or index expectation; remove a public allowlist entry; remove a required prose claim; omit one redaction branch check; mutate catalog lookup to ignore schema or dropped columns. Verify mutant fails, restore source, rerun focused tests. Do not commit mutants. [VERIFIED: CONTEXT D-09; `AGENTS.md` zero-human-verification directive]

### Wave 0 gaps

- [ ] Create stability-guide doc contract and focused stable field/public allowlist assertions where no existing owner fits.
- [ ] Add generated migration tests for invalid `mask`, invalid `exclude`, valid control, and transactional rollback; decide coverage of both PK-resolution branches explicitly.
- [ ] Add table-shape and threat-guide doc contracts that inspect literal public options/routes and evidence links, and reject unscoped redaction absolutes.

## Security Domain

### Applicable ASVS categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No direct auth change | No authentication behavior in this phase. |
| V3 Session Management | No | No session code. |
| V4 Access Control | Yes, narrow | State clearly that database superuser access can bypass ordinary permission controls; redaction is not access control. |
| V5 Input Validation | Yes | Validate configured names against actual relation catalog before trigger DDL; preserve identifier/value separation. |
| V6 Cryptography | No new cryptography | No new crypto or secret handling. |

### Known threat patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Misspelled `mask`/`exclude` silently fails to cover intended field | Information disclosure | Fail closed at generated migration time and test both options against live PostgreSQL. |
| Schema confusion or dropped-column acceptance | Tampering / Information disclosure | Scope `pg_attribute` to resolved `regclass`, compare exact `attname`, exclude `attnum <= 0` and dropped columns. |
| Prior triggers and captured rows assumed to update automatically | Information disclosure | Explain host-owned migration regeneration and non-retroactive data behavior in guide. |
| WAL, backups, replicas, superuser access, host logs, downstream export copies | Information disclosure | Name as residual plaintext locations; no unqualified guarantee. |

## Project Constraints (from AGENTS.md)

- Keep capture, semantics, and exploration/operations responsibilities distinct; capture stays PostgreSQL trigger-backed and SQL-native.
- Preserve domain vocabulary: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`.
- Use named `mix verify.*` / `mix ci.*` commands in contributor-facing material; keep `mix test` honest and all contract tests in the normal test suite.
- No operator-UI work in this phase. Docs should follow the current Brand Book, not older voice references.
- Zero human verification by default: automated test checks for durable claims and independent agent review for prose clarity.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | Mix compile and tests | ✓ | OTP 27 observed; Elixir version not captured | None for execution |
| PostgreSQL | Live catalog contracts and migration regression | ✓ | Local server accepts `/tmp:5432`; server version not queried | CI/test PostgreSQL |
| Ecto SQL/Postgrex | Existing project migration/test stack | ✓ by project dependency lock; not invoked | Project Ecto SQL 3.x | None |

No packages need to be added for this phase. Package legitimacy audit is not applicable.

## Sources

### Primary / in-repository

- `.planning/phases/235-stability-contract-and-adopter-guides/235-CONTEXT.md` — locked scope, promises, and evidence boundaries.
- `.planning/REQUIREMENTS.md` CONTRACT-01–05 and DOCS-01–02; `.planning/ROADMAP.md` Phase 235 — acceptance and success criteria.
- `lib/threadline/capture/primary_key_sql.ex`, `trigger_sql.ex`, `trigger_capture_config.ex`, `redaction_policy.ex`, `migration.ex`, `lib/threadline/storage_schema.ex` — SQL catalog seam, options, identifier helpers, and host migration generation.
- `test/threadline/capture/trigger_migrate_time_errors_test.exs`, `trigger_pk_shapes_test.exs`, `trigger_pk_override_test.exs`, `redaction_leak_property_test.exs`, `redaction_policy_property_test.exs`, `test/threadline/storage_schema_migration_contract_test.exs`, `test/threadline/telemetry_registry_contract_test.exs` — current integration/property/contract patterns.
- `prompts/Threadline Brand Book.txt`, `prompts/audit-lib-domain-model-reference.md`, `prompts/threadline-elixir-oss-dna.md`, `prompts/THREADLINE-GSD-IDEA.md`, `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`, and `prompts/prior-art/oss-deep-research/{elixir-best-practices-deep-research.md,ecto-best-practices-deep-research.md,elixir-opensource-libs-best-practices-deep-research.md,elixir-oss-lib-ci-cd-best-practices-deep-research.md,elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md,phoenix-best-practices-deep-research.md,phoenix-live-view-best-practices-deep-research.md}` — product language, OSS, Elixir/Ecto/Phoenix practice.

### Official external references

- [PostgreSQL trigger behavior](https://www.postgresql.org/docs/current/trigger-definition.html) — row-level trigger support, transactional rollback, partition leaf behavior.
- [PostgreSQL `CREATE TRIGGER`](https://www.postgresql.org/docs/current/sql-createtrigger.html) — trigger matrix for tables/views, trigger replacement, partition clones.
- [PostgreSQL `pg_attribute`](https://www.postgresql.org/docs/current/catalog-pg-attribute.html) — catalog column names, relation OID, dropped-column marker.
- [PostgreSQL lexical structure](https://www.postgresql.org/docs/current/sql-syntax-lexical.html) — 63-byte default identifier length.
- [PostgreSQL logical decoding](https://www.postgresql.org/docs/current/logicaldecoding.html), [WAL archiving](https://www.postgresql.org/docs/current/continuous-archiving.html), [role attributes](https://www.postgresql.org/docs/current/role-attributes.html) — residual plaintext paths and superuser privilege.
- [Ecto SQL migration anatomy](https://ecto-sql.hexdocs.pm/3.14.0/migration_anatomy.html) — migration transactions and rollback behavior.
- [Diátaxis](https://www.diataxis.fr/start-here/) — separate how-to tasks from reference information.
- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html) — explicit threat boundaries and assets.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The unlogged-table operational caveat and physical leaf relation semantics are represented as specified in CONTEXT and should be checked against exact current code/test wording before prose is locked. | Supported table shapes | The guide could overstate durability or the relation recorded. |
| A2 | Carbonite is adjacent prior art for trigger-backed audit capture, but no version-specific feature comparison was needed or claimed. | Documentation UX and prior art | An unsupported comparative statement could mislead adopters. |

## Open Questions — Resolved for Phase 235

1. **Stable field subsets.** The plans select identity, grouping, payload, and semantic-context fields from the current Ecto schemas and adopter-facing domain documentation. `AuditChange` promises `[:id, :transaction_id, :table_schema, :table_name, :table_pk, :op, :data_after, :changed_fields, :changed_from, :captured_at]`; `AuditTransaction` promises `[:id, :txid, :occurred_at, :actor_ref, :action_id, :source]`; `AuditAction` promises `[:id, :name, :actor_ref, :status, :reason, :correlation_id, :inserted_at]`. These are selected subsets of their current Ecto schemas, never whole-schema freezes. The contract compares each literal list with `__schema__(:fields)` and permits additional fields in both the schema and `t` types. `changed_fields` is a text array/list, while `data_after` and `changed_from` are JSONB maps; the additive shape promise follows the actual schema types. [VERIFIED: `lib/threadline/capture/audit_change.ex`; `lib/threadline/capture/audit_transaction.ex`; `lib/threadline/semantics/audit_action.ex`; CONTEXT D-02; PLAN 235-05]
2. **Public allowlist ownership.** Keep focused test modules by contract: `test/threadline/storage_catalog_contract_test.exs` for live catalog facts, `test/threadline/capture/public_sql_contract_test.exs` for the actor GUC and trigger-function names, `test/threadline/export_public_contract_test.exs` for export headers and health codes, and `test/threadline/public_options_contract_test.exs` for Mix-task flags and operator-router options/routes. Reuse the literal expected-set and attributable diff style in `test/threadline/telemetry_registry_contract_test.exs`; do not derive expected sets solely from production values or introduce a registry used only by tests. [VERIFIED: CONTEXT D-03/D-09; `test/threadline/telemetry_registry_contract_test.exs`; PLAN 235-03/04]

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Migration guard seam and rollback | HIGH | Directly inspected both generated SQL branches, helper, migration harness patterns, and official PostgreSQL/Ecto transaction documentation. |
| Stability contract/test structure | HIGH | Requirements/context are explicit and existing schema/telemetry contract patterns are present. |
| Supported table matrix | HIGH except caveats marked assumed | Existing key/naming/partition sources were inspected; two operational nuances need exact-source verification when drafting. |
| Redaction threat guide | HIGH | Current property test documents exact paths and exclusions; residual surfaces cite official PostgreSQL docs. |
| Documentation UX/prior art | MEDIUM | Diátaxis is primary documentation guidance; Carbonite was not inspected deeply enough for claims beyond adjacent category. |

**Research date:** 2026-10-06  
**Valid until:** 2026-11-05 for stable architecture/contracts; recheck official docs if the PostgreSQL major version changes.
