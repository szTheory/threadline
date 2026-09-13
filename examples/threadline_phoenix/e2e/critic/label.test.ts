import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { resolve } from "node:path";
import test from "node:test";
import {
  adjudicateRoundItems,
  loadRoundEvidence,
  nextRoundCommand,
  r1CommitState,
  reconcileRoundEvidence,
  runLabel,
  type RoundFile,
  type RoundItem,
} from "./label.js";

const singleItem = (round: "r1" | "r2"): RoundItem => ({
  queue_id: "q_single",
  token: round === "r1" ? "A001" : "B001",
  cell_id: "page.single",
  lens: "hierarchy",
  kind: "single",
  pair_with: null,
  pair_with_token: null,
  verdict: "good",
  evidence: `${round} single evidence`,
  labeled_at: "2026-09-13T00:00:00Z",
});

const pairItem = (round: "r1" | "r2"): RoundItem => ({
  queue_id: "q_pair",
  token: round === "r1" ? "A002" : "B002",
  cell_id: "page.left",
  lens: "hierarchy",
  kind: "pair",
  pair_with: "page.right",
  pair_with_token: round === "r1" ? "A003" : "B003",
  verdict: "better",
  margin: "clear",
  evidence: `${round} pair evidence`,
  labeled_at: "2026-09-13T00:00:01Z",
});

async function persistSessions(
  path: string,
  round: "r1" | "r2",
  sessions: RoundItem[],
): Promise<RoundFile> {
  for (const item of sessions) {
    const evidence = loadRoundEvidence(path, round);
    evidence.items.push(item);
    await writeFile(path, `${JSON.stringify(evidence, null, 2)}\n`, "utf8");
  }

  return loadRoundEvidence(path, round);
}

test("single and pair sessions survive in both orders and reconcile together", async () => {
  for (const order of ["single-first", "pair-first"] as const) {
    const root = await mkdtemp(resolve(tmpdir(), `threadline-label-${order}-`));
    const r1Path = resolve(root, "r1.json");
    const r2Path = resolve(root, "r2.json");

    try {
      const r1Sessions = order === "single-first"
        ? [singleItem("r1"), pairItem("r1")]
        : [pairItem("r1"), singleItem("r1")];
      const r2Sessions = order === "single-first"
        ? [pairItem("r2"), singleItem("r2")]
        : [singleItem("r2"), pairItem("r2")];

      const r1 = await persistSessions(r1Path, "r1", r1Sessions);
      const r2 = await persistSessions(r2Path, "r2", r2Sessions);

      assert.deepEqual(new Set(r1.items.map((item) => item.queue_id)), new Set(["q_single", "q_pair"]));
      assert.deepEqual(new Set(r2.items.map((item) => item.queue_id)), new Set(["q_single", "q_pair"]));

      const reconciled = reconcileRoundEvidence(r1.items, r2.items);
      assert.equal(reconciled.disagreements.length, 0);
      assert.deepEqual(
        new Set(reconciled.agreements.map((item) => item.kind)),
        new Set(["single", "pair"]),
      );
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  }
});

test("generated next-round commands preserve pair mode", () => {
  assert.equal(
    nextRoundCommand("r2", true),
    "npm run critic:label -- --round r2 --pairs",
  );
  assert.equal(
    nextRoundCommand("r2", false),
    "npm run critic:label -- --round r2",
  );
});

test("reconciliation serializes the adjudicator's selected verdict and pair margin", () => {
  const r1Single = singleItem("r1");
  const r2Single = { ...singleItem("r2"), verdict: "bad" as const };
  const keepR1 = adjudicateRoundItems(r1Single, r2Single, "r1", "gs_001");
  const keepR2 = adjudicateRoundItems(r1Single, r2Single, "r2", "gs_001");

  assert.deepEqual(keepR1.adjudicated, { source: "r1", verdict: "good" });
  assert.deepEqual(keepR2.adjudicated, { source: "r2", verdict: "bad" });
  assert.notDeepEqual(keepR1.adjudicated, keepR2.adjudicated);

  const r1Pair = pairItem("r1");
  const r2Pair = {
    ...pairItem("r2"),
    verdict: "worse" as const,
    margin: "subtle" as const,
  };
  assert.deepEqual(
    adjudicateRoundItems(r1Pair, r2Pair, "r2", "gs_002").adjudicated,
    { source: "r2", verdict: "worse", margin: "subtle" },
  );
});

test("CLI and web r2 reject missing, untracked, and modified r1 evidence", async () => {
  const root = await mkdtemp(resolve(tmpdir(), "threadline-r2-gate-"));
  const firstRoundPath = resolve(root, "golden/rounds/r1.json");
  const commands = [
    ["--round", "r2"],
    ["--round", "r2", "--web"],
  ];

  try {
    execFileSync("git", ["init", "--quiet"], { cwd: root });
    execFileSync("git", ["config", "user.email", "critic-test@threadline.invalid"], { cwd: root });
    execFileSync("git", ["config", "user.name", "Threadline Critic Test"], { cwd: root });

    assert.equal(r1CommitState(firstRoundPath, root), "missing");
    for (const argv of commands) {
      await assert.rejects(
        runLabel(argv, { r1Path: firstRoundPath, repoRoot: root }),
        /does not exist/,
      );
    }

    await mkdir(resolve(root, "golden/rounds"), { recursive: true });
    await writeFile(firstRoundPath, "{}\n", "utf8");
    assert.equal(r1CommitState(firstRoundPath, root), "dirty");
    for (const argv of commands) {
      await assert.rejects(
        runLabel(argv, { r1Path: firstRoundPath, repoRoot: root }),
        /not committed to git/,
      );
    }

    execFileSync("git", ["add", "golden/rounds/r1.json"], { cwd: root });
    execFileSync("git", ["commit", "--quiet", "-m", "test: commit r1"], { cwd: root });
    assert.equal(r1CommitState(firstRoundPath, root), "committed");

    await writeFile(firstRoundPath, "{\"modified\":true}\n", "utf8");
    assert.equal(r1CommitState(firstRoundPath, root), "dirty");
    for (const argv of commands) {
      await assert.rejects(
        runLabel(argv, { r1Path: firstRoundPath, repoRoot: root }),
        /not committed to git/,
      );
    }
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
