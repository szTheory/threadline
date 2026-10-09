import { expect, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

test("opens an authorized transaction with separate action and row evidence", async ({ page }) => {
  await login(page);
  const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const correlation = `tl239-transaction-${suffix}`;
  const slug = `transaction-proof-${suffix}`;
  const nextCorrelation = `tl239-next-transaction-${suffix}`;
  const nextSlug = `following-proof-${suffix}`;
  const longTitle = `Unicode café ${"complete-evidence-value-".repeat(4)}${suffix}`;
  const response = await page.request.post("/api/posts", {
    data: { post: { title: longTitle, slug } },
    headers: {
      "content-type": "application/json",
      "x-correlation-id": correlation,
      "x-request-id": `request-${suffix}`,
    },
  });
  expect(response.status()).toBe(201);

  const nextResponse = await page.request.post("/api/posts", {
    data: { post: { title: `Second transaction ${suffix}`, slug: nextSlug } },
    headers: {
      "content-type": "application/json",
      "x-correlation-id": nextCorrelation,
      "x-request-id": `next-request-${suffix}`,
    },
  });
  expect(nextResponse.status()).toBe(201);

  const fromTo = new URLSearchParams({
    from: "2020-01-01T00:00",
    to: "2099-01-01T00:00",
    table: "posts",
    correlation_id: correlation,
  });
  await page.goto(`/audit/timeline?${fromTo.toString()}`);
  const matchingRow = page
    .getByTestId("timeline-row")
    .filter({ has: page.locator(`[data-tl-copy="${correlation}"]`) })
    .first();
  await expect(matchingRow).toBeVisible();
  await matchingRow.getByTestId("transaction-link").click();

  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);
  await expect(page.getByRole("heading", { name: "Transaction", exact: true })).toBeVisible();
  await expect(page.getByText("Action actor", { exact: true })).toBeVisible();
  await expect(page.getByText("Request ID", { exact: true })).toBeVisible();
  await expect(
    page.locator(`.tl-secondary-ref[data-tl-copy="request-${suffix}"]`),
  ).toBeVisible();

  const change = page.getByTestId("transaction-change-row").filter({ hasText: "posts" }).first();
  await expect(change).toBeVisible();
  await expect(change).toContainText("INSERT");
  await expect(change).toContainText("After");
  await expect(change).toContainText("transaction-proof");

  const fullTitle = change.getByText("Show full title after value", { exact: true });
  await fullTitle.focus();
  await page.keyboard.press("Enter");
  await expect(change.getByText(longTitle, { exact: true })).toBeVisible();
  await expect(
    page.getByText("Show full exact captured time", { exact: true }),
  ).toBeVisible();
  const exactTime = page.getByText("Show full exact captured time", { exact: true });
  await exactTime.focus();
  await page.keyboard.press("Enter");
  await expect(exactTime.locator("xpath=..").locator("code")).toContainText(/Z$/);

  const transactionId = new URL(page.url()).pathname.split("/").pop();
  await expect(
    page.locator(`.tl-detail-header code[data-tl-copy="${transactionId}"]`),
  ).toHaveAttribute("data-tl-copy", transactionId!);

  const nextFilter = new URLSearchParams({
    from: "2020-01-01T00:00",
    to: "2099-01-01T00:00",
    table: "posts",
    correlation_id: nextCorrelation,
  });
  await page.goto(`/audit/timeline?${nextFilter.toString()}`);
  const nextRow = page
    .getByTestId("timeline-row")
    .filter({ has: page.locator(`[data-tl-copy="${nextCorrelation}"]`) })
    .first();
  await expect(nextRow).toBeVisible();
  await nextRow.getByTestId("transaction-link").click();
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);
  await expect(page.getByTestId("transaction-change-row")).toContainText(nextSlug);
  await expect(page.getByTestId("transaction-change-row")).not.toContainText(slug);
});
