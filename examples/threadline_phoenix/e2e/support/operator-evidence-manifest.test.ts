import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { chmodSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test, { type TestContext } from "node:test";
import { assetRecord, candidateIdentity, localAssetPath, semanticFixtureId, serializeManifest, writeManifest, type OperatorEvidenceManifest } from "./operator-evidence-manifest.js";
import { DEFAULT_OPERATOR_SURFACE_PATHS } from "./operator-surface-paths.js";

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
const hash = (value: string) => createHash("sha256").update(value).digest("hex");

function valid(): OperatorEvidenceManifest {
  const seedManifestSha256 = hash("synthetic seed");
  const asset = { url: "http://127.0.0.1:4002/assets/app.js", status: 200, contentType: "text/javascript", servedSha256: hash("script"), localPath: "examples/threadline_phoenix/priv/static/assets/app.js", localSha256: hash("script") };
  return {
    schemaVersion: 1, baseSha: "a".repeat(40), candidateHead: "a".repeat(40), candidateAncestry: [], candidatePaths: [], candidateDiffDigest: hash("[]"),
    fixture: { scenario: "synthetic-demo", version: "v1", seedManifestSha256, semanticId: semanticFixtureId("synthetic-demo", "v1", seedManifestSha256) },
    route: "/audit", state: "authenticated-home", actor: { role: "seeded-admin", scope: "isolated-demo" }, appearance: { effectiveTheme: "dark", preference: "dark" },
    browser: { playwright: "1.60.0", browser: "148.0.7778.96" }, viewport: { width: 1280, height: 900, deviceScaleFactor: 1 }, input: { motion: "reduced", zoom: 1 },
    captures: [{ id: "home-shell", route: "/audit", state: "authenticated-home", condition: "desktop", outputPath: "home.png", outputSha256: hash("pixels"), assets: [asset, { ...asset, url: "inline:/audit#operator-css", contentType: "text/css", localPath: "lib/threadline/operator_surface/style/*.css" }] }],
  };
}

test("metadata proof accepts one route without claiming eleven-route browser coverage", () => {
  const result = JSON.parse(serializeManifest(valid()));
  assert.equal(new Set(result.captures.map((c: {route: string}) => c.route)).size, 1);
  assert.equal(result.complete, undefined);
  assert.equal(result.routeCount, undefined);
});

test("metadata proof rejects absent candidate diff identity", () => {
  assert.throws(() => serializeManifest({ ...valid(), candidateDiffDigest: "" }), /source|digest|identity/i);
});

test("metadata proof rejects missing fixture identity and forged semantic identity", () => {
  const manifest = valid();
  for (const key of ["scenario", "version", "seedManifestSha256", "semanticId"] as const) {
    assert.throws(() => serializeManifest({ ...manifest, fixture: { ...manifest.fixture, [key]: "" } }), /fixture|identity/i, key);
  }
  assert.throws(() => serializeManifest({ ...manifest, fixture: { ...manifest.fixture, semanticId: hash("forged") } }), /fixture|identity/i);
});

test("metadata proof rejects empty captures, assets, route, state and output hashes", () => {
  const manifest = valid();
  assert.throws(() => serializeManifest({ ...manifest, captures: [] }), /capture/i);
  assert.throws(() => serializeManifest({ ...manifest, captures: [{ ...manifest.captures[0], assets: [] }] }), /asset/i);
  for (const key of ["id", "route", "state", "condition", "outputPath", "outputSha256"] as const) {
    assert.throws(() => serializeManifest({ ...manifest, captures: [{ ...manifest.captures[0], [key]: "" }] }), /capture|route|state|condition|hash|output/i, key);
  }
});

test("metadata proof rejects altered asset bytes and duplicate capture IDs", () => {
  const manifest = valid();
  assert.throws(() => serializeManifest({ ...manifest, captures: [{ ...manifest.captures[0], assets: [{ ...manifest.captures[0].assets[0], servedSha256: hash("altered") }] }] }), /disagree/i);
  assert.throws(() => serializeManifest({ ...manifest, captures: [manifest.captures[0], manifest.captures[0]] }), /duplicate/i);
});

test("metadata proof preserves equal-content captures and orders route/state/condition/ID deterministically", () => {
  const manifest = valid();
  const c = manifest.captures[0];
  const captures = [{ ...c, id: "z" }, { ...c, id: "a" }, { ...c, id: "b", state: "other" }, { ...c, id: "c", route: "/audit/timeline" }];
  const first = serializeManifest({ ...manifest, captures });
  assert.equal(first, serializeManifest({ ...manifest, captures: [...captures].reverse() }));
  assert.deepEqual(JSON.parse(first).captures.map((item: {id: string}) => item.id), ["a", "z", "b", "c"]);
  assert.equal(new Set(JSON.parse(first).captures.map((item: {outputSha256: string}) => item.outputSha256)).size, 1);
});

test("metadata proof rejects credential fields and unknown metadata", () => {
  for (const key of ["password", "cookie", "authorization", "accessToken", "secret", "credentials", "api_key", "notes"]) {
    assert.throws(() => serializeManifest({ ...valid(), [key]: "must not be persisted" }), /secret|field|metadata/i, key);
  }
});

test("same scenario/version/seed retains semantic fixture identity across fresh partitions", () => {
  assert.equal(semanticFixtureId("demo", "v1", hash("seed")), semanticFixtureId("demo", "v1", hash("seed")));
  assert.notEqual(semanticFixtureId("demo", "v1", hash("seed")), semanticFixtureId("demo", "v2", hash("seed")));
});

test("asset proof maps exact URL paths, rejects unknown assets, altered bytes and symlinks", (t) => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "operator-assets-")));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const staticRoot = join(root, "examples/threadline_phoenix/priv/static");
  mkdirSync(join(staticRoot, "assets/nested"), { recursive: true });
  mkdirSync(join(root, "lib/threadline/operator_surface/style"), { recursive: true });
  writeFileSync(join(staticRoot, "assets/app.js"), "script");
  writeFileSync(join(staticRoot, "assets/nested/app.js"), "other script");
  writeFileSync(join(root, "lib/threadline/operator_surface/style/01_tokens.css"), "style");
  assert.equal(localAssetPath(root, "http://127.0.0.1/assets/nested/app.js"), join(staticRoot, "assets/nested/app.js"));
  assert.throws(() => localAssetPath(root, "http://127.0.0.1/assets/missing.css"), /No local built asset/i);
  assert.throws(() => localAssetPath(root, "http://127.0.0.1/unknown/app.js"), /No local built asset/i);
  assert.throws(() => assetRecord(root, "http://127.0.0.1/assets/app.js", 200, "text/javascript", Buffer.from("altered")), /disagree/i);
  symlinkSync(join(root, "lib"), join(staticRoot, "assets/linked"));
  assert.throws(() => localAssetPath(root, "http://127.0.0.1/assets/linked/anything.js"), /symlink/i);
});

