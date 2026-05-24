# Phase 86: Scoped Read-Path Closure - Validation Requirements (Nyquist Compliance)

## Overview
This document defines the strict Nyquist test coverage requirements and validation criteria for the changes introduced in Phase 86 (`86-01`, `86-02`, and `86-03` plans). The objective is to ensure absolute compliance with tenant data isolation (read-path boundaries) and support surface access control, closing all potential cross-tenant or system topology leaks.

## 1. Coverage Dashboard Gating (Plans 86-01 & 86-02)

### 1.1 Auth Flow & Assignment (`Auth.on_mount/4`)
*   **Target:** `lib/threadline/operator_surface/auth.ex`
*   **Nyquist Criteria:** `test/threadline/operator_surface/auth_test.exs` must explicitly verify:
    *   When a host provides a passing `coverage_authorize_fn`, `:threadline_coverage_enabled` is assigned as `true`.
    *   When a host provides a failing `coverage_authorize_fn`, `:threadline_coverage_enabled` is assigned as `false`.
    *   When no `coverage_authorize_fn` is provided, it strictly defaults to `false` (Default Deny).

### 1.2 Telemetry Polling Gate (`Coverage.OnMount`)
*   **Target:** `lib/threadline/operator_surface/coverage/on_mount.ex`
*   **Nyquist Criteria:** `test/threadline/operator_surface/coverage/on_mount_test.exs` must explicitly verify:
    *   If `:threadline_coverage_enabled` is `false`, the initial database coverage fetch is bypassed completely.
    *   If `:threadline_coverage_enabled` is `false`, the `Process.send_after` background telemetry polling loop is never initiated, preventing silent background leakage.

### 1.3 Surface UI Gating & Badges
*   **Targets:** 
    *   `lib/threadline/operator_surface/live/coverage_live.ex`
    *   `lib/threadline/operator_surface/components/surface_header.ex`
    *   All caller LiveViews (`timeline_live`, `retention_history_live`, `export_status_live`, `actor_live`, `transaction_live`)
*   **Nyquist Criteria:**
    *   **Direct Access:** `test/threadline/operator_surface/live/coverage_live_test.exs` must assert that unauthorized sessions manually navigating to `/coverage` are immediately redirected via `push_navigate` back to the root base path.
    *   **Header Component:** Tests must assert that the Coverage UI badge markup (`surface-badge--warn`, `surface-badge--ok`) is completely absent from the DOM when `coverage_enabled` is `false`.
    *   **Threading Guarantees:** Caller LiveViews must successfully compile without errors, proving they correctly thread `coverage_enabled={@threadline_coverage_enabled}` into the `<.surface_header>` component.

## 2. Row History Tenant Scoping (Plan 86-03)

### 2.1 Query Boundaries
*   **Target:** `lib/threadline/query.ex`
*   **Nyquist Criteria:** `test/threadline/query_test.exs` must comprehensively verify:
    *   All four historical endpoints (`history/3`, `as_of/4`, `row_history/4`, and `row_history_page/4`) correctly apply the `maybe_apply_scope/2` macro using the new `row_history_scope_opts/3` private helper.
    *   When `scope_query_fn` is provided in the options, the resulting `Ecto.Query` accurately applies the host's scoping where-clauses, demonstrating that cross-tenant read access is blocked at the query level.

### 2.2 Component Parameter Threading
*   **Targets:** `lib/threadline/operator_surface/live/row_history_component.ex` and `TransactionLive`
*   **Nyquist Criteria:**
    *   **Propagation:** `TransactionLive` must thread `scope={@threadline_scope}` and `scope_query_fn={@threadline_scope_query_fn}` to the `RowHistoryComponent`.
    *   **Execution:** `RowHistoryComponent` tests (if present) or integration checks must assert that these assigns are successfully unpacked into the `opts` list passed to `Threadline.history/3` and `Threadline.as_of/4`, completing the secure path from the host config to the database query.

## Acceptance Sign-Off
- [ ] 100% pass rate for the above scenarios under `mix test`.
- [ ] Code strictly follows established `maybe_apply_scope/2` and `Auth.on_mount/4` patterns (no one-off implementations).
- [ ] Security gates are fail-closed (default deny).