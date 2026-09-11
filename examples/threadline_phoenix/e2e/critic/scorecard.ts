/**
 * scorecard.ts — Writes per-dimension critic scores to the generated score root.
 *
 * Output tree: <cell_id>/<lens>/<dimension>.json
 *
 * INVARIANT: NEVER writes under committed scorecards — that tree is the deterministic
 * committed bundle gated by verify.mechanical in ci.all. LLM output goes ONLY under
 * critic-scores/. This is enforced by the guard in critic_trust_test.exs.
 *
 * Stamping fields (D-07/RUNNER-02): every output file includes model_id, rubric_version,
 * n, scores_raw, score, band, band_mode, iqr, range, stable, pass, evidence, rationale, scored_at.
 *
 * Unstable cells set score and current to null (NEVER 0) — D-04 / Pitfall 5.
 */

import { existsSync, mkdirSync } from "node:fs";
import type { CriticDimensionResult, LensName } from "./schema.js";
import {
  atomicWriteFile,
  currentOperatorSurfacePaths,
  resolveContainedPath,
  type AtomicWriteOptions,
} from "../support/operator-surface-paths.js";

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

function writeJson(path: string, value: unknown, options: AtomicWriteOptions): void {
  // Two-space indent + trailing newline: byte-stable convention (matches project scorecards)
  atomicWriteFile(path, `${JSON.stringify(value, null, 2)}\n`, options);
}

/**
 * Write a stamped critic-score file for one (cell, lens, dimension).
 *
 * T-195-16 guard: shared canonical containment keeps every constructed path under
 * the generated root. The ExUnit guard supplies the independent CI assertion.
 */
export function writeCriticScore(
  params: ScorecardWriteParams,
  options: AtomicWriteOptions = {},
): void {
  const { criticScoresDir } = currentOperatorSurfacePaths();
  if (!existsSync(criticScoresDir)) mkdirSync(criticScoresDir, { recursive: true });
  const outputDir = resolveContainedPath(
    criticScoresDir,
    `${params.cellId}/${params.lens}`,
  );

  mkdirSync(outputDir, { recursive: true });

  const outputPath = resolveContainedPath(outputDir, `${params.dimension}.json`);

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

  writeJson(outputPath, output, options);
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
  return resolveContainedPath(
    currentOperatorSurfacePaths().criticScoresDir,
    `${cellId}/${lens}/${dimension}.json`,
  );
}

/**
 * Check whether a score file already exists on disk.
 */
export function criticScoreExists(
  cellId: string,
  lens: LensName,
  dimension: string,
): boolean {
  if (!existsSync(currentOperatorSurfacePaths().criticScoresDir)) return false;
  return existsSync(criticScorePath(cellId, lens, dimension));
}
