---
phase: 164-brand-book-imagery
plan: 02
subsystem: brand
tags: [brand, brandbook, html, theme, light-mode, accessibility]

# Dependency graph
requires:
  - phase: 164-brand-book-imagery
    plan: 01
    provides: "Imagery section + banned strip (panels audited and pinned by this plan)"
  - phase: 162-brand-book-v2
    plan: 02
    provides: "index.html chrome custom properties, gate suite, tokens.css light lane (SSOT)"
provides:
  - "Dark / Light / System preview toggle in the brandbook/index.html header — v1.36 data-tl-theme triad vocabulary"
  - ":root[data-tl-theme=\"light\"] property lane + @media (prefers-color-scheme: light) :root[data-tl-theme=\"system\"] variant, values verbatim from tokens.css .tl-theme-light"
  - "Theme-invariant demonstration panels: every surface-specific specimen pinned to literal grounds"
affects: [165 light-mode strategy, brand-book mini-UAT]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Preview lanes redefine page-local custom properties on :root[data-tl-theme=...]; dark is the no-attribute default"
    - "Demonstration grounds use literal hex values, never theme vars — a chip demonstrates a SPECIFIC surface"
    - "Chrome-embedded lockups use --lockup-ink (Fog on dark, Ink on light) per the designed-not-recolored rule"

key-files:
  created:
    - .planning/phases/164-brand-book-imagery/evidence/toggle-dark-desktop.png
    - .planning/phases/164-brand-book-imagery/evidence/toggle-dark-mobile.png
    - .planning/phases/164-brand-book-imagery/evidence/toggle-light-desktop.png
    - .planning/phases/164-brand-book-imagery/evidence/toggle-light-mobile.png
  modified:
    - brandbook/index.html

key-decisions:
  - "Toggle lives in the topbar as a segmented mono-caps pill (Dark / Light / System); dark default = attribute removed; no persistence by design"
  - "a11y remap inside the light lane: --steel and --text-soft both map to the lane's text-muted #3B4762 (lane #73819C is 3.93:1 on white — AA fail at the sizes these vars carry)"
  - "Kicker numerals switch from Stitch Blue to a --num var (light lane uses accent #1557C0; Stitch Blue is 3.6:1 on Paper)"
  - "Chrome-embedded artwork (hero, topbar, clearspace lockups) flips Fog->Ink via --lockup-ink — page chrome, not a pinned specimen; clearspace bracket uses var(--signal) (#0F8F85 light)"
  - "picture-demo stays driven by the SYSTEM scheme (its <picture> asset choice is) — its dark variant pinned to literals so the page toggle can't strand the asset on the wrong ground"
  - "At <=640px the BRAND BOOK topbar label hides so the toggle fits at 390"

patterns-established:
  - "Pinned vs flipping audit: chips (.chip-dark/.chip-light), banned tiles, favrow/flow labels = pinned; body, TOC, kickers, cards, code blocks, micro callouts, captions = flip"

requirements-completed: [IMG-01]

# Metrics
duration: 9min
completed: 2026-06-12
---

# Phase 164 Plan 02: Brand Book Preview Toggle Summary

**Dark/Light/System preview toggle added to brandbook/index.html: light/system property lanes copied verbatim from tokens.css's .tl-theme-light, a calm mono-caps header control with no persistence, every surface-specific demonstration panel pinned theme-invariant, and a light-chrome AA pass — all gates green at 236KB of 300KB.**

## What flips vs what's pinned