function repository(t: TestContext) {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "operator-source-")));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const git = (...args: string[]) => execFileSync("git", args, { cwd: root, encoding: "utf8", env: { ...process.env, GIT_CONFIG_NOSYSTEM: "1" } }).trim();
  git("init", "-q", "-b", "operator-source-fixture");
  git("config", "user.email", "synthetic@example.invalid");
  git("config", "user.name", "Synthetic test");
  const source = "lib/threadline/operator_surface/style/example.css";
  mkdirSync(dirname(join(root, source)), { recursive: true });
  writeFileSync(join(root, source), "base");
  git("add", source); git("commit", "-qm", "synthetic base");
  return { root, git, source, base: git("rev-parse", "HEAD") };
}

test("source proof includes first-time unstaged/staged edits and retains digest on commit", (t) => {
  const { root, git, source, base } = repository(t);
  const clean = candidateIdentity(root, base);
  writeFileSync(join(root, source), "candidate");
  const dirty = candidateIdentity(root, base);
  assert.deepEqual(dirty.candidatePaths, [source]);
  assert.notEqual(clean.candidateDiffDigest, dirty.candidateDiffDigest);
  git("add", source);
  assert.equal(candidateIdentity(root, base).candidateDiffDigest, dirty.candidateDiffDigest);
  git("commit", "-qm", "synthetic candidate");
  assert.equal(candidateIdentity(root, base).candidateDiffDigest, dirty.candidateDiffDigest);
  chmodSync(join(root, source), 0o755);
  assert.notEqual(candidateIdentity(root, base).candidateDiffDigest, dirty.candidateDiffDigest);
  rmSync(join(root, source));
  assert.notEqual(candidateIdentity(root, base).candidateDiffDigest, dirty.candidateDiffDigest);
});

test("output proof rejects traversal, altered output bytes and reference fixture destinations", (t) => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "operator-output-")));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  writeFileSync(join(root, "home.png"), "pixels");
  writeManifest(root, "manifest.json", valid());
  const original = readFileSync(join(root, "manifest.json"), "utf8");
  assert.throws(() => writeManifest(root, "../escape.json", valid()), /outside/i);
  writeFileSync(join(root, "home.png"), "altered");
  assert.throws(() => writeManifest(root, "manifest.json", valid()), /output|hash/i);
  assert.equal(readFileSync(join(root, "manifest.json"), "utf8"), original);
  assert.throws(() => writeManifest(DEFAULT_OPERATOR_SURFACE_PATHS.fixtureRoot, "must-not-write.json", valid()), /immutable|overlap/i);
});

