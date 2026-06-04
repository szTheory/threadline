import { test, expect, Page, TestInfo } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const supportEmail = "support@acme.example.com";
const correlation = "walk-acme-4521-close";
const leavingAgentId = "33123cc4-da21-5674-b030-e168cee90521";
const durableScreenshotNames = new Set([
  "actor",
  "coverage",
  "evidence",
  "exports",
  "home",
  "redaction",
  "retention",
  "row-history",
  "timeline",
  "timeline-dense",
  "timeline-empty",
  "transaction",
]);

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

  const outputDir = process.env.OPERATOR_SCREENSHOT_DIR;
  const viewport = screenshotViewport(testInfo);
  if (outputDir && viewport && durableScreenshotNames.has(name)) {
    mkdirSync(outputDir, { recursive: true });
    await page.screenshot({
      path: join(outputDir, `${name}__default__${viewport}.png`),
      fullPage: true,
      scale: "css",
    });
  }
}

function screenshotViewport(testInfo: TestInfo) {
  switch (testInfo.project.name) {
    case "desktop-chromium":
      return "1280";
    case "mobile-chromium":
      return "375";
    default:
      return null;
  }
}

test.describe("operator surface screenshots", () => {
  test.beforeEach(async ({ page }, testInfo) => {
    if (!process.env.OPERATOR_SCREENSHOT_DIR) {
      return;
    }

    if (testInfo.project.name === "desktop-chromium") {
      await page.setViewportSize({ width: 1280, height: 900 });
    }

    if (testInfo.project.name === "mobile-chromium") {
      await page.setViewportSize({ width: 375, height: 812 });
    }
  });

  test("admin investigation and governance surfaces", async ({ page }, testInfo) => {
    await login(page);

    await page.goto("/audit");
    await expect(page.getByTestId("operator-header")).toBeVisible();
    await capture(page, testInfo, "home");

    await page.goto("/audit/timeline");
    await expect(page.getByTestId("operator-header")).toBeVisible();
    await capture(page, testInfo, "timeline");

    await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(correlation)}`);
    await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);
    await expect(page.getByTestId("timeline-row").filter({ hasText: "tickets" }).first()).toBeVisible();
    await capture(page, testInfo, "timeline-dense");

    await page.getByTestId("transaction-link").first().click();
    await expect(page).toHaveURL(/\/audit\/transactions\//);
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    await capture(page, testInfo, "transaction");

    await page
      .getByTestId("transaction-change-row")
      .filter({ hasText: "ticket_replies" })
      .getByTestId("row-history-link")
      .first()
      .click();
    await expect(page.getByTestId("row-history-drawer")).toBeVisible();
    await expect(page.getByTestId("row-history-drawer").getByText("[REDACTED]")).toBeVisible();
    await capture(page, testInfo, "row-history");

    await page.goto("/audit/timeline?table=ticket_replies&from=2026-05-20T00:00&to=2026-05-21T23:59");
    await expect(page.getByTestId("timeline-row").filter({ hasText: "DELETE" }).first()).toBeVisible();
    await capture(page, testInfo, "admin-delete-4518-timeline");

    await page.goto(`/audit/actors/user/${leavingAgentId}`);
    await page.getByRole("button", { name: "30d" }).click();
    await expect(page.getByText(`Actor: user / ${leavingAgentId}`)).toBeVisible();
    await expect(page.getByRole("button", { name: "30d", pressed: true })).toBeVisible();
    await expect(page.locator("#transactions-list, .tl-empty")).toBeVisible();
    await capture(page, testInfo, "actor");

    await page.goto("/audit/evidence");
    await expect(page.getByTestId("evidence-table").first()).toBeVisible();
    await expect(page.locator('.tl-secondary-ref[title*="walk-retention-offboarded-co"]')).toBeVisible();
    await capture(page, testInfo, "evidence");

    await page.goto("/audit/coverage");
    await expect(page.getByTestId("coverage-table")).toBeVisible();
    await capture(page, testInfo, "coverage");

    await page.goto("/audit/policy/redaction");
    await expect(page.getByTestId("policy-section").first()).toBeVisible();
    await expect(page.getByRole("heading", { name: "Redaction assurance" })).toBeVisible();
    await capture(page, testInfo, "redaction");

    await page.goto("/audit/policy/retention");
    await expect(page.getByText("What was purged, and did it succeed?")).toBeVisible();
    await capture(page, testInfo, "retention");

    await page.goto("/audit/exports");
    await expect(page.getByText("What's ready to hand off?")).toBeVisible();
    await expect(page.getByText("Completed").first()).toBeVisible();
    await expect(page.getByText("Failed").first()).toBeVisible();
    await expect(page.getByText("Queued").first()).toBeVisible();
    await capture(page, testInfo, "exports");
  });

  test("empty and denied states", async ({ page }, testInfo) => {
    await login(page);

    await page.goto("/audit/timeline?correlation_id=no-such-correlation");
    await expect(page.getByText("No captured changes match this window")).toBeVisible();
    await capture(page, testInfo, "timeline-empty");

    await page.goto("/audit/timeline?from=not-a-date");
    await expect(page.locator("[role='alert']").first()).toBeVisible();
    await capture(page, testInfo, "admin-timeline-invalid-filter");

    await page.context().clearCookies();
    await login(page, supportEmail);

    await page.goto("/audit/timeline");
    await expect(page.getByTestId("timeline-row").first()).toBeVisible();
    await capture(page, testInfo, "support-acme-timeline");

    await page.goto("/audit/evidence");
    await expect(page.getByText("Evidence view unavailable.")).toBeVisible();
    await capture(page, testInfo, "support-evidence-denied");

    await page.goto("/audit/coverage");
    await expect(page.getByText("Coverage inspection is not available")).toBeVisible();
    await capture(page, testInfo, "support-coverage-denied");
  });
});
