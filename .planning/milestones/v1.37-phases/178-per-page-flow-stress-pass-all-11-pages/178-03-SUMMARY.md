---
phase: 178-per-page-flow-stress-pass-all-11-pages
plan: 03
subsystem: operator-surface
tags: [operator-surface, page-03, centering, grid, justify-self, latent-twin, tier-a, tier-b]
requires:
  - "test/threadline/operator_surface/style_contract_test.exs (Wave-0 RED justify-self guards for .tl-container + .tl-home)"
  - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts (Wave-0 Tier B centering scaffold, test.fixme)"
provides:
  - ".tl-container justify-self: center (PAGE-03 grid-native centering, D-09)"
  - ".tl-home justify-self: center (latent-twin fix, RESEARCH Pitfall 1 / Open Q1)"
  - "Tier A justify-self guards GREEN for both .tl-container and .tl-home"
  - "Tier B centering specs active + passing: transaction + Home centered within grid column 2 at 1024 + 1440 (dark + light)"
affects:
  - "lib/threadline/operator_surface/style.ex (.tl-container:675-679, .tl-home:690-694 — two one-line additions)"
  - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts (4 centering cells un-fixme'd, column-2 measurement corrected)"
tech-stack:
  added: []
  patterns:
    - "Grid-native centering: justify-self: center on a max-width-capped grid item (margin: 0 auto does NOT center a grid item under default justify-self: stretch)"
    - "Tier B geometry assertion measures within the grid column 2 TRACK derived from .threadline-ui computed grid-template-columns, never raw viewport/2 (RESEARCH Pitfall 4)"
key-files:
  created: []
  modified:
    - "lib/threadline/operator_surface/style.ex"
    - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts"
decisions:
  - "Home latent twin (.tl-home) fixed in the SAME task as .tl-container with its own Tier A guard — the explicit, visibly-noted extension the planner/RESEARCH directed (RESOLVED: fold in), neither silently dropped nor silently expanded"
  - "Tier B centering tolerance = 24px (D-14 discretion): headroom for sub-pixel rounding + scrollbar gutter; assertion measures symmetric left/right gutters of the capped <main> within grid column 2"
  - "Corrected a Pitfall-4 false-pass latent in the Wave-0 scaffold: the capped <main> IS the grid item (#tl-main carries tl-page tl-container), so measuring .tl-container against #tl-main compared an element to itself (gutters always 0). Column 2 track is now derived from .threadline-ui's computed grid-template-columns + columnGap"
  - "D-09b inner tl-short-content alignment NOT touched — it is [informational]/opportunistic, not a tracked PAGE-03 acceptance requirement; scope held tight"
metrics:
  duration: "~20 min"
  completed: "2026-06-18"
  tasks: 2
  files_changed: 2
status: complete
---

# Phase 178 Plan 03: PAGE-03 transaction-page centering (+ Home latent twin) Summary

Fixed the PAGE-03 desktop centering bug the grid-native way: `justify-self: center` on `.tl-container`, keeping `max-width: 1000px`. Applied the identical one-line fix to `.tl-home` — RESEARCH confirmed it is a latent twin of the same bug (same capping CSS on a grid-item `<main>`). This turned the two Wave-0 Tier A `justify-self` guards GREEN and made the Tier B centering geometry cells pass on real Chromium. Markup untouched, zero new `--tl-*` token, zero new dep.

## What was built

**Task 1 — `style.ex` `justify-self` fix (commit 29dc8bd):**
- `.tl-container` (style.ex:675-679) now carries `justify-self: center;` alongside `max-width: 1000px` — the PAGE-03 fix (D-09).
- `.tl-home` (style.ex:690-694) now carries the same `justify-self: center;` — the latent twin (RESEARCH Pitfall 1 / Open Q1, RESOLVED: fold in). **This is the deliberate, visibly-noted extension**, fixed in the same task with its own Tier A guard, per the explicit planner/RESEARCH decision — not a silent expansion, and the Home twin is not silently dropped.
- `margin: 0 auto` retained in both blocks (harmless on a grid item; the centering now comes from `justify-self`).
- No `transaction_live.ex` / `start_live.ex` markup edit; no new `--tl-*` token.

**Task 2 — Tier B centering specs finalized (commit 31db561):**
- Un-`.fixme`'d the 4 PAGE-03 centering cells (transaction × 1024/1440 + Home × 1024/1440); they are now active and passing.
- Corrected a Pitfall-4 false-pass latent in the Wave-0 scaffold: the capped `<main>` (`#tl-main`, class `tl-page tl-container` / `tl-page tl-home`) IS itself the grid item at `grid-column: 2`, so the scaffold's `expectCenteredWithinColumn(.tl-container, #tl-main)` compared an element to itself (gutters always 0). The helper now derives the **grid column-2 track** from `.threadline-ui`'s computed `grid-template-columns` + `columnGap` + `paddingLeft`, then asserts the `<main>` box sits with symmetric gutters inside that track.
- Tolerance: **24px** (D-14 discretion) — headroom for sub-pixel rounding and the scrollbar gutter.
- The `#1` scroll-trap (line 210, Plan 04) and the real socket-drop (line 254, Plan 05) `test.fixme` markers are left untouched — not this plan's scope.
- NO pixel-diff; geometry assertions only.

## RED -> GREEN delta

| Assertion | Tier | Before (Wave-0) | After (this plan) |
|-----------|------|-----------------|-------------------|
| `.tl-container` carries `justify-self: center` (D-09) | A | RED (no justify-self) | **GREEN** |
| `.tl-home` carries `justify-self: center` (latent twin) | A | RED (no justify-self) | **GREEN** |
| transaction `.tl-container` centered within column 2 @1024/1440 | B | `test.fixme` (RED-by-design) | **active + PASS** (dark + light) |
| Home `.tl-home` centered within column 2 @1024/1440 | B | `test.fixme` (RED-by-design) | **active + PASS** (dark + light) |

The two remaining `style_contract_test.exs` failures (#6 `.tl-timeline-fact` raw `gap: 2px`, #1 desktop scroll-margin reconciliation) are Plan-04-owned RED scaffolds and stay RED by design — verified they are exactly those two and not regressions from this plan.

## Tier B real-engine confirmation

Ran via the `run-e2e.sh` harness (builds + seeds the example app, starts Phoenix on a live Postgres, runs Playwright):

- **Dark lanes** (`chromium`, `desktop-chromium`, `mobile-chromium`): `12 passed (7.2s)` — all 4 centering cells × 3 lanes.
- **Light lane** (`THREADLINE_E2E_THEME=system`, `desktop-chromium-light`, `colorScheme: light`): `4 passed (2.1s)`.

This is true real-engine confirmation that the `justify-self: center` fix centers content within grid column 2 — not just a source-scan.

## Deviations from Plan

**[Rule 1 — Bug] Corrected a latent Pitfall-4 false-pass in the Wave-0 Tier B scaffold.**
- **Found during:** Task 2 (un-fixme-ing the centering cells).
- **Issue:** The Wave-0 helper measured `.tl-container` against `#tl-main`, but per CONTEXT D-08 the capped `<main>` element IS `#tl-main` and IS the grid item (it carries `tl-page tl-container`). Comparing it to itself yields gutters of 0 — the cell would have "passed" even with the left-push bug present (a false green).
- **Fix:** Derived the grid column-2 track from the grid container (`.threadline-ui`) computed `grid-template-columns` (last track = content column), `columnGap`, and `paddingLeft`, then asserted symmetric gutters of the `<main>` within that track. This is the RESEARCH Pitfall-4-correct measurement ("within column 2, not raw viewport/2").
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts`.
- **Commit:** 31db561.
- This stays within Task 2's mandate ("measure within grid column 2, NOT raw viewport/2"); it makes the authored cell actually test the thing it claims to.

D-09b (inner `tl-short-content` wrapper alignment) was deliberately NOT touched — it is `[informational]`/opportunistic and explicitly "not required for PAGE-03 acceptance." Scope held tight (prohibition: no silent expansion).

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs` → 41 tests, **2 failures**, both Plan-04-owned (#1/#6); the two `justify-self` guards (`.tl-container`, `.tl-home`) are GREEN.
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted lib/threadline/operator_surface/style.ex` clean.
- `style.ex` diff is exactly the two `justify-self: center` lines — no new `--tl-*` token, brand-token parity unaffected.
- `git diff` on `transaction_live.ex` / `start_live.ex` empty — markup untouched (D-09).
- Tier B: 12 dark + 4 light centering cells PASS on real Chromium (see above). The `#1`/socket-drop `test.fixme` markers preserved for Plans 04/05.
- Capture / semantics layers untouched; no new dependency; CSP-proof (no inline JS, layout-only CSS property).

## Self-Check: PASSED

- `lib/threadline/operator_surface/style.ex` — FOUND (`.tl-container` + `.tl-home` both carry `justify-self: center`)
- `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` — FOUND (4 centering cells active, passing)
- Commit 29dc8bd (Task 1) — FOUND
- Commit 31db561 (Task 2) — FOUND
