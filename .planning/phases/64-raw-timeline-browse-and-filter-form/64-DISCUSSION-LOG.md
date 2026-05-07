# Phase 64: Raw Timeline Browse & Filter Form - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 64-raw-timeline-browse-and-filter-form
**Areas discussed:** Route + nav placement, Filter form interaction model, Table + actor_id input shape, Pagination + cursor

**Discussion mode:** research-then-recommend (parallel `gsd-advisor-researcher` subagents per area, single roll-up confirm). Per user-memory `gsd-research-then-recommend` — research is dispatched before any option-style question lands; the user sees a single coherent recommendation set with confirm/adjust/reject.

---

## Route + Nav Placement

**A1 — Route literal**

| Option | Description | Selected |
|--------|-------------|----------|
| `/` (mount root) | Browse view = surface home page; one canonical URL never moves | ✓ |
| `/timeline` | Dedicated subroute; mount root stays free for a future home/index | |
| `/changes` | Domain-noun route; closer to `AuditChange` than to "timeline" | |
| `/` + `/timeline` alias | Both work | |

**A2 — Cross-screen nav**

| Option | Description | Selected |
|--------|-------------|----------|
| Inline "← Timeline" back-link | Small back-link in `.threadline-ui` header on TransactionLive / ActorLive | ✓ |
| No nav | Browser back button only | |
| Real top nav bar | Timeline / Coverage / Redaction tabs (predicts Phases 66/67) | |

**Rationale:** Every prior-art operator surface (Oban Web, LiveDashboard, Hangfire, Sidekiq Web, Sentry org root, GitHub `/audit-log`) treats the mount path as the firehose landing page. A named subroute would strand the mount root as a 404 and force a redirect when Phase 66 lands `/audit/coverage` as a sibling. Inline back-link defers the real top-nav decision to Phase 66 when the IA is no longer hypothetical.

---

## Filter Form Interaction Model

**B1 — Submit / apply behavior**

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-apply (debounced) | Every change patches the URL | |
| Hybrid (auto for selects/datetime, explicit for text) | Two mental models in one form | |
| Explicit Apply (Enter or button) | One submit = one URL entry | ✓ |

**B2 — Layout**

| Option | Description | Selected |
|--------|-------------|----------|
| Sticky top toolbar, right-aligned actions | Always visible; natural home for Apply + Phase 65 download cluster | ✓ |
| Collapsible `<details>` drawer | Hides what's active | |
| Inline pill bar (Oban Web style) | Compact; fits a query DSL, not Threadline's fixed keys | |
| Left sidebar / rail | Overkill for 5 keys | |

**B3 — Reset / clear affordance**

| Option | Description | Selected |
|--------|-------------|----------|
| "Clear all" link → bare path (re-defaults to last 24h) | Single canonical reset gesture | ✓ |
| Per-filter chips + "Clear all" | Granular but only meaningful with B2=pills (rejected) | |
| Per-filter chips only | No nuke-it-all gesture | |
| None | Hostile DX | |

**Rationale:** Threadline's filter form is a query builder, not an incremental search. Five heterogeneous keys (two datetimes, table, actor kind+id, correlation_id) almost never make sense one-at-a-time. Auto-apply would thrash the URL on every keystroke (terrible back-button UX, locked in by `live_patch`), fight the focus-loss footgun on free-text fields under `phx-change`, and issue partial queries with half-typed UUIDs. Sticky toolbar reserves the right-aligned cluster for Phase 65's `[Download CSV] [Download JSON]` next to `[Apply]` — same shape, same anchor.

---

## Table + Actor_id Input Shape

**C1 — `:table` filter input**

| Option | Description | Selected |
|--------|-------------|----------|
| Free-text input | No closed-set silent truncation | |
| `<select>` of covered tables | Discoverable; closed-set silently drops unknown URLs | |
| `<input list>` + `<datalist>` | Free-text + native autocomplete; zero JS; degrades cleanly | ✓ |
| Free text + hint label | No autocomplete; hint drifts | |

