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

    await page.goto(new URL("/audit/timeline?correlation_id=walk-acme-4521-close", String(baseURL)).toString());
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

    const transactionLink = page.getByTestId("timeline-row").first().getByTestId("transaction-link");
    await expect(transactionLink).toBeVisible();
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).toMatch(/^\/audit\/transactions\/[^/?]+$/);
    await page.goto(new URL(transactionHref!, String(baseURL)).toString());
    const transactionZoom = await setAndReadTabZoom(context, page);
    expect(transactionZoom.tabId).toBe(zoom.tabId);
    expect(transactionZoom.zoomFactor).toBe(2);
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    const firstChange = page.getByTestId("transaction-change-row").first();
    const disclosures = page.locator(".tl-transaction details > summary");
    const transactionObservation: PageObservation = await observePage(page, "Transaction", [
      ["Transaction ID full value disclosure", page.getByRole("button", { name: "Show full transaction ID" })],
      ["Before value label", page.getByText("Before", { exact: true })],
      ["After value label", page.getByText("After", { exact: true })],
      ["Native full-value disclosure", disclosures.first()],
      ["Transaction row history", firstChange.getByTestId("row-history-link")],
    ], acceptMode);
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
        };
      });
    }
    controls.push({ name, found, visible, ...state });
    if (requireReachable) {
      expect(visible, `${route} control ${name} is hidden`).toBe(true);
      expect(state.reachable, `${route} control ${name} is off-screen or covered`).toBe(true);
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
