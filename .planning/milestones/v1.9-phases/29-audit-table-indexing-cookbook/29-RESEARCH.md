# Phase 29 — Technical research: audit table indexing cookbook

**Question:** What do we need to know to PLAN this phase well?

---

## Shipped DDL and indexes (source of truth)

From `lib/threadline/capture/migration.ex` (`migration_content/0`):

| Object | Index / constraint |
|--------|-------------------|
| `audit_transactions` | PK `id` uuid; `txid` bigint UNIQUE; index `audit_transactions_txid_idx` on `(txid)` |
| `audit_changes` | PK `id`; FK `transaction_id` → `audit_transactions`; indexes `audit_changes_transaction_id_idx`, `audit_changes_table_name_idx`, `audit_changes_captured_at_idx` |

From `lib/threadline/semantics/migration.ex`:

| Object | Index / constraint |
|--------|-------------------|
| `audit_actions` | PK `id`; GIN `audit_actions_actor_ref_idx` on `actor_ref`; btree `audit_actions_inserted_at_idx`, `audit_actions_name_idx` |
| `audit_transactions` (Phase 2 alter) | columns `actor_ref` jsonb, `action_id` uuid FK → `audit_actions` |

No separate btree index on `audit_actions.correlation_id` in shipped migrations — correlation filter uses join on `at.action_id == aa.id` and `aa.correlation_id == ^cid`.

---

## Query / export / retention access patterns

### Timeline (`Threadline.Query.timeline_query/1`)

Pipeline: `timeline_base_query` → `filter_by_correlation` → `timeline_order`.

- **Base:** `AuditChange` **inner join** `AuditTransaction` on `ac.transaction_id == at.id`.
- **Filters:** `ac.table_name`, `at.actor_ref` @> jsonb, `ac.captured_at` range.
- **Correlation (non-nil filter):** **inner** join `AuditAction` on `at.action_id == aa.id and aa.correlation_id == ^cid`.
- **Order:** `desc: ac.captured_at`, `desc: ac.id`.

Index implications: hot paths use `transaction_id`, `captured_at`, `table_name`, `audit_transactions.actor_ref` (GIN exists on `audit_actions.actor_ref` but **not** on `audit_transactions.actor_ref` in shipped DDL — worth calling out in cookbook).

### Export (`Threadline.Query.export_changes_query/1`)

- **No `correlation_id`:** `timeline_base_query` + **LEFT** join `AuditAction` on `at.action_id == aa.id` (surfacing action metadata in select).
- **With `correlation_id`:** same as timeline (inner join via `filter_by_correlation`).

Prose in guide must distinguish LEFT vs inner join — aligns with **29-CONTEXT** D-3.

### Retention (`Threadline.Retention.purge/1`)

- **Change batch delete:** `WHERE captured_at < cutoff` with `id IN (subquery LIMIT batch_size)`.
- **Orphan txns (optional):** `NOT EXISTS` subquery on `audit_changes` for `transaction_id = at.id`.

Indexes: `audit_changes_captured_at_idx` supports cutoff scans; orphan drain benefits from `audit_changes_transaction_id_idx` for NOT EXISTS.

---

## Doc and ExDoc patterns

- **Extras:** `mix.exs` → `docs/0` → `extras:` list + `groups_for_extras` — Reference group is `~r{^guides/}`.
- **Contract tests:** `test/threadline/support_playbook_doc_contract_test.exs` — `File.read!` from repo root, `String.contains?/2` on headings and marker strings. Phase 29 targets **medium** strictness per CONTEXT D-4: one marker + spine headings + cross-link fragments.

---

## Risks / tradeoffs to surface in cookbook

- **Redundant indexes:** e.g. btree on column already leading a composite; partial overlaps.
- **Write amplification:** each new index on high-insert `audit_changes`.
- **`CREATE INDEX CONCURRENTLY`:** production-safe additive pattern.
- **Evidence before tuning:** `EXPLAIN (ANALYZE, BUFFERS)`, `pg_stat_user_indexes`.

---

## Validation Architecture

**Dimension 8 (documentation integrity):** Plans must produce (1) a single new guide whose structure matches locked CONTEXT decisions, (2) ExDoc registration, (3) navigation links from existing guides, (4) an automated doc contract test that fails if the marker or operator spine headings disappear.

**Automated verification surface:**

| Artifact | Command |
|----------|---------|
| Elixir format / compile | `mix format`, `mix compile --warnings-as-errors` |
| Full test suite | `mix test` |
| Doc contract (after plan 02) | `mix test test/threadline/audit_indexing_doc_contract_test.exs` |

**Manual:** Optional human read of cookbook for tone — not a gate for this phase.

---

## RESEARCH COMPLETE

Findings are sufficient for planner: shipped indexes enumerated, join semantics documented, retention delete shapes noted, doc/test patterns identified.
