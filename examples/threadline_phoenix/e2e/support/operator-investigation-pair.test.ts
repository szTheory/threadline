import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, utimesSync, writeFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import test from "node:test";
import {
  additionalSourceIdentity,
  assertAdditionalSourceFreshness,
  assertInvestigationCaptureFiles,
  assertFreshBrowserReport,
  assertInvestigationPair,
  assertInvestigationReview,
  assertLaunchedSourceFreshness,
  assertListenerIdentity,
  assertServingCheckout,
  sourceIdentity,
  validateBeforeCandidateReceipt,
  validateBrowserReport,
} from "./operator-investigation-pair.js";

const timelineUrl = "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=ticket_replies&correlation_id=walk-acme-4521-close";
const browser = { project: "desktop-chromium", version: "148.0.7778.96", playwright: "1.60.0" };
const legacyFontNames = ["geist-400.woff2", "geist-500.woff2", "geist-600.woff2", "ibm-plex-mono-400.woff2", "ibm-plex-mono-500.woff2"];
const currentFontFaces = [
  { family: "Threadline Familjen Grotesk", weight: "400 700", file: "FamiljenGrotesk-normal-400-700.woff2" },
  { family: "Threadline Geist", weight: "400 700", file: "Geist-normal-400-700.woff2" },
  { family: "Threadline IBM Plex Mono", weight: "400", file: "IBMPlexMono-normal-400.woff2" },
  { family: "Threadline IBM Plex Mono", weight: "500", file: "IBMPlexMono-normal-500.woff2" },
];
const currentFontNames = currentFontFaces.map(({ file }) => file);
const hash = (letter: string) => letter.repeat(64).slice(0, 64);
const digest = (value: Buffer | string) => createHash("sha256").update(value).digest("hex");
const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");

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
  const candidateId = half === "before" ? "baseline-correction-test" : undefined;
  const captureBase = candidateId ? `candidates/${candidateId}/captures/before` : `captures/${half}`;
  const halfFontNames = half === "before" ? legacyFontNames : currentFontNames;
  const fonts = Object.fromEntries(halfFontNames.map((name, index) => [name, { sha256: hash("abcdef"[index]!), bytes: 12000 + index }]));
  const captureSpecs = [
    ["transaction", `/audit/transactions/${transactionId}`, "transaction-detail"],
    ["ticket-prior", `/audit/transactions/${transactionId}/history/tickets/${ticketId}?as_of=2026-05-01T00%3A00%3A00Z`, "prior-ticket-history-snapshot"],
    ["reply-history", half === "before"
      ? `/audit/rows/ticket_replies/${replyId}?origin=timeline&from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=ticket_replies&correlation_id=walk-acme-4521-close`
      : `/audit/transactions/${transactionId}/history/ticket_replies/${replyId}?as_of=2026-05-26T14%3A30%3A00Z`,
    half === "before" ? "timeline-origin-reply-history" : "transaction-origin-reply-history"],
    ["timeline-restored", timelineUrl, "filtered-timeline-return"],
  ] as const;
  const captures = captureSpecs.flatMap(([prefix, route, state]) => (["dark", "light"] as const).map((theme) => {
    const id = `${prefix}-${theme}`;
    const file = (name: string) => `${captureBase}/attempt/${name}`;
    return {
      id,
      route: half === "after" && !id.startsWith("timeline-restored-")
        ? (() => {
          const url = new URL(route, "http://127.0.0.1");
          url.searchParams.set("origin", "timeline");
          for (const [key, value] of new URL(timelineUrl, "http://127.0.0.1").searchParams) url.searchParams.set(key, value);
          return url.pathname + url.search;
        })() : route,
      state,
      condition: condition(theme, theme),
      shell: { file: file(`${id}-shell.png`), sha256: hash("a"), bytes: 1000 },
      content: { file: file(`${id}-content.png`), sha256: hash("b"), bytes: 2000 },
      observation: { file: file(`${id}-observation.json`), sha256: hash("c"), bytes: 3000 },
      assets: {
        stylesheetSha256: hash("d"),
        fontFaceCount: halfFontNames.length,
        fonts,
        ...(half === "after" ? { fontFaces: currentFontFaces } : {}),
        inlineScriptSha256: hash("e"),
        svgCount: 26,
        svgMarkupSha256: hash("f"),
      },
    };
  }));
  const systemObservations = (["dark", "light"] as const).map((system) => ({
    id: `system-${system}`,
    file: `${captureBase}/attempt/system-${system}-observation.json`,
    sha256: hash(system === "dark" ? "1" : "2"),
    condition: condition("system", system),
  }));
  return {
    schemaVersion: 1,
    half,
    capturedAt: half === "before" ? "2026-11-12T11:01:01.122Z" : "2026-11-12T12:00:00.000Z",
    canonical: half === "after",
    ...(candidateId ? { candidateId } : {}),
    pairId: half === "before" ? "before-pair" : "after-pair",
    materializationSha256: hash("9"),
    historySha256: hash("8"),
    historyChangeCount: 3,
    selected,
    server: { pid: 17946, port: 60150, sourceHeadAtStart: "81fd490359cd0d68a558675678339df6cbc57b7c", servingSource: { files: { "lib/threadline/operator_surface/live/timeline_live.ex": { sha256: hash("1"), bytes: 4000 } } } },
    testSource: { files: { "lib/threadline/operator_surface/live/timeline_live.ex": { sha256: hash("1"), bytes: 4000 } } },
    ...(half === "after" ? { additionalRuntimeSources: Object.fromEntries(
      ["launched", "serving", "test"].map((key) => [key, { files: {
        "lib/threadline/operator_surface/live/timeline_live/helpers.ex": { sha256: hash("1"), bytes: 18198 },
      } }]),
    ) } : {}),
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
      navigationMode: half === "before" ? "legacy-before" : "strict-after",
      copyContext: half === "before" ? "timeline" : "transaction-history",
      returnMode: half === "before" ? "browser-back" : "ui-links",
    },
    captures,
    systemObservations,
  };
}

