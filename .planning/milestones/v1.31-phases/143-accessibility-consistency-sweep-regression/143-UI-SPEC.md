---
phase: 143-accessibility-consistency-sweep-regression
requirements: [POLISH-A11Y]
date: 2026-06-04
---

# Phase 143 UI Contract

## Accessibility Baseline

- All interactive primitives have visible keyboard focus using the existing Threadline focus ring.
- Focus order follows visual/semantic order: skip link -> header/nav -> screen primary controls -> rows/cards/actions -> drawers.
- Nav active state exposes `aria-current`; segmented controls expose `aria-pressed`; destructive actions expose text and confirmation semantics.
- Icon/copy/action buttons have accessible names.
- Status/verdict chips include text labels and shape/border treatment; no status meaning is conveyed by color alone.
- Muted body text hits WCAG AA contrast on the dark surface tokens used by cards, panels, and page background.

## Consistency Sweep

- Existing Phase 134 findings owned by Phases 135-142 must be traceable to a closing phase artifact or explicitly closed in Phase 143.
- Existing browser specs must be made current with shipped v1.31 behavior.
- Stale copy/selectors should be updated to stable, user-facing selectors without weakening the behavioral assertion.

## Screenshot Diff

- Final screenshot set must cover the Phase 134 baseline matrix: 12 screen states x 2 viewports.
- Every changed screen must have a short explanation tied to phases 135-143.
- No unexplained generated screenshot artifacts are committed outside the final screenshot directory and guard snapshots.

## CI Guard

- The guard must run through the existing Playwright test lane invoked by `mix verify.example_browser`.
- A guard failure should clearly name the screenshot/surface that drifted.
- Guard scope should remain lightweight enough for PR CI.

