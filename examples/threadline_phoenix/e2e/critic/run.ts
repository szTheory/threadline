/**
 * run.ts — CLI entry point and subcommand dispatcher for the adversarial critic runner.
 *
 * Subcommands:
 *   score    — fully wired: bundle → prompt → client → cache → scorecard
 *   validate — refute battery runner (Plan 06, lazily imported)
 *   label    — golden-set authoring CLI (Plan 07, lazily imported)
 *   rubric   — rubric lint + hash checker (Plan 07, lazily imported)
 *
 * score flags:
 *   --page <ledger_id>     Score only cells for this page ledger ID
 *   --lens <lens>          Score only this lens
 *   --theme <dark|light>   Score only this theme (default: dark)
 *   --golden               Score only the labeled golden-set (cell, lens) pairs (cheap; for trust measurement)
 *   --refute-only          Score only refute-twin cells
 *   --dry-run              Print budget estimate without billing any API calls
 *   --force                Re-score even if verdict cache has a hit
 *
 * Empty-golden state: if golden-set.json has no items, score exits 0 with guided path.
 * Missing ANTHROPIC_API_KEY: the Elixir alias no-ops; this Node side never checks it
 * (the SDK will throw if key is absent at actual call time — but dry-run doesn't need it).
 *
 * D-07 / D-09 / RUNNER-01 / RUNNER-02 / RUNNER-04
 */

import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { createClient, runNSamples } from "./client.js";
import { loadBundle, committedCellIds } from "./bundle.js";
import { buildPrompt } from "./prompt.js";
import { writeCriticScore } from "./scorecard.js";
import { lookupCache, writeCache } from "./cache.js";
import { MODEL_ID, SCHEMA_VERSION, type LensName } from "./schema.js";
import { generateReport } from "./report.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const goldenSetPath = resolve(repoRoot, ".planning/golden/golden-set.json");
const syntheticSetPath = resolve(repoRoot, ".planning/golden/synthetic-set.json");
const rubricDir = resolve(here, "rubrics");

// Pinned constants
export { MODEL_ID, SCHEMA_VERSION };

// Lens → dimensions map (from committed rubric files; 13 total across 6 lenses)
const LENS_DIMENSIONS: Record<LensName, string[]> = {
  hierarchy: ["entry_point_clarity", "scan_path_reading_order", "emphasis_discipline"],
  density: ["signal_to_chrome", "task_primary_prominence"],
  rhythm: ["grouping_by_proximity", "vertical_cadence_coherence"],
  typography: ["role_differentiation", "scale_expresses_hierarchy"],
  color_contrast: ["color_as_signal", "accent_job_discipline"],
  brand_fidelity: ["designed_not_recolored", "register_voice_fit"],
};

// Persona → lenses map (D-06 / critic→lens map frozen from Phase 194)
// Persona fan-out. The divergence probe (2026-07-28) proved p1-p5 are REDUNDANT on
// hierarchy/density — 15/15 unanimous rank agreement clean>degraded, ±3 absolute spread,
// zero inversions — so all six lenses are now scored by the single "all" critic (the
// most-demanding cross-persona standard, PERSONA_CLAUSES.all). This is the ~5x cost lever
// on the two persona lenses, and keeps validation == deployment (one critic per lens).
// Oracle rho is the backstop: if one critic proves too noisy on finer rungs, rho fails the
// trust gate and personas are added back. (p1-p5 clauses remain defined in prompt.ts.)
const PERSONA_LENSES: Record<string, LensName[]> = {
  all: ["rhythm", "typography", "color_contrast", "brand_fidelity", "hierarchy", "density"],
};

// Budget estimate bands for --dry-run (D-07)
// Approximate cost per call: ~$0.015 (Opus 4.8 input 0.1× cached + output)
// Scoped run (~30 dimensions): ~$0.45
// Full sweep 1 theme/bp (174 cells × 13 dims): ~$12
// Full sweep dark+light: ~$23
const BUDGET_BANDS = {
  scoped: "~$0.45 (one page, all lenses, one theme/breakpoint)",
  full_single: "~$12 (full Tier-B sweep, one theme/breakpoint)",
  full_dual: "~$23 (full Tier-B sweep, dark + light)",
} as const;

