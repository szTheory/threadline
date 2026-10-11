import assert from "node:assert/strict";
import { test } from "node:test";

const previewModule = await import("./operator-preview-receipt.js").catch(() => null);

const hash = (value: string) => value.padEnd(64, "0").slice(0, 64);
const fixture = {
  scenario: "threadline-demo-seed",
  version: "seed-pipeline-v1",
  seedManifestSha256: hash("a"),
  semanticId: hash("b"),
};
const asset = {
  url: "http://127.0.0.1:4002/assets/app.js",
  status: 200,
  contentType: "text/javascript",
  servedSha256: hash("c"),
  localPath: "examples/threadline_phoenix/priv/static/assets/app.js",
  localSha256: hash("c"),
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
  assets: [asset],
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
  assert.throws(() => validate({ ...receipt, password: "canary-secret" }, expected), /field|schema/i);
  assert.throws(() => validate({ ...receipt, url: "https://preview.example.com" }, expected), /loopback|url/i);
  assert.throws(() => validate({ ...receipt, assets: [{ ...asset, servedSha256: hash("9") }] }, expected), /asset|hash/i);
});

test("stop retains state and does not signal when process, port, database or source bytes differ", () => {
  assert.ok(previewModule, "preview receipt module must be implemented");
  const observed = { pid: receipt.pid, cwd: receipt.worktree, host: "127.0.0.1", port: 4002, database: receipt.database };
  let signals = 0;
  const stop = (value: unknown, bytes: string, originalBytes: string, process: unknown) =>
    previewModule.guardedStopPreview(value, bytes, originalBytes, process, () => { signals += 1; });
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
