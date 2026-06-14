---
created: 2026-06-13T00:00:00Z
title: Transaction page content left-pushed at desktop widths (theme-independent layout bug)
area: operator-surface
resolves_phase: 178
origin: Phase 167 light-mode review (item E)
files:
  - lib/threadline/operator_surface/style.ex
---

## Problem

On `/audit/transactions/:id`, the `.tl-transaction.tl-short-content` content reads as **pushed
to the left at desktop widths** (looks fine at tablet). Reported during the Phase 167 review.

This is **theme-independent** (reproduces in dark too) — a **layout** issue, outside Phase 167's
value-lane scope, so it was deferred.

## Findings (from Phase 167 exploration)

- `.tl-short-content { max-width: 72ch; margin-inline: auto; }` *should* center the block.
- `.tl-transaction` / `.tl-page__header` have no width/centering of their own.
- The shell uses a grid at ≥768px (`grid-template-columns: minmax(196px,232px) minmax(0,1fr)`),
  `.tl-page` is `grid-column: 2` with `min-width: 0`. The centering appears not to take effect at
  desktop — likely the grid column sizing / a missing desktop layer rather than `.tl-short-content`.

## Solution (when picked up)

1. **First check whether it's a nav-overhaul-lane regression** — the shell grid + `.tl-page`
   layout was touched in the uncommitted nav-overhaul work; this push may be a side effect there
   rather than a standalone bug.
2. Otherwise, restore centering at desktop (verify `.tl-page` isn't constraining its child, or add
   the desktop layout layer that lets `margin-inline: auto` resolve).
