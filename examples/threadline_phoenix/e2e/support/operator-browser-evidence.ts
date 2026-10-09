import { expect, type Browser, type Page, type TestInfo } from "@playwright/test";
import { createHash } from "node:crypto";
import { readFileSync, readdirSync } from "node:fs";
import { createRequire } from "node:module";
import { join, relative, resolve } from "node:path";
import { currentOperatorSurfacePaths, resolveContainedPath, atomicWriteFile } from "./operator-surface-paths.js";
import { assetRecord, candidateIdentity, outputRecord, semanticFixtureId, writeManifest, type OperatorEvidenceManifest, type ServedAsset } from "./operator-evidence-manifest.js";

export const paths = currentOperatorSurfacePaths();
const require = createRequire(import.meta.url);
const sha = (value: string | Buffer) => createHash("sha256").update(value).digest("hex");
export const widths = [1280, 768, 375] as const;
export const inventory = JSON.parse(readFileSync(join(paths.repositoryRoot, "test/fixtures/operator_surface/route-inventory.json"), "utf8")) as {
  routes: { id: string; pattern: string; path?: string; seedResolution: string; role: string; scope: string }[];
};

export async function login(page: Page, email = "admin@example.com") {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  await page.locator("#login_form").getByLabel("Email").fill(email);
  await page.locator("#login_form").getByLabel("Password").fill(process.env.DEMO_SEED_PASSWORD ?? "password123456");
  await page.locator("#login_form").getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

export async function seedPaths(page: Page) {
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  const link = page.getByTestId("timeline-row").first().getByTestId("transaction-link");
  await expect(link).toBeVisible();
  const transaction = await link.getAttribute("href");
  expect(transaction).toMatch(/^\/audit\/transactions\/[^/?]+$/);
  await page.goto(transaction!);
  const rowLink = page.getByTestId("transaction-change-row").filter({ hasText: "tickets" }).getByTestId("row-history-link").first();
  await expect(rowLink).toBeVisible();
  const drawer = await rowLink.getAttribute("href");
  const match = drawer && new URL(drawer, "http://127.0.0.1").pathname.match(/^\/audit\/transactions\/([^/]+)\/history\/([^/]+)\/([^/]+)$/);
  expect(match, "Seeded AuditChange must resolve a scalar row-history path").toBeTruthy();
  return { transaction: transaction!, drawer: drawer!, row: `/audit/rows/${match![2]}/${match![3]}` };
}

export function runRoot() {
  const value = process.env.THREADLINE_E2E_EVIDENCE_ROOT;
  if (!value) throw new Error("Runner must provide a fresh evidence output root");
  return resolveContainedPath(paths.e2eRoot, relative(paths.e2eRoot, resolve(value)));
}

export async function startEvidence(page: Page, browser: Browser, info: TestInfo, role = "seeded-admin") {
  const base = process.env.THREADLINE_E2E_BASE_SHA;
  if (!base) throw new Error("Missing verified isolation base");
  const identity = candidateIdentity(paths.repositoryRoot, base);
  const seedRoot = join(paths.repositoryRoot, "examples/threadline_phoenix/lib/threadline_phoenix/demo");
  const seedHash = createHash("sha256");
  const seedFiles = ["seed.ex", "manifest.ex", ...readdirSync(join(seedRoot, "seed"), { recursive: true }).map((entry) => `seed/${entry}`)].sort();
  for (const file of seedFiles) seedHash.update(file).update("\0").update(readFileSync(join(seedRoot, file)));
  seedHash.update("config/test.exs\0").update(readFileSync(join(paths.repositoryRoot, "examples/threadline_phoenix/config/test.exs")));
  const seedManifestSha256 = seedHash.digest("hex");
  const fixture = { scenario: "threadline-demo-seed", version: "seed-pipeline-v1", seedManifestSha256, semanticId: semanticFixtureId("threadline-demo-seed", "seed-pipeline-v1", seedManifestSha256) };
  const assets = new Map<string, ServedAsset>();
  const errors: string[] = [];
  const pending: Promise<void>[] = [];
  // Start before operator navigation; never save network headers or document HTML.
  await page.route("**/assets/**", (route) => route.continue());
  page.on("response", (response) => {
    if (!["stylesheet", "script"].includes(response.request().resourceType())) return;
    pending.push((async () => {
      try { assets.set(response.url(), assetRecord(paths.repositoryRoot, response.url(), response.status(), response.headers()["content-type"] ?? "", await response.body())); }
      catch (error) { errors.push(String(error)); }
    })());
  });
  const captures: OperatorEvidenceManifest["captures"][number][] = [];
  let lastAppearance = { preference: "unknown", effectiveTheme: "unknown" };
  let lastViewport = { width: 1280, height: 900, deviceScaleFactor: 1 };

  async function capture(id: string, route: string, state: string, extra: Record<string, unknown> = {}, connected = true) {
    const root = page.locator(".threadline-ui").first();
    const content = page.locator("#tl-main");
    await expect(root).toBeVisible();
    await expect(content).toBeVisible();
    if (connected) await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await page.evaluate(() => document.fonts.ready);
    await Promise.all(pending);
    if (errors.length) throw new Error(errors.join("\n"));
    const styleText = (await page.locator("style").allTextContents()).find((s) => s.includes(".threadline-ui"));
    if (!styleText) throw new Error("Missing served operator stylesheet");
    const local = ["01_tokens.css", "02_base_shell.css", "03_page_home.css", "04_controls.css", "05_feedback.css", "06_layout_primitives.css", "07_find_detail.css", "08_overlays_motion.css", "09_responsive.css"].map((f) => readFileSync(join(paths.repositoryRoot, "lib/threadline/operator_surface/style", f), "utf8")).join("");
    const css: ServedAsset = { url: "inline:/audit#threadline-operator-stylesheet", status: 200, contentType: "text/css; charset=utf-8", servedSha256: sha(styleText), localPath: "lib/threadline/operator_surface/style/*.css (ordered segments)", localSha256: sha(local) };
    const verified = [...assets.values(), css];
    const observation = await root.evaluate((el) => {
      const style = getComputedStyle(el);
      const names = ["--tl-color-bg", "--tl-color-text", "--tl-color-paper", "--tl-color-ink", "--tl-motion-base", "--tl-font-size-body"];
      return { preference: (el.querySelector('input[name="theme"]:checked') as HTMLInputElement)?.value ?? "unknown", effectiveTheme: el.getAttribute("data-tl-theme") ?? "unknown", osLight: matchMedia("(prefers-color-scheme: light)").matches, reducedMotion: matchMedia("(prefers-reduced-motion: reduce)").matches, dpr: devicePixelRatio, cssWidth: innerWidth, scrollWidth: document.documentElement.scrollWidth, background: style.backgroundColor, resolvedValues: Object.fromEntries(names.map((n) => [n, style.getPropertyValue(n).trim()])) };
    });
    lastAppearance = { preference: observation.preference, effectiveTheme: observation.effectiveTheme };
    lastViewport = { ...page.viewportSize()!, deviceScaleFactor: observation.dpr };
    const condition = JSON.stringify({ project: info.project.name, viewport: lastViewport, motion: observation.reducedMotion ? "reduced" : "default", browserZoom: "unverified", ...extra });
    for (const region of ["shell", "content"] as const) {
      const file = resolveContainedPath(runRoot(), `${id}-${region}.png`);
      if (region === "shell") await root.screenshot({ path: file, scale: "css", animations: "disabled" });
      else await content.screenshot({ path: file, scale: "css", animations: "disabled", mask: [page.locator("time"), page.locator('[data-dynamic="true"]')], maskColor: observation.effectiveTheme === "light" ? "#F8FAFC" : "#0B1020" });
      captures.push({ ...outputRecord(`${id}-${region}`, route, state, condition, file), assets: verified });
    }
    const observationPath = resolveContainedPath(runRoot(), `${id}-observation.json`);
    atomicWriteFile(observationPath, JSON.stringify({ route, state, ...observation, ...extra }, null, 2) + "\n");
    captures.push({ ...outputRecord(`${id}-observation`, route, state, condition, observationPath), assets: verified });
    return observation;
  }
  function finish(id: string, route: string, state: string) {
    const manifest: OperatorEvidenceManifest = { schemaVersion: 1, ...identity, fixture, route, state, actor: { role, scope: "isolated-local-demo-database" }, appearance: lastAppearance, browser: { playwright: require("@playwright/test/package.json").version, browser: browser.version() }, viewport: lastViewport, input: { motion: "observed-per-capture", zoom: 1 }, captures };
    // zoom=1 is a neutral compatibility field, NOT proof of browser chrome zoom;
    // every capture's condition explicitly records browserZoom=unverified.
    writeManifest(runRoot(), `${id}-manifest.json`, manifest);
    return manifest;
  }
  function recordFile(id: string, route: string, state: string, condition: string, file: string) {
    if (!captures.length) throw new Error("Record metadata only after verified browser capture");
    captures.push({ ...outputRecord(id, route, state, condition, file), assets: captures[0].assets });
  }
  return { capture, finish, recordFile };
}
