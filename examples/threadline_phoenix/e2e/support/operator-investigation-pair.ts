import { createHash, randomUUID } from "node:crypto";
import {
  appendFileSync,
  existsSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  realpathSync,
} from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import type { Browser, Page, TestInfo } from "@playwright/test";
import {
  atomicWriteFile,
  resolveContainedPath,
} from "./operator-surface-paths.js";
import { assertNoCanaryLeak } from "./operator-evidence-manifest.js";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
const canary = "synthetic-secret-canary-239-6f71";
const expectedAction = "ticket_replied_and_closed";
const expectedCorrelation = "walk-acme-4521-close";
const expectedDatabase = "threadline_phoenix_testp250pair";
const expectedPartition = "p250pair";
const expectedSystemId = "7706932079119234489";
const forbiddenAppPorts = new Set([5432, 60025]);
const digestPattern = /^[a-f0-9]{64}$/;

const styleFiles = [
  "01_tokens.css", "02_base_shell.css", "03_page_home.css", "04_controls.css",
  "05_feedback.css", "06_layout_primitives.css", "07_find_detail.css",
  "08_overlays_motion.css", "09_responsive.css",
];
const embeddedFonts = [
  ["Geist", 400, "geist-400.woff2"], ["Geist", 500, "geist-500.woff2"],
  ["Geist", 600, "geist-600.woff2"], ["IBM Plex Mono", 400, "ibm-plex-mono-400.woff2"],
  ["IBM Plex Mono", 500, "ibm-plex-mono-500.woff2"],
] as const;
const productionSources = [
  "lib/threadline/operator_surface/live/timeline_live.ex",
  "lib/threadline/operator_surface/live/timeline_live/changes.ex",
  "lib/threadline/operator_surface/live/transaction_live.ex",
  "lib/threadline/operator_surface/live/row_history_component.ex",
  "lib/threadline/operator_surface/style.ex",
  "lib/threadline/operator_surface/fonts.ex",
  "lib/threadline/operator_surface/script.ex",
  "lib/threadline/operator_surface/components/icon.ex",
  ...styleFiles.map((file) => `lib/threadline/operator_surface/style/${file}`),
  ...embeddedFonts.map(([, , file]) => `priv/fonts/${file}`),
];

type Materialization = {
  readonly sha256: string;
  readonly snapshot: {
    readonly database: string;
    readonly actions: readonly Record<string, unknown>[];
    readonly transactions: readonly Record<string, unknown>[];
    readonly changes: readonly Record<string, unknown>[];
    readonly ticket_row_hashes: readonly { id: string; sha256: string }[];
    readonly reply_row_hashes: readonly { id: string; sha256: string }[];
  };
  readonly method?: string;
};
type AppReceipt = {
  readonly checkout: string;
  readonly database: string;
  readonly db_host: string;
  readonly db_port: number;
  readonly pair_partition: string;
  readonly pg_system_id: string;
  readonly pid: number;
  readonly port: number;
  readonly source_head: string;
  readonly status: string;
  readonly url: string;
  readonly materialization: string;
};

export type InvestigationJourney = {
  readonly timelineUrl: string;
  readonly actionId: string;
  readonly transactionId: string;
  readonly changeIds: readonly string[];
  readonly replyId: string;
  readonly ticketId: string;
  readonly actorId: string;
  readonly eventTime: string;
  readonly actionInsertedAt: string;
  readonly copyValue: string;
  readonly copyStatus: string;
  readonly keyboardActivation: boolean;
  readonly filtersRestored: boolean;
};

type AssetIdentity = { readonly sha256: string; readonly bytes?: number };
type SourceIdentity = { readonly files: Readonly<Record<string, AssetIdentity>> };
type ServedAssetIdentity = {
  readonly stylesheetSha256: string;
  readonly fontFaceCount: number;
  readonly fonts: Readonly<Record<string, AssetIdentity>>;
  readonly inlineScriptSha256: string | null;
  readonly svgCount: number;
  readonly svgMarkupSha256: string;
};
type BrowserCondition = {
  readonly project: string;
  readonly browser: string;
  readonly playwright: string;
  readonly viewport: { readonly width: number; readonly height: number; readonly dpr: number };
  readonly preference: string;
  readonly mountedTheme: string;
  readonly effectiveTheme: string;
  readonly systemScheme: string;
  readonly reducedMotion: boolean;
  readonly browserZoom: "unverified";
};
export type InvestigationCapture = {
  readonly id: string;
  readonly route: string;
  readonly state: string;
  readonly condition: BrowserCondition;
  readonly shell: AssetIdentity & { readonly file: string };
  readonly content: AssetIdentity & { readonly file: string };
  readonly observation: AssetIdentity & { readonly file: string };
  readonly assets: ServedAssetIdentity;
};
export type InvestigationHalf = {
  readonly schemaVersion: 1;
  readonly half: "before" | "after";
  readonly capturedAt: string;
  readonly canonical: boolean;
  readonly pairId: string;
  readonly materializationSha256: string;
  readonly selected: {
    readonly database: string;
    readonly partition: string;
    readonly httpPort: number;
    readonly actionId: string;
    readonly actionName: string;
    readonly transactionId: string;
    readonly changeIds: readonly string[];
    readonly replyId: string;
    readonly ticketId: string;
    readonly actorId: string;
    readonly eventTime: string;
    readonly actionInsertedAt: string;
  };
  readonly server: {
    readonly pid: number;
    readonly port: number;
    readonly sourceHeadAtStart: string;
    readonly servingSource: SourceIdentity;
  };
  readonly testSource: SourceIdentity;
  readonly browser: { readonly project: string; readonly version: string; readonly playwright: string };
  readonly journey: InvestigationJourney;
  readonly captures: readonly InvestigationCapture[];
};

const sha256 = (value: string | Uint8Array) => createHash("sha256").update(value).digest("hex");
const now = () => new Date().toISOString();
const require = createRequire(import.meta.url);
const playwrightVersion = () => require("@playwright/test/package.json").version as string;

function pairRoot(): string {
  const value = process.env.THREADLINE_PHASE250_PAIR_ROOT;
  if (!value || !isAbsolute(value) || !existsSync(value)) throw new Error("Missing durable absolute THREADLINE_PHASE250_PAIR_ROOT");
  const root = realpathSync(value);
  const worktree = realpathSync(repoRoot);
  if (root === worktree || root.startsWith(`${worktree}${sep}`) || worktree.startsWith(`${root}${sep}`)) {
    throw new Error("The Phase250 pair root must stay outside disposable source checkouts");
  }
  return root;
}

