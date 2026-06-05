# Phase 137: "Prove" Cluster Polish - Pattern Map

**Generated:** 2026-06-04
**Status:** Ready for planning

## Overview

Phase 137 should reuse existing operator-surface idioms rather than introduce a new component architecture. The strongest analog is `PolicyRedactionLive`: grouped sections, explicit status owners, `details` disclosure, and remediation links. Exports, Retention, and Evidence should move toward that level of clarity while keeping implementation inside existing LiveViews, `Presentation`, and `Style`.

## File Mapping

| Target file | Role | Closest analog | Pattern to reuse |
|-------------|------|----------------|------------------|
| `lib/threadline/operator_surface/presentation.ex` | Shared display semantics | Existing `status_label/1`, `status_modifier/1`, `truncate_middle/2`, `query_pairs/1`, `export_summary/1` | Add pure helpers for derived labels/ranks and ref display; keep no DB/product behavior here |
| `lib/threadline/operator_surface/style.ex` | Scoped `.tl-*` primitive catalog | Existing `.tl-button`, `.tl-chip`, `.tl-alert`, `.tl-empty`, `.tl-job`, `.tl-record-card`, `.tl-copy` | Add narrow token-backed classes only where primitives need layout support |
| `lib/threadline/operator_surface/live/export_status_live.ex` | Export readiness monitor | `PolicyRedactionLive` grouped sections; `TimelineLive` stream reset patterns | Group by readiness or deliberately reset assigned grouped lists on refresh |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | Retention health + destructive action | Redaction summary-before-detail; table responsive pattern | Move context before destructive action; keep `handle_event("prune_now")` thin |
| `lib/threadline/operator_surface/live/evidence_live.ex` | Proof verdict cards | Existing `tl-record-card`; Transaction/Actor copy id affordance | Status-led card order, muted mono subject refs, first proof-history action |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | Baseline Prove pattern | Self | Preserve unless primitive alignment requires small changes |
| LiveView tests under `test/threadline/operator_surface/live/` | Contract verification | Existing copy/status/assertion tests | Add exact copy/order/class assertions for audit finding closure |
| `test/threadline/operator_surface/style_contract_test.exs` | CSS contract | Existing dark/token/status assertions | Add assertions for any new reusable `.tl-*` classes if introduced |

## Existing Code Excerpts and Guidance

### Shared Presentation Helpers

Current helper examples:

```elixir
def truncate_middle(value, max_length \\ 34)
def status_modifier(status)
def status_label(status)
def query_pairs(params)
def export_summary(params)
```

Use this file for:

- export readiness calculation and group rank
- ready/unavailable/action labels
- actor and subject display values if multiple surfaces need them
- explicit placeholder labels

Do not use this file for DB access, LiveView event behavior, or route expansion.

### Redaction Baseline

`PolicyRedactionLive` establishes the local Prove cluster shape:

- summary metrics first
- grouped sections in locked order
- one status chip per row
- `details` disclosure for secondary configured/deployed content
- remediation links in row summary

Exports should copy the grouped-section idea for readiness groups. Retention should copy the summary-before-detail idea. Evidence should copy the "status owner before detail" rule.

### Stream Patterns

Exports and Retention currently use streams:

- `ExportStatusLive` streams `:jobs`, inserts on refresh, and assigns `:has_jobs`.
- `RetentionHistoryLive` streams `:runs`, inserts on refresh, and recomputes `:runs_summary`.
- `TimelineLive` and `ActorLive` show reset patterns such as `stream(:changes, page.entries, reset: true)`.

If Exports switches from a flat stream to grouped readiness sections, the planner must choose one of:

- keep streams and define how each group stays correct across refreshes, or
- use assigned grouped lists and replace the whole grouped assign on each refresh.

The second option is simpler for a 100-row bounded monitor and avoids grouped-stream complexity.

### Copy Affordance

`Threadline.OperatorSurface.Script` and `.tl-copy` already support dependency-free copy buttons on `[data-tl-copy]` elements. Existing examples:

- `transaction_live.ex` copies transaction ids.
- `timeline_live.ex` copies correlation ids.
- `actor_live.ex` copies transaction ids.

Evidence subject refs and export actor refs can reuse this if copy buttons are needed. If not, the minimum requirement is middle-truncated visible text plus full value in `title`.

### Unsupported and Empty State Pattern

`UnsupportedView` renders:

- `.tl-empty tl-empty--unsupported`
- title/body
- CLI fallback as `<code>`
- Back to Timeline action

Do not create a separate unsupported component for this phase. Improve empty states inside the four target LiveViews using `.tl-empty`, locked headings/bodies, and existing action buttons.

## Recommended Task Dependencies

1. Shared `Presentation`/`Style` changes must land first.
2. Exports and Retention can then proceed independently.
3. Evidence and Redaction alignment can proceed independently after shared helpers.
4. Tests for each surface should be updated in the same plan as the source changes.

## Acceptance Anchors

- No new routes.
- No schema or query expansion.
- No Tailwind/shadcn/icon dependency.
- New CSS remains `.tl-*` and token-backed.
- Each plan cites `POLISH-PROVE`.
- Each plan covers the relevant context decisions D-01 through D-25 and UI-SPEC finding IDs.

## PATTERN MAPPING COMPLETE
