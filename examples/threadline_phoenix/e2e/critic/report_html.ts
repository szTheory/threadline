/**
 * report_html.ts — self-contained visual critique viewer.
 *
 * Renders `.planning/critic-report.html`: one card per scored REAL-UI cell (page.* /
 * story.*, refute/graded synthetic cells excluded) with the screenshot beside its
 * 6-lens scorecard — rollup, per-lens band + score + delta-vs-floor, a trusted/advisory
 * badge (from the ledger's validated lenses), and the worst finding's evidence +
 * rationale. Screenshots are base64-inlined so the output is a single portable file that
 * opens in any browser with NO server.
 *
 * Reuses report.ts's score→rollup→delta logic; this file only renders it as HTML.
 * Deterministic: cells sorted by id, so re-running with unchanged scores is a clean diff.
 */

import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  ALL_LENSES,
  computeRollup,
  criticScoresDir,
  readCellLensScores,
  readFloors,
  repoRoot,
  type LensResult,
} from "./report.js";
import { scoreToBand, type LensName } from "./schema.js";

const outPath = resolve(repoRoot, ".planning/critic-report.html");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const ledgerPath = resolve(repoRoot, ".planning/design-system-ledger.json");

// Band → colour (never colour-only; always paired with the band word — D-08).
const BAND_COLOR: Record<string, string> = {
  fail: "#e5484d",
  weak: "#f5a524",
  ok: "#e2c541",
  strong: "#46b17a",
  exemplary: "#30a46c",
};

interface Finding {
  dimension: string;
  score: number | null;
  band: string | null;
  locator: string;
  observation: string;
  rationale: string;
}

const esc = (s: string): string =>
  s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c] as string));

// Lenses the trust gate has promoted to validated:true (ledger critic_trust block).
function validatedLenses(): Set<string> {
  try {
    const ct = JSON.parse(readFileSync(ledgerPath, "utf8")).critic_trust ?? {};
    return new Set(Object.entries(ct).filter(([, v]) => (v as { validated?: boolean }).validated).map(([k]) => k));
  } catch {
    return new Set();
  }
}

// Worst (lowest-scoring stable) dimension per lens → the actionable finding.
function worstFinding(cellDir: string, lens: LensName): Finding | null {
  const lensDir = resolve(cellDir, lens);
  if (!existsSync(lensDir)) return null;
  let worst: Finding | null = null;
  for (const f of readdirSync(lensDir).filter((x) => x.endsWith(".json"))) {
    try {
      const d = JSON.parse(readFileSync(resolve(lensDir, f), "utf8"));
      const cur: Finding = {
        dimension: d.dimension,
        score: d.score,
        band: d.band,
        locator: d.evidence?.locator ?? "",
        observation: d.evidence?.observation ?? "",
        rationale: d.rationale ?? "",
      };
      if (worst === null || (cur.score !== null && (worst.score === null || cur.score < worst.score))) {
        worst = cur;
      }
    } catch {
      /* skip malformed */
    }
  }
  return worst;
}

// The committed scorecard's screenshot → base64 data URI (single portable file).
function screenshotDataUri(cellId: string): string | null {
  const sc = resolve(scorecardsDir, `${cellId}.json`);
  if (!existsSync(sc)) return null;
  const rel = (JSON.parse(readFileSync(sc, "utf8")).artifacts ?? {}).screenshot as string | undefined;
  if (!rel) return null;
  const abs = resolve(repoRoot, rel);
  if (!existsSync(abs)) return null;
  return `data:image/png;base64,${readFileSync(abs).toString("base64")}`;
}

function deltaLabel(score: number | null, floor: number | undefined): string {
  if (score === null) return "~ unstable";
  if (floor === undefined) return "▲ new";
  const d = score - floor;
  if (d > 0) return `▲ +${d}`;
  if (d < 0) return `▽ ${d}`;
  return "same";
}

function lensRow(
  cellDir: string,
  lens: LensName,
  result: LensResult | undefined,
  floor: number | undefined,
  validated: Set<string>,
): string {
  const trust = validated.has(lens)
    ? `<span class="badge trusted">trusted</span>`
    : `<span class="badge advisory">advisory</span>`;

  if (!result) {
    return `<tr><td class="lens">${lens}</td><td colspan="3" class="muted">— not scored</td><td>${trust}</td></tr>`;
  }
  if (result.vetoed) {
    return `<tr><td class="lens">${lens}</td><td colspan="3">⛔ vetoed</td><td>${trust}</td></tr>`;
  }
  if (!result.stable || result.score === null) {
    return `<tr><td class="lens">${lens}</td><td colspan="3" class="muted">~ unstable (IQR ${result.iqr.toFixed(1)})</td><td>${trust}</td></tr>`;
  }

  const band = result.band ?? scoreToBand(result.score);
  const color = BAND_COLOR[band] ?? "#8a8a93";
  const find = worstFinding(cellDir, lens);
  const finding = find
    ? `<div class="finding"><b>${esc(find.dimension)}</b>${find.locator ? ` · <code>${esc(find.locator)}</code>` : ""}<br>${esc(find.observation)}${find.rationale ? `<span class="rationale"> — ${esc(find.rationale)}</span>` : ""}</div>`
    : "";

  return `<tr>
    <td class="lens">${lens}</td>
    <td><span class="chip" style="background:${color}">${band}</span></td>
    <td class="score">${result.score}</td>
    <td class="delta">${deltaLabel(result.score, floor)}</td>
    <td>${trust}</td>
  </tr>${finding ? `<tr class="finding-row"><td></td><td colspan="4">${finding}</td></tr>` : ""}`;
}

