---
phase: 160-glyph-outline-pipeline
plan: 01
subsystem: brandbook
tags: [fontkit, svg, woff2, geist, playwright, glyph-outlines, gpos-kerning]

# Dependency graph
requires:
  - phase: none (fonts vendored previously in priv/fonts/)
    provides: geist-500/600 woff2 with OFL notices; existing e2e Playwright install
provides:
  - Deterministic fontkit text-to-outline pipeline (tools/text-to-paths.mjs)
  - glyph-kit-geist-{500,600}.{svg,json} — per-glyph paths + metadata for "Threadline"
  - Per-glyph kerned x-offsets and measured l/T stem widths for Phase 161 motif work
  - Overlay specimen + 2x screenshot evidence proving outline fidelity (GLYPH-02)
  - Post-archive regeneration copy under brandbook/tools/
affects: [161-logo-candidates, 162-final-assets, brandbook]

# Tech tracking
tech-stack:
  added: [fontkit@2.0.4 (ephemeral only, never committed)]
  patterns:
    - "Ephemeral npm deps via mktemp prefix + NODE_PATH + createRequire (ESM import ignores NODE_PATH)"
    - "One <path> per glyph, glyph-local d + translate(x 0) transform exposing kerned offset"
    - "Canonical 2-decimal formatter (toFixed + trailing-zero strip, -0 normalized) for byte-determinism"

key-files:
  created:
    - .planning/phases/160-glyph-outline-pipeline/tools/text-to-paths.mjs
    - .planning/phases/160-glyph-outline-pipeline/tools/capture-overlay.mjs
    - .planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-500.svg
    - .planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-500.json
    - .planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-600.svg
    - .planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-600.json
    - .planning/phases/160-glyph-outline-pipeline/overlay-specimen.html
    - .planning/phases/160-glyph-outline-pipeline/overlay-evidence-2x.png
    - brandbook/tools/text-to-paths.mjs
    - brandbook/tools/README.md
  modified: []

key-decisions:
  - "fontkit resolved via createRequire so NODE_PATH works under ESM; clear error names the canonical install command"
  - "Overlay baseline math: line-height = (ascent - descent) x scale = 156px gives zero half-leading, so live-text baseline and SVG baseline (ascent x scale = 120.6px) coincide at top:0"
  - "Counters section uses <use> against shared <defs> so kit path data appears once per weight in the specimen"
  - "Kit SVGs inlined into the specimen at build time (fetch unreliable over file://); only root-tag presentation attributes added, path data byte-identical to committed kits"

patterns-established:
  - "Ephemeral dependency install: FONTKIT_DIR=$(mktemp -d); npm install --prefix; NODE_PATH + createRequire"
  - "Playwright reuse from phase scripts: module.createRequire(e2e dir) + require('@playwright/test')"

requirements-completed: [GLYPH-01, GLYPH-02, GLYPH-03]

# Metrics
duration: ~45min across two sessions (first session stalled mid-Task-2 verification; resumed session ~10min)
completed: 2026-06-12
---

# Phase 160 Plan 01: Glyph Outline Pipeline Summary

**Deterministic fontkit@2.0.4 pipeline converting Geist 500/600 woff2 into per-glyph "Threadline" SVG paths with shaped GPOS kerning, proven byte-identical on regeneration and visually matched against live-font browser renders at 2x.**

## Performance

- **Duration:** ~45 min across two sessions (first session committed Tasks 1-2 artifacts then stalled during Task 2 verification; resumed session re-ran all gates and completed Tasks 3-4 in ~10 min)
- **Started:** 2026-06-11T22:03:31Z (first task commit) / resumed 2026-06-12T00:43:17Z
- **Completed:** 2026-06-12T00:52:00Z
- **Tasks:** 4/4
- **Files modified:** 10 created

## Accomplishments

- `tools/text-to-paths.mjs`: ESM script resolving fontkit via createRequire + NODE_PATH (ephemeral mktemp install, nothing committed), shaping with `font.layout()` for real GPOS kerning, serializing one `<path>` per glyph with 2-decimal y-flipped coordinates through a single canonical formatter.
- Glyph kits for both weights: 10 glyphs each, JSON metadata with per-glyph kerned x-offsets and measured stem widths (500: l=106/T=108; 600: l=128/T=130 font units) for Phase 161 stroke matching.
- Determinism proven: fresh fontkit@2.0.4 install into mktemp, regeneration into a temp dir, `cmp` byte-identical for all four kit files.
- Overlay evidence (GLYPH-02): live Geist webfont (magenta 50%) vs inlined kit outlines (cyan 50%) baseline-aligned at 120px; 4x inspection crops showed only hairline antialiasing fringes, no glyph-shaped displacement. e/a/d counters render as holes on dark and white backgrounds (GLYPH-03).
- Regeneration copy under `brandbook/tools/` (byte-identical cmp) with README pinning fontkit@2.0.4 and documenting the CLI/output contracts; no other brandbook/ path touched.

