---
phase: 143-accessibility-consistency-sweep-regression
requirements: [POLISH-A11Y]
source: auto-mode continuation after Phase 142
date: 2026-06-04
---

# Phase 143 Context

## Goal

Establish the final accessibility and regression baseline for the v1.31 operator surface:

- interactive primitives meet accessibility baseline for focus order, focus-visible, contrast, and ARIA;
- remaining Phase 134 audit findings are either closed by prior phases or explicitly closed in this final sweep;
- final screenshots are diffed against the Phase 134 baseline with every delta explained;
- a lightweight screenshot guard is wired into the existing Playwright / CI browser lane.

## Inputs

- `.planning/milestones/v1.31-UI-AUDIT.md`
- `.planning/milestones/v1.31-screenshots/baseline/*.png`
- Phase 135-142 summaries, review, and verification artifacts
- `lib/threadline/operator_surface/style.ex`
- `lib/threadline/operator_surface/components/surface_header.ex`
- `lib/threadline/operator_surface/live/*.ex`
- `test/threadline/operator_surface/style_contract_test.exs`
- `examples/threadline_phoenix/e2e/tests/*.spec.ts`
- `examples/threadline_phoenix/e2e/playwright.config.ts`
- `.github/workflows/ci.yml`
- `mix.exs`

## Locked Scope

Phase 143 owns:

- F-901: muted text contrast verification and token lift if needed.
- F-902: status/verdict meaning must not rely on link-blue color alone.
- F-903: focus order, focus-visible, and ARIA sweep over interactive primitives.
- Final closure audit for all Phase 134 findings.
- Screenshot final set and diff report against the Phase 134 baseline.
- Screenshot-diff guard connected to `mix verify.example_browser` / Playwright / CI.
- Existing browser-suite red specs that block final regression confidence when they are stale assertions around already-shipped flows/copy/selectors.

Phase 143 does not own:

- New product flows beyond already-shipped v1.31 behavior.
- A light theme, Tailwind/CSS architecture switch, new design framework, or new browser route.
- Broad dependency churn. Add a visual-diff dependency only if the guard cannot be made credible with existing Playwright snapshot capabilities.
- Reopening already-completed visual design work except where it fails the final a11y/regression gate.

## Current Evidence

After Phase 142:

- `mix test test/threadline/operator_surface/style_contract_test.exs` passes: 17 tests, 0 failures.
- `operator-responsive-mobile-first.spec.ts` passes standalone and inside `mix verify.example_browser`.
- `mix verify.example_browser` remains red with 93 passed / 18 failed.

Full-suite failures are:

- `operator-earned-flows.spec.ts` EF1: Home record-first form remains on `/audit` instead of `/audit/rows/...`.
- `operator-earned-flows.spec.ts` EF4: Home correlation form remains on `/audit` instead of `/audit/timeline`.
- `operator-home-nav-mobile.spec.ts`: stale assertion expects Home has zero forms, but Phase 140 intentionally added workflow forms.
- `operator-screenshots.spec.ts`: strict-mode `[REDACTED]` ambiguity and stale empty-state copy.
- `operator.spec.ts`: strict-mode `[REDACTED]` ambiguity.

These failures must be resolved in Phase 143 because the final screenshot/CI guard must start from a green browser lane.

## Decisions

- D-01: Accessibility baseline targets WCAG 2.1 AA for text contrast, focus visible, accessible names, ARIA states, keyboard reachability, and no keyboard traps.
- D-02: Contrast checks can be token/source-level for stable theme pairs and browser-level for representative computed styles.
- D-03: Focus/ARIA checks should be Playwright runtime assertions, not screenshots.
- D-04: Existing screenshot specs should be repaired, not replaced, where they already capture the Phase 134 state matrix.
- D-05: Final screenshot diff may record intentional deltas in a Markdown report; the CI guard must provide an automated failure signal for future unexpected drift.
- D-06: Prefer Playwright snapshot assertions for the lightweight guard because Playwright is already installed and wired through `mix verify.example_browser`.
- D-07: Do not commit generated `test-results` artifacts; final screenshots and diff report belong under `.planning/milestones/v1.31-screenshots/final/` and the Phase 143 directory.

## Success Criteria Mapping

| Roadmap criterion | Phase 143 delivery |
|---|---|
| Interactive primitives meet accessibility baseline | ExUnit source contracts plus Playwright a11y/focus spec |
| Remaining Phase-134 audit findings closed | `143-AUDIT-CLOSURE.md` with finding-by-finding status |
| Final screenshot set diffed against baseline | final screenshot artifacts plus `143-SCREENSHOT-DIFF.md` |
| Screenshot-diff guard in Playwright/CI lane | Playwright guard spec and existing `mix verify.example_browser` / CI browser job integration |

