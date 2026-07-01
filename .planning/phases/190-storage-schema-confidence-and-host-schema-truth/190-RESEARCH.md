# Phase 190: Storage Schema Confidence and Host-Schema Truth - Research

**Researched:** 2026-07-01
**Domain:** Elixir/Ecto/PostgreSQL storage schemas, generated migrations, trigger SQL, and operator host-schema truth
**Confidence:** HIGH for codebase findings; MEDIUM for external docs cross-checks

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### the agent's Discretion

Downstream agents may choose the exact file/test organization, helper names, and whether to use SQL shape assertions, sentinel rows, or both for individual paths. They should preserve the locked contracts above: layered real-DB proof, no fixed owned-schema prefix, quoted generated identifiers, explicit host-schema identity, and no scope expansion.

### Deferred Ideas (OUT OF SCOPE)

- A broad all-schema operator coverage/redaction scan is deferred. Phase 190 should keep selected-schema behavior and no all-schema polling.
- A full Ecto.Migration DSL rewrite is deferred. It may be useful later, but Phase 190's contract is quoted raw SQL plus focused fixes.
- Broad browser/example E2E for every storage-schema path is deferred unless planning finds a small high-value smoke. Targeted real-DB proof is the authority.
- Per-request multi-tenant Threadline storage is deferred. The phase supports one configured storage schema with explicit per-call override for tests/advanced callers, not arbitrary tenant storage routing.
- Full duplicate table-name row-history disambiguation across host schemas may be deferred only if documented and test-locked; planner should try to resolve it if the blast radius is small.
- No todo artifacts matched Phase 190, so none were folded or reviewed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHEMA-01 | Prove custom non-default `storage_schema` end to end or fix gaps in capture, query, evidence, governance, and operator paths. | Use real PostgreSQL dual-schema sentinel tests with `audit` selected and `threadline` populated as a false-positive trap. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: codebase grep] |
| SCHEMA-02 | Prove or correct Ecto prefix behavior so configurable storage schemas do not silently hit hardcoded `threadline`. | Remove fixed `@schema_prefix "threadline"` from owned schemas and require repo/preload/bulk prefix contracts. [VERIFIED: codebase grep; CITED: https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix] |
| SCHEMA-03 | Quote validated storage-schema identifiers consistently in generated migration SQL or narrow/document/test-lock the identifier contract. | Reuse `Threadline.StorageSchema.quote_ident/1`, `qualify/2`, and `table/2`; generated migration modules currently interpolate unquoted schema strings. [VERIFIED: codebase grep; CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html] |
| SCHEMA-04 | Implement or test-lock non-public host-table support for continuity, redaction inspection, and operator coverage. | Trigger generation, coverage, and timeline already have schema-aware pieces; continuity and policy redaction paths still default/pin public. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 190 should be planned as a correctness and truth-repair phase, not as a broad feature phase. The current code already has a strong central seam in `Threadline.StorageSchema` for validation, quoting, host-table parsing, and repo prefix options, but generated install migrations still interpolate unquoted schema names and all Threadline-owned Ecto schemas still declare `@schema_prefix "threadline"`. [VERIFIED: codebase grep]

The implementation center of gravity is backend/API plus PostgreSQL integration tests. Ecto's official prefix precedence makes the fixed-prefix risk real for reads, joins, and preloads: repo `prefix:` is not enough when the schema or query source declares a prefix. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html; CITED: https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix] Source/string contracts remain useful, but the closing gate must be real DB isolation with both `threadline` and `audit` populated. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md]

