/**
 * bundle.ts — Reads the deterministic Tier-B scorecard input for a cell.
 *
 * Reads:
 *   - .planning/scorecards/<cell_id>.json (deterministic, committed bundle)
 *   - .planning/scorecards/<cell_id>.aria.yml (band-2 only, may be null)
 *   - e2e/artifacts/tier-a/<cell_id>/screenshot.png (gitignored binary)
 *
 * Downsamples the screenshot PNG to ~1092px on the long edge (D-11 / D-04:
 * ~1600 tokens per image, which is load-bearing cache prefix padding). Uses
 * `sips` (macOS, always present in local dev) or `magick` (ImageMagick 7+,
 * cross-platform) via child_process to avoid a native-module dependency.
 *
 * Security (T-195-17): cell_id is validated against committed scorecard files
 * before constructing any filesystem path — no raw interpolation of untrusted input.
 */

import {
  existsSync,
  readFileSync,
  readdirSync,
  mkdtempSync,
  unlinkSync,
} from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";
import { tmpdir } from "node:os";

const here = dirname(fileURLToPath(import.meta.url));
// critic/ → e2e/ → threadline_phoenix/ → examples/ → repo root
const repoRoot = resolve(here, "../../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");

// Target long-edge for downsampled screenshots (D-11 / D-04: ~1600 tokens per image).
// Prohibits: NO hi-res 2576px screenshots (VLM must not re-measure pixels).
const TARGET_LONG_EDGE = 1092;

export interface ScorecardBundle {
  cellId: string;
  scorecard: ScorecardJson;
  screenshotBase64: string;
  ariaSnapshot: string | null;
  mechanicalLines: string[];
  repoRoot: string;
}

export interface ScorecardJson {
  schema_version: number;
  cell_id: string;
  ledger_id: string;
  theme: string;
  breakpoint: number;
  capture_tier: string;
  band: number;
  tokens: Record<string, string>;
  mode_b: {
    type_size_count: number;
    interactive_control_count: number;
    card_nesting_depth: number;
    scroll_cost: number;
    font_sizes: string[];
  };
  a11y_summary: {
    headings: number;
    landmarks: number;
    interactive_elements: number;
  };
  artifacts: {
    screenshot: string;
    dom: string;
    a11y: string;
    aria: string | null;
  };
}

/**
 * Returns the list of all committed cell IDs (from the scorecards directory).
 * Used to validate cell_id before path construction (T-195-17).
 */
export function committedCellIds(): string[] {
  if (!existsSync(scorecardsDir)) return [];
  return readdirSync(scorecardsDir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => f.replace(/\.json$/, ""));
}

/**
 * Validate that a cell_id is a committed scorecard cell.
 * Throws if the cell is not in the ledger (T-195-17 path traversal guard).
 */
export function validateCellId(cellId: string): void {
  const allowed = committedCellIds();
  if (!allowed.includes(cellId)) {
    throw new Error(
      `Unknown cell_id: ${JSON.stringify(cellId)} — not found in ${scorecardsDir}. ` +
        `Refusing to construct filesystem path from untrusted input.`,
    );
  }
}

/**
 * Read raw PNG dimensions from its IHDR chunk (no third-party library needed).
 */
function pngDimensions(buf: Buffer): { width: number; height: number } {
  // PNG signature is 8 bytes; IHDR chunk starts at byte 8
  // IHDR: 4-byte length | 4-byte "IHDR" | 4-byte width | 4-byte height | ...
  if (buf.length < 24) throw new Error("PNG buffer too small");
  const sig = buf.subarray(0, 8);
  const expected = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (!sig.equals(expected)) throw new Error("Not a valid PNG file");
  const width = buf.readUInt32BE(16);
  const height = buf.readUInt32BE(20);
  return { width, height };
}

/**
 * Downsample a PNG file to ~targetLongEdge px on the long edge.
 * Returns base64-encoded PNG bytes. Uses sips (macOS) or magick (cross-platform).
 * If neither is available, falls back to raw bytes (with a console warning).
 */
