# Phase 2: Semantics Layer - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 delivers application-level audit semantics wired to the existing capture substrate:

- **`ActorRef`** — value object with the six actor types from ACTR-02, JSON-serializable per ACTR-04, validated construction per ACTR-03 / SEM-05, stored as JSONB where schemas require it.
- **`Threadline.Semantics.AuditAction`** — Ecto schema and `audit_actions` table per SEM-01–SEM-04 (typed columns + JSONB only).
- **`Threadline.record_action/2`** — persists an `AuditAction`; returns `{:ok, action}` or `{:error, _}`; invalid actor input returns a tagged error tuple, not a raised exception (SEM-05).
- **`Threadline.Plug`** and **`Threadline.Job`** — CTX-01 / CTX-05 integration surfaces: request-scoped `AuditContext` on `Plug.Conn`, and explicit Oban/job-side context binding without ETS or process dictionary.
- **Schema evolution** — additive migration(s) from Phase 1: `audit_actions` table; nullable `actor_ref` and `action_id` on `audit_transactions` for SEM-03 / CTX-04.
- **Trigger alignment for CTX-03** — extend capture DDL so `audit_transactions.actor_ref` can be filled from a **transaction-local PostgreSQL GUC** set by application code in the same DB transaction as audited writes (details under decisions). Trigger body continues to avoid `SET LOCAL` / metadata hacks on the hot path incompatible with PgBouncer (see `gate-01-01.md`).

