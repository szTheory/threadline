# brandbook/tools — text-to-outline pipeline

`text-to-paths.mjs` converts a vendored woff2 font plus a text string into
per-glyph SVG path data with real shaped (GPOS) kerning, via
[fontkit](https://www.npmjs.com/package/fontkit). It exists so brand outlines
(e.g. the "Threadline" wordmark glyphs) stay regenerable after the Phase 160
planning directory archives.

## Regenerating glyph kits

Dependencies are ephemeral — never commit `node_modules/`, `package.json`, or
`package-lock.json`. The fontkit version is pinned for byte-determinism:

```bash
cd <repo-root>
FONTKIT_DIR=$(mktemp -d)
npm install --prefix "$FONTKIT_DIR" --no-fund --no-audit --silent fontkit@2.0.4
NODE_PATH="$FONTKIT_DIR/node_modules" node brandbook/tools/text-to-paths.mjs \
  --font priv/fonts/geist-500.woff2 --out /tmp/glyph-kit-geist-500
NODE_PATH="$FONTKIT_DIR/node_modules" node brandbook/tools/text-to-paths.mjs \
  --font priv/fonts/geist-600.woff2 --out /tmp/glyph-kit-geist-600
```

Note: the script resolves fontkit through CJS `require` (which honors
`NODE_PATH`) because ESM `import` ignores it.

## CLI contract

```
node text-to-paths.mjs --font <path-to-woff2> --out <output-prefix> [--text "Threadline"]
```

- `--font` (required) — path to a woff2 font file
- `--out` (required) — output prefix; emits `<prefix>.svg` and `<prefix>.json`
- `--text` (optional) — text to shape; defaults to `Threadline`

## Output contract

- One `<path>` per glyph, never merged; zero `<text>` elements.
- Coordinates in font units, y-flipped into SVG space (baseline at
  `y = ascent`), rounded to 2 decimals through one canonical formatter.
- Contour order and winding preserved exactly as fontkit emits them — counters
  (e/a/d holes) render under the SVG default nonzero fill rule; no `fill-rule`
  attribute is emitted.
- Shaped kerning from `font.layout()`; each glyph's kerned pen offset is
  exposed via `transform="translate(x 0)"` and `x_offset_kerned` in the JSON,
  keeping the glyph-local `d` editable.
- Deterministic: same inputs produce byte-identical outputs.
- JSON metadata: text, font metrics (postscript name, weight, units-per-em,
  ascent/descent, cap/x-height, SVG baseline y), total advance, per-glyph
  name/code points/advance/kerned offset/bbox/`d`, and measured stem widths of
  `l` and `T` (for matching stroke widths to letterform stems).

## Fonts and licensing

Source fonts live in `priv/fonts/` (Geist and IBM Plex Mono, woff2). They are
licensed under the SIL Open Font License — outline conversion is license-clean;
the OFL notices are vendored alongside the fonts (`priv/fonts/OFL-Geist.txt`).
Do not copy font binaries into `brandbook/` — point at `priv/fonts/` instead.

## Original kits and evidence

The original generated kits (`glyph-kit-geist-{500,600}.{svg,json}`), the
live-font overlay specimen, and the 2x screenshot evidence live in the Phase
160 planning directory: `.planning/phases/160-glyph-outline-pipeline/`.
