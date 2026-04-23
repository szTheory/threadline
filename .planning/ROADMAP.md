# Roadmap: Threadline

## Overview

Threadline builds from correctness upward: establish trigger-backed row capture first (Phase 1), layer on application-level action semantics (Phase 2), add the query and observability surface (Phase 3), then document and publish to Hex (Phase 4). Each phase delivers a coherent, independently verifiable capability. Phase 1 closed the capture substrate decision (Path B: custom `Threadline.Capture` triggers — see `gate-01-01.md`); downstream phases build on that contract.

## Phases

- [x] **Phase 1: Capture Foundation** - Trigger-backed row capture with correct PgBouncer-safe schema, migration helpers, and CI pipeline (completed 2026-04-23)
- [x] **Phase 2: Semantics Layer** - AuditAction, typed ActorRef, AuditContext, Plug integration, and Oban job context binding (completed 2026-04-23)
- [ ] **Phase 3: Query & Observability** - Query API, health checks, and telemetry events
- [ ] **Phase 4: Documentation & Release** - README, domain reference, ExDoc strings, and Hex publish readiness

## Phase Details

### Phase 1: Capture Foundation
**Goal**: Every INSERT, UPDATE, and DELETE on an audited table is durably captured in a correct, SQL-queryable schema — regardless of how the write occurred
**Depends on**: Nothing (first phase)
**Requirements**: PKG-01, PKG-02, PKG-03, PKG-04, PKG-05, CAP-01, CAP-02, CAP-03, CAP-04, CAP-05, CAP-06, CAP-07, CAP-08, CAP-09, CAP-10, CI-01, CI-02, CI-03, CI-04, CI-05, CI-06, CI-07, DOC-04
**Success Criteria** (what must be TRUE):
  1. A developer can run `mix threadline.install` and `mix threadline.gen.triggers` to set up the audit schema and triggers on a fresh PostgreSQL database
  2. Every INSERT, UPDATE, and DELETE on an audited table produces an `AuditChange` row with correct operation type, JSONB data, and grouped `AuditTransaction`
  3. Writes made directly via SQL or `Ecto.Repo` calls (bypassing application-layer callbacks) are still captured
  4. Running `mix threadline.install` twice is safe — no data corruption, no migration failure
  5. `mix ci.all` passes: `verify.format`, `verify.credo`, and `verify.test` all green; CONTRIBUTING.md skeleton exists
**Plans**: 3 defined

Plans:
- [x] 01-01: Carbonite Research Gate — binary decision (Carbonite or custom triggers); produces `gate-01-01.md` when executed
- [x] 01-02: Library Scaffold + Schema + Capture Infrastructure — working trigger capture, Mix tasks, integration tests
- [x] 01-03: CI Pipeline + CONTRIBUTING.md — passing GitHub Actions CI, `mix ci.all` green

### Phase 2: Semantics Layer
**Goal**: Application code can record who did what and why, with full actor identity, request context, and correlation IDs that survive async boundaries
**Depends on**: Phase 1
**Requirements**: ACTR-01, ACTR-02, ACTR-03, ACTR-04, SEM-01, SEM-02, SEM-03, SEM-04, SEM-05, CTX-01, CTX-02, CTX-03, CTX-04, CTX-05
**Success Criteria** (what must be TRUE):
  1. `Threadline.record_action/2` persists an `AuditAction` with actor, intent, and status to the `audit_actions` table
  2. An `ActorRef` can represent all six actor types (user, admin, service account, job, system, anonymous) without schema changes; anonymous requires no actor_id
  3. `Threadline.Plug` captures request context (actor, request_id, correlation_id, remote_ip) for the duration of a Phoenix request
  4. `Threadline.Job` binds actor and correlation context for an Oban worker without using ETS or process dictionary
  5. An invalid `ActorRef` (missing actor_id for a non-anonymous type) returns a tagged error tuple, not a runtime exception
**Plans**: 3 defined

Plans:
- [x] 02-01: Semantics schema, ActorRef, trigger GUC bridge
- [x] 02-02: AuditAction, `record_action/2`, associations
- [x] 02-03: `AuditContext`, `Threadline.Plug`, `Threadline.Job`

### Phase 3: Query & Observability
**Goal**: Operators and application code can query audit history and monitor capture health through a composable Elixir API and telemetry events
**Depends on**: Phase 2
**Requirements**: QUERY-01, QUERY-02, QUERY-03, QUERY-04, QUERY-05, HLTH-01, HLTH-02, HLTH-03, HLTH-04, HLTH-05
**Success Criteria** (what must be TRUE):
  1. `Threadline.history(schema_module, id)` returns ordered `AuditChange` records for a given record; results are plain Ecto structs
  2. `Threadline.actor_history(actor_ref)` returns `AuditTransaction` records for a given actor
  3. `Threadline.timeline/1` accepts filter options (`:table`, `:actor_ref`, `:from`, `:to`) and returns a filtered result set
  4. `Threadline.Health.trigger_coverage/0` reports covered and uncovered tables; uncovered tables are explicitly flagged as `{:uncovered, table_name}`
  5. `:telemetry` events fire for transaction commit, action record, and health check; each carries the documented measurement map
**Plans**: 2 defined

Plans:
- [ ] 03-01: Query Core — `Threadline.Query` module with `history/2`, `actor_history/1`, `timeline/1`; delegating functions on `Threadline`; GIN index migration
- [ ] 03-02: Health + Telemetry — `Threadline.Health.trigger_coverage/0`; `Threadline.Telemetry` helper; telemetry patch to `record_action/2`

### Phase 4: Documentation & Release
**Goal**: Threadline is published on Hex with complete, tested documentation that a developer can follow in under 15 minutes to set up audit capture in a Phoenix app
**Depends on**: Phase 3
**Requirements**: DOC-01, DOC-02, DOC-03, DOC-05
**Success Criteria** (what must be TRUE):
  1. A developer following the README installation example (add dep, run install task, configure Plug) has audit capture working in under 15 minutes
  2. The README documents the PgBouncer transaction-mode constraint and Threadline's safe context propagation pattern
  3. The domain reference document defines all six core entities: AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, and Correlation
  4. All public API modules have `@moduledoc` and all public functions have `@doc` strings
**Plans**: TBD

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Capture Foundation | 3/3 | Complete    | 2026-04-23 |
| 2. Semantics Layer | 3/3 | Complete    | 2026-04-23 |
| 3. Query & Observability | 0/2 | Ready      | - |
| 4. Documentation & Release | 0/? | Not started | - |
