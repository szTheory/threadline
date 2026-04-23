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

## Brownfield continuity

Tables with **pre-existing rows** still use **T0** semantics: `Threadline.history/3` may return `[]` until the first trigger-backed mutation after capture is installed. Operators should follow [`guides/brownfield-continuity.md`](brownfield-continuity.md) for checklists, `mix threadline.verify_coverage`, and `mix threadline.continuity` (including `--dry-run`).

## AuditAction

`AuditAction` rows represent application-level audit events you insert via `Threadline.record_action/2`. They are independent of trigger capture until you associate them with transactions through `action_id`.

## AuditContext

`AuditContext` is built by `Threadline.Plug` (or your own code) and stored on `conn.assigns`. It is not persisted until you bridge actor identity into the database inside a transaction (see `Threadline.Plug`).

## ActorRef

`ActorRef` is the structured actor representation serialized to JSON for `audit_transactions.actor_ref` and `audit_actions.actor_ref`. Use `Threadline.Semantics.ActorRef.to_map/1` with `Jason.encode!()` when setting the GUC.

## Correlation

**Correlation is not a database table** in Threadline. Correlation identifiers flow through headers (`x-correlation-id`), assigns, and optional fields on `AuditAction`. Treat them like trace context: they stitch logs and actions across boundaries without implying a `correlations` schema.
