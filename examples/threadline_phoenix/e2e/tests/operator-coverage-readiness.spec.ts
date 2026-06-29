import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

const viewports = [
  { name: "phone-320", width: 320, height: 812, isMobile: true },
  { name: "phone-375", width: 375, height: 812, isMobile: true },
  { name: "tablet", width: 768, height: 900, isMobile: false },
  { name: "desktop-1024", width: 1024, height: 900, isMobile: false },
  { name: "desktop-1440", width: 1440, height: 900, isMobile: false },
];

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

async function expectBoxWithinViewport(
  locator: Locator,
  viewportWidth: number,
) {
  const edgeTolerance = 4;
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(-edgeTolerance);
  expect(rect!.x + rect!.width).toBeLessThanOrEqual(
    viewportWidth + edgeTolerance,
  );
}

async function expectKeyboardFocus(locator: Locator, page: Page, maxTabs = 30) {
  await expect(locator).toBeVisible();

  for (let step = 0; step < maxTabs; step += 1) {
    await page.keyboard.press("Tab");

    try {
      await expect(locator).toBeFocused({ timeout: 100 });
      break;
    } catch {
      if (step === maxTabs - 1) {
        await expect(locator).toBeFocused();
      }
    }
  }

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

async function openCoverage(page: Page) {
  await login(page);
  await page.goto("/audit/coverage");
  await expect(
    page.getByRole("heading", { name: "Audit coverage" }),
  ).toBeVisible();
  await expect(
    page.getByRole("region", { name: "Selected schema readiness" }),
  ).toBeVisible();
}

async function expectCommandAndCopyDoNotOverlap(action: Locator) {
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

for (const viewport of viewports) {
  test.describe(`Coverage readiness viewport: ${viewport.name}`, () => {
    test.use({
      viewport: { width: viewport.width, height: viewport.height },
      isMobile: viewport.isMobile,
    });

    test("keeps the selected-schema verdict, picker, row actions, and table readable", async ({
      page,
    }) => {
      await openCoverage(page);

      const verdict = page.getByRole("region", {
        name: "Selected schema readiness",
      });
      const schemaSelect = page.locator("#coverage-schema");
      const table = page.getByTestId("coverage-table");
      const firstUncovered = page.locator(".tl-table__row--uncovered").first();
      const firstCoveredLink = page
        .locator(".tl-table__row--covered")
        .getByRole("link", { name: "View activity" })
        .first();

      await expect(verdict).toContainText("selected schema");
      await expect(schemaSelect).toBeVisible();
      await expect(schemaSelect).toHaveAttribute("name", "schema");
      const optionValues = await schemaSelect.evaluate(
        (select: HTMLSelectElement) =>
          Array.from(select.options).map((option) => option.value),
      );
      expect(optionValues).toContain("public");
      await expect(page.getByRole("button", { name: "Refresh" })).toBeVisible();
      await expect(table).toBeVisible();
      await expect(firstUncovered.getByText("Add capture")).toBeVisible();
      await expect(firstCoveredLink).toBeVisible();

      await expectBoxWithinViewport(verdict, viewport.width);
      await expectBoxWithinViewport(schemaSelect, viewport.width);
      await expectBoxWithinViewport(table, viewport.width);
      await expectNoHorizontalOverflow(page);
    });
  });
}

test.describe("Coverage readiness keyboard and row-action proof", () => {
  test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

  test("keeps focus visible and command/copy controls separated", async ({
    page,
  }) => {
    await openCoverage(page);

    const schemaSelect = page.locator("#coverage-schema");
    const refresh = page.getByRole("button", { name: "Refresh" });
    const firstAction = page.locator(".tl-row-action").first();
    const summary = firstAction.locator(".tl-row-action__summary");

    await expectKeyboardFocus(schemaSelect, page);
    await expectKeyboardFocus(refresh, page);
    await expectKeyboardFocus(summary, page);

    await summary.press("Enter");
    await expect(firstAction).toHaveAttribute("open", "");
    await expectCommandAndCopyDoNotOverlap(firstAction);

    const copy = firstAction.locator(".tl-copy--command");
    await expectKeyboardFocus(copy, page);

    const firstCoveredLink = page
      .locator(".tl-table__row--covered")
      .getByRole("link", { name: "View activity" })
      .first();
    await firstCoveredLink.scrollIntoViewIfNeeded();
    await expectKeyboardFocus(firstCoveredLink, page, 80);
    await expectNoHorizontalOverflow(page);
  });
});

test.describe("Coverage readiness link behavior", () => {
  test("keeps public covered-row Timeline links scoped by table without table_schema", async ({
    page,
  }) => {
    await openCoverage(page);

    const firstCoveredLink = page
      .locator(".tl-table__row--covered")
      .getByRole("link", { name: "View activity" })
      .first();
    await expect(firstCoveredLink).toBeVisible();

    const href = await firstCoveredLink.getAttribute("href");
    expect(href).not.toBeNull();
    expect(href!).toContain("/audit/timeline?table=");
    expect(href!).not.toContain("table_schema=");
  });
});
