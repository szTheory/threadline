#!/usr/bin/env node
/**
 * text-to-paths.mjs — Convert a woff2 font + text string into per-glyph SVG path data.
 *
 * Canonical invocation (ephemeral fontkit install — NEVER commit node_modules,
 * package.json, or package-lock.json):
 *
 *   FONTKIT_DIR=$(mktemp -d)
 *   npm install --prefix "$FONTKIT_DIR" --no-fund --no-audit --silent fontkit@2.0.4
 *   NODE_PATH="$FONTKIT_DIR/node_modules" node tools/text-to-paths.mjs \
 *     --font priv/fonts/geist-500.woff2 --out <output-prefix> [--text "Threadline"]
 *
 * Emits <output-prefix>.svg and <output-prefix>.json.
 *
 * Output contract:
 *   - One <path> per glyph, never merged. Contour order and winding preserved
 *     exactly as fontkit emits them (counters render via default nonzero fill).
 *   - Coordinates in font units, y-flipped into SVG space (ySvg = ascent - yFont,
 *     baseline at y = ascent), rounded to 2 decimals via one canonical formatter.
 *   - Shaped kerning: font.layout() applies real GPOS kerning; each glyph's pen
 *     offset is exposed via transform="translate(x 0)" and JSON x_offset_kerned,
 *     keeping the glyph-local `d` editable.
 *   - Deterministic: same inputs produce byte-identical outputs (no timestamps,
 *     no randomness, fixed key order, locale-independent formatting, \n endings).
 *   - JSON metadata: per-glyph name/advance/kerned offset/bbox/d, font metrics,
 *     and measured stem widths of "l" and "T" for stroke-width matching.
 *
 * fontkit is resolved via createRequire because ESM `import` ignores NODE_PATH;
 * CJS `require` honors it.
 */
import { createRequire } from "node:module";
import { writeFileSync } from "node:fs";
import { basename } from "node:path";

const require = createRequire(import.meta.url);
let fontkit;
try {
  fontkit = require("fontkit");
} catch {
  console.error(
    [
      "error: cannot resolve fontkit. Install it ephemerally and expose it via NODE_PATH:",
      "  FONTKIT_DIR=$(mktemp -d)",
      '  npm install --prefix "$FONTKIT_DIR" --no-fund --no-audit --silent fontkit@2.0.4',
      '  NODE_PATH="$FONTKIT_DIR/node_modules" node tools/text-to-paths.mjs --font <woff2> --out <prefix>',
    ].join("\n"),
  );
  process.exit(1);
}

function parseArgs(argv) {
  const args = { text: "Threadline" };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (key === "--font" || key === "--out" || key === "--text") {
      args[key.slice(2)] = argv[i + 1];
      i += 1;
    } else {
      console.error(`error: unknown argument ${key}`);
      process.exit(1);
    }
  }
  if (!args.font || !args.out) {
    console.error('usage: text-to-paths.mjs --font <woff2> --out <prefix> [--text "Threadline"]');
    process.exit(1);
  }
  return args;
}

// Canonical coordinate formatter: toFixed(2), strip trailing zeros and trailing
// dot, normalize -0 to 0. Used for every number in both the SVG and the JSON.
function fmt(n) {
  let s = n.toFixed(2);
  if (s.includes(".")) s = s.replace(/0+$/, "").replace(/\.$/, "");
  return s === "-0" ? "0" : s;
}

function round2(n) {
  return Number(fmt(n));
}

const SVG_OPS = {
  moveTo: "M",
  lineTo: "L",
  quadraticCurveTo: "Q",
  bezierCurveTo: "C",
  closePath: "Z",
};

// Glyph-local path data, y-flipped (applies to every point, including bezier
// control points). Pen offset is NOT baked in.
function glyphPathD(glyph, ascent) {
  const parts = [];
  for (const { command, args } of glyph.path.commands) {
    const op = SVG_OPS[command];
    if (!op) throw new Error(`unsupported path command: ${command}`);
    const coords = [];
    for (let i = 0; i < args.length; i += 2) {
      coords.push(fmt(args[i]), fmt(ascent - args[i + 1]));
    }
    parts.push(coords.length > 0 ? `${op} ${coords.join(" ")}` : op);
  }
  return parts.join(" ");
}

