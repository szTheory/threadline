---
phase: 175-navigation-app-shell-runtime-theme-picker
plan: 02
subsystem: operator-surface
tags: [csp, theme-picker, native-details, css-has, scroll-hardening, accessibility, nav, wave-2]

# Dependency graph
requires:
  - phase: 175-01
    provides: "surface_header_csp_test.exs standing CSP source-string guard (the RED inline-handler refute this plan turns GREEN)"
provides:
  - "CSP-proof operator shell: zero inline on*= handlers; theme picker works under a strict adopter script-src"
  - "Runtime theme picker as visible native radios + explicit Apply theme button with a pure-CSS :has(:checked) non-color active cue"
  - "Native <details>/<summary> mobile nav keyed on [open]; hardened sticky/scroll (scroll-padding-top + overscroll-behavior:contain + 100svh)"
  - "Lifted style-contract theme-toggle ban, replaced by a positive CSP guard test"
affects: [175-03, 175-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Native HTML disclosure (<details>/<summary>) keyed on the [open] attribute selector replaces JS-toggled hidden-checkbox nav (CSP-proof, zero JS)"
    - "Pure-CSS selected-state cue via label:has(:checked) with a non-color dual signal (inset border bar + font weight + accent-soft background)"
    - "scroll-padding-top reconciled to the SAME token as per-row scroll-margin-top so the sticky offset is never double-counted"

key-files:
  created:
    - .planning/phases/175-navigation-app-shell-runtime-theme-picker/175-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/components/surface_header.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/router.ex
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "[175-02]: New visible radio group uses a stable BEM block tl-theme-picker__options / tl-theme-picker__option so the :has(:checked) selector targets it without a markup --active class; the dead tl-segmented__item--active hook is removed entirely."
  - "[175-02]: :has(:checked) active cue uses --tl-weight-medium (500, the reserved active-emphasis weight) + an inset accent-border bar as the non-color signals, with accent-soft as the color half — color is never the only signal; zero new --tl-* tokens."
  - "[175-02]: scroll-padding-top reconciled to calc(var(--tl-header-height-mobile) + var(--tl-space-4)) (identical to .tl-target-row scroll-margin-top) on mobile and topbar-only (--tl-header-height) at >=768px, so the sticky offset is never double-counted."
  - "[175-02 / Rule 3]: the pre-existing phase-142 responsive contract test asserted the old .tl-shell-nav__control:checked / .--open selectors the plan re-points; updated both assertions to the new .tl-shell-nav[open] selector (same authorized test file) to unblock the GREEN gate."

requirements-completed: [NAV-03, NAV-04]

# Metrics
duration: ~15min
completed: 2026-06-17
---

# Phase 175 Plan 02: CSP-Proof Shell + Runtime Theme Picker Summary

**Removed all three inline event handlers from the operator shell (theme onchange, nav onclick, skip-link onclick), rebuilt the theme picker as zero-JS native radios + an explicit "Apply theme" button with a pure-CSS :has(:checked) non-color active cue, converted the mobile nav to a native <details> disclosure keyed on [open], hardened sticky/scroll (scroll-padding-top + overscroll-behavior:contain + 100svh), corrected the router macro doc, and lifted the style-contract theme-toggle ban in favor of a positive CSP guard.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-06-17
- **Tasks:** 2
- **Files modified:** 4 (1 SUMMARY created)

## Accomplishments

- **Turned the Wave-0 CSP RED target GREEN.** `surface_header_csp_test.exs` (the standing gate from Plan 01) now passes: the shell carries no `onclick=`/`onchange=`/any inline `on*=` handler, while the `/theme` POST + `_csrf_token` GREEN regression locks stay green.
- **Rebuilt the theme picker** (surface_header.ex): a `<fieldset>` + `<legend>Theme</legend>` with three VISIBLE native `<input type="radio" name="theme">` (System/Light/Dark, each with an associated `<label for=…>` and `checked={@theme == value}`), plus an explicit `<button type="submit" class="tl-button tl-button--primary">Apply theme</button>` promoted out of `<noscript>`. The hidden `_csrf_token` and `<form action="…/theme" method="post">` are kept verbatim (D-04). Removed every `tl-sr-only`, every `onchange="this.form.submit()"`, and the dead `tl-segmented__item--active` markup class.
- **Converted the mobile nav to native `<details>`/`<summary>`** (surface_header.ex): deleted the hidden `tl-shell-nav__control` checkbox and the `<button onclick=…>Menu</button>`; the `<details class="tl-shell-nav" data-testid="operator-nav-shell" aria-label="Operator surface">` + `<summary class="tl-shell-nav__toggle">Menu</summary>` preserves all `data-testid` hooks, the Find/Verify/Prove IA, and `current={@current}`. No `aria-expanded` on `<summary>`; no shared `name=`.
- **Made the skip link scriptless** (D-26): deleted the `onclick` on `<a href="#tl-main">`; native fragment navigation focuses `<main id="tl-main" tabindex="-1">` (all pages already carry the tabindex, locked GREEN by Plan 01's skip_link_test).
- **Re-pointed the mobile-nav CSS off `:checked`/`.--open` onto `.tl-shell-nav[open]`** (style.ex, D-22): removed the dead `.tl-shell-nav__control` sr-only block and the `:not(.tl-shell-nav__control)` desktop guard; kept the `@media (min-width:768px)` rail-always-visible override, re-pointed.
- **Added the pure-CSS picker active cue** (style.ex, D-05): `.tl-theme-picker__option:has(:checked)` uses `box-shadow: inset 2px 0 0 var(--tl-color-accent-border)` + `font-weight: var(--tl-weight-medium)` + `background: var(--tl-color-accent-soft)` — a non-color dual signal with color as the third (never sole) cue; options are >=44px effective touch targets (`--tl-hit-area` + `--tl-space-*` padding); reads correctly in dark and light via semantic tokens only.
- **Hardened sticky/scroll** (style.ex, D-23/D-24/D-25): `scroll-padding-top` on `.threadline-ui` reconciled to the same token as `.tl-target-row` `scroll-margin-top` (mobile = topbar + collapsed summary band via the shared calc; >=768px = topbar only), `overscroll-behavior: contain` on the shell and on `.tl-subview`, and `min-height: 100svh` on the shell with the existing `100vh` line kept first as the fallback.
- **Corrected the router macro doc** (router.ex, D-08): no longer claims "no runtime theme toggle"; states a runtime dark/light/system theme picker (cookie + plug, server-resolved) is available and that the shell adds no JavaScript and no local storage.
- **Lifted the theme-toggle style-contract ban** (style_contract_test.exs, D-07): removed the two `refute String.contains?(src, "theme-toggle")` assertions and the explaining comment, removed only `"theme-toggle"` from the anti-pattern list (kept `@tailwind`/`shadcn`/`daisyui`/`heroicons`), and added a positive CSP guard test asserting `.tl-shell-nav[open]`, `:has(:checked)`, `scroll-padding-top`, `overscroll-behavior: contain`, `100svh`, and the absence of `.tl-shell-nav__control:checked` / `tl-shell-nav--open` / `tl-segmented__item--active`.

## Task Commits

Each task was committed atomically:

1. **Task 1: remove inline handlers, rebuild theme picker + native details nav** — `b0a8c9c` (feat)
2. **Task 2: CSP-proof shell CSS — [open] nav, :has(:checked) picker cue, scroll hardening + lift ban** — `25a582d` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/components/surface_header.ex` — fieldset/legend theme picker with visible radios + Apply theme button + CSRF; native `<details>` nav; scriptless skip link; zero inline handlers.
- `lib/threadline/operator_surface/style.ex` — `[open]` nav re-point, `.tl-theme-picker__options/__option` + `:has(:checked)` cue, `scroll-padding-top`/`overscroll-behavior: contain`/`100svh` hardening; removed dead `.tl-shell-nav__control` block.
- `lib/threadline/operator_surface/router.ex` — macro doc corrected (runtime picker exists; still no JS/localStorage).
- `test/threadline/operator_surface/style_contract_test.exs` — theme-toggle ban lifted; positive CSP guard test added; phase-142 responsive assertion re-pointed to `[open]`.

## TDD Gate Compliance

Task 2 (`tdd="true"`) followed RED -> GREEN: the positive CSP guard assertions in `style_contract_test.exs` were authored first and confirmed RED (1 failure: `.tl-shell-nav[open]` absent) before the `style.ex`/`router.ex` edits turned them GREEN. The contract test and the source it asserts are interdependent (a source-string contract), so the RED test edit and the GREEN implementation were committed together in `25a582d` rather than as separate `test`/`feat` commits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pre-existing phase-142 responsive contract test asserted the old nav selectors**
- **Found during:** Task 2 (style.ex `[open]` re-point)
- **Issue:** `style_contract_test.exs:445` ("phase 142 responsive primitives…") asserted the old `.tl-shell-nav__control:checked + .tl-shell-nav .tl-shell-nav__panel` and `.tl-shell-nav.tl-shell-nav--open .tl-shell-nav__panel` selectors that the plan explicitly re-points to `[open]`. After the style.ex edit it failed.
- **Fix:** Replaced both stale assertions with a single `.tl-shell-nav[open] .tl-shell-nav__panel` assertion (the plan authorizes editing this test file).
- **Files modified:** `test/threadline/operator_surface/style_contract_test.exs`
- **Commit:** `25a582d`

## Verification

- `mix test test/threadline/operator_surface/surface_header_csp_test.exs` — GREEN (7 tests incl. the previously-RED inline-handler refute; CSP headline).
- `mix test test/threadline/operator_surface/surface_header_test.exs` — GREEN (data-testids, nav IA, single aria-current preserved).
- `mix test test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/theme_doc_contract_test.exs` — GREEN (46 tests, 0 failures).
- `mix test test/threadline/brandbook_token_parity_test.exs` — GREEN (zero new tokens).
- `mix format --check-formatted` on all four files — clean.
- Full `test/threadline/operator_surface/` run: 497 tests, 8 failures — all 8 are the documented Wave-0 RED targets for Plans 03/04 (PageHeaderTest x2, BreadcrumbTest x2, PagerTest x4), unchanged by this plan. The Plan-01 CSP RED target is now GREEN (9 RED -> 8 RED, exactly as designed).

## Known Stubs

None. The picker is fully wired to the existing `/theme` controller route (backend untouched per D-09); the active cue and nav disclosure are pure CSS keyed off real DOM state.

## Issues Encountered

- One pre-existing in-file contract assertion (phase-142 responsive test) referenced the old `:checked`/`.--open` nav selectors; re-pointed to `[open]` (see Deviations). No other surprises.

## Next Phase Readiness

- The standing CSP source-string guard is now fully GREEN and remains the gate for Plans 03–04 shell/form changes.
- Plan 03 (page_header + breadcrumb relabel) and Plan 04 (pager) still have their Wave-0 RED targets to turn GREEN.
- Backend (ThemeController, Auth.on_mount, `data-tl-theme`) is untouched and correct as shipped (D-09).

## Self-Check: PASSED

All four modified files present; commits `b0a8c9c` and `25a582d` verified in git log; SUMMARY.md created.

---
*Phase: 175-navigation-app-shell-runtime-theme-picker*
*Completed: 2026-06-17*
