import { Browser, expect, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const supportAcmeEmail = "support@acme.example.com";
const supportOffboardedEmail = "support@offboarded-co.example.com";

async function login(page: Page, email: string) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

// CR-05 fix: the admin half of the Coverage discrimination test needs a
// genuinely distinct session, not the support session reused after a logout.
// The example app's only logout affordance is a POST form
// (components/layouts/app.html.heex) that is not rendered inside the mounted
// operator surface, so — per the round-5 plan's stated fallback — a fresh
// browser context (no shared cookies with the support session) stands in for
// logout here.
async function loginAsAdminInFreshContext(
  browser: Browser,
): Promise<{ page: Page; close: () => Promise<void> }> {
  const context = await browser.newContext();
  const page = await context.newPage();
  await login(page, adminEmail);

  // Identity proof: confirm this is really a distinct, unscoped admin session
  // BEFORE trusting anything the Coverage page renders for it, so a silently
  // failed identity switch cannot make the admin half pass on the support
  // session. `timeline_live.ex` renders `data-testid="operator-scope"` only
  // when `threadline_scope` is non-nil (support_read_only sessions, per
  // `my_authorize_fn` in router.ex); admin's authorize_fn returns a bare `:ok`
  // with no scope, so an admin session must never show that testid.
  await page.goto("/audit/timeline");
  await expect(page.getByTestId("operator-scope")).toHaveCount(0);

  return { page, close: () => context.close() };
}

test.describe("operator surface - Phase 135 automated UAT", () => {
  test("default Timeline renders in-window op variety and non-human actor labels", async ({
    page,
  }) => {
    await login(page, adminEmail);
    await page.goto("/audit/timeline");

    const rows = page.getByTestId("timeline-row");
    await expect(rows.filter({ hasText: "UPDATE" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "DELETE" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "service_account/zendesk-sync" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "job/oban-retention-purge" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "system/trigger-backfill" }).first()).toBeVisible();
    await expect(rows.filter({ hasText: "Actor unknown" }).first()).toBeVisible();
  });

  test("reply-edit transaction renders before/after diff with redacted internal note", async ({
    page,
  }) => {
    await login(page, adminEmail);
    await page.goto("/audit/timeline?table=ticket_replies");

    const replyUpdate = page
      .getByTestId("timeline-row")
      .filter({ hasText: "UPDATE" })
      .filter({ hasText: "ticket_replies" })
      .first();

    await expect(replyUpdate).toBeVisible();
    await replyUpdate.getByTestId("transaction-link").click();

    await expect(page).toHaveURL(/\/audit\/transactions\//);
    const changeRow = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: "ticket_replies" })
      .filter({ hasText: "UPDATE" })
      .first();

    await expect(changeRow).toBeVisible();
    await expect(changeRow.getByText("body", { exact: true })).toBeVisible();
    await expect(changeRow.getByText("Original reply from Zendesk sync.")).toBeVisible();
    await expect(changeRow.getByText("Updated reply")).toBeVisible();
    await expect(changeRow.getByText("internal_note_body")).toBeVisible();
    await expect(changeRow.getByText("[REDACTED]")).toHaveCount(2);
    await expect(changeRow.getByText("Internal: route to tier-2")).toHaveCount(0);
    await expect(changeRow.getByText("Confirmed tier-2 resolved. Closing.")).toHaveCount(0);
  });

  test("offboarded support user gets an honest empty scoped Timeline", async ({ page }) => {
    await login(page, supportOffboardedEmail);
    await page.goto("/audit/timeline");

    await expect(page.getByTestId("operator-scope")).toBeVisible();
    await expect(page.getByTestId("timeline-row")).toHaveCount(0);
    await expect(page.locator(".tl-empty")).toBeVisible();
    await expect(page.locator(".tl-empty")).toContainText(/No captured changes/);
    await expect(page.locator(".tl-empty")).not.toContainText(/error|crash/i);
  });

  // Renamed from "support user is denied admin-only Coverage" (CR-05): that name
  // promised a denial the old assertions did not make — they asserted
  // `Unsupported.descriptor(:coverage_unavailable)`, whose own body text reads
  // "This is not a permissions issue," so the test passed identically whether
  // authorization worked OR Coverage was dead for every role including admin.
  // The admin half below is the load-bearing addition that makes this a role
  // proof rather than a lane-capability observation.
  test("Coverage is role-discriminating: support gets the unavailable lane, admin gets the table", async ({
    page,
    browser,
  }) => {
    await login(page, supportAcmeEmail);
    await page.goto("/audit/coverage");

    await expect(page).toHaveURL(/\/audit\/coverage$/);
    // Product contract: Threadline.OperatorSurface.Unsupported.descriptor(:coverage_unavailable)
    // (unsupported.ex) renders this exact title + body — an honest "unavailable in this
    // support lane" affordance, not an access-control denial on its own. REVIEW.md IN-04
    // confirms these strings match unsupported.ex verbatim; the semantics, not the
    // strings, were the defect this test fixes.
    await expect(page.getByRole("heading", { name: "Coverage unavailable" })).toBeVisible();
    await expect(
      page.getByText("Coverage is unavailable in this support lane"),
    ).toBeVisible();
    await expect(page.getByTestId("coverage-table")).toHaveCount(0);

    // The load-bearing half (CR-05): a genuinely distinct identity — a fresh
    // browser context sharing no cookies with the support session above — must
    // see the admin-only Coverage table at the same route. Without this half,
    // the assertions above pass identically in a world where Coverage is
    // unavailable to every role, including admin.
    const admin = await loginAsAdminInFreshContext(browser);
    try {
      await admin.page.goto("/audit/coverage");
      await expect(admin.page).toHaveURL(/\/audit\/coverage$/);
      await expect(admin.page.getByTestId("coverage-table")).toBeVisible();
    } finally {
      await admin.close();
    }
  });
});
