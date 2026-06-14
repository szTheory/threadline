import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";

const viewports = [
  { name: "phone", width: 375, height: 812, isMobile: true },
  { name: "tablet", width: 768, height: 900, isMobile: false },
  { name: "desktop", width: 1280, height: 900, isMobile: false },
];

const destinations = [
  { testId: "operator-nav-overview", path: "/audit" },
  { testId: "operator-nav-timeline", path: "/audit/timeline" },
  { testId: "operator-nav-coverage", path: "/audit/coverage" },
  { testId: "operator-nav-evidence", path: "/audit/evidence" },
  { testId: "operator-nav-policy", path: "/audit/policy/redaction" },
  { testId: "operator-nav-retention", path: "/audit/policy/retention" },
  { testId: "operator-nav-exports", path: "/audit/exports" },
];

type MatrixRoute = {
  name: string;
  path: string;
  assertRoute: (page: Page, viewportWidth: number) => Promise<void>;
};

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

async function expectComputedPx(
  locator: Locator,
  property: string,
  expectedPx: number,
) {
  await expect(locator).toBeVisible();
  const value = await locator.evaluate(
    (element, cssProperty) =>
      window.getComputedStyle(element).getPropertyValue(cssProperty),
    property,
  );
  expect(Math.round(Number.parseFloat(value))).toBe(expectedPx);
}

async function expectReadableScale(page: Page) {
  await expectComputedPx(
    page.locator(".threadline-ui").first(),
    "font-size",
    16,
  );
  await expectComputedPx(
    page
      .locator(".tl-page__lede, .tl-orientation__lede, .tl-timeline-command__lede")
      .first(),
    "font-size",
    15,
  );
  await expectComputedPx(page.locator(".tl-button").first(), "font-size", 14);
  await expectComputedPx(page.locator(".tl-chip").first(), "font-size", 14);
  await expectComputedPx(
    page.locator(".tl-toolbar__field").first(),
    "font-size",
    14,
  );
}

async function expectCompactTableDensity(page: Page) {
  await expectComputedPx(
    page.locator(".tl-table--compact td").first(),
    "font-size",
    13,
  );
}

async function expectPageGutter(page: Page, expectedPx: number) {
  const main = page.locator("#tl-main.tl-page");
  await expect(main).toBeVisible();
  await expectComputedPx(main, "padding-left", expectedPx);
  await expectComputedPx(main, "padding-right", expectedPx);
}

async function expectTimelineIntroFlow(page: Page) {
  const mainToolbar = page.locator("#tl-main > .tl-toolbar");
  await expect(mainToolbar).toHaveCount(1);
  await expect(page.locator("#tl-main #timeline-filters")).toHaveCount(1);
  await expect(page.locator("#tl-main > .tl-timeline-command")).toHaveCount(1);

  const gap = await page.evaluate(() => {
    const command = document.querySelector(".tl-timeline-command");
    const toolbar = document.querySelector(".tl-toolbar");
    if (!command || !toolbar) {
      throw new Error("Timeline command surface or toolbar missing");
    }

    return toolbar.getBoundingClientRect().top - command.getBoundingClientRect().top;
  });

  expect(gap).toBeGreaterThanOrEqual(0);
  expect(gap).toBeLessThanOrEqual(1);
}

async function expectTrustRailGap(page: Page, expectedPx: number) {
  const gap = await page.evaluate(() => {
    const rail = document.querySelector("#tl-main > .tl-trust-rail");
    const next = rail?.nextElementSibling;
    if (!rail || !next) {
      throw new Error("Standalone trust rail or following section missing");
    }

    return Math.round(
      next.getBoundingClientRect().top - rail.getBoundingClientRect().bottom,
    );
  });

  expect(gap).toBeGreaterThanOrEqual(expectedPx);
}

async function expectCoverageCommandGap(page: Page, expectedPx: number) {
  const gap = await page.evaluate(() => {
    const rail = document.querySelector(".tl-coverage-command .tl-trust-rail");
    const metrics = document.querySelector(".tl-coverage-command__metrics");
    if (!rail || !metrics) {
      throw new Error("Coverage command rail or metrics missing");
    }

    return Math.round(
      metrics.getBoundingClientRect().top - rail.getBoundingClientRect().bottom,
    );
  });

  expect(gap).toBeGreaterThanOrEqual(expectedPx);
}

