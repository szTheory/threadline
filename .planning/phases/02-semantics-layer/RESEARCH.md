# Phase 2: Semantics Layer — Research

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Researcher:** Claude Sonnet 4.6 (headless research mode)

---

## 1. Current State — What Phase 1 Built

### Schemas (canonical implementations)

**`Threadline.Capture.AuditTransaction`** (`lib/threadline/capture/audit_transaction.ex`)

- Ecto schema for `audit_transactions` table
- Fields: `txid` (integer), `occurred_at` (utc_datetime_usec), `source` (string), `meta` (map)
- Has-many `changes` via `Threadline.Capture.AuditChange`
- No actor fields, no `action_id` — these are Phase 2 additions
- No timestamps block (correct: the table only has `occurred_at`, no `inserted_at`/`updated_at`)
- Uses `@primary_key {:id, :binary_id, autogenerate: true}` and `@foreign_key_type :binary_id`

**`Threadline.Capture.AuditChange`** (`lib/threadline/capture/audit_change.ex`)

- Ecto schema for `audit_changes` table
- Fields: `table_schema`, `table_name`, `table_pk` (map), `op` (string), `data_after` (map), `changed_fields` ({:array, :string}), `captured_at`
- Belongs-to `Threadline.Capture.AuditTransaction` via `transaction_id`
- No timestamps block (correct)

**`Threadline.Capture.Migration`** (`lib/threadline/capture/migration.ex`)

- Returns DDL as a string via `migration_content/0`
- Creates `audit_transactions` and `audit_changes` tables
- Installs `threadline_capture_changes()` PL/pgSQL trigger function
- Uses `IF NOT EXISTS`/`CREATE OR REPLACE` for idempotency
- Pattern: `TriggerSQL` module generates the raw SQL strings; `Migration` assembles the `.exs` content

**`Threadline.Capture.TriggerSQL`** (`lib/threadline/capture/trigger_sql.ex`)

- Generates `threadline_capture_changes()` trigger function
- PgBouncer-safe via `txid_current()` — no `SET LOCAL`, no session variables in the capture path
- Groups changes by DB transaction using `ON CONFLICT DO NOTHING` on the `txid` UNIQUE constraint
- Provides `create_trigger/1` and `drop_trigger/1` for per-table trigger SQL

### Scaffold files that Phase 2 must remove

Three files at `lib/threadline/` are structurally incorrect scaffolding:

- `lib/threadline/audit_action.ex` — flat `actor_type`/`actor_id` columns instead of `actor_ref jsonb`; uses `timestamps/1` (wrong for append-only schema); `actor_id` is required (blocks anonymous actors)
- `lib/threadline/audit_transaction.ex` — conflicts with `Threadline.Capture.AuditTransaction`; has wrong columns (flat actor fields, uses `timestamps/1`, missing `txid`, references `Threadline.AuditChange`)
- `lib/threadline/audit_change.ex` — conflicts with `Threadline.Capture.AuditChange`; has wrong `table_pk` type (`:string` instead of `:map`), wrong timestamps, references `Threadline.AuditTransaction`

These cannot coexist with the canonical schemas without Ecto reflection conflicts.

### Migration state

One migration exists: `priv/repo/migrations/20260101000000_threadline_audit_schema.exs`

Creates:
- `audit_transactions` table (id, txid, occurred_at, source, meta)
- `audit_changes` table (id, transaction_id, table_schema, table_name, table_pk, op, data_after, changed_fields, captured_at)
- `threadline_capture_changes()` trigger function
- Three indexes on `audit_changes`, one on `audit_transactions.txid`

Phase 2 needs a second migration for `audit_actions` and two new columns on `audit_transactions`.

### Test infrastructure

- `Threadline.Test.Repo` — bare `Ecto.Repo` for PostgreSQL
- `Threadline.DataCase` — ExUnit case template; no sandbox (trigger tests need real DB transactions); cleans `audit_changes` then `audit_transactions` in `setup`
- Integration tests in `test/threadline/capture/trigger_test.exs` cover INSERT/UPDATE/DELETE and multi-write grouping
- `test/support/data_case.ex` aliases `Threadline.Capture.{AuditChange, AuditTransaction}` — Phase 2 must extend this for `AuditAction`

