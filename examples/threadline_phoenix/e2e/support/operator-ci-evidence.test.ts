import assert from "node:assert/strict";
import test from "node:test";
import { identityKey } from "./operator-ci-evidence.js";

test("journey identity includes project, file, and complete title path", () => {
  assert.equal(
    identityKey({
      file: "tests/operator-timeline-investigation-flow.spec.ts",
      titlePath: [
        "Timeline investigation flow browser proof",
        "starts at Home, applies a Timeline query, and opens its transaction",
      ],
      project: "desktop-chromium",
    }),
    JSON.stringify([
      "desktop-chromium",
      "tests/operator-timeline-investigation-flow.spec.ts",
      [
        "Timeline investigation flow browser proof",
        "starts at Home, applies a Timeline query, and opens its transaction",
      ],
    ]),
  );
});
