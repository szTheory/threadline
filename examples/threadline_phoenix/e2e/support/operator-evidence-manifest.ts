import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  readFileSync,
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
  readonly captures: readonly OperatorCapture[];
}

const sha256 = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex");
const secretKey = /password|cookie|authorization|token|secret|credential|api[_-]?key/i;

function rejectSecrets(value: unknown, path = "metadata"): void {
  if (Array.isArray(value)) return value.forEach((item, index) => rejectSecrets(item, `${path}[${index}]`));
  if (!value || typeof value !== "object") return;
  for (const [key, child] of Object.entries(value)) {
    if (secretKey.test(key)) throw new Error(`Secret-bearing field is not allowed: ${path}.${key}`);
    rejectSecrets(child, `${path}.${key}`);
  }
}

export function semanticFixtureId(scenario: string, version: string, seedManifestSha256: string): string {
  if (!scenario.trim() || !version.trim() || !/^[a-f0-9]{64}$/.test(seedManifestSha256)) {
    throw new Error("Fixture scenario, version, and SHA-256 seed manifest identity are required");
  }
  return sha256(`${scenario}\0${version}\0${seedManifestSha256}`);
}

function relevant(path: string): boolean {
  return /^(lib\/threadline\/operator_surface(?:\/|\.ex$)|examples\/threadline_phoenix\/(e2e\/|lib\/|assets\/|priv\/static\/|config\/|mix\.(?:exs|lock)$)|mix\.(?:exs|lock)$|\.tool-versions$)/.test(path);
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
  fields(manifest, ["schemaVersion", "baseSha", "candidateHead", "candidateAncestry", "candidatePaths", "candidateChanges", "candidateDiffDigest", "fixture", "route", "state", "actor", "appearance", "browser", "viewport", "input", "captures"], "source");
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