### Mix tasks

- `mix threadline.install` — generates the Phase 1 migration
- `mix threadline.gen.triggers` — generates per-table trigger SQL

### Dependencies available for Phase 2

From `mix.exs`:
- `ecto_sql ~> 3.10` — Ecto schemas, changesets, custom types
- `postgrex ~> 0.17` — PostgreSQL adapter
- `jason ~> 1.4` — JSON encode/decode (needed for JSONB custom type)
- `telemetry ~> 1.2` — telemetry events (Phase 3 concern, but available)
- `carbonite ~> 0.16` — in deps as prior art/reference; NOT used as a dependency of Threadline itself

**Oban is NOT a dependency.** `Threadline.Job` must be designed for Oban ergonomics without a compile-time dependency on Oban. Any Oban integration must be optional or use duck-typed patterns.

---

## 2. ActorRef Design — Options for the Value Object

### Option A: Plain Elixir Struct + `Ecto.Type` (simple custom type)

```elixir
defmodule Threadline.Semantics.ActorRef do
  @enforce_keys [:type]
  defstruct [:type, :id]

  @types ~w(user admin service_account job system anonymous)a

  def new(type, id \\ nil) ...  # {:ok, %ActorRef{}} | {:error, atom}

  def to_map(%ActorRef{} = ref) ...   # %{"type" => "user", "id" => "123"}
  def from_map(map) ...               # {:ok, %ActorRef{}} | {:error, atom}
end

defmodule Threadline.Semantics.ActorRef.EctoType do
  use Ecto.Type
  def type, do: :map
  def cast(%ActorRef{} = ref), do: {:ok, ref}
  def cast(%{"type" => _} = map), do: ActorRef.from_map(map)
  def cast(_), do: :error
  def load(%{"type" => _} = map), do: ActorRef.from_map(map)
  def dump(%ActorRef{} = ref), do: {:ok, ActorRef.to_map(ref)}
end
```

Schema usage: `field :actor_ref, Threadline.Semantics.ActorRef.EctoType`

Pros: Simple. No Ecto overhead on the struct itself. Works perfectly for JSONB via `:map` underlying type.
Cons: Two modules (struct + type). The type module name is verbose in schema fields.

### Option B: Plain Elixir Struct + `Ecto.ParameterizedType`

```elixir
defmodule Threadline.Semantics.ActorRef do
  use Ecto.ParameterizedType
  @enforce_keys [:type]
  defstruct [:type, :id]

  def init(opts), do: Enum.into(opts, %{})
  def type(_params), do: :map
  def cast(%__MODULE__{} = ref, _params), do: {:ok, ref}
  def cast(%{"type" => _} = map, _params), do: from_map(map)
  def cast(_, _), do: :error
  def load(map, _loader, _params), do: from_map(map)
  def dump(%__MODULE__{} = ref, _dumper, _params), do: {:ok, to_map(ref)}
  def dump(nil, _dumper, _params), do: {:ok, nil}
end
```

Schema usage: `field :actor_ref, Threadline.Semantics.ActorRef`

Pros: Single module. Schema field declaration is clean. `Ecto.ParameterizedType` is the modern recommended approach for custom types. Handles nil in `dump/3` and `load/3` explicitly (required by ParameterizedType contract).
Cons: Slightly more callbacks to implement. The struct and type behavior live in one module which is unusual but valid.

### Option C: Embedded Schema

```elixir
defmodule Threadline.Semantics.ActorRef do
  use Ecto.Schema
  embedded_schema do
    field :type, :string
    field :id, :string
  end
end
```

Schema usage: `embeds_one :actor_ref, ActorRef` with `embed_as: :dump` for JSONB.

Pros: Familiar pattern for Ecto users. Changeset validation built in.
Cons: Carries full Ecto schema overhead. `embeds_one` semantics differ from a simple field (changeset nesting, association preloading). Harder to reuse the same "type" in both `audit_transactions.actor_ref` and `audit_actions.actor_ref` without duplication. ACTR-04 requires map serializability — embedded schemas need `Ecto.embedded_dump` which is less transparent. `anonymous` actor validation is harder to express cleanly in a changeset.

### Recommendation