// Geist lowercase "l" is a vertical stem with a small tail at the baseline
// (the outline reaches right of the stem near y = 0), so bbox width would
// overstate the stem. The upper half of the glyph contains only the stem:
// measure the x-extent of all outline points above the glyph bbox midline.
function stemWidthL(font) {
  const glyph = font.layout("l").glyphs[0];
  const midY = (glyph.bbox.minY + glyph.bbox.maxY) / 2;
  const xs = [];
  for (const { args } of glyph.path.commands) {
    for (let i = 0; i < args.length; i += 2) {
      if (args[i + 1] > midY) xs.push(args[i]);
    }
  }
  if (xs.length === 0) throw new Error("no l stem points found above bbox midline");
  return Math.max(...xs) - Math.min(...xs);
}

// The lower half of "T" contains only the vertical stem (the crossbar sits at
// the top), so the x-extent of all outline points with y < capHeight/2 is the
// stem width.
function stemWidthT(font, capHeight) {
  const xs = [];
  for (const { args } of font.layout("T").glyphs[0].path.commands) {
    for (let i = 0; i < args.length; i += 2) {
      if (args[i + 1] < capHeight / 2) xs.push(args[i]);
    }
  }
  if (xs.length === 0) throw new Error("no T stem points found below capHeight/2");
  return Math.max(...xs) - Math.min(...xs);
}

function fontWeight(fontPath, font) {
  const m = basename(fontPath).match(/-(\d{3})\.\w+$/);
  if (m) return Number(m[1]);
  return font["OS/2"].usWeightClass;
}

const { font: fontPath, out: outPrefix, text } = parseArgs(process.argv.slice(2));
const font = fontkit.openSync(fontPath);
const { ascent, descent, unitsPerEm, capHeight, xHeight, postscriptName } = font;
const run = font.layout(text);

let penX = 0;
const glyphs = [];
for (let i = 0; i < run.glyphs.length; i += 1) {
  const glyph = run.glyphs[i];
  const pos = run.positions[i];
  const name = glyph.name || `gid${glyph.id}`;
  const xKerned = penX + pos.xOffset;
  const { bbox } = glyph;
  glyphs.push({
    index: i,
    name,
    code_points: glyph.codePoints,
    advance_width: round2(glyph.advanceWidth),
    x_offset_kerned: round2(xKerned),
    y_offset: round2(pos.yOffset),
    bbox: {
      min_x: round2(bbox.minX),
      min_y: round2(ascent - bbox.maxY),
      max_x: round2(bbox.maxX),
      max_y: round2(ascent - bbox.minY),
    },
    d: glyphPathD(glyph, ascent),
  });
  penX += pos.xAdvance;
}
const totalAdvance = penX;

const svgLines = [
  `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${fmt(totalAdvance)} ${fmt(ascent - descent)}">`,
];
for (const g of glyphs) {
  svgLines.push(
    `  <path id="g-${g.index}-${g.name}" transform="translate(${fmt(g.x_offset_kerned)} 0)" d="${g.d}"/>`,
  );
}
svgLines.push("</svg>");
writeFileSync(`${outPrefix}.svg`, `${svgLines.join("\n")}\n`);

const json = {
  text,
  font: {
    file: basename(fontPath),
    postscriptName,
    weight: fontWeight(fontPath, font),
    unitsPerEm,
    ascent: round2(ascent),
    descent: round2(descent),
    capHeight: round2(capHeight),
    xHeight: round2(xHeight),
    baseline_y_svg: round2(ascent),
  },
  total_advance: round2(totalAdvance),
  glyphs,
  stem_widths: {
    l: round2(stemWidthL(font)),
    T: round2(stemWidthT(font, capHeight)),
    units: "font_units",
    method:
      "l: max(x) - min(x) over all on-path and control points above the glyph bbox midline (upper half of 'l' contains only the vertical stem; the baseline tail is excluded); T: max(x) - min(x) over all on-path and control points with y < capHeight/2 (lower half of 'T' contains only the vertical stem)",
  },
};
writeFileSync(`${outPrefix}.json`, `${JSON.stringify(json, null, 2)}\n`);