function cellCard(cellId: string, validated: Set<string>): string {
  const cellDir = resolve(criticScoresDir, cellId);
  const lenses = readCellLensScores(cellDir);
  const rollup = computeRollup(lenses);
  const floors = readFloors()[cellId] ?? {};
  const img = screenshotDataUri(cellId);

  const rollupBand = rollup === null ? "—" : scoreToBand(rollup);
  const rollupColor = rollup === null ? "#8a8a93" : (BAND_COLOR[rollupBand] ?? "#8a8a93");

  const rows = ALL_LENSES.map((lens) => lensRow(cellDir, lens, lenses[lens], floors[lens], validated)).join("\n");

  return `<section class="card">
    <div class="shot">${img ? `<img src="${img}" alt="${esc(cellId)}">` : `<div class="muted">no screenshot</div>`}</div>
    <div class="scores">
      <div class="cell-head">
        <code class="cell-id">${esc(cellId)}</code>
        <div class="rollup"><span class="rollup-num" style="color:${rollupColor}">${rollup ?? "—"}</span><span class="rollup-band">${rollupBand} · rollup ${deltaLabel(rollup, Object.values(floors).length ? Math.min(...Object.values(floors)) : undefined)}</span></div>
      </div>
      <table><tbody>${rows}</tbody></table>
    </div>
  </section>`;
}

export function generateHtmlReport(): number {
  const validated = validatedLenses();

  const cells = existsSync(criticScoresDir)
    ? readdirSync(criticScoresDir)
        .filter((d) => statSync(resolve(criticScoresDir, d)).isDirectory())
        // Real UI only — synthetic refute/graded oracle cells are excluded from the viewer.
        .filter((d) => !d.startsWith("refute."))
        .filter((d) => Object.keys(readCellLensScores(resolve(criticScoresDir, d))).length > 0)
        .sort()
    : [];

  const cards = cells.map((c) => cellCard(c, validated)).join("\n");
  const trustedList = [...validated].sort().join(", ") || "none yet";

  const html = `<!doctype html><html><head><meta charset="utf-8">
<title>Threadline — critic report</title>
<style>
  :root{--bg:#0b0b0d;--panel:#141418;--border:#2a2a30;--text:#e7e7ea;--muted:#8a8a93}
  *{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--text);font:14px/1.5 -apple-system,system-ui,sans-serif}
  header{padding:28px 32px;border-bottom:1px solid var(--border)}
  h1{margin:0 0 6px;font-size:20px;letter-spacing:.02em}
  .sub{color:var(--muted);font-size:13px;max-width:70ch}
  .legend{margin-top:12px;display:flex;gap:14px;flex-wrap:wrap;color:var(--muted);font-size:12px}
  .legend .chip{font-size:11px}
  main{padding:24px 32px;display:flex;flex-direction:column;gap:24px}
  .card{display:grid;grid-template-columns:minmax(300px,480px) 1fr;gap:20px;background:var(--panel);border:1px solid var(--border);border-radius:10px;padding:16px;align-items:start}
  .shot img{width:100%;border:1px solid var(--border);border-radius:6px;display:block}
  .cell-head{display:flex;justify-content:space-between;align-items:baseline;gap:12px;margin-bottom:10px}
  .cell-id{color:var(--muted);font-size:12px}
  .rollup{text-align:right} .rollup-num{font-size:30px;font-weight:700} .rollup-band{display:block;color:var(--muted);font-size:11px}
  table{width:100%;border-collapse:collapse} td{padding:6px 8px;border-top:1px solid var(--border);vertical-align:top}
  .lens{font-weight:600;width:120px} .score{font-variant-numeric:tabular-nums} .delta{color:var(--muted);font-size:12px}
  .chip{padding:2px 8px;border-radius:20px;color:#0b0b0d;font-weight:700;font-size:12px}
  .badge{font-size:10px;padding:1px 6px;border-radius:4px;text-transform:uppercase;letter-spacing:.04em}
  .badge.trusted{background:#173a2b;color:#46b17a;border:1px solid #46b17a55}
  .badge.advisory{background:#2a2a30;color:var(--muted);border:1px solid var(--border)}
  .finding-row td{border-top:0;padding-top:0} .finding{color:#c7c7cf;font-size:12.5px;background:#0f0f13;border-left:2px solid var(--border);padding:6px 10px;border-radius:0 4px 4px 0}
  .rationale{color:var(--muted)} code{color:#8ab4f8;font-size:11.5px} .muted{color:var(--muted)}
</style></head>
<body>
<header>
  <h1>Threadline critic — what the critic sees</h1>
  <div class="sub">The validated UI critic scoring real operator surfaces. Each card: screenshot · rollup (worst lens) · per-lens band + score + delta-vs-floor + the worst finding. Oracle: <b>synthetic twin</b> (D-12), zero human labeling. <b>Trusted</b> lenses met the ranking gate (ρ≥0.7): ${esc(trustedList)}. Other lenses are <b>advisory</b>. First run shows <b>▲ new</b> (no prior floor) — after one improvement iteration this becomes a true before/after (<b>▲ +N</b>).</div>
  <div class="legend">
    ${Object.entries(BAND_COLOR).map(([b, c]) => `<span><span class="chip" style="background:${c}">${b}</span></span>`).join("")}
    <span>▲ new · ▲ +N gain · ▽ −N regression · ~ unstable · ⛔ vetoed</span>
  </div>
</header>
<main>
${cards || `<div class="muted">No real-UI cells scored yet. Run: npm run critic:score -- --page page.transaction.happy --theme dark --breakpoint 1280</div>`}
</main>
</body></html>`;

  writeFileSync(outPath, html, "utf8");
  console.log(`[critic report --html] wrote ${cells.length} cells → ${outPath}`);
  return cells.length;
}
