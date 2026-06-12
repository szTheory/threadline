#!/usr/bin/env node
// brand-gate.mjs — mechanical HC-1..6 gate for the Threadline brandbook asset family.
// Usage: node brand-gate.mjs <brandbook-dir>
// Adapted from .planning/phases/161-logo-tournament/tools/hc-gate.mjs for brandbook
// asset roles (the tournament TOUR-01 quota section is dropped — tournament-only).
// Checks every *.svg in <dir> and <dir>/examples against the hard constraints of
// .planning/phases/159-brand-audit-and-research/159-DESIGN-BRIEF.md (HC-1..6) plus
// the BOOK-02 corpus rule (tagline isolated to -subtitle + social card).
// Plain Node, no deps. Exit code: 0 only if zero FAIL lines.

import fs from "node:fs";
import path from "node:path";

const dir = process.argv[2];
if (!dir || !fs.existsSync(dir)) {
  console.error("usage: node brand-gate.mjs <brandbook-dir>");
  process.exit(2);
}

const TAGLINE = "FOLLOW WHAT HAPPENED";
const TAGLINE_FILES = new Set(["logo-primary-subtitle.svg", "social-card.svg"]);
const ROLE_VALUES = new Set(["mark", "tagline", "background", "art", "copy"]);

// Collect brandbook SVGs: root + examples/.
const files = [];
for (const f of fs.readdirSync(dir)) {
  if (f.endsWith(".svg")) files.push(f);
}
const exDir = path.join(dir, "examples");
if (fs.existsSync(exDir)) {
  for (const f of fs.readdirSync(exDir)) {
    if (f.endsWith(".svg")) files.push(path.join("examples", f));
  }
}
files.sort();

let failures = 0;
let warnings = 0;
const lines = [];
function pass(file, check, msg = "") {
  lines.push(`PASS  ${file}  ${check}${msg ? "  " + msg : ""}`);
}
function fail(file, check, msg) {
  failures++;
  lines.push(`FAIL  ${file}  ${check}  ${msg}`);
}
function warn(file, check, msg) {
  warnings++;
  lines.push(`WARN  ${file}  ${check}  ${msg}`);
}

// Role classification by filename.
function roleOf(rel) {
  const base = path.basename(rel);
  if (rel.startsWith("examples" + path.sep) || rel.startsWith("examples/")) return "example";
  if (["logo-primary.svg", "logo-primary-light.svg", "logo-wordmark.svg"].includes(base)) return "primary";
  if (base === "logo-mark.svg") return "mark";
  if (base === "logo-monochrome.svg") return "mono";
  if (base === "favicon.svg") return "favicon";
  if (TAGLINE_FILES.has(base)) return "tagline-bearing";
  return "unknown";
}

// "Threadline" letter multiset (case-insensitive).
const TARGET = countLetters("threadline");
function countLetters(s) {
  const m = {};
  for (const ch of s.toLowerCase().replace(/[^a-z]/g, "")) m[ch] = (m[ch] || 0) + 1;
  return m;
}
function multisetEq(a, b) {
  const ka = Object.keys(a), kb = Object.keys(b);
  if (ka.length !== kb.length) return false;
  return ka.every((k) => a[k] === b[k]);
}
function multisetSubset(sub, sup) {
  return Object.keys(sub).every((k) => (sup[k] || 0) >= sub[k]);
}

// Strip internal <style> blocks (sanctioned for the favicon prefers-color-scheme
// flip) so style-sheet color rules never count as paint attributes.
function withoutStyleBlocks(src) {
  return src.replace(/<style[\s\S]*?<\/style>/gi, "");
}

// Extract all element open-tags of a given name with their raw attribute strings.
function elements(src, tag) {
  const re = new RegExp(`<${tag}\\b([^>]*)>`, "g");
  const out = [];
  let m;
  while ((m = re.exec(src))) out.push(m[1]);
  return out;
}
function attr(attrs, name) {
  const m = attrs.match(new RegExp(`(?:^|\\s)${name}\\s*=\\s*["']([^"']*)["']`));
  return m ? m[1] : null;
}
function isPainted(p) {
  const f = attr(p, "fill"), s = attr(p, "stroke");
  // SVG default fill is black: a path with no fill attribute is painted.
  return f !== "none" || (s != null && s !== "none");
}

