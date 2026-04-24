# Phase 27: Example app correlation path - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **27-CONTEXT.md** — this log preserves research synthesis.

**Date:** 2026-04-24
**Phase:** 27 — Example app correlation path
**Areas discussed:** Proof surface (test vs README); HTTP `record_action` wiring; timeline vs export proof; README alignment
**Mode:** User selected **all** gray areas; parallel subagent research + maintainer synthesis (no interactive Q/A turns).

---

## Summary of research threads

### 1. Proof surface

| Option | Summary | Verdict |
|--------|---------|---------|
| Test-only | CI contract, no drift; weak discoverability | Partial |
| README-only | Fast human DX; brittle, no proof app matches prose | Reject as sole proof |
| Both | Test authoritative; README short + cross-link | **Selected** |

**Lessons cited:** OpenTelemetry exemplars (middleware order, don’t only script in IEx); Rails `request_id` (defaults vs reinvention); audit SDKs (prerequisites for correlation queries).

### 2. HTTP `record_action`

| Option | Summary | Verdict |
|--------|---------|---------|
| Same txn as audited write | Atomic story; satisfies strict `:correlation_id` join | **Selected** |
| Capture-only HTTP | Valid for some domains; contradicts “correlation path” demo | Secondary / explicitly labeled only |

**Lessons cited:** Tracing (correlation on durable artifacts); dual-write footguns; outbox/async valid only with explicit contract.

### 3. Timeline vs export

| Option | Summary | Verdict |
|--------|---------|---------|
| Timeline in CI | Minimal, idiomatic ExUnit | **Primary automated proof** |
| Export in README | jq / ticket ergonomics; same filter map | **Illustrative snippet** |
| Both fully tested in example | Duplicates library parity tests | Avoid |

### 4. README alignment

| Option | Summary | Verdict |
|--------|---------|---------|
| Minimal patch | Fast; may under-teach | Insufficient alone |
| Full rewrite | Coherent but high churn | Reject |
| Layered (capture → semantics/correlation) | Progressive disclosure; matches Phoenix/Oban README patterns | **Selected** |

**Patterns cited:** Phoenix guides (progressive disclosure), Oban README (one canonical vertical slice), Stripe-style explicit semantics.

---

## User's choice (synthesized)

Single coherent package: **integration test** proves HTTP → **`record_action`** → **`timeline/2`** with **`:correlation_id`**; **README** layered + **export+jq** snippet + **replace stale `action_id` disclaimer**; preserve **REF-01** doc-contract literals.

## Deferred ideas

Captured in **27-CONTEXT.md** `<deferred>`.