// All valid lens names
const ALL_LENSES: LensName[] = [
  "hierarchy",
  "density",
  "rhythm",
  "typography",
  "color_contrast",
  "brand_fidelity",
];

interface ScoreArgs {
  page?: string;
  lens?: LensName;
  breakpoint?: string;
  theme: "dark" | "light";
  golden: boolean;
  synthetic: boolean;
  refuteOnly: boolean;
  dryRun: boolean;
  force: boolean;
}

// The active oracle set path: synthetic-set.json under --synthetic (D-12), else the
// human golden-set.json. Set once at the top of runScore/dryRun.
let activeSetPath = goldenSetPath;

/**
 * Parse CLI args into a ScoreArgs object.
 * argv is process.argv.slice(2) after the subcommand.
 */
function parseScoreArgs(argv: string[]): ScoreArgs {
  const args: ScoreArgs = {
    theme: "dark",
    golden: false,
    synthetic: false,
    refuteOnly: false,
    dryRun: false,
    force: false,
  };

  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--page":
        args.page = argv[++i];
        break;
      case "--breakpoint":
        args.breakpoint = argv[++i];
        break;
      case "--lens": {
        const lensArg = argv[++i];
        if (!ALL_LENSES.includes(lensArg as LensName)) {
          console.error(`Unknown lens: ${lensArg}. Valid lenses: ${ALL_LENSES.join(", ")}`);
          process.exit(1);
        }
        args.lens = lensArg as LensName;
        break;
      }
      case "--theme": {
        const themeArg = argv[++i];
        if (themeArg !== "dark" && themeArg !== "light") {
          console.error(`Unknown theme: ${themeArg}. Valid themes: dark, light`);
          process.exit(1);
        }
        args.theme = themeArg;
        break;
      }
      case "--golden":
        args.golden = true;
        break;
      case "--synthetic":
        // D-12: score exactly the synthetic-set (cell, lens) pairs (graded twin oracle).
        args.synthetic = true;
        args.golden = true;
        break;
      case "--refute-only":
        args.refuteOnly = true;
        break;
      case "--dry-run":
        args.dryRun = true;
        break;
      case "--force":
        args.force = true;
        break;
    }
  }

  return args;
}

/**
 * Read and validate the golden-set.json.
 * Returns the parsed object or null if empty.
 */
function loadGoldenSet(): { items: unknown[] } | null {
  if (!existsSync(activeSetPath)) return null;
  const gs = JSON.parse(readFileSync(activeSetPath, "utf8")) as {
    items: unknown[];
  };
  return gs;
}

/**
 * Derive the labeled (cell, lens) scope from the golden set. Used by `--golden`
 * to score exactly the cells the maintainer labeled — for cheap, correct trust
 * measurement — instead of every committed scorecard cell.
 */
interface GoldenScopeItem {
  cell_id: string;
  lens: LensName;
  kept?: boolean;
}

function goldenScope(): { cellIds: string[]; lensByCell: Map<string, Set<LensName>> } {
  const gs = loadGoldenSet() as { items: GoldenScopeItem[] } | null;
  const lensByCell = new Map<string, Set<LensName>>();
  for (const it of gs?.items ?? []) {
    if (it.kept === false) continue; // only reconciled items
    if (!lensByCell.has(it.cell_id)) lensByCell.set(it.cell_id, new Set());
    lensByCell.get(it.cell_id)!.add(it.lens);
  }
  return { cellIds: [...lensByCell.keys()], lensByCell };
}

/**
 * Get the rubric version string for a lens (reads the <!-- header --> from the rubric file).
 * Returns "unknown@0.0.0+00000000" if the rubric file is missing or malformed.
 */