**Primary recommendation:** Use the existing `StorageSchema` seam everywhere, remove owned fixed prefixes, add a dual-schema integration helper, and make `storage_schema: "audit"` pass through capture, query, semantics, evidence, export, retention, saved views, and operator reads before closing the phase. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Storage schema resolution and identifier quoting | API / Backend | Database / Storage | `Threadline.StorageSchema` owns resolution, validation, quoting, and repo prefix construction before SQL or Repo calls execute. [VERIFIED: lib/threadline/storage_schema.ex] |
| Generated install migration SQL | API / Backend | Database / Storage | Mix generators freeze app config into host migration files; raw SQL must be emitted already quoted and schema-qualified. [VERIFIED: lib/mix/tasks/threadline.install.ex; VERIFIED: lib/threadline/capture/migration.ex] |
| Trigger/function SQL | API / Backend | Database / Storage | `TriggerSQL` generates PL/pgSQL and host-table triggers while PostgreSQL executes capture. [VERIFIED: lib/threadline/capture/trigger_sql.ex] |
| Ecto owned reads/writes/joins/preloads | API / Backend | Database / Storage | Query and governance modules execute through host Repo calls, so prefix correctness belongs at Repo-operation boundaries. [VERIFIED: codebase grep; CITED: https://ecto.hexdocs.pm/Ecto.Repo.html] |
| Async export and retention runtimes | API / Backend | Database / Storage | Jobs and pruners use GenServer/Task/Oban adapters but still persist state in Threadline-owned tables through Repo options. [VERIFIED: lib/threadline/export/orchestrator.ex; VERIFIED: lib/threadline/retention/pruner.ex] |
| Host-table schema identity | API / Backend | CLI / Operator Surface | Host table schema is input identity (`support.tickets`, `--schema=support`, `table_schema: "support"`), not the Threadline storage prefix. [VERIFIED: lib/threadline/storage_schema.ex; VERIFIED: guides/operator-surface.md] |
| Operator coverage/redaction messages | CLI / Operator Surface | API / Backend | Operator surfaces should expose selected host schema and next command, not Ecto prefix internals. [VERIFIED: brandbook/index.html; VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md] |

## Project Constraints (from AGENTS.md)

No root `./AGENTS.md` exists in `/Users/jon/projects/threadline`; no AGENTS.md directives apply to this phase. [VERIFIED: rg --files -g AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5, OTP 28 | Compile/test runner and Mix task platform | Current local runtime; `mix.exs` requires Elixir `~> 1.15`. [VERIFIED: elixir --version; VERIFIED: mix.exs] |
| Ecto | locked 3.13.5; HexDocs current page viewed at 3.14.0 | Schemas, query DSL, Repo operations, prefix semantics | Existing storage/query layer; official prefix docs define the phase's main correctness risk. [VERIFIED: mix deps; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] |
| Ecto SQL | locked 3.13.5; HexDocs current page viewed at 3.14.0 | Migrations, SQL adapter integration, SQL test helpers | Existing migration/test stack and official prefix helpers for table/index DDL. [VERIFIED: mix deps; CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html] |
| Postgrex | locked 0.22.0 | PostgreSQL adapter for Ecto | Existing adapter for real PostgreSQL integration tests. [VERIFIED: mix deps] |
| PostgreSQL | local server/client 14.17 | Schemas, triggers, PL/pgSQL, integration proof | Phase target database; local server is reachable on `localhost:5432`. [VERIFIED: psql --version; VERIFIED: pg_isready] |
| ExUnit | bundled with Elixir | Unit and integration tests | Existing test suite and `Threadline.DataCase` use ExUnit with real PostgreSQL. [VERIFIED: test/test_helper.exs; VERIFIED: test/support/data_case.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix / LiveView | Phoenix 1.8.7, LiveView 1.1.30, optional | Operator LiveViews/controllers | Only for narrow operator schema/redaction smoke if backend tests cannot cover the read path. [VERIFIED: mix deps; VERIFIED: mix.exs] |
| Jason | locked 1.4.4 | JSON evidence/export/query metadata | Keep existing use; no phase need for new JSON libraries. [VERIFIED: mix deps] |
| NimbleCSV | locked 1.3.0 | CSV export serialization | Existing export tests should be extended only if export storage-schema isolation is affected. [VERIFIED: mix deps] |
| Oban | locked 2.22.1, optional | Persistent export queue adapter | Test global-config storage schema behavior where the optional adapter is already covered; do not add new queue dependency. [VERIFIED: mix deps; VERIFIED: lib/threadline/export_queue/oban.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `StorageSchema.repo_opts/1` on each owned Repo operation | Repo `default_options/1` or `prepare_query/3` | A repo hook could reduce omissions, but Threadline is a library using host Repos; explicit options are less invasive and match existing public opts. [ASSUMED] |
| Raw generated SQL with helper-quoted identifiers | Full Ecto.Migration DSL rewrite | DSL prefixes help tables/indexes, but raw SQL is still needed for schemas, PL/pgSQL functions, triggers, and DO blocks. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html] |
| Targeted real DB integration proof | Broad browser E2E | Browser tests are slower and do not prove Ecto prefix isolation for every backend path. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md] |
| Selected host-schema checks | All-schema polling | All-schema polling is deferred and would expand operator load/scope. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md] |

**Installation:**

No new external packages should be installed for Phase 190. [VERIFIED: mix.exs; VERIFIED: .planning/REQUIREMENTS.md]

**Version verification:** Current stack versions were checked with `elixir --version`, `mix --version`, `mix deps`, `psql --version`, and `show server_version`. [VERIFIED: command output]

## Package Legitimacy Audit

Phase 190 should not install external packages; the Package Legitimacy Gate is not triggered. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install recommended. [VERIFIED: mix.exs] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no new package recommendations]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new package recommendations]

## Architecture Patterns

### System Architecture Diagram

