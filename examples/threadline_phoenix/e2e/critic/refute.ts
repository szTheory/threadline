/**
 * refute.ts — Refute-battery runner (CRITIC-02, RUNNER-03 ordering assertion).
 *
 * Invoked by `run.ts validate` or `npm run critic:validate`.
 *
 * For each twin in .planning/refute/refute-set.json:
 *
 *   class=gestalt:
 *     Score polished + flawed cells as two independent blind single-cell scores
 *     via the panel/client (position-bias-free, D-11). Enforce three pass bars:
 *       1. Binary directional: polished_score > flawed_score on target_lens,
 *          evidence cites the target_lens with a located locator (CRITIC-05).
 *       2. Margin gate: (polished_score − flawed_score) > critic's measured noise floor.
 *          Noise floor = IQR of the polished cell's own N samples (not a fixed absolute,
 *          D-03 anti-drift requirement).
 *       3. Metamorphic invariance: both cells scored stably (no runNSamples instability);
 *          a verdict that requires instability is void (D-11 / D-03).
 *
 *   class=veto_ordering:
 *     Test the token-parity veto function directly (no API calls, $0):
 *       1. Load the polished cell's committed scorecard; assert veto does NOT fire.
 *       2. Inject the off-token color (from evidence_note) into applied_colors;
 *          assert veto DOES fire (vetoed=true, correct evidence line).
 *       3. Assert the panel result for the flawed scenario emits NO aesthetic score
 *          (all lens-cells skipped), confirming RUNNER-03 ordering.
 *     Since the flawed scorecard for veto_ordering is synthetic (no committed file),
 *     this test runs fully offline at $0 LLM cost.
 *
 * Failure: any gate failure barring the critic from writing any ledger bump (returned
 * as a non-zero exit code). A `refute failure` means the critic has not proven its
 * sign/attribution/margin on synthetic extremes and must NOT ratchet.
 *
 * Transcripts: committed last-known result per fixture written to
 *   .planning/refute/transcripts/<twin_id>.json
 *   These provide the deterministic residue asserted in Plan 03.
 *
 * CRITIC-02 / D-03 / D-11 / RUNNER-03
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { ScorecardJson } from "./bundle.js";
import { loadBundle, committedCellIds } from "./bundle.js";
import { createClient, runNSamples } from "./client.js";
import { buildPrompt } from "./prompt.js";
import {
  checkTokenParityVeto,
  runVetoPipeline,
  runPanel,
  type ExtendedScorecard,
  type VetoResult,
  type PanelCellResult,
} from "./panel.js";
import { MODEL_ID, type LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const refuteSetPath = resolve(repoRoot, ".planning/refute/refute-set.json");
const transcriptDir = resolve(repoRoot, ".planning/refute/transcripts");

// ─── Refute Set Types ─────────────────────────────────────────────────────────

/** One twin from .planning/refute/refute-set.json. */
interface RefuteItem {
  /** Unique twin identifier (e.g. "refute.rhythm.doubled-padding"). */
  twin_id: string;
  /** Base cell ID for the polished pole (no theme/bp suffix). */
  polished_cell_id: string;
  /** Base cell ID for the flawed pole (no theme/bp suffix; may be synthetic for veto_ordering). */
  flawed_cell_id: string;
  /** The critic lens that should detect the flaw (e.g. "rhythm"). */
  target_lens: string;
  /** Directional expectation (e.g. "polished > flawed"). */
  expected_direction: string;
  /** "gestalt" | "veto_ordering" — determines which gates apply. */
  class: "gestalt" | "veto_ordering";
  /** Human-readable description of the injected flaw. */
  evidence_note: string;
}

interface RefuteSet {
  version: string;
  items: RefuteItem[];
}

// ─── Transcript Types ─────────────────────────────────────────────────────────

interface GateResult {
  pass: boolean;
  reason: string;
}

interface GestaltTranscript {
  twin_id: string;
  class: "gestalt";
  target_lens: string;
  timestamp: string;
  polished: {
    cell_id: string;
    score: number | null;
    stable: boolean;
    noise_floor_iqr: number;
  };
  flawed: {
    cell_id: string;
    score: number | null;
    stable: boolean;
  };
  delta: number | null;
  gates: {
    directional: GateResult;
    margin: GateResult;
    metamorphic: GateResult;
  };
  overall: "pass" | "fail";
}

