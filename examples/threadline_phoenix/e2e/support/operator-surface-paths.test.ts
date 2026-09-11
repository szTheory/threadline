import assert from "node:assert/strict";
import {
  copyFile,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  realpath,
  rm,
  symlink,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, relative, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const expectedRepositoryRoot = resolve(here, "../../../..");

const criticReaders = [
  "bundle.ts",
  "gate.ts",
  "label.ts",
  "label_web.ts",
  "panel.ts",
  "prompt.ts",
  "refute.ts",
  "report.ts",
  "report_html.ts",
  "rubric.ts",
  "schema.ts",
] as const;

async function loadAdapter(moduleUrl = new URL("./operator-surface-paths.js", import.meta.url)) {
  try {
    return await import(moduleUrl.href);
  } catch (error) {
    return { loadError: error };
  }
}

test("resolves repository evidence identically from root, nested cwd, and a worktree", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.resolveOperatorSurfacePaths, "function");

  const originalCwd = process.cwd();
  const nestedCwd = resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/critic");

  try {
    process.chdir(expectedRepositoryRoot);
    const fromRoot = adapter.resolveOperatorSurfacePaths();
    process.chdir(nestedCwd);
    const fromNested = adapter.resolveOperatorSurfacePaths();

    assert.deepEqual(fromNested, fromRoot);
    assert.equal(fromRoot.repositoryRoot, expectedRepositoryRoot);
    assert.equal(fromRoot.scorecardsDir, resolve(expectedRepositoryRoot, ".planning/scorecards"));
  } finally {
    process.chdir(originalCwd);
  }

  const worktreeRoot = await mkdtemp(resolve(tmpdir(), "threadline-paths-worktree-"));
  const copiedModule = resolve(
    worktreeRoot,
    "examples/threadline_phoenix/e2e/support/operator-surface-paths.ts",
  );

  try {
    await mkdir(dirname(copiedModule), { recursive: true });
    await mkdir(resolve(worktreeRoot, ".planning/critic-scores"), { recursive: true });
    await copyFile(resolve(here, "operator-surface-paths.ts"), copiedModule);
    const worktreeAdapter = await loadAdapter(pathToFileURL(copiedModule));
    assert.equal(
      "loadError" in worktreeAdapter,
      false,
      `worktree adapter failed to load: ${String(worktreeAdapter.loadError)}`,
    );

    const worktreePaths = worktreeAdapter.resolveOperatorSurfacePaths();
    const canonicalWorktreeRoot = await realpath(worktreeRoot);
    assert.equal(worktreePaths.repositoryRoot, canonicalWorktreeRoot);
    assert.equal(
      worktreePaths.scorecardsDir,
      resolve(canonicalWorktreeRoot, ".planning/scorecards"),
    );
  } finally {
    await rm(worktreeRoot, { recursive: true, force: true });
  }
});

test("explicit fixture and output flags override deterministic defaults without environment lookup", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);

  const fixtureRoot = await mkdtemp(resolve(tmpdir(), "threadline-paths-fixtures-"));
  const outputRoot = await mkdtemp(resolve(tmpdir(), "threadline-paths-output-"));
  const previousEnvironmentValue = process.env.THREADLINE_FIXTURE_ROOT;
  process.env.THREADLINE_FIXTURE_ROOT = resolve(tmpdir(), "must-not-be-used");

  try {
    const parsed = adapter.parseOperatorSurfaceRootFlags([
      "--fixture-root",
      fixtureRoot,
      "--output-root",
      outputRoot,
      "--dry-run",
    ]);
    const paths = adapter.resolveOperatorSurfacePaths(parsed.overrides);

    assert.deepEqual(parsed.rest, ["--dry-run"]);
    assert.equal(paths.fixtureRoot, await realpath(fixtureRoot));
    assert.equal(paths.goldenDir, resolve(await realpath(fixtureRoot), "golden"));
    assert.equal(paths.generatedRoot, await realpath(outputRoot));
    assert.equal(paths.criticScoresDir, await realpath(outputRoot));
  } finally {
    if (previousEnvironmentValue === undefined) delete process.env.THREADLINE_FIXTURE_ROOT;
    else process.env.THREADLINE_FIXTURE_ROOT = previousEnvironmentValue;
    await rm(fixtureRoot, { recursive: true, force: true });
    await rm(outputRoot, { recursive: true, force: true });
  }
});

