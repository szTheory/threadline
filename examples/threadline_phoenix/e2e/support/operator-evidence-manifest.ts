import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  readFileSync,
  readdirSync,
  statSync,
} from "node:fs";
import { join, relative, resolve } from "node:path";
import { atomicWriteFile, assertSeparatedOutputRoot, DEFAULT_OPERATOR_SURFACE_PATHS, resolveContainedPath } from "./operator-surface-paths.js";

export interface ServedAsset {
  readonly url: string;
  readonly status: number;
  readonly contentType: string;
  readonly servedSha256: string;
  readonly localPath: string;
  readonly localSha256: string;
}

export interface OperatorCapture {
  readonly id: string;
  readonly route: string;
  readonly state: string;
  readonly condition: string;
  readonly outputPath: string;
  readonly outputSha256: string;
  readonly assets: readonly ServedAsset[];
}

export interface OperatorEvidenceManifest {
  readonly schemaVersion: 1;
  readonly baseSha: string;
  readonly candidateHead: string;
  readonly candidateAncestry: readonly string[];
  readonly candidatePaths: readonly string[];
  readonly candidateChanges: readonly { readonly path: string; readonly mode: string; readonly sha256: string }[];
  readonly candidateDiffDigest: string;
  readonly custody: {
    readonly receiptSha256: string;
    readonly acceptedReceiptSha256: string;
    readonly acceptedEvidenceIndexSha256: string;
    readonly acceptedHead: string;
    readonly forwardTaskCommits: readonly string[];
  };
  readonly fixture: {
    readonly scenario: string;
    readonly version: string;
    readonly seedManifestSha256: string;
    readonly semanticId: string;
  };
  readonly route: string;
  readonly state: string;
  readonly actor: { readonly role: string; readonly scope: string };
  readonly appearance: { readonly effectiveTheme: string; readonly preference: string };
  readonly browser: { readonly playwright: string; readonly browser: string };
  readonly viewport: { readonly width: number; readonly height: number; readonly deviceScaleFactor: number };
  readonly input: { readonly motion: string; readonly zoom: number };
  readonly environment?: { readonly os: string };
  readonly captures: readonly OperatorCapture[];
}

export interface Operator239CandidateReceipt {
  readonly schemaVersion: 1;
  readonly phase: 239;
  readonly worktree: string;
  readonly branch: string;
  readonly baseSha: string;
  readonly acceptedHead: string;
  readonly acceptedReceiptSha256: string;
  readonly acceptedEvidenceIndexSha256: string;
  readonly acceptedEvidenceManifestSets: readonly string[];
  readonly forwardTaskCommits: readonly string[];
  readonly candidateHead: string;
  readonly candidateAncestry: readonly string[];
  readonly candidatePaths: readonly string[];
  readonly candidateChanges: readonly { readonly path: string; readonly mode: string; readonly sha256: string }[];
  readonly candidateDiffDigest: string;
  readonly planningContextSha256: Readonly<Record<string, string>>;
}

const sha256 = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex");
const secretKey = /password|cookie|authorization|token|secret|credential|api[_-]?key/i;
const captureMetadataFields: Readonly<Record<string, "string" | "number" | "boolean" | "nullable-string">> = {
  pattern: "string", seedResolution: "string", httpStatus: "number", injectedRankingStyles: "boolean",
  reducedDuration: "string", clipboardMatches: "boolean", handlerBound: "boolean", copiedFeedback: "boolean",
  exactMatch: "boolean", rank: "string", ownerPhase: "number", deniedClipboardLimitation: "string",
  permission: "string", limitation: "string", stateSource: "string", requestHeld: "boolean",
  longValueLength: "number", priorDataRetained: "number", fullValueRetained: "boolean", input: "string",
  disabled: "boolean", ariaDisabled: "nullable-string", mutationMarker: "boolean", pointerEvents: "string",
  jobsBefore: "number", jobsAfter: "number", observedAddedJobs: "number", completionClaim: "boolean",
  focusedInside: "boolean", returned: "boolean", physicalDevice: "boolean", role: "string",
  scopeDecision: "string", timelineAllowed: "boolean", unauthenticatedTimelineStatus: "number",
  notPending: "boolean",
};

