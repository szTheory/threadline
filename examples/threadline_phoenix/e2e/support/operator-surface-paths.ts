import { randomUUID } from "node:crypto";
import {
  closeSync,
  existsSync,
  fsyncSync,
  lstatSync,
  openSync,
  readFileSync,
  readdirSync,
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
  readonly tierAArtifactsDir: string;
  readonly fixtureRoot: string;
  readonly ledgerPath: string;
  readonly scorecardsDir: string;
  readonly goldenDir: string;
  readonly refuteDir: string;
  readonly generatedRoot: string;
  readonly routeScorecardsDir: string;
  readonly criticScoresDir: string;
  readonly verdictCacheDir: string;
  readonly refuteTranscriptsDir: string;
  readonly critiqueReportPath: string;
  readonly criticReportHtmlPath: string;
  readonly criticFloorsPath: string;
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
    overrides.fixtureRoot ?? resolve(repositoryRoot, "test/fixtures/operator_surface"),
  );
  const generatedRoot = canonicalizeExistingParent(
    overrides.outputRoot ?? resolve(repositoryRoot, "test/generated/operator_surface"),
  );

  const ledgerPath = resolve(fixtureRoot, "design-system-ledger.json");
  const scorecardsDir = resolve(fixtureRoot, "scorecards");
  const goldenDir = resolve(fixtureRoot, "golden");
  const refuteDir = resolve(fixtureRoot, "refute");
  const routeScorecardsDir = resolve(generatedRoot, "route-scorecards");
  const criticScoresDir = resolve(generatedRoot, "critic-scores");
  const verdictCacheDir = resolve(generatedRoot, "critic-verdict-cache");
  const refuteTranscriptsDir = resolve(generatedRoot, "refute-transcripts");
  const reportsDir = resolve(generatedRoot, "reports");
  const immutableRoots = [ledgerPath, scorecardsDir, goldenDir, refuteDir];
  assertSeparatedOutputRoot(generatedRoot, immutableRoots);

  return Object.freeze({
    repositoryRoot,
    e2eRoot: resolve(repositoryRoot, "examples/threadline_phoenix/e2e"),
    criticRubricsDir: resolve(repositoryRoot, "examples/threadline_phoenix/e2e/critic/rubrics"),
    tierAArtifactsDir: resolve(repositoryRoot, "examples/threadline_phoenix/e2e/artifacts/tier-a"),
    fixtureRoot,
    ledgerPath,
    scorecardsDir,
    goldenDir,
    refuteDir,
    generatedRoot,
    routeScorecardsDir,
    criticScoresDir,
    verdictCacheDir,
    refuteTranscriptsDir,
    critiqueReportPath: resolve(reportsDir, "CRITIQUE.md"),
    criticReportHtmlPath: resolve(reportsDir, "critic-report.html"),
    criticFloorsPath: resolve(reportsDir, "critic-floors.json"),
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
  const traversalSegments = candidate.split(/[\\/]+/);
  if (traversalSegments.includes("..")) {
    throw new Error(`Path is outside the permitted root (traversal): ${candidate}`);
  }

  const canonicalRoot = realpathSync(resolve(root));
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

const processRootOverrides = parseOperatorSurfaceRootFlags(process.argv.slice(2)).overrides;
export const DEFAULT_OPERATOR_SURFACE_PATHS = resolveOperatorSurfacePaths(processRootOverrides);
let activeOperatorSurfacePaths = DEFAULT_OPERATOR_SURFACE_PATHS;

export function configureOperatorSurfacePaths(
  overrides: OperatorSurfaceRootOverrides,
): Readonly<OperatorSurfacePaths> {
  activeOperatorSurfacePaths = resolveOperatorSurfacePaths(overrides);
  return activeOperatorSurfacePaths;
}

export function currentOperatorSurfacePaths(): Readonly<OperatorSurfacePaths> {
  return activeOperatorSurfacePaths;
}

/**
 * Enumerate live route scorecards from the adapter-owned generated root.
 * Committed/golden/synthetic readers intentionally do not use this lane.
 */
export function routeScorecardCellIds(): string[] {
  const { generatedRoot, routeScorecardsDir } = currentOperatorSurfacePaths();
  if (!existsSync(routeScorecardsDir)) return [];

  const containedRoot = resolveContainedPath(generatedRoot, routeScorecardsDir);
  return readdirSync(containedRoot)
    .filter((filename) => filename.startsWith("route.") && filename.endsWith(".json"))
    .map((filename) => filename.replace(/\.json$/, ""))
    .sort();
}

/** Match one route page and its dot-qualified variants without prefix confusion. */
export function routeCellMatchesPage(cellId: string, page: string): boolean {
  const cellDelimiter = cellId.indexOf("__");
  if (cellDelimiter < 1) return false;

  const ledgerId = cellId.slice(0, cellDelimiter);
  return ledgerId === page || ledgerId.startsWith(`${page}.`);
}

/** Resolve one live route scorecard only after exact adapter-owned enumeration. */
export function routeScorecardPath(cellId: string): string {
  const { routeScorecardsDir } = currentOperatorSurfacePaths();
  if (!routeScorecardCellIds().includes(cellId)) {
    throw new Error(
      `Unknown route cell_id: ${JSON.stringify(cellId)} — not found in ${routeScorecardsDir}. ` +
        `Refusing to construct a generated evidence path from untrusted input.`,
    );
  }

  return resolveContainedPath(routeScorecardsDir, `${cellId}.json`);
}

/** Read one live route scorecard only after exact adapter-owned enumeration. */
export function readRouteScorecard<T = unknown>(cellId: string): T {
  return readRequiredJson<T>(routeScorecardPath(cellId), {
    dataset: `generated route scorecard ${cellId}`,
    repositoryOnly: false,
    recoveryCommand: "npm run capture:pages",
  });
}

export function reviewDiffCommand(targetPath: string): string {
  const { repositoryRoot } = currentOperatorSurfacePaths();
  const containedTarget = resolveContainedPath(repositoryRoot, targetPath);
  return `git -C ${JSON.stringify(repositoryRoot)} diff -- ${JSON.stringify(relative(repositoryRoot, containedTarget))}`;
}
export const IMMUTABLE_EVIDENCE_ROOTS = Object.freeze([
  DEFAULT_OPERATOR_SURFACE_PATHS.ledgerPath,
  DEFAULT_OPERATOR_SURFACE_PATHS.scorecardsDir,
  DEFAULT_OPERATOR_SURFACE_PATHS.goldenDir,
  DEFAULT_OPERATOR_SURFACE_PATHS.refuteDir,
]);
export const GENERATED_EVIDENCE_ROOT = DEFAULT_OPERATOR_SURFACE_PATHS.generatedRoot;
