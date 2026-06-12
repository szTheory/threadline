---
phase: 165-light-mode-strategy
plan: 01
subsystem: brand
tags: [light-mode, theming, research, decision, operator-surface]

requires:
  - phase: 162-brand-book-v2
    provides: "UAT gap 1 (dark/light posture question) + brandbook light token lane"
provides:
  - "165-LIGHT-MODE-RECOMMENDATION.md — approved strategy: theme: :dark|:light|:system host config, dark default, pure-CSS data-tl-theme lane, no toggle v1"
  - "Superseding decision [165-01] over [136-01]; v1.36 'Operator Surface Light Mode' seeded with 5-phase breakdown"
affects: [v1.36]
---

# Plan 165-01 Summary — Light-mode strategy: researched, recommended, decided

## Outcome

**User decision (2026-06-12, checkpoint): "Approve (Recommended)"** — the recommendation is accepted as the seed for milestone v1.36 "Operator Surface Light Mode". v1.35 closes with no UI changes; the dark-only contract stays physically intact until v1.36's opening wave amends it source-first.

**Decision [165-01], superseding [136-01]:** Dark remains the Threadline operator-surface default and brand-primary mode. Light and system-following modes become supported via host configuration (`theme: :dark | :light | :system` on `threadline_operator_surface/2`, default `:dark`), implemented as a pure-CSS token lane under `.threadline-ui[data-tl-theme=...]` with scoped `color-scheme`. The `theme-toggle` ban stands — no runtime toggle in v1; the documented upgrade path is a Backpex-style cookie + plug if adopter demand materializes. The light lane is designed, never recolored. The `prefers-color-scheme` / `color-scheme: light` contract-test bans are amended in v1.36's opening wave, same-wave with the style.ex change, per the v1.31 source-first convention.

## What was done

- Three parallel research lanes, all committed with cited sources:
  - `165-RESEARCH-ECOSYSTEM.md` (a193d1f) — Phoenix/LiveView idioms; mounted-library constraint analysis (Backpex precedent; localStorage rejected: FOUC + CSP).
  - `165-RESEARCH-LESSONS.md` (931ac9f) — cross-ecosystem case studies; "designed not recolored" (Grafana lesson); brand light lane contrast-validated computationally; honest eye-strain evidence grading.
  - `165-RESEARCH-SURFACE.md` (715b2e9) — exact change surface: 45 tokens (19 seeded / 26 designed), one stray rgba (style.ex:489), 7 contract-test refutes, component risk concentration in the status-tint system, v1.36 sizing.
- Synthesis: `165-LIGHT-MODE-RECOMMENDATION.md` (c6dd4b9) — single coherent recommendation with rejected-alternatives notes and the 5-phase v1.36 breakdown.
- No lib/, contract-test, or brandbook changes in this phase (verified: nothing staged outside the phase dir).

## Requirements

- LIGHT-01 satisfied (three cited research lanes covering ecosystem, cross-ecosystem lessons, and the Threadline change surface).
- LIGHT-02 satisfied (single recommendation + explicit user decision recorded above, verbatim option label "Approve (Recommended)").

## Handoff to v1.36

Seed context = `165-LIGHT-MODE-RECOMMENDATION.md` (the 5-phase breakdown is the draft roadmap). Open with `/gsd-new-milestone` when chosen; the opening wave MUST pair the style.ex light lane with the `style_contract_test.exs` amendment (seven refutes → theme-aware assertions; AA mirror test needs alpha-tint parsing in `color_tokens/1`).
