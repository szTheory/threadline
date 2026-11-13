import { expect, Locator, Page, test } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { installControlledClipboard } from "../support/operator-browser-evidence.js";

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
      const table = page.getByRole("table", { name: "Coverage for schema public" });
      const firstUncovered = page.locator(".tl-table__row--uncovered").first();
      const firstCoveredLink = page
        .locator(".tl-table__row--covered")
        .getByRole("link", { name: "View activity" })
        .first();

      // 197-02 (commit 842bd737) intentionally dropped the verdict's
      // self-labeling "selected schema: … · Checked …" meta line — the
      // section is already marked by its aria-label, and the verdict
      // heading itself still names the schema (coverage_live.ex
      // verdict_heading/2). openCoverage() navigates to /audit/coverage with
      // no `schema` param, so the schema defaults to "public"
      // (coverage_live.ex:49) — assert that, not the retired copy.
      await expect(verdict).toContainText("public");
      await expect(schemaSelect).toBeVisible();
      await expect(schemaSelect).toHaveAttribute("name", "schema");
      const optionValues = await schemaSelect.evaluate(
        (select: HTMLSelectElement) =>
          Array.from(select.options).map((option) => option.value),
      );
      expect(optionValues).toContain("public");
      await expect(
        page.getByRole("button", { name: "Refresh coverage" }),
      ).toBeVisible();
      await expect(table).toBeVisible();
      await expect(firstUncovered.getByText("Add capture")).toBeVisible();
      await expect(firstCoveredLink).toBeVisible();

      const uncoveredTable = (
        await firstUncovered.locator('td[data-label="TABLE"] code').textContent()
      )?.trim();
      expect(uncoveredTable).toBeTruthy();
      await firstUncovered.locator(".tl-row-action__summary").click();
      const command = firstUncovered.locator(".tl-remediation__command");
      await expect(command).toHaveText(
        `mix threadline.gen.triggers --tables public.${uncoveredTable}`,
      );
      await expect(
        firstUncovered.getByRole("button", {
          name: `Copy public.${uncoveredTable} capture command`,
        }),
      ).toHaveAttribute(
        "data-tl-copy",
        `mix threadline.gen.triggers --tables public.${uncoveredTable}`,
      );
      await expect(firstUncovered).toContainText(
        "Run mix threadline.verify_coverage --schema=public after applying the migration.",
      );

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
    const refresh = page.getByRole("button", { name: "Refresh coverage" });
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


async function withPhase251CoverageFixture(page: Page, run: (fixture: { selected: string; empty: string; sql: (statement: string) => string }) => Promise<void>) {
  const partition = process.env.MIX_TEST_PARTITION ?? "";
  expect(partition).toMatch(/^(?:\d+|p251pair)?$/);
  expect(process.env.THREADLINE_E2E).toBe("1");
  if (partition === "p251pair") {
    expect(new URL(page.url()).origin).toBe("http://127.0.0.1:60152");
    expect(process.env.DB_HOST).toBe("127.0.0.1");
    expect(process.env.DB_PORT).toBe("60025");
  }
  const suffix = randomUUID().replaceAll("-", "").slice(0, 12);
  const selected = `phase251_cov_${suffix}`;
  const empty = `phase251_empty_${suffix}`;
  const sql = (statement: string) => execFileSync("psql", ["-X", "-h", process.env.DB_HOST ?? "localhost", "-p", process.env.DB_PORT ?? "5432", "-U", "postgres", "-d", `threadline_phoenix_test${partition}`, "-v", "ON_ERROR_STOP=1", "--single-transaction", "-At", "-c", statement], { env: { ...process.env, PGPASSWORD: process.env.PGPASSWORD ?? "postgres" }, encoding: "utf8" });
  sql(`CREATE SCHEMA ${selected}; CREATE TABLE ${selected}.invoices (id integer PRIMARY KEY); CREATE TABLE ${selected}.schema_migrations (version bigint PRIMARY KEY); CREATE SCHEMA ${empty}`);
  try { await run({ selected, empty, sql }); }
  finally { sql(`DROP SCHEMA ${selected} CASCADE; DROP SCHEMA ${empty} CASCADE`); }
}


test("Phase251 Coverage selected snapshot", async ({ page }) => {
  await installControlledClipboard(page);
  await login(page);
  await withPhase251CoverageFixture(page, async ({ selected, empty, sql }) => {
    await page.goto(`/audit/coverage?schema=${selected}`);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const status = page.getByTestId("coverage-status");
    await expect(status).toContainText(`${selected}: 1 not audited`);
    await expect(status).toHaveAttribute("href", `/audit/coverage?schema=${selected}`);
    await expect(page.locator("tr.tl-table__row--uncovered")).toContainText("Not audited");
    await expect(page.locator("tr.tl-table__row--expected")).toContainText("Expected gap");
    sql(`CREATE TABLE ${selected}.payments (id integer PRIMARY KEY)`);
    await page.getByRole("button", { name: "Refresh coverage", exact: true }).click();
    await expect(status).toContainText(`${selected}: 2 not audited`);
    expect(await page.locator("tr.tl-table__row--uncovered td[data-label=TABLE]").allTextContents()).toEqual(["invoices", "payments"]);
    await page.reload();
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(status).toContainText(`${selected}: 2 not audited`);
    await expect(page.locator('#coverage-schema option[value="public"]')).toHaveCount(1);
    await page.locator("#coverage-schema").selectOption("public");
    await page.getByRole("button", { name: "Apply schema", exact: true }).click();
    await expect.poll(() => new URL(page.url()).searchParams.get("schema")).toBe("public");
    await expect(status).toContainText("public:");
    await page.goto(`/audit/coverage?schema=${empty}`);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(status).toContainText(`${empty}: 0 audited`);
    await expect(page.getByText(`No tables found in schema ${empty} during this inspection. Other schemas were not inspected.`, { exact: true })).toBeVisible();
    await expect(page.getByText("All tables captured", { exact: true })).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
    expect(await page.evaluate(() => (window as any).__phase251CopyCounter.count)).toBe(0);
  });
});