function makePair() {
  return { before: makeHalf("before"), after: makeHalf("after") };
}

function snapshotFor(half: ReturnType<typeof makeHalf>) {
  const selected = half.selected;
  const replyChange = {
    id: selected.changeIds[0], op: "insert", table_pk: { id: selected.replyId },
    data_after: { id: selected.replyId, body: "Thanks — we're closing this out.", internal_note_body: "[REDACTED]", ticket_id: selected.ticketId },
    table_name: "ticket_replies", captured_at: selected.eventTime, transaction_id: selected.transactionId,
  };
  const ticketChange = {
    id: selected.changeIds[1], op: "update", table_pk: { id: selected.ticketId },
    data_after: { id: selected.ticketId, number: 4521, status: "closed", closed_at: "2026-05-26T14:30:00" },
    table_name: "tickets", captured_at: selected.eventTime, transaction_id: selected.transactionId,
  };
  return {
    database: selected.database,
    actions: [{ id: selected.actionId, name: selected.actionName, correlation_id: "walk-acme-4521-close", actor_ref: { type: "user", id: selected.actorId }, inserted_at: selected.actionInsertedAt }],
    transactions: [{ id: selected.transactionId, action_id: selected.actionId, actor_ref: { type: "user", id: selected.actorId }, occurred_at: selected.eventTime }],
    changes: [replyChange, ticketChange],
    ticket_row_hashes: [{ id: selected.ticketId, sha256: hash("5") }],
    reply_row_hashes: [{ id: selected.replyId, sha256: hash("4") }],
  };
}

function liveFor(half: ReturnType<typeof makeHalf>) {
  return { matched: true as const, sha256: half.materializationSha256, snapshot: snapshotFor(half), history_sha256: half.historySha256, history_change_count: half.historyChangeCount };
}

