# Phase 184: Timeline investigation flow - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-28
**Phase:** 184-timeline-investigation-flow
**Areas discussed:** Investigation command shape, Row scan and pivots, Handoff utilities, Ugly-data states and proof bar

---

## Investigation Command Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Row-first command surface | First viewport has starter filters, result facts, readiness, active chips, Apply/reset; drawer has advanced filters, saved views, export/handoff. | yes |
| Fully inline filter console | All filters, saved views, export, and readiness controls visible above rows. | |
| Query-string command bar | One search input using qualifiers like `table:`, `actor:`, `correlation:` plus facts/chips. | |
| Persistent filter side rail | Desktop side panel with filters/saved views, mobile drawer, results beside it. | |

**User's choice:** User selected all gray areas and requested research-backed one-shot recommendations rather than piecemeal choices.
**Notes:** Subagent research recommended the row-first command surface. It matches current URL-backed LiveView behavior, keeps rows visible, preserves native controls, and avoids mobile/keyboard crowding. The drawer should hold secondary refinement and handoff utilities.

---

## Row Scan And Pivots

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid scan row with visible pivots | Fast scan of op/table/time/PK, transaction remains primary, row history direct when safe, actor/correlation URL pivots visible, copy affordances contextual. | yes |
| Transaction-first row only | Minimal churn; row history is available only after opening transaction. | |
| Dense table/grid with fixed action columns | Strong desktop alignment and comparison, but risky on mobile/reflow. | |
| Expandable row or overflow-menu pivots | Compact first row with details hidden behind expansion/menu. | |

**User's choice:** User selected all gray areas and requested cohesive recommendations.
**Notes:** Subagent research recommended the hybrid row. Direct row-history should appear only when the row has a safe routeable identity; otherwise transaction remains the safe pivot. Do not hide primary actions behind menus, and do not animate high-frequency streamed rows.

---

## Handoff Utilities

| Option | Description | Selected |
|--------|-------------|----------|
| Utility drawer with one visible handoff entry | Keep saved views, checks, Queue export, Carry to Exports, and downloads in drawer/sheet; main Timeline stays scan-first. | yes |
| Exports-first handoff | Send operators to Exports for most handoff work; strongest status/auth context but more friction. | |
| Inline Timeline utility rail | Make all handoff utilities visible inline above or beside rows. | |

**User's choice:** User selected all gray areas and requested cohesive recommendations.
**Notes:** Subagent research recommended keeping utilities in the drawer. Saved views stay near filters; Carry to Exports is the safest primary handoff; Queue export is a faster secondary path; direct CSV/JSON/NDJSON links remain real HTTP links and remain guarded by export auth and filter parity.

---

## Ugly-data States And Proof Bar

| Option | Description | Selected |
|--------|-------------|----------|
| Timeline-critical state lattice + layered proof | First-class proof for states that affect investigation decisions, using source/LiveView/Playwright/stress layers without screenshot sprawl. | yes |
| Exhaustive Timeline matrix | Full ugly-data/theme/viewport screenshot and browser matrix. | |
| Generic component/stress proof only | Rely mostly on shared component and stress-route proof. | |
| LiveView contract-only proof | Fast source/LiveView proof without new layout-critical browser checks. | |

**User's choice:** User selected all gray areas and requested cohesive recommendations.
**Notes:** Subagent research recommended the Timeline-critical state lattice. First-class proof should cover empty/no-data/future/unknown-table/error/export/scope/loading-stale/long-value/mobile-keyboard/reduced-motion/theme behavior. Generic states remain in shared stress/data-state proof unless Timeline renders them directly.

---

## Claude's Discretion

- User explicitly delegated the recommendations and asked for expert synthesis across Elixir/Phoenix/Plug/Ecto, OSS library DX, SRE/operator posture, UI/UX, accessibility, brand, and cross-ecosystem lessons.
- Downstream agents may choose exact plan count, task split, helper names, CSS selectors, and test organization while preserving the locked recommendations in `184-CONTEXT.md`.

## Deferred Ideas

- Query-language power-user search.
- Persistent desktop filter side rail.
- Dense fixed-column Timeline table.
- Expandable row raw diff previews.
- Exports page IA polish.
- Coverage workflow polish.
- Broad screenshot matrix or visual-regression SaaS.
- Public component API, Tailwind/shadcn migration, production Storybook/stress route, and runtime destructive redaction.