```text
Host config / per-call opts
        |
        v
StorageSchema.get/quote_ident/qualify/repo_opts
        |
        +--> mix threadline.install --> generated migration SQL --> PostgreSQL storage schema ("audit")
        |
        +--> TriggerSQL.install/create_trigger --> PL/pgSQL function + host trigger
        |                                      |
        |                                      v
        |                         host table mutation (public.users or support.tickets)
        |                                      |
        |                                      v
        |                         audit.audit_transactions / audit.audit_changes
        |
        +--> Threadline API / Query / Evidence / Export / Retention / Operator reads
                                               |
                                               v
                            Repo operation with prefix "audit"
                                               |
                      +------------------------+------------------------+
                      |                                                 |
              expected audit rows                               sentinel threadline rows
                      |                                                 |
                      v                                                 v
              returned/mutated                                  must not be returned/mutated
```

### Recommended Project Structure

```text
lib/threadline/
├── storage_schema.ex                    # single storage-schema contract
├── capture/migration.ex                 # generated capture migration SQL
├── semantics/migration.ex               # generated semantics migration SQL
├── governance/migration.ex              # generated governance migration SQL
├── capture/trigger_sql.ex               # trigger/function SQL and host-table qualification
├── query.ex                             # timeline/history/export query prefix plumbing
├── evidence.ex                          # evidence prefix plumbing
├── export*/                             # export job/run/download prefix plumbing
├── retention*/                          # retention run/prune prefix plumbing
├── health*/                             # selected host-schema coverage
├── policy/redaction_presenter.ex        # selected host-schema redaction drift
└── operator_surface/                    # narrow operator schema UI/copy if needed

test/threadline/
├── storage_schema*_test.exs             # identifier, generated SQL, static prefix contracts
├── storage_schema_integration_test.exs  # recommended dual-schema sentinel DB proof
├── capture/*storage_schema*_test.exs    # trigger SQL and trigger execution proof
├── query_test.exs                       # timeline/history/as-of/query prefix proof
├── evidence_test.exs                    # evidence storage proof
├── export/*_test.exs                    # export job/status/download proof
├── retention*_test.exs                  # retention and pruning proof
└── operator_surface/*                   # selected-schema redaction/coverage smoke only where needed
```

### Pattern 1: One Storage Schema Seam

**What:** All raw SQL and Repo operations should receive a schema resolved through `Threadline.StorageSchema`. [VERIFIED: lib/threadline/storage_schema.ex]

**When to use:** Use it for generated migrations, trigger SQL, Repo reads/writes, joins, preloads, bulk operations, and background/operator reads. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/threadline/storage_schema.ex and Ecto.Repo docs
opts = StorageSchema.repo_opts(storage_schema: "audit")
repo.all(query, opts)
repo.preload(entries, [transaction: :action], opts)
```

### Pattern 2: Remove Owned Fixed Prefixes

**What:** Threadline-owned schemas should not declare `@schema_prefix "threadline"`. [VERIFIED: codebase grep; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]

**When to use:** Apply to `AuditTransaction`, `AuditChange`, `AuditAction`, `EvidenceRecord`, `ExportJob`, `RetentionRun`, and `SavedView`. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: Ecto.Schema / Ecto.Query prefix docs
defmodule Threadline.Capture.AuditChange do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "audit_changes" do
    belongs_to(:transaction, Threadline.Capture.AuditTransaction, foreign_key: :transaction_id)
  end
end
```

### Pattern 3: Dual-Schema Sentinel Integration Tests

**What:** Test with `audit` as selected storage schema while plausible rows exist in `threadline`. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md]

**When to use:** Use for each storage path that could silently read/write the default schema. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: test/support/data_case.ex pattern plus Threadline.StorageSchema
setup do
  original = Application.get_env(:threadline, :storage_schema)
  Application.put_env(:threadline, :storage_schema, "audit")
  on_exit(fn -> Application.put_env(:threadline, :storage_schema, original) end)

  # Build/clean audit schema and seed threadline sentinels.
  :ok
end
```

### Pattern 4: Selected Host Schema Is Not Storage Schema

**What:** Host schema flows should parse or accept `support.tickets`, `--schema=support`, or `table_schema: "support"` without changing Threadline-owned storage prefix. [VERIFIED: lib/threadline/storage_schema.ex; VERIFIED: test/threadline/query_test.exs]

**When to use:** Use for trigger generation, coverage/verify, policy redaction, continuity, and timeline links. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/threadline/storage_schema.ex and test/threadline/capture/trigger_sql_storage_schema_test.exs
TriggerSQL.create_trigger("support.tickets", :default, storage_schema: "audit")
# creates trigger on "support"."tickets" calling "audit"."threadline_capture_changes"()
```

### Anti-Patterns to Avoid

- **Fixed owned schema prefixes:** They defeat repo prefix fallback for query reads and joins. [CITED: https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix]
- **Unquoted raw migration identifiers:** They rely on case folding and can break valid configured names such as `AuditLog`. [CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html]
- **Search-path host/schema magic:** PostgreSQL documents that search-path lookup can resolve the wrong object and can be unsafe when writable schemas are in the path. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html]
- **All-schema polling:** It is explicitly deferred and would expand operator/database load. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md]
- **Browser-only proof:** It cannot prove all Repo operation paths and is not the core gate. [VERIFIED: .planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md]

