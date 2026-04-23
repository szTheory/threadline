# Architecture Research

**Domain:** Elixir audit platform (trigger-backed capture + semantics + operations)
**Researched:** 2026-04-22
**Confidence:** HIGH — derived from authoritative project documents and domain model reference

---

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     Host Application                              │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │  Plug/Phoenix│  │  Oban Jobs   │  │  Direct Ecto / Scripts │  │
│  │   Requests   │  │  Workers     │  │  Migrations / Backfill │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬─────────────┘  │
└─────────│─────────────────│──────────────────────│────────────────┘
          │                 │                      │
          ▼                 ▼                      ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Semantics Layer (Threadline)                      │
│                                                                    │
│  Threadline.Plug      Threadline.Job      (no wiring needed)      │
│  ─────────────        ─────────────                               │
│  • bind AuditContext  • bind AuditContext                         │
│  • resolve ActorRef   • resolve ActorRef                         │
│  • set correlation    • propagate correlation                     │
│                                                                    │
│  Threadline.Action.record/2                                       │
│  ─────────────────────────                                        │
│  • AuditAction (name, actor, subject, reason, context, status)   │
│  • links to AuditTransaction via context_id / action_id          │
└───────────────────────────────────────┬──────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Capture Layer (Threadline)                       │
│                                                                    │
│  PostgreSQL Triggers (per audited table)                          │
│  ──────────────────────────────────────                          │
│  INSERT / UPDATE / DELETE  →  audit_changes row                   │
│                            →  linked to audit_transactions row    │
│                                                                    │
│  Threadline.Capture  (Carbonite substrate or equivalent)          │
│  ────────────────────                                             │
│  • migration helpers     • trigger registration                   │
│  • context propagation   • excluded / filtered columns            │
│  • outbox integration    • composite PK support                   │
└───────────────────────────────────────┬──────────────────────────┘
                                        │
                                        ▼
