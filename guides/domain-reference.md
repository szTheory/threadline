# Threadline domain reference

This guide defines the vocabulary Threadline uses across capture triggers, Ecto schemas, and the public API. It complements the [README](../README.md) and module documentation on [HexDocs](https://hexdocs.pm/threadline).

## Ubiquitous language

| Term | One sentence | Tier |
|------|----------------|------|
| AuditAction | A semantic “who did what and why” event your application records explicitly. | persisted row |
| AuditTransaction | A database transaction bucket produced by capture, grouping row-level changes and optional actor context. | persisted row |
| AuditChange | One captured INSERT/UPDATE/DELETE on an audited table, tied to a transaction. | persisted row |
| AuditContext | Request-scoped metadata (actor, request/correlation IDs, IP) carried on the connection before it reaches the database. | concept only |
| ActorRef | Structured identifier for who performed an action or triggered writes, stored as JSON-compatible data. | field on row |
| Correlation | Cross-cutting identifier linking work across processes or services (headers, job args), not a first-class DB entity in Threadline. | concept only |

## Relationships

```text
  AuditAction                    AuditTransaction
       |                                |
       |         optional link          |
       +--------------------------------+
       |                                |
       |                                v
       |                         AuditChange
       |                         (one row op)
       v
   (semantic intent)              (physical capture)
```

Invariant: every `AuditChange` belongs to exactly one `AuditTransaction`; an `AuditTransaction` may link to zero or one `AuditAction` when you correlate semantic intent with physical changes.

## AuditTransaction

An `AuditTransaction` is the capture substrate’s grouping record for a single database transaction. PostgreSQL assigns `txid`; Threadline stores it with `occurred_at`, optional `source`/`meta`, and optional `actor_ref` populated from a transaction-local GUC set in the same database transaction as your writes. It may reference an `AuditAction` when you connect semantic events to captured rows.

## AuditChange

An `AuditChange` is one row-level mutation on an audited table: schema/name, primary key map, operation (`op`), optional `data_after`, changed field list, and `captured_at`. Multiple changes in one DB transaction share the same `transaction_id`.

## Redaction at capture

Threadline can **exclude** or **mask** configured columns when PL/pgSQL capture functions are generated (`mix threadline.gen.triggers`), so JSON written to `audit_changes` never contains raw values for those keys. **`exclude`** removes keys from `data_after` (and from change lists where the generator applies the same filter). **`mask`** keeps the key but persists only a stable placeholder (default `"[REDACTED]"`) for both `data_after` and sparse **`changed_from`** when that mode is enabled. Overlap between exclude and mask is a hard error at codegen. **json/jsonb** columns use whole-value masking only. Configuration lives under **`config :threadline, :trigger_capture`** (see README). Path B is preserved: redaction is static SQL and trigger paths do not introduce new session writes.

## Retention (Phase 13)

Operators cap table growth with a **global retention window** under **`config :threadline, :retention`**, validated by `Threadline.Retention.Policy` before purge runs.

- **Primary clock:** eligibility uses each row’s **`AuditChange.captured_at`** (`timestamptz`, microsecond precision), not `AuditTransaction.occurred_at`. This matches `Threadline.Query.timeline/2`, which applies **`captured_at >= :from`** (inclusive lower bound) and **`captured_at <= :to`** (inclusive upper bound) when those filters are set. Retention purge deletes changes with **`captured_at` strictly less than** the computed cutoff (`now` minus the configured window), so the boundary is **exclusive on the “keep” side** at the cutoff instant — slightly stricter than the inclusive `:to` filter in timeline queries; operators should treat the cutoff as “anything older than this instant is eligible.”
- **Global window:** v1.3 is one documented interval for all captured changes (same relation Threadline owns). Per-table retention is an extension point for later releases.
- **Long transactions:** multiple `AuditChange` rows under one `audit_transactions` row can carry **different** `captured_at` values; retention is evaluated **per change row**, not “whole transaction expires as one timestamp.”
- **Empty parents:** after eligible changes are removed, the default purge path deletes **`audit_transactions`** rows that have **no** remaining child changes (optional `delete_empty_transactions: false` for transitional installs). See `Threadline.Retention` / `mix threadline.retention.purge`.

## Export (Phase 14)

Read-only exports for operator playbooks (“export then purge”, cross-checks, ad-hoc analysis).

- **Filter vocabulary:** identical to `Threadline.Query.timeline/2` — `:repo`, `:table`, `:actor_ref`, `:from`, `:to`, `:correlation_id`. Bounds apply to **`AuditChange.captured_at`** (inclusive). **`AuditTransaction.occurred_at`** appears inside exported transaction context and can differ from `captured_at` on the same change row.
- **APIs:** `Threadline.Export` (`to_csv_iodata/2`, `to_json_document/2`, `count_matching/2`, `stream_changes/2`), `Threadline.export_csv/2`, `Threadline.export_json/2`, and **`mix threadline.export`** (see task `@moduledoc`).
- **Formats:** CSV uses a fixed hybrid column layout (JSON blobs for nested maps, single `transaction_json` column). JSON uses **`format_version: 1`** on the wrapped document; **`ndjson`** omits the outer wrapper.
- **Safety:** default **`max_rows`** caps in-memory materialization; results report **`truncated`** when the cap is hit. Streaming ignores that cap — compose with `Stream.take/2` when needed.

## Audit indexing (integrator-owned)

Physical PostgreSQL indexes on **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** are **integrator-owned**: Threadline ships a safe baseline via migrations, but workload-specific btree/GIN choices stay with the team operating the database. For baseline inventory, join shapes (timeline vs export vs correlation), retention delete patterns, and **optional** additive DDL framed as non-mandatory, read the **[Audit table indexing cookbook](audit-indexing.md)**—do not duplicate full DDL matrices here; link to the cookbook when operators need tuning guidance.

<span id="operating-at-scale-v19"></span>

## Operating at scale (v1.9+)

v1.9 adds the **telemetry operator narrative**, the **audit table indexing cookbook**, and **production checklist** guidance on **volume, retention cadence, and purge monitoring** — this heading is a **map** to those homes, not a second copy of their tables or matrices.

- **[Telemetry (operator reference)](#telemetry-operator-reference)** — `:telemetry` events operators should chart.
- **[Trigger coverage (operational)](#trigger-coverage-operational)** — how `Threadline.Health.trigger_coverage/1` tuples relate to `mix threadline.verify_coverage` and on-call triage.
- **[Audit table indexing cookbook](audit-indexing.md)** — baseline vs optional indexes and join semantics for timeline, export, and correlation workloads.
- **[Production checklist — retention and volume](production-checklist.md#4-retention-and-purge)** — purge cadence, growth signals, and CLI/API gates (see **`### Volume, growth, and purge cadence`** under §4).

## Brownfield continuity

Tables with **pre-existing rows** still use **T0** semantics: `Threadline.history/3` may return `[]` until the first trigger-backed mutation after capture is installed. Operators should follow [`guides/brownfield-continuity.md`](brownfield-continuity.md) for checklists, `mix threadline.verify_coverage`, and `mix threadline.continuity` (including `--dry-run`).

## AuditAction

`AuditAction` rows represent application-level audit events you insert via `Threadline.record_action/2`. They are independent of trigger capture until you associate them with transactions through `action_id`.

## AuditContext

`AuditContext` is built by `Threadline.Plug` (or your own code) and stored on `conn.assigns`. It is not persisted until you bridge actor identity into the database inside a transaction (see `Threadline.Plug`).

## ActorRef

`ActorRef` is the structured actor representation serialized to JSON for `audit_transactions.actor_ref` and `audit_actions.actor_ref`. Use `Threadline.Semantics.ActorRef.to_map/1` with `Jason.encode!()` when setting the GUC.

## Telemetry (operator reference)

Threadline emits **`:telemetry.execute/3`** events (no attached handler is required for correctness). Attach handlers in your application `Application.start/2` (or equivalent) for metrics and logs.

| Event | When | Measurements | Metadata |
|-------|------|--------------|----------|
| `[:threadline, :transaction, :committed]` | After capture commits work, or as a proxy when `Threadline.record_action/2` succeeds without an explicit post-commit hook | `table_count` (non‑neg integer; accurate only if you call `Threadline.Telemetry.transaction_committed/2` after the transaction) | `%{}` |
| `[:threadline, :action, :recorded]` | After `Threadline.record_action/2` finishes (success or failure) | `status` (`:ok` or `:error`) | `%{}` |
| `[:threadline, :health, :checked]` | After `Threadline.Health.trigger_coverage/1` returns | `covered`, `uncovered` (counts of tables in each bucket) | `%{}` |

### `[:threadline, :transaction, :committed]`

**When it fires.** Threadline emits this event after capture-associated transactions commit their work, and also emits it as a **proxy** with `table_count: 0` when `Threadline.record_action/2` succeeds without an explicit post-commit hook that supplies real per-transaction counts.

**What to measure.** Use `table_count` when you need fidelity to “how many distinct audited tables produced rows in this transaction.” Compare week-over-week after deploys or schema changes.

**Metadata.** Handlers receive an empty map (`%{}`) today; keep dashboards tolerant if metadata keys are added later.

**Misleading or degraded signals.** `table_count` is often **0** on the `record_action` proxy path even when semantic capture succeeded — that is not proof that triggers failed. A generic smell: steady **zero** `table_count` while application traces show audited-table writes for hours → confirm whether events are dominated by the proxy vs missing `Threadline.Telemetry.transaction_committed/2` after `Repo.transaction/1`.

**Where to look next.** [`production-checklist.md` §1 — Capture and triggers](production-checklist.md#1-capture-and-triggers) for install / `mix threadline.gen.triggers` / coverage cadence; [`production-checklist.md` §6 — Observability](production-checklist.md#6-observability) for handler wiring.

### `[:threadline, :action, :recorded]`

**When it fires.** Immediately after `Threadline.record_action/2` completes, success or failure.

**What to measure.** Emit rate split by `status` (`:ok` vs `:error`). Error spikes often track validation failures, missing `ActorRef`, or repo outages — chart both absolute errors and error ratio.

**Metadata.** Empty map (`%{}`).

**Misleading or degraded signals.** High `:ok` traffic does **not** imply every domain table row was captured; this event tracks the semantics helper, not each physical mutation.

**Where to look next.** [`production-checklist.md` §1 — Capture and triggers](production-checklist.md#1-capture-and-triggers) for trigger coverage cadence; [`production-checklist.md` §2 — Actor bridge and semantics](production-checklist.md#2-actor-bridge-and-semantics) for GUC / `record_action` pairing.

<span id="threadline-health-checked"></span>

### `[:threadline, :health, :checked]`

**When it fires.** After `Threadline.Health.trigger_coverage/1` returns from its catalog pass.

**What to measure.** `covered` and `uncovered` are **aggregate counts** of tables in each bucket across the public user tables `Health` enumerates — telemetry does not stream per-table tuples here.

**Metadata.** Empty map (`%{}`).

**Misleading or degraded signals.** A rising `uncovered` count is inventory drift, not automatically a CI failure: `mix threadline.verify_coverage` enforces only the configured `expected_tables` intersection (see [`## Trigger coverage (operational)`](#trigger-coverage-operational)).

**Where to look next.** Tuple-level results and Mix policy live under [`## Trigger coverage (operational)`](#trigger-coverage-operational); operational cadence in [`production-checklist.md` §1 — Capture and triggers](production-checklist.md#1-capture-and-triggers).

**Weekly / post-deploy / “metrics look wrong” triage**

1. Confirm `:telemetry` handlers for Threadline events are attached in the running release ([`production-checklist.md` §6 — Observability](production-checklist.md#6-observability)).
2. For `[:threadline, :transaction, :committed]`, sample `table_count`: persistent zeros during known writes usually mean the proxy path or missing `Threadline.Telemetry.transaction_committed/2` — revisit the subsection above and `Threadline.Telemetry` on HexDocs.
3. For `[:threadline, :action, :recorded]`, compare `:ok` vs `:error` trends against deploys and auth incidents ([`production-checklist.md` §2 — Actor bridge and semantics](production-checklist.md#2-actor-bridge-and-semantics)).
4. For `[:threadline, :health, :checked]`, reconcile `uncovered` with [`## Trigger coverage (operational)`](#trigger-coverage-operational) before tuning alerts.
5. After schema or trigger changes, rerun the §1 checklist items for `mix threadline.gen.triggers` and `mix threadline.verify_coverage` ([`production-checklist.md` §1 — Capture and triggers](production-checklist.md#1-capture-and-triggers)).
6. Remember **retention purge** does not emit these events — use purge batch logs, not this triage list, when investigating purge-only windows.
7. If correlation-scoped investigations spike, verify whether `record_action` volume alone explains `transaction_committed` traffic (proxy vs counted commits).
8. After material Plug/Phoenix changes, re-check actor GUC wiring and telemetry boot order together (§1 + §6).

**Retention purge** does not emit these events today; use application logs from `mix threadline.retention.purge` / `Threadline.Retention.purge/1` (see task `@moduledoc`) or wrap purge calls with your own telemetry.

See also: `Threadline.Telemetry` on HexDocs for copy-paste attach examples.

## Trigger coverage (operational)

`Threadline.Health.trigger_coverage/1` takes **`repo:`** (required `Ecto.Repo` module) and returns a list of tagged tuples:

`[{:covered, String.t()} | {:uncovered, String.t()}]`

Each tuple names a **public** user table the catalog query sees. `{:covered, name}` means Threadline’s `threadline_audit_*` trigger was found on that relation; `{:uncovered, name}` means it was not.

**Audit catalog tables.** `audit_transactions`, `audit_changes`, and `audit_actions` are **excluded** from the per-table list — they are not expected to carry capture triggers (CAP-10 / `Threadline.Health` `@moduledoc`). Do not expect them in `Health` output.

**`mix threadline.verify_coverage`.** Hosts configure `config :threadline, :verify_coverage, expected_tables: [...]` with the audited tables CI must protect. The task calls `Threadline.Health.trigger_coverage/1`, then `Threadline.Verify.CoveragePolicy.violations/2`, which applies **intersection semantics:** only names in `expected_tables` can fail the Mix task. A `{:uncovered, table}` tuple for a table **not** listed in `expected_tables` is informative output, not a Mix failure by itself.

**Telemetry link.** When you need how those aggregate counts surface in metrics, see the [`[:threadline, :health, :checked]`](#threadline-health-checked) subsection under [`## Telemetry (operator reference)`](#telemetry-operator-reference).

## Correlation

**Correlation is not a database table** in Threadline. Correlation identifiers flow through headers (`x-correlation-id`), assigns, and optional fields on `AuditAction`. Treat them like trace context: they stitch logs and actions across boundaries without implying a `correlations` schema.

## Support incident queries

SQL-native operator playbooks for the five canonical support questions (see `.planning/milestones/v1.8-REQUIREMENTS.md`, “Evidence-driving questions”). Run against a **read-only** session or **replica** when possible. Example SQL uses placeholder schema **`your_schema`** — replace it (and any `your_table` / PK literals) with your install’s names before executing.

**Replace before run:** `your_schema` → audited schema (often `public`); `your_table` / PK values → the row under investigation; time literals → bounded window; `your_correlation_id` → trace string from logs.

Contract marker for automated doc checks: **LOOP-04-SUPPORT-INCIDENT-QUERIES**

| # | Question | Primary path |
|---|----------|--------------|
| 1 | Row history — what changed for this domain row (PK) in the last N days? | `Threadline.history/3` or `Threadline.Query.timeline/2` — SQL: [subsection 1](#1-row-history-pk-changes-in-a-time-window) |
| 2 | Actor window — what did this actor drive across tables in a time window? | `Threadline.actor_history/2` or `Threadline.Query.timeline/2` with `:actor_ref` — SQL: [subsection 2](#2-actor-window-one-actor-across-tables) |
| 3 | Correlation bundle — row-level changes and semantic actions sharing a correlation id | `Threadline.Query.timeline/2` / export with `:correlation_id` — SQL: [subsection 3](#3-correlation-bundle-shared-correlation_id) |
| 4 | Export parity — same slice for review and export | `Threadline.Export`, `mix threadline.export` — details: [subsection 4](#4-export-parity-timeline-and-export-filters-agree) |
| 5 | Action ↔ capture — tie semantic actions to captured mutations | Join `audit_actions` ↔ `audit_transactions` — SQL: [subsection 5](#5-action-and-capture-link-semantic-actions-to-changes) |

### 1. Row history - PK changes in a time window

| Path | When to use it |
|------|----------------|
| **API** | `Threadline.history(MyApp.Schema, id, repo: MyApp.Repo)` returns `AuditChange` structs for one PK; use `Threadline.Query.timeline/2` when you need the shared filter map (`:table`, `:from`, `:to`, …). |
| **SQL** | Ad-hoc psql / BI — join `audit_changes` to `audit_transactions`, constrain `table_name`, JSON containment on `table_pk`, and **bounded** `captured_at`. |

When **`:from`** / **`:to`** are set on `timeline/2`, bounds apply to **`AuditChange.captured_at`** (inclusive). Prefer **`LIMIT`** in raw SQL during exploration.

**Replace before run:** `your_schema`, `your_table`, PK map, timestamps.

```sql
SELECT ac.id,
       ac.transaction_id,
       ac.table_schema,
       ac.table_name,
       ac.op,
       ac.captured_at,
       ac.table_pk,
       ac.changed_fields
FROM   your_schema.audit_changes ac
JOIN   your_schema.audit_transactions at ON at.id = ac.transaction_id
WHERE  ac.table_name = 'your_table'
  AND  ac.table_pk @> '{"id": 123}'::jsonb
  AND  ac.captured_at >= '2026-04-01T00:00:00Z'::timestamptz
  AND  ac.captured_at <= '2026-04-24T23:59:59Z'::timestamptz
ORDER BY ac.captured_at DESC, ac.id DESC
LIMIT 500;
```

### 2. Actor window - one actor across tables

| Path | When to use it |
|------|----------------|
| **API** | `Threadline.actor_history/2` lists transactions for one `ActorRef`; combine with `timeline/2` and `:actor_ref` when you need change rows across tables in a window. |
| **SQL** | Filter `audit_transactions.actor_ref` (JSON) or join through capture rows — keep a **time bound** on `at.occurred_at` or `ac.captured_at`. |

**Replace before run:** `your_schema`, actor JSON literal, window bounds.

```sql
SELECT ac.id,
       ac.table_name,
       ac.op,
       ac.captured_at,
       ac.table_pk
FROM   your_schema.audit_changes ac
JOIN   your_schema.audit_transactions at ON at.id = ac.transaction_id
WHERE  at.actor_ref @> '{"kind": "user", "id": "user-uuid-here"}'::jsonb
  AND  ac.captured_at >= '2026-04-20T00:00:00Z'::timestamptz
  AND  ac.captured_at <= '2026-04-24T23:59:59Z'::timestamptz
ORDER BY ac.captured_at DESC
LIMIT 500;
```

### 3. Correlation bundle - shared correlation_id

| Path | When to use it |
|------|----------------|
| **API** | `Threadline.Query.timeline/2`, `Threadline.Export` / `mix threadline.export` with **`:correlation_id`** in the filter list (same key as timeline). |
| **SQL** | Mirror library semantics with an **inner join** to `audit_actions` on the transaction’s `action_id`. |

**Strict semantics:** when **`:correlation_id`** is set to a non-empty string, **timeline** and **export** return only `audit_changes` whose **`audit_transactions`** row links to an **`audit_actions`** row with that **`correlation_id`** (via `action_id`). Capture rows for transactions **without** that action link **do not** appear — there is no “include orphan capture” mode for this filter. Omit `:correlation_id` entirely to leave correlation out of the filter (export may still `LEFT JOIN` actions for metadata without changing which changes match).

**Replace before run:** `your_schema`, `your_correlation_id`.

```sql
SELECT ac.id,
       ac.table_name,
       ac.op,
       ac.captured_at,
       ac.table_pk,
       aa.id AS audit_action_id,
       aa.correlation_id
FROM   your_schema.audit_changes ac
JOIN   your_schema.audit_transactions at ON at.id = ac.transaction_id
JOIN   your_schema.audit_actions aa
       ON aa.id = at.action_id
      AND aa.correlation_id = 'your_correlation_id'
ORDER BY ac.captured_at DESC, ac.id DESC
LIMIT 500;
```

### 4. Export parity - timeline and export filters agree

| Path | When to use it |
|------|----------------|
| **Mix / API** | **`mix threadline.export`** (see task `@moduledoc`) and `Threadline.Export.to_csv_iodata/2`, `to_json_document/2`, `stream_changes/2` — same allowed keys as `Threadline.Query.timeline/2`. |
| **SQL** | Use when validating parity in the database; **replicate the same predicates** you pass to `timeline/2` (table, actor, time bounds, correlation inner join when filtering by correlation). |

Unknown filter keys raise **`ArgumentError`** in both code paths — see `Threadline.Query` moduledoc.

### 5. Action and capture - link semantic actions to changes

| Path | When to use it |
|------|----------------|
| **API** | `Threadline.record_action/2` sets semantic intent; capture links when the transaction’s `action_id` points at the `audit_actions` row driving that transaction. |
| **SQL** | Start from `audit_actions`, join `audit_transactions`, then `audit_changes`. |

**Replace before run:** `your_schema`, `your_action_id`.

```sql
SELECT aa.id,
       aa.name,
       aa.correlation_id,
       at.id AS transaction_id,
       ac.id AS change_id,
       ac.table_name,
       ac.op,
       ac.captured_at
FROM   your_schema.audit_actions aa
JOIN   your_schema.audit_transactions at ON at.action_id = aa.id
JOIN   your_schema.audit_changes ac ON ac.transaction_id = at.id
WHERE  aa.id = 999001
ORDER BY ac.captured_at DESC
LIMIT 500;
```
