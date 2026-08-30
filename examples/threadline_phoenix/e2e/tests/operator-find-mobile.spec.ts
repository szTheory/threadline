import { expect, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";

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

test.describe("operator Find cluster mobile UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("timeline dense mobile keeps filters and rows visible without a journey legend", async ({
    page,
  }) => {
    await page.goto("/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00");

    const filterSummary = page.locator(".tl-filter-summary");
    const timeline = page.getByTestId("operator-timeline");
    const firstRow = page.getByTestId("timeline-row").first();

    await expect(filterSummary).toBeVisible();
    await expect(timeline).toBeVisible();
    await expect(firstRow).toBeVisible();
    await expect(page.locator(".tl-journey--legend")).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
  });

  test("transaction mobile opens from Timeline with semantic values and copy controls", async ({
    page,
  }) => {
    await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);

    await page.getByTestId("transaction-link").first().click();
    await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

    await expect(page.locator(".tl-short-content")).toBeVisible();
    await expect(page.locator(".tl-value--redacted").first()).toBeVisible();

    const copy = page.locator(".tl-copy").first();
    await expect(copy).toBeVisible();
    await expect(copy).toBeEnabled();

    await expectNoHorizontalOverflow(page);
  });

  test("row-history mobile opens from a Transaction row with formatted values", async ({
    page,
  }) => {
    await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
    await page.getByTestId("transaction-link").first().click();

    await page
      .getByTestId("transaction-change-row")
      .filter({ hasText: "ticket_replies" })
      .getByTestId("row-history-link")
      .first()
      .click();

    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText("Row history:")).toBeVisible();

    await expect(drawer.locator(".tl-value--redacted").first()).toBeVisible();

    await expectNoHorizontalOverflow(page);
  });

  test("actor mobile exposes selected window state and transaction pivots", async ({ page }) => {
    await page.goto("/audit/actors/service_account/zendesk-sync");

    await expect(page.getByRole("button", { name: "24h", pressed: true })).toBeVisible();
    await expect(page.locator(".tl-segmented__item")).toHaveCount(0);

    const summary = page.locator(".tl-actor-summary").first();
    await expect(summary).toBeVisible();
    const summaryText = (await summary.textContent()) ?? "";
    expect(summaryText.includes("Changes unavailable") || summaryText.includes("changes")).toBeTruthy();

    await expect(page.getByRole("link", { name: "Open transaction" }).first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("coverage mobile shows Add capture remediation without horizontal overflow", async ({
    page,
  }) => {
    await page.goto("/audit/coverage");

    // WR-11: the remediation command lives inside a native <details> row
    // action (`tl-row-action--capture`, coverage_live.ex:197) that renders
    // collapsed by default — the summary ("Add capture") is visible
    // immediately, but its body (including the remediation command) is
    // hidden until the row is expanded. Make the expansion idempotent (read
    // `open` before deciding to click, rather than always clicking, so a
    // future `<details open>` default doesn't silently re-collapse the row)
    // and assert the summary text plus the resulting open state, so a
    // renamed affordance or a stale `open` default fails with a named cause
    // instead of an opaque visibility timeout.
    const row = page.locator("details.tl-row-action--capture").first();
    await expect(row.locator("summary")).toContainText("Add capture");
    if (!(await row.evaluate((el: HTMLDetailsElement) => el.open))) {
      await row.locator("summary").click();
    }
    await expect(row).toHaveAttribute("open", "");
    await expect(page.getByText("mix threadline.gen.triggers --tables").first()).toBeVisible();

    await expectNoHorizontalOverflow(page);
  });
});
