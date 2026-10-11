import assert from "node:assert/strict";
import test from "node:test";
import { identityKey, parseDiscovered, parseExecuted, validateEvidence, type OperatorJourneyIdentity } from "./operator-ci-evidence.js";

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
    requirement: "UIV-01",
    journey: "Home to Timeline transaction investigation",
    failureClass: "missing-or-retry-only-journey",
    voting: "required" as const,
    identity: identity(project),
  })),
};

function report(status = "passed", attempts = 1) {
  return {
    suites: projects.map((project) => ({
      title: "",
      suites: [{
        title: titlePath[0],
        file: `tests/${file}`,
        specs: [{
          title: titlePath[1],
          tests: [{
            projectName: project,
            expectedStatus: "passed",
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
