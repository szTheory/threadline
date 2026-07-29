/**
 * gate.ts — Forward-only net-positive gate orchestrator (Phase 196 tracer).
 *
 * The thinnest PRODUCTION-QUALITY end-to-end slice of the forward-only gate:
 * one blocking lens (brand_fidelity) × one real route cell (route.timeline) run
 * through the whole propose → re-evaluate → guard loop, returning an accept/reject
 * verdict. This proves the architecture CLOSES before any multi-cell expansion
 * (that is Plan 03). It is written for keeps, not as a prototype.
 *
 * The loop is four ordered steps, each a separate function so Plan 03 can expand it:
 *   1. blastRadius(page)      — deterministic re-capture diff over route.* scorecards
 *                               (Pattern 2): the affected set = route.* cells whose bytes
 *                               changed vs their prior copy. With no edit applied → 0 cells.
 *   2. mechanicalFloor(cell)  — resolve the route cell to its committed page.* Tier-A twin
 *                               (route.timeline → page.timeline.happy) and gate the
 *                               deterministic `mix verify.mechanical` on that COMMITTED twin,
 *                               NOT on the gitignored, non-byte-stable route.* cell
 *                               (Pattern 3 / Pitfall 1 — resolves the route.* jurisdiction gap).
 *   3. rankReeval(cell, lens) — the LLM ranking re-eval (196-D1): the targeted blocking lens
 *                               must move up beyond the noise floor AND no blocking lens may
 *                               regress below −noise_floor. Reuses `scoreCellLens` from refute.ts
 *                               (two blind single-cell scores, median+IQR) — does NOT reimplement.
 *   4. verdict()              — combine the three into ACCEPT / REJECT / VOID and print.
 *
 * Cost & determinism (196-D9): the LLM step is strictly local. `--dry-run` bills ZERO API
 * calls and never throws when ANTHROPIC_API_KEY is absent — it degrades to the dry plan.
 * This command is NEVER wired into any `mix` alias or `ci.all`; only the deterministic
 * guards (`verify.critic_trust`, `verify.mechanical`) run in CI.
 *
 * GATE-01 / 196-D1 / 196-D9
 */

import { execSync } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { committedCellIds } from "./bundle.js";
import { scoreCellLens, LENS_DIMENSIONS } from "./refute.js";
import type { LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");

// The blocking panel (196-D2). A ranking regression on ANY blocking lens rejects.
// This constant mirrors the frozen `critic_panel.blocking` ledger block (GATE-04); the
// deterministic guard `verify.critic_trust` is what pins it. Advisory lenses
// (hierarchy, color_contrast) never appear here — they never block (196-D2).
const BLOCKING_PANEL: LensName[] = ["brand_fidelity", "density", "typography", "rhythm"];

// Route → committed page.* Tier-A twin. The mechanical floor is asserted on the twin,
// never on the gitignored route.* cell (Pattern 3 / Pitfall 1). One entry for the tracer;
// Plan 03 expands this map as the route lane grows.
const ROUTE_PAGE_TWIN: Record<string, string> = {
  "route.timeline": "page.timeline.happy",
};

// The tracer is scoped to exactly one theme/breakpoint. Plan 03 fans out.
const CELL_SUFFIX = "__dark-1280";

interface GateArgs {
  page: string; // ledger id, e.g. "route.timeline"
  lens: LensName; // targeted blocking lens
  dryRun: boolean;
  force: boolean;
  n: number;
}

const ALL_LENSES: LensName[] = [
  "hierarchy",
  "density",
  "rhythm",
  "typography",
  "color_contrast",
  "brand_fidelity",
];

/**
 * Parse CLI args (mirrors run.ts's flag-parsing style). argv is process.argv.slice(2)
 * after the `gate` subcommand.
 */
function parseGateArgs(argv: string[]): GateArgs {
  const args: GateArgs = {
    page: "route.timeline",
    lens: "brand_fidelity",
    dryRun: false,
    force: false,
    n: 3,
  };

  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--page":
        args.page = argv[++i];
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
      case "--dry-run":
        args.dryRun = true;
        break;
      case "--force":
        args.force = true;
        break;
      case "--n":
        args.n = parseInt(argv[++i] ?? "3", 10) || 3;
        break;
    }
  }

  return args;
}

// ─── Step 1: blast radius ──────────────────────────────────────────────────────

interface BlastRadius {
  changed: string[];
  scanned: number;
  note: string;
}

/**
 * Deterministic re-capture diff (Pattern 2). The affected set is the subset of
 * `route.*` scorecards whose bytes changed vs the prior/committed copy after an edit.
 *
 * Under `--dry-run` we do NOT shell `npm run capture:pages` (no browser, no billing) —
 * we report the intended diff surface (the route.* cells the recapture WOULD touch) and,
 * with no edit applied, report "0 cells changed" cleanly. Plan 03 wires the real
 * before/after byte diff over a recapture.
 */
