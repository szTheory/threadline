---
phase: 1
plan: "01-01"
subsystem: capture
tags: [research, gate, carbonite, postgresql, pgbouncer]
key-files:
  - .planning/phases/01-capture-foundation/gate-01-01.md
key-decisions:
  - "Use Carbonite ~> 0.16 as capture substrate (all four gate questions passed)"
duration: "<10 minutes"
completed: "2026-04-22"
---

# Summary: Plan 01-01 — Carbonite Research Gate

Carbonite passes all gate questions. Decision: **use `{:carbonite, "~> 0.16"}`** as the capture substrate for Phase 1.

## Task Results

| Task | Status | Key Finding |
|------|--------|-------------|
| 1 — Version/maintenance | DONE | v0.16.1 released 2026-04-19; bitcrowd org; 248 stars; 1 open issue; actively maintained |
| 2 — PostgreSQL ≥ 14 | DONE | PG 13+ required (uses `pg_current_xact_id()`); PG 14 fully supported |
| 3 — Transaction-row vs SET LOCAL | DONE | Pure transaction-row: `carbonite_transactions.id` is `xid8` via `pg_current_xact_id()`; `insert_transaction/3` is `INSERT ... ON CONFLICT DO NOTHING`; no `SET LOCAL` anywhere in the metadata path |
| 4 — API surface | DONE | `Migrations.up/2`, `create_trigger/2`, `insert_transaction/3`; `carbonite_prefix` option available; no D-05 conflicts |
| 5 — Gate document | DONE | Written to `gate-01-01.md` with binary decision, evidence table, and Plan 01-02 implications |

## Gate Outcome

**PASS — Carbonite** on all four questions.

The critical D-06 constraint (PgBouncer-safe context propagation via transaction-row insert, not `SET LOCAL`) is satisfied. Carbonite's design is structurally compatible with Threadline's schema constraints.

## Deviations

None. Plan executed as specified.

## Plan 01-02 Unblocked

Plan 01-02 can proceed with:
- `{:carbonite, "~> 0.16"}` dep
- `carbonite_prefix` set to a non-public schema (e.g. `"threadline_audit"`)
- `Carbonite.Migrations.up(1..12)` for schema installation
- `xid8` type consideration for `AuditTransaction` Ecto schema (maps to 64-bit integer in Postgrex)
- No `processed_at` / outbox work in Phase 1
