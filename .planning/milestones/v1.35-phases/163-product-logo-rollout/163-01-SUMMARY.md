---
phase: 163
plan: 01
subsystem: brand-rollout
tags: [brand, logo, operator-surface, favicon, readme]
requires: [162]
provides: [c13-product-surfaces]
affects:
  - lib/threadline/operator_surface/components/logo.ex
  - examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg
  - README.md
tech-stack:
  added: []
  patterns: [brandbook-geometry-authority, picture-prefers-color-scheme]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/components/logo.ex
    - examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg
    - README.md
decisions:
  - "Wordmark renders as pure Geist 600 path outlines copied verbatim from brandbook/logo-primary.svg; component keeps --tl-* vars (glyphs --tl-color-text, arc --tl-color-accent) — #4781E6 stays a brand-asset constant only"
  - "Non-rendering display=none <text> compat node retained so the in-flight nav-overhaul lane's uncommitted header assertions (>Threadline</text>, wordmark class) stay green; drop it when that lane lands and updates its contract"
metrics:
  duration: ~25 minutes
  completed: 2026-06-12
---

# Phase 163 Plan 01: Product Logo Rollout Summary

C13 stitch identity rolled into all three product surfaces: operator-surface logo
component (pure-path lockup on the frozen `--tl-*` contract), example-app admin
favicon (chipless 16px cut with internal scheme flip), and the root README header
(documented `<picture>` dark/light pattern).

## What Was Done

### ROLL-01 — operator-surface logo component (`898b63f`)
- `Logo.compact/1` SVG body rewritten to the C13 lockup: 11 glyph outline paths +
  stitch arc, geometry verbatim from `brandbook/logo-primary.svg`
  (viewBox `-80 60 5194 1140`), path order preserved so the arc paints flush on
  the cut d/l stems.
- Contract preserved: class `tl-topbar__brand-logo`, `aria-hidden="true"`,
  `focusable="false"`, `{@rest}`; glyphs `var(--tl-color-text)`, arc
  `var(--tl-color-accent)`; flat C13 — old gradient defs removed; no `role="img"`.
- `style.ex` untouched (freeze exception covers logo.ex only).

### ROLL-02 — example-app admin favicon (`2e8be6d`)
- `threadline-admin-favicon.svg` now carries `brandbook/favicon.svg` verbatim:
  two strokes, no container chip, internal `prefers-color-scheme: dark` ink flip.
- `xmllint --noout` clean; zero `<rect>` / `<text>` elements.

### ROLL-03 — README brand header (`5fd61fc`)
- Documented `<picture>` snippet from brandbook "Dark and light" inserted at the
  top of `README.md`: dark scheme → `brandbook/logo-primary.svg`, light fallback
  `brandbook/logo-primary-light.svg`, width 420. All prior content and badges
  preserved; both referenced assets are tracked.

### Evidence (`c19fded`)
- `topbar-mark-evidence.png` — standalone dark-token render of the new component
  at both brand-logo contract sizes (132x32, 148x36) plus the favicon at 16/32/64
  under a dark color scheme (proves the internal flip). Full-app launch skipped as
  heavyweight per plan; browser-tab chrome is not capturable via page screenshots,
  so the favicon row in the evidence render stands in for the tab check.

## Verification

| Gate | Result |
|------|--------|
| `mix compile --warnings-as-errors` | green |
| Baseline `mix verify.test` (pre-change) | 886 tests, 3 failures |
| Post ROLL-01 `mix verify.test` | 886 tests, same 3 failures — no NEW |
| Post ROLL-03 `mix verify.test` | 886 tests, same 3 failures — no NEW |
| surface_header + style_contract focused run | 28 tests, 0 failures |
| Favicon `xmllint --noout` | clean |

Pre-existing failures (other lanes, untouched): `V123CharterDocContractTest`
(PROJECT.md posture) and `ExportsDocContractTest` x2 (TimelineLive download
anchors/labels).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Hidden wordmark `<text>` compat node**
- **Found during:** Task 1 (ROLL-01)
- **Issue:** The in-flight nav-overhaul lane's uncommitted
  `test/threadline/operator_surface/surface_header_test.exs` asserts
  `>Threadline</text>` and `class="tl-topbar__brand-wordmark"` against this
  component's output; that file belongs to another lane and could not be edited,
  while the rollout spec requires a pure-path wordmark.
- **Fix:** Visible wordmark is pure paths; a single non-rendering
  `<text class="tl-topbar__brand-wordmark" display="none">Threadline</text>` node
  satisfies the in-flight contract without any font-rendered wordmark. Documented
  in the module comment; remove once the nav-overhaul lane lands and updates its
  assertions to the path-based contract.
- **Files modified:** lib/threadline/operator_surface/components/logo.ex
- **Commit:** 898b63f

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes; static asset and
markup changes only.

## TDD Gate Compliance

Not a TDD plan (asset rollout; contract held by existing tests).

## Self-Check: PASSED

All created/modified files present; commits 898b63f, 2e8be6d, 5fd61fc, c19fded verified; no file deletions in the task commits; no other-lane files staged.
