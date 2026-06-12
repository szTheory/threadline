---
phase: 162-brand-book-v2
plan: 02
subsystem: brand
tags: [brand, brandbook, html, misuse-gallery, docs, tokens]

# Dependency graph
requires:
  - phase: 162-brand-book-v2
    plan: 01
    provides: "8-asset stitch logo family (pure paths), blue-reconciliation decision, keep/prune examples table, brand-gate.mjs"
provides:
  - "Standalone professional brand book (brandbook/index.html): 7 sections, zero network requests under file://, all 8 assets inlined as pure paths"
  - "Visual misuse gallery: 6 inline-SVG don't specimens + Do reference + numeric small-size thresholds (GAP-12/UP-10 closed)"
  - "HTML-escaped GitHub <picture> snippet + live same-directory <picture> demo (GAP-06/UP-06 closed)"
  - "brand-book.md Logo/Color sections as settled brand truth; README.md inventory accurate"
  - "Additive stitch-blue tokens: raw stitch-blue + semantic logo-arc in both lanes, css + json"
affects: [162-03 pressure-test rerun, 163 rollout]

# Tech tracking
tech-stack:
  added: []
  patterns: ["shared inline-SVG defs with currentColor glyphs and var(--arc) stitch, reused via <use> across every render", "misuse specimens as inline SVG only — never committed asset files"]

key-files:
  created: []
  modified:
    - brandbook/index.html
    - brandbook/brand-book.md
    - brandbook/README.md
    - brandbook/tokens.json
    - brandbook/tokens.css

key-decisions:
  - "Clear space: half the wordmark cap height on all sides for lockups (31% of rendered height; 32px render keeps 10px); one quarter of rendered size for mark/favicon"
  - "Minimum sizes: 120px wide for primary/light/monochrome/wordmark (~26px tall, lowercase ~13px, arc ~3px); 180px for the subtitle lockup (tagline caps ~7px); 16px mark (prefer 24+); favicon designed at 16px, never smaller"
  - "Token additions: raw stitch-blue #4781E6 plus semantic logo-arc #4781E6 in BOTH dark and light lanes (the arc is scheme-invariant); tokens.json version bumped 1.0.0 -> 1.1.0; zero existing values changed"
  - "All 8 family assets render inline via one shared defs block (glyphs currentColor, arc var(--arc)) — page is standalone even without the sibling SVG files; the only file-based loads are the live <picture> demo and the favicon link, both same-directory"
  - "Page is fixed dark (the brand is dark-first); prefers-color-scheme is used by the live picture-demo panel so the browser-selected asset always sits on its designed surface"

patterns-established:
  - "Abuse colors (#D946B5, #FFD23E) exist only as attribute values inside misuse specimens — deliberately off-palette, never documented as tokens"
  - "Tagline appears in index.html prose as sentence case only; the capitalized form stays exclusive to the two sanctioned SVGs (specimen renders use outlined paths, not strings)"

requirements-completed: [BOOK-03, BOOK-05]

# Metrics
duration: 16min
completed: 2026-06-12
---

# Phase 162 Plan 02: Brand Book Rebuild Summary

**brandbook/index.html rebuilt as a standalone dark-first brand book — 7 sections, all 8 logo assets inlined as pure paths, a rendered 6-specimen misuse gallery with numeric thresholds, the GitHub `<picture>` snippet (escaped + live demo), and zero network requests proven by Playwright — with brand-book.md/README.md settled as present-tense truth and the stitch blue added to tokens additively.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-06-12T16:05:47Z
- **Completed:** 2026-06-12T16:21:17Z
- **Tasks:** 2
- **Files modified:** 5

## Section inventory (index.html)

1. **Identity** — essence ("Threadline makes system history followable"), the stitch metaphor told without overclaiming (the thread rises out of one cut stem and dives into the other; the letterforms are the material), feels-like/never-feels-like, anti-traits.
2. **Logo system** — all 8 family assets rendered inline as pure paths with role + surface assignment; clear-space diagram (dashed boundary + cyan half-cap bracket); minimum sizes with live at-size renders; dark/light duo with the #4781E6-on-both-surfaces contrast numbers; HTML-escaped `<picture>` code block (root-README-relative paths) plus a live `<picture>` demo using same-directory paths; favicon story (designed at 16px, scheme-flip ink).
3. **Misuse** (BOOK-05) — one Do reference + six rendered inline-SVG Don'ts; small-size thresholds panel with the four numeric rules.
4. **Color** — palette philosophy, 16 token swatches with hexes, "Two blues, two jobs" reconciliation exactly per plan 01's decision, usage rules.
5. **Typography** — Geist/IBM Plex Mono roles with a live type specimen, the pure-path wordmark story, tracking rules.
6. **Voice & microcopy** — ported faithfully from brand-book.md KEEP sections: preference pairs, writing rules (incl. banned vague words), both say-this/not-this pairs, all four UX microcopy examples.
7. **Applications** — readme-header and docs-page specimens re-rendered from the same shared geometry, social card, sentence-case tagline note.

