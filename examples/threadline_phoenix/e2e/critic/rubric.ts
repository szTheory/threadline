/**
 * rubric.ts — Rubric lint and hash checker + version bumper (D-05/D-09, Plan 07).
 *
 * Invoked via `run.ts rubric` / `npm run critic:rubric`.
 *
 * Subcommands:
 *   lint                       Verify all rubrics: hash==disk, ≤3 dims, poles resolve
 *   bump <lens> [--patch|--minor|--major]  Bump semver, recompute sha8, print blast radius
 *
 * Rubric header format:
 *   <!-- lens: hierarchy | version: 1.0.0 | sha8: 00000000 -->
 *
 * sha8 computation (stable, normalized):
 *   sha8 = first 8 hex chars of sha256(content with sha8 value replaced by "00000000")
 *   This is a self-referential hash — normalization avoids the circular dependency.
 *   sha8 = "00000000" → uninitialized; lint warns but exits 0 (D-02 auto-invalidation).
 *
 * D-05 (per-lens semver + sha8) / D-09 (rubric lint + bump) / T-195-22
 */

import {
  existsSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { createHash } from "node:crypto";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const rubricDir = resolve(here, "rubrics");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const ledgerPath = resolve(repoRoot, ".planning/design-system-ledger.json");

const ALL_LENSES: LensName[] = [
  "hierarchy",
  "density",
  "rhythm",
  "typography",
  "color_contrast",
  "brand_fidelity",
];

// ── Types ─────────────────────────────────────────────────────────────────────

interface RubricHeader {
  lens: string;
  version: string; // semver: major.minor.patch
  sha8: string; // first 8 hex chars of sha256(normalized content)
}

interface LintResult {
  lens: LensName;
  path: string;
  header: RubricHeader | null;
  hashOk: boolean; // computed sha8 matches stored sha8 (or stored is "00000000")
  hashUninitialized: boolean; // stored sha8 is "00000000"
  dimCount: number;
  dimsOk: boolean; // ≤3 dimensions
  polesOk: boolean;
  missingPoles: string[];
  errors: string[];
  warnings: string[];
}

// ── sha8 computation ──────────────────────────────────────────────────────────

/**
 * Normalize rubric content for hashing: replace the sha8 value with "00000000".
 * This makes the hash stable regardless of the current stored sha8.
 */
function normalizeForHash(content: string): string {
  // Replace sha8 value in the header comment
  return content.replace(
    /(<!--\s*lens:\s*\S+\s*\|\s*version:\s*\S+\s*\|\s*sha8:\s*)([a-f0-9]+)(\s*-->)/,
    "$1" + "00000000" + "$3",
  );
}

/**
 * Compute sha8 for a rubric file: sha256(normalized content).substr(0, 8)
 */
function computeSha8(content: string): string {
  const normalized = normalizeForHash(content);
  return createHash("sha256").update(normalized, "utf8").digest("hex").substring(0, 8);
}

// ── Header parsing ────────────────────────────────────────────────────────────

/**
 * Parse the rubric header comment: <!-- lens: X | version: X | sha8: X -->
 */
function parseHeader(content: string): RubricHeader | null {
  const match = content.match(
    /<!--\s*lens:\s*(\S+)\s*\|\s*version:\s*(\S+)\s*\|\s*sha8:\s*([a-f0-9]+)\s*-->/,
  );
  if (!match) return null;
  return { lens: match[1], version: match[2], sha8: match[3] };
}

/**
 * Count the number of dimensions in a rubric (### N. headers).
 */
function countDimensions(content: string): number {
  const matches = content.match(/^###\s+\d+\./gm);
  return matches ? matches.length : 0;
}

/**
 * Extract pole cell IDs from the ## Anchors section.
 * Returns { pass, fail } or null if not found.
 */
function extractPoles(
  content: string,
): { pass: string; fail: string } | null {
  const passMatch = content.match(/\*\*Pass pole:\*\*\s+`([^`]+)`/);
  const failMatch = content.match(/\*\*Fail pole:\*\*\s+`([^`]+)`/);
  if (!passMatch || !failMatch) return null;
  return { pass: passMatch[1], fail: failMatch[1] };
}

// ── Lint ──────────────────────────────────────────────────────────────────────

/**
 * Lint a single rubric file.
 */
function lintRubric(lens: LensName): LintResult {
  const rubricPath = resolve(rubricDir, `${lens}.md`);
  const result: LintResult = {
    lens,
    path: rubricPath,
    header: null,
    hashOk: false,
    hashUninitialized: false,
    dimCount: 0,
    dimsOk: false,
    polesOk: false,
    missingPoles: [],
    errors: [],
    warnings: [],
  };

  if (!existsSync(rubricPath)) {
    result.errors.push(`Rubric file not found: ${rubricPath}`);
    return result;
  }

  const content = readFileSync(rubricPath, "utf8");
  const header = parseHeader(content);

  if (!header) {
    result.errors.push(
      `Missing or malformed header. Expected: <!-- lens: ${lens} | version: X.Y.Z | sha8: XXXXXXXX -->`,
    );
    return result;
  }

  result.header = header;

  // ── Hash check ────────────────────────────────────────────────────────────
  if (header.sha8 === "00000000") {
    result.hashUninitialized = true;
    result.hashOk = true; // uninitialized → not an error; warn only
    const computed = computeSha8(content);
    result.warnings.push(
      `sha8 is uninitialized (00000000). Computed sha8: ${computed}. ` +
        `Run: critic rubric bump ${lens} --patch   to stamp the correct hash.`,
    );
  } else {
    const computed = computeSha8(content);
    if (computed !== header.sha8) {
      result.hashOk = false;
      result.errors.push(
        `Hash mismatch for ${lens}: stored=${header.sha8}, computed=${computed}. ` +
          `The rubric file was modified without running 'critic rubric bump'.`,
      );
    } else {
      result.hashOk = true;
    }
  }

  // ── Dimension count ───────────────────────────────────────────────────────
  result.dimCount = countDimensions(content);
  if (result.dimCount > 3) {
    result.dimsOk = false;
    result.errors.push(
      `Too many dimensions: ${result.dimCount} (max 3 per D-05). ` +
        `Dimension bloat is rubric footgun #1 — keep lenses tight.`,
    );
  } else if (result.dimCount === 0) {
    result.dimsOk = false;
    result.errors.push(
      `No dimensions found. Expected ### N. headers in the ## Dimensions section.`,
    );
  } else {
    result.dimsOk = true;
  }

  // ── Poles resolve ─────────────────────────────────────────────────────────
  const poles = extractPoles(content);
  if (!poles) {
    result.polesOk = false;
    result.errors.push(
      `Missing ## Anchors section with **Pass pole** and **Fail pole** cell IDs.`,
    );
  } else {
    const missing: string[] = [];
    for (const [, cellId] of Object.entries(poles)) {
      if (!existsSync(resolve(scorecardsDir, `${cellId}.json`))) {
        missing.push(cellId);
      }
    }
    result.missingPoles = missing;
    if (missing.length > 0) {
      result.polesOk = false;
      result.errors.push(
        `Pole cell IDs not found in scorecards/: ${missing.join(", ")}`,
      );
    } else {
      result.polesOk = true;
    }
  }

  return result;
}

/**
 * Lint all committed rubric files. Returns true if all pass (no errors).
 */
function lintAllRubrics(): boolean {
  const rubricFiles = existsSync(rubricDir)
    ? readdirSync(rubricDir)
        .filter((f) => f.endsWith(".md"))
        .map((f) => f.replace(/\.md$/, "") as LensName)
        .filter((l) => ALL_LENSES.includes(l))
    : [];

  if (rubricFiles.length === 0) {
    console.error(
      "[critic rubric lint] No rubric files found in " + rubricDir,
    );
    return false;
  }

  let allOk = true;
  let warnCount = 0;

  console.log(`[critic rubric lint] Checking ${rubricFiles.length} rubric files...\n`);

  for (const lens of ALL_LENSES) {
    if (!rubricFiles.includes(lens)) {
      console.error(`  MISSING  ${lens}.md`);
      allOk = false;
      continue;
    }

    const result = lintRubric(lens);
    const status =
      result.errors.length === 0 ? (result.warnings.length === 0 ? "ok" : "warn") : "FAIL";

    const dimStr =
      result.dimCount > 0 ? `${result.dimCount} dim${result.dimCount === 1 ? "" : "s"}` : "?";
    const versionStr = result.header?.version ?? "?";
    const sha8Str = result.header?.sha8 ?? "?";

    const prefix = status === "ok" ? "  ok  " : status === "warn" ? "  warn " : "  FAIL ";

    console.log(
      `${prefix} ${lens.padEnd(16)} v${versionStr}  sha8=${sha8Str}  ${dimStr}  poles=${result.polesOk ? "ok" : "FAIL"}`,
    );

    for (const err of result.errors) {
      console.error(`         ERROR: ${err}`);
      allOk = false;
    }
    for (const warn of result.warnings) {
      console.warn(`         WARN:  ${warn}`);
      warnCount++;
    }
  }

  console.log("");
  if (allOk) {
    if (warnCount > 0) {
      console.log(
        `[critic rubric lint] All rubrics OK with ${warnCount} warning${warnCount === 1 ? "" : "s"}.`,
      );
      console.log(
        `  Run 'critic rubric bump <lens> --patch' to stamp sha8 on uninitialized rubrics.`,
      );
    } else {
      console.log(`[critic rubric lint] All rubrics OK.`);
    }
  } else {
    console.error(`[critic rubric lint] FAILED — fix errors above before proceeding.`);
  }

  return allOk;
}

// ── Bump ──────────────────────────────────────────────────────────────────────

/**
 * Bump the rubric version and recompute sha8.
 * Prints the invalidation blast radius before writing.
 */
function bumpRubric(
  lens: LensName,
  part: "patch" | "minor" | "major",
): void {
  const rubricPath = resolve(rubricDir, `${lens}.md`);
  if (!existsSync(rubricPath)) {
    console.error(
      `[critic rubric bump] Rubric file not found: ${rubricPath}`,
    );
    process.exit(1);
  }

  const content = readFileSync(rubricPath, "utf8");
  const header = parseHeader(content);

  if (!header) {
    console.error(
      `[critic rubric bump] Missing or malformed header in ${lens}.md`,
    );
    process.exit(1);
  }

  // ── Version bump ──────────────────────────────────────────────────────────
  const [major, minor, patch] = header.version
    .split(".")
    .map((n) => parseInt(n, 10));

  let newVersion: string;
  switch (part) {
    case "major":
      newVersion = `${major + 1}.0.0`;
      break;
    case "minor":
      newVersion = `${major}.${minor + 1}.0`;
      break;
    case "patch":
    default:
      newVersion = `${major}.${minor}.${patch + 1}`;
  }

  // ── Compute new sha8 ──────────────────────────────────────────────────────
  // Replace version in header, set sha8 to 00000000, then compute hash
  const updatedContent = content.replace(
    /<!--\s*lens:\s*(\S+)\s*\|\s*version:\s*\S+\s*\|\s*sha8:\s*[a-f0-9]+\s*-->/,
    `<!-- lens: ${lens} | version: ${newVersion} | sha8: 00000000 -->`,
  );
  const newSha8 = computeSha8(updatedContent);

  // Final content with correct sha8
  const finalContent = updatedContent.replace(
    /<!--\s*lens:\s*(\S+)\s*\|\s*version:\s*\S+\s*\|\s*sha8:\s*00000000\s*-->/,
    `<!-- lens: ${lens} | version: ${newVersion} | sha8: ${newSha8} -->`,
  );

  // ── Blast radius ──────────────────────────────────────────────────────────
  const oldVersionStr = `${lens}@${header.version}+${header.sha8}`;
  const newVersionStr = `${lens}@${newVersion}+${newSha8}`;

  console.log(
    `[critic rubric bump] ${lens}: ${header.version}+${header.sha8} → ${newVersion}+${newSha8}`,
  );

  // Read critic_trust block from ledger to compute blast radius
  let trustN = 0;
  let trustValidated = false;
  if (existsSync(ledgerPath)) {
    try {
      const ledger = JSON.parse(readFileSync(ledgerPath, "utf8")) as {
        critic_trust?: Record<
          string,
          { n?: number; validated?: boolean; golden_rubric_version?: string }
        >;
      };
      const trust = ledger.critic_trust?.[lens];
      if (trust) {
        trustN = trust.n ?? 0;
        trustValidated = trust.validated ?? false;
      }
    } catch {
      // ignore ledger parse errors
    }
  }

  console.log("\n  Invalidation blast radius:");
  console.log(`    critic_trust.${lens}:`);
  if (trustValidated) {
    console.log(`      validated: true → will be set false (rubric changed)`);
  } else {
    console.log(`      validated: false (no change needed)`);
  }
  if (trustN > 0) {
    console.log(
      `      ${trustN} golden-set judgment${trustN === 1 ? "" : "s"} need re-scoring.`,
    );
    console.log(
      `      Scorer stamp: '${oldVersionStr}' → '${newVersionStr}'`,
    );
  } else {
    console.log(`      0 judgments to re-score (golden set empty for this lens).`);
  }
  console.log(`    Prompt cache:`);
  console.log(
    `      The cached prefix key includes the sha8. After this bump, the first`,
  );
  console.log(
    `      call per lens will MISS the cache (1.25× write cost) then re-hit.`,
  );

  if (part === "major") {
    console.log(
      `\n  MAJOR bump: redefines the lens scope. All prior judgments for ${lens}`,
    );
    console.log(
      `  are invalidated — the rubric now expresses a different question.`,
    );
    console.log(
      `  Consider re-running --bootstrap --lens ${lens} to rebuild the golden set.`,
    );
  } else if (part === "minor") {
    console.log(`\n  MINOR bump: adds a new dimension. Existing judgments remain valid`);
    console.log(`  but the new dimension has no golden-set coverage yet.`);
  } else {
    console.log(
      `\n  PATCH bump: wording refinement. Existing judgments likely still valid.`,
    );
  }

  // ── Write updated rubric ──────────────────────────────────────────────────
  writeFileSync(rubricPath, finalContent, "utf8");

  console.log(`\n  Written: ${rubricPath}`);
  console.log(`  Commit: git add ${rubricPath} && git commit -m 'chore: bump rubric ${newVersionStr}'`);
  console.log(
    `  Verify: npm run critic:rubric -- lint   (should show ${lens} as ok)`,
  );
}

// ── Main entry ────────────────────────────────────────────────────────────────

export async function runRubric(argv: string[]): Promise<void> {
  const [subcommand, ...rest] = argv;

  switch (subcommand) {
    case "lint": {
      const ok = lintAllRubrics();
      if (!ok) process.exit(1);
      break;
    }

    case "bump": {
      const lens = rest[0] as LensName;
      if (!lens || !ALL_LENSES.includes(lens)) {
        console.error(
          `Usage: critic rubric bump <lens> [--patch|--minor|--major]`,
        );
        console.error(`  Valid lenses: ${ALL_LENSES.join(", ")}`);
        process.exit(1);
      }

      let part: "patch" | "minor" | "major" = "patch";
      for (const arg of rest.slice(1)) {
        if (arg === "--patch") part = "patch";
        else if (arg === "--minor") part = "minor";
        else if (arg === "--major") part = "major";
      }

      bumpRubric(lens, part);
      break;
    }

    default:
      if (!subcommand) {
        console.error(`Usage: critic rubric <subcommand>`);
        console.error(`  lint                   Verify all rubrics`);
        console.error(`  bump <lens> [--patch|--minor|--major]  Bump version + sha8`);
      } else {
        console.error(`Unknown rubric subcommand: ${subcommand}`);
        console.error(`  Valid: lint, bump`);
      }
      process.exit(1);
  }
}
