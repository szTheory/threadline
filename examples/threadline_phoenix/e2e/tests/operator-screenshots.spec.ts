import { test, expect, Page, TestInfo } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const supportEmail = "support@acme.example.com";
const correlation = "walk-acme-4521-close";

async function login(page: Page, email = adminEmail) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function capture(page: Page, testInfo: TestInfo, name: string) {
  await page.waitForLoadState("networkidle");
  await page.screenshot({
    path: testInfo.outputPath(`${name}.png`),
    fullPage: true,
  });
}

test.describe("operator surface screenshots", () => {
  test("admin investigation and governance surfaces", async ({ page }, testInfo) => {
    await login(page);

    await page.goto("/audit");
    await expect(page.getByTestId("operator-header")).toBeVisible();
    await capture(page, testInfo, "admin-timeline-default");

    await page.goto(`/audit?correlation_id=${encodeURIComponent(correlation)}`);
    await expect(page.getByTestId("timeline-row").filter({ hasText: "tickets" }).first()).toBeVisible();
    await capture(page, testInfo, "admin-timeline-correlation");

    await page.getByTestId("transaction-link").first().click();
    await expect(page).toHaveURL(/\/audit\/transactions\//);
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    await capture(page, testInfo, "admin-transaction-detail");

    await page
      .getByTestId("transaction-change-row")
      .filter({ hasText: "ticket_replies" })
      .getByTestId("row-history-link")
      .first()
      .click();
    await expect(page.getByTestId("row-history-drawer")).toBeVisible();
    await capture(page, testInfo, "admin-row-history");

    await page.goto("/audit/evidence");
    await expect(page.getByTestId("evidence-table").first()).toBeVisible();
    await capture(page, testInfo, "admin-evidence");

    await page.goto("/audit/coverage");
    await expect(page.getByTestId("coverage-table")).toBeVisible();
    await capture(page, testInfo, "admin-coverage");

    await page.goto("/audit/policy/redaction");
    await expect(page.getByTestId("policy-section").first()).toBeVisible();
    await capture(page, testInfo, "admin-policy-redaction");

    await page.goto("/audit/policy/retention");
    await expect(page.getByText("Retention History")).toBeVisible();
    await capture(page, testInfo, "admin-retention");

    await page.goto("/audit/exports");
    await expect(page.getByText("Export Status")).toBeVisible();
    await capture(page, testInfo, "admin-exports");
  });

  test("empty and denied states", async ({ page }, testInfo) => {
    await login(page);

    await page.goto("/audit?correlation_id=no-such-correlation");
    await expect(page.getByText("No changes match")).toBeVisible();
    await capture(page, testInfo, "admin-timeline-empty");

    await page.goto("/audit?from=not-a-date");
    await expect(page.locator("[role='alert']").first()).toBeVisible();
    await capture(page, testInfo, "admin-timeline-invalid-filter");

    await page.context().clearCookies();
    await login(page, supportEmail);

    await page.goto("/audit/evidence");
    await expect(page.getByText("Evidence view unavailable.")).toBeVisible();
    await capture(page, testInfo, "support-evidence-denied");

    await page.goto("/audit/coverage");
    await expect(page.getByText("Coverage inspection is not available")).toBeVisible();
    await capture(page, testInfo, "support-coverage-denied");
  });
});
