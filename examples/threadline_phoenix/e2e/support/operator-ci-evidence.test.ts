import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, truncateSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { identityKey, parseDiscovered, parseExecuted, parseExecutedJson, validateEvidence, type OperatorJourneyIdentity } from "./operator-ci-evidence.js";

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
const projects = ["desktop-chromium", "mobile-chromium"] as const;
const file = "operator-timeline-investigation-flow.spec.ts";
const titlePath = [
  "Timeline investigation flow browser proof",
  "starts at Home, applies a Timeline query, and opens its transaction",
];
const identity = (project: string): OperatorJourneyIdentity => ({ file, titlePath, project });
const inventory = {
  schemaVersion: 1 as const,
  votingProjects: projects,
  rows: projects.map((project) => ({
    category: "investigation",
    requirement: "UIV-01",
    journey: "Home to Timeline transaction investigation",
    failureClass: "missing-or-retry-only-journey",
    voting: "required" as const,
    identity: identity(project),
  })),
};

function report(status = "passed", attempts = 1, expectedStatus = "passed") {
  return {
    suites: projects.map((project) => ({
      title: file,
      file,
      suites: [{
        title: titlePath[0],
        file: `tests/${file}`,
        specs: [{
          title: titlePath[1],
          tests: [{
            projectName: project,
            expectedStatus,
            results: Array.from({ length: attempts }, (_, retry) => ({
              status: retry + 1 === attempts ? status : "failed",
              retry,
            })),
          }],
        }],
      }],
    })),
  };
}

test("journey identity includes project, file, and complete title path", () => {
  assert.equal(
    identityKey(identity("desktop-chromium")),
    JSON.stringify(["desktop-chromium", file, titlePath]),
  );
});

test("native reporter file suites do not become part of the title path", () => {
  const executed = parseExecuted(report());
  assert.deepEqual(executed.map(({ project, file: executedFile, titlePath: executedTitlePath }) => ({
    project,
    file: executedFile,
    titlePath: executedTitlePath,
  })), projects.map((project) => ({ project, file, titlePath })));
});

test("required inventory names every supported journey and material failure class", () => {
  const checkedIn = JSON.parse(readFileSync(resolve(repositoryRoot, "examples/threadline_phoenix/e2e/support/operator-journey-inventory.json"), "utf8"));
  const categories = new Set(checkedIn.rows.filter((row: { voting: string }) => row.voting === "required").map((row: { category?: string }) => row.category));
  for (const category of [
    "investigation", "actor-correlation", "saved-search", "evidence", "coverage-redaction",
    "export-download-return", "retention", "disconnect-reconnect", "accessibility-responsive",
    "reduced-motion", "desktop-zoom",
  ]) assert.ok(categories.has(category), `required inventory is missing ${category}`);

  const nonvoting = checkedIn.rows.filter((row: { voting: string }) => row.voting === "nonvoting");
  for (const label of ["light/System", "browser-full", "mobile zoom", "browser limitation"]) {
    assert.ok(nonvoting.some((row: { reason?: string }) => row.reason?.toLowerCase().includes(label.toLowerCase())), `missing explicit nonvoting reason for ${label}`);
  }
});

test("renamed file or title no longer satisfies the expected identity", () => {
  const discovered = projects.map((project) => identity(project));
  const executed = parseExecuted(report());
  assert.throws(() => validateEvidence(inventory, discovered.map((item) => ({ ...item, file: "renamed.spec.ts" })), executed, { githubSha: "a".repeat(40), githubRunId: "123" }), /not discovered/i);
  assert.throws(() => validateEvidence(inventory, discovered.map((item) => ({ ...item, titlePath: [titlePath[0], "renamed title"] })), executed, { githubSha: "a".repeat(40), githubRunId: "123" }), /not discovered/i);
});