Out of scope for Phase 2: query APIs, health checks, telemetry events (Phase 3), README / Hex / broad docs (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Module layout (semantics vs capture)

- **D-01:** Semantics types and schemas live under `Threadline.Semantics.*` (`ActorRef`, `AuditAction`, and any small helpers co-located there). **`Threadline.Plug`** and **`Threadline.Job`** remain **top-level** modules (integration boundaries, not domain entities), matching the three-layer split in `CLAUDE.md`.
- **D-08:** Remove legacy top-level scaffold modules under `lib/threadline/` that duplicate or conflict with `Threadline.Capture.*` (`audit_action.ex`, `audit_transaction.ex`, `audit_change.ex` as applicable). Canonical row-capture schemas stay **`Threadline.Capture.AuditTransaction`** and **`Threadline.Capture.AuditChange`**.

### `ActorRef` shape and storage

- **D-02:** Implement `ActorRef` as a plain struct plus a single **`Ecto.ParameterizedType`** (or equivalent custom type) used on both `audit_actions.actor_ref` and `audit_transactions.actor_ref`. JSONB map uses keys **`"type"`** and **`"id"`** (compact, stable). Elixir-facing `type` is one of `~w(user admin service_account job system anonymous)a`. **`anonymous`** allows `id: nil`; all other types require a non-empty string `id`. Validation errors are **`{:error, reason_atom}`** before any changeset.
- **D-02b (indexing):** Add a **GIN** index on `audit_actions.actor_ref` JSONB to support Phase 3 `actor_history/1` style queries (`@>` / containment). Defer only if migration size is a concern; default is **yes, add the index** in Phase 2.

### `AuditAction` table and schema

- **D-03:** `audit_actions` columns (conceptual): `id` (uuid), `name` (text, required), `actor_ref` (jsonb, required), `status` (text or enum-like string with constraint `ok` / `error`), optional `verb`, `category`, `reason`, `comment`, `correlation_id`, `request_id`, `job_id`, `inserted_at`. **Correlation fields stay flat text columns**, not nested JSON blobs. **`name`** is stored as **text** at rest; call sites may pass atom or string — **`record_action/2` normalizes to string** before cast/insert. **Do not** `String.to_existing_atom/1` on values read from the database for untrusted rows; strings from DB stay strings unless the host app adds an explicit registry later (documented deferral).

### Migrations and Phase 1 compatibility

- **D-04:** Ship Phase 2 as an **additive** migration (separate file from Phase 1’s install migration): create `audit_actions`; add nullable `actor_ref` (jsonb) and nullable `action_id` (uuid FK → `audit_actions.id`, `ON DELETE SET NULL`) to `audit_transactions`. **`Threadline.Capture.Migration` (or companion semantics migration module)** grows **`up_v2/0` / `down_v2/0`** (or equivalent) so host apps can generate/apply Phase 2 DDL without rewriting Phase 1 history. Install task should generate **both** Phase 1 and Phase 2 artifacts (exact file split is planner discretion) while keeping **idempotent** re-runs safe (PKG-04 spirit).

### Linking actions to capture rows

- **D-05:** **Primary link direction:** `audit_transactions.action_id` → `audit_actions.id` (nullable). Multiple transaction rows may share one action when a logical operation spans DB transactions. **`record_action/2` does not auto-magic-link** to the open transaction; callers that need linkage use **`Ecto.Multi`** or a later Phase 3 helper. This preserves explicit composition and async-safe semantics (per SEM-03 wording).

### `Threadline.record_action/2` API

- **D-06:** Public shape: `Threadline.record_action(name, opts \\ [])` with **`repo:` required** in `opts` (no implicit `Application.get_env` repo lookup). Options include `actor` / `actor_ref` (validated `ActorRef`), `status` (`:ok` | `:error`, default `:ok`), optional `verb`, `category`, `reason`, `comment`, `correlation_id`, `request_id`, `job_id`. Returns **`{:ok, %Threadline.Semantics.AuditAction{}}`** or **`{:error, %Ecto.Changeset{}}`**. **Invalid `ActorRef` before schema** → **`{:error, :invalid_actor_ref}`** (or a small closed set of tagged errors), not a changeset, matching SEM-05 intent.

### Request and job context (CTX-01, CTX-02, CTX-05)

- **D-07:** **`AuditContext`** is a plain struct: `actor_ref`, `request_id`, `correlation_id`, `remote_ip` (CTX-02). **`Threadline.Plug`** implements Plug behaviour, parses headers / conn fields (`x-request-id`, `x-correlation-id`, `remote_ip`, plus host-supplied actor resolver hook if present — **resolver callback shape is planner discretion**), and assigns **`conn.assigns[:audit_context]`**.
- **D-07b:** **`Threadline.Job`** exposes **small pure helpers** to derive `record_action/2` opts and/or `ActorRef` from **`Oban.Job` args** — no hidden global state, no ETS, no process dictionary (CTX-05).

### CTX-03 — PostgreSQL bridge without breaking the capture gate

- **D-09:** Satisfy **CTX-03** by documenting and implementing a **host-controlled** pattern: application code calls **`SELECT set_config('threadline.actor_ref', <json text>, true)`** (third argument **`true`** = transaction-local) **inside the same `Ecto.Repo.transaction/1`** as audited writes when they want trigger-populated `audit_transactions.actor_ref`. **Phase 2 extends `threadline_capture_changes()`** so the `INSERT INTO audit_transactions (...)` includes **`actor_ref`** sourced from **`NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb`** (exact SQL is planner-owned; must treat “unset” as NULL per CTX-04). **The trigger function must not call `SET LOCAL` itself** — it only **reads** a GUC the application set in-band, avoiding the Carbonite-style “metadata via SET inside library-owned hot path” failure mode called out in `gate-01-01.md`.
- **D-09b:** If the host never sets the GUC, **`actor_ref` on `audit_transactions` stays NULL** and capture still works (CTX-04). **`record_action/2`** still records **`audit_actions.actor_ref`** independently.

### Trigger / DDL ownership

- **D-10:** **`Threadline.Capture.TriggerSQL.install_function/0`** (or a clearly named successor) remains the **single source** for the PL/pgSQL function body; Phase 2 edits that generator so regenerated installs pick up `actor_ref` behaviour. Per-table trigger shells stay thin `EXECUTE FUNCTION` wrappers.

### Claude's Discretion

Exact names for small helper modules (e.g. context → repo wrapper), Credo/module ordering, changeset error message text, and precise SQL for `current_setting` / `set_config` edge cases (empty string vs null) — **planner/executor decide** within the constraints above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product and requirements

- `.planning/ROADMAP.md` — Phase 2 goal, success criteria, dependencies.
- `.planning/REQUIREMENTS.md` — ACTR-*, SEM-*, CTX-* IDs (especially **CTX-03** session GUC vs **CTX-05** no process dictionary).
- `.planning/PROJECT.md` — vision, constraints, Path B capture decision references.

### Prior phase decisions

- `.planning/phases/01-capture-foundation/gate-01-01.md` — **Path B**; PgBouncer / no `SET LOCAL` in the **library-owned capture hot path** rationale.
- `.planning/phases/01-capture-foundation/01-CONTEXT.md` — capture schema, migration/install patterns, Phase 1 boundaries.

### Repository conventions

- `CLAUDE.md` — three-layer architecture definitions and vocabulary.
- `prompts/audit-lib-domain-model-reference.md` — entity definitions and bounded-context language.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- `lib/threadline/capture/audit_transaction.ex` — canonical `audit_transactions` schema; Phase 2 adds nullable `actor_ref` + `belongs_to :action`.
- `lib/threadline/capture/audit_change.ex` — unchanged contract for row-level capture.
- `lib/threadline/capture/migration.ex` — pattern for emitting migration DDL strings from Elixir.
- `lib/threadline/capture/trigger_sql.ex` — **must** be extended for `actor_ref` on `audit_transactions` INSERT while preserving txid upsert semantics.
- `lib/mix/tasks/threadline.install.ex` — install entrypoint; should surface Phase 2 migration generation alongside Phase 1.

### Established patterns

- **PgBouncer-safe grouping** — `txid_current()` + `ON CONFLICT (txid) DO NOTHING` on `audit_transactions`; keep this invariant.
- **No Carbonite** — do not reintroduce as runtime dependency without a new gate/ADR.

### Integration points

- Phoenix / Plug pipeline — consumer inserts `Threadline.Plug` and reads `conn.assigns[:audit_context]`.
- Oban workers — pass serializable context in `args`, use `Threadline.Job` helpers, call `set_config` + `Repo.transaction` when DB-level actor propagation is required.

</code_context>

<specifics>
## Specific Ideas

- JSON keys **`type` / `id`** in JSONB (not `actor_type` / `actor_id`) for a compact on-wire shape.
- **GIN index** on `audit_actions.actor_ref` to unblock Phase 3 containment queries.
- Plug header defaults: prefer **`x-request-id`** and **`x-correlation-id`** when present; fall back behaviour (generate vs nil) is discretion but must be documented in moduledoc.

</specifics>

<deferred>
## Deferred Ideas

- **Auto-link `record_action` to `txid_current()`** — convenience helper; likely Phase 3+.
- **Telemetry `[:threadline, :action, :recorded]`** — HLTH-04; Phase 3.
- **Richer actor resolution** (JWT claims → `ActorRef`) — host-app-specific; document recipes, not hard-wire in Phase 2.
- **README / ExDoc polish** — Phase 4.

### Reviewed Todos (not folded)

- None from `todo.match-phase` for Phase 2.

</deferred>

---

*Phase: 02-semantics-layer*
*Context gathered: 2026-04-22*
