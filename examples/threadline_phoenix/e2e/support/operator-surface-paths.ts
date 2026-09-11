import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const moduleDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(moduleDirectory, "../../../..");

export interface OperatorSurfacePaths {
  readonly repositoryRoot: string;
  readonly fixtureRoot: string;
  readonly ledgerPath: string;
  readonly scorecardsDir: string;
  readonly goldenDir: string;
  readonly refuteDir: string;
  readonly generatedRoot: string;
  readonly criticScoresDir: string;
}

export function resolveOperatorSurfacePaths(): Readonly<OperatorSurfacePaths> {
  const fixtureRoot = resolve(repositoryRoot, ".planning");
  const generatedRoot = fixtureRoot;

  return Object.freeze({
    repositoryRoot,
    fixtureRoot,
    ledgerPath: resolve(fixtureRoot, "design-system-ledger.json"),
    scorecardsDir: resolve(fixtureRoot, "scorecards"),
    goldenDir: resolve(fixtureRoot, "golden"),
    refuteDir: resolve(fixtureRoot, "refute"),
    generatedRoot,
    criticScoresDir: resolve(generatedRoot, "critic-scores"),
  });
}
