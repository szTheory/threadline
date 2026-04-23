# Phase 13: Retention & batched purge - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `13-CONTEXT.md`.

**Date:** 2026-04-23  
**Phase:** 13 — Retention & batched purge  
**Areas discussed:** Retention clock, Policy scope, Orphan `audit_transactions`, Mix vs public API (research-backed synthesis)

---

## Retention clock (`captured_at` vs `occurred_at`)

| Option | Description | Selected |
|--------|-------------|----------|
| `captured_at` (per change) | Aligns with `timeline/1`, row-level TTL, clear operator story | ✓ |
| `occurred_at` (per transaction) | Transaction-centric; diverges from timeline filters | |
| Hybrid | Two knobs; compliance-only use cases | |

**User's choice:** Research synthesis + project coherence — primary clock **`AuditChange.captured_at`**.  
**Notes:** Document long-transaction spread; `occurred_at` remains for txn-scoped APIs only unless future policy extends.

---

## Policy scope (global vs per-table / tenant)

| Option | Description | Selected |
|--------|-------------|----------|
| Global window | Single knob; matches v1.3 “bound growth” | ✓ |
| Per-table (v1.3) | Higher matrix; defer unless plan expands | |
| Per-tenant / per-schema | High complexity; defer | |

**User's choice:** **Global default** for v1.3 with **API shape** ready for optional per-table later.  
**Notes:** Config in `config :threadline` like Phase 12; document resolution order when overrides exist.

---

## Empty `audit_transactions` after purge

| Option | Description | Selected |
|--------|-------------|----------|
| Delete empty parents | Keeps `actor_history` consistent with change-backed audit | ✓ |
| Leave orphans | Simpler single `DELETE`; misleading counts | |
| Configurable | Default delete; optional `false` for transition | ✓ (as compat flag) |

**User's choice:** **Default delete empty parents**; optional flag to skip.  
**Notes:** Current DDL: child FK `ON DELETE CASCADE` from parent — child-only delete does not cascade to parent; second pass required.

---

## Operator surface (Mix vs API)

| Option | Description | Selected |
|--------|-------------|----------|
| Mix-only | Ops-friendly; poor for Oban per tick | |
| API-only | Embeddable; weaker discoverability | |
| Both (Mix → API) | Ecto-style split; single source of truth | ✓ |

**User's choice:** **Public purge module + thin Mix task**; Oban calls API; document `MIX_ENV`, repo resolution, idempotent batches.

---

## Claude's Discretion

Exact module names, telemetry vs log-only first cut, CTE vs subquery style for batched deletes.

## Deferred Ideas

Legal holds; per-tenant retention; hybrid txn clocks; cross-phase “export then purge” playbook detail (phase 14).
