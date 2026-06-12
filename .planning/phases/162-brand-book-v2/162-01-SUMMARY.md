---
phase: 162-brand-book-v2
plan: 01
subsystem: brand
tags: [brand, svg, logo, c13, graduation, fontkit, ibm-plex-mono, geist]

# Dependency graph
requires:
  - phase: 161-logo-tournament
    provides: "Winner C13 topstitch-geist (primary/mono/favicon cuts) and hc-gate.mjs"
  - phase: 160-glyph-outline-pipeline
    provides: "text-to-paths.mjs pipeline + glyph-kit-geist-600 (uncut d/l outlines)"
  - phase: 159-brand-audit-and-research
    provides: "HC-1..6 hard constraints and the audit GAP/UP backlog"
provides:
  - "Complete 8-asset C13 logo family in brandbook/ (pure paths, chipless, gated)"
  - "brand-gate.mjs — mechanical HC-1..6 + BOOK-02 verifier for brandbook roles"
  - "Outlined IBM Plex Mono tagline (subtitle + social card only)"
  - "Pruned examples/ set: readme-header + docs-page, pure-path re-cuts"
affects: [162-02 index.html rebuild, 162-03 pressure-test rerun, 163 rollout]

# Tech tracking
tech-stack:
  added: []
  patterns: ["per-glyph pure-path SVGs with data-glyph/data-role tagging", "brand-gate role classification by filename", "ephemeral pinned fontkit@2.0.4 outlining"]

key-files:
  created:
    - brandbook/logo-wordmark.svg
    - brandbook/logo-primary-subtitle.svg
    - .planning/phases/162-brand-book-v2/tools/brand-gate.mjs
  modified:
    - brandbook/logo-primary.svg
    - brandbook/logo-primary-light.svg
    - brandbook/logo-monochrome.svg
    - brandbook/logo-mark.svg
    - brandbook/favicon.svg
    - brandbook/social-card.svg
    - brandbook/examples/readme-header.svg
    - brandbook/examples/docs-page.svg

key-decisions:
  - "Blue reconciliation: arc stays #4781E6 (Stitch Blue) on BOTH dark and light surfaces; #4F8CFF remains the UI/tokens accent; #4781E6 to be documented as an additive raw token in plan 02"
  - "Favicon color mechanism: default Ink #0F1728 strokes + internal <style> prefers-color-scheme:dark flip to Fog #D7DEEA (standalone equivalent of the winner's currentColor design)"
  - "Subtitle tagline tracking: 240 font units (0.24em) on IBM Plex Mono 500, justified to the wordmark ink edges"
  - "Examples pruned to readme-header + docs-page; landing-hero/components/palette/terminal/typography deleted"

patterns-established:
  - "Tagging contract: every painted path carries data-glyph or data-role in {mark, tagline, background, art, copy}"
  - "social-card.svg holds the single sanctioned full-bleed data-role=background path; the literal <rect> ban is absolute everywhere"

requirements-completed: [BOOK-01, BOOK-02]

# Metrics
duration: 17min
completed: 2026-06-12
---

# Phase 162 Plan 01: C13 Graduation Summary

**C13 topstitch-geist graduated into brandbook/ as the full 8-asset pure-path family — verbatim arc geometry, chipless 16px favicon, true one-color mono, tagline isolated to -subtitle + social card — all proven by a new mechanical brand-gate (0 FAIL, 0 WARN).**

## Performance

- **Duration:** 17 min
- **Started:** 2026-06-12T15:40:36Z
- **Completed:** 2026-06-12T15:57:24Z
- **Tasks:** 3
- **Files modified:** 16 (11 written, 5 pruned)

## Accomplishments

- All 8 family files regenerated faithfully from the tournament winner; arc path `M 3164 449 V 260 A 130.5 130.5 0 0 1 3425 260 V 449` is byte-identical in both primaries, the subtitle, the mono, and the social card.
- brand-gate.mjs adapted from hc-gate.mjs: role classification by filename, BOOK-02 corpus-wide tagline isolation, social-card background exemption, favicon `<style>`-aware paint counting. Proved itself by reporting 48 FAILs against the old assets, 0 against the new family.
- Visual render verification via local Playwright (dark/light primaries, 16/32/64px favicon in both color schemes, subtitle, social card, examples) — evidence PNGs in /tmp (phase-dir screenshots not required by this plan; UAT renders belong to plan 02/03).
- Full mechanical suite green: gate exit 0; zero `<text>`; zero `<rect>`; tagline greps in exactly the two sanctioned files; xmllint clean across all 10 SVGs; brandbook total 176KB (≤ 300KB budget).

## Task Commits

1. **Task 1: brand-gate.mjs** - `d912dc2` (feat)
2. **Task 2: core family (primary dark/light, wordmark, mono, mark, favicon)** - `2f1036b` (feat)
3. **Task 3: tagline-bearing assets + examples refresh/prune** - `14ecffc` (feat)

## Files Created/Modified

