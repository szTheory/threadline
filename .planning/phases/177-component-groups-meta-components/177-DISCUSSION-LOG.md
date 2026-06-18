# Phase 177: Component groups / meta-components - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 177-component-groups-meta-components
**Areas discussed:** Realization mechanism, Scope & registry map, Cross-child state coordination, Motion language

---

## Realization mechanism

### Q1 — How should component groups be realized?

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid (primitives-first) | Tiny set of layout/spacing primitives (stack/cluster) + named meta-component only for the 2-3 assemblies that recur with coordination logic; audit the rest in-place. | ✓ |
| Named meta-components | Extract every recurring configuration into its own named UI component. | |
| Composition primitives only | Spacing/layout primitives + documented conventions only, no named groups. | |

**User's choice:** Hybrid (primitives-first)
**Notes:** Matches "explicit composition" + "build for real demand" from the OSS-DNA; avoids rigid wrappers around per-page-varying assemblies while still locking the high-recurrence ones. → D-01/D-02.

### Q2 — Which assemblies become named meta-components? (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| data-panel | data_table + state family + pager with coordination baked in. | ✓ |
| toolbar | search + filters + sort cluster with wrap/spacing + disabled-coordination. | ✓ |
| detail-header | title + metadata KV + actions for detail pages (recurs 3×). | ✓ |
| extend page_header w/ breadcrumbs | Add a :breadcrumbs slot to existing page_header instead of a new group. | ✓ |

**User's choice:** All four
**Notes:** data_panel, toolbar, detail_header extracted as named; page_header gains a :breadcrumbs slot; everything else stays inline composition over stack/cluster. → D-03/D-04/D-05.

---

## Scope & registry map

### Q1 — How wide is the audit scope across the ~12 configurations?

| Option | Description | Selected |
|--------|-------------|----------|
| All 12, mark live vs reference | Cover all 12 named in GROUP-01 as group stress stories; build from real-page markup where it exists, stress story is canonical reference otherwise; tag live vs reference-only. | ✓ |
| Only configs on real pages | Audit only configurations that appear on the 11 pages; mark rest N/A. | |
| All 12 fully built | Build every config as a fully-realized assembly even with no page consumer. | |

**User's choice:** All 12, mark live vs reference
**Notes:** GROUP-01 enumerates all 12 as literal acceptance criteria; tagging live/reference feeds Phase 178 page-stress. → D-06b/D-07.

### Q2 — Reconnect/offline-banner + disabled-actions: how to detect disconnect (CSP-clean, no new JS)?

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView built-in CSS hooks | Use .phx-loading/.phx-disconnected/.phx-error body classes to drive banner + disable actions via pure CSS. | ✓ |
| Server-assign connected? flag | Track connected?/1 + heartbeat assign, render from server. | |

**User's choice:** LiveView built-in CSS hooks
**Notes:** Catches a dropped socket mid-session (connected? is mount-time only); zero new JS/deps; CSP-clean. → D-08. (Chart piece carried from D-176-22 as hand-rolled inline — D-08b.)

---

## Cross-child state coordination

### Q1 — When one child enters a non-happy state, how do siblings behave?

| Option | Description | Selected |
|--------|-------------|----------|
| Scoped by state class | Content-replacing states swap only the data region (header/toolbar stay, controls disable on loading/error); permission/unavailable collapses panel body only; stale = banner above live data. | ✓ |
| Full group takeover | Any non-happy state replaces the entire group with one message. | |
| Per-child, independent | Each child renders its own state with no coordination rule. | |

**User's choice:** Scoped by state class
**Notes:** Preserves orientation (header/breadcrumb), avoids over-hiding on empty filter results, keeps the D-176-16 forensic distinctions, honors D-176-14 (stale precedes data). Focus-move and branching carried from D-176-15/17. → D-06/D-06c/D-06d.

---

## Motion language

### Q1 — Which transitions earn motion? (multi-select; rest stay instant)

| Option | Description | Selected |
|--------|-------------|----------|
| Overlay enter/exit | Modal/drawer/toast/dropdown entrance + exit via JS.show/hide transitions. | ✓ |
| Data-region state swap | Short cross-fade on the region container when state swaps. | ✓ |
| Stale banner appear | Banner fade/slide in above live data on failed refresh. | ✓ |
| Tab / segmented switch | Animate active indicator and/or subview crossfade. | ✓ |

**User's choice:** All four
**Notes:** Reconciliation captured in D-11 — the data-region swap animates the *container on a (low-frequency) state change*, NOT per-row streamed inserts (timeline stream stays un-animated per the existing style.ex motion block). Reduced-motion already handled by the system-wide blanket at style.ex:3868 (D-12) — no per-component handling needed.

---

## Claude's Discretion

- Spacing/hierarchy rhythm — likely a small set of semantic gap tokens (stack/inline/section) over the numeric `--tl-space-*` scale (D-09).
- Per-group responsive reflow — toolbar wrap order, action-bar→kebab, stat-cards grid→stack, breadcrumb overflow; reuse existing responsive mechanisms, no ARIA table roles (D-13).
- Exact component/slot names, ledger tag field name, new `--tl-*` token names, file location — match existing idioms (D-14).

## Deferred Ideas

- Fully building configs with no live page (drawer+form, tabs+subviews as shipped surfaces) — reference-only this phase; promote on real demand.
- A named `UI.chart` component — chart stays hand-rolled inline; extract only if a second charted surface appears.
- Group-level bulk actions / multi-select — rejected in D-176-19, not revisited.
- Per-group copy/microcopy sweep — systematic pass is Phase 179.
