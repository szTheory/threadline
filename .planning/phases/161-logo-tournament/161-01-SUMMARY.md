---
phase: 161-logo-tournament
plan: 01
subsystem: brand
tags: [logo, svg, geist, sora, space-grotesk, hc-gate, gallery, playwright, fontkit]

# Dependency graph
requires:
  - phase: 159-brand-audit-and-research
    provides: 159-DESIGN-BRIEF.md — binding generation contract (MR-1..5, HC-1..6, §4, §5 lanes)
  - phase: 160-glyph-outline-pipeline
    provides: glyph-kit-geist-{500,600}.{svg,json}, text-to-paths.mjs pipeline, ephemeral-fontkit + Playwright-reuse patterns
provides:
  - 8 round-1 logo candidates x 3 forms (primary/mono/16px favicon) = 24 pure-path SVGs, all HC-1..6 green
  - tools/hc-gate.mjs — mechanical HC-1..6 + TOUR-01 quota/distinctness gate, runnable on any round dir
  - tools/build-gallery.mjs + candidates/round-1/gallery.html — self-contained six-context file:// review gallery
  - ROUNDS.md — protocol header + round-1 roster, rationales, kerning notes, empty feedback skeleton
affects: [161-02 round-1 checkpoint, 162-brand-book-v2]

# Tech tracking
tech-stack:
  added: [Sora SemiBold v2.000 (OFL, ephemeral), Space Grotesk Medium v2.0.0 (OFL, ephemeral)]
  patterns:
    - "Candidate SVG contract: data-lane/data-technique/data-hook on primary roots, data-glyph per letterform path, data-role=mark for motif geometry — gate verifies quota, pair distinctness, and glyph inventory mechanically"
    - "Mono renditions generated from primaries by color substitution only (structure identity by construction)"
    - "Favicon ink-floor: 16px render pixel-scanned at 4x; designed features >= 1px, acute-junction wedges adjudicated via silhouette render"

key-files:
  created:
    - .planning/phases/161-logo-tournament/candidates/round-1/c{1..8}-*.svg (24 files, 3 forms each)
    - .planning/phases/161-logo-tournament/candidates/round-1/strategies.json
    - .planning/phases/161-logo-tournament/candidates/round-1/gallery.html
    - .planning/phases/161-logo-tournament/tools/hc-gate.mjs
    - .planning/phases/161-logo-tournament/tools/build-gallery.mjs
    - .planning/phases/161-logo-tournament/ROUNDS.md
  modified: []

key-decisions:
  - "Strategy matrix: SC and CLM are the two doubled techniques (different hooks); all six BRIEF §2 techniques used across 3/3/1/1 lanes"
  - "Brief's 'double-l verticals' hook mapped to the adjacent d/l ascender pair (Threadline has no literal double-l); documented in ROUNDS.md"
  - "Palette: ink = currentColor (adaptive dark/light), at most one flat accent per candidate (#4781E6 blue or #D9A03F gold); C2/C4/C6-mono/C7 fully monochromatic"
  - "hc-gate plate heuristic exempts stroke-only (fill=none) paths — strokes cannot be background plates; literal <rect> ban absolute"
  - "C7 favicon is the monogram's true geometry mapped to 16px with the crossbar solid (over/under weave is a display-size feature)"

requirements-completed: [TOUR-01, LOGO-01, LOGO-02, LOGO-03, LOGO-04, LOGO-05]
requirements-partial: [TOUR-02 (round-1 portion; later rounds repeat per-round)]

# Metrics
duration: ~68min
completed: 2026-06-12
---

# Phase 161 Plan 01: Round-1 Logo Candidates Summary

**Eight genuine, gate-verified logo candidates across the BRIEF §5 lanes — every letterform from the Phase 160 pipeline (Geist kits + fresh Sora/Space Grotesk OFL runs), every motif structurally load-bearing (MR-2), packaged in a zero-network six-context gallery with a seeded ROUNDS.md for the 161-02 checkpoint.**

## Performance

- **Duration:** ~68 min (2026-06-12T01:37:19Z → 02:45Z)
- **Tasks:** 4/4
- **Files:** 29 created, 0 modified outside the phase dir

## The Round-1 Roster

| ID | Lane | Strategy | Typeface | Concept (one line) |
|----|------|----------|----------|--------------------|
| C1 running-thread | typemark | Stroke continuation · descender-free run | Geist 500 | Both e-bars escape as one woven thread through the whole word |
| C2 strung-crossbar | typemark | Ligature wordmark · Th pair | Geist 600 | One crossbar spans T and h, slack bellying between the posts; h decapitated beneath it |
| C3 pinned-eye | typemark | Counter replacement · e/a/d counters | Geist 500 | First e's counter re-cut as a circular eye holding a gold pin |
| C4 knotline | lockup | Continuous-line mark · T crossbar | Geist 500 | One stroke: loose end → geometric loop → becomes the T's crossbar (left arm removed) |
| C5 needle-eye | lockup | Negative space · i dot | Geist 500 | i dot becomes the needle's eye; the thread is an unprinted channel ending in it |
| C6 topstitch | lockup | Stroke continuation · double-l verticals (d/l pair) | Sora 600 | d/l ascenders cut and escaped into one stitch arc, surfaced part in accent |
| C7 th-monoline | monogram | Continuous-line mark · Th pair | monoline + Geist 600 | One thread writes "th"; crossbar weaves behind the stem; monogram is the favicon |
| C8 needle-run | wordmark | Pattern-through-letterforms · descender-free run | Space Grotesk 500 | Nine needle punctures through the stems; the thread shown only by its evidence |