function materializeCaptureFiles(root: string, half: ReturnType<typeof makeHalf>) {
  for (const capture of half.captures as any[]) {
    for (const identity of [capture.shell, capture.content, capture.observation]) {
      const file = resolve(root, identity.file);
      const bytes = Buffer.from(`artifact:${identity.file}`);
      mkdirSync(dirname(file), { recursive: true });
      writeFileSync(file, bytes);
      identity.sha256 = digest(bytes);
      identity.bytes = bytes.byteLength;
    }
  }
  for (const observation of half.systemObservations as any[]) {
    const file = resolve(root, observation.file);
    const bytes = Buffer.from(`artifact:${observation.file}`);
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, bytes);
    observation.sha256 = digest(bytes);
  }
}

function writeCandidate(root: string, half: ReturnType<typeof makeHalf>) {
  materializeCaptureFiles(root, half);
  const file = resolve(root, "candidates/baseline-correction-test/captures/before/half.json");
  mkdirSync(dirname(file), { recursive: true });
  const bytes = Buffer.from(`${JSON.stringify(half, null, 2)}\n`);
  writeFileSync(file, bytes);
  const candidate = {
    schemaVersion: 1,
    candidateId: "baseline-correction-test",
    createdAt: "2026-11-12T12:00:00.000Z",
    half: { file: "candidates/baseline-correction-test/captures/before/half.json", sha256: digest(bytes), pairId: half.pairId },
  };
  const candidatePath = resolve(root, "candidates/baseline-correction-test/candidate.json");
  mkdirSync(dirname(candidatePath), { recursive: true });
  writeFileSync(candidatePath, `${JSON.stringify(candidate, null, 2)}\n`);
  return candidatePath;
}