- `.planning/phases/162-brand-book-v2/tools/brand-gate.mjs` - Mechanical HC-1..6 + BOOK-02 gate, plain Node, exit 0 only on zero FAIL
- `brandbook/logo-primary.svg` - Dark-surface primary: Fog #D7DEEA glyphs, Stitch Blue #4781E6 arc, C13 verbatim
- `brandbook/logo-primary-light.svg` - Designed light rendition: Ink #0F1728 glyphs, #4781E6 arc (see decisions)
- `brandbook/logo-wordmark.svg` - Geist-600 pure paths, intact d/l ascenders (tops at y=295 from the Phase 160 kit), no arc, currentColor
- `brandbook/logo-monochrome.svg` - C13 mono verbatim, exactly one paint value (currentColor), no gradients/opacity
- `brandbook/logo-mark.svg` - Favicon idiom at 4x (64px canvas): blue surfaced arc, currentColor stems/fabric, fabric line paints last so the thread disappears behind it at the crossings
- `brandbook/favicon.svg` - C13 16px cut verbatim (two 1.7-width strokes, no chip), ink default + dark-scheme flip
- `brandbook/logo-primary-subtitle.svg` - The ONLY tagline lockup; outlined Plex Mono 500 caps; aria-label carries the literal string
- `brandbook/social-card.svg` - 1280x640, single sanctioned background path, centered lockup + tagline
- `brandbook/examples/readme-header.svg` - Dark README header specimen, lockup inlined as paths + hairline rule
- `brandbook/examples/docs-page.svg` - Docs chrome wireframe specimen, inlined mark, stroke-only bars (no text/rect/plate)

## Decisions Made

**1. Blue reconciliation (recorded here, applied in docs by plan 02):**
- The stitch arc keeps **#4781E6** everywhere — the user approved this exact rendering at the tournament checkpoint and CONTEXT mandates faithful regeneration.
- **#4F8CFF** stays the UI/tokens accent (`--tl-color-thread-blue` / `--tl-color-accent` untouched; operator-surface tokens untouched).
- **#4781E6** becomes an additive "stitch blue" raw token, to be documented in plan 02's tokens/index.html work.
- Per-surface hexes used: dark primary arc #4781E6 on transparent/dark (5.0:1 vs #0B1020); light primary arc #4781E6 on white (3.78:1, above the 3:1 graphics floor, visually confirmed strong at render — no darkening needed).

**2. Light rendition (explicitly designed, not recolored):**
- Glyph ink **#0F1728** from the light token lane (`--tl-color-text` light), not an inversion of Fog.
- Arc verified on white at render via Playwright screenshot before accepting #4781E6 (the fallback — deliberately darkening the light-surface arc — was not needed).

**3. Favicon color mechanism:**
- Default **Ink #0F1728** stroke attributes + internal `<style>@media (prefers-color-scheme: dark){ path { stroke: #D7DEEA } }</style>`.
- Why: the C13 favicon was designed currentColor (adaptive ink); favicons cannot inherit currentColor from a host page, and the scheme flip is the standalone equivalent. It maximizes stroke contrast at literal 16px in both chromes (~15:1 light, ~11:1 dark) vs 3.78:1 for blue-on-white at 1.7px stroke width. Verified in both schemes via Playwright `--color-scheme=dark`.

**4. Subtitle tagline layout numbers:**
- Tracking: **240 font units = 0.24em** added to the 600-unit mono advance (effective pitch 840) — carried from the prior brand's caps tracking, reads as a measured rule.
- Scale 0.30334, justified to the wordmark ink edges (x 11..4994); cap top 145 units below the wordmark baseline; tagline baseline y=1361.7; tagline ink #8F9DB5 (text-soft).
- Social card embeds the identical subtitle geometry at scale 0.15252, centered (lockup width 760px of 1280).

**5. Social card composition:** lockup + tagline only; the optional positioning line was omitted — the tagline already carries the message, and restraint keeps the card calm and inside budget.

## Example keep/prune table

| File | Verdict | Reason |
|------|---------|--------|
| examples/readme-header.svg | KEEP (re-cut) | README/GitHub is the deciding brand surface (Phase 150 decision); lockup now inlined as paths per GAP-07/UP-09 |
| examples/docs-page.svg | KEEP (re-cut) | HexDocs/docs chrome is a real consuming surface; mark inlined, wireframe re-cut to stroke paths |
| examples/landing-hero.svg | PRUNE | Landing deferred to LANDING-01 — no consuming surface exists |
| examples/components.svg | PRUNE | Component primitives are prose-heavy; plan 02's index.html shows them natively in HTML/CSS — cannot be re-cut to pure paths cheaply or honestly |
| examples/palette.svg | PRUNE | Token swatches are HTML/CSS-native in index.html; the SVG was rect+text throughout |
| examples/terminal.svg | PRUNE | Terminal copy is live text by nature; index.html code blocks cover the role |
| examples/typography.svg | PRUNE | A typography specimen's point is live type; a pure-path version contradicts itself — index.html owns the type story |

Plan 02 must align brand-book.md/index.html references to the surviving set (readme-header, docs-page) and the new logo-wordmark/logo-primary-subtitle filenames.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. (`docs-page.svg`'s old `<image href>` and the old favicon chip were known defects the gate was built to catch, not surprises.)

## Known Stubs

None — no placeholder content; all assets carry final geometry.

## Threat Flags

None — no new network endpoints, auth paths, or trust-boundary surface. T-162-01 mitigated by the gate's HYGIENE check (script/image/foreignObject/http refs FAIL); T-162-SC followed verbatim (pinned fontkit@2.0.4, mktemp prefix, nothing committed).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 (index.html rebuild) can consume the full family by filename; replace-in-place preserved logo-primary/logo-primary-light/logo-mark/logo-monochrome/favicon/social-card references.
- Plan 02 owns: documenting the #4781E6 stitch-blue additive token, the GitHub `<picture>` snippet, the misuse gallery, and doc alignment to the pruned examples set.
- brand-gate.mjs is rerunnable as-is for plan 03's verification suite.

## Self-Check: PASSED

All 12 created/modified files exist, all 5 prunes confirmed absent, all 3 task commits (d912dc2, 2f1036b, 14ecffc) present in git log.

---
*Phase: 162-brand-book-v2*
*Completed: 2026-06-12*
