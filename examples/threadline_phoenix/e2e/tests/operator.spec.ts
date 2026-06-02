import { test, expect } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const correlation = "walk-acme-4521-close";

async function login(page, email: string) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

test.describe("operator surface (demo fiction)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page, adminEmail);
  });

  test("correlation filter surfaces hero close transaction", async ({ page }) => {
    await page.goto(`/audit?correlation_id=${encodeURIComponent(correlation)}`);

    await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);
    await expect(page.getByTestId("timeline-row").filter({ hasText: "tickets" }).first()).toBeVisible();
  });

  test("evidence detail lists retention_run proof", async ({ page }) => {
    await page.goto("/audit/evidence");

    await expect(page.getByText("retention_run").first()).toBeVisible();
    await expect(page.getByText("walk-retention-offboarded-co")).toBeVisible();
  });

  test("row history on #4521 close reply shows redacted capture", async ({ page }) => {
    await page.goto(`/audit?correlation_id=${encodeURIComponent(correlation)}`);

    const incidentLink = page.getByTestId("transaction-link").first();
    await expect(incidentLink).toBeVisible();
    await incidentLink.click();

    await expect(page).toHaveURL(/\/audit\/transactions\//);
    // The close transaction captures BOTH a tickets update and a ticket_replies
    // insert; target the reply's row-history link specifically (the redacted
    // internal_note_body lives on ticket_replies, not the ticket).
    const historyLink = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: "ticket_replies" })
      .getByTestId("row-history-link")
      .first();
    await expect(historyLink).toBeVisible();
    await historyLink.click();

    await expect(page).toHaveURL(/\/history\/ticket_replies\//);
    await expect(page.getByText("[REDACTED]")).toBeVisible();
  });
});