function refreshCandidateDigest(root: string, half: ReturnType<typeof makeHalf>) {
  const file = resolve(root, "candidates/baseline-correction-test/captures/before/half.json");
  const bytes = Buffer.from(`${JSON.stringify(half, null, 2)}\n`);
  writeFileSync(file, bytes);
  const candidatePath = resolve(root, "candidates/baseline-correction-test/candidate.json");
  const candidate = JSON.parse(readFileSync(candidatePath, "utf8"));
  candidate.half.sha256 = digest(bytes);
  candidate.half.pairId = half.pairId;
  writeFileSync(candidatePath, `${JSON.stringify(candidate, null, 2)}\n`);
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

test("legacy before keeps five font files while current after binds four approved descriptors", () => {
  const { before, after } = makePair();
  assert.deepEqual(assertInvestigationPair(before, after), {
    matched: true,
    pairId: "before-pair/after-pair",
    materializationSha256: hash("9"),
  });

  const weakenedBefore = makeHalf("before");
  weakenedBefore.captures[0]!.assets.fontFaceCount = 4;
  assert.throws(() => assertInvestigationPair(weakenedBefore, after), /before half has incomplete/i);

  const staleAfter = makeHalf("after");
  Object.assign(staleAfter.captures[0]!.assets, { fontFaces: [] });
  assert.throws(() => assertInvestigationPair(before, staleAfter), /after half has incomplete/i);
});

test("missing, wrong-half, noncanonical and out-of-custody halves fail closed", () => {
  const pair = makePair();
  assert.throws(() => assertInvestigationPair(undefined, pair.after), /before investigation half/i);
  pair.before.half = "after" as "before";
  assert.throws(() => assertInvestigationPair(pair.before, pair.after), /before investigation half/i);

  const noncanonical = makePair();
  noncanonical.before.canonical = true;
  assert.throws(() => assertInvestigationPair(noncanonical.before, noncanonical.after), /before investigation half/i);

  for (const file of ["/tmp/outside.png", "captures/after/outside.png", "captures/before/../outside.png"]) {
    const mutated = makePair();
    mutated.before.captures[0]!.shell.file = file;
    assert.throws(() => assertInvestigationPair(mutated.before, mutated.after), /incomplete|incomparable/i, file);
  }
});

test("candidate receipt binds nonempty selected fields to live materialization after pointer digest refresh", () => {
  const mutations: Array<[string, (half: ReturnType<typeof makeHalf>) => void]> = [
    ["action", (half) => { half.selected.actionId = "different-action"; half.journey.actionId = "different-action"; }],
    ["transaction", (half) => {
      const old = half.selected.transactionId;
      half.selected.transactionId = "different-transaction";
      half.journey.transactionId = "different-transaction";
      for (const capture of half.captures as any[]) capture.route = capture.route.replace(old, "different-transaction");
    }],
    ["change IDs", (half) => { half.selected.changeIds[0] = "different-change"; half.journey.changeIds[0] = "different-change"; }],
    ["reply", (half) => {
      const old = half.selected.replyId;
      half.selected.replyId = "different-reply";
      half.journey.replyId = "different-reply";
      half.journey.copyValue = "different-reply";
      for (const capture of half.captures as any[]) capture.route = capture.route.replace(old, "different-reply");
    }],
    ["ticket", (half) => {
      const old = half.selected.ticketId;
      half.selected.ticketId = "different-ticket";
      half.journey.ticketId = "different-ticket";
      for (const capture of half.captures as any[]) capture.route = capture.route.replace(old, "different-ticket");
    }],
    ["actor", (half) => { half.selected.actorId = "different-actor"; half.journey.actorId = "different-actor"; }],
    ["event time", (half) => { half.selected.eventTime = "2026-05-27T14:30:00+00:00"; half.journey.eventTime = "2026-05-27T14:30:00+00:00"; }],
    ["recording time", (half) => { half.selected.actionInsertedAt = "2026-11-13T10:06:36.944698+00:00"; half.journey.actionInsertedAt = "2026-11-13T10:06:36.944698+00:00"; }],
    ["materialization fingerprint", (half) => { half.materializationSha256 = hash("7"); }],
    ["history fingerprint", (half) => { half.historySha256 = hash("6"); }],
    ["history count", (half) => { half.historyChangeCount = 4; }],
  ];
  for (const [name, mutate] of mutations) {
    const root = mkdtempSync(join(tmpdir(), "phase250-live-bind-"));
    try {
      const before = makeHalf("before");
      mutate(before);
      writeCandidate(root, before); // Recomputed candidate pointer digest keeps each capsule internally self-consistent.
      assert.throws(() => validateBeforeCandidateReceipt(root, "baseline-correction-test", liveFor(makeHalf("before"))), /live|fingerprint|materialization|history/i, name);
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  }

  const root = mkdtempSync(join(tmpdir(), "phase250-live-bind-clean-"));
  try {
    const before = makeHalf("before");
    writeCandidate(root, before);
    assert.equal(validateBeforeCandidateReceipt(root, "baseline-correction-test", liveFor(before)).candidateId, "baseline-correction-test");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("capture receipt resolves nested files, checks digests, and rejects missing or symlink-escaped bytes", () => {
  const cleanRoot = mkdtempSync(join(tmpdir(), "phase250-capture-clean-"));
  try {
    const half = makeHalf("before");
    materializeCaptureFiles(cleanRoot, half);
    assert.equal(assertInvestigationCaptureFiles(cleanRoot, half), 26);
    const shellFile = resolve(cleanRoot, half.captures[0]!.shell.file);
    assert.equal(digest(readFileSync(shellFile)), half.captures[0]!.shell.sha256);
  } finally {
    rmSync(cleanRoot, { recursive: true, force: true });
  }

  for (const failure of ["missing", "changed", "nested symlink escape"] as const) {
    const root = mkdtempSync(join(tmpdir(), "phase250-capture-negative-"));
    const outside = mkdtempSync(join(tmpdir(), "phase250-capture-outside-"));
    try {
      const half = makeHalf("before");
      materializeCaptureFiles(root, half);
      const file = resolve(root, half.captures[0]!.shell.file);
      if (failure === "missing") rmSync(file);
      if (failure === "changed") writeFileSync(file, "different bytes");
      if (failure === "nested symlink escape") {
        const attemptDir = dirname(file);
        rmSync(attemptDir, { recursive: true, force: true });
        const outsideFile = join(outside, basename(file));
        writeFileSync(outsideFile, "outside private root");
        symlinkSync(outside, attemptDir, "dir");
        const escapedPath = join(attemptDir, basename(file));
        if (escapedPath !== file) throw new Error("Test fixture did not target the nested shell path");
      }
      assert.throws(() => assertInvestigationCaptureFiles(root, half), /regular file|outside|bytes|missing|digest|symlink/i, failure);
    } finally {
      rmSync(root, { recursive: true, force: true });
      rmSync(outside, { recursive: true, force: true });
    }
  }
});

test("startup, serving and test freshness compare the loaded runtime source inventory", () => {
  const current = sourceIdentity(repoRoot);
  const paths = Object.keys(current.files);
  for (const path of [
    "lib/threadline/operator_surface/components/surface_header.ex",
    "lib/threadline/operator_surface/components/logo.ex",
    "lib/threadline/operator_surface/presentation.ex",
    "lib/threadline/operator_surface/ui/data.ex",
    "lib/threadline/operator_surface/ui/display.ex",
    "lib/threadline/operator_surface/live/row_history_live.ex",
    "brand/assets/logo/threadline-lockup-dark.svg",
    "brand/assets/logo/threadline-lockup-light.svg",
    "brand/assets/icon/favicon.svg",
    "brand/assets/fonts/web/FamiljenGrotesk-normal-400-700.woff2",
    "brand/assets/fonts/web/Geist-normal-400-700.woff2",
    "brand/assets/fonts/web/IBMPlexMono-normal-400.woff2",
    "brand/assets/fonts/web/IBMPlexMono-normal-500.woff2",
  ]) assert.ok(paths.includes(path), `missing source freshness input ${path}`);
  assert.doesNotThrow(() => assertLaunchedSourceFreshness(current, current, current));

  const changed = JSON.parse(JSON.stringify(current));
  const key = paths[0]!;
  changed.files[key].sha256 = hash("f");
  assert.throws(() => assertLaunchedSourceFreshness(current, changed, current), /startup source differs from current serving/i);
  assert.throws(() => assertLaunchedSourceFreshness(current, current, changed), /startup source differs from current test/i);
  assert.throws(() => assertLaunchedSourceFreshness({ files: {} }, current, current), /complete Phase250 inventory/i);
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

  const historyFingerprint = makePair();
  historyFingerprint.after.historySha256 = hash("7");
  assert.throws(() => assertInvestigationPair(historyFingerprint.before, historyFingerprint.after), /materialization/i);

  const historyCount = makePair();
  historyCount.after.historyChangeCount = 4;
  assert.throws(() => assertInvestigationPair(historyCount.before, historyCount.after), /materialization/i);

  const legacyAfter = makePair();
  legacyAfter.after.journey.navigationMode = "legacy-before";
  legacyAfter.after.journey.copyContext = "timeline";
  legacyAfter.after.journey.returnMode = "browser-back";
  assert.throws(() => assertInvestigationPair(legacyAfter.before, legacyAfter.after), /strict transaction-history copy/i);

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
    ["decoded fonts", (half) => { (half.before.captures[0] as any).assets.fonts[legacyFontNames[0]!] = undefined; }],
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


test("additional runtime helper requires actual matching startup, serving and test bytes", () => {
  const identity = additionalSourceIdentity(repoRoot);
  assert.deepEqual(Object.keys(identity.files), ["lib/threadline/operator_surface/live/timeline_live/helpers.ex"]);
  assert.doesNotThrow(() => assertAdditionalSourceFreshness(identity, identity, identity));
  assert.throws(() => assertAdditionalSourceFreshness(undefined, identity, identity), /additional runtime/i);
  assert.throws(() => assertAdditionalSourceFreshness({ files: {} }, identity, identity), /additional runtime/i);
  const changed = structuredClone(identity);
  changed.files["lib/threadline/operator_surface/live/timeline_live/helpers.ex"].sha256 = hash("f");
  assert.throws(() => assertAdditionalSourceFreshness(identity, changed, identity), /additional runtime/i);
  assert.throws(() => assertAdditionalSourceFreshness(identity, identity, changed), /additional runtime/i);
});

test("after proof rejects absent or altered additional runtime provenance while legacy before stays valid", () => {
  const pair = makePair();
  assert.doesNotThrow(() => assertInvestigationPair(pair.before, pair.after));
  delete (pair.after as any).additionalRuntimeSources;
  assert.throws(() => assertInvestigationPair(pair.before, pair.after), /additional runtime/i);
  const altered = makePair();
  (altered.after as any).additionalRuntimeSources.test.files["lib/threadline/operator_surface/live/timeline_live/helpers.ex"].bytes += 1;
  assert.throws(() => assertInvestigationPair(altered.before, altered.after), /additional runtime/i);
});


test("independent review binds exact source and capture bytes with both judgment artifacts", () => {
  const after = makeHalf("after");
  const binding = {
    reviewedRevision: "a".repeat(40), beforeCandidateId: "baseline-correction-test",
    beforeHalfSha256: hash("b"), afterFile: "captures/after/attempt/half.json", afterSha256: hash("c"),
    servingSource: after.server.servingSource, additionalRuntimeSources: after.additionalRuntimeSources,
  };
  const review = { schemaVersion: 1, status: "accepted", binding, reviewedRevision: binding.reviewedRevision,
    beforeHalfSha256: binding.beforeHalfSha256, afterSha256: binding.afterSha256, findings: [],
    reviewers: ["source-copy-security", "visual"].map((role) => ({ role, status: "passed", artifact: { file: `review/${role}.md`, sha256: hash("d") } })),
  };
  assert.equal(assertInvestigationReview(review, binding).reviewIdentityMatched, true);
  for (const field of ["reviewedRevision", "beforeHalfSha256", "afterSha256"] as const) {
    const changed = structuredClone(review); changed.binding[field] = field === "reviewedRevision" ? "f".repeat(40) : hash("f");
    assert.throws(() => assertInvestigationReview(changed, binding), /different source\/capture/);
  }
  const missing = structuredClone(review); missing.reviewers.pop();
  assert.throws(() => assertInvestigationReview(missing, binding), /artifacts are required/);
  assert.throws(() => assertInvestigationReview({ ...review, status: "pending" }, binding), /unaccepted/);
  assert.throws(() => assertInvestigationReview({ ...review, findings: [{ severity: "high", disposition: "open" }] }, binding), /unresolved high/);
  assert.equal(assertInvestigationReview({ ...review, findings: [{ severity: "high", disposition: "resolved" }] }, binding).reviewIdentityMatched, true);
});


test("after capture permits only exact retained context and preserves the prior snapshot selection", () => {
  const before = makeHalf("before"); const after = makeHalf("after");
  assert.equal(assertInvestigationPair(before, after).matched, true);
  for (const suffix of ["&unexpected=1", "&origin=timeline", "&table=tickets"]) {
    const changed = structuredClone(after); changed.captures[0]!.route += suffix;
    assert.throws(() => assertInvestigationPair(before, changed), /incomplete or incomparable/);
  }
  const changedFilter = structuredClone(after);
  changedFilter.captures[0]!.route = changedFilter.captures[0]!.route.replace("table=ticket_replies", "table=tickets");
  assert.throws(() => assertInvestigationPair(before, changedFilter), /incomplete or incomparable/);
  const changedSnapshot = structuredClone(after);
  changedSnapshot.captures[2]!.route = changedSnapshot.captures[2]!.route.replace("2026-05-01", "2026-05-02");
  assert.throws(() => assertInvestigationPair(before, changedSnapshot), /route differs/);
});


test("pair routes reject absolute, protocol-relative and nonlocal route evidence", () => {
  for (const prefix of ["https://outside.example", "http://127.0.0.1:60150", "//outside.example", "/" + String.fromCharCode(92) + "outside.example"]) {
    const before = makeHalf("before"); const after = makeHalf("after");
    before.journey.timelineUrl = prefix + before.journey.timelineUrl;
    assert.throws(() => assertInvestigationPair(before, after), /Invalid or incomplete/);
    const cleanBefore = makeHalf("before");
    after.captures[0]!.route = prefix + after.captures[0]!.route;
    assert.throws(() => assertInvestigationPair(cleanBefore, after), /incomplete or incomparable/);
  }
  for (const suffix of ["#fragment", "\n"]) {
    const before = makeHalf("before"); const after = makeHalf("after"); after.captures[0]!.route += suffix;
    assert.throws(() => assertInvestigationPair(before, after), /incomplete or incomparable/);
  }
});
