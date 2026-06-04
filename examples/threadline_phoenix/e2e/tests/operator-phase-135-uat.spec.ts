import { expect, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const supportAcmeEmail = "support@acme.example.com";
const supportOffboardedEmail = "support@offboarded-co.example.com";

async function login(page: Page, email: string) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

test.describe("operator surface - Phase 135 automated UAT", () => {
  test("default Timeline renders in-window op variety and non-human actor labels", async ({
    page,
  }) => {
    await login(page, adminEmail);
    await page.goto("/audit/timeline");

    const rows = page.getByTestId("timeline-row");
    await expect(rows.filter({ hasText: "UPDATE" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "DELETE" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "service_account/zendesk-sync" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "job/oban-retention-purge" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "system/trigger-backfill" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "Actor unknown" }).first()).toBeVisible();
  });

  test("reply-edit transaction renders before/after diff with redacted internal note", async ({
    page,
  }) => {
    await login(page, adminEmail);
    await page.goto("/audit/timeline?table=ticket_replies");

    const replyUpdate = page
      .getByTestId("timeline-row")
      .filter({ hasText: "UPDATE" })
      .filter({ hasText: "ticket_replies" })
      .first();

    await expect(replyUpdate).toBeVisible();
    await replyUpdate.getByTestId("transaction-link").click();

    await expect(page).toHaveURL(/\/audit\/transactions\//);
    const changeRow = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: "ticket_replies" })
      .filter({ hasText: "UPDATE" })
      .first();

    await expect(changeRow).toBeVisible();
    await expect(changeRow.getByText("body", { exact: true })).toBeVisible();
    await expect(changeRow.getByText("Original reply from Zendesk sync.")).toBeVisible();
    await expect(changeRow.getByText("Updated reply")).toBeVisible();
    await expect(changeRow.getByText("internal_note_body")).toBeVisible();
    await expect(changeRow.getByText("[REDACTED]")).toHaveCount(2);
    await expect(changeRow.getByText("Internal: route to tier-2")).toHaveCount(0);
    await expect(changeRow.getByText("Confirmed tier-2 resolved. Closing.")).toHaveCount(0);
  });

  test("offboarded support user gets an honest empty scoped Timeline", async ({ page }) => {
    await login(page, supportOffboardedEmail);
    await page.goto("/audit/timeline");

    await expect(page.getByTestId("operator-scope")).toBeVisible();
    await expect(page.getByTestId("timeline-row")).toHaveCount(0);
    await expect(page.locator(".tl-empty")).toBeVisible();
    await expect(page.locator(".tl-empty")).toContainText(/No captured changes/);
    await expect(page.locator(".tl-empty")).not.toContainText(/error|crash/i);
  });

  test("support user is denied admin-only Coverage", async ({ page }) => {
    await login(page, supportAcmeEmail);
    await page.goto("/audit/coverage");

    await expect(page).toHaveURL(/\/audit\/coverage$/);
    await expect(page.getByRole("heading", { name: "Unsupported View" })).toBeVisible();
    await expect(page.getByText("Coverage inspection is not available")).toBeVisible();
    await expect(page.getByTestId("coverage-table")).toHaveCount(0);
  });
});
