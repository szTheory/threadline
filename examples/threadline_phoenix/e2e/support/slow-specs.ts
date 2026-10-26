// CI-01 (phase 247 D-04/D-05): turn the Playwright JSON report CI already
// writes (PLAYWRIGHT_JSON_OUTPUT_FILE) into a "slowest browser specs" job
// summary plus a timings JSON artifact. Reporter config stays untouched.
//
// This script is diagnostic only and must never fail the job: every error is
// printed as a `::warning::` annotation and process.exitCode stays 0. The
// summary carries names and numbers only, never raw log text.
import { appendFileSync, readFileSync, statSync, writeFileSync } from "node:fs";

export const MAX_REPORT_BYTES = 20 * 1024 * 1024;
const SAFE_NAME = /^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$/;
const MAX_TITLE = 160;
const DEFAULT_CAP = 20;

export interface TimingRow {
  readonly project: string;
  readonly file: string;
  readonly title: string;
  readonly durationMs: number;
  readonly attempts: number;
  readonly retried: boolean;
}

export interface FileTotal {
  readonly project: string;
  readonly file: string;
  readonly durationMs: number;
  readonly tests: number;
}

export interface ProjectTotal {
  readonly project: string;
  readonly durationMs: number;
  readonly tests: number;
}

export interface TimingSummary {
  readonly top: readonly TimingRow[];
  readonly files: readonly FileTotal[];
  readonly projects: readonly ProjectTotal[];
  readonly totalMs: number;
  readonly unattributedMs: number | null;
  readonly retriedCount: number;
}

export interface DropCounter {
  unsafeProjects: number;
}

function object(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} is malformed`);
  return value as Record<string, unknown>;
}

function duration(value: unknown): number {
  const result = object(value, "test result");
  const ms = result.duration;
  return typeof ms === "number" && Number.isFinite(ms) && ms > 0 ? ms : 0;
}

export function collectRows(value: unknown, dropped: DropCounter = { unsafeProjects: 0 }): TimingRow[] {
  const report = object(value, "Playwright report");
  if (!Array.isArray(report.suites)) throw new Error("Playwright report has no suites");
  const rows: TimingRow[] = [];

  const visit = (suiteValue: unknown, parentTitles: string[], inheritedFile: string) => {
    const suite = object(suiteValue, "report suite");
    const title = typeof suite.title === "string" ? suite.title : "";
    const file = typeof suite.file === "string" && suite.file ? suite.file.replaceAll("\\", "/") : inheritedFile;
    const isFileSuite = title === file.split("/").at(-1);
    const titlePath = title && !isFileSuite ? [...parentTitles, title] : parentTitles;

    if (Array.isArray(suite.specs)) {
      for (const specValue of suite.specs) {
        const spec = object(specValue, "report spec");
        if (typeof spec.title !== "string" || !Array.isArray(spec.tests)) continue;
        const specFile = (typeof spec.file === "string" && spec.file ? spec.file : file)
          .replaceAll("\\", "/")
          .replace(/^tests\//, "");
        for (const testValue of spec.tests) {
          const test = object(testValue, "report test");
          const results = Array.isArray(test.results) ? test.results : [];
          const expectedStatus = typeof test.expectedStatus === "string" ? test.expectedStatus : "passed";
          if (expectedStatus === "skipped" || results.length === 0) continue;
          const project = typeof test.projectName === "string" ? test.projectName : "";
          if (!SAFE_NAME.test(project)) {
            dropped.unsafeProjects += 1;
            continue;
          }
          rows.push({
            project,
            file: specFile,
            title: [...titlePath, spec.title].join(" › "),
            durationMs: results.reduce((sum: number, result: unknown) => sum + duration(result), 0),
            attempts: results.length,
            retried: results.length > 1,
          });
        }
      }
    }

    if (Array.isArray(suite.suites)) {
      for (const child of suite.suites) visit(child, titlePath, file);
    }
  };

  for (const suite of report.suites) visit(suite, [], "");
  return rows;
}

export function summarize(rows: readonly TimingRow[], stats: unknown, cap = DEFAULT_CAP): TimingSummary {
  const byDuration = <T extends { durationMs: number }>(a: T, b: T) => b.durationMs - a.durationMs;
  const files = new Map<string, FileTotal>();
  const projects = new Map<string, ProjectTotal>();
  let totalMs = 0;

  for (const row of rows) {
    totalMs += row.durationMs;
    const fileKey = JSON.stringify([row.project, row.file]);
    const file = files.get(fileKey);
    files.set(fileKey, {
      project: row.project,
      file: row.file,
      durationMs: (file?.durationMs ?? 0) + row.durationMs,
      tests: (file?.tests ?? 0) + 1,
    });
    const project = projects.get(row.project);
    projects.set(row.project, {
      project: row.project,
      durationMs: (project?.durationMs ?? 0) + row.durationMs,
      tests: (project?.tests ?? 0) + 1,
    });
  }

  const statsObject = stats && typeof stats === "object" ? (stats as Record<string, unknown>) : {};
  const wall = statsObject.duration;
  const unattributedMs = typeof wall === "number" && Number.isFinite(wall) && wall > 0
    ? Math.round(wall - totalMs)
    : null;

  return {
    top: [...rows].sort(byDuration).slice(0, cap),
    files: [...files.values()].sort(byDuration),
    projects: [...projects.values()].sort(byDuration),
    totalMs,
    unattributedMs,
    retriedCount: rows.filter((row) => row.retried).length,
  };
}

export function cell(value: string, max = MAX_TITLE): string {
  const flat = value.replace(/[\r\n]+/g, " ").replace(/[\u0000-\u001f\u007f]/g, "");
  const capped = flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
  return capped.replaceAll("\\", "\\\\").replaceAll("|", "\\|").replaceAll("`", "'");
}