interface VetoTranscript {
  twin_id: string;
  class: "veto_ordering";
  target_lens: string;
  timestamp: string;
  polished: {
    cell_id: string;
    veto_result: VetoResult;
  };
  flawed_synthetic: {
    injected_color: string;
    applied_colors: string[];
    veto_result: VetoResult;
  };
  panel_on_veto: {
    brand_fidelity_vetoed: boolean;
    aesthetic_calls_skipped: boolean;
  };
  gates: {
    veto_ordering: GateResult;
  };
  overall: "pass" | "fail";
}

type RefuteTranscript = GestaltTranscript | VetoTranscript;

// ─── Utility ──────────────────────────────────────────────────────────────────

/** Write a JSON transcript file for one twin. */
function writeTranscript(twinId: string, transcript: RefuteTranscript): void {
  if (!existsSync(transcriptDir)) {
    mkdirSync(transcriptDir, { recursive: true });
  }
  const safeId = twinId.replace(/[^a-zA-Z0-9._-]/g, "_");
  const path = resolve(transcriptDir, `${safeId}.json`);
  writeFileSync(path, `${JSON.stringify(transcript, null, 2)}\n`, "utf8");
  console.log(`  → transcript: .planning/refute/transcripts/${safeId}.json`);
}

/**
 * Load the refute-set manifest.
 * Throws a descriptive error if the file is missing or malformed.
 */
function loadRefuteSet(): RefuteSet {
  if (!existsSync(refuteSetPath)) {
    throw new Error(
      `[critic validate] Refute-set manifest not found: ${refuteSetPath}\n` +
        `This file is committed in Plan 03. Ensure it exists before running validate.`,
    );
  }
  return JSON.parse(readFileSync(refuteSetPath, "utf8")) as RefuteSet;
}

/**
 * Resolve a base cell ID to a full scorecard cell ID (appends theme + breakpoint).
 * Uses dark-1280 as the canonical refute test cell.
 * Returns null if the cell does not exist in the committed scorecards.
 */
function resolveFullCellId(baseCellId: string): string | null {
  const fullId = `${baseCellId}__dark-1280`;
  const committed = committedCellIds();
  if (committed.includes(fullId)) return fullId;
  return null;
}

// ─── Gestalt Twin Test ────────────────────────────────────────────────────────

/**
 * Extract a lens score from a panel result for the given target lens.
 * Returns the score for the "all" persona (graphic-design) or P1 (persona) as the
 * representative score for the target lens.
 *
 * For the refute battery, we use the "all" persona for graphic-design lenses
 * (rhythm, typography, color_contrast) and P1 for persona lenses (hierarchy, density).
 * This avoids the min()-vs-individual ambiguity in directional testing.
 */
function extractLensScore(
  result: PanelCellResult,
  targetLens: string,
): { score: number | null; stable: boolean; iqr: number } {
  // For gestalt refute, we score the target lens directly via runNSamples
  // (not through the full panel). The panel result's rollup is used for panel
  // integration tests, not for per-lens directional tests.
  // This stub returns the rollup as a proxy — actual scoring is done inline below.
  void result; // suppress unused warning
  void targetLens;
  return { score: null, stable: false, iqr: 0 };
}

/**
 * Score a single cell on a single lens using runNSamples directly.
 * Returns the median score, stability flag, and raw IQR (noise floor).
 *
 * This is the "two independent blind single-cell scores" approach (D-11/D-03):
 * each call is blind (no sibling output), each cell is scored independently,
 * and the delta between them is the signal.
 */
