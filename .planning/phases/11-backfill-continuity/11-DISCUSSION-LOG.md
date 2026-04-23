# Phase 11: Backfill / continuity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `11-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 11 — Backfill / continuity
**Areas discussed:** Baseline T₀ semantics; Operator surface (Mix vs module); `audit_transactions` linkage; Documentation strategy
**Mode:** User requested **all** areas in one shot with **subagent research** and a **unified recommendation set** (no interactive per-area Q&A).

---

## Research synthesis (subagents)

Parallel `generalPurpose` agents produced: (1) baseline options A–E with prior art (PaperTrail, Audited, Logidze, Carbonite, temporal, Debezium); (2) Mix-only vs module vs both with ecosystem parallels (Ecto, Oban, Req); (3) linkage options A–C + footguns + recommendation favoring explicit adoption transaction; (4) README vs guide split with Ash/Oban/Absinthe/Ecto patterns.

**Tension resolved in CONTEXT:** Agent (1) and roadmap SC3 favor **no default rows in `audit_changes` that mimic trigger captures** and preserve **`AuditChange` “trigger-only” moduledoc**. Agent (3) favored **explicit synthetic transaction with baseline rows** for stream continuity — **rejected as v1.2 default** because it collides with D-02 unless reserved ops + schema work land; **optional future opt-in** deferred (D-04). **Default path:** strict empty history until first real mutation + **out-of-band** baseline documentation (D-03).

---

## Baseline / T₀ semantics

| Option | Description | Selected |
|--------|-------------|----------|
| A — Strict empty until first mutation | Honest gap; `history/3` `[]` until first capture | ✓ |
| B — Distinguishable marker in `audit_changes` | Reserved op / column; needs API filter semantics | Deferred |
| C — Fake INSERT snapshot | Looks like real insert; misleading | ✗ |
| D — Sidecar snapshot / export | Compliance baseline outside audit rows | ✓ (documented pattern) |

**User's choice:** Expert synthesis per user request — **A + D** as shipped story; **B** deferred.

---

## Operator surface

| Option | Description | Selected |
|--------|-------------|----------|
| Mix-only | Tasks only | ✗ |
| Module-only | No discoverable CLI | ✗ |
| Thin Mix + public module | README + releases + tests | ✓ |

---

## `audit_transactions` linkage

| Option | Description | Selected |
|--------|-------------|----------|
| A — Synthetic tx + baseline changes | Single adoption tx with rows | ✗ as default (see tension) |
| B — Piggyback on first user tx | Mixed causality | ✗ |
| C — No audit rows until first trigger | Matches strict T₀ | ✓ |

---

## Documentation

| Option | Description | Selected |
|--------|-------------|----------|
| README-only | Risky for audit ops | ✗ |
| Guide-only | Poor Hex skim | ✗ |
| Split README + `guides/…` + Hex extras | Progressive disclosure | ✓ |

---

## Claude's Discretion

Exact task/module naming; optional small cutover metadata table vs doc-only — left to plan-phase.

## Deferred Ideas

- In-stream baseline markers with schema/API (`history/3` filtering).
- Optional `threadline_*` cutover registry table if doc-only is insufficient for TOOL-02 tests.