test("filtered projects, duplicate identities, and unexpected projects fail closed", () => {
  const valid = projects.map((project) => identity(project));
  const executed = parseExecuted(report());
  assert.throws(() => validateEvidence(inventory, valid.slice(0, 1), executed, { githubSha: "a".repeat(40), githubRunId: "123" }), /not discovered/i);
  assert.throws(() => validateEvidence(inventory, [...valid, valid[0]], executed, { githubSha: "a".repeat(40), githubRunId: "123" }), /duplicate/i);
  assert.throws(() => validateEvidence(inventory, [...valid, { ...valid[0], project: "firefox" }], executed, { githubSha: "a".repeat(40), githubRunId: "123" }), /unexpected project/i);
});

test("missing, malformed, zero-test, and skipped executed reports fail closed", () => {
  assert.throws(() => parseExecuted({ suites: [] }), /zero suites/i);
  assert.throws(() => parseExecuted({ suites: [{ title: "", specs: [], suites: [] }] }), /zero tests/i);
  assert.throws(() => parseExecutedJson(""), /missing/i);
  assert.throws(() => parseExecutedJson("{ truncated"), /JSON|property/i);
  assert.throws(() => validateEvidence(inventory, projects.map(identity), parseExecuted(report("skipped")), { githubSha: "a".repeat(40), githubRunId: "123" }), /did not pass/i);
  assert.throws(() => validateEvidence(inventory, projects.map(identity), parseExecuted(report("skipped", 0, "skipped")), { githubSha: "a".repeat(40), githubRunId: "123" }), /did not pass/i);
});

test("failed and retry-passed required tests do not count as green evidence", () => {
  assert.throws(() => validateEvidence(inventory, projects.map(identity), parseExecuted(report("failed")), { githubSha: "a".repeat(40), githubRunId: "123" }), /did not pass/i);
  assert.throws(() => validateEvidence(inventory, projects.map(identity), parseExecuted(report("passed", 2)), { githubSha: "a".repeat(40), githubRunId: "123" }), /retried/i);
});

test("receipt rejects forged run identity and contains only allowlisted synthetic fields", () => {
  const discovered = projects.map((project) => identity(project));
  const executed = parseExecuted(report());
  for (const metadata of [
    { githubSha: "forged", githubRunId: "123" },
    { githubSha: "a".repeat(40), githubRunId: "0" },
    { githubSha: "a".repeat(40), githubRunId: "123\nGITHUB_RUN_ID=456" },
  ]) assert.throws(() => validateEvidence(inventory, discovered, executed, metadata), /GITHUB_/i);

  const receipt = validateEvidence(inventory, discovered, executed, { githubSha: "a".repeat(40), githubRunId: "123" });
  assert.deepEqual(Object.keys(receipt).sort(), ["counts", "githubRunId", "githubSha", "identities", "jobId", "projects", "schemaVersion"].sort());
  assert.deepEqual(Object.keys(receipt.identities[0]).sort(), ["attempts", "identity", "status"]);
  assert.equal(JSON.stringify(receipt).toLowerCase().includes("attachment"), false);
  assert.equal(JSON.stringify(receipt).toLowerCase().includes("cookie"), false);
});

test("reporter-supplied run metadata cannot override the trusted workflow identity", () => {
  const untrusted = { ...report(), GITHUB_SHA: "f".repeat(40), GITHUB_RUN_ID: "999", cookie: "synthetic-canary" };
  const receipt = validateEvidence(inventory, projects.map(identity), parseExecuted(untrusted), {
    githubSha: "a".repeat(40),
    githubRunId: "123",
  });
  assert.equal(receipt.githubSha, "a".repeat(40));
  assert.equal(receipt.githubRunId, "123");
  assert.equal(JSON.stringify(receipt).includes("synthetic-canary"), false);
});