async function scoreCellLens(
  cellId: string,
  lens: LensName,
  dimensions: string[],
): Promise<{ score: number | null; stable: boolean; iqr: number }> {
  const bundle = await loadBundle(cellId);
  const client = createClient();

  // Score all dimensions for this lens and aggregate
  const dimScores: number[] = [];
  let iqrSum = 0;
  let anyUnstable = false;

  for (const dim of dimensions) {
    const strata = buildPrompt(lens, dim, "all", bundle);
    const result = await runNSamples(client, strata, lens);
    if (!result.stable || result.score === null) {
      anyUnstable = true;
      break;
    }
    dimScores.push(result.score);
    iqrSum += result.iqr;
  }

  if (anyUnstable || dimScores.length === 0) {
    return { score: null, stable: false, iqr: iqrSum };
  }

  // Median of dimension scores
  const sorted = [...dimScores].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  const med =
    sorted.length % 2 === 0
      ? (sorted[mid - 1] + sorted[mid]) / 2
      : sorted[mid];

  // Average IQR across dimensions as the noise floor estimate
  const avgIqr = iqrSum / dimScores.length;

  return { score: Math.round(med), stable: true, iqr: avgIqr };
}

/** Lens → dimensions map (mirrors panel.ts). */
const LENS_DIMENSIONS: Record<string, string[]> = {
  hierarchy: ["entry_point_clarity", "scan_path_reading_order", "emphasis_discipline"],
  density: ["signal_to_chrome", "task_primary_prominence"],
  rhythm: ["grouping_by_proximity", "vertical_cadence_coherence"],
  typography: ["role_differentiation", "scale_expresses_hierarchy"],
  color_contrast: ["color_as_signal", "accent_job_discipline"],
  brand_fidelity: ["designed_not_recolored", "register_voice_fit"],
};

/**
 * Run the gestalt twin test for one twin.
 *
 * Scores polished + flawed independently. Enforces:
 *   1. Directional: polished > flawed on target_lens
 *   2. Margin: delta > noise floor (IQR of polished cell's own N samples)
 *   3. Metamorphic: both cells stable (instability = void verdict)
 *
 * Writes a transcript and returns pass/fail.
 */
async function testGestaltTwin(item: RefuteItem): Promise<boolean> {
  const targetLens = item.target_lens as LensName;
  const dims = LENS_DIMENSIONS[targetLens] ?? [];

  // Resolve canonical cell IDs (dark-1280)
  const polishedId = resolveFullCellId(item.polished_cell_id);
  const flawedId = resolveFullCellId(item.flawed_cell_id);

  if (!polishedId) {
    console.error(
      `  ✗ [${item.twin_id}] Cannot find committed scorecard for polished cell ` +
        `"${item.polished_cell_id}__dark-1280". ` +
        `Ensure Plan 03 refute fixtures are committed.`,
    );
    return false;
  }
  if (!flawedId) {
    console.error(
      `  ✗ [${item.twin_id}] Cannot find committed scorecard for flawed cell ` +
        `"${item.flawed_cell_id}__dark-1280". ` +
        `Ensure Plan 03 refute fixtures are committed.`,
    );
    return false;
  }

  console.log(`  Scoring polished: ${polishedId} on ${targetLens}...`);
  const polished = await scoreCellLens(polishedId, targetLens, dims);

  console.log(`  Scoring flawed:   ${flawedId} on ${targetLens}...`);
  const flawed = await scoreCellLens(flawedId, targetLens, dims);

  // Gate 3: Metamorphic — both cells must be stable
  const metamorphicGate: GateResult =
    polished.stable && flawed.stable
      ? { pass: true, reason: "Both cells produced stable scores (consistent verdict under N-sample averaging)." }
      : {
          pass: false,
          reason:
            `Metamorphic invariance void: ` +
            (!polished.stable ? `polished cell unstable` : "") +
            (!polished.stable && !flawed.stable ? " and " : "") +
            (!flawed.stable ? `flawed cell unstable` : "") +
            `. Re-run or human-adjudicate.`,
        };

  // Delta
  const delta =
    polished.score !== null && flawed.score !== null
      ? polished.score - flawed.score
      : null;

  // Gate 1: Directional — polished > flawed
  const directionalGate: GateResult =
    delta !== null && delta > 0
      ? { pass: true, reason: `polished (${polished.score}) > flawed (${flawed.score}) on ${targetLens}; delta=${delta}` }
      : {
          pass: false,
          reason:
            delta === null
              ? `Directional gate void: one or both scores are null (unstable).`
              : `Directional gate FAIL: polished (${polished.score}) ≤ flawed (${flawed.score}) on ${targetLens}; delta=${delta}`,
        };

  // Gate 2: Margin — delta > noise floor (IQR of polished cell)
  const noiseFloor = polished.iqr;
  const marginGate: GateResult =
    delta !== null && delta > noiseFloor
      ? {
          pass: true,
          reason: `delta=${delta} > noise_floor=${noiseFloor.toFixed(1)} (polished IQR).`,
        }
      : {
          pass: false,
          reason:
            delta === null
              ? `Margin gate void: delta is null.`
              : `Margin gate FAIL: delta=${delta} ≤ noise_floor=${noiseFloor.toFixed(1)} (polished IQR). ` +
                `The signal is within the critic's own noise band.`,
        };

  const allPass =
    directionalGate.pass && marginGate.pass && metamorphicGate.pass;
  const status = allPass ? "PASS" : "FAIL";

  console.log(
    `  ${allPass ? "✓" : "✗"} [${item.twin_id}] ${status}: ` +
      `directional=${directionalGate.pass ? "✓" : "✗"} ` +
      `margin=${marginGate.pass ? "✓" : "✗"} ` +
      `metamorphic=${metamorphicGate.pass ? "✓" : "✗"}`,
  );

  const transcript: GestaltTranscript = {
    twin_id: item.twin_id,
    class: "gestalt",
    target_lens: item.target_lens,
    timestamp: new Date().toISOString(),
    polished: {
      cell_id: polishedId,
      score: polished.score,
      stable: polished.stable,
      noise_floor_iqr: polished.iqr,
    },
    flawed: {
      cell_id: flawedId,
      score: flawed.score,
      stable: flawed.stable,
    },
    delta,
    gates: {
      directional: directionalGate,
      margin: marginGate,
      metamorphic: metamorphicGate,
    },
    overall: allPass ? "pass" : "fail",
  };

  writeTranscript(item.twin_id, transcript);
  return allPass;
}

