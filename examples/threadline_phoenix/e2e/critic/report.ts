/**
 * report.ts — CRITIQUE.md projection from .planning/critic-scores/ (D-08, Plan 07).
 *
 * Invoked via `run.ts report` or automatically at the end of `run.ts score`.
 * Reads .planning/critic-scores/<cell_id>/<lens>/<dimension>.json files.
 * Generates .planning/CRITIQUE.md — never hand-edited.
 *
 * Report structure:
 *   - Legend (symbol+word+reason; not color-only — survives grep/screen-readers/monochrome)
 *   - Baseline header (@v1.37 → @HEAD)
 *   - Table: one row per scored cell, one column per lens, min() rollup as leading column
 *   - In-cell: score + band + Betterer category (new/fixed/same/regression) + delta
 *
 * Signal design (D-08):
 *   ▲ new    — first score, no prior floor
 *   ▲ +N     — gain (above floor)
 *   same     — same band as floor
 *   ▽ -N     — regression (below floor)
 *   ~ unstable — null score, excluded from rollup + net-positive
 *   ⛔ vetoed — brand veto tripped, no aesthetic score
 *   ? untrusted — lens not validated (α<0.67 or n<20)
 *   —        — not yet scored
 *
 * No color-only signals. "Unknown" must never read as "bad" (D-08).
 * No external SaaS tool names (locked milestone invariant).
 *
 * D-08 / CRITIC-01
 */