export type CaptureMetadataValue = string | number | boolean | null;

export function validateCaptureMetadata(
  value: unknown,
  canary: string,
  source: string,
): asserts value is Record<string, CaptureMetadataValue> {
  if (!value || typeof value !== "object" || Array.isArray(value) || (Object.getPrototypeOf(value) !== Object.prototype && Object.getPrototypeOf(value) !== null)) {
    throw new Error("Capture metadata must be a plain object");
  }

  for (const [key, fieldValue] of Object.entries(value)) {
    if (secretKey.test(key)) throw new Error(`Secret-bearing capture metadata field is not allowed: ${key}`);
    const expectedType = captureMetadataFields[key];
    if (!expectedType) throw new Error(`Unknown capture metadata field: ${key}`);
    const validType = expectedType === "nullable-string"
      ? fieldValue === null || typeof fieldValue === "string"
      : typeof fieldValue === expectedType;
    if (!validType || (typeof fieldValue === "number" && !Number.isFinite(fieldValue))) {
      throw new Error(`Invalid capture metadata value for ${key}`);
    }
    if (typeof fieldValue === "string" && (fieldValue.length > 500 || /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/.test(fieldValue))) {
      throw new Error(`Capture metadata string is not a bounded plain value: ${key}`);
    }
  }

  assertNoCanaryLeak(canary, source, JSON.stringify(value));
}

function rejectSecrets(value: unknown, path = "metadata"): void {
  if (Array.isArray(value)) return value.forEach((item, index) => rejectSecrets(item, `${path}[${index}]`));
  if (!value || typeof value !== "object") return;
  for (const [key, child] of Object.entries(value)) {
    if (secretKey.test(key)) throw new Error(`Secret-bearing field is not allowed: ${path}.${key}`);
    rejectSecrets(child, `${path}.${key}`);
  }
}

export function assertNoCanaryLeak(canary: string, source: string, payload: string | Uint8Array): void {
  if (!canary) throw new Error("Evidence canary must not be empty");
  const bytes = typeof payload === "string" ? Buffer.from(payload, "utf8") : Buffer.from(payload);
  if (bytes.includes(Buffer.from(canary, "utf8"))) {
    throw new Error(`Synthetic redaction canary found in evidence output: ${source}`);
  }
}

export function semanticFixtureId(scenario: string, version: string, seedManifestSha256: string): string {
  if (!scenario.trim() || !version.trim() || !/^[a-f0-9]{64}$/.test(seedManifestSha256)) {
    throw new Error("Fixture scenario, version, and SHA-256 seed manifest identity are required");
  }
  return sha256(`${scenario}\0${version}\0${seedManifestSha256}`);
}

export function seededFixtureIdentity(root: string) {
  const seedRoot = "examples/threadline_phoenix/lib/threadline_phoenix/demo";
  const seedFiles = ["seed.ex", "manifest.ex", ...readdirSync(join(root, seedRoot, "seed"), { recursive: true }).map((file) => `seed/${String(file)}`)].sort();
  const hash = createHash("sha256");
  for (const path of seedFiles) {
    const absolute = resolveContainedPath(root, join(seedRoot, path));
    if (!lstatSync(absolute).isFile()) throw new Error(`Fixture source must be a regular file: ${path}`);
    hash.update(path).update("\0").update(readFileSync(absolute));
  }
  const configPath = "examples/threadline_phoenix/config/test.exs";
  const configFile = resolveContainedPath(root, configPath);
  if (!lstatSync(configFile).isFile()) throw new Error("Fixture test configuration must be a regular file");
  const seedManifestSha256 = hash.update(configPath).update("\0").update(readFileSync(configFile)).digest("hex");
  const scenario = "threadline-demo-seed";
  const version = "seed-pipeline-v1";
  return { scenario, version, seedManifestSha256, semanticId: semanticFixtureId(scenario, version, seedManifestSha256) };
}