async function expectAuditHostBody(page: Page) {
  await expectComputedPx(page.locator("body"), "padding-left", 0);
  await expectComputedPx(page.locator("body"), "padding-right", 0);
  await expect(page.locator(".host-shell")).toHaveCount(0);
}

async function expectDemoHostShell(page: Page) {
  await expectComputedPx(page.locator("body"), "padding-left", 0);
  await expectComputedPx(page.locator("body"), "padding-right", 0);
  await expect(page.locator(".host-shell")).toBeVisible();
  await expect(page.locator(".rd-auth")).toBeVisible();
  await expect(page.locator(".rd-auth__card")).toBeVisible();
}

async function expectReachable(locator: Locator, options?: { scroll?: boolean }) {
  if (options?.scroll !== false) {
    await locator.scrollIntoViewIfNeeded();
  }

  await expect(locator).toBeVisible();
}

async function openOperatorNavIfNeeded(shell: Locator) {
  const panel = shell.locator(".tl-shell-nav__panel");
  if (!(await panel.isVisible())) {
    await shell.locator(".tl-shell-nav__toggle").click();
  }
  await expect(panel).toBeVisible();
  return panel;
}

async function closeOperatorNavIfNeeded(shell: Locator) {
  const panel = shell.locator(".tl-shell-nav__panel");
  if (await panel.isVisible()) {
    await shell.locator(".tl-shell-nav__toggle").click();
  }
  await expect(panel).toBeHidden();
}

async function expectLiveViewConnected(page: Page) {
  const liveRoot = page.locator("[data-phx-main]").first();
  if ((await liveRoot.count()) > 0) {
    await expect(liveRoot).toHaveClass(/phx-connected/);
  }
}

async function expectBoxWithinViewport(
  locator: Locator,
  viewportWidth: number,
) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(-1);
  expect(rect!.x + rect!.width).toBeLessThanOrEqual(viewportWidth + 1);
}

async function expectOperatorChrome(page: Page) {
  await expect(page.locator("#tl-main")).toHaveCount(1);
  await expectLiveViewConnected(page);
  await expect(page.getByTestId("operator-header")).toBeVisible();

  const shell = page.getByTestId("operator-nav-shell");
  await expect(shell).toBeVisible();
  const viewportWidth = page.viewportSize()?.width ?? 1280;

  if (viewportWidth < 768) {
    await openOperatorNavIfNeeded(shell);
  } else {
    await expect(shell.locator(".tl-shell-nav__toggle")).toBeHidden();
  }

  const nav = shell.locator(".tl-shell-nav__panel");
  await expect(nav).toBeVisible();

  for (const destination of destinations) {
    if (viewportWidth < 768 && !(await nav.isVisible())) {
      await openOperatorNavIfNeeded(shell);
    }

    const link = nav.getByTestId(destination.testId);
    await expectReachable(link, { scroll: false });
    await expect(link).toHaveAttribute("href", destination.path);
  }

  if (viewportWidth < 768) {
    await closeOperatorNavIfNeeded(shell);
  }
}

async function expectResponsiveTable(locator: Locator, viewportWidth: number) {
  await expect(locator).toBeVisible();

  if (viewportWidth < 1280) {
    const firstCell = locator.locator(".tl-table--responsive td").first();
    await expect(firstCell).toBeVisible();
    const labelContent = await firstCell.evaluate(
      (element) => window.getComputedStyle(element, "::before").content,
    );
    expect(labelContent).not.toBe("none");
    expect(labelContent).not.toBe('""');
  } else {
    await expect(locator.locator(".tl-table--responsive thead")).toBeVisible();
    await expect(
      locator.locator(".tl-table--responsive th").first(),
    ).toBeVisible();
  }
}

