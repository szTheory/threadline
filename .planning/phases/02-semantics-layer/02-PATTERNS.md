# Phase 2 — Pattern Map

**Generated:** 2026-04-22 (replan)

Maps new semantics artifacts to existing Threadline patterns.

---

## DDL and migrations

| New / changed | Analog | Excerpt / convention |
|---------------|--------|----------------------|
| `Threadline.Semantics.Migration.migration_content/0` | `Threadline.Capture.Migration.migration_content/0` | Returns string of `defmodule ... use Ecto.Migration` with `execute """..."""` blocks; idempotent `IF NOT EXISTS` / `ADD COLUMN IF NOT EXISTS`. |
| Phase 2 `.exs` under `priv/repo/migrations/` | `priv/repo/migrations/*_threadline_audit_schema.exs` | Separate file from Phase 1 per D-04. |

---

## Trigger SQL

| New / changed | Analog | Excerpt / convention |
|---------------|--------|----------------------|
| `threadline_capture_changes()` body | `lib/threadline/capture/trigger_sql.ex` `install_function/0` | Single `INSERT ... ON CONFLICT (txid) DO NOTHING` for `audit_transactions`, then `INSERT` into `audit_changes`. Extend **only** the `audit_transactions` insert column list and `SELECT id` logic — no `SET LOCAL` in function body. |

---

## Ecto schemas

| New / changed | Analog | Excerpt / convention |
|---------------|--------|----------------------|
| `Threadline.Semantics.AuditAction` | `Threadline.Capture.AuditTransaction` | `@primary_key {:id, :binary_id, autogenerate: true}`, `@foreign_key_type :binary_id`, no gratuitous `timestamps` unless table has columns. |
| JSONB custom type on field | (new) `Threadline.Semantics.ActorRef` as `Ecto.ParameterizedType` | D-02: field `field :actor_ref, Threadline.Semantics.ActorRef` |

---

## Tests

| New / changed | Analog | Excerpt / convention |
|---------------|--------|----------------------|
| Integration tests touching triggers | `test/threadline/capture/trigger_test.exs` | `use Threadline.DataCase`; real `Repo`; no Sandbox. |
| Table cleanup | `test/support/data_case.ex` | `Repo.delete_all` order respects FKs: `audit_changes` → `audit_transactions` → `audit_actions`. |

---

## Mix tasks

| New / changed | Analog | Excerpt / convention |
|---------------|--------|----------------------|
| Second generated migration | `Mix.Tasks.Threadline.Install` | Mirror `existing_migration?/1` with a second predicate for `*_threadline_semantics_schema.exs`; do not overwrite user edits. |