test("native Playwright list and executed JSON prove both voting projects", () => {
  const listed = projects.map((project) =>
    `  [${project}] › ${file}:660:3 › ${titlePath.join(" › ")}`,
  ).join("\n");
  const discovered = parseDiscovered(`Listing tests:\n${listed}\nTotal: 2 tests in 1 file\n`);
  const executed = parseExecuted(report());
  const receipt = validateEvidence(inventory, discovered, executed, {
    githubSha: "a".repeat(40),
    githubRunId: "123456789",
  });

  assert.deepEqual(receipt.projects, projects);
  assert.deepEqual(receipt.counts, { expected: 2, discovered: 2, executed: 2, passed: 2 });
  assert.equal(receipt.jobId, "verify-example-browser");
  assert.deepEqual(receipt.identities.map((item) => item.identity), projects.map(identity));
  assert.equal(JSON.stringify(receipt).includes("attachments"), false);
});

// D-07a: the fan-in job reconciles one discovered/executed pair per matrix leg.
// These cases drive the real CLI under plain `node --experimental-strip-types`
// (no tsx), which is how the fan-in job runs it without `npm ci`.
const script = resolve(dirname(fileURLToPath(import.meta.url)), "operator-ci-evidence.ts");
const trustedEnv = { GITHUB_SHA: "a".repeat(40), GITHUB_RUN_ID: "123456789" };

function legDiscovered(project: string): string {
  return `Listing tests:\n  [${project}] › ${file}:660:3 › ${titlePath.join(" › ")}\nTotal: 1 test in 1 file\n`;
}

function legExecuted(project: string): string {
  const full = report();
  return JSON.stringify({ suites: full.suites.filter((_, index) => projects[index] === project) });
}

function workspace() {
  const dir = mkdtempSync(join(tmpdir(), "operator-ci-evidence-"));
  const write = (name: string, contents: string) => {
    const path = join(dir, name);
    writeFileSync(path, contents);
    return path;
  };
  const inventoryPath = write("inventory.json", JSON.stringify(inventory));
  const legs = Object.fromEntries(projects.map((project) => [project, {
    discovered: write(`discovered-${project}.txt`, legDiscovered(project)),
    executed: write(`executed-${project}.json`, legExecuted(project)),
  }])) as Record<(typeof projects)[number], { discovered: string; executed: string }>;
  return { dir, write, inventoryPath, legs, receiptPath: join(dir, "receipt.json"), cleanup: () => rmSync(dir, { recursive: true, force: true }) };
}

function runCli(args: string[]) {
  const env = { ...process.env, ...trustedEnv };
  delete env.NODE_OPTIONS;
  const result = spawnSync(process.execPath, ["--experimental-strip-types", "--no-warnings", script, ...args], { env, encoding: "utf8" });
  return { status: result.status, stdout: result.stdout, stderr: result.stderr };
}

test("plain node loads the receipt script without tsx and prints both usage forms", () => {
  const result = runCli([]);
  assert.equal(result.status, 1);
  assert.doesNotMatch(result.stderr, /ERR_MODULE_NOT_FOUND|SyntaxError/);
  assert.match(result.stderr, /usage: .*--discovered .*--executed/);
  assert.match(result.stderr, /usage: .*--verify inventory discovered-json executed-json output-receipt/);
});

test("split matrix legs reconcile across repeated --discovered and --executed files", () => {
  const ws = workspace();
  try {
    const { legs } = ws;
    const result = runCli([
      "--verify", ws.inventoryPath,
      "--discovered", legs["desktop-chromium"].discovered, "--discovered", legs["mobile-chromium"].discovered,
      "--executed", legs["desktop-chromium"].executed, "--executed", legs["mobile-chromium"].executed,
      ws.receiptPath,
    ]);
    assert.equal(result.status, 0, result.stderr);
    const receipt = JSON.parse(readFileSync(ws.receiptPath, "utf8"));
    assert.equal(receipt.jobId, "verify-example-browser");
    assert.deepEqual(receipt.counts, { expected: 2, discovered: 2, executed: 2, passed: 2 });
    assert.deepEqual(receipt.identities.map((item: { identity: OperatorJourneyIdentity }) => item.identity), projects.map(identity));
  } finally {
    ws.cleanup();
  }
});