## Component Responsibilities

| File / Area | Current Finding | Planning Implication |
|-------------|-----------------|----------------------|
| `lib/threadline/storage_schema.ex` | Central helper validates one identifier segment, quotes identifiers, qualifies storage/host names, and returns `[prefix: schema]`. [VERIFIED: codebase grep] | Extend here for byte-length and `pg_` narrowing if chosen; do not duplicate validation elsewhere. |
| `lib/threadline/capture/migration.ex` | Generated DDL interpolates unquoted `#{storage_schema}` for schema/table/index/FK/drop SQL. [VERIFIED: codebase grep] | Replace raw references with helper-quoted strings in generated content. |
| `lib/threadline/semantics/migration.ex` | Generated DDL interpolates unquoted storage schema for action table and transaction FK changes. [VERIFIED: codebase grep] | Same quote/qualify contract as capture migration. |
| `lib/threadline/governance/migration.ex` | Generated governance DDL interpolates unquoted storage schema for export/retention/saved/evidence tables. [VERIFIED: codebase grep] | Same quote/qualify contract as capture migration. |
| Owned schema modules | Seven owned schemas have fixed `@schema_prefix "threadline"`. [VERIFIED: codebase grep] | Remove fixed prefix and rely on explicit Repo options. |
| `lib/threadline/query.ex` | Query paths route through `storage_opts/2`, but preloads use `repo.preload(... )` without prefix opts. [VERIFIED: codebase grep] | Add prefix opts to preloads or prove loaded prefix is preserved for custom schema. |
| `lib/threadline/evidence.ex` | Evidence paths pass `StorageSchema.repo_opts(filters ++ opts)`. [VERIFIED: codebase grep] | Add custom-schema integration proof and allow `storage_schema:` only through opts/filters as intended. |
| `lib/threadline/export*.ex` | Export reads use `Query.storage_opts/2`; export job row fetch/update/cleanup uses global `StorageSchema.repo_opts()`. [VERIFIED: codebase grep] | Decide and test global-config contract for async jobs. |
| `lib/threadline/retention*.ex` | Retention reads/deletes/run tracking use global `StorageSchema.repo_opts()`. [VERIFIED: codebase grep] | Test global configured `audit` behavior and sentinel isolation. |
| `lib/threadline/continuity.ex` | `assert_capture_ready!/2` checks public table existence and default public coverage. [VERIFIED: codebase grep] | Add `--schema`/qualified-table support or document/test-lock public-only. |
| `lib/threadline/policy/redaction_presenter.ex` | Presenter accepts `schema:` but configured table keys are grouped by bare table names and caller defaults public. [VERIFIED: codebase grep] | Normalize qualified config keys by selected host schema and preserve selected-schema labels/links. |
| `lib/mix/tasks/threadline.policy.show.ex` | Mix task parses only `--json` and calls presenter with `schema: "public"`. [VERIFIED: codebase grep] | Add `--schema=NAME` edge validation and JSON schema output parity. |
| `PolicyRedactionLive` | LiveView calls presenter without selected schema and links Timeline without `table_schema`. [VERIFIED: codebase grep] | Reuse coverage schema selector pattern or explicitly test-lock public-only. |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQL storage identifier escaping | Ad hoc string replace or mixed quoted/unquoted fragments | `StorageSchema.validate!/1`, `quote_ident/1`, `qualify/2`, `table/2`, `function/2` | One contract avoids case-folding and injection drift. [VERIFIED: lib/threadline/storage_schema.ex; CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html] |
| Ecto dynamic storage routing | Manual `search_path` setting | Repo `prefix:` options via `StorageSchema.repo_opts/1` | Search path can resolve wrong objects and has security implications. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| Multi-tenant storage router | Per-request arbitrary storage schemas | One configured schema plus explicit per-call override for advanced/tests | Per-request multi-tenant storage is deferred. [VERIFIED: 190-CONTEXT.md] |
| Broad redaction/coverage discovery | All-schema scans | Selected schema input (`--schema`, URL `?schema=`) | All-schema polling is deferred. [VERIFIED: 190-CONTEXT.md] |
| Custom DB mocking | Fake Repo or unit-only SQL assertions | Real PostgreSQL integration tests with sentinels | `DataCase` already uses real PostgreSQL and no Ecto sandbox for trigger truth. [VERIFIED: test/support/data_case.ex] |

