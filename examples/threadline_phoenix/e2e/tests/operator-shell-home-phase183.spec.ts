import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const expectedTheme =
  process.env.THREADLINE_E2E_THEME === "system" ? "system" : "dark";
const shellWidths = [320, 375, 768, 1024, 1280, 1440];

const destinations = [
  { label: "Overview", testId: "operator-nav-overview", path: "/audit" },
  { label: "Timeline", testId: "operator-nav-timeline", path: "/audit/timeline" },
  { label: "Coverage", testId: "operator-nav-coverage", path: "/audit/coverage" },
  { label: "Evidence", testId: "operator-nav-evidence", path: "/audit/evidence" },
  {
    label: "Redaction",
    testId: "operator-nav-policy",
    path: "/audit/policy/redaction",
  },
  {
    label: "Retention",
    testId: "operator-nav-retention",
    path: "/audit/policy/retention",
  },
  { label: "Exports", testId: "operator-nav-exports", path: "/audit/exports" },
];

const adjacentRoutes = [
  {
    path: "/audit/timeline",
    currentTestId: "operator-nav-timeline",
    heading: "Investigate audit activity",
  },
  {
    path: "/audit/coverage",
    currentTestId: "operator-nav-coverage",
    heading: "Audit coverage",
  },
  {
    path: "/audit/evidence",
    currentTestId: "operator-nav-evidence",
    heading: "Evidence",
  },
  {
    path: "/audit/policy/redaction",
    currentTestId: "operator-nav-policy",
    heading: "Redaction policy",
  },
  {
    path: "/audit/policy/retention",
    currentTestId: "operator-nav-retention",
    heading: "Retention window",
  },
  {
    path: "/audit/exports",
    currentTestId: "operator-nav-exports",
    heading: "Exports",
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

async function expectFocusCue(locator: Locator, page: Page) {
  await locator.scrollIntoViewIfNeeded();
  await locator.focus();
  await expect(locator).toBeFocused();

  const focus = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const x = rect.left + Math.min(rect.width / 2, Math.max(1, rect.width - 1));
    const y = rect.top + Math.min(rect.height / 2, Math.max(1, rect.height - 1));
    const hit = document.elementFromPoint(x, y);
    const style = window.getComputedStyle(element);

    return {
      boxShadow: style.boxShadow,
      outlineStyle: style.outlineStyle,
      outlineWidth: style.outlineWidth,
      visible:
        rect.width > 0 &&
        rect.height > 0 &&
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= window.innerHeight + 1 &&
        rect.right <= window.innerWidth + 1 &&
        !!hit &&
        (hit === element || element.contains(hit)),
    };
  });

  const hasFocusRing =
    focus.boxShadow !== "none" ||
    (focus.outlineStyle !== "none" && focus.outlineWidth !== "0px");

  expect(hasFocusRing).toBe(true);
  expect(focus.visible).toBe(true);
  await expectNoHorizontalOverflow(page);
}

async function expectMobileDisclosureNav(page: Page) {
  const shell = page.getByTestId("operator-nav-shell");
  await expect(shell).toBeVisible();
  await expect(shell).toHaveAttribute("aria-label", "Audit navigation");

  const disclosure = shell.locator(".tl-shell-nav__disclosure");
  const toggle = shell.locator(".tl-shell-nav__toggle");
  const panel = shell.locator(".tl-shell-nav__panel");

  await expect(toggle).toBeVisible();
  await expect(toggle).toHaveText("Audit navigation");
  await expect(panel).toBeHidden();

  await expectFocusCue(toggle, page);
  await page.keyboard.press("Enter");
  await expect(disclosure).toHaveAttribute("open", "");
  await expect(panel).toBeVisible();

  for (const destination of destinations) {
    const link = shell.getByTestId(destination.testId);
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute("href", destination.path);
  }

  for (const theme of ["System", "Light", "Dark"]) {
    await expect(shell.getByRole("radio", { name: theme })).toBeVisible();
  }
  await expect(shell.getByRole("button", { name: "Apply theme" })).toBeVisible();

  // Pointer activation should reopen the same native disclosure after keyboard activation.
  await toggle.click();
  await expect(panel).toBeHidden();
  await toggle.click();
  await expect(panel).toBeVisible();
  await expectFocusCue(shell.getByTestId("operator-nav-timeline"), page);
  await expectNoHorizontalOverflow(page);
}

