/**
 * scorecard.ts — Writes per-dimension critic scores to .planning/critic-scores/.
 *
 * Output tree: .planning/critic-scores/<cell_id>/<lens>/<dimension>.json
 *
 * INVARIANT: NEVER writes under .planning/scorecards/ — that tree is the deterministic
 * committed bundle gated by verify.mechanical in ci.all. LLM output goes ONLY under
 * critic-scores/. This is enforced by the guard in critic_trust_test.exs.
 *
 * Stamping fields (D-07/RUNNER-02): every output file includes model_id, rubric_version,
 * n, scores_raw, score, band, band_mode, iqr, range, stable, pass, evidence, rationale, scored_at.
 *
 * Unstable cells set score and current to null (NEVER 0) — D-04 / Pitfall 5.
 */

import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { CriticDimensionResult, LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");

// The ONLY permitted write root — guard: never under .planning/scorecards/
const CRITIC_SCORES_ROOT = resolve(repoRoot, ".planning/critic-scores");
// Prohibited root — never write here (asserted by critic_trust_test.exs)
const FORBIDDEN_ROOT = resolve(repoRoot, ".planning/scorecards");

export interface ScorecardWriteParams {
  cellId: string;
  lens: LensName;
  dimension: string;
  modelId: string;
  rubricVersion: string;
  n: number;
  scoresRaw: number[];
  score: number | null;  // null when unstable (NEVER 0)
  band: string | null;   // null when unstable
  bandMode: string;
  iqr: number;
  range: number;
  stable: boolean;
  pass: boolean;
  evidence: CriticDimensionResult["evidence"];
  rationale: string;
}

export interface ScorecardOutput {
  cell_id: string;
  lens: LensName;
  dimension: string;
  model_id: string;
  rubric_version: string;
  n: number;
  scores_raw: number[];
  score: number | null;
  band: string | null;
  band_mode: string;
  iqr: number;
  range: number;
  stable: boolean;
  pass: boolean;
  evidence: CriticDimensionResult["evidence"];
  rationale: string;
  scored_at: string;
}

function writeJson(path: string, value: unknown): void {
  // Two-space indent + trailing newline: byte-stable convention (matches project scorecards)
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

/**
 * Write a stamped critic-score file for one (cell, lens, dimension).
 *
 * T-195-16 guard: throws if any constructed path resolves under FORBIDDEN_ROOT
 * (.planning/scorecards/). This is an in-process check; the ExUnit guard in
 * critic_trust_test.exs provides the CI-level assertion.
 */
export function writeCriticScore(params: ScorecardWriteParams): void {
  // Guard (T-195-16): verify output path is inside critic-scores/, NOT scorecards/
  const outputDir = resolve(CRITIC_SCORES_ROOT, params.cellId, params.lens);

  if (outputDir.startsWith(FORBIDDEN_ROOT)) {
    throw new Error(
      `[scorecard] FATAL: attempted write under .planning/scorecards/ (T-195-16 guard).\n` +
        `Constructed path: ${outputDir}\n` +
        `Critic output must go under .planning/critic-scores/ ONLY.`,
    );
  }

  mkdirSync(outputDir, { recursive: true });

  const outputPath = resolve(outputDir, `${params.dimension}.json`);

  const output: ScorecardOutput = {
    cell_id: params.cellId,
    lens: params.lens,
    dimension: params.dimension,
    model_id: params.modelId,
    rubric_version: params.rubricVersion,
    n: params.n,
    scores_raw: params.scoresRaw,
    // unstable → null (NEVER 0) — D-04 Pitfall 5
    score: params.stable ? params.score : null,
    band: params.stable ? params.band : null,
    band_mode: params.bandMode,
    iqr: params.iqr,
    range: params.range,
    stable: params.stable,
    pass: params.pass,
    evidence: params.evidence,
    rationale: params.rationale,
    scored_at: new Date().toISOString(),
  };

  writeJson(outputPath, output);
}

/**
 * Returns the output path for a given (cellId, lens, dimension).
 * Useful for checking existence before re-scoring (cache check).
 */
export function criticScorePath(
  cellId: string,
  lens: LensName,
  dimension: string,
): string {
  return resolve(CRITIC_SCORES_ROOT, cellId, lens, `${dimension}.json`);
}

/**
 * Check whether a score file already exists on disk.
 */
export function criticScoreExists(
  cellId: string,
  lens: LensName,
  dimension: string,
): boolean {
  return existsSync(criticScorePath(cellId, lens, dimension));
}
