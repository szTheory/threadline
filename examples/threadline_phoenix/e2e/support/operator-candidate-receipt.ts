import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { lstatSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { atomicWriteFile, resolveContainedPath } from "./operator-surface-paths.js";
import { candidateIdentity, semanticFixtureId } from "./operator-evidence-manifest.js";

export const CANDIDATE_RECEIPT_PATH = ".planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json";
const ACCEPTED_RECEIPT_PATH = ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json";
const ACCEPTED_INDEX_PATH = ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md";
const APPROVED_BASE = "9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2";
const APPROVED_HEAD = "43c5bcfa960b1a10cb07ef997e2231e9615dca6f";
const APPROVED_RECEIPT_SHA256 = "1eaa28ead2105993d73e77364166600033e0940cf345e5b1776eb5ee5823ae99";
const APPROVED_INDEX_SHA256 = "388700a3de3db3206fdf8fe5bdfc7dc316e8e83e59ed49150094e9e898789d47";
const APPROVED_MANIFEST_SETS = [
  "d796f34cfbe976e89b68e3d597b535e564f432cba18e55a3b76024dbc775ffb3",
  "25744cfd3e4644a33600eba7ea3edcdfdb884cbff2d25f6877b0f86ba2b32a9b",
  "ad53c46d449804e6bde6b5f35b5643646535ecd3c58ecc57bea30a3d321673b3",
] as const;
const SEED_ROOT = "examples/threadline_phoenix/lib/threadline_phoenix/demo";
const sha = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex");

export interface Operator243CandidateReceipt {
  readonly schemaVersion: 1;
  readonly phase: 243;
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
  readonly fixture: { readonly scenario: string; readonly version: string; readonly seedManifestSha256: string; readonly semanticId: string };
}

function git(root: string, ...args: string[]): string {
  return execFileSync("git", args, { cwd: root, encoding: "utf8" }).trim();
}

function fixtureIdentity(root: string): Operator243CandidateReceipt["fixture"] {
  const seedDir = join(root, SEED_ROOT);
  const seedFiles = ["seed.ex", "manifest.ex", ...readdirSync(join(seedDir, "seed"), { recursive: true }).map((file) => `seed/${String(file)}`)].sort();
  const hash = createHash("sha256");
  for (const path of seedFiles) {
    const absolute = resolveContainedPath(root, join(SEED_ROOT, path));
    if (!lstatSync(absolute).isFile()) throw new Error(`Fixture source must be a regular file: ${path}`);
    hash.update(path).update("\0").update(readFileSync(absolute));
  }
  const configPath = "examples/threadline_phoenix/config/test.exs";
  hash.update(configPath).update("\0").update(readFileSync(resolveContainedPath(root, configPath)));
  const seedManifestSha256 = hash.digest("hex");
  const scenario = "threadline-demo-seed";
  const version = "seed-pipeline-v1";
  return { scenario, version, seedManifestSha256, semanticId: semanticFixtureId(scenario, version, seedManifestSha256) };
}

function acceptedCustody(root: string, enforceApprovedBaseline: boolean) {
  const receiptBytes = readFileSync(join(root, ACCEPTED_RECEIPT_PATH));
  const indexBytes = readFileSync(join(root, ACCEPTED_INDEX_PATH));
  const parent = JSON.parse(receiptBytes.toString("utf8")) as { base_sha?: string; candidate_head?: string };
  const index = indexBytes.toString("utf8");
  const accepted = index.split("## Historical evidence")[0];
  const manifestSets = [...accepted.matchAll(/\| (?:Eleven routes \+ degraded|Dark states|System\/light states) \|[^|]*\| [0-9]+ \| `([a-f0-9]{64})` \|/g)].map((match) => match[1]);
  if (manifestSets.length !== 3 || !parent.base_sha || !parent.candidate_head) throw new Error("Accepted Phase 238 custody is incomplete");
  const receiptSha256 = sha(receiptBytes);
  const indexSha256 = sha(indexBytes);
  if (enforceApprovedBaseline && (parent.base_sha !== APPROVED_BASE || parent.candidate_head !== APPROVED_HEAD || receiptSha256 !== APPROVED_RECEIPT_SHA256 || indexSha256 !== APPROVED_INDEX_SHA256 || JSON.stringify(manifestSets) !== JSON.stringify(APPROVED_MANIFEST_SETS))) {
    throw new Error("Phase 238 receipt, evidence index, or selected manifests differ from the approved immutable baseline");
  }
  if (indexSha256 !== sha(indexBytes)) throw new Error("Accepted Phase 238 evidence index changed while reading");
  return { baseSha: parent.base_sha, acceptedHead: parent.candidate_head, receiptSha256, indexSha256, manifestSets };
}

export function build243CandidateReceipt(root: string, enforceApprovedBaseline = true): Operator243CandidateReceipt {
  const absoluteRoot = resolve(root);
  if (git(absoluteRoot, "rev-parse", "--show-toplevel") !== absoluteRoot) throw new Error("Candidate root must be the exact git worktree root");
  const accepted = acceptedCustody(absoluteRoot, enforceApprovedBaseline);
  try {
    execFileSync("git", ["merge-base", "--is-ancestor", accepted.acceptedHead, "HEAD"], { cwd: absoluteRoot, stdio: "ignore" });
  } catch {
    throw new Error("Candidate is not descended from the accepted Phase 238 head");
  }
  const candidate = candidateIdentity(absoluteRoot, accepted.baseSha);
  if (!candidate.candidateAncestry.includes(accepted.acceptedHead)) throw new Error("Accepted Phase 238 head is missing from candidate ancestry");
  return {
    schemaVersion: 1,
    phase: 243,
    worktree: absoluteRoot,
    branch: git(absoluteRoot, "branch", "--show-current"),
    baseSha: accepted.baseSha,
    acceptedHead: accepted.acceptedHead,
    acceptedReceiptSha256: accepted.receiptSha256,
    acceptedEvidenceIndexSha256: accepted.indexSha256,
    acceptedEvidenceManifestSets: accepted.manifestSets,
    forwardTaskCommits: git(absoluteRoot, "rev-list", "--first-parent", "--reverse", `${accepted.acceptedHead}..HEAD`).split("\n").filter(Boolean),
    ...candidate,
    fixture: fixtureIdentity(absoluteRoot),
  };
}

function expectedReceiptPath(root: string, path: string): string {
  if (path !== CANDIDATE_RECEIPT_PATH) throw new Error("Phase 243 candidate receipt path must be the exact owned repository-relative path");
  return resolveContainedPath(root, path);
}

export function validate243CandidateReceipt(root: string, receipt: Operator243CandidateReceipt, path = CANDIDATE_RECEIPT_PATH, enforceApprovedBaseline = true): void {
  const expected = expectedReceiptPath(root, path);
  const actual = readFileSync(expected);
  let onDisk: Operator243CandidateReceipt;
  try { onDisk = JSON.parse(actual.toString("utf8")) as Operator243CandidateReceipt; }
  catch { throw new Error("Candidate receipt is not valid JSON"); }
  if (JSON.stringify(receipt) !== JSON.stringify(onDisk)) throw new Error("Candidate receipt bytes do not match the validated receipt object");
  const rebuilt = build243CandidateReceipt(root, enforceApprovedBaseline);
  if (JSON.stringify(onDisk) !== JSON.stringify(rebuilt)) throw new Error("Phase 243 candidate receipt is stale or forged for this worktree, branch, baseline, fixture, or candidate bytes");
}

export function refresh243CandidateReceipt(root: string, path = CANDIDATE_RECEIPT_PATH, enforceApprovedBaseline = true): Operator243CandidateReceipt {
  const output = expectedReceiptPath(root, path);
  const receipt = build243CandidateReceipt(root, enforceApprovedBaseline);
  atomicWriteFile(output, `${JSON.stringify(receipt, null, 2)}\n`);
  return receipt;
}

export function candidateReceiptSha256(bytes: string | Uint8Array): string { return sha(bytes); }

const moduleDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(moduleDirectory, "../../../..");
const mode = process.argv[2];
const cliPath = process.argv[3] ?? CANDIDATE_RECEIPT_PATH;
if (mode === "--refresh" || mode === "--validate") {
  try {
    if (mode === "--refresh") {
      const receipt = refresh243CandidateReceipt(repositoryRoot, cliPath);
      const bytes = readFileSync(expectedReceiptPath(repositoryRoot, cliPath));
      process.stdout.write(JSON.stringify({ candidateHead: receipt.candidateHead, candidateDiffDigest: receipt.candidateDiffDigest, receiptSha256: sha(bytes) }) + "\n");
    } else {
      const path = expectedReceiptPath(repositoryRoot, cliPath);
      const bytes = readFileSync(path);
      const receipt = JSON.parse(bytes.toString("utf8")) as Operator243CandidateReceipt;
      validate243CandidateReceipt(repositoryRoot, receipt, cliPath);
      process.stdout.write(JSON.stringify({ candidateHead: receipt.candidateHead, candidateDiffDigest: receipt.candidateDiffDigest, receiptSha256: sha(bytes) }) + "\n");
    }
  } catch (error) {
    process.stderr.write(`${String(error)}\n`);
    process.exitCode = 1;
  }
}
