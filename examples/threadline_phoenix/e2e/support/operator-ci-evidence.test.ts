import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
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
