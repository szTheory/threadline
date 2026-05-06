# Phase 60: Architectural Decisions

*Resolved during the Discuss Phase.*

## 1. Pagination Strategy
**Decision:** Keyset Pagination + LiveView Streams

**Rationale:**
Time-window bounding alone is a massive memory footgun for high-volume system actors. Traditional offset pagination degrades DB performance and causes UX drift. Keyset pagination (cursor-based on `occurred_at` + `id`) combined with Phoenix LiveView Streams gives constant-time DB performance, bounded server memory, and the seamless infinite-scroll UX expected in premium observability tools like Datadog and Stripe.

## 2. API Contract Update (`Threadline.actor_history/2`)
**Decision:** Expand options to support bounded, cursor-based fetching.

**Rationale:**
We will expand the existing `actor_history/2` to accept `opts` for:
- `:limit` (default 50)
- `:before` / `:after` (keyset cursors `{%DateTime{}, id}`)
- `:from` / `:to` (optional time boundaries for the picker)
This makes the core API robust for arbitrary data scale.

## 3. Time-Window Picker Default
**Decision:** Default to Last 24 Hours

**Rationale:**
For audit logs, 15m is too tight and 30d is too broad for initial page load. 24h provides immediate context while minimizing the initial DB scan cost.

## 4. Empty State UX
**Decision:** Distinct empty states

**Rationale:**
Explicitly distinguish between "Actor has never existed/acted" and "Actor has no events in the last 24h" to prevent operator confusion.