test("required JSON failures name the dataset, resolved path, repository scope, and recovery command", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.readRequiredJson, "function");

  const fixtureRoot = await mkdtemp(resolve(tmpdir(), "threadline-paths-json-"));
  const missingPath = resolve(fixtureRoot, "missing.json");
  const malformedPath = resolve(fixtureRoot, "malformed.json");
  const recoveryCommand = "npm run critic:check";

  try {
    assert.throws(
      () => adapter.readRequiredJson(missingPath, {
        dataset: "golden set",
        repositoryOnly: true,
        recoveryCommand,
      }),
      (error: Error) =>
        error.message.includes("golden set") &&
        error.message.includes(missingPath) &&
        error.message.includes("repository-only: true") &&
        error.message.includes(recoveryCommand),
    );

    await writeFile(malformedPath, "{not-json}\n", "utf8");
    assert.throws(
      () => adapter.readRequiredJson(malformedPath, {
        dataset: "synthetic set",
        repositoryOnly: true,
        recoveryCommand,
      }),
      (error: Error) =>
        error.message.includes("synthetic set") &&
        error.message.includes(malformedPath) &&
        error.message.includes("repository-only: true") &&
        error.message.includes(recoveryCommand),
    );
  } finally {
    await rm(fixtureRoot, { recursive: true, force: true });
  }
});

test("critic readers share the adapter without independent planning or cwd roots", async () => {
  const criticRoot = resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/critic");
  const offenders: string[] = [];

  for (const filename of criticReaders) {
    const source = await readFile(resolve(criticRoot, filename), "utf8");
    if (source.includes(".planning")) offenders.push(`${filename}: planning literal`);
    if (source.includes("process.cwd(")) offenders.push(`${filename}: process.cwd root`);

    if (filename !== "schema.ts" && !source.includes("operator-surface-paths.js")) {
      offenders.push(`${filename}: shared adapter import missing`);
    }
  }

  const shellSource = await readFile(
    resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/critic-before-pole.sh"),
    "utf8",
  );
  assert.match(shellSource, /critic\/run\.ts paths/);
  assert.doesNotMatch(shellSource, /\.planning|CACHE_DIR="\$ROOT/);
  assert.deepEqual(offenders, []);
});

test("graded capture uses contained generated targets without redirecting snapshots", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);

  const source = await readFile(
    resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/tests/operator-graded-capture.spec.ts"),
    "utf8",
  );

  assert.match(source, /operator-surface-paths\.js/);
  assert.match(source, /resolveContainedPath/);
  assert.match(source, /atomicWriteFile/);
  assert.doesNotMatch(source, /process\.cwd\(|\.planning\//);
  assert.doesNotMatch(source, /writeFileSync/);
  assert.doesNotMatch(source, /toHaveScreenshot\(/);

  assert.throws(
    () => adapter.resolveContainedPath(
      adapter.DEFAULT_OPERATOR_SURFACE_PATHS.e2eRoot,
      "artifacts/graded/../../../../hostile-output",
    ),
    /outside|traversal/i,
  );
});

test("rejects traversal, absolute escape, prefix confusion, and symlink escape", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.resolveContainedPath, "function");

  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-paths-containment-"));
  const root = resolve(sandbox, "evidence");
  const prefixSibling = resolve(sandbox, "evidence-escape");
  const outside = resolve(sandbox, "outside");

  try {
    await mkdir(resolve(root, "nested"), { recursive: true });
    await mkdir(prefixSibling);
    await mkdir(outside);
    await symlink(outside, resolve(root, "linked-outside"));
    const canonicalRoot = await realpath(root);

    assert.equal(
      adapter.resolveContainedPath(root, "nested/valid.json"),
      resolve(canonicalRoot, "nested/valid.json"),
    );
    assert.throws(() => adapter.resolveContainedPath(root, "../escape.json"), /outside/i);
    assert.throws(
      () => adapter.resolveContainedPath(root, resolve(outside, "absolute.json")),
      /outside/i,
    );
    assert.throws(
      () => adapter.resolveContainedPath(root, resolve(prefixSibling, "confused.json")),
      /outside/i,
    );
    assert.throws(
      () => adapter.resolveContainedPath(root, "linked-outside/symlink.json"),
      /symlink/i,
    );
  } finally {
    await rm(sandbox, { recursive: true, force: true });
  }
});