function appReceiptPath(root = pairRoot()): string {
  return resolve(dirname(root), "threadline-250-app.json");
}

function materializationPath(root = pairRoot()): string {
  return resolve(root, "materialization.json");
}

function readJson<T>(path: string): T {
  return JSON.parse(readFileSync(path, "utf8")) as T;
}

export function readInvestigationMaterialization(): Materialization {
  const value = readJson<Materialization>(materializationPath());
  assertMaterialization(value);
  return value;
}

function assertMaterialization(value: Materialization): void {
  if (value.snapshot.database !== expectedDatabase || value.snapshot.actions.length !== 1 ||
      value.snapshot.transactions.length !== 1 || value.snapshot.changes.length !== 2) {
    throw new Error("Pair materialization must contain one selected action, transaction and two changes in its owned database");
  }
  const [action] = value.snapshot.actions as Array<Record<string, any>>;
  const [transaction] = value.snapshot.transactions as Array<Record<string, any>>;
  const actionTime = Date.parse(action.inserted_at);
  const eventTime = Date.parse(transaction.occurred_at);
  if (action.name !== expectedAction || action.correlation_id !== expectedCorrelation || action.actor_ref?.type !== "user" ||
      !action.id || !action.actor_ref?.id || !Number.isFinite(actionTime) || !Number.isFinite(eventTime) || actionTime === eventTime ||
      transaction.action_id !== action.id || transaction.actor_ref?.id !== action.actor_ref?.id || !transaction.id) {
    throw new Error("Pair materialization does not identify the selected Acme close action and transaction");
  }
  const byTable = new Map(value.snapshot.changes.map((change: any) => [change.table_name, change]));
  const reply: any = byTable.get("ticket_replies");
  const ticket: any = byTable.get("tickets");
  if (!reply || !ticket || reply.op !== "insert" || ticket.op !== "update" || reply.transaction_id !== transaction.id || ticket.transaction_id !== transaction.id ||
      !reply.id || !ticket.id || reply.table_pk?.id !== reply.data_after?.id || ticket.table_pk?.id !== ticket.data_after?.id ||
      reply.captured_at !== transaction.occurred_at || ticket.captured_at !== transaction.occurred_at ||
      reply.data_after?.body !== "Thanks — we're closing this out." || reply.data_after?.internal_note_body !== "[REDACTED]" ||
      ticket.data_after?.number !== 4521 || ticket.data_after?.status !== "closed" ||
      ticket.data_after?.closed_at !== "2026-05-26T14:30:00") {
    throw new Error("Pair materialization is missing the expected redacted reply or ticket close state");
  }
  const changeIds = value.snapshot.changes.map((change: any) => change.id);
  const validRowHashes = (rows: readonly { id: string; sha256: string }[], id: string) =>
    rows.length === 1 && rows[0]?.id === id && digestPattern.test(rows[0].sha256);
  if (new Set(changeIds).size !== 2 ||
      !validRowHashes(value.snapshot.ticket_row_hashes, ticket.table_pk.id) ||
      !validRowHashes(value.snapshot.reply_row_hashes, reply.table_pk.id)) {
    throw new Error("Pair materialization is missing unique changes or the selected subject-row fingerprints");
  }
  const serialized = JSON.stringify(value);
  if (serialized.includes(canary) || !/^[a-f0-9]{64}$/.test(value.sha256)) {
    throw new Error("Pair materialization is malformed or exposes the seeded secret canary");
  }
}

function readAppReceipt(): AppReceipt {
  const receipt = readJson<AppReceipt>(appReceiptPath());
  if (receipt.status !== "ready" || receipt.database !== expectedDatabase || receipt.pair_partition !== expectedPartition ||
      !Number.isInteger(receipt.port) || receipt.port < 1 || receipt.port > 65535 || forbiddenAppPorts.has(receipt.port) ||
      receipt.db_port !== 60025 || receipt.db_host !== "127.0.0.1" || receipt.pg_system_id !== expectedSystemId ||
      receipt.url !== `http://127.0.0.1:${receipt.port}` || receipt.materialization !== materializationPath()) {
    throw new Error("Parent app receipt does not match the preserved pair service identity");
  }
  return receipt;
}

function sourceIdentity(root: string): SourceIdentity {
  const files: Record<string, AssetIdentity> = {};
  for (const path of productionSources) {
    const bytes = readFileSync(resolve(root, path));
    files[path] = { sha256: sha256(bytes), bytes: bytes.byteLength };
  }
  return { files };
}

function sameSource(left: SourceIdentity, right: SourceIdentity): boolean {
  return JSON.stringify(left.files) === JSON.stringify(right.files);
}

function inspectOwnedListener(receipt: AppReceipt) {
  const listener = execFileSync("lsof", ["-nP", "-a", "-p", String(receipt.pid), `-iTCP:${receipt.port}`, "-sTCP:LISTEN", "-Fp"], { encoding: "utf8" }).trim();
  const cwdOutput = execFileSync("lsof", ["-a", "-p", String(receipt.pid), "-d", "cwd", "-Fn"], { encoding: "utf8" }).trim();
  const actualCwd = cwdOutput.split("\n").find((line) => line.startsWith("n"))?.slice(1);
  const expectedCwd = appWorkingDirectory(receipt);
  assertServingCheckout(receipt.checkout);
  if (!actualCwd) throw new Error("The recorded app PID has no discoverable working directory");
  assertListenerIdentity(receipt.pid, listener, actualCwd, expectedCwd);
  return { actualCwd, listener };
}

function appWorkingDirectory(receipt: AppReceipt): string {
  return resolve(receipt.checkout, "examples/threadline_phoenix");
}

export function assertServingCheckout(checkout: string): string {
  if (!isAbsolute(checkout)) throw new Error("Retained serving checkout must be an absolute path");
  try {
    return realpathSync(checkout);
  } catch {
    throw new Error("Retained serving checkout is missing or unavailable");
  }
}

export function assertListenerIdentity(pid: number, listener: string, actualCwd: string, expectedCwd: string): void {
  if (!Number.isInteger(pid) || pid <= 0 || listener.split("\n", 1)[0] !== `p${pid}` ||
      !isAbsolute(actualCwd) || !isAbsolute(expectedCwd) ||
      realpathSync(actualCwd) !== realpathSync(expectedCwd)) {
    throw new Error("The recorded app PID does not own the expected HTTP listener and retained serving checkout");
  }
}