function getRubricVersion(lens: LensName): string {
  const rubricPath = resolve(rubricDir, `${lens}.md`);
  if (!existsSync(rubricPath)) return `${lens}@0.0.0+00000000`;
  const text = readFileSync(rubricPath, "utf8");
  const match = text.match(/<!--\s*lens:\s*\S+\s*\|\s*version:\s*(\S+)\s*\|\s*sha8:\s*(\S+)\s*-->/);
  if (!match) return `${lens}@0.0.0+00000000`;
  return `${lens}@${match[1]}+${match[2]}`;
}

/**
 * Extract the sha8 component from a rubric version string (e.g. "hierarchy@1.0.0+ab3f1234" → "ab3f1234").
 */
function getRubricHash(rubricVersion: string): string {
  const match = rubricVersion.match(/\+([a-f0-9]+)$/);
  return match ? match[1] : "00000000";
}

/**
 * Print the dry-run budget estimate without making any API calls.
 */
function dryRun(args: ScoreArgs): void {
  const cellIds = getScopedCellIds(args);
  const lenses = args.lens ? [args.lens] : ALL_LENSES;
  let totalDimensions = 0;
  for (const lens of lenses) {
    totalDimensions += LENS_DIMENSIONS[lens].length;
  }
  const estimatedCalls = cellIds.length * totalDimensions * 3; // N=3 base
  const estimatedCost = (estimatedCalls * 0.015).toFixed(2);

  console.log(`\n[critic dry-run] Budget estimate`);
  console.log(`  Cells in scope:       ${cellIds.length}`);
  console.log(`  Lenses in scope:      ${lenses.join(", ")}`);
  console.log(`  Dimensions (total):   ${totalDimensions}`);
  console.log(`  Estimated calls (N=3): ${estimatedCalls}`);
  console.log(`  Estimated cost:        ~$${estimatedCost} (base N=3; may escalate to N=7)`);
  console.log(`\n  Budget bands (reference):`);
  console.log(`    Scoped (1 page):     ${BUDGET_BANDS.scoped}`);
  console.log(`    Full sweep (1 theme): ${BUDGET_BANDS.full_single}`);
  console.log(`    Full sweep (dark+light): ${BUDGET_BANDS.full_dual}`);
  console.log(`\n  Tip: Use --page <ledger_id> to scope to one page (~$0.45/run).`);
  console.log(`  Tip: Verdict cache skips re-billed cells on subsequent runs.`);
}

/**
 * Determine the set of cell IDs to score based on the score args.
 */
function getScopedCellIds(args: ScoreArgs): string[] {
  const committed = new Set(committedCellIds());
  // --golden restricts the base set to labeled golden cells; otherwise all committed cells.
  const base = args.golden ? goldenScope().cellIds : committedCellIds();
  return base.filter((cellId) => {
    // T-195-17: a golden cell must resolve to a committed scorecard (no path traversal)
    if (args.golden && !committed.has(cellId)) return false;
    // Theme filter
    if (!cellId.includes(`__${args.theme}-`)) return false;
    // Breakpoint filter (e.g. --breakpoint 1280 → only the __<theme>-1280 cell)
    if (args.breakpoint && !cellId.endsWith(`-${args.breakpoint}`)) return false;
    // Page filter
    if (args.page && !cellId.startsWith(args.page + "__")) return false;
    // Refute-only filter
    if (args.refuteOnly && !cellId.startsWith("refute.")) return false;
    // Normal run excludes refute cells (scored via --refute-only / --synthetic);
    // the graded oracle cells are refute.*-prefixed but explicitly in scope under --synthetic.
    if (!args.refuteOnly && !args.synthetic && cellId.startsWith("refute.")) return false;
    return true;
  });
}

/**
 * Run the score subcommand — fully wired: bundle → prompt → client → cache → scorecard.
 */
