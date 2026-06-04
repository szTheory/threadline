import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";

const viewports = [
  { name: "phone", width: 375, height: 812, isMobile: true },
  { name: "tablet", width: 768, height: 900, isMobile: false },
  { name: "desktop", width: 1280, height: 900, isMobile: false },
];

const destinations = [
  { testId: "operator-nav-timeline", path: "/audit/timeline" },
  { testId: "operator-nav-coverage", path: "/audit/coverage" },
  { testId: "operator-nav-evidence", path: "/audit/evidence" },
  { testId: "operator-nav-policy", path: "/audit/policy/redaction" },
  { testId: "operator-nav-retention", path: "/audit/policy/retention" },
  { testId: "operator-nav-exports", path: "/audit/exports" },
];

type MatrixRoute = {
  name: string;
  path: string;
  assertRoute: (page: Page, viewportWidth: number) => Promise<void>;
};

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

async function expectBoxWithinViewport(locator: Locator, viewportWidth: number) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(-1);
  expect(rect!.x + rect!.width).toBeLessThanOrEqual(viewportWidth + 1);
}

async function expectOperatorChrome(page: Page) {
  await expect(page.locator("#tl-main")).toHaveCount(1);
  await expect(page.getByTestId("operator-header")).toBeVisible();

  const nav = page.locator(".tl-topbar__nav");
  await expect(nav).toBeVisible();

  for (const destination of destinations) {
    const link = page.getByTestId(destination.testId);
    await expectReachable(link);
    await expect(link).toHaveAttribute("href", destination.path);
  }
}

async function expectResponsiveTable(locator: Locator, viewportWidth: number) {
  await expect(locator).toBeVisible();

  if (viewportWidth < 1280) {
    const firstCell = locator.locator(".tl-table--responsive td").first();
    await expect(firstCell).toBeVisible();
    const labelContent = await firstCell.evaluate(
      (element) => window.getComputedStyle(element, "::before").content,
    );
    expect(labelContent).not.toBe("none");
    expect(labelContent).not.toBe('""');
  } else {
    await expect(locator.locator(".tl-table--responsive thead")).toBeVisible();
    await expect(locator.locator(".tl-table--responsive th").first()).toBeVisible();
  }
}

async function discoverMatrixRoutes(page: Page): Promise<MatrixRoute[]> {
  await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);

  const transactionHref = await page.getByTestId("transaction-link").first().getAttribute("href");
  expect(transactionHref).not.toBeNull();

  await page.goto(transactionHref!);
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  const rowHistoryHref = await page
    .getByTestId("transaction-change-row")
    .filter({ hasText: "ticket_replies" })
    .getByTestId("row-history-link")
    .first()
    .getAttribute("href");
  expect(rowHistoryHref).not.toBeNull();

  const rowMatch = rowHistoryHref!.match(/\/history\/([^/?#]+)\/([^?#/]+)/);
  expect(rowMatch, `expected row-history href, got ${rowHistoryHref}`).not.toBeNull();
  const rowPath = `/audit/rows/${rowMatch![1]}/${rowMatch![2]}`;

  return [
    { name: "home", path: "/audit", assertRoute: assertHome },
    { name: "timeline", path: "/audit/timeline", assertRoute: assertTimeline },
    { name: "coverage", path: "/audit/coverage", assertRoute: assertCoverage },
    { name: "transaction", path: transactionHref!, assertRoute: assertTransaction },
    { name: "row history", path: rowPath, assertRoute: assertRowHistory },
    {
      name: "actor",
      path: "/audit/actors/service_account/zendesk-sync",
      assertRoute: assertActor,
    },
    { name: "evidence", path: "/audit/evidence", assertRoute: assertEvidence },
    { name: "redaction", path: "/audit/policy/redaction", assertRoute: assertRedaction },
    { name: "retention", path: "/audit/policy/retention", assertRoute: assertRetention },
    { name: "exports", path: "/audit/exports", assertRoute: assertExports },
  ];
}

async function assertHome(page: Page) {
  await expect(page.getByRole("heading", { name: "Follow what happened." })).toBeVisible();
  await expect(page.locator('[data-earned-flow="EF1"]')).toBeVisible();
}

async function assertTimeline(page: Page) {
  await expect(page.getByTestId("operator-timeline")).toBeVisible();
  await expect(page.locator(".tl-toolbar__form")).toBeVisible();
  await page.locator("#filter-correlation-id").fill(closeCorrelation);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
}

async function assertCoverage(page: Page, viewportWidth: number) {
  await expect(page.getByRole("heading", { name: /Coverage/ })).toBeVisible();
  await expectResponsiveTable(page.getByTestId("coverage-table"), viewportWidth);
  await expect(page.getByText("Add capture").first()).toBeVisible();
}

async function assertTransaction(page: Page, viewportWidth: number) {
  await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
  await expectBoxWithinViewport(page.locator(".tl-value, .tl-secondary-ref").first(), viewportWidth);
  await expect(page.getByTestId("row-history-link").first()).toBeVisible();
}

async function assertRowHistory(page: Page, viewportWidth: number) {
  const drawer = page.getByTestId("row-history-drawer");
  await expect(page.locator(".tl-subview")).toBeVisible();
  await expect(drawer).toBeVisible();
  await expect(drawer.getByText("Row history:")).toBeVisible();
  await expectBoxWithinViewport(drawer, viewportWidth);
  await expectBoxWithinViewport(drawer.locator(".tl-value, .tl-secondary-ref").first(), viewportWidth);
}

async function assertActor(page: Page) {
  await expect(page.locator(".tl-actor-summary").first()).toBeVisible();
  await expect(page.getByRole("link", { name: "Open transaction" }).first()).toBeVisible();
}

async function assertEvidence(page: Page) {
  await expect(page.getByText("What can Threadline prove right now?")).toBeVisible();
  await expect(page.getByTestId("evidence-table").first()).toBeVisible();
  await expect(page.getByRole("link", { name: "Open proof history" }).first()).toBeVisible();
}

async function assertRedaction(page: Page) {
  await expect(page.getByText("Redaction assurance").first()).toBeVisible();
  await expect(page.getByTestId("policy-section").first()).toBeVisible();
}

async function assertRetention(page: Page, viewportWidth: number) {
  await expect(page.getByText("What was purged, and did it succeed?")).toBeVisible();
  await expect(page.getByRole("button", { name: "Run retention prune" }).last()).toBeVisible();
  await expectResponsiveTable(page.getByTestId("retention-runs-table"), viewportWidth);
}

async function assertExports(page: Page) {
  await expect(page.getByText("What's ready to hand off?")).toBeVisible();
  await expect(page.getByTestId("export-jobs")).toBeVisible();
  await expect(page.getByRole("link", { name: "Download export" }).first()).toBeVisible();
}

for (const viewport of viewports) {
  test.describe(`operator responsive matrix: ${viewport.name}`, () => {
    test.use({
      viewport: { width: viewport.width, height: viewport.height },
      isMobile: viewport.isMobile,
    });

    test("keeps every operator route usable without root horizontal overflow", async ({ page }) => {
      await login(page);
      const routes = await discoverMatrixRoutes(page);

      for (const route of routes) {
        await test.step(`${viewport.name}: ${route.name}`, async () => {
          await page.goto(route.path);
          await expectOperatorChrome(page);
          await route.assertRoute(page, viewport.width);
          await expectNoHorizontalOverflow(page);
        });
      }
    });
  });
}
