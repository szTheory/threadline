# Requirements: Threadline

**Defined:** 2026-04-22
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1 Requirements

### Package & Installation

- [x] **PKG-01**: Hex package `threadline` is published with Elixir ≥ 1.15, OTP ≥ 26, and Ecto 3.x as minimum dependencies
- [x] **PKG-02**: `mix threadline.install` creates the `audit_transactions` and `audit_changes` tables with correct indexes via Ecto migration
- [x] **PKG-03**: `mix threadline.gen.triggers` installs PostgreSQL triggers on specified tables; accepts a list of table names and supports column exclusion options
- [x] **PKG-04**: Running `mix threadline.install` twice is idempotent (safe migration re-runs do not corrupt data or fail)
- [x] **PKG-05**: The package compiles without warnings under `mix compile --warnings-as-errors`

### Capture Layer

- [x] **CAP-01**: Every INSERT on an audited table is recorded as an `AuditChange` row with `operation = :insert`, `data_after` (JSONB), and `changed_fields` list
- [x] **CAP-02**: Every UPDATE on an audited table is recorded as an `AuditChange` row with `operation = :update`, `data_after` (JSONB), and `changed_fields` list
- [x] **CAP-03**: Every DELETE on an audited table is recorded as an `AuditChange` row with `operation = :delete` and `data_after = null`; the row's primary key is preserved in `table_pk`
- [x] **CAP-04**: Capture fires from PostgreSQL triggers so writes made directly via SQL or `Ecto.Repo` calls without app-layer callbacks are still captured
- [x] **CAP-05**: Multiple row mutations within a single database transaction are grouped under one `AuditTransaction` record
- [x] **CAP-06**: `AuditChange` rows reference their `AuditTransaction` via a foreign key; orphaned change records are not permitted
- [x] **CAP-07**: All audit data is stored as JSONB or typed columns; no Erlang binary terms or YAML serialization is used anywhere in the schema
- [x] **CAP-08**: `AuditTransaction` records an `occurred_at` timestamp set at transaction commit time (not insert time)
- [x] **CAP-09**: `AuditChange` records a `captured_at` timestamp set when the trigger fires
- [x] **CAP-10**: Capture does not fire on the `audit_transactions` or `audit_changes` tables themselves (no recursive audit loops)

### Actor Model

- [ ] **ACTR-01**: `ActorRef` is a value object with `actor_type` (enum) and `actor_id` (string); it is not a foreign key into any application table
- [ ] **ACTR-02**: `ActorRef.actor_type` supports exactly: `user`, `admin`, `service_account`, `job`, `system`, `anonymous`
- [ ] **ACTR-03**: An `anonymous` actor can be created without an `actor_id`; all other actor types require a non-empty `actor_id`
- [ ] **ACTR-04**: `ActorRef` is serializable to/from a plain map so it can be stored in JSONB columns and reconstructed without schema coupling

### Semantics Layer

- [ ] **SEM-01**: `Threadline.record_action/2` records an `AuditAction` with at minimum: `name` (atom), `actor_ref` (ActorRef), and `status` (`:ok` or `:error`)
- [ ] **SEM-02**: `AuditAction` supports optional fields: `verb`, `category`, `reason` (atom), `comment` (string), `correlation_id`, `request_id`, `job_id`
- [ ] **SEM-03**: An `AuditAction` can be linked to one or more `AuditTransaction` records to connect semantic events to row-level changes
- [ ] **SEM-04**: `AuditAction` records are stored in an `audit_actions` table created by `mix threadline.install`; all fields are typed columns or JSONB — no opaque blobs
- [ ] **SEM-05**: Recording an `AuditAction` with an invalid `ActorRef` (e.g., missing `actor_id` for a non-anonymous type) returns a tagged error tuple, not a runtime exception

### Context Propagation

- [ ] **CTX-01**: `Threadline.Plug` extracts actor and request context from a `Plug.Conn` and makes it available as an `AuditContext` for the duration of the request
- [ ] **CTX-02**: `AuditContext` carries: `actor_ref`, `request_id`, `correlation_id`, and `remote_ip`
- [ ] **CTX-03**: Context propagation to PostgreSQL uses a connection-level session variable (not a process dictionary entry) so it survives PgBouncer transaction-mode pooling
- [ ] **CTX-04**: When no context is set, capture still works — the `actor_ref` columns on `AuditTransaction` are nullable
- [ ] **CTX-05**: `Threadline.Job` module binds actor and correlation context for Oban workers; context is explicitly passed, not stored in ETS or a process dictionary