async function expectCoverageCaptureDisclosure(page: Page, viewportWidth: number) {
  const firstUncoveredRow = page.locator(".tl-table__row--uncovered").first();
  await expect(firstUncoveredRow).toBeVisible();

  if (viewportWidth >= 1280) {
    const tableCell = firstUncoveredRow.locator('td[data-label="TABLE"]');
    const tableBox = await tableCell.boundingBox();
    expect(tableBox).not.toBeNull();
    expect(tableBox!.width).toBeGreaterThanOrEqual(150);
  }

  const action = firstUncoveredRow.locator(".tl-row-action").first();
  const summary = action.locator(".tl-row-action__summary");
  await expect(summary).toBeVisible();
  await expect(summary).toContainText("Add capture");
  await summary.click();

  const command = action.locator(".tl-remediation__command");
  const copy = action.locator(".tl-copy--command");
  await expect(command).toBeVisible();
  await expect(copy).toBeVisible();

  const commandBox = await command.boundingBox();
  const copyBox = await copy.boundingBox();
  expect(commandBox).not.toBeNull();
  expect(copyBox).not.toBeNull();

  const overlaps = !(
    commandBox!.x + commandBox!.width <= copyBox!.x ||
    copyBox!.x + copyBox!.width <= commandBox!.x ||
    commandBox!.y + commandBox!.height <= copyBox!.y ||
    copyBox!.y + copyBox!.height <= commandBox!.y
  );

  expect(overlaps).toBe(false);
}

