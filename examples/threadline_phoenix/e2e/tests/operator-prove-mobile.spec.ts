import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

test.use({ viewport: { width: 375, height: 812 }, isMobile: true });

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

async function box(locator: Locator) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  return rect!;
}

test.describe("operator evidence and exports mobile UAT", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("exports dense state keeps readiness hierarchy and ready-only primary action", async ({
    page,
  }) => {
    await page.goto("/audit/exports");
    await expect(page.getByRole("heading", { name: "Exports" })).toBeVisible();

    const exportJobs = page.getByTestId("export-jobs");
    for (const heading of ["Ready to hand off", "Preparing", "Needs attention", "Unavailable"]) {
      await expect(exportJobs.getByRole("heading", { name: heading, exact: true })).toBeVisible();
    }

    const readyGroup = page.locator(".tl-job-group", { hasText: "Ready to hand off" });
    await expect(readyGroup.getByRole("link", { name: "Download export" })).toBeVisible();

    for (const groupName of ["Preparing", "Needs attention", "Unavailable"]) {
      const group = page.locator(".tl-job-group", { hasText: groupName });
      await expect(group.getByRole("link", { name: "Download export" })).toHaveCount(0);
    }

    await expect(page.getByText(/Queued|Processing/).first()).toBeVisible();
    await expect(page.getByText("Export failed.").first()).toBeVisible();
    await expect(page.getByRole("link", { name: "Reopen source search" }).first()).toBeVisible();
    await expect(page.getByText(/Expired|File unavailable/).first()).toBeVisible();

    const secondaryRefs = page.locator(".tl-secondary-ref");
    await expect(secondaryRefs.first()).toBeVisible();
    await expect(secondaryRefs.first()).toHaveAttribute("title", /.+/);

    const refBox = await box(secondaryRefs.first());
    expect(refBox.width).toBeLessThanOrEqual(350);
    await expectNoHorizontalOverflow(page);
  });

  test("retention dense state keeps context before destructive prune and targetable failures", async ({
    page,
  }) => {
    await page.goto("/audit/policy/retention");
    await expect(page.getByRole("heading", { name: "Retention window" })).toBeVisible();

    const summary = await box(page.locator(".tl-summary-grid"));
    const prune = await box(page.getByRole("button", { name: "Run retention prune" }).last());
    expect(summary.y).toBeLessThan(prune.y);

    const pruneButton = page.getByRole("button", { name: "Run retention prune" }).last();
    await expect(pruneButton).toHaveClass(/tl-button--secondary/);
    await expect(pruneButton).toHaveClass(/tl-button--danger/);
    await expect(pruneButton).not.toHaveAttribute("data-confirm", /./);
    await pruneButton.click();
    const modal = page.locator("#prune-confirm");
    await expect(
      modal.getByRole("heading", { name: "Prune retention window permanently?" }),
    ).toBeVisible();
    await expect(
      modal.getByText("older than the retention window for policy"),
    ).toBeVisible();
    await expect(
      modal.getByRole("button", { name: "Prune records permanently" }),
    ).toBeVisible();
    await expect(
      modal.getByText("Type the policy name default to confirm"),
    ).toBeVisible();
    await modal.getByRole("button", { name: "Keep retention window" }).click();

    const failureMetric = page.locator(".tl-card--metric", { hasText: "Failures" });
    const failureLink = failureMetric.getByRole("link");
    await expect(failureLink).toBeVisible();
    const href = await failureLink.getAttribute("href");
    expect(href).toMatch(/^#runs-/);

    const failedRow = page.locator(href!);
    await expect(failedRow).toBeVisible();
    await expect(failedRow).toContainText("Failed");

    const chip = failedRow.locator(".tl-chip").first();
    const chipBox = await box(chip);
    const rowBox = await box(failedRow);
    expect(chipBox.width).toBeLessThan(rowBox.width);
    await expect(page.getByText("No rows deleted").first()).toBeVisible();
    await expect(page.getByText("No duration yet").first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("evidence and redaction dense states keep evidence/status owners readable", async ({ page }) => {
    await page.goto("/audit/evidence");
    await expect(page.getByRole("heading", { name: "Evidence", exact: true })).toBeVisible();
    // Density (196-06): the latest-mode lede prose was removed; the "Latest projection"
    // Mode chip in the Evidence scope card is the stable projection-semantics anchor.
    await expect(page.getByText("Latest projection").first()).toBeVisible();

    const firstEvidenceCard = page.locator(".tl-record-card").first();
    const verdict = await box(firstEvidenceCard.locator(".tl-chip").first());
    const ref = await box(firstEvidenceCard.locator(".tl-secondary-ref").first());
    expect(verdict.y).toBeLessThanOrEqual(ref.y);

    const history = await box(firstEvidenceCard.getByRole("link", { name: "Open proof history" }));
    const firstSupport = firstEvidenceCard.getByRole("link").nth(1);
    if ((await firstSupport.count()) > 0) {
      const support = await box(firstSupport);
      expect(history.x).toBeLessThanOrEqual(support.x);
      expect(history.y).toBeLessThanOrEqual(support.y + 2);
    }

    await expectNoHorizontalOverflow(page);

    await page.goto("/audit/policy/redaction");
    await expect(page.getByRole("heading", { name: "Redaction policy", exact: true })).toBeVisible();
    await expect(page.getByText("Redaction drift detected").first()).toBeVisible();
    await expect(page.getByTestId("policy-section").first()).toBeVisible();
    await expect(page.locator("details.tl-policy__row").first()).toBeVisible();

    const redactionChip = page.locator("details.tl-policy__row .tl-chip").first();
    const redactionChipBox = await box(redactionChip);
    expect(redactionChipBox.width).toBeLessThanOrEqual(220);
    await expectNoHorizontalOverflow(page);
  });
});
