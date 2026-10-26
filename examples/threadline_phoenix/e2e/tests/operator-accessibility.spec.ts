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

async function expectImmediateMotion(locator: Locator) {
  const style = await locator.evaluate((element) => {
    const computed = window.getComputedStyle(element);
    return {
      animationDelay: computed.animationDelay,
      animationDuration: computed.animationDuration,
      animationName: computed.animationName,
      transitionDelay: computed.transitionDelay,
      transitionDuration: computed.transitionDuration,
      transitionProperty: computed.transitionProperty,
    };
  });

  expect(style.animationName).toBe("none");
  expect(style.animationDuration.split(",").every((value) => value.trim() === "0s")).toBe(true);
  expect(style.animationDelay.split(",").every((value) => value.trim() === "0s")).toBe(true);
  expect(style.transitionProperty).toBe("none");
  expect(style.transitionDuration.split(",").every((value) => value.trim() === "0s")).toBe(true);
  expect(style.transitionDelay.split(",").every((value) => value.trim() === "0s")).toBe(true);
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
  // Overlay focus moves at open time while its entrance transition may still be
  // running. Wait for the complete control to enter the viewport before checking
  // the final hit target; a partial slide-in is not a stable accessibility state.
  await expect(locator).toBeInViewport({ ratio: 1 });
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

  for (const theme of ["Light", "Dark", "System"]) {
    test(`inspection routes retain context and reachable controls in ${theme} at 320, 768, and 1280 CSS px`, async ({ page, isMobile }) => {
      await page.emulateMedia({ colorScheme: "light" });
      await page.goto("/audit/coverage");
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      await openOperatorNav(page);
      const picker = page.getByTestId("operator-nav-group-theme");
      await picker.getByRole("radio", { name: theme, exact: true }).check();
      await picker.getByRole("button", { name: "Apply theme", exact: true }).click();

      await page.goto("/audit/evidence");
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      const seeded = page.locator(".tl-record-card").filter({ has: page.locator('code[title*="walk-retention-offboarded-co"]') });
      await expect(seeded).toHaveCount(1);
      const reference = (await seeded.locator("code[data-tl-copy]").getAttribute("data-tl-copy"))!;
      expect(JSON.parse(reference).run_id).toBe("walk-retention-offboarded-co");
      for (const width of [320, 768, 1280]) {
        await page.setViewportSize({ width, height: 900 });
        await page.goto("/audit/coverage?schema=public");
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        await expect(page.locator(".threadline-ui").first()).toHaveAttribute("data-tl-theme", theme.toLowerCase());
        await expect(page.getByRole("region", { name: "Selected schema readiness" })).toContainText("public");
        const refreshCoverage = page.getByRole("button", { name: "Refresh coverage", exact: true });
        await refreshCoverage.focus();
        await expectNonObscuredFocused(refreshCoverage, page);
        if (isMobile) await refreshCoverage.tap();
        else await page.keyboard.press("Enter");
        await expect(page.locator("#coverage-schema")).toHaveValue("public");
        await expectNoHorizontalOverflow(page);

        await page.goto(
          `/audit/evidence?subject=retention_run&subject_ref_json=${encodeURIComponent(reference)}&mode=history`,
        );
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        const scope = page.locator(".tl-evidence__workflow-summary");
        await expect(scope.locator("code[data-tl-copy]")).toHaveAttribute("data-tl-copy", reference);
        await expect(page.getByTestId("evidence-claim-boundary")).toContainText("recorded snapshot");
        await expect(page.locator(".tl-record-card").first()).toBeVisible();
        await expectNoHorizontalOverflow(page);

        await page.goto("/audit/policy/redaction?schema=public");
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        const posture = page.getByRole("region", { name: "Redaction policy posture" });
        await expect(posture).toContainText("public");
        await expect(posture).toContainText("current deployed trigger definitions only");
        const refreshPolicy = page.getByRole("button", { name: "Refresh policy inspection", exact: true });
        await refreshPolicy.focus();
        await expectNonObscuredFocused(refreshPolicy, page);
        const row = page.locator("details.tl-policy__row").filter({ has: page.getByText("posts", { exact: true }) });
        const disclosure = row.locator("summary");
        await disclosure.focus();
        await expectNonObscuredFocused(disclosure, page);
        if (isMobile) await disclosure.tap();
        else await page.keyboard.press("Enter");
        await expect(row).toHaveAttribute("open", "");
        await expect(row.getByRole("table")).toBeVisible();
        await expect(row.getByText("Deployed matches config", { exact: true })).toBeVisible();
        await expectNoHorizontalOverflow(page);
      }
    });
  }
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
        .getByRole("button", { name: "Open the timeline" }),
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
    // 197-02 (commit 842bd737) intentionally dropped the verdict's
    // self-labeling "selected schema: … · Checked …" meta line — the verdict
    // heading itself still names the schema (coverage_live.ex
    // verdict_heading/2). This test navigates to /audit/coverage with no
    // `schema` param, so it defaults to "public" (coverage_live.ex:49).
    await expect(readiness).toContainText("public");

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

  test("keeps System selection while served colors follow OS through investigation navigation", async ({
    page,
  }) => {
    await page.goto("/audit");

    const themeGroup = page.getByTestId("operator-nav-group-theme");
    await openOperatorNav(page);
    const system = themeGroup.getByRole("radio", { name: "System" });
    if (process.env.THREADLINE_E2E_THEME === "system") {
      await expect(system).toBeChecked();
      await expect(page.locator(".threadline-ui")).toHaveAttribute(
        "data-tl-theme",
        "system",
      );
    }
    await system.check();
    await themeGroup.getByRole("button", { name: "Apply theme" }).click();
    await expect(page.locator(".threadline-ui")).toHaveAttribute(
      "data-tl-theme",
      "system",
    );

    const appearance = async () =>
      page.locator(".threadline-ui").evaluate((root) => {
        const card = root.querySelector(".tl-home__card");
        if (!(card instanceof HTMLElement)) throw new Error("Home card missing");
        const rootStyle = getComputedStyle(root);
        const cardStyle = getComputedStyle(card);
        return {
          background: rootStyle.backgroundColor,
          foreground: rootStyle.color,
          border: cardStyle.borderTopColor,
        };
      });

    await page.emulateMedia({ colorScheme: "light" });
    const systemLight = await appearance();
    expect(systemLight.background).toBe("rgb(247, 249, 252)");
    expect(systemLight.foreground).toBe("rgb(15, 23, 40)");
    expect(systemLight.border).toBe("rgb(167, 180, 200)");

    await page.emulateMedia({ colorScheme: "dark" });
    const systemDark = await appearance();
    expect(systemDark.background).toBe("rgb(11, 16, 32)");
    expect(systemDark.foreground).not.toBe(systemLight.foreground);
    expect(systemDark.border).not.toBe(systemLight.border);
    await expect(page.locator('input[name="theme"]:checked')).toHaveValue(
      "system",
    );

    await page.getByRole("link", { name: "Open the timeline" }).click();
    await expect(page.locator(".threadline-ui")).toHaveAttribute(
      "data-tl-theme",
      "system",
    );
    await expect(page.locator('input[name="theme"]:checked')).toHaveValue(
      "system",
    );
    const { transactionHref } = await discoverTransactionAndRowHistory(page);
    await page.goto(transactionHref);
    await expect(page.locator(".threadline-ui")).toHaveAttribute(
      "data-tl-theme",
      "system",
    );
    await page.reload();
    await expect(page.locator(".threadline-ui")).toHaveAttribute(
      "data-tl-theme",
      "system",
    );
    await expect(page.locator('input[name="theme"]:checked')).toHaveValue(
      "system",
    );

    for (const theme of ["light", "dark"]) {
      await openOperatorNav(page);
      const group = page.getByTestId("operator-nav-group-theme");
      await group.getByRole("radio", { name: new RegExp(theme, "i") }).check();
      await group.getByRole("button", { name: "Apply theme" }).click();
      await expect(page.locator(".threadline-ui")).toHaveAttribute(
        "data-tl-theme",
        theme,
      );
      await page.reload();
      await expect(page.locator(".threadline-ui")).toHaveAttribute(
        "data-tl-theme",
        theme,
      );
      await expect(page.locator('input[name="theme"]:checked')).toHaveValue(
        theme,
      );
    }
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
      .getByRole("button", { name: "Prune now" })
      .last();
    await expect(prune).toBeVisible();
    await prune.focus();
    await expectNonObscuredFocused(prune, page);
    await prune.click();
    const pruneModal = page.locator("#prune-confirm");
    const pruneDialog = page.getByRole("dialog", {
      name: "Prune retained audit data?",
    });
    await expect(pruneModal).toBeVisible();
    await expect(pruneDialog).toBeVisible();
    await expect(pruneDialog).toHaveAttribute("aria-modal", "true");
    await expect(pruneDialog).toHaveAttribute(
      "aria-describedby",
      "prune-confirm-description",
    );
    await expect(pruneModal).toContainText(
      "This prune applies the configured retention policy globally to the configured Threadline storage schema",
    );
    await expect(pruneModal).toContainText(
      "removes AuditChange rows strictly older than the policy cutoff",
    );
    await expect(
      pruneModal.getByText("Type the policy name “default” to confirm"),
    ).toBeVisible();
    await expect(
      pruneModal.getByRole("button", { name: "Keep audit data" }),
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
      // Anchored to the canonical rendered literal (export_status_live.ex:489,
      // "Export expired") — plan 198-25 fixed the "Expired" -> "Export expired"
      // product copy, which this partial-capital-E regex no longer matched.
      exportJobs.getByText(/Export expired|File unavailable/).first(),
    ).toBeVisible();

    await expectNoHorizontalOverflow(page);
  });

  test("keeps export and retention journeys readable across themes, widths, and a live reconnect", async ({ page }) => {
    let blockReconnect = false;
    await page.routeWebSocket(/\/live\/websocket/, (socket) => {
      if (blockReconnect) socket.close();
      else socket.connectToServer();
    });

    for (const theme of ["Light", "Dark", "System"] as const) {
      await page.goto("/audit");
      await openOperatorNav(page);
      const themeGroup = page.getByTestId("operator-nav-group-theme");
      const themeRadio = themeGroup.getByRole("radio", { name: theme, exact: true });
      if (!(await themeRadio.isChecked())) await themeRadio.check();
      await themeGroup.getByRole("button", { name: "Apply theme", exact: true }).click();
      await expect(page.locator(".threadline-ui").first()).toHaveAttribute("data-tl-theme", theme.toLowerCase());

      const longCorrelation = `retention-export-filter-${"x".repeat(80)}`;
      await page.goto(`/audit/exports?table=${rowTable}&correlation_id=${encodeURIComponent(longCorrelation)}`);
      const root = page.locator("[data-phx-main]");
      await expect(root).toHaveClass(/phx-connected/);
      const exportContext = page.getByTestId("timeline-export-context");
      await expect(exportContext).toContainText(longCorrelation);
      await expect(page.getByTestId("export-jobs")).toBeVisible();
      const queue = page.getByRole("button", { name: "Queue Timeline export", exact: true });
      for (const width of [320, 375, 768, 1280]) {
        await page.setViewportSize({ width, height: 900 });
        await expect(page.locator(".threadline-ui").first()).toHaveAttribute("data-tl-theme", theme.toLowerCase());
        await expect(exportContext).toContainText(longCorrelation);
        const target = await queue.boundingBox();
        expect(target, `Queue target exists at ${width}px`).toBeTruthy();
        expect(target!.width, `Queue target width at ${width}px`).toBeGreaterThanOrEqual(40);
        expect(target!.height, `Queue target height at ${width}px`).toBeGreaterThanOrEqual(40);
        await expectNoHorizontalOverflow(page);
      }

      if (theme === "System") {
        await page.setViewportSize({ width: 320, height: 900 });
        const main = page.locator("#tl-main");
        await main.focus();
        blockReconnect = true;
        await page.evaluate(() => (window as any).liveSocket.disconnect());
        await expect(root).toHaveClass(/phx-loading/);
        const banner = page.locator(".tl-reconnect-banner");
        await expect(banner).toBeVisible();
        await expect(banner).toHaveAttribute("role", "status");
        await expect(banner.locator(".tl-reconnect-banner__reconnecting")).toHaveText(
          "Reconnecting. Actions will remain unavailable until current status is refreshed.",
        );
        await expect(queue).toBeDisabled();
        await expect(main).toBeVisible();
        await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("tl-main");
        const bannerLayout = await banner.evaluate((element) => ({
          clientWidth: element.clientWidth,
          scrollWidth: element.scrollWidth,
          viewportWidth: window.innerWidth,
        }));
        expect(bannerLayout.scrollWidth).toBeLessThanOrEqual(bannerLayout.clientWidth + 1);
        expect(bannerLayout.clientWidth).toBeLessThanOrEqual(bannerLayout.viewportWidth);
        await expectNoHorizontalOverflow(page);
        blockReconnect = false;
        await page.evaluate(() => (window as any).liveSocket.connect());
        await expect(root).toHaveClass(/phx-connected/);
        await expect(banner).toBeHidden();
      }

      await page.goto("/audit/policy/retention");
      await expect(root).toHaveClass(/phx-connected/);
      const history = page.locator("#retention-runs");
      await expect(history).toBeVisible();
      await expect(history).toContainText(/Completed|Queued|No retention runs/);
      const prune = page.getByRole("button", { name: "Prune now", exact: true }).first();
      for (const width of [320, 375, 768, 1280]) {
        await page.setViewportSize({ width, height: 900 });
        await expect(page.locator(".threadline-ui").first()).toHaveAttribute("data-tl-theme", theme.toLowerCase());
        const target = await prune.boundingBox();
        expect(target, `Prune target exists at ${width}px`).toBeTruthy();
        expect(target!.width, `Prune target width at ${width}px`).toBeGreaterThanOrEqual(40);
        expect(target!.height, `Prune target height at ${width}px`).toBeGreaterThanOrEqual(40);
        await expectNoHorizontalOverflow(page);
      }

      await page.setViewportSize({ width: 320, height: 440 });
      await prune.focus();
      await page.keyboard.press("Enter");
      const modal = page.locator("#prune-confirm");
      const dialog = page.getByRole("dialog", { name: "Prune retained audit data?" });
      await expect(dialog).toBeVisible();
      await expect(dialog).toContainText("This prune applies the configured retention policy globally");
      await expect(dialog.getByRole("textbox", { name: "Policy name to confirm" })).toBeFocused();
      const keepData = dialog.getByRole("button", { name: "Keep audit data", exact: true });
      await keepData.scrollIntoViewIfNeeded();
      await expect(keepData).toBeInViewport({ ratio: 1 });
      await expectNoHorizontalOverflow(page);
      await keepData.focus();
      await page.keyboard.press("Enter");
      await expect(modal).toBeHidden();
      await expect(prune).toBeFocused();
    }
  });

  test("keeps row-history drawer dialog semantics and visible focus", async ({
    page,
  }, testInfo) => {
    const rowHistoryRedControl =
      process.env.THREADLINE_ROW_HISTORY_RED_CONTROL;

    if (
      rowHistoryRedControl !== undefined &&
      rowHistoryRedControl !== "" &&
      rowHistoryRedControl !== "obscure-date-input"
    ) {
      throw new Error(`unknown row-history red control: ${rowHistoryRedControl}`);
    }

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

    const expectedHistoryUrl = new URL(rowHistoryHref, page.url());
    await page.keyboard.press("Enter");
    await expect(page).toHaveURL(expectedHistoryUrl.toString());
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
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
    await expect(close).toBeFocused();
    await expectImmediateMotion(dialog.locator(".tl-row-history-drawer"));
    await expectImmediateMotion(dialog.locator(".tl-subview__timeline li").first());

    const snapshot = dialog.getByLabel("View snapshot at");
    await expect(snapshot).toBeVisible();
    await snapshot.focus();

    for (const value of ["2026-10-10T10:00", "2026-10-10T10:05"]) {
      await snapshot.fill(value);
      await expect
        .poll(() => new URL(page.url()).searchParams.get("as_of"))
        .toBe(`${value}:00Z`);
      await expect(snapshot).toBeFocused();
      await expectImmediateMotion(dialog.locator(".tl-row-history-drawer"));
      await expectImmediateMotion(dialog.locator(".tl-subview__timeline li").first());
    }

    if (rowHistoryRedControl === "obscure-date-input") {
      await snapshot.evaluate((element) => {
        const rect = element.getBoundingClientRect();
        const obscurer = document.createElement("div");
        obscurer.setAttribute("data-threadline-row-history-red-control", "");
        Object.assign(obscurer.style, {
          background: "transparent",
          height: `${rect.height}px`,
          left: `${rect.left}px`,
          position: "fixed",
          top: `${rect.top}px`,
          width: `${rect.width}px`,
          zIndex: "2147483647",
        });
        document.body.appendChild(obscurer);
      });
    }

    try {
      const geometry = await snapshot.evaluate((input) => {
        const active = document.activeElement;
        const dialogElement = input.closest('[role="dialog"]');
        const rect = (element: Element | null) => {
          if (!element) return null;
          const bounds = element.getBoundingClientRect();

          return {
            bottom: bounds.bottom,
            height: bounds.height,
            left: bounds.left,
            right: bounds.right,
            top: bounds.top,
            width: bounds.width,
          };
        };

        const inputRect = input.getBoundingClientRect();
        const style = window.getComputedStyle(input);

        return {
          activeElement: active
            ? {
                ariaLabel: active.getAttribute("aria-label"),
                id: active.id || null,
                name: active.getAttribute("name"),
                role: active.getAttribute("role"),
                tag: active.tagName,
                testId: active.getAttribute("data-testid"),
                type: active.getAttribute("type"),
              }
            : null,
          dialogRect: rect(dialogElement),
          dialogScroll: dialogElement
            ? { left: dialogElement.scrollLeft, top: dialogElement.scrollTop }
            : null,
          documentScroll: { left: window.scrollX, top: window.scrollY },
          inputRect: rect(input),
          visible:
            inputRect.width > 0 &&
            inputRect.height > 0 &&
            style.display !== "none" &&
            style.visibility !== "hidden",
          windowViewport: {
            height: window.innerHeight,
            width: window.innerWidth,
          },
        };
      });

      const focusEvidence = {
        ...geometry,
        attempt: {
          repeatEachIndex: testInfo.repeatEachIndex,
          retry: testInfo.retry,
          workerIndex: testInfo.workerIndex,
        },
        project: testInfo.project.name,
        trace: {
          outputDirectory: testInfo.outputDir.split(/[\\/]/).pop(),
          setting: "retain-on-failure",
        },
        viewport: page.viewportSize(),
      };

      await testInfo.attach("row-history-focus-geometry", {
        body: Buffer.from(JSON.stringify(focusEvidence, null, 2)),
        contentType: "application/json",
      });

      await expectNonObscuredFocused(snapshot, page);
      await expectNoHorizontalOverflow(page);
    } finally {
      const redControl = page.locator(
        "[data-threadline-row-history-red-control]",
      );
      await redControl.evaluateAll((elements) =>
        elements.forEach((element) => element.remove()),
      );
      await expect(redControl).toHaveCount(0);
    }

    await page.keyboard.press("Escape");
    await expect(page).toHaveURL(transactionHref);
    await expect(dialog).toBeHidden();
    await expectNonObscuredFocused(rowHistoryLink, page);
  });

  test("opens stress rendered widgets with names, keyboard state, and focus entry", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
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

    // The fixture intentionally includes a persistent toast. Dismiss it before
    // checking that the drawer trigger is visible, focused, and not obscured on
    // the mobile viewport.
    const toast = page.locator("#stress-toast");
    if (await toast.isVisible()) {
      const closeToast = toast.getByRole("button", { name: "Close" });
      await closeToast.focus();
      await page.keyboard.press("Enter");
      await expect(toast).toBeHidden();
    }

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

  test("keeps drawer focus stable while the toast is layered above it", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(page.getByTestId("stress-preview")).toBeVisible();

    const toast = page.locator("#stress-toast");
    const toastClose = toast.getByRole("button", { name: "Close" });
    await expect(toast).toBeVisible();
    await expect(toastClose).toBeVisible();

    const drawerTrigger = page.getByRole("button", { name: "Show Drawer" });
    await focusByKeyboard(page, drawerTrigger);
    await page.keyboard.press("Enter");
    const drawer = page.getByRole("dialog", { name: "Stress drawer" });
    const drawerClose = drawer.getByRole("button", { name: "Close stress drawer" });
    await expect(drawer).toBeVisible();
    await expect(drawerClose).toBeFocused();
    await expectNonObscuredFocused(drawerClose, page);

    // The toast has the higher stacking order and must receive this real pointer
    // activation without dismissing the drawer underneath it.
    await toastClose.click();
    await expect(toast).toBeHidden();
    await expect(drawer).toBeVisible();
    await expect(drawerClose).toBeFocused();
    await page.keyboard.press("Escape");
    await expect(drawer).toBeHidden();
    await expect(drawerTrigger).toBeFocused();
    await expect(drawerTrigger).toBeVisible();

  });

  test("preserves modal and drawer Escape focus through repeated LiveView patches", async ({ page }) => {
    const errors: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    await page.goto("/audit/__stress?category=group&story=group.modal-destructive.current");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const liveId = await page.locator("[data-phx-main]").getAttribute("id");
    await page.evaluate(() => { (window as any).__tl239PatchMarker = "same-document"; });
    await page.locator("#stress-toast").getByRole("button", { name: "Close" }).click();
    for (let iteration = 0; iteration < 3; iteration++) {
      const story = page.getByTestId("stress-story-list").getByRole("link").nth(iteration % 2);
      const target = await story.getAttribute("href");
      await story.click();
      await expect(page).toHaveURL(new URL(target!, page.url()).href);
      await expect(page.locator("[data-phx-main]")).toHaveAttribute("id", liveId!);
      expect(await page.evaluate(() => (window as any).__tl239PatchMarker)).toBe("same-document");
      for (const kind of ["Modal", "Drawer"]) {
        const trigger = page.getByRole("button", { name: `Show ${kind}`, exact: true });
        await focusByKeyboard(page, trigger, 160);
        await page.keyboard.press("Enter");
        const dialog = page.getByRole("dialog", { name: `Stress ${kind.toLowerCase()}`, exact: true });
        await expect(dialog).toBeVisible();
        await expect(dialog.locator("[data-tl-initial-focus]")).toBeFocused();
        await page.keyboard.press("Tab");
        await expect(dialog.locator("[data-tl-initial-focus]")).toBeFocused();
        await page.keyboard.press("Escape");
        await expect(dialog).toBeHidden();
        await expect(trigger).toBeFocused();
      }
    }
    expect(errors).toEqual([]);
  });

  test("closes the focused menu before its drawer and recovers from removed or disabled controls", async ({ page }) => {
    const errors: string[] = [];
    page.on("pageerror", (error) => errors.push(error.message));
    for (const [state, action] of [["empty", "Remove dialog controls"], ["disabled", "Disable dialog controls"], ["removed", "Remove opener"]]) {
      await page.goto("/audit/__stress?story=group.modal-destructive.current");
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      const rootId = await page.locator("[data-phx-main]").getAttribute("id");
      const opener = page.getByRole("button", { name: "Open overlay edge cases", exact: true });
      await focusByKeyboard(page, opener);
      await page.keyboard.press("Enter");
      const drawer = page.getByRole("dialog", { name: "Overlay edge cases", exact: true });
      await expect(drawer).toBeVisible();
      const toast = page.locator("#stress-toast");
      const toastClose = toast.getByRole("button", { name: "Close" });
      await expect(toast).toHaveClass(/tl-overlay-visible/);
      // show_drawer's JS.focus chain lands on [data-tl-initial-focus] asynchronously;
      // wait for it, or it can steal focus back from the toast after the focus() below.
      await expect(drawer.locator("[data-tl-initial-focus]")).toBeFocused();
      await toastClose.focus();
      await expect(toastClose).toBeFocused();
      await page.keyboard.press("Escape");
      await expect(toast).toBeHidden();
      await expect(drawer).toBeVisible();
      await expect(drawer.locator("[data-tl-initial-focus]")).toBeFocused();
      const menuButton = drawer.getByRole("button", { name: "Drawer actions" });
      await menuButton.click();
      await expect(drawer.getByRole("menuitem", { name: "Inspect evidence" })).toBeFocused();
      await page.keyboard.press("Escape");
      await expect(drawer.getByRole("menu")).toBeHidden();
      await expect(drawer).toBeVisible();
      await expect(menuButton).toBeFocused();
      await drawer.getByRole("button", { name: action, exact: true }).click();
      await expect(page.locator("#stress-edge-state")).toHaveText(state);
      await expect(page.locator("[data-phx-main]")).toHaveAttribute("id", rootId!);
      await expect(page.locator("#stress-edge-content")).toBeFocused();
      await page.keyboard.press("Escape");
      await expect(drawer).toBeHidden();
      await expect(state === "removed" ? page.locator("#tl-main") : opener).toBeFocused();
      if (state !== "removed") {
        await page.keyboard.press("Enter");
        await expect(page.locator("#stress-edge-content")).toBeFocused();
        await page.keyboard.press("Tab");
        await expect(page.locator("#stress-edge-content")).toBeFocused();
        await page.keyboard.press("Escape");
        await expect(drawer).toBeHidden();
        await expect(opener).toBeFocused();
      }
    }
    expect(errors).toEqual([]);
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
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
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
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await page.getByRole("button", { name: "Prune now" }).last().click();
    const retentionSnapshot = await expectAriaSnapshotContains(
      page.getByRole("dialog", { name: "Prune retained audit data?" }),
      [
        'dialog "Prune retained audit data?"',
        'heading "Prune retained audit data?" [level=2]',
        'textbox "Policy name to confirm"',
        'button "Keep audit data"',
        'button "Prune now"',
      ],
      { depth: 5 },
    );
    await testInfo.attach("retention-modal-aria-snapshot", {
      body: retentionSnapshot,
      contentType: "text/plain",
    });
    await page.keyboard.press("Escape");

    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
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

    // The fixture includes a persistent toast that overlaps this trigger on
    // narrow screens. Dismiss it through its keyboard-accessible control first.
    const toast = page.locator("#stress-toast");
    if (await toast.isVisible()) {
      const closeToast = toast.getByRole("button", { name: "Close" });
      await closeToast.focus();
      await page.keyboard.press("Enter");
      await expect(toast).toBeHidden();
    }

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