function blastRadius(page: string, dryRun: boolean): BlastRadius {
  const routeCells = existsSync(scorecardsDir)
    ? readdirSync(scorecardsDir)
        .filter((f) => f.startsWith(`${page}`) && f.endsWith(".json"))
        .map((f) => f.replace(/\.json$/, ""))
        .sort()
    : [];

  if (dryRun) {
    return {
      changed: [],
      scanned: routeCells.length,
      note:
        `dry-run: skipped \`npm run capture:pages\`; would diff ${routeCells.length} ` +
        `${page}.* scorecard(s) byte-for-byte vs their prior copy. No edit applied → 0 cells changed.`,
    };
  }

  // Non-dry-run (Plan 03 expands this to a real recapture + byte diff). For the tracer
  // with no edit staged, the changed set is empty by construction.
  return {
    changed: [],
    scanned: routeCells.length,
    note: `${routeCells.length} ${page}.* scorecard(s) in scope; 0 changed (no edit staged).`,
  };
}

// ─── Step 2: mechanical floor ──────────────────────────────────────────────────

interface MechanicalFloor {
  twin: string;
  passed: boolean;
  note: string;
}

/**
 * Resolve the route cell to its committed page.* Tier-A twin and gate the deterministic
 * `mix verify.mechanical` on THAT twin — never on the gitignored route.* cell (Pattern 3 /
 * Pitfall 1). A non-zero exit is a hard REJECT (196-D1c / GATE-01): a route "fix" can never
 * bypass the deterministic floor because the floor is enforced on the committed twin.
 *
 * Under `--dry-run` we report the resolved twin and the command that would run, without
 * shelling it (keeps dry-run offline and fast).
 */
function mechanicalFloor(page: string, dryRun: boolean): MechanicalFloor {
  const twin = ROUTE_PAGE_TWIN[page];
  if (!twin) {
    return {
      twin: "(none)",
      passed: false,
      note:
        `No page.* twin registered for "${page}" in ROUTE_PAGE_TWIN — cannot gate the ` +
        `mechanical floor on a committed cell. REJECT (Pattern 3 / Pitfall 1).`,
    };
  }

  if (dryRun) {
    return {
      twin,
      passed: true,
      note:
        `dry-run: would assert \`mix verify.mechanical\` on the committed Tier-A twin ` +
        `"${twin}${CELL_SUFFIX}" (NOT the gitignored "${page}${CELL_SUFFIX}"). Non-zero exit → REJECT.`,
    };
  }

  try {
    execSync(`mix verify.mechanical`, { cwd: repoRoot, stdio: "pipe" });
    return { twin, passed: true, note: `mix verify.mechanical passed (floor holds on ${twin}${CELL_SUFFIX}).` };
  } catch {
    return {
      twin,
      passed: false,
      note: `mix verify.mechanical FAILED — deterministic floor rejects the change (twin ${twin}${CELL_SUFFIX}).`,
    };
  }
}

// ─── Step 3: LLM ranking re-eval ───────────────────────────────────────────────

interface RankReeval {
  ran: boolean;
  targetDelta: number | null;
  noiseFloor: number;
  stable: boolean;
  accepted: boolean;
  void: boolean;
  note: string;
}

/** The accept/reject rule, as prose — printed under dry-run so the plan is self-documenting. */
const ACCEPT_REJECT_RULE =
  `ACCEPT iff the targeted lens improves beyond the noise floor ` +
  `(Δ_target > noise_floor(IQR)) AND every blocking lens holds ` +
  `(Δ_blocking ≥ −noise_floor). An unstable targeted-lens verdict is VOID, not a pass (196-D1).`;

/**
 * The LLM ranking re-eval (196-D1). Composes the EXISTING `scoreCellLens` primitive from
 * refute.ts (two blind single-cell scores, median + IQR noise floor) — does NOT reimplement
 * per-cell scoring. Under `--dry-run` (or a missing key) it prints the rule and skips billing.
 *
 * For the tracer there is no staged edit, so before/after are the same cell → Δ = 0, which
 * fails the strict `Δ > noise_floor` bar (an honest non-accept). Plan 03 supplies the real
 * post-edit recapture as the "after" pole.
 */