┌──────────────────────────────────────────────────────────────────┐
│                     PostgreSQL Database                            │
│                                                                    │
│  audit_transactions   audit_changes   audit_actions               │
│  ────────────────     ─────────────   ─────────────               │
│  id                   id              id                          │
│  actor_ref (JSONB)    transaction_id  name                        │
│  context_ref (JSONB)  table_schema    actor_ref (JSONB)           │
│  action_id            table_name      subject_refs (JSONB[])      │
│  occurred_at          table_pk        context_ref (JSONB)         │
│  source               op              reason                      │
│  meta (JSONB)         data_after      status                      │
│                       changed_fields  started_at / completed_at   │
│                       data_before     meta (JSONB)                │
└──────────────────────────────────────────────────────────────────┘
```

### Three Bounded Contexts — Non-Negotiable Separation

| Bounded Context | Owns | Does NOT Own |
|-----------------|------|--------------|
| **Capture** | AuditTransaction, AuditChange, trigger registration, change-field filtering, row identity, integrity | Action naming, UI grouping, retention decisions |
| **Semantics** | AuditAction, ActorRef, AuditContext, correlation IDs, request/job binding, reason, evidence | How rows changed, trigger plumbing |
| **Exploration/Operations** | Query API, timelines, diffs, as-of snapshots, exports, health checks, retention, redaction, coverage | Capture details, semantic naming conventions |

This separation is the core architectural principle. Collapsing these was the mistake made by PaperTrail (too action-heavy), ExAudit (too change-heavy), and Logidze (record-local, loses history on delete).

---

## Recommended Project Structure

```
lib/
├── threadline.ex                   # top-level public API surface
│
├── threadline/
│   ├── capture/
│   │   ├── carbonite.ex            # Carbonite adapter (if used)
│   │   ├── transaction.ex          # AuditTransaction struct + queries
│   │   ├── change.ex               # AuditChange struct + queries
│   │   ├── migration.ex            # migration helpers
│   │   └── coverage.ex             # trigger coverage checks
│   │
│   ├── semantics/
│   │   ├── action.ex               # AuditAction struct + record/2
│   │   ├── actor.ex                # ActorRef value object
│   │   ├── context.ex              # AuditContext value object
│   │   ├── subject.ex              # SubjectRef value object
│   │   └── correlation.ex          # correlation ID helpers
│   │
│   ├── integration/
│   │   ├── plug.ex                 # Threadline.Plug — bind context in requests
│   │   └── job.ex                  # Threadline.Job — bind context in Oban workers
│   │
│   ├── query/
│   │   ├── timeline.ex             # list_timeline/1, resource_history/2
│   │   ├── diff.ex                 # diff_versions/2, changed_fields/2
│   │   └── snapshot.ex             # reconstruct_as_of/2
│   │
│   ├── operations/
│   │   ├── health.ex               # run_health_checks/0
│   │   ├── retention.ex            # run_retention/1
│   │   ├── redaction.ex            # apply_redaction/1
│   │   └── export.ex               # export_audit/1, sink management
│   │
│   └── telemetry.ex                # :telemetry events
│
├── mix/
│   └── tasks/
│       ├── threadline.install.ex   # mix threadline.install
│       └── threadline.gen.triggers.ex  # mix threadline.gen.triggers
│
test/
├── support/
│   ├── data_case.ex
│   └── audit_helpers.ex            # test assertion helpers
├── threadline/
│   ├── capture/
│   ├── semantics/
│   ├── integration/
│   ├── query/
│   └── operations/
└── test_helper.exs
```

### Structure Rationale

- **capture/**: owns DB-level concerns in isolation; swap Carbonite adapter without touching semantics
- **semantics/**: pure Elixir structs and value objects — no trigger or Ecto awareness required
- **integration/**: thin adapters for Plug and Oban; the only place where external frameworks touch Threadline
- **query/**: read-side only; no mutation; can be optimized independently
- **operations/**: background/admin tasks with own lifecycle; deliberately last, not first

---

## Architectural Patterns

### Pattern 1: Trigger-Backed Capture (not application hooks)

**What:** PostgreSQL triggers fire on INSERT/UPDATE/DELETE and write `audit_changes` rows directly, regardless of application code path.

**When to use:** Always — this is the foundation. Every audited table gets a trigger.

**Trade-offs:**
- Pro: Cannot be bypassed by plain `Repo` calls, direct SQL, Ecto.Multi shortcuts, or bulk operations
- Pro: Correctness guarantee is at the database level, not the application level
- Con: TRUNCATE is not captured (document this explicitly, recommend against unlogged TRUNCATE on audited tables)
- Con: Metadata must be propagated into the transaction via a secondary mechanism (session-local variables or an audit_transactions row written before domain writes)

**Example:**
```sql
-- Trigger created by mix threadline.gen.triggers
CREATE TRIGGER audit_members_changes
  AFTER INSERT OR UPDATE OR DELETE ON members
  FOR EACH ROW EXECUTE FUNCTION threadline.capture_change();
```

```elixir
# Migration helper — generated, not hand-rolled
defmodule MyApp.Repo.Migrations.AddAuditToMembers do
  use Ecto.Migration
  def up, do: Threadline.Capture.Migration.install_trigger("members")
  def down, do: Threadline.Capture.Migration.remove_trigger("members")
end
```

---

### Pattern 2: Context Propagation via audit_transactions row (not session variables)

**What:** Before domain writes, Threadline inserts an `audit_transactions` row in the same DB transaction, carrying actor, context, and action references. Triggers link `audit_changes` rows to this transaction by ID.

**When to use:** Always — preferred over PostgreSQL session-local variables.

**Trade-offs:**
- Pro: PgBouncer-safe (Logidze uses session variables and documents PgBouncer hazards; Threadline must avoid this)
- Pro: Transaction-local, not connection-local — no leakage across async boundaries
- Pro: Survives any connection pool configuration
- Con: Requires inserting a row at transaction open time, adding a small write

**Example:**
```elixir
# The developer-facing API
Threadline.transaction(fn ->
  Threadline.set_actor(%ActorRef{type: :user, id: current_user.id})
  Threadline.Action.record("member.role_changed", subject: member_ref)
  Repo.update(changeset)  # trigger fires, links to audit_transaction
end)
```

---

### Pattern 3: ActorRef as Value Object (not FK to users table)

**What:** Actor identity is stored as a JSONB value object (`{type, id, display_name, impersonator_ref}`), not as a foreign key to any application table.

**When to use:** Always — the actor can be a user, admin, service account, Oban job, system, or anonymous entity.

**Trade-offs:**
- Pro: Decoupled from application user tables; no FK constraint, no join requirement
- Pro: Survives user deletion without losing audit history
- Pro: Represents all actor types uniformly without a brittle polymorphic FK
- Con: Cannot enforce referential integrity at the DB level — integrity is at application level

**Example:**
```elixir
# ActorRef is a plain struct/value object
%Threadline.ActorRef{
  type: :user,
  id: "usr_123",
  display_name: "Alice",
  impersonator_ref: nil
}

