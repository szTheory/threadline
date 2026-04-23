# Phase 2: Semantics Layer - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Source:** AI self-discuss (headless mode)

## Phase Boundary

Phase 2 delivers:
- `ActorRef` — value object struct with six actor types, JSONB serialization, and validated construction
- `AuditAction` — semantic application-level event schema stored in `audit_actions` table
- `AuditContext` — execution context struct (actor, request_id, correlation_id, remote_ip)
- `Threadline.record_action/2` — persists an AuditAction; returns `{:ok, action}` or `{:error, changeset}`
- `Threadline.Plug` — extracts AuditContext from `Plug.Conn` and stores it in `conn.assigns[:audit_context]`
- `Threadline.Job` — provides explicit context binding for Oban workers
- Migration: `audit_actions` table + additive Phase 2 columns on `audit_transactions`

Phase 2 does NOT deliver: query API, health checks, telemetry events (Phase 3), README or Hex publish (Phase 4).

## Implementation Decisions

### D-01: Module Namespace — Semantics Layer Lives Under `Threadline.Semantics.*`

**Decision:** Phase 2 modules use the `Threadline.Semantics.*` namespace:
- `Threadline.Semantics.ActorRef` — value object + Ecto custom type
- `Threadline.Semantics.AuditAction` — Ecto schema for `audit_actions` table
- `Threadline.Semantics.AuditContext` — plain struct (not an Ecto schema)
- `Threadline.Plug` — stays at `Threadline.Plug` (it's a boundary integration, not a domain entity)
- `Threadline.Job` — stays at `Threadline.Job` (same rationale)

Existing `lib/threadline/audit_action.ex`, `lib/threadline/audit_transaction.ex`, and `lib/threadline/audit_change.ex` are early scaffolding from `c1e1508`. They have structural problems (flat actor fields, wrong column names, timestamps on tables that don't have them in the real schema). Phase 2 replaces `lib/threadline/audit_action.ex` with `lib/threadline/semantics/audit_action.ex`; the other two top-level scaffolding files are removed — `Threadline.Capture.AuditTransaction` and `Threadline.Capture.AuditChange` are the canonical implementations.

**Rationale:** CLAUDE.md defines three distinct layers. Phase 1 established `Threadline.Capture.*`. Consistent layering keeps responsibilities clear and avoids the exploration layer (Phase 3) bleeding into capture and semantics.

---

### D-02: ActorRef — Elixir Struct + Custom Ecto.ParameterizedType, Stored as JSONB

**Decision:** `ActorRef` is implemented as a plain Elixir struct with a companion `Ecto.ParameterizedType` module:

```elixir
defmodule Threadline.Semantics.ActorRef do
  @enforce_keys [:type]
  defstruct [:type, :id]

  # Six actor types per ACTR-02
  @types ~w(user admin service_account job system anonymous)a

  # Returns {:ok, %ActorRef{}} or {:error, reason_atom}
  def new(type, id \\ nil) do ... end

  # ACTR-04: map round-trip
  def to_map(%ActorRef{} = ref) do ... end
  def from_map(%{"type" => type, "id" => id}) do ... end
end
```

Storage: `actor_ref jsonb` column on both `audit_transactions` and `audit_actions`. The custom Ecto type handles casting: `%ActorRef{}` → `%{"type" => "user", "id" => "123"}` → JSONB. Reconstruction reverses this.

`anonymous` actors are valid with `id: nil`. All other types require a non-empty string `id`. Validation is in `ActorRef.new/2` (returns error tuple per ACTR-03 + SEM-05).

**Rationale:** ACTR-04 requires map serializability for JSONB storage. A custom type keeps Ecto schema definitions clean (one field, not two) and centralizes all ActorRef validation logic. JSONB storage makes actor_ref fields queryable with PostgreSQL's `@>` operator without extra indexes, which the query layer (Phase 3) will exploit. Flat columns (`actor_type`, `actor_id`) on the existing scaffolding schemas are replaced.

---

### D-03: AuditAction Schema — JSONB ActorRef, Flat Correlation Fields

**Decision:** `audit_actions` table schema:

```sql
id              uuid PRIMARY KEY DEFAULT gen_random_uuid()
name            text NOT NULL                    -- atom serialized as string, e.g. "member.role_changed"
actor_ref       jsonb NOT NULL                   -- ActorRef struct as JSONB
status          text NOT NULL CHECK (status IN ('ok', 'error'))
verb            text                             -- optional; e.g. "update", "delete"
category        text                             -- optional; e.g. "membership"
reason          text                             -- optional atom as string
comment         text                             -- optional human explanation
correlation_id  text                             -- optional; cross-boundary correlation
request_id      text                             -- optional; from Plug.RequestId / x-request-id
job_id          text                             -- optional; Oban job ID
inserted_at     timestamptz NOT NULL DEFAULT now()
```

`name` is stored as a `text` column (not atom JSONB) — atoms are serialized to string at persist time, deserialized back to atom on load via a custom Ecto.Type or `String.to_existing_atom/1`.

No `action_id` FK on `audit_transactions` in Phase 2 (see D-05). AuditAction links to transactions via `audit_transactions.action_id` (the other direction).

**Rationale:** SEM-01/SEM-02 enumerate the required fields. Keeping correlation fields (request_id, job_id, correlation_id) as flat text columns is simpler than nesting them in a JSONB context blob — they're flat IDs, not structured data. JSONB is reserved for ActorRef (structured value object). This schema is also identical to what the scaffolding `lib/threadline/audit_action.ex` intended, corrected to use `actor_ref jsonb` instead of flat `actor_type`/`actor_id`.

---

### D-04: `audit_transactions` Phase 2 Columns — Additive Migration

**Decision:** Phase 2 adds a second pre-committed migration: `priv/repo/migrations/20260102000000_threadline_semantics_schema.exs`.

This migration:
1. Creates `audit_actions` table (D-03 schema)
2. Adds `actor_ref jsonb` to `audit_transactions` (nullable — CTX-04: capture still works without context)
3. Adds `action_id uuid REFERENCES audit_actions(id) ON DELETE SET NULL` to `audit_transactions` (nullable)

`Threadline.Capture.AuditTransaction` Ecto schema gains `actor_ref` (ActorRef custom type) and `belongs_to(:action, Threadline.Semantics.AuditAction)` fields, but these are optional — existing Phase 1 integration tests continue passing with `nil` actor_ref.

The `Threadline.Capture.Migration` module gets a second function `up_v2/0` / `down_v2/0` for generating the Phase 2 migration in host apps. The install task generates BOTH migration files (or a single combined migration with `create_if_not_exists` for idempotency).

**Rationale:** Adding Phase 2 columns as a separate migration preserves Phase 1 migration stability — existing test databases that have run `20260101000000` only need to run the new migration, not re-run from scratch. This is the Oban versioned migration pattern. The library is pre-release so breaking changes are acceptable, but the separate migration approach is still better practice.

---

### D-05: AuditAction ↔ AuditTransaction Linking — `audit_transactions.action_id`

**Decision:** The link between semantics and capture goes through `audit_transactions.action_id` (nullable FK pointing to `audit_actions`). This answers "which action triggered these row changes?"

`record_action/2` does NOT automatically link to the current transaction. It returns `{:ok, %AuditAction{}}`. Callers that want to link changes to the action must either:
1. Call `record_action/2` inside an `Ecto.Multi` that also sets `action_id` on the relevant `audit_transactions` row, or
2. Use a higher-level helper (Phase 3+ concern)

SEM-03 says "can be linked to one or more AuditTransactions" — this is supported by having nullable `action_id` on `audit_transactions`. Multiple `audit_transactions` rows (from separate DB transactions within the same logical action) can all point to the same `audit_actions.id`.

**Rationale:** Automatic linking requires reading `txid_current()` at action-record time, which ties the action record to a specific open DB transaction. This is fragile for async scenarios and pre/post linking. Explicit linking via Multi keeps the API honest and composable. Phase 3's query layer handles the "find all changes for this action" case by joining on `action_id`.

---

### D-06: `Threadline.record_action/2` API Shape

**Decision:**

```elixir
Threadline.record_action(name, opts \\ [])
# name: atom — e.g. :member_role_changed
# opts:
#   actor: %ActorRef{} (required unless actor_ref given)
#   actor_ref: %ActorRef{} (alias for actor:)
#   status: :ok | :error (default: :ok)
#   verb: atom | string (optional)
#   category: atom | string (optional)
#   reason: atom (optional)
#   comment: string (optional)
#   correlation_id: string (optional)
#   request_id: string (optional)
#   job_id: string (optional)
#   repo: Ecto.Repo (required — no global config assumption)
```

Returns `{:ok, %AuditAction{}}` or `{:error, %Ecto.Changeset{}}` (SEM-05).

Validation path: `ActorRef.new/2` validates the actor before the changeset. Invalid ActorRef returns `{:error, :invalid_actor_ref}` (not a changeset error, since the ActorRef itself is the problem before schema insertion).

**Rationale:** Requiring explicit `repo:` avoids global application config coupling — the library does not call `Application.get_env/3` to find the repo. This is the pattern Oban and PaperTrail use for library-level DB access. Keeping `name` as a positional atom (serialized to string at persist time) gives good DX and avoids magic string typing at call sites.

---

### D-07: Context Propagation — Explicit Passing, No Process Dictionary

**Decision:**

`AuditContext` is a plain Elixir struct:
```elixir
defstruct [:actor_ref, :request_id, :correlation_id, :remote_ip]
```

`Threadline.Plug` implements `Plug.init/1` and `Plug.call/2`. It extracts context from `conn` and stores it as `conn.assigns[:audit_context]`. Application code accesses context via `conn.assigns[:audit_context]` and passes it explicitly to `record_action/2` (as `correlation_id:`, `request_id:`, `actor:` options extracted from the context struct).

`Threadline.Job` is NOT a plug or middleware — it is a helper module with a `bind_context/2` function:
```elixir
# Called at the start of an Oban worker's perform/1
Threadline.Job.bind_context(%{actor_ref: actor_ref, correlation_id: id})
```

Wait — but CTX-05 says "context is explicitly passed, not stored in ETS or process dictionary." If `bind_context` stores nothing, how does context flow? It must be explicit: the Oban worker accepts context in its args, extracts it, and passes it to `record_action` explicitly. `Threadline.Job` provides helpers to extract `ActorRef` from Oban job args and build partial `record_action` opts.

Revised `Threadline.Job` API:
```elixir
Threadline.Job.actor_ref_from_args(job.args)  # extracts ActorRef from job args map
Threadline.Job.context_opts(job)               # builds keyword opts for record_action
```

**Rationale:** CTX-05 prohibits ETS and process dictionary. The only compliant approach is explicit threading. `Threadline.Plug` makes context available in `conn.assigns` (idiomatic Phoenix pattern). Jobs receive context in args (standard Oban pattern for serializable job state). No magic, no hidden globals.

---

### D-08: Schema Cleanup — Remove Top-Level Scaffolding Files

**Decision:** Phase 2 removes three scaffolding files that are structurally incorrect:
- `lib/threadline/audit_transaction.ex` — conflicts with `Threadline.Capture.AuditTransaction`; has wrong columns (`actor_type`/`actor_id` flat, missing `txid`)
- `lib/threadline/audit_action.ex` — replaced by `lib/threadline/semantics/audit_action.ex`
- `lib/threadline/audit_change.ex` — conflicts with `Threadline.Capture.AuditChange`

The canonical schemas remain `Threadline.Capture.AuditTransaction` and `Threadline.Capture.AuditChange`. The semantics layer introduces `Threadline.Semantics.AuditAction`.

**Rationale:** Having two `AuditTransaction` modules pointing at the same table will cause Ecto reflection conflicts and confuse contributors. The scaffolding was useful to sketch the domain model but must be removed before integration tests would pass with both loaded.

---

## AI Discretion

Areas where requirements left room for judgment and choices were made:

- **ActorRef as custom Ecto type vs. embedded schema** — chose custom `Ecto.ParameterizedType` over `Ecto.embedded_schema`. Reason: embedded schemas carry more Ecto baggage (changesets, `embed_as`) for what is a simple value object. A custom type is lighter and composable across multiple schema fields (`audit_transactions.actor_ref` and `audit_actions.actor_ref` both use the same type).
- **`name` as atom serialized to string** — could have used a string throughout. Atom at the call site gives better DX and IDE autocomplete; string in the DB is required (atoms are not safe in untrusted JSONB). Serialization boundary is the changeset.
- **`record_action/2` requires explicit `repo:` opt** — could have looked up a configured repo. Explicit is better for library ergonomics and testability.
- **`Threadline.Job` as helpers, not middleware** — Oban workers are standalone processes; there's no plug pipeline. Helper functions that extract/build context opts are the minimally invasive design.
- **Phase 2 migration as a separate file** — could have modified the Phase 1 migration. Separate file is safer and more maintainable even pre-release.

## Existing Code Insights

### Reusable Assets

- `Threadline.Capture.AuditTransaction` (`lib/threadline/capture/audit_transaction.ex`) — will gain `actor_ref` and `belongs_to(:action, ...)` fields in Phase 2. The schema already has the right foundation.
- `Threadline.Capture.Migration` (`lib/threadline/capture/migration.ex`) — the pattern for generating DDL strings will be reused for the Phase 2 migration helper.
- Test infrastructure (`Threadline.Test.Repo`, `Threadline.DataCase`) — fully reusable for Phase 2 integration tests. No changes needed.

### Established Patterns

- **Custom type pattern**: none in codebase yet, but `Ecto.ParameterizedType` is well-established for JSONB value objects. Reference: Ecto docs, Oban's `Oban.Pro.Engines.SmartEngine` uses similar patterns.
- **Migration helper pattern**: `Threadline.Capture.Migration.up/0` returns a DDL string. Phase 2 adds `Threadline.Semantics.Migration.up/0` following the same pattern, called by the install task.
- **Phase 1 tests run against real PostgreSQL**: the same `DataCase` with `sandbox: false` for trigger tests applies. Phase 2 integration tests for `record_action/2` will use the same setup.

## Specific Ideas

- **ActorRef JSONB key naming**: use `"type"` and `"id"` (not `"actor_type"` and `"actor_id"`) in the JSONB representation. This is more compact and avoids the word "actor" in the serialized form, which is redundant given the field is named `actor_ref`.
- **`new/2` error returns**: `ActorRef.new(:anonymous)` → `{:ok, %ActorRef{type: :anonymous, id: nil}}`. `ActorRef.new(:user, nil)` → `{:error, :missing_actor_id}`. `ActorRef.new(:invalid_type)` → `{:error, :unknown_actor_type}`. Simple atom errors (not changesets) since ActorRef is not an Ecto schema.
- **Plug header extraction**: `x-request-id` → `request_id`, `x-correlation-id` → `correlation_id`, `remote_ip` from `conn.remote_ip` converted to string. If `x-request-id` absent, generate one with `Ecto.UUID.generate/0` (or leave nil — the host app's Plug.RequestId handles this).
- **`audit_actions` index**: add `CREATE INDEX audit_actions_actor_ref_idx ON audit_actions USING GIN (actor_ref)` for Phase 3's `actor_history/1` query.

## Deferred Ideas

- **`Threadline.record_action/3` with auto-linking to current transaction** — linking action to txid_current() at record time would be convenient but fragile. Deferred to Phase 3 as an optional Multi helper.
- **AuditContext stored in conn.private vs. conn.assigns** — `conn.assigns` is the convention for consumer-visible state; `conn.private` for library internals. Using `assigns` makes it easy for Phoenix controllers to access. If this causes namespace pollution in large apps, could move to `conn.private` in Phase 4.
- **Telemetry event on record_action** — HLTH-04 requires `[:threadline, :action, :recorded]` telemetry. Deferred to Phase 3 (telemetry is in HLTH requirements, not SEM).
- **`Threadline.with_context/2` wrapper** — a higher-level function that wraps a block with AuditContext injection into a Multi. Useful ergonomic but not in Phase 2 requirements; Phase 3+.
- **Atom safety for `name` field** — using `String.to_existing_atom/1` on read is safe only if the atom was already loaded (i.e., the module defining it is compiled). For library code, document that action names must be atoms defined in the host application's modules. Enforce this at Phase 4 documentation time.
