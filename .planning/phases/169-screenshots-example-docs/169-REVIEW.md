---
phase: 169-screenshots-example-docs
reviewed: 2026-06-14T15:05:13Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - test/threadline/operator_surface/theme_doc_contract_test.exs
  - guides/operator-surface.md
  - README.md
findings:
  critical: 0
  warning: 0
  info: 2
  total: 2
status: clean
---

# Phase 169: Code Review Report

**Reviewed:** 2026-06-14T15:05:13Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** clean

## Summary

Phase 169 (screenshots-example-docs) is a tightly-scoped change across two lanes: (1) admitting the
`desktop-chromium-light` Playwright project to the screenshots + regression e2e suites and emitting
`__light__`-suffixed durable baselines, and (2) documenting the `theme: :dark | :light | :system`
triad in the operator-surface guide + an additive README pointer, locked by a new literal-pin
doc-contract test.

I scoped strictly to the four phase-169 commits (`81ac95b`, `54c7a32`, `e00a5cd`, `04f3663`) via
`git show`, deliberately ignoring the ~30 uncommitted nav-overhaul working-tree files per the scope
instructions. I verified the e2e lane logic against the full surrounding file context and the docs
against actual source (`router.ex`, `auth.ex`, `style.ex`). The new doc-contract test was executed
and passes (5 tests, 0 failures).

**All focus-item concerns were checked and cleared:**

- **Lane selection (`__light__` vs `__default__`):** The infix is gated on
  `testInfo.project.name === "desktop-chromium-light"` — every other project (including
  `desktop-chromium`) falls through to `__default__`. The dark lane cannot emit `__light__`.
- **Light viewport case:** `screenshotViewport()` returns `"1280"` for `desktop-chromium-light`,
  matching the config-level `viewport: { width: 1280, height: 900 }`. Dark and light both emit at
  1280px width but with distinct filename infixes (`home__default__1280.png` vs
  `home__light__1280.png`) — no baseline collision, no rename of existing dark baselines (D-02 honored).
- **`testMatch` widening:** `/operator-(accessibility|screenshots|screenshot-regression)\.spec\.ts/`
  is well-formed and anchored to the literal `.spec.ts` suffix; it admits exactly the three intended
  specs and nothing else.
- **Regression-guard gating + CI-skip:** `test.skip(!!process.env.CI, ...)` is preserved at the
  describe level; the `chromium` project remains skipped in `beforeEach`; the 5-screen set (home,
  timeline-dense, row-history, exports, retention) is intact. The light lane is double-gated (only
  registered when `THREADLINE_E2E_THEME === "system"` AND skipped under CI), so it stays local-only
  and the dark projects are never dragged onto a `:system` mount.
- **Doc-contract test:** `use ExUnit.Case, async: true`, pure `File.read!` + `String.contains?`,
  no `capture_io`/Mix-task/runtime/process spawning. Each literal asserted individually. All five
  pinned literals (`theme:`, `:dark`, `:light`, `:system`, `daytime-use recommendation`) exist in the
  guide; the daytime-use phrase is contiguous on a single line (line 74) after the reflow.
- **Doc factual accuracy:** The `:dark | :light | :system` triad, `:dark` default, and "validated at
  compile time" all match `router.ex:52,63,67` (validation is inside `defmacro` using `__CALLER__`,
  genuinely compile-time). The `:system` "scoped CSS only / `@media (prefers-color-scheme: light)`
  keyed on `data-tl-theme`" framing matches `style.ex:239-240`. "No JS, no localStorage, correct on
  first paint / dead render" matches `auth.ex` (server-rendered `data-tl-theme` assign). No medical
  eye-strain claim — the light lane is framed as a readability/accessibility choice; the astigmatism
  reference is reading-comfort, not a medical assertion.
- **README:** Purely additive (5 lines before the 1-Minute Mount block); the mount snippet is
  byte-identical. The `#theme` anchor resolves to the guide's `### Theme` heading; "pure CSS, no JS"
  matches source.

No blocking or quality-degrading defects found. The two Info items below are non-blocking
observations a maintainer may optionally consider.

## Info

### IN-01: `__light__` baselines are rendered by the `:system` mount under forced light, not a `:light` mount

**File:** `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts:45-46`
(infix derivation), `examples/threadline_phoenix/e2e/playwright.config.ts:14,26`

**Issue:** The `desktop-chromium-light` project is only registered when
`THREADLINE_E2E_THEME === "system"` (the example app is mounted in the `:system` lane), and the
project then forces `colorScheme: "light"`. So the `__light__` durable screenshots actually capture
*the `:system` lane resolving to light via `prefers-color-scheme`* — not a `theme: :light` mount.
For visual-affordance proof these are pixel-equivalent (both resolve through the same
`@media (prefers-color-scheme: light)` token lane in `style.ex`), so this is not a correctness bug.
But the `__light__` filename and the inline comment ("the light project ... emits `__light__`
baselines") could mislead a future maintainer into believing a forced `theme: :light` mount is under
test. This is consistent with the Phase 168 lightLane design and intentional; flagging only for
documentation clarity.

**Fix:** Optional — a one-line comment near the `laneInfix` derivation noting that `__light__`
captures the `:system` mount under a forced-light `colorScheme`, e.g.
`// __light__ = :system mount resolved to light via colorScheme:light (see lightLane in playwright.config.ts)`.

### IN-02: `desktop-chromium-light` relies entirely on config-level viewport with no explicit `beforeEach` branch in either spec

**File:** `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:94-97`
(comment) and `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts:71-83` (beforeEach)

**Issue:** Both `beforeEach` blocks set `setViewportSize` explicitly for `desktop-chromium` (1280x900)
and `mobile-chromium` (375x812) but have no branch for `desktop-chromium-light`, which inherits its
1280x900 viewport from the Playwright project `use` config. This is correct today (the config viewport
matches the explicit dark-lane override), but it introduces a latent coupling: if someone later changes
the explicit `desktop-chromium` beforeEach viewport without also updating the config-level
`desktop-chromium-light` viewport (or vice versa), the light baselines could silently diverge in
dimensions from the dark ones. The regression spec documents this dependency in a comment; the
screenshots spec does not. Non-blocking — current values are consistent (both 1280x900).

**Fix:** Optional — for symmetry and drift-resistance, either (a) add the same explanatory comment to
the screenshots-spec `beforeEach`, or (b) keep a single source of truth for the desktop viewport and
reference it from both the config and the explicit `setViewportSize` calls.

---

_Reviewed: 2026-06-14T15:05:13Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
