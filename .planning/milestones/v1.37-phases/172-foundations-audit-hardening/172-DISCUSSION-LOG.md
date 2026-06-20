# Phase 172: foundations-audit-hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 172-foundations-audit-hardening
**Areas discussed:** Token Override Approach, Decision Brief Format, Motion Reductions

---

## Token Override Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Strict brandbook parity | Strict parity across all UI tokens | |
| Operator-local tokens | Operator-local tokens in style.ex | |
| Semantic Token Mapping | Semantic Token Mapping in style.ex (Primitive parity, Functional local) | ✓ |

**User's choice:** Semantic Token Mapping in style.ex
**Notes:** One-shot recommendation based on Elixir idiomatic preferences and brand alignment.

---

## Decision Brief Format

| Option | Description | Selected |
|--------|-------------|----------|
| Inline comments | Inline comments in style.ex | |
| Markdown files | Markdown files in .planning/ | |
| Hybrid | Hybrid (Code-anchored pointers + Markdown Ledger in DESIGN-SYSTEM.md) | ✓ |

**User's choice:** Hybrid
**Notes:** One-shot recommendation.

---

## Motion Reductions

| Option | Description | Selected |
|--------|-------------|----------|
| 0ms | 0ms for reduced motion | |
| Opacity fades | Opacity fades for reduced motion | ✓ |

**User's choice:** Opacity fades
**Notes:** Cross-fade fallback (Emil Kowalski / GOV.UK approach). Zero out positional transitions, preserve opacity fades.

---

## Claude's Discretion

None

## Deferred Ideas

None