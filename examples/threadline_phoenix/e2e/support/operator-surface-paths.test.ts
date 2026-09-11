import assert from "node:assert/strict";
import { copyFile, mkdir, mkdtemp, rm } from "node:fs/promises";
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
    await copyFile(resolve(here, "operator-surface-paths.ts"), copiedModule);
    const worktreeAdapter = await loadAdapter(pathToFileURL(copiedModule));
    assert.equal(
      "loadError" in worktreeAdapter,
      false,
      `worktree adapter failed to load: ${String(worktreeAdapter.loadError)}`,
    );

    const worktreePaths = worktreeAdapter.resolveOperatorSurfacePaths();
    assert.equal(worktreePaths.repositoryRoot, worktreeRoot);
    assert.equal(worktreePaths.scorecardsDir, resolve(worktreeRoot, ".planning/scorecards"));
  } finally {
    await rm(worktreeRoot, { recursive: true, force: true });
  }
});
