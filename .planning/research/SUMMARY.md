# Project Research Summary

**Project:** Threadline — Elixir audit platform for Phoenix/Ecto/PostgreSQL
**Domain:** Trigger-backed audit capture + application-level action semantics (Hex library)
**Researched:** 2026-04-22
**Confidence:** HIGH (core stack, features, architecture, pitfalls all grounded in authoritative project sources and documented ecosystem prior art)

---

## Executive Summary

Threadline is a correctness-first audit library for the Elixir/Phoenix/Ecto/PostgreSQL stack. The defining pattern of high-quality Elixir audit libraries is trigger-backed capture — row mutations are recorded at the database level, not the application layer, making it impossible to miss changes from direct SQL, Ecto.Multi, or bulk operations. Every serious competitor (Carbonite, PaperTrail, ExAudit) stops there. Threadline's differentiation is the semantic layer on top: a first-class `AuditAction` model with typed `ActorRef`, structured `AuditContext`, and correlation IDs that survive async boundaries — none of which exist in any current Elixir library.

The recommended approach: build on Carbonite (~> 0.16) as the capture substrate, confirm compatibility in a Phase 1 research gate, and layer Threadline's semantics model on top. The schema separates `audit_transactions` (DB-level, trigger-linked) from `audit_actions` (application-level intent) with an explicit nullable FK between them. Actor identity is a JSONB value object — not a user FK — supporting all six actor types (user, admin, service account, job, system, anonymous) from day one.

The two most dangerous pitfalls — both documented in production failures across competitor libraries — are (1) PgBouncer transaction pooling breaking session-variable metadata propagation and (2) ETS/PID-scoped context stores silently losing actor identity across async boundaries. Both are design-time decisions. The context propagation mechanism must be chosen before building any trigger infrastructure, because it determines schema shape and correctness guarantees for every downstream consumer.

---

## Key Findings

### Recommended Stack

Threadline's runtime stack is well-settled: Elixir ≥ 1.15, OTP ≥ 26, PostgreSQL ≥ 14, Ecto ~> 3.10, Postgrex ~> 0.17, Jason ~> 1.4, Telemetry ~> 1.2. The one open decision is the capture substrate. Carbonite (~> 0.16) is the leading candidate — it is the best-maintained trigger library in the Elixir ecosystem, handles composite PKs, schema isolation, `Ecto.Multi`, column filtering, and outbox abstraction. A custom trigger implementation is only warranted if Phase 1 research reveals a hard incompatibility. All other stack decisions (Jason over Poison, real PostgreSQL in CI, Telemetry over custom callbacks, Plug as optional dep) are clear calls with documented rationale.

**Core technologies:**
- Elixir ≥ 1.15 / OTP ≥ 26: project constraint; 1.17+ preferred for improved type system
- PostgreSQL ≥ 14: trigger host and JSONB storage; JSONB performance gains available from PG 14
- Ecto ~> 3.10 + Ecto SQL: DB abstraction, migration DSL, `Ecto.Multi` for atomic wrapping
- Postgrex ~> 0.17: PostgreSQL wire protocol; native JSONB map support, no custom codec needed
- Carbonite ~> 0.16 *(pending Phase 1 gate)*: trigger-backed capture substrate
- Jason ~> 1.4: JSONB encoding; ecosystem standard
- Telemetry ~> 1.2: observability hooks; OTP-native, no custom callback surface

**Notable exclusions:**
- No ETS / process dictionary for audit context
- No session-local `SET LOCAL` for metadata propagation
- No Erlang binary or YAML serialization for audit data
- No monkeypatching of `Ecto.Repo`
- No hard Phoenix runtime dependency (Threadline is a library, not a Phoenix app)

### Expected Features

**Must have (table stakes):**
- INSERT/UPDATE/DELETE capture via PostgreSQL triggers — correctness guarantee at DB level
- Before/after values + changed fields list per row mutation
- Row identity preservation after delete (normalized `table_pk` JSONB)
- Timestamps on every record (`occurred_at`, `captured_at`)
- Actor tracking via typed `ActorRef` (user, admin, service account, job, system, anonymous)
- SQL-queryable JSONB storage — no opaque blobs
- `mix threadline.install` + `mix threadline.gen.triggers` migration helpers
- Basic query API: resource history, actor history, timeline

**Should have (competitive differentiators — none exist in any current Elixir library):**
- `AuditAction` semantic layer: name, verb, category, status, actor, subject, reason, correlation
- First-class polymorphic `ActorRef` (JSONB value object, not a user FK)
- Correlation IDs propagated explicitly across async/job boundaries
- Trigger coverage health checks + `mix threadline.verify_coverage`
- Oban job helper (`Threadline.Job`) for background worker context binding
- Reason + comment fields on `AuditAction`
- Telemetry events for all major lifecycle points

**Defer to v0.2+:**
- Redaction / field masking (`RedactionPolicy`)
- Retention + scheduled purge with legal hold
- Export sinks (CSV/JSON/Oban outbox)
- LiveView operator UI (`threadline_web` or optional component)
- As-of snapshot reconstruction
- Multi-tenant Ecto prefix scoping
- Association tracking (avoid — PaperTrail proved this bloats the core)

