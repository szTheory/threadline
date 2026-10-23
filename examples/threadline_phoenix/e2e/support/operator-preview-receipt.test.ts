import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, realpathSync, symlinkSync } from "node:fs";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const previewModule = await import("./operator-preview-receipt.js").catch(() => null);

const hash = (value: string) => value.padEnd(64, "0").slice(0, 64);
const fixture = {
  scenario: "threadline-demo-seed",
  version: "seed-pipeline-v1",
  seedManifestSha256: hash("a"),
  semanticId: createHash("sha256").update(`threadline-demo-seed\0seed-pipeline-v1\0${hash("a")}`).digest("hex"),
};
const asset = {
  url: "http://127.0.0.1:4002/assets/app.js",
  status: 200,
  contentType: "text/javascript",
  servedSha256: hash("c"),
  localPath: "examples/threadline_phoenix/priv/static/assets/app.js",
  localSha256: hash("c"),
};
const styleAsset = {
  url: "inline:/audit#threadline-operator-stylesheet",
  status: 200,
  contentType: "text/css; charset=utf-8",
  servedSha256: hash("7"),
  localPath: "lib/threadline/operator_surface/style/*.css (ordered segments)",
  localSha256: hash("7"),
};
const receipt = {
  schemaVersion: 1,
  candidateHead: hash("d").slice(0, 40),
  candidateDiffDigest: hash("e"),
  sourceReceiptSha256: hash("f"),
  fixture,
  url: "http://127.0.0.1:4002",
  pid: 43210,
  database: "threadline_phoenix_testoperator_preview_01",
  partition: "operator_preview_01",
  worktree: "/repo/worktree",
  branch: "agent-241-01",
  probes: {
    unauthenticatedLoginRedirect: true,
    authenticatedRoutes: Array.from({ length: 11 }, (_, index) => `/audit/route-${index + 1}`),
    liveViewConnected: true,
  },
  assets: [asset, styleAsset],
};
const expected = {
  worktree: receipt.worktree,
  branch: receipt.branch,
  candidateHead: receipt.candidateHead,
  candidateDiffDigest: receipt.candidateDiffDigest,
  sourceReceiptSha256: receipt.sourceReceiptSha256,
  fixture,
};

test("preview receipt binds allowlisted candidate, fixture, route probes and exact served assets", () => {
  assert.ok(previewModule, "preview receipt module must be implemented");
  assert.deepEqual(previewModule.validatePreviewReceipt(receipt, expected), receipt);
});

test("preview receipt rejects forged identity, secrets, external URLs and changed assets", () => {
  assert.ok(previewModule, "preview receipt module must be implemented");
  const validate = previewModule.validatePreviewReceipt;
  assert.throws(() => validate({ ...receipt, candidateHead: hash("0").slice(0, 40) }, expected), /candidate/i);
  assert.throws(() => validate({ ...receipt, candidateDiffDigest: hash("0") }, expected), /candidate/i);
  assert.throws(() => validate({ ...receipt, password: "canary-secret" }, expected), /field|schema/i);
  assert.throws(() => validate({ ...receipt, worktree: "/other/root" }, expected), /worktree/i);
  assert.throws(() => validate({ ...receipt, url: "https://preview.example.com" }, expected), /loopback|url/i);
  assert.throws(() => validate({ ...receipt, assets: [{ ...asset, servedSha256: hash("9") }, styleAsset] }, expected), /asset|hash/i);
  assert.throws(() => validate({ ...receipt, assets: [{ ...asset, url: `${asset.url}?token=canary-secret` }, styleAsset] }, expected), /asset|url/i);
});

test("stop retains state and does not signal when process, port, database or source bytes differ", () => {
  assert.ok(previewModule, "preview receipt module must be implemented");
  const observed = { pid: receipt.pid, cwd: `${receipt.worktree}/examples/threadline_phoenix`, host: "127.0.0.1", port: 4002, database: receipt.database };
  let signals = 0;
  const stop = (value: unknown, bytes: string, originalBytes: string, process: unknown) =>
    previewModule.guardedStopPreview(value, expected, bytes, originalBytes, process, () => { signals += 1; });
  assert.equal(stop(receipt, "source", "source", observed), true);
  assert.equal(signals, 1);
  for (const mismatch of [
    { ...observed, pid: receipt.pid + 1 },
    { ...observed, cwd: "/other/worktree" },
    { ...observed, host: "0.0.0.0" },
    { ...observed, port: 4003 },
    { ...observed, database: "postgres" },
  ]) {
    assert.throws(() => stop(receipt, "source", "source", mismatch), /ownership|changed|mismatch/i);
    assert.equal(signals, 1);
  }
  assert.throws(() => stop(receipt, "changed", "source", observed), /changed|source/i);
  assert.equal(signals, 1);
});

test("preview state paths reject traversal and symlink escapes", () => {
  assert.ok(previewModule, "preview receipt module must be implemented");
  const parent = mkdtempSync(join(tmpdir(), "preview-path-contract-"));
  const safe = join(parent, "threadline-e2e-preview-operator_test.json");
  assert.equal(previewModule.resolvePreviewStatePath(safe), join(realpathSync(parent), "threadline-e2e-preview-operator_test.json"));
  assert.throws(() => previewModule.resolvePreviewStatePath(join(parent, "..", "escaped.json")), /outside|traversal/i);
  symlinkSync("/etc", join(parent, "escape"));
  assert.throws(() => previewModule.resolvePreviewStatePath(join(parent, "escape", "threadline-e2e-preview-operator_test.json")), /symlink|outside/i);
});

