import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test, { type TestContext } from "node:test";
import { assertCandidateFixtureMatchesReceipt, reviewEvidenceBundles } from "./operator-candidate-review.js";

const sha = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex");
const png = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 5, 0, 0, 0, 3, 132]);

function bundle(t: TestContext, prefix: string, options: { browser?: string; fixture?: string } = {}) {
  const root = realpathSync(mkdtempSync(join(tmpdir(), `candidate-review-${prefix}-`)));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const sourceRoot = join(root, "source"), runRoot = join(root, "run");
  mkdirSync(join(sourceRoot, "assets"), { recursive: true });
  mkdirSync(runRoot, { recursive: true });
  const js = "served javascript", css = "served css";
  writeFileSync(join(sourceRoot, "assets/app.js"), js);
  writeFileSync(join(sourceRoot, "assets/style.css"), css);
  const assets = [
    { url: "http://127.0.0.1/assets/app.js", status: 200, contentType: "text/javascript", servedSha256: sha(js), localPath: "assets/app.js", localSha256: sha(js) },
    { url: "http://127.0.0.1/assets/style.css", status: 200, contentType: "text/css", servedSha256: sha(css), localPath: "assets/style.css", localSha256: sha(css) },
  ];
  const captures = Array.from({ length: 11 }, (_, index) => {
    const id = `route.page-${index}__dark-1280-shell`;
    const outputPath = `${id}.png`;
    writeFileSync(join(runRoot, outputPath), png);
    return { id, route: `/audit/page-${index}`, state: "direct-entry", condition: JSON.stringify({ viewport: { width: 1280, height: 900, deviceScaleFactor: 1 }, motion: "reduced", browserZoom: "unverified" }), outputPath, outputSha256: sha(png), assets };
  });
  const manifest = {
    schemaVersion: 1, baseSha: "9".repeat(40), candidateHead: "a".repeat(40), candidateAncestry: ["a".repeat(40)],
    candidatePaths: [], candidateChanges: [], candidateDiffDigest: sha("[]"),
    custody: { receiptSha256: sha("receipt"), acceptedReceiptSha256: sha("accepted"), acceptedEvidenceIndexSha256: sha("index"), acceptedHead: "a".repeat(40), forwardTaskCommits: ["a".repeat(40)] },
    fixture: { scenario: "threadline-demo-seed", version: "v1", seedManifestSha256: sha("seed"), semanticId: options.fixture ?? sha("fixture") },
    route: "/audit", state: "eleven-routes", actor: { role: "seeded-admin", scope: "isolated-local-demo-database" },
    appearance: { effectiveTheme: "dark", preference: "dark" }, browser: { playwright: "1.60.0", browser: options.browser ?? "148.0" },
    viewport: { width: 1280, height: 900, deviceScaleFactor: 1 }, input: { motion: "reduced", zoom: 1 }, environment: { os: "linux" }, captures,
  };
  return { runRoot, sourceRoot, manifests: [manifest] };
}

test("review validates eleven full-shell PNG hashes and served/local assets", (t) => {
  const baseline = bundle(t, "baseline"), candidate = bundle(t, "candidate");
  const result = reviewEvidenceBundles([baseline], candidate);
  assert.equal(result.shellCount, 11);
  assert.equal(result.comparison, "matched");
  assert.deepEqual(result.differences, []);
});

test("review rejects a missing shell, changed output bytes, and asset mismatch", (t) => {
  const baseline = bundle(t, "baseline"), candidate = bundle(t, "candidate");
  const missing = structuredClone(candidate);
  missing.manifests[0].captures.pop();
  assert.throws(() => reviewEvidenceBundles([baseline], missing), /eleven|shell/i);

  const changed = bundle(t, "changed");
  writeFileSync(join(changed.runRoot, changed.manifests[0].captures[0].outputPath), "corrupt image");
  assert.throws(() => reviewEvidenceBundles([baseline], changed), /output.*hash|hash.*output/i);

  const assetMismatch = bundle(t, "asset");
  assetMismatch.manifests[0].captures[0].assets[0].localSha256 = sha("forged");
  assert.throws(() => reviewEvidenceBundles([baseline], assetMismatch), /asset|served|source/i);

  const changedBaseline = bundle(t, "changed-baseline");
  writeFileSync(join(changedBaseline.runRoot, changedBaseline.manifests[0].captures[0].outputPath), "changed accepted reference");
  assert.throws(() => reviewEvidenceBundles([changedBaseline], bundle(t, "baseline-check")), /output.*hash|hash.*output/i);
});

test("environment and fixture differences are disclosed and limit side-by-side comparison", (t) => {
  const baseline = bundle(t, "baseline"), candidate = bundle(t, "candidate", { browser: "149.0", fixture: sha("other fixture") });
  const result = reviewEvidenceBundles([baseline], candidate);
  assert.equal(result.comparison, "limited");
  assert.ok(result.differences.some((difference: string) => difference.includes("browser.browser")));
  assert.ok(result.differences.some((difference: string) => difference.includes("fixture.semanticId")));
});

test("fresh candidate manifest fixture must match its source receipt", (t) => {
  const candidate = bundle(t, "candidate");
  const fixture = candidate.manifests[0].fixture;
  assert.doesNotThrow(() => assertCandidateFixtureMatchesReceipt(fixture, fixture));
  assert.throws(() => assertCandidateFixtureMatchesReceipt({ ...fixture, seedManifestSha256: sha("different seed") }, fixture), /fixture identity.*candidate receipt/i);
});

test("historical generated asset drift is disclosed without weakening candidate asset verification", (t) => {
  const baseline = bundle(t, "baseline"), candidate = bundle(t, "candidate");
  writeFileSync(join(baseline.sourceRoot, "assets/app.js"), "regenerated baseline dependency asset");
  const result = reviewEvidenceBundles([baseline], candidate);
  assert.equal(result.comparison, "limited");
  assert.ok(result.differences.some((difference: string) => difference.includes("asset") && difference.includes("/assets/app.js")));

  writeFileSync(join(candidate.sourceRoot, "assets/app.js"), "changed candidate served asset");
  assert.throws(() => reviewEvidenceBundles([bundle(t, "baseline-check")], candidate), /asset|served|source/i);
});