async function assertLivePair(receipt = readAppReceipt()) {
  if (assertServingCheckout(receipt.checkout) === realpathSync(repoRoot)) throw new Error("The serving app and test source checkout must be distinct");
  const listener = inspectOwnedListener(receipt);
  const response = await fetch(`${receipt.url}/users/log_in`, { signal: AbortSignal.timeout(5000) });
  if (response.status !== 200) throw new Error(`Retained app readiness returned HTTP ${response.status}`);
  const servingSource = sourceIdentity(receipt.checkout);
  const testSource = sourceIdentity(repoRoot);
  if (!sameSource(servingSource, testSource)) throw new Error("Mounted production source/assets differ between the retained app and test checkout");
  return { listener, servingSource, testSource };
}

function checkMaterialization(): { readonly matched: true; readonly sha256: string } {
  const materialization = readInvestigationMaterialization();
  const helper = resolve(dirname(pairRoot()), "threadline-250-materialization.py");
  const result = execFileSync("python3", [helper, "--check"], { encoding: "utf8", timeout: 15_000 });
  const parsed = JSON.parse(result) as { matched: boolean; sha256: string };
  if (parsed.matched !== true || parsed.sha256 !== materialization.sha256) throw new Error("Live selected-row materialization changed after the preserved before snapshot");
  return { matched: true, sha256: parsed.sha256 };
}

function appendInvocation(record: Record<string, unknown>) {
  const log = resolve(pairRoot(), "executor-invocations.jsonl");
  const safe = JSON.stringify({ at: now(), ...record });
  assertNoCanaryLeak(canary, "phase250 invocation log", safe);
  appendFileSync(log, `${safe}\n`, { mode: 0o600 });
}

function assertJourney(journey: InvestigationJourney, materialization: Materialization): void {
  const [action] = materialization.snapshot.actions as Array<Record<string, any>>;
  const [transaction] = materialization.snapshot.transactions as Array<Record<string, any>>;
  const reply: any = materialization.snapshot.changes.find((change: any) => change.table_name === "ticket_replies");
  const ticket: any = materialization.snapshot.changes.find((change: any) => change.table_name === "tickets");
  const replyId = reply?.table_pk?.id;
  const ticketId = ticket?.table_pk?.id;
  const eventTime = transaction.occurred_at;
  const returnedUrl = new URL(journey.timelineUrl, "http://127.0.0.1");
  const returnedParams = returnedUrl.searchParams;
  const exactFilterKeys = [...returnedParams.keys()].sort().join(",");
  if (journey.actionId !== action.id || journey.transactionId !== transaction.id || journey.replyId !== replyId ||
      journey.ticketId !== ticketId || journey.actorId !== action.actor_ref?.id ||
      journey.eventTime !== eventTime || journey.actionInsertedAt !== action.inserted_at ||
      returnedUrl.pathname !== "/audit/timeline" || exactFilterKeys !== "correlation_id,from,table,to" ||
      returnedParams.get("from") !== "2020-01-01T00:00" || returnedParams.get("to") !== "2099-01-01T00:00" ||
      returnedParams.get("table") !== "ticket_replies" || returnedParams.get("correlation_id") !== expectedCorrelation ||
      journey.changeIds.length !== 2 || !journey.changeIds.includes(reply.id) || !journey.changeIds.includes(ticket.id) ||
      journey.copyValue !== replyId || journey.copyStatus !== "Copied." || journey.keyboardActivation !== true ||
      journey.filtersRestored !== true) {
    throw new Error("Rendered whole-investigation journey did not bind to the exact selected records, copy control and restored query");
  }
}

async function pageAssetIdentity(page: Page, root: string): Promise<ServedAssetIdentity> {
  const styles = await page.locator("style").allTextContents();
  const stylesheet = styles.find((value) => value.includes(".threadline-ui"));
  const fontStyle = styles.find((value) => value.includes("data:font/woff2;base64,"));
  if (!stylesheet || !fontStyle) throw new Error("Served operator CSS or embedded font face is missing");
  const localStyle = styleFiles.map((file) => readFileSync(join(root, "lib/threadline/operator_surface/style", file), "utf8")).join("");
  if (stylesheet !== localStyle) throw new Error("Served mounted stylesheet bytes differ from the actual serving source segments");
  const encoded = [...fontStyle.matchAll(/data:font\/woff2;base64,([A-Za-z0-9+/=]+)/g)].map((match) => Buffer.from(match[1]!, "base64"));
  if (encoded.length !== embeddedFonts.length) throw new Error(`Expected ${embeddedFonts.length} actual embedded WOFF2 faces, found ${encoded.length}`);
  const fonts: Record<string, AssetIdentity> = {};
  for (const [index, [, , file]] of embeddedFonts.entries()) {
    const served = encoded[index]!;
    const local = readFileSync(join(root, "priv/fonts", file));
    if (!Buffer.from(served).equals(local)) throw new Error(`Served font bytes do not match ${file}`);
    fonts[file] = { sha256: sha256(served), bytes: served.byteLength };
  }
  const scripts = await page.locator("script").allTextContents();
  const inlineScript = scripts.find((value) => value.includes("__tlCopyBound")) ?? null;
  if (!inlineScript) throw new Error("Mounted delegated copy script is missing");
  const svgs = await page.locator(".threadline-ui svg").evaluateAll((nodes) => nodes.map((node) => node.outerHTML));
  if (!svgs.length) throw new Error("No rendered Threadline SVG icons found");
  return {
    stylesheetSha256: sha256(stylesheet), fontFaceCount: encoded.length, fonts,
    inlineScriptSha256: sha256(inlineScript), svgCount: svgs.length,
    svgMarkupSha256: sha256(svgs.join("\n")),
  };
}

async function observeCondition(page: Page, browser: Browser, info: TestInfo): Promise<BrowserCondition> {
  const root = page.locator(".threadline-ui").first();
  const dom = await root.evaluate((element) => {
    const selected = element.querySelector<HTMLInputElement>('input[name="theme"]:checked');
    const style = getComputedStyle(element);
    return {
      preference: selected?.value ?? "unknown",
      mountedTheme: element.getAttribute("data-tl-theme") ?? "unknown",
      effectiveTheme: style.colorScheme,
      systemScheme: matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark",
      reducedMotion: matchMedia("(prefers-reduced-motion: reduce)").matches,
      dpr: devicePixelRatio,
    };
  });
  const viewport = page.viewportSize();
  if (!viewport) throw new Error("Browser viewport is not measurable");
  return {
    project: info.project.name,
    browser: browser.version(),
    playwright: playwrightVersion(),
    viewport: { width: viewport.width, height: viewport.height, dpr: dom.dpr },
    preference: dom.preference,
    mountedTheme: dom.mountedTheme,
    effectiveTheme: dom.effectiveTheme,
    systemScheme: dom.systemScheme,
    reducedMotion: dom.reducedMotion,
    browserZoom: "unverified",
  };
}

