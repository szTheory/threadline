import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
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
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
  await expect(page.locator("#filter-table")).toHaveValue(rowTable);

  const transactionLink = page
    .getByTestId("timeline-row")
    .filter({ hasText: rowTable })
    .first()
    .getByTestId("transaction-link");

  await expect(transactionLink).toBeVisible();
  const transactionHref = await transactionLink.getAttribute("href");
  expect(transactionHref).not.toBeNull();

  await page.goto(transactionHref!);
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

async function readComputedStyle(locator: Locator, pseudoElement?: string): Promise<StyleSnapshot> {
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

async function computedStyle(locator: Locator, pseudoElement?: string): Promise<StyleSnapshot> {
  await expect(locator).toBeVisible();
  return readComputedStyle(locator, pseudoElement);
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

async function expectImmediateMotion(locator: Locator) {
  const style = await computedStyle(locator);
  expect(style.animationName).toBe("none");
  expectDurationList(style.animationDuration, "0s");
  expectDurationList(style.animationDelay, "0s");
  expect(style.transitionProperty).toBe("none");
  expectDurationList(style.transitionDuration, "0s");
  expectNoTransitionDelay(style);
  expectIdentityOrNone(style.transform);
}

async function expectNoEntranceMotion(locator: Locator) {
  const style = await computedStyle(locator);
  expect(style.animationName).toBe("none");
  expectDurationList(style.animationDuration, "0s");
  expectDurationList(style.animationDelay, "0s");
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
  const style = await readComputedStyle(locator);
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

  test("row-history evidence stays immediate across as-of LiveView patches", async ({ page }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);
    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

    const drawer = page.locator(".tl-row-history-drawer");
    const rows = drawer.locator(".tl-subview__timeline li");
    await expect(drawer).toBeVisible();
    await expect(rows.first()).toBeVisible();
    await expectImmediateMotion(drawer);
    await expectImmediateMotion(rows.first());

    const asOf = drawer.locator('input[name="as_of"]');
    for (const value of ["2026-10-10T10:00", "2026-10-10T10:05"]) {
      await asOf.fill(value);
      await expect
        .poll(() => new URL(page.url()).searchParams.get("as_of"))
        .toBe(`${value}:00Z`);
      await expect(drawer).toBeVisible();
      await expectImmediateMotion(drawer);
      await expectImmediateMotion(rows.first());
    }
  });

  test("evidence cards and actor investigation rows do not animate on entry", async ({ page }) => {
    await page.goto("/audit/evidence");
    const evidenceCard = page.locator(".tl-record-list > .tl-record-card").first();
    await expect(evidenceCard).toBeVisible();
    await expectNoEntranceMotion(evidenceCard);

    await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
    const actorHref = await page
      .getByTestId("timeline-row")
      .first()
      .getByTitle("View actor activity")
      .getAttribute("href");
    expect(actorHref).not.toBeNull();
    await page.goto(actorHref!);

    const transactionRow = page.locator("#transactions-list > .tl-change").first();
    await expect(transactionRow).toBeVisible();
    await expectNoEntranceMotion(transactionRow);
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

    const modalOpener = page.getByRole("button", { name: "Show Modal", exact: true });
    await modalOpener.click();
    const modalStyle = await computedStyle(page.locator("#stress-modal-content"));
    expectTransitionIncludes(modalStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
    await page.getByRole("button", { name: "Confirm stress modal" }).click();
    await expect(page.locator("#stress-modal")).toBeHidden();
    await expect(modalOpener).toBeFocused();

    // The fixture's persistent toast can overlap the drawer trigger on mobile.
    const toast = page.locator("#stress-toast");
    if (await toast.isVisible()) {
      const closeToast = toast.getByRole("button", { name: "Close" });
      await closeToast.focus();
      await page.keyboard.press("Enter");
      await expect(toast).toBeHidden();
    }

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
    const enabled = page.getByRole("button", { name: "Active/Pressed" });
    const enabledStyle = await computedStyle(enabled);
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

  test("inspection refresh and native disclosure preserve their outcomes with reduced motion", async ({ page }) => {
    await page.goto("/audit/coverage?schema=public");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const refreshCoverage = page.getByRole("button", { name: "Refresh coverage", exact: true });
    await refreshCoverage.focus();
    await page.keyboard.press("Enter");
    await expect(page.getByRole("region", { name: "Selected schema readiness" })).toContainText("public");
    await expect(page.locator("#coverage-schema")).toHaveValue("public");

    await page.goto("/audit/evidence");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const seeded = page.locator(".tl-record-card").filter({ has: page.locator('code[title*="walk-retention-offboarded-co"]') });
    await expect(seeded).toHaveCount(1);
    const reference = (await seeded.locator("code[data-tl-copy]").getAttribute("data-tl-copy"))!;
    expect(JSON.parse(reference).run_id).toBe("walk-retention-offboarded-co");
    await page.goto(`/audit/evidence?subject=retention_run&subject_ref_json=${encodeURIComponent(reference)}&mode=history`);
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(page.locator(".tl-evidence__workflow-summary code[data-tl-copy]")).toHaveAttribute("data-tl-copy", reference);
    const evidenceStyle = await computedStyle(page.locator(".tl-record-card").first());
    expect(evidenceStyle.animationName).toBe("none");
    expectDurationList(evidenceStyle.animationDuration, "0.001s");

    await page.goto("/audit/policy/redaction?schema=public");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const row = page.locator("details.tl-policy__row").filter({ has: page.getByText("posts", { exact: true }) });
    await row.locator("summary").focus();
    await page.keyboard.press("Enter");
    await expect(row).toHaveAttribute("open", "");
    await expect(row.getByRole("table")).toBeVisible();
    expectDurationList((await computedStyle(row, "::details-content")).transitionDuration, "0.001s");
    await page.getByRole("button", { name: "Refresh policy inspection", exact: true }).click();
    await expect(row.getByText("Deployed matches config", { exact: true })).toBeVisible();
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

  test("retention confirmation remains immediate and usable with reduced motion", async ({ page }) => {
    await page.goto("/audit/policy/retention");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const prune = page.getByRole("button", { name: "Prune now", exact: true }).first();
    await prune.focus();
    await page.keyboard.press("Enter");

    const dialog = page.getByRole("dialog", { name: "Prune retained audit data?" });
    const modal = page.locator("#prune-confirm-content");
    await expect(dialog).toBeVisible();
    await expect(dialog.getByRole("textbox", { name: "Policy name to confirm" })).toBeFocused();
    const motion = await computedStyle(modal);
    expectDurationList(motion.transitionDuration, "0.001s");
    expectNoTransitionDelay(motion);
    expectIdentityOrNone(motion.transform);
    await expect(dialog.getByRole("button", { name: "Keep audit data", exact: true })).toBeVisible();

    await page.keyboard.press("Escape");
    await expect(page.locator("#prune-confirm")).toBeHidden();
    await expect(prune).toBeFocused();
    await expect(page.getByText("Prune request accepted", { exact: false })).toHaveCount(0);
  });

  test("row-history drawer and evidence stay immediate with reduced motion", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);
    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);

    const drawer = page.locator(".tl-row-history-drawer");
    const firstRow = drawer.locator(".tl-subview__timeline li").first();
    await expect(drawer).toBeVisible();
    await expect(firstRow).toBeVisible();
    await expectImmediateMotion(drawer);
    await expectImmediateMotion(firstRow);
  });

  test("reduced motion preserves keyboard row-history route, dialog, and focus", async ({
    page,
  }) => {
    await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
    await expect(page.locator("#filter-table")).toHaveValue(rowTable);

    const transactionLink = page
      .getByTestId("timeline-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("transaction-link");
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).not.toBeNull();
    await page.goto(transactionHref!);

    const rowHistoryLink = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: rowTable })
      .getByTestId("row-history-link")
      .first();
    const rowHistoryHref = await rowHistoryLink.getAttribute("href");
    expect(rowHistoryHref).not.toBeNull();
    await rowHistoryLink.focus();
    await page.keyboard.press("Enter");
    await expect(page).toHaveURL(new URL(rowHistoryHref!, page.url()).toString());

    const drawer = page.locator(".tl-row-history-drawer");
    const dialog = page.getByRole("dialog", { name: /Row history/ });
    const close = dialog.getByRole("link", { name: "Close", exact: true });
    await expect(dialog).toBeVisible();
    await expect(dialog).toHaveAttribute("aria-modal", "true");
    await expect(close).toBeFocused();
    await expectImmediateMotion(drawer);

    await page.keyboard.press("Escape");
    await expect(page).toHaveURL(transactionHref!);
    await expect(dialog).toBeHidden();
    await expect(rowHistoryLink).toBeFocused();
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

    const toast = page.locator("#stress-toast");
    const toastStyle = await computedStyle(toast);
    expectDurationList(toastStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(toastStyle);
    expectIdentityOrNone(toastStyle.transform);
    const closeToast = toast.getByRole("button", { name: "Close" });
    await closeToast.click();
    await expect(toast).toBeHidden();

    const modalOpener = page.getByRole("button", { name: "Show Modal", exact: true });
    await modalOpener.click();
    const modalContainer = page.locator("#stress-modal");
    const modal = page.locator("#stress-modal-content");
    await expect(modal).toBeVisible();
    const modalStyle = await computedStyle(modal);
    expectDurationList(modalStyle.transitionDuration, "0.001s");
    expectNoTransitionDelay(modalStyle);
    expectIdentityOrNone(modalStyle.transform);

    await page.getByRole("button", { name: "Confirm stress modal" }).click();
    await expect(modalContainer).toBeHidden();
    await expect(modalOpener).toBeFocused();
    if (await toast.isVisible()) {
      await closeToast.click();
      await expect(toast).toBeHidden();
    }

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
