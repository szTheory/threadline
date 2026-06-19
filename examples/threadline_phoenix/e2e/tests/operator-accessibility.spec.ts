import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const rowTable = "ticket_replies";
const leavingAgentId = "33123cc4-da21-5674-b030-e168cee90521";

const d04RenderedStateCoverage = [
  {
    category: "modal/dialog",
    evidence: "Retention prune modal and stress modal opened in Chromium",
    status: "covered",
  },
  {
    category: "drawer",
    evidence: "Row-history drawer and stress drawer opened in Chromium",
    status: "covered",
  },
  {
    category: "dropdown/menu",
    evidence: "Stress dropdown menu and retention run action menu",
    status: "covered",
  },
  {
    category: "tabs",
    evidence: "Stress tabs render as a tablist with selected state",
    status: "covered",
  },
  {
    category: "disclosure/accordion",
    evidence: "Timeline advanced filters and stress accordion",
    status: "covered",
  },
  {
    category: "combobox/select/search",
    evidence:
      "Native Timeline filters plus stress combobox/select/search controls",
    status: "covered-native",
  },
  {
    category: "error summary",
    evidence: "Stress form error summary focuses an alert summary",
    status: "covered",
  },
  {
    category: "permission/unavailable/alert",
    evidence:
      "Stress permission, source-down, redacted, pruned, alert, and status states",
    status: "covered",
  },
  {
    category: "stale/status",
    evidence: "Stress stale banner and Timeline/Home/Retention status regions",
    status: "covered",
  },
  {
    category: "table/list/data panel",
    evidence: "Timeline list, Retention table, and stress data panel",
    status: "covered",
  },
  {
    category: "shell nav",
    evidence: "Operator shell nav, skip link, labelled nav groups",
    status: "covered",
  },
  {
    category: "mobile nav",
    evidence: "Native details-based shell nav at mobile viewport",
    status: "covered-native",
  },
  {
    category: "tooltip/popover",
    evidence:
      "Covered by APG/component semantics in Plan 180-02; no critical operator action is hover-only in current A11Y-01 flows",
    status: "not-applicable",
  },
];

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