test("live preview proves login, eleven deep links, served assets, guarded stop and fresh reopen", {
  skip: process.env.THREADLINE_E2E_LIVE_PREVIEW !== "1",
  timeout: 600_000,
}, async () => {
  assert.ok(previewModule, "preview receipt module must be implemented");
  const root = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
  const canonicalRoot = execFileSync("git", ["rev-parse", "--show-toplevel"], { cwd: root, encoding: "utf8" }).trim();
  const e2e = join(canonicalRoot, "examples/threadline_phoenix/e2e");
  const runner = join(e2e, "run-e2e.sh");
  const tsx = join(e2e, "node_modules/.bin/tsx");
  const candidateReceipt = ".planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json";
  const receiptScript = join(e2e, "support/operator-candidate-receipt.ts");
  const usedPorts = new Set<number>();
  const nonce = `${Date.now()}_${process.pid}`;

  async function freePort(): Promise<number> {
    for (;;) {
      const server = createServer();
      await new Promise<void>((resolve, reject) => server.once("error", reject).listen(0, "127.0.0.1", resolve));
      const port = (server.address() as { port: number }).port;
      await new Promise<void>((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
      if (!usedPorts.has(port)) { usedPorts.add(port); return port; }
    }
  }

  function refreshCandidate(): void {
    execFileSync(tsx, [receiptScript, "--refresh", candidateReceipt], { cwd: canonicalRoot, stdio: "pipe" });
  }

  function start(partition: string, state: string, port: number) {
    refreshCandidate();
    const env = {
      ...process.env,
      THREADLINE_E2E_EVIDENCE: "1",
      THREADLINE_E2E_PREVIEW: "1",
      THREADLINE_E2E_CANDIDATE_RECEIPT: candidateReceipt,
      THREADLINE_E2E_PREVIEW_STATE: state,
      MIX_TEST_PARTITION: partition,
      DB_HOST: "127.0.0.1",
      PORT: String(port),
      E2E_HOST: "127.0.0.1",
      E2E_BASE_URL: `http://127.0.0.1:${port}`,
    };
    const result = spawnSync("bash", [runner], { cwd: canonicalRoot, env, encoding: "utf8", timeout: 300_000 });
    assert.equal(result.status, 0, `preview start/capture failed: ${result.stderr}\n${result.stdout}`);
    const parsed = JSON.parse(readFileSync(state, "utf8"));
    assert.deepEqual(previewModule.validatePreviewReceipt(parsed, {
      worktree: canonicalRoot,
      branch: parsed.branch,
      candidateHead: parsed.candidateHead,
      candidateDiffDigest: parsed.candidateDiffDigest,
      sourceReceiptSha256: parsed.sourceReceiptSha256,
      fixture: parsed.fixture,
    }), parsed);
    process.kill(parsed.pid, 0);
    const listenerPid = execFileSync("lsof", ["-t", "-nP", `-iTCP:${port}`, "-sTCP:LISTEN"], { encoding: "utf8" }).trim();
    assert.equal(listenerPid, String(parsed.pid), "receipt PID must be the live listener-owning process after the launcher exits");
    const command = execFileSync("ps", ["-p", String(parsed.pid), "-o", "command="], { encoding: "utf8" }).trim();
    assert.match(command, /beam\.smp/, "preview receipt must name the Elixir VM");
    return { env, receipt: parsed };
  }

  function stop(state: string, env: NodeJS.ProcessEnv): void {
    const result = spawnSync("bash", [runner], {
      cwd: canonicalRoot,
      env: { ...env, THREADLINE_E2E_STOP_PREVIEW: "1" },
      encoding: "utf8",
      timeout: 30_000,
    });
    assert.equal(result.status, 0, `guarded preview stop failed: ${result.stderr}\n${result.stdout}`);
  }

  const firstPartition = `operator_243prev_${nonce}_a`;
  const secondPartition = `operator_243prev_${nonce}_b`;
  const firstState = join(tmpdir(), `threadline-e2e-preview-${firstPartition}.json`);
  const secondState = join(tmpdir(), `threadline-e2e-preview-${secondPartition}.json`);
  const first = start(firstPartition, firstState, await freePort());
  try {
    assert.equal(first.receipt.probes.authenticatedRoutes.length, 11);
    assert.ok(first.receipt.assets.some((item: { contentType: string }) => item.contentType.includes("javascript")));
    assert.ok(first.receipt.assets.some((item: { contentType: string }) => item.contentType.includes("css")));
  } finally {
    if (existsSync(firstState)) stop(firstState, first.env);
  }
  assert.throws(() => execFileSync("lsof", ["-nP", "-iTCP", `:${new URL(first.receipt.url).port}`, "-sTCP:LISTEN"], { stdio: "ignore" }));

  const second = start(secondPartition, secondState, await freePort());
  try {
    assert.notEqual(second.receipt.pid, first.receipt.pid);
    assert.notEqual(second.receipt.url, first.receipt.url);
    assert.notEqual(second.receipt.database, first.receipt.database);
    assert.notEqual(second.receipt.sourceReceiptSha256, "");
  } finally {
    if (existsSync(secondState)) stop(secondState, second.env);
  }
});
