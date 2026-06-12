---
planted_during: v1.35 Phase 165
trigger_when: User opens the next milestone, or any adopter asks about light mode / theming the operator surface
---

# SEED-004: Milestone v1.36 — Operator Surface Light Mode

Approved strategy (decision [165-01], supersedes [136-01]): `theme: :dark | :light | :system` host config on `threadline_operator_surface/2`, default `:dark`, pure-CSS `data-tl-theme` token lane, no runtime toggle in v1. Full recommendation + 5-phase breakdown: `.planning/phases/165-light-mode-strategy/165-LIGHT-MODE-RECOMMENDATION.md` (archived with v1.35).

## Why This Matters
Closes the v1.35 brand-book UAT gap 1 with researched, user-approved direction; the operator surface seam makes it unusually cheap now (45 tokens, 19 pre-seeded; one stray hardcoded rgba). Opening wave MUST amend style.ex + style_contract_test.exs same-wave (source-first convention).