async function applyTheme(page: Page, preference: "dark" | "light" | "system", system: "dark" | "light") {
  await page.emulateMedia({ colorScheme: system, reducedMotion: "reduce" });
  await page.locator(`input[name="theme"][value="${preference}"]`).check();
  await page.getByRole("button", { name: "Apply theme", exact: true }).click();
  await page.waitForFunction((value) => document.querySelector(".threadline-ui")?.getAttribute("data-tl-theme") === value, preference);
}

async function captureLane(
  page: Page,
  browser: Browser,
  info: TestInfo,
  sourceRoot: string,
  outputRoot: string,
  relativeDir: string,
  id: string,
  state: string,
  preference: "dark" | "light",
  system: "dark" | "light",
  servingSource: SourceIdentity,
  testSource: SourceIdentity,
): Promise<InvestigationCapture> {
  await applyTheme(page, preference, system);
  const shell = page.locator(".threadline-ui").first();
  const content = page.locator("#tl-main");
  const url = new URL(page.url());
  const condition = await observeCondition(page, browser, info);
  if (condition.effectiveTheme !== preference || condition.preference !== preference || condition.reducedMotion !== true) {
    throw new Error(`Theme/motion condition failed for ${id}`);
  }
  const assets = await pageAssetIdentity(page, sourceRoot);
  const outputDir = resolveContainedPath(outputRoot, relativeDir);
  mkdirSync(outputDir, { recursive: true, mode: 0o700 });
  const shellPath = resolveContainedPath(outputDir, `${id}-shell.png`);
  const contentPath = resolveContainedPath(outputDir, `${id}-content.png`);
  await shell.screenshot({ path: shellPath, animations: "disabled", scale: "css" });
  await content.screenshot({ path: contentPath, animations: "disabled", scale: "css", mask: [page.locator("time"), page.locator('[data-dynamic="true"]')], maskColor: preference === "light" ? "#F8FAFC" : "#0B1020" });
  const shellBytes = readFileSync(shellPath);
  const contentBytes = readFileSync(contentPath);
  assertNoCanaryLeak(canary, shellPath, shellBytes);
  assertNoCanaryLeak(canary, contentPath, contentBytes);
  const observation = {
    id, route: url.pathname + url.search, state, condition,
    assets,
    source: { test: testSource, serving: servingSource },
    viewport: condition.viewport,
    browserZoom: "unverified",
    capturedAt: now(),
  };
  const observationPath = resolveContainedPath(outputDir, `${id}-observation.json`);
  const serialized = `${JSON.stringify(observation, null, 2)}\n`;
  assertNoCanaryLeak(canary, observationPath, serialized);
  atomicWriteFile(observationPath, serialized);
  const identity = (file: string, bytes: Buffer) => ({ file, sha256: sha256(bytes), bytes: bytes.byteLength });
  return {
    id, route: observation.route, state, condition,
    shell: identity(relative(outputRoot, shellPath), shellBytes),
    content: identity(relative(outputRoot, contentPath), contentBytes),
    observation: identity(relative(outputRoot, observationPath), Buffer.from(serialized)),
    assets,
  };
}

async function captureSystemObservations(
  page: Page,
  browser: Browser,
  info: TestInfo,
  sourceRoot: string,
  outputRoot: string,
  relativeDir: string,
  servingSource: SourceIdentity,
  testSource: SourceIdentity,
) {
  const observations = [];
  for (const system of ["dark", "light"] as const) {
    await applyTheme(page, "system", system);
    const condition = await observeCondition(page, browser, info);
    if (condition.preference !== "system" || condition.mountedTheme !== "system" || condition.effectiveTheme !== system || condition.systemScheme !== system) {
      throw new Error(`System scheme observation did not resolve to ${system}`);
    }
    const observation = {
      id: `system-${system}`, route: new URL(page.url()).pathname + new URL(page.url()).search,
      condition, assets: await pageAssetIdentity(page, sourceRoot), source: { serving: servingSource, test: testSource },
      capturedAt: now(),
    };
    const directory = resolveContainedPath(outputRoot, relativeDir);
    mkdirSync(directory, { recursive: true, mode: 0o700 });
    const path = resolveContainedPath(directory, `${observation.id}-observation.json`);
    const text = `${JSON.stringify(observation, null, 2)}\n`;
    assertNoCanaryLeak(canary, path, text);
    atomicWriteFile(path, text);
    observations.push({ id: observation.id, file: relative(outputRoot, path), sha256: sha256(text), condition });
  }
  return observations;
}

