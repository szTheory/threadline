import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  existsSync,
  lstatSync,
  readFileSync,
  realpathSync,
  unlinkSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium, expect, type Browser } from "@playwright/test";
import {
  CANDIDATE_RECEIPT_PATH,
  validate243CandidateReceipt,
  type Operator243CandidateReceipt,
} from "./operator-candidate-receipt.js";
import { assetRecord, semanticFixtureId, type ServedAsset } from "./operator-evidence-manifest.js";
import { login, seedPaths } from "./operator-browser-evidence.js";
import { atomicWriteFile, resolveContainedPath } from "./operator-surface-paths.js";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
const sha = (value: string | Uint8Array) => createHash("sha256").update(value).digest("hex");
const PREVIEW_PREFIX = "threadline-e2e-preview-";
const ROUTE_IDS = [
  "route.home", "route.timeline", "route.transaction", "route.row", "route.drawer",
  "route.actor", "route.coverage", "route.evidence", "route.exports",
  "route.redaction", "route.retention",
] as const;
const STYLE_SEGMENTS = [
  "01_tokens.css", "02_base_shell.css", "03_page_home.css", "04_controls.css",
  "05_feedback.css", "06_layout_primitives.css", "07_find_detail.css",
  "08_overlays_motion.css", "09_responsive.css",
] as const;

export interface PreviewAsset extends ServedAsset {}

export interface OperatorPreviewReceipt {
  readonly schemaVersion: 1;
  readonly candidateHead: string;
  readonly candidateDiffDigest: string;
  readonly sourceReceiptSha256: string;
  readonly fixture: Operator243CandidateReceipt["fixture"];
  readonly url: string;
  readonly pid: number;
  readonly database: string;
  readonly partition: string;
  readonly worktree: string;
  readonly branch: string;
  readonly probes: {
    readonly unauthenticatedLoginRedirect: true;
    readonly authenticatedRoutes: readonly string[];
    readonly liveViewConnected: true;
  };
  readonly assets: readonly PreviewAsset[];
}

export interface PreviewReceiptExpectation {
  readonly worktree: string;
  readonly branch: string;
  readonly candidateHead: string;
  readonly candidateDiffDigest: string;
  readonly sourceReceiptSha256: string;
  readonly fixture: Operator243CandidateReceipt["fixture"];
}

interface ProcessObservation {
  readonly pid: number;
  readonly cwd: string;
  readonly host: string;
  readonly port: number;
  readonly database: string;
}

function exactKeys(value: object, expected: readonly string[], label: string): void {
  const actual = Object.keys(value).sort();
  if (JSON.stringify(actual) !== JSON.stringify([...expected].sort())) {
    throw new Error(`${label} schema has unexpected or missing fields`);
  }
}

function requireHash(value: unknown, label: string, length = 64): asserts value is string {
  if (typeof value !== "string" || !new RegExp(`^[a-f0-9]{${length}}$`).test(value)) {
    throw new Error(`${label} must be a SHA-256 identity`);
  }
}

function validateAsset(value: PreviewAsset, expectedOrigin: string): void {
  exactKeys(value, ["url", "status", "contentType", "servedSha256", "localPath", "localSha256"], "preview asset");
  if (value.status !== 200 || !/^text\/(?:css|javascript)(?:;|$)|^application\/(?:css|javascript)(?:;|$)/.test(value.contentType)) {
    throw new Error("Preview asset must be a successful local CSS or JavaScript response");
  }
  if (!value.url.startsWith("inline:")) {
    const assetUrl = new URL(value.url);
    if (assetUrl.origin !== expectedOrigin || !assetUrl.pathname.startsWith("/assets/") || assetUrl.search || assetUrl.hash || assetUrl.username || assetUrl.password) {
      throw new Error("Preview asset URL must use a clean local asset path on the preview origin");
    }
  }
  if (value.url.startsWith("inline:") && value.url !== "inline:/audit#threadline-operator-stylesheet") {
    throw new Error("Preview inline stylesheet URL is not allowlisted");
  }
  if (!value.localPath.startsWith("examples/threadline_phoenix/priv/static/") && value.localPath !== "lib/threadline/operator_surface/style/*.css (ordered segments)") {
    throw new Error("Preview asset local source is not allowlisted");
  }
  requireHash(value.servedSha256, "served asset hash");
  requireHash(value.localSha256, "local asset hash");
  if (value.servedSha256 !== value.localSha256) throw new Error("Served and local asset hashes disagree");
}