// Rough bbox of an absolute-command path `d` (M L H V Q C A Z). Control points
// included — adequate for the background-plate heuristic.
function pathBBox(d) {
  const tokens = d.match(/[MLHVQCAZmlhvqcaz]|-?\d*\.?\d+(?:e-?\d+)?/g) || [];
  let i = 0, x = 0, y = 0, minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  const pt = (px, py) => {
    minX = Math.min(minX, px); maxX = Math.max(maxX, px);
    minY = Math.min(minY, py); maxY = Math.max(maxY, py);
  };
  let cmd = null;
  while (i < tokens.length) {
    const t = tokens[i];
    if (/[A-Za-z]/.test(t)) { cmd = t; i++; continue; }
    switch (cmd) {
      case "M": case "L":
        x = +tokens[i]; y = +tokens[i + 1]; pt(x, y); i += 2; break;
      case "H": x = +tokens[i]; pt(x, y); i += 1; break;
      case "V": y = +tokens[i]; pt(x, y); i += 1; break;
      case "Q":
        pt(+tokens[i], +tokens[i + 1]); x = +tokens[i + 2]; y = +tokens[i + 3]; pt(x, y); i += 4; break;
      case "C":
        pt(+tokens[i], +tokens[i + 1]); pt(+tokens[i + 2], +tokens[i + 3]);
        x = +tokens[i + 4]; y = +tokens[i + 5]; pt(x, y); i += 6; break;
      case "A":
        x = +tokens[i + 5]; y = +tokens[i + 6]; pt(x, y); i += 7; break;
      default: i++; break;
    }
  }
  if (minX === Infinity) return null;
  return { minX, minY, maxX, maxY };
}

const taglineCarriers = [];

