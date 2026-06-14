---
created: 2026-06-13T00:00:00Z
title: Coverage "schema: public" card de-clutter (reduce nested border/padding blocks)
area: operator-surface
resolves_phase: 176
origin: Phase 167 light-mode review (item C, structural part)
files:
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
---

## Problem

On `/audit/coverage`, the "Coverage — schema: public" section reads as **cluttered** — a lot of
nested bordered/padded blocks. Verified nesting: `.tl-coverage-command` (border + shadow + padding)
> `.tl-summary-grid` > `.tl-card--metric` ×3 (each its own border + shadow + padding), plus the
per-table "Needs capture" cards repeat the border/shadow treatment again. The repeated chrome reads
loud on white ("focal but ugly").

This is **structural/layout** (nesting depth + repeated containers), outside Phase 167's value-lane
scope, so the structural fix was deferred (only token value-softening was in 167's remit).

## Solution (when picked up)

Reduce the card-in-card-in-card depth on the coverage surface — e.g. let the metric row be a single
panel with internal dividers instead of three independently-bordered/shadowed `.tl-card--metric`
cards, and flatten the per-table rows. Aim for one clear container per logical group, not nested
borders at every level. Touch `coverage_live.ex` (DOM) + the relevant `style.ex` rules.
