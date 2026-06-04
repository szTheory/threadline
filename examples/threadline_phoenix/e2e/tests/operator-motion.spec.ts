import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";
const rowTable = "ticket_replies";

type StyleSnapshot = {
  animationName: string;
  animationDuration: string;
  animationDelay: string;
  transform: string;
  transitionDuration: string;
};

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function discoverTicketReplyRecordId(page: Page) {
  await page.goto(`/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
  await page.getByTestId("transaction-link").first().click();
  await expect(page).toHaveURL(/\/audit\/transactions\/[^/]+$/);

  const rowHistoryLink = page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first();

  await expect(rowHistoryLink).toBeVisible();
  const href = await rowHistoryLink.getAttribute("href");
  expect(href).not.toBeNull();

  const match = href!.match(new RegExp(`/history/${rowTable}/([^?#/]+)`));
  expect(match, `expected ${rowTable} row-history href, got ${href}`).not.toBeNull();
  return decodeURIComponent(match![1]);
}

async function computedStyle(locator: Locator, pseudoElement?: string): Promise<StyleSnapshot> {
  await expect(locator).toBeVisible();

  return locator.evaluate(
    (element, pseudo) => {
      const style = getComputedStyle(element, pseudo || undefined);

      return {
        animationName: style.animationName,
        animationDuration: style.animationDuration,
        animationDelay: style.animationDelay,
        transform: style.transform,
        transitionDuration: style.transitionDuration,
      };
    },
    pseudoElement,
  );
}

function expectDurationList(value: string, duration: string) {
  const durations = value.split(",").map((part) => part.trim());
  expect(durations.length, `expected ${value} to include at least one duration`).toBeGreaterThan(0);
  expect(durations.every((part) => part === duration), `expected ${value} to collapse to ${duration}`).toBe(true);
}

test.describe("operator motion contracts with default motion", () => {
  test.use({ reducedMotion: "no-preference" });

  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "no-preference" });
    await login(page);
  });

  test("Home card and signature thread use named keyframes and locked durations", async ({
    page,
  }) => {
    await page.goto("/audit");

    const card = page.locator(".tl-home__card").first();
    const cardStyle = await computedStyle(card);
    expect(cardStyle.animationName).toBe("tl-rise-in");
    expect(cardStyle.animationDuration).toBe("0.18s");

    const primaryCard = page.locator(".tl-home__card--primary").first();
    const signatureThreadStyle = await computedStyle(primaryCard, "::before");
    expect(signatureThreadStyle.animationName).toBe("tl-thread-draw");
    expect(signatureThreadStyle.animationDuration).toBe("0.24s");
    expect(signatureThreadStyle.animationDelay).toBe("0.12s");
  });
});

test.describe("operator motion contracts with reduced motion", () => {
  test.use({ reducedMotion: "reduce" });

  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page);
  });

  test("Home motion collapses animation durations and signature thread delay", async ({
    page,
  }) => {
    await page.goto("/audit");

    const cardStyle = await computedStyle(page.locator(".tl-home__card").first());
    expect(cardStyle.animationName).toBe("tl-rise-in");
    expect(cardStyle.animationDuration).toBe("0.001s");

    const signatureThreadStyle = await computedStyle(
      page.locator(".tl-home__card--primary").first(),
      "::before",
    );
    expect(signatureThreadStyle.animationName).toBe("tl-thread-draw");
    expect(signatureThreadStyle.animationDuration).toBe("0.001s");
    expect(signatureThreadStyle.animationDelay).toBe("0s");
  });

  test("row-history drawer enters without off-screen reduced-motion transform", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);
    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);

    const drawerStyle = await computedStyle(page.getByTestId("row-history-drawer"));
    expect(drawerStyle.animationName).toBe("tl-drawer-in");
    expect(drawerStyle.animationDuration).toBe("0.001s");
    expect(drawerStyle.transform).not.toMatch(/matrix\(1,\s*0,\s*0,\s*1,\s*1[0-9]{2,}/);
  });

  test("policy details content transition durations collapse", async ({ page }) => {
    await page.goto("/audit/policy/redaction");

    const policyRow = page.locator("details.tl-policy__row").first();
    await expect(policyRow).toBeVisible();
    await policyRow.locator("summary").click();

    const detailsContentStyle = await computedStyle(policyRow, "::details-content");
    expectDurationList(detailsContentStyle.transitionDuration, "0.001s");
  });
});
