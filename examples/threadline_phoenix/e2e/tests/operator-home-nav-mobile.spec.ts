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

async function expectReachable(locator: Locator) {
  await locator.scrollIntoViewIfNeeded();
  await expect(locator).toBeVisible();
}

test.describe("operator Home orientation mobile UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("home exposes orientation cards, health, resume, and no workflow form", async ({
    page,
  }) => {
    await page.goto("/audit");

    const main = page.locator("#tl-main");
    await expect(main.getByRole("heading", { name: "Follow what happened." })).toBeVisible();

    await expect(main.getByText("Find", { exact: true })).toBeVisible();
    await expect(main.getByRole("heading", { name: "What changed?" })).toBeVisible();
    await expect(main.getByRole("link", { name: "Open the timeline" })).toBeVisible();

    await expect(main.getByText("Verify", { exact: true })).toBeVisible();
    await expect(main.getByRole("heading", { name: "Is everything captured?" })).toBeVisible();
    await expect(main.getByRole("link", { name: "Check coverage" })).toBeVisible();

    await expect(main.getByText("Prove", { exact: true })).toBeVisible();
    await expect(main.getByRole("heading", { name: "Prove and export" })).toBeVisible();
    for (const action of ["Evidence", "Redaction", "Retention", "Exports"]) {
      await expect(main.getByRole("link", { name: action, exact: true })).toBeVisible();
    }

    const health = main.getByRole("status", { name: "System health" });
    await expect(health).toBeVisible();
    await expect(health.getByText("System health")).toBeVisible();

    await expect(main.getByRole("heading", { name: "Pick up where you left off" })).toBeVisible();
    await expect(main.getByRole("link", { name: "Recent deletes" })).toBeVisible();
    await expect(main.getByRole("link", { name: "Closed this week" })).toBeVisible();

    await expect(main.locator("form")).toHaveCount(0);
    await expect(main.locator("input, textarea, select")).toHaveCount(0);
    await expect(main.getByLabel(/record/i)).toHaveCount(0);
    await expect(main.getByLabel(/correlation/i)).toHaveCount(0);

    await expectNoHorizontalOverflow(page);
  });
});