## Verification Results

- `node tools/hc-gate.mjs candidates/round-1` → **24 files, 0 FAIL, 0 WARN**; TOUR-01 quota 3/3/1/1, 8 distinct (technique, hook) pairs, no within-lane technique repeats, exactly two techniques doubled with different hooks.
- `xmllint --noout` all 24 SVGs + gallery — PASS.
- Gallery gates: `grep -cE 'https?://'` = 0; `grep -c '<text'` = 0; 88 inlined SVGs (>= 48); 1062 lines (>= 200); C1..C8 all present.
- Silhouette test (all paths one solid, literal 16px + 4x): all 8 favicons identifiable — PASS (/tmp renders, not committed).
- Flatten check (mono beside primary at 64px): structure identical for all 8 (monos generated by color substitution only) — PASS.
- Ink-floor pixel scan (filled favicons, 16px @ 4x sampling): C5 min ink 2.00px / gap 1.75px; C8 min ink 1.00px / gap 1.00px — PASS. C1's sub-1px designed entry-gap found and fixed; remaining sub-1px interior runs on C1/C2/C3/C4/C6 adjudicated as acute-junction wedges via silhouette renders.
- Optical kerning overlays (candidate cyan over kit magenta, 2x, /tmp): zero translate-offset changes in round 1; all surgeries glyph-internal or additive; clearances recorded in ROUNDS.md.
- `git status --porcelain`: zero staged paths under brandbook/, lib/, examples/, test/ at every commit (pre-existing unstaged changes there untouched).

## Task Commits (incremental, stall-resilient)

1. `34de760` — strategy manifest + hc-gate.mjs
2. `5ac4814` — C1–C3 (+ gate stroke-only plate exemption)
3. `d7aa88a` — C4–C5
4. `af79537` — C6–C8 (OFL alternates)
5. `2bc991f` — gallery.html + build-gallery.mjs + C1 favicon gap fix
6. `88476b5` — ROUNDS.md seeded

## OFL Alternate Provenance (binaries never committed)

- Sora SemiBold v2.000 — `github.com/sora-xor/sora-font` (master, `fonts/ttf/Sora-SemiBold.ttf`), pipeline run `--text Threadline`.
- Space Grotesk Medium v2.0.0 — `github.com/floriankarsten/space-grotesk` release 2.0.0 zip, `ttf/static/SpaceGrotesk-Medium.ttf`, pipeline run `--text threadline`.
- Both via `brandbook/tools/text-to-paths.mjs` with ephemeral `fontkit@2.0.4` (mktemp prefix + NODE_PATH), per the Phase 160 pattern. Downloads and kits lived in mktemp dirs only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] hc-gate plate heuristic false positive on stroke-only paths**
- **Found during:** Task 2 (C3 favicon's thin diagonal flagged as a background plate by bbox)
- **Fix:** paths with `fill="none"` exempted from the plate heuristic (a stroke cannot be a plate); literal `<rect>` ban and filled-path heuristic unchanged
- **Files:** tools/hc-gate.mjs · **Commit:** 5ac4814

**2. [Rule 1 - Bug] C1 favicon designed gap below the 1px floor**
- **Found during:** Task 2 ink-floor scan (0.35px gap between entry dash and bowl wall)
- **Fix:** left entry dash removed; the bar now under-passes inside the bowl with a 1.05px gap
- **Files:** c1-running-thread-favicon.svg · **Commit:** 2bc991f

### Process deviations

**3. Incremental commits instead of Task 4's single package commit** — per orchestrator stall-resilience instruction (prior run stalled with zero artifacts). Six commits, each gated.
**4. strategies.json committed** — plan said working notes stay uncommitted; orchestrator instructed committing the strategy manifest first for stall resilience.
**5. tools/build-gallery.mjs added** (not in the plan's file list) — makes the gallery regenerable for rounds 2+; pure phase-dir tooling.
**6. Design iterations within scope** — C2's catenary-span first cut read as a notch defect and was redesigned to the shared-bar-with-belly ligature; C4's hand-drawn knot read as a cursive ribbon and was redesigned to the geometric tangent loop; C2/C3/C7/C8 favicons recut after misreads (torii gate, search icon, squiggle, hydrant). All iterations verified by /tmp renders before commit.

## Known Stubs

None — all 29 artifacts fully wired; gallery and gate verified end to end.

## Threat Flags

None beyond the plan's register: both font downloads came from the official upstreams named in ROUNDS.md; fontkit pinned at 2.0.4 ephemeral; gate enforces zero script/image/foreignObject/fetchable refs in all committed SVGs and the gallery greps network-free.

## Next Step Readiness

Plan 161-02 (round-1 human checkpoint) has everything it needs: `candidates/round-1/gallery.html` to open over file://, ROUNDS.md with the empty verdict skeleton, and `tools/hc-gate.mjs` + `tools/build-gallery.mjs` for round-2 candidate generation after feedback.

## Self-Check: PASSED

All claimed artifacts exist on disk (24 candidate SVGs + gallery + strategies.json + 2 tools + ROUNDS.md + SUMMARY); all six commits (34de760, 5ac4814, d7aa88a, af79537, 2bc991f, 88476b5) verified in git log.
