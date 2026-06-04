import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";
const rowTable = "ticket_replies";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function discoverRowHistoryHref(page: Page) {
  await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);

  const transactionHref = await page.getByTestId("transaction-link").first().getAttribute("href");
  expect(transactionHref).not.toBeNull();
  await page.goto(transactionHref!);

  const rowHistoryHref = await page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first()
    .getAttribute("href");

  expect(rowHistoryHref).not.toBeNull();
  return rowHistoryHref!;
}

async function expectOperatorScreenshot(page: Page, name: string, options: { fullPage?: boolean } = {}) {
  await page.waitForLoadState("networkidle");
  await expect(page).toHaveScreenshot(`${name}.png`, {
    fullPage: options.fullPage ?? true,
    maxDiffPixelRatio: 0.01,
    mask: dynamicMasks(page),
  });
}

function dynamicMasks(page: Page): Locator[] {
  return [
    page.locator("time"),
    page.locator(".tl-table__date"),
    page.locator(".tl-copy.is-copied"),
  ];
}

test.describe("operator screenshot regression guard", () => {
  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");

    if (testInfo.project.name === "desktop-chromium") {
      await page.setViewportSize({ width: 1280, height: 900 });
    }

    if (testInfo.project.name === "mobile-chromium") {
      await page.setViewportSize({ width: 375, height: 812 });
    }

    await login(page);
  });

  test("global chrome and Home workflow launchers stay stable", async ({ page }) => {
    await page.goto("/audit");
    await expect(page.getByTestId("operator-header")).toBeVisible();
    await expect(page.locator("#tl-record-lookup")).toBeVisible();
    await expectOperatorScreenshot(page, "home");
  });

  test("dense Timeline keeps row-first evidence stable", async ({ page }) => {
    await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
    await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
    await expect(page.getByTestId("timeline-row").first()).toBeVisible();
    await expectOperatorScreenshot(page, "timeline-dense", { fullPage: false });
  });

  test("row-history drawer keeps as-of evidence stable", async ({ page }) => {
    const rowHistoryHref = await discoverRowHistoryHref(page);

    await page.goto(rowHistoryHref);
    await expect(page.getByTestId("row-history-drawer")).toBeVisible();
    await expectOperatorScreenshot(page, "row-history");
  });

  test("Exports readiness hierarchy stays stable", async ({ page }) => {
    await page.goto("/audit/exports");
    await expect(page.getByText("What's ready to hand off?")).toBeVisible();
    await expect(
      page.getByTestId("export-jobs").getByRole("heading", { name: "Ready to hand off" }),
    ).toBeVisible();
    await expectOperatorScreenshot(page, "exports");
  });

  test("Retention safety hierarchy stays stable", async ({ page }) => {
    await page.goto("/audit/policy/retention");
    await expect(page.getByText("What was purged, and did it succeed?")).toBeVisible();
    await expect(page.getByRole("button", { name: "Run retention prune" }).last()).toBeVisible();
    await expectOperatorScreenshot(page, "retention");
  });
});