function seconds(ms: number): string {
  return `${(ms / 1000).toFixed(1)}s`;
}

export function renderMarkdown(summary: TimingSummary, label: string): string {
  const lines = [
    `### Slowest browser specs (${cell(label, 80)})`,
    "",
    `${summary.top.length} slowest of ${summary.projects.reduce((sum, p) => sum + p.tests, 0)} executed tests; ` +
      `${summary.retriedCount} retried. Durations sum every attempt.`,
    "",
    "| Project | File | Test | Duration | Attempts |",
    "| --- | --- | --- | ---: | ---: |",
    ...summary.top.map((row) =>
      `| ${row.project} | ${cell(row.file)} | ${cell(row.title)} | ${seconds(row.durationMs)} | ` +
        `${row.retried ? `${row.attempts} (retried)` : row.attempts} |`),
    "",
    "#### Per-project totals",
    "",
    "| Project | Tests | Duration |",
    "| --- | ---: | ---: |",
    ...summary.projects.map((p) => `| ${p.project} | ${p.tests} | ${seconds(p.durationMs)} |`),
    "",
    "#### Per-file totals",
    "",
    "| Project | File | Tests | Duration |",
    "| --- | --- | ---: | ---: |",
    ...summary.files.map((f) => `| ${f.project} | ${cell(f.file)} | ${f.tests} | ${seconds(f.durationMs)} |`),
    "",
    summary.unattributedMs === null
      ? "Unattributed: unknown (report has no stats.duration)."
      : `Unattributed (stats.duration minus summed results; parallel workers make this negative): ${seconds(summary.unattributedMs)}.`,
    "",
  ];
  return lines.join("\n");
}

function parseArgs(args: readonly string[]): { report: string; label: string; out: string } {
  const usage = "usage: slow-specs.ts <report.json> --label <name> --out <timings.json>";
  if (args.length !== 5 || args[1] !== "--label" || args[3] !== "--out") throw new Error(usage);
  const [report, , label, , out] = args;
  if (!SAFE_NAME.test(label)) throw new Error("label must be a safe name");
  return { report, label, out };
}

/** Runs the CLI and returns the warning lines it printed. Never throws. */
export function run(args: readonly string[], env: Record<string, string | undefined>): string[] {
  const warnings: string[] = [];
  const warn = (message: string) => {
    const line = `::warning::slow-specs: ${message.replace(/[\r\n]+/g, " ")}`;
    warnings.push(line);
    console.log(line);
  };

  try {
    const { report, label, out } = parseArgs(args);
    if (statSync(report).size > MAX_REPORT_BYTES) throw new Error("Playwright report exceeds the size limit");
    const value = object(JSON.parse(readFileSync(report, "utf8")), "Playwright report");
    const dropped: DropCounter = { unsafeProjects: 0 };
    const summary = summarize(collectRows(value, dropped), value.stats);
    if (dropped.unsafeProjects > 0) warn(`dropped ${dropped.unsafeProjects} tests with an unsafe project name`);

    const json = {
      schema: "threadline.browser-timings/1",
      label,
      top: summary.top,
      files: summary.files,
      projects: summary.projects,
      total_ms: summary.totalMs,
      unattributed_ms: summary.unattributedMs,
    };
    writeFileSync(out, `${JSON.stringify(json, null, 2)}\n`, { flag: "wx" });

    const markdown = renderMarkdown(summary, label);
    if (env.GITHUB_STEP_SUMMARY) appendFileSync(env.GITHUB_STEP_SUMMARY, `${markdown}\n`);
    else console.log(markdown);
  } catch (error) {
    const message = error instanceof Error ? error.message : "could not summarize browser timings";
    warn((error as NodeJS.ErrnoException)?.code === "ENOENT" ? "no Playwright JSON report" : message);
  }
  return warnings;
}

if (process.argv[1]?.endsWith("slow-specs.ts")) {
  run(process.argv.slice(2), process.env);
}
