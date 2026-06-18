---
phase: 178-per-page-flow-stress-pass-all-11-pages
plan: 01
subsystem: operator-surface
tags: [operator-surface, stress, footgun, tier-a, tier-b, wave-0, guard-first, red-scaffold]
requires:
  - "test/threadline/operator_surface/style_contract_test.exs (contrast_ratio/2 + composite/2 engine, selector_block!/media_section helpers)"
  - "test/threadline/operator_surface/component_contract_test.exs (rendered_to_string + =~ idiom, index_of!/2)"
  - "test/threadline/operator_surface/stress_fixtures_test.exs (StressFixtures registry)"
  - "examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts (boundingBox/within-viewport helpers)"
provides:
  - "Tier A RED guard: .tl-container + .tl-home justify-self:center (PAGE-03 + latent twin)"
  - "Tier A RED guard: #1 desktop scroll-padding/scroll-margin reconciliation"
  - "Tier A RED guard: #6 stressed-page child spacing-token source scan"
  - "Tier A permanent guard: #10/#11 per-role secondary-text AA contrast"
  - "Tier A RED guard: reconnect-banner-mounted-once shared-shell contract (SEED-005)"
  - "Tier A RED guard: #4 scrim click-outside dismiss marker (independent of #3)"
  - "Tier A permanent guards: #5/#7/#8/#9 footgun structural halves"
  - "Tier A RED guard: 11 page-story reserved->current 7-path conversion (D-04)"
  - "Tier B spec scaffold: operator-phase-178-uat.spec.ts (centering, footgun sweep, real socket-drop)"
affects:
  - "lib/threadline/operator_surface/style.ex (turned green by Plans 03/04 — NOT edited here)"
  - "lib/threadline/operator_surface/ui.ex (turned green by Plan 05 — NOT edited here)"
  - "lib/threadline/operator_surface/live/*.ex (shared shell — Plan 05 — NOT edited here)"
  - "lib/threadline/operator_surface/stress_fixtures.ex (page stories — Plan 04 — NOT edited here)"
tech-stack:
  added: []
  patterns:
    - "Guard-first RED scaffold (171-177 ratchet ethos, D-05)"
    - "rendered_to_string + =~ / source-scan substring assertions (parser-agnostic, RESEARCH Pitfall 2)"
    - "Tier B test.fixme for RED-by-design unbuilt surface; authored not stubbed"
key-files:
  created:
    - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts"
  modified:
    - "test/threadline/operator_surface/style_contract_test.exs"
    - "test/threadline/operator_surface/component_contract_test.exs"
    - "test/threadline/operator_surface/stress_fixtures_test.exs"
    - "examples/threadline_phoenix/e2e/playwright.config.ts"
decisions:
  - "#1 RED dimension is the DESKTOP reconciliation gap (scroll-margin-top stays mobile while scroll-padding-top goes desktop) — the mobile/overscroll/100svh half was already green from Phase 177"
  - "#6 RED peg is .tl-timeline-fact raw `gap: 2px` (the only off-rhythm stressed-page child gap today); raw margins are already token-clean surface-wide"
  - "#4 RED peg is the inert scrim (no phx-click) — asserted independently of #3's phx-click-away-on-content focus mechanism"
  - "Shell + page-story contracts use source-scans (DB-free, deterministic) rather than full-LiveView renders (which need socket+DB)"
metrics:
  duration: "~25 min"
  completed: "2026-06-18"
  tasks: 3
  files_changed: 4
status: complete
---

# Phase 178 Plan 01: Wave-0 RED Scaffold (guard-first detectors + Tier B spec) Summary

Authored the guard-first RED detectors and the Tier B spec scaffold that Waves 03-05 turn green: PAGE-03 centering (+ its latent Home twin), the footgun structural halves, the 11 page-story ledger conversion target, and the SEED-005 reconnect-banner-mounted-once + real socket-drop contract. Zero production code, zero new runtime dep, zero new token — RED is the deliverable, and every new detector fails on today's surface for a verified, documented reason.

## What was built

**Task 1 — `style_contract_test.exs` (commit 25b25c0):**
- `.tl-container` `justify-self: center` guard (D-09)
- `.tl-home` latent-twin `justify-self: center` guard (RESEARCH Pitfall 1)
- #1 desktop scroll-padding/scroll-margin reconciliation source scan (D-06)
- #6 stressed-page child spacing-token source scan (D-06)
- #10/#11 per-role secondary-text AA contrast coverage (reuses `contrast_ratio/2`)

**Task 2 — `component_contract_test.exs` (commit 40dc1ff):**
- reconnect-banner-mounted-once shared-shell contract over all 11 page LiveViews (D-10/D-11)
- forbidden-anchor guard (no `<body>`/`.phx-disconnected`) (D-11)
- #4 Esc + click-outside scrim dismiss markers, independent of #3 focus hooks (D-06)
- #5/#7/#8/#9 footgun structural detectors (D-07)

