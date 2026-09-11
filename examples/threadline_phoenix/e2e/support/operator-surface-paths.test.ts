import assert from "node:assert/strict";
import { copyFile, mkdir, mkdtemp, realpath, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const expectedRepositoryRoot = resolve(here, "../../../..");

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