export function validatePreviewReceipt(value: unknown, expected: PreviewReceiptExpectation): OperatorPreviewReceipt {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Preview receipt must be an object");
  const receipt = value as OperatorPreviewReceipt;
  exactKeys(receipt, [
    "schemaVersion", "candidateHead", "candidateDiffDigest", "sourceReceiptSha256", "fixture", "url",
    "pid", "database", "partition", "worktree", "branch", "probes", "assets",
  ], "preview receipt");
  if (receipt.schemaVersion !== 1) throw new Error("Unsupported preview receipt schema");
  requireHash(receipt.candidateHead, "candidate HEAD", 40);
  requireHash(receipt.candidateDiffDigest, "candidate diff digest");
  requireHash(receipt.sourceReceiptSha256, "source receipt hash");
  if (receipt.candidateHead !== expected.candidateHead || receipt.candidateDiffDigest !== expected.candidateDiffDigest) {
    throw new Error("Preview receipt candidate identity is stale or forged");
  }
  if (receipt.sourceReceiptSha256 !== expected.sourceReceiptSha256) throw new Error("Preview receipt source receipt bytes changed");
  if (receipt.worktree !== expected.worktree || receipt.branch !== expected.branch) throw new Error("Preview receipt worktree or branch identity changed");
  if (JSON.stringify(receipt.fixture) !== JSON.stringify(expected.fixture)) throw new Error("Preview receipt fixture identity changed");
  exactKeys(receipt.fixture, ["scenario", "version", "seedManifestSha256", "semanticId"], "preview fixture");
  requireHash(receipt.fixture.seedManifestSha256, "fixture seed hash");
  if (receipt.fixture.semanticId !== semanticFixtureId(receipt.fixture.scenario, receipt.fixture.version, receipt.fixture.seedManifestSha256)) {
    throw new Error("Preview receipt semantic fixture identity is invalid");
  }
  if (!Number.isSafeInteger(receipt.pid) || receipt.pid < 2) throw new Error("Preview receipt PID is invalid");
  if (!/^operator_[A-Za-z0-9_]+$/.test(receipt.partition)) throw new Error("Preview receipt partition is invalid");
  if (receipt.database !== `threadline_phoenix_test${receipt.partition}` || receipt.database.length > 63) throw new Error("Preview receipt database is not derived from its unique partition");
  let url: URL;
  try { url = new URL(receipt.url); } catch { throw new Error("Preview URL is invalid"); }
  if (url.protocol !== "http:" || url.hostname !== "127.0.0.1" || !url.port || url.pathname !== "/" || url.search || url.hash || url.origin !== receipt.url) {
    throw new Error("Preview URL must be an exact 127.0.0.1 origin");
  }
  exactKeys(receipt.probes, ["unauthenticatedLoginRedirect", "authenticatedRoutes", "liveViewConnected"], "preview probes");
  if (receipt.probes.unauthenticatedLoginRedirect !== true || receipt.probes.liveViewConnected !== true || !Array.isArray(receipt.probes.authenticatedRoutes)) {
    throw new Error("Preview authentication and LiveView probes must pass");
  }
  const routes = receipt.probes.authenticatedRoutes;
  if (routes.length !== ROUTE_IDS.length || new Set(routes).size !== ROUTE_IDS.length || routes.some((route) => typeof route !== "string" || !(route === "/audit" || route.startsWith("/audit/")) || /[?#\s]/.test(route))) {
    throw new Error("Preview must prove eleven unique authenticated operator routes");
  }
  if (!Array.isArray(receipt.assets) || receipt.assets.length < 2) throw new Error("Preview must prove local JavaScript and CSS bytes");
  receipt.assets.forEach((asset) => validateAsset(asset, url.origin));
  if (!receipt.assets.some((asset) => asset.contentType.includes("javascript")) || !receipt.assets.some((asset) => asset.contentType.includes("css"))) {
    throw new Error("Preview receipt requires both JavaScript and CSS assets");
  }
  return receipt;
}

export function guardedStopPreview(
  value: unknown,
  expected: PreviewReceiptExpectation,
  sourceReceiptBytes: string,
  originalReceiptBytes: string,
  observed: ProcessObservation,
  signal: (pid: number) => void,
): true {
  if (sourceReceiptBytes !== originalReceiptBytes) throw new Error("Preview receipt bytes changed during ownership check");
  const receipt = validatePreviewReceipt(value, expected);
  const url = new URL(receipt.url);
  const expectedCwd = resolve(receipt.worktree, "examples/threadline_phoenix");
  const matches = observed.pid === receipt.pid && observed.cwd === expectedCwd && observed.host === url.hostname &&
    observed.port === Number(url.port) && observed.database === receipt.database;
  if (!matches) throw new Error("Preview process, port, worktree or database ownership mismatch");
  signal(receipt.pid);
  return true;
}

export function resolvePreviewStatePath(path: string): string {
  const temporaryRoot = resolve(tmpdir());
  const absolute = resolve(path);
  const contained = resolveContainedPath(temporaryRoot, relative(temporaryRoot, absolute));
  if (!basename(contained).startsWith(PREVIEW_PREFIX) || !basename(contained).endsWith(".json")) {
    throw new Error("Preview state path is outside the owned temporary receipt namespace");
  }
  if (existsSync(contained) && !lstatSync(contained).isFile()) throw new Error("Preview state must be a regular file");
  return contained;
}

function expectedFor(rootDir: string, bytes: Buffer): { expectation: PreviewReceiptExpectation; source: Operator243CandidateReceipt } {
  const receiptPath = resolveContainedPath(rootDir, CANDIDATE_RECEIPT_PATH);
  const source = JSON.parse(bytes.toString("utf8")) as Operator243CandidateReceipt;
  validate243CandidateReceipt(rootDir, source, CANDIDATE_RECEIPT_PATH);
  if (readFileSync(receiptPath).compare(bytes) !== 0) throw new Error("Candidate receipt changed while preview was being verified");
  return {
    source,
    expectation: {
      worktree: rootDir,
      branch: source.branch,
      candidateHead: source.candidateHead,
      candidateDiffDigest: source.candidateDiffDigest,
      sourceReceiptSha256: sha(bytes),
      fixture: source.fixture,
    },
  };
}

function localStylesheet(): PreviewAsset {
  const local = STYLE_SEGMENTS.map((file) => readFileSync(join(root, "lib/threadline/operator_surface/style", file), "utf8")).join("");
  const digest = sha(local);
  return {
    url: "inline:/audit#threadline-operator-stylesheet",
    status: 200,
    contentType: "text/css; charset=utf-8",
    servedSha256: digest,
    localPath: "lib/threadline/operator_surface/style/*.css (ordered segments)",
    localSha256: digest,
  };
}

async function provePreview(url: string, browser: Browser): Promise<OperatorPreviewReceipt["probes"] & { assets: PreviewAsset[] }> {
  const unauthenticated = await fetch(`${url}/audit`, { redirect: "manual" });
  const location = unauthenticated.headers.get("location");
  if (![301, 302, 303, 307, 308].includes(unauthenticated.status) || !location) throw new Error("Unauthenticated /audit request did not return a login redirect");
  const target = new URL(location, url);
  if (target.origin !== url || target.pathname !== "/users/log_in" || target.username || target.password) throw new Error("Unauthenticated /audit redirect is not the local login path");

  const context = await browser.newContext({ baseURL: url });
  const page = await context.newPage();
  const assets = new Map<string, PreviewAsset>();
  const pending: Promise<void>[] = [];
  const assetErrors: string[] = [];
  page.on("response", (response) => {
    if (!["stylesheet", "script"].includes(response.request().resourceType()) || response.status() < 200 || response.status() >= 300) return;
    pending.push(response.body().then((body) => {
      const record = assetRecord(root, response.url(), response.status(), response.headers()["content-type"] ?? "", body);
      assets.set(record.url, record);
    }).catch((error: unknown) => { assetErrors.push(String(error)); }));
  });
  try {
    await login(page);
    const seeded = await seedPaths(page);
    const routes = [
      "/audit", "/audit/timeline", seeded.transaction, seeded.row, seeded.drawer,
      "/audit/actors/service_account/zendesk-sync", "/audit/coverage", "/audit/evidence",
      "/audit/exports", "/audit/policy/redaction", "/audit/policy/retention",
    ].map((route) => new URL(route, url).pathname);
    for (const route of routes) {
      await page.goto(route, { waitUntil: "domcontentloaded" });
      await expect(page.locator(".threadline-ui")).toBeVisible();
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      if (new URL(page.url()).pathname !== new URL(route, url).pathname) throw new Error(`Authenticated route did not stay on its deep link: ${route}`);
    }
    await Promise.all(pending);
    if (assetErrors.length) throw new Error(`Preview asset capture failed: ${assetErrors.join("; ")}`);
    await page.evaluate(() => document.fonts.ready);
    const servedCss = await page.locator("style").evaluateAll((styles) => styles.map((style) => style.textContent ?? "").find((text) => text.includes(".threadline-ui")) ?? "");
    const localCss = localStylesheet();
    if (!servedCss || sha(servedCss) !== localCss.localSha256) throw new Error("Served operator stylesheet differs from ordered local CSS segments");
    const scriptAssets = [...assets.values()].filter((asset) => asset.contentType.includes("javascript"));
    if (!scriptAssets.length) throw new Error("No local JavaScript asset was served by the preview");
    const css = { ...localCss, servedSha256: sha(servedCss) };
    return { unauthenticatedLoginRedirect: true, authenticatedRoutes: routes, liveViewConnected: true, assets: [...scriptAssets, css] };
  } finally {
    await context.close();
  }
}

export async function capturePreviewReceipt(path: string, pid: number, url: string, database: string, partition: string): Promise<OperatorPreviewReceipt> {
  const state = resolvePreviewStatePath(path);
  const receiptBytes = readFileSync(resolveContainedPath(root, CANDIDATE_RECEIPT_PATH));
  const { expectation, source } = expectedFor(root, receiptBytes);
  const port = Number(new URL(url).port);
  const browser = await chromium.launch({ headless: true });
  try {
    const proof = await provePreview(url, browser);
    const receipt: OperatorPreviewReceipt = {
      schemaVersion: 1,
      candidateHead: source.candidateHead,
      candidateDiffDigest: source.candidateDiffDigest,
      sourceReceiptSha256: expectation.sourceReceiptSha256,
      fixture: source.fixture,
      url,
      pid,
      database,
      partition,
      worktree: root,
      branch: source.branch,
      probes: {
        unauthenticatedLoginRedirect: proof.unauthenticatedLoginRedirect,
        authenticatedRoutes: proof.authenticatedRoutes,
        liveViewConnected: proof.liveViewConnected,
      },
      assets: proof.assets,
    };
    validatePreviewReceipt(receipt, expectation);
    const example = join(root, "examples/threadline_phoenix");
    const observation = inspectProcess(pid, port, database, example);
    if (observation.database !== database) throw new Error("Preview PostgreSQL connection did not map to the synthetic database");
    if (readFileSync(resolveContainedPath(root, CANDIDATE_RECEIPT_PATH)).compare(receiptBytes) !== 0) throw new Error("Candidate receipt changed during live preview verification");
    atomicWriteFile(state, `${JSON.stringify(receipt, null, 2)}\n`);
    return receipt;
  } finally {
    await browser.close();
  }
}

function run(command: string, args: readonly string[], env = process.env): string {
  return execFileSync(command, [...args], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], env }).trim();
}

