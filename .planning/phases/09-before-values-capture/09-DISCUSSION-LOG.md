# Phase 9: Before-values capture - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `09-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 9 — Before-values capture
**Mode:** `[--all]` Auto-selected all gray areas; research via parallel subagents; user requested one-shot cohesive recommendations (no interactive Q&A).

**Areas discussed:** `changed_from` semantics, Opt-in surface, `history/3` / struct API, Sensitive columns

---

## 1. `changed_from` semantics (full OLD vs sparse subset)

| Option | Description | Selected |
|--------|-------------|----------|
| Full prior row | Serialize entire `OLD` as JSON for every UPDATE | |
| Sparse subset | JSON map: keys = changed columns only, values = prior values; explicit JSON null for SQL NULL | ✓ |

**User's choice:** Sparse subset (aligned with research: Carbonite-style naming, storage/PII tradeoffs, synergy with `changed_fields`, single derivation path).

**Notes:** Full-row snapshot deferred to a **separate** future opt-in if reify-from-one-row becomes a requirement. INSERT/DELETE remain null per BVAL-01.

---

## 2. Opt-in surface (`store_changed_from`)

| Option | Description | Selected |
|--------|-------------|----------|
| Config-only | Application config drives capture | |
| Install-only | Global default in install migration | |
| Gen.triggers authoritative | Per-table flag in emitted DDL; install adds nullable column only | ✓ |
| Hybrid | D + optional config as **generator default** only | ✓ |

**User's choice:** Hybrid per research — **install/upgrade = column**; **`mix threadline.gen.triggers` = per-table behavior** in versioned migrations; **optional config** for generator defaults only; **CLI wins** on conflict.

**Notes:** Avoids silent mismatch between “dev thinks BVAL is on” and production trigger body. Matches Oban-style “migrations are truth” for durable artifacts.

---

## 3. `Threadline.history/3` and `%AuditChange{}` API

| Option | Description | Selected |
|--------|-------------|----------|
| New field on struct | Nullable `:changed_from` on `%AuditChange{}` | ✓ |
| Opt-in `:with` | Keyword to load before-values | |
| `history/2` | Implicit repo | |

**User's choice:** Add schema field; keep **`history/3`** with required **`repo:`**; default query selects column; no `:with` for normal path.

**Notes:** Matches Ecto “struct = row” and additive versioning columns in Rails-style libs; least surprise vs association preload patterns.

---

## 4. Sensitive / heavy columns

| Option | Description | Selected |
|--------|-------------|----------|
| Document only | Warn in docs, no mechanism | |
| Generator `except` list | Per-table omitted columns baked into emitted trigger SQL | ✓ |
| Full redaction product | Policy engine / masking | |

**User's choice:** Generator-time **`--except-columns`** (exact flag name: planner discretion) — minimal v1.2 mechanism without redaction product scope.

**Notes:** Pairs with per-table BVAL opt-in; parallels Logidze `--except`, PaperTrail `ignore`; operator must re-run when schema adds sensitive columns.

---

## Claude's Discretion

- Exact **CLI spelling** and **PL/pgSQL** structure for building sparse JSON — left to plan-phase within constraints D01–D14 in `09-CONTEXT.md`.

## Deferred Ideas

- Full-row OLD as separate column/phase
- Runtime redaction / DLP
- Coverage task warnings for function/column mismatch (Phase 10)
