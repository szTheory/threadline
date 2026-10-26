import { readFileSync, statSync, writeFileSync } from "node:fs";
import { parseArgs } from "node:util";

export interface OperatorJourneyIdentity {
  readonly file: string;
  readonly titlePath: readonly string[];
  readonly project: string;
}

interface InventoryRow {
  readonly category: string;
  readonly requirement: string;
  readonly journey: string;
  readonly failureClass: string;
  readonly voting: "required" | "nonvoting";
  readonly reason?: string;
  readonly identity: OperatorJourneyIdentity;
}

interface Inventory {
  readonly schemaVersion: 1;
  readonly votingProjects: readonly string[];
  readonly rows: readonly InventoryRow[];
}

interface ExecutedIdentity extends OperatorJourneyIdentity {
  readonly status: string;
  readonly attempts: number;
}

const MAX_REPORT_BYTES = 20 * 1024 * 1024;
const SAFE_NAME = /^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$/;

export function identityKey(identity: OperatorJourneyIdentity): string {
  if (!identity || !SAFE_NAME.test(identity.project) || typeof identity.file !== "string" ||
      identity.file.length === 0 || identity.file.startsWith("/") || identity.file.includes("..") ||
      !Array.isArray(identity.titlePath) || identity.titlePath.length === 0 ||
      identity.titlePath.some((title) => typeof title !== "string" || title.length === 0)) {
    throw new Error("invalid journey identity");
  }

  const file = identity.file.replaceAll("\\", "/").replace(/^\.\//, "");
  return JSON.stringify([identity.project, file, identity.titlePath]);
}

export function parseDiscovered(output: string): OperatorJourneyIdentity[] {
  if (output.length === 0 || output.length > MAX_REPORT_BYTES) throw new Error("missing or oversized discovered report");
  const identities: OperatorJourneyIdentity[] = [];

  for (const line of output.split(/\r?\n/)) {
    const match = line.match(/^\s*\[([^\]]+)\] › (.+?):\d+:\d+ › (.+)$/);
    if (!match) continue;
    const [, project, file, titles] = match;
    identities.push({ project, file: file.replaceAll("\\", "/"), titlePath: titles.split(" › ") });
  }

  if (identities.length === 0) throw new Error("discovered report contains zero Playwright tests");
  return identities;
}