### Architecture Approach

Three bounded contexts, with strict non-negotiable separation. **Capture** owns DB-level concerns: `AuditTransaction`, `AuditChange`, trigger registration, column filtering, and row integrity. **Semantics** owns application-level concepts: `AuditAction`, `ActorRef`, `AuditContext`, correlation, request/job binding, reason, evidence. **Exploration/Operations** owns the read side: timelines, diffs, as-of queries, exports, health checks, retention, redaction. Collapse any two of these — as PaperTrail, ExAudit, and Logidze each did in different ways — and you inherit their failure modes.

**Major components:**
1. `Threadline.Capture` — Carbonite adapter, trigger SQL, migration helpers, coverage checks; swap adapter without touching semantics
2. `Threadline.Semantics` — `AuditAction`, `ActorRef`, `AuditContext` as pure Elixir value objects; no trigger or Ecto dependency
3. `Threadline.Integration` — thin Plug and Oban adapters; the only place where external frameworks touch Threadline
4. `Threadline.Query` — read-only query layer; joins across capture and semantics tables; pagination-first
5. `Threadline.Operations` — health checks, retention, redaction; background-safe, scheduled mutations last

**Data model key decisions:**
- `audit_transactions` and `audit_actions` are separate tables with nullable FK (`audit_transactions.action_id → audit_actions.id`)
- `ActorRef` stored as JSONB on both tables — no FK to application user tables
- `data_after` / `data_before` as JSONB; `op`, `table_name`, `actor_type` as indexed text columns
- Context propagation via `audit_transactions` row insert inside the DB transaction (not session variables)

### Critical Pitfalls

1. **PgBouncer transaction pooling corrupts session-variable metadata** — `SET LOCAL` used for actor propagation is connection-scoped and silently wrong under PgBouncer transaction pooling (default for cloud deployments). Fix: insert `audit_transactions` row within the same DB transaction — pooler-agnostic by design. This is a Phase 1 schema decision that cannot be retrofitted.

2. **Process-local / ETS context stores lose actor across async boundaries** — `Task.async`, Oban workers, and Phoenix channels spawn new processes with no access to parent's dictionary. Fix: hold `AuditContext` in the process dictionary for request/job duration only; serialize `correlation_id` into Oban job args explicitly; provide `Threadline.Job.bind_context/1` for reconstruction. This is a Phase 2 API design constraint.

3. **Conflating `AuditTransaction` with `AuditAction`** — forces a 1:1 assumption that is wrong in all edge cases (zero-action migrations, zero-transaction read events, multi-step sagas). Fix: encode separation in schema from day one with nullable FK. This is a joint Phase 1+2 design decision.

4. **Actor model collapse (everything is a user FK)** — breaks for service accounts, Oban jobs, system, and anonymous actors; requires painful schema migration to add each new type. Fix: `ActorRef` as JSONB value object with typed constructors from v0.1.

5. **`audit_changes` write bottleneck without partitioning** — under high-write workloads, the central append table becomes the most-written table in the database; adding partitioning after the fact requires downtime. Fix: document declarative range partitioning (`PARTITION BY RANGE (captured_at)`) in the install guide as a recommended option from v0.1.

---

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Capture Foundation
**Rationale:** Every other layer depends on correct, pooler-safe, trigger-backed capture. The context propagation mechanism determines schema shape — it must be locked before semantics or query layers are built. This is also where the Carbonite research gate lives.
**Delivers:** Working trigger infrastructure, correct schema, migration helpers, test support, PgBouncer-safe context propagation, trigger coverage health check
**Addresses (FEATURES.md):** INSERT/UPDATE/DELETE capture, `mix threadline.install`, `mix threadline.gen.triggers`, basic actor storage on `audit_transactions`, immutability enforcement, trigger coverage health check
**Avoids (PITFALLS.md):** PgBouncer metadata corruption (pitfall 1), migration ordering failures (pitfall 9), test sandbox incompatibility (pitfall 10), write bottleneck schema (pitfall 6), schema drift via session variables (anti-pattern 2)
**Research flag:** Confirm Carbonite version, PostgreSQL floor, trigger metadata mechanism, and maintenance status before locking the adapter choice

### Phase 2: Semantics Layer
**Rationale:** Once capture is correct, the semantic layer adds what no competitor provides. `AuditAction`, `ActorRef`, and `AuditContext` are pure Elixir concerns — they do not touch trigger plumbing. Plug and Oban integrations deliver the developer ergonomics that make the library adoptable.
**Delivers:** `AuditAction` recording, typed `ActorRef` value object, `AuditContext` propagation, `Threadline.Plug`, `Threadline.Job` Oban helper, correlation ID threading, reason/comment fields
**Implements (ARCHITECTURE.md):** Semantics bounded context, Integration module, context propagation API that explicitly avoids ETS/PID
**Avoids (PITFALLS.md):** Process-local context store (pitfall 2), actor model collapse (pitfall 5), soft-delete semantic ambiguity (pitfall 8)
**Research flag:** Standard patterns — Plug/Oban integration is well-documented; no external research needed

