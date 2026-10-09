import { chromium, expect, test } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { setAndReadTabZoom, withIsolatedZoomContext } from "../support/operator-tab-zoom.js";

const require = createRequire(import.meta.url);
const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const acceptMode = process.env.THREADLINE_ZOOM_ACCEPT === "1";

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

    const observations = [];
    await expect(page.getByRole("link", { name: "Open the timeline" })).toBeVisible();
    observations.push(await observePage(page, "Home"));

    await page.goto(new URL("/audit/timeline?correlation_id=walk-acme-4521-close", String(baseURL)).toString());
    await expect(page.getByRole("heading", { name: "Investigate audit activity" })).toBeVisible();
    await expect(page.getByRole("button", { name: "Apply", exact: true })).toBeVisible();
    await expect(page.getByRole("textbox", { name: "Correlation id" })).toBeVisible();
    observations.push(await observePage(page, "Timeline"));

    const transactionLink = page.getByTestId("timeline-row").first().getByTestId("transaction-link");
    await expect(transactionLink).toBeVisible();
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).toMatch(/^\/audit\/transactions\/[^/?]+$/);
    await page.goto(new URL(transactionHref!, String(baseURL)).toString());
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    observations.push(await observePage(page, "Transaction"));

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

async function observePage(page: import("@playwright/test").Page, route: string) {
  return page.evaluate((routeName) => {
    const root = document.documentElement;
    const controls = Array.from(document.querySelectorAll<HTMLElement>("a,button,input,select,textarea,summary"))
      .filter((element) => {
        const style = getComputedStyle(element);
        return style.display !== "none" && style.visibility !== "hidden" && element.getAttribute("aria-hidden") !== "true";
      })
      .map((element) => {
        const rect = element.getBoundingClientRect();
        const x = rect.left + Math.min(Math.max(rect.width / 2, 1), Math.max(rect.width - 1, 1));
        const y = rect.top + Math.min(Math.max(rect.height / 2, 1), Math.max(rect.height - 1, 1));
        const hit = document.elementFromPoint(x, y);
        const label = element.getAttribute("aria-label") || element.innerText || element.getAttribute("name") || element.id || element.tagName;
        return {
          name: label.trim().replace(/\s+/g, " ").slice(0, 100),
          visible: rect.width > 0 && rect.height > 0,
          reachable: rect.left >= -1 && rect.right <= root.clientWidth + 1 && rect.top >= -1 && rect.bottom <= window.innerHeight + 1 && Boolean(hit) && (hit === element || element.contains(hit)),
        };
      });

    return {
      route: routeName,
      path: location.pathname + location.search,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      documentWidth: root.scrollWidth,
      clientWidth: root.clientWidth,
      overflow: root.scrollWidth - root.clientWidth,
      controls,
    };
  }, route);
}
