/**
 * gate.ts — Forward-only net-positive gate orchestrator (Phase 196).
 *
 * The full forward-only ranking gate. A proposed UI edit on a real `/audit` route is
 * ACCEPTED only if the targeted blocking lens improves beyond the critic's own noise
 * floor AND no blocking lens regresses on ANY blast-radius cell AND the deterministic
 * mechanical floor still passes. Advisory lenses are scored and printed but never gate.
 *
 * The loop is an ordered pipeline, each step a separate function:
 *   1. blastRadius(page)          — deterministic re-capture diff (Pattern 2): every
 *                                    `route.*__dark-*` scorecard whose bytes changed vs the
 *                                    prior copy after the edit. Under --dry-run it reports the
 *                                    in-scope set that a recapture WOULD touch ($0, no browser).
 *   2. mechanicalFloor(page)      — resolve the route cell to its committed page.* Tier-A twin
 *                                    (route.timeline → page.timeline.happy) and gate the
 *                                    deterministic `mix verify.mechanical` on that COMMITTED twin,
 *                                    NOT on the gitignored route.* cell (Pattern 3 / Pitfall 1).
 *   3. rankReeval(cells, lens)    — the LLM ranking re-eval (196-D1) fanned out over
 *                                    affectedCells × the 4 BLOCKING lenses. Composes the existing
 *                                    `scoreCellLens` / `runNSamples` primitives (N=3→7 escalation,
 *                                    median + IQR noise floor) — does NOT reimplement scoring.
 *                                    ACCEPT iff Δ_target > noise on the edited cell AND every
 *                                    blocking lens holds (Δ ≥ −noise) on EVERY affected cell.
 *   4. divergenceHalt()           — GATE-03 Goodhart guard: recompute held-out oracle ρ via
 *                                    `mix critic.measure --source synthetic` and HALT (non-zero)
 *                                    if any blocking lens ρ falls below its recorded trust floor.
 *   5. advisoryReport(cells)      — score hierarchy + color_contrast, print under an
 *                                    "ADVISORY — verify vs ground truth" badge; NEVER gate (D2).
 *   6. surfaceMechanicalFixes()   — GATE-02 surface-a-diff: print MODE-A `fix:` hints for the
 *                                    human to apply; no source rewriter, no structural auto-apply.
 *   7. verdict()                  — combine floor → ranking → divergence into
 *                                    ACCEPT / REJECT / VOID / HALT / DRY-RUN and exit.
 *
 * Cost & determinism (196-D9): every LLM step is strictly local. `--dry-run` bills ZERO API
 * calls and never throws when ANTHROPIC_API_KEY is absent — it degrades to the dry plan and reads
 * the RECORDED ledger ρ (never recomputing). This command is NEVER wired into any `mix` alias or
 * `ci.all`; only the deterministic guards (`verify.critic_trust`, `verify.mechanical`) run in CI.
 *
 * GATE-01 / GATE-02 / GATE-03 / 196-D1..D4 / 196-D9
 */

import { execSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { committedCellIds } from "./bundle.js";
import { scoreCellLens, LENS_DIMENSIONS } from "./refute.js";
import type { LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const criticScoresDir = resolve(repoRoot, ".planning/critic-scores");
const ledgerPath = resolve(repoRoot, ".planning/design-system-ledger.json");
const e2eDir = resolve(repoRoot, "examples/threadline_phoenix/e2e");

// The blocking panel (196-D2, mirroring the frozen `critic_panel.blocking` ledger block,
// guarded by GATE-04 / verify.critic_trust). A ranking regression on ANY blocking lens rejects.
const BLOCKING_LENSES: LensName[] = ["brand_fidelity", "density", "typography", "rhythm"];

// The advisory panel (196-D2). Scored + printed with an advisory badge; findings must be
// verified against ground truth before a human acts (they confidently hallucinate specifics —
// [[critic-advisory-lenses-hallucinate-specifics]]). Advisory lenses NEVER gate accept/reject.
const ADVISORY_LENSES: LensName[] = ["hierarchy", "color_contrast"];

// Route → committed page.* Tier-A twin. The mechanical floor is asserted on the twin,
// never on the gitignored route.* cell (Pattern 3 / Pitfall 1). Expand this map as the
// route lane grows (196-04 adds coverage/retention/actor/evidence twins).
const ROUTE_PAGE_TWIN: Record<string, string> = {
  "route.timeline": "page.timeline.happy",
  "route.coverage": "page.coverage.happy",
  "route.retention": "page.retention.happy",
  "route.actor": "page.actor.happy",
  "route.evidence": "page.evidence.happy",
};

// The primary edited cell's theme/breakpoint. The targeted-lens improvement rule is asserted
// on this cell; blast radius fans out over every `route.*__dark-*` cell that changed.
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

/** The dark-theme blast-radius cells for a page currently on disk (gitignored route.* cells). */
function pageDarkCells(page: string): string[] {
  if (!existsSync(scorecardsDir)) return [];
  return readdirSync(scorecardsDir)
    .filter((f) => f.startsWith(`${page}`) && f.includes("__dark-") && f.endsWith(".json"))
    .map((f) => f.replace(/\.json$/, ""))
    .sort();
}

// ─── Step 1: blast radius ──────────────────────────────────────────────────────

interface BlastRadius {
  changed: string[]; // route.* cells whose bytes changed after recapture
  inScope: string[]; // all route.* cells a recapture would touch (the diff surface)
  scanned: number;
  note: string;
}

/**
 * Deterministic re-capture diff (Pattern 2). The affected set is the subset of
 * `route.*__dark-*` scorecards whose bytes changed vs the prior/committed copy after an edit.
 *
 * Live: snapshot the prior bytes, run `npm run capture:pages` (deterministic, $0 LLM), then diff.
 * A shared token/primitive edit changes many cells → many re-score; a page-local template edit
 * changes one → one re-scores (196-D1d). Cells whose bytes are unchanged after recapture are NOT
 * in the blast radius — this reverts scroll_cost jitter false-positives for rhythm (R2 / Pitfall 2).
 *
 * Under `--dry-run` we do NOT shell the capture (no browser, no billing) — we report the in-scope
 * diff surface (the route.* cells the recapture WOULD touch); with no edit applied → 0 changed.
 */
function blastRadius(page: string, dryRun: boolean): BlastRadius {
  const inScope = pageDarkCells(page);

  if (dryRun) {
    return {
      changed: [],
      inScope,
      scanned: inScope.length,
      note:
        `dry-run: skipped \`npm run capture:pages\`; would diff ${inScope.length} ` +
        `${page}.*__dark-* scorecard(s) byte-for-byte vs their prior copy. No edit applied → 0 changed.`,
    };
  }

  // Live: snapshot before-bytes → recapture → diff. Cells with identical bytes are reverted
  // out of the blast radius (unchanged = not affected), which drops scroll_cost jitter (R2).
  const before = new Map<string, string>();
  for (const cell of inScope) {
    before.set(cell, readFileSync(resolve(scorecardsDir, `${cell}.json`), "utf8"));
  }

  try {
    execSync(`npm run capture:pages`, { cwd: e2eDir, stdio: "pipe" });
  } catch (err) {
    return {
      changed: [],
      inScope,
      scanned: inScope.length,
      note: `capture:pages failed — cannot compute blast radius (${String(err)}). Treat as VOID.`,
    };
  }

  const afterCells = pageDarkCells(page);
  const changed = afterCells.filter((cell) => {
    const priorBytes = before.get(cell);
    const nowBytes = existsSync(resolve(scorecardsDir, `${cell}.json`))
      ? readFileSync(resolve(scorecardsDir, `${cell}.json`), "utf8")
      : null;
    // A brand-new cell (no prior) or a byte-changed cell is in the blast radius.
    return priorBytes === undefined || (nowBytes !== null && nowBytes !== priorBytes);
  });

  return {
    changed,
    inScope: afterCells,
    scanned: afterCells.length,
    note:
      `${afterCells.length} ${page}.*__dark-* scorecard(s) recaptured; ` +
      `${changed.length} changed (byte-diff vs prior): ${changed.join(", ") || "(none)"}.`,
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
 * Pitfall 1). A non-zero exit is a hard REJECT (196-D3 / GATE-01c): a route "fix" can never
 * bypass the deterministic floor because the floor is enforced on the committed twin.
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

// ─── Step 3: LLM ranking re-eval (multi-cell × 4 blocking lenses) ───────────────

interface CellLensDelta {
  cell: string;
  lens: LensName;
  delta: number | null;
  noiseFloor: number;
  stable: boolean;
  regressed: boolean; // delta < −noiseFloor
}

interface RankReeval {
  ran: boolean;
  editedCell: string;
  targetLens: LensName;
  deltas: CellLensDelta[];
  targetImproved: boolean;
  anyRegression: boolean;
  accepted: boolean;
  void: boolean;
  note: string;
}

/** The accept/reject rule, as prose — printed under dry-run so the plan is self-documenting. */
const ACCEPT_REJECT_RULE =
  `ACCEPT iff the targeted lens improves beyond the noise floor on the edited cell ` +
  `(Δ_target > noise_floor(IQR)) AND every blocking lens holds on EVERY affected cell ` +
  `(Δ_blocking ≥ −noise_floor). An unstable targeted-lens verdict is VOID, not a pass (196-D1). ` +
  `Only Δ direction vs the per-cell IQR is compared — never an absolute-score threshold.`;

/**
 * Read the pre-edit ("before") per-lens score for a cell from the committed critic-scores
 * snapshot (`.planning/critic-scores/<cell>/<lens>/<dim>.json`, written by an earlier
 * `npm run critic:score --page <page>` the maintainer runs BEFORE editing). This is the
 * before pole the RESEARCH flow specifies ("reuse scoreCellLens OR the committed critic-scores").
 * Returns null when no before-snapshot exists (→ the caller voids and asks for a pre-edit score).
 */
function beforeLensScore(cell: string, lens: LensName): { score: number | null; stable: boolean } | null {
  const dir = resolve(criticScoresDir, cell, lens);
  if (!existsSync(dir)) return null;
  const files = readdirSync(dir).filter((f) => f.endsWith(".json"));
  if (files.length === 0) return null;

  const scores: number[] = [];
  let stable = true;
  for (const f of files) {
    const j = JSON.parse(readFileSync(resolve(dir, f), "utf8")) as { score: number | null; stable: boolean };
    if (j.score === null || j.stable !== true) {
      stable = false;
      continue;
    }
    scores.push(j.score);
  }
  if (scores.length === 0) return { score: null, stable: false };

  const sorted = [...scores].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  const med = sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid];
  return { score: Math.round(med), stable };
}

/**
 * The LLM ranking re-eval (196-D1), fanned out over affectedCells × the 4 BLOCKING lenses.
 * Composes the EXISTING `scoreCellLens` primitive (which itself uses `runNSamples`' N=3→7
 * escalation + IQR noise floor) — does NOT reimplement per-cell scoring. Under `--dry-run`
 * (or a missing key) it prints the fan-out plan + rule and skips billing.
 */
async function rankReeval(
  page: string,
  affectedCells: string[],
  targetLens: LensName,
  n: number,
  dryRun: boolean,
): Promise<RankReeval> {
  const editedCell = `${page}${CELL_SUFFIX}`;
  const base: RankReeval = {
    ran: false,
    editedCell,
    targetLens,
    deltas: [],
    targetImproved: false,
    anyRegression: false,
    accepted: false,
    void: false,
    note: "",
  };

  // The cells actually re-scored: the changed blast-radius set, always including the edited cell.
  const cells = affectedCells.length > 0 ? affectedCells : [editedCell];

  if (dryRun || !process.env.ANTHROPIC_API_KEY) {
    const plan = cells
      .map((c) => `${c} × [${BLOCKING_LENSES.join(", ")}]`)
      .join("\n          ");
    return {
      ...base,
      note:
        (dryRun ? "dry-run" : "no ANTHROPIC_API_KEY") +
        `: skipping LLM billing (N=${n}, escalates to 7 on unstable cells).\n` +
        `        Would re-score (targeted lens=${targetLens}):\n          ${plan}\n` +
        `        Rule: ${ACCEPT_REJECT_RULE}`,
    };
  }

  const deltas: CellLensDelta[] = [];
  for (const cell of cells) {
    if (!committedCellIds().includes(cell)) {
      return {
        ...base,
        void: true,
        note: `Cell "${cell}" has no scorecard on disk — capture it (\`npm run capture:pages\`) before gating.`,
      };
    }
    for (const lens of BLOCKING_LENSES) {
      const dims = LENS_DIMENSIONS[lens] ?? [];
      const after = await scoreCellLens(cell, lens, dims);
      const before = beforeLensScore(cell, lens);

      if (before === null) {
        return {
          ...base,
          ran: true,
          void: true,
          note:
            `No before-snapshot for ${cell}/${lens}. Run \`npm run critic:score -- --page ${page}\` ` +
            `BEFORE editing to record the pre-edit poles, then re-run the gate.`,
        };
      }

      const stable = before.stable && after.stable;
      const delta =
        before.score !== null && after.score !== null ? after.score - before.score : null;
      const noiseFloor = after.iqr;
      deltas.push({
        cell,
        lens,
        delta,
        noiseFloor,
        stable,
        regressed: delta !== null && delta < -noiseFloor,
      });
    }
  }

  const targetRecord = deltas.find((d) => d.cell === editedCell && d.lens === targetLens);
  // An unstable or null targeted-lens verdict is VOID, not a pass (R2 / 196-D1).
  if (!targetRecord || !targetRecord.stable || targetRecord.delta === null) {
    return {
      ...base,
      ran: true,
      deltas,
      void: true,
      note: `Targeted-lens verdict (${editedCell}/${targetLens}) is unstable or null → VOID (not a pass), per 196-D1.`,
    };
  }

  const targetImproved = targetRecord.delta > targetRecord.noiseFloor;
  const anyRegression = deltas.some((d) => d.regressed);
  const accepted = targetImproved && !anyRegression;

  const regressionNote = anyRegression
    ? ` Blocking regression(s): ${deltas
        .filter((d) => d.regressed)
        .map((d) => `${d.cell}/${d.lens} Δ=${d.delta}<−${d.noiseFloor.toFixed(1)}`)
        .join("; ")}.`
    : " No blocking regression on any affected cell.";

  return {
    ran: true,
    editedCell,
    targetLens,
    deltas,
    targetImproved,
    anyRegression,
    accepted,
    void: false,
    note:
      `Δ_target(${editedCell}/${targetLens})=${targetRecord.delta} ` +
      `${targetImproved ? ">" : "≤"} noise_floor=${targetRecord.noiseFloor.toFixed(1)}.` +
      regressionNote,
  };
}

// ─── Step 4: held-out divergence halt (GATE-03 Goodhart guard) ──────────────────

interface LedgerShape {
  critic_panel?: {
    trust_floors?: Record<string, number>;
    blocking?: string[];
    advisory?: string[];
  };
  critic_trust?: Record<string, { spearman: number | null; validated?: boolean }>;
}

function readLedger(): LedgerShape {
  return JSON.parse(readFileSync(ledgerPath, "utf8")) as LedgerShape;
}

interface DivergenceComparison {
  lens: LensName;
  spearman: number | null;
  floor: number | null;
  below: boolean;
}

interface Divergence {
  ran: boolean;
  halted: boolean;
  comparisons: DivergenceComparison[];
  note: string;
}

/**
 * Compare each blocking lens's held-out oracle ρ to its recorded `critic_panel.trust_floors`
 * floor. Reads the floors from the committed ledger (never a hardcoded number). If ANY blocking
 * lens ρ is below its floor → HALT (196-D4 Goodhart guard) BEFORE any accept.
 */
function compareDivergence(): DivergenceComparison[] {
  const ledger = readLedger();
  const floors = ledger.critic_panel?.trust_floors ?? {};
  const trust = ledger.critic_trust ?? {};
  return BLOCKING_LENSES.map((lens) => {
    const spearman = trust[lens]?.spearman ?? null;
    const floor = floors[lens] ?? null;
    const below = spearman !== null && floor !== null && spearman < floor;
    return { lens, spearman, floor, below };
  });
}

/**
 * GATE-03 divergence halt.
 *
 * Under `--dry-run`: read the CURRENTLY RECORDED ρ + floors and print the pass/fail comparison
 * without recomputing (deterministic, $0, no key). Never shells `mix critic.measure`.
 *
 * Live (keyed): shell `mix critic.measure --source synthetic` to RECOMPUTE the held-out ρ into
 * the ledger, then re-read and compare. The oracle is scored for validity ONLY — the gate never
 * edits the synthetic set or adds route cells to chase ρ (Pitfall 4 / 196-D4).
 */
function divergenceHalt(dryRun: boolean): Divergence {
  if (dryRun) {
    const comparisons = compareDivergence();
    const halted = comparisons.some((c) => c.below);
    return {
      ran: false,
      halted,
      comparisons,
      note:
        `dry-run: read RECORDED held-out ρ vs critic_panel.trust_floors (no recompute, $0). ` +
        (halted
          ? "At least one blocking lens is below floor → WOULD HALT."
          : "All blocking lenses ≥ floor → OK."),
    };
  }

  // Live: recompute the held-out ρ on the synthetic oracle, then compare. This is the ONLY
  // path that shells `mix critic.measure --source synthetic` (never under --dry-run).
  try {
    execSync(`mix critic.measure --source synthetic`, { cwd: repoRoot, stdio: "pipe" });
  } catch (err) {
    return {
      ran: true,
      halted: true,
      comparisons: compareDivergence(),
      note: `mix critic.measure --source synthetic failed (${String(err)}) — HALT (cannot certify held-out ρ).`,
    };
  }

  const comparisons = compareDivergence();
  const halted = comparisons.some((c) => c.below);
  return {
    ran: true,
    halted,
    comparisons,
    note: halted
      ? `loop halted — held-out ρ diverged: ${comparisons
          .filter((c) => c.below)
          .map((c) => `${c.lens}: ρ=${c.spearman} < floor=${c.floor}`)
          .join("; ")}`
      : `held-out ρ holds on all blocking lenses (Goodhart guard OK).`,
  };
}

// ─── Step 5: advisory report (NEVER gates) ─────────────────────────────────────

/**
 * Score hierarchy + color_contrast and print under an "ADVISORY — verify vs ground truth" badge.
 * These lenses are ρ≤0.698 and confidently hallucinate specifics (Pitfall 3 / 196-D2). Their
 * output is print-only — it is NEVER an input to the accept/reject verdict.
 */
async function advisoryReport(affectedCells: string[], targetPage: string, dryRun: boolean): Promise<void> {
  const cells = affectedCells.length > 0 ? affectedCells : [`${targetPage}${CELL_SUFFIX}`];

  console.log(`\n  [5/7] ADVISORY — verify vs ground truth (NEVER gates, 196-D2):`);
  if (dryRun || !process.env.ANTHROPIC_API_KEY) {
    console.log(
      `        ${dryRun ? "dry-run" : "no ANTHROPIC_API_KEY"}: would score ${ADVISORY_LENSES.join(", ")} on ` +
        `${cells.length} cell(s); printed with an advisory badge, never fed to accept/reject.`,
    );
    return;
  }

  for (const cell of cells) {
    for (const lens of ADVISORY_LENSES) {
      const dims = LENS_DIMENSIONS[lens] ?? [];
      const scored = await scoreCellLens(cell, lens, dims);
      console.log(
        `        ⚠ ADVISORY ${cell}/${lens}: score=${scored.score ?? "null"} ` +
          `(stable=${scored.stable}) — verify against the committed scorecard/DOM before acting.`,
      );
    }
  }
}

// ─── Step 6: mechanical fix surfacing (GATE-02 surface-a-diff) ──────────────────

/**
 * Surface MODE-A mechanical fixes (snap-to-token, raise-contrast, replace-shadow) as a suggested
 * diff the human applies behind the gate — the GATE-02 auto-apply path for THIS phase (196-D3).
 * It runs `MechanicalChecker` over the committed page.* twin and prints any `fix:` strings.
 * It writes NO source files and performs NO structural auto-apply (the whitelist stays empty).
 */
function surfaceMechanicalFixes(page: string, dryRun: boolean): void {
  const twin = ROUTE_PAGE_TWIN[page];
  console.log(`\n  [6/7] MODE-A mechanical fixes (surface-a-diff, human-applied, 196-D3):`);
  if (!twin) {
    console.log(`        No page.* twin for "${page}" — nothing to surface.`);
    return;
  }
  if (dryRun) {
    console.log(
      `        dry-run: would run MechanicalChecker over the committed twin "${twin}${CELL_SUFFIX}" and ` +
        `print MODE-A fix hints (snap-to-token / raise-contrast / replace-shadow) as a suggested diff. ` +
        `No source file is written; no structural auto-apply (whitelist empty).`,
    );
    return;
  }

  // Live: shell a thin Elixir reporter that prints MODE-A fixes for the twin with a sentinel
  // prefix, so compile noise never contaminates the parsed output. No source is written here.
  const snippet =
    `case Threadline.OperatorSurface.MechanicalChecker.run() do ` +
    `{:ok, _} -> :ok; ` +
    `{:error, vs} -> vs |> Enum.filter(&(&1.mode == "A" and String.starts_with?(&1.cell_id, "${twin}"))) ` +
    `|> Enum.each(fn v -> IO.puts("FIX::" <> v.selector <> " :: " <> v.fix) end) end`;

  let out = "";
  try {
    out = execSync(`mix run --no-start -e ${JSON.stringify(snippet)}`, {
      cwd: repoRoot,
      stdio: ["ignore", "pipe", "pipe"],
    }).toString();
  } catch (err) {
    console.log(`        Could not run the MODE-A reporter (${String(err)}).`);
    return;
  }

  const fixes = out
    .split("\n")
    .filter((l) => l.startsWith("FIX::"))
    .map((l) => l.replace(/^FIX::/, ""));

  if (fixes.length === 0) {
    console.log(`        No MODE-A fixes to surface — the committed twin is already token-clean.`);
    return;
  }
  console.log(`        ${fixes.length} MODE-A fix(es) suggested (apply by hand, then re-gate):`);
  for (const fix of fixes) {
    console.log(`          • ${fix}`);
  }
}

// ─── Step 7: verdict ───────────────────────────────────────────────────────────

type Verdict = "ACCEPT" | "REJECT" | "VOID" | "HALT" | "DRY-RUN";

/**
 * Combine the pipeline into a verdict. Ordering: mechanical floor → ranking → divergence halt.
 * Advisory results and surfaced fixes are print-only and are NEVER inputs here (D2 / D3).
 */
function verdict(
  floor: MechanicalFloor,
  reeval: RankReeval,
  divergence: Divergence,
  dryRun: boolean,
): Verdict {
  if (dryRun) return "DRY-RUN";
  if (!floor.passed) return "REJECT"; // deterministic floor is the hard block (196-D3)
  if (reeval.void) return "VOID";
  if (divergence.halted) return "HALT"; // Goodhart guard halts before accept (196-D4)
  return reeval.accepted ? "ACCEPT" : "REJECT";
}

// ─── Orchestrator ──────────────────────────────────────────────────────────────

/**
 * runGate — the full propose → re-evaluate → guard loop (blast radius → floor → 4-lens ranking →
 * divergence halt → advisory report → surfaced fixes → verdict). Exits 0 under `--dry-run` (no key
 * required); exits non-zero on a REJECT/VOID/HALT in a real (keyed) run so a caller/CI-adjacent
 * script can branch on the verdict.
 */
export async function runGate(argv: string[]): Promise<void> {
  const args = parseGateArgs(argv);
  const editedCell = `${args.page}${CELL_SUFFIX}`;

  console.log(`\n[critic gate] Forward-only net-positive gate (4 blocking lenses, blast-radius aware)`);
  console.log(`  Page (ledger id):   ${args.page}  →  edited cell ${editedCell}`);
  console.log(`  Targeted lens:      ${args.lens}  (blocking: ${BLOCKING_LENSES.join(", ")})`);
  console.log(`  Advisory (no gate): ${ADVISORY_LENSES.join(", ")}`);
  console.log(`  Mode:               ${args.dryRun ? "dry-run (no billing, no key required)" : "live"}  (N=${args.n})`);

  // Step 1 — blast radius (deterministic re-capture diff)
  const blast = blastRadius(args.page, args.dryRun);
  console.log(`\n  [1/7] Blast radius: ${blast.changed.length} changed of ${blast.scanned} scanned`);
  console.log(`        In-scope cells: ${blast.inScope.join(", ") || "(none on disk)"}`);
  console.log(`        ${blast.note}`);

  // Step 2 — deterministic mechanical floor on the committed page.* twin
  const floor = mechanicalFloor(args.page, args.dryRun);
  console.log(`\n  [2/7] Mechanical floor twin: ${floor.twin}${CELL_SUFFIX}`);
  console.log(`        ${floor.note}`);

  // Step 3 — LLM ranking re-eval fanned out over affected cells × 4 blocking lenses
  const affected = args.dryRun ? blast.inScope : blast.changed;
  const reeval = await rankReeval(args.page, affected, args.lens, args.n, args.dryRun);
  console.log(`\n  [3/7] Ranking re-eval (targeted lens ${args.lens}, blocking panel × affected cells):`);
  console.log(`        ${reeval.note}`);

  // Step 4 — held-out divergence halt (Goodhart guard) — before any accept
  const divergence = divergenceHalt(args.dryRun);
  console.log(`\n  [4/7] Held-out divergence (GATE-03 Goodhart guard):`);
  for (const c of divergence.comparisons) {
    console.log(
      `        ${c.lens}: ρ=${c.spearman ?? "null"} vs floor=${c.floor ?? "null"} → ${c.below ? "HALT" : "OK"}`,
    );
  }
  console.log(`        ${divergence.note}`);

  // Step 5 — advisory report (never gates)
  await advisoryReport(affected, args.page, args.dryRun);

  // Step 6 — surface MODE-A mechanical fixes (surface-a-diff; human applies)
  surfaceMechanicalFixes(args.page, args.dryRun);

  // Step 7 — verdict
  const v = verdict(floor, reeval, divergence, args.dryRun);
  console.log(`\n  [7/7] Verdict: ${v}`);

  if (args.dryRun) {
    console.log(
      `\n  Dry plan wired end-to-end (blast radius → floor → 4-lens ranking → divergence → advisory → fixes).` +
        `\n  No API calls billed. Run without --dry-run (with ANTHROPIC_API_KEY) to bill the ranking re-eval.\n`,
    );
    process.exit(0);
  }

  // Live run: non-zero exit on a non-accept so callers can branch on the verdict.
  if (v === "ACCEPT") {
    console.log(`\n  ✓ Change ACCEPTED: targeted lens advanced, no blocking regression, floor holds, oracle stable.\n`);
    process.exit(0);
  }
  console.log(`\n  ⛔ Change ${v}: not net-positive under the forward-only gate.\n`);
  process.exit(1);
}
