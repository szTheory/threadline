import { randomUUID } from "node:crypto";
import {
  closeSync,
  existsSync,
  fsyncSync,
  lstatSync,
  openSync,
  readFileSync,
  realpathSync,
  renameSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const moduleDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(moduleDirectory, "../../../..");

export interface OperatorSurfacePaths {
  readonly repositoryRoot: string;
  readonly e2eRoot: string;
  readonly criticRubricsDir: string;
  readonly fixtureRoot: string;
  readonly ledgerPath: string;
  readonly scorecardsDir: string;
  readonly goldenDir: string;
  readonly refuteDir: string;
  readonly generatedRoot: string;
  readonly criticScoresDir: string;
}

export interface OperatorSurfaceRootOverrides {
  readonly fixtureRoot?: string;
  readonly outputRoot?: string;
}

export interface RequiredJsonContext {
  readonly dataset: string;
  readonly repositoryOnly: boolean;
  readonly recoveryCommand: string;
}

export interface AtomicWriteOptions {
  readonly beforeRename?: (temporaryPath: string, targetPath: string) => void;
}

function isOutside(root: string, candidate: string): boolean {
  const rel = relative(root, candidate);
  return rel === ".." || rel.startsWith(`..${sep}`) || isAbsolute(rel);
}

function canonicalizeExistingParent(path: string): string {
  const absolutePath = resolve(path);
  let existing = absolutePath;

  while (!existsSync(existing)) {
    const parent = dirname(existing);
    if (parent === existing) {
      throw new Error(`No existing parent found for path: ${absolutePath}`);
    }
    existing = parent;
  }

  const canonicalExisting = realpathSync(existing);
  return existing === absolutePath
    ? canonicalExisting
    : resolve(canonicalExisting, relative(existing, absolutePath));
}

export function resolveOperatorSurfacePaths(
  overrides: OperatorSurfaceRootOverrides = {},
): Readonly<OperatorSurfacePaths> {
  const fixtureRoot = canonicalizeExistingParent(
    overrides.fixtureRoot ?? resolve(repositoryRoot, ".planning"),
  );
  const generatedRoot = canonicalizeExistingParent(
    overrides.outputRoot ?? resolve(repositoryRoot, ".planning/critic-scores"),
  );

  const ledgerPath = resolve(fixtureRoot, "design-system-ledger.json");
  const scorecardsDir = resolve(fixtureRoot, "scorecards");
  const goldenDir = resolve(fixtureRoot, "golden");
  const refuteDir = resolve(fixtureRoot, "refute");
  assertSeparatedOutputRoot(generatedRoot, [ledgerPath, scorecardsDir, goldenDir, refuteDir]);

  return Object.freeze({
    repositoryRoot,
    e2eRoot: resolve(repositoryRoot, "examples/threadline_phoenix/e2e"),
    criticRubricsDir: resolve(repositoryRoot, "examples/threadline_phoenix/e2e/critic/rubrics"),
    fixtureRoot,
    ledgerPath,
    scorecardsDir,
    goldenDir,
    refuteDir,
    generatedRoot,
    criticScoresDir: generatedRoot,
  });
}

export function parseOperatorSurfaceRootFlags(argv: readonly string[]): Readonly<{
  overrides: Readonly<OperatorSurfaceRootOverrides>;
  rest: readonly string[];
}> {
  const overrides: { fixtureRoot?: string; outputRoot?: string } = {};
  const rest: string[] = [];

  for (let index = 0; index < argv.length; index++) {
    const flag = argv[index];
    if (flag !== "--fixture-root" && flag !== "--output-root") {
      rest.push(flag);
      continue;
    }

    const value = argv[++index];
    if (!value || value.startsWith("--")) {
      throw new Error(`${flag} requires a path value`);
    }

    if (flag === "--fixture-root") overrides.fixtureRoot = value;
    else overrides.outputRoot = value;
  }

  return Object.freeze({ overrides: Object.freeze(overrides), rest: Object.freeze(rest) });
}

export function resolveContainedPath(root: string, candidate: string): string {
  const canonicalRoot = realpathSync(resolve(root));
  const traversalSegments = candidate.split(/[\\/]+/);
  if (traversalSegments.includes("..")) {
    throw new Error(`Path is outside the permitted root (traversal): ${candidate}`);
  }

  const absoluteCandidate = isAbsolute(candidate)
    ? resolve(candidate)
    : resolve(canonicalRoot, candidate);
  if (isOutside(canonicalRoot, absoluteCandidate)) {
    throw new Error(
      `Path is outside the permitted root. Root: ${canonicalRoot}; candidate: ${absoluteCandidate}`,
    );
  }

  const lexicalRelative = relative(canonicalRoot, absoluteCandidate);
  let cursor = canonicalRoot;
  for (const segment of lexicalRelative.split(sep).filter(Boolean)) {
    cursor = join(cursor, segment);
    if (existsSync(cursor) && lstatSync(cursor).isSymbolicLink()) {
      throw new Error(`Path crosses a symlink and is not permitted: ${cursor}`);
    }
  }

  const canonicalCandidate = canonicalizeExistingParent(absoluteCandidate);
  if (isOutside(canonicalRoot, canonicalCandidate)) {
    throw new Error(
      `Path resolves outside the permitted root. Root: ${canonicalRoot}; candidate: ${canonicalCandidate}`,
    );
  }

  return canonicalCandidate;
}

export function assertSeparatedOutputRoot(
  outputRoot: string,
  immutableRoots: readonly string[],
): string {
  const canonicalOutput = canonicalizeExistingParent(outputRoot);

  for (const immutableRoot of immutableRoots) {
    const canonicalImmutable = canonicalizeExistingParent(immutableRoot);
    if (
      canonicalOutput === canonicalImmutable ||
      !isOutside(canonicalImmutable, canonicalOutput) ||
      !isOutside(canonicalOutput, canonicalImmutable)
    ) {
      throw new Error(
        `Generated output root overlaps immutable evidence. Output: ${canonicalOutput}; immutable: ${canonicalImmutable}`,
      );
    }
  }

  return canonicalOutput;
}

export function atomicWriteFile(
  targetPath: string,
  data: string | Uint8Array,
  options: AtomicWriteOptions = {},
): void {
  const absoluteTarget = resolve(targetPath);
  const temporaryPath = resolve(
    dirname(absoluteTarget),
    `.${basename(absoluteTarget)}.${process.pid}.${randomUUID()}.tmp`,
  );
  let descriptor: number | undefined;

  try {
    descriptor = openSync(temporaryPath, "wx", 0o600);
    writeFileSync(descriptor, data);
    fsyncSync(descriptor);
    closeSync(descriptor);
    descriptor = undefined;

    options.beforeRename?.(temporaryPath, absoluteTarget);
    renameSync(temporaryPath, absoluteTarget);
  } finally {
    try {
      if (descriptor !== undefined) closeSync(descriptor);
    } finally {
      if (existsSync(temporaryPath)) unlinkSync(temporaryPath);
    }
  }
}

export function readRequiredJson<T = unknown>(
  filePath: string,
  context: RequiredJsonContext,
): T {
  const resolvedPath = resolve(filePath);
  const diagnostic = (state: "unavailable" | "invalid", detail: string) =>
    new Error(
      `${context.dataset} is ${state}.\n` +
        `Resolved path: ${resolvedPath}\n` +
        `repository-only: ${context.repositoryOnly}\n` +
        `Recovery: ${context.recoveryCommand}\n` +
        `Cause: ${detail}`,
    );

  let source: string;
  try {
    source = readFileSync(resolvedPath, "utf8");
  } catch (error) {
    throw diagnostic("unavailable", String(error));
  }

  try {
    return JSON.parse(source) as T;
  } catch (error) {
    throw diagnostic("invalid", String(error));
  }
}

export const DEFAULT_OPERATOR_SURFACE_PATHS = resolveOperatorSurfacePaths();
export const IMMUTABLE_EVIDENCE_ROOTS = Object.freeze([
  DEFAULT_OPERATOR_SURFACE_PATHS.ledgerPath,
  DEFAULT_OPERATOR_SURFACE_PATHS.scorecardsDir,
  DEFAULT_OPERATOR_SURFACE_PATHS.goldenDir,
  DEFAULT_OPERATOR_SURFACE_PATHS.refuteDir,
]);
export const GENERATED_EVIDENCE_ROOT = DEFAULT_OPERATOR_SURFACE_PATHS.generatedRoot;
