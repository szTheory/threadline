#!/usr/bin/env node
// hc-gate.mjs — mechanical HC-1..6 gate for Threadline logo tournament candidates.
// Usage: node hc-gate.mjs <round-dir>
// Checks every c*.svg in the round directory against the hard constraints of
// .planning/phases/159-brand-audit-and-research/159-DESIGN-BRIEF.md (HC-1..6)
// plus the TOUR-01 lane quota / strategy distinctness rules. Plain Node, no deps.
// Exit code: 0 only if zero FAIL lines.

import fs from "node:fs";
import path from "node:path";

const dir = process.argv[2];
if (!dir || !fs.existsSync(dir)) {
  console.error("usage: node hc-gate.mjs <round-dir>");
  process.exit(2);
}

const files = fs
  .readdirSync(dir)
  .filter((f) => /^c\d+-.*\.svg$/.test(f))
  .sort();

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

const primaries = [];

for (const file of files) {
  const fp = path.join(dir, file);
  const src = fs.readFileSync(fp, "utf8");
  const kind = /-favicon\.svg$/.test(file) ? "favicon" : /-mono\.svg$/.test(file) ? "mono" : "primary";

  // ---- HC-6: zero <text> elements ----
  if (/<text[\s>]/i.test(src)) fail(file, "HC-6", "<text> element present");
  else pass(file, "HC-6");

  // ---- Hygiene: no script/image/foreignObject, no fetchable refs ----
  if (/<script[\s>]|<image[\s>]|<foreignObject[\s>]/i.test(src)) {
    fail(file, "HYGIENE", "script/image/foreignObject element present");
  } else if (/(xlink:href|href|src)\s*=\s*["'][^"']*http/i.test(src) || /url\(\s*["']?[^)]*http/i.test(src)) {
    fail(file, "HYGIENE", "externally fetchable reference (http in href/src/url())");
  } else pass(file, "HYGIENE", "(xmlns declarations allowed)");

  // ---- HC-2: no <rect>, no background plates ----
  const svgAttrs = elements(src, "svg")[0] || "";
  const vb = (attr(svgAttrs, "viewBox") || "0 0 0 0").trim().split(/[\s,]+/).map(Number);
  const [vbX, vbY, vbW, vbH] = vb;
  if (/<rect[\s>]/i.test(src)) fail(file, "HC-2", "<rect> element present");
  else {
    let plate = null;
    let untagged = null;
    for (const p of elements(src, "path")) {
      const glyph = attr(p, "data-glyph");
      const role = attr(p, "data-role");
      if (!glyph && role !== "mark") untagged = true;
      const d = attr(p, "d");
      if (!d) continue;
      // Stroke-only paths (fill="none") cannot be background plates; the plate
      // heuristic applies to filled geometry. The literal <rect> ban above is absolute.
      if (attr(p, "fill") === "none") continue;
      const bb = pathBBox(d);
      if (!bb) continue;
      // Heuristic: a single filled path covering >=85% of BOTH viewBox dimensions is a plate.
      if (vbW > 0 && vbH > 0 && (bb.maxX - bb.minX) >= 0.85 * vbW && (bb.maxY - bb.minY) >= 0.85 * vbH) {
        plate = true;
      }
    }
    if (plate) fail(file, "HC-2", "path bbox spans >=85% of both viewBox dimensions (background plate)");
    else pass(file, "HC-2");
    if (untagged) fail(file, "TAGGING", "painted path without data-glyph or data-role=\"mark\"");
    else pass(file, "TAGGING");
  }

  // ---- HC-1 / glyph inventory ----
  const glyphVals = [];
  for (const p of elements(src, "path")) {
    const g = attr(p, "data-glyph");
    if (g) glyphVals.push(g);
  }
  const inventory = countLetters(glyphVals.join(""));
  if (kind === "favicon") {
    if (multisetSubset(inventory, TARGET)) pass(file, "HC-1", `inventory subset of "Threadline" (${glyphVals.join("") || "mark-only"})`);
    else fail(file, "HC-1", `glyph inventory ${JSON.stringify(inventory)} not a subset of "Threadline"`);
  } else {
    if (multisetEq(inventory, TARGET)) pass(file, "HC-1", "inventory == letters of \"Threadline\" exactly");
    else fail(file, "HC-1", `glyph inventory ${glyphVals.join("|")} != letters of "Threadline" (case-insensitive)`);
  }

  // ---- HC-5: mono renditions ----
  if (kind === "mono") {
    if (/gradient/i.test(src)) fail(file, "HC-5", "gradient present");
    else if (/opacity/i.test(src)) fail(file, "HC-5", "opacity present");
    else {
      const colors = new Set();
      const re = /(?:fill|stroke)\s*=\s*["']([^"']+)["']/g;
      let m;
      while ((m = re.exec(src))) {
        const v = m[1].trim().toLowerCase();
        if (v !== "none") colors.add(v);
      }
      if (colors.size === 1) pass(file, "HC-5", `single flat color: ${[...colors][0]}`);
      else fail(file, "HC-5", `expected exactly 1 paint color, found ${colors.size}: ${[...colors].join(", ")}`);
    }
  }

  // ---- HC-4: favicon numeric thresholds ----
  if (kind === "favicon") {
    const paths = elements(src, "path");
    const painted = paths.filter((p) => {
      const f = attr(p, "fill"), s = attr(p, "stroke");
      return (f !== "none") || (s && s !== "none");
    });
    if (painted.length > 4) fail(file, "HC-4", `${painted.length} painted elements > 4`);
    else pass(file, "HC-4-count", `${painted.length} painted elements (<= 4)`);
    const scale = vbH > 0 ? 16 / vbH : 1;
    for (const p of painted) {
      const s = attr(p, "stroke");
      if (s && s !== "none") {
        const sw = parseFloat(attr(p, "stroke-width") || "1");
        const scaled = sw * scale;
        if (scaled < 1.0) fail(file, "HC-4", `stroke ${scaled.toFixed(2)}px at 16px canvas < 1.0px floor`);
        else if (scaled < 1.5) warn(file, "HC-4", `stroke ${scaled.toFixed(2)}px at 16px canvas < 1.5px target (>= 1.0 floor ok)`);
        else pass(file, "HC-4-stroke", `${scaled.toFixed(2)}px at 16px canvas`);
      }
    }
  }

  // ---- collect primaries for TOUR-01 ----
  if (kind === "primary") {
    primaries.push({
      file,
      lane: attr(svgAttrs, "data-lane"),
      technique: attr(svgAttrs, "data-technique"),
      hook: attr(svgAttrs, "data-hook"),
    });
  }
}

