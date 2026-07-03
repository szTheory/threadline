/**
 * schema.ts — Zod schema for per-dimension critic structured output (CRITIC-05).
 *
 * evidence{kind, locator, observation} is REQUIRED — a score without a located citation
 * fails messages.parse() and is discarded, never written to critic-scores/.
 *
 * Field order enforces the D-11 cite-before-score discipline:
 *   evidence → pass → band → score → lens → rationale
 *
 * NOTE: Use `from "zod/v4"` so this stays compatible with @anthropic-ai/sdk 0.110.0,
 * which imports `zod/v4` internally for zodOutputFormat. Zod 3.25+ ships the v4 compat
 * path at that subpath export.
 */

import * as z from "zod/v4";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";

// Pinned for cross-machine reproducibility — never a runtime-derived value.
export const MODEL_ID = "claude-opus-4-8" as const;
export const SCHEMA_VERSION = 1 as const;

// 5-band scale cuts (D-10). Band boundaries are inclusive on the lower end.
export const BAND_CUTS = {
  fail: [0, 34],
  weak: [35, 54],
  ok: [55, 69],
  strong: [70, 84],
  exemplary: [85, 100],
} as const;

export const BAND_LOWER_CUTS: Record<BandName, number> = {
  fail: 0,
  weak: 35,
  ok: 55,
  strong: 70,
  exemplary: 85,
};

export type BandName = "fail" | "weak" | "ok" | "strong" | "exemplary";
export type LensName =
  | "hierarchy"
  | "density"
  | "rhythm"
  | "typography"
  | "color_contrast"
  | "brand_fidelity";

/**
 * Compute the band for a given score (0–100).
 * Uses the D-10 band-of-median rule.
 */
export function scoreToBand(score: number): BandName {
  if (score >= 85) return "exemplary";
  if (score >= 70) return "strong";
  if (score >= 55) return "ok";
  if (score >= 35) return "weak";
  return "fail";
}

/**
 * Per-dimension critic response schema (CRITIC-05 + D-07 + D-11).
 *
 * evidence is NOT optional — any parse response lacking evidence.kind or
 * evidence.locator is rejected by messages.parse() and must never be written.
 */
export const CriticDimensionSchema = z.object({
  // Cite-before-score (D-11): evidence comes first in the field order
  evidence: z.object({
    kind: z.enum(["region", "selector", "mechanical_line"]),
    locator: z.string().min(1), // REQUIRED, min 1 char — CRITIC-05
    observation: z.string(),
  }),
  pass: z.boolean(),
  band: z.enum(["fail", "weak", "ok", "strong", "exemplary"]),
  score: z.number().int(), // SDK strips min/max — clamp to 0-100 client-side after parse
  lens: z.enum([
    "hierarchy",
    "density",
    "rhythm",
    "typography",
    "color_contrast",
    "brand_fidelity",
  ]),
  rationale: z.string(),
});

export type CriticDimensionResult = z.infer<typeof CriticDimensionSchema>;

/**
 * zodOutputFormat for use in client.messages.parse() calls.
 * This is the output_config.format value passed to the Anthropic SDK.
 */
export const criticOutputFormat = zodOutputFormat(CriticDimensionSchema);
