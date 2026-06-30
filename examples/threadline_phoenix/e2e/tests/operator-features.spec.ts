import { test, expect, Page } from "@playwright/test";

// Deterministic DOM assertions for the pass-3 operator-surface features. No
// pixel diffs — every new behavior is locked by a state assertion so CI gates
// it with zero human review. Runs against the deterministic demo seed.

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const supportEmail = "support@acme.example.com";
const correlation = "walk-acme-4521-close";

async function login(page: Page, email = adminEmail) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

test.describe("operator surface — pass-3 features", () => {
  test("home login link and credentials behave without a redirect loop", async ({
    page,
    context,
  }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.goto("/", { waitUntil: "domcontentloaded" });

    const panel = page.locator(".rd-hero__panel");
    const status = panel.locator("[data-demo-copy-status]");
    await expect(panel.getByRole("button", { name: "Copy email" })).toHaveCount(
      0,
    );
    await expect(
      panel.getByRole("button", { name: "Copy password" }),
    ).toHaveCount(0);
    const email = panel.locator(`[data-demo-copy="${adminEmail}"]`).first();
    await expect(email).toBeVisible();
    await email.click();
    await expect(status).toHaveText("Copied email");
    await expect(status).toHaveClass(/is-visible/);
    await expect
      .poll(() => page.evaluate(() => navigator.clipboard.readText()))
      .toBe(adminEmail);

    const passwordCopy = panel
      .locator(`[data-demo-copy="${password}"]`)
      .first();
    await expect(passwordCopy).toBeVisible();
    await passwordCopy.press("Enter");
    await expect(status).toHaveText("Copied password");
    await expect
      .poll(() => page.evaluate(() => navigator.clipboard.readText()))
      .toBe(password);

    await page
      .getByRole("link", { name: /^Log in$/ })
      .first()
      .click();
    await expect(page).toHaveURL("/users/log_in");
    await expect(
      page.getByRole("heading", { name: "Log in to the support ops demo" }),
    ).toBeVisible();
  });

  test("demo login credentials copy independently with visible feedback", async ({
    page,
    context,
  }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
    await expect(page.getByRole("button", { name: "Copy email" })).toHaveCount(
      0,
    );
    await expect(
      page.getByRole("button", { name: "Copy password" }),
    ).toHaveCount(0);

    const email = page.locator('[data-demo-copy="admin@example.com"]').first();
    await expect(email).toBeVisible();
    await email.click();
    await expect(page.locator("[data-demo-copy-status]")).toHaveText(
      "Copied email",
    );
    await expect
      .poll(() => page.evaluate(() => navigator.clipboard.readText()))
      .toBe(adminEmail);

    const passwordCopy = page
      .locator('[data-demo-copy="password123456"]')
      .first();
    await expect(passwordCopy).toBeVisible();
    await passwordCopy.press("Enter");
    await expect(page.locator("[data-demo-copy-status]")).toHaveText(
      "Copied password",
    );
    await expect
      .poll(() => page.evaluate(() => navigator.clipboard.readText()))
      .toBe(password);
  });

  test("authenticated home topbar does not expose the login link", async ({
    page,
  }) => {
    await login(page);

    const nav = page.getByRole("navigation", { name: "RelayDesk demo" });
    await expect(nav.getByText("Signed in as")).toBeVisible();
    await expect(nav.getByText(adminEmail)).toBeVisible();
    await expect(
      nav.getByRole("link", { name: "Open Threadline admin" }),
    ).toHaveCount(0);
    await expect(
      page.locator(".rd-signed-in").getByRole("link", {
        name: "Open Threadline admin",
      }),
    ).toBeVisible();
    await expect(nav.getByRole("button", { name: "Log out" })).toBeVisible();
    await expect(nav.getByRole("link", { name: /^Log in$/ })).toHaveCount(0);
  });

  test("coverage shows the uncovered audit_events row + header badge", async ({
    page,
  }) => {
    await login(page);
    await page.goto("/audit/coverage");
    await expect(
      page.getByRole("region", { name: "Selected schema readiness" }),
    ).toBeVisible();
    await expect(page.getByLabel("Coverage schema")).toBeVisible();
    const table = page.getByTestId("coverage-table");
    await expect(table).toBeVisible();
    const row = table.locator("tr", { hasText: "audit_events" });
    await expect(row).toBeVisible();
    await expect(row.getByText("Needs capture")).toBeVisible();
    await expect(page.getByText(/tables? need audit coverage/)).toBeVisible();
  });

  test("retention history shows the full run lifecycle", async ({ page }) => {
    await login(page);
    await page.goto("/audit/policy/retention");
    await expect(
      page.getByRole("heading", { name: "Retention window" }),
    ).toBeVisible();
    const table = page.getByTestId("retention-runs-table");
    await expect(table.getByText("Failed").first()).toBeVisible();
    await expect(table.getByText("Queued").first()).toBeVisible();
    await expect(table.getByText("18342")).toBeVisible();
  });

  test("evidence overview shows all three verdicts", async ({ page }) => {
    await login(page);
    await page.goto("/audit/evidence");
    await expect(page.getByTestId("evidence-table").first()).toBeVisible();
    await expect(page.getByText("Proven").first()).toBeVisible();
    await expect(page.getByText("Inferred").first()).toBeVisible();
    await expect(page.getByText("Unsupported").first()).toBeVisible();
  });

  test("redaction shows a deployed-matches-config row for posts", async ({
    page,
  }) => {
    await login(page);
    await page.goto("/audit/policy/redaction");
    await expect(
      page.getByRole("heading", { name: "Redaction policy" }),
    ).toBeVisible();
    await expect(
      page.getByText("Deployed matches config").first(),
    ).toBeVisible();
    await expect(page.getByText("posts").first()).toBeVisible();
  });

  test("active actor default 24h view is non-empty", async ({ page }) => {
    await login(page);
    // The active agent's recent closes appear on the default timeline; pivot to
    // their actor page and confirm the default window renders transactions.
    await page.goto("/audit/timeline");
    const actorLink = page.locator('a[href^="/audit/actors/user/"]').first();
    await expect(actorLink).toBeVisible();
    await actorLink.click();
    await expect(page).toHaveURL(/\/audit\/actors\/user\//);
    await expect(
      page.getByTestId("actor-transaction-row").first(),
    ).toBeVisible();
  });

  test("copy button copies the full visible reference and confirms", async ({
    page,
    context,
  }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await login(page);
    await page.goto(`/audit/timeline?table=${encodeURIComponent("ticket_replies")}`);
    const copyBtn = page.locator("button.tl-copy[data-tl-copy]").first();
    await expect(copyBtn).toBeVisible();
    const expectedCopy = await copyBtn.getAttribute("data-tl-copy");
    expect(expectedCopy).toBeTruthy();
    await copyBtn.click();
    await expect(copyBtn).toHaveClass(/is-copied/);
    const clip = await page.evaluate(() => navigator.clipboard.readText());
    expect(clip).toBe(expectedCopy);
  });

  test("support user sees a scoped-view chip", async ({ page }) => {
    await login(page, supportEmail);
    await page.goto("/audit/timeline");
    await expect(page.getByTestId("operator-scope")).toBeVisible();
    await expect(page.getByText("Scoped view")).toBeVisible();
  });

  test("support user sees governance and export surfaces as unavailable without enabled controls", async ({
    page,
  }) => {
    await login(page, supportEmail);
    await page.goto("/audit");

    const nav = page.getByTestId("operator-nav-shell");
    await expect(nav.getByTestId("operator-nav-evidence")).toHaveCount(0);
    await expect(nav.getByTestId("operator-nav-policy")).toHaveCount(0);
    await expect(nav.getByTestId("operator-nav-retention")).toHaveCount(0);
    await expect(nav.getByTestId("operator-nav-exports")).toHaveCount(0);

    await page.goto("/audit/evidence");
    await expect(page.getByRole("alert").filter({ hasText: "Evidence unavailable" })).toBeVisible();
    await expect(page.getByRole("link", { name: "Carry to Exports" })).toHaveCount(0);

    await page.goto("/audit/policy/redaction");
    await expect(
      page.getByRole("alert").filter({ hasText: "Redaction policy unavailable" }),
    ).toBeVisible();
    await expect(
      page.locator("#tl-main").getByRole("button", { name: /redact|delete|apply/i }),
    ).toHaveCount(0);

    await page.goto("/audit/policy/retention");
    await expect(
      page.getByRole("alert").filter({ hasText: "Retention history unavailable" }),
    ).toBeVisible();
    await expect(page.getByRole("button", { name: "Run retention prune" })).toHaveCount(0);

    await page.goto("/audit/exports");
    await expect(page.getByRole("alert").filter({ hasText: "Export access needed" })).toBeVisible();
    await expect(page.getByRole("link", { name: "Download export" })).toHaveCount(0);
    await expect(page.getByRole("button", { name: "Queue Timeline export" })).toHaveCount(0);
  });
});