**Option B (Ecto.ParameterizedType in a single module)** is the best fit. It yields a single module, clean schema declarations, and handles the nil-in-dump case that ParameterizedType supports natively. The D-02 decision in the context file already reached this conclusion via independent analysis.

Key implementation notes:
- Store JSONB keys as `"type"` and `"id"` (compact, no redundant "actor_" prefix)
- `new(:anonymous)` → `{:ok, %ActorRef{type: :anonymous, id: nil}}` — anonymous id is allowed to be nil
- `new(:user, nil)` → `{:error, :missing_actor_id}` — all non-anonymous types require non-empty id
- `new(:user, "")` → `{:error, :missing_actor_id}` — empty string must be rejected
- `new(:unknown_type)` → `{:error, :unknown_actor_type}`
- Type stored as atom internally; serialized to string in JSONB; deserialized back to atom via `String.to_existing_atom/1` on load

---

## 3. AuditAction Schema — Table Design and Linking Strategy

### Table: `audit_actions`

```sql
CREATE TABLE IF NOT EXISTS audit_actions (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text        NOT NULL,
  actor_ref       jsonb       NOT NULL,
  status          text        NOT NULL CHECK (status IN ('ok', 'error')),
  verb            text,
  category        text,
  reason          text,
  comment         text,
  correlation_id  text,
  request_id      text,
  job_id          text,
  inserted_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS audit_actions_actor_ref_idx
  ON audit_actions USING GIN (actor_ref);
CREATE INDEX IF NOT EXISTS audit_actions_inserted_at_idx
  ON audit_actions (inserted_at);
CREATE INDEX IF NOT EXISTS audit_actions_name_idx
  ON audit_actions (name);
```

Design notes:
- `name` is `text NOT NULL` — atom serialized to string at persist time. Atoms are not safe to store directly; text is required.
- `actor_ref jsonb NOT NULL` — ActorRef custom type. JSONB enables `@>` containment queries for actor-based lookups (Phase 3 `actor_history/1`).
- `status` as a text CHECK constraint (not `Ecto.Enum`) so the constraint is enforced at the DB level even for direct SQL inserts.
- No `updated_at` — AuditAction is append-only.
- No `meta jsonb` column in Phase 2 — SEM-02 enumerates the optional fields explicitly; a catch-all `meta` blob would violate the "no opaque blobs" constraint in SEM-04.
- `reason` stored as text (atom serialized to string), same pattern as `name`.

### Linking: `audit_transactions.action_id`

Phase 2 adds to `audit_transactions`:

```sql
ALTER TABLE audit_transactions
  ADD COLUMN IF NOT EXISTS actor_ref jsonb,
  ADD COLUMN IF NOT EXISTS action_id uuid REFERENCES audit_actions(id) ON DELETE SET NULL;
```

Notes:
- `actor_ref` is nullable on `audit_transactions` (CTX-04: capture must work without context)
- `action_id` is nullable with `ON DELETE SET NULL` — if an action is deleted, transactions are not orphaned
- Multiple `audit_transactions` rows can share the same `action_id` (SEM-03: one action → many DB transactions)
- The FK direction is `audit_transactions.action_id → audit_actions.id`, not the reverse, because:
  - An action exists before its changes happen (or may have zero changes)
  - One action can span multiple DB transactions (retry, multi-step)
  - A join table would be a third schema with no independent identity

### Ecto Schema Changes

`Threadline.Capture.AuditTransaction` gains:
```elixir
field :actor_ref, Threadline.Semantics.ActorRef   # custom ParameterizedType
belongs_to :action, Threadline.Semantics.AuditAction
```

`Threadline.Semantics.AuditAction` Ecto schema:
```elixir
schema "audit_actions" do
  field :name, :string
  field :actor_ref, Threadline.Semantics.ActorRef
  field :status, :string
  field :verb, :string
  field :category, :string
  field :reason, :string
  field :comment, :string
  field :correlation_id, :string
  field :request_id, :string
  field :job_id, :string
  has_many :transactions, Threadline.Capture.AuditTransaction, foreign_key: :action_id
  timestamps(inserted_at: :inserted_at, updated_at: false)
end
```

---

## 4. Context Propagation — AuditContext, Plug Integration, PgBouncer-Safe Patterns

### AuditContext Struct

