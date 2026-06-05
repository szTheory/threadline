# Phase 136: Design-System Hardening - Context

**Gathered:** 2026-06-04
**Status:** In progress

## Phase Boundary

Harden the `/audit` operator surface design system before the per-screen polish phases. Scope is the existing dark-first, BEM-scoped, inline CSS architecture in `Threadline.OperatorSurface.Style`; no Tailwind migration, no light mode, no theme toggle, no route/schema/query expansion.

This phase owns the Phase-134 design-system findings: F-101 through F-109. It is a prerequisite for the Prove, Find, Home/Nav, flows, motion, responsive, and accessibility sweeps.

## Decisions

- Dark-only remains intentional brand direction: "night infrastructure with luminous signal lines." Do not add `prefers-color-scheme`, `color-scheme: light`, or a theme toggle.
- Improve dark mode through shared tokens first, then apply component primitives. Per-screen one-offs should be avoided unless a screen has a genuinely unique interaction.
- Thread Blue is reserved for links, actions, active states, and focus affordances. Signal Cyan is reserved for correlation/as-of/thread-path emphasis and positive system flow.
- Status, verdict, operation, and danger tokens need visible borders and text contrast in addition to color hue.
- Disabled controls should not rely on opacity alone; use explicit surface, border, and muted text tokens.

## Source Artifacts

- `.planning/milestones/v1.31-UI-AUDIT.md` — Phase 136 findings F-101 through F-109, plus F-901/F-902 accessibility pressure.
- `.planning/milestones/v1.31-PERSONAS-IA.md` — P1-P5, J1-J11, EF1-EF5; preserve Find/Verify/Prove.
- `prompts/Threadline Brand Book.txt` — brand voice and dark palette.
- `lib/threadline/operator_surface/style.ex` — scoped CSS tokens and primitives.

## Plan Slices

1. **136-01 Dark token and interaction contrast foundation** — lift muted/status contrast, make hover/focus/disabled states intentional, lock dark-only CSS contract.
2. **Remaining Phase 136 work** — status-badge/verdict consolidation, op-chip/KV/diff primitives, chip role catalog, card accent rules, date/as-of treatment, `v1.31-DESIGN-SYSTEM.md`, token freeze.