function relevant(path: string): boolean {
  if (/^examples\/threadline_phoenix\/e2e\/(?:artifacts\/|node_modules\/|playwright-report\/|test-results\/|\.cache\/)/.test(path)) return false;
  return /^(?:\.github\/workflows\/ci\.yml|bin\/(?:verify-example-browser(?:\.sh)?|e2e-preflight(?:\.sh)?)|test\/(?:partition_weights\.txt|fixtures\/operator_surface\/route-inventory\.json|threadline\/(?:[^/]*(?:browser|e2e|evidence|ci_workflow)[^/]*_test\.exs|support\/[^/]+\.exs))|lib\/threadline\/|examples\/threadline_phoenix\/(?:e2e\/|lib\/|assets\/|priv\/static\/|config\/|mix\.(?:exs|lock)$)|mix\.(?:exs|lock)|\.tool-versions)/.test(path);
}

export function candidateIdentity(root: string, baseSha: string) {
  const git = (args: string[]) => execFileSync("git", args, { cwd: root, encoding: "utf8" }).trim();
  const candidateHead = git(["rev-parse", "HEAD"]);
  try {
    execFileSync("git", ["merge-base", "--is-ancestor", baseSha, "HEAD"], { cwd: root, stdio: "ignore" });
  } catch {
    throw new Error(`Candidate HEAD ${candidateHead} is not descended from immutable base ${baseSha}`);
  }
  const committed = git(["diff", "--name-only", "-z", baseSha, "HEAD"]).split("\0");
  const staged = git(["diff", "--cached", "--name-only", "-z"]).split("\0");
  const unstaged = git(["diff", "--name-only", "-z"]).split("\0");
  const untracked = git(["ls-files", "--others", "--exclude-standard", "-z"]).split("\0");
  const paths = [...new Set([...committed, ...staged, ...unstaged, ...untracked].filter((path) => path && relevant(path)))].sort();
  const entries = paths.map((path) => {
    const absolute = resolveContainedPath(root, path);
    if (!existsSync(absolute)) return { path, mode: "deleted", sha256: "deleted" };
    const stat = statSync(absolute);
    const mode = stat.mode & 0o111 ? "100755" : "100644";
    return { path, mode, sha256: sha256(readFileSync(absolute)) };
  });
  const ancestry = git(["rev-list", "--first-parent", "--reverse", `${baseSha}..HEAD`]).split("\n").filter(Boolean);
  return { baseSha, candidateHead, candidateAncestry: ancestry, candidatePaths: paths, candidateChanges: entries, candidateDiffDigest: sha256(JSON.stringify(entries)) };
}

const receiptPath = ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json";
const evidenceIndexPath = ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md";
const contextPaths = [
  ".planning/phases/239-investigation-entry-and-transaction-composition/239-07-PLAN.md",
  ".planning/phases/239-investigation-entry-and-transaction-composition/239-CONTEXT.md",
  ".planning/phases/239-investigation-entry-and-transaction-composition/239-UI-SPEC.md",
  ".planning/phases/239-investigation-entry-and-transaction-composition/239-RESEARCH.md",
  ".planning/phases/239-investigation-entry-and-transaction-composition/239-PATTERNS.md",
  ".planning/phases/239-investigation-entry-and-transaction-composition/239-VALIDATION.md",
];

function firstParent(root: string, range: string): string[] {
  const output = execFileSync("git", ["rev-list", "--first-parent", "--reverse", range], { cwd: root, encoding: "utf8" }).trim();
  return output ? output.split("\n") : [];
}

function verifiedTaskCommits(root: string, acceptedHead: string): string[] {
  return firstParent(root, `${acceptedHead}..HEAD`).filter((commit) => {
    const subject = execFileSync("git", ["show", "-s", "--format=%s", commit], { cwd: root, encoding: "utf8" }).trim();
    return /^(?:test|feat|fix|refactor|perf|chore)\(239-\d{2}\):/.test(subject);
  });
}

