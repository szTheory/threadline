import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

const destinations = [
  { label: "Timeline", testId: "operator-nav-timeline", path: "/audit/timeline" },
  { label: "Coverage", testId: "operator-nav-coverage", path: "/audit/coverage" },
  { label: "Evidence", testId: "operator-nav-evidence", path: "/audit/evidence" },
  { label: "Redaction", testId: "operator-nav-policy", path: "/audit/policy/redaction" },
  { label: "Retention", testId: "operator-nav-retention", path: "/audit/policy/retention" },
  { label: "Exports", testId: "operator-nav-exports", path: "/audit/exports" },
];

const representativeScreens = [
  "/audit",
  "/audit/timeline",
  "/audit/coverage",
  "/audit/evidence",
  "/audit/policy/redaction",
  "/audit/policy/retention",
  "/audit/exports",
];

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

async function expectMobileLayoutViewport(page: Page) {
  const viewport = await page.evaluate(() => ({
    hasViewportMeta: !!document.querySelector('meta[name="viewport"]'),
    innerWidth: window.innerWidth,
    rootClientWidth: document.documentElement.clientWidth,
  }));

  expect(viewport.hasViewportMeta).toBeTruthy();
  expect(viewport.innerWidth).toBeLessThanOrEqual(375);
  expect(viewport.rootClientWidth).toBeLessThanOrEqual(375);
}

async function expectReachable(locator: Locator) {
  await locator.scrollIntoViewIfNeeded();
  await expect(locator).toBeVisible();
}

async function expectHeaderDestinationsReachable(page: Page) {
  const nav = page.locator(".tl-topbar__nav");
  await expect(nav).toBeVisible();

  for (const group of ["Find", "Verify", "Prove"]) {
    await expectReachable(nav.locator(`.tl-topbar__nav-group[aria-label="${group}"] .tl-topbar__nav-label`));
  }

  for (const destination of destinations) {
    const link = page.getByTestId(destination.testId);
    await expectReachable(link);
    await expect(link).toHaveAttribute("href", destination.path);
  }
}

async function expectPath(page: Page, path: string) {
  await expect.poll(() => new URL(page.url()).pathname).toBe(path);
}

test.describe("operator Home orientation mobile UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("home exposes orientation cards, health, resume, and workflow launchers", async ({
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

    await expect(main.locator('[data-earned-flow="EF1"]')).toBeVisible();
    await expect(main.locator("#tl-record-lookup").getByLabel("Table")).toBeVisible();
    await expect(main.locator("#tl-record-lookup").getByLabel("Record id")).toBeVisible();
    await expect(
      main.locator("#tl-record-lookup").getByRole("button", { name: "Open row history" }),
    ).toBeVisible();

    await expect(main.locator('[data-earned-flow="EF4"]')).toBeVisible();
    await expect(main.locator("#tl-correlation-lookup").getByLabel("Correlation id")).toBeVisible();
    await expect(
      main.locator("#tl-correlation-lookup").getByRole("button", { name: "Open Timeline" }),
    ).toBeVisible();

    await expectMobileLayoutViewport(page);
    await expectNoHorizontalOverflow(page);
  });

  test("header destinations stay reachable from representative screens", async ({
    page,
  }) => {
    for (const screen of representativeScreens) {
      await page.goto(screen);
      await expectPath(page, screen);
      await expectMobileLayoutViewport(page);
      await expectHeaderDestinationsReachable(page);
      await expectNoHorizontalOverflow(page);
    }
  });

  test("home header nav activates every enabled destination", async ({ page }) => {
    for (const destination of destinations) {
      await page.goto("/audit");
      await expectPath(page, "/audit");

      const link = page.getByTestId(destination.testId);
      await expectReachable(link);
      await link.click();

      await expectPath(page, destination.path);
      await expectMobileLayoutViewport(page);
      await expectNoHorizontalOverflow(page);
    }
  });
});
