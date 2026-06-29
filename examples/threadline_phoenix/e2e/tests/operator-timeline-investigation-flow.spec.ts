import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const rowTable = "ticket_replies";
const correlatedTable = "posts";
const expectedTheme =
  process.env.THREADLINE_E2E_THEME === "system" ? "system" : "dark";

const viewports = [
  { name: "phone-320", width: 320, height: 760, isMobile: true },
  { name: "phone-375", width: 375, height: 812, isMobile: true },
  { name: "tablet-768", width: 768, height: 900, isMobile: false },
  { name: "desktop-1024", width: 1024, height: 900, isMobile: false },
  { name: "desktop-1440", width: 1440, height: 960, isMobile: false },
];

type TimelineParams = {
  correlation?: string;
  table?: string;
};

type CorrelatedPost = {
  correlation: string;
  table: string;
};

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function createCorrelatedPost(page: Page): Promise<CorrelatedPost> {
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const correlation = `tl-184-${suffix}`;
  const slug = `timeline-proof-${suffix}`;
  const response = await page.request.post("/api/posts", {
    data: {
      post: {
        title: "Timeline browser proof",
        slug,
      },
    },
    headers: {
      "content-type": "application/json",
      "x-correlation-id": correlation,
      "x-request-id": `tl-184-${suffix}`,
    },
  });

  expect(response.status()).toBe(201);

  return { correlation, table: correlatedTable };
}

function timelineUrl(params: TimelineParams = {}) {
  const search = new URLSearchParams({
    from: "2020-01-01T00:00",
    to: "2099-01-01T00:00",
  });

  if (params.table) {
    search.set("table", params.table);
  }

  if (params.correlation) {
    search.set("correlation_id", params.correlation);
  }

  return `/audit/timeline?${search.toString()}`;
}

