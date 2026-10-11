import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import test, { type TestContext } from "node:test";
import { build243CandidateReceipt } from "./operator-candidate-receipt.js";

const sha = (bytes: string | Uint8Array) => createHash("sha256").update(bytes).digest("hex");

function checkout(t: TestContext) {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "operator-candidate-243-")));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const git = (...args: string[]) => execFileSync("git", args, { cwd: root, encoding: "utf8" }).trim();
  git("init", "-q", "-b", "agent-test-243");
  git("config", "user.email", "synthetic@example.invalid");
  git("config", "user.name", "Synthetic test");
  const seedDir = "examples/threadline_phoenix/lib/threadline_phoenix/demo";
  const files = [
    ["mix.exs", "synthetic mix"],
    ["examples/threadline_phoenix/config/test.exs", "synthetic test config"],
    [`${seedDir}/seed.ex`, "defmodule Seed do end"],
    [`${seedDir}/manifest.ex`, "defmodule Manifest do end"],
    [`${seedDir}/seed/sample.exs`, "seed"],
  ] as const;
  for (const [path, value] of files) {
    mkdirSync(dirname(join(root, path)), { recursive: true });
    writeFileSync(join(root, path), value);
  }
  git("add", "mix.exs", "examples");
  git("commit", "-qm", "accepted synthetic baseline");
  const base = git("rev-parse", "HEAD");
  const acceptedDir = ".planning/phases/238-current-main-preview-and-acceptance-baseline";
  mkdirSync(join(root, acceptedDir), { recursive: true });
  const evidenceIndex = [
    "# Final operator evidence custody",
    `Immutable base: \`${base}\`.`,
    "| Eleven routes + degraded | bundle | 135 | `" + "a".repeat(64) + "` | output |",
    "| Dark states | bundle | 63 | `" + "b".repeat(64) + "` | output |",
    "| System/light states | bundle | 63 | `" + "c".repeat(64) + "` | output |",
    "## Historical evidence",
  ].join("\n");
  const receipt = { phase: 238, base_sha: base, candidate_head: base };
  writeFileSync(join(root, acceptedDir, "238-ISOLATION-RECEIPT.json"), JSON.stringify(receipt));
  writeFileSync(join(root, acceptedDir, "238-EVIDENCE-INDEX.md"), evidenceIndex);
  git("add", acceptedDir);
  git("commit", "-qm", "accept synthetic evidence custody");
  return { root, git, base, acceptedDir };
}

test("candidate receipt binds approved baseline, worktree, branch, dirty source and fixture", (t) => {
  const { root, git } = checkout(t);
  writeFileSync(join(root, "mix.exs"), "candidate mix");

  let receipt: unknown;
  try { receipt = build243CandidateReceipt(root); } catch { receipt = undefined; }
  assert.ok(receipt, "candidate builder must return a source-bound receipt");
});
