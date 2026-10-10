import { chromium, expect, Page, test } from "@playwright/test";
import {
  setAndReadTabZoom,
  withIsolatedZoomContext,
} from "../support/operator-tab-zoom.js";

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

async function expectLiveViewConnected(page: Page) {
  const liveRoot = page.locator("[data-phx-main]").first();
  if ((await liveRoot.count()) > 0) {
    await expect(liveRoot).toHaveClass(/phx-connected/);
  }
}

async function discoverTicketReplyRecordId(page: Page) {
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
  await expectLiveViewConnected(page);
  await expect(page.locator("#filter-table")).toHaveValue(rowTable);

  const transactionLink = page
    .getByTestId("timeline-row")
    .filter({ hasText: rowTable })
    .first()
    .getByTestId("transaction-link");

  await expect(transactionLink).toBeVisible();
  const transactionHref = await transactionLink.getAttribute("href");
  expect(transactionHref).not.toBeNull();

  await page.goto(transactionHref!);
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);
  await expectLiveViewConnected(page);

  const rowHistoryLink = page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first();

  await expect(rowHistoryLink).toBeVisible();
  const href = await rowHistoryLink.getAttribute("href");
  expect(href).not.toBeNull();

  const match = href!.match(new RegExp(`/history/${rowTable}/([^?#/]+)`));
  expect(
    match,
    `expected ${rowTable} row-history href, got ${href}`,
  ).not.toBeNull();
  return decodeURIComponent(match![1]);
}