async function expectLiveViewConnected(page: Page) {
  const liveRoot = page.locator("[data-phx-main]").first();
  if ((await liveRoot.count()) > 0) {
    await expect(liveRoot).toHaveClass(/phx-connected/);
  }
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function expectBoxWithinViewport(locator: Locator, viewportWidth: number) {
  const edgeTolerance = 4;
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(-edgeTolerance);
  expect(rect!.x + rect!.width).toBeLessThanOrEqual(
    viewportWidth + edgeTolerance,
  );
}

async function expectFocused(locator: Locator) {
  await expect(locator).toBeFocused();
  const hasVisibleCue = await locator.evaluate((element) => {
    const style = window.getComputedStyle(element);

    return (
      style.boxShadow !== "none" ||
      (style.outlineStyle !== "none" && style.outlineWidth !== "0px")
    );
  });

  expect(hasVisibleCue).toBe(true);
}

async function isFocused(locator: Locator) {
  return locator.evaluateAll((elements) =>
    elements.some(
      (element) =>
        element === document.activeElement ||
        element.contains(document.activeElement),
    ),
  );
}

async function tabTo(
  page: Page,
  locator: Locator,
  label: string,
  maxTabs = 40,
) {
  await expect(locator, `${label} must exist before tabbing`).toBeVisible();

  for (let i = 0; i <= maxTabs; i += 1) {
    if (await isFocused(locator)) {
      await expectFocused(locator);
      return;
    }

    await page.keyboard.press("Tab");
  }

  throw new Error(`Could not reach ${label} with ${maxTabs} Tab presses`);
}

async function expectTimelineWorkflow(page: Page, viewportWidth: number) {
  await expectLiveViewConnected(page);
  await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
    "data-tl-theme",
    expectedTheme,
  );
  await expect(
    page.getByRole("heading", { name: "Investigate audit activity" }),
  ).toBeVisible();

  const form = page.locator("#timeline-filters");
  await expect(form).toBeVisible();

  for (const label of ["From", "To", "Table", "Correlation id"]) {
    await expect(form.getByLabel(label, { exact: true })).toBeVisible();
  }

  await expect(page.getByRole("button", { name: "Filters" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Reset to last 24h" })).toBeVisible();
  await expect(
    form.getByRole("button", { name: "Apply", exact: true }),
  ).toBeVisible();

  const timeline = page.getByTestId("operator-timeline");
  const firstRow = page.getByTestId("timeline-row").first();
  const transaction = firstRow.getByTestId("transaction-link");

  await expect(timeline).toBeVisible();
  await expect(firstRow).toBeVisible();
  await expect(transaction).toBeVisible();

  const rowMetrics = await page.evaluate(() => {
    const command = document.querySelector(".tl-timeline-command");
    const firstRow = document.querySelector('[data-testid="timeline-row"]');
    const action = firstRow?.querySelector('[data-testid="transaction-link"]');

    if (!command || !firstRow || !action) {
      throw new Error("Timeline command, row, or transaction action missing");
    }

    const commandRect = command.getBoundingClientRect();
    const rowRect = firstRow.getBoundingClientRect();

    return {
      commandBottom: commandRect.bottom,
      rowTop: rowRect.top,
      rowVisiblePx: Math.max(
        0,
        Math.min(rowRect.bottom, window.innerHeight) - Math.max(rowRect.top, 0),
      ),
      viewportHeight: window.innerHeight,
    };
  });

  expect(rowMetrics.rowTop).toBeGreaterThanOrEqual(rowMetrics.commandBottom);
  expect(rowMetrics.rowTop).toBeLessThan(rowMetrics.viewportHeight);
  expect(rowMetrics.rowVisiblePx).toBeGreaterThanOrEqual(40);

  await expectBoxWithinViewport(firstRow, viewportWidth);
  await transaction.scrollIntoViewIfNeeded();
  await expectBoxWithinViewport(transaction, viewportWidth);
  const actionHitTestable = await transaction.evaluate((action) => {
    const rect = action.getBoundingClientRect();
    const actionCenterX = rect.left + rect.width / 2;
    const actionCenterY = rect.top + rect.height / 2;
    const hitTarget = document.elementFromPoint(actionCenterX, actionCenterY);

    return hitTarget === action || Boolean(hitTarget && action.contains(hitTarget));
  });
  expect(actionHitTestable).toBe(true);

  const refStyle = await firstRow.locator(".tl-secondary-ref").first().evaluate((element) => {
    const style = window.getComputedStyle(element);
    return {
      overflowWrap: style.overflowWrap,
      wordBreak: style.wordBreak,
    };
  });
  expect([refStyle.overflowWrap, refStyle.wordBreak]).toContain("anywhere");

  await expectNoHorizontalOverflow(page);
}

async function expectDrawerFocusReturn(page: Page, viewportWidth: number) {
  const filtersButton = page.getByRole("button", { name: "Filters" });
  await filtersButton.click();

  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  await expect(drawer).toBeVisible();
  await expectBoxWithinViewport(drawer, viewportWidth);
  await expect(drawer.getByLabel("Schema")).toBeVisible();
  await expect(drawer.getByLabel("Actor kind")).toBeVisible();
  await expect(drawer.getByLabel("Actor id")).toBeVisible();
  await expect(drawer.getByRole("button", { name: "Apply filters" })).toBeVisible();
  await expect(drawer.getByRole("link", { name: "Carry to Exports" })).toBeVisible();
  await expect(drawer.getByRole("button", { name: "Queue export" })).toBeVisible();

  await page.keyboard.press("Escape");
  await expect(drawer).toBeHidden();
  await expectFocused(filtersButton);
  await expectNoHorizontalOverflow(page);
}

async function expectFullValueCopy(page: Page, proof: CorrelatedPost) {
  const correlationCopy = page
    .locator(
      `[aria-label="Copy correlation id"][data-tl-copy="${proof.correlation}"]`,
    )
    .first();
  await expect(correlationCopy).toBeVisible();
  await expect(correlationCopy).toHaveAttribute("data-tl-copy", proof.correlation);

  const row = correlationCopy.locator(
    "xpath=ancestor::*[@data-testid='timeline-row'][1]",
  );
  await expect(row).toBeVisible();

  const correlationCode = row
    .locator(`code.tl-secondary-ref[data-tl-copy="${proof.correlation}"]`)
    .first();
  await expect(correlationCode).toHaveAttribute("data-tl-copy", proof.correlation);

  const actorCopy = row.getByRole("button", { name: "Copy actor ref" });
  if (await actorCopy.isVisible()) {
    const actorValue = await actorCopy.getAttribute("data-tl-copy");
    expect(actorValue).toMatch(/\S+\/\S+/);
  }

  const rowCopy = row.getByRole("button", { name: "Copy row id" });
  if (await rowCopy.isVisible()) {
    const copied = await rowCopy.getAttribute("data-tl-copy");
    const visible = await rowCopy.locator("xpath=../code").getAttribute("data-tl-copy");
    expect(copied).toBe(visible);
    expect(copied).toMatch(/\S/);
  }
}

async function expectExportAnchorsUseCurrentQuery(page: Page, proof: CorrelatedPost) {
  await page.getByRole("button", { name: "Filters" }).click();
  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  await expect(drawer).toBeVisible();

  const carry = drawer.getByRole("link", { name: "Carry to Exports" });
  await expect(carry).toHaveAttribute(
    "href",
    new RegExp(
      `/audit/exports\\?.*table=${proof.table}.*correlation_id=${proof.correlation}`,
    ),
  );

  for (const format of ["CSV", "JSON", "NDJSON"]) {
    const link = drawer.getByRole("link", { name: format, exact: true });
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute("download", "");
    await expect(link).toHaveAttribute(
      "href",
      new RegExp(
        `/audit/exports/changes\\.${format.toLowerCase()}\\?.*table=${proof.table}.*correlation_id=${proof.correlation}`,
      ),
    );
  }

  await page.keyboard.press("Escape");
  await expect(drawer).toBeHidden();
}

async function expectTimelineRouteTransition(page: Page, proof: CorrelatedPost) {
  await page.goto(timelineUrl({ table: proof.table }));
  const row = page
    .getByTestId("timeline-row")
    .filter({
      has: page.locator(
        `[aria-label="Copy correlation id"][data-tl-copy="${proof.correlation}"]`,
      ),
    })
    .first();
  await expect(row).toBeVisible();

  const correlationPivot = row.locator('a[title="View correlated changes in Timeline"]').first();
  await expect(correlationPivot).toBeVisible();
  await correlationPivot.click();
  await expect.poll(() => new URL(page.url()).pathname).toBe("/audit/timeline");
  expect(new URL(page.url()).searchParams.get("correlation_id")).toBe(
    proof.correlation,
  );

  await page.goto(timelineUrl({ correlation: proof.correlation, table: proof.table }));
  const transaction = page.getByTestId("transaction-link").first();
  await expect(transaction).toBeVisible();
  await transaction.click();
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  await page.goto(timelineUrl({ table: rowTable }));
  const historyRow = page
    .getByTestId("timeline-row")
    .filter({ has: page.getByTestId("timeline-row-history-link") })
    .first();
  await expect(historyRow).toBeVisible();
  const rowHistory = historyRow.getByTestId("timeline-row-history-link").first();
  await expect(rowHistory).toBeVisible();
  const rowHistoryHref = await rowHistory.getAttribute("href");
  expect(rowHistoryHref).toMatch(new RegExp(`/audit/rows/${rowTable}/[^?#/]+`));
  await rowHistory.click();
  await expect(page).toHaveURL(new RegExp(`/audit/rows/${rowTable}/[^?#/]+`));
  await expect(page.getByTestId("row-history-drawer")).toBeVisible();

  await page.goto(timelineUrl({ correlation: proof.correlation, table: proof.table }));
  await page.getByRole("button", { name: "Filters" }).click();
  await page.getByRole("link", { name: "Carry to Exports" }).click();
  await expect.poll(() => new URL(page.url()).pathname).toBe("/audit/exports");
  const url = new URL(page.url());
  expect(url.searchParams.get("table")).toBe(proof.table);
  expect(url.searchParams.get("correlation_id")).toBe(proof.correlation);
}

async function expectUrlRecovery(page: Page, proof: CorrelatedPost) {
  await page.goto("/audit/timeline");
  await expect(page.locator("#filter-from")).toHaveValue(
    /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/,
  );

  await page.locator("#filter-table").fill(rowTable);
  await page.locator("#filter-correlation-id").fill(proof.correlation);
  await page.keyboard.press("Enter");
  await expect.poll(() => new URL(page.url()).searchParams.get("table")).toBe(rowTable);
  expect(new URL(page.url()).searchParams.get("correlation_id")).toBe(
    proof.correlation,
  );

  await page.locator("#filter-correlation-id").fill("");
  await page
    .locator("#timeline-filters")
    .getByRole("button", { name: "Apply", exact: true })
    .click();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("correlation_id"))
    .toBeNull();

  await page.goBack();
  await expect.poll(() => new URL(page.url()).searchParams.get("correlation_id")).toBe(
    proof.correlation,
  );
  await expect(page.locator("#filter-correlation-id")).toHaveValue(
    proof.correlation,
  );

  await page.goForward();
  await expect
    .poll(() => new URL(page.url()).searchParams.get("correlation_id"))
    .toBeNull();
  await expect(page.locator("#filter-table")).toHaveValue(rowTable);
}

async function expectKeyboardWorkflow(page: Page, proof: CorrelatedPost) {
  await page.goto(timelineUrl({ correlation: proof.correlation, table: proof.table }));

  await page.keyboard.press("Tab");
  const skipLink = page.locator(".tl-skip-link");
  await expectFocused(skipLink);
  await page.keyboard.press("Enter");
  await expect(page.locator("#tl-main")).toBeFocused();

  const form = page.locator("#timeline-filters");
  await tabTo(page, form.getByLabel("From", { exact: true }), "From");
  await tabTo(page, form.getByLabel("To", { exact: true }), "To");
  await tabTo(page, form.getByLabel("Table", { exact: true }), "Table");
  await tabTo(
    page,
    form.getByLabel("Correlation id", { exact: true }),
    "Correlation id",
  );
  await tabTo(page, page.getByRole("button", { name: "Filters" }), "Filters");
  await tabTo(
    page,
    page.getByRole("link", { name: "Reset to last 24h" }),
    "Reset to last 24h",
  );
  await tabTo(
    page,
    form.getByRole("button", { name: "Apply", exact: true }),
    "Apply",
  );

  const row = page
    .getByTestId("timeline-row")
    .filter({ has: page.getByRole("button", { name: "Copy correlation id" }) })
    .first();
  await expect(row).toBeVisible();

  await tabTo(page, row.getByRole("button", { name: "Copy actor ref" }), "Copy actor ref");
  await tabTo(page, row.getByRole("link", { name: "Actor timeline" }), "Actor timeline");
  await tabTo(
    page,
    row.getByRole("button", { name: "Copy correlation id" }),
    "Copy correlation id",
  );
  await tabTo(
    page,
    row.locator('a[title="View correlated changes in Timeline"]'),
    "correlation Timeline pivot",
  );

  const rowCopy = row.getByRole("button", { name: "Copy row id" });
  if (await rowCopy.isVisible()) {
    await tabTo(page, rowCopy, "Copy row id");
  }

  await tabTo(
    page,
    row.getByRole("link", { name: "Open transaction" }),
    "Open transaction",
  );

  await page.goto(timelineUrl({ table: rowTable }));
  const historyRow = page
    .getByTestId("timeline-row")
    .filter({ has: page.getByTestId("timeline-row-history-link") })
    .first();
  await expect(historyRow).toBeVisible();
  await tabTo(
    page,
    historyRow.getByRole("link", { name: "Row history" }),
    "Row history",
  );

  const older = page.getByRole("button", { name: "Older" });
  if ((await older.count()) > 0 && await older.isEnabled()) {
    await tabTo(page, older, "Older pager");
  } else if ((await older.count()) > 0) {
    await expect(older).toBeDisabled();
  }

  const filters = page.getByRole("button", { name: "Filters" });
  await filters.focus();
  await page.keyboard.press("Enter");
  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  await expect(drawer).toBeVisible();
  await expect(drawer.getByRole("button", { name: "Close", exact: true })).toBeFocused();

  await tabTo(page, drawer.getByLabel("Schema"), "Schema");
  await tabTo(page, drawer.getByLabel("Actor kind"), "Actor kind");
  await tabTo(page, drawer.getByLabel("Actor id"), "Actor id");
  await tabTo(page, drawer.getByRole("button", { name: "Apply filters" }), "Apply filters");

  await page.keyboard.press("Escape");
  await expect(drawer).toBeHidden();
  await expectFocused(filters);
}

async function expectReducedMotionStableRows(page: Page) {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto(timelineUrl({ table: rowTable }));
  const row = page.getByTestId("timeline-row").first();
  await expect(row).toBeVisible();

  const before = await row.boundingBox();
  const style = await row.evaluate((element) => {
    const computed = window.getComputedStyle(element);

    return {
      animationName: computed.animationName,
      transform: computed.transform,
      transitionProperty: computed.transitionProperty,
    };
  });

  await page.waitForTimeout(150);
  const after = await row.boundingBox();

  expect(before).not.toBeNull();
  expect(after).not.toBeNull();
  expect(Math.round(after!.x - before!.x)).toBe(0);
  expect(Math.round(after!.y - before!.y)).toBe(0);
  expect(style.animationName).toBe("none");
  expect(["none", "matrix(1, 0, 0, 1, 0, 0)"]).toContain(style.transform);
  expect(style.transitionProperty).not.toContain("all");
  await expectNoHorizontalOverflow(page);
}

test.describe("Timeline investigation flow browser proof", () => {
  for (const viewport of viewports) {
    test.describe(`${viewport.name}`, () => {
      test.use({
        viewport: { width: viewport.width, height: viewport.height },
        isMobile: viewport.isMobile,
      });

      test("keeps filter-scan-open-export workflow reachable without overflow", async ({
        page,
      }) => {
        await login(page);
        await page.goto(timelineUrl({ table: rowTable }));
        await expectTimelineWorkflow(page, viewport.width);
        await expectDrawerFocusReturn(page, viewport.width);
      });
    });
  }

  test("keeps keyboard-only filters, rows, pagination, drawer, and route transitions operable", async ({
    page,
  }) => {
    await login(page);
    const proof = await createCorrelatedPost(page);
    await page.setViewportSize({ width: 768, height: 900 });
    await expectKeyboardWorkflow(page, proof);
  });

  test("restores URL-backed filters and proves Timeline route handoffs", async ({
    page,
  }) => {
    await login(page);
    const proof = await createCorrelatedPost(page);
    await expectUrlRecovery(page, proof);
    await expectTimelineRouteTransition(page, proof);
  });

  test("binds full-value copy metadata and real direct export anchors to the current query", async ({
    page,
  }) => {
    await login(page);
    const proof = await createCorrelatedPost(page);
    await page.goto(timelineUrl({ correlation: proof.correlation, table: proof.table }));
    await expectFullValueCopy(page, proof);
    await expectExportAnchorsUseCurrentQuery(page, proof);
  });
});

test.describe("Timeline reduced-motion browser proof", () => {
  test.use({ reducedMotion: "reduce" });

  test("keeps Timeline rows static with reduced motion", async ({ page }) => {
    await login(page);
    await expectReducedMotionStableRows(page);
  });
});