export async function captureInvestigationHalf(
  page: Page,
  browser: Browser,
  info: TestInfo,
  journey: InvestigationJourney,
): Promise<InvestigationHalf> {
  const half = process.env.THREADLINE_PHASE250_PAIR_HALF;
  if (half !== "before" && half !== "after") throw new Error("Set THREADLINE_PHASE250_PAIR_HALF to before or after");
  if (info.project.name !== "desktop-chromium") throw new Error("The selected pair capture is limited to desktop-chromium");
  const root = pairRoot();
  const materialization = readInvestigationMaterialization();
  assertJourney(journey, materialization);
  const actual = checkMaterialization();
  const receipt = readAppReceipt();
  const live = await assertLivePair(receipt);
  if (actual.sha256 !== materialization.sha256 || forbiddenAppPorts.has(receipt.port) ||
      process.env.MIX_TEST_PARTITION !== expectedPartition || process.pid === receipt.pid) {
    throw new Error("Pair materialization, protected port, or assigned partition differs from the parent binding");
  }
  await page.waitForFunction(() => document.querySelector("[data-phx-main]")?.classList.contains("phx-connected") === true);
  const capturedAt = now();
  const halfDir = resolve(root, "captures", half);
  mkdirSync(halfDir, { recursive: true, mode: 0o700 });
  const canonical = !existsSync(resolve(halfDir, "canonical.json"));
  const pairId = randomUUID();
  const attemptName = `${capturedAt.replaceAll(":", "-")}-${pairId}`;
  const relativeDir = relative(root, resolve(halfDir, attemptName));
  const captures: InvestigationCapture[] = [];
  for (const theme of ["dark", "light"] as const) {
    captures.push(await captureLane(page, browser, info, repoRoot, root, relativeDir, `timeline-restored-${theme}`, "filtered-timeline-return", theme, "dark", live.servingSource, live.testSource));
  }
  const systemObservations = await captureSystemObservations(page, browser, info, repoRoot, root, relativeDir, live.servingSource, live.testSource);
  await applyTheme(page, "dark", "dark");
  const selected = materialization.snapshot;
  const [action] = selected.actions as Array<Record<string, any>>;
  const [transaction] = selected.transactions as Array<Record<string, any>>;
  const manifest: InvestigationHalf = {
    schemaVersion: 1,
    half,
    capturedAt,
    canonical,
    pairId,
    materializationSha256: materialization.sha256,
    selected: {
      database: selected.database,
      partition: expectedPartition,
      httpPort: receipt.port,
      actionId: action.id,
      actionName: action.name,
      transactionId: transaction.id,
      changeIds: [...journey.changeIds].sort(),
      replyId: journey.replyId,
      ticketId: journey.ticketId,
      actorId: journey.actorId,
      eventTime: journey.eventTime,
      actionInsertedAt: journey.actionInsertedAt,
    },
    server: { pid: receipt.pid, port: receipt.port, sourceHeadAtStart: receipt.source_head, servingSource: live.servingSource },
    testSource: live.testSource,
    browser: { project: info.project.name, version: browser.version(), playwright: playwrightVersion() },
    journey,
    captures,
  };
  const final = { ...manifest, systemObservations };
  const output = resolveContainedPath(root, `captures/${half}/${attemptName}/half.json`);
  mkdirSync(dirname(output), { recursive: true, mode: 0o700 });
  const serialized = `${JSON.stringify(final, null, 2)}\n`;
  assertNoCanaryLeak(canary, output, serialized);
  atomicWriteFile(output, serialized);
  if (canonical) atomicWriteFile(resolveContainedPath(root, `captures/${half}/canonical.json`), JSON.stringify({ file: relative(root, output), sha256: sha256(serialized), pairId }, null, 2) + "\n");
  appendInvocation({
    type: "pair-capture", half, pairId, canonical, materializationSha256: materialization.sha256,
    output: relative(root, output), runnerPid: process.pid, testCheckout: repoRoot,
    appPid: receipt.pid, appCheckout: receipt.checkout, appCwd: live.listener.actualCwd, status: "passed",
  });
  return manifest;
}

function validDigest(value: unknown): value is string {
  return typeof value === "string" && digestPattern.test(value);
}

function validAssetIdentity(value: any): boolean {
  return validDigest(value?.sha256) && Number.isInteger(value?.bytes) && value.bytes > 0;
}

function capturedFileBelongsToHalf(file: unknown, half: "before" | "after"): boolean {
  if (typeof file !== "string" || !file || isAbsolute(file) || /^[A-Za-z]:[\\/]/.test(file)) return false;
  const parts = file.split(/[\\/]+/);
  return parts[0] === "captures" && parts[1] === half && !parts.includes("..") && !parts.includes(".");
}

function validSourceIdentity(value: any): boolean {
  if (!value?.files || typeof value.files !== "object" || Array.isArray(value.files) || Object.keys(value.files).length === 0) return false;
  return Object.entries(value.files).every(([path, asset]: [string, any]) => Boolean(path) && validAssetIdentity(asset));
}

function validBrowserCondition(condition: any, browser: any): boolean {
  return condition?.project === browser.project && condition?.browser === browser.version &&
    condition?.playwright === browser.playwright && condition?.reducedMotion === true &&
    condition?.browserZoom === "unverified" && condition?.viewport?.width === 1280 &&
    condition?.viewport?.height === 900 && condition?.viewport?.dpr === 1;
}

