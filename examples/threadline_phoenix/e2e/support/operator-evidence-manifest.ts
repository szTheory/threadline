import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  readFileSync,
  statSync,
} from "node:fs";
import { basename, join, relative, resolve, sep } from "node:path";
import { atomicWriteFile, resolveContainedPath } from "./operator-surface-paths.js";

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
  return /^(lib\/threadline\/operator_surface\/|examples\/threadline_phoenix\/(e2e\/|lib\/|assets\/|priv\/static\/))/.test(path);
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
  const untracked = git(["ls-files", "--others", "--exclude-standard", "-z"]).split("\0");
  const paths = [...new Set([...committed, ...untracked].filter((path) => path && relevant(path)))].sort();
  const entries = paths.map((path) => {
    const absolute = resolve(root, path);
    if (!existsSync(absolute)) return { path, mode: "deleted", sha256: "deleted" };
    const stat = statSync(absolute);
    const mode = stat.mode & 0o111 ? "100755" : "100644";
    return { path, mode, sha256: sha256(readFileSync(absolute)) };
  });
  const ancestry = git(["rev-list", "--first-parent", "--reverse", `${baseSha}..HEAD`]).split("\n").filter(Boolean);
  return { baseSha, candidateHead, candidateAncestry: ancestry, candidatePaths: paths, candidateDiffDigest: sha256(JSON.stringify(entries)) };
}

export function validateServedAsset(asset: ServedAsset): void {
  if (!asset.url || asset.status !== 200 || !asset.contentType || !asset.localPath) {
    throw new Error("Served asset URL, successful status, type, and local source mapping are required");
  }
  if (!/^[a-f0-9]{64}$/.test(asset.servedSha256) || !/^[a-f0-9]{64}$/.test(asset.localSha256)) {
    throw new Error(`Asset hashes are missing or invalid for ${asset.url}`);
  }
  if (asset.servedSha256 !== asset.localSha256) throw new Error(`Served asset bytes disagree with local source: ${asset.url}`);
}

export function serializeManifest(manifest: OperatorEvidenceManifest): string {
  rejectSecrets(manifest);
  if (manifest.schemaVersion !== 1 || !/^[a-f0-9]{40}$/.test(manifest.baseSha) || !/^[a-f0-9]{40}$/.test(manifest.candidateHead)) {
    throw new Error("Manifest source identity is incomplete");
  }
  if (!manifest.fixture.semanticId || !manifest.fixture.scenario || !manifest.route || !manifest.state || !manifest.captures.length) {
    throw new Error("Manifest source, fixture, route, state, and capture identity are required");
  }
  const ids = new Set<string>();
  for (const capture of manifest.captures) {
    if (!capture.id || ids.has(capture.id)) throw new Error(`Missing or duplicate capture ID: ${capture.id || "<empty>"}`);
    ids.add(capture.id);
    if (!capture.outputPath || !/^[a-f0-9]{64}$/.test(capture.outputSha256)) throw new Error(`Capture output hash is required: ${capture.id}`);
    capture.assets.forEach(validateServedAsset);
  }
  const captures = [...manifest.captures].sort((a, b) => a.route.localeCompare(b.route) || a.state.localeCompare(b.state) || a.condition.localeCompare(b.condition) || a.id.localeCompare(b.id));
  return `${JSON.stringify({ ...manifest, captures }, null, 2)}\n`;
}

export function writeManifest(root: string, path: string, manifest: OperatorEvidenceManifest): void {
  const output = resolveContainedPath(root, path);
  atomicWriteFile(output, serializeManifest(manifest));
}

export function localAssetPath(root: string, responseUrl: string): string {
  const pathname = new URL(responseUrl).pathname;
  const file = basename(pathname);
  const candidates = [
    join(root, "examples/threadline_phoenix/priv/static/assets", file),
    join(root, "examples/threadline_phoenix/priv/static", file),
    join(root, "examples/threadline_phoenix/assets", file),
    ...[
      "lib/threadline/operator_surface/style/01_tokens.css",
      "lib/threadline/operator_surface/style/02_base_shell.css",
      "lib/threadline/operator_surface/style/03_page_home.css",
      "lib/threadline/operator_surface/style/04_controls.css",
      "lib/threadline/operator_surface/style/05_feedback.css",
      "lib/threadline/operator_surface/style/06_layout_primitives.css",
      "lib/threadline/operator_surface/style/07_find_detail.css",
      "lib/threadline/operator_surface/style/08_overlays_motion.css",
      "lib/threadline/operator_surface/style/09_responsive.css",
    ].map((path) => join(root, path)),
  ];
  const found = candidates.find((candidate) => existsSync(candidate));
  if (!found) throw new Error(`No local built asset maps to browser response ${responseUrl}`);
  const rel = relative(resolve(root), resolve(found));
  if (rel.startsWith(`..${sep}`)) throw new Error(`Asset mapping escaped source root: ${responseUrl}`);
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
