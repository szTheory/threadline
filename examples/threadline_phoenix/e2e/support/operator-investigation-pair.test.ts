import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, realpathSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import test from "node:test";
import {
  assertFreshBrowserReport,
  assertInvestigationPair,
  assertListenerIdentity,
  assertServingCheckout,
  validateBrowserReport,
} from "./operator-investigation-pair.js";

const timelineUrl = "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=ticket_replies&correlation_id=walk-acme-4521-close";
const browser = { project: "desktop-chromium", version: "148.0.7778.96", playwright: "1.60.0" };
const fontNames = ["geist-400.woff2", "geist-500.woff2", "geist-600.woff2", "ibm-plex-mono-400.woff2", "ibm-plex-mono-500.woff2"];
const hash = (letter: string) => letter.repeat(64).slice(0, 64);

function condition(preference: "dark" | "light" | "system", effectiveTheme: "dark" | "light") {
  return {
    project: browser.project,
    browser: browser.version,
    playwright: browser.playwright,
    viewport: { width: 1280, height: 900, dpr: 1 },
    preference,
    mountedTheme: preference,
    effectiveTheme,
    systemScheme: preference === "system" ? effectiveTheme : "dark",
    reducedMotion: true,
    browserZoom: "unverified" as const,
  };
}

function makeHalf(half: "before" | "after") {
  const actionId = "c5c875c0-ed40-45c2-908e-925872fce082";
  const transactionId = "de666048-6343-432a-b800-b4ac5d41e749";
  const replyId = "9c8e4f16-806e-47b4-81bd-6e4341056781";
  const ticketId = "2cfa0b53-305a-4d52-b57c-e82520596390";
  const actorId = "cb1b4a0f-17e6-5afe-a072-5c5a6895ee5b";
  const changeIds = ["338472f6-d6df-435d-b9ff-e3d3d6c00580", "9daa43cf-db14-40e2-b4df-aa1a6bfdc7e8"];
  const selected = {
    database: "threadline_phoenix_testp250pair",
    partition: "p250pair",
    httpPort: 60150,
    actionId,
    actionName: "ticket_replied_and_closed",
    transactionId,
    changeIds,
    replyId,
    ticketId,
    actorId,
    eventTime: "2026-05-26T14:30:00+00:00",
    actionInsertedAt: "2026-11-12T10:06:36.944698+00:00",
  };
  const fonts = Object.fromEntries(fontNames.map((name, index) => [name, { sha256: hash("abcdef"[index]!), bytes: 12000 + index }]));
  const captures = (["dark", "light"] as const).map((theme) => {
    const id = `timeline-restored-${theme}`;
    const file = (name: string) => `captures/${half}/attempt/${name}`;
    return {
      id,
      route: timelineUrl,
      state: "filtered-timeline-return",
      condition: condition(theme, theme),
      shell: { file: file(`${id}-shell.png`), sha256: hash("a"), bytes: 1000 },
      content: { file: file(`${id}-content.png`), sha256: hash("b"), bytes: 2000 },
      observation: { file: file(`${id}-observation.json`), sha256: hash("c"), bytes: 3000 },
      assets: {
        stylesheetSha256: hash("d"),
        fontFaceCount: 5,
        fonts,
        inlineScriptSha256: hash("e"),
        svgCount: 26,
        svgMarkupSha256: hash("f"),
      },
    };
  });
  const systemObservations = (["dark", "light"] as const).map((system) => ({
    id: `system-${system}`,
    file: `captures/${half}/attempt/system-${system}-observation.json`,
    sha256: hash(system === "dark" ? "1" : "2"),
    condition: condition("system", system),
  }));
  return {
    schemaVersion: 1,
    half,
    capturedAt: half === "before" ? "2026-11-12T11:01:01.122Z" : "2026-11-12T12:00:00.000Z",
    canonical: true,
    pairId: half === "before" ? "before-pair" : "after-pair",
    materializationSha256: hash("9"),
    selected,
    server: { pid: 17946, port: 60150, sourceHeadAtStart: "81fd490359cd0d68a558675678339df6cbc57b7c", servingSource: { files: { "lib/threadline/operator_surface/live/timeline_live.ex": { sha256: hash("1"), bytes: 4000 } } } },
    testSource: { files: { "lib/threadline/operator_surface/live/timeline_live.ex": { sha256: hash("1"), bytes: 4000 } } },
    browser,
    journey: {
      timelineUrl,
      actionId,
      transactionId,
      changeIds,
      replyId,
      ticketId,
      actorId,
      eventTime: selected.eventTime,
      actionInsertedAt: selected.actionInsertedAt,
      copyValue: replyId,
      copyStatus: "Copied.",
      keyboardActivation: true,
      filtersRestored: true,
    },
    captures,
    systemObservations,
  };
}