async function discoverMatrixRoutes(page: Page): Promise<MatrixRoute[]> {
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
    .filter({ hasText: "ticket_replies" })
    .getByTestId("row-history-link")
    .first()
    .getAttribute("href");
  expect(rowHistoryHref).not.toBeNull();

  const rowMatch = rowHistoryHref!.match(/\/history\/([^/?#]+)\/([^?#/]+)/);
  expect(
    rowMatch,
    `expected row-history href, got ${rowHistoryHref}`,
  ).not.toBeNull();
  const rowPath = `/audit/rows/${rowMatch![1]}/${rowMatch![2]}`;

  return [
    { name: "home", path: "/audit", assertRoute: assertHome },
    { name: "timeline", path: "/audit/timeline", assertRoute: assertTimeline },
    { name: "coverage", path: "/audit/coverage", assertRoute: assertCoverage },
    {
      name: "transaction",
      path: transactionHref!,
      assertRoute: assertTransaction,
    },
    { name: "row history", path: rowPath, assertRoute: assertRowHistory },
    {
      name: "actor",
      path: "/audit/actors/service_account/zendesk-sync",
      assertRoute: assertActor,
    },
    { name: "evidence", path: "/audit/evidence", assertRoute: assertEvidence },
    {
      name: "redaction",
      path: "/audit/policy/redaction",
      assertRoute: assertRedaction,
    },
    {
      name: "retention",
      path: "/audit/policy/retention",
      assertRoute: assertRetention,
    },
    { name: "exports", path: "/audit/exports", assertRoute: assertExports },
  ];
}

async function assertHome(page: Page) {
  await expect(page.getByTestId("operator-nav-overview")).toHaveAttribute(
    "aria-current",
    "page",
  );
  await expect(
    page.getByRole("heading", { name: "Follow what happened." }),
  ).toBeVisible();
  await expect(page.locator('[data-earned-flow="EF1"]')).toBeVisible();
}

async function assertTimeline(page: Page) {
  await expect(page.getByTestId("operator-timeline")).toBeVisible();
  await expect(page.locator(".tl-toolbar__form")).toBeVisible();
  await expectTimelineIntroFlow(page);
  await page.locator("#filter-correlation-id").fill(closeCorrelation);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(
    closeCorrelation,
  );
}

async function assertCoverage(page: Page, viewportWidth: number) {
  await expect(page.getByRole("heading", { name: /Coverage/ })).toBeVisible();
  await expectCoverageCommandGap(page, 12);
  await expectResponsiveTable(
    page.getByTestId("coverage-table"),
    viewportWidth,
  );
  await expectCoverageCaptureDisclosure(page, viewportWidth);
}

async function assertTransaction(page: Page, viewportWidth: number) {
  await expect(
    page.getByTestId("transaction-change-row").first(),
  ).toBeVisible();
  await expectBoxWithinViewport(
    page.locator(".tl-value, .tl-secondary-ref").first(),
    viewportWidth,
  );
  await expect(page.getByTestId("row-history-link").first()).toBeVisible();
}

async function assertRowHistory(page: Page, viewportWidth: number) {
  const drawer = page.getByTestId("row-history-drawer");
  await expect(page.locator(".tl-subview")).toBeVisible();
  await expect(drawer).toBeVisible();
  await expect(drawer.getByText("Row history:")).toBeVisible();
  await expectBoxWithinViewport(drawer, viewportWidth);
  await expectBoxWithinViewport(
    drawer.locator(".tl-value, .tl-secondary-ref").first(),
    viewportWidth,
  );
}

async function assertActor(page: Page) {
  await expect(page.locator(".tl-actor-summary").first()).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Open transaction" }).first(),
  ).toBeVisible();
}

async function assertEvidence(page: Page) {
  await expect(
    page.getByText("What can Threadline prove right now?"),
  ).toBeVisible();
  await expect(page.getByTestId("evidence-table").first()).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Open proof history" }).first(),
  ).toBeVisible();
}

async function assertRedaction(page: Page) {
  await expect(page.getByText("Redaction assurance").first()).toBeVisible();
  await expectTrustRailGap(page, 16);
  await expect(page.getByTestId("policy-section").first()).toBeVisible();
}

async function assertRetention(page: Page, viewportWidth: number) {
  await expect(
    page.getByText("What was purged, and did it succeed?"),
  ).toBeVisible();
  await expectTrustRailGap(page, 16);
  await expect(
    page.getByRole("button", { name: "Run retention prune" }).last(),
  ).toBeVisible();
  await expectResponsiveTable(
    page.getByTestId("retention-runs-table"),
    viewportWidth,
  );
}

async function assertExports(page: Page) {
  await expect(page.getByText("What's ready to hand off?")).toBeVisible();
  await expect(page.getByTestId("export-jobs")).toBeVisible();
  await expect(
    page.getByRole("link", { name: "Download export" }).first(),
  ).toBeVisible();
}

for (const viewport of viewports) {
  test.describe(`operator responsive matrix: ${viewport.name}`, () => {
    test.use({
      viewport: { width: viewport.width, height: viewport.height },
      isMobile: viewport.isMobile,
    });

    test("keeps every operator route usable without root horizontal overflow", async ({
      page,
    }) => {
      await login(page);
      const routes = await discoverMatrixRoutes(page);

      for (const route of routes) {
        await test.step(`${viewport.name}: ${route.name}`, async () => {
          await page.goto(route.path);
          await expectOperatorChrome(page);
          await route.assertRoute(page, viewport.width);
          await expectNoHorizontalOverflow(page);
        });
      }
    });

    test("keeps readable typography and intentional page gutters", async ({
      page,
    }) => {
      await login(page);
      await page.goto(
        `/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`,
      );
      await expect(page.locator("#filter-correlation-id")).toHaveValue(
        closeCorrelation,
      );
      await expect(page.getByTestId("timeline-row").first()).toBeVisible();
      await expectAuditHostBody(page);
      await expectReadableScale(page);
      await expectPageGutter(
        page,
        viewport.name === "phone" ? 8 : viewport.name === "tablet" ? 12 : 16,
      );
      await expectNoHorizontalOverflow(page);

      const transactionHref = await page
        .getByTestId("transaction-link")
        .first()
        .getAttribute("href");
      expect(transactionHref).not.toBeNull();
      await page.goto(transactionHref!);
      await expect(
        page.getByTestId("transaction-change-row").first(),
      ).toBeVisible();
      await expectComputedPx(
        page.locator(".tl-value").first(),
        "font-size",
        14,
      );
      await expectNoHorizontalOverflow(page);

      await page.goto("/audit/coverage");
      await expect(page.getByTestId("coverage-table")).toBeVisible();
      await expectCompactTableDensity(page);
      await expectPageGutter(
        page,
        viewport.name === "phone" ? 8 : viewport.name === "tablet" ? 12 : 16,
      );
      await expectNoHorizontalOverflow(page);
    });

    test("keeps non-audit demo pages in the host shell", async ({ page }) => {
      await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
      await expect(page.locator("#login_form")).toBeVisible();
      await expectDemoHostShell(page);
      await expectNoHorizontalOverflow(page);
    });
  });
}
