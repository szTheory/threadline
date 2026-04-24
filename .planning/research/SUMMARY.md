# Research Summary: "As-of" / Point-in-Time Reconstruction

**Project:** Threadline
**Last Updated:** 2026-04-24
**Status:** COMPLETE

## Executive Summary

Threadline's "As-of" feature enables "Time Travel"—the ability to reconstruct the state of any database record at any point in history. This is achieved by leveraging Threadline's existing trigger-backed capture mechanism, which stores full-row snapshots (`data_after`) as JSONB on every mutation. Unlike patch-based systems that require replaying many events, Threadline can reify historical state in a single query by fetching the latest snapshot at or before the target timestamp.

The recommended approach is to provide an operator-grade API that returns read-only Ecto structs by default, while allowing fallback to raw Maps when schemas have diverged significantly. The primary risks involve "The Genesis Gap" (records existing before auditing started) and "Schema Drift" (loading old data into new code). These will be mitigated via a "Snapshot-First" retrieval strategy and permissive Ecto loading.

## Key Findings

### Technology Stack (from STACK.md)
*   **Zero New Dependencies:** Reconstruction relies on standard Elixir 1.15+, Ecto 3.10+, and PostgreSQL 14+.
*   **Native Reification:** Uses `Ecto.embedded_load/3` to cast JSONB maps into typed structs without manual mapping.
*   **Snapshot-Driven:** Eschews patch-based reconstruction (like `ExAudit`) in favor of direct snapshot loading for performance and reliability.

### Feature Landscape (from FEATURES.md)
*   **Table Stakes:** Single-row `as_of` lookup, handling of deleted states, non-existence checks (before the first INSERT), and read-only struct projection.
*   **Differentiators:** Collection-level `as_of` (e.g., "list all users as of last Monday"), association travel (reconstructing related records at the same point in time), and visual time-sliders.
*   **Anti-Features:** Avoid global process-level "time context" (dangerous in Elixir); reconstruction should be a read-only "query" feature, not an "auto-revert" write feature.

### Architectural Patterns (from ARCHITECTURE.md)
*   **Snapshot-at-Capture:** Every audit entry is a standalone version, decoupling the history from the live table.
*   **Point-in-Time Lookup:** SQL-native queries using `WHERE captured_at <= T ORDER BY captured_at DESC LIMIT 1`.
*   **Boundary Separation:** Logic is split between `Threadline.Query` (retrieval) and `Threadline.Reify` (structural transformation).

### Critical Pitfalls (from PITFALLS.md)
*   **The Genesis Gap:** Auditing "Brownfield" data often misses the initial state. Requires `Threadline.Continuity` to capture baseline snapshots.
*   **Schema Evolution:** Modern structs may not match 1-year-old JSON. Use permissive loading and maintain raw Map access.
*   **Ghost State:** Deleted records are "invisible" to live-table-first logic. Always use the audit log as the primary source of truth for historical queries.

## Implications for Roadmap

### Suggested Phase Structure

1.  **Phase A: Single-Row Foundation** — Implement the core `Threadline.as_of(schema, id, time)` logic.
    *   *Rationale:* Solves 80% of support use cases with the lowest complexity.
    *   *Deliverables:* `Threadline.Query` extensions and `Reify` module.
2.  **Phase B: Collection & Bulk Operations** — Support `as_of` for lists and filtered queries.
    *   *Rationale:* Required for reporting and compliance audits.
    *   *Deliverables:* SQL optimizations using `LATERAL JOIN` or `DISTINCT ON`.
3.  **Phase C: Association & Correlation Depth** — Reconstruct associated records at time T.
    *   *Rationale:* High complexity; needs to handle "Association Clock Skew" and cross-table references.
    *   *Deliverables:* Recursive reconstruction helpers.

### Research Flags
*   **Needs Research:** Collection-level SQL performance at scale (millions of audit rows).
*   **Standard Patterns:** Single-row reconstruction via `embedded_load` is well-documented and low-risk.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Native Ecto/PG primitives are extremely stable. |
| Features | HIGH | Clear differentiation between "must-have" and "nice-to-have". |
| Architecture | HIGH | Snapshot-based design is already inherent in Threadline's core capture. |
| Pitfalls | HIGH | Identified critical gaps (Genesis, Schema Drift) with clear mitigations. |

### Gaps to Address
*   **Schema Evolution Policy:** We need to decide exactly how "permissive" the default struct loader should be (e.g., error on extra fields or drop them?).
*   **Performance Benchmarks:** Collection-level `as_of` queries on large `audit_changes` tables need validated index strategies.

## Sources
*   `Threadline.Capture.TriggerSQL` (Project Source)
*   `Ecto.Schema` Documentation (Ecto Internals)
*   Prior Art: Logidze (Ruby), Carbonite (Elixir), Hibernate Envers (Java)
