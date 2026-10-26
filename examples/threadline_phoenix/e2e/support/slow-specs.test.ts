import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, test } from "node:test";
import { collectRows, MAX_REPORT_BYTES, renderMarkdown, run, summarize } from "./slow-specs.js";

interface FakeTest {
  readonly project?: string;
  readonly title: string;
  readonly file?: string;
  readonly durations: readonly number[];
  readonly expectedStatus?: string;
}

function report(tests: readonly FakeTest[], statsDuration?: number) {
  const byFile = new Map<string, FakeTest[]>();
  for (const item of tests) {
    const file = item.file ?? "alpha.spec.ts";
    byFile.set(file, [...(byFile.get(file) ?? []), item]);
  }
  const total = tests.reduce((sum, item) => sum + item.durations.reduce((a, b) => a + b, 0), 0);
  return {
    stats: { duration: statsDuration ?? total },
    suites: [...byFile.entries()].map(([file, items]) => ({
      title: file,
      file,
      suites: [{
        title: "Describe block",
        file: `tests/${file}`,
        specs: items.map((item) => ({
          title: item.title,
          tests: [{
            projectName: item.project ?? "desktop-chromium",
            expectedStatus: item.expectedStatus ?? "passed",
            results: item.durations.map((duration, retry) => ({ duration, retry, status: "passed" })),
          }],
        })),
      }],
    })),
  };
}

function scratch(): string {
  return mkdtempSync(join(tmpdir(), "slow-specs-"));
}

describe("slow-specs", () => {
  test("ranks by summed duration and caps the table at 20 rows", () => {
    const tests = Array.from({ length: 25 }, (_, index) => ({ title: `test ${index}`, durations: [(index + 1) * 100] }));
    const summary = summarize(collectRows(report(tests)), { duration: 0 });
    assert.equal(summary.top.length, 20);
    assert.equal(summary.top[0].title, "Describe block › test 24");
    assert.equal(summary.top[0].durationMs, 2500);
    for (let index = 1; index < summary.top.length; index += 1) {
      assert.ok(summary.top[index - 1].durationMs >= summary.top[index].durationMs);
    }
    const markdown = renderMarkdown(summary, "all");
    assert.equal(markdown.split("\n").filter((line) => line.startsWith("| desktop-chromium |") && line.includes("test ")).length, 20);
  });

  test("sums durations across retries and flags retried tests", () => {
    const rows = collectRows(report([{ title: "flaky", durations: [1000, 1500] }]));
    assert.equal(rows.length, 1);
    assert.equal(rows[0].durationMs, 2500);
    assert.equal(rows[0].attempts, 2);
    assert.equal(rows[0].retried, true);
    assert.match(renderMarkdown(summarize(rows, { duration: 2500 }), "all"), /\| 2 \(retried\) \|/);
  });

  test("skipped tests and tests without results are excluded from rows and totals", () => {
    const rows = collectRows(report([
      { title: "ran", durations: [300] },
      { title: "skipped", durations: [900], expectedStatus: "skipped" },
      { title: "never ran", durations: [] },
    ]));
    assert.deepEqual(rows.map((row) => row.title), ["Describe block › ran"]);
    const summary = summarize(rows, { duration: 300 });
    assert.equal(summary.projects[0].durationMs, 300);
  });

  test("per-project and per-file totals plus the unattributed remainder", () => {
    const value = report([
      { title: "a1", file: "a.spec.ts", durations: [100] },
      { title: "a2", file: "a.spec.ts", durations: [200] },
      { title: "b1", file: "b.spec.ts", durations: [400] },
      { title: "a1", file: "a.spec.ts", project: "mobile-chromium", durations: [50] },
    ], 1000);
    const summary = summarize(collectRows(value), value.stats);
    assert.deepEqual(summary.projects, [
      { project: "desktop-chromium", durationMs: 700, tests: 3 },
      { project: "mobile-chromium", durationMs: 50, tests: 1 },
    ]);
    assert.deepEqual(summary.files.slice(0, 2), [
      { project: "desktop-chromium", file: "b.spec.ts", durationMs: 400, tests: 1 },
      { project: "desktop-chromium", file: "a.spec.ts", durationMs: 300, tests: 2 },
    ]);
    assert.equal(summary.unattributedMs, 250);
  });

  test("escapes pipes and newlines and caps long titles", () => {
    const rows = collectRows(report([
      { title: "a | b\nc", durations: [10] },
      { title: "x".repeat(400), durations: [5] },
    ]));
    const markdown = renderMarkdown(summarize(rows, { duration: 15 }), "all");
    assert.ok(markdown.includes("a \\| b c"));
    assert.ok(!markdown.includes("a | b"));
    const longLine = markdown.split("\n").find((line) => line.includes("xxxx"));
    assert.ok(longLine);
    assert.ok(longLine.length < 260, "long titles are truncated");
    assert.ok(longLine.includes("…"));
  });

  test("rows with an unsafe project name are dropped and counted", () => {
    const dropped = { unsafeProjects: 0 };
    const rows = collectRows(report([
      { title: "good", durations: [10] },
      { title: "bad", project: "evil|<script>", durations: [10] },
    ]), dropped);
    assert.deepEqual(rows.map((row) => row.project), ["desktop-chromium"]);
    assert.equal(dropped.unsafeProjects, 1);
  });

  test("main writes the timings JSON and appends the step summary", () => {
    const dir = scratch();
    const input = join(dir, "report.json");
    const out = join(dir, "timings.json");
    const summaryFile = join(dir, "summary.md");
    writeFileSync(summaryFile, "existing\n");
    writeFileSync(input, JSON.stringify(report([{ title: "only", durations: [42] }], 50)));
    const warnings = run([input, "--label", "all", "--out", out], { GITHUB_STEP_SUMMARY: summaryFile });
    assert.deepEqual(warnings, []);
    const json = JSON.parse(readFileSync(out, "utf8"));
    assert.equal(json.schema, "threadline.browser-timings/1");
    assert.equal(json.label, "all");
    assert.equal(json.top[0].durationMs, 42);
    assert.equal(json.unattributed_ms, 8);
    const appended = readFileSync(summaryFile, "utf8");
    assert.ok(appended.startsWith("existing\n"));
    assert.match(appended, /Slowest browser specs \(all\)/);
  });

  test("missing, malformed, and oversized reports warn without throwing", () => {
    const dir = scratch();
    assert.match(run([join(dir, "absent.json"), "--label", "all", "--out", join(dir, "o1.json")], {})[0], /::warning::slow-specs:/);

    const malformed = join(dir, "malformed.json");
    writeFileSync(malformed, "{ not json");
    assert.match(run([malformed, "--label", "all", "--out", join(dir, "o2.json")], {})[0], /::warning::slow-specs:/);

    const oversized = join(dir, "oversized.json");
    writeFileSync(oversized, Buffer.alloc(MAX_REPORT_BYTES + 1, 32));
    assert.match(run([oversized, "--label", "all", "--out", join(dir, "o3.json")], {})[0], /size limit/);

    assert.match(run(["--label"], {})[0], /::warning::slow-specs: usage/);
  });
});