## Misuse specimens rendered

| # | Specimen | Rendered as |
|---|----------|-------------|
| 1 | Background chip | Mark inside a rounded-square plate (inline `<rect>`) |
| 2 | Icon bolted beside plain text | Inline mark + HTML span "Threadline" in page font |
| 3 | Tagline as primary | Subtitle lockup at 128px — below its 180px floor, tagline collapses |
| 4 | Gradient dependence | Gradient-stroked arc + radial glow blob behind the lockup |
| 5 | Stretch/squash | Lockup with `preserveAspectRatio="none"` at a wrong-aspect box |
| 6 | Off-palette recolor | Lockup in #D946B5 glyphs / #FFD23E arc |

All specimens are inline SVG inside index.html only; `git status brandbook/ | grep -c misuse` = 0 — no antipattern files committed.

## Token additions (exact keys/values)

- `tokens.json` raw.color: `"stitch-blue": "#4781E6"`
- `tokens.json` semantic.dark: `"logo-arc": "#4781E6"`
- `tokens.json` semantic.light: `"logo-arc": "#4781E6"`
- `tokens.css` :root: `--tl-color-stitch-blue: #4781E6;`
- `tokens.css` dark lane: `--tl-color-logo-arc: #4781E6;`
- `tokens.css` light lane: `--tl-color-logo-arc: #4781E6;`
- `tokens.json` version `1.0.0` → `1.1.0` (only non-additive line; carries no hex)

Diff-verified additive: zero removed/modified lines carrying hex values; operator-surface contract untouched.

## Clear-space / minimum-size numbers chosen

- **Clear space (lockups):** half the wordmark cap height (355 of 1140 viewBox units = 31% of rendered height) on all sides; 32px-tall render keeps 10px.
- **Clear space (mark/favicon):** one quarter of rendered size on all sides; 16px context keeps 4px.
- **Minimums:** 120px wide for the four wordmark-bearing assets (≈26px tall; lowercase ≈13px, arc stroke ≈3px); 180px wide for the subtitle lockup (≈48px tall; tagline caps ≈7px); 16px square mark (prefer 24px+); favicon never below its native 16px.
- Rationale documented in both index.html and brand-book.md: the arc renders at 11% of lockup height, so wordmark legibility — not the arc — governs.

## Gate results

- Task 1 gate (xmllint + no http src/href + no url(http + no @import + `<picture>` + misuse): **PASS**
- Task 2 gate (additive-only token hex diff + banned-vocabulary grep on brand-book.md/index.html): **PASS**
- Banned vocabulary also absent from README.md
- Playwright file:// render (dark + light schemes): zero non-file requests, zero page errors; live `<picture>` selects logo-primary.svg in dark and logo-primary-light.svg in light (evidence PNGs in /tmp/brandbook-*.png)
- brand-gate.mjs rerun on brandbook/: 10 files, 0 FAIL, 0 WARN
- tokens.json parses as valid JSON
- brandbook/ total: 208KB ≤ 300KB budget
- Staging limited to brandbook/ + phase dir; pre-existing lib//examples//test/ worktree changes untouched

## Task Commits

1. **Task 1: index.html rebuild** - `abfbbfe` (feat)
2. **Task 2: durable docs + stitch-blue tokens** - `f9898c6` (feat)

## Files Created/Modified

- `brandbook/index.html` - Standalone brand book; embedded CSS, shared pure-path defs, no JS, no external requests
- `brandbook/brand-book.md` - Logo System rewritten as settled truth (roster, numbers, `<picture>`, misuse + thresholds); Color System gains Stitch Blue + reconciliation
- `brandbook/README.md` - Inventory matches the 8-file family + 2 examples; defaults describe the integrated stitch typemark
- `brandbook/tokens.json` - Additive stitch-blue/logo-arc tokens, version 1.1.0
- `brandbook/tokens.css` - Additive stitch-blue/logo-arc custom properties

## Decisions Made

See key-decisions in frontmatter. Notable: the page inlines all eight assets through one defs block so the book itself never depends on the sibling files (the live `<picture>` demo and favicon link are the deliberate, same-directory exceptions that demonstrate file-based usage).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None — all sections carry final content; no placeholders.

## Threat Flags

None — no new network endpoints, scripts, or trust-boundary surface. T-162-03 mitigated: zero http(s) in src/href/url()/@import, verified by grep and by Playwright request monitoring under file://. T-162-04 accepted as planned: zero JavaScript on the page.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03 can rerun pressure-test.md against the finished book; brand-gate.mjs remains green.
- Render evidence for UAT exists at /tmp/brandbook-*.png (dark/light tops, picture demo both schemes, misuse gallery, clear space, color, applications, full page).
- ROLL-03 (applying the `<picture>` snippet to the root README) stays optional Phase 163; the snippet is documented verbatim in both index.html and brand-book.md.

## Self-Check: PASSED

All 5 modified files and the SUMMARY exist on disk; both task commits (abfbbfe, f9898c6) present in git log.
