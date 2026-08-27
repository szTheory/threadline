/**
 * panel.ts — 7-critic panel with brand-veto ordering (RUNNER-03).
 *
 * Critic→lens map (D-06, 14 lens-cells/page):
 *   P1–P5: each writes p{n}.hierarchy + p{n}.density (persona-weighted, blind)
 *   Graphic-design: writes all.rhythm, all.typography, all.color_contrast
 *   Brand-veto: writes all.brand_fidelity (mechanical token-parity, $0 LLM)
 *
 * Veto pipeline per capture cell (ordered, RUNNER-03):
 *   (1) Mechanical gate: card_nesting_depth / type_size_count from scorecard mode_b ($0)
 *   (2) Token-parity brand veto: applied_colors vs --tl-color-* token set ($0)
 *   (3) On veto: write all.brand_fidelity={current:null,vetoed:true,evidence}
 *       and SKIP all aesthetic vision calls for that cell (persona AND graphic-design)
 *   (4) No veto: fan out one vision call per (cell × lens-key × dimension × persona),
 *       each blind (no sibling output in context); persona clause in uncached suffix
 *       so all five persona critics reuse one cached lens prefix (D-06/D-11).
 *
 * Precedence: vetoed(null) ≻ unstable(null) ≻ scored — both write null but the
 * vetoed flag distinguishes them so neither poisons min().
 *
 * Disagreement: no averaging across personas; the min()-losing (persona, lens) cell
 * is named in the rollup evidence string (D-06).
 *
 * Pre-warming: graphic-design lenses are scored first to establish cached prefixes
 * before the five-persona sweep, keeping the Opus 4.8 5-min TTL alive (D-04/D-06).
 *
 * D-06 / RUNNER-03
 */