### Phase 3: Query & Operations Layer
**Rationale:** After capture and semantics are validated in a real app, the query API can be shaped to the actual access patterns. Building the query layer before the data model is stable leads to premature abstractions that block schema evolution.
**Delivers:** `resource_history/2`, `actor_history/1`, `correlation_trace/1`, `Threadline.Diff`, timeline pagination, `Threadline.Health.run_checks/0`, telemetry events
**Addresses (FEATURES.md):** Basic query API (P1), telemetry (P1), `mix threadline.verify_coverage` (P2), JSONB schema drift helpers (pitfall 7)
**Avoids (PITFALLS.md):** Unbounded queries (no pagination default), JSONB shape drift in `fetch_field` helpers
**Research flag:** No external research needed; access patterns will emerge from Phase 1+2 usage

### Phase 4: Hardening & Hex Publish
**Rationale:** The OSS DNA requires doc contract tests, CI stability, and a working example app before publishing. The README example must be tested; ExDoc + Hex publication require final API stability.
**Delivers:** README + guides, ExDoc Hex docs, CI pipeline (`mix ci.all`), doc contract tests, example app, `mix threadline.verify_coverage` CLI, backfill helper
**Addresses (FEATURES.md):** All P1 items closed; P2 items (before-values `store_changed_from`, backfill helper, doc contract tests) included
**Research flag:** Standard patterns; no external research needed

### Phase Ordering Rationale

- **Schema before API:** Context propagation mechanism (Phase 1) determines whether every downstream record is correct. Reversing this order produces ExAudit's footgun.
- **Semantics after correctness:** `AuditAction` is only meaningful if the underlying `AuditChange` records are trustworthy. Building the semantic layer before capture is stable yields PaperTrail's bug surface.
- **Query after data model:** Query helpers must know the stable shape of `ActorRef`, `AuditContext`, and the `audit_transactions ↔ audit_actions` link. Building them earlier creates churn.
- **Docs/publish after API stability:** Doc contract tests enforce that README examples work; publishing before this produces brittle docs that mislead adopters.

### Research Flags

Phases needing deeper research during planning:
- **Phase 1:** Carbonite research gate — confirm version, PG floor, trigger metadata mechanism (session variable vs. transaction row), and maintenance status before locking adapter

Phases with standard patterns (skip research):
- **Phase 2:** Plug/Oban integration patterns are well-documented; `AuditContext` design is fully specified in domain model reference
- **Phase 3:** Query layer patterns are standard Ecto; no novel research needed
- **Phase 4:** ExDoc, Hex, GitHub Actions patterns are well-established

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH (core) / MEDIUM (Carbonite) | Core runtime stack is stable and well-sourced; Carbonite version/maintenance needs Phase 1 verification |
| Features | HIGH | Grounded in deep domain model reference + documented prior-art failures across 6+ libraries |
| Architecture | HIGH | Derived directly from authoritative project documents; three bounded contexts are non-negotiable by design |
| Pitfalls | HIGH | Every critical pitfall maps to a documented production failure in a named library (Logidze, ExAudit, Carbonite, PaperTrail, Ruby Audited) |

**Overall confidence:** HIGH

### Gaps to Address

- **Carbonite compatibility gate:** Confirm exact version, PostgreSQL ≥ 14 support, trigger metadata mechanism (session-local vs. transaction row), and maintenance status in Phase 1 before locking the capture substrate
- **Postgrex 0.18.x changes:** Verify no breaking changes in JSONB handling
- **Elixir 1.18 status:** Has it shipped by April 2026? Any type system features relevant to Threadline's public API design?
- **PgBouncer test coverage:** Integration test with PgBouncer in transaction pooling mode is documented but not yet built; must be a Phase 1 exit criterion
- **LiveView integration:** Explicitly deferred to v0.2+; socket-assign context binding pattern not yet designed

---

## Sources

### Primary (HIGH confidence)
- `prompts/audit-lib-domain-model-reference.md` — canonical domain model, entities, bounded contexts, API shapes
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem analysis, prior-art lessons, Carbonite evaluation
- `.planning/PROJECT.md` — constraints, decisions, out-of-scope boundaries
- `prompts/threadline-elixir-oss-dna.md` — engineering quality bar, CI/testing patterns

### Secondary (MEDIUM confidence)
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md` — Elixir API design patterns
- Carbonite v0.16.x library — current version confirmed in ecosystem analysis; verify in Phase 1
- Elixir/Ecto ecosystem knowledge — Postgrex JSONB, Phoenix LTS, Oban prevalence

### Tertiary (referenced in pitfalls)
- Logidze README/issues — PgBouncer session variable limitation documented
- ExAudit GitHub — ETS/PID-scoped context; async issues raised by community
- Ruby PaperTrail issue archive — association tracking complexity
- Ruby Audited CHANGELOG — YAML storage deprecation
- PostgreSQL documentation — `SET LOCAL` scope, partitioning, trigger WHEN clauses

---

*Research completed: 2026-04-22*
*Ready for roadmap: yes*
