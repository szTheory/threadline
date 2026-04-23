# Phase 9 — Technical research: Before-values capture

**Question:** What do we need to know to plan `changed_from` JSONB, trigger semantics, and `Threadline.history/3` without breaking callers?

## Current implementation snapshot

- **`Threadline.Capture.TriggerSQL.install_function/0`** emits a single global `threadline_capture_changes()` used by every per-table trigger (`create_trigger/1`). UPDATE branch already computes `v_changed_fields` via `jsonb_each(NEW)` joined to `jsonb_each(OLD)` with `IS DISTINCT FROM` — this is the **same key set** `CONTEXT.md` D-01/D-14 require for `changed_from` keys.
- **`audit_changes` INSERT** currently lists `id, transaction_id, table_schema, table_name, table_pk, op, data_after, changed_fields, captured_at` — no `changed_from` column yet (`migration.ex`).
- **`Mix.Tasks.Threadline.Gen.Triggers`** only accepts `--tables` and emits migrations that call the **shared** function — no per-table behavior flags today.
- **Tests:** `test/threadline/capture/trigger_test.exs` uses `DataCase`, creates `test_audit_target`, installs trigger via `TriggerSQL.create_trigger/1`, asserts `AuditChange` rows. This is the right harness for BVAL-01 integration coverage.

## Design tension: global function vs per-table opt-in

`CONTEXT.md` D-05/D-06 require **`mix threadline.gen.triggers` to be the per-table switch** for whether UPDATE rows **write** `changed_from`, default **off**. A single shared `threadline_capture_changes()` cannot encode different **write** behavior per table unless:

1. **Per-table PL/pgSQL functions** (e.g. `threadline_capture_changes_posts()`), each emitted in the migration produced by `gen.triggers` when `--store-changed-from` is set for that invocation, with `CREATE TRIGGER ... EXECUTE FUNCTION ...` pointing at that function; tables generated **without** the flag keep calling the **canonical** `threadline_capture_changes()` from `mix threadline.install`, **or**
2. A **maintained whitelist** inside one global function (requires regenerating the global body whenever any table opts in — conflicts with incremental migrations).

**Recommendation for planning:** Prefer **(1)** — codegen emits a **named function variant** (or duplicated body with compile-time constants) per opted-in table migration, leaving the library default install path unchanged for non-opted tables. The shared Elixir builder should centralize SQL text so `changed_fields` and `changed_from` construction stay one code path (D-14).

## `changed_from` JSON shape (BVAL-01)

- **Sparse map:** keys = columns in the UPDATE change set (same as `changed_fields` ordering policy — keys sorted for stable diffs if we reuse the query’s `ORDER BY n.key`).
- **NULL prior values:** JSON `null` for that key when `OLD` column was SQL NULL (D-02).
- **INSERT/DELETE:** `changed_from` stays SQL NULL (omit from INSERT or insert explicit NULL).
- **`--except-columns`:** Generator strips keys from both `changed_fields` consideration and `changed_from` payload (D-11) — single exclusion list in emitted SQL.

## Schema and upgrades (D-04)

- **`mix threadline.install`** template adds `changed_from jsonb` nullable on `audit_changes` in **new** installs.
- **Existing adopters:** need a **follow-up migration** pattern documented in install guide: `ALTER TABLE audit_changes ADD COLUMN IF NOT EXISTS changed_from jsonb` — executor may ship a **snippet** in docs or optional second generator; plans should not assume `install` overwrites existing migrations.

## Ecto / API (BVAL-02)

- Add `field(:changed_from, :map)` on `Threadline.Capture.AuditChange`; default `nil` in structs when column null.
- **`Threadline.Query.history/3`** uses `repo.all()` without a narrowing `select` — once the schema field exists, Ecto loads it automatically; verify no `select` merge drops columns elsewhere.

## PgBouncer / session coupling (SC #4)

- Extend UPDATE branch using only `OLD`/`NEW`/`TG_*` and existing `current_setting('threadline.actor_ref', true)` read — **no new `set_config` / `SET LOCAL`**.

## Risk: composite primary keys

- `table_pk` still uses `jsonb_build_object('id', ...)` in template — known limitation noted in `CONTEXT.md` code_context; Phase 9 should **not** silently widen debt; plans may **document** only unless a one-line alignment falls out of trigger refactor.

---

## Validation Architecture

**Nyquist sampling for this phase**

| Dimension | Signal | Automated hook |
|-----------|--------|------------------|
| Correctness | UPDATE writes sparse `changed_from` when opt-in SQL installed; INSERT/DELETE null | ExUnit integration tests on PostgreSQL (`DataCase` + temp table + `Repo.all(AuditChange)`) |
| Compatibility | Existing callers of `history/3` receive structs with new key defaulting nil | ExUnit on `Threadline.history/3` / `Query.history/3` |
| Migration truth | Column exists after install template; gen emits reviewable SQL | Grep `changed_from` in `migration.ex` template; fixture migration strings in test optional |
| Security | No new dynamic SQL beyond existing table-name interpolation in triggers | Code review task + grep `SET LOCAL` / `set_config` in `TriggerSQL` output must stay absent except documented actor read |

**Quick command:** `MIX_ENV=test mix test test/threadline/capture/trigger_test.exs test/threadline/query_test.exs` (extend paths once new tests land).

**Full command:** `MIX_ENV=test mix ci.all` (per project CI alias).

**Wave 0:** Not required — ExUnit + Postgres already present (`test/support/data_case.ex`).

---

## RESEARCH COMPLETE

Findings above are sufficient to author `09-VALIDATION.md`, `09-PATTERNS.md`, and executable plans without reopening framework choice.