export function build239CandidateReceipt(root: string, explicitTaskCommits: readonly string[], enforceApprovedBaseline = true): Operator239CandidateReceipt {
  const parentBytes = readFileSync(join(root, receiptPath));
  const parent = JSON.parse(parentBytes.toString("utf8")) as { base_sha: string; candidate_head: string; worktree: string; branch: string };
  const evidenceBytes = readFileSync(join(root, evidenceIndexPath));
  const evidenceIndex = evidenceBytes.toString("utf8");
  const acceptedEvidence = evidenceIndex.split("## Historical evidence")[0];
  const manifestSets = [...acceptedEvidence.matchAll(/\| (?:Eleven routes \+ degraded|Dark states|System\/light states) \|[^|]*\| [0-9]+ \| `([a-f0-9]{64})` \|/g)].map((match) => match[1]);
  if (manifestSets.length !== 3 || !parent.candidate_head || !parent.base_sha || (enforceApprovedBaseline && (parent.candidate_head !== "43c5bcfa960b1a10cb07ef997e2231e9615dca6f" || parent.base_sha !== "9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2"))) throw new Error("Accepted Phase 238 custody is incomplete or not the approved baseline");
  const expected = verifiedTaskCommits(root, parent.candidate_head);
  if (JSON.stringify(expected) !== JSON.stringify(explicitTaskCommits)) throw new Error("Explicit Phase 239 task commits disagree with first-parent task history");
  const candidate = candidateIdentity(root, parent.base_sha);
  const planningContextSha256 = Object.fromEntries(contextPaths.map((path) => [path, sha256(readFileSync(join(root, path)))]));
  return {
    schemaVersion: 1, phase: 239, worktree: execFileSync("git", ["rev-parse", "--show-toplevel"], { cwd: root, encoding: "utf8" }).trim(),
    branch: execFileSync("git", ["branch", "--show-current"], { cwd: root, encoding: "utf8" }).trim(), baseSha: parent.base_sha,
    acceptedHead: parent.candidate_head, acceptedReceiptSha256: sha256(parentBytes), acceptedEvidenceIndexSha256: sha256(evidenceBytes),
    acceptedEvidenceManifestSets: manifestSets, forwardTaskCommits: [...explicitTaskCommits], ...candidate, planningContextSha256,
  };
}

export function validate239CandidateReceipt(root: string, receipt: Operator239CandidateReceipt, expectedPath?: string, enforceApprovedBaseline = true): void {
  const keys = ["schemaVersion", "phase", "worktree", "branch", "baseSha", "acceptedHead", "acceptedReceiptSha256", "acceptedEvidenceIndexSha256", "acceptedEvidenceManifestSets", "forwardTaskCommits", "candidateHead", "candidateAncestry", "candidatePaths", "candidateChanges", "candidateDiffDigest", "planningContextSha256"];
  fields(receipt, keys, "239 candidate receipt");
  const rebuilt = build239CandidateReceipt(root, receipt.forwardTaskCommits, enforceApprovedBaseline);
  if (expectedPath) {
    const actualPath = resolve(root, expectedPath);
    if (!actualPath.startsWith(resolve(root, ".planning/phases/239-investigation-entry-and-transaction-composition/") + "/")) throw new Error("Candidate receipt path escapes the Phase 239 evidence directory");
  }
  if (JSON.stringify(receipt) !== JSON.stringify(rebuilt)) throw new Error("239 candidate receipt identity, accepted evidence, planning context or changed-path digest is stale or forged");
}

export function refresh239CandidateReceipt(root: string, path: string, explicitTaskCommits: readonly string[]): Operator239CandidateReceipt {
  const receipt = build239CandidateReceipt(root, explicitTaskCommits);
  const output = resolve(root, path);
  if (!output.startsWith(resolve(root, ".planning/phases/239-investigation-entry-and-transaction-composition/") + "/")) throw new Error("Candidate receipt path escapes the Phase 239 evidence directory");
  atomicWriteFile(output, `${JSON.stringify(receipt, null, 2)}\n`);
  return receipt;
}

