---
phase: 167-component-retune
plan: 01
status: complete
completed_at: 2026-06-13
requirements: [COMP-01, COMP-02]
---

# Plan 167-01 Summary — Review-First Gate

## What was built
- Scaffolded and filled `LIGHT-REVIEW.md` (the committed human-judgment artifact, D-08): per-family
  disposition for all 9 dark-effect families + per-criterion outcomes for the 3 data-viz surfaces.
- Ran the review-first gate: rendered the Phase 166 light/system token-recolor **live** at
  `http://localhost:4010/audit` (admin session, `mix demo.seed` data) and recorded human verdicts.

## Review coverage
- `:light` reviewed **live** (Home, Coverage, Timeline, Transaction/diff).
- `:dark` is the unchanged frozen baseline (no dark token/rule touched; frozen-hex tests enforce).
- `:system` is value-identical to `:light` (same tokens via the `@media` branch; D-07(a) dual-branch
  assertion guarantees parity).
- `#5` drawer scrim / `#6` drawer shadow pre-screened from Phase-166 tokens (not live-confirmed —
  drawer is the `Open row history` overlay; flagged as flag-later candidates).

## Proven fail-list (drives Plan 167-02)
- **9 families:** all **pass** (confirm-strict — no override).
- **B (data-viz):** coverage `.tl-table` row **hover polarity inverted** on white (tinted default →
  white hover; should be white default → tinted hover) → `override-needed`, light + system.
- **A (tint-rider):** danger + warning **status-tint pills too weak** on white (10–12% washes vanish)
  → `override-needed`; fix by strengthening the **shared light-lane status-tint tokens** (bg/border
  alpha) at the lane root — TOKEN-02 safe (no per-component rider selector). Hue/text hex unchanged.
- **FLAGGED for user decision:** none — A and B are alpha/value tuning of existing tokens (D-04
  autonomous); no new hue or primitive required.

## Deferred (out of 167's value-lane scope — captured as seeds)
- C-structure: coverage "schema: public" card nesting de-clutter.
- E: `/audit/transactions/:id` content left-pushed at desktop (theme-independent layout bug — possibly
  a nav-overhaul-lane regression).
- D: dark/light/system picker — blocked by `[165-01]` theme-toggle ban; already `THEME-TOGGLE-01`.

## Deviations from plan
- The phase plan anticipated failures in the 9 glass/scrim families; the live review instead surfaced
  failures in a **tint-rider** (status pills, A) and a **data-viz hover polarity** (B). Scope to fix
  both in 167 confirmed with the user. The 9 glass/scrim families all passed.

## Self-Check: PASSED
- `LIGHT-REVIEW.md` exists with all 9 family dispositions + all 3 data-viz surfaces recorded.
- Fail-list enumerated (A + B; FLAGGED: none).
- No example-app / nav-overhaul files staged.
