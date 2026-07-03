/**
 * client.ts — Anthropic SDK wrapper with N-sample self-consistency engine.
 *
 * Implements RUNNER-01 + RUNNER-02:
 *   - messages.parse() with zodOutputFormat (CRITIC-05, schema-enforced evidence)
 *   - NO temperature/top_p/top_k/budget_tokens (returns 400 on Opus 4.8)
 *   - Adaptive thinking: display:"summarized" (NOT the omitted default)
 *   - N-sample loop: N=3 → escalate to N=7 → N=7 stability re-test
 *   - Median + band-of-median + band-mode + IQR/range variance gates
 *   - Unstable → score/band = null (NEVER 0) — Pitfall 5
 *   - Cache hit assertion: warns if cache_read_input_tokens == 0 on subsequent calls
 *   - SDK auto-retry handles 429/5xx; no manual retry loop
 *
 * D-04 escalation triggers (any one → escalate N=3 → N=7):
 *   1. No strict majority band: count(modal band) < ceil(N/2)
 *   2. Median within ±2 pts of a band cut (35, 55, 70, 85)
 *   3. Median within ≤5 pts of floor (0) or target (100)
 *
 * D-04 instability rule (N=7, any one → unstable → null):
 *   1. Band-mode count < ceil(7/2) = 4
 *   2. IQR > 10
 *   3. Range > 15
 */

import Anthropic from "@anthropic-ai/sdk";
import { MODEL_ID, BAND_CUTS, scoreToBand, criticOutputFormat } from "./schema.js";
import type { CriticDimensionResult, BandName } from "./schema.js";
import type { PromptStrata } from "./prompt.js";

const BAND_NAMES: BandName[] = ["fail", "weak", "ok", "strong", "exemplary"];

// Band cut points for escalation trigger #2
const BAND_CUT_POINTS = [35, 55, 70, 85];

// Max tokens for the critic response (structured output + thinking)
const MAX_TOKENS = 4096;

// Whether to log cache usage (enabled in development; quiet in batch mode)
const DEBUG_CACHE = process.env.CRITIC_DEBUG_CACHE === "1";

export interface SamplingResult {
  scoresRaw: number[];
  score: number | null;      // median, null if unstable
  band: BandName | null;     // band of median, null if unstable
  bandMode: BandName;        // modal band across samples
  iqr: number;
  range: number;
  stable: boolean;
  n: number;
  // Best evidence from the run (from the sample nearest the median)
  evidence: CriticDimensionResult["evidence"];
  rationale: string;
  pass: boolean;
}

/**
 * Create a shared Anthropic client (reads ANTHROPIC_API_KEY from env).
 * The SDK auto-retries 429/5xx with jittered backoff.
 */
export function createClient(): Anthropic {
  return new Anthropic();
}

/** Clamp score to 0-100 client-side (SDK strips numeric bounds from schema). */
function clampScore(s: number): number {
  return Math.max(0, Math.min(100, s));
}

/** Compute the median of an array of numbers (sorted). */
function median(sorted: number[]): number {
  const n = sorted.length;
  if (n === 0) throw new Error("Cannot compute median of empty array");
  const mid = Math.floor(n / 2);
  return n % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
}

/** Compute IQR (Q3 - Q1) of a sorted array. */
function iqr(sorted: number[]): number {
  const n = sorted.length;
  const q1 = sorted[Math.floor(n / 4)];
  const q3 = sorted[Math.floor((3 * n) / 4)];
  return q3 - q1;
}

/** Find the modal band and its count across a set of raw scores. */
function bandMode(scores: number[]): { band: BandName; count: number } {
  const counts: Record<BandName, number> = {
    fail: 0,
    weak: 0,
    ok: 0,
    strong: 0,
    exemplary: 0,
  };
  for (const s of scores) {
    counts[scoreToBand(s)]++;
  }
  let maxCount = 0;
  let maxBand: BandName = "fail";
  for (const band of BAND_NAMES) {
    if (counts[band] > maxCount) {
      maxCount = counts[band];
      maxBand = band;
    }
  }
  return { band: maxBand, count: maxCount };
}

/**
 * Check if the median score is near a band cut (within ±2 pts) or near the floor/target.
 * Triggers N escalation (D-04 trigger #2 and #3).
 */
function isNearBoundary(med: number): boolean {
  // Near a band cut (±2 pts)
  for (const cut of BAND_CUT_POINTS) {
    if (Math.abs(med - cut) <= 2) return true;
  }
  // Near floor (≤5 pts from 0)
  if (med <= 5) return true;
  // Near target (≤5 pts from 100)
  if (med >= 95) return true;
  return false;
}

/**
 * Single call to the Anthropic API for one dimension.
 * Returns the parsed structured output.
 *
 * Prohibitions (return 400 on Opus 4.8 if sent):
 *   - temperature, top_p, top_k
 *   - budget_tokens (adaptive thinking uses display:"summarized" only)
 */
