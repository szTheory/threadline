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
      "Stress tooltip relationship and popover dialog trigger are asserted in source/rendered proof",
    status: "covered",
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
  const focusStyle = await locator.evaluate((element) => {
    const style = window.getComputedStyle(element);

    return {
      boxShadow: style.boxShadow,
      outlineStyle: style.outlineStyle,
      outlineWidth: style.outlineWidth,
    };
  });
  const hasFocusRing =
    focusStyle.boxShadow !== "none" ||
    (focusStyle.outlineStyle !== "none" &&
      focusStyle.outlineWidth !== "0px");

  expect(hasFocusRing).toBe(true);
}

async function expectThemeOptionFocusVisible(radio: Locator) {
  await expect(radio).toBeFocused();
  const option = radio.locator(
    "xpath=ancestor::label[contains(concat(' ', normalize-space(@class), ' '), ' tl-theme-picker__option ')][1]",
  );
  await expect(option).toBeVisible();

  const focusStyle = await option.evaluate((element) => {
    const style = window.getComputedStyle(element);

    return {
      matchesFocusVisible: element.matches(":has(:focus-visible)"),
      matchesFocusWithin: element.matches(":focus-within"),
      outlineStyle: style.outlineStyle,
      outlineWidth: style.outlineWidth,
    };
  });

  const hasFocusRing =
    focusStyle.outlineStyle !== "none" && focusStyle.outlineWidth !== "0px";

  expect(
    hasFocusRing,
    `expected theme option focus ring, got ${JSON.stringify(focusStyle)}`,
  ).toBe(true);
}

async function focusByKeyboard(page: Page, target: Locator, maxTabs = 40) {
  for (let index = 0; index < maxTabs; index += 1) {
    const isFocused = await target.evaluate(
      (element) => element === document.activeElement,
    );

    if (isFocused) return;

    await page.keyboard.press("Tab");
  }

  await expect(target).toBeFocused();
}

async function expectNonObscuredFocused(locator: Locator, page: Page) {
  await expectFocused(locator);
  const focusVisibility = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const x = rect.left + Math.min(rect.width / 2, Math.max(1, rect.width - 1));
    const y = rect.top + Math.min(rect.height / 2, Math.max(1, rect.height - 1));
    const hit = document.elementFromPoint(x, y);

    const visible =
      rect.width > 0 &&
      rect.height > 0 &&
      rect.top >= 0 &&
      rect.left >= 0 &&
      rect.bottom <= window.innerHeight + 1 &&
      rect.right <= window.innerWidth + 1 &&
      !!hit &&
      (hit === element || element.contains(hit));

    return {
      hitTag: hit?.tagName ?? null,
      innerHeight: window.innerHeight,
      innerWidth: window.innerWidth,
      rect: {
        bottom: rect.bottom,
        height: rect.height,
        left: rect.left,
        right: rect.right,
        top: rect.top,
        width: rect.width,
      },
      visible,
    };
  });

  expect(
    focusVisibility.visible,
    `expected non-obscured focus, got ${JSON.stringify(focusVisibility)}`,
  ).toBe(true);
  await expectNoHorizontalOverflow(page);
}

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function expectAriaSnapshotContains(
  locator: Locator,
  expectedSnippets: (string | RegExp)[],
  options: { depth?: number } = {},
) {
  const snapshot = await locator.ariaSnapshot({
    depth: options.depth ?? 6,
  });

  for (const snippet of expectedSnippets) {
    if (typeof snippet === "string") {
      expect(snapshot).toContain(snippet);
    } else {
      expect(snapshot).toMatch(snippet);
    }
  }

  return snapshot;
}

async function openOperatorNav(page: Page) {
  const shell = page.getByTestId("operator-nav-shell");
  const disclosure = shell.locator(".tl-shell-nav__disclosure");
  const toggle = shell.locator(".tl-shell-nav__toggle");
  const panel = shell.locator(".tl-shell-nav__panel");

  if ((await toggle.isVisible()) && !(await panel.isVisible())) {
    await toggle.focus();
    await expectFocused(toggle);
    await page.keyboard.press("Enter");
  }

  await expect(panel).toBeVisible();
}

