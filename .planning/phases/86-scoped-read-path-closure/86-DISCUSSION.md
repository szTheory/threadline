# Phase 86: Scoped Read-Path Closure — Discussion & Recommendations

This document resolves the gray areas for Phase 86, focusing on how Threadline's read-paths should behave for tenant-scoped operators to guarantee a truthfully safe support lane without breaking the operator experience.

## Gray Area 1: Row History / As-Of Support for Scoped Operators

### Context & Analysis
The `RowHistoryComponent` provides exploratory "As-Of" snapshots and timeline diffs, relying on `Threadline.history/3` and `Threadline.as_of/4`. Unlike the Timeline, Actor, and Transaction views, these functions do not currently accept or apply the host-owned `scope_query_fn`. The question is whether to block this component for scoped sessions or push the narrowing logic down into the core JSONB historical queries.

*   **Option A: Disable `RowHistoryComponent` when scoped.**
    *   *Pros:* Trivial to implement. Guarantees zero data leakage.
    *   *Cons:* Creates a degraded, two-tier Operator Experience (DX/UX). Disabling a core exploratory feature means support operators cannot reconstruct historical states. It violates the Principle of Least Surprise and contradicts Threadline's goal of being a "batteries-included" hybrid platform.
*   **Option B: Thread `scope_query_fn` into the core APIs.**
    *   *Pros:* Idiomatic Elixir/Ecto. Ecto excels at composable queries. Passing an anonymous query-transform function down to the `Threadline` context allows the host application to retain opaque authorization logic while Threadline handles the query mechanics safely. It maintains full feature parity for support operators without compromising security.
    *   *Cons:* Requires modifying the internal `history/3` and `as_of/4` queries to properly compose with the host's filtering logic over the `AuditChange` schema.

### Recommendation: Scope It
**We must thread `scope_query_fn` down into `Threadline.history/3` and `Threadline.as_of/4`.**
Disabling row history for support operators is a UX anti-pattern. Threadline’s contract dictates that the host owns the auth semantics and Threadline provides the exploratory UI. By extending these functions to accept `scope_query_fn` (e.g., passing `surface: :row_history`), we ensure tenant-scoped agents can safely reconstruct states for the records they are authorized to see, eliminating the cross-tenant data leak vulnerability while preserving the core product value. 

---

## Gray Area 2: Coverage Dashboard Posture

### Context & Analysis
The Coverage Dashboard (`/audit/coverage` via `CoverageLive`) displays system-wide trigger coverage, exposing database table names, schema structure, and overall operational health.

*   **Option A: Allow access based on the baseline `authorize_fn`.**
    *   *Pros:* Keeps configuration minimal.
    *   *Cons:* Unacceptable Information Disclosure risk. Tenant-scoped operators (e.g., customer support agents) have no legitimate business viewing system-wide `pg_namespace` details, trigger gaps, or baseline schema names.
*   **Option B: Explicitly block/gate the Coverage Dashboard.**
    *   *Pros:* Aligns with the project's existing security posture for bulk exports (which requires an explicit `export_authorize_fn` opt-in). It honors the distinction between "safe row-exploration" and "global operational/admin access."
    *   *Cons:* Adds a new callback to the API surface.

### Recommendation: Explicitly Block and Gate
**We must explicitly block tenant-scoped operators from the Coverage Dashboard via a new `coverage_authorize_fn` callback.**
The coverage dashboard is a system-global operational surface. Unlike timelines or transactions, it cannot be conceptually "narrowed" via a `scope_query_fn` because it operates on system catalogs and global definitions, not tenant records. 

To maintain security and the Principle of Least Privilege, Threadline must treat the Coverage Dashboard exactly like Exports:
1.  Introduce a `coverage_authorize_fn` option to the mount configuration.
2.  Default it to `false` (fail-closed) so that, by default, only operators explicitly approved for coverage viewing can access it.
3.  Hide the Coverage navigation link and deny access at the `CoverageLive` mount level if the check fails.

## Final Authoritative Call
1.  **Row History:** Extend `Threadline.history/3` and `Threadline.as_of/4` to apply `scope_query_fn` to the `AuditChange` queries. Preserve the UX; do not disable the component.
2.  **Coverage Dashboard:** Implement `coverage_authorize_fn` (defaulting to `false`) to explicitly gate the Coverage surface. Do not leak global database schemas to tenant-scoped support staff.