function makePair() {
  return { before: makeHalf("before"), after: makeHalf("after") };
}

const titles = {
  theme: ["theme preference, effective cascade and reduced motion are distinct observed facts"],
  "fonts-loaded": [
    "Clipboard success waits for confirmation on direct entry and after patches",
    "Clipboard failure shows manual recovery without claiming success",
    "Clipboard fallback confirms success and restores focus and selection",
    "Copy feedback fits long URLs and redacted values stay non-copyable",
    "Phase250 fonts and brand boundaries",
  ],
  "fonts-disabled": ["Phase250 fonts and brand boundaries"],
} as const;

function reportFor(gate: keyof typeof titles, options: {
  readonly statusAt?: number;
  readonly status?: string;
  readonly projectAt?: number;
  readonly retry?: number;
  readonly duplicateAt?: number;
  readonly extra?: boolean;
} = {}) {
  const specs: Array<{ title: string; tests: Array<{ projectName: string; results: Array<{ status: string; retry: number }> }> }> = titles[gate].map((title, index) => ({
    title: options.duplicateAt === index ? titles[gate][0] : title,
    tests: [{
      projectName: options.projectAt === index ? "firefox" : "desktop-chromium",
      results: [{ status: options.statusAt === index ? options.status ?? "skipped" : "passed", retry: options.retry ?? 0 }],
    }],
  }));
  if (options.extra) specs.push({ title: "unexpected extra test", tests: [{ projectName: "desktop-chromium", results: [{ status: "passed", retry: 0 }] }] });
  const passed = specs.filter((spec) => spec.tests[0]?.results[0]?.status === "passed").length;
  const skipped = specs.filter((spec) => spec.tests[0]?.results[0]?.status === "skipped").length;
  const unexpected = specs.length - passed - skipped;
  return {
    errors: [],
    suites: [{ title: "tests", file: "tests/phase250.spec.ts", suites: [{ title: "nested", specs }] }],
    stats: { startTime: "2026-11-12T12:00:00.000Z", duration: 1000, expected: passed, skipped, unexpected, flaky: 0 },
  };
}

test("a clean pair is accepted while rendered source and assets may change", () => {
  const { before, after } = makePair();
  const changedSource = { files: { "lib/threadline/operator_surface/live/timeline_live.ex": { sha256: hash("2"), bytes: 4100 } } };
  after.testSource = changedSource;
  after.server.servingSource = changedSource;
  after.server.sourceHeadAtStart = "abcdefabcdefabcdefabcdefabcdefabcdefabcd";
  after.captures[0]!.assets.stylesheetSha256 = hash("3");
  after.captures[1]!.assets.svgMarkupSha256 = hash("4");
  assert.deepEqual(assertInvestigationPair(before, after), {
    matched: true,
    pairId: "before-pair/after-pair",
    materializationSha256: hash("9"),
  });
});

test("missing, wrong-half, noncanonical and out-of-custody halves fail closed", () => {
  const pair = makePair();
  assert.throws(() => assertInvestigationPair(undefined, pair.after), /before investigation half/i);
  pair.before.half = "after" as "before";
  assert.throws(() => assertInvestigationPair(pair.before, pair.after), /before investigation half/i);

  const noncanonical = makePair();
  noncanonical.before.canonical = false;
  assert.throws(() => assertInvestigationPair(noncanonical.before, noncanonical.after), /before investigation half/i);

  for (const file of ["/tmp/outside.png", "captures/after/outside.png", "captures/before/../outside.png"]) {
    const mutated = makePair();
    mutated.before.captures[0]!.shell.file = file;
    assert.throws(() => assertInvestigationPair(mutated.before, mutated.after), /incomplete|incomparable/i, file);
  }
});

