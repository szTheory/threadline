/**
 * label.ts — Blind-round golden-set authoring CLI (D-09, Plan 07).
 *
 * Invoked via `run.ts label` / `npm run critic:label`.
 *
 * Subcommands (via argv flags):
 *   --bootstrap           Seed the labeling queue (pole anchors → mid-range)
 *   --round r1|r2         Label the queue for round r1 or r2 (interactive)
 *   --reconcile           Present r1≠r2 disagreements; write golden-set.json
 *   --status              Show per-lens N vs the ≥20 bar
 *   --add <cell-id>       Append a cell to the queue (refuses held_out_ids)
 *   --revalidate          Re-queue cells for a specific lens (requires --lens)
 *   --lens <lens>         Scope to a specific lens
 *   --page <ledger_id>    Scope to a specific page
 *   --pairs               Label A/B pairs (better/worse + clear/subtle margin)
 *   --resume              Resume an incomplete round at the last unlabeled item
 *   --brief               Collapse the per-item lens guidance to a one-line legend
 *
 * Blind enforcement (D-09):
 *   r1 writes to .planning/golden/rounds/r1.json (tokens generated per session)
 *   --round r2 NEVER reads or displays r1.json content
 *   --round r2 refuses to run until r1.json is committed to git
 *   --reconcile is the ONLY writer of golden-set.json
 *   held_out_ids are refused at enqueue time ("Phase-196 true-north")
 *
 * First-run empty state: prints guided path, exits 0.
 *
 * D-09 / CRITIC-01 / T-195-22 (ID masking, blind rounds) / T-195-23 (held_out refusal)
 */