**Task 3 — `stress_fixtures_test.exs` + new Tier B spec (commit f0f266b):**
- 11 page-story reserved->current 7-path conversion target (D-04)
- new `operator-phase-178-uat.spec.ts`: PAGE-03 + Home centering within grid column 2 (RESEARCH Pitfall 4), `/audit/*` footgun sweep (#6 within-viewport + #1 sticky-occlusion), real socket-drop via `window.liveSocket.disconnect()` (D-13)
- registered the 178 spec in the `desktop-chromium-light` lane (D-02 dark+light sampling)

## RED-by-design vs GREEN-confirming (assertion ledger)

| Assertion | Tier | State today | Turns green |
|-----------|------|-------------|-------------|
| `.tl-container` `justify-self: center` (PAGE-03, D-09) | A | **RED** (no justify-self) | Plan 03 Task 1 |
| `.tl-home` `justify-self: center` (latent twin, Pitfall 1) | A | **RED** (no justify-self) | Plan 03 Task 1 |
| #1 desktop scroll-padding↔scroll-margin reconciliation (D-06) | A | **RED** (`.tl-target-row` stays `--tl-header-height-mobile` at desktop) | Plan 04 |
| #6 stressed-page child spacing token scan (`.tl-timeline-fact` raw `gap: 2px`, D-06) | A | **RED** (raw `2px`) | Plan 04 |
| #10/#11 per-role secondary-text AA contrast | A | **GREEN-confirming** (text + muted clear 4.5:1 on all chrome surfaces, all 3 lanes) | permanent guard |
| reconnect-banner-mounted-once shared shell (SEED-005, D-10) | A | **RED** (0 banners, no shell) | Plan 05 |
| no `<body>`/`.phx-disconnected` anchor (D-11) | A | **GREEN-confirming** (already absent) | permanent guard |
| #4 scrim click-outside dismiss marker (D-06) | A | **RED** (scrim inert, `aria-hidden` only) | Plan 05 Task 2 |
| #8 nav active-state non-color cue | A | **GREEN-confirming** (`box-shadow` inset present) | permanent guard |
| #9 pager disable-at-edge / hide-at-zero | A | **GREEN-confirming** (`UI.pager` already does both) | permanent guard |
| #5/#7 disabled affordance (toolbar `aria-disabled`+`is-disabled`) | A | **GREEN-confirming** | permanent guard |
| 11 page-story reserved->current 7-path conversion (D-04) | A | **RED** (all still `reserved`) | Plan 04 |
| PAGE-03 + Home centering within column 2 (Pitfall 4) | B | **RED** (`test.fixme`, authored) | Plans 03 |
| `/audit/*` #6 within-viewport sweep | B | active (real-engine sample) | already exercisable |
| #1 sticky-occlusion after scroll | B | **RED** (`test.fixme`, authored) | Plan 04 |
| real socket-drop banner + `[data-tl-mutating]` dim (D-13) | B | **RED** (`test.fixme`, authored) | Plan 05 |

### Why each RED fails for the RIGHT reason (verified, not typos)
- **PAGE-03 / Home centering:** `grep justify-self lib/.../style.ex` returns nothing today; both `.tl-container` (675-678) and `.tl-home` (689-692) carry only `max-width: 1000px; margin: 0 auto` on a grid-item `<main>`.
- **#1 reconciliation:** desktop `scroll-padding-top` uses `--tl-header-height` (style.ex:3897) but `.tl-target-row` `scroll-margin-top` stays at `--tl-header-height-mobile` (style.ex:2647) with no desktop override — a genuine desktop occlusion gap (the mobile/overscroll/100svh half was already green from Phase 177's CSP-proof scroll test, so the new RED is precisely the un-reconciled desktop offset).
- **#6 spacing:** `.tl-timeline-fact` (a timeline-page child) declares raw `gap: 2px` (style.ex:1105), the one off-`--tl-space-*` stressed-page child gap on the surface today.
- **Shell mount:** `grep reconnect_banner lib/.../live/` returns zero references — no LiveView mounts it; no shared shell exists.
- **#4 scrim:** the modal/drawer scrims (`tl-modal-scrim`/`tl-drawer-scrim`, ui.ex:871/945) are `aria-hidden="true"` with NO `phx-click`; dismissal rides `phx-click-away` on the content element (the #3-adjacent mechanism), so the scrim's own click-outside affordance is genuinely absent.
- **Page-story conversion:** all 11 `page.<x>` subjects resolve only to `.reserved` (status `reserved`, `cases: ["warning"]`) — none is a fixture-backed current 7-path story yet.

## Deviations from Plan

None — plan executed exactly as written. The plan explicitly anticipated that some footgun classes (#8, #9, #5/#7, #10/#11, the `<body>`/`.phx-disconnected` guard) would be GREEN-confirming today; those are registered as permanent guards and documented above, as the plan directed.

A discretionary scoping choice (within plan latitude): the #1 RED detector targets the **desktop reconciliation gap** rather than re-asserting the mobile `overscroll-behavior`/`100svh`/mobile-reconciliation that Phase 177's existing CSP-proof scroll test already covers and that pass today. This keeps the new guard genuinely RED for the right reason instead of GREEN-confirming what is already locked. Likewise #6 targets the single real off-token gap (`.tl-timeline-fact`) because raw child margins are already surface-wide token-clean.

## Verification

- `mix test test/threadline/operator_surface/` → **590 tests, 7 failures**, and all 7 are the new Phase-178 RED detectors (4 in style_contract, 2 in component_contract, 1 in stress_fixtures). No pre-existing test regressed.
- `mix format --check-formatted` clean on all three edited test files.
- Tier B spec parses: `playwright test --list` enumerates all 178 cells across all lanes; the spec references `window.liveSocket`, column-2 centering, and the `disconnect()` ladder.
- Tier B spec registered in the `desktop-chromium-light` lane (D-02 dark+light coverage).

## Self-Check: PASSED

- `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` — FOUND
- `test/threadline/operator_surface/style_contract_test.exs` — FOUND (modified)
- `test/threadline/operator_surface/component_contract_test.exs` — FOUND (modified)
- `test/threadline/operator_surface/stress_fixtures_test.exs` — FOUND (modified)
- Commit 25b25c0 (Task 1) — FOUND
- Commit 40dc1ff (Task 2) — FOUND
- Commit f0f266b (Task 3) — FOUND