test("database, partition, port, IDs, event and recording times must match", () => {
  const mutations: Array<[string, (half: ReturnType<typeof makeHalf>) => void]> = [
    ["database", (half) => { half.after.selected.database = "other_database"; }],
    ["partition", (half) => { half.after.selected.partition = "other_partition"; }],
    ["port", (half) => { half.after.selected.httpPort = 5432; half.after.server.port = 5432; }],
    ["action", (half) => { half.after.selected.actionId = "other-action"; }],
    ["transaction", (half) => { half.after.selected.transactionId = "other-transaction"; }],
    ["change IDs", (half) => { half.after.selected.changeIds[0] = "other-change"; }],
    ["reply", (half) => { half.after.selected.replyId = "other-reply"; }],
    ["ticket", (half) => { half.after.selected.ticketId = "other-ticket"; }],
    ["actor", (half) => { half.after.selected.actorId = "other-actor"; }],
    ["event time", (half) => { half.after.selected.eventTime = "2026-05-27T14:30:00+00:00"; }],
    ["recording time", (half) => { half.after.selected.actionInsertedAt = "2026-11-13T10:06:36.944698+00:00"; }],
  ];
  for (const [name, mutate] of mutations) {
    const pair = makePair();
    mutate(pair);
    assert.throws(() => assertInvestigationPair(pair.before, pair.after), /incomplete|mismatch|materialization/i, name);
  }
  const forbiddenDatabasePort = makePair();
  forbiddenDatabasePort.after.selected.httpPort = 60025;
  forbiddenDatabasePort.after.server.port = 60025;
  assert.throws(() => assertInvestigationPair(forbiddenDatabasePort.before, forbiddenDatabasePort.after), /incomplete/i);
});

test("row fingerprint, browser identity and pair identity are stable", () => {
  const fingerprint = makePair();
  fingerprint.after.materializationSha256 = hash("8");
  assert.throws(() => assertInvestigationPair(fingerprint.before, fingerprint.after), /materialization/i);

  const sameCapture = makePair();
  sameCapture.after.pairId = sameCapture.before.pairId;
  assert.throws(() => assertInvestigationPair(sameCapture.before, sameCapture.after), /distinct pair identities/i);

  const sameBrowser = makePair();
  sameBrowser.after.browser.version = "different-browser";
  assert.throws(() => assertInvestigationPair(sameBrowser.before, sameBrowser.after), /incomplete|browser identity/i);
});

test("missing shell, content, source, stylesheet, SVG or decoded font evidence rejects", () => {
  const mutations: Array<[string, (half: ReturnType<typeof makeHalf>) => void]> = [
    ["shell", (half) => { (half.before.captures[0] as any).shell = undefined; }],
    ["content", (half) => { (half.before.captures[0] as any).content = undefined; }],
    ["observation", (half) => { (half.before.captures[0] as any).observation = undefined; }],
    ["source", (half) => { half.before.testSource.files = {}; }],
    ["served CSS", (half) => { (half.before.captures[0] as any).assets.stylesheetSha256 = "missing"; }],
    ["served SVG", (half) => { (half.before.captures[0] as any).assets.svgMarkupSha256 = "missing"; }],
    ["decoded fonts", (half) => { (half.before.captures[0] as any).assets.fonts[fontNames[0]!] = undefined; }],
  ];
  for (const [name, mutate] of mutations) {
    const pair = makePair();
    mutate(pair);
    assert.throws(() => assertInvestigationPair(pair.before, pair.after), /incomplete|incomparable/i, name);
  }
});

test("theme, motion, zoom and system observations must be comparable", () => {
  const mutations: Array<[string, (half: ReturnType<typeof makeHalf>) => void]> = [
    ["preference", (half) => { (half.after.captures[0] as any).condition.preference = "light"; }],
    ["motion", (half) => { (half.after.captures[1] as any).condition.reducedMotion = false; }],
    ["unmeasured zoom", (half) => { (half.after.captures[0] as any).condition.browserZoom = 1; }],
    ["system", (half) => { (half.after.systemObservations[1] as any).condition.systemScheme = "dark"; }],
    ["listener PID", (half) => { half.after.server.pid = 0; }],
  ];
  for (const [name, mutate] of mutations) {
    const pair = makePair();
    mutate(pair);
    assert.throws(() => assertInvestigationPair(pair.before, pair.after), /incomplete|comparable|system/i, name);
  }
});

