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
  test("coverage shows the uncovered audit_events row + header badge", async ({ page }) => {
    await login(page);
    await page.goto("/audit/coverage");
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
    await expect(page.getByText("Retention History")).toBeVisible();
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

  test("redaction shows a deployed-matches-config row for posts", async ({ page }) => {
    await login(page);
    await page.goto("/audit/policy/redaction");
    await expect(page.getByText("Redaction assurance")).toBeVisible();
    await expect(page.getByText("Deployed matches config").first()).toBeVisible();
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
    await expect(page.getByTestId("actor-transaction-row").first()).toBeVisible();
  });

  test("copy button copies the correlation id and confirms", async ({ page, context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await login(page);
    await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(correlation)}`);
    const copyBtn = page.locator(`button.tl-copy[data-tl-copy="${correlation}"]`).first();
    await expect(copyBtn).toBeVisible();
    await copyBtn.click();
    await expect(copyBtn).toHaveClass(/is-copied/);
    const clip = await page.evaluate(() => navigator.clipboard.readText());
    expect(clip).toBe(correlation);
  });

  test("support user sees a scoped-view chip", async ({ page }) => {
    await login(page, supportEmail);
    await page.goto("/audit/timeline");
    await expect(page.getByTestId("operator-scope")).toBeVisible();
    await expect(page.getByText("Scoped view")).toBeVisible();
  });
});
