# Phase 60 Validation Analysis

## Goal-Backward Verification

**Phase Goal**: Implement the Actor Window Screen to provide a paginated, time-bounded view of an actor's history.

**Observable Truths:**
- Actor history queries can be paginated forward and backward.
- Actor history queries can be bounded by a time window.
- User can visit `/audit/actors/:kind/:id` and see a paginated list of transactions.
- User can change the time window.
- User sees explicit empty states for "no events in window" vs "no events ever".
- Transactions deep-link to the incident drill-down screen.

**Required Artifacts vs Plans:**
- `lib/threadline/query/actor_history_page.ex` -> Addressed in Plan 60-01 (Pagination struct).
- `lib/threadline/query.ex` -> Addressed in Plan 60-01 (Expanding `actor_history/2`).
- `lib/threadline.ex` -> Addressed in Plan 60-01 (Delegation).
- `lib/threadline/operator_surface/live/actor_live.ex` -> Addressed in Plan 60-02 (LiveView).
- `lib/threadline/operator_surface/router.ex` -> Addressed in Plan 60-02 (Routing).

## Nyquist Compliance
- **60-01-PLAN.md**: Includes `<verify>` block with `mix test test/threadline/query_test.exs` to ensure pagination and time bounding logic works on the core data fetch mechanism.
- **60-02-PLAN.md**: Includes `<verify>` block with `mix test test/threadline/operator_surface/live/actor_live_test.exs` to guarantee the LiveView mounts, routes properly, handles explicit empty states, and sets up DOM streams for bidirectional scrolling.

Both plans have clear `<automated>` commands within their `<verify>` elements. The testing spans both the core query logic and the presentation layer, verifying the goals backward from user perception to core implementation.
