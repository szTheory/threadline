/**
 * cache.ts — Verdict cache for the adversarial critic runner.
 *
 * Keyed on {cell_id}__{dimension}__{rubric_hash}__{model_id} → fs JSON.
 * Enables free resume/replay of completed cells without re-billing (D-07/D-04).
 *
 * The rubric_hash is the sha8 component of the rubric version string (e.g. "ab3f1234"),
 * so a rubric edit auto-invalidates the cache for affected cells.
 *
 * Cache location: .planning/critic-verdict-cache/ (gitignored)
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { CriticDimensionResult } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const verdictCacheDir = resolve(repoRoot, ".planning/critic-verdict-cache");

export interface CachedVerdict {
  cell_id: string;
  dimension: string;
  rubric_hash: string;
  model_id: string;
  result: CriticDimensionResult;
  n: number;
  scores_raw: number[];
  score: number;
  band: string;
  band_mode: string;
  iqr: number;
  range: number;
  stable: boolean;
  cached_at: string;
}

function writeJson(path: string, value: unknown): void {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function cacheKey(
  cellId: string,
  dimension: string,
  rubricHash: string,
  modelId: string,
): string {
  // Sanitize key components to prevent path traversal
  const safe = (s: string) => s.replace(/[^a-zA-Z0-9._-]/g, "_");
  return `${safe(cellId)}__${safe(dimension)}__${safe(rubricHash)}__${safe(modelId)}`;
}

function cachePath(key: string): string {
  return resolve(verdictCacheDir, `${key}.json`);
}

/**
 * Look up a cached verdict by (cellId, dimension, rubricHash, modelId).
 * Returns the cached verdict if found, or null on miss.
 */
export function lookupCache(
  cellId: string,
  dimension: string,
  rubricHash: string,
  modelId: string,
): CachedVerdict | null {
  const key = cacheKey(cellId, dimension, rubricHash, modelId);
  const path = cachePath(key);
  if (!existsSync(path)) return null;
  try {
    return JSON.parse(readFileSync(path, "utf8")) as CachedVerdict;
  } catch {
    return null; // corrupt cache entry — treat as miss
  }
}

/**
 * Write a verdict to the cache.
 */
export function writeCache(verdict: CachedVerdict): void {
  if (!existsSync(verdictCacheDir)) {
    mkdirSync(verdictCacheDir, { recursive: true });
  }
  const key = cacheKey(
    verdict.cell_id,
    verdict.dimension,
    verdict.rubric_hash,
    verdict.model_id,
  );
  writeJson(cachePath(key), verdict);
}