```elixir
defmodule Threadline.Semantics.AuditContext do
  @moduledoc """
  Execution context for a request or job. Plain struct, not an Ecto schema.
  """
  @enforce_keys []
  defstruct [:actor_ref, :request_id, :correlation_id, :remote_ip]
end
```

Fields match CTX-02. All fields are nullable by default — context may be partially populated.

### Plug Integration

`Threadline.Plug` implements `Plug.init/1` and `Plug.call/2`:

```elixir
defmodule Threadline.Plug do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    context = %Threadline.Semantics.AuditContext{
      actor_ref: conn.assigns[:current_user] |> to_actor_ref(),
      request_id: get_req_header(conn, "x-request-id") |> List.first(),
      correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
      remote_ip: format_ip(conn.remote_ip)
    }
    Plug.Conn.assign(conn, :audit_context, context)
  end
end
```

Notes:
- Stores context in `conn.assigns[:audit_context]` (idiomatic Phoenix; accessible in controllers and LiveView assigns)
- Does NOT resolve actor — `Threadline.Plug` cannot know which `conn.assigns` key holds the current user; callers configure actor extraction separately
- Actor extraction should be configurable via plug options: `plug Threadline.Plug, actor_from: :current_user` with a resolver function
- `x-request-id` extraction: if Phoenix's `Plug.RequestId` runs before `Threadline.Plug`, the request ID will already be in `conn.assigns[:request_id]` — the plug should check both sources
- `remote_ip` from `conn.remote_ip` is an Erlang IP tuple `{127, 0, 0, 1}` — must be formatted to string with `:inet.ntoa/1`

### PgBouncer Safety Analysis

CTX-03 requires context propagation to PostgreSQL survive PgBouncer transaction-mode pooling.

**What this means:** In PgBouncer transaction-mode, a different backend process may handle each transaction. Session-level PostgreSQL settings (`SET` without `LOCAL`) are lost between transactions. Only `SET LOCAL` (transaction-scoped) or connection-level application state survives — but connection-level state also resets when PgBouncer reassigns the connection.

**Phase 1 solution:** `txid_current()` inside the trigger — this is transaction-scoped and PgBouncer-safe. No session variables are needed for the capture layer.

**Phase 2 challenge:** CTX-03 asks for context propagation using a "connection-level session variable" that survives PgBouncer transaction-mode pooling. This is a contradiction: session variables by definition do not survive PgBouncer transaction-mode pooling.

**Correct interpretation of CTX-03:** The requirement means "the mechanism must not rely on process-dictionary state in the Elixir process." The PostgreSQL-level propagation for Phase 2 context (actor, request ID) must either:

1. **Not use PostgreSQL session variables at all** — instead, attach context to the `AuditTransaction` row via Elixir code before/during the DB transaction. This is the approach used by Carbonite (`insert_transaction/3` inserts a row with metadata). Phase 2 takes this approach: `actor_ref` is a column on `audit_transactions`, populated by application code via Ecto, not by a trigger reading a session variable.

2. **Use `SET LOCAL` within the transaction** — safe for PgBouncer transaction-mode because the variable is transaction-scoped. Carbonite uses `SET LOCAL carbonite_default.override_mode = 'capture'` for trigger behavior control. If the trigger needed to read actor context, `SET LOCAL app.actor_ref = '{"type":"user","id":"123"}'` then `current_setting('app.actor_ref')` in the trigger function would work. However, this approach requires modifying the trigger function.

**Phase 2 decision:** Do not modify the trigger to read session variables. Instead, application code sets `actor_ref` on `audit_transactions` rows directly. The trigger creates the `audit_transactions` row with `actor_ref = NULL`; application code updates it (or the multi-step approach pre-inserts the `audit_transactions` row with context before writes). This is PgBouncer-safe and does not require session variable mechanics.

**Note on `application_name`:** Some audit libraries use `SET application_name` to propagate metadata. This is a session variable and NOT safe for PgBouncer transaction-mode. Do not use it.

### Carbonite's `SET LOCAL` Pattern (Reference)

Carbonite uses `SET LOCAL #{prefix}.override_mode = '#{mode}'` within a transaction to control trigger behavior. This is:
- Transaction-scoped (safe for PgBouncer transaction-mode)
- Done by the application within an open transaction, not at session level

