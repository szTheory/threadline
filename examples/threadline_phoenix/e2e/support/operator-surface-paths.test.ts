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
  const nestedCwd = resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/support");

  try {
    process.chdir(expectedRepositoryRoot);
    const fromRoot = adapter.resolveOperatorSurfacePaths();
    process.chdir(nestedCwd);
    const fromNested = adapter.resolveOperatorSurfacePaths();

    assert.deepEqual(fromNested, fromRoot);
    assert.equal(fromRoot.repositoryRoot, expectedRepositoryRoot);
    assert.equal(fromRoot.ledgerPath, resolve(expectedRepositoryRoot, "test/fixtures/operator_surface/design-system-ledger.json"));
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
    await mkdir(resolve(worktreeRoot, "test/fixtures/operator_surface"), { recursive: true });
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
      worktreePaths.ledgerPath,
      resolve(canonicalWorktreeRoot, "test/fixtures/operator_surface/design-system-ledger.json"),
    );
    assert.equal(
      worktreePaths.generatedRoot,
      resolve(canonicalWorktreeRoot, "test/generated/operator_surface"),
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
    assert.equal(paths.ledgerPath, resolve(await realpath(fixtureRoot), "design-system-ledger.json"));
    assert.equal(paths.generatedRoot, await realpath(outputRoot));
    assert.equal(paths.routeScorecardsDir, resolve(await realpath(outputRoot), "route-scorecards"));
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
  const recoveryCommand = "npm run capture:pages";

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

test("a required dataset read fails closed rather than reporting an empty result", async () => {
  // Given a path that does not exist, the required reader must THROW. Returning
  // null, {} or [] is the specific failure mode that would let missing evidence
  // pass as a clean result.
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);

  const fixtureRoot = await mkdtemp(resolve(tmpdir(), "threadline-required-evidence-"));

  try {
    for (const dataset of ["scorecard", "refute set", "ledger"]) {
      const absent = resolve(fixtureRoot, `${dataset.replace(/\s+/g, "-")}.json`);
      let threw = false;

      try {
        adapter.readRequiredJson(absent, {
          dataset,
          repositoryOnly: true,
          recoveryCommand: "npm run capture:pages",
        });
      } catch {
        threw = true;
      }

      assert.equal(threw, true, `${dataset}: an absent required dataset did not fail closed`);
    }
  } finally {
    await rm(fixtureRoot, { recursive: true, force: true });
  }
});

test("e2e artifact targets cannot traverse out of the e2e root", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);

  assert.throws(
    () => adapter.resolveContainedPath(
      adapter.DEFAULT_OPERATOR_SURFACE_PATHS.e2eRoot,
      "artifacts/routes/../../../../hostile-output",
    ),
    /outside|traversal/i,
  );
});

test("every remaining capture consumer shares contained paths and immutable snapshots", async () => {
  const testsRoot = resolve(
    expectedRepositoryRoot,
    "examples/threadline_phoenix/e2e/tests",
  );
  const captureWriters = ["operator-page-capture.spec.ts"] as const;
  const consumers = [...captureWriters, "operator-stress.spec.ts"] as const;

  for (const filename of consumers) {
    const source = await readFile(resolve(testsRoot, filename), "utf8");
    assert.match(source, /operator-surface-paths\.js/, `${filename}: adapter import`);
    assert.match(source, /resolveContainedPath/, `${filename}: contained targets`);
    assert.doesNotMatch(source, /process\.cwd\(|\.planning\//, `${filename}: local path authority`);
  }

  for (const filename of captureWriters) {
    const source = await readFile(resolve(testsRoot, filename), "utf8");
    assert.match(source, /atomicWriteFile/, `${filename}: atomic evidence replacement`);
    assert.doesNotMatch(source, /writeFileSync/, `${filename}: direct evidence write`);
  }

  const stressSource = await readFile(resolve(testsRoot, "operator-stress.spec.ts"), "utf8");
  assert.match(stressSource, /tests\/operator-stress\.spec\.ts-snapshots/);
});

test("nondeterministic producers stay inside one generated boundary", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);

  const paths = adapter.DEFAULT_OPERATOR_SURFACE_PATHS;
  const generatedRoot = resolve(expectedRepositoryRoot, "test/generated/operator_surface");
  assert.equal(paths.generatedRoot, generatedRoot);
  assert.equal(paths.routeScorecardsDir, resolve(generatedRoot, "route-scorecards"));

  const pageCapture = await readFile(
    resolve(expectedRepositoryRoot, "examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts"),
    "utf8",
  );

  assert.match(pageCapture, /paths\.routeScorecardsDir/);
  assert.doesNotMatch(pageCapture, /const scorecardsDir = paths\.scorecardsDir/);
});