test.describe("operator earned-flow browser UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("Home record lookup reaches first-class row history", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);

    await page.goto("/audit");
    await expectLiveViewConnected(page);

    const form = page.locator("#tl-record-lookup");
    await expect(form).toBeVisible();
    await expect(form.getByLabel("Table")).toBeVisible();
    await expect(form.getByLabel("Record id")).toBeVisible();
    await form
      .locator('select[name="record_lookup[table]"]')
      .selectOption(rowTable);
    await form
      .locator('input[name="record_lookup[record_id]"]')
      .fill(ticketReplyRecordId);
    await form.getByRole("button", { name: "Open row history" }).click();

    await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText("Row history:")).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("direct first-class row-history route opens without a transaction first", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);

    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    await expectLiveViewConnected(page);

    await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText(`Row history: ${rowTable}`)).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("Timeline-origin row history preserves committed filters and safe return", async ({
    page,
  }) => {
    const from = "2020-01-01T00:00";
    const to = "2099-01-01T00:00";
    await page.goto(
      `/audit/timeline?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&table=${encodeURIComponent(rowTable)}`,
    );
    await expectLiveViewConnected(page);

    const rowHistoryLink = page
      .getByTestId("timeline-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("timeline-row-history-link");
    await expect(rowHistoryLink).toBeVisible();
    const href = await rowHistoryLink.getAttribute("href");
    expect(href).not.toBeNull();
    const rowHistoryUrl = new URL(href!, page.url());
    expect(rowHistoryUrl.searchParams.get("origin")).toBe("timeline");
    expect(rowHistoryUrl.searchParams.get("from")).toBe(from);
    expect(rowHistoryUrl.searchParams.get("to")).toBe(to);
    expect(rowHistoryUrl.searchParams.get("table")).toBe(rowTable);

    await rowHistoryLink.click();
    await expectPath(page, rowHistoryUrl.pathname);
    await expectLiveViewConnected(page);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();

    const asOf = "2026-10-10T10:00";
    await drawer.locator('input[name="as_of"]').fill(asOf);
    await expect
      .poll(() => new URL(page.url()).searchParams.get("as_of"))
      .toBe("2026-10-10T10:00:00Z");
    const selectedUrl = new URL(page.url());
    expect(selectedUrl.searchParams.get("origin")).toBe("timeline");
    expect(selectedUrl.searchParams.get("from")).toBe(from);
    expect(selectedUrl.searchParams.get("to")).toBe(to);
    expect(selectedUrl.searchParams.get("table")).toBe(rowTable);

    await drawer.getByRole("link", { name: "Close", exact: true }).click();
    await expectPath(page, "/audit/timeline");
    const returnUrl = new URL(page.url());
    expect(returnUrl.searchParams.get("from")).toBe(from);
    expect(returnUrl.searchParams.get("to")).toBe(to);
    expect(returnUrl.searchParams.get("table")).toBe(rowTable);
    expect(returnUrl.searchParams.has("origin")).toBe(false);
    await expect(page.locator("#filter-table")).toHaveValue(rowTable);
    await expectNoHorizontalOverflow(page);
  });

  test("Timeline-origin row history stays reachable at actual 200% zoom", async ({}, testInfo) => {
    test.skip(
      testInfo.project.name !== "desktop-chromium",
      "The real tab-zoom extension runs only in desktop-chromium",
    );

    await withIsolatedZoomContext(chromium, async (context, page) => {
      const baseURL = testInfo.project.use.baseURL ?? "http://127.0.0.1:4002";
      await page.goto(new URL("/users/log_in", String(baseURL)).toString());
      const form = page.locator("#login_form");
      await form.getByLabel("Email").fill(adminEmail);
      await form.getByLabel("Password").fill(password);
      await form.getByRole("button", { name: /log in/i }).click();
      await expect(page).toHaveURL(new URL("/", String(baseURL)).toString(), {
        timeout: 30_000,
      });

      const from = "2020-01-01T00:00";
      const to = "2099-01-01T00:00";
      await page.goto(
        new URL(
          `/audit/timeline?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&table=${encodeURIComponent(rowTable)}`,
          String(baseURL),
        ).toString(),
      );
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      const zoom = await setAndReadTabZoom(context, page);
      expect(zoom.zoomFactor).toBe(2);

      const rowHistoryLink = page
        .getByTestId("timeline-row")
        .filter({ hasText: rowTable })
        .first()
        .getByTestId("timeline-row-history-link");
      await expect(rowHistoryLink).toBeVisible();
      await rowHistoryLink.click();
      await expect(page.getByTestId("row-history-drawer")).toBeVisible();
      const drawerZoom = await setAndReadTabZoom(context, page);
      expect(drawerZoom.tabId).toBe(zoom.tabId);
      expect(drawerZoom.zoomFactor).toBe(2);
      await expect(
        page.getByTestId("row-history-drawer").getByRole("link", {
          name: "Close",
          exact: true,
        }),
      ).toBeVisible();
      await expect(
        page.getByTestId("row-history-drawer").locator('input[name="as_of"]'),
      ).toBeVisible();
      await expectNoHorizontalOverflow(page);
    });
  });

  test("transaction-origin row history returns to the same transaction", async ({
    page,
  }) => {
    await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
    await expectLiveViewConnected(page);
    const transactionLink = page
      .getByTestId("timeline-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("transaction-link");
    await expect(transactionLink).toBeVisible();
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).not.toBeNull();
    const transactionUrl = new URL(transactionHref!, page.url());
    const transactionId = transactionUrl.pathname.split("/").at(-1)!;

    await page.goto(transactionUrl.toString());
    await expect(page).toHaveURL(transactionUrl.toString());
    await expectLiveViewConnected(page);
    const rowHistoryLink = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("row-history-link");
    await expect(rowHistoryLink).toBeVisible();
    const href = await rowHistoryLink.getAttribute("href");
    expect(href).not.toBeNull();
    const rowHistoryUrl = new URL(href!, page.url());
    expect(rowHistoryUrl.pathname).toContain(
      `/audit/transactions/${transactionId}/history/`,
    );

    await rowHistoryLink.click();
    await expectPath(page, rowHistoryUrl.pathname);
    await expectLiveViewConnected(page);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await drawer.locator('input[name="as_of"]').fill("2026-10-10T10:00");
    await expect
      .poll(() => new URL(page.url()).searchParams.get("as_of"))
      .toBe("2026-10-10T10:00:00Z");

    await drawer.getByRole("link", { name: "Close", exact: true }).click();
    await expectPath(page, `/audit/transactions/${transactionId}`);
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("Home correlation lookup lands on Timeline correlation filter", async ({
    page,
  }) => {
    await page.goto("/audit");
    await expectLiveViewConnected(page);

    const form = page.locator("#tl-correlation-lookup");
    await expect(form).toBeVisible();
    await expect(form.getByLabel("Correlation id")).toBeVisible();
    await form
      .locator('input[name="correlation[correlation_id]"]')
      .fill(closeCorrelation);
    await form.getByRole("button", { name: "Open the timeline" }).click();

    await expectPath(page, "/audit/timeline");
    expect(new URL(page.url()).searchParams.get("correlation_id")).toBe(
      closeCorrelation,
    );
    await expect(page.locator("#filter-correlation-id")).toHaveValue(
      closeCorrelation,
    );
    await expectNoHorizontalOverflow(page);
  });

  test("filtered Timeline context carries into Exports", async ({
    page,
  }) => {
    await page.goto(
      `/audit/timeline?table=${encodeURIComponent(rowTable)}&correlation_id=${encodeURIComponent(
        closeCorrelation,
      )}`,
    );
    await expectLiveViewConnected(page);

    await expect(page.locator("#filter-correlation-id")).toHaveValue(
      closeCorrelation,
    );

    await page.getByRole("button", { name: "Filters" }).click();
    const filterDrawer = page.getByRole("dialog", { name: "Filters and handoff" });
    await expect(filterDrawer).toBeVisible();

    const carry = filterDrawer.getByRole("link", { name: "Carry to Exports" });
    await expect(carry).toBeVisible();
    await expect(carry).toHaveAttribute("href", /\/audit\/exports\?/);
    await carry.click();

    await expectPath(page, "/audit/exports");
    const url = new URL(page.url());
    expect(url.searchParams.get("table")).toBe(rowTable);
    expect(url.searchParams.get("correlation_id")).toBe(closeCorrelation);

    const context = page.getByTestId("timeline-export-context");
    await expect(context).toBeVisible();
    await expect(context.getByText("Timeline export context")).toBeVisible();
    await expect(context.locator("dt", { hasText: "table" })).toBeVisible();
    await expect(
      context.locator("dd", { hasText: rowTable }).locator(".tl-secondary-ref"),
    ).toHaveAttribute("data-tl-copy", rowTable);
    await expect(context.locator("dt", { hasText: "correlation_id" })).toBeVisible();
    await expect(
      context.locator("dd", { hasText: closeCorrelation }).locator(".tl-secondary-ref"),
    ).toHaveAttribute("data-tl-copy", closeCorrelation);
    await expect(context.locator("dt", { hasText: "source" })).toHaveCount(0);
    await expect(context.locator("dt", { hasText: "subject_ref_json" })).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
  });

  test("filtered Evidence context carries into Exports", async ({
    page,
  }) => {
    await page.goto("/audit/evidence");
    await expectLiveViewConnected(page);

    const proofHistory = page
      .getByRole("link", { name: "Open proof history" })
      .first();
    await expect(proofHistory).toBeVisible();
    await expect(proofHistory).toHaveAttribute(
      "href",
      /\/audit\/evidence\?.*mode=history/,
    );
    const proofHistoryHref = await proofHistory.getAttribute("href");
    expect(proofHistoryHref).not.toBeNull();
    await page.goto(proofHistoryHref!);
    await expect(page).toHaveURL(/\/audit\/evidence\?.*mode=history/);
    await expectLiveViewConnected(page);

    const carry = page
      .getByRole("link", { name: "Carry to Exports" })
      .first();
    await expect(carry).toBeVisible();
    await expect(carry).toHaveAttribute("href", /\/audit\/exports\?/);
    await carry.click();

    await expectPath(page, "/audit/exports");
    const url = new URL(page.url());
    expect(url.searchParams.get("source")).toBe("evidence");
    expect(url.searchParams.get("mode")).toBe("history");
    expect(url.searchParams.get("subject")).toBeTruthy();
    expect(url.searchParams.get("subject_ref_json")).toBeTruthy();

    const context = page.getByTestId("evidence-export-context");
    await expect(context).toBeVisible();
    await expect(context.getByText("Evidence export context")).toBeVisible();
    await expect(context.getByText("Evidence handoff")).toBeVisible();
    await expect(context.getByText("active Evidence view")).toBeVisible();
    await expect(context.locator("dt", { hasText: /^subject$/ })).toBeVisible();
    await expect(context.locator("dt", { hasText: /^mode$/ })).toBeVisible();
    await expect(
      context.locator("dd", { hasText: "history" }).locator(".tl-secondary-ref"),
    ).toHaveAttribute("data-tl-copy", "history");

    const reopen = context.getByRole("link", { name: "Reopen Evidence" });
    await expect(reopen).toBeVisible();
    await expect(reopen).toHaveAttribute("href", /\/audit\/evidence\?/);
    await expectNoHorizontalOverflow(page);
  });
});
