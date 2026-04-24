# Audit table indexing cookbook

<!-- IDX-02-AUDIT-INDEXING -->

This guide is the **integrator-owned** place for PostgreSQL index strategy on Threadline’s audit tables. Threadline ships a **baseline** via migrations; optional indexes below are **not mandatory**—measure before you paste DDL into production.

Shipped names and columns are defined in **`Threadline.Capture.Migration`** (`audit_transactions`, `audit_changes`) and **`Threadline.Semantics.Migration`** (`audit_actions`, `audit_transactions.action_id`). Diff those modules when upgrading across Hex releases.

## Installed defaults

Threadline’s install path creates the three relations **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** with the following **baseline** btree / GIN indexes (exact names — copy from migrations, do not rename in docs-only prose):

| Index name | Table | Columns / access method |
|------------|-------|-------------------------|
| `audit_transactions_txid_idx` | `audit_transactions` | `(txid)` |
| `audit_changes_transaction_id_idx` | `audit_changes` | `(transaction_id)` |
| `audit_changes_table_name_idx` | `audit_changes` | `(table_name)` |
| `audit_changes_captured_at_idx` | `audit_changes` | `(captured_at)` |
| `audit_actions_actor_ref_idx` | `audit_actions` | `GIN (actor_ref)` |
| `audit_actions_inserted_at_idx` | `audit_actions` | `(inserted_at)` |
| `audit_actions_name_idx` | `audit_actions` | `(name)` |

Primary keys: `audit_transactions.id`, `audit_changes.id`, `audit_actions.id`. Foreign key: `audit_changes.transaction_id` → `audit_transactions.id` (ON DELETE CASCADE). Optional link: `audit_transactions.action_id` → `audit_actions.id` (see semantics migration).

## Table primers

### audit_transactions

**Grain:** one row per captured database transaction. **Keys:** `id` (UUID PK), `txid` (bigint, unique), `occurred_at`, optional `source` / `meta`, optional `actor_ref` and `action_id` once semantics DDL is applied. **Invariants:** every `audit_change` references exactly one transaction; retention may delete **empty** transactions after changes are purged—tuning indexes for “orphan” cleanup matters alongside change deletes.

### audit_changes

**Grain:** one row per INSERT/UPDATE/DELETE on an audited user table. **Keys:** `id`, `transaction_id`, `table_schema`, `table_name`, `table_pk` (jsonb), `op`, `captured_at`, optional payload columns. **Invariants:** timeline, export, and retention predicates overwhelmingly filter or order on **`captured_at`**, **`table_name`**, and **`transaction_id`**; align any additive index with those access paths.

### audit_actions

**Grain:** one semantic action (`Threadline.record_action/2`). **Keys:** `id`, `name`, `actor_ref` (jsonb), `correlation_id`, timestamps, etc. **Invariants:** correlation filtering joins `audit_actions` to `audit_transactions` on `action_id` with an **inner** join when `:correlation_id` is set; export without correlation still **left**-joins actions for optional metadata—do not confuse the two shapes when explaining indexes to operators.

## Access patterns

Each subsection below uses a **“Tables & modules”** box naming the entry points that must stay aligned with physical tuning.

## Timeline and Threadline.Query

**Tables & modules**

- **Tables:** `audit_changes` ⟵ **INNER JOIN** → `audit_transactions`
- **Module:** `Threadline.Query` — `timeline_query/1` → `timeline_base_query/1` → `filter_by_correlation/2` → `timeline_order/1`; public API `timeline/2`

**Join shape.** `timeline_base_query/1` inner-joins `AuditChange` to `AuditTransaction` on `transaction_id`. When `:correlation_id` is present (non-empty after trim), `filter_by_correlation/2` adds a further **inner** join to `AuditAction` on `at.action_id == aa.id` **and** `aa.correlation_id == ^cid`. When correlation is omitted, no action join is added for timeline rows.

**Already covered / consider adding**

| Already covered (baseline) | Consider adding (non-mandatory) |
|----------------------------|----------------------------------|
| `captured_at` ordering + range filters (`filter_by_from` / `filter_by_to`) | Partial btree on `(table_name, captured_at DESC)` if one hot table dominates timeline |
| `table_name` equality | Narrow composite matching your heaviest `where table_name = ? order by captured_at desc` |
| `transaction_id` for FK traversal | Only after `EXPLAIN (ANALYZE, BUFFERS)` shows seq scans or sort spills |

## Export and Threadline.Export

**Tables & modules**