test("route scorecard readers enumerate the generated root exactly, without prefix confusion", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  const outputRoot = await mkdtemp(resolve(tmpdir(), "threadline-route-reader-"));
  const routeScorecardsDir = resolve(outputRoot, "route-scorecards");
  const cellId = "route.timeline__dark-1280";
  const variantCellId = "route.timeline.degraded__dark-1280";
  const prefixSiblingCellId = "route.timelineish__dark-1280";

  try {
    await mkdir(routeScorecardsDir, { recursive: true });
    await writeFile(resolve(routeScorecardsDir, `${cellId}.json`), "{}\n", "utf8");
    await writeFile(resolve(routeScorecardsDir, `${variantCellId}.json`), "{}\n", "utf8");
    await writeFile(resolve(routeScorecardsDir, `${prefixSiblingCellId}.json`), "{}\n", "utf8");
    adapter.configureOperatorSurfacePaths({ outputRoot });
    assert.deepEqual(adapter.routeScorecardCellIds(), [variantCellId, cellId, prefixSiblingCellId]);
    assert.equal(adapter.routeCellMatchesPage(cellId, "route.timeline"), true);
    assert.equal(adapter.routeCellMatchesPage(variantCellId, "route.timeline"), true);
    assert.equal(adapter.routeCellMatchesPage(prefixSiblingCellId, "route.timeline"), false);
    assert.deepEqual(adapter.readRouteScorecard(cellId), {});
    assert.throws(() => adapter.routeScorecardPath("route.unknown__dark-1280"), /Unknown route cell_id/);
  } finally {
    adapter.configureOperatorSurfacePaths({
      fixtureRoot: adapter.DEFAULT_OPERATOR_SURFACE_PATHS.fixtureRoot,
      outputRoot: adapter.DEFAULT_OPERATOR_SURFACE_PATHS.generatedRoot,
    });
    await rm(outputRoot, { recursive: true, force: true });
  }
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

test("resolves first-run output paths beneath a root that does not exist yet", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  assert.equal(typeof adapter.resolveContainedPath, "function");

  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-paths-first-run-"));
  const outputRoot = resolve(sandbox, "artifacts", "routes");

  try {
    const canonicalSandbox = await realpath(sandbox);
    const expectedRoot = resolve(canonicalSandbox, "artifacts", "routes");
    const cellRoot = adapter.resolveContainedPath(outputRoot, "timeline-density-dark-1280");

    assert.equal(cellRoot, resolve(expectedRoot, "timeline-density-dark-1280"));
    assert.equal(
      adapter.resolveContainedPath(cellRoot, "screenshot.png"),
      resolve(expectedRoot, "timeline-density-dark-1280", "screenshot.png"),
    );
    assert.throws(() => adapter.resolveContainedPath(outputRoot, "../escape.json"), /outside/i);
    assert.throws(
      () => adapter.resolveContainedPath(outputRoot, resolve(sandbox, "outside.json")),
      /outside/i,
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
  const separatedOutput = resolve(sandbox, "generated-output");

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

test("review diff commands stay contained in the repository", async () => {
  const adapter = await loadAdapter();
  assert.equal("loadError" in adapter, false, `adapter failed to load: ${String(adapter.loadError)}`);
  const sandbox = await mkdtemp(resolve(tmpdir(), "threadline-review-diff-"));

  try {
    assert.throws(() => adapter.reviewDiffCommand(resolve(sandbox, "outside.json")), /outside/i);
  } finally {
    await rm(sandbox, { recursive: true, force: true });
  }

  const canonicalTarget = adapter.DEFAULT_OPERATOR_SURFACE_PATHS.ledgerPath;
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