async function runScore(argv: string[]): Promise<void> {
  const args = parseScoreArgs(argv);
  activeSetPath = args.synthetic ? syntheticSetPath : goldenSetPath;

  if (args.dryRun) {
    dryRun(args);
    process.exit(0);
  }

  // Empty-oracle check (D-09) — only when the run is SCOPED to an oracle set
  // (--golden / --synthetic), which needs items to measure trust. Plain scoring of
  // committed cells (e.g. --page for the CRITIQUE / HTML projection) needs no oracle.
  if (args.golden || args.synthetic) {
    const oracleSet = loadGoldenSet();
    if (!oracleSet || oracleSet.items.length === 0) {
      console.log(`\n[critic score] No ${args.synthetic ? "synthetic" : "golden"}-set items found.`);
      console.log(`\nThe oracle set is required for --golden/--synthetic trust scoping.`);
      console.log(`  synthetic: run \`mix critic.synth\` (D-12 graded twin oracle)`);
      console.log(`  human:     run \`npm run critic:label -- --bootstrap\``);
      console.log(`See .planning/golden/${args.synthetic ? "synthetic" : "golden"}-set.json.`);
      process.exit(0);
    }
  }

  const cellIds = getScopedCellIds(args);
  if (cellIds.length === 0) {
    console.log(`[critic score] No cells match the scope (page=${args.page ?? "all"}, theme=${args.theme}).`);
    process.exit(0);
  }

  const lenses = args.lens ? [args.lens] : ALL_LENSES;
  // Under --golden, score only the lenses each cell was actually labeled on.
  const goldenLensMap = args.golden ? goldenScope().lensByCell : null;
  const client = createClient();

  console.log(`[critic score] Scoring ${cellIds.length} cells × ${lenses.length} lenses`);

  let scored = 0;
  let skipped = 0;
  let errored = 0;

  for (const cellId of cellIds) {
    const cellLenses = goldenLensMap
      ? lenses.filter((l) => goldenLensMap.get(cellId)?.has(l))
      : lenses;
    for (const lens of cellLenses) {
      const rubricVersion = getRubricVersion(lens);
      const rubricHash = getRubricHash(rubricVersion);
      const dimensions = LENS_DIMENSIONS[lens];

      // Determine which personas score this lens
      const personas = Object.entries(PERSONA_LENSES)
        .filter(([, lensesForPersona]) => lensesForPersona.includes(lens))
        .map(([persona]) => persona);

      for (const dimension of dimensions) {
        for (const persona of personas) {
          // Verdict cache check
          if (!args.force) {
            const cached = lookupCache(cellId, `${lens}.${dimension}.${persona}`, rubricHash, MODEL_ID);
            if (cached) {
              skipped++;
              continue;
            }
          }

          try {
            const bundle = await loadBundle(cellId);
            const strata = buildPrompt(lens, dimension, persona, bundle);
            const result = await runNSamples(client, strata, lens);

            // Write to critic-scores/
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

            // Write to verdict cache for resume/replay
            writeCache({
              cell_id: cellId,
              dimension: `${lens}.${dimension}.${persona}`,
              rubric_hash: rubricHash,
              model_id: MODEL_ID,
              result: {
                ...result.evidence,
                score: result.score ?? 0,
                band: (result.band ?? "fail") as ReturnType<typeof import("./schema.js").scoreToBand>,
                pass: result.pass,
                lens,
                rationale: result.rationale,
                evidence: result.evidence,
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

            const stability = result.stable ? "stable" : "UNSTABLE";
            console.log(
              `  ✓ ${cellId} / ${lens} / ${dimension} [${persona}]: ` +
                `score=${result.score ?? "null"} band=${result.band ?? "null"} n=${result.n} ${stability}`,
            );
            scored++;
          } catch (err) {
            console.error(`  ✗ ${cellId} / ${lens} / ${dimension} [${persona}]: ${String(err)}`);
            errored++;
          }
        }
      }
    }
  }

  console.log(
    `\n[critic score] Done: ${scored} scored, ${skipped} cache-skipped, ${errored} errored`,
  );
  if (errored > 0) process.exit(1);

  // Regenerate CRITIQUE.md projection after each scoring run (D-08)
  try {
    const count = generateReport();
    if (count > 0) {
      console.log(`[critic score] CRITIQUE.md regenerated (${count} cells).`);
    }
  } catch (err) {
    console.warn(`[critic score] WARNING: CRITIQUE.md regeneration failed: ${String(err)}`);
  }
}

// ─── CLI dispatcher ─────────────────────────────────────────────────────────

const [subcommand, ...rest] = process.argv.slice(2);

switch (subcommand) {
  case "score":
    await runScore(rest);
    break;

  case "report":
    // `--html` → self-contained visual critique viewer; otherwise the CRITIQUE.md projection.
    try {
      if (rest.includes("--html")) {
        const { generateHtmlReport } = await import("./report_html.js");
        generateHtmlReport();
      } else {
        const { runReport } = await import("./report.js");
        await runReport(rest);
      }
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ERR_MODULE_NOT_FOUND") {
        console.error(
          `[critic report] Module not found — report.ts lands in Plan 07.\n` +
            `Error: ${String(err)}`,
        );
        process.exit(1);
      }
      throw err;
    }
    break;

  case "gate":
    // Lazy import — Phase 196 forward-only gate (local-only LLM; never in CI, 196-D9)
    try {
      const { runGate } = await import("./gate.js");
      await runGate(rest);
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ERR_MODULE_NOT_FOUND") {
        console.error(
          `[critic gate] Module not found — gate.ts is the Phase 196 forward-only gate.\n` +
            `Error: ${String(err)}`,
        );
        process.exit(1);
      }
      throw err;
    }
    break;

  case "validate":
    // Lazy import — Plan 06 (refute.ts / panel.ts)
    try {
      const { runValidate } = await import("./refute.js");
      await runValidate(rest);
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ERR_MODULE_NOT_FOUND") {
        console.error(
          `[critic validate] Module not found — the validate subcommand lands in Plan 06.\n` +
            `Run: npm run critic:score to use the scoring engine.\n` +
            `Error: ${String(err)}`,
        );
        process.exit(1);
      }
      throw err;
    }
    break;

  case "label":
    // Lazy import — Plan 07 (label.ts)
    try {
      const { runLabel } = await import("./label.js");
      await runLabel(rest);
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ERR_MODULE_NOT_FOUND") {
        console.error(
          `[critic label] Module not found — the label subcommand lands in Plan 07.\n` +
            `Run: npm run critic:score -- --dry-run for a budget preview.\n` +
            `Error: ${String(err)}`,
        );
        process.exit(1);
      }
      throw err;
    }
    break;

  case "rubric":
    // Lazy import — Plan 07 (rubric linter)
    try {
      const { runRubric } = await import("./rubric.js");
      await runRubric(rest);
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code === "ERR_MODULE_NOT_FOUND") {
        console.error(
          `[critic rubric] Module not found — the rubric subcommand lands in Plan 07.\n` +
            `Error: ${String(err)}`,
        );
        process.exit(1);
      }
      throw err;
    }
    break;

  default:
    console.error(`Unknown subcommand: ${subcommand ?? "(none)"}`);
    console.error(`Usage: critic <subcommand> [options]`);
    console.error(`Subcommands: score, gate, validate, label, rubric, report`);
    console.error(`  score --dry-run        Print budget estimate`);
    console.error(`  score --page <id>      Score a specific page`);
    console.error(`  score --lens <lens>    Score a specific lens`);
    console.error(`  score --theme <theme>  Score a specific theme (dark|light)`);
    console.error(`  score --force          Re-score even on cache hit`);
    console.error(`  gate --page <id> --lens <lens>            Forward-only net-positive gate (local-only, 4 blocking lenses)`);
    console.error(`       [--dry-run]                          Print the wired plan; $0, no ANTHROPIC_API_KEY required`);
    console.error(`       [--n <3>]                            Base N samples per cell/lens (escalates to 7 on unstable)`);
    console.error(`       (advisory lenses hierarchy/color_contrast are reported with a badge, never gate)`);
    console.error(`  report                 Regenerate CRITIQUE.md from critic-scores`);
    process.exit(1);
}