async function expectNonObscuredFocused(locator: Locator, page: Page) {
  await expectFocused(locator);
  const visibleFocus = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const x = rect.left + Math.min(rect.width / 2, Math.max(1, rect.width - 1));
    const y = rect.top + Math.min(rect.height / 2, Math.max(1, rect.height - 1));
    const hit = document.elementFromPoint(x, y);

    return (
      rect.width > 0 &&
      rect.height > 0 &&
      rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= window.innerHeight + 1 &&
      rect.right <= window.innerWidth + 1 &&
      !!hit &&
      (hit === element || element.contains(hit))
    );
  });

  expect(visibleFocus).toBe(true);
  await expectNoHorizontalOverflow(page);
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function openOperatorNav(page: Page) {
  const shell = page.getByTestId("operator-nav-shell");
  const toggle = shell.locator(".tl-shell-nav__toggle");
  const panel = shell.locator(".tl-shell-nav__panel");

  if ((await toggle.isVisible()) && !(await panel.isVisible())) {
    await toggle.click();
  }

  if (!(await panel.isVisible())) {
    await shell.evaluate((element) => {
      if (element instanceof HTMLDetailsElement) {
        element.open = true;
      } else {
        element.setAttribute("open", "");
      }
    });
  }

  await expect(panel).toBeVisible();
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
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
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

  test("documents every D-04 rendered-state category as covered or explicitly bounded", async () => {
    expect(d04RenderedStateCoverage).toHaveLength(13);

    for (const item of d04RenderedStateCoverage) {
      expect(item.status, `${item.category} must not be missing`).not.toBe(
        "missing",
      );
      expect(item.evidence, `${item.category} needs concrete evidence`).toMatch(
        /\S/,
      );
      if (item.status === "not-applicable") {
        expect(item.evidence).toMatch(/Plan 180-02|native|no critical/i);
      }
    }
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

    const shellNav = page.getByTestId("operator-nav-shell");
    await expect(shellNav).toBeVisible();
    await expect(shellNav).toHaveAttribute("aria-label", "Operator surface");
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
    await openOperatorNav(page);
    const timelineNav = page.getByTestId("operator-nav-timeline");
    await expect(timelineNav).toHaveAttribute("aria-current", "page");
    await timelineNav.focus();
    await expectNonObscuredFocused(timelineNav, page);
  });

  test("keeps mobile shell navigation keyboard reachable without obscured focus", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 375, height: 900 });
    await page.goto("/audit");
    await openOperatorNav(page);

    const nav = page.getByTestId("operator-nav-shell");
    await expect(nav).toHaveAttribute("aria-label", "Operator surface");

    const toggle = nav.locator(".tl-shell-nav__toggle");
    await toggle.focus();
    await expectNonObscuredFocused(toggle, page);
    await page.keyboard.press("Enter");
    await expect(nav.locator(".tl-shell-nav__panel")).toBeVisible();

    const timeline = page.getByTestId("operator-nav-timeline");
    await timeline.focus();
    await expectNonObscuredFocused(timeline, page);
  });

  test("keeps Timeline filters, Actor segments, and Retention danger action named and stateful", async ({
    page,
  }) => {
    await page.goto("/audit/timeline");

    for (const label of ["From", "To", "Table", "Correlation id"]) {
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
    for (const label of ["Actor kind", "Actor id"]) {
      await expect(page.getByLabel(label, { exact: true })).toBeVisible();
    }

    const correlationFilter = page.getByLabel("Correlation id", {
      exact: true,
    });
    await correlationFilter.focus();
    await expectNonObscuredFocused(correlationFilter, page);

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
    await prune.focus();
    await expectNonObscuredFocused(prune, page);
    await prune.click();
    const pruneModal = page.locator("#prune-confirm");
    const pruneDialog = page.getByRole("dialog", {
      name: "Prune retention window permanently?",
    });
    await expect(pruneModal).toBeVisible();
    await expect(pruneDialog).toBeVisible();
    await expect(pruneDialog).toHaveAttribute("aria-modal", "true");
    await expect(pruneDialog).toHaveAttribute(
      "aria-describedby",
      "prune-confirm-description",
    );
    await expect(pruneModal).toContainText(
      "This permanently deletes audit records older than the retention window",
    );
    const confirm = pruneModal.getByLabel("Policy name to confirm");
    await expect(confirm).toBeVisible();
    await expectNonObscuredFocused(confirm, page);

    await page.keyboard.press("Escape");
    await expect(pruneModal).toBeHidden();
    await expectNonObscuredFocused(prune, page);

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
    await expectNonObscuredFocused(rowHistoryLink, page);

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
    await expectNonObscuredFocused(close, page);

    await expect(drawer.getByLabel("View snapshot at")).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("opens stress rendered widgets with names, keyboard state, and focus entry", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    await expect(page.getByTestId("stress-preview")).toBeVisible();

    const dropdownTrigger = page.locator("#stress-dropdown-button");
    const dropdownMenu = page.locator("#stress-dropdown-menu");
    await expect(dropdownTrigger).toHaveAttribute("aria-expanded", "false");
    await dropdownTrigger.focus();
    await expectNonObscuredFocused(dropdownTrigger, page);
    await page.keyboard.press("Enter");
    await expect(dropdownTrigger).toHaveAttribute("aria-expanded", "true");
    await expect(dropdownMenu).toBeVisible();
    await expect(dropdownMenu).toHaveAttribute("role", "menu");
    await expect(
      dropdownMenu.getByRole("menuitem", { name: "View stress details" }),
    ).toBeVisible();
    await page.keyboard.press("Escape");

    const accordion = page.getByRole("button", { name: "Accordion Section" });
    await expect(accordion).toHaveAttribute("aria-expanded", "false");
    await accordion.focus();
    await expectNonObscuredFocused(accordion, page);
    await page.keyboard.press("Enter");
    await expect(accordion).toHaveAttribute("aria-expanded", "true");
    await expect(page.locator("#stress-accordion-content")).toBeVisible();

    const activeTab = page.getByRole("tab", { name: "Tab 1" });
    await expect(activeTab).toHaveAttribute("aria-selected", "true");
    await activeTab.focus();
    await expectNonObscuredFocused(activeTab, page);

    await expect(
      page.getByRole("combobox", { name: "Combobox Field" }),
    ).toBeVisible();
    await expect(page.getByLabel("Select Field")).toBeVisible();
    await expect(page.getByLabel("Search Field")).toBeVisible();

    const errorSummary = page.getByRole("alert", {
      name: "There is a problem",
    });
    await expect(errorSummary).toBeVisible();
    await expect(errorSummary.getByRole("link", { name: /required/i })).toHaveAttribute(
      "href",
      "#stress-error",
    );

    const dataPanel = page.getByRole("region", { name: "Stress data panel" });
    await expect(dataPanel).toBeVisible();
    await expect(
      dataPanel.getByRole("table").getByRole("columnheader", {
        name: "Status",
      }),
    ).toBeVisible();

    await expect(
      page.getByRole("alert", {
        name: /You do not have access to this audit data/i,
      }),
    ).toBeVisible();
    await expect(
      page.getByRole("status").filter({ hasText: "Could not refresh" }),
    ).toBeVisible();

    const modalTrigger = page.getByRole("button", { name: "Show Modal" });
    await modalTrigger.focus();
    await expectNonObscuredFocused(modalTrigger, page);
    await page.keyboard.press("Enter");
    const modal = page.getByRole("dialog", { name: "Stress modal" });
    await expect(modal).toBeVisible();
    await expect(modal).toHaveAttribute("aria-modal", "true");
    await expect(modal).toHaveAttribute(
      "aria-describedby",
      "stress-modal-description",
    );
    await expect(page.getByRole("button", { name: "Confirm stress modal" })).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(modal).toBeHidden();
    await expectNonObscuredFocused(modalTrigger, page);

    const drawerTrigger = page.getByRole("button", { name: "Show Drawer" });
    await drawerTrigger.focus();
    await expectNonObscuredFocused(drawerTrigger, page);
    await page.keyboard.press("Enter");
    const drawer = page.getByRole("dialog", { name: "Stress drawer" });
    await expect(drawer).toBeVisible();
    await expect(drawer).toHaveAttribute("aria-modal", "true");
    await expect(drawer).toHaveAttribute(
      "aria-describedby",
      "stress-drawer-description",
    );
    await expect(page.getByRole("button", { name: "Close stress drawer" })).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(drawer).toBeHidden();
    await expectNonObscuredFocused(drawerTrigger, page);

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
