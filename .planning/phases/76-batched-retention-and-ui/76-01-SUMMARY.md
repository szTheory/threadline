---
phase: 76
plan: 01
subsystem: Retention
tags:
  - backend
  - governance
  - background-jobs
requires:
  - 75-01
provides:
  - Background scheduler GenServer
  - Run tracking for retention policies
affects:
  - lib/threadline/retention.ex
  - lib/threadline/retention/pruner.ex
tech_stack_added:
  - PostgreSQL advisory locks via Ecto RAW SQL
tech_stack_patterns:
  - GenServer with Repo.checkout for scoped DB connections
key_files_created:
  - lib/threadline/retention/pruner.ex
  - test/threadline/retention/pruner_test.exs
key_files_modified:
  - lib/threadline/retention.ex
  - test/threadline/retention_test.exs
key_decisions:
  - "Used `Repo.checkout` in Pruner to ensure `pg_try_advisory_lock` is held by the same connection during the entire purge process to prevent leaking locks to the Ecto connection pool."
metrics:
  duration: 12
  completed_date: "2024-05-22"
---

# Phase 76 Plan 01: Batched Retention Pruning and Run Tracking Summary

Implement autovacuum-aware retention pruning and a background scheduler to safely delete old records and track execution.

## Execution Outcomes

Task 1: Core Batched Pruning and Run Tracking
- Added a `sleep_ms` option (default 50) to the batched pruning loop.
- Wrapped the purge loop in an insert and update of `Threadline.Governance.RetentionRun` to track runs (duration, count of deleted rows).

Task 2: Background Scheduler GenServer
- Created `Threadline.Retention.Pruner` GenServer.
- Scans for abandoned runs (older than 24h) in `init` and marks them as "failed".
- Periodically attempts to acquire a session-level PostgreSQL advisory lock `pg_try_advisory_lock` before executing the purge function.
- Ensures the same DB connection is used by wrapping the execution in `Repo.checkout`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Advisory lock connection leak**
- **Found during:** Task 2 (tests failed due to locking on unreserved pool connections)
- **Issue:** Using `Ecto.Adapters.SQL.query!` without `Repo.checkout` returns the connection back to the Ecto pool immediately. Since `pg_try_advisory_lock` is a session-level lock, this causes the pool connection to retain the lock forever, leading to failed unlocks and false positives on subsequent pool checkouts.
- **Fix:** Wrapped the `acquire_lock`, `purge`, and `release_lock` calls inside `Repo.checkout(fn -> ... end)` in the `handle_info(:run_purge, state)` callback, ensuring that a single dedicated connection is held for the entire lock duration.
- **Files modified:** `lib/threadline/retention/pruner.ex`, `test/threadline/retention/pruner_test.exs`
- **Commit:** 8d33df4

## Self-Check: PASSED
- `lib/threadline/retention/pruner.ex` exists.
- Commits match the intended work scope and hashes are present.