async function expectDesktopRailNav(page: Page, heading = "Follow what happened.") {
  const shell = page.getByTestId("operator-nav-shell");
  const panel = shell.locator(".tl-shell-nav__panel");
  const toggle = shell.locator(".tl-shell-nav__toggle");

  await expect(shell).toBeVisible();
  await expect(toggle).toBeHidden();
  await expect(panel).toBeVisible();

  const shellBox = await shell.boundingBox();
  expect(shellBox).not.toBeNull();
  expect(shellBox!.width).toBeGreaterThanOrEqual(194);
  expect(shellBox!.width).toBeLessThanOrEqual(234);

  for (const destination of destinations) {
    const link = panel.getByTestId(destination.testId);
    await expect(link).toBeVisible();
    await expect(link).toHaveAttribute("href", destination.path);
  }

  const mainBox = await page.locator("#tl-main").boundingBox();
  expect(mainBox).not.toBeNull();
  expect(mainBox!.width).toBeGreaterThan(shellBox!.width);
  await expect(
    page.locator("#tl-main").getByRole("heading", {
      name: heading,
      level: 1,
      exact: true,
    }),
  ).toBeVisible();
  await expectNoHorizontalOverflow(page);
}

async function expectHomeTaskHierarchy(page: Page) {
  const main = page.locator("#tl-main");
  await expect(
    main.getByRole("heading", { name: "Follow what happened." }),
  ).toBeVisible();
  await expect(
    main.getByText(
      "Every change is connected to the action, context, and story around it. Pick where you want to start.",
    ),
  ).toBeVisible();
  await expect(main.getByRole("status", { name: "System health" })).toBeVisible();

  const timelineCard = main.locator(".tl-home__card--primary");
  await expect(timelineCard.getByRole("heading", { name: "Find what changed" })).toBeVisible();
  await expect(timelineCard.getByRole("link", { name: "Open the timeline" })).toBeVisible();

  await expect(main.getByRole("heading", { name: "Check audit readiness" })).toBeVisible();
  await expect(main.getByRole("link", { name: "Check coverage" })).toBeVisible();

  for (const action of ["Evidence", "Redaction", "Retention", "Exports"]) {
    await expect(main.getByRole("link", { name: action, exact: true })).toBeVisible();
  }

  await expect(main.locator('[data-earned-flow="EF1"]')).toBeVisible();
  await expect(main.locator('[data-earned-flow="EF4"]')).toBeVisible();
  await expect(main.getByRole("button", { name: "Open row history" })).toBeVisible();
  await expect(main.getByRole("button", { name: "Open Timeline" })).toBeVisible();
  await expect(
    main.getByRole("heading", { name: "Pick up where you left off" }),
  ).toBeVisible();
  await expect(main.getByText(/get started/i)).toHaveCount(0);
}

async function expectActiveNavNonColorCue(page: Page, currentTestId: string) {
  const shell = page.getByTestId("operator-nav-shell");
  const currentLinks = shell.locator('[aria-current="page"]');
  await expect(currentLinks).toHaveCount(1);

  const current = shell.getByTestId(currentTestId);
  await expect(current).toHaveAttribute("aria-current", "page");
  await expect(current).toBeVisible();

  const style = await current.evaluate((element) => {
    const computed = window.getComputedStyle(element);
    const borderColors = [
      computed.borderTopColor,
      computed.borderRightColor,
      computed.borderBottomColor,
      computed.borderLeftColor,
    ];

    return {
      boxShadow: computed.boxShadow,
      borderColors,
      borderWidths: [
        computed.borderTopWidth,
        computed.borderRightWidth,
        computed.borderBottomWidth,
        computed.borderLeftWidth,
      ],
      fontWeight: computed.fontWeight,
    };
  });

  const hasBoxShadow = style.boxShadow !== "none";
  const hasVisibleBorder = style.borderColors.some(
    (color, index) =>
      style.borderWidths[index] !== "0px" &&
      color !== "transparent" &&
      color !== "rgba(0, 0, 0, 0)",
  );

  expect(hasBoxShadow || hasVisibleBorder).toBe(true);
  expect(Number.parseInt(style.fontWeight, 10)).toBeGreaterThanOrEqual(600);
}