- **Tables:** `audit_changes` ⟵ **INNER JOIN** → `audit_transactions`; optional **`AuditAction`** join depends on filters
- **Module:** `Threadline.Export` (and `Threadline.Query.export_changes_query/1`)

**Join shape (verbatim semantics from code).** `export_changes_query/1` validates filters, then:

- If **`:correlation_id` is absent**, it builds `timeline_base_query/1` and adds **`join(:left, [ac, at], aa in AuditAction, on: at.action_id == aa.id)`** so export payloads can surface `aa.id` / `aa.correlation_id` without narrowing the change set.
- If **`:correlation_id` is present**, it uses `timeline_base_query/1` followed by **`filter_by_correlation/2`**, which applies the same **inner** join to `audit_actions` as timeline.

Do **not** document export as “always inner join actions”; the **LEFT JOIN** path is the export-specific behavior when correlation filtering is off.

**Already covered / consider adding**

| Already covered | Consider adding (non-mandatory) |
|-----------------|----------------------------------|
| Same change/txn backbone as timeline | Covering indexes only if exports are dominated by sequential scans on stable projections |
| `captured_at` for ordering | BRIN on `captured_at` for very large append-mostly tables (measure bloat vs benefit) |

## Correlation filtering

**Tables & modules**

- **Tables:** `audit_transactions.action_id` → `audit_actions.id`; filter on `audit_actions.correlation_id`
- **Modules:** `Threadline.Query.filter_by_correlation/2` (inner join path)

**Join shape.** With a non-empty correlation id, queries **inner** join `audit_actions` so only changes whose transaction links to an action with that `correlation_id` are returned. Index **`audit_actions(correlation_id)`** is *not* in the shipped baseline; if correlation bundles are hot, add it as **optional** DDL after measuring.

**Already covered / consider adding**

| Already covered | Consider adding (non-mandatory) |
|-----------------|----------------------------------|
| `audit_actions_name_idx`, `audit_actions_inserted_at_idx` | btree on `(correlation_id)` or `(correlation_id, inserted_at)` for bundle lookups |

## Retention and Threadline.Retention

**Tables & modules**

- **Tables:** `audit_changes` (delete by `captured_at` cutoff), then optional `audit_transactions` with **no** child changes
- **Module:** `Threadline.Retention` — `delete_change_batch/3`, `drain_orphans/3` / `drain_orphan_batches/2`

**Predicates.** `delete_change_batch/3` deletes `audit_changes` rows with `captured_at < cutoff` in bounded batches (ids from a subquery with `limit`). When `delete_empty_transactions` is enabled, `drain_orphans` removes transactions where **`NOT EXISTS (SELECT 1 FROM audit_changes c WHERE c.transaction_id = at.id)`**.

Retention touches **changes and transactions**, not “changes alone”—operators should size indexes and autovacuum for **both** tables’ churn.

**Already covered / consider adding**

| Already covered | Consider adding (non-mandatory) |
|-----------------|----------------------------------|
| `audit_changes_captured_at_idx` for eligibility scans | None required if batches stay selective—verify with `EXPLAIN` on your cutoff workload |
| FK from `audit_changes.transaction_id` | — |

## Tradeoffs and evidence

- **Write amplification:** every extra btree/GIN means more work on every capturing insert/update and on semantic `record_action` paths. Redundant indexes (same leading prefix as another index) often waste space with little gain.
- **Redundant prefixes:** a btree on `(table_name, captured_at)` may subsume single-column `table_name` queries—check plans before keeping both.
- **Production DDL:** prefer **`CREATE INDEX CONCURRENTLY`** for additive indexes on live databases; library migrations cannot assume concurrent mode inside transactional migrations.
- **Evidence:** use **`EXPLAIN (ANALYZE, BUFFERS)`** on representative timeline, export, and retention statements; pair with **`pg_stat_user_indexes`** (or `pg_stat_all_indexes`) to confirm an index is actually hit before cementing it in runbooks.

## Optional additive indexes

The following is **illustrative only**—not shipped by Threadline, **not mandatory**, and must be validated on your data.

```sql
-- NON-MANDATORY EXAMPLE — run CONCURRENTLY in prod; replace placeholder names.
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_changes_hot_table_cap
--   ON audit_changes (table_name, captured_at DESC)
--   WHERE table_name = 'your_hot_table';
```

## See also

- [Threadline domain reference](domain-reference.md) — vocabulary, retention vs timeline time bases, export filters
- [Production checklist](production-checklist.md) — operational gates before relying on purge/export in prod