## Task Commits

Each task was committed atomically:

1. **Task 1: tools/text-to-paths.mjs (fontkit pipeline script)** - `7815e80` (feat) — committed in the prior session together with Task 2 outputs
2. **Task 2: Geist 500/600 glyph kits + determinism proof** - `7815e80` (feat) — same commit; full verification gate re-run and passed in this session
3. **Task 3: Overlay specimen + 2x screenshot evidence** - `ea25e34` (feat)
4. **Task 4: Regeneration copy under brandbook/tools/** - `ac837c7` (feat)

## Verification Results

All Task 2 gates re-run from scratch in the resumed session (fresh `mktemp` fontkit@2.0.4 install):

- Determinism: `cmp` byte-identical for all four kit files against temp regeneration — PASS
- `xmllint --noout` both SVGs — PASS
- Zero `<text>` elements both SVGs — PASS
- One `<path>` per glyph (10 paths == 10 JSON glyphs, both weights) — PASS
- e/a/d glyphs each carry >= 2 `M` commands (counters preserved) — PASS
- No 3+-decimal coordinates in SVGs or JSONs — PASS
- Size budget: 3675 / 3667 bytes (<= 30720) — PASS
- `stem_widths.l` / `stem_widths.T` positive both weights — PASS

Task 3 gate: PNG exists (2800x2200, deviceScaleFactor 2), `file` reports PNG, zero `https?://` src/href in specimen — PASS. Visual inspection at 4x: aligned outlines, intact counters — PASS.

Task 4 gate: `cmp` clean, `fontkit@2.0.4` pinned in README, `git status` shows brandbook changes only under `brandbook/tools/`, no woff2/binaries — PASS.

No node_modules/package.json/package-lock.json anywhere in the tree — PASS.

## Files Created/Modified

- `.planning/phases/160-glyph-outline-pipeline/tools/text-to-paths.mjs` - fontkit text-to-outline pipeline (CLI: --font/--out/--text)
- `.planning/phases/160-glyph-outline-pipeline/tools/capture-overlay.mjs` - Playwright capture reusing the e2e install, deviceScaleFactor 2
- `.planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-500.{svg,json}` - per-glyph paths + metadata, Geist Medium
- `.planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-600.{svg,json}` - per-glyph paths + metadata, Geist SemiBold
- `.planning/phases/160-glyph-outline-pipeline/overlay-specimen.html` - file:// specimen: live-font vs outlines overlay + counters section
- `.planning/phases/160-glyph-outline-pipeline/overlay-evidence-2x.png` - committed 2x evidence (GLYPH-02)
- `brandbook/tools/text-to-paths.mjs` - byte-identical regeneration copy
- `brandbook/tools/README.md` - pinned regeneration instructions + contracts

## Decisions Made

- Baseline alignment via zero half-leading: `line-height: 156px` equals `(ascent - descent) x scale` for Geist (1005/-295/1000 upm at 120px), so the live-text baseline lands exactly at `ascent x scale = 120.6px`, matching the SVG kit's baseline position with both layers at `top: 0`. Confirmed correct on first capture — no baseline-math fixes needed.
- Counters section references kit paths via `<use>`/`<defs>` to avoid quadruplicating path data in the specimen.
- Inspection crops for the 4x zoom check were captured to /tmp and deleted — only the plan-specified `overlay-evidence-2x.png` is committed.

## Deviations from Plan

None - plan executed exactly as written. The resumed session re-ran the full Task 2 verification gate rather than trusting the stalled run's partial results; all gates passed without any script changes.

## Issues Encountered

- Prior execution session stalled while running Task 2's verification gate (fresh ephemeral fontkit install + cmp). Artifacts were already committed in `7815e80`; this session verified the commit, re-ran every gate from scratch, and confirmed all passing before proceeding to Task 3.

## Known Stubs

None - all artifacts are fully wired and verified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 161 has everything it needs: per-glyph editable `d` data, kerned x-offsets (`x_offset_kerned` + translate transforms), font metrics, and measured l/T stem widths for matching the thread-motif stroke width to letterform stems.
- Pipeline survives phase archive via `brandbook/tools/`; regeneration command documented with pinned fontkit@2.0.4.
- Human check remaining at phase verification: open `overlay-specimen.html` over file:// and confirm visual match (automated evidence already committed).

## Self-Check: PASSED

All 11 claimed artifacts exist on disk; commits 7815e80, ea25e34, ac837c7 verified in git log.

---
*Phase: 160-glyph-outline-pipeline*
*Completed: 2026-06-12*