# Stored as JSONB in audit_transactions and audit_actions
# Queryable without application-level decoding:
# SELECT * FROM audit_actions WHERE actor_ref->>'id' = 'usr_123';
```

---

### Pattern 4: Action ≠ Change — Separate Records with Explicit Links

**What:** `audit_actions` and `audit_transactions`/`audit_changes` are separate tables linked via `context_id` or explicit `action_id` references. Actions carry semantic meaning; changes carry row-level truth.

**When to use:** Always — this is the core thesis. Never conflate them.

**Trade-offs:**
- Pro: An action can span many transactions (e.g., a multi-step workflow)
- Pro: An action can exist with zero row changes (read-side or administrative events)
- Pro: Row changes can be queried without loading action overhead
- Con: Traversal requires a join; query API must abstract this for common cases

---

### Pattern 5: JSONB + Typed Columns, No Opaque Serialization

**What:** Changed data (`data_after`, `data_before_subset`) stored as JSONB. Actor, context, subject refs stored as JSONB. Discriminator fields (`op`, `table_name`, `actor_type`) as typed columns for indexing.

**When to use:** Always.

**Why:** Ruby Audited's YAML storage and ExAudit's Erlang binary format both caused multi-year upgrade pain. JSONB is introspectable with plain SQL and does not require application-layer decoding for operator investigation.

---

## Data Flow

### Interactive Request Flow

```
HTTP Request
    │
    ▼
Threadline.Plug
    │  • initializes AuditContext (request_id, correlation_id, route, IP, user agent)
    │  • resolves ActorRef from session/assigns
    ▼
Controller / Service
    │
    ▼
Threadline.Action.record("member.role_changed", ...)
    │  • writes audit_actions row
    │  • carries context_id linking to transaction
    ▼
Ecto.Repo transaction opens
    │
    ▼
Threadline inserts audit_transactions row (same transaction)
    │  • actor_ref, context_ref, action_id, occurred_at
    ▼
Domain writes (Repo.insert/update/delete)
    │
    ▼
PostgreSQL triggers fire (per audited table)
    │  • write audit_changes rows
    │  • linked to audit_transactions.id
    ▼
Transaction commits
    │
    ▼
Query layer can now answer:
  • "What action was this?"    → audit_actions
  • "What rows changed?"       → audit_changes via audit_transactions
  • "Who did it?"              → actor_ref on both
  • "What request?"            → context_ref on both
```

### Background Job Flow

```
Oban Job starts
    │
    ▼
Threadline.Job.bind_context(job)
    │  • resolves actor (service_account or system)
    │  • propagates parent correlation_id from job args
    │  • sets source: :job, job_id, job_attempt
    ▼
Job logic runs
    │
    ▼
[same as request flow from "Threadline.Action.record" onward]
```

**Critical:** Context must be serialized into job args explicitly (not via ETS/PID). ExAudit's PID-scoped ETS context store is the anti-model — it does not survive async task spawning or Oban's worker process isolation.

### Correlation Propagation

```
Request (correlation_id: "req_abc")
    │
    ├── audit_transactions.context_ref.correlation_id = "req_abc"
    ├── audit_actions.context_ref.correlation_id = "req_abc"
    │
    └── enqueue Oban job with args: %{correlation_id: "req_abc"}
              │
              ▼
         Job binds context from args
              │
              ├── audit_transactions.context_ref.correlation_id = "req_abc"
              └── audit_actions.context_ref.correlation_id = "req_abc"

-- SQL: find all audit records for a request chain
SELECT * FROM audit_actions
WHERE context_ref->>'correlation_id' = 'req_abc'
ORDER BY started_at;
```

---

## Database Schema Design

### Core Tables

```sql
-- Capture layer
CREATE TABLE audit_transactions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  occurred_at     timestamptz NOT NULL DEFAULT now(),
  actor_ref       jsonb NOT NULL,      -- ActorRef value object
  context_ref     jsonb,               -- AuditContext value object
  action_id       uuid,                -- FK to audit_actions (nullable)
  source          text NOT NULL,       -- 'request'|'job'|'system'|'migration'
  meta            jsonb
);

