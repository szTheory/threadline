# Phase 162 — Evidence Index & BOOK-07 Scorecard Comparison

Rerun of the 15-dimension adversarial pressure test (`brandbook/pressure-test.md`)
against the rebuilt brand system, compared row-for-row against the 159-AUDIT.md §3
baseline (79/150). BOOK-07 requires the rerun to meet or beat the total with no
dimension below its baseline row.

## Baseline vs rerun, row for row

| # | Dimension | Baseline | Rerun | Delta |
|---|---|---|---|---|
| 1 | Distinctiveness | 4 | 8 | +4 |
| 2 | Mark/type integration | 2 | 9 | +7 |
| 3 | 16px survival | 3 | 8 | +5 |
| 4 | Monochrome survival | 3 | 9 | +6 |
| 5 | Dark/light versatility | 5 | 9 | +4 |
| 6 | Portability (no font dependency) | 2 | 10 | +8 |
| 7 | Scalability | 4 | 8 | +4 |
| 8 | Voice | 9 | 9 | 0 |
| 9 | Palette | 8 | 8 | 0 |
| 10 | Typography | 8 | 8 | 0 |
| 11 | Token rigor | 8 | 8 | 0 |
| 12 | Application coverage | 7 | 8 | +1 |
| 13 | Misuse guidance | 6 | 9 | +3 |
| 14 | Consistency | 6 | 9 | +3 |
| 15 | Craft | 4 | 8 | +4 |
| | **Total** | **79 / 150** | **128 / 150** | **+49** |

**Result: 128/150 vs the 79/150 baseline — total beaten by +49; zero dimensions below
baseline; the four KEEP rows (Voice, Palette, Typography, Token rigor) held without
regression.** The seven mark-survival rows (1-7), which baselined at an average of 3.3,
now average 8.7 — the v1.35 thesis (rebuild the visual half, preserve the verbal half)
is demonstrated mechanically.

Per-row rationale and the testable pass condition behind every score live in
`brandbook/pressure-test.md` (the durable QA guide). Scores cite only mechanical
outputs, committed-file properties, or the screenshots indexed below — no self-graded
rows.

## Evidence index

All artifacts live in `.planning/phases/162-brand-book-v2/evidence/` (planning dir,
never brandbook/ — brandbook/ stays binary-free).

| Artifact | What it proves |
|---|---|
| `evidence/index-desktop.png` | `brandbook/index.html` direct-open (file://) at 1440×900 full-page: all 7 sections render, all inlined assets paint, misuse gallery + thresholds visible, no broken images, no overflow (dimensions 1, 5, 12, 13, 15) |
| `evidence/index-mobile.png` | Same page at 390×844 full-page: single-column layout holds, swatches/specimens/code blocks fit the viewport, no horizontal overflow (dimensions 12, 15) |
| `evidence/favicon-contexts.png` | /tmp harness (throwaway, not committed), light color scheme: `favicon.svg` at literal 16px, 32px, 64px (=4× of 16) on side-by-side #FFFFFF and #0B1020 panels — Ink #0F1728 strokes crisp on the light panel, identifiable at the 16px cell (dimensions 3, 5) |
| `evidence/favicon-contexts-dark.png` | Same harness captured with `--color-scheme=dark`: the internal `prefers-color-scheme` style flips strokes to Fog #D7DEEA, crisp on the dark panel at all three sizes — proving the scheme-flip mechanism both ways (dimensions 3, 5) |
| `evidence/gates.txt` | Full mechanical suite output: brand-gate (`10 files reported, 0 FAIL, 0 WARN`, exit 0), zero-`<text>` grep, zero-`<rect>` grep, tagline isolation (exactly 2 sanctioned files), no-http grep on index.html, xmllint pass on all 10 SVGs, size budget (≤300KB), text-only format check (dimensions 3, 4, 6, 11, 14 + BOOK-06) |

Why two favicon captures: the favicon's ink is scheme-driven (its internal
`prefers-color-scheme` style), so a single browser capture can only show one ink
state. The pair proves both states; in each capture the scheme-matched panel is the
operative evidence and the opposite panel demonstrates the flip.

## Mechanical commands behind the scores

Recorded verbatim in `evidence/gates.txt`; rerunnable from the repo root as documented
in `brandbook/pressure-test.md` ("The mechanical suite"). Key results at capture time
(2026-06-12, post-162-02 tree):

- `node .planning/phases/162-brand-book-v2/tools/brand-gate.mjs brandbook` → exit 0, `10 files reported, 0 FAIL, 0 WARN`
- `grep -rln '<text' brandbook/ --include='*.svg'` → empty
- `grep -rln '<rect' brandbook/ --include='*.svg'` → empty
- `grep -rln 'FOLLOW WHAT HAPPENED' brandbook/` → exactly `social-card.svg`, `logo-primary-subtitle.svg`
- `grep -nE 'src="http|href="http' brandbook/index.html` → empty
- `grep -il opacity brandbook/*.svg brandbook/examples/*.svg` → empty (no opacity tiers anywhere)
- `grep -il gradient brandbook/*.svg brandbook/examples/*.svg` → empty (no gradients in committed SVGs)
- `xmllint --noout` on all 10 SVGs → clean
- `find brandbook -type f ! -name '.DS_Store' -print0 | xargs -0 du -ck | tail -1` → 208KB ≤ 300KB
- `git ls-files brandbook/ | grep -vE '[.](svg|html|css|json|md|mjs)$'` → empty (text-only formats, no binaries)
- All 10 SVG paint hexes (#0B1020, #0F1728, #8F9DB5, #D7DEEA, #23304A, #3B4762, #4EDFD1, #4F8CFF, #73819C, #4781E6) present in `tokens.json`

## UAT pointer

The phase closes with the user's gsd-verify-work UAT: open
`brandbook/index.html` directly in a browser (both a desktop and a narrow window),
confirm it reads as a professional standalone brand book, and approve. The screenshots
above are the executor's evidence; the human gate is the user's own eyes.
