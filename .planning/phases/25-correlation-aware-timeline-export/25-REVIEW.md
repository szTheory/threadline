---
status: clean
phase: 25
reviewed: 2026-04-24
---

# Phase 25 code review

## Scope

`Threadline.Query`, `Threadline.Export`, `Threadline` docs, tests, CHANGELOG for LOOP-01 `:correlation_id`.

## Findings

No blocking issues. Correlation filter uses parameterized join (`^cid`). Validation rejects ambiguous empty/`nil` key usage per D-2. Export uses left join only on the export query path when the filter is absent, preserving timeline row counts while enabling JSON `action` metadata.

## Residual risk

Operators should treat empty result sets as “no matching linked action,” not invalid ids (documented in CONTEXT D-5; CHANGELOG hints at semantics).