test("a dropped matrix leg's executed file fails closed as not executed", () => {
  const ws = workspace();
  try {
    const { legs } = ws;
    const result = runCli([
      "--verify", ws.inventoryPath,
      "--discovered", legs["desktop-chromium"].discovered, "--discovered", legs["mobile-chromium"].discovered,
      "--executed", legs["desktop-chromium"].executed,
      ws.receiptPath,
    ]);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /required journey was not executed/);
    assert.equal(existsSync(ws.receiptPath), false);
  } finally {
    ws.cleanup();
  }
});

test("the same executed test supplied in two leg files is rejected as a duplicate", () => {
  const ws = workspace();
  try {
    const { legs } = ws;
    const copy = ws.write("executed-desktop-copy.json", readFileSync(legs["desktop-chromium"].executed, "utf8"));
    const result = runCli([
      "--verify", ws.inventoryPath,
      "--discovered", legs["desktop-chromium"].discovered, "--discovered", legs["mobile-chromium"].discovered,
      "--executed", legs["desktop-chromium"].executed, "--executed", copy, "--executed", legs["mobile-chromium"].executed,
      ws.receiptPath,
    ]);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /executed report contains duplicate journey identity/);
    assert.equal(existsSync(ws.receiptPath), false);
  } finally {
    ws.cleanup();
  }
});

test("zero --executed or --discovered files and stray positionals are usage errors", () => {
  const ws = workspace();
  try {
    const { legs } = ws;
    const discovered = ["--discovered", legs["desktop-chromium"].discovered, "--discovered", legs["mobile-chromium"].discovered];
    const executed = ["--executed", legs["desktop-chromium"].executed, "--executed", legs["mobile-chromium"].executed];
    for (const args of [
      ["--verify", ws.inventoryPath, ...discovered, ws.receiptPath],
      ["--verify", ws.inventoryPath, ...executed, ws.receiptPath],
      ["--verify", ws.inventoryPath, ...discovered, ...executed],
      ["--verify", ws.inventoryPath, ...discovered, ...executed, ws.receiptPath, "extra"],
      ["--verify", ws.inventoryPath, ...discovered, ...executed, "--unknown", "x", ws.receiptPath],
    ]) {
      const result = runCli(args);
      assert.equal(result.status, 1, args.join(" "));
      assert.match(result.stderr, /usage|unknown option/i, args.join(" "));
    }
    assert.equal(existsSync(ws.receiptPath), false);
  } finally {
    ws.cleanup();
  }
});

test("the report size cap applies to every repeated input file", () => {
  const ws = workspace();
  try {
    const { legs } = ws;
    const oversized = ws.write("executed-oversized.json", "");
    truncateSync(oversized, 20 * 1024 * 1024 + 1);
    const result = runCli([
      "--verify", ws.inventoryPath,
      "--discovered", legs["desktop-chromium"].discovered, "--discovered", legs["mobile-chromium"].discovered,
      "--executed", legs["desktop-chromium"].executed, "--executed", oversized,
      ws.receiptPath,
    ]);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /exceeds the report size limit/);
  } finally {
    ws.cleanup();
  }
});

test("the legacy four-positional --verify form still writes the receipt", () => {
  const ws = workspace();
  try {
    const listed = projects.map((project) => `  [${project}] › ${file}:660:3 › ${titlePath.join(" › ")}`).join("\n");
    const discoveredPath = ws.write("discovered.txt", `Listing tests:\n${listed}\nTotal: 2 tests in 1 file\n`);
    const executedPath = ws.write("executed.json", JSON.stringify(report()));
    const result = runCli(["--verify", ws.inventoryPath, discoveredPath, executedPath, ws.receiptPath]);
    assert.equal(result.status, 0, result.stderr);
    const receipt = JSON.parse(readFileSync(ws.receiptPath, "utf8"));
    assert.equal(receipt.jobId, "verify-example-browser");
    assert.deepEqual(receipt.counts, { expected: 2, discovered: 2, executed: 2, passed: 2 });
  } finally {
    ws.cleanup();
  }
});