**Key insight:** This phase is about trust boundaries. A string contract can prove SQL shape, but only a dual-schema database test can prove the selected storage schema is the one actually read or mutated. [VERIFIED: 190-CONTEXT.md]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Local `threadline_test` currently has `public` and `threadline` schemas; `audit` and `support` are absent; Threadline-owned tables exist under `threadline`. [VERIFIED: psql query] | Tests should create/drop `audit` and `support` schemas inside setup/on_exit; do not assume they preexist. |
| Live service config | `config/test.exs` sets `config :threadline, storage_schema: "threadline"` and no `THREADLINE*`, `DB_*`, `PG*`, or `DATABASE_URL` env vars were present in the shell. [VERIFIED: config/test.exs; VERIFIED: env grep] | Tests that mutate application env must restore it in `on_exit`. |
| OS-registered state | None found for this phase; no launchd/systemd/pm2/task state was referenced by phase context or repo search. [VERIFIED: 190-CONTEXT.md; VERIFIED: rg] | No OS re-registration task needed. |
| Secrets/env vars | No env var names are required for `storage_schema`; DB connection uses default test config unless `DB_HOST`/`DB_PORT` are set. [VERIFIED: config/test.exs] | No secret migration; preserve DB env fallback behavior. |
| Build artifacts | Existing `_build`/compiled deps may cache module attributes during a test run; changing `@schema_prefix` source requires recompilation. [ASSUMED] | Planner should include `mix compile --warnings-as-errors` and targeted tests after schema module edits. |

**Nothing found in category:** OS-registered state is none by repo/context inspection. [VERIFIED: rg]

## Common Pitfalls

### Pitfall 1: Split-Brain Prefixing

**What goes wrong:** Inserts/updates can use `prefix: "audit"` while reads/joins still target `threadline`. [CITED: https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix]

**Why it happens:** Ecto query prefix precedence falls back to schema prefixes before repo options, and owned schemas currently declare `@schema_prefix "threadline"`. [VERIFIED: codebase grep; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]

**How to avoid:** Remove fixed owned prefixes and add DB tests that return only `audit` sentinels. [VERIFIED: 190-CONTEXT.md]

**Warning signs:** A test passes when `threadline` has the same row as `audit`, or only source strings are asserted. [ASSUMED]

### Pitfall 2: Prefetch/Preload Falling Back

**What goes wrong:** Timeline/transaction preload paths can fetch associations from the wrong prefix or fail only under custom schema. [VERIFIED: codebase grep]

**Why it happens:** Current `repo.preload/2` calls do not pass `StorageSchema.repo_opts/1`. [VERIFIED: codebase grep]

**How to avoid:** Pass repo opts into `repo.preload/3` or prove Ecto's loaded-prefix metadata covers the path. [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html]

**Warning signs:** `timeline_page` returns changes but `transaction: :action` preloads are nil or from sentinel rows. [ASSUMED]

### Pitfall 3: Async Jobs Move Schemas Accidentally

**What goes wrong:** An export job row is inserted in one storage schema but the worker later fetches from another schema after config changes. [VERIFIED: lib/threadline/export/orchestrator.ex; ASSUMED]

**Why it happens:** Queue adapters pass only `job_id`, and orchestrator fetches jobs with `StorageSchema.repo_opts()` from current/global config. [VERIFIED: lib/threadline/export_queue/task_adapter.ex; VERIFIED: lib/threadline/export_queue/oban.ex]

**How to avoid:** For Phase 190, test-lock and document the global-config contract for background export/retention, or pass storage schema through queue args if the planner chooses stronger queued-job stability. [VERIFIED: 190-CONTEXT.md]

**Warning signs:** Tests set `storage_schema: "audit"` to enqueue, restore config, then worker cannot find the job or streams default rows. [ASSUMED]

### Pitfall 4: Qualified Host Table Config Does Not Match Redaction Rows

**What goes wrong:** Config key `support.tickets` can be compared against deployed table row `tickets`, producing false drift/match rows. [VERIFIED: lib/threadline/policy/redaction_presenter.ex; VERIFIED: lib/threadline/capture/trigger_capture_config.ex]

**Why it happens:** Redaction config stores string keys as given, while deployed rows are grouped by `c.relname` only for the selected schema. [VERIFIED: codebase grep]

**How to avoid:** Normalize configured keys through `StorageSchema.parse_table_identifier/1`; for selected schema `support`, compare deployed `tickets` against configured `support.tickets` and display `support.tickets`. [VERIFIED: lib/threadline/storage_schema.ex]

**Warning signs:** Policy output shows both `support.tickets` and `tickets` for the same trigger. [ASSUMED]

### Pitfall 5: Storage Schema and Host Schema Copy Collapse

**What goes wrong:** Operator copy or tests imply `storage_schema: "audit"` audits host schema `audit`, or `--schema=support` changes Threadline-owned storage. [VERIFIED: 190-CONTEXT.md]

**Why it happens:** Both concepts use "schema" but mean different PostgreSQL namespaces. [ASSUMED]

