import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, lstatSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { atomicWriteFile, resolveContainedPath } from "./operator-surface-paths.js";
import { candidateIdentity } from "./operator-evidence-manifest.js";
import { CANDIDATE_RECEIPT_PATH, validate243CandidateReceipt, type Operator243CandidateReceipt } from "./operator-candidate-receipt.js";

const sha = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex");
const acceptedIndexPath = ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md";
const acceptedReceiptPath = ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json";
const acceptedTable = /\| (Eleven routes \+ degraded|Dark states|System\/light states) \| `([^`]+)` \| (\d+) \| `([a-f0-9]{64})` \| `([a-f0-9]{64})` \|/g;
const stylesheetParts = ["01_tokens.css", "02_base_shell.css", "03_page_home.css", "04_controls.css", "05_feedback.css", "06_layout_primitives.css", "07_find_detail.css", "08_overlays_motion.css", "09_responsive.css"];

interface EvidenceCapture {
  id: string; route: string; state: string; condition: string; outputPath: string; outputSha256: string;
  assets: { url: string; status: number; contentType: string; servedSha256: string; localPath: string; localSha256: string }[];
}

interface EvidenceManifest {
  schemaVersion: number; baseSha: string; candidateHead: string; candidateAncestry: string[];
  candidatePaths: string[]; candidateChanges: { path: string; mode: string; sha256: string }[]; candidateDiffDigest: string;
  custody: { receiptSha256: string; acceptedReceiptSha256: string; acceptedEvidenceIndexSha256: string; acceptedHead: string; forwardTaskCommits: string[] };
  fixture: { scenario: string; version: string; seedManifestSha256: string; semanticId: string };
  route: string; state: string; actor: { role: string; scope: string }; appearance: { effectiveTheme: string; preference: string };
  browser: { playwright: string; browser: string }; viewport: { width: number; height: number; deviceScaleFactor: number };
  input: { motion: string; zoom: number }; environment?: { os: string }; captures: EvidenceCapture[];
}

interface Bundle { readonly runRoot: string; readonly sourceRoot: string; readonly manifests: readonly EvidenceManifest[] }
interface AcceptedBundleRow { readonly lane: string; readonly path: string; readonly outputCount: number; readonly manifestSetSha256: string; readonly outputSetSha256: string }

function readJson(path: string): any {
  try { return JSON.parse(readFileSync(path, "utf8")); }
  catch { throw new Error(`Evidence manifest is missing or invalid JSON: ${path}`); }
}

function safeFile(root: string, path: string): string {
  const absolute = resolveContainedPath(root, path);
  const info = lstatSync(absolute);
  if (!info.isFile() || info.isSymbolicLink()) throw new Error(`Evidence path must be a regular, contained file: ${path}`);
  return absolute;
}

function fileHash(root: string, path: string): string { return sha(readFileSync(safeFile(root, path))); }

function localAssetHash(sourceRoot: string, localPath: string): string {
  const suffix = " (ordered segments)";
  if (localPath.endsWith(suffix)) {
    const directory = localPath.slice(0, -suffix.length).replace(/\/\*\.css$/, "");
    const bytes = stylesheetParts.map((name) => readFileSync(safeFile(sourceRoot, join(directory, name))));
    return sha(Buffer.concat(bytes));
  }
  return fileHash(sourceRoot, localPath);
}

function validateManifestBundle(bundle: Bundle, expected?: Operator243CandidateReceipt, expectedReceiptSha256?: string): Map<string, EvidenceCapture> {
  const captures = new Map<string, EvidenceCapture>();
  for (const manifest of bundle.manifests) {
    if (manifest.schemaVersion !== 1 || !Array.isArray(manifest.captures) || !manifest.captures.length) throw new Error("Evidence manifest has no valid captures");
    if (expected && (manifest.baseSha !== expected.baseSha || manifest.candidateHead !== expected.candidateHead || manifest.candidateDiffDigest !== expected.candidateDiffDigest || manifest.custody?.receiptSha256 === undefined)) {
      throw new Error("Fresh manifest source identity does not match the validated candidate receipt");
    }
    if (expected && manifest.custody.receiptSha256 !== expectedReceiptSha256) throw new Error("Fresh manifest receipt custody does not match the current candidate receipt");
    for (const capture of manifest.captures) {
      if (!capture.id || !capture.outputPath || !/^[a-f0-9]{64}$/.test(capture.outputSha256)) throw new Error("Capture output identity is incomplete");
      const output = safeFile(bundle.runRoot, capture.outputPath);
      if (sha(readFileSync(output)) !== capture.outputSha256) throw new Error(`Capture output hash mismatch: ${capture.id}`);
      if (capture.id.endsWith("-shell") && (!capture.outputPath.endsWith(".png") || !isPng(output))) throw new Error(`Full-shell capture is not a PNG image: ${capture.id}`);
      if (!Array.isArray(capture.assets) || !capture.assets.length) throw new Error(`Capture assets are missing: ${capture.id}`);
      const kinds = new Set<string>();
      for (const asset of capture.assets) {
        if (asset.status !== 200 || !/^[a-f0-9]{64}$/.test(asset.servedSha256) || !/^[a-f0-9]{64}$/.test(asset.localSha256)) throw new Error(`Invalid served-asset identity: ${capture.id}`);
        const localSha = localAssetHash(bundle.sourceRoot, asset.localPath);
        if (localSha !== asset.localSha256 || asset.servedSha256 !== asset.localSha256) throw new Error(`Served/local asset hash mismatch: ${asset.url}`);
        if (asset.contentType.includes("javascript")) kinds.add("javascript");
        if (asset.contentType.includes("css")) kinds.add("css");
      }
      if (!kinds.has("javascript") || !kinds.has("css")) throw new Error(`Capture lacks verified CSS and JavaScript: ${capture.id}`);
      captures.set(capture.id, capture);
    }
  }
  const shells = [...captures.values()].filter((capture) => capture.id.endsWith("-shell") && capture.outputPath.endsWith(".png"));
  const routeIds = new Set(shells.map((capture) => capture.id.replace(/__[^/]+-shell$/, "")));
  if (routeIds.size < 11) throw new Error(`Fresh evidence must contain full-shell PNGs for eleven routes; found ${routeIds.size}`);
  return captures;
}

function isPng(path: string): boolean {
  const bytes = readFileSync(path);
  return bytes.length >= 24 && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) && bytes.toString("ascii", 12, 16) === "IHDR" && bytes.readUInt32BE(16) > 0 && bytes.readUInt32BE(20) > 0;
}

function compareConditions(baseline: EvidenceManifest, candidate: EvidenceManifest, differences: Set<string>): void {
  const values: [string, unknown, unknown][] = [
    ["fixture.semanticId", baseline.fixture?.semanticId, candidate.fixture?.semanticId],
    ["actor.role", baseline.actor?.role, candidate.actor?.role], ["actor.scope", baseline.actor?.scope, candidate.actor?.scope],
    ["appearance.effectiveTheme", baseline.appearance?.effectiveTheme, candidate.appearance?.effectiveTheme],
    ["appearance.preference", baseline.appearance?.preference, candidate.appearance?.preference],
    ["browser.playwright", baseline.browser?.playwright, candidate.browser?.playwright],
    ["browser.browser", baseline.browser?.browser, candidate.browser?.browser],
    ["viewport", baseline.viewport, candidate.viewport], ["input.motion", baseline.input?.motion, candidate.input?.motion],
    ["environment.os", baseline.environment?.os ?? "not-recorded", candidate.environment?.os ?? "not-recorded"],
  ];
  for (const [name, before, after] of values) if (JSON.stringify(before) !== JSON.stringify(after)) differences.add(`${name}: ${JSON.stringify(before)} -> ${JSON.stringify(after)}`);
}

export function reviewEvidenceBundles(baselineBundles: readonly Bundle[], candidateBundle: Bundle) {
  if (!baselineBundles.length) throw new Error("Approved baseline bundles are required");
  const baselineCaptures = new Map<string, { manifest: EvidenceManifest; capture: EvidenceCapture }>();
  for (const bundle of baselineBundles) {
    const captures = validateManifestBundle(bundle);
    for (const manifest of bundle.manifests) for (const capture of manifest.captures) {
      if (!baselineCaptures.has(capture.id)) baselineCaptures.set(capture.id, { manifest, capture });
    }
    if (captures.size === 0) throw new Error("Approved baseline bundle has no capture outputs");
  }
  const candidateCaptures = validateManifestBundle(candidateBundle);
  const differences = new Set<string>();
  for (const candidate of candidateBundle.manifests) {
    const peer = baselineBundles.flatMap((bundle) => bundle.manifests).find((manifest) => manifest.route === candidate.route && manifest.state === candidate.state);
    if (!peer) differences.add(`manifest route/state ${candidate.route} (${candidate.state}): absent from Phase 238 baseline`);
    else compareConditions(peer, candidate, differences);
  }
  for (const capture of candidateCaptures.values()) {
    const baseline = baselineCaptures.get(capture.id);
    if (!baseline) differences.add(`capture ${capture.id}: absent from Phase 238 baseline`);
    else {
      if (capture.route !== baseline.capture.route || capture.state !== baseline.capture.state) differences.add(`capture ${capture.id}: route/state identity differs`);
      let oldCondition: Record<string, unknown> = {}, newCondition: Record<string, unknown> = {};
      try { oldCondition = JSON.parse(baseline.capture.condition); } catch { differences.add(`capture ${capture.id}: baseline render condition is not recorded JSON`); }
      try { newCondition = JSON.parse(capture.condition); } catch { differences.add(`capture ${capture.id}: candidate render condition is not recorded JSON`); }
      for (const key of ["project", "viewport", "motion", "browserZoom", "pattern", "seedResolution", "httpStatus"]) {
        if (JSON.stringify(oldCondition[key]) !== JSON.stringify(newCondition[key])) differences.add(`capture ${capture.id}.condition.${key}: ${JSON.stringify(oldCondition[key])} -> ${JSON.stringify(newCondition[key])}`);
      }
    }
  }
  return { comparison: differences.size ? "limited" as const : "matched" as const, differences: [...differences].sort(), shellCount: [...candidateCaptures.values()].filter((capture) => capture.id.endsWith("-shell") && capture.outputPath.endsWith(".png")).length };
}

function acceptedRows(index: string): AcceptedBundleRow[] {
  const section = index.split("## Historical evidence")[0];
  const rows: AcceptedBundleRow[] = [];
  for (const match of section.matchAll(acceptedTable)) rows.push({ lane: match[1], path: match[2], outputCount: Number(match[3]), manifestSetSha256: match[4], outputSetSha256: match[5] });
  if (rows.length !== 3) throw new Error("Approved Phase 238 index must name exactly three accepted evidence bundles");
  return rows;
}

function readBundle(runRoot: string, sourceRoot: string, includeAggregate = true): Bundle {
  const manifests: EvidenceManifest[] = [];
  const files = readdirSync(runRoot).filter((name) => name.endsWith("-manifest.json") || (includeAggregate && name === "manifest.json")).sort();
  if (!files.length) throw new Error(`No evidence manifests in ${runRoot}`);
  for (const name of files) manifests.push(readJson(safeFile(runRoot, name)) as EvidenceManifest);
  return { runRoot, sourceRoot, manifests };
}

function verifyIndexedBundle(sourceRoot: string, row: AcceptedBundleRow) {
  const runRoot = resolveContainedPath(sourceRoot, row.path);
  const bundle = readBundle(runRoot, sourceRoot);
  const manifestFiles = readdirSync(runRoot).filter((name) => name.endsWith("-manifest.json") || (row.lane === "Eleven routes + degraded" && name === "manifest.json")).sort();
  const manifestPairs = manifestFiles.map((name) => [name, fileHash(runRoot, name)] as const);
  if (sha(JSON.stringify(manifestPairs)) !== row.manifestSetSha256) throw new Error(`Accepted ${row.lane} manifest set changed from the Phase 238 index`);
  const outputs = new Map<string, string>();
  for (const manifest of bundle.manifests) for (const capture of manifest.captures ?? []) outputs.set(capture.outputPath, capture.outputSha256);
  const outputPairs = [...outputs].sort().map(([path, expected]) => {
    const actual = fileHash(runRoot, path);
    if (actual !== expected) throw new Error(`Accepted Phase 238 output bytes changed: ${row.path}/${path}`);
    return [path, actual] as const;
  });
  if (outputPairs.length !== row.outputCount || sha(JSON.stringify(outputPairs)) !== row.outputSetSha256) throw new Error(`Accepted ${row.lane} output set changed from the Phase 238 index`);
  return { bundle, pairs: [...manifestPairs.map(([path, hash]) => [`${row.path}/${path}`, hash] as const), ...outputPairs.map(([path, hash]) => [`${row.path}/${path}`, hash] as const)] };
}

export function acceptedBaselineByteDigest(root: string): string {
  const receipt = readJson(join(root, acceptedReceiptPath)) as { worktree?: string };
  if (!receipt.worktree) throw new Error("Phase 238 receipt has no retained baseline worktree");
  const sourceRoot = resolve(receipt.worktree);
  if (!existsSync(sourceRoot) || gitRoot(sourceRoot) !== sourceRoot) throw new Error("Retained Phase 238 evidence worktree is missing or invalid");
  const index = readFileSync(join(root, acceptedIndexPath), "utf8");
  const pairs: (readonly [string, string])[] = [[acceptedReceiptPath, sha(readFileSync(join(root, acceptedReceiptPath)))], [acceptedIndexPath, sha(index)]];
  for (const row of acceptedRows(index)) pairs.push(...verifyIndexedBundle(sourceRoot, row).pairs);
  return sha(JSON.stringify(pairs.sort()));
}

function gitRoot(root: string): string { return execFileSync("git", ["rev-parse", "--show-toplevel"], { cwd: root, encoding: "utf8" }).trim(); }

export function validateCandidateReview(root: string, candidateRunPath: string) {
  const receiptPath = resolveContainedPath(root, CANDIDATE_RECEIPT_PATH);
  const receiptBytes = readFileSync(receiptPath);
  const receipt = JSON.parse(receiptBytes.toString("utf8")) as Operator243CandidateReceipt;
  validate243CandidateReceipt(root, receipt, CANDIDATE_RECEIPT_PATH);
  const identity = candidateIdentity(root, receipt.baseSha);
  if (identity.candidateHead !== receipt.candidateHead || identity.candidateDiffDigest !== receipt.candidateDiffDigest) throw new Error("Fresh review candidate no longer matches its receipt");
  const runRoot = resolveContainedPath(join(root, "examples/threadline_phoenix/e2e/artifacts/operator-evidence"), candidateRunPath);
  if (!/^operator_243_routes_[A-Za-z0-9_-]+$/.test(relative(join(root, "examples/threadline_phoenix/e2e/artifacts/operator-evidence"), runRoot).split("/").at(-1) ?? "")) throw new Error("Review input must be one fresh Phase 243 route run");
  const acceptedReceipt = readJson(join(root, acceptedReceiptPath)) as { worktree: string };
  const baselineRoot = resolve(acceptedReceipt.worktree);
  const index = readFileSync(join(root, acceptedIndexPath), "utf8");
  const verified = acceptedRows(index).map((row) => verifyIndexedBundle(baselineRoot, row));
  const candidateBundle = readBundle(runRoot, root);
  const candidateCaptures = validateManifestBundle(candidateBundle, receipt, sha(receiptBytes));
  const baselineCaptures = verified.map((item) => item.bundle);
  const result = reviewEvidenceBundles(baselineCaptures, candidateBundle);
  const baselineDigest = acceptedBaselineByteDigest(root);
  const review = { schemaVersion: 1, candidateHead: receipt.candidateHead, candidateDiffDigest: receipt.candidateDiffDigest, receiptSha256: sha(receiptBytes), runPath: relative(root, runRoot), baselineByteDigest: baselineDigest, comparison: result.comparison, differences: result.differences, routeIds: [...new Set([...candidateCaptures.values()].filter((capture) => capture.id.endsWith("-shell")).map((capture) => capture.id.replace(/__[^/]+-shell$/, "")))].sort(), shellCount: result.shellCount };
  atomicWriteFile(join(runRoot, "candidate-review.json"), `${JSON.stringify(review, null, 2)}\n`);
  return review;
}

const moduleDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(moduleDirectory, "../../../..");
if (process.argv[2] === "--validate" || process.argv[2] === "--baseline-hash") {
  try {
    const result = process.argv[2] === "--baseline-hash" ? { baselineByteDigest: acceptedBaselineByteDigest(repositoryRoot) } : validateCandidateReview(repositoryRoot, process.argv[3] ?? "");
    process.stdout.write(`${JSON.stringify(result)}\n`);
  } catch (error) {
    process.stderr.write(`${String(error)}\n`);
    process.exitCode = 1;
  }
}