CREATE TABLE audit_changes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id  uuid NOT NULL REFERENCES audit_transactions(id),
  table_schema    text NOT NULL,
  table_name      text NOT NULL,
  table_pk        jsonb NOT NULL,      -- {column: value} normalized
  op              text NOT NULL,       -- 'insert'|'update'|'delete'
  data_after      jsonb,
  changed_fields  text[],
  data_before     jsonb,               -- only changed fields subset
  captured_at     timestamptz NOT NULL DEFAULT now(),
  redaction_state text                 -- 'none'|'partial'|'full'
);

-- Semantics layer (separate table)
CREATE TABLE audit_actions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,       -- 'member.role_changed'
  category        text,                -- 'security'|'billing'|...
  verb            text,                -- 'update'|'delete'|'grant'|...
  actor_ref       jsonb NOT NULL,
  subject_refs    jsonb[],             -- SubjectRef value objects
  context_ref     jsonb,
  reason          text,
  comment         text,
  status          text NOT NULL,       -- 'succeeded'|'failed'|'partial'
  started_at      timestamptz NOT NULL DEFAULT now(),
  completed_at    timestamptz,
  meta            jsonb
);

-- Indexes for common query patterns
CREATE INDEX ON audit_changes (transaction_id);
CREATE INDEX ON audit_changes (table_name, (table_pk->>'id'));
CREATE INDEX ON audit_changes (captured_at DESC);
CREATE INDEX ON audit_transactions ((actor_ref->>'id'));
CREATE INDEX ON audit_transactions ((context_ref->>'correlation_id'));
CREATE INDEX ON audit_actions (name, started_at DESC);
CREATE INDEX ON audit_actions ((actor_ref->>'id'), started_at DESC);
```

### Schema Namespace

Use a dedicated `audit` schema (or `threadline` schema) to isolate audit tables from application tables. `Ecto.Migration` prefix support handles this cleanly.

---

## API Surface Design

Three layers of public API, exposed progressively:

```elixir
# Layer 1: Zero-to-one (install + basic capture)
mix threadline.install          # generates migrations, config
mix threadline.gen.triggers     # adds triggers to specified tables
plug Threadline.Plug            # in router or endpoint

# Layer 2: App integration
Threadline.set_actor(actor_ref)
Threadline.Action.record("member.role_changed", subject: ref, reason: "admin")
Threadline.transaction(fn -> ... end)
Threadline.Job.bind_context(job)  # in Oban worker