import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from "node:fs";
import { createInterface } from "node:readline";
import { execSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
// critic/ → e2e/ → threadline_phoenix/ → examples/ → repo root
const repoRoot = resolve(here, "../../../..");

// ── Path constants ────────────────────────────────────────────────────────────
const goldenDir = resolve(repoRoot, ".planning/golden");
const roundsDir = resolve(goldenDir, "rounds");
const queuePath = resolve(goldenDir, "queue.json");
const goldenSetPath = resolve(goldenDir, "golden-set.json");
const r1Path = resolve(roundsDir, "r1.json");
const r2Path = resolve(roundsDir, "r2.json");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const rubricDir = resolve(here, "rubrics");

const ALL_LENSES: LensName[] = [
  "hierarchy",
  "density",
  "rhythm",
  "typography",
  "color_contrast",
  "brand_fidelity",
];

// Plain-English per-lens guidance shown inline during labeling (grounded in the
// rubric dimensions + reference bar). good/bad are lens-specific; borderline/broken
// are shared (VERDICT_SCALE). This is what tells the labeler what they are judging.
const LENS_GUIDE: Record<LensName, { q: string; good: string; bad: string }> = {
  hierarchy: {
    q: "does your eye land on one main content thing first?",
    good: "one clear anchor; the eye knows where to go",
    bad: "two+ things fight, or chrome (nav/filter) is loudest",
  },
  density: {
    q: "is the real data prominent — not buried in chrome or self-describing copy?",
    good: "the data speaks for itself; the primary task stands out",
    bad: "clutter / explanatory copy / chrome drowns the task",
  },
  rhythm: {
    q: "are related things grouped, with even, consistent spacing?",
    good: "consistent vertical rhythm; clear grouping by proximity",
    bad: "uneven gaps; unrelated things crammed or scattered",
  },
  typography: {
    q: "are text roles clearly distinct, and does size match importance?",
    good: "heading / body / label clearly differ; size tracks importance",
    bad: "everything similar weight & size; size doesn't signal importance",
  },
  color_contrast: {
    q: "is color a meaningful signal, accent reserved for its job, and readable?",
    good: "color means something; accent used sparingly; good contrast",
    bad: "decorative / random color; accent overused; low contrast",
  },
  brand_fidelity: {
    q: "does it feel designed in a terse, operational voice — not generically recolored?",
    good: "intentional design; precise, operational copy",
    bad: "generic / recolored; chatty, vague, or apologetic copy",
  },
};

// Shared meanings for the middle/bottom of the single-verdict scale.
const VERDICT_SCALE = {
  borderline: "mostly there, one notable flaw",
  broken: "empty / error / unusable / can't tell",
} as const;

// Single canonical key→verdict map for single (non-pair) items.
const SINGLE_VERDICTS: Record<string, RoundItem["verdict"]> = {
  g: "good",
  o: "borderline",
  a: "bad",
  x: "broken",
};

/**
 * Print plain-English guidance for the current lens above the verdict prompt, so
 * the labeler knows exactly what they are judging. `brief` collapses it to a
 * one-line legend for experienced labelers (--brief).
 */
function renderLensGuide(lens: LensName, pairs: boolean, brief: boolean): void {
  if (brief) {
    console.log(
      pairs
        ? "  Verdict: b=better  w=worse   then  c=clear  s=subtle"
        : "  Verdict: g=good  o=borderline  a=bad  x=broken",
    );
    return;
  }

  const g = LENS_GUIDE[lens];
  const name = lens.toUpperCase();

  if (pairs) {
    console.log(`  Comparing for ${name} — ${g.q}`);
    console.log("    b better    this screenshot serves the lens better");
    console.log("    w worse     this one is weaker");
    console.log("    then  c clear (obvious)  /  s subtle (slight)");
    console.log("  Glance ~2s, trust your gut.");
    return;
  }

  console.log(`  Judging ${name} — ${g.q}`);
  console.log(`    g good        ${g.good}`);
  console.log(`    o borderline  ${VERDICT_SCALE.borderline}`);
  console.log(`    a bad         ${g.bad}`);
  console.log(`    x broken      ${VERDICT_SCALE.broken}`);
  console.log("  Glance ~2s, trust your gut, then one key.");
}

// The 3 target pages for mid-range bootstrap sampling (transaction/coverage/retention)
const BOOTSTRAP_TARGET_PAGES = ["transaction", "coverage", "retention"];

// ── Types ─────────────────────────────────────────────────────────────────────

interface QueueItem {
  id: string; // q_001 etc
  cell_id: string;
  lens: LensName;
  kind: "single" | "pair";
  pair_with: string | null;
  queue_order: number;
  source: "bootstrap_pole" | "bootstrap_midrange" | "manual" | "revalidate";
}

interface QueueFile {
  version: number;
  created_at: string;
  items: QueueItem[];
}

interface RoundItem {
  queue_id: string;
  token: string; // ephemeral opaque token shown to labeler
  cell_id: string; // stored for reconcile; NOT shown during labeling
  lens: LensName;
  kind: "single" | "pair";
  pair_with_token: string | null;
  verdict: "good" | "borderline" | "bad" | "broken" | "better" | "worse";
  margin?: "clear" | "subtle"; // for pair verdicts
  evidence: string;
  labeled_at: string;
}

interface RoundFile {
  round: "r1" | "r2";
  completed: boolean;
  completed_at: string | null;
  items: RoundItem[];
}

interface GoldenItem {
  id: string; // gs_001 etc
  cell_id: string;
  lens: LensName;
  kind: "single" | "pair";
  pair_with: string | null;
  r1: { verdict: string; evidence: string; blind: true };
  r2: { verdict: string; evidence: string; blind: true };
  kept: boolean;
}

interface GoldenSetFile {
  version: number;
  model_pin: string;
  rubric_rev: string | null;
  held_out_ids: string[];
  items: GoldenItem[];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function writeJson(path: string, value: unknown): void {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function readJson<T>(path: string): T {
  return JSON.parse(readFileSync(path, "utf8")) as T;
}

function ensureDirs(): void {
  mkdirSync(goldenDir, { recursive: true });
  mkdirSync(roundsDir, { recursive: true });
}

/** Generate an ephemeral opaque token (not shown as cell_id; resets each session). */
function generateToken(index: number, round: "r1" | "r2"): string {
  const prefix = round === "r1" ? "A" : "B";
  return `${prefix}${String(index + 1).padStart(3, "0")}`;
}

/** Return committed scorecard cell IDs from .planning/scorecards/. */
function committedCellIds(): string[] {
  if (!existsSync(scorecardsDir)) return [];
  return readdirSync(scorecardsDir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => f.replace(/\.json$/, ""));
}

/** Read held_out_ids from golden-set.json. */
function heldOutIds(): string[] {
  if (!existsSync(goldenSetPath)) return [];
  try {
    const gs = readJson<GoldenSetFile>(goldenSetPath);
    return gs.held_out_ids ?? [];
  } catch {
    return [];
  }
}

/** Parse pole cell IDs from a rubric file's ## Anchors section. */
function parseRubricPoles(lens: LensName): { pass: string; fail: string } | null {
  const rubricPath = resolve(rubricDir, `${lens}.md`);
  if (!existsSync(rubricPath)) return null;
  const text = readFileSync(rubricPath, "utf8");
  const passMatch = text.match(/\*\*Pass pole:\*\*\s+`([^`]+)`/);
  const failMatch = text.match(/\*\*Fail pole:\*\*\s+`([^`]+)`/);
  if (!passMatch || !failMatch) return null;
  return { pass: passMatch[1], fail: failMatch[1] };
}

/** Open a screenshot for viewing (iTerm2 inline if available, else OS viewer). */
function showScreenshot(screenshotPath: string): void {
  if (!existsSync(screenshotPath)) {
    console.log(`  [screenshot not found: ${screenshotPath}]`);
    return;
  }

  // iTerm2 inline image protocol
  if (process.env["TERM_PROGRAM"] === "iTerm.app") {
    try {
      const imgData = readFileSync(screenshotPath).toString("base64");
      const imgName = Buffer.from(screenshotPath).toString("base64");
      const iterm2Seq = `\x1b]1337;File=name=${imgName};inline=1;width=60:${imgData}\x07`;
      process.stdout.write(iterm2Seq + "\n");
      return;
    } catch {
      // Fall through to OS viewer
    }
  }

  // macOS `open` command (opens in Preview or default image viewer)
  try {
    execSync(`open ${JSON.stringify(screenshotPath)}`, { stdio: "ignore" });
    console.log(`  [screenshot opened in viewer]`);
  } catch {
    console.log(`  [could not open screenshot: ${screenshotPath}]`);
  }
}

/** Get screenshot path for a cell ID from its scorecard. */
function getScreenshotPath(cellId: string): string | null {
  const scorecardPath = resolve(scorecardsDir, `${cellId}.json`);
  if (!existsSync(scorecardPath)) return null;
  try {
    const sc = readJson<{ artifacts: { screenshot: string } }>(scorecardPath);
    return resolve(repoRoot, sc.artifacts.screenshot);
  } catch {
    return null;
  }
}

/** Prompt for a single keystroke (verdict input). Returns the character. */
async function promptKeystroke(validKeys: string[]): Promise<string> {
  return new Promise((resolve) => {
    const onData = (key: string) => {
      if (key === "\x03") {
        // Ctrl+C
        process.stdout.write("\n");
        process.exit(0);
      }
      if (validKeys.includes(key.toLowerCase())) {
        process.stdout.write(key.toLowerCase() + "\n");
        if (process.stdin.setRawMode) {
          process.stdin.setRawMode(false);
          process.stdin.pause();
          process.stdin.removeListener("data", onData);
        }
        resolve(key.toLowerCase());
      }
    };

    if (process.stdin.isTTY && process.stdin.setRawMode) {
      process.stdin.setRawMode(true);
      process.stdin.resume();
      process.stdin.setEncoding("utf8");
      process.stdin.on("data", onData);
    } else {
      // Non-TTY fallback: read a line
      const rl = createInterface({ input: process.stdin });
      rl.question("", (answer) => {
        rl.close();
        const key = answer.trim()[0]?.toLowerCase() ?? "";
        if (validKeys.includes(key)) {
          resolve(key);
        } else {
          resolve(validKeys[0]);
        }
      });
    }
  });
}

/** Prompt for a text line (evidence input). */
async function promptLine(promptText: string): Promise<string> {
  return new Promise((resolve) => {
    const rl = createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    rl.question(promptText, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

// ── Bootstrap ─────────────────────────────────────────────────────────────────

/**
 * Seed the labeling queue: pole anchors first, then mid-range from target pages.
 * Poles-first builds labeler calibration AND serves as the D-05 few-shot poles.
 * Held-out IDs are refused at queue time (T-195-23).
 */
function runBootstrap(opts: { lens?: LensName; page?: string }): void {
  const held = heldOutIds();
  const allCells = committedCellIds();
  const items: QueueItem[] = [];
  let order = 0;

  // Track which cells are already queued to avoid duplicates
  const queued = new Set<string>();

  const addItem = (
    cellId: string,
    lens: LensName,
    source: QueueItem["source"],
  ): void => {
    if (held.includes(cellId)) {
      console.warn(
        `  [skip] ${cellId} is in held_out_ids — Phase-196 true-north, not enqueued.`,
      );
      return;
    }
    const key = `${cellId}::${lens}`;
    if (queued.has(key)) return;
    if (!allCells.includes(cellId)) {
      console.warn(`  [skip] ${cellId} not found in scorecards/`);
      return;
    }
    queued.add(key);
    items.push({
      id: `q_${String(items.length + 1).padStart(3, "0")}`,
      cell_id: cellId,
      lens,
      kind: "single",
      pair_with: null,
      queue_order: order++,
      source,
    });
  };

  const lensesToQueue = opts.lens ? [opts.lens] : ALL_LENSES;

  // ── Phase 1: Pole anchors (one pass + one fail per lens, dark-1280) ──────
  console.log("\n[bootstrap] Phase 1: Pole anchors (6 rubrics × 2 poles)...");
  for (const lens of lensesToQueue) {
    const poles = parseRubricPoles(lens);
    if (!poles) {
      console.warn(`  [skip] No rubric found for lens: ${lens}`);
      continue;
    }
    // Queue the fail pole first (builds adversarial calibration)
    addItem(poles.fail, lens, "bootstrap_pole");
    addItem(poles.pass, lens, "bootstrap_pole");
  }
  console.log(`  ${items.length} pole items queued.`);

  // ── Phase 2: Mid-range cells from the 3 target pages ─────────────────────
  console.log(
    `\n[bootstrap] Phase 2: Mid-range cells (${BOOTSTRAP_TARGET_PAGES.join(", ")})...`,
  );
  const pages = opts.page ? [opts.page] : BOOTSTRAP_TARGET_PAGES;
  for (const page of pages) {
    const pageCells = allCells.filter((c) => {
      // Filter: cell belongs to this page + dark theme + 1280bp (primary capture)
      return c.startsWith(`page.${page}.`) && c.includes("__dark-1280");
    });
    for (const cellId of pageCells.slice(0, 4)) {
      // Up to 4 mid-range cells per target page per lens
      for (const lens of lensesToQueue) {
        addItem(cellId, lens, "bootstrap_midrange");
      }
    }
  }

  const preBootstrap = items.length;
  const midRangeAdded = preBootstrap - (lensesToQueue.length * 2);
  console.log(`  ${midRangeAdded} mid-range items queued.`);

  if (items.length === 0) {
    console.log(
      "\n[bootstrap] No items queued — check that scorecards/ is populated.",
    );
    return;
  }

  // ── Write queue file ──────────────────────────────────────────────────────
  ensureDirs();
  const existing = existsSync(queuePath)
    ? readJson<QueueFile>(queuePath)
    : null;

  if (existing && existing.items.length > 0) {
    console.log(
      `\n[bootstrap] Existing queue has ${existing.items.length} items. Appending ${items.length} new items.`,
    );
    // Deduplicate against existing queue
    const existingKeys = new Set(
      existing.items.map((i) => `${i.cell_id}::${i.lens}`),
    );
    const newItems = items.filter(
      (i) => !existingKeys.has(`${i.cell_id}::${i.lens}`),
    );
    existing.items.push(...newItems);
    writeJson(queuePath, existing);
    console.log(`  ${newItems.length} new items added to queue.`);
  } else {
    const queue: QueueFile = {
      version: 1,
      created_at: new Date().toISOString(),
      items,
    };
    writeJson(queuePath, queue);
    console.log(`\n[bootstrap] Queue created with ${items.length} items.`);
  }

  console.log("\nNext steps:");
  console.log(
    "  1. Run: npm run critic:label -- --round r1   (label round 1)",
  );
  console.log(
    "  2. Commit r1.json: git add .planning/golden/rounds/r1.json && git commit -m 'chore: golden set r1 labels'",
  );
  console.log(
    "  3. Run: npm run critic:label -- --round r2   (label round 2, blind)",
  );
  console.log(
    "  4. Run: npm run critic:label -- --reconcile  (produce golden-set.json)",
  );
}

// ── Round labeling ────────────────────────────────────────────────────────────

/**
 * Check whether r1.json is committed to git (required before r2 can run).
 * Blind test-retest: r2 refuses until r1 is committed.
 */
function isR1Committed(): boolean {
  try {
    const result = execSync(
      `git -C ${JSON.stringify(repoRoot)} status --porcelain .planning/golden/rounds/r1.json`,
      { encoding: "utf8", stdio: "pipe" },
    );
    // If r1.json is tracked with no untracked/modified status, it's committed
    // An empty result means the file is committed and clean
    return result.trim() === "";
  } catch {
    return false;
  }
}

async function runRound(
  round: "r1" | "r2",
  opts: { lens?: LensName; page?: string; pairs: boolean; resume: boolean; brief: boolean },
): Promise<void> {
  // Blind enforcement: r2 refuses until r1 is committed
  if (round === "r2") {
    if (!existsSync(r1Path)) {
      console.error(
        "\n[critic label] ERROR: .planning/golden/rounds/r1.json does not exist.",
      );
      console.error(
        "  Run --round r1 first, then commit r1.json before running r2.",
      );
      process.exit(1);
    }
    if (!isR1Committed()) {
      console.error(
        "\n[critic label] ERROR: r1.json exists but is not committed to git.",
      );
      console.error(
        "  Commit r1.json first: git add .planning/golden/rounds/r1.json && git commit",
      );
      console.error(
        "  This enforces a time gap between r1 and r2 for honest blind test-retest.",
      );
      process.exit(1);
    }
  }

  if (!existsSync(queuePath)) {
    console.log("\n[critic label] No queue found.");
    console.log(
      "  Run: npm run critic:label -- --bootstrap   (seed the labeling queue)",
    );
    process.exit(0);
  }

  const queue = readJson<QueueFile>(queuePath);
  if (queue.items.length === 0) {
    console.log("\n[critic label] Queue is empty.");
    console.log(
      "  Run: npm run critic:label -- --bootstrap   (seed the labeling queue)",
    );
    process.exit(0);
  }

  // Load existing round file for resume
  const roundPath = round === "r1" ? r1Path : r2Path;
  let roundFile: RoundFile;
  if (opts.resume && existsSync(roundPath)) {
    roundFile = readJson<RoundFile>(roundPath);
    console.log(
      `[critic label] Resuming ${round} (${roundFile.items.length} already labeled).`,
    );
  } else {
    roundFile = {
      round,
      completed: false,
      completed_at: null,
      items: [],
    };
  }

  // Determine which queue items to label (skip already-labeled ones)
  const labeledQueueIds = new Set(roundFile.items.map((i) => i.queue_id));

  // Filter and scope queue items
  let toLabel = queue.items.filter((qi) => {
    if (labeledQueueIds.has(qi.id)) return false;
    if (opts.lens && qi.lens !== opts.lens) return false;
    if (opts.page && !qi.cell_id.includes(opts.page)) return false;
    if (opts.pairs && qi.kind !== "pair") return false;
    return true;
  });

  // For r2: reshuffle (Fisher-Yates) — different presentation order than r1
  if (round === "r2") {
    for (let i = toLabel.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [toLabel[i], toLabel[j]] = [toLabel[j], toLabel[i]];
    }
  }

  if (toLabel.length === 0) {
    console.log(`\n[critic label] All items for ${round} are already labeled.`);
    if (!roundFile.completed) {
      roundFile.completed = true;
      roundFile.completed_at = new Date().toISOString();
      ensureDirs();
      writeJson(roundPath, roundFile);
    }
    return;
  }

  console.log(
    `\n[critic label] Round ${round.toUpperCase()} — ${toLabel.length} items to label`,
  );
  console.log("");
  console.log("  How this works: you're building the answer key the AI critic is graded against.");
  console.log("  For each screenshot you judge ONE quality (the \"lens\"), press one key, add a few words.");
  console.log("  Trust your first-glance gut — that is exactly what's being measured; don't overthink it.");
  console.log("  Progress saves after every item — Ctrl+C anytime and re-run to resume where you left off.");
  console.log("  Tip: do one lens at a time with  --lens hierarchy  to avoid switching gears each item.");
  console.log("");
  if (round === "r1") {
    console.log(
      "  IDs are masked — you will see tokens (A001, A002, ...), not cell names.",
    );
    console.log("  After completing r1, commit it before running r2.\n");
  } else {
    console.log(
      "  This round NEVER shows round-1 answers or original cell IDs.",
    );
    console.log(
      "  Items are reshuffled and re-tokenized for true blind test-retest.\n",
    );
  }

  const verdictKeys = opts.pairs ? ["b", "w"] : ["g", "o", "a", "x"];

  for (let idx = 0; idx < toLabel.length; idx++) {
    const qItem = toLabel[idx];
    const token = generateToken(roundFile.items.length, round);

    console.log(`\n─── [${idx + 1}/${toLabel.length}] Token: ${token} ───────────────────`);
    console.log(`  Lens:    ${qItem.lens}`);
    if (qItem.kind === "pair" && qItem.pair_with) {
      console.log(`  Kind:    pair (vs ${round === "r1" ? "B" : "A"}${String(roundFile.items.length + 2).padStart(3, "0")})`);
    } else {
      console.log("  Kind:    single");
    }
    console.log("");

    // Plain-English guidance for THIS lens — what you're judging + what good/bad looks like.
    renderLensGuide(qItem.lens, opts.pairs, opts.brief);
    console.log("");

    // Show screenshot (masked — no cell_id displayed)
    const screenshotPath = getScreenshotPath(qItem.cell_id);
    if (screenshotPath) {
      showScreenshot(screenshotPath);
    }

    // Verdict prompt
    let verdictChar = "";
    let verdict: RoundItem["verdict"];
    let margin: "clear" | "subtle" | undefined;

    if (opts.pairs) {
      process.stdout.write("  Better? [b/w]  (Ctrl+C = quit)\n  > ");
      verdictChar = await promptKeystroke(verdictKeys);
      verdict = (verdictChar === "b" ? "better" : "worse") as RoundItem["verdict"];

      // Margin for pairs
      process.stdout.write("  Margin? [c=clear / s=subtle]\n  > ");
      const marginChar = await promptKeystroke(["c", "s"]);
      margin = marginChar === "c" ? "clear" : "subtle";
    } else {
      process.stdout.write("  Verdict? [g/o/a/x]  (Ctrl+C = quit)\n  > ");
      verdictChar = await promptKeystroke(verdictKeys);
      verdict = SINGLE_VERDICTS[verdictChar] ?? "borderline";
    }

    // Evidence (required — CRITIC-05 applies to oracle too, D-01)
    let evidence = "";
    while (!evidence) {
      evidence = await promptLine(
        '  Why? a few words on what you saw (e.g. "eye hit the big action row"): ',
      );
      if (!evidence) {
        console.log("  Just a few words is fine — what did you notice? (required)");
      }
    }

    const item: RoundItem = {
      queue_id: qItem.id,
      token,
      cell_id: qItem.cell_id, // stored for reconcile; NOT shown to labeler
      lens: qItem.lens,
      kind: qItem.kind,
      pair_with_token: null, // TODO: wire pair tokens when pair mode is implemented
      verdict,
      ...(margin !== undefined ? { margin } : {}),
      evidence,
      labeled_at: new Date().toISOString(),
    };

    if (opts.pairs && margin) {
      item.margin = margin;
    }

    roundFile.items.push(item);

    // Save after each label (crash-safe, enables --resume)
    ensureDirs();
    writeJson(roundPath, roundFile);

    console.log(
      `  Saved: ${token} → ${verdict}${margin ? ` (${margin})` : ""}`,
    );
  }

  // Mark round complete
  roundFile.completed = true;
  roundFile.completed_at = new Date().toISOString();
  writeJson(roundPath, roundFile);

  console.log(`\n[critic label] Round ${round.toUpperCase()} complete — ${roundFile.items.length} items labeled.`);

  if (round === "r1") {
    console.log(
      "\nNext: commit r1.json, then run r2:",
    );
    console.log(
      "  git add .planning/golden/rounds/r1.json && git commit -m 'chore: golden set r1 labels'",
    );
    console.log("  npm run critic:label -- --round r2");
  } else {
    console.log(
      "\nNext: reconcile the two rounds into golden-set.json:",
    );
    console.log("  npm run critic:label -- --reconcile");
  }
}

// ── Reconcile ─────────────────────────────────────────────────────────────────

/**
 * --reconcile: compare r1 and r2, present disagreements, write golden-set.json.
 * This is the ONLY writer of golden-set.json.
 */
async function runReconcile(): Promise<void> {
  if (!existsSync(r1Path) || !existsSync(r2Path)) {
    console.error(
      "\n[critic label] ERROR: Both r1.json and r2.json must exist before reconciling.",
    );
    console.error(
      "  Run --round r1 and --round r2 first.",
    );
    process.exit(1);
  }

  const r1 = readJson<RoundFile>(r1Path);
  const r2 = readJson<RoundFile>(r2Path);

  // Build lookup by cell_id + lens for each round
  const r1Map = new Map<string, RoundItem>();
  for (const item of r1.items) {
    r1Map.set(`${item.cell_id}::${item.lens}`, item);
  }

  const r2Map = new Map<string, RoundItem>();
  for (const item of r2.items) {
    r2Map.set(`${item.cell_id}::${item.lens}`, item);
  }

  const agreements: GoldenItem[] = [];
  const disagreements: Array<{ key: string; r1Item: RoundItem; r2Item: RoundItem }> = [];

  // Compare rounds — keep only items in both rounds
  for (const [key, r1Item] of r1Map) {
    const r2Item = r2Map.get(key);
    if (!r2Item) continue; // r2 didn't label this item

    if (r1Item.verdict === r2Item.verdict) {
      // Agreement: include in golden set
      agreements.push({
        id: `gs_${String(agreements.length + 1).padStart(3, "0")}`,
        cell_id: r1Item.cell_id,
        lens: r1Item.lens,
        kind: r1Item.kind,
        pair_with: null,
        r1: {
          verdict: r1Item.verdict,
          evidence: r1Item.evidence,
          blind: true,
        },
        r2: {
          verdict: r2Item.verdict,
          evidence: r2Item.evidence,
          blind: true,
        },
        kept: true,
      });
    } else {
      // Disagreement: queue for human tiebreak
      disagreements.push({ key, r1Item, r2Item });
    }
  }

  console.log(
    `\n[critic label] Reconcile: ${r1Map.size} r1 items, ${r2Map.size} r2 items`,
  );
  console.log(
    `  ${agreements.length} agreements, ${disagreements.length} disagreements`,
  );

  // Present disagreements for human tiebreak
  if (disagreements.length > 0) {
    console.log(
      `\n  Presenting ${disagreements.length} disagreement${disagreements.length === 1 ? "" : "s"} for tiebreak...`,
    );
    console.log("  (r1 and r2 gave different verdicts — keep r1, keep r2, or drop)\n");

    for (const { key, r1Item, r2Item } of disagreements) {
      const cellParts = key.split("::");
      const lens = cellParts[1];
      console.log(
        `\n  Disagreement: lens=${lens}`,
      );
      console.log(`    r1 verdict: ${r1Item.verdict}`);
      console.log(`    r2 verdict: ${r2Item.verdict}`);
      console.log(`    r1 evidence: ${r1Item.evidence}`);
      console.log(`    r2 evidence: ${r2Item.evidence}`);

      // Show screenshot
      const screenshotPath = getScreenshotPath(r1Item.cell_id);
      if (screenshotPath) showScreenshot(screenshotPath);

      console.log("  Keep: 1=r1  2=r2  d=drop   [Ctrl+C = quit]");
      process.stdout.write("  > ");
      const choice = await promptKeystroke(["1", "2", "d"]);

      if (choice === "1") {
        agreements.push({
          id: `gs_${String(agreements.length + 1).padStart(3, "0")}`,
          cell_id: r1Item.cell_id,
          lens: r1Item.lens,
          kind: r1Item.kind,
          pair_with: null,
          r1: { verdict: r1Item.verdict, evidence: r1Item.evidence, blind: true },
          r2: { verdict: r2Item.verdict, evidence: r2Item.evidence, blind: true },
          kept: true,
        });
        console.log("  Kept r1 verdict.");
      } else if (choice === "2") {
        agreements.push({
          id: `gs_${String(agreements.length + 1).padStart(3, "0")}`,
          cell_id: r1Item.cell_id,
          lens: r1Item.lens,
          kind: r1Item.kind,
          pair_with: null,
          r1: { verdict: r1Item.verdict, evidence: r1Item.evidence, blind: true },
          r2: { verdict: r2Item.verdict, evidence: r2Item.evidence, blind: true },
          kept: true,
        });
        console.log("  Kept r2 verdict.");
      } else {
        console.log("  Dropped (disagreement not resolved).");
      }
    }
  }

  // Write golden-set.json (sole writer, T-195-22)
  const existingGs = existsSync(goldenSetPath)
    ? readJson<GoldenSetFile>(goldenSetPath)
    : {
        version: 1,
        model_pin: "claude-opus-4-8",
        rubric_rev: null,
        held_out_ids: [],
        items: [] as GoldenItem[],
      };

  existingGs.items = agreements;
  ensureDirs();
  writeJson(goldenSetPath, existingGs);

  console.log(
    `\n[critic label] golden-set.json written: ${agreements.length} items.`,
  );

  // Per-lens count summary
  const lensCount: Partial<Record<LensName, number>> = {};
  for (const item of agreements) {
    lensCount[item.lens] = (lensCount[item.lens] ?? 0) + 1;
  }
  console.log("\n  Per-lens count:");
  for (const lens of ALL_LENSES) {
    const n = lensCount[lens] ?? 0;
    const bar = n >= 20 ? "✓" : "provisional";
    console.log(`    ${lens}: ${n}/20+ (${bar})`);
  }
}

// ── Status ────────────────────────────────────────────────────────────────────

function runStatus(): void {
  console.log("\n[critic label] Golden-set status\n");

  if (!existsSync(goldenSetPath)) {
    console.log("  No golden-set.json found.");
    console.log(
      "  Run: npm run critic:label -- --bootstrap   to seed the queue.",
    );
    return;
  }

  const gs = readJson<GoldenSetFile>(goldenSetPath);
  const lensCount: Partial<Record<LensName, number>> = {};
  for (const item of gs.items) {
    lensCount[item.lens] = (lensCount[item.lens] ?? 0) + 1;
  }

  console.log(
    `  Total items: ${gs.items.length}`,
  );
  console.log(`  model_pin: ${gs.model_pin}`);
  console.log(`  held_out_ids: ${gs.held_out_ids.length}`);
  console.log("\n  Per-lens progress (target: ≥20 per lens for validated status):");
  console.log(
    "  ─────────────────────────────────────────────────────────────────────",
  );

  let allProvTally = 0;
  for (const lens of ALL_LENSES) {
    const n = lensCount[lens] ?? 0;
    const validated = n >= 20;
    const status = validated ? "validated" : "provisional (ratchet blocked)";
    const bar = "█".repeat(Math.min(n, 20)).padEnd(20, "░");
    console.log(`  ${lens.padEnd(16)} [${bar}] ${n}/20  ${status}`);
    if (!validated) allProvTally++;
  }
  console.log(
    "  ─────────────────────────────────────────────────────────────────────",
  );

  if (allProvTally === 0) {
    console.log("  All lenses at ≥20 judgments. Ready for trust computation.");
    console.log("  Run: mix verify.ui_critique   to score the golden cells.");
  } else {
    console.log(
      `  ${allProvTally} lens${allProvTally === 1 ? "" : "es"} under the 20-judgment bar (provisional).`,
    );
    console.log(
      "  Run: npm run critic:label -- --bootstrap   to add more cells.",
    );
  }
}

// ── Add cell ──────────────────────────────────────────────────────────────────

function runAdd(cellId: string, lens: LensName | undefined): void {
  const held = heldOutIds();
  if (held.includes(cellId)) {
    console.error(
      `\n[critic label] ERROR: ${cellId} is in held_out_ids — Phase-196 true-north.`,
    );
    console.error("  Held-out cells cannot be labeled (T-195-23).");
    process.exit(1);
  }

  const allCells = committedCellIds();
  if (!allCells.includes(cellId)) {
    console.error(
      `\n[critic label] ERROR: ${cellId} not found in .planning/scorecards/.`,
    );
    console.error("  Only committed Tier-A scorecard cells can be enqueued.");
    process.exit(1);
  }

  ensureDirs();
  const queue = existsSync(queuePath)
    ? readJson<QueueFile>(queuePath)
    : { version: 1, created_at: new Date().toISOString(), items: [] as QueueItem[] };

  const lensesToAdd = lens ? [lens] : ALL_LENSES;
  let added = 0;

  for (const l of lensesToAdd) {
    const key = `${cellId}::${l}`;
    const exists = queue.items.some((i) => `${i.cell_id}::${i.lens}` === key);
    if (!exists) {
      queue.items.push({
        id: `q_${String(queue.items.length + 1).padStart(3, "0")}`,
        cell_id: cellId,
        lens: l,
        kind: "single",
        pair_with: null,
        queue_order: queue.items.length,
        source: "manual",
      });
      added++;
    }
  }

  writeJson(queuePath, queue);
  console.log(
    `[critic label] Added ${added} item${added === 1 ? "" : "s"} for ${cellId} to queue.`,
  );
}

// ── Revalidate ────────────────────────────────────────────────────────────────

function runRevalidate(lens: LensName): void {
  if (!existsSync(goldenSetPath)) {
    console.error(
      "\n[critic label] ERROR: No golden-set.json found. Run --bootstrap first.",
    );
    process.exit(1);
  }

  const gs = readJson<GoldenSetFile>(goldenSetPath);
  const cellsForLens = gs.items
    .filter((i) => i.lens === lens)
    .map((i) => i.cell_id);

  if (cellsForLens.length === 0) {
    console.log(
      `[critic label] No golden-set items found for lens: ${lens}.`,
    );
    return;
  }

  ensureDirs();
  const queue = existsSync(queuePath)
    ? readJson<QueueFile>(queuePath)
    : { version: 1, created_at: new Date().toISOString(), items: [] as QueueItem[] };

  let added = 0;
  for (const cellId of cellsForLens) {
    const key = `${cellId}::${lens}`;
    if (!queue.items.some((i) => `${i.cell_id}::${i.lens}` === key)) {
      queue.items.push({
        id: `q_${String(queue.items.length + 1).padStart(3, "0")}`,
        cell_id: cellId,
        lens,
        kind: "single",
        pair_with: null,
        queue_order: queue.items.length,
        source: "revalidate",
      });
      added++;
    }
  }

  writeJson(queuePath, queue);
  console.log(
    `[critic label] Re-queued ${added} item${added === 1 ? "" : "s"} for lens: ${lens}.`,
  );
  console.log(
    "  Run --round r1 then --round r2 then --reconcile to re-label.",
  );
}

// ── First-run empty state ──────────────────────────────────────────────────────

function printEmptyState(): void {
  const gs = existsSync(goldenSetPath)
    ? readJson<GoldenSetFile>(goldenSetPath)
    : null;

  const totalItems = gs?.items.length ?? 0;
  const lensCount: Partial<Record<LensName, number>> = {};
  if (gs) {
    for (const item of gs.items) {
      lensCount[item.lens] = (lensCount[item.lens] ?? 0) + 1;
    }
  }
  const lensesAtBar = ALL_LENSES.filter((l) => (lensCount[l] ?? 0) >= 20).length;

  console.log(
    `\n[critic label] No oracle yet. Guided path to build the golden set:\n`,
  );
  console.log(`  Progress: ${totalItems} cells  ·  ${lensesAtBar}/6 lenses at N≥20`);
  console.log("");
  console.log(
    "  Step 1: Seed the queue (6 pole anchors queued first for calibration):",
  );
  console.log("          npm run critic:label -- --bootstrap");
  console.log("");
  console.log("  Step 2: Label round 1 (keystroke-driven, ~20 min for the poles):");
  console.log("          npm run critic:label -- --round r1");
  console.log("          git add .planning/golden/rounds/r1.json && git commit");
  console.log("");
  console.log("  Step 3: Label round 2 (blind — different tokens, reshuffled order):");
  console.log("          npm run critic:label -- --round r2");
  console.log("");
  console.log(
    "  Step 4: Reconcile (keep r1==r2 agreements; you tiebreak disagreements):",
  );
  console.log("          npm run critic:label -- --reconcile");
  console.log("");
  console.log(
    "  Step 5: Check progress — are ≥20 cells per lens in the golden set?",
  );
  console.log("          npm run critic:label -- --status");
  console.log("");
  console.log(
    "  Step 6: Score + measure trust (requires ANTHROPIC_API_KEY):",
  );
  console.log("          mix verify.ui_critique");
}

// ── Main entry ────────────────────────────────────────────────────────────────

export async function runLabel(argv: string[]): Promise<void> {
  // Parse flags
  let bootstrap = false;
  let round: "r1" | "r2" | null = null;
  let reconcile = false;
  let status = false;
  let addCellId: string | null = null;
  let revalidate = false;
  let lens: LensName | undefined;
  let page: string | undefined;
  let pairs = false;
  let resume = false;
  let brief = false;

  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case "--bootstrap":
        bootstrap = true;
        break;
      case "--round": {
        const r = argv[++i];
        if (r !== "r1" && r !== "r2") {
          console.error(`Invalid round: ${r}. Use --round r1 or --round r2.`);
          process.exit(1);
        }
        round = r;
        break;
      }
      case "--reconcile":
        reconcile = true;
        break;
      case "--status":
        status = true;
        break;
      case "--add":
        addCellId = argv[++i];
        break;
      case "--revalidate":
        revalidate = true;
        break;
      case "--lens": {
        const lensArg = argv[++i] as LensName;
        if (!ALL_LENSES.includes(lensArg)) {
          console.error(`Unknown lens: ${lensArg}. Valid: ${ALL_LENSES.join(", ")}`);
          process.exit(1);
        }
        lens = lensArg;
        break;
      }
      case "--page":
        page = argv[++i];
        break;
      case "--pairs":
        pairs = true;
        break;
      case "--resume":
        resume = true;
        break;
      case "--brief":
        brief = true;
        break;
    }
  }

  // Dispatch
  if (bootstrap) {
    runBootstrap({ lens, page });
    return;
  }

  if (status) {
    runStatus();
    return;
  }

  if (addCellId) {
    runAdd(addCellId, lens);
    return;
  }

  if (revalidate) {
    if (!lens) {
      console.error("--revalidate requires --lens <lens>");
      process.exit(1);
    }
    runRevalidate(lens);
    return;
  }

  if (reconcile) {
    await runReconcile();
    return;
  }

  if (round) {
    await runRound(round, { lens, page, pairs, resume, brief });
    return;
  }

  // No flag → first-run empty state (D-09)
  printEmptyState();
}