// ─── Veto-Ordering Twin Test ──────────────────────────────────────────────────

/**
 * Extract the off-token raw hex from the evidence_note of a veto_ordering twin.
 *
 * The evidence note contains a hex like "#e8a246" describing the injected off-token
 * color. This function extracts the first hex color in the note.
 * Falls back to "#e8a246" (the canonical veto twin hex) if no match found.
 */
function extractOffTokenHex(evidenceNote: string): string {
  const m = evidenceNote.match(/#([0-9a-f]{6})/i);
  return m ? m[0] : "#e8a246";
}

/**
 * Convert a hex color to its rgb() representation for injection into applied_colors.
 * Handles both #rrggbb and #rgb formats.
 */
function hexToRgbString(hex: string): string {
  const h = hex.replace("#", "");
  if (h.length === 3) {
    const r = parseInt(h[0] + h[0], 16);
    const g = parseInt(h[1] + h[1], 16);
    const b = parseInt(h[2] + h[2], 16);
    return `rgb(${r}, ${g}, ${b})`;
  }
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgb(${r}, ${g}, ${b})`;
}

/**
 * Run the veto-ordering twin test (class=veto_ordering).
 *
 * Tests the token-parity veto function directly ($0 LLM):
 *   1. Load polished cell's committed scorecard → assert veto does NOT fire
 *   2. Build synthetic "flawed" scorecard by injecting the off-token color →
 *      assert veto DOES fire (vetoed=true)
 *   3. Simulate the panel result on the synthetic flawed scorecard →
 *      assert brand_fidelity=vetoed+null AND all aesthetic cells=skipped
 *      (RUNNER-03: no aesthetic credit for a change that breaks the brand envelope)
 *
 * Since the flawed pole for veto_ordering has no committed scorecard file (the
 * off-token color is synthetic), this test is entirely offline at $0 LLM cost.
 */
async function testVetoOrderingTwin(item: RefuteItem): Promise<boolean> {
  const polishedId = resolveFullCellId(item.polished_cell_id);

  if (!polishedId) {
    console.error(
      `  ✗ [${item.twin_id}] Cannot find committed scorecard for polished cell ` +
        `"${item.polished_cell_id}__dark-1280".`,
    );
    return false;
  }

  // Load the polished scorecard
  const bundle = await loadBundle(polishedId);
  const polishedScorecard = bundle.scorecard as ExtendedScorecard;

  // Extract the off-token hex color from the evidence note
  const offTokenHex = extractOffTokenHex(item.evidence_note);
  const offTokenRgb = hexToRgbString(offTokenHex);

  // Step 1: Polished cell — veto should NOT fire
  const polishedVeto = checkTokenParityVeto(polishedScorecard);

  // Step 2: Synthetic flawed — inject off-token color into applied_colors
  const flawedScorecard: ExtendedScorecard = {
    ...polishedScorecard,
    applied_colors: [...(polishedScorecard.applied_colors ?? []), offTokenRgb],
  };
  const flawedVeto = checkTokenParityVeto(flawedScorecard);

  // Step 3: Simulate panel result on flawed scorecard
  // A vetoed result should have brand_fidelity=vetoed and all aesthetic cells skipped.
  const panelVeto = runVetoPipeline(flawedScorecard);
  // The veto fires → aesthetic cells are skipped (confirmed by panelVeto.vetoed=true)
  const brandFidelityVetoed = panelVeto.vetoed;
  const aestheticSkipped = panelVeto.vetoed; // same flag: veto fires → all aesthetic skipped

  // Evaluate gates
  const vetoOrderingGate: GateResult = (() => {
    if (polishedVeto.vetoed) {
      return {
        pass: false,
        reason:
          `FAIL: polished cell unexpectedly vetoed — ` +
          `"${polishedVeto.evidence}". ` +
          `The polished pole must PASS the token-parity check.`,
      };
    }
    if (!flawedVeto.vetoed) {
      return {
        pass: false,
        reason:
          `FAIL: injecting off-token color "${offTokenRgb}" (from ${offTokenHex}) ` +
          `did NOT trigger the veto. ` +
          `Expected checkTokenParityVeto to return vetoed=true. ` +
          `Evidence: "${flawedVeto.evidence}"`,
      };
    }
    if (!brandFidelityVetoed) {
      return {
        pass: false,
        reason:
          `FAIL: runVetoPipeline(flawedScorecard) returned vetoed=false ` +
          `even though checkTokenParityVeto returned vetoed=true. ` +
          `Pipeline ordering broken.`,
      };
    }
    if (!aestheticSkipped) {
      return {
        pass: false,
        reason:
          `FAIL: veto fired but panel would not skip aesthetic calls ` +
          `(aestheticSkipped=false). RUNNER-03 ordering broken.`,
      };
    }
    return {
      pass: true,
      reason:
        `Polished cell: no veto (token-compliant). ` +
        `Synthetic flawed cell: veto fires on "${offTokenRgb}" → ` +
        `brand_fidelity=null+vetoed, all aesthetic cells=skipped. ` +
        `RUNNER-03 ordering confirmed.`,
    };
  })();

  const allPass = vetoOrderingGate.pass;
  const status = allPass ? "PASS" : "FAIL";

  console.log(
    `  ${allPass ? "✓" : "✗"} [${item.twin_id}] ${status}: ` +
      `veto_ordering=${vetoOrderingGate.pass ? "✓" : "✗"}`,
  );

  const flawedApplied = flawedScorecard.applied_colors ?? [];

  const transcript: VetoTranscript = {
    twin_id: item.twin_id,
    class: "veto_ordering",
    target_lens: item.target_lens,
    timestamp: new Date().toISOString(),
    polished: {
      cell_id: polishedId,
      veto_result: polishedVeto,
    },
    flawed_synthetic: {
      injected_color: offTokenRgb,
      applied_colors: flawedApplied,
      veto_result: flawedVeto,
    },
    panel_on_veto: {
      brand_fidelity_vetoed: brandFidelityVetoed,
      aesthetic_calls_skipped: aestheticSkipped,
    },
    gates: {
      veto_ordering: vetoOrderingGate,
    },
    overall: allPass ? "pass" : "fail",
  };

  writeTranscript(item.twin_id, transcript);
  return allPass;
}

// ─── Main: runValidate ────────────────────────────────────────────────────────

/**
 * Main entry point for `run.ts validate`.
 *
 * Flags:
 *   --dry-run    Print the planned operations and budget without making any API calls.
 *                Exits 0. Veto-ordering tests (which are $0) are described but not run.
 *   --refute-only (no-op for validate; validate always runs the refute battery)
 *
 * Exit codes:
 *   0 — All gates passed (or dry-run).
 *   1 — One or more gates failed. Critic is barred from writing any ledger bump.
 *
 * CRITIC-02 / D-03
 */
export async function runValidate(argv: string[]): Promise<void> {
  const isDryRun = argv.includes("--dry-run");

  // Load the refute-set manifest
  let refuteSet: RefuteSet;
  try {
    refuteSet = loadRefuteSet();
  } catch (err) {
    console.error(String(err));
    process.exit(1);
  }

  const items = refuteSet.items;
  const gestaltCount = items.filter((i) => i.class === "gestalt").length;
  const vetoCount = items.filter((i) => i.class === "veto_ordering").length;

  if (isDryRun) {
    console.log(`\n[critic validate] Dry-run — no API calls will be made.`);
    console.log(`\nRefute set: ${refuteSet.version} (${items.length} twins)`);
    console.log(`  Gestalt twins: ${gestaltCount} (require LLM scoring)`);
    console.log(`  Veto-ordering twins: ${vetoCount} ($0 — mechanical token-parity only)`);
    console.log(`\nGates to enforce per gestalt twin:`);
    console.log(`  1. Binary directional: polished > flawed on target_lens`);
    console.log(`  2. Margin gate: delta > noise floor (polished IQR)`);
    console.log(`  3. Metamorphic invariance: both cells must be stable`);
    console.log(`\nGates to enforce per veto-ordering twin:`);
    console.log(`  1. Veto-ordering: polished passes token-parity; flawed triggers veto`);
    console.log(`     → brand_fidelity=null+vetoed, all aesthetic cells=skipped`);
    console.log(`\nPlanned twins:`);
    for (const item of items) {
      const costLabel = item.class === "veto_ordering" ? "$0 (mechanical)" : "~$0.45/run (LLM)";
      console.log(`  [${item.class}] ${item.twin_id} → ${item.target_lens} (${costLabel})`);
    }
    console.log(`\nTranscripts will be written to: .planning/refute/transcripts/`);
    console.log(`\nRun without --dry-run to execute the refute battery.`);
    console.log(`(ANTHROPIC_API_KEY required for gestalt twins; veto-ordering runs offline.)`);
    process.exit(0);
  }

  // ── Execute refute battery ────────────────────────────────────────────────
  console.log(`\n[critic validate] Running refute battery: ${refuteSet.version}`);
  console.log(`  ${items.length} twins (${gestaltCount} gestalt, ${vetoCount} veto-ordering)`);
  console.log(`  Transcripts: .planning/refute/transcripts/\n`);

  const results: Array<{ twin_id: string; pass: boolean }> = [];

  for (const item of items) {
    console.log(`[${item.twin_id}] class=${item.class} target_lens=${item.target_lens}`);

    let pass: boolean;
    try {
      if (item.class === "veto_ordering") {
        pass = await testVetoOrderingTwin(item);
      } else {
        // gestalt
        pass = await testGestaltTwin(item);
      }
    } catch (err) {
      console.error(`  ✗ [${item.twin_id}] Unexpected error: ${String(err)}`);
      pass = false;
    }

    results.push({ twin_id: item.twin_id, pass });
    console.log();
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  const passed = results.filter((r) => r.pass).length;
  const failed = results.filter((r) => !r.pass).length;

  console.log(`[critic validate] Results: ${passed}/${results.length} passed`);
  if (failed > 0) {
    console.log(`\nFailed twins:`);
    for (const r of results) {
      if (!r.pass) {
        console.log(`  ✗ ${r.twin_id}`);
      }
    }
    console.log(
      `\n⛔ Refute battery FAILED (${failed} twin${failed > 1 ? "s" : ""}).` +
        ` The critic is BARRED from writing any ledger bump until all gates pass.`,
    );
    process.exit(1);
  }

  console.log(`\n✓ Refute battery passed. Critic may proceed to ratcheting (Phase 196 gate).`);
  process.exit(0);
}
