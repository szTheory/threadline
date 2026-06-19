import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";
const rowTable = "ticket_replies";
const leavingAgentId = "33123cc4-da21-5674-b030-e168cee90521";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function expectFocused(locator: Locator) {
  await expect(locator).toBeFocused();
  const boxShadow = await locator.evaluate(
    (element) => window.getComputedStyle(element).boxShadow,
  );
  expect(boxShadow).not.toBe("none");
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function openTimelineAdvancedFilters(page: Page) {
  const disclosure = page.locator(".tl-filter-disclosure");
  if ((await disclosure.count()) === 0) {
    return;
  }

  const open = await disclosure.evaluate((element) =>
    element.hasAttribute("open"),
  );
  if (!open) {
    await disclosure.locator("summary").click();
  }
}

async function discoverTransactionAndRowHistory(page: Page) {
  await page.goto(
    `/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`,
  );
  await expect(page.locator("#filter-correlation-id")).toHaveValue(
    closeCorrelation,
  );

  const transactionHref = await page
    .getByTestId("transaction-link")
    .first()
    .getAttribute("href");
  expect(transactionHref).not.toBeNull();

  await page.goto(transactionHref!);
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  const rowHistoryHref = await page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first()
    .getAttribute("href");

  expect(rowHistoryHref).not.toBeNull();
  return { transactionHref: transactionHref!, rowHistoryHref: rowHistoryHref! };
}

test.describe("operator accessibility baseline", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("exposes keyboard focus, skip link, nav state, and Home form names", async ({
    page,
  }) => {
    await page.goto("/audit");

    await page.keyboard.press("Tab");
    await expectFocused(page.locator(".tl-skip-link"));
    await expect(page.locator(".tl-skip-link")).toHaveText(
      "Skip to main content",
    );

    await page.keyboard.press("Enter");
    await expect(page.locator("#tl-main")).toBeFocused();

    await expect(
      page.getByRole("navigation", { name: "Operator surface" }),
    ).toBeVisible();
    await expect(page.getByTestId("operator-nav-overview")).toHaveAttribute(
      "aria-current",
      "page",
    );
    await expect(
      page.getByRole("status", { name: "System health" }),
    ).toBeVisible();

    await expect(
      page.locator("#tl-record-lookup").getByLabel("Table"),
    ).toBeVisible();
    await expect(
      page.locator("#tl-record-lookup").getByLabel("Record id"),
    ).toBeVisible();
    await expect(
      page
        .locator("#tl-record-lookup")
        .getByRole("button", { name: "Open row history" }),
    ).toBeVisible();
    await expect(
      page.locator("#tl-correlation-lookup").getByLabel("Correlation id"),
    ).toBeVisible();
    await expect(
      page
        .locator("#tl-correlation-lookup")
        .getByRole("button", { name: "Open Timeline" }),
    ).toBeVisible();

    await page.goto("/audit/timeline");
    const navToggle = page.locator(".tl-shell-nav__toggle");
    if (await navToggle.isVisible()) {
      await navToggle.click();
    }
    const timelineNav = page.getByTestId("operator-nav-timeline");
    await expect(timelineNav).toHaveAttribute("aria-current", "page");
    await timelineNav.focus();
    await expectFocused(timelineNav);
  });

  test("keeps Timeline filters, Actor segments, and Retention danger action named and stateful", async ({
    page,
  }) => {
    await page.goto("/audit/timeline");

    for (const label of ["from", "to", "table", "correlation id"]) {
      await expect(page.getByLabel(label, { exact: true })).toBeVisible();
    }

    const workflowLine = page.getByText(
      "Filter the timeline, open transactions or row history, then export the current view when you need a handoff.",
    );
    await expect(workflowLine).toBeVisible();
    await expect(page.getByText("FIND")).toHaveCount(0);
    await expect(page.getByText("EXPLAIN")).toHaveCount(0);
    await expect(page.getByText("PACKAGE")).toHaveCount(0);

    await openTimelineAdvancedFilters(page);
    for (const label of ["actor kind", "actor id"]) {
      await expect(page.getByLabel(label, { exact: true })).toBeVisible();
    }

    await page.getByLabel("correlation id", { exact: true }).focus();
    await expectFocused(page.getByLabel("correlation id", { exact: true }));

    await page.goto(`/audit/actors/user/${leavingAgentId}`);
    await page.getByRole("button", { name: "30d" }).click();
    const selectedWindow = page.getByRole("button", { pressed: true }).first();
    await expect(selectedWindow).toBeVisible();
    await expect(
      page.getByRole("group", { name: "Actor activity window" }),
    ).toBeVisible();

    await page.goto("/audit/policy/retention");
    const prune = page
      .getByRole("button", { name: "Run retention prune" })
      .last();
    await expect(prune).toBeVisible();
    await expect(prune).toHaveAttribute(
      "data-confirm",
      /permanently deletes older audit records/,
    );
    await prune.focus();
    await expectFocused(prune);

    await expectNoHorizontalOverflow(page);
  });

  test("keeps row-history drawer dialog semantics and visible focus", async ({
    page,
  }) => {
    const { transactionHref, rowHistoryHref } =
      await discoverTransactionAndRowHistory(page);

    await page.goto(transactionHref);
    const rowHistoryLink = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: rowTable })
      .getByTestId("row-history-link")
      .first();
    await expect(rowHistoryLink).toBeVisible();
    await rowHistoryLink.scrollIntoViewIfNeeded();
    await rowHistoryLink.focus();
    await expectFocused(rowHistoryLink);

    await page.goto(rowHistoryHref);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer).toHaveAttribute("role", "dialog");
    await expect(drawer).toHaveAttribute("aria-modal", "true");
    await expect(drawer).toHaveAttribute(
      "aria-labelledby",
      /row-history-title|row-history/,
    );

    const close = drawer.getByRole("link", { name: "Close" });
    await expect(close).toBeVisible();
    await close.focus();
    await expectFocused(close);

    await expect(drawer.getByLabel("View snapshot at")).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("renders status and verdict chips with text labels and non-color shape", async ({
    page,
  }) => {
    await page.goto("/audit/evidence");
    const verdict = page
      .locator(".tl-chip")
      .filter({ hasText: /Proven|Inferred|Unsupported/ })
      .first();
    await expect(verdict).toBeVisible();
    const verdictStyle = await verdict.evaluate((element) => {
      const style = window.getComputedStyle(element);
      return {
        borderWidth: style.borderTopWidth,
        borderStyle: style.borderTopStyle,
      };
    });
    expect(verdictStyle.borderWidth).not.toBe("0px");
    expect(verdictStyle.borderStyle).not.toBe("none");

    await page.goto("/audit/exports");
    for (const label of [
      "Ready to hand off",
      "Preparing",
      "Needs attention",
      "Unavailable",
    ]) {
      await expect(
        page.getByRole("heading", { name: label, exact: true }),
      ).toBeVisible();
    }

    await expectNoHorizontalOverflow(page);
  });
});