import {
  existsSync,
  readdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { scoreToBand, type LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
// critic/ → e2e/ → threadline_phoenix/ → examples/ → repo root
export const repoRoot = resolve(here, "../../../..");
export const criticScoresDir = resolve(repoRoot, ".planning/critic-scores");
const critiqueOutputPath = resolve(repoRoot, ".planning/CRITIQUE.md");
const floorsPath = resolve(repoRoot, ".planning/critic-floors.json");

export const ALL_LENSES: LensName[] = [
  "hierarchy",
  "density",
  "rhythm",
  "typography",
  "color_contrast",
  "brand_fidelity",
];

// ─── Types ───────────────────────────────────────────────────────────────────

interface DimScoreFile {
  cell_id: string;
  lens: LensName;
  dimension: string;
  model_id: string;
  rubric_version: string;
  n: number;
  scores_raw: number[];
  score: number | null; // null when unstable
  band: string | null; // null when unstable
  band_mode: string;
  iqr: number;
  range: number;
  stable: boolean;
  pass: boolean;
  vetoed?: boolean; // brand-veto flag from panel.ts
  evidence: { kind: string; locator: string; observation: string };
  rationale: string;
  scored_at: string;
}

export interface LensResult {
  score: number | null; // min() of stable dimension scores; null if all unstable
  band: string | null;
  stable: boolean; // true if at least one stable dimension exists
  vetoed: boolean; // brand/token veto tripped
  iqr: number; // max IQR across dimensions (for ~ unstable display)
  evidence: string | null; // first cited locator (for veto display)
  dimensionCount: number;
}

/** Per-cell score floors committed from a previous run. cellId → lens → floor */
export type FloorMap = Record<string, Record<string, number>>;

// ─── Floor management ────────────────────────────────────────────────────────

export function readFloors(): FloorMap {
  if (!existsSync(floorsPath)) return {};
  try {
    return JSON.parse(readFileSync(floorsPath, "utf8")) as FloorMap;
  } catch {
    return {};
  }
}

// ─── Score aggregation ───────────────────────────────────────────────────────

/**
 * Read all dimension score files for a cell and aggregate per lens.
 * Returns a partial record (only lenses that have been scored).
 */
export function readCellLensScores(
  cellDir: string,
): Partial<Record<LensName, LensResult>> {
  const results: Partial<Record<LensName, LensResult>> = {};

  for (const lens of ALL_LENSES) {
    const lensDir = resolve(cellDir, lens);
    if (!existsSync(lensDir)) continue;

    const dimFiles = readdirSync(lensDir)
      .filter((f) => f.endsWith(".json"))
      .map((f) => resolve(lensDir, f));

    if (dimFiles.length === 0) continue;

    const dims: DimScoreFile[] = [];
    for (const dimPath of dimFiles) {
      try {
        dims.push(JSON.parse(readFileSync(dimPath, "utf8")) as DimScoreFile);
      } catch {
        // ignore malformed files
      }
    }

    if (dims.length === 0) continue;

    // Veto check: any dimension flagged vetoed → whole lens is vetoed
    const vetoed = dims.some(
      (d) => (d as DimScoreFile & { vetoed?: boolean }).vetoed === true,
    );

    const stableDims = dims.filter((d) => d.stable && d.score !== null);
    const maxIqr = Math.max(...dims.map((d) => d.iqr), 0);
    const firstLocator =
      dims.find((d) => d.evidence?.locator)?.evidence?.locator ?? null;

    if (vetoed) {
      results[lens] = {
        score: null,
        band: null,
        stable: false,
        vetoed: true,
        iqr: maxIqr,
        evidence: firstLocator,
        dimensionCount: dims.length,
      };
      continue;
    }

    if (stableDims.length === 0) {
      // All dimensions unstable
      results[lens] = {
        score: null,
        band: null,
        stable: false,
        vetoed: false,
        iqr: maxIqr,
        evidence: firstLocator,
        dimensionCount: dims.length,
      };
      continue;
    }

    // min() of stable dimension scores (conservative-unrated discipline, D-10)
    const scores = stableDims.map((d) => d.score as number);
    const minScore = Math.min(...scores);
    const band = scoreToBand(minScore);

    results[lens] = {
      score: minScore,
      band,
      stable: true,
      vetoed: false,
      iqr: maxIqr,
      evidence: firstLocator,
      dimensionCount: dims.length,
    };
  }

  return results;
}

/**
 * Compute the cell rollup: min() across all scored (stable, not-vetoed) lens scores.
 * Returns null if no stable scores exist.
 */
export function computeRollup(
  lenses: Partial<Record<LensName, LensResult>>,
): number | null {
  const scores: number[] = [];
  for (const lens of ALL_LENSES) {
    const r = lenses[lens];
    if (r && r.stable && !r.vetoed && r.score !== null) {
      scores.push(r.score);
    }
  }
  return scores.length === 0 ? null : Math.min(...scores);
}

// ─── Formatting ──────────────────────────────────────────────────────────────

/**
 * Format a single lens cell value for the markdown table.
 *
 * Signal design (D-08): symbol + word + reason, never color-only.
 * "Unknown" (unscored) must never read as "bad".
 */
function formatLensCell(
  result: LensResult | undefined,
  floor: number | undefined,
): string {
  if (!result) return "—";

  if (result.vetoed) {
    const evSnippet =
      result.evidence
        ? ` (${result.evidence.substring(0, 28).replace(/\|/g, "/")}...)`
        : "";
    return `⛔ vetoed${evSnippet}`;
  }

  if (!result.stable || result.score === null) {
    return `~ unstable (IQR ${result.iqr.toFixed(1)})`;
  }

  const score = result.score;
  const band = result.band ?? scoreToBand(score);

  if (floor === undefined) {
    return `▲ new ${score} [${band}]`;
  }

  const delta = score - floor;
  if (delta > 0) {
    return `▲ +${delta} ${score} [${band}]`;
  } else if (delta < 0) {
    return `▽ ${delta} ${score} [${band}]`;
  } else {
    return `${score} [${band}] same`;
  }
}

/**
 * Format the rollup cell (leading column, min() across lenses).
 */
function formatRollupCell(
  rollup: number | null,
  cellFloors: Record<string, number> | undefined,
): string {
  if (rollup === null) return "—";

  const band = scoreToBand(rollup);

  if (!cellFloors || Object.keys(cellFloors).length === 0) {
    return `▲ new ${rollup} [${band}]`;
  }

  const priorRollup = Math.min(
    ...Object.values(cellFloors).filter((v) => typeof v === "number"),
  );
  const delta = rollup - priorRollup;
  if (delta > 0) return `▲ +${delta} ${rollup} [${band}]`;
  if (delta < 0) return `▽ ${delta} ${rollup} [${band}]`;
  return `${rollup} [${band}] same`;
}

// ─── Report generation ───────────────────────────────────────────────────────

/**
 * Generate the CRITIQUE.md projection from .planning/critic-scores/.
 * Writes to .planning/CRITIQUE.md and returns the number of scored cells.
 * Never hand-edit the output — call this function to regenerate.
 */
export function generateReport(): number {
  const now = new Date().toISOString().split("T")[0];
  const floors = readFloors();

  // ── Collect scored cells ─────────────────────────────────────────────────

  interface CellData {
    cellId: string;
    lenses: Partial<Record<LensName, LensResult>>;
    rollup: number | null;
  }

  const cells: CellData[] = [];

  if (existsSync(criticScoresDir)) {
    const entries = readdirSync(criticScoresDir).filter((d) => {
      const full = resolve(criticScoresDir, d);
      return existsSync(full) && statSync(full).isDirectory();
    });

    for (const dirName of entries.sort()) {
      const lenses = readCellLensScores(resolve(criticScoresDir, dirName));
      // Only include cells with at least one scored lens
      if (Object.keys(lenses).length > 0) {
        cells.push({
          cellId: dirName,
          lenses,
          rollup: computeRollup(lenses),
        });
      }
    }
  }

  // ── Build table rows ─────────────────────────────────────────────────────

  const tableRows = cells.map((c) => {
    const rollup = formatRollupCell(c.rollup, floors[c.cellId]);
    const lensValues = ALL_LENSES.map((lens) =>
      formatLensCell(c.lenses[lens], floors[c.cellId]?.[lens]),
    );
    return `| \`${c.cellId}\` | ${rollup} | ${lensValues.join(" | ")} |`;
  });

  const emptyNote =
    cells.length === 0
      ? "\n*(No scores yet. Run `critic label --bootstrap` then `npm run critic:score` to populate.)*\n"
      : "";

  // ── Write CRITIQUE.md ────────────────────────────────────────────────────

  const content = `<!-- GENERATED — do not hand-edit. Regenerate: npm run critic:score -->
<!-- Baseline: @v1.37 → @HEAD -->
<!-- Last regenerated: ${now} -->

# CRITIQUE.md — Adversarial Critic Projection

> Generated from \`.planning/critic-scores/\` by \`report.ts\`.
> Never hand-edit — regenerate with \`npm run critic:score\`.
> Freshness-tested: every scored cell must have a row here (see \`critic_trust_test.exs\`).

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ▲ new {score} [band] | New score — no prior floor for this cell/lens. |
| ▲ +N {score} [band] | Gain — score N points above the committed floor. |
| {score} [band] same | Same band as prior floor — no meaningful change. |
| ▽ -N {score} [band] | Regression — score N points below the committed floor. |
| ~ unstable (IQR N) | Unstable — high variance across self-consistency samples. Score is null (never 0); excluded from rollup and Phase-196 net-positive calculation. Re-run or human-adjudicate. |
| ⛔ vetoed (locator...) | Brand/token veto tripped before aesthetic scoring. No aesthetic score recorded for this cell. The cited mechanical line is the evidence. |
| ? N [band] (untrusted) | Lens not yet validated (α < 0.67 or n < 20 golden judgments). Number shown for reference; do not use for ratchet decisions or floor bumps. |
| — | Not yet scored. Run \`npm run critic:score\` to populate. |

**Stability rule:** \`~ unstable\` cells show null, never 0. An unstable cell that scores 0 would poison the \`min()\` rollup and illegally register as a regression — null is the correct sentinel.

**"Unknown" is not "bad":** unscored (—) and unstable (~) cells are information gaps, not failures. Only a scored \`fail\` or \`weak\` band is a signal to act on.

**Rollup (leading column):** \`min()\` across all scored, stable, non-vetoed lens scores for the cell. A single weak lens floors the entire rollup — the same discipline as the scorecard cube.

---

## Baseline

Baseline: @v1.37 → @HEAD (delta vs committed critic floors from prior scoring run; \`▲ new\` = no prior floor).

Reference bar: Linear (primary) — one accent per job, primary + secondary metadata in one clear scan path.
Vercel/Stripe (typographic restraint + accent discipline). Grafana (cautionary — high-density footgun).

---

## Score Table

One row per scored cell. Columns: \`rollup\` = min() across all lenses; per-lens = min() across dimensions.
Betterer idiom: \`▲ new\` (first score), \`▲ +N\` (gain), \`same\` (no change), \`▽ -N\` (regression).
Per finding: score + band + delta vs floor + cited evidence locator + suggested direction (not an auto-fix).

| cell_id | rollup | hierarchy | density | rhythm | typography | color_contrast | brand_fidelity |
|---------|--------|-----------|---------|--------|------------|----------------|----------------|
${tableRows.join("\n")}${emptyNote}

---

*Threat boundary: screenshot/DOM content sent to the Anthropic API during local scoring is dev-only tooling.
No production data. Opt-in via \`ANTHROPIC_API_KEY\`. See CONTRIBUTING.md "Local-only critic" section.*
`;

  writeFileSync(critiqueOutputPath, content, "utf8");
  return cells.length;
}

/**
 * CLI entry point for `run.ts report`.
 */
export async function runReport(_argv: string[]): Promise<void> {
  const count = generateReport();
  if (count === 0) {
    console.log(
      "[critic report] CRITIQUE.md generated (0 scored cells — run `critic label --bootstrap` then `npm run critic:score` to populate).",
    );
  } else {
    console.log(
      `[critic report] CRITIQUE.md regenerated with ${count} scored cell${count === 1 ? "" : "s"}.`,
    );
  }
}