for (const rel of files) {
  const fp = path.join(dir, rel);
  const src = fs.readFileSync(fp, "utf8");
  const role = roleOf(rel);
  const base = path.basename(rel);
  if (role === "unknown") warn(rel, "ROLE", "filename matches no known brandbook role — example-level checks applied");

  // ---- BOOK-02 corpus collection ----
  if (src.includes(TAGLINE)) taglineCarriers.push(rel);

  // ---- HC-6: zero <text> elements (all roles) ----
  if (/<text[\s>]/i.test(src)) fail(rel, "HC-6", "<text> element present");
  else pass(rel, "HC-6");

  // ---- Hygiene: no script/image/foreignObject, no fetchable refs (all roles) ----
  if (/<script[\s>]|<image[\s>]|<foreignObject[\s>]/i.test(src)) {
    fail(rel, "HYGIENE", "script/image/foreignObject element present");
  } else if (/(xlink:href|href|src)\s*=\s*["'][^"']*http/i.test(src) || /url\(\s*["']?[^)]*http/i.test(src)) {
    fail(rel, "HYGIENE", "externally fetchable reference (http in href/src/url())");
  } else pass(rel, "HYGIENE", "(xmlns declarations allowed)");

  // ---- HC-2: no <rect>, no background plates (all roles) ----
  // Sanctioned exemption: social-card.svg may carry exactly ONE full-bleed path
  // tagged data-role="background" (a social card has a canvas; a mark must not
  // have a chip). The literal <rect> ban stays absolute everywhere.
  const svgAttrs = elements(src, "svg")[0] || "";
  const vb = (attr(svgAttrs, "viewBox") || "0 0 0 0").trim().split(/[\s,]+/).map(Number);
  const [, , vbW, vbH] = vb;
  const paths = elements(src, "path");
  if (/<rect[\s>]/i.test(src)) fail(rel, "HC-2", "<rect> element present");
  else {
    const plates = [];
    for (const p of paths) {
      const d = attr(p, "d");
      if (!d) continue;
      // Stroke-only paths (fill="none") cannot be background plates; the plate
      // heuristic applies to filled geometry.
      if (attr(p, "fill") === "none") continue;
      const bb = pathBBox(d);
      if (!bb) continue;
      // Heuristic: a single filled path covering >=85% of BOTH viewBox dimensions is a plate.
      if (vbW > 0 && vbH > 0 && (bb.maxX - bb.minX) >= 0.85 * vbW && (bb.maxY - bb.minY) >= 0.85 * vbH) {
        plates.push(p);
      }
    }
    if (plates.length === 0) pass(rel, "HC-2");
    else if (
      base === "social-card.svg" &&
      plates.length === 1 &&
      attr(plates[0], "data-role") === "background"
    ) {
      pass(rel, "HC-2", "single sanctioned data-role=\"background\" canvas (social card exemption)");
    } else {
      fail(rel, "HC-2", `${plates.length} filled path(s) span >=85% of both viewBox dimensions (background plate)`);
    }
  }

  // ---- TAGGING: every painted path carries data-glyph or a sanctioned data-role (all roles) ----
  {
    let bad = 0;
    for (const p of paths) {
      if (!isPainted(p)) continue;
      const glyph = attr(p, "data-glyph");
      const r = attr(p, "data-role");
      if (glyph) continue;
      if (r && ROLE_VALUES.has(r)) {
        if (r === "background" && base !== "social-card.svg") {
          bad++;
          fail(rel, "TAGGING", "data-role=\"background\" is only sanctioned in social-card.svg");
        }
        continue;
      }
      bad++;
      fail(rel, "TAGGING", `painted path without data-glyph or data-role in {${[...ROLE_VALUES].join(", ")}}`);
    }
    if (bad === 0) pass(rel, "TAGGING");
  }

  // ---- HC-1 / glyph inventory (role-dependent) ----
  const glyphVals = [];
  for (const p of paths) {
    const g = attr(p, "data-glyph");
    if (g) glyphVals.push(g);
  }
  const inventory = countLetters(glyphVals.join(""));
  if (role === "primary") {
    if (multisetEq(inventory, TARGET)) pass(rel, "HC-1", "inventory == letters of \"Threadline\" exactly");
    else fail(rel, "HC-1", `glyph inventory ${glyphVals.join("|") || "(empty)"} != letters of "Threadline" (case-insensitive)`);
  } else if (role === "mark" || role === "favicon") {
    if (multisetSubset(inventory, TARGET)) pass(rel, "HC-1", `inventory subset of "Threadline" (${glyphVals.join("") || "mark-only"})`);
    else fail(rel, "HC-1", `glyph inventory ${JSON.stringify(inventory)} not a subset of "Threadline"`);
  } else if (role === "tagline-bearing") {
    if (multisetSubset(TARGET, inventory)) pass(rel, "HC-1", "full \"Threadline\" inventory present (extra tagged paths allowed)");
    else fail(rel, "HC-1", `"Threadline" inventory incomplete: have ${glyphVals.join("") || "(none)"}`);
  }

  // ---- HC-5: mono rendition (logo-monochrome.svg) ----
  if (role === "mono") {
    if (/gradient/i.test(src)) fail(rel, "HC-5", "gradient present");
    else if (/opacity/i.test(src)) fail(rel, "HC-5", "opacity present");
    else {
      const colors = new Set();
      const re = /(?:fill|stroke)\s*=\s*["']([^"']+)["']/g;
      let m;
      while ((m = re.exec(withoutStyleBlocks(src)))) {
        const v = m[1].trim().toLowerCase();
        if (v !== "none") colors.add(v);
      }
      if (colors.size === 1) pass(rel, "HC-5", `single flat color: ${[...colors][0]}`);
      else fail(rel, "HC-5", `expected exactly 1 paint color, found ${colors.size}: ${[...colors].join(", ")}`);
    }
  }

  // ---- HC-4: favicon numeric thresholds ----
  // An internal <style> block is ignored when counting paints — a
  // prefers-color-scheme ink flip is sanctioned for favicons.
  if (role === "favicon") {
    const cleaned = withoutStyleBlocks(src);
    const fpaths = elements(cleaned, "path");
    const painted = fpaths.filter(isPainted);
    if (painted.length > 4) fail(rel, "HC-4", `${painted.length} painted elements > 4`);
    else pass(rel, "HC-4-count", `${painted.length} painted elements (<= 4)`);
    const scale = vbH > 0 ? 16 / vbH : 1;
    for (const p of painted) {
      const s = attr(p, "stroke");
      if (s && s !== "none") {
        const sw = parseFloat(attr(p, "stroke-width") || "1");
        const scaled = sw * scale;
        if (scaled < 1.0) fail(rel, "HC-4", `stroke ${scaled.toFixed(2)}px at 16px canvas < 1.0px floor`);
        else if (scaled < 1.5) warn(rel, "HC-4", `stroke ${scaled.toFixed(2)}px at 16px canvas < 1.5px target (>= 1.0 floor ok)`);
        else pass(rel, "HC-4-stroke", `${scaled.toFixed(2)}px at 16px canvas`);
      }
    }
  }

  // ---- Tagline-bearing: the literal string must be present as metadata ----
  // (aria-label, <title>, or comment — pure-path tagline glyphs cannot carry it.)
  if (role === "tagline-bearing") {
    if (src.includes(TAGLINE)) pass(rel, "BOOK-02", "tagline string present as metadata");
    else fail(rel, "BOOK-02", `literal string "${TAGLINE}" missing (required in aria-label, <title>, or comment)`);
  }
}

// ---- BOOK-02 corpus rule: tagline appears in exactly the two sanctioned files ----
for (const rel of taglineCarriers) {
  if (!TAGLINE_FILES.has(path.basename(rel)) || rel.includes("examples")) {
    fail(rel, "BOOK-02", `"${TAGLINE}" present outside the sanctioned files (logo-primary-subtitle.svg, social-card.svg)`);
  }
}
for (const wanted of TAGLINE_FILES) {
  const found = taglineCarriers.some((rel) => path.basename(rel) === wanted && !rel.includes("examples"));
  if (found) pass(wanted, "BOOK-02-corpus", "carries the tagline as sanctioned");
  else fail(wanted, "BOOK-02-corpus", `sanctioned tagline carrier missing or lacks "${TAGLINE}"`);
}

console.log(lines.join("\n"));
console.log(`\n${files.length} files reported, ${failures} FAIL, ${warnings} WARN`);
process.exit(failures > 0 ? 1 : 0);