function inspectProcess(pid: number, port: number, database: string, example: string): ProcessObservation {
  const cwdOutput = run("lsof", ["-a", "-p", String(pid), "-d", "cwd", "-Fn"]);
  const cwd = cwdOutput.split("\n").find((line) => line.startsWith("n"))?.slice(1) ?? "";
  if (realpathSync(cwd) !== realpathSync(example)) throw new Error("Preview process cwd does not match the example app");
  const listeners = run("lsof", ["-nP", "-a", "-p", String(pid), "-iTCP", "-sTCP:LISTEN", "-Fn"]).split("\n").filter((line) => line.startsWith("n"));
  if (listeners.length !== 1 || listeners[0] !== `n127.0.0.1:${port}`) throw new Error("Preview process must own exactly its 127.0.0.1 listener");
  const connections = run("lsof", ["-nP", "-a", "-p", String(pid), "-iTCP", "-sTCP:ESTABLISHED", "-Fn"]);
  const clientPorts = [...connections.matchAll(/n127\.0\.0\.1:(\d+)->127\.0\.0\.1:(\d+)/g)].filter((match) => Number(match[2]) === Number(process.env.DB_PORT || 5432)).map((match) => Number(match[1]));
  if (!clientPorts.length) throw new Error("Preview process has no loopback PostgreSQL connection");
  const clientList = clientPorts.join(",");
  const dbHost = process.env.DB_HOST || "127.0.0.1";
  const dbPort = process.env.DB_PORT || "5432";
  const dbUser = process.env.DB_USERNAME || "postgres";
  const dbResult = run("psql", ["-X", "-h", dbHost, "-p", dbPort, "-U", dbUser, "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-Atqc", `SELECT DISTINCT datname FROM pg_stat_activity WHERE client_port IN (${clientList})`], {
    ...process.env,
    PGPASSWORD: process.env.DB_PASSWORD || "postgres",
  });
  if (dbResult !== database) throw new Error("Preview process PostgreSQL sessions do not map only to its derived database");
  return { pid, cwd: realpathSync(cwd), host: "127.0.0.1", port, database: dbResult };
}