# Layer 3: Query + Operator
Threadline.Query.resource_history(Member, id)
Threadline.Query.actor_history(actor_ref)
Threadline.Query.correlation_trace(correlation_id)
Threadline.Diff.versions(change_a, change_b)
Threadline.Health.run_checks()
Threadline.Coverage.verify_triggers()
```

---

## Integration Points

### External Frameworks

| Framework | Integration Pattern | Notes |
|-----------|---------------------|-------|
| Phoenix / Plug | `Threadline.Plug` in pipeline | Binds AuditContext from conn; actor resolution via config callback |
| Ecto | Wraps `Repo` transaction to insert audit_transactions first | Must NOT monkeypatch Repo — explicit `Threadline.transaction/1` wrapper |
| Oban | `Threadline.Job.bind_context/1` in worker `perform/1` | Correlation propagated via job args, not process state |
| Phoenix LiveView | Defer to v0.2+ — binds from socket assigns | Socket assigns hold actor after auth; context re-bound per event |
| PostgreSQL | Triggers via DDL migrations | Threadline manages trigger SQL; host app runs via `mix ecto.migrate` |

### Internal Module Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Capture ↔ Semantics | `audit_transactions.action_id` + `context_ref` JSONB | Explicit DB-level link; no Elixir module dependency |
| Semantics ↔ Integration | `Threadline.context/0` returns current `AuditContext` | Context held in process dictionary only for duration of request/job — not ETS |
| Query ↔ Capture/Semantics | SQL queries across `audit_changes`, `audit_transactions`, `audit_actions` | Query layer joins; never mutates |
| Operations ↔ All | Read-only access + scheduled mutations (retention, redaction) | Oban jobs for retention/redaction; health checks are pure read |

---

## Anti-Patterns

### Anti-Pattern 1: Process-Local Context via ETS or PID

**What people do:** Store current actor/context in ETS keyed by PID (ExAudit's approach).

**Why it's wrong:** Oban workers run in separate processes. `Task.async` spawns new processes. The context is silently absent without error — the worst kind of failure.

**Do this instead:** Hold context in the process dictionary only for the immediate request or job process. Serialize correlation_id into Oban job args explicitly. Provide `Threadline.Job.bind_context/1` to restore context from args.

---

### Anti-Pattern 2: Session/Connection Variables for Metadata (Logidze-style)

**What people do:** Pass metadata to triggers via `SET LOCAL threadline.actor = 'user_123'` PostgreSQL session variables.

**Why it's wrong:** With PgBouncer in transaction pooling mode, the connection is returned to the pool between statements. Session variables set in one statement may not be visible to the trigger in the next if pooling resets the connection state.

**Do this instead:** Insert the `audit_transactions` row at transaction start within the same DB transaction. Triggers read the transaction ID from their row context, not from session variables.

---

### Anti-Pattern 3: Monkeypatching Ecto.Repo

**What people do:** Override `Repo.insert/update/delete` to intercept writes (ExAudit's approach via `use ExAudit`).

**Why it's wrong:** Creates hidden magic that breaks with bulk operations (`Repo.insert_all`), direct SQL (`Repo.query`), and `Ecto.Multi` when `Repo.transaction` is called outside the patched functions. The correctness guarantee is still opt-in, just less visibly so.

**Do this instead:** Trigger-backed capture requires no repo interception. Semantic actions use `Threadline.Action.record/2` explicitly — explicit is better than magic.

---

### Anti-Pattern 4: Opaque Binary / YAML Change Storage

**What people do:** Serialize `data_after`/`data_before` as Erlang binary or YAML (ExAudit, Audited-historical).

**Why it's wrong:** Operators cannot run `SELECT * FROM audit_changes WHERE data_after->>'status' = 'suspended'`. Debugging requires the application stack. Version upgrades can break deserialization.

**Do this instead:** JSONB for all data payloads. Type discriminator fields (`op`, `table_name`, `actor_type`) as indexed text columns.

---

### Anti-Pattern 5: Record-Local History

**What people do:** Store audit history on the audited record (e.g., Logidze's `log_data` column on the source table).

**Why it's wrong:** Deleting the record deletes its history. Hot tables become bloated with audit data. History is inaccessible without knowing which table to query.

**Do this instead:** Central `audit_changes` table linked by `(table_name, table_pk)` reference. History survives deletes. Operators can query across all tables uniformly.

---

## Scaling Considerations

| Scale | Architecture Approach |
|-------|----------------------|
| Small apps (< 1M audit rows) | Default config — single `audit` schema, standard indexes |
| Medium apps (1M–100M rows) | Add `captured_at` range partitioning on `audit_changes`; configure `retention.keep_days` |
| Large apps (100M+ rows) | Partition + archival to cold storage; cursor-based export sinks; bounded timeline queries |

### First Bottleneck: Write Volume

Triggers add a row-per-mutation overhead. If a bulk import inserts 100k rows, 100k trigger firings occur. Mitigations:
- Allow per-table trigger bypass for known bulk paths (`Threadline.Capture.bypass/1`)
- Document trigger overhead in benchmarks
- Never use record-local storage that would bloat hot tables

### Second Bottleneck: Query Performance on Large History

Timeline queries over unbounded time ranges become slow. Mitigations:
- Default pagination (no unbounded queries in public API)
- Composite indexes on `(table_name, table_pk, captured_at DESC)`
- Partition `audit_changes` by `captured_at` for large installations

---

## Sources

- `prompts/audit-lib-domain-model-reference.md` — canonical domain model, entities, bounded contexts, API shapes (authoritative, project-internal)
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem analysis and architecture recommendations (authoritative, project-internal)
- `.planning/PROJECT.md` — constraints, decisions, and prior-art lessons

---

*Architecture research for: Threadline — Elixir audit platform*
*Researched: 2026-04-22*