**How to avoid:** Keep copy as "Storage schema" for Threadline-owned tables and "Host schema" for audited app tables. [VERIFIED: 190-CONTEXT.md; VERIFIED: brandbook/index.html]

**Warning signs:** A CLI option named `--storage-schema` appears on coverage, or a docs line says `--schema=audit` changes Threadline storage. [ASSUMED]

## Code Examples

### Generated Migration Quoting

```elixir
# Source: Threadline.StorageSchema + PostgreSQL identifier docs
schema = Threadline.StorageSchema.get()
quoted_schema = Threadline.StorageSchema.quote_ident(schema)
audit_transactions = Threadline.StorageSchema.qualify(schema, "audit_transactions")

"""
execute "CREATE SCHEMA IF NOT EXISTS #{quoted_schema}"

execute \"\"\"
CREATE TABLE IF NOT EXISTS #{audit_transactions} (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid()
)
\"\"\"
"""
```

### Repo Operation Prefixing

```elixir
# Source: Ecto.Repo prefix option docs
def list_runs(repo, opts) do
  from(r in Threadline.Governance.RetentionRun, order_by: [desc: r.started_at])
  |> repo.all(Threadline.StorageSchema.repo_opts(opts))
end
```

### Prefix-Aware Preload

```elixir
# Source: Ecto.Repo preload docs
def preload_visible_context(page, repo, opts) do
  %{page | entries: repo.preload(page.entries, [transaction: :action], StorageSchema.repo_opts(opts))}
end
```

### Qualified Host Table Redaction Matching