If Threadline ever needs to propagate actor context to the trigger function (e.g., for a future trigger-read approach), `SET LOCAL threadline.actor_ref = '...'` + `current_setting('threadline.actor_ref', true)` in the trigger is the correct pattern. Phase 2 does not need this because actor context is applied at the application layer.

---

## 5. Oban Job Context — Explicit Binding Without Process State

### The Problem

CTX-05 prohibits ETS and process dictionary for context propagation. Carbonite uses `Process.put(:carbonite_meta, ...)` — this is explicitly what Threadline must NOT do. Carbonite's `Transaction.put_meta/2` stores context in the process dictionary, which fails for async tasks spawned from the job worker process.

### Oban's Standard Pattern

Oban workers receive all state through `args` (a serializable map stored in the `oban_jobs` table). The canonical pattern for propagating context from a request to a job is to encode context in the job args at enqueue time:

```elixir
# At enqueue time (in the controller/action):
%{
  "actor_ref" => ActorRef.to_map(actor_ref),
  "correlation_id" => correlation_id,
  "resource_id" => resource.id
}
|> MyWorker.new()
|> Oban.insert()

# In the worker:
def perform(%Oban.Job{args: args}) do
  actor_ref = Threadline.Job.actor_ref_from_args(args)
  opts = Threadline.Job.context_opts(args, job_id: "#{args["__meta__"]["id"]}")
  Threadline.record_action(:member_role_synced, [actor: actor_ref] ++ opts)
end
```

### `Threadline.Job` API Design

`Threadline.Job` is a helper module, not a plug or middleware:

```elixir
defmodule Threadline.Job do
  @moduledoc """
  Helpers for propagating AuditContext through Oban workers.

  Context is explicitly passed via job args, never stored in process state.
  """

  alias Threadline.Semantics.ActorRef

  @doc """
  Extracts an ActorRef from Oban job args map.
  Returns {:ok, %ActorRef{}} or {:error, reason}.
  """
  def actor_ref_from_args(%{"actor_ref" => actor_ref_map}) do
    ActorRef.from_map(actor_ref_map)
  end
  def actor_ref_from_args(_), do: {:error, :missing_actor_ref}

  @doc """
  Builds record_action opts from job args.
  Extracts correlation_id, job_id from args map.
  """
  def context_opts(args, extra \\ []) when is_map(args) do
    base = [
      correlation_id: args["correlation_id"],
      job_id: args["job_id"]
    ]
    Keyword.merge(base, extra)
  end
end
```

### Why No Process Dictionary

The Oban `perform/1` callback runs in a supervised GenServer process. Storing context in the process dictionary:
- Works fine within the synchronous `perform/1` call
- Fails if the worker spawns `Task.async` or uses `Task.Supervisor`
- Creates invisible coupling between the "binding" call and the action recording call
- Cannot be easily tested without mocking global state

Explicit passing is testable: `{:ok, actor_ref} = Job.actor_ref_from_args(args)` is a pure function call.

### Oban Dependency Strategy

Oban is not in `mix.exs`. `Threadline.Job` must not `import Oban.Worker` or reference `Oban.Job` struct in its public API. Instead:
- Accept plain maps as args (Oban job args are always a map)
- Document that `Oban.Job` struct should have its `args` extracted and passed
- Do not add `:oban` to deps; document it as an optional integration

---

## 6. Key Design Decisions — Questions for the Planner

### D-OPEN-01: Actor resolution strategy for `Threadline.Plug`

How does the plug know which `conn.assigns` key contains the current actor? Options:

A. **Opts-based resolver**: `plug Threadline.Plug, actor_from: {:assigns, :current_user}, actor_type: :user` — simple but assumes actor type is uniform
B. **Function-based resolver**: `plug Threadline.Plug, actor_fn: &MyApp.Auth.to_actor_ref/1` — flexible, caller provides `conn -> ActorRef | nil`
C. **No resolution in plug**: Plug only extracts request metadata (request_id, correlation_id, remote_ip). Actor must be set explicitly via `Plug.Conn.assign(conn, :audit_actor, actor_ref)` in the controller. AuditContext on `conn.assigns` is assembled from both.