if (process.argv[2] === "--refresh-239-receipt") {
  const root = process.cwd();
  const parent = JSON.parse(readFileSync(join(root, receiptPath), "utf8")) as { candidate_head: string };
  const commits = verifiedTaskCommits(root, parent.candidate_head);
  const receipt = refresh239CandidateReceipt(root, process.argv[3] ?? ".planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json", commits);
  process.stdout.write(JSON.stringify({ candidateHead: receipt.candidateHead, taskCommitCount: commits.length, receiptSha256: sha256(readFileSync(join(root, process.argv[3] ?? ".planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json"))) }) + "\n");
} else if (process.argv[2] === "--validate-239-receipt") {
  const path = process.argv[3] ?? ".planning/phases/239-investigation-entry-and-transaction-composition/239-CANDIDATE-RECEIPT.json";
  const receipt = JSON.parse(readFileSync(join(process.cwd(), path), "utf8")) as Operator239CandidateReceipt;
  validate239CandidateReceipt(process.cwd(), receipt, path);
  process.stdout.write("239 forward receipt verified\n");
}

function fields(value: object, keys: readonly string[], name: string): void {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`Missing ${name} metadata`);
  for (const key of Object.keys(value)) {
    if (!keys.includes(key)) throw new Error(`Unknown metadata field: ${name}.${key}`);
  }
  for (const key of keys) {
    if (!Object.hasOwn(value, key)) throw new Error(`Missing metadata field: ${name}.${key}`);
  }
}

const nonempty = (value: unknown): value is string => typeof value === "string" && value.trim().length > 0;
const digest = (value: unknown): value is string => typeof value === "string" && /^[a-f0-9]{64}$/.test(value);
const compare = (a: string, b: string) => a < b ? -1 : a > b ? 1 : 0;

export function validateServedAsset(asset: ServedAsset): void {
  fields(asset, ["url", "status", "contentType", "servedSha256", "localPath", "localSha256"], "asset");
  if (!nonempty(asset.url) || asset.status !== 200 || !nonempty(asset.contentType) || !nonempty(asset.localPath)) {
    throw new Error("Served asset URL, successful status, type, and local source mapping are required");
  }
  if (!/^(?:text|application)\/(?:css|javascript)(?:;|$)/.test(asset.contentType)) throw new Error(`Invalid served asset content type: ${asset.url}`);
  const url = new URL(asset.url);
  if (url.username || url.password || url.search || (url.protocol !== "inline:" && (url.protocol !== "http:" || !["127.0.0.1", "localhost", "[::1]"].includes(url.hostname)))) throw new Error("Asset URL must be local and contain no credential metadata");
  if (!/^[a-f0-9]{64}$/.test(asset.servedSha256) || !/^[a-f0-9]{64}$/.test(asset.localSha256)) {
    throw new Error(`Asset hashes are missing or invalid for ${asset.url}`);
  }
  if (asset.servedSha256 !== asset.localSha256) throw new Error(`Served asset bytes disagree with local source: ${asset.url}`);
}

