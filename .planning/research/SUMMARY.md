# Research Summary: Threadline v1.20 - Scale and Governance Depth

**Domain:** Audit Logging / Operator UI Governance
**Researched:** 2026-05-08
**Overall confidence:** HIGH

## Executive Summary

Threadline's v1.20 milestone shifts the focus from purely "capturing and reading" data to managing its lifecycle and improving operator ergonomics. The core thesis is that as an audit log grows to tens of millions of rows, synchronous HTTP exports and manual database pruning become unviable. To be considered an enterprise-grade library, Threadline must provide mechanisms for retention pruning, asynchronous exports, and saved views.

The primary architectural challenge is building these heavy-duty features without violating Threadline's "zero host intrusion" promise. Imposing Oban for background jobs or `pg_partman` for database partitioning would alienate smaller adopters. Therefore, the research strongly advocates for using Elixir's built-in OTP primitives (`Task.Supervisor`, `GenServer`) and `Ecto` for default implementations, while providing explicit `Behaviours` (`Threadline.Storage`, `Threadline.ExportQueue`) that allow scale-ups to swap in Oban and S3.

## Key Findings

**Stack:** Zero new required runtime dependencies; leverage `Task.Supervisor` and Ecto for state, offer Oban/S3 adapters.
**Architecture:** Pluggable backends for Storage and Queues; host-owned actor IDs for scoping Saved Views.
**Critical pitfall:** Naive `DELETE FROM` statements without chunking will lock production databases; Threadline must provide a batched, autovacuum-aware pruner.

## Implications for Roadmap

Based on research, suggested phase structure for v1.20:

1. **State & Behaviours Infrastructure**
   - Rationale: Before the UI can do anything, the underlying schemas (`threadline_export_jobs`, `threadline_retention_runs`, `threadline_saved_views`) and Behaviours (`Storage`, `ExportQueue`) must exist.
   - Addresses: Database migrations and foundational contracts.

2. **Retention Pruning Engine & UI**
   - Rationale: The highest risk to the host DB. Build the batched pruner, log runs to the DB, and expose a "Retention History" LiveView page.
   - Avoids: DB locks via naive deletions.

3. **Saved Views Ergonomics**
   - Rationale: A fast, high-value win for operators. Requires mapping the host's `actor` to a view owner and building the UI form in the existing timeline.
   - Addresses: Repeated investigations UX.

4. **Async Exports Orchestrator & UI**
   - Rationale: The most complex feature. Requires the queue runner, the CSV stream writer (to local disk), and the UI to show pending/running/completed status with a download link.
   - Avoids: LiveView timeouts during massive exports.

5. **Scale Adapters (Oban / S3)**
   - Rationale: Once the built-in system is proven, provide the `Oban` and `ExAws.S3` adapters so enterprise adopters can deploy the feature in multi-node environments safely.
   - Avoids: Broken downloads across load-balanced nodes.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | The Elixir ecosystem is mature regarding Oban vs Task tradeoffs. Pluggable behaviours are standard. |
| Features | HIGH | Table stakes for scale are well understood in the enterprise SaaS space. |
| Architecture | HIGH | Chunked deletions and DB-backed queues are standard Ecto patterns. |
| Pitfalls | HIGH | Multi-node file storage and Postgres autovacuum exhaustion are classic, well-documented traps. |

## Gaps to Address

- **Storage Cleanup:** If exports are written to Local Disk or S3, when are they deleted? We may need a feature in Phase 4 to "expire" export artifacts after 7 days to avoid disk bloat.
- **Export Formats:** Is CSV sufficient, or will adopters demand JSONL? (Sticking to CSV for MVP).
