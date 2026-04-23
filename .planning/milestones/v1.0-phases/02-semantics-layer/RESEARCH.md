# Phase 2: Semantics Layer — Research

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Researcher:** Claude Sonnet 4.6 (headless research mode)

---

## 1. Current State — What Phase 1 Built

**Repo sync (2026-04-22):** `mix.exs` has no Carbonite dependency. Top-level scaffold modules under `lib/threadline/` are **absent** in the current tree — semantics work adds **new** `lib/threadline/semantics/` and boundary modules only. If stale artifacts reappear, remove them before defining `Threadline.Semantics.*` schemas for the same tables.

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

### PgBouncer Safety Analysis (CTX-03 — locked to `02-CONTEXT.md` D-09)

CTX-03 requires PostgreSQL-visible context propagation **without** the Elixir process dictionary. **Locked decision (D-09):** application code runs `SELECT set_config('threadline.actor_ref', <json text>, true)` inside the **same** `Ecto.Repo.transaction/1` as audited writes. The third argument **`true`** makes the GUC **transaction-local** — it is visible to triggers in that transaction and is discarded at `COMMIT`, so it is safe under PgBouncer **transaction** pooling (no cross-transaction leakage on a pooled connection).

Phase 2 extends `threadline_capture_changes()` so the `INSERT INTO audit_transactions (...)` supplies `actor_ref` from:

`NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb`

**Hard constraint (gate-01-01 / D-10):** the trigger function must **not** call `SET LOCAL` or otherwise mutate session state on the library-owned hot path — it only **reads** a GUC the host already set in-band.

If the host never sets the GUC, `actor_ref` on new `audit_transactions` rows is NULL (CTX-04). `record_action/2` still persists `audit_actions.actor_ref` independently.

**Anti-patterns:** `SET application_name` or session-scoped `set_config(..., false)` for actor propagation — unsafe or misleading under pooling.

### Reference: transaction-local GUC + `current_setting`

Same transaction semantics as `SET LOCAL` for visibility purposes; chosen pattern matches D-09 wording and keeps control in host code.

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

**Locked (D-09):** Host sets transaction-local GUC `threadline.actor_ref` via `set_config(..., true)` in the same DB transaction as audited writes. The extended `threadline_capture_changes()` reads it when inserting the `audit_transactions` row so `actor_ref` is populated trigger-side without Elixir process dictionary.

**Fallback:** If the GUC is unset, `actor_ref` stays NULL (CTX-04). Semantic actor still lives on `audit_actions` via `record_action/2`.

### D-OPEN-06: `Threadline.DataCase` cleanup for `audit_actions`

Phase 2 adds `audit_actions`. The `DataCase` setup must also clean this table. Since `audit_transactions.action_id` references `audit_actions.id`, the FK must be respected: delete `audit_changes`, then `audit_transactions`, then `audit_actions`.

### D-OPEN-07: Top-level scaffolding removal timing

If duplicate scaffold modules exist under `lib/threadline/` for capture tables, remove them before adding `Threadline.Semantics.*` — otherwise Ecto will see conflicting schema modules. Current repo snapshot has none; keep this as a guardrail task (no-op if absent).

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
- No process dictionary; no ETS; PostgreSQL visibility uses **transaction-local** `set_config` (D-09), not Elixir process state

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

Capture remains PgBouncer-safe via `txid_current()`. For `audit_transactions.actor_ref`, the trigger **reads** a transaction-local GUC set by host code (`set_config(..., true)`); the trigger does **not** issue `SET` / `SET LOCAL`. CTX-03 is satisfied without the Elixir process dictionary.

### Namespace

**CONFIDENCE: HIGH**

- `Threadline.Semantics.ActorRef` — struct + custom Ecto type
- `Threadline.Semantics.AuditAction` — Ecto schema
- `Threadline.Semantics.AuditContext` — plain struct
- `Threadline.Semantics.Migration` — DDL helper
- `Threadline.Plug` — boundary integration (top-level)
- `Threadline.Job` — boundary integration (top-level)

---

## Validation Architecture

Nyquist sampling for Phase 2 uses **ExUnit** against a real **PostgreSQL** database (existing `Threadline.DataCase` pattern — no Sandbox; tables cleaned in `setup`).

| Dimension | Strategy |
|-----------|----------|
| **Unit / type** | `mix compile --warnings-as-errors` after each semantic module lands. |
| **Persistence** | Repo integration tests: insert `AuditAction`, assert columns + constraints; `record_action/2` happy path and error tuples (SEM-05). |
| **Trigger + GUC** | Integration test in `DataCase`: inside `Repo.transaction`, run raw SQL `set_config('threadline.actor_ref', ...)` then mutate an audited fixture table; assert `audit_transactions.actor_ref` JSONB matches (CTX-03 + D-09). |
| **Regression** | `mix verify.test` (full suite) after each plan wave; `mix verify.credo` + `mix verify.format` before phase close. |

**Wave 0:** Not required — ExUnit and `Threadline.Test.Repo` already exist from Phase 1.

**Feedback commands:**

- Quick (after most commits): `mix test test/threadline/semantics/` (once paths exist) or targeted test file.
- Full: `mix verify.test`

**Dimension 8 (validation):** Every plan task that mutates Elixir or SQL must name an automated check (grep, compile, or test module) in its acceptance criteria — no "looks correct" language.

---

## 8. Risks and Pitfalls

### R-01: Dual module conflict on the same table (HIGH PRIORITY)

If duplicate scaffold modules for `audit_transactions` / `audit_changes` / `audit_actions` are introduced alongside `Threadline.Capture.*` or `Threadline.Semantics.*`, Ecto reflection conflicts. **Keep a single schema module per table.**

### R-02: `String.to_existing_atom/1` safety on name/reason fields

When reading `name` or `reason` from the database, converting string to atom with `String.to_existing_atom/1` only works if the atom was already defined in a compiled module. If a host application defines action names in a module that is not loaded at read time (e.g., lazy loading, hot code reload scenarios), this will raise `ArgumentError`. Mitigation: document clearly that action names must be atoms defined in compiled modules. Provide a `String.to_atom/1` fallback option (with the usual atom-table-exhaustion caveat) for admin/ops read paths.

### R-03: `actor_ref` NOT NULL on `audit_actions`

SEM-05 says invalid ActorRef returns an error tuple. The DB constraint (`actor_ref jsonb NOT NULL`) enforces this at the DB level too. But if `record_action/2` fails validation before inserting, the NOT NULL is never reached. The risk is if someone bypasses `record_action/2` and directly inserts into `audit_actions` without `actor_ref` — the DB constraint catches it correctly. No mitigation needed; this is correct behavior.

### R-04: PgBouncer and misuse of session state

Contributors might use session-scoped `set_config(..., false)` or `SET` without transaction locality, or add `SET LOCAL` inside the trigger body — all hazardous under pooling or forbidden by D-10. Tests and docs must lock the **host-set transaction-local GUC + trigger read** pattern only.

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

### R-10: Stale docs referencing Carbonite in `mix.exs`

Older research revisions mentioned Carbonite in dependencies. Current `mix.exs` does not list it — keep docs and RESEARCH aligned with the tree.

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
- D-08: Remove top-level scaffold files if present — guardrail before new semantics modules

One clarification from this research not covered in the context file: D-07 discusses `Threadline.Job.bind_context/2` which would need to store state somewhere. This research confirms the correct design is `Threadline.Job` as a pure helper (no storage), providing `actor_ref_from_args/1` and `context_opts/2` that extract from the args map. The context file already reached the same conclusion at the end of D-07.