async function openTimelineAdvancedFilters(page: Page) {
  const disclosure = page.locator(".tl-filter-disclosure");
  if ((await disclosure.count()) > 0) {
    const open = await disclosure.evaluate((element) =>
      element.hasAttribute("open"),
    );
    if (!open) {
      await disclosure.locator("summary").click();
    }
    return;
  }

  const drawer = page.locator("#timeline-filters-drawer");
  if ((await drawer.count()) === 0 || (await drawer.isVisible())) {
    return;
  }

  await page.getByRole("button", { name: "Filters" }).first().click();
  await expect(drawer).toBeVisible();
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
    await expect(shellNav).toHaveAttribute("aria-label", "Audit navigation");
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
    await expect(page.locator("#filter-from")).toHaveValue(
      /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/,
    );
    await openOperatorNav(page);
    const timelineNav = page.getByTestId("operator-nav-timeline");
    await expect(timelineNav).toHaveAttribute("aria-current", "page");
    await expect(timelineNav).toBeVisible();
    await timelineNav.evaluate((element) => {
      if (element instanceof HTMLElement) element.focus();
    });
    await expectFocused(timelineNav);
    await expectNoHorizontalOverflow(page);
  });

  test("keeps mobile shell navigation keyboard reachable without obscured focus", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 375, height: 900 });
    await page.goto("/audit");

    const nav = page.getByTestId("operator-nav-shell");
    const disclosure = nav.locator(".tl-shell-nav__disclosure");
    await expect(nav).toHaveAttribute("aria-label", "Audit navigation");
    await disclosure.evaluate((element) => {
      if (element instanceof HTMLDetailsElement) {
        element.open = false;
      } else {
        element.removeAttribute("open");
      }
    });

    const toggle = nav.locator(".tl-shell-nav__toggle");
    const panel = nav.locator(".tl-shell-nav__panel");
    await expect(panel).toBeHidden();
    await toggle.focus();
    await expect(toggle).toBeFocused();
    await page.keyboard.press("Enter");
    await expect(disclosure).toHaveAttribute("open", "");
    await expect(panel).toBeVisible();

    const timeline = page.getByTestId("operator-nav-timeline");
    await expect(timeline).toBeVisible();
    await timeline.evaluate((element) => {
      if (element instanceof HTMLElement) element.focus();
    });
    await expectFocused(timeline);
    await expectNoHorizontalOverflow(page);
  });

  test("keeps Coverage readiness, schema recovery, and theme picker controls keyboard reachable", async ({
    page,
  }) => {
    await page.goto("/audit/coverage");

    const readiness = page.getByRole("region", {
      name: "Selected schema readiness",
    });
    await expect(readiness).toBeVisible();
    await expect(readiness).toContainText("selected schema");

    const schemaSelect = page.locator("#coverage-schema");
    await expect(schemaSelect).toBeVisible();
    await expect(schemaSelect).toHaveAttribute("name", "schema");
    await schemaSelect.focus();
    await expectNonObscuredFocused(schemaSelect, page);

    const applySchema = page.getByRole("button", { name: "Apply schema" });
    await applySchema.focus();
    await expectNonObscuredFocused(applySchema, page);

    const refresh = page.getByRole("button", { name: "Refresh" });
    await refresh.focus();
    await expectNonObscuredFocused(refresh, page);

    const rowAction = page.locator(".tl-row-action").first();
    await expect(rowAction).toBeVisible();
    const rowSummary = rowAction.locator("summary");
    await rowSummary.focus();
    await expectNonObscuredFocused(rowSummary, page);
    await page.keyboard.press("Enter");
    await expect(rowAction).toHaveAttribute("open", "");

    const copyCommand = rowAction.getByRole("button", {
      name: /Copy .* capture command/,
    });
    await expect(copyCommand).toBeVisible();
    await copyCommand.focus();
    await expectNonObscuredFocused(copyCommand, page);

    await page.goto("/audit/coverage?schema=missing_schema_187");
    const invalidSchema = page.locator(".tl-alert--error").first();
    await expect(invalidSchema).toBeVisible();
    await expect(invalidSchema).toContainText("missing_schema_187");
    const usePublicSchema = page.getByRole("link", { name: "Use public schema" });
    await usePublicSchema.focus();
    await expectNonObscuredFocused(usePublicSchema, page);

    await page.goto("/audit");
    await openOperatorNav(page);
    const themeGroup = page.getByTestId("operator-nav-group-theme");
    await expect(themeGroup).toBeVisible();
    await expect(themeGroup.locator('form[action="/audit/theme"]')).toBeVisible();
    await expect(themeGroup.locator('input[name="_csrf_token"]')).toHaveCount(1);

    for (const theme of ["System", "Light", "Dark"]) {
      const radio = themeGroup.getByRole("radio", { name: theme });
      await expect(radio).toBeVisible();
    }

    const checkedTheme = themeGroup.locator('input[name="theme"]:checked');
    await focusByKeyboard(page, checkedTheme);
    await expectThemeOptionFocusVisible(checkedTheme);

    for (let index = 0; index < 2; index += 1) {
      await page.keyboard.press("ArrowUp");
      await expectThemeOptionFocusVisible(
        themeGroup.locator('input[name="theme"]:focus'),
      );
    }

    const applyTheme = themeGroup.getByRole("button", { name: "Apply theme" });
    await page.keyboard.press("Tab");
    await expect(applyTheme).toBeFocused();
    await expectNonObscuredFocused(applyTheme, page);
  });

  test("keeps Timeline filters, Actor segments, and Retention danger action named and stateful", async ({
    page,
  }) => {
    await page.goto("/audit/timeline");

    for (const label of ["From", "To", "Table", "Correlation id"]) {
      await expect(page.getByLabel(label, { exact: true })).toBeVisible();
    }

    await expect(
      page.getByText(
        "Filter the timeline, open transactions or row history, then export the current view when you need a handoff.",
      ),
    ).toHaveCount(0);

    const timelineText = await page.locator("#tl-main").textContent();
    expect(timelineText).not.toMatch(/\bFIND\b/);
    expect(timelineText).not.toMatch(/\bEXPLAIN\b/);
    expect(timelineText).not.toMatch(/\bPACKAGE\b/);

    const correlationFilter = page
      .getByLabel("Correlation id", {
        exact: true,
      })
      .filter({ visible: true })
      .first();
    await correlationFilter.focus();
    await expectNonObscuredFocused(correlationFilter, page);

    await openTimelineAdvancedFilters(page);
    for (const label of ["Actor kind", "Actor id"]) {
      await expect(
        page.getByLabel(label, { exact: true }).filter({ visible: true }),
      ).toBeVisible();
    }

    await page.goto(`/audit/actors/user/${leavingAgentId}`);
    await page.getByRole("button", { name: "30d" }).click();
    const selectedWindow = page.getByRole("button", { pressed: true }).first();
    await expect(selectedWindow).toBeVisible();
    await expect(
      page.getByRole("group", { name: "Actor activity window" }),
    ).toBeVisible();

    await page.goto("/audit/policy/retention");
    await expect(page.locator("[data-phx-main]").first()).toHaveClass(
      /phx-connected/,
    );
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
    await expect(
      pruneModal.getByText("Type the policy name default to confirm"),
    ).toBeVisible();
    await expect(
      pruneModal.getByRole("button", { name: "Keep retention window" }),
    ).toBeVisible();
    const confirm = pruneModal.getByLabel("Policy name to confirm");
    await expect(confirm).toBeVisible();
    await expectNonObscuredFocused(confirm, page);

    await page.keyboard.press("Escape");
    await expect(pruneModal).toBeHidden();
    await expectNonObscuredFocused(prune, page);

    await expectNoHorizontalOverflow(page);
  });

  test("keeps Exports queue and download states named and keyboard reachable", async ({
    page,
  }) => {
    await page.goto(`/audit/exports?table=${encodeURIComponent(rowTable)}`);

    const exportContext = page.getByTestId("timeline-export-context");
    await expect(exportContext).toBeVisible();
    await expect(exportContext).toContainText("Timeline export context");

    const queue = exportContext.getByRole("button", {
      name: "Queue Timeline export",
    });
    await queue.focus();
    await expectNonObscuredFocused(queue, page);

    await page.goto("/audit/exports");
    const exportJobs = page.getByTestId("export-jobs");

    for (const label of [
      "Ready to hand off",
      "Preparing",
      "Needs attention",
      "Unavailable",
    ]) {
      await expect(
        exportJobs.getByRole("heading", { name: label, exact: true }),
      ).toBeVisible();
    }

    const download = exportJobs
      .getByRole("link", { name: "Download export" })
      .first();
    await expect(download).toBeVisible();
    await download.focus();
    await expectNonObscuredFocused(download, page);

    const reopen = exportJobs
      .getByRole("link", { name: "Reopen source search" })
      .first();
    await expect(reopen).toBeVisible();
    await reopen.focus();
    await expectNonObscuredFocused(reopen, page);

    await expect(exportJobs.getByText(/Queued|Processing/).first()).toBeVisible();
    await expect(exportJobs.getByText("Export failed.").first()).toBeVisible();
    await expect(
      exportJobs.getByText(/Expired|File unavailable/).first(),
    ).toBeVisible();

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
    const dialog = drawer.getByRole("dialog", { name: /Row history/ });
    await expect(drawer).toBeVisible();
    await expect(dialog).toBeVisible();
    await expect(dialog).toHaveAttribute("aria-modal", "true");
    await expect(dialog).toHaveAttribute(
      "aria-labelledby",
      /row-history-title|row-history/,
    );

    const close = dialog.getByRole("link", { name: "Close" });
    await expect(close).toBeVisible();

    const snapshot = dialog.getByLabel("View snapshot at");
    await expect(snapshot).toBeVisible();
    await snapshot.focus();
    await expectNonObscuredFocused(snapshot, page);
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
    await expect(dropdownTrigger).toHaveAttribute("aria-haspopup", "menu");
    await dropdownTrigger.scrollIntoViewIfNeeded();
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
    await accordion.scrollIntoViewIfNeeded();
    await accordion.focus();
    await expectNonObscuredFocused(accordion, page);
    await page.keyboard.press("Enter");
    await expect(accordion).toHaveAttribute("aria-expanded", "true");
    await expect(page.locator("#stress-accordion-content")).toHaveAttribute(
      "role",
      "region",
    );
    await expect(page.locator("#stress-accordion-content")).toBeVisible();

    const activeTab = page.getByRole("tab", { name: "Tab 1" });
    await expect(activeTab).toHaveAttribute("aria-selected", "true");
    await activeTab.scrollIntoViewIfNeeded();
    await activeTab.focus();
    await expectNonObscuredFocused(activeTab, page);

    await expect(
      page.getByRole("combobox", { name: "Combobox Field" }),
    ).toBeVisible();
    await expect(page.getByRole("combobox", { name: "Combobox Field" })).toHaveAttribute(
      "aria-haspopup",
      "listbox",
    );
    await expect(page.getByLabel("Select Field")).toBeVisible();
    await expect(page.getByLabel("Search Field")).toBeVisible();

    const popoverTrigger = page.locator("#stress-popover-trigger");
    await expect(popoverTrigger).toHaveAttribute("aria-haspopup", "dialog");
    await expect(popoverTrigger).toHaveAttribute("aria-controls", "stress-popover");
    await popoverTrigger.focus();
    await expectNonObscuredFocused(popoverTrigger, page);
    await popoverTrigger.click();
    await expect(popoverTrigger).toHaveAttribute("aria-expanded", "true");
    const popover = page.locator("#stress-popover");
    await expect(popover).toBeVisible();
    await expect(popover).toHaveAttribute("role", "dialog");
    await expect(popover).toContainText("Popover content");
    await popoverTrigger.click();
    await expect(popover).toBeHidden();

    const tooltipTrigger = page.getByText("Hover Tooltip");
    await expect(tooltipTrigger).toBeVisible();
    await expect(page.getByRole("tooltip")).toContainText("Tooltip content");

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
    await expect(dataPanel.getByRole("table")).toBeVisible();
    await expect(dataPanel.locator("th", { hasText: "Status" })).toHaveCount(
      1,
    );
    await expect(dataPanel.locator('td[data-label="Status"]')).toBeVisible();

    await expect(
      page
        .getByRole("alert")
        .filter({ hasText: "You do not have access to this audit data" }),
    ).toBeVisible();
    await expect(
      page.getByRole("status").filter({ hasText: "Could not refresh" }),
    ).toBeVisible();

    const modalTrigger = page.getByRole("button", { name: "Show Modal" });
    await modalTrigger.scrollIntoViewIfNeeded();
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
    await page.keyboard.press("Enter");
    await expect(modal).toBeHidden();
    await expectNonObscuredFocused(modalTrigger, page);

    const drawerTrigger = page.getByRole("button", { name: "Show Drawer" });
    await drawerTrigger.scrollIntoViewIfNeeded();
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
    await page.keyboard.press("Enter");
    await expect(drawer).toBeHidden();
    await expectNonObscuredFocused(drawerTrigger, page);

    await expectNoHorizontalOverflow(page);
  });

  test("captures accessibility-tree evidence for screen-reader-ready structure", async ({
    page,
  }, testInfo) => {
    await page.goto("/audit");
    const homeSnapshot = await expectAriaSnapshotContains(
      page.locator("#tl-main"),
      [
        '- main:',
        'heading "Follow what happened."',
        'status "System health"',
        'link "Open the timeline"',
        'combobox "Table"',
        'textbox "Record id"',
        'button "Open row history"',
      ],
      { depth: 6 },
    );
    await testInfo.attach("home-main-aria-snapshot", {
      body: homeSnapshot,
      contentType: "text/plain",
    });

    await page.goto("/audit/timeline");
    await openTimelineAdvancedFilters(page);
    const timelineSnapshot = await expectAriaSnapshotContains(
      page.locator("#tl-main"),
      [
        'region "Investigate audit activity"',
        'heading "Investigate audit activity" [level=1]',
        '- search:',
        'group "Search"',
        'textbox "From"',
        'textbox "To"',
        'combobox "Table"',
        'textbox "Correlation id"',
        'button "Apply"',
        'status:',
      ],
      { depth: 5 },
    );
    await testInfo.attach("timeline-main-aria-snapshot", {
      body: timelineSnapshot,
      contentType: "text/plain",
    });

    const { rowHistoryHref } = await discoverTransactionAndRowHistory(page);
    await page.goto(rowHistoryHref);
    const rowHistorySnapshot = await expectAriaSnapshotContains(
      page.getByTestId("row-history-drawer"),
      [
        /^- '?dialog /m,
        /heading "Row history:/,
        'link "Close"',
        'textbox "View snapshot at"',
        'list:',
      ],
      { depth: 6 },
    );
    await testInfo.attach("row-history-drawer-aria-snapshot", {
      body: rowHistorySnapshot,
      contentType: "text/plain",
    });

    await page.goto("/audit/policy/retention");
    await page.getByRole("button", { name: "Run retention prune" }).last().click();
    const retentionSnapshot = await expectAriaSnapshotContains(
      page.getByRole("dialog", { name: "Prune retention window permanently?" }),
      [
        'dialog "Prune retention window permanently?"',
        'heading "Prune retention window permanently?" [level=2]',
        'textbox "Policy name to confirm"',
        'button "Keep retention window"',
        'button "Prune records permanently"',
      ],
      { depth: 5 },
    );
    await testInfo.attach("retention-modal-aria-snapshot", {
      body: retentionSnapshot,
      contentType: "text/plain",
    });
    await page.keyboard.press("Escape");

    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    const dropdownTrigger = page.locator("#stress-dropdown-button");
    await dropdownTrigger.scrollIntoViewIfNeeded();
    await dropdownTrigger.click();
    await expect(dropdownTrigger).toHaveAttribute("aria-expanded", "true");
    const dropdownSnapshot = await expectAriaSnapshotContains(
      page.getByTestId("stress-preview"),
      [
        'button "Dropdown Menu" [expanded]',
        'combobox "Combobox Field"',
        'alert "There is a problem"',
        '- tablist:',
      ],
      { depth: 8 },
    );
    await testInfo.attach("stress-menu-aria-snapshot", {
      body: dropdownSnapshot,
      contentType: "text/plain",
    });
    await page.keyboard.press("Escape");

    await page.getByRole("button", { name: "Show Modal" }).click();
    const stressModalSnapshot = await expectAriaSnapshotContains(
      page.getByRole("dialog", { name: "Stress modal" }),
      [
        'dialog "Stress modal"',
        'heading "Stress modal" [level=2]',
        'button "Confirm stress modal"',
      ],
      { depth: 5 },
    );
    await testInfo.attach("stress-modal-aria-snapshot", {
      body: stressModalSnapshot,
      contentType: "text/plain",
    });
    await page.getByRole("button", { name: "Confirm stress modal" }).click();

    await page.getByRole("button", { name: "Show Drawer" }).click();
    const stressDrawerSnapshot = await expectAriaSnapshotContains(
      page.getByRole("dialog", { name: "Stress drawer" }),
      [
        'dialog "Stress drawer"',
        'heading "Stress drawer" [level=2]',
        'button "Close stress drawer"',
      ],
      { depth: 5 },
    );
    await testInfo.attach("stress-drawer-aria-snapshot", {
      body: stressDrawerSnapshot,
      contentType: "text/plain",
    });
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