function runnerFixture(t: TestContext) {
  const { root, git, base } = repository(t);
  const e2e = join(root, "examples/threadline_phoenix/e2e");
  mkdirSync(e2e, { recursive: true });
  mkdirSync(join(root, "examples/threadline_phoenix/config"));
  copyFileSync(join(repositoryRoot, "examples/threadline_phoenix/config/test.exs"), join(root, "examples/threadline_phoenix/config/test.exs"));
  copyFileSync(join(repositoryRoot, "examples/threadline_phoenix/e2e/run-e2e.sh"), join(e2e, "run-e2e.sh"));
  const receipt = join(root, ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json");
  mkdirSync(dirname(receipt), { recursive: true });
  writeFileSync(receipt, JSON.stringify({ base_sha: base, expected_task_commits: [], worktree: root, branch: git("branch", "--show-current") }));
  const bin = join(root, "bin"); mkdirSync(bin);
  writeFileSync(join(bin, "psql"), '#!/usr/bin/env bash\nprintf "%s" "${FAKE_EXISTING_DB:-}"\n');
  writeFileSync(join(bin, "mix"), '#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$RUNNER_SENTINEL"\nexit 89\n');
  for (const command of ["psql", "mix"]) chmodSync(join(bin, command), 0o755);
  const sentinel = join(root, "reset-called");
  const env: NodeJS.ProcessEnv = { PATH: `${bin}:${process.env.PATH}`, HOME: process.env.HOME, TMPDIR: root, RUNNER_SENTINEL: sentinel, THREADLINE_E2E_PARTITION_REGISTRY: join(root, "registry"), THREADLINE_E2E_EVIDENCE: "1", THREADLINE_E2E_EVIDENCE_PREFLIGHT_ONLY: "1", MIX_TEST_PARTITION: "operator_contract", DB_HOST: "127.0.0.1", DB_PORT: "5432" };
  const run = (overrides: NodeJS.ProcessEnv = {}, args: string[] = []) => spawnSync("bash", [join(e2e, "run-e2e.sh"), ...args], { env: { ...env, ...overrides }, encoding: "utf8" });
  return { root, e2e, env, run, sentinel };
}

test("runner proof rejects unsafe evidence/preview targets before any reset subprocess", (t) => {
  const { run, sentinel } = runnerFixture(t);
  for (const [overrides, message] of [
    [{ MIX_TEST_PARTITION: "" }, /fresh MIX_TEST_PARTITION/],
    [{ MIX_TEST_PARTITION: "shared_dev" }, /fresh MIX_TEST_PARTITION/],
    [{ DB_HOST: "production.example.invalid" }, /non-loopback/],
    [{ DB_PORT: "0" }, /valid local DB_PORT/],
    [{ DATABASE_URL: "postgres://shared" }, /overrides/],
    [{ DEMO_ALLOW_RESET: "1" }, /overrides/],
    [{ FAKE_EXISTING_DB: "1" }, /existing database/],
    [{ E2E_BASE_URL: "https://external.example.invalid" }, /non-loopback|mismatched/],
  ] as const) {
    const result = run(overrides);
    assert.notEqual(result.status, 0, JSON.stringify(overrides));
    assert.match(result.stderr, message);
    assert.equal(existsSync(sentinel), false, "reset sentinel must never execute");
  }
  assert.notEqual(run({ THREADLINE_E2E_EVIDENCE: "0" }, ["--preview"]).status, 0);
});

test("runner proof registers a fresh synthetic target and refuses reused partition", (t) => {
  const { run, e2e, sentinel } = runnerFixture(t);
  const first = run();
  assert.equal(first.status, 0, first.stderr);
  const receipt = JSON.parse(readFileSync(join(e2e, "artifacts/operator-evidence/operator_contract/run.json"), "utf8"));
  assert.equal(receipt.database, "threadline_phoenix_testoperator_contract");
  assert.equal(receipt.partition, "operator_contract");
  const repeated = run();
  assert.notEqual(repeated.status, 0);
  assert.match(repeated.stderr, /reused partition/);
  assert.equal(existsSync(sentinel), false);
});

test("runner proof forwards ordinary and System/light named arguments without a partition", (t) => {
  const { run, sentinel } = runnerFixture(t);
  for (const theme of ["", "system"]) {
    const result = run({ THREADLINE_E2E_EVIDENCE: "0", THREADLINE_E2E_ARGUMENTS_ONLY: "1", MIX_TEST_PARTITION: "", THREADLINE_E2E_THEME: theme }, ["operator-shell-home.spec.ts", "--grep", "home"]);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /npm test --/);
    assert.match(result.stdout, /operator-shell-home.spec.ts --grep home/);
    assert.equal(result.stdout.includes("--project=desktop-chromium-light"), theme === "system");
    assert.equal(existsSync(sentinel), false);
  }
});