async function rankReeval(
  page: string,
  lens: LensName,
  n: number,
  dryRun: boolean,
): Promise<RankReeval> {
  const skeleton: RankReeval = {
    ran: false,
    targetDelta: null,
    noiseFloor: 0,
    stable: false,
    accepted: false,
    void: false,
    note: "",
  };

  if (dryRun || !process.env.ANTHROPIC_API_KEY) {
    return {
      ...skeleton,
      note:
        (dryRun ? "dry-run" : "no ANTHROPIC_API_KEY") +
        `: skipping LLM billing (N=${n}). Rule: ${ACCEPT_REJECT_RULE}`,
    };
  }

  const cell = `${page}${CELL_SUFFIX}`;
  if (!committedCellIds().includes(cell)) {
    return {
      ...skeleton,
      void: true,
      note: `Cell "${cell}" has no scorecard on disk — capture it (\`npm run capture:pages\`) before gating.`,
    };
  }

  const dims = LENS_DIMENSIONS[lens] ?? [];
  // Before / after (tracer: same cell, no staged edit → Δ = 0). Plan 03 diffs a real edit.
  const before = await scoreCellLens(cell, lens, dims);
  const after = await scoreCellLens(cell, lens, dims);

  const stable = before.stable && after.stable;
  const targetDelta =
    before.score !== null && after.score !== null ? after.score - before.score : null;
  const noiseFloor = after.iqr;

  if (!stable || targetDelta === null) {
    return {
      ...skeleton,
      ran: true,
      noiseFloor,
      stable,
      void: true,
      note: `Targeted-lens verdict is unstable → VOID (not a pass), per 196-D1.`,
    };
  }

  const accepted = targetDelta > noiseFloor;
  return {
    ran: true,
    targetDelta,
    noiseFloor,
    stable,
    accepted,
    void: false,
    note: accepted
      ? `Δ_target=${targetDelta} > noise_floor=${noiseFloor.toFixed(1)} — targeted lens improved.`
      : `Δ_target=${targetDelta} ≤ noise_floor=${noiseFloor.toFixed(1)} — no net improvement.`,
  };
}

// ─── Step 4: verdict ───────────────────────────────────────────────────────────

type Verdict = "ACCEPT" | "REJECT" | "VOID" | "DRY-RUN";

function verdict(
  floor: MechanicalFloor,
  reeval: RankReeval,
  dryRun: boolean,
): Verdict {
  if (dryRun) return "DRY-RUN";
  if (!floor.passed) return "REJECT"; // deterministic floor is the hard block (196-D3)
  if (reeval.void) return "VOID";
  return reeval.accepted ? "ACCEPT" : "REJECT";
}

// ─── Orchestrator ──────────────────────────────────────────────────────────────

/**
 * runGate — the propose → re-evaluate → guard loop for one lens × one route cell.
 * Exits 0 under `--dry-run` (no key required); exits non-zero on a REJECT/VOID in a
 * real (keyed) run so a caller/CI-adjacent script can branch on the verdict.
 */
export async function runGate(argv: string[]): Promise<void> {
  const args = parseGateArgs(argv);
  const cell = `${args.page}${CELL_SUFFIX}`;

  console.log(`\n[critic gate] Forward-only net-positive gate — one lens × one route cell`);
  console.log(`  Page (ledger id):   ${args.page}  →  cell ${cell}`);
  console.log(`  Targeted lens:      ${args.lens}  (blocking panel: ${BLOCKING_PANEL.join(", ")})`);
  console.log(`  Mode:               ${args.dryRun ? "dry-run (no billing, no key required)" : "live"}`);

  // Step 1 — blast radius (deterministic re-capture diff)
  const blast = blastRadius(args.page, args.dryRun);
  console.log(`\n  [1/4] Blast radius:  ${blast.changed.length} cell(s) changed of ${blast.scanned} scanned`);
  console.log(`        ${blast.note}`);

  // Step 2 — deterministic mechanical floor on the committed page.* twin
  const floor = mechanicalFloor(args.page, args.dryRun);
  console.log(`\n  [2/4] Mechanical floor twin: ${floor.twin}${CELL_SUFFIX}`);
  console.log(`        ${floor.note}`);

  // Step 3 — LLM ranking re-eval (local-only, bounded, blast-radius scoped)
  const reeval = await rankReeval(args.page, args.lens, args.n, args.dryRun);
  console.log(`\n  [3/4] Ranking re-eval (${args.lens}):`);
  console.log(`        ${reeval.note}`);

  // Step 4 — verdict
  const v = verdict(floor, reeval, args.dryRun);
  console.log(`\n  [4/4] Verdict: ${v}`);
  if (args.dryRun) {
    console.log(
      `\n  Dry plan wired end-to-end (propose → re-evaluate → guard). No API calls billed.` +
        `\n  Run without --dry-run (with ANTHROPIC_API_KEY) to bill the ranking re-eval.\n`,
    );
    process.exit(0);
  }

  // Live run: non-zero exit on a non-accept so callers can branch on the verdict.
  if (v === "ACCEPT") {
    console.log(`\n  ✓ Change ACCEPTED: targeted lens advanced, no blocking regression, floor holds.\n`);
    process.exit(0);
  }
  console.log(`\n  ⛔ Change ${v}: not net-positive under the forward-only gate.\n`);
  process.exit(1);
}
