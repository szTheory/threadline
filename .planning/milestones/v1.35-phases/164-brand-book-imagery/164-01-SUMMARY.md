---
phase: 164-brand-book-imagery
plan: 01
subsystem: brand
tags: [brand, brandbook, html, imagery, diagrams, svg]

# Dependency graph
requires:
  - phase: 162-brand-book-v2
    plan: 02
    provides: "brandbook/index.html section structure, misuse-gallery craft bar, brand-gate.mjs, palette tokens"
provides:
  - "Imagery section (04) in brandbook/index.html: 4 inline-SVG acceptable specimens drawn in the brand language, each with a one-sentence usage caption"
  - "Evidence path (line map), timeline-with-depth rail, contour cross-section on a light Paper panel, labeled system flow (request -> action -> transaction -> change)"
  - "Banned-imagery strip: 7 crossed-out linework glyphs mirroring brand-book.md's banned list (stock people, courtrooms, locks, shields, police tape, server racks, unlabelled graphs)"
  - "Diagram rules panel restating brand-book.md's kit: lines/points/labels/layered rails, domain nouns, sparse arrows, actual flow over decorative complexity"
affects: [165 light-mode strategy, future docs/blog diagram art]

# Tech tracking
tech-stack:
  added: []
  patterns: ["specimen linework is pure <path> elements only — dots drawn as zero-length round-cap strokes (M x y h 0.01)", "diagram labels are absolutely-positioned HTML spans over the SVG (percent top + translateY), never SVG <text>"]

key-files:
  created:
    - .planning/phases/164-brand-book-imagery/evidence/imagery-desktop.png
    - .planning/phases/164-brand-book-imagery/evidence/imagery-mobile.png
  modified:
    - brandbook/index.html

key-decisions:
  - "Section placed as 04 Imagery, between Misuse (03) and Color (05); downstream sections and TOC renumbered to 01-08"
  - "Heading voice: 'Lines, not lock icons.' — matches the existing section heading register"
  - "Specimen accents: Thread Blue #4F8CFF carries the followable line / probe / action; Signal Cyan #4EDFD1 marks change ticks and route endpoints; Stitch Blue stays exclusive to the mark's arc"
  - "Contour cross-section is the light-panel specimen (Paper chip) since imagery ships into light docs surfaces; probe blue holds the 3:1 graphics floor on Paper"
  - "System flow labels are HTML spans (page content, like the misuse gallery), keeping all SVG linework pure paths; activity column sits at x=380 so verticals clear the label band at both 1440 and 390 widths"
  - "Banned strip rendered as 7 tight glyph tiles with a danger-red strike — same render-the-abuse-inline-only treatment as the misuse gallery; no antipattern asset files ship"

patterns-established:
  - "Imagery specimens are reference drawings meant to be copied as starting points for real diagrams — the section says so explicitly in the lede"

requirements-completed: [IMG-01]

# Metrics
duration: 10min
completed: 2026-06-12
---

# Phase 164 Plan 01: Brand Book Imagery Summary

**Visual Imagery section added to brandbook/index.html: four captioned inline-SVG specimens (evidence path, timeline with depth, light-panel contour cross-section, labeled request→action→transaction→change system flow), a 7-glyph banned-imagery strip, and the diagram rules — all gates green at 232KB of the 300KB budget.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-12T20:52:20Z
- **Completed:** 2026-06-12T21:02:15Z
- **Tasks:** 2/2
- **Files modified:** 3 (brandbook/index.html, 2 evidence PNGs) + 2 planning docs

## Accomplishments

- Closed UAT gap 2: brand-book.md's "Imagery And Diagrams" guidance is now visualized in index.html at the misuse-gallery craft bar.
- Four acceptable specimens, each one-sentence captioned with when to use it (docs hero / blog headers / light guides / architecture explainers) and a surface line, in the established `.asset` card treatment.
- At least one specimen on a light panel: the contour cross-section sits on Paper, proving the imagery language works on light docs surfaces.
- Don't strip mirrors brand-book.md's banned list exactly — no rules invented; the diagram rules panel restates the brand-book kit verbatim in voice.
- TOC and section numbering extended cleanly to 01–08.

## Gate Results

| Gate | Result |
| ---- | ------ |
| `imagery|illustration` present in index.html | PASS |
| Zero fetchable http refs (src/href/url) | PASS |
| brand-gate.mjs (10 SVG files) | PASS — 0 FAIL, 0 WARN |
| brandbook/ size budget | PASS — 232KB ≤ 300KB |
| Staging scope (brandbook/ + .planning/ only) | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] System-flow label/arrow collision**
- **Found during:** Task 2 (screenshot eyeball)
- **Issue:** The vertical flow arrows at x=170 crossed through the "TRANSACTION" HTML label at both 1440 and 390 widths.
- **Fix:** Shifted the activity column (dots, arrows, transaction span, drops, ticks) right to x=380 so all verticals clear the label band at both breakpoints; re-verified with close crops.
- **Files modified:** brandbook/index.html
- **Commit:** 1ff102b (fix folded into the Task 1 commit, which was made after visual verification)

## Evidence

- `evidence/imagery-desktop.png` — 1440px, full section: 2×2 specimen grid, rules panel, banned strip. Eyeballed: light panel renders, labels aligned, nothing broken.
- `evidence/imagery-mobile.png` — 390px, single-column stack. Eyeballed: specimens scale, banned strip wraps to tiles, flow labels clear.

## Next Steps

- **Pending mini-UAT:** user eyeball of the Imagery section is the phase gate. IMG-01 traceability set to "Complete — pending mini-UAT".

## Self-Check: PASSED

- brandbook/index.html — FOUND (imagery section present)
- evidence/imagery-desktop.png, evidence/imagery-mobile.png — FOUND, non-empty
- Commit 1ff102b — FOUND