import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type Anthropic from "@anthropic-ai/sdk";
import type { ScorecardJson, ScorecardBundle } from "./bundle.js";
import { loadBundle } from "./bundle.js";
import { runNSamples } from "./client.js";
import { buildPrompt } from "./prompt.js";
import { writeCriticScore } from "./scorecard.js";
import { lookupCache, writeCache, sha8OfFile } from "./cache.js";
import { MODEL_ID, type LensName, type BandName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const rubricDir = resolve(here, "rubrics");

// ─── Critic→Lens Map (D-06, 14 lens-cells/page) ─────────────────────────────

/**
 * The 7-critic → lens mapping (14 lens-cells/page).
 * Persona critics are blind to each other's output (D-06 invariant).
 *
 * Each persona (P1–P5) independently judges hierarchy + density against their own
 * JTBD pass-condition (the clause is placed in the uncached suffix so all five
 * persona critics reuse the one cached lens prefix — D-11 anti-pattern 2 prevention).
 *
 * Persona is a WEIGHT (different pass-conditions), never a ×5 multiplier.
 * The 6 frozen lenses: hierarchy · density · rhythm · typography · color_contrast · brand_fidelity.
 */
export const CRITIC_LENS_MAP = {
  // Persona critics: each writes hierarchy + density (10 cells)
  p1: ["hierarchy", "density"] as const,
  p2: ["hierarchy", "density"] as const,
  p3: ["hierarchy", "density"] as const,
  p4: ["hierarchy", "density"] as const,
  p5: ["hierarchy", "density"] as const,
  // Graphic-design critic: writes rhythm, typography, color_contrast (3 cells)
  all_graphic: ["rhythm", "typography", "color_contrast"] as const,
  // Brand-veto critic: writes brand_fidelity ($0 mechanical + optional gestalt) (1 cell)
  all_brand: ["brand_fidelity"] as const,
} as const;

/** Total lens-cells per page = 5 × 2 + 3 + 1 = 14. */
export const LENS_CELL_COUNT = 14 as const;

// ─── Extended Scorecard (adds runtime-captured fields not in the base schema) ─

/**
 * Extended scorecard shape: includes applied_colors and color_pairs captured
 * at render time but not reflected in the base ScorecardJson interface.
 * Used by the token-parity veto to inspect raw applied colors.
 */
export interface ExtendedScorecard extends ScorecardJson {
  /** Computed color strings applied to rendered elements (e.g. "rgb(163, 175, 194)"). */
  applied_colors?: string[];
  /** Detailed color+selector pairs from the rendered DOM. */
  color_pairs?: Array<{
    selector: string;
    color: string;
    background_color: string;
  }>;
}

// ─── Veto Pipeline ───────────────────────────────────────────────────────────

/** Result of a veto check — vetoed=false means aesthetic scoring is permitted. */
export interface VetoResult {
  vetoed: boolean;
  /** Human-readable evidence line cited in all.brand_fidelity on veto. */
  evidence: string;
}

/**
 * Convert a CSS hex color (#rrggbb or #rgb) to rgb(r, g, b) format.
 * Returns null if the input is not a valid hex color string.
 */
export function hexToRgb(hex: string): string | null {
  const trimmed = hex.trim();
  const shortHex = trimmed.match(/^#([0-9a-f]{3})$/i);
  if (shortHex) {
    const r = parseInt(shortHex[1][0] + shortHex[1][0], 16);
    const g = parseInt(shortHex[1][1] + shortHex[1][1], 16);
    const b = parseInt(shortHex[1][2] + shortHex[1][2], 16);
    return `rgb(${r}, ${g}, ${b})`;
  }
  const fullHex = trimmed.match(/^#([0-9a-f]{6})$/i);
  if (fullHex) {
    const r = parseInt(fullHex[1].slice(0, 2), 16);
    const g = parseInt(fullHex[1].slice(2, 4), 16);
    const b = parseInt(fullHex[1].slice(4, 6), 16);
    return `rgb(${r}, ${g}, ${b})`;
  }
  return null;
}

/**
 * Build the set of allowed RGB color strings from the scorecard's --tl-color-* tokens.
 *
 * A color is "on-token" if its resolved rgb() value appears in this set.
 * Tokens that are not --tl-color-* (e.g. --tl-space-*, --tl-font-size-*) are excluded.
 */
export function buildTokenRgbSet(tokens: Record<string, string>): Set<string> {
  const allowed = new Set<string>();
  for (const [key, value] of Object.entries(tokens)) {
    if (!key.startsWith("--tl-color")) continue;
    const v = value.trim();
    // Accept hex: convert to rgb
    const rgb = hexToRgb(v);
    if (rgb) {
      allowed.add(rgb.toLowerCase());
    }
    // Also accept the raw rgb() form if the token is already in that format
    if (v.startsWith("rgb(")) {
      allowed.add(v.replace(/\s+/g, " ").toLowerCase().trim());
    }
  }
  return allowed;
}

/**
 * Check the --tl-* token-parity brand veto (MODE A, $0).
 *
 * Fires when any applied_color in the scorecard is NOT present in the --tl-color-*
 * token set. A raw hex color used directly in inline styles or CSS (instead of
 * var(--tl-color-*)) will not appear in the token set and triggers the veto.
 *
 * Dark↔light parity: the scorecard's token set is resolved for its theme, so a
 * light-mode color applied in a dark-mode render would also be off-token.
 *
 * Returns vetoed=false if:
 *   - No applied_colors were captured (conservative pass — no evidence of violation)
 *   - All applied colors are transparent (rgba(0,0,0,0)) or map to a token
 *
 * This function is exported for direct testing in the refute battery (veto-ordering twin).
 */
export function checkTokenParityVeto(scorecard: ExtendedScorecard): VetoResult {
  const applied = scorecard.applied_colors ?? [];

  if (applied.length === 0) {
    return {
      vetoed: false,
      evidence: "Token-parity: no applied_colors captured — check skipped (conservative pass).",
    };
  }

  const allowedRgb = buildTokenRgbSet(scorecard.tokens);

  const offToken: string[] = [];
  for (const color of applied) {
    const norm = color.replace(/\s+/g, " ").toLowerCase().trim();
    // Transparent values are always permitted
    if (norm === "rgba(0, 0, 0, 0)" || norm === "transparent") continue;
    if (!allowedRgb.has(norm)) {
      offToken.push(color);
    }
  }

  if (offToken.length === 0) {
    return {
      vetoed: false,
      evidence: "Token-parity: all applied colors resolve to --tl-color-* tokens.",
    };
  }

  const sample = offToken.slice(0, 3).join(", ");
  const extra = offToken.length > 3 ? ` … (${offToken.length - 3} more)` : "";
  return {
    vetoed: true,
    evidence:
      `token-parity veto: ${offToken.length} off-token color${offToken.length > 1 ? "s" : ""} ` +
      `detected in applied_colors — not in --tl-color-* token set: ${sample}${extra}. ` +
      `Use var(--tl-color-*) instead of raw hex/rgb values.`,
  };
}

/**
 * Check the mechanical gate (MODE A hard-block, $0).
 *
 * Reads the committed scorecard mode_b fields. Fires on any MODE A hard-block:
 *   - card_nesting_depth > 3: card-in-card-in-card anti-pattern (explicitly named in D-03)
 *   - type_size_count < 2: all text at one size — no typographic hierarchy signal
 *
 * If the scorecard's band is 0 (reserved for MODE A total failure), also fires.
 */
export function checkMechanicalGate(scorecard: ScorecardJson): VetoResult {
  const m = scorecard.mode_b;

  if (m.card_nesting_depth > 3) {
    return {
      vetoed: true,
      evidence:
        `mechanical gate: card_nesting_depth=${m.card_nesting_depth} exceeds ` +
        `the 3-level ceiling (MODE A hard-block).`,
    };
  }

  if (m.type_size_count < 2) {
    return {
      vetoed: true,
      evidence:
        `mechanical gate: type_size_count=${m.type_size_count} < 2 floor ` +
        `(MODE A hard-block — no typographic hierarchy signal).`,
    };
  }

  return {
    vetoed: false,
    evidence: "Mechanical gate: all MODE A checks pass.",
  };
}

/**
 * Run the full veto pipeline for a capture cell (RUNNER-03):
 *   (1) Mechanical gate — MODE A hard-block ($0)
 *   (2) Token-parity brand veto — --tl-color-* parity ($0)
 *
 * Returns the first veto that fires, or vetoed=false if both pass.
 * The evidence string is cited verbatim in all.brand_fidelity when vetoed=true.
 */
export function runVetoPipeline(scorecard: ExtendedScorecard): VetoResult {
  // Step 1: Mechanical gate
  const mech = checkMechanicalGate(scorecard);
  if (mech.vetoed) return mech;

  // Step 2: Token-parity brand veto
  const token = checkTokenParityVeto(scorecard);
  if (token.vetoed) return token;

  return {
    vetoed: false,
    evidence: "Veto pipeline: all gates pass — aesthetic scoring enabled.",
  };
}

// ─── Cell Score Types ─────────────────────────────────────────────────────────

/**
 * An aesthetically-scored lens-cell.
 * current=null means unstable (NEVER 0 — would poison min() rollup, D-04 Pitfall 5).
 */
export interface AestheticCellScore {
  current: number | null;
  stable: boolean;
  vetoed: false;
}

/**
 * A vetoed lens-cell.
 * Written to all.brand_fidelity when the veto pipeline fires.
 * The vetoed=true flag distinguishes it from an unstable cell (both write null).
 */
export interface VetoCellScore {
  current: null;
  stable: false;
  vetoed: true;
  evidence: string;
}

/**
 * A lens-cell that was not scored because the veto pipeline fired for this capture cell.
 * Aesthetic vision calls (persona + graphic-design) are skipped entirely on veto.
 * skipped=true distinguishes this from an unstable cell.
 */
export interface SkippedCellScore {
  current: null;
  stable: false;
  vetoed: false;
  skipped: true;
  reason: string;
}

export type CellScore = AestheticCellScore | VetoCellScore | SkippedCellScore;

/**
 * Full 14-lens-cell result for one capture cell.
 *
 * Layout:
 *   - brand_fidelity: always written (VetoCellScore when vetoed, AestheticCellScore otherwise)
 *   - p1_hierarchy .. p5_density: SkippedCellScore on veto, AestheticCellScore otherwise
 *   - all_rhythm, all_typography, all_color_contrast: same as personas
 *   - rollup: min() over all non-null stable scores; losing_cell names the (persona,lens)
 */
export interface PanelCellResult {
  cellId: string;
  brand_fidelity: VetoCellScore | AestheticCellScore;
  p1_hierarchy: CellScore;
  p1_density: CellScore;
  p2_hierarchy: CellScore;
  p2_density: CellScore;
  p3_hierarchy: CellScore;
  p3_density: CellScore;
  p4_hierarchy: CellScore;
  p4_density: CellScore;
  p5_hierarchy: CellScore;
  p5_density: CellScore;
  all_rhythm: CellScore;
  all_typography: CellScore;
  all_color_contrast: CellScore;
  rollup: {
    /** min() over all stable non-null scores. Null if no stable cells exist. */
    min_score: number | null;
    /**
     * Names the losing (persona, lens) cell.
     * Example: "page.actor.happy__dark-1280 p3.hierarchy = 48"
     * (D-06: persona disagreement is PRESERVED; P1-high/P3-low is signal, not averaged)
     */
    losing_cell: string;
  };
}

// ─── Internal Helpers ────────────────────────────────────────────────────────

/** Lens → dimensions map (13 total across 6 lenses, mirrored from run.ts). */
const LENS_DIMENSIONS: Record<LensName, string[]> = {
  hierarchy: ["entry_point_clarity", "scan_path_reading_order", "emphasis_discipline"],
  density: ["signal_to_chrome", "task_primary_prominence"],
  rhythm: ["grouping_by_proximity", "vertical_cadence_coherence"],
  typography: ["role_differentiation", "scale_expresses_hierarchy"],
  color_contrast: ["color_as_signal", "accent_job_discipline"],
  brand_fidelity: ["designed_not_recolored", "register_voice_fit"],
};

/** Read the rubric version header from a committed rubric file. */
function getRubricVersion(lens: LensName): string {
  const path = resolve(rubricDir, `${lens}.md`);
  if (!existsSync(path)) return `${lens}@0.0.0+00000000`;
  const text = readFileSync(path, "utf8");
  const m = text.match(/<!--\s*lens:\s*\S+\s*\|\s*version:\s*(\S+)\s*\|\s*sha8:\s*(\S+)\s*-->/);
  if (!m) return `${lens}@0.0.0+00000000`;
  return `${lens}@${m[1]}+${m[2]}`;
}

/** Extract the sha8 component from a rubric version string. */
function getRubricHash(rubricVersion: string): string {
  const m = rubricVersion.match(/\+([a-f0-9]+)$/);
  return m ? m[1] : "00000000";
}

/** Build a skipped score for aesthetic cells when the veto fires. */
function skippedScore(reason: string): SkippedCellScore {
  return { current: null, stable: false, vetoed: false, skipped: true, reason };
}

/**
 * Score one (cell, lens, dimension, persona) via the Anthropic client.
 * Checks the verdict cache first; writes result to both critic-scores/ and cache.
 */
async function scoreOneDimension(
  cellId: string,
  lens: LensName,
  dimension: string,
  persona: string,
  bundle: ScorecardBundle,
  client: Anthropic,
  rubricVersion: string,
  force: boolean,
): Promise<{ score: number | null; stable: boolean }> {
  const rubricHash = getRubricHash(rubricVersion);
  // sha8 of the screenshot being scored (197-01): binds the verdict to the exact pixels,
  // so a re-captured screenshot MISSES instead of returning a stale cached verdict.
  const screenshotHash = sha8OfFile(
    resolve(bundle.repoRoot, bundle.scorecard.artifacts.screenshot),
  );

  // Verdict cache check (D-07: free resume/replay without re-billing)
  if (!force) {
    const cached = lookupCache(
      cellId,
      `${lens}.${dimension}.${persona}`,
      rubricHash,
      MODEL_ID,
      screenshotHash,
    );
    if (cached) {
      return { score: cached.stable ? cached.score : null, stable: cached.stable };
    }
  }

  const strata = buildPrompt(lens, dimension, persona, bundle);
  const result = await runNSamples(client, strata, lens);

  // Write stamped output to .planning/critic-scores/ (NEVER .planning/scorecards/)
  writeCriticScore({
    cellId,
    lens,
    dimension,
    modelId: MODEL_ID,
    rubricVersion,
    n: result.n,
    scoresRaw: result.scoresRaw,
    score: result.score,
    band: result.band,
    bandMode: result.bandMode,
    iqr: result.iqr,
    range: result.range,
    stable: result.stable,
    pass: result.pass,
    evidence: result.evidence,
    rationale: result.rationale,
  });

  // Write to verdict cache for resume/replay (bound to the scored screenshot, 197-01)
  writeCache({
    cell_id: cellId,
    dimension: `${lens}.${dimension}.${persona}`,
    rubric_hash: rubricHash,
    model_id: MODEL_ID,
    screenshot_hash: screenshotHash,
    result: {
      evidence: result.evidence,
      pass: result.pass,
      band: (result.band ?? "fail") as BandName,
      score: result.score ?? 0,
      lens,
      rationale: result.rationale,
    },
    n: result.n,
    scores_raw: result.scoresRaw,
    score: result.score ?? 0,
    band: result.band ?? "fail",
    band_mode: result.bandMode,
    iqr: result.iqr,
    range: result.range,
    stable: result.stable,
    cached_at: new Date().toISOString(),
  });

  return { score: result.stable ? (result.score ?? null) : null, stable: result.stable };
}

/**
 * Score all dimensions for a (cell, lens, persona) and aggregate to a single lens score.
 *
 * Aggregation: median of dimension scores (D-10 band-of-median applied to the aggregate).
 * If any dimension is unstable (null), the aggregate is also null (conservative).
 */
async function scoreLens(
  cellId: string,
  lens: LensName,
  persona: string,
  bundle: ScorecardBundle,
  client: Anthropic,
  rubricVersion: string,
  force: boolean,
): Promise<AestheticCellScore> {
  const dims = LENS_DIMENSIONS[lens];
  const dimResults: Array<{ score: number | null; stable: boolean }> = [];

  for (const dim of dims) {
    const r = await scoreOneDimension(cellId, lens, dim, persona, bundle, client, rubricVersion, force);
    dimResults.push(r);
  }

  // If any dimension is unstable, the lens score is unstable
  const allStable = dimResults.every((d) => d.stable);
  const hasNull = dimResults.some((d) => d.score === null);

  if (!allStable || hasNull) {
    return { current: null, stable: false, vetoed: false };
  }

  // Median of dimension scores
  const scores = (dimResults.map((d) => d.score) as number[]).sort((a, b) => a - b);
  const mid = Math.floor(scores.length / 2);
  const med =
    scores.length % 2 === 0
      ? (scores[mid - 1] + scores[mid]) / 2
      : scores[mid];

  return { current: Math.round(med), stable: true, vetoed: false };
}

/**
 * Compute the min() rollup over all 14 lens-cells, naming the losing (persona, lens) cell.
 *
 * Only stable scored cells (current !== null, vetoed=false, !skipped) contribute.
 * Null when no stable scored cells exist (all vetoed, unstable, or skipped).
 *
 * Persona disagreement is PRESERVED in the losing_cell name:
 * e.g. "page.actor.happy__dark-1280 p3.hierarchy = 48" signals that P3's JTBD
 * is the constraining factor, not P1's (which may score higher on the same lens).
 */
function computeRollup(
  cellId: string,
  scores: Record<string, CellScore>,
): PanelCellResult["rollup"] {
  const candidates: Array<{ key: string; score: number }> = [];

  for (const [key, cs] of Object.entries(scores)) {
    if (!cs.vetoed && !("skipped" in cs) && cs.current !== null) {
      candidates.push({ key, score: cs.current });
    }
  }

  if (candidates.length === 0) {
    return { min_score: null, losing_cell: `${cellId}: no stable scored cells` };
  }

  const losing = candidates.reduce((min, e) => (e.score < min.score ? e : min));
  return {
    min_score: losing.score,
    losing_cell: `${cellId} ${losing.key} = ${losing.score}`,
  };
}

// ─── Public API ──────────────────────────────────────────────────────────────

export interface RunPanelOptions {
  /** Anthropic client instance (required for actual API calls; can be omitted for dry-run). */
  client?: Anthropic;
  /** Re-score even if verdict cache has a hit. Default: false. */
  force?: boolean;
  /** Print budget estimate without making any API calls. Default: false. */
  dryRun?: boolean;
}

/**
 * Run the full 7-critic panel for a single capture cell (RUNNER-03).
 *
 * Pipeline:
 *   (1) Load scorecard bundle from .planning/scorecards/
 *   (2) Run veto pipeline ($0, deterministic)
 *       → On veto: return vetoed PanelCellResult immediately (no aesthetic calls)
 *   (3) No veto: fan out vision calls in this order (pre-warm pattern):
 *       (a) Graphic-design lenses first (rhythm, typography, color_contrast, brand_fidelity)
 *           — establishes cached prefixes before the five-persona sweep (D-04 TTL pre-warm)
 *       (b) Persona critics (P1–P5), each scoring hierarchy + density
 *           — each call is blind (no sibling output in context, D-06)
 *           — persona clause placed AFTER the cache boundary (D-11 anti-pattern 2 prevention)
 *   (4) Compute min() rollup naming the losing (persona, lens) cell.
 *
 * Returns a complete PanelCellResult with 14 lens-cells + rollup.
 * In dry-run mode (or when client is omitted), returns null scores without API calls.
 *
 * @param cellId - Full scorecard cell ID (e.g. "page.actor.happy__dark-1280")
 * @param opts - See RunPanelOptions
 */
export async function runPanel(
  cellId: string,
  opts: RunPanelOptions = {},
): Promise<PanelCellResult> {
  const bundle = await loadBundle(cellId);
  const sc = bundle.scorecard as ExtendedScorecard;

  // ── Veto pipeline ($0, always runs) ──────────────────────────────────────
  const veto = runVetoPipeline(sc);

  if (veto.vetoed) {
    // Vetoed: brand_fidelity = null+vetoed; all aesthetic cells = skipped
    const vetoCell: VetoCellScore = {
      current: null,
      stable: false,
      vetoed: true,
      evidence: veto.evidence,
    };
    const skip = skippedScore(`veto: ${veto.evidence}`);

    return {
      cellId,
      brand_fidelity: vetoCell,
      p1_hierarchy: skip, p1_density: skip,
      p2_hierarchy: skip, p2_density: skip,
      p3_hierarchy: skip, p3_density: skip,
      p4_hierarchy: skip, p4_density: skip,
      p5_hierarchy: skip, p5_density: skip,
      all_rhythm: skip, all_typography: skip, all_color_contrast: skip,
      rollup: {
        min_score: null,
        losing_cell: `${cellId}: vetoed — ${veto.evidence}`,
      },
    };
  }

  // ── Dry-run or no client: return null scores without API calls ────────────
  if (opts.dryRun || !opts.client) {
    const empty: AestheticCellScore = { current: null, stable: false, vetoed: false };
    return {
      cellId,
      brand_fidelity: empty,
      p1_hierarchy: empty, p1_density: empty,
      p2_hierarchy: empty, p2_density: empty,
      p3_hierarchy: empty, p3_density: empty,
      p4_hierarchy: empty, p4_density: empty,
      p5_hierarchy: empty, p5_density: empty,
      all_rhythm: empty, all_typography: empty, all_color_contrast: empty,
      rollup: {
        min_score: null,
        losing_cell: `${cellId}: dry-run — no API calls made`,
      },
    };
  }

  // ── Aesthetic vision calls (no veto) ─────────────────────────────────────
  const client = opts.client;
  const force = opts.force ?? false;

  // Pre-compute rubric versions once (not per-call)
  const rvHierarchy = getRubricVersion("hierarchy");
  const rvDensity = getRubricVersion("density");
  const rvRhythm = getRubricVersion("rhythm");
  const rvTypography = getRubricVersion("typography");
  const rvColorContrast = getRubricVersion("color_contrast");
  const rvBrandFidelity = getRubricVersion("brand_fidelity");

  // Pre-warm: score graphic-design lenses first to establish cached prefixes
  // before the five-persona sweep. This keeps the Opus 4.8 5-min TTL alive
  // when the full sweep takes longer than the TTL window (D-04).
  //
  // Order: graphic-design (all) → persona critics (P1–P5)
  // Each critic is blind — no sibling output ever appears in any call's context.

  // Graphic-design lenses (persona = "all")
  const allRhythm = await scoreLens(cellId, "rhythm", "all", bundle, client, rvRhythm, force);
  const allTypography = await scoreLens(cellId, "typography", "all", bundle, client, rvTypography, force);
  const allColorContrast = await scoreLens(cellId, "color_contrast", "all", bundle, client, rvColorContrast, force);
  const allBrandFidelity = await scoreLens(cellId, "brand_fidelity", "all", bundle, client, rvBrandFidelity, force);

  // Persona critics (each blind, each with its own JTBD pass-condition in uncached suffix)
  const p1h = await scoreLens(cellId, "hierarchy", "p1", bundle, client, rvHierarchy, force);
  const p1d = await scoreLens(cellId, "density", "p1", bundle, client, rvDensity, force);
  const p2h = await scoreLens(cellId, "hierarchy", "p2", bundle, client, rvHierarchy, force);
  const p2d = await scoreLens(cellId, "density", "p2", bundle, client, rvDensity, force);
  const p3h = await scoreLens(cellId, "hierarchy", "p3", bundle, client, rvHierarchy, force);
  const p3d = await scoreLens(cellId, "density", "p3", bundle, client, rvDensity, force);
  const p4h = await scoreLens(cellId, "hierarchy", "p4", bundle, client, rvHierarchy, force);
  const p4d = await scoreLens(cellId, "density", "p4", bundle, client, rvDensity, force);
  const p5h = await scoreLens(cellId, "hierarchy", "p5", bundle, client, rvHierarchy, force);
  const p5d = await scoreLens(cellId, "density", "p5", bundle, client, rvDensity, force);

  const allScores: Record<string, CellScore> = {
    "brand_fidelity": allBrandFidelity,
    "p1.hierarchy": p1h, "p1.density": p1d,
    "p2.hierarchy": p2h, "p2.density": p2d,
    "p3.hierarchy": p3h, "p3.density": p3d,
    "p4.hierarchy": p4h, "p4.density": p4d,
    "p5.hierarchy": p5h, "p5.density": p5d,
    "all.rhythm": allRhythm,
    "all.typography": allTypography,
    "all.color_contrast": allColorContrast,
  };

  return {
    cellId,
    brand_fidelity: allBrandFidelity,
    p1_hierarchy: p1h, p1_density: p1d,
    p2_hierarchy: p2h, p2_density: p2d,
    p3_hierarchy: p3h, p3_density: p3d,
    p4_hierarchy: p4h, p4_density: p4d,
    p5_hierarchy: p5h, p5_density: p5d,
    all_rhythm: allRhythm,
    all_typography: allTypography,
    all_color_contrast: allColorContrast,
    rollup: computeRollup(cellId, allScores),
  };
}