function validateHalf(value: any, expectedHalf: "before" | "after") {
  const selected = value?.selected;
  const browser = value?.browser;
  const journey = value?.journey;
  const route = typeof journey?.timelineUrl === "string" ? new URL(journey.timelineUrl, "http://127.0.0.1") : null;
  const routeKeys = route ? [...route.searchParams.keys()].sort().join(",") : "";
  if (!value || value.schemaVersion !== 1 || value.half !== expectedHalf || value.canonical !== true ||
      typeof value.pairId !== "string" || !value.pairId || !validDigest(value.materializationSha256) ||
      !Number.isFinite(Date.parse(value.capturedAt)) || selected?.database !== expectedDatabase || selected?.partition !== expectedPartition ||
      !Number.isInteger(selected?.httpPort) || selected.httpPort < 1 || selected.httpPort > 65535 || forbiddenAppPorts.has(selected.httpPort) ||
      !selected?.actionId || selected.actionName !== expectedAction || !selected?.transactionId ||
      !Array.isArray(selected.changeIds) || selected.changeIds.length !== 2 || new Set(selected.changeIds).size !== 2 ||
      !selected?.replyId || !selected?.ticketId || !selected?.actorId ||
      !Number.isFinite(Date.parse(selected.eventTime)) || !Number.isFinite(Date.parse(selected.actionInsertedAt)) ||
      Date.parse(selected.eventTime) === Date.parse(selected.actionInsertedAt) ||
      !Number.isInteger(value.server?.pid) || value.server.pid <= 0 || value.server?.port !== selected.httpPort ||
      !/^[a-f0-9]{40}$/.test(value.server?.sourceHeadAtStart ?? "") ||
      !validSourceIdentity(value.testSource) || !validSourceIdentity(value.server?.servingSource) ||
      !sameSource(value.testSource, value.server.servingSource) ||
      browser?.project !== "desktop-chromium" || !browser.version || !browser.playwright ||
      !journey || journey.actionId !== selected.actionId || journey.transactionId !== selected.transactionId ||
      JSON.stringify([...(journey.changeIds ?? [])].sort()) !== JSON.stringify([...selected.changeIds].sort()) ||
      journey.replyId !== selected.replyId || journey.ticketId !== selected.ticketId || journey.actorId !== selected.actorId ||
      journey.eventTime !== selected.eventTime || journey.actionInsertedAt !== selected.actionInsertedAt ||
      journey.copyValue !== selected.replyId || journey.copyStatus !== "Copied." || journey.keyboardActivation !== true ||
      journey.filtersRestored !== true || !route || route.pathname !== "/audit/timeline" || routeKeys !== "correlation_id,from,table,to" ||
      route.searchParams.get("from") !== "2020-01-01T00:00" || route.searchParams.get("to") !== "2099-01-01T00:00" ||
      route.searchParams.get("table") !== "ticket_replies" || route.searchParams.get("correlation_id") !== expectedCorrelation ||
      !Array.isArray(value.captures) || value.captures.length !== 2 ||
      !Array.isArray(value.systemObservations) || value.systemObservations.length !== 2) {
    throw new Error(`Invalid or incomplete ${expectedHalf} investigation half`);
  }
  const ids = new Set(value.captures.map((capture: any) => capture?.id));
  if (ids.size !== 2 || !ids.has("timeline-restored-dark") || !ids.has("timeline-restored-light")) {
    throw new Error(`${expectedHalf} half lacks matching dark/light shell and content captures`);
  }
  for (const capture of value.captures) {
    const theme = capture.id.endsWith("dark") ? "dark" : "light";
    const fontNames = Object.keys(capture.assets?.fonts ?? {}).sort();
    if (!capture.route || capture.route !== journey.timelineUrl || capture.state !== "filtered-timeline-return" ||
        !validBrowserCondition(capture.condition, browser) || capture.condition.preference !== theme ||
        capture.condition.mountedTheme !== theme || capture.condition.effectiveTheme !== theme || capture.condition.systemScheme !== "dark" ||
        !capturedFileBelongsToHalf(capture.shell?.file, expectedHalf) || !validAssetIdentity(capture.shell) ||
        !capturedFileBelongsToHalf(capture.content?.file, expectedHalf) || !validAssetIdentity(capture.content) ||
        !capturedFileBelongsToHalf(capture.observation?.file, expectedHalf) || !validAssetIdentity(capture.observation) ||
        capture.assets?.fontFaceCount !== embeddedFonts.length ||
        JSON.stringify(fontNames) !== JSON.stringify(embeddedFonts.map(([, , file]) => file).sort()) ||
        !validDigest(capture.assets?.stylesheetSha256) || !validDigest(capture.assets?.inlineScriptSha256) ||
        !validDigest(capture.assets?.svgMarkupSha256) || !Number.isInteger(capture.assets?.svgCount) || capture.assets.svgCount <= 0 ||
        !Object.values(capture.assets.fonts).every((font: any) => validAssetIdentity(font))) {
      throw new Error(`${expectedHalf} half has incomplete or incomparable browser/source/assets evidence`);
    }
  }
  const expectedSystemIds = ["system-dark", "system-light"];
  for (const [index, observation] of value.systemObservations.entries()) {
    const system = index === 0 ? "dark" : "light";
    if (observation.id !== expectedSystemIds[index] || !capturedFileBelongsToHalf(observation.file, expectedHalf) ||
        !validDigest(observation.sha256) || observation.condition?.project !== browser.project ||
        observation.condition?.browser !== browser.version || observation.condition?.playwright !== browser.playwright ||
        observation.condition?.preference !== "system" || observation.condition?.mountedTheme !== "system" ||
        observation.condition?.effectiveTheme !== system || observation.condition?.systemScheme !== system ||
        observation.condition?.reducedMotion !== true || observation.condition?.browserZoom !== "unverified" ||
        observation.condition?.viewport?.width !== 1280 || observation.condition?.viewport?.height !== 900 || observation.condition?.viewport?.dpr !== 1) {
      throw new Error(`${expectedHalf} half lacks matched dark/light system-preference observations`);
    }
  }
  return value;
}

export function assertInvestigationPair(before: unknown, after: unknown) {
  const b: any = validateHalf(before, "before");
  const a: any = validateHalf(after, "after");
  if (b.pairId === a.pairId) throw new Error("Before and after captures must have distinct pair identities");
  const keys = ["database", "partition", "httpPort", "actionId", "actionName", "transactionId", "replyId", "ticketId", "actorId", "eventTime", "actionInsertedAt"] as const;
  for (const key of keys) if (b.selected[key] !== a.selected[key]) throw new Error(`Pair mismatch: selected.${key}`);
  if (JSON.stringify([...b.selected.changeIds].sort()) !== JSON.stringify([...a.selected.changeIds].sort()) ||
      b.materializationSha256 !== a.materializationSha256 || b.journey.timelineUrl !== a.journey.timelineUrl ||
      b.browser.version !== a.browser.version || b.browser.playwright !== a.browser.playwright ||
      b.browser.project !== a.browser.project) throw new Error("Pair materialization or browser identity differs between halves");
  const byId = new Map(b.captures.map((capture: any) => [capture.id, capture]));
  for (const capture of a.captures as any[]) {
    const previous: any = byId.get(capture.id);
    if (!previous || previous.route !== capture.route || JSON.stringify(previous.condition) !== JSON.stringify(capture.condition)) {
      throw new Error(`Pair capture condition or route differs for ${capture.id}`);
    }
  }
  if (JSON.stringify(b.systemObservations.map((v: any) => v.condition)) !== JSON.stringify(a.systemObservations.map((v: any) => v.condition))) {
    throw new Error("System preference/effective scheme observations differ between halves");
  }
  return { matched: true as const, pairId: `${b.pairId}/${a.pairId}`, materializationSha256: b.materializationSha256 };
}

export function verifyBeforeReceipt() {
  const root = pairRoot();
  const pointer = readJson<{ file: string; sha256: string; pairId: string }>(resolve(root, "captures/before/canonical.json"));
  if (!capturedFileBelongsToHalf(pointer.file, "before") || !validDigest(pointer.sha256) || !pointer.pairId) {
    throw new Error("Canonical before pointer has invalid custody or digest metadata");
  }
  const file = resolveContainedPath(root, pointer.file);
  const bytes = readFileSync(file);
  if (sha256(bytes) !== pointer.sha256) throw new Error("Canonical before capsule digest does not match its file");
  const before = validateHalf(JSON.parse(bytes.toString("utf8")), "before");
  if (pointer.pairId !== before.pairId) throw new Error("Canonical before pointer identity does not match its capsule");
  const live = checkMaterialization();
  const receipt = readAppReceipt();
  const custody = inspectOwnedListener(receipt);
  if (live.sha256 !== before.materializationSha256 || receipt.port !== before.selected.httpPort ||
      realpathSync(custody.actualCwd) !== realpathSync(appWorkingDirectory(receipt))) {
    throw new Error("Before receipt is not bound to the current pair data and retained serving app");
  }
  const result = { verifiedBefore: true, pairId: before.pairId, materializationSha256: live.sha256, source: "selected read-only PostgreSQL rows and actual mounted source/assets" };
  appendInvocation({ type: "check-before", ...result, status: "passed" });
  return result;
}

