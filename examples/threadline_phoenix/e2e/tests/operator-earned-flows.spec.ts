import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";
const rowTable = "ticket_replies";

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

async function expectPath(page: Page, path: string) {
  await expect.poll(() => new URL(page.url()).pathname).toBe(path);
}

async function expectEarnedFlow(locator: Locator, flow: string) {
  await expect(locator).toBeVisible();
  await expect(locator).toHaveAttribute("data-earned-flow", flow);
}

async function expectEarnedFlowTrace(locator: Locator, flow: string) {
  await expect(locator).toHaveAttribute("data-earned-flow", flow);
}

async function discoverTicketReplyRecordId(page: Page) {
  await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
  await page.getByTestId("transaction-link").first().click();
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  const rowHistoryLink = page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first();

  await expect(rowHistoryLink).toBeVisible();
  const href = await rowHistoryLink.getAttribute("href");
  expect(href).not.toBeNull();

  const match = href!.match(new RegExp(`/history/${rowTable}/([^?#/]+)`));
  expect(match, `expected ${rowTable} row-history href, got ${href}`).not.toBeNull();
  return decodeURIComponent(match![1]);
}

test.describe("operator earned-flow browser UAT", () => {
  let ticketReplyRecordId: string;

  test.beforeEach(async ({ page }) => {
    await login(page);
    ticketReplyRecordId = await discoverTicketReplyRecordId(page);
  });

  test("EF1 Home record-first lookup reaches first-class row history", async ({ page }) => {
    await page.goto("/audit");

    const earnedFlow = page.locator('[data-earned-flow="EF1"]');
    await expectEarnedFlow(earnedFlow, "EF1");

    const form = page.locator("#tl-record-lookup");
    await form.locator('select[name="record_lookup[table]"]').selectOption(rowTable);
    await form.locator('input[name="record_lookup[record_id]"]').fill(ticketReplyRecordId);
    await form.getByRole("button", { name: "Open row history" }).click();

    await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    await expectEarnedFlowTrace(page.locator("#tl-main"), "EF2");
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText("Row history:")).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("EF2 direct first-class row-history route opens without a transaction first", async ({
    page,
  }) => {
    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);

    await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    await expectEarnedFlowTrace(page.locator("#tl-main"), "EF2");
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText(`Row history: ${rowTable}`)).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("EF4 Home correlation paste lands on Timeline correlation filter", async ({
    page,
  }) => {
    await page.goto("/audit");

    const earnedFlow = page.locator('[data-earned-flow="EF4"]');
    await expectEarnedFlow(earnedFlow, "EF4");

    const form = page.locator("#tl-correlation-lookup");
    await form.locator('input[name="correlation[correlation_id]"]').fill(closeCorrelation);
    await form.getByRole("button", { name: "Open Timeline" }).click();

    await expectPath(page, "/audit/timeline");
    expect(new URL(page.url()).searchParams.get("correlation_id")).toBe(closeCorrelation);
    await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
    await expect(page.getByTestId("timeline-row").first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("EF3 filtered Timeline context carries into Exports", async ({ page }) => {
    await page.goto(
      `/audit/timeline?table=${encodeURIComponent(rowTable)}&correlation_id=${encodeURIComponent(
        closeCorrelation,
      )}`,
    );

    await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
    await expect(page.getByTestId("timeline-row").first()).toBeVisible();

    const carry = page
      .locator('[data-earned-flow="EF3"]')
      .filter({ hasText: "Carry to Exports" })
      .first();
    await expectEarnedFlow(carry, "EF3");
    await carry.click();

    await expectPath(page, "/audit/exports");
    const url = new URL(page.url());
    expect(url.searchParams.get("table")).toBe(rowTable);
    expect(url.searchParams.get("correlation_id")).toBe(closeCorrelation);

    const context = page.getByTestId("timeline-export-context");
    await expectEarnedFlow(context, "EF3");
    await expect(context.getByText("Timeline export context")).toBeVisible();
    await expect(context.locator(".tl-param", { hasText: "table" })).toHaveAttribute(
      "title",
      `table: ${rowTable}`,
    );
    await expect(context.locator(".tl-param", { hasText: "correlation_id" })).toHaveAttribute(
      "title",
      `correlation_id: ${closeCorrelation}`,
    );
    await expect(context.locator(".tl-param__key", { hasText: "source" })).toHaveCount(0);
    await expect(context.locator(".tl-param__key", { hasText: "subject_ref_json" })).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
  });

  test("EF3 filtered Evidence proof context carries into Exports", async ({ page }) => {
    await page.goto("/audit/evidence");

    await page.getByRole("link", { name: "Open proof history" }).first().click();
    await expect(page).toHaveURL(/\/audit\/evidence\?.*mode=history/);

    const carry = page
      .locator('[data-earned-flow="EF3"]')
      .filter({ hasText: "Carry to Exports" })
      .first();
    await expectEarnedFlow(carry, "EF3");
    await carry.click();

    await expectPath(page, "/audit/exports");
    const url = new URL(page.url());
    expect(url.searchParams.get("source")).toBe("evidence");
    expect(url.searchParams.get("mode")).toBe("history");
    expect(url.searchParams.get("subject")).toBeTruthy();
    expect(url.searchParams.get("subject_ref_json")).toBeTruthy();

    const context = page.getByTestId("evidence-export-context");
    await expectEarnedFlow(context, "EF3");
    await expect(context.getByText("Evidence proof context")).toBeVisible();
    await expect(context.getByText("Proof handoff")).toBeVisible();
    await expect(context.locator('.tl-param[title^="subject: "]')).toHaveAttribute(
      "title",
      /subject: .+/,
    );
    await expect(context.locator(".tl-param", { hasText: "mode" })).toHaveAttribute(
      "title",
      "mode: history",
    );

    const reopen = context.getByRole("link", { name: "Reopen Evidence proof" });
    await expect(reopen).toBeVisible();
    await expect(reopen).toHaveAttribute("href", /\/audit\/evidence\?/);
    await expectNoHorizontalOverflow(page);
  });
});