test("stale listener identity and a removed retained checkout fail closed", () => {
  const directory = mkdtempSync(join(tmpdir(), "phase250-serving-checkout-"));
  const appCwd = join(directory, "examples", "threadline_phoenix");
  mkdirSync(appCwd, { recursive: true });
  try {
    assert.equal(assertServingCheckout(directory), realpathSync(directory));
    assert.doesNotThrow(() => assertListenerIdentity(17946, "p17946\nf40", appCwd, appCwd));
    assert.throws(() => assertListenerIdentity(17946, "p17947\nf40", appCwd, appCwd), /does not own/i);
    assert.throws(() => assertListenerIdentity(17946, "p17946\nf40", directory, appCwd), /does not own/i);
    rmSync(directory, { recursive: true, force: true });
    assert.throws(() => assertServingCheckout(directory), /missing|unavailable/i);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test("browser gates accept only clean exact 1/5/1 title and project sets", () => {
  for (const gate of ["theme", "fonts-loaded", "fonts-disabled"] as const) {
    const report = reportFor(gate);
    assert.equal(validateBrowserReport(gate, report).length, titles[gate].length);
    assert.deepEqual(validateBrowserReport(gate, report).map((result) => result.title), titles[gate]);
  }
});

test("missing, zero-test and skip-only browser reports fail closed", () => {
  assert.throws(() => validateBrowserReport("theme", null), /malformed/i);
  assert.throws(() => validateBrowserReport("theme", { errors: [], stats: reportFor("theme").stats, suites: [] }), /0 result rows/i);
  const skipOnly = reportFor("theme", { statusAt: 0, status: "skipped" });
  assert.throws(() => validateBrowserReport("theme", skipOnly), /first attempt|statistics/i);
});

test("a single skipped result among five is rejected even when other cases pass", () => {
  const report = reportFor("fonts-loaded", { statusAt: 2, status: "skipped" });
  assert.throws(() => validateBrowserReport("fonts-loaded", report), /first attempt|statistics/i);
});

test("duplicate, extra, wrong-project and retried browser results fail closed", () => {
  const duplicate = reportFor("fonts-loaded", { duplicateAt: 4 });
  assert.throws(() => validateBrowserReport("fonts-loaded", duplicate), /duplicate|missing|result rows/i);
  assert.throws(() => validateBrowserReport("fonts-loaded", reportFor("fonts-loaded", { extra: true })), /result rows/i);
  assert.throws(() => validateBrowserReport("theme", reportFor("theme", { projectAt: 0 })), /wrong-project/i);
  assert.throws(() => validateBrowserReport("theme", reportFor("theme", { retry: 1 })), /first attempt/i);
});

test("malformed and stale Playwright report files are rejected", () => {
  const directory = mkdtempSync(join(tmpdir(), "phase250-browser-report-"));
  try {
    const missing = join(directory, "missing.json");
    assert.throws(() => assertFreshBrowserReport(missing, new Date().toISOString()), /absent or stale/i);
    const stale = join(directory, "stale.json");
    writeFileSync(stale, "{}");
    const old = new Date(Date.now() - 2 * 60 * 60_000);
    utimesSync(stale, old, old);
    assert.throws(() => assertFreshBrowserReport(stale, new Date(Date.now() - 60_000).toISOString()), /stale|fresh/i);
    const fresh = join(directory, "fresh.json");
    writeFileSync(fresh, JSON.stringify(reportFor("theme")));
    assert.doesNotThrow(() => assertFreshBrowserReport(fresh, new Date(Date.now() - 1_000).toISOString()));
    const linked = join(directory, "linked.json");
    symlinkSync(fresh, linked);
    assert.throws(() => assertFreshBrowserReport(linked, new Date(Date.now() - 1_000).toISOString()), /regular file/i);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