export async function capturePhase250GateObservation(
  page: Page,
  browser: Browser,
  info: TestInfo,
  gate: "theme" | "fonts-loaded" | "fonts-disabled",
) {
  const root = pairRoot();
  const receipt = readAppReceipt();
  const live = await assertLivePair(receipt);
  if (info.project.name !== "desktop-chromium" || process.pid === receipt.pid) {
    throw new Error("Phase250 browser observations require the selected desktop project and a separate test process");
  }
  const condition = await observeCondition(page, browser, info);
  const assets = await pageAssetIdentity(page, receipt.checkout);
  const id = `${gate}-${randomUUID()}`;
  const outputDir = resolve(root, "gates", gate);
  mkdirSync(outputDir, { recursive: true, mode: 0o700 });
  const shellPath = resolveContainedPath(outputDir, `${id}-shell.png`);
  const contentPath = resolveContainedPath(outputDir, `${id}-content.png`);
  await page.locator(".threadline-ui").first().screenshot({ path: shellPath, animations: "disabled", scale: "css" });
  await page.locator("#tl-main").screenshot({
    path: contentPath,
    animations: "disabled",
    scale: "css",
    mask: [page.locator("time"), page.locator('[data-dynamic="true"]')],
    maskColor: condition.effectiveTheme === "light" ? "#F8FAFC" : "#0B1020",
  });
  const shellBytes = readFileSync(shellPath);
  const contentBytes = readFileSync(contentPath);
  assertNoCanaryLeak(canary, shellPath, shellBytes);
  assertNoCanaryLeak(canary, contentPath, contentBytes);
  const imageIdentity = (file: string, bytes: Buffer) => ({ file: relative(root, file), sha256: sha256(bytes), bytes: bytes.byteLength });
  const observation = {
    gate, id, route: new URL(page.url()).pathname + new URL(page.url()).search, condition, assets,
    shell: imageIdentity(shellPath, shellBytes), content: imageIdentity(contentPath, contentBytes),
    source: { serving: live.servingSource, test: live.testSource }, observedAt: now(),
  };
  const file = resolveContainedPath(outputDir, `${id}.json`);
  const serialized = `${JSON.stringify(observation, null, 2)}\n`;
  assertNoCanaryLeak(canary, file, serialized);
  atomicWriteFile(file, serialized);
  appendInvocation({ type: "browser-observation", gate, id, output: relative(root, file), status: "passed" });
  return observation;
}