**Flips with the toggle (page chrome):** body bg/text, topbar chrome, hero lockup ink (Fog→Ink, the designed light treatment), TOC, kickers + section headers, asset/specimen/pair card bodies and captions, panels (clear space, thresholds, diagram rules, typo spec), code blocks (`--code-bg` #EEF3FA light), micro callout borders + semantic text colors, links, swatch card text, footer.

**Pinned theme-invariant (demonstrates a specific surface):** all `.chip-dark` grounds (#0B1020/#23304A literals — logo family, misuse gallery, imagery specimens, minsizes, duo, favicon tiles, README/docs/social app strips), `.chip-light` grounds (Paper/Mist palette constants), banned-imagery tiles (#141B2D ground, #FF8585 labels), system-flow labels and favicon size labels (#73819C on pinned grounds), the social-card SVG (own dark plate), and `.picture-demo` (follows the SYSTEM scheme because its `<picture>` asset choice does; dark variant pinned to literals).

## Accessibility fixes (light chrome)

- `--steel` and `--text-soft` map to the light lane's text-muted **#3B4762** (lane value #73819C is 3.93:1 on white — fails AA at the 11–14px sizes these vars carry: kickers, TOC numbers, surface lines, hex labels, captions, code comments, footer).
- Kicker numerals: new `--num` var — Stitch Blue #4781E6 on dark, accent **#1557C0** on light (Stitch Blue is 3.6:1 on Paper).
- Swatch wells: border switched to `--well-border` (rgba ink at 0.14 on light) so the Paper/Mist wells stay visible on white cards.
- Clearspace bracket: `var(--signal)` → #0F8F85 on light (Signal Cyan #4EDFD1 is ~1.5:1 on white).
- Verified: code blocks render #EEF3FA/#C9D3E2/#0F1728; micro callout borders use the light semantic colors (#136C47/#7A5400/#A33434).

## Gate Results

| Gate | Result |
| ---- | ------ |
| brand-gate.mjs (10 SVG files) | PASS — 0 FAIL, 0 WARN |
| Zero fetchable http refs in index.html | PASS — 0 |
| brandbook/ size budget | PASS — 236KB ≤ 300KB |
| Evidence: toggle-{dark,light}-{desktop,mobile}.png | PASS — all four captured + eyeballed (plus per-section crops of every section in both modes) |
| Functional: click light/system/dark, reload | PASS — attribute set/removed, system follows OS scheme, reload returns to dark |
| Staging scope (brandbook/ + .planning/ only) | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Chrome-embedded lockups would vanish on light chrome**
- **Found during:** Task 1 panel audit
- **Issue:** Hero, topbar, and clearspace lockups used literal Fog `#D7DEEA` ink while sitting on flipping page-chrome grounds — invisible on Paper.
- **Fix:** `--lockup-ink` var (Fog dark / Ink light, matching the brand's designed-light-rendition rule); clearspace bracket moved to `var(--signal)`.
- **Files modified:** brandbook/index.html
- **Commit:** 6948289

**2. [Rule 2 - A11y/visibility] Swatch wells and kicker numerals failed on light chrome**
- **Found during:** Task 1 a11y pass
- **Issue:** Well borders (Fog at 0.08 alpha) invisible on white; Stitch Blue kicker numerals 3.6:1 at 12px.
- **Fix:** `--well-border` and `--num` vars with light-lane values (spec item 4 covered steel/text-soft; these two were the remaining failures found by the section-by-section eyeball).
- **Files modified:** brandbook/index.html
- **Commit:** 6948289

## Evidence

- `evidence/toggle-dark-desktop.png` / `toggle-dark-mobile.png` — 1440/390, dark default. Eyeballed: identical chrome to pre-toggle (dark values unchanged by construction), toggle pill calm in the topbar, mobile fits with the BRAND BOOK label hidden.
- `evidence/toggle-light-desktop.png` / `toggle-light-mobile.png` — 1440/390, light. Eyeballed every section via per-section crops: Ink hero on Paper, dark specimen panels pinned, light contour chip stays Paper, banned tiles pinned dark, swatch wells bordered, code blocks/micro callouts on light values, app strips pinned dark, footer readable.

## Next Steps

- **Pending phase gate:** combined mini-UAT — user eyeball of the Imagery section (164-01) plus the preview toggle in both modes (164-02).

## Self-Check: PASSED

- brandbook/index.html — FOUND (`data-tl-theme` lanes + toggle present)
- evidence/toggle-{dark,light}-{desktop,mobile}.png — FOUND, non-empty
- Commits 3835de6 (plan), 6948289 (feat) — FOUND
