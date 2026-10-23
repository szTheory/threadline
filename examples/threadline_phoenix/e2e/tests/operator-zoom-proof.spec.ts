import { chromium, expect, test } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { setAndReadTabZoom, withIsolatedZoomContext } from "../support/operator-tab-zoom.js";

const require = createRequire(import.meta.url);
const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const acceptMode = process.env.THREADLINE_ZOOM_ACCEPT === "1";
type PageObservation = Awaited<ReturnType<typeof observePage>> & {
  overlay?: { opened: boolean; dismissed: boolean; focusReturned: boolean };
  tabZoom?: { tabId: number; zoomFactor: number };
};

test("isolated Chromium tab reports real 200% zoom on the operator investigation journey", async ({}, testInfo) => {
  test.skip(testInfo.project.name !== "desktop-chromium", "The extension proof runs only in desktop-chromium");

  await withIsolatedZoomContext(chromium, async (context, page) => {
    const baseURL = testInfo.project.use.baseURL ?? "http://127.0.0.1:4002";
    await page.goto(new URL("/users/log_in", String(baseURL)).toString());
    const form = page.locator("#login_form");
    await form.getByLabel("Email").fill("admin@example.com");
    await form.getByLabel("Password").fill(password);
    await form.getByRole("button", { name: /log in/i }).click();
    await expect(page).toHaveURL(new URL("/", String(baseURL)).toString(), { timeout: 30_000 });
    await page.goto(new URL("/audit", String(baseURL)).toString());
    await expect(page.locator(".threadline-ui").first()).toBeVisible();
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();

    const zoom = await setAndReadTabZoom(context, page);
    expect(zoom.zoomFactor).toBe(2);
    expect(zoom.tabId).toBeGreaterThan(0);

    const observations: PageObservation[] = [];
    await expect(page.getByRole("heading", { name: "Follow what happened." })).toBeVisible();
    const homeObservation: PageObservation = await observePage(page, "Home", [
      ["Open the timeline", page.getByRole("link", { name: "Open the timeline" })],
      ["Row history table", page.locator('select[name="record_lookup[table]"]')],
      ["Row history record ID", page.locator('input[name="record_lookup[record_id]"]')],
      ["Correlation lookup", page.locator('input[name="correlation[correlation_id]"]')],
    ], acceptMode);
    homeObservation.tabZoom = { tabId: zoom.tabId, zoomFactor: zoom.zoomFactor };
    observations.push(homeObservation);

    await page.goto(new URL("/audit/timeline?table=ticket_replies&from=2020-01-01T00%3A00&to=2099-01-01T00%3A00", String(baseURL)).toString());
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    const timelineZoom = await setAndReadTabZoom(context, page);
    expect(timelineZoom.tabId).toBe(zoom.tabId);
    expect(timelineZoom.zoomFactor).toBe(2);
    await expect(page.getByRole("heading", { name: "Investigate audit activity" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Apply", exact: true })).toBeVisible();
    await expect(page.getByRole("textbox", { name: "Correlation id" })).toBeVisible();
    const filtersButton = page.getByRole("button", { name: "Filters", exact: true });
    let overlay = { openerVisible: false, opened: false, dismissed: false, focusReturned: false };
    overlay.openerVisible = await filtersButton.isVisible();
    if (overlay.openerVisible) {
      await filtersButton.click();
      const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
      await expect(drawer).toBeVisible({ timeout: 2_000 }).catch(() => undefined);
      overlay.opened = await drawer.isVisible();
      if (overlay.opened) {
        await page.keyboard.press("Escape");
        await expect(drawer).toBeHidden({ timeout: 2_000 }).catch(() => undefined);
        overlay.dismissed = !(await drawer.isVisible());
        overlay.focusReturned = await filtersButton.evaluate((element) => element === document.activeElement);
        if (!overlay.dismissed) {
          const close = drawer.getByRole("button", { name: "Close", exact: true });
          if (await close.isVisible()) {
            await close.click();
            await expect(drawer).toBeHidden({ timeout: 2_000 }).catch(() => undefined);
          }
        }
      }
    }
    const timelineObservation: PageObservation = await observePage(page, "Timeline", [
      ["From date", page.getByLabel("From", { exact: true })],
      ["To date", page.getByLabel("To", { exact: true })],
      ["Table filter", page.getByLabel("Table", { exact: true })],
      ["Correlation filter", page.getByLabel("Correlation id", { exact: true })],
      ["Filters disclosure", filtersButton],
      ["Apply query", page.getByRole("button", { name: "Apply", exact: true })],
    ], acceptMode);
    const themeControls = await openThemeControls(page);
    const themeObservation = await observePage(page, "Timeline theme", themeControls, acceptMode);
    timelineObservation.controls.push(...themeObservation.controls);
    timelineObservation.overlay = overlay;
    timelineObservation.tabZoom = { tabId: timelineZoom.tabId, zoomFactor: timelineZoom.zoomFactor };
    observations.push(timelineObservation);
    if (acceptMode) {
      expect(overlay.opened, "Timeline filter overlay did not open at 200% zoom").toBe(true);
      expect(overlay.dismissed, "Escape did not dismiss the Timeline filter overlay").toBe(true);
      expect(overlay.focusReturned, "Focus did not return to Filters after dismissal").toBe(true);
    }

    const transactionLink = page.getByTestId("timeline-row").filter({
      has: page.locator(".tl-change__op").filter({ hasText: /^UPDATE$/ }),
    }).first().getByTestId("transaction-link");
    await expect(transactionLink).toBeVisible();
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).toMatch(/^\/audit\/transactions\/[^/?]+$/);
    await page.goto(new URL(transactionHref!, String(baseURL)).toString());
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    const transactionZoom = await setAndReadTabZoom(context, page);
    expect(transactionZoom.tabId).toBe(zoom.tabId);
    expect(transactionZoom.zoomFactor).toBe(2);
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    const firstChange = page.getByTestId("transaction-change-row").filter({
      has: page.locator(".tl-change__table").filter({ hasText: /^ticket_replies$/ }),
    });
    await expect(firstChange).toHaveCount(1);
    const disclosures = page.locator(".tl-transaction details > summary");
    await expect(firstChange.locator(".tl-change__op")).toHaveText("UPDATE");
    const bodyField = firstChange.locator(".tl-diff__row").filter({
      has: page.locator(".tl-change__field-name").filter({ hasText: /^body$/ }),
    });
    const cells = bodyField.locator(".tl-diff__cell");
    await expect(cells).toHaveCount(2);
    await expect(cells.nth(0).getByText("Before", { exact: true })).toBeVisible();
    await expect(cells.nth(0).getByText("Original reply from Zendesk sync.", { exact: true })).toBeVisible();
    await expect(cells.nth(1).getByText("After", { exact: true })).toBeVisible();
    await expect(cells.nth(1).getByText("Updated reply — issue resolved.", { exact: true })).toBeVisible();
    const beforeBox = (await cells.nth(0).boundingBox())!;
    const afterBox = (await cells.nth(1).boundingBox())!;
    expect(afterBox.y, "Before/After stack at actual 200% zoom").toBeGreaterThanOrEqual(beforeBox.y + beforeBox.height);
    const transactionControls: [string, import("@playwright/test").Locator][] = [
      ["Transaction ID full value disclosure", page.getByText("Show full transaction id", { exact: true })],
      ["Native full-value disclosure", disclosures.first()],
      ["Transaction row history", firstChange.getByTestId("row-history-link")],
    ];
    const transactionObservation: PageObservation = await observePage(page, "Transaction", transactionControls, acceptMode);
    transactionObservation.tabZoom = { tabId: transactionZoom.tabId, zoomFactor: transactionZoom.zoomFactor };
    observations.push(transactionObservation);

    const browserVersion = execFileSync(chromium.executablePath(), ["--version"], { encoding: "utf8" }).trim();
    const result = {
      browserVersion,
      playwrightVersion: require("@playwright/test/package.json").version,
      tabId: zoom.tabId,
      tabUrl: zoom.url,
      zoomFactor: zoom.zoomFactor,
      viewport: page.viewportSize(),
      devicePixelRatio: await page.evaluate(() => window.devicePixelRatio),
      observations,
    };
    console.log(`THREADLINE_ZOOM_OBSERVATION=${JSON.stringify(result)}`);

    if (acceptMode) {
      for (const observation of observations) {
        expect(observation.overflow, `${observation.route} has whole-page horizontal overflow`).toBeLessThanOrEqual(1);
        for (const control of observation.controls) {
          expect(control.visible, `${observation.route} control ${control.name} is hidden`).toBe(true);
          expect(control.reachable, `${observation.route} control ${control.name} is off-screen or covered`).toBe(true);
        }
      }
    }
  });
});

test("inspection routes preserve exact scope and controls at verified real 200% tab zoom", async ({}, testInfo) => {
  test.skip(testInfo.project.name !== "desktop-chromium", "The extension proof runs only in desktop-chromium");
  await withIsolatedZoomContext(chromium, async (context, page) => {
    const baseURL = String(testInfo.project.use.baseURL ?? "http://127.0.0.1:4002");
    let blockReconnect = false;
    await page.routeWebSocket(/\/live\/websocket/, (socket) => {
      if (blockReconnect) socket.close();
      else socket.connectToServer();
    });
    const visit = async (path: string) => {
      await page.goto(new URL(path, baseURL).toString());
      if (path.startsWith("/audit")) await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    };
    await visit("/users/log_in");
    const form = page.locator("#login_form");
    await form.getByLabel("Email").fill("admin@example.com");
    await form.getByLabel("Password").fill(password);
    await form.getByRole("button", { name: /log in/i }).click();
    await expect(page).toHaveURL(new URL("/", baseURL).toString());
    const observations: PageObservation[] = [];

    await visit("/audit/coverage?schema=public");
    const coverageZoom = await setAndReadTabZoom(context, page);
    expect(coverageZoom.zoomFactor).toBe(2);
    await expect(page.locator("#coverage-schema")).toHaveValue("public");
    observations.push({ ...await observePage(page, "Coverage", [
      ["Host schema", page.locator("#coverage-schema")],
      ["Refresh coverage", page.getByRole("button", { name: "Refresh coverage", exact: true })],
    ], true), tabZoom: coverageZoom });

    await visit("/audit/evidence");
    const seeded = page.locator(".tl-record-card").filter({ has: page.locator('code[title*="walk-retention-offboarded-co"]') });
    await expect(seeded).toHaveCount(1);
    const reference = (await seeded.locator("code[data-tl-copy]").getAttribute("data-tl-copy"))!;
    expect(JSON.parse(reference).run_id).toBe("walk-retention-offboarded-co");
    await visit(`/audit/evidence?subject=retention_run&subject_ref_json=${encodeURIComponent(reference)}`);
    const evidenceZoom = await setAndReadTabZoom(context, page);
    expect(evidenceZoom.tabId).toBe(coverageZoom.tabId);
    await expect(page.locator(".tl-evidence__workflow-summary code[data-tl-copy]")).toHaveAttribute("data-tl-copy", reference);
    const history = page.locator(".tl-record-card").first().getByRole("link", { name: "View proof history", exact: true });
    observations.push({ ...await observePage(page, "Evidence", [["View proof history", history]], true), tabZoom: evidenceZoom });
    await history.click();
    await expect(page.locator(".tl-evidence__workflow-summary code[data-tl-copy]")).toHaveAttribute("data-tl-copy", reference);

    await visit("/audit/policy/redaction?schema=public");
    const policyZoom = await setAndReadTabZoom(context, page);
    expect(policyZoom.tabId).toBe(coverageZoom.tabId);
    await expect(page.getByRole("region", { name: "Redaction policy posture" })).toContainText("public");
    const row = page.locator("details.tl-policy__row").filter({ has: page.getByText("posts", { exact: true }) });
    observations.push({ ...await observePage(page, "Redaction policy", [
      ["Refresh policy inspection", page.getByRole("button", { name: "Refresh policy inspection", exact: true })],
      ["Exact posts policy disclosure", row.locator("summary")],
    ], true), tabZoom: policyZoom });
    await page.keyboard.press("Enter");
    await expect(row).toHaveAttribute("open", "");
    await expect(row.getByRole("table")).toBeVisible();

    const longCorrelation = `zoom-proof-filter-${"x".repeat(80)}`;
    await visit(`/audit/exports?table=ticket_replies&correlation_id=${encodeURIComponent(longCorrelation)}`);
    const exportZoom = await setAndReadTabZoom(context, page);
    expect(exportZoom.tabId).toBe(coverageZoom.tabId);
    expect(exportZoom.zoomFactor).toBe(2);
    await expect(page.getByTestId("timeline-export-context")).toContainText(longCorrelation);
    await expect(page.getByTestId("export-jobs")).toBeVisible();
    observations.push({ ...await observePage(page, "Exports", [
      ["Queue Timeline export", page.getByRole("button", { name: "Queue Timeline export", exact: true })],
      ["Reopen source search", page.getByRole("link", { name: "Reopen source search" }).first()],
    ], true), tabZoom: exportZoom });

    const root = page.locator("[data-phx-main]");
    const main = page.locator("#tl-main");
    await main.focus();
    blockReconnect = true;
    await page.evaluate(() => (window as any).liveSocket.disconnect());
    await expect(root).toHaveClass(/phx-loading/);
    const reconnectBanner = page.locator(".tl-reconnect-banner");
    await expect(reconnectBanner).toBeVisible();
    await expect(reconnectBanner.locator(".tl-reconnect-banner__reconnecting")).toHaveText(
      "Reconnecting. Actions will remain unavailable until current status is refreshed.",
    );
    const bannerLayout = await page.evaluate(() => ({
      viewportWidth: window.innerWidth,
      documentWidth: document.documentElement.scrollWidth,
      clientWidth: document.documentElement.clientWidth,
      bannerWidth: document.querySelector(".tl-reconnect-banner")!.scrollWidth,
      bannerClientWidth: document.querySelector(".tl-reconnect-banner")!.clientWidth,
    }));
    expect(bannerLayout.viewportWidth).toBe(640);
    expect(bannerLayout.documentWidth - bannerLayout.clientWidth).toBeLessThanOrEqual(1);
    expect(bannerLayout.bannerWidth - bannerLayout.bannerClientWidth).toBeLessThanOrEqual(1);
    await expect(main).toBeVisible();
    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("tl-main");
    observations.push({
      route: "Reconnect status at 200%",
      path: new URL(page.url()).pathname + new URL(page.url()).search,
      viewport: { width: bannerLayout.viewportWidth, height: page.viewportSize()?.height },
      documentWidth: bannerLayout.documentWidth,
      clientWidth: bannerLayout.clientWidth,
      overflow: bannerLayout.documentWidth - bannerLayout.clientWidth,
      controls: [{ name: "Reconnecting status", visible: true, reachable: true, focused: false }],
      tabZoom: exportZoom,
    });
    blockReconnect = false;
    await page.evaluate(() => (window as any).liveSocket.connect());
    await expect(root).toHaveClass(/phx-connected/);
    await expect(reconnectBanner).toBeHidden();

    await visit("/audit/policy/retention");
    const retentionZoom = await setAndReadTabZoom(context, page);
    expect(retentionZoom.tabId).toBe(coverageZoom.tabId);
    expect(retentionZoom.zoomFactor).toBe(2);
    await expect(page.locator("#retention-runs")).toBeVisible();
    const prune = page.getByRole("button", { name: "Prune now", exact: true }).first();
    observations.push({ ...await observePage(page, "Retention history", [
      ["Open prune confirmation", prune],
    ], true), tabZoom: retentionZoom });
    await page.setViewportSize({ width: 1280, height: 420 });
    expect((await setAndReadTabZoom(context, page)).zoomFactor).toBe(2);
    await prune.click();
    const pruneDialog = page.getByRole("dialog", { name: "Prune retained audit data?" });
    await expect(pruneDialog).toBeVisible();
    await expect(pruneDialog).toContainText("This prune applies the configured retention policy globally");
    const keepAuditData = pruneDialog.getByRole("button", { name: "Keep audit data", exact: true });
    await keepAuditData.scrollIntoViewIfNeeded();
    observations.push({ ...await observePage(page, "Retention confirmation at 200%", [
      ["Confirmation policy name", pruneDialog.getByRole("textbox", { name: "Policy name to confirm" })],
      ["Keep audit data", keepAuditData],
    ], true), tabZoom: retentionZoom });
    await keepAuditData.click();
    await expect(page.locator("#prune-confirm")).toBeHidden();
    await expect(prune).toBeFocused();

    console.log(`THREADLINE_INSPECTION_ZOOM_OBSERVATION=${JSON.stringify(observations)}`);
    await testInfo.attach("inspection-real-200-percent-zoom", { body: Buffer.from(JSON.stringify(observations, null, 2)), contentType: "application/json" });
  });
});

async function observePage(
  page: import("@playwright/test").Page,
  route: string,
  targets: [string, import("@playwright/test").Locator][],
  requireReachable: boolean,
) {
  const controls = [];
  for (const [name, locator] of targets) {
    const found = (await locator.count()) > 0;
    if (!found) {
      controls.push({ name, found, visible: false, reachable: false, focused: false });
      if (requireReachable) expect(found, `${route} is missing required control ${name}`).toBe(true);
      continue;
    }

    const target = locator.first();
    const visible = await target.isVisible();
    let state = { reachable: false, focused: false };
    if (visible) {
      await target.scrollIntoViewIfNeeded();
      await target.focus();
      state = await target.evaluate((element) => {
        const label = element instanceof HTMLInputElement && (element.type === "radio" || element.type === "checkbox")
          ? element.labels?.[0]
          : undefined;
        const pointerTarget = label ?? element;
        const rect = pointerTarget.getBoundingClientRect();
        const x = rect.left + Math.min(Math.max(rect.width / 2, 1), Math.max(rect.width - 1, 1));
        const y = rect.top + Math.min(Math.max(rect.height / 2, 1), Math.max(rect.height - 1, 1));
        const hit = document.elementFromPoint(x, y);
        const focused = element === document.activeElement;
        const pointerReachable = rect.width > 0 && rect.height > 0 && rect.left >= -1 && rect.right <= innerWidth + 1 && rect.top >= -1 && rect.bottom <= innerHeight + 1 && hit !== null && (hit === pointerTarget || pointerTarget.contains(hit) || hit.contains(pointerTarget));
        return {
          reachable: focused && pointerReachable,
          focused,
          pointerTarget: `${pointerTarget.tagName.toLowerCase()}${pointerTarget.id ? `#${pointerTarget.id}` : ""}${typeof pointerTarget.className === "string" && pointerTarget.className ? `.${pointerTarget.className.trim().replace(/\s+/g, ".")}` : ""}`,
          targetRect: { left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom, width: rect.width, height: rect.height },
          hitTarget: hit ? `${hit.tagName.toLowerCase()}${hit.id ? `#${hit.id}` : ""}${typeof hit.className === "string" && hit.className ? `.${hit.className.trim().replace(/\s+/g, ".")}` : ""}` : null,
        };
      });
    }
    controls.push({ name, found, visible, ...state });
    if (requireReachable) {
      expect(visible, `${route} control ${name} is hidden`).toBe(true);
      expect(state.reachable, `${route} control ${name} is off-screen or covered: ${JSON.stringify(state)}`).toBe(true);
    }
  }

  const layout = await page.evaluate((routeName) => {
    const root = document.documentElement;
    return {
      route: routeName,
      path: location.pathname + location.search,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      documentWidth: root.scrollWidth,
      clientWidth: root.clientWidth,
      overflow: root.scrollWidth - root.clientWidth,
    };
  }, route);
  expect(layout.viewport.width, `${route} CSS viewport width at 200% tab zoom`).toBe(640);
  if (requireReachable) expect(layout.overflow, `${route} has whole-page horizontal overflow`).toBeLessThanOrEqual(1);
  return { ...layout, controls };
}

async function openThemeControls(page: import("@playwright/test").Page): Promise<[string, import("@playwright/test").Locator][]> {
  const shell = page.getByTestId("operator-nav-shell");
  const theme = (name: string) => [`${name} theme`, shell.getByRole("radio", { name, exact: true })] as [string, import("@playwright/test").Locator];
  const system = shell.getByRole("radio", { name: "System" });
  if (!(await system.isVisible())) {
    const toggle = shell.locator(".tl-shell-nav__toggle");
    if (await toggle.isVisible()) await toggle.click();
  }
  return [theme("System"), theme("Light"), theme("Dark"), ["Apply theme", shell.getByRole("button", { name: "Apply theme", exact: true })]];
}