test("rejects immutable and generated root aliasing while allowing a separated output", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.assertSeparatedOutputRoot, "function");

  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-paths-separation-"));
  const immutableRoot = resolve(sandbox, "scorecards");
  const nestedOutput = resolve(immutableRoot, "generated");
  const broadOutput = sandbox;
  const separatedOutput = resolve(sandbox, "critic-scores");

  try {
    await mkdir(nestedOutput, { recursive: true });
    await mkdir(separatedOutput);

    assert.throws(
      () => adapter.assertSeparatedOutputRoot(immutableRoot, [immutableRoot]),
      /overlap/i,
    );
    assert.throws(
      () => adapter.assertSeparatedOutputRoot(nestedOutput, [immutableRoot]),
      /overlap/i,
    );
    assert.throws(
      () => adapter.assertSeparatedOutputRoot(broadOutput, [immutableRoot]),
      /overlap/i,
    );
    assert.equal(
      adapter.assertSeparatedOutputRoot(separatedOutput, [immutableRoot]),
      await realpath(separatedOutput),
    );
  } finally {
    await rm(sandbox, { recursive: true, force: true });
  }
});

test("critic score and cache writers use contained atomic targets", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  const scorecardModule = await import("../critic/scorecard.js");
  const cacheModule = await import("../critic/cache.js");
  const scorecardSource = await readFile(
    resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/critic/scorecard.ts"),
    "utf8",
  );
  const cacheSource = await readFile(
    resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/critic/cache.ts"),
    "utf8",
  );

  assert.throws(
    () => scorecardModule.criticScorePath("../escape", "density", "signal_to_chrome"),
    /outside|traversal/i,
  );
  for (const [filename, source] of [
    ["scorecard.ts", scorecardSource],
    ["cache.ts", cacheSource],
  ] as const) {
    assert.match(source, /operator-surface-paths\.js/, `${filename} must import the adapter`);
    assert.match(source, /resolveContainedPath/, `${filename} must contain its target`);
    assert.match(source, /atomicWriteFile/, `${filename} must replace atomically`);
    assert.doesNotMatch(source, /writeFileSync/, `${filename} must not write destinations directly`);
  }

  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-critic-writers-"));
  const fixtureRoot = resolve(sandbox, "fixtures");
  const outputRoot = resolve(sandbox, "critic-scores");
  const outside = resolve(sandbox, "outside");
  await mkdir(fixtureRoot, { recursive: true });
  await mkdir(outputRoot);
  await mkdir(outside);

  const params = {
    cellId: "page.actor.happy__dark-1280",
    lens: "density" as const,
    dimension: "signal_to_chrome",
    modelId: "test-model",
    rubricVersion: "density@1.0.0+00000000",
    n: 3,
    scoresRaw: [70, 72, 74],
    score: 72,
    band: "strong",
    bandMode: "median",
    iqr: 2,
    range: 4,
    stable: true,
    pass: true,
    evidence: { kind: "region" as const, locator: "main", observation: "clear" },
    rationale: "test",
  };
  const cachedVerdict = {
    cell_id: params.cellId,
    dimension: params.dimension,
    rubric_hash: "00000000",
    model_id: params.modelId,
    screenshot_hash: "deadbeef",
    result: {
      evidence: params.evidence,
      pass: true,
      band: "strong" as const,
      score: 72,
      lens: "density" as const,
      rationale: "test",
    },
    n: 3,
    scores_raw: [70, 72, 74],
    score: 72,
    band: "strong",
    band_mode: "median",
    iqr: 2,
    range: 4,
    stable: true,
    cached_at: "2026-09-11T00:00:00Z",
  };

  try {
    adapter.configureOperatorSurfacePaths({ fixtureRoot, outputRoot });
    await symlink(outside, resolve(outputRoot, "linked"));
    assert.throws(
      () => scorecardModule.criticScorePath("linked", "density", params.dimension),
      /symlink/i,
    );

    scorecardModule.writeCriticScore(params);
    const scorePath = scorecardModule.criticScorePath(
      params.cellId,
      params.lens,
      params.dimension,
    );
    const originalScore = await readFile(scorePath, "utf8");
    assert.throws(
      () => scorecardModule.writeCriticScore(
        { ...params, rationale: "must not land" },
        { beforeRename: () => { throw new Error("forced score failure"); } },
      ),
      /forced score failure/,
    );
    assert.equal(await readFile(scorePath, "utf8"), originalScore);
    assert.deepEqual(
      (await readdir(dirname(scorePath))).filter((name) => name.includes(".tmp")),
      [],
    );

    cacheModule.writeCache(cachedVerdict);
    const cacheFiles = await readdir(adapter.currentOperatorSurfacePaths().verdictCacheDir);
    assert.equal(cacheFiles.length, 1);
    const cachePath = resolve(adapter.currentOperatorSurfacePaths().verdictCacheDir, cacheFiles[0]);
    const originalCache = await readFile(cachePath, "utf8");
    assert.throws(
      () => cacheModule.writeCache(
        { ...cachedVerdict, score: 73 },
        { beforeRename: () => { throw new Error("forced cache failure"); } },
      ),
      /forced cache failure/,
    );
    assert.equal(await readFile(cachePath, "utf8"), originalCache);
    assert.deepEqual(
      (await readdir(adapter.currentOperatorSurfacePaths().verdictCacheDir)).filter((name) => name.includes(".tmp")),
      [],
    );
    assert.throws(
      () => cacheModule.writeCache({ ...cachedVerdict, cell_id: "../escape" }),
      /outside|traversal/i,
    );

    assert.throws(
      () => adapter.reviewDiffCommand(resolve(fixtureRoot, "golden/golden-set.json")),
      /outside/i,
    );
  } finally {
    adapter.configureOperatorSurfacePaths({
      fixtureRoot: adapter.DEFAULT_OPERATOR_SURFACE_PATHS.fixtureRoot,
      outputRoot: adapter.DEFAULT_OPERATOR_SURFACE_PATHS.generatedRoot,
    });
    await rm(sandbox, { recursive: true, force: true });
  }

  const canonicalTarget = resolve(
    adapter.DEFAULT_OPERATOR_SURFACE_PATHS.goldenDir,
    "golden-set.json",
  );
  assert.equal(
    adapter.reviewDiffCommand(canonicalTarget),
    `git -C ${JSON.stringify(expectedRepositoryRoot)} diff -- ${JSON.stringify(relative(expectedRepositoryRoot, canonicalTarget))}`,
  );
});

test("atomic replacement writes complete bytes through a sibling temporary file", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.atomicWriteFile, "function");

  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-paths-atomic-"));
  const target = resolve(sandbox, "evidence.json");

  try {
    await writeFile(target, "original\n", "utf8");
    adapter.atomicWriteFile(target, "replacement\n");

    assert.equal(await readFile(target, "utf8"), "replacement\n");
    assert.deepEqual(await readdir(sandbox), ["evidence.json"]);
  } finally {
    await rm(sandbox, { recursive: true, force: true });
  }
});

test("atomic replacement preserves the target and removes its temporary file on failure", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.atomicWriteFile, "function");

  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-paths-atomic-failure-"));
  const target = resolve(sandbox, "evidence.json");

  try {
    await writeFile(target, "original\n", "utf8");

    assert.throws(
      () =>
        adapter.atomicWriteFile(target, "partial\n", {
          beforeRename: () => {
            throw new Error("forced rename failure");
          },
        }),
      /forced rename failure/,
    );

    assert.equal(await readFile(target, "utf8"), "original\n");
    assert.deepEqual(await readdir(sandbox), ["evidence.json"]);
  } finally {
    await rm(sandbox, { recursive: true, force: true });
  }
});