export function serializeManifest(manifest: OperatorEvidenceManifest): string {
  rejectSecrets(manifest);
  const manifestFields = ["schemaVersion", "baseSha", "candidateHead", "candidateAncestry", "candidatePaths", "candidateChanges", "candidateDiffDigest", "custody", "fixture", "route", "state", "actor", "appearance", "browser", "viewport", "input", "captures"];
  if (manifest.environment !== undefined) manifestFields.push("environment");
  fields(manifest, manifestFields, "source");
  if (manifest.schemaVersion !== 1 || !/^[a-f0-9]{40}$/.test(manifest.baseSha) || !/^[a-f0-9]{40}$/.test(manifest.candidateHead)) {
    throw new Error("Manifest source identity is incomplete");
  }
  if (!digest(manifest.candidateDiffDigest) || !Array.isArray(manifest.candidateAncestry) || manifest.candidateAncestry.some((sha) => !/^[a-f0-9]{40}$/.test(sha))) throw new Error("Manifest source digest or ancestry is incomplete");
  if (!Array.isArray(manifest.candidatePaths) || !Array.isArray(manifest.candidateChanges) || manifest.candidatePaths.length !== manifest.candidateChanges.length) throw new Error("Manifest source path identity is incomplete");
  for (const [index, change] of manifest.candidateChanges.entries()) {
    fields(change, ["path", "mode", "sha256"], "source change");
    if (change.path !== manifest.candidatePaths[index] || !relevant(change.path) || change.path.split(/[\\/]/).includes("..") || (index > 0 && compare(manifest.candidatePaths[index - 1], change.path) >= 0)) throw new Error("Manifest source paths must be unique, contained and ordered");
    if (change.mode === "deleted" ? change.sha256 !== "deleted" : !["100644", "100755"].includes(change.mode) || !digest(change.sha256)) throw new Error("Manifest source change identity is invalid");
  }
  if (sha256(JSON.stringify(manifest.candidateChanges)) !== manifest.candidateDiffDigest) throw new Error("Manifest source changes disagree with candidate digest");
  fields(manifest.custody, ["receiptSha256", "acceptedReceiptSha256", "acceptedEvidenceIndexSha256", "acceptedHead", "forwardTaskCommits"], "custody");
  if (![manifest.custody.receiptSha256, manifest.custody.acceptedReceiptSha256, manifest.custody.acceptedEvidenceIndexSha256].every(digest) || !/^[a-f0-9]{40}$/.test(manifest.custody.acceptedHead) || !Array.isArray(manifest.custody.forwardTaskCommits) || !manifest.custody.forwardTaskCommits.length || manifest.custody.forwardTaskCommits.some((sha) => !/^[a-f0-9]{40}$/.test(sha))) throw new Error("Manifest forward custody identity is incomplete");
  const acceptedIndex = manifest.candidateAncestry.indexOf(manifest.custody.acceptedHead);
  let previousCommitIndex = acceptedIndex;
  if (acceptedIndex < 0) throw new Error("Manifest accepted 238 HEAD is absent from candidate ancestry");
  for (const commit of manifest.custody.forwardTaskCommits) {
    const commitIndex = manifest.candidateAncestry.indexOf(commit);
    if (commitIndex <= previousCommitIndex) throw new Error("Manifest forward custody commit is absent, duplicated or out of ancestry order");
    previousCommitIndex = commitIndex;
  }
  fields(manifest.fixture, ["scenario", "version", "seedManifestSha256", "semanticId"], "fixture");
  if (manifest.fixture.semanticId !== semanticFixtureId(manifest.fixture.scenario, manifest.fixture.version, manifest.fixture.seedManifestSha256)) throw new Error("Manifest fixture semantic identity disagrees with seed identity");
  for (const [value, keys, name] of [
    [manifest.actor, ["role", "scope"], "actor"],
    [manifest.appearance, ["effectiveTheme", "preference"], "appearance"],
    [manifest.browser, ["playwright", "browser"], "browser"],
  ] as const) {
    fields(value, keys, name);
    if (Object.values(value).some((v) => !nonempty(v))) throw new Error(`Missing ${name} identity`);
  }
  fields(manifest.viewport, ["width", "height", "deviceScaleFactor"], "viewport");
  if (Object.values(manifest.viewport).some((v) => typeof v !== "number" || !Number.isFinite(v) || v <= 0)) throw new Error("Invalid viewport condition");
  fields(manifest.input, ["motion", "zoom"], "input");
  if (!nonempty(manifest.input.motion) || !Number.isFinite(manifest.input.zoom) || manifest.input.zoom <= 0) throw new Error("Invalid input condition");
  if (manifest.environment !== undefined) {
    fields(manifest.environment, ["os"], "environment");
    if (!nonempty(manifest.environment.os)) throw new Error("Invalid operating system identity");
  }
  if (!nonempty(manifest.route) || !manifest.route.startsWith("/") || !nonempty(manifest.state) || !Array.isArray(manifest.captures) || !manifest.captures.length) {
    throw new Error("Manifest source, fixture, route, state, and capture identity are required");
  }
  const ids = new Set<string>();
  for (const capture of manifest.captures) {
    fields(capture, ["id", "route", "state", "condition", "outputPath", "outputSha256", "assets"], "capture");
    if (!nonempty(capture.id) || ids.has(capture.id)) throw new Error(`Missing or duplicate capture ID: ${capture.id || "<empty>"}`);
    ids.add(capture.id);
    if (!nonempty(capture.route) || !capture.route.startsWith("/") || !nonempty(capture.state) || !nonempty(capture.condition)) throw new Error(`Capture route, state and condition are required: ${capture.id}`);
    if (!nonempty(capture.outputPath) || !digest(capture.outputSha256)) throw new Error(`Capture output hash is required: ${capture.id}`);
    if (!Array.isArray(capture.assets) || !capture.assets.length) throw new Error(`Capture assets are required: ${capture.id}`);
    capture.assets.forEach(validateServedAsset);
    if (!capture.assets.some((a: ServedAsset) => a.contentType.includes("javascript")) || !capture.assets.some((a: ServedAsset) => a.contentType.includes("text/css"))) throw new Error(`Capture requires both CSS and JavaScript assets: ${capture.id}`);
  }
  const captures = manifest.captures.map((capture) => ({ ...capture, assets: [...capture.assets].sort((a, b) => compare(a.url, b.url)) })).sort((a, b) => compare(a.route, b.route) || compare(a.state, b.state) || compare(a.condition, b.condition) || compare(a.id, b.id));
  return `${JSON.stringify({ ...manifest, captures }, null, 2)}\n`;
}

