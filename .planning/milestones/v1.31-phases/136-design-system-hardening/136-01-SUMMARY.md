---
phase: 136-design-system-hardening
plan: "01"
subsystem: operator-surface-design-system
tags: [operator-surface, dark-mode, design-system, accessibility, css-tokens]
requirements_completed: []
requirements_advanced: [POLISH-DS]
completed: 2026-06-04
---

# Phase 136 Plan 01 Summary: Dark Token and Interaction Contrast Foundation

Implemented the first Phase 136 design-system slice. This is **not** the full v1.31 milestone and **not** all of Phase 136. It establishes a stronger dark-mode token foundation for the rest of the design-system and per-screen polish work.

## Files Changed

- `lib/threadline/operator_surface/style.ex`
- `test/threadline/operator_surface/style_contract_test.exs`

## What Changed

- Lifted muted text and semantic status colors for dark-mode readability.
- Added shared surface-hover, selected, focus-border, muted-soft, accent-border, and danger-border tokens.
- Improved nav, segmented controls, form controls, buttons, chips, alerts, and empty-error state styling through shared CSS.
- Replaced opacity-only disabled button styling with explicit disabled surface/border/text states.
- Kept dark-only behavior locked: `color-scheme: dark`, no `prefers-color-scheme`, no light-mode token block.
- Added a contract test for the dark-only decision and the dark interaction/status token seams.

## Verification

- `DB_PORT=5433 mix test test/threadline/operator_surface/style_contract_test.exs` — 3 tests, 0 failures
- `DB_PORT=5433 mix test test/threadline/operator_surface --max-failures 1` — 269 tests, 0 failures
- `DB_PORT=5433 mix verify.example_browser` — 42 Playwright tests passed
- `git diff --check` — clean
- Manual screenshot spot-check:
  - desktop Home
  - mobile Exports
  - mobile Timeline invalid-filter state

## Remaining Phase 136 Work

- Consolidate status/verdict rendering into a canonical primitive (F-101/F-102).
- Apply op-chip modifier consistently and extract shared value/KV/diff treatment (F-103/F-104).
- Define chip roles, card accent rules, radius rules, and count ownership (F-105/F-109).
- Document the canonical `.tl-*` catalog in `v1.31-DESIGN-SYSTEM.md`.
- Freeze the token scale for downstream phases.