function downsampleScreenshot(srcPath: string, targetLongEdge = TARGET_LONG_EDGE): string {
  const raw = readFileSync(srcPath);
  const { width, height } = pngDimensions(raw);

  const longEdge = Math.max(width, height);
  if (longEdge <= targetLongEdge) {
    // Already small enough — return as-is
    return raw.toString("base64");
  }

  // Create a temp file for the resized output
  const tmpDir = mkdtempSync(resolve(tmpdir(), "critic-resize-"));
  const tmpOut = resolve(tmpDir, "resized.png");

  try {
    const scale = targetLongEdge / longEdge;
    const dstW = Math.round(width * scale);
    const dstH = Math.round(height * scale);

    let resized = false;

    // Try sips (macOS system tool, no install required)
    try {
      execSync(
        `sips -z ${dstH} ${dstW} ${JSON.stringify(srcPath)} --out ${JSON.stringify(tmpOut)}`,
        { stdio: "pipe" },
      );
      resized = existsSync(tmpOut);
    } catch {
      // sips not available or failed
    }

    // Try magick (ImageMagick 7+) if sips didn't work
    if (!resized) {
      try {
        execSync(
          `magick ${JSON.stringify(srcPath)} -resize ${dstW}x${dstH} ${JSON.stringify(tmpOut)}`,
          { stdio: "pipe" },
        );
        resized = existsSync(tmpOut);
      } catch {
        // magick not available
      }
    }

    if (resized) {
      const buf = readFileSync(tmpOut);
      return buf.toString("base64");
    }

    // Fallback: return original (warn but don't crash — the critic still works)
    console.warn(
      `[bundle] WARNING: Could not resize ${srcPath} — sending at original ${width}x${height}. ` +
        `Install ImageMagick (brew install imagemagick) for proper downsampling.`,
    );
    return raw.toString("base64");
  } finally {
    try {
      if (existsSync(tmpOut)) unlinkSync(tmpOut);
    } catch {
      // ignore cleanup errors
    }
  }
}

/**
 * Build mode_b mechanical evidence lines for the uncached prompt suffix.
 * These are the quantitative inputs the LLM uses as cited evidence for mechanical_line citations.
 */
function buildMechanicalLines(scorecard: ScorecardJson): string[] {
  const m = scorecard.mode_b;
  const a = scorecard.a11y_summary;
  const lines: string[] = [
    `type_size_count: ${m.type_size_count} (${m.font_sizes.join(", ")})`,
    `interactive_control_count: ${m.interactive_control_count}`,
    `card_nesting_depth: ${m.card_nesting_depth}`,
    `scroll_cost: ${m.scroll_cost.toFixed(3)}`,
    `headings: ${a.headings}`,
    `landmarks: ${a.landmarks}`,
    `interactive_elements: ${a.interactive_elements}`,
  ];

  // Add color token values for brand-veto / brand_fidelity evidence
  const tokenLines = Object.entries(scorecard.tokens)
    .filter(([k]) => k.startsWith("--tl-color"))
    .map(([k, v]) => `${k}: ${v}`);
  if (tokenLines.length > 0) {
    lines.push(...tokenLines);
  }

  return lines;
}

/**
 * Load and assemble the Tier-B bundle for a given cell.
 *
 * @param cellId - The capture cell ID (e.g. "page.actor.happy__dark-1280")
 * @returns ScorecardBundle ready for prompt.ts
 */
export async function loadBundle(cellId: string): Promise<ScorecardBundle> {
  // Security guard: validate before any path construction (T-195-17)
  validateCellId(cellId);

  const scorecardPath = resolve(scorecardsDir, `${cellId}.json`);
  const scorecard = JSON.parse(readFileSync(scorecardPath, "utf8")) as ScorecardJson;

  // Screenshot: path in scorecard is a relative repo path
  const screenshotPath = resolve(repoRoot, scorecard.artifacts.screenshot);
  if (!existsSync(screenshotPath)) {
    throw new Error(
      `Screenshot not found for cell ${cellId}: ${screenshotPath}\n` +
        `Run \`npm run capture:tier-a\` to regenerate artifacts.`,
    );
  }

  const screenshotBase64 = downsampleScreenshot(screenshotPath);

  // Aria snapshot (band-2 only; may be null)
  let ariaSnapshot: string | null = null;
  if (scorecard.artifacts.aria) {
    const ariaPath = resolve(repoRoot, scorecard.artifacts.aria);
    if (existsSync(ariaPath)) {
      ariaSnapshot = readFileSync(ariaPath, "utf8");
    }
  }

  const mechanicalLines = buildMechanicalLines(scorecard);

  return {
    cellId,
    scorecard,
    screenshotBase64,
    ariaSnapshot,
    mechanicalLines,
    repoRoot,
  };
}
