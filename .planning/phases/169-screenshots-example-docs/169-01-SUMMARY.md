---
phase: 169-screenshots-example-docs
plan: 01
subsystem: example-app-e2e
tags: [screenshots, playwright, light-mode, e2e, local-only]
requires:
  - "Phase 168 light-render plumbing: desktop-chromium-light Playwright project, THREADLINE_E2E_THEME=system gate, colorScheme:light"
provides:
  - "__light__ durable screenshot lane (12 desktop screens at 1280) beside the dark __default__ baselines"
  - "Light-project regression guard (5 curated screens) with auto-namespaced baselines"
affects:
  - "examples/threadline_phoenix/e2e (test/config wiring only — no lib/ source, no mix alias, no router mount)"
tech-stack:
  added: []
  patterns:
    - "Lane-derived screenshot suffix keyed on testInfo.project.name (desktop-chromium-light → __light__, else __default__)"
    - "Explicit-union testMatch regex (operator-(accessibility|screenshots|screenshot-regression)) keeps the gate readable"
    - "{projectName} snapshotPathTemplate token auto-namespaces light regression baselines (no template change)"
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
decisions:
  - "D-01: teach the desktop-chromium-light project name → 1280 in screenshotViewport(); widen testMatch via explicit alternation"
  - "D-02: NO rename of __default__ — the dark lane keeps its baselines; light is purely additive"
  - "D-03: reuse durableScreenshotNames verbatim (12 screens, desktop-only); NO mobile-chromium-light case"
  - "Lane selection keyed on testInfo.project.name === 'desktop-chromium-light' (preferred — already the viewport key) rather than the env var"
metrics:
  duration: ~10m
  completed: 2026-06-14
---

# Phase 169 Plan 01: Light Screenshot Lane Summary

Added a `__light__` durable screenshot lane and a light-project regression guard by minimally wiring the existing Phase-168 light-render plumbing — no new Playwright project, no mix alias, no example-app mount change, no `lib/` edits.

## What Was Built

**Task 1 — `operator-screenshots.spec.ts` (commit 81ac95b):**
- `screenshotViewport()` gained `case "desktop-chromium-light": return "1280";`, so the light project now produces a durable emit (previously it fell to `default → null` and emitted nothing).
- The durable-emit block now derives the path infix per lane: `__light__` when `testInfo.project.name === "desktop-chromium-light"`, otherwise `__default__`. The dark lane is byte-for-byte unchanged (D-02 — no rename).
- `durableScreenshotNames` reused verbatim — all 12 desktop screens, no mobile-light case.

**Task 2 — `playwright.config.ts` + `operator-screenshot-regression.spec.ts` (commit 54c7a32):**
- Widened the `desktop-chromium-light` project `testMatch` from `/operator-accessibility\.spec\.ts/` to `/operator-(accessibility|screenshots|screenshot-regression)\.spec\.ts/`.
- Left the `lightLane` env gate (line 13), `colorScheme: "light"`, the `viewport`, and the `snapshotPathTemplate` (line 37) untouched — the `{projectName}` token already auto-namespaces the light regression baselines.
- The regression `beforeEach` already admits `desktop-chromium-light` (it is not `chromium`, so it is not skipped, and it inherits the config 1280×900 viewport). Added an explanatory no-op comment documenting the admission; the existing `test.skip(testInfo.project.name === "chromium", ...)` and the `test.skip(!!process.env.CI, ...)` local-only posture (cf0e8e2) are both intact. The same 5 screens (home, timeline-dense, row-history, exports, retention) are guarded — none added or removed.

## Verification

| Check | Path taken | Result |
|-------|-----------|--------|
| `npx tsc --noEmit` | NOT available — `node_modules` present but `typescript`/`tsc` not installed and no `tsconfig.json` exists. Per the plan's verification note this lane is CI-skipped / local-only, so tsc is a non-blocking nice-to-have. Relied on grep-based acceptance criteria + TypeScript-correctness by inspection. | Skipped (tsc unavailable) |
| `grep __light__` (non-comment) in screenshots spec | grep | 1 (≥1) ✓ |
| `__default__` still present | grep | 2 (dark lane unchanged) ✓ |
| `case "desktop-chromium-light"` → "1280" | grep | present ✓ |
| `mobile-chromium-light` anywhere | grep | 0 ✓ |
| testMatch includes screenshots + screenshot-regression | grep | 1 ✓ |
| lightLane gate / colorScheme:light / snapshotPathTemplate unchanged | grep | each = 1, unchanged ✓ |
| `test.skip(!!process.env.CI` preserved | grep | present (line 79) ✓ |
| 5 guarded regression screens unchanged | grep | home, timeline-dense, row-history, exports, retention ✓ |
| Plan diff scope | `git diff --name-only` | only the 3 declared e2e files — no `lib/`, no `mix.exs`, no router, no nav-overhaul files ✓ |

A local `mix verify.example_browser_light` run (which emits the actual PNGs) was not executed in this agent — it requires the running seeded demo app and is local-only by design (cf0e8e2). The wiring is verified by inspection and grep; the artifact emit is the manual/local step the lane is built for.

## Deviations from Plan

None — plan executed exactly as written.

The plan's preferred lane-selection mechanism (`testInfo.project.name === "desktop-chromium-light"`) was chosen over the `THREADLINE_E2E_THEME === "system"` alternative, as the plan flagged this as preferred ("it is already the viewport key").

## Known Stubs

None. No placeholder data, hardcoded empty values, or unwired components introduced. The changes are additive test/config wiring.

## Self-Check: PASSED

- FOUND: examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts (modified)
- FOUND: examples/threadline_phoenix/e2e/playwright.config.ts (modified)
- FOUND: examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts (modified)
- FOUND: commit 81ac95b (Task 1)
- FOUND: commit 54c7a32 (Task 2)