### Query API

- [ ] **QUERY-01**: `Threadline.history(schema_module, id)` returns a list of `AuditChange` records for the given record, ordered by `captured_at` descending
- [ ] **QUERY-02**: `Threadline.actor_history(actor_ref)` returns a list of `AuditTransaction` records associated with the given actor
- [ ] **QUERY-03**: `Threadline.timeline/1` accepts filter options (`:table`, `:actor_ref`, `:from`, `:to`) and returns a combined list of `AuditChange` records
- [ ] **QUERY-04**: All query functions accept an `Ecto.Repo` option so callers can target a specific repo in multi-repo setups
- [ ] **QUERY-05**: Query results are plain Ecto structs, not opaque library types — callers can pipe results through standard `Ecto.Query` composition

### Health & Observability

- [ ] **HLTH-01**: `Threadline.Health.trigger_coverage/0` returns a list of audited tables and whether each has a valid trigger installed in the current PostgreSQL schema
- [ ] **HLTH-02**: A table with no trigger installed is reported as `{:uncovered, table_name}` in the coverage result
- [ ] **HLTH-03**: `:telemetry` event `[:threadline, :transaction, :committed]` is emitted after each `AuditTransaction` is committed, with `%{table_count: n}` as measurements
- [ ] **HLTH-04**: `:telemetry` event `[:threadline, :action, :recorded]` is emitted after each `AuditAction` is persisted, with `%{status: :ok | :error}` as measurements
- [ ] **HLTH-05**: `:telemetry` event `[:threadline, :health, :checked]` is emitted when `trigger_coverage/0` is called, with `%{covered: n, uncovered: m}` as measurements

### CI & Quality

- [x] **CI-01**: `mix verify.format` exits non-zero if any file is not formatted
- [x] **CI-02**: `mix verify.credo` runs Credo in strict mode and exits non-zero on violations
- [x] **CI-03**: `mix verify.test` runs the full test suite and exits non-zero on any failure
- [x] **CI-04**: `mix ci.all` runs `verify.format`, `verify.credo`, and `verify.test` in sequence; exits non-zero if any step fails
- [x] **CI-05**: GitHub Actions workflow uses stable `id:` fields for all jobs; job `name:` fields may change freely without breaking status checks
- [x] **CI-06**: All CI jobs run on `push` to `main` regardless of path filters applied to PR jobs
- [x] **CI-07**: `mix test` runs the full suite with no silently excluded tests; any exclusion is documented in `test/test_helper.exs` and the README

### Documentation

- [ ] **DOC-01**: README contains a working installation example (add dep, run install task, configure Plug) that a developer can follow in under 15 minutes
- [ ] **DOC-02**: README links to a domain reference document that defines: AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, and Correlation
- [ ] **DOC-03**: README documents the PgBouncer transaction-mode constraint and the safe context propagation pattern Threadline uses
- [x] **DOC-04**: CONTRIBUTING.md skeleton exists and describes how to run the test suite and submit a PR
- [ ] **DOC-05**: All public API modules have `@moduledoc` and all public functions have `@doc` strings

## v2 Requirements

### Before-Values Capture

- **BVAL-01**: Trigger option `store_changed_from: true` captures `changed_from` (JSONB) with the previous field values for UPDATE operations
- **BVAL-02**: `Threadline.history/2` includes `changed_from` in results when the option was enabled at trigger time

### Developer Tooling

- **TOOL-01**: `mix threadline.verify_coverage` prints a human-readable table of audited tables and their trigger status; exits non-zero if any table is uncovered
- **TOOL-02**: Backfill helper enables introducing auditing to an existing table without losing history continuity
- **TOOL-03**: Doc contract tests assert that README code examples are syntactically valid and match the public API

### Retention & Redaction

- **RETN-01**: `RetentionPolicy` configuration allows specifying a maximum age for `AuditChange` records per table
- **RETN-02**: A purge task deletes expired records in batches to avoid table locks; respects a configurable batch size
- **REDN-01**: `RedactionPolicy` configuration allows marking specific columns as excluded (not captured) or masked (value replaced with a fixed token)
- **REDN-02**: Field exclusion and masking are applied at trigger time, not post-processing; excluded fields never enter the database

### Export