```elixir
# Source: Threadline.StorageSchema.parse_table_identifier/1
%{schema: "support", table: "tickets"} =
  Threadline.StorageSchema.parse_table_identifier("support.tickets")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed `@schema_prefix "threadline"` on owned schemas | Dynamic repo/query prefixing for owned storage | Ecto prefix docs current at viewed 3.14.0; Threadline phase 190 owns code change. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] | Avoids read/write split-brain under `storage_schema: "audit"`. |
| Unquoted generated storage schema references | Validated, consistently double-quoted raw SQL identifiers | PostgreSQL docs current at version 18 page; Phase 190 owns generated SQL fix. [CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html] | Supports uppercase configured names and avoids case-folding ambiguity. |
| Public-only host coverage/redaction assumptions | Selected host schema with explicit identity | Coverage path already supports selected schema; redaction/continuity still need repair or lock. [VERIFIED: codebase grep] | Keeps `support.tickets` trustworthy without all-schema polling. |
| Broad visual/browser proof for correctness | Targeted real DB integration proof | Locked by Phase 190 context. [VERIFIED: 190-CONTEXT.md] | Faster and more precise proof for prefix/schema correctness. |

**Deprecated/outdated:**
- Generated migration contracts that assert unquoted `threadline.audit_transactions` are outdated for SCHEMA-03 and must be updated. [VERIFIED: test/threadline/storage_schema_migration_contract_test.exs]
- Policy redaction docs that imply parity with non-public coverage while Mix/LiveView default public are incomplete for SCHEMA-04. [VERIFIED: guides/domain-reference.md; VERIFIED: lib/mix/tasks/threadline.policy.show.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Build artifacts may cache removed module attributes until recompilation. | Runtime State Inventory | Planner may omit compile verification after deleting `@schema_prefix`. |
| A2 | Repo hooks such as `prepare_query/3` are less suitable for this library phase than explicit repo opts. | Standard Stack / Alternatives | Planner might choose broader host-Repo integration and expand blast radius. |
| A3 | Async schema movement after config changes is a realistic failure mode, not yet proven by a current test. | Common Pitfalls / Open Questions | Planner may need a focused queued-job test before choosing global-only or persisted schema behavior. |
| A4 | Warning signs listed for pitfalls are inferred test smells, not current failing tests. | Common Pitfalls | Planner should treat them as guide rails, not existing bug evidence. |

## Open Questions

1. **Async export schema contract**
   - What we know: Export queue adapters pass only `job_id`, and orchestrator uses current `StorageSchema.repo_opts()` to fetch/update the job row. [VERIFIED: codebase grep]
   - What's unclear: Whether Phase 190 should document global-config-only behavior or strengthen queue args to carry storage schema. [VERIFIED: 190-CONTEXT.md]
   - Recommendation: Use global configured storage schema for Phase 190, add tests for `config :threadline, storage_schema: "audit"` export/retention paths, and document that changing storage schema after queueing requires draining/rerunning jobs. [ASSUMED]

2. **Redaction LiveView schema selector depth**
   - What we know: Coverage LiveView has selected-schema UI; PolicyRedactionLive currently uses default public presenter and Timeline links omit `table_schema`. [VERIFIED: codebase grep]
   - What's unclear: Whether to add a schema picker to redaction now or test-lock redaction as public-only. [VERIFIED: 190-CONTEXT.md]
   - Recommendation: Add selected-schema redaction support by reusing `CoverageSchemas` validation and coverage selector patterns, because SCHEMA-04 names redaction inspection as a host-schema proof target. [VERIFIED: 190-CONTEXT.md]

3. **Duplicate host table names beyond Timeline**
   - What we know: `Threadline.timeline/2` already filters by both `table_schema` and `table` when duplicate table names exist. [VERIFIED: test/threadline/query_test.exs]
   - What's unclear: Whether every row-history/operator path can disambiguate duplicate names without broader API changes. [VERIFIED: 190-CONTEXT.md]
   - Recommendation: Fix the low-blast-radius paths; document/test-lock any remaining duplicate-name limit explicitly. [VERIFIED: 190-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | yes [VERIFIED: command output] | 1.19.5 / OTP 28 [VERIFIED: command output] | none |
| Mix | Test/verify tasks | yes [VERIFIED: command output] | 1.19.5 [VERIFIED: command output] | none |
| PostgreSQL server | Real DB integration proof | yes [VERIFIED: command output] | 14.17 [VERIFIED: command output] | none |
| psql | Runtime state audit/debug | yes [VERIFIED: command output] | 14.17 [VERIFIED: command output] | Ecto SQL queries |
| Node.js | Optional browser/operator smoke only | yes [VERIFIED: command output] | v22.14.0 [VERIFIED: command output] | Skip browser smoke unless needed |
| ctx7 CLI | Preferred docs provider fallback | no [VERIFIED: command output] | n/a | Official docs via websearch were used [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] |

**Missing dependencies with no fallback:**
- none for required backend research and planning. [VERIFIED: command output]

**Missing dependencies with fallback:**
- `ctx7` CLI is missing; official HexDocs/PostgreSQL docs were fetched with websearch instead. [VERIFIED: command output; CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 with real PostgreSQL through `Threadline.Test.Repo`. [VERIFIED: test/test_helper.exs; VERIFIED: test/support/repo.ex] |
| Config file | `config/test.exs`. [VERIFIED: config/test.exs] |
| Quick run command | `mix test test/threadline/storage_schema_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs` [VERIFIED: command passed 10 tests] |
| Full suite command | `mix test` or `mix ci.all` depending on planner risk; `mix ci.all` includes browser example lane. [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SCHEMA-01 | `storage_schema: "audit"` captures, queries, exports, retains, and reads operator/governance data without touching `threadline` sentinels. | integration | `mix test test/threadline/storage_schema_integration_test.exs -x` | no - Wave 0 |
| SCHEMA-02 | Owned schemas have no fixed `@schema_prefix "threadline"` and joins/preloads/bulk ops use `audit`. | static + integration | `mix test test/threadline/storage_schema_prefix_contract_test.exs test/threadline/query_test.exs -x` | no for prefix contract; query exists |
| SCHEMA-03 | Generated migrations quote configured storage schema identifiers consistently, including `AuditLog` and invalid-name failures. | unit/source contract | `mix test test/threadline/storage_schema_migration_contract_test.exs -x` | yes, update required |
| SCHEMA-04 | `support.tickets` works for trigger generation, coverage/verify, redaction inspection, timeline filtering, and continuity readiness. | integration + Mix task + LiveView where needed | `mix test test/threadline/continuity_brownfield_test.exs test/threadline/operator_surface/policy_show_mix_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs -x` | yes, extensions required |

### Sampling Rate

- **Per task commit:** `mix test <touched focused test files>` plus `mix compile --warnings-as-errors` after schema module changes. [ASSUMED]
- **Per wave merge:** `mix test test/threadline/storage_schema*_test.exs test/threadline/capture/trigger_sql_storage_schema_test.exs test/threadline/query_test.exs test/threadline/evidence_test.exs test/threadline/export test/threadline/retention_test.exs`. [ASSUMED]
- **Phase gate:** `mix test` at minimum; `mix ci.all` if operator LiveView/browser smoke is changed or closeout requires full local parity. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/threadline/storage_schema_integration_test.exs` - dual-schema sentinel fixture for SCHEMA-01/SCHEMA-02. [ASSUMED]
- [ ] `test/threadline/storage_schema_prefix_contract_test.exs` - static owned-schema prefix scan plus representative preload/join behavior. [ASSUMED]
- [ ] Extend `test/threadline/storage_schema_migration_contract_test.exs` - quoted identifiers and frozen config examples for SCHEMA-03. [VERIFIED: existing file]
- [ ] Extend `test/threadline/operator_surface/policy_show_mix_test.exs` and `policy_redaction_live_test.exs` - `--schema=support` / selected host schema redaction proof for SCHEMA-04. [VERIFIED: existing files]
- [ ] Extend `test/threadline/continuity_brownfield_test.exs` - `support.tickets` readiness proof or public-only lock. [VERIFIED: existing file]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase does not change auth; preserve existing operator auth gates. [VERIFIED: 190-CONTEXT.md] |
| V3 Session Management | no | No session behavior change. [VERIFIED: 190-CONTEXT.md] |
| V4 Access Control | yes | Preserve operator authorization and avoid adding new public surfaces. [VERIFIED: 190-CONTEXT.md] |
| V5 Input Validation | yes | Validate storage identifiers and host schema/table names at the boundary; quote storage identifiers in raw SQL. [VERIFIED: lib/threadline/storage_schema.ex; CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html] |
| V6 Cryptography | no | No crypto changes; do not hand-roll crypto. [VERIFIED: 190-CONTEXT.md] |
| V7 Error Handling and Logging | yes | Errors must state unsupported/misconfigured behavior clearly and avoid silent fallback. [VERIFIED: 190-CONTEXT.md; VERIFIED: brandbook/index.html] |
| V14 Configuration | yes | `config :threadline, storage_schema: "audit"` becomes a correctness boundary and must be tested/restored in env-mutating tests. [VERIFIED: config/test.exs; VERIFIED: 190-CONTEXT.md] |

