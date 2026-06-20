import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";
const rowTable = "ticket_replies";

type StyleSnapshot = {
  animationName: string;
  animationDuration: string;
  animationDelay: string;
  boxShadow: string;
  cursor: string;
  opacity: string;
  pointerEvents: string;
  transform: string;
  transformOrigin: string;
  transitionDelay: string;
  transitionDuration: string;
  transitionProperty: string;
  transitionTimingFunction: string;
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
        boxShadow: style.boxShadow,
        cursor: style.cursor,
        opacity: style.opacity,
        pointerEvents: style.pointerEvents,
        transform: style.transform,
        transformOrigin: style.transformOrigin,
        transitionDelay: style.transitionDelay,
        transitionDuration: style.transitionDuration,
        transitionProperty: style.transitionProperty,
        transitionTimingFunction: style.transitionTimingFunction,
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

function splitCssList(value: string) {
  return value.split(",").map((part) => part.trim());
}

function expectTransitionIncludes(
  style: StyleSnapshot,
  {
    duration,
    properties,
    easing,
  }: { duration: string; properties: string[]; easing: string },
) {
  const durations = splitCssList(style.transitionDuration);
  expect(
    durations.some((part) => part === duration),
    `expected transitionDuration ${style.transitionDuration} to include ${duration}`,
  ).toBe(true);

  const transitionProperties = splitCssList(style.transitionProperty);
  for (const property of properties) {
    expect(
      transitionProperties.includes(property),
      `expected transitionProperty ${style.transitionProperty} to include ${property}`,
    ).toBe(true);
  }

  expect(
    style.transitionTimingFunction,
    `expected transitionTimingFunction to include ${easing}`,
  ).toContain(easing);
}

function expectNoTransitionDelay(style: StyleSnapshot) {
  expectDurationList(style.transitionDelay, "0s");
}

function expectIdentityOrNone(transform: string) {
  expect(["none", "matrix(1, 0, 0, 1, 0, 0)"]).toContain(transform);
}

function expectTopOrigin(style: StyleSnapshot) {
  const parts = style.transformOrigin.split(" ");
  expect(parts.length).toBeGreaterThanOrEqual(2);
  expect(parts[1], `expected top transform-origin, got ${style.transformOrigin}`).toBe("0px");
}

async function styleDuringPointerDown(page: Page, locator: Locator): Promise<StyleSnapshot> {
  await expect(locator).toBeVisible();
  const box = await locator.boundingBox();
  expect(box).not.toBeNull();

  await page.mouse.move(box!.x + box!.width / 2, box!.y + box!.height / 2);
  await page.mouse.down();
  const style = await computedStyle(locator);
  await page.mouse.up();

  return style;
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

  test("stress overlays, popovers, details, and toasts compute tokenized compositor motion", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    await expect(page.getByTestId("stress-preview")).toBeVisible();

    const toastStyle = await computedStyle(page.locator("#stress-toast"));
    expectTransitionIncludes(toastStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
    expectNoTransitionDelay(toastStyle);

    await page.getByRole("button", { name: "Show Modal" }).click();
    const modalStyle = await computedStyle(page.locator("#stress-modal-content"));
    expectTransitionIncludes(modalStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
    await page.getByRole("button", { name: "Confirm stress modal" }).click();

    await page.getByRole("button", { name: "Show Drawer" }).click();
    const drawerStyle = await computedStyle(page.locator("#stress-drawer-content"));
    expectTransitionIncludes(drawerStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
    await page.getByRole("button", { name: "Close stress drawer" }).click();

    await page.locator("#stress-dropdown-button").click();
    const dropdownStyle = await computedStyle(page.locator("#stress-dropdown-menu"));
    expectTransitionIncludes(dropdownStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
    expectTopOrigin(dropdownStyle);

    await page.locator("#stress-popover-trigger").click();
    const popoverStyle = await computedStyle(page.locator("#stress-popover"));
    expectTransitionIncludes(popoverStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
    expectTopOrigin(popoverStyle);

    await page.getByRole("button", { name: "Accordion Section" }).click();
    const accordionStyle = await computedStyle(page.locator("#stress-accordion-content"));
    expectTransitionIncludes(accordionStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });

    await page.goto("/audit/policy/redaction");
    const policyRow = page.locator("details.tl-policy__row").first();
    await policyRow.locator("summary").click();
    const detailsContentStyle = await computedStyle(policyRow, "::details-content");
    expectTransitionIncludes(detailsContentStyle, {
      duration: "0.18s",
      properties: ["opacity"],
      easing: "cubic-bezier(0.16, 1, 0.3, 1)",
    });
  });

  test("enabled controls press with transform feedback while disabled controls stay still", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    const enabled = page.getByRole("button", { name: "Default" });
    const enabledStyle = await styleDuringPointerDown(page, enabled);
    expect(enabledStyle.transform).toContain("0.96");
    expect(enabledStyle.cursor).toBe("pointer");

    const disabled = page.getByRole("button", { name: "Disabled" });
    const disabledPointerStyle = await styleDuringPointerDown(page, disabled);
    expectIdentityOrNone(disabledPointerStyle.transform);
    expect(disabledPointerStyle.cursor).toBe("not-allowed");
    expect(disabledPointerStyle.boxShadow).toBe("none");

    await disabled.dispatchEvent("keydown", { key: " " });
    const disabledKeyboardStyle = await computedStyle(disabled);
    expectIdentityOrNone(disabledKeyboardStyle.transform);
    expect(disabledKeyboardStyle.pointerEvents).not.toBe("none");
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

  test("stress overlay, popover, accordion, and toast motion collapses but remains visible", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    await expect(page.getByTestId("stress-preview")).toBeVisible();

    const toastStyle = await computedStyle(page.locator("#stress-toast"));
    expectDurationList(toastStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(toastStyle);
    expectIdentityOrNone(toastStyle.transform);

    await page.getByRole("button", { name: "Show Modal" }).click();
    const modal = page.locator("#stress-modal-content");
    await expect(modal).toBeVisible();
    const modalStyle = await computedStyle(modal);
    expectDurationList(modalStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(modalStyle);
    expectIdentityOrNone(modalStyle.transform);

    await page.getByRole("button", { name: "Confirm stress modal" }).click();
    await page.getByRole("button", { name: "Show Drawer" }).click();
    const drawer = page.locator("#stress-drawer-content");
    await expect(drawer).toBeVisible();
    const drawerStyle = await computedStyle(drawer);
    expectDurationList(drawerStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(drawerStyle);
    expectIdentityOrNone(drawerStyle.transform);

    await page.getByRole("button", { name: "Close stress drawer" }).click();
    await page.locator("#stress-dropdown-button").click();
    const dropdown = page.locator("#stress-dropdown-menu");
    await expect(dropdown).toBeVisible();
    const dropdownStyle = await computedStyle(dropdown);
    expectDurationList(dropdownStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(dropdownStyle);
    expectIdentityOrNone(dropdownStyle.transform);

    await page.locator("#stress-popover-trigger").click();
    const popover = page.locator("#stress-popover");
    await expect(popover).toBeVisible();
    const popoverStyle = await computedStyle(popover);
    expectDurationList(popoverStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(popoverStyle);
    expectIdentityOrNone(popoverStyle.transform);

    await page.getByRole("button", { name: "Accordion Section" }).click();
    const accordion = page.locator("#stress-accordion-content");
    await expect(accordion).toBeVisible();
    const accordionStyle = await computedStyle(accordion);
    expectDurationList(accordionStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(accordionStyle);
    expectIdentityOrNone(accordionStyle.transform);
  });
});
