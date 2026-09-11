import { readFileSync, realpathSync } from "node:fs";
import { dirname, resolve } from "node:path";
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

function canonicalRoot(path: string): string {
  return realpathSync(resolve(path));
}

export function resolveOperatorSurfacePaths(
  overrides: OperatorSurfaceRootOverrides = {},
): Readonly<OperatorSurfacePaths> {
  const fixtureRoot = canonicalRoot(overrides.fixtureRoot ?? resolve(repositoryRoot, ".planning"));
  const generatedRoot = canonicalRoot(
    overrides.outputRoot ?? resolve(repositoryRoot, ".planning/critic-scores"),
  );

  return Object.freeze({
    repositoryRoot,
    e2eRoot: resolve(repositoryRoot, "examples/threadline_phoenix/e2e"),
    criticRubricsDir: resolve(repositoryRoot, "examples/threadline_phoenix/e2e/critic/rubrics"),
    fixtureRoot,
    ledgerPath: resolve(fixtureRoot, "design-system-ledger.json"),
    scorecardsDir: resolve(fixtureRoot, "scorecards"),
    goldenDir: resolve(fixtureRoot, "golden"),
    refuteDir: resolve(fixtureRoot, "refute"),
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
