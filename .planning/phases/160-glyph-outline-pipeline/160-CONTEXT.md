# Phase 160: glyph-outline-pipeline - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning
**Source:** Approved milestone plan (`~/.claude/plans/have-to-compare-it-lexical-shore.md`), user decisions locked at plan approval

<domain>
## Phase Boundary

Build a reproducible text-to-outline pipeline that converts the vendored Geist woff2 fonts into per-glyph SVG path data for "Threadline" with real font-shaping kerning — so every Phase 161 logo candidate and every Phase 162 final asset can be pure paths (zero `<text>` elements, portable in GitHub's SVG sandbox) while individual letterforms remain surgically editable for motif integration. This phase delivers tooling + glyph kit + overlay verification evidence; it does not design logos.

</domain>

<decisions>
## Implementation Decisions

### Pipeline tech
- Node script using **fontkit** (not opentype.js): fontkit parses woff2/Brotli natively and `font.layout("Threadline")` applies real GPOS kerning. opentype.js cannot read woff2 without a separate wawoff2 decompression step and handles GPOS kerning poorly.
- Source fonts: vendored `priv/fonts/geist-500.woff2` and `priv/fonts/geist-600.woff2` (OFL — outline conversion is legally clean; OFL notice already vendored).
- Run with ephemeral deps (`npx`-style / temp install) — **no `node_modules` committed**. Commit only the ~100-line script and its outputs.
- Script lives at `.planning/phases/160-glyph-outline-pipeline/tools/text-to-paths.mjs` during the phase, with a copy or pointer under `brandbook/tools/` so outlines stay regenerable after the phase archives. (Small script file in brandbook/tools/ is acceptable; it is text.)

### Output contract
- `glyph-kit.svg` + `glyph-kit.json`: per-glyph path data for "Threadline" at Geist 500 and 600.
- **One `<path>` per glyph** — never merged — so individual letterforms can be edited in the tournament.
- Per-glyph metadata in JSON: glyph name, advance width, kerned x-offset, baseline, units-per-em, font weight.
- Coordinates rounded to 2 decimals (unrounded fontkit output bloats files 5–10×).
- Y-flipped into SVG coordinate space.
- Script must be deterministic: same inputs → byte-identical outputs.

### Verification approach
- Overlay artifact: generated outlines superimposed on a browser-rendered live-Geist specimen (the webfonts exist in priv/fonts/ for an HTML specimen page); visually indistinguishable at 2× zoom.
- `xmllint --noout` on glyph-kit.svg; `grep -c '<text'` must be 0.
- Counters (holes in e, a, d) must render correctly — fill-rule/winding preserved from font outlines (nonzero winding with opposing contour directions; never "simplify" paths).

### Known footguns to encode in the plan
- Font kerning is tuned for text sizes; display-size logos need a later manual optical pass (owned by Phase 161, not this phase — but the kit must expose per-glyph offsets so 161 can adjust).
- Stroke-vs-fill mismatch: glyph outlines are fills; the thread motif is a stroke. The kit JSON should include measured stem width(s) of representative glyphs (e.g. "l", "T") so Phase 161 can match motif stroke width to letterform stems.

### Claude's Discretion
- Exact JSON schema layout.
- Whether to also emit a combined convenience path per weight (only if per-glyph paths remain the primary output).
- How the ephemeral install is wired (npm prefix tempdir, npx, etc.) as long as nothing is committed.
- Support for additional OFL exploration typefaces is OPTIONAL scaffolding (a `--font <path>` arg is enough); only Geist 500/600 outputs are required by GLYPH-01.

</decisions>

<specifics>
## Specific Ideas

- GitHub's SVG sandbox loads no external fonts — this is the concrete bug in the current `brandbook/logo-primary.svg` (uses `<text font-family="Geist...">`). The pipeline exists to make that class of bug impossible.
- The repo already vendors geist-400/500/600 and ibm-plex-mono-400/500 woff2 under `priv/fonts/` with OFL licenses.

</specifics>

<deferred>
## Deferred Ideas

- Optical kerning adjustments for display sizes — Phase 161 task.
- Motif splicing into letterforms — Phase 161.

</deferred>

---

*Phase: 160-glyph-outline-pipeline*
*Context gathered: 2026-06-11*
