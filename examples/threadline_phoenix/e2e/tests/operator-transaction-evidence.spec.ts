import { expect, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

const responsiveCases = [
  { name: "320px", width: 320, height: 800 },
  { name: "375px", width: 375, height: 812 },
  { name: "768px", width: 768, height: 900 },
  { name: "1280px", width: 1280, height: 900 },
  { name: "short 320px", width: 320, height: 420 },
];

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() =>
    document.documentElement.scrollWidth - document.documentElement.clientWidth,
  );
  expect(overflow, "document must not gain horizontal scroll").toBeLessThanOrEqual(1);
}

async function expectInsideViewport(locator: ReturnType<Page["locator"]>, width: number) {
  await expect(locator).toBeVisible();
  const box = await locator.boundingBox();
  expect(box).not.toBeNull();
  expect(box!.x).toBeGreaterThanOrEqual(-1);
  expect(box!.x + box!.width).toBeLessThanOrEqual(width + 1);
}

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
  await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
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

for (const viewport of responsiveCases) {
  test(`reflows Home and complete transaction evidence at ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await login(page);

    const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    const correlation = `tl239-responsive-${suffix}`;
    const controlCorrelation = `tl239-boundary-control-${suffix}`;
    const slug = `responsive-proof-${suffix}`;
    const controlSlug = `responsive-control-${suffix}`;
    const longTitle = `café-🧵-${"界μ".repeat(70)}-${suffix}`;

    const created = await page.request.post("/api/posts", {
      data: { post: { title: longTitle, slug } },
      headers: {
        "content-type": "application/json",
        "x-correlation-id": correlation,
        "x-request-id": `request-${suffix}`,
      },
    });
    expect(created.status()).toBe(201);

    const control = await page.request.post("/api/posts", {
      data: { post: { title: `Control ${suffix}`, slug: controlSlug } },
      headers: {
        "content-type": "application/json",
        "x-correlation-id": controlCorrelation,
        "x-request-id": `control-request-${suffix}`,
      },
    });
    expect(control.status()).toBe(201);

    await page.goto("/audit");
    const primaryCard = page.locator(".tl-home__card--primary");
    const earnedLookups = page.locator(".tl-home__earned-flow");
    await expect(primaryCard).toBeVisible();
    await expect(primaryCard.getByRole("heading", { name: "Find what changed", exact: true })).toBeVisible();
    await expect(primaryCard.getByRole("link", { name: "Open the timeline", exact: true })).toBeVisible();
    const primaryPrecedesLookups = await page.locator(".tl-home").evaluate((home) => {
      const primary = home.querySelector(".tl-home__card--primary");
      const lookups = home.querySelector(".tl-home__earned-flow");
      return Boolean(
        primary &&
          lookups &&
          (primary.compareDocumentPosition(lookups) & Node.DOCUMENT_POSITION_FOLLOWING),
      );
    });
    expect(primaryPrecedesLookups).toBe(true);

    const paperAndInk = await page.locator(".threadline-ui").evaluate((shell) => {
      const styles = getComputedStyle(shell);
      return {
        paper: styles.getPropertyValue("--tl-color-paper").trim(),
        ink: styles.getPropertyValue("--tl-color-ink").trim(),
      };
    });
    expect(paperAndInk.paper).toMatch(/^#[0-9a-f]{6}$/i);
    expect(paperAndInk.ink).toMatch(/^#[0-9a-f]{6}$/i);
    const homeButtonStyle = await primaryCard
      .getByRole("link", { name: "Open the timeline", exact: true })
      .evaluate((button) => {
        const styles = getComputedStyle(button);
        return { fontSize: parseFloat(styles.fontSize), minHeight: parseFloat(styles.minHeight) };
      });
    expect(homeButtonStyle.fontSize).toBeGreaterThanOrEqual(14);
    expect(homeButtonStyle.minHeight).toBeGreaterThanOrEqual(40);
    await expectNoHorizontalOverflow(page);
    await expectInsideViewport(primaryCard.getByRole("link", { name: "Open the timeline", exact: true }), viewport.width);
    if (viewport.height === 420) {
      const homeControls = [
        page.getByLabel("Table", { exact: true }),
        page.getByLabel("Record id", { exact: true }),
        page.getByRole("button", { name: "Open row history", exact: true }),
        page.getByLabel("Correlation id", { exact: true }),
        page.getByRole("button", { name: "Open the timeline", exact: true }),
      ];
      for (const controlLocator of homeControls) {
        await controlLocator.focus();
        await expect(controlLocator).toBeInViewport();
      }
    }

    const search = new URLSearchParams({
      from: "2020-01-01T00:00",
      to: "2099-01-01T00:00",
      table: "posts",
      correlation_id: correlation,
    });
    await page.goto(`/audit/timeline?${search.toString()}`);
    const targetRow = page.getByTestId("timeline-row").filter({
      has: page.locator(`[data-tl-copy="${correlation}"]`),
    });
    const boundaryControlRow = page.getByTestId("timeline-row").filter({
      has: page.locator(`[data-tl-copy="${controlCorrelation}"]`),
    });
    await expect(targetRow).toHaveCount(1);
    await expect(targetRow).toBeVisible();
    await expect(boundaryControlRow).toHaveCount(0);
    await targetRow.getByTestId("transaction-link").click();

    await expect(page.getByRole("heading", { name: "Transaction", exact: true })).toBeVisible();
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    const change = page.getByTestId("transaction-change-row");
    await expect(change).toHaveCount(1);
    await expect(change).toBeVisible();
    await expect(change.locator(".tl-change__table")).toHaveText("posts");
    await expect(change.getByText(slug, { exact: true })).toBeVisible();

    const titleFieldName = change.locator(".tl-change__field-name").getByText("title", { exact: true });
    await expect(titleFieldName).toHaveCount(1);
    const titleField = titleFieldName.locator("xpath=..");
    const valueCells = titleField.locator(".tl-diff__cell");
    await expect(valueCells).toHaveCount(1);
    const after = valueCells.first();
    await expect(titleField.getByText("Before", { exact: true }), "an INSERT has no prior value axis").toHaveCount(0);
    await expect(after.getByText("After", { exact: true })).toBeVisible();
    const fullValue = after.getByText("Show full title after value", { exact: true });
    await fullValue.focus();
    await expect(fullValue).toBeInViewport();
    await expect(fullValue).toBeFocused();
    await fullValue.press("Enter");
    await expect(after.getByText(longTitle, { exact: true })).toBeVisible();
    await expect(change).not.toContainText(controlSlug);
    const compactTargets = await change.locator(".tl-button--compact").evaluateAll((controls) =>
      controls.map((control) => {
        const { width, height } = control.getBoundingClientRect();
        return { width, height, fontSize: parseFloat(getComputedStyle(control).fontSize) };
      }),
    );
    expect(compactTargets.length).toBeGreaterThan(0);
    for (const target of compactTargets) {
      expect(target.width, "compact action target width").toBeGreaterThanOrEqual(40);
      expect(target.height, "compact action target height").toBeGreaterThanOrEqual(40);
      expect(target.fontSize, "interactive label size").toBeGreaterThanOrEqual(14);
    }
    const axisFontSize = await after.getByText("After", { exact: true }).evaluate((label) =>
      parseFloat(getComputedStyle(label).fontSize),
    );
    expect(axisFontSize).toBeGreaterThanOrEqual(14);
    await expectNoHorizontalOverflow(page);

    const disclosureValue = after.locator("code.tl-value__full");
    const textSelection = await disclosureValue.evaluate((code) => {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection?.removeAllRanges();
      selection?.addRange(range);
      return selection?.toString();
    });
    expect(textSelection).toBe(longTitle);

    await expectInsideViewport(fullValue, viewport.width);

    // The seeded reply edit captures both axes. An INSERT alone
    // cannot establish the paired-wide / stacked-narrow layout contract.
    const updateQuery = new URLSearchParams({
      from: "2020-01-01T00:00",
      to: "2099-01-01T00:00",
      table: "ticket_replies",
    });
    await page.goto(`/audit/timeline?${updateQuery}`);
    const updateRow = page.getByTestId("timeline-row").filter({
      has: page.locator(".tl-change__op").filter({ hasText: /^UPDATE$/ }),
    }).first();
    await expect(updateRow).toBeVisible();
    await expect(updateRow.locator(".tl-change__op")).toHaveText("UPDATE");
    const updateHref = await updateRow.getByTestId("transaction-link").getAttribute("href");
    await updateRow.getByTestId("transaction-link").click();
    await expect(page).toHaveURL(new URL(updateHref!, page.url()).toString());
    await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
    const ticketChange = page.getByTestId("transaction-change-row").filter({
      has: page.locator(".tl-change__table").filter({ hasText: /^ticket_replies$/ }),
    });
    await expect(ticketChange).toHaveCount(1);
    await expect(ticketChange.locator(".tl-change__op")).toHaveText("UPDATE");
    const statusField = ticketChange.locator(".tl-diff__row").filter({
      has: page.locator(".tl-change__field-name").filter({ hasText: /^body$/ }),
    });
    const statusCells = statusField.locator(".tl-diff__cell");
    await expect(statusCells).toHaveCount(2);
    const beforeCell = statusCells.nth(0);
    const afterCell = statusCells.nth(1);
    await expect(beforeCell.getByText("Before", { exact: true })).toBeVisible();
    await expect(beforeCell.getByText("Original reply from Zendesk sync.", { exact: true })).toBeVisible();
    await expect(afterCell.getByText("After", { exact: true })).toBeVisible();
    await expect(afterCell.getByText("Updated reply — issue resolved.", { exact: true })).toBeVisible();
    const beforeBox = (await beforeCell.boundingBox())!;
    const afterBox = (await afterCell.boundingBox())!;
    if (viewport.width >= 768) {
      expect(Math.abs(beforeBox.y - afterBox.y), "wide values share one row").toBeLessThanOrEqual(1);
      expect(afterBox.x, "After follows Before horizontally").toBeGreaterThanOrEqual(beforeBox.x + beforeBox.width);
    } else {
      expect(afterBox.y, "narrow values stack vertically").toBeGreaterThanOrEqual(beforeBox.y + beforeBox.height);
    }
    await expectNoHorizontalOverflow(page);
  });
}
