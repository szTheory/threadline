import { test, expect, Page } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const rowTable = "ticket_replies";

async function login(page: Page, email: string) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function gotoTicketRepliesTimeline(page: Page) {
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
  await expect(page.locator("#filter-table")).toHaveValue(rowTable);
}

async function openFirstTicketReplyTransaction(page: Page) {
  await gotoTicketRepliesTimeline(page);

  const timelineRow = page.getByTestId("timeline-row").filter({ hasText: rowTable }).first();
  await expect(timelineRow).toBeVisible();

  const transactionLink = timelineRow.getByTestId("transaction-link");
  await expect(transactionLink).toBeVisible();
  const transactionHref = await transactionLink.getAttribute("href");
  expect(transactionHref, `expected ${rowTable} transaction href`).not.toBeNull();

  await transactionLink.click();
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  return transactionHref!;
}

test.describe("operator surface (demo fiction)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, adminEmail);
  });

  test("ticket_replies table filter surfaces current seeded activity", async ({ page }) => {
    await gotoTicketRepliesTimeline(page);

    const row = page.getByTestId("timeline-row").filter({ hasText: rowTable }).first();
    await expect(row).toBeVisible();
    await expect(row.getByTestId("transaction-link")).toHaveAttribute(
      "href",
      /\/audit\/transactions\/[^/]+$/,
    );
  });

  test("evidence detail lists retention_run proof", async ({ page }) => {
    await page.goto("/audit/evidence");

    await expect(page.getByText("retention_run").first()).toBeVisible();
    await expect(page.locator('.tl-secondary-ref[title*="walk-retention-offboarded-co"]')).toBeVisible();
  });

  test("ticket_replies row history shows redacted capture", async ({ page }) => {
    await openFirstTicketReplyTransaction(page);

    const historyLink = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: rowTable })
      .getByTestId("row-history-link")
      .first();
    await expect(historyLink).toBeVisible();
    await historyLink.click();

    await expect(page).toHaveURL(/\/history\/ticket_replies\//);
    await expect(page.getByTestId("row-history-drawer").getByText("[REDACTED]")).toBeVisible();
  });

  test("ticket_replies delete row opens actor transaction", async ({ page }) => {
    await gotoTicketRepliesTimeline(page);

    const deleteRow = page
      .getByTestId("timeline-row")
      .filter({ hasText: rowTable })
      .filter({ hasText: "DELETE" })
      .first();
    await expect(deleteRow).toBeVisible();
    await deleteRow.getByTestId("transaction-link").click();

    await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);
    await expect(page.locator('a[href^="/audit/actors/user/"]').first()).toBeVisible();
    await expect(
      page
        .getByTestId("transaction-change-row")
        .filter({ hasText: rowTable })
        .filter({ hasText: "DELETE" }),
    ).toBeVisible();
  });
});