### Known Threat Patterns for Elixir/Ecto/PostgreSQL

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection through generated schema/table/function names | Tampering | Accept one validated identifier segment and double-quote every raw SQL identifier. [VERIFIED: lib/threadline/storage_schema.ex; CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html] |
| Search-path hijack or wrong-object lookup | Elevation/Tampering | Schema-qualify Threadline-owned objects and schema-qualified host trigger targets; do not rely on `search_path`. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| Cross-schema data leakage between `threadline` and `audit` | Information Disclosure | Dual-schema sentinel tests for every public path. [VERIFIED: 190-CONTEXT.md] |
| Redaction drift false confidence for non-public host tables | Information Disclosure | Selected-schema redaction presenter/Mix/LiveView proof and no sample values in output. [VERIFIED: lib/threadline/policy/redaction_presenter.ex; VERIFIED: test/threadline/operator_surface/policy_show_mix_test.exs] |
| Retention/delete against wrong storage schema | Tampering/Denial | Prefix all retention queries/deletes and prove `audit` storage with `threadline` sentinels. [VERIFIED: lib/threadline/retention.ex] |
| Export from wrong storage schema | Information Disclosure | Prefix export reads/job rows and prove exported bytes exclude `threadline` sentinels. [VERIFIED: lib/threadline/export.ex; VERIFIED: lib/threadline/export/orchestrator.ex] |

## Sources

### Primary (HIGH confidence)

- Codebase reads/grep: `lib/threadline/storage_schema.ex`, generated migration modules, owned schema modules, query/evidence/export/retention paths, health/redaction/continuity modules, Mix tasks, and focused tests. [VERIFIED: codebase grep]
- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-CONTEXT.md` - locked phase decisions. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` - v1.39 scope and SCHEMA requirements. [VERIFIED: file read]
- `prompts/threadline-elixir-oss-dna.md`, `prompts/audit-lib-domain-model-reference.md`, audit-library strategy prompt, and `brandbook/index.html` - product/DX guidance. [VERIFIED: file read]

### Secondary (MEDIUM confidence)

- https://ecto.hexdocs.pm/Ecto.Schema.html - `@schema_prefix` behavior. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]
- https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix - query prefix precedence. [CITED: https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix]
- https://ecto.hexdocs.pm/Ecto.Repo.html - Repo prefix and preload API. [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html]
- https://ecto-sql.hexdocs.pm/Ecto.Migration.html - migration prefix helpers and `execute`. [CITED: https://ecto-sql.hexdocs.pm/Ecto.Migration.html]
- https://www.postgresql.org/docs/current/sql-syntax-lexical.html - identifiers, quoting, case folding, 63-byte limit. [CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html]
- https://www.postgresql.org/docs/current/ddl-schemas.html - schemas and `search_path` risks. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html]

### Tertiary (LOW confidence)

- Assumptions in the Assumptions Log only. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `mix deps`, `mix.exs`, local runtime commands, and existing files. [VERIFIED: command output]
- Architecture: HIGH for code seams, MEDIUM for Ecto/PostgreSQL docs implications. [VERIFIED: codebase grep; CITED: https://ecto.hexdocs.pm/Ecto.Query.html#module-query-prefix; CITED: https://www.postgresql.org/docs/current/sql-syntax-lexical.html]
- Pitfalls: HIGH where backed by code/docs, LOW where listed as inferred warning signs. [VERIFIED: codebase grep; ASSUMED]

**Research date:** 2026-07-01
**Valid until:** 2026-07-31 for codebase findings; 2026-07-08 for current external documentation/version assumptions. [ASSUMED]