function object(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} is malformed`);
  return value as Record<string, unknown>;
}

export function parseExecuted(value: unknown): ExecutedIdentity[] {
  const report = object(value, "executed report");
  if (!Array.isArray(report.suites) || report.suites.length === 0) throw new Error("executed report contains zero suites");
  const identities: ExecutedIdentity[] = [];

  const visit = (suiteValue: unknown, parentTitles: string[], inheritedFile: string) => {
    const suite = object(suiteValue, "executed suite");
    const title = typeof suite.title === "string" ? suite.title : "";
    const file = typeof suite.file === "string" && suite.file ? suite.file.replaceAll("\\", "/") : inheritedFile;
    const isFileSuite = title === file.split("/").at(-1);
    const titlePath = title && !isFileSuite ? [...parentTitles, title] : parentTitles;

    if (Array.isArray(suite.specs)) {
      for (const specValue of suite.specs) {
        const spec = object(specValue, "executed spec");
        if (typeof spec.title !== "string" || !spec.title || !Array.isArray(spec.tests)) {
          throw new Error("executed spec has no title or test results");
        }
        const specFile = (typeof spec.file === "string" && spec.file ? spec.file : file)
          .replaceAll("\\", "/")
          .replace(/^tests\//, "");
        for (const testValue of spec.tests) {
          const test = object(testValue, "executed test");
          const project = typeof test.projectName === "string" ? test.projectName : "";
          const results = Array.isArray(test.results) ? test.results : [];
          const attempts = results.length;
          const expectedStatus = typeof test.expectedStatus === "string" ? test.expectedStatus : "passed";
          let status = "skipped";
          if (expectedStatus !== "skipped" && attempts > 0) {
            status = attempts > 1 ? "retried" : String(object(results[0], "executed result").status ?? "unknown");
          }
          identities.push({
            project,
            file: specFile,
            titlePath: [...titlePath, spec.title],
            status,
            attempts,
          });
        }
      }
    }

    if (Array.isArray(suite.suites)) {
      for (const child of suite.suites) visit(child, titlePath, file);
    }
  };

  for (const suite of report.suites) visit(suite, [], "");
  if (identities.length === 0) throw new Error("executed report contains zero tests");
  return identities;
}

export function parseExecutedJson(raw: string): ExecutedIdentity[] {
  if (!raw || raw.length > MAX_REPORT_BYTES) throw new Error("missing or oversized executed report");
  return parseExecuted(JSON.parse(raw));
}

function uniqueIndex<T extends OperatorJourneyIdentity>(items: readonly T[], label: string): Map<string, T> {
  const index = new Map<string, T>();
  for (const item of items) {
    const key = identityKey(item);
    if (index.has(key)) throw new Error(`${label} contains duplicate journey identity: ${key}`);
    index.set(key, item);
  }
  return index;
}

function parseInventory(value: unknown): Inventory {
  const inventory = object(value, "inventory") as unknown as Inventory;
  if (inventory.schemaVersion !== 1 || !Array.isArray(inventory.votingProjects) ||
      !Array.isArray(inventory.rows) || inventory.rows.length === 0) throw new Error("inventory is malformed or empty");
  if (new Set(inventory.votingProjects).size !== inventory.votingProjects.length ||
      inventory.votingProjects.some((project) => !SAFE_NAME.test(project))) throw new Error("inventory voting projects are invalid");
  for (const row of inventory.rows) {
    if (!row || !row.category || !row.requirement || !row.journey || !row.failureClass ||
        !["required", "nonvoting"].includes(row.voting)) {
      throw new Error("inventory row is malformed");
    }
    if (row.voting === "nonvoting" && !row.reason) throw new Error("nonvoting inventory row requires a reason");
    identityKey(row.identity);
    if (row.voting === "required" && !inventory.votingProjects.includes(row.identity.project)) {
      throw new Error("required journey project is outside the voting project set");
    }
  }
  uniqueIndex(inventory.rows.filter((row) => row.voting === "required").map((row) => row.identity), "inventory");
  return inventory;
}

export function validateEvidence(
  inventoryValue: unknown,
  discovered: readonly OperatorJourneyIdentity[],
  executed: readonly ExecutedIdentity[],
  metadata: { readonly githubSha: string; readonly githubRunId: string },
) {
  const inventory = parseInventory(inventoryValue);
  if (!/^[a-f0-9]{40,64}$/i.test(metadata.githubSha)) throw new Error("GITHUB_SHA is invalid");
  if (!/^[1-9][0-9]{0,19}$/.test(metadata.githubRunId)) throw new Error("GITHUB_RUN_ID is invalid");
  const votingProjects = new Set(inventory.votingProjects);
  if (discovered.some((item) => !votingProjects.has(item.project))) throw new Error("discovered report includes an unexpected project");
  if (executed.some((item) => !votingProjects.has(item.project))) throw new Error("executed report includes an unexpected project");

  const discoveredById = uniqueIndex(discovered, "discovered report");
  const executedById = uniqueIndex(executed, "executed report");
  const required = inventory.rows.filter((row) => row.voting === "required");
  if (required.length === 0) throw new Error("inventory contains zero required journeys");

  const identities = required.map((row) => {
    const key = identityKey(row.identity);
    if (!discoveredById.has(key)) throw new Error(`required journey was not discovered: ${row.journey}`);
    const result = executedById.get(key);
    if (!result) throw new Error(`required journey was not executed: ${row.journey}`);
    if (result.status !== "passed" || result.attempts !== 1) {
      throw new Error(`required journey did not pass exactly once without retry (${result.status}): ${row.journey}`);
    }
    return { identity: row.identity, status: "passed" as const, attempts: 1 };
  });

  return {
    schemaVersion: 1 as const,
    githubSha: metadata.githubSha,
    githubRunId: metadata.githubRunId,
    jobId: "verify-example-browser" as const,
    projects: inventory.votingProjects,
    counts: { expected: required.length, discovered: identities.length, executed: identities.length, passed: identities.length },
    identities,
  };
}

const USAGE = [
  "usage: operator-ci-evidence.ts --verify inventory --discovered discovered-list... --executed executed-json... output-receipt",
  "usage: operator-ci-evidence.ts --verify inventory discovered-json executed-json output-receipt",
].join("\n");

interface EvidenceInputs {
  readonly inventoryPath: string;
  readonly discoveredPaths: readonly string[];
  readonly executedPaths: readonly string[];
  readonly receiptPath: string;
}

// D-07a: the fan-in job passes one --discovered and one --executed file per matrix
// leg. The legacy four-positional form stays valid for the single-job ci.yml.
function evidenceInputs(args: string[]): EvidenceInputs {
  if (args[0] !== "--verify") throw new Error(USAGE);
  const rest = args.slice(1);

  if (!rest.some((arg) => arg.startsWith("--"))) {
    if (rest.length !== 4) throw new Error(USAGE);
    const [inventoryPath, discoveredPath, executedPath, receiptPath] = rest;
    return { inventoryPath, discoveredPaths: [discoveredPath], executedPaths: [executedPath], receiptPath };
  }

  let parsed;
  try {
    parsed = parseArgs({
      args: rest,
      allowPositionals: true,
      strict: true,
      options: {
        discovered: { type: "string", multiple: true },
        executed: { type: "string", multiple: true },
      },
    });
  } catch (error) {
    throw new Error(`${error instanceof Error ? error.message : "invalid arguments"}\n${USAGE}`);
  }
  const discoveredPaths = parsed.values.discovered ?? [];
  const executedPaths = parsed.values.executed ?? [];
  if (parsed.positionals.length !== 2 || discoveredPaths.length === 0 || executedPaths.length === 0) {
    throw new Error(USAGE);
  }
  const [inventoryPath, receiptPath] = parsed.positionals;
  return { inventoryPath, discoveredPaths, executedPaths, receiptPath };
}

function main(args: string[]) {
  const { inventoryPath, discoveredPaths, executedPaths, receiptPath } = evidenceInputs(args);
  for (const path of [inventoryPath, ...discoveredPaths, ...executedPaths]) {
    if (statSync(path).size > MAX_REPORT_BYTES) throw new Error(`${path} exceeds the report size limit`);
  }
  const inventory = JSON.parse(readFileSync(inventoryPath, "utf8"));
  const discovered = discoveredPaths.flatMap((path) => parseDiscovered(readFileSync(path, "utf8")));
  const executed = executedPaths.flatMap((path) => parseExecutedJson(readFileSync(path, "utf8")));
  const receipt = validateEvidence(inventory, discovered, executed, {
    githubSha: process.env.GITHUB_SHA ?? "",
    githubRunId: process.env.GITHUB_RUN_ID ?? "",
  });
  writeFileSync(receiptPath, `${JSON.stringify(receipt, null, 2)}\n`, { flag: "wx" });
  console.log(`Validated ${receipt.counts.passed} named journeys across ${receipt.projects.join(", ")}.`);
}

if (process.argv[1]?.endsWith("operator-ci-evidence.ts")) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : "operator CI evidence validation failed");
    process.exitCode = 1;
  }
}
