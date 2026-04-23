# Phase 2: Semantics Layer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `02-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 02 — Semantics Layer
**Areas discussed:** Module layout, ActorRef storage, AuditAction schema, migrations, action↔transaction linking, record_action API, Plug/Job context, CTX-03 PostgreSQL bridge, trigger ownership

**Session note:** User chose to follow the agent’s recommended path: **update existing context** (replacing headless draft) and **continue with replan after** existing plans. Gray areas were resolved using **recommended defaults** logged below (equivalent to guided auto-selection).

---

## Module layout and scaffolding cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Semantics under `Threadline.Semantics.*`, Plug/Job top-level | Matches `CLAUDE.md` three-layer model | ✓ |
| Flatten semantics into `Threadline` root | Fewer namespaces, blurrier boundaries |  |

**User's choice:** Recommended default (agent-applied on user request).
**Notes:** Remove conflicting `lib/threadline/audit_*.ex` scaffolds; keep `Threadline.Capture.*` canonical for row capture.

---

## ActorRef representation

| Option | Description | Selected |
|--------|-------------|----------|
| Struct + `Ecto.ParameterizedType`, JSONB `type`/`id` keys | Single column, shared cast/load, query-friendly JSONB | ✓ |
| Flat `actor_type` + `actor_id` columns | Simpler SQL types, more columns and drift vs JSON map requirement |  |
| Embedded schema | Heavier changeset surface for a value object |  |

**User's choice:** Recommended default.
**Notes:** Six actor types including `anonymous` without id.

---

## CTX-03 vs gate-01-01 (session GUC vs PgBouncer safety)

| Option | Description | Selected |
|--------|-------------|----------|
| App calls `set_config(..., true)` in same transaction; trigger **reads** GUC on INSERT | Meets CTX-03; trigger does not issue `SET LOCAL`; transaction-local visibility | ✓ |
| Ignore CTX-03 in code; document only | Fails locked requirements |  |
| `SET LOCAL` inside trigger for actor | Reintroduces Carbonite-class hazard flagged in gate |  |

**User's choice:** Recommended default.
**Notes:** Distinguish **application-set, transaction-local GUC** from **library trigger issuing SET** on the capture hot path.

---

## `record_action/2` repo coupling

| Option | Description | Selected |
|--------|-------------|----------|
| Required `repo:` option | Library stays explicit and testable | ✓ |
| `Application.get_env` default repo | Magic config, multi-repo pitfalls |  |

**User's choice:** Recommended default.

---

## Action ↔ transaction linking

| Option | Description | Selected |
|--------|-------------|----------|
| Nullable `audit_transactions.action_id` FK; explicit Multi linking | SEM-03 without fragile implicit txid coupling | ✓ |
| Implicit auto-link on every `record_action` | Async / nested transaction hazards |  |

**User's choice:** Recommended default.

---

## Claude's Discretion

- Helper module naming for applying GUC + transaction wrapper around Repo callbacks.
- Exact PL/pgSQL for `current_setting` / cast edge cases.
- Plug callback shape for resolving `actor_ref` from host auth.

## Deferred Ideas

See `<deferred>` in `02-CONTEXT.md` — telemetry, auto-link helpers, README work, third-party actor resolution recipes.