async function expectThemePickerSelected(page: Page, theme: "dark" | "system") {
  const root = page.locator(".threadline-ui").first();
  await expect(root).toHaveAttribute("data-tl-theme", theme);

  const shell = page.getByTestId("operator-nav-shell");
  const radio = shell.locator(`input[name="theme"][value="${theme}"]`);
  await expect(radio).toBeChecked();

  const selectedOption = shell.locator(`.tl-theme-picker__option:has(input[value="${theme}"])`);
  const style = await selectedOption.evaluate((element) => {
    const computed = window.getComputedStyle(element);
    return {
      boxShadow: computed.boxShadow,
      borderColor: computed.borderTopColor,
      fontWeight: computed.fontWeight,
    };
  });

  expect(style.boxShadow !== "none" || style.borderColor !== "rgba(0, 0, 0, 0)").toBe(true);
  expect(Number.parseInt(style.fontWeight, 10)).toBeGreaterThanOrEqual(500);
}

async function expectLauncherValidation(page: Page) {
  await page.goto("/audit");

  const recordLookup = page.locator("#tl-record-lookup");
  await recordLookup.getByRole("button", { name: "Open row history" }).click();
  await expectPath(page, "/audit");
  await expect(
    recordLookup.locator("xpath=following-sibling::*[@role='alert']").filter({
      hasText: "Select a table for row history.",
    }),
  ).toBeVisible();

  const correlationLookup = page.locator("#tl-correlation-lookup");
  await correlationLookup.getByRole("button", { name: "Open Timeline" }).click();
  await expectPath(page, "/audit");
  await expect(
    correlationLookup.locator("xpath=following-sibling::*[@role='alert']").filter({
      hasText: "Enter a correlation id to open the timeline.",
    }),
  ).toBeVisible();
}

async function expectPath(page: Page, path: string) {
  await expect.poll(() => new URL(page.url()).pathname).toBe(path);
}

test.describe("Phase 183 shell and Home browser perception", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  for (const width of shellWidths) {
    test(`keeps shell navigation perceivable at ${width}px`, async ({ page }) => {
      await page.setViewportSize({ width, height: 900 });
      await page.goto("/audit");
      await expectLiveViewConnected(page);

      if (width < 768) {
        await expectMobileDisclosureNav(page);
      } else {
        await expectDesktopRailNav(page);
      }

      await expectActiveNavNonColorCue(page, "operator-nav-overview");
      await expectThemePickerSelected(page, expectedTheme);
    });
  }

  test("keeps Home task hierarchy, theme, active state, and launcher validation explicit", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/audit");
    await expectLiveViewConnected(page);
    await expectHomeTaskHierarchy(page);
    await expectActiveNavNonColorCue(page, "operator-nav-overview");
    await expectThemePickerSelected(page, expectedTheme);
    await expectLauncherValidation(page);
    await expectNoHorizontalOverflow(page);
  });

  test("navigates the primary Home launchers to stable routes", async ({ page }) => {
    await page.goto("/audit");
    await page.getByRole("link", { name: "Open the timeline" }).click();
    await expectPath(page, "/audit/timeline");

    await page.goto("/audit");
    await page.getByRole("link", { name: "Check coverage" }).click();
    await expectPath(page, "/audit/coverage");
  });

  test("keeps adjacent routes constrained to shell invariants", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });

    for (const route of adjacentRoutes) {
      await test.step(route.path, async () => {
        await page.goto(route.path);
        await expectPath(page, route.path);
        await expectLiveViewConnected(page);
        await expectDesktopRailNav(page, route.heading);
        await expectActiveNavNonColorCue(page, route.currentTestId);
        await expectThemePickerSelected(page, expectedTheme);
        await expectFocusCue(page.getByTestId(route.currentTestId), page);
        await expectNoHorizontalOverflow(page);
      });
    }
  });
});