**C2 — `:actor_ref` input**

| Option | Description | Selected |
|--------|-------------|----------|
| Two inputs: kind `<select>` + id `<input>` | 1:1 with `ActorRef` struct; two flat URL params | ✓ |
| Single `kind:id` text input | Compact; breaks on IDs with `:`; invents UI-only DSL | |
| Three-state with "Any kind" + nil-id support | Requires lib-API expansion (out of phase scope) | |
| Kind-only filter | Same lib-API expansion; defer | |

**C3 — `:correlation_id`**

| Option | Description | Selected |
|--------|-------------|----------|
| Plain text + `phx-debounce="300"` + `maxlength="256"` | Matches server validation exactly | |
| Plain text + inline help | Same as above + discoverability hint | ✓ |
| Plain text + `pattern=` constraint | Over-constrains; no canonical format exists | |

**Rationale:** Datalist preserves "URL = source of truth" — stale URLs round-trip through the form and degrade to a server-side hint instead of being silently dropped. Two flat URL params for actor mirror the struct 1:1, never invent a colon-DSL that breaks when adopters use colons in their IDs (URNs, integration tokens, correlation tokens). Plain text + inline help respects the lib's deliberately-loose `correlation_id` contract — adopters define the format.

---

## Pagination + Cursor

**D1 — Pagination UX**

| Option | Description | Selected |
|--------|-------------|----------|
| Infinite scroll, cursor in assigns, filters-only URL | Coherent with TransactionLive / ActorLive; no tombstone surface | ✓ |
| Next/Prev + cursor in URL | Deep-link to specific page; tombstone 404 on retention purge | |
| Hybrid (infinite scroll + "Copy this view" snapshot button) | Two URL shapes; doubles test matrix | |
| Numbered offset | Pathological at scale; lib has no offset API | |

**D2 — Page size**

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed at lib default (`@default_timeline_page_size`) | One number to reason about (BUT: lib default is 1000, too large for LV render — pass `page_size: 50` explicitly at call site) | ✓ (with override) |
| 25 / 50 / 100 pills | Operator agency; another URL key | |
| Implicit (viewport hooks) | Already implied by infinite scroll | |

**Rationale:** BROWSE-03's "URL alone reproduces results" is a filter-set contract, not a deep-link-to-page-47 contract. SREs paste filter URLs into Slack so a colleague lands on the same first-page top-of-feed — they don't paste opaque keyset cursors. Cursor-in-URL adds three liabilities: (1) history pollution every viewport hit, (2) tombstone 404s when retention purges the cursor row, (3) divergence from the two existing screens that would force Phases 66/67 to rewrite the same wheel. With no cursor in the URL, a 6-month-old pasted URL re-resolves cleanly from "now" backward through the filter window.

---

## Claude's Discretion

- Exact CSS class names, visual styling, and CSS-variable additions under `Threadline.OperatorSurface.Style`.
- Exact wording of empty-state copy, unknown-table hint, and correlation-id help text.
- Stream DOM ids and `phx-update="stream"` boilerplate.
- Exact ARIA label literals (must be locked by the doc-contract test, but the planner picks the literals and the test asserts them).

## Deferred Ideas

- Real top nav bar (Timeline / Coverage / Redaction tabs) — Phase 66 when second sibling exists.
- Saved views with owner / visibility / sharing — v1.19+ (URL bookmarks cover persistence at this stage).
- Per-filter chip UI / "x" remove on each pill — not needed.
- `page_size` URL knob — not needed at v1.18.
- Cursor in URL / "Copy this view" snapshot — Phase 65 export covers durable "save these rows" need.
- Numbered offset pagination — never landing.
- Kind-only actor filter (non-anonymous with nil id) — requires `ActorRef` API expansion; revisit when an adopter reports the need.
- `:schema`-aware datalist — Phase 66 concern.
- Auto-refresh / "newer events" badge — revisit only on real adopter pain.
