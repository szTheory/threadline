/**
 * cache.ts — Verdict cache for the adversarial critic runner.
 *
 * Keyed on {cell_id}__{dimension}__{rubric_hash}__{model_id}__{screenshot_hash} → fs JSON.
 * Enables free resume/replay of completed cells without re-billing (D-07/D-04).
 *
 * The rubric_hash is the sha8 component of the rubric version string (e.g. "ab3f1234"),
 * so a rubric edit auto-invalidates the cache for affected cells.
 *
 * The screenshot_hash is the sha8 of the cell's screenshot PNG bytes (197-01, OQ-3
 * debt #1), so a re-capture auto-invalidates the cache for the affected cell — a
 * stale verdict can never masquerade as a fresh score after the pixels changed.
 * Old-format (4-part) entries simply MISS under the 5-part key; no migration.
 *
 * Cache location: the adapter-owned generated verdict-cache directory (gitignored)
 */

import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import type { CriticDimensionResult } from "./schema.js";
import {
  atomicWriteFile,
  currentOperatorSurfacePaths,
  resolveContainedPath,
  type AtomicWriteOptions,
} from "../support/operator-surface-paths.js";

export interface CachedVerdict {
  cell_id: string;
  dimension: string;
  rubric_hash: string;
  model_id: string;
  screenshot_hash: string;
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

function writeJson(path: string, value: unknown, options: AtomicWriteOptions): void {
  atomicWriteFile(path, `${JSON.stringify(value, null, 2)}\n`, options);
}

/**
 * Compute the sha8 of a file's bytes (first 8 hex chars of sha256). Used to bind a
 * cached verdict to the exact screenshot PNG it was scored against (197-01).
 */
export function sha8OfFile(path: string): string {
  return createHash("sha256").update(readFileSync(path)).digest("hex").slice(0, 8);
}

function cacheKey(
  cellId: string,
  dimension: string,
  rubricHash: string,
  modelId: string,
  screenshotHash: string,
): string {
  return `${cellId}__${dimension}__${rubricHash}__${modelId}__${screenshotHash}`;
}

function cachePath(key: string): string {
  return resolveContainedPath(currentOperatorSurfacePaths().verdictCacheDir, `${key}.json`);
}

/**
 * Look up a cached verdict by (cellId, dimension, rubricHash, modelId, screenshotHash).
 * Returns the cached verdict if found, or null on miss. A re-captured screenshot
 * changes screenshotHash, so the lookup MISSES — never a stale verdict (197-01).
 */
export function lookupCache(
  cellId: string,
  dimension: string,
  rubricHash: string,
  modelId: string,
  screenshotHash: string,
): CachedVerdict | null {
  if (!existsSync(currentOperatorSurfacePaths().verdictCacheDir)) return null;
  const key = cacheKey(cellId, dimension, rubricHash, modelId, screenshotHash);
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
export function writeCache(
  verdict: CachedVerdict,
  options: AtomicWriteOptions = {},
): void {
  const { verdictCacheDir } = currentOperatorSurfacePaths();
  if (!existsSync(verdictCacheDir)) {
    mkdirSync(verdictCacheDir, { recursive: true });
  }
  const key = cacheKey(
    verdict.cell_id,
    verdict.dimension,
    verdict.rubric_hash,
    verdict.model_id,
    verdict.screenshot_hash,
  );
  writeJson(cachePath(key), verdict, options);
}