function waitForProcessExit(pid: number): void {
  const delay = new Int32Array(new SharedArrayBuffer(4));
  for (let attempt = 0; attempt < 100; attempt += 1) {
    try { process.kill(pid, 0); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ESRCH") return;
      throw error;
    }
    Atomics.wait(delay, 0, 0, 50);
  }
  throw new Error("Verified preview process did not exit after SIGTERM; state is retained");
}

export function stopPreviewReceipt(path: string): void {
  const state = resolvePreviewStatePath(path);
  const originalStat = lstatSync(state);
  const original = readFileSync(state, "utf8");
  const receipt = JSON.parse(original) as OperatorPreviewReceipt;
  const candidateBytes = readFileSync(resolveContainedPath(root, CANDIDATE_RECEIPT_PATH));
  const { expectation } = expectedFor(root, candidateBytes);
  validatePreviewReceipt(receipt, expectation);
  const checkedStat = lstatSync(state);
  if (!checkedStat.isFile() || checkedStat.dev !== originalStat.dev || checkedStat.ino !== originalStat.ino) throw new Error("Preview state file identity changed during ownership check");
  const observed = inspectProcess(receipt.pid, Number(new URL(receipt.url).port), receipt.database, join(root, "examples/threadline_phoenix"));
  if (readFileSync(resolveContainedPath(root, CANDIDATE_RECEIPT_PATH)).compare(candidateBytes) !== 0) throw new Error("Candidate receipt changed during process ownership check");
  const finalStat = lstatSync(state);
  if (!finalStat.isFile() || finalStat.dev !== originalStat.dev || finalStat.ino !== originalStat.ino) throw new Error("Preview state file identity changed before signal");
  const currentReceiptBytes = readFileSync(state, "utf8");
  const afterReadStat = lstatSync(state);
  if (currentReceiptBytes !== original || afterReadStat.dev !== originalStat.dev || afterReadStat.ino !== originalStat.ino) throw new Error("Preview receipt bytes changed before signal");
  guardedStopPreview(receipt, expectation, currentReceiptBytes, original, observed, (pid) => process.kill(pid, "SIGTERM"));
  waitForProcessExit(receipt.pid);
  unlinkSync(state);
  process.stdout.write(`Stopped owned loopback preview process ${receipt.pid}.\n`);
}

const mode = process.argv[2];
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    if (mode === "--capture") {
      const [, , , path, pidText, url, database, partition] = process.argv;
      if (!path || !/^\d+$/.test(pidText ?? "") || !url || !database || !partition) throw new Error("Preview capture arguments are incomplete");
      const receipt = await capturePreviewReceipt(path, Number(pidText), url, database, partition);
      process.stdout.write(JSON.stringify({ pid: receipt.pid, url: receipt.url, database: receipt.database, candidateHead: receipt.candidateHead, assetCount: receipt.assets.length }) + "\n");
    } else if (mode === "--stop") {
      const path = process.argv[3];
      if (!path) throw new Error("Preview state path is required");
      stopPreviewReceipt(path);
    }
  } catch (error) {
    process.stderr.write(`${String(error)}\n`);
    process.exitCode = 1;
  }
}