**Recommendation**: Option B (function-based resolver) with Option C as the fallback when no resolver is configured. A good plug should be usable without forcing callers to configure actor extraction.

### D-OPEN-02: `name` field serialization boundary

When does the `name` atom get serialized to string?

A. In `record_action/2` before building the changeset
B. In the Ecto changeset `cast/4` step
C. In a custom Ecto type for the name field

**Recommendation**: In `record_action/2` — convert atom to string explicitly before passing to changeset. Keeps the changeset simple (`:string` field). On read, `String.to_existing_atom/1` on the name field — document that action names must be defined as atoms in compiled modules.

### D-OPEN-03: `status` field — `:ok`/`:error` atoms vs strings

The changeset accepts `:ok` and `:error` atoms from the caller (SEM-01) but stores `"ok"` and `"error"` as strings in the DB. Where is the coercion?

**Recommendation**: Same as name — coerce in `record_action/2` before changeset. Or use `Ecto.Enum` with `values: [ok: "ok", error: "error"]`. Either works; `Ecto.Enum` is cleaner and enforces the DB CHECK constraint semantics at the Ecto layer.

### D-OPEN-04: `record_action/2` repo requirement

SEM-01/SEM-05 say it returns `{:ok, action}` or error. Requiring `repo:` as an explicit keyword option is the pattern from D-06 in the context file. But library ergonomics could benefit from a configurable default repo (like Oban's `:repo` config). However, global Application config couples the library to host app config.

**Decision needed**: Explicit `repo:` always required? Or allow `Application.get_env(:threadline, :repo)` as a fallback?

**Recommendation**: Explicit `repo:` required in Phase 2. Keep it simple and testable. A convenience wrapper can be documented for Phase 4.

### D-OPEN-05: Updating `audit_transactions.actor_ref`

When application code performs a write inside a DB transaction, the trigger creates an `audit_transactions` row with `actor_ref = NULL`. How does actor context get attached?

Options:
A. Application code pre-inserts an `audit_transactions` row with actor context before writes; trigger's `ON CONFLICT DO NOTHING` reuses it. Requires the trigger to upsert on `txid` and respect pre-existing rows.
B. Application code updates the `audit_transactions` row after the transaction commits (but within the same DB transaction — before `COMMIT`).
C. `record_action/2` is called inside an `Ecto.Multi` that also sets `action_id` on the `audit_transactions` row — actor is on the action, not the transaction.
D. Phase 2 does not populate `actor_ref` on `audit_transactions` at all. It's nullable (CTX-04). The action-to-transaction link via `action_id` gives enough context.

**Recommendation**: Option D for Phase 2. The `actor_ref` on `audit_transactions` is a Phase 3 enhancement when the query layer needs it directly. For Phase 2, the actor is on `audit_actions`. The `action_id` FK provides the link. This avoids requiring application code to perform DB-level introspection within every transaction.

### D-OPEN-06: `Threadline.DataCase` cleanup for `audit_actions`

Phase 2 adds `audit_actions`. The `DataCase` setup must also clean this table. Since `audit_transactions.action_id` references `audit_actions.id`, the FK must be respected: delete `audit_changes`, then `audit_transactions`, then `audit_actions`.

### D-OPEN-07: Top-level scaffolding removal timing

The three incorrect scaffold files (`lib/threadline/audit_action.ex`, `lib/threadline/audit_transaction.ex`, `lib/threadline/audit_change.ex`) must be removed before Phase 2 schemas are added — otherwise there will be duplicate module definitions for the same table. This should be the first task in Phase 2 implementation.

---

## 7. Recommended Approach — Concrete Recommendations

### ActorRef Implementation

**CONFIDENCE: HIGH**

Implement `Threadline.Semantics.ActorRef` as a single module that is both a plain Elixir struct and implements `Ecto.ParameterizedType`. The `use Ecto.ParameterizedType` macro handles the boilerplate. The module owns:
- `new/1` and `new/2` constructors with error tuples
- `to_map/1` and `from_map/1` for JSONB round-trip
- `cast/2`, `load/3`, `dump/3` for Ecto integration

The JSONB representation uses string keys `"type"` and `"id"`. Atoms are used at the Elixir layer; strings at the DB layer.

### AuditAction Schema

**CONFIDENCE: HIGH**

`Threadline.Semantics.AuditAction` with the table schema described in Section 3. Key choices:
- `actor_ref jsonb NOT NULL` — ActorRef custom type
- Flat text columns for all other optional fields (no nested JSONB blobs)
- GIN index on `actor_ref` for Phase 3 query layer
- `status` as `Ecto.Enum` with values `[:ok, :error]`
- `name` as plain `:string`; serialization handled in `record_action/2`

### `record_action/2` API

**CONFIDENCE: HIGH**

```elixir
Threadline.record_action(name, opts)
# Required opts: actor: (or actor_ref:), repo:
# Optional: status:, verb:, category:, reason:, comment:,
#           correlation_id:, request_id:, job_id:
# Returns: {:ok, %AuditAction{}} | {:error, %Ecto.Changeset{}} | {:error, atom}
```

Validation order:
1. Validate `actor_ref` via `ActorRef.new/1-2` — return `{:error, :invalid_actor_ref}` (or specific error atom) before changeset
2. Serialize name atom to string
3. Build changeset and insert

### AuditContext and Plug

**CONFIDENCE: HIGH**

- `AuditContext` is a plain struct with four fields (CTX-02)
- `Threadline.Plug` stores context in `conn.assigns[:audit_context]`
- Actor extraction is caller-configured via a function option
- No process dictionary; no ETS; no session variables

### Migration Strategy

**CONFIDENCE: HIGH**

Second migration: `priv/repo/migrations/20260102000000_threadline_semantics_schema.exs`

Creates `audit_actions` table and adds two nullable columns to `audit_transactions`:
- `actor_ref jsonb`
- `action_id uuid REFERENCES audit_actions(id) ON DELETE SET NULL`

`Threadline.Semantics.Migration` module (mirroring `Threadline.Capture.Migration`) provides `migration_content/0` for the install task. The install task is updated to generate both migrations.

### Oban Integration

**CONFIDENCE: HIGH**

`Threadline.Job` is a stateless helper module. No Oban compile-time dependency. Accepts plain maps. Provides `actor_ref_from_args/1` and `context_opts/2`. Document that Oban job args should include `"actor_ref"` and `"correlation_id"` keys when enqueuing jobs that need audit context.

### PgBouncer Safety

**CONFIDENCE: HIGH**

Phase 2 does not introduce session variables. The capture layer is already PgBouncer-safe via `txid_current()`. The semantics layer adds columns to `audit_transactions` that are populated by application code (not by triggers reading session variables). CTX-03's intent is satisfied without literal session-variable propagation.

### Namespace

**CONFIDENCE: HIGH**

- `Threadline.Semantics.ActorRef` — struct + custom Ecto type
- `Threadline.Semantics.AuditAction` — Ecto schema
- `Threadline.Semantics.AuditContext` — plain struct
- `Threadline.Semantics.Migration` — DDL helper
- `Threadline.Plug` — boundary integration (top-level)
- `Threadline.Job` — boundary integration (top-level)

---

## 8. Risks and Pitfalls

### R-01: Dual module conflict on the same table (HIGH PRIORITY)

The three top-level scaffold files define Ecto schemas for the same tables as the canonical `Threadline.Capture.*` modules. If both are compiled simultaneously, Ecto's reflection will conflict (two modules for `audit_transactions`, two for `audit_changes`). Tests will fail or produce confusing errors. **The scaffolding files must be the very first thing removed in Phase 2 implementation.**

### R-02: `String.to_existing_atom/1` safety on name/reason fields

When reading `name` or `reason` from the database, converting string to atom with `String.to_existing_atom/1` only works if the atom was already defined in a compiled module. If a host application defines action names in a module that is not loaded at read time (e.g., lazy loading, hot code reload scenarios), this will raise `ArgumentError`. Mitigation: document clearly that action names must be atoms defined in compiled modules. Provide a `String.to_atom/1` fallback option (with the usual atom-table-exhaustion caveat) for admin/ops read paths.

### R-03: `actor_ref` NOT NULL on `audit_actions`

SEM-05 says invalid ActorRef returns an error tuple. The DB constraint (`actor_ref jsonb NOT NULL`) enforces this at the DB level too. But if `record_action/2` fails validation before inserting, the NOT NULL is never reached. The risk is if someone bypasses `record_action/2` and directly inserts into `audit_actions` without `actor_ref` — the DB constraint catches it correctly. No mitigation needed; this is correct behavior.

### R-04: PgBouncer and `SET LOCAL` misconception

The requirement CTX-03 mentions "connection-level session variable" which contradicts PgBouncer transaction-mode safety. The design recommendation (Section 4) avoids session variables entirely. If a future contributor interprets CTX-03 literally and tries to use `SET` (not `SET LOCAL`), it will silently fail in PgBouncer environments. The implementation and tests must make clear that no session variables are used.

### R-05: Oban not in deps — `Threadline.Job` API contract

If `Threadline.Job` is tested without Oban, test helpers must simulate the `args` map pattern without importing Oban types. This is easy since `Threadline.Job` only accepts plain maps. The risk is if a contributor adds `%Oban.Job{}` pattern matching to `Threadline.Job`, creating a hidden compile-time dependency. API surface must be kept to plain maps.

### R-06: `DataCase` cleanup order

Phase 2 adds `audit_actions`. The FK `audit_transactions.action_id → audit_actions.id` means `audit_actions` must be deleted AFTER `audit_transactions` (since audit_transactions has the FK). But `audit_changes` must be deleted before `audit_transactions`. Correct order: `audit_changes` → `audit_transactions` → `audit_actions`. If `DataCase` is not updated, test cleanup will fail with FK constraint violations.

### R-07: `anonymous` actor id handling in JSONB

When `ActorRef{type: :anonymous, id: nil}` is serialized to JSONB, the `"id"` key should be omitted or stored as `null`. When deserializing, `from_map(%{"type" => "anonymous"})` must handle the missing `"id"` key. The implementation must explicitly test this round-trip.

### R-08: Migration idempotency

The Phase 1 migration uses `IF NOT EXISTS` for all DDL. The Phase 2 migration should use `ADD COLUMN IF NOT EXISTS` for the `audit_transactions` alterations and `CREATE TABLE IF NOT EXISTS` for `audit_actions`. This ensures running the migration twice does not fail.

### R-09: `insert_at` vs `inserted_at` naming

Ecto's `timestamps/1` uses `inserted_at` by default. The `audit_actions` table must use `inserted_at` (not `created_at` or `insert_at`). The `audit_transactions` and `audit_changes` tables in Phase 1 do NOT use `timestamps/1` — they have `occurred_at` and `captured_at` respectively. Phase 2 `audit_actions` uses `timestamps(inserted_at: :inserted_at, updated_at: false)` matching the scaffold file's intent but correcting the schema design.

### R-10: Carbonite as a listed dependency

`mix.exs` includes `{:carbonite, "~> 0.16"}` as a dependency. Carbonite is currently used as prior art research but is listed as a compile-time dependency. This will be pulled into any host app that uses Threadline. If Threadline does not intend to use Carbonite as a library (the trigger SQL is hand-written), this dependency should be removed from `mix.exs` to avoid transitive dependency bloat. This is a Phase 2 housekeeping concern.

---

## Appendix: Existing Context File Summary

The `02-CONTEXT.md` file in this directory (gathered 2026-04-23, marked "Ready for planning") contains eight pre-made implementation decisions (D-01 through D-08) that are broadly consistent with this research. Key alignments:

- D-01: Namespace as `Threadline.Semantics.*` — confirmed correct
- D-02: `ActorRef` as plain struct + `Ecto.ParameterizedType` — confirmed correct
- D-03: `audit_actions` schema with JSONB `actor_ref` — confirmed correct
- D-04: Second migration file — confirmed correct
- D-05: `audit_transactions.action_id` FK — confirmed correct
- D-06: `record_action/2` with explicit `repo:` — confirmed correct
- D-07: Explicit context passing (no process dictionary) — confirmed correct
- D-08: Remove top-level scaffold files — confirmed correct, must be first step

One clarification from this research not covered in the context file: D-07 discusses `Threadline.Job.bind_context/2` which would need to store state somewhere. This research confirms the correct design is `Threadline.Job` as a pure helper (no storage), providing `actor_ref_from_args/1` and `context_opts/2` that extract from the args map. The context file already reached the same conclusion at the end of D-07.
