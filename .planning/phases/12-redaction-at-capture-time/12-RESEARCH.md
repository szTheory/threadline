# Phase 12 — Technical research: Redaction at capture time

**Phase:** 12 — Redaction at capture time  
**Question:** What do we need to know to plan implementation well?

## Summary

Redaction is **codegen-time policy** baked into static PL/pgSQL (`CREATE OR REPLACE FUNCTION …`), matching existing Path B constraints: `txid_current()` grouping, read-only `current_setting('threadline.actor_ref', true)`, no `SET LOCAL` / `set_config` in the trigger path for redaction (D-15).

**Gap today:** `threadline_capture_changes()` assigns `v_data_after := to_jsonb(NEW)` on INSERT/UPDATE without stripping excluded columns or masking. Per-table `install_function_for_table/2` only applies `except_columns` to **changed_fields / changed_from** logic on UPDATE — not to full-row `data_after` on INSERT (D-11).

**Implementation vectors:**

1. **Config** — Add `config :threadline, :trigger_capture` (or `:gen_triggers`) with per-table `exclude: [...]`, `mask: [...]`, optional `mask_placeholder`, optional per-table placeholder. Load in `Mix.Tasks.Threadline.Gen.Triggers` via `Application.get_env/2` after `Mix.Task.run("app.config")` pattern (verify how other Mix tasks read host config in this repo).

2. **Validation (Elixir)** — At codegen: `exclude ∩ mask` → `Mix.raise` with column list (D-08). Placeholder: max length, charset, no control chars; emit as single-quoted SQL literal in generated function body (D-06).

3. **TriggerSQL** — Extend `install_function/1` and `install_function_for_table/3` (arity bump for redaction opts) to:
   - Build `v_data_after` from `to_jsonb(NEW)` minus excluded keys, then apply mask keys with literal placeholder.
   - UPDATE: same shaping for `v_data_after`; for `changed_fields` / `changed_from`, apply exclude-then-mask to values sourced from OLD/NEW consistently (D-09, D-10).
   - INSERT/DELETE: parity per CONTEXT D-11; DELETE unchanged for row body.
   - **json/jsonb columns:** whole-value replacement with placeholder only (D-12).

4. **Per-table vs global** — When `exclude`/`mask` non-empty **or** `store_changed_from: true`, emit per-table function + `:per_table` trigger (D-13). Tables with neither use global function (unchanged).

5. **Duplication** — Factor shared fragment for transaction upsert + `audit_changes` INSERT; per-table wrapper only shapes JSON variables (D-14). No `EXECUTE` for policy.

6. **Mix task** — Parse new options or rely purely on config: CONTEXT prefers config as canonical; optional `--dry-run` prints resolved policy. Keep `--tables` required.

## PostgreSQL / JSONB notes

- Dropping keys: `v_data_after := v_data_after - ARRAY['col1','col2']` or build `jsonb` incrementally — prefer `-` / `||` with `jsonb_build_object` for masked keys for clarity in generated SQL.
- Mask: set key to `to_jsonb('[REDACTED]'::text)` style — literal must match chosen default.
- `changed_from`: today built from `to_jsonb(OLD) -> key` for keys in `v_changed_fields`; masked keys must show placeholder, excluded keys absent.

## Risks

- **Regression** on existing `trigger_changed_from_test.exs` / `trigger_test.exs` — any signature change to `install_function_for_table` must update all call sites and generated migration patterns.
- **Primary key** — `table_pk` uses `id` column hardcoded in SQL today; redaction must not remove PK from `table_pk` json if `id` were ever listed (unlikely) — document that PK columns should not be exclude/mask targets or validate against PK if schema introspection added later; for Phase 12, document-only may suffice per REDN scope.

## Carbonite cross-check

`Carbonite.Migrations.put_trigger_config/4` uses `excluded_columns` vs `filtered_columns` — aligns mentally with exclude vs mask; Threadline remains custom SQL but naming in docs can reference analogy.

## Validation Architecture

Phase 12 verification is **integration-first on PostgreSQL** (roadmap success criteria 1–2). Nyquist sampling during execution:

| Dimension | Strategy |
|-----------|----------|
| **Unit / fast** | Pure Elixir tests for config merge validation, overlap detection, placeholder validation (no DB) where logic is isolated. |
| **Integration** | `DataCase` tests mirroring `trigger_changed_from_test.exs`: create temp table, `Repo.query!(TriggerSQL…)`, run INSERT/UPDATE/DELETE, assert `AuditChange` rows via `Repo.all` — grep-able payloads. |
| **CI parity** | `MIX_ENV=test mix ci.all` after substantive changes; document in SUMMARY if PG unavailable locally. |
| **Security / Path B** | Static review checklist: generated SQL must not introduce `set_config`, `SET LOCAL`, or dynamic SQL for policy; acceptance greps on `lib/threadline/capture/trigger_sql.ex`. |

**Wave 0:** No new global test framework — reuse `Threadline.DataCase` and existing audit schemas.

**Sampling:** After each task touching SQL generation, run targeted `mix test test/threadline/capture/trigger_redaction_test.exs` (created in plan 02); before phase close, full `MIX_ENV=test mix ci.all`.

---

## RESEARCH COMPLETE