const gateTitles = {
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
type Gate = keyof typeof gateTitles;

function validateGate(value: string): asserts value is Gate {
  if (!(value in gateTitles)) throw new Error(`Unknown Phase250 browser gate: ${value}`);
}

function browserGateFiles(gate: Gate) {
  const root = pairRoot();
  const invocationsDir = resolve(root, "browser-invocations");
  mkdirSync(invocationsDir, { recursive: true, mode: 0o700 });
  return { root, invocationsDir, report: process.env.THREADLINE_PHASE250_BROWSER_REPORT };
}

export async function browserBegin(gateValue: string) {
  validateGate(gateValue);
  const gate = gateValue;
  const { root, invocationsDir, report } = browserGateFiles(gate);
  if (!report || !isAbsolute(report)) throw new Error("Parent must supply a fresh absolute Playwright JSON report under the durable pair root");
  const safeReport = resolveContainedPath(root, relative(root, resolve(report)));
  if (!safeReport.startsWith(`${root}${sep}`) || existsSync(safeReport)) throw new Error("Playwright JSON report path is outside custody or already exists");
  const before = verifyBeforeReceipt();
  const receipt = readAppReceipt();
  const live = await assertLivePair(receipt);
  const nonce = randomUUID();
  const invocation = {
    schemaVersion: 1,
    gate,
    nonce,
    startedAt: now(),
    expected: gateTitles[gate].map((title) => ({ project: "desktop-chromium", title })),
    report: relative(root, safeReport),
    pairId: before.pairId,
    materializationSha256: before.materializationSha256,
    app: { pid: receipt.pid, port: receipt.port, checkout: receipt.checkout, cwd: live.listener.actualCwd, sourceHeadAtStart: receipt.source_head },
    executor: { pid: process.pid, checkout: repoRoot },
    servingSource: live.servingSource,
    testSource: live.testSource,
  };
  const path = resolveContainedPath(invocationsDir, `${gate}-${nonce}.json`);
  atomicWriteFile(path, `${JSON.stringify(invocation, null, 2)}\n`);
  atomicWriteFile(resolveContainedPath(invocationsDir, `${gate}-current.json`), JSON.stringify({ path: relative(root, path), nonce }, null, 2) + "\n");
  appendInvocation({ type: "browser-begin", gate, nonce, report: invocation.report, status: "ready" });
  return { ready: true, gate, nonce, report: invocation.report };
}

type PlaywrightResult = { readonly title: string; readonly projectName: string; readonly results: readonly { readonly status: string; readonly retry: number }[] };
function flattenPlaywrightReport(value: any): PlaywrightResult[] {
  const output: PlaywrightResult[] = [];
  function visit(suite: any, file = "") {
    if (!suite || typeof suite !== "object") throw new Error("Malformed Playwright suite tree");
    const currentFile = typeof suite.file === "string" && suite.file ? suite.file : file;
    if (suite.specs !== undefined && !Array.isArray(suite.specs)) throw new Error("Malformed Playwright specs list");
    for (const spec of suite.specs ?? []) {
      if (!spec || typeof spec.title !== "string" || !Array.isArray(spec.tests)) throw new Error("Malformed Playwright test spec");
      for (const test of spec.tests) {
        if (!test || typeof test.projectName !== "string" || !Array.isArray(test.results)) throw new Error("Malformed Playwright test result");
        output.push({ title: spec.title, projectName: test.projectName, results: test.results });
      }
    }
    if (suite.suites !== undefined && !Array.isArray(suite.suites)) throw new Error("Malformed nested Playwright suites list");
    for (const child of suite.suites ?? []) visit(child, currentFile);
  }
  if (!Array.isArray(value.suites)) throw new Error("Malformed Playwright root suites");
  for (const suite of value.suites) visit(suite);
  return output;
}

export function assertFreshBrowserReport(reportPath: string, startedAtValue: string, nowMs = Date.now()): void {
  const startedAt = Date.parse(startedAtValue);
  if (!isAbsolute(reportPath) || !Number.isFinite(startedAt) || startedAt > nowMs + 1_000 ||
      nowMs - startedAt > 30 * 60_000 || !existsSync(reportPath)) {
    throw new Error("Playwright report is absent or stale for this browser-begin receipt");
  }
  const reportStat = lstatSync(reportPath);
  if (!reportStat.isFile() || reportStat.isSymbolicLink() || reportStat.mtimeMs + 5_000 < startedAt) {
    throw new Error("Playwright report is not a fresh regular file for this browser-begin receipt");
  }
}

export function validateBrowserReport(gateValue: string, report: any) {
  validateGate(gateValue);
  const gate = gateValue;
  if (!report || !Array.isArray(report.errors) || report.errors.length !== 0 || !report.stats ||
      typeof report.stats.startTime !== "string" || !Number.isFinite(Date.parse(report.stats.startTime)) ||
      typeof report.stats.duration !== "number" || typeof report.stats.expected !== "number" ||
      typeof report.stats.unexpected !== "number" || typeof report.stats.skipped !== "number" ||
      typeof report.stats.flaky !== "number") throw new Error("Malformed or error-bearing Playwright report");
  const actual = flattenPlaywrightReport(report);
  const expected = gateTitles[gate];
  if (actual.length !== expected.length) throw new Error(`Gate ${gate} has ${actual.length} result rows, expected ${expected.length}`);
  const seen = new Set<string>();
  for (const result of actual) {
    if (result.projectName !== "desktop-chromium" || !(expected as readonly string[]).includes(result.title) || seen.has(result.title)) {
      throw new Error(`Unexpected, duplicate or wrong-project Playwright test result: ${result.projectName}/${result.title}`);
    }
    seen.add(result.title);
    if (result.results.length !== 1 || result.results[0]?.status !== "passed" || result.results[0]?.retry !== 0) {
      throw new Error(`Selected test did not pass exactly once on its first attempt: ${result.title}`);
    }
  }
  if (seen.size !== expected.length || expected.some((title) => !seen.has(title)) ||
      report.stats.expected !== expected.length || report.stats.unexpected !== 0 || report.stats.skipped !== 0 ||
      report.stats.flaky !== 0) {
    throw new Error(`Playwright summary statistics do not match the exact ${gate} gate case set`);
  }
  return actual.map(({ title, projectName, results }) => ({ title, projectName, status: results[0]!.status, retry: results[0]!.retry }));
}

function latestInvocation(root: string, gate: Gate) {
  const directory = resolve(root, "browser-invocations");
  const current = readJson<{ path: string; nonce: string }>(resolve(directory, `${gate}-current.json`));
  const path = resolveContainedPath(root, current.path);
  const invocation = readJson<any>(path);
  const reportPath = process.env.THREADLINE_PHASE250_BROWSER_REPORT;
  const invocationPath = `browser-invocations/${gate}-${current.nonce}.json`;
  const expected = gateTitles[gate].map((title) => ({ project: "desktop-chromium", title }));
  if (current.path !== invocationPath || current.nonce !== invocation.nonce || invocation.gate !== gate ||
      JSON.stringify(invocation.expected) !== JSON.stringify(expected)) {
    throw new Error("Current browser invocation pointer or exact gate identity does not match its receipt");
  }
  if (!reportPath || !isAbsolute(reportPath) || relative(root, resolve(reportPath)) !== invocation.report) throw new Error("Browser report path does not match the current fresh invocation");
  return { path, invocation, reportPath: resolveContainedPath(root, invocation.report) };
}

export async function browserCheck(gateValue: string) {
  validateGate(gateValue);
  const gate = gateValue;
  const root = pairRoot();
  const { path, invocation, reportPath } = latestInvocation(root, gate);
  assertFreshBrowserReport(reportPath, invocation.startedAt);
  const before = verifyBeforeReceipt();
  const receipt = readAppReceipt();
  const live = await assertLivePair(receipt);
  if (before.pairId !== invocation.pairId || before.materializationSha256 !== invocation.materializationSha256 ||
      receipt.pid !== invocation.app.pid || receipt.port !== invocation.app.port ||
      realpathSync(receipt.checkout) !== realpathSync(invocation.app.checkout) ||
      realpathSync(live.listener.actualCwd) !== realpathSync(invocation.app.cwd) ||
      realpathSync(repoRoot) !== realpathSync(invocation.executor.checkout) || process.pid === receipt.pid ||
      !sameSource(live.servingSource, invocation.servingSource) || !sameSource(live.testSource, invocation.testSource)) {
    throw new Error("Browser report source, app or materialization custody changed after browser-begin");
  }
  const reportBytes = readFileSync(reportPath);
  let report: any;
  try { report = JSON.parse(reportBytes.toString("utf8")); } catch { throw new Error("Malformed Playwright JSON report"); }
  const actual = validateBrowserReport(gate, report);
  const verified = {
    schemaVersion: 1,
    verified: true,
    gate,
    nonce: invocation.nonce,
    reportSha256: sha256(reportBytes),
    invocationSha256: sha256(readFileSync(path)),
    source: { serving: live.servingSource, test: live.testSource },
    results: actual,
    checkedAt: now(),
  };
  const pathOut = resolveContainedPath(root, `browser-invocations/${gate}-${invocation.nonce}-verified.json`);
  atomicWriteFile(pathOut, `${JSON.stringify(verified, null, 2)}\n`);
  appendInvocation({ type: "browser-check", gate, nonce: invocation.nonce, reportSha256: verified.reportSha256, output: relative(root, pathOut), status: "passed" });
  return { verifiedBrowserGate: true, gate, nonce: invocation.nonce, reportSha256: verified.reportSha256, results: actual.length };
}

function main() {
  const [command, argument] = process.argv.slice(2);
  const run = async () => {
    if (command === "check-before") return verifyBeforeReceipt();
    if (command === "browser-begin" && argument) return browserBegin(argument);
    if (command === "browser-check" && argument) return browserCheck(argument);
    if (command === "pair") {
      const root = pairRoot();
      const beforePtr = readJson<{ file: string }>(resolve(root, "captures/before/canonical.json"));
      const afterPtr = readJson<{ file: string }>(resolve(root, "captures/after/canonical.json"));
      const before = readJson<any>(resolveContainedPath(root, beforePtr.file));
      const after = readJson<any>(resolveContainedPath(root, afterPtr.file));
      return assertInvestigationPair(before, after);
    }
    throw new Error("Usage: operator-investigation-pair.ts check-before|pair|browser-begin <gate>|browser-check <gate>");
  };
  void run().then((value) => process.stdout.write(`${JSON.stringify(value)}\n`)).catch((error) => {
    const message = error instanceof Error ? error.message : String(error);
    appendInvocation({ type: command ?? "unknown", argument: argument ?? null, status: "failed", error: message });
    process.stderr.write(`${message}\n`);
    process.exitCode = 1;
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