- **EXPO-01**: `Threadline.Export.to_csv/2` exports a filtered set of `AuditChange` records to a CSV-formatted binary
- **EXPO-02**: `Threadline.Export.to_json/2` exports a filtered set of `AuditChange` records to a JSON-formatted binary

## Out of Scope

| Feature | Reason |
|---------|--------|
| WAL / logical replication CDC backend | Requires `wal_level` changes (irreversible on some clouds), PgBouncer hazards, and operational surface area incompatible with batteries-included v0.x promise |
| TRUNCATE capture | PostgreSQL triggers do not fire on TRUNCATE; workarounds are fragile; documented as an explicit gap |
| LiveView operator UI (v0.1) | Premature before API surface is stable; deferred to v0.2+ |
| SIEM / security information and event management | Different product category, different buyers, different infrastructure |
| Full event sourcing / CQRS | Threadline captures audit facts; it does not drive application state reconstruction |
| pgAudit replacement | Statement-level DB auditing is a separate concern; Threadline is application-level |
| Association tracking (has_many, etc.) | Added enormous complexity to Ruby PaperTrail; keep v0.1 focused on row-level changes |
| Process-local / ETS audit context | Silently disappears across async boundaries; source of subtle production bugs |
| YAML / Erlang term serialization | Caused years of upgrade pain in Ruby Audited and ExAudit; JSONB is the answer |
| Automatic field exclusion via schema annotations | Couples app schemas to audit library; hard to apply to third-party schemas |
| Multi-tenant prefix scoping | Defer until base capture is validated |
| Umbrella package / `threadline_web` companion | Defer until API sketch exists and usage patterns are known |
| Audit-of-audit (who viewed audit data) | Very high-trust environments only; not v0.1 scope |
| As-of snapshot reconstruction | High value, high complexity; deferred to v0.2+ |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PKG-01 | Phase 1 | Complete |
| PKG-02 | Phase 1 | Complete |
| PKG-03 | Phase 1 | Complete |
| PKG-04 | Phase 1 | Complete |
| PKG-05 | Phase 1 | Complete |
| CAP-01 | Phase 1 | Complete |
| CAP-02 | Phase 1 | Complete |
| CAP-03 | Phase 1 | Complete |
| CAP-04 | Phase 1 | Complete |
| CAP-05 | Phase 1 | Complete |
| CAP-06 | Phase 1 | Complete |
| CAP-07 | Phase 1 | Complete |
| CAP-08 | Phase 1 | Complete |
| CAP-09 | Phase 1 | Complete |
| CAP-10 | Phase 1 | Complete |
| ACTR-01 | Phase 2 | Pending |
| ACTR-02 | Phase 2 | Pending |
| ACTR-03 | Phase 2 | Pending |
| ACTR-04 | Phase 2 | Pending |
| SEM-01 | Phase 2 | Pending |
| SEM-02 | Phase 2 | Pending |
| SEM-03 | Phase 2 | Pending |
| SEM-04 | Phase 2 | Pending |
| SEM-05 | Phase 2 | Pending |
| CTX-01 | Phase 2 | Pending |
| CTX-02 | Phase 2 | Pending |
| CTX-03 | Phase 2 | Pending |
| CTX-04 | Phase 2 | Pending |
| CTX-05 | Phase 2 | Pending |
| QUERY-01 | Phase 3 | Pending |
| QUERY-02 | Phase 3 | Pending |
| QUERY-03 | Phase 3 | Pending |
| QUERY-04 | Phase 3 | Pending |
| QUERY-05 | Phase 3 | Pending |
| HLTH-01 | Phase 3 | Pending |
| HLTH-02 | Phase 3 | Pending |
| HLTH-03 | Phase 3 | Pending |
| HLTH-04 | Phase 3 | Pending |
| HLTH-05 | Phase 3 | Pending |
| CI-01 | Phase 1 | Complete |
| CI-02 | Phase 1 | Complete |
| CI-03 | Phase 1 | Complete |
| CI-04 | Phase 1 | Complete |
| CI-05 | Phase 1 | Complete |
| CI-06 | Phase 1 | Complete |
| CI-07 | Phase 1 | Complete |
| DOC-01 | Phase 4 | Pending |
| DOC-02 | Phase 4 | Pending |
| DOC-03 | Phase 4 | Pending |
| DOC-04 | Phase 1 | Complete |
| DOC-05 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 51 total
- Mapped to phases: 51
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-22*
*Last updated: 2026-04-22 after initial definition from PROJECT.md and feature research*
