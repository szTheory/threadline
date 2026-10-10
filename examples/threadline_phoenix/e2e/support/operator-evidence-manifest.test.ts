import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { chmodSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test, { type TestContext } from "node:test";
import { assetRecord, writeRouteBundle, candidateIdentity, build239CandidateReceipt, validate239CandidateReceipt, assertNoCanaryLeak, validateCaptureMetadata, localAssetPath, semanticFixtureId, serializeManifest, writeManifest, type OperatorEvidenceManifest } from "./operator-evidence-manifest.js";
import { DEFAULT_OPERATOR_SURFACE_PATHS } from "./operator-surface-paths.js";

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
const hash = (value: string) => createHash("sha256").update(value).digest("hex");

function valid(): OperatorEvidenceManifest {
  const seedManifestSha256 = hash("synthetic seed");
  const asset = { url: "http://127.0.0.1:4002/assets/app.js", status: 200, contentType: "text/javascript", servedSha256: hash("script"), localPath: "examples/threadline_phoenix/priv/static/assets/app.js", localSha256: hash("script") };
  return {
    schemaVersion: 1, baseSha: "0".repeat(40), candidateHead: "c".repeat(40), candidateAncestry: ["b".repeat(40), "c".repeat(40)], candidatePaths: [], candidateChanges: [], candidateDiffDigest: hash("[]"),
    custody: { receiptSha256: hash("receipt"), acceptedReceiptSha256: hash("accepted receipt"), acceptedEvidenceIndexSha256: hash("accepted index"), acceptedHead: "b".repeat(40), forwardTaskCommits: ["c".repeat(40)] },
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
  for (const key of ["baseSha", "candidateHead", "candidateDiffDigest"] as const) {
    assert.throws(() => serializeManifest({ ...valid(), [key]: "" }), /source|digest|identity/i);
  }
});

test("forward custody must bind receipt, accepted evidence and explicit task ancestry", () => {
  const manifest = valid();
  assert.doesNotThrow(() => serializeManifest(manifest));
  assert.throws(() => serializeManifest({ ...manifest, candidateAncestry: [manifest.custody.acceptedHead] }), /ancestry/i);
  for (const changes of [
    { receiptSha256: "forged" },
    { acceptedEvidenceIndexSha256: "" },
    { acceptedHead: "not-a-commit" },
    { forwardTaskCommits: ["not-a-commit"] },
  ]) {
    assert.throws(() => serializeManifest({ ...manifest, custody: { ...manifest.custody, ...changes } }), /custody|ancestry|hash/i);
  }
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

test("evidence canary scan rejects secret text, attributes, and output bytes", () => {
  const canary = "synthetic-secret-canary-239-6f71";
  for (const payload of [
    `visible text ${canary}`,
    `<span data-tl-copy="${canary}">[REDACTED]</span>`,
    Buffer.from(`synthetic PNG payload ${canary}`),
  ]) {
    assert.throws(() => assertNoCanaryLeak(canary, "synthetic evidence output", payload), /canary/i);
  }
  assert.doesNotThrow(() => assertNoCanaryLeak(canary, "redacted evidence output", "[REDACTED]"));
});

test("capture metadata accepts known scalar fields and rejects unknown, nested, or canary-bearing values", () => {
  const canary = "synthetic-secret-canary-239-6f71";
  assert.doesNotThrow(() => validateCaptureMetadata({ httpStatus: 200, permission: "granted", limitation: "Actual denial remains unverified.", scopeDecision: "host callback" }, canary, "metadata"));
  assert.throws(() => validateCaptureMetadata({ authorizationSource: "host callback" }, canary, "metadata"), /secret-bearing/i);
  assert.throws(() => validateCaptureMetadata({ internalToken: "must not be persisted" }, canary, "metadata"), /secret-bearing/i);
  assert.throws(() => validateCaptureMetadata({ arbitrary: "unreviewed value" }, canary, "metadata"), /unknown capture metadata field/i);
  assert.throws(() => validateCaptureMetadata({ limitation: { value: "nested arbitrary metadata" } }, canary, "metadata"), /invalid capture metadata value/i);
  assert.throws(() => validateCaptureMetadata({ limitation: `leaked ${canary}` }, canary, "metadata"), /canary/i);
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
  const productionSource = "lib/threadline/change_diff.ex";
  mkdirSync(dirname(join(root, source)), { recursive: true });
  mkdirSync(dirname(join(root, productionSource)), { recursive: true });
  writeFileSync(join(root, source), "base");
  writeFileSync(join(root, productionSource), "base production module");
  git("add", source, productionSource); git("commit", "-qm", "synthetic base");
  return { root, git, source, productionSource, base: git("rev-parse", "HEAD") };
}

test("forward receipt chains accepted 238 evidence and rejects forged parent, changed source/context, and extra task ancestry", (t) => {
  const { root, git, source, base } = repository(t);
  const phase = ".planning/phases/239-investigation-entry-and-transaction-composition";
  const parentDir = ".planning/phases/238-current-main-preview-and-acceptance-baseline";
  mkdirSync(join(root, parentDir), { recursive: true });
  mkdirSync(join(root, phase), { recursive: true });
  const parentPath = join(root, parentDir, "238-ISOLATION-RECEIPT.json");
  const indexPath = join(root, parentDir, "238-EVIDENCE-INDEX.md");
  const receiptPath = join(root, phase, "239-CANDIDATE-RECEIPT.json");
  const contextPaths = ["239-07-PLAN.md", "239-CONTEXT.md", "239-UI-SPEC.md", "239-RESEARCH.md", "239-PATTERNS.md", "239-VALIDATION.md"];
  writeFileSync(parentPath, JSON.stringify({ base_sha: base, candidate_head: base }));
  writeFileSync(indexPath, ["# Final operator evidence custody", "| Eleven routes + degraded | bundle | 135 | `" + hash("routes") + "` | output |", "| Dark states | bundle | 63 | `" + hash("dark") + "` | output |", "| System/light states | bundle | 63 | `" + hash("light") + "` | output |", "## Historical evidence"].join("\n"));
  for (const file of contextPaths) writeFileSync(join(root, phase, file), file);
  git("add", parentDir, phase); git("commit", "-qm", "accepted 238 evidence snapshot");
  const acceptedHead = git("rev-parse", "HEAD");
  writeFileSync(parentPath, JSON.stringify({ base_sha: base, candidate_head: acceptedHead }));
  writeFileSync(join(root, source), "phase 239 candidate");
  git("add", source); git("commit", "-qm", "test(239-01): synthetic forward task");
  const taskCommit = git("rev-parse", "HEAD");
  const receipt = build239CandidateReceipt(root, [taskCommit], false);
  writeFileSync(receiptPath, JSON.stringify(receipt, null, 2) + "\n");
  assert.doesNotThrow(() => validate239CandidateReceipt(root, receipt, receiptPath, false));

  const acceptedBytes = readFileSync(parentPath), evidenceBytes = readFileSync(indexPath), contextPath = join(root, phase, "239-CONTEXT.md"), contextBytes = readFileSync(contextPath), sourceBytes = readFileSync(join(root, source));
  writeFileSync(parentPath, JSON.stringify({ base_sha: base, candidate_head: "f".repeat(40) }));
  assert.throws(() => validate239CandidateReceipt(root, receipt, receiptPath, false), /parent|custody|ancestry/i);
  writeFileSync(parentPath, acceptedBytes);
  writeFileSync(indexPath, evidenceBytes.toString("utf8").replace("bundle", "forged"));
  assert.throws(() => validate239CandidateReceipt(root, receipt, receiptPath, false), /receipt|evidence|forged|stale/i);
  writeFileSync(indexPath, evidenceBytes);
  writeFileSync(contextPath, "changed approved context");
  assert.throws(() => validate239CandidateReceipt(root, receipt, receiptPath, false), /context|stale|forged/i);
  writeFileSync(contextPath, contextBytes);
  writeFileSync(join(root, source), "altered candidate bytes");
  assert.throws(() => validate239CandidateReceipt(root, receipt, receiptPath, false), /source|digest|stale|forged/i);
  writeFileSync(join(root, source), sourceBytes);
  writeFileSync(join(root, source), "unexpected new 239 task");
  git("add", source); git("commit", "-qm", "feat(239-07): unexpected task ancestry");
  assert.throws(() => validate239CandidateReceipt(root, receipt, receiptPath, false), /commits|ancestry|stale/i);
});

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
  const untracked = "lib/threadline/operator_surface/style/new.css";
  writeFileSync(join(root, untracked), "new style");
  const identity = candidateIdentity(root, base);
  assert.ok(identity.candidatePaths.includes(untracked));
  writeFileSync(join(root, "README.md"), "unrelated prose");
  assert.equal(candidateIdentity(root, base).candidateDiffDigest, identity.candidateDiffDigest);
  rmSync(join(root, untracked));
  symlinkSync(join(root, "README.md"), join(root, untracked));
  assert.throws(() => candidateIdentity(root, base), /symlink/i);
});

test("candidate source identity includes changed root-level Threadline modules", (t) => {
  const { root, git, productionSource, base } = repository(t);
  writeFileSync(join(root, productionSource), "candidate production module");
  git("add", productionSource);
  git("commit", "-qm", "fix(239-07): change a core Threadline module");

  const identity = candidateIdentity(root, base);
  assert.ok(identity.candidatePaths.includes(productionSource));
  assert.equal(identity.candidateChanges.find((change) => change.path === productionSource)?.sha256, hash("candidate production module"));
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
  writeFileSync(receipt, JSON.stringify({ base_sha: base, expected_task_commits: [], worktree: root, branch: git("branch", "--show-current"), copied_context_sha256: {} }));
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
    [{ PORT: "invalid" }, /valid local HTTP port/],
    [{ DATABASE_URL: "postgres://shared" }, /overrides/],
    [{ DEMO_ALLOW_RESET: "1" }, /overrides/],
    [{ FAKE_EXISTING_DB: "1" }, /existing database/],
    [{ E2E_BASE_URL: "https://external.example.invalid" }, /non-loopback|mismatched/],
  ] as const) {
    for (const args of [[], ["--preview"]]) {
      const result = run(overrides, args);
      assert.notEqual(result.status, 0, JSON.stringify(overrides));
      assert.match(result.stderr, message);
      assert.equal(existsSync(sentinel), false, "reset sentinel must never execute");
    }
  }
  assert.notEqual(run({ THREADLINE_E2E_EVIDENCE: "0" }, ["--preview"]).status, 0);
});

