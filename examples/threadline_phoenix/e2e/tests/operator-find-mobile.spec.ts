import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function box(locator: Locator) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  return rect!;
}

test.describe("operator Find cluster mobile UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("timeline dense mobile keeps filters and rows ahead of journey legend", async ({
    page,
  }) => {
    await page.goto("/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00");

    const filterSummary = page.locator(".tl-filter-summary");
    const timeline = page.getByTestId("operator-timeline");
    const firstRow = page.getByTestId("timeline-row").first();
    const journeyLegend = page.locator(".tl-journey--legend");

    await expect(filterSummary).toBeVisible();
    await expect(timeline).toBeVisible();
    await expect(firstRow).toBeVisible();
    await expect(journeyLegend).toBeVisible();

    const rowBox = await box(firstRow);
    const legendBox = await box(journeyLegend);
    expect(rowBox.y).toBeLessThan(legendBox.y);

    await expect(journeyLegend.locator("a, button")).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
  });
});