// ---- TOUR-01: lane quota + strategy distinctness across primaries ----
if (primaries.length === 8) {
  const laneCounts = {};
  for (const p of primaries) laneCounts[p.lane] = (laneCounts[p.lane] || 0) + 1;
  const quotaOk =
    laneCounts.typemark === 3 && laneCounts.lockup === 3 &&
    laneCounts.monogram === 1 && laneCounts.wordmark === 1;
  if (quotaOk) pass("(round)", "TOUR-01-quota", "lanes 3/3/1/1");
  else fail("(round)", "TOUR-01-quota", `lane counts ${JSON.stringify(laneCounts)} != typemark:3 lockup:3 monogram:1 wordmark:1`);

  const pairs = primaries.map((p) => `${p.technique} :: ${p.hook}`);
  if (new Set(pairs).size === 8) pass("(round)", "TOUR-01-pairs", "8 distinct (technique, hook) pairs");
  else fail("(round)", "TOUR-01-pairs", `duplicate (technique, hook) pair among: ${pairs.join(" | ")}`);

  const byLane = {};
  let laneRepeat = false;
  for (const p of primaries) {
    byLane[p.lane] = byLane[p.lane] || new Set();
    if (byLane[p.lane].has(p.technique)) laneRepeat = true;
    byLane[p.lane].add(p.technique);
  }
  if (!laneRepeat) pass("(round)", "TOUR-01-lane-techniques", "no technique repeats within a lane");
  else fail("(round)", "TOUR-01-lane-techniques", "technique name repeats within a lane");

  const techCounts = {};
  for (const p of primaries) techCounts[p.technique] = (techCounts[p.technique] || 0) + 1;
  const over = Object.entries(techCounts).filter(([, n]) => n > 2);
  const twice = Object.entries(techCounts).filter(([, n]) => n === 2);
  if (over.length === 0 && twice.length <= 2) pass("(round)", "TOUR-01-tech-spread", `twice: ${twice.map(([t]) => t).join(", ") || "none"}`);
  else fail("(round)", "TOUR-01-tech-spread", `technique used >2x (${over.map(([t]) => t).join(", ")}) or >2 techniques doubled`);

  // doubles must use different hooks
  const doubleHookViolation = Object.keys(techCounts)
    .filter((t) => techCounts[t] === 2)
    .some((t) => {
      const hooks = primaries.filter((p) => p.technique === t).map((p) => p.hook);
      return new Set(hooks).size !== hooks.length;
    });
  if (!doubleHookViolation) pass("(round)", "TOUR-01-double-hooks", "doubled techniques use different hooks");
  else fail("(round)", "TOUR-01-double-hooks", "a doubled technique reuses the same hook");
} else {
  lines.push(`NOTE  (round)  TOUR-01 quota check expects 8 primaries, found ${primaries.length} — distinctness still applies in later rounds`);
}

console.log(lines.join("\n"));
console.log(`\n${files.length} files reported, ${failures} FAIL, ${warnings} WARN`);
process.exit(failures > 0 ? 1 : 0);
