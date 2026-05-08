---
id: SEED-002
status: dormant
planted: 2026-05-08
planted_during: v1.19 — Integration Breadth, post-Phase-74 closeout
trigger_when: v1.20 opens or the first adopter asks for retention admin, saved views, queued exports, or governance policy controls
scope: Large
---

# SEED-002: Scale and governance depth for Threadline

## Why This Matters

Threadline already has the core audit substrate, host seams, and operator
surface. The next useful jump is turning that into a more opinionated
production workflow for teams that want retention oversight, repeatable
investigations, and clearer governance controls without losing the current
host-owned boundary.

## When to Surface

**Trigger:** v1.20 planning starts, or adopter feedback starts asking for any of:

- retention admin with visible last-purge history
- saved views or bookmarks for repeated investigations
- queued or scheduled exports with a status surface
- governance or policy UI that stays host-owned

This seed should surface during `$gsd-new-milestone` when the next milestone
needs a real scale/governance slice instead of another breadth or integration
refinement.

## Scope Estimate

**Large** — likely a full milestone, not a single phase.

The work is probably split into several phases with prerequisites:

- operator-facing retention visibility first
- investigation ergonomics next
- export queue/status after the read path is stable
- any broader governance controls last, once the support story is proven

## Breadcrumbs

Related files and decisions already in the repo:

- `.planning/MILESTONE-ARC.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/research/SUMMARY.md`
- `.planning/REQUIREMENTS.md`
- `guides/how-threadline-works.md`
- `guides/upgrade-path.md`
- `guides/domain-reference.md`
- `guides/operator-surface.md`

## Notes

- Keep `threadline_web` extraction evidence-based; do not split for aesthetics.
- The next milestone should start from the current mental model and then
  decompose into prereq-first chunks instead of rediscovering the product shape.