export function writeManifest(root: string, path: string, manifest: OperatorEvidenceManifest): void {
  assertSeparatedOutputRoot(root, [DEFAULT_OPERATOR_SURFACE_PATHS.fixtureRoot]);
  const output = resolveContainedPath(root, path);
  serializeManifest(manifest);
  const captures = manifest.captures.map((capture) => {
    const artifact = resolveContainedPath(root, capture.outputPath);
    if (sha256(readFileSync(artifact)) !== capture.outputSha256) throw new Error(`Capture output hash disagrees with file bytes: ${capture.id}`);
    return { ...capture, outputPath: relative(root, artifact) };
  });
  atomicWriteFile(output, serializeManifest({ ...manifest, captures }));
}

export function localAssetPath(root: string, responseUrl: string): string {
  const pathname = decodeURIComponent(new URL(responseUrl).pathname);
  if (!pathname.startsWith("/assets/")) throw new Error(`No local built asset maps to browser response ${responseUrl}`);
  const found = resolveContainedPath(join(root, "examples/threadline_phoenix/priv/static"), pathname.slice(1));
  if (!existsSync(found) || !statSync(found).isFile()) throw new Error(`No local built asset maps to browser response ${responseUrl}`);
  return found;
}

export function assetRecord(root: string, url: string, status: number, contentType: string, body: Uint8Array): ServedAsset {
  const localPath = localAssetPath(root, url);
  const record = { url, status, contentType, servedSha256: sha256(body), localPath: relative(root, localPath), localSha256: sha256(readFileSync(localPath)) };
  validateServedAsset(record);
  return record;
}

export function outputRecord(id: string, route: string, state: string, condition: string, outputPath: string): OperatorCapture {
  return { id, route, state, condition, outputPath, outputSha256: sha256(readFileSync(outputPath)), assets: [] };
}

// Aggregate only tests started by this worker. A missing selected capture fails;
// a filtered run is explicitly partial and is never accepted as the full baseline.
export function writeRouteBundle(root: string, selected: readonly string[], expected: readonly string[]): void {
  if (selected.length === 0) return;
  if (new Set(selected).size !== selected.length || selected.some(id => !expected.includes(id))) throw new Error("Invalid route selection");
  const manifests: OperatorEvidenceManifest[] = selected.map(id => JSON.parse(readFileSync(resolveContainedPath(root, `${id}-manifest.json`), "utf8")));
  const first = manifests[0];
  for (const manifest of manifests) {
    serializeManifest(manifest);
    if (manifest.candidateDiffDigest !== first.candidateDiffDigest || manifest.baseSha !== first.baseSha || manifest.fixture.semanticId !== first.fixture.semanticId || manifest.custody.receiptSha256 !== first.custody.receiptSha256 || JSON.stringify(manifest.custody.forwardTaskCommits) !== JSON.stringify(first.custody.forwardTaskCommits)) throw new Error("Route manifest identity mismatch");
  }
  writeManifest(root, "manifest.json", {...first, route:"/audit", state: selected.length === expected.length ? "eleven-direct-routes-plus-ranking-twin" : "partial-direct-route-selection", captures: manifests.flatMap(m => m.captures)});
}