async function callOnce(
  client: Anthropic,
  strata: PromptStrata,
  callIndex: number,
  lens: string,
): Promise<{ result: CriticDimensionResult; cacheRead: number; cacheCreate: number }> {
  const response = await client.messages.parse({
    model: MODEL_ID,
    max_tokens: MAX_TOKENS,
    thinking: {
      type: "adaptive",
      display: "summarized",
      // budget_tokens MUST NOT be sent — returns 400 on Opus 4.8
    },
    // temperature / top_p / top_k MUST NOT be sent — returns 400 on Opus 4.8
    system: strata.system,
    messages: strata.messages,
    output_config: {
      format: criticOutputFormat,
    },
  });

  const usage = response.usage as unknown as Record<string, number>;
  const cacheRead = usage["cache_read_input_tokens"] ?? 0;
  const cacheCreate = usage["cache_creation_input_tokens"] ?? 0;

  // Cache hit assertion (D-04 / RESEARCH Pattern 2):
  // First call of a lens sweep: assert cache_creation_input_tokens > 4096
  // Subsequent calls: warn if cache_read_input_tokens == 0 (silent cache miss)
  if (callIndex === 0) {
    if (cacheCreate <= 4096 && DEBUG_CACHE) {
      console.warn(
        `[client] WARNING: cache_creation_input_tokens=${cacheCreate} ≤ 4096 for lens ${lens}. ` +
          `The cached prefix may be below the Opus 4.8 floor. ` +
          `Check that pole images are included in the cached prefix.`,
      );
    }
  } else if (cacheRead === 0 && DEBUG_CACHE) {
    console.warn(
      `[client] WARNING: cache_read_input_tokens=0 on call ${callIndex + 1} for lens ${lens}. ` +
          `Possible cache miss: prefix may have changed, TTL exceeded, or floor not cleared.`,
    );
  }

  if (!response.parsed_output) {
    throw new Error(
      `[client] messages.parse() returned null parsed_output on call ${callIndex + 1}. ` +
        `The response likely failed schema validation (evidence.locator missing? CRITIC-05 enforcement).`,
    );
  }

  // Clamp score client-side (SDK strips numeric bounds)
  const raw = response.parsed_output;
  const clamped: CriticDimensionResult = {
    ...raw,
    score: clampScore(raw.score),
  };

  return { result: clamped, cacheRead, cacheCreate };
}

/**
 * Run N samples for one (lens, dimension, persona) and compute self-consistency statistics.
 *
 * Implements the D-04 two-tier N=3→7 escalation logic + variance gates.
 *
 * @param client - Anthropic client instance
 * @param strata - Pre-built prompt strata (system + messages)
 * @param lens - Lens name (for logging and cache assertion)
 * @returns SamplingResult with median, band, stability flags, and best evidence
 */
export async function runNSamples(
  client: Anthropic,
  strata: PromptStrata,
  lens: string,
): Promise<SamplingResult> {
  const allScores: number[] = [];
  const allResults: CriticDimensionResult[] = [];

  // First pass: N=3
  const N1 = 3;
  for (let i = 0; i < N1; i++) {
    const { result } = await callOnce(client, strata, allScores.length, lens);
    allScores.push(result.score);
    allResults.push(result);
  }

  // Check N=3 escalation triggers
  const sorted3 = [...allScores].sort((a, b) => a - b);
  const med3 = median(sorted3);
  const { band: mode3, count: modeCount3 } = bandMode(allScores);
  const hasMajority3 = modeCount3 >= Math.ceil(N1 / 2);
  const nearBound3 = isNearBoundary(med3);

  const shouldEscalate = !hasMajority3 || nearBound3;

  if (shouldEscalate) {
    // Escalate: run 4 more samples to reach N=7
    const N2 = 7;
    for (let i = N1; i < N2; i++) {
      const { result } = await callOnce(client, strata, allScores.length, lens);
      allScores.push(result.score);
      allResults.push(result);
    }
  }

  // Final statistics
  const finalN = allScores.length;
  const sortedFinal = [...allScores].sort((a, b) => a - b);
  const medianScore = median(sortedFinal);
  const { band: modalBand, count: modalCount } = bandMode(allScores);
  const medianBand = scoreToBand(medianScore);
  const iqrVal = iqr(sortedFinal);
  const rangeVal = sortedFinal[sortedFinal.length - 1] - sortedFinal[0];

  // Stability check (D-04 variance gates)
  const majorityThreshold = Math.ceil(finalN / 2);
  const hasStableMajority = modalCount >= majorityThreshold;
  const iqrStable = iqrVal <= 10;
  const rangeStable = rangeVal <= 15;
  const stable = hasStableMajority && iqrStable && rangeStable;

  // Best evidence: pick the result with score closest to median
  const closestIdx = allScores.reduce((bestIdx, score, idx) => {
    return Math.abs(score - medianScore) < Math.abs(allScores[bestIdx] - medianScore)
      ? idx
      : bestIdx;
  }, 0);
  const bestResult = allResults[closestIdx];

  return {
    scoresRaw: allScores,
    // unstable → null (NEVER 0, would poison min() rollup) — D-04 / Pitfall 5
    score: stable ? Math.round(medianScore) : null,
    band: stable ? medianBand : null,
    bandMode: modalBand,
    iqr: iqrVal,
    range: rangeVal,
    stable,
    n: finalN,
    evidence: bestResult.evidence,
    rationale: bestResult.rationale,
    pass: bestResult.pass,
  };
}