test("runner proof rejects altered isolation root, branch, context and ancestry before reset", (t) => {
  const { root, run, sentinel } = runnerFixture(t);
  const receipt = join(root, ".planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json");
  const original = JSON.parse(readFileSync(receipt, "utf8"));
  for (const changes of [
    { worktree: root + "-other" }, { branch: "other-candidate" },
    { copied_context_sha256: { "examples/threadline_phoenix/config/test.exs": hash("altered context") } },
    { expected_task_commits: ["f".repeat(40)] },
  ]) {
    writeFileSync(receipt, JSON.stringify({ ...original, ...changes }));
    const result = run();
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Isolation receipt|isolation context|ancestry/i);
    assert.equal(existsSync(sentinel), false);
  }
});

test("ordinary runner lifecycle forwards arguments and removes only ignored export files", (t) => {
  const { root, e2e, run, sentinel } = runnerFixture(t);
  const bin = join(root, "bin");
  writeFileSync(join(bin, "mix"), '#!/usr/bin/env bash\nprintf "mix %s\\n" "$*" >> "$RUNNER_SENTINEL"\nif [[ "$*" == "phx.server" ]]; then exec sleep 30; fi\n');
  for (const name of ["npm", "npx"]) {
    writeFileSync(join(bin, name), `#!/usr/bin/env bash\nprintf '${name} %s\\n' "$*" >> "$RUNNER_SENTINEL"\n`);
    chmodSync(join(bin, name), 0o755);
  }
  writeFileSync(join(bin, "curl"), '#!/usr/bin/env bash\nif [[ "$*" == *"/audit"* ]]; then printf "HTTP/1.1 302 Found\\r\\nLocation: /users/log_in\\r\\n\\r\\n\\n__HTTP_CODE__302"; fi\n');
  writeFileSync(join(bin, "lsof"), "#!/usr/bin/env bash\nexit 1\n");
  chmodSync(join(bin, "curl"), 0o755); chmodSync(join(bin, "lsof"), 0o755);
  const example = dirname(e2e);
  mkdirSync(join(example, "lib/threadline_phoenix_web"), { recursive: true });
  writeFileSync(join(example, "lib/threadline_phoenix_web/router.ex"), "synthetic router");
  mkdirSync(join(example, "priv/threadline_exports"), { recursive: true });
  const tracked = join(example, "priv/threadline_exports/tracked.txt");
  writeFileSync(tracked, "retain tracked data");
  execFileSync("git", ["add", "examples/threadline_phoenix/priv/threadline_exports/tracked.txt"], { cwd: root });
  writeFileSync(join(root, ".gitignore"), "examples/threadline_phoenix/priv/threadline_exports/*\nunrelated.tmp\n");
  writeFileSync(join(root, "unrelated.tmp"), "retain unrelated generated data");
  for (const theme of ["", "system"]) {
    writeFileSync(join(example, "priv/threadline_exports/generated.csv"), "generated export");
    const result = run({ THREADLINE_E2E_EVIDENCE: "0", MIX_TEST_PARTITION: "", THREADLINE_E2E_THEME: theme, THREADLINE_E2E_EVIDENCE_PREFLIGHT_ONLY: "0" }, ["operator-shell-home.spec.ts", "--grep", "home"]);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(existsSync(join(example, "priv/threadline_exports/generated.csv")), false);
    assert.equal(readFileSync(tracked, "utf8"), "retain tracked data");
    assert.equal(readFileSync(join(root, "unrelated.tmp"), "utf8"), "retain unrelated generated data");
    assert.ok(readFileSync(sentinel, "utf8").includes(`npm test -- ${theme === "system" ? "--project=desktop-chromium-light " : ""}operator-shell-home.spec.ts --grep home`));
  }
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

test("both preview stop entrypoints reject invalid or unowned processes without signalling", (t) => {
  const { root, env, run } = runnerFixture(t);
  const state = join(root, "preview.json");
  const signal = join(root, "signal-called");
  const preload = join(root, "signal-mock.cjs");
  writeFileSync(preload, `process.kill=(pid,sig)=>{require('node:fs').writeFileSync(${JSON.stringify(signal)},JSON.stringify([pid,sig]));return true;};`);
  const bin = join(root, "bin");
  writeFileSync(join(bin, "lsof"), '#!/usr/bin/env bash\nexit 1\n');
  chmodSync(join(bin, "lsof"), 0o755);
  for (const args of [["--stop-preview"], []]) for (const pid of [0, 1, 777777]) {
    writeFileSync(state, JSON.stringify({pid,url:"http://127.0.0.1:4109",partition:"operator_stop",database:"threadline_phoenix_testoperator_stop"}));
    const result = run({ THREADLINE_E2E_PREVIEW_STATE:state, THREADLINE_E2E_STOP_PREVIEW:args.length ? "0":"1", NODE_OPTIONS:`--require=${preload}` }, args);
    assert.notEqual(result.status, 0, `accepted unowned PID ${pid}`);
    assert.ok(existsSync(state), "failed ownership check removed state");
    assert.ok(!existsSync(signal), "failed ownership check sent signal");
  }
});

test("owned preview stop checks cwd, loopback listener and database on both entrypoints", (t) => {
  const {root, run} = runnerFixture(t);
  const state=join(root,"preview.json"), signal=join(root,"signal-called"), preload=join(root,"signal-mock.cjs"), bin=join(root,"bin");
  writeFileSync(preload, `process.kill=(pid,sig)=>{require('node:fs').writeFileSync(${JSON.stringify(signal)},JSON.stringify([pid,sig]));return true;};`);
  writeFileSync(join(bin,"lsof"), '#!/usr/bin/env bash\ncase "$*" in\n*"-d cwd"*) printf "p777777\\nn%s\\n" "$FAKE_CWD" ;;\n*"-sTCP:LISTEN"*) printf "p777777\\nn%s\\n" "$FAKE_LISTENER" ;;\n*) printf "p777777\\nn127.0.0.1:55001->127.0.0.1:5432\\n" ;;\nesac\n');
  chmodSync(join(bin,"lsof"),0o755);
  const good={THREADLINE_E2E_PREVIEW_STATE:state,NODE_OPTIONS:`--require=${preload}`,FAKE_CWD:join(root,"examples/threadline_phoenix"),FAKE_LISTENER:"127.0.0.1:4109",FAKE_EXISTING_DB:"threadline_phoenix_testoperator_stop"};
  for(const args of [["--stop-preview"],[]]) {
    const mode={THREADLINE_E2E_STOP_PREVIEW:args.length ? "0":"1"};
    for(const override of [{FAKE_CWD:"/unrelated"},{FAKE_LISTENER:"*:4109"},{FAKE_LISTENER:"127.0.0.1:4110"},{FAKE_EXISTING_DB:"production"},{DB_HOST:"remote.invalid"}]) {
      writeFileSync(state,JSON.stringify({pid:777777,url:"http://127.0.0.1:4109",partition:"operator_stop",database:"threadline_phoenix_testoperator_stop"}));
      const result=run({...good,...mode,...override},args);
      assert.notEqual(result.status,0);assert.ok(existsSync(state));assert.ok(!existsSync(signal));
    }
    const result=run({...good,...mode},args);
    assert.equal(result.status,0,result.stderr);assert.deepEqual(JSON.parse(readFileSync(signal,"utf8")),[777777,"SIGTERM"]);assert.ok(!existsSync(state));
    unlinkSync(signal);
  }
});

test("focused route aggregation is partial and still rejects missing selected captures", (t) => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "operator-route-selection-")));
  t.after(() => rmSync(root, {recursive:true, force:true}));
  writeFileSync(join(root,"home.png"), "pixels");
  writeManifest(root,"route.home-manifest.json", valid());
  writeRouteBundle(root,["route.home"],["route.home","route.timeline"]);
  const partial = JSON.parse(readFileSync(join(root,"manifest.json"),"utf8"));
  assert.equal(partial.state,"partial-direct-route-selection");assert.equal(partial.captures.length,1);
  assert.throws(() => writeRouteBundle(root,["route.home","route.timeline"],["route.home","route.timeline"]), /ENOENT/);
  writeRouteBundle(root,[],["route.home","route.timeline"]);
  assert.deepEqual(JSON.parse(readFileSync(join(root,"manifest.json"),"utf8")),partial);
});
