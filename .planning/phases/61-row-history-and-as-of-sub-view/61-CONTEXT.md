# Phase 61: Row History & As-of Sub-view - Discuss Context

This document captures the architectural decisions made during the discuss phase for Phase 61.

## Goal
Render `Threadline.history/3` plus `Threadline.as_of/4` as a sub-view reachable only from incident drill-down change rows, with a timestamp picker driving the as-of snapshot panel.

## Key Decisions

1. **Routing & Rendering Architecture: Patched URL Sub-view (`live_action` / `live_patch`)**
   - **Decision:** The sub-view is implemented as a slide-over `LiveComponent` rendered over the existing `TransactionLive` screen. It uses a new `live_action` (e.g. `:history`) via `live_patch`.
   - **Rationale:** This pattern is deeply idiomatic for observability tools (like Datadog, Sentry, or GitHub Blame). It allows operators to copy and share exact, deep-linked URLs during an incident without losing the broader parent transaction context. It avoids the "unshareable modal" footgun while skipping the disruptive full-page navigation of a distinct route.
   - **Mechanism:** The URL pattern should be `/transactions/:id/history/:table/:record_id?as_of=...` routed to `TransactionLive` with a `:history` action.

2. **The "As-of" Snapshot UX: Click-to-Scrub Timeline**
   - **Decision:** The primary "timestamp picker" is the history list itself. Clicking any row in the change history immediately updates the URL `?as_of=<captured_at>` (via `push_patch`), and the adjacent "As-of Snapshot" panel updates to show the full state of the record at that exact moment.
   - **Rationale:** This click-to-scrub pattern is vastly superior for incident forensics compared to typing in raw timestamps. We will still include a fallback `datetime-local` HTML input for manual entry, but the primary UX relies on the row timeline acting as the picker.

3. **Component Data Boundary: Component Fetches via `update/2`**
   - **Decision:** The `LiveComponent` (`RowHistoryComponent`) owns its own data fetching.
   - **Rationale:** The parent `TransactionLive` extracts `table_name`, `record_id`, and `as_of` from the URL parameters (`handle_params`) and passes them down. This perfectly encapsulates the `Threadline.history/3` and `Threadline.as_of/4` calls, preventing `TransactionLive` from bloating with domain queries that are completely irrelevant when the slide-over is closed.
