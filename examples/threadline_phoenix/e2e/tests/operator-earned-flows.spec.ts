import { chromium, expect, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import { installControlledClipboard, seedPaths } from "../support/operator-browser-evidence.js";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import {
  captureInvestigationCheckpoint,
  captureInvestigationHalf,
  readInvestigationMaterialization,
} from "../support/operator-investigation-pair.js";
import {
  setAndReadTabZoom,
  withIsolatedZoomContext,
} from "../support/operator-tab-zoom.js";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";
const rowTable = "ticket_replies";
const investigationTitle = "Acme 4521 whole investigation";
const investigationFrom = "2020-01-01T00:00";
const investigationTo = "2099-01-01T00:00";
const demoManifest = readFileSync(resolve(dirname(fileURLToPath(import.meta.url)), "../../DEMO-MANIFEST.md"), "utf8");
const closerId = demoManifest.match(/^\| Acme closer \| `closer@acme\.example\.com` \| `([^`]+)` \|$/m)?.[1];
if (!closerId) throw new Error("DEMO-MANIFEST.md does not declare the Acme closer identity");

function investigationSearch() {
  const params = new URLSearchParams([
    ["from", investigationFrom], ["to", investigationTo], ["table", rowTable], ["correlation_id", closeCorrelation],
  ]);
  return `/audit/timeline?${params.toString()}`;
}

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

async function expectPath(page: Page, path: string) {
  await expect.poll(() => new URL(page.url()).pathname).toBe(path);
}

async function expectLiveViewConnected(page: Page) {
  const liveRoot = page.locator("[data-phx-main]").first();
  if ((await liveRoot.count()) > 0) {
    await expect(liveRoot).toHaveClass(/phx-connected/);
  }
}

async function discoverTicketReplyRecordId(page: Page) {
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
  await expectLiveViewConnected(page);
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
  await expectLiveViewConnected(page);

  const rowHistoryLink = page
    .getByTestId("transaction-change-row")
    .filter({ hasText: rowTable })
    .getByTestId("row-history-link")
    .first();

  await expect(rowHistoryLink).toBeVisible();
  const href = await rowHistoryLink.getAttribute("href");
  expect(href).not.toBeNull();

  const match = href!.match(new RegExp(`/history/${rowTable}/([^?#/]+)`));
  expect(
    match,
    `expected ${rowTable} row-history href, got ${href}`,
  ).not.toBeNull();
  return decodeURIComponent(match![1]);
}

test.describe("operator earned-flow browser UAT", () => {
  test.beforeEach(async ({ page }, info) => {
    if (info.title === investigationTitle) {
      await page.context().addInitScript(() => {
        const probe = {
          calls: [] as Array<{ value: string; trustedActivation: boolean }>,
          pending: [] as Array<() => void>,
          fallbackCalls: 0,
          resolveNext() { this.pending.shift()?.(); },
        };
        (window as any).__threadlinePhase250Clipboard = probe;
        Object.defineProperty(navigator, "clipboard", {
          configurable: true,
          value: {
            writeText(value: string) {
              probe.calls.push({ value, trustedActivation: navigator.userActivation?.isActive === true });
              return new Promise<void>((resolve) => probe.pending.push(resolve));
            },
          },
        });
        document.execCommand = (() => {
          probe.fallbackCalls += 1;
          return false;
        }) as typeof document.execCommand;
      });
    }
    await login(page);
  });

  test(investigationTitle, async ({ page, browser }, info) => {
    const half = process.env.THREADLINE_PHASE250_PAIR_HALF;
    if (half !== "before" && half !== "after") throw new Error("Selected whole-investigation proof requires an explicit before/after half");
    const materialization = readInvestigationMaterialization();
    const snapshot = materialization.snapshot;
    const [action] = snapshot.actions as Array<Record<string, any>>;
    const [transaction] = snapshot.transactions as Array<Record<string, any>>;
    const replyChange = snapshot.changes.find((change: any) => change.table_name === rowTable) as any;
    const ticketChange = snapshot.changes.find((change: any) => change.table_name === "tickets") as any;
    expect(transaction.occurred_at).not.toBe(action.inserted_at);
    expect(replyChange.data_after.body).toBe("Thanks — we're closing this out.");
    expect(replyChange.data_after.internal_note_body).toBe("[REDACTED]");
    expect(ticketChange.data_after.status).toBe("closed");
    expect(ticketChange.data_after.closed_at).toBe("2026-05-26T14:30:00");

    const timelineUrl = investigationSearch();
    await page.goto(timelineUrl);
    await expectLiveViewConnected(page);
    const actualUrl = new URL(page.url());
    expect(actualUrl.pathname + actualUrl.search).toBe(timelineUrl);
    await expect(page.locator("#filter-from")).toHaveValue(investigationFrom);
    await expect(page.locator("#filter-to")).toHaveValue(investigationTo);
    await expect(page.locator("#filter-table")).toHaveValue(rowTable);
    await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);

    const selectedRow = page.getByTestId("timeline-row")
      .filter({ hasText: closeCorrelation })
      .filter({ hasText: rowTable });
    await expect(selectedRow).toHaveCount(1);
    await expect(selectedRow).toContainText("INSERT");
    const eventTime = await selectedRow.locator("time").getAttribute("datetime");
    expect(eventTime).not.toBeNull();
    expect(new Date(eventTime!).toISOString()).toBe("2026-05-26T14:30:00.000Z");
    const actorControl = selectedRow.locator(`[data-tl-copy="user/${closerId}"]`).first();
    await expect(actorControl).toBeVisible();
    await expect(actorControl).toHaveAttribute("data-tl-copy", `user/${closerId}`);

    const transactionLink = selectedRow.getByTestId("transaction-link");
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).not.toBeNull();
    const transactionUrl = new URL(transactionHref!, page.url());
    expect(transactionUrl.pathname).toBe(`/audit/transactions/${transaction.id}`);
    await transactionLink.click();
    await expect(page).toHaveURL(transactionUrl.toString());
    await expectLiveViewConnected(page);

    const transactionRows = page.getByTestId("transaction-change-row");
    await expect(transactionRows).toHaveCount(2);
    await expect(page.getByText("ticket_replied_and_closed", { exact: true })).toBeVisible();
    await expect(page.getByText("2 tables", { exact: true })).toBeVisible();
    await expect(page.getByText("2 changes", { exact: true })).toBeVisible();
    const actualChangeIds = await transactionRows.evaluateAll((rows) => rows.map((row) => row.id.replace(/^change-/, "")).sort());
    expect(actualChangeIds).toEqual(snapshot.changes.map((change: any) => change.id).sort());
    await captureInvestigationCheckpoint(page, browser, info, "transaction", "transaction-detail");

    const replyRow = transactionRows.filter({ hasText: rowTable });
    await expect(replyRow).toContainText("Thanks — we're closing this out.");
    await expect(replyRow).toContainText("[REDACTED]");
    const ticketRow = transactionRows.filter({ hasText: "tickets" });
    const statusField = ticketRow.locator(".tl-change__field").filter({ has: page.getByText("status", { exact: true }) });
    await expect(statusField.locator(".tl-diff__cell").last()).toContainText("closed");
    const closedAtField = ticketRow.locator(".tl-change__field").filter({ has: page.getByText("closed_at", { exact: true }) });
    await expect(closedAtField.locator(".tl-diff__cell").last()).toContainText("2026-05-26T14:30:00");
    const transactionRendered = await page.locator(".threadline-ui").evaluate((element) => {
      const values = [element.textContent ?? ""];
      for (const node of [element, ...Array.from(element.querySelectorAll("*"))]) {
        for (const attribute of Array.from(node.attributes)) values.push(attribute.value);
      }
      return values.join("\n");
    });
    expect(transactionRendered).not.toContain("synthetic-secret-canary-239-6f71");

    // The ticket's earlier state is reconstructed through its existing row-history route.
    const ticketHistoryLink = ticketRow.getByTestId("row-history-link");
    const ticketHistoryHref = await ticketHistoryLink.getAttribute("href");
    expect(ticketHistoryHref).not.toBeNull();
    const ticketHistoryUrl = new URL(ticketHistoryHref!, page.url());
    expect(ticketHistoryUrl.pathname).toBe(`/audit/transactions/${transaction.id}/history/tickets/${ticketChange.table_pk.id}`);
    await ticketHistoryLink.click();
    await expectPath(page, ticketHistoryUrl.pathname);
    await expectLiveViewConnected(page);
    const ticketDrawer = page.getByTestId("row-history-drawer");
    await expect(ticketDrawer).toBeVisible();
    const ticketHistoryTimes = await ticketDrawer.locator(".tl-subview__timeline li time").evaluateAll((nodes) => nodes.map((node) => (node as HTMLTimeElement).dateTime));
    const priorEventIndex = ticketHistoryTimes.findIndex((time) => new Date(time).getTime() < new Date(transaction.occurred_at).getTime());
    expect(priorEventIndex, "The seeded ticket must retain an earlier captured state for the before side of its close").toBeGreaterThanOrEqual(0);
    await ticketDrawer.locator(".tl-subview__timeline li").nth(priorEventIndex).getByRole("link").click();
    await expect.poll(() => new URL(page.url()).searchParams.get("as_of")).not.toBeNull();
    await expectLiveViewConnected(page);
    await expect(ticketDrawer.getByText("status", { exact: true })).toBeVisible();
    await expect(ticketDrawer.getByText("open", { exact: true })).toBeVisible();
    await expect(ticketDrawer.getByText("closed_at", { exact: true })).toBeVisible();
    await expect(ticketDrawer.getByText("null", { exact: true })).toBeVisible();
    await captureInvestigationCheckpoint(page, browser, info, "ticket-prior", "prior-ticket-history-snapshot");
    await ticketDrawer.getByRole("link", { name: "Close", exact: true }).click();
    await expectPath(page, `/audit/transactions/${transaction.id}`);
    await expectLiveViewConnected(page);

    if (half === "after") {
      const transactionReplyRow = page.getByTestId("transaction-change-row").filter({ hasText: rowTable });
      const transactionReplyHistoryLink = transactionReplyRow.getByTestId("row-history-link");
      const transactionReplyHistoryHref = await transactionReplyHistoryLink.getAttribute("href");
      expect(transactionReplyHistoryHref).not.toBeNull();
      const transactionReplyHistoryUrl = new URL(transactionReplyHistoryHref!, page.url());
      expect(transactionReplyHistoryUrl.pathname).toBe(`/audit/transactions/${transaction.id}/history/${rowTable}/${replyChange.table_pk.id}`);
      await transactionReplyHistoryLink.click();
      await expectPath(page, transactionReplyHistoryUrl.pathname);
      await expectLiveViewConnected(page);
      const strictHistory = page.getByTestId("row-history-drawer");
      await expect(strictHistory).toBeVisible();
      await expect(strictHistory).toContainText("Row timeline");
      await expect(strictHistory).toContainText("Thanks — we're closing this out.");
      await expect(strictHistory).toContainText("[REDACTED]");
      await captureInvestigationCheckpoint(page, browser, info, "reply-history", "transaction-origin-reply-history");

      const historyCopy = strictHistory.locator(`.tl-ref button[data-tl-copy="${replyChange.table_pk.id}"]`).first();
      await expect(historyCopy).toBeVisible();
      await historyCopy.focus();
      await page.keyboard.press("Enter");
      const historyStatus = historyCopy.locator("xpath=..").locator("[data-tl-copy-status]");
      await expect(historyStatus).toHaveText("Copying…");
      await expect(historyCopy).toBeFocused();
      const historyCalls = await page.evaluate(() => (window as any).__threadlinePhase250Clipboard.calls);
      expect(historyCalls).toEqual([{ value: replyChange.table_pk.id, trustedActivation: true }]);
      await page.evaluate(() => (window as any).__threadlinePhase250Clipboard.resolveNext());
      await expect(historyStatus).toHaveText("Copied.");
      await expect(historyCopy).toBeFocused();
      expect(await page.evaluate(() => (window as any).__threadlinePhase250Clipboard.fallbackCalls)).toBe(0);

      await strictHistory.getByRole("link", { name: "Close", exact: true }).click();
      await expectPath(page, `/audit/transactions/${transaction.id}`);
      await expectLiveViewConnected(page);
      const openTimeline = page.getByRole("link", { name: "Open timeline", exact: true }).first();
      await expect(openTimeline).toBeVisible();
      await openTimeline.click();
      await expectPath(page, "/audit/timeline");
      await expectLiveViewConnected(page);
      const expectedTimelineUrl = new URL(timelineUrl, page.url()).toString();
      await expect(page).toHaveURL(expectedTimelineUrl);
      for (const [selector, expected] of [["#filter-from", investigationFrom], ["#filter-to", investigationTo], ["#filter-table", rowTable], ["#filter-correlation-id", closeCorrelation]] as const) {
        await expect(page.locator(selector)).toHaveValue(expected);
      }
      const restoredRow = page.getByTestId("timeline-row")
        .filter({ hasText: closeCorrelation })
        .filter({ hasText: rowTable });
      await expect(restoredRow).toHaveCount(1);
    } else {

      // Legacy before evidence records the routes the current UI actually supports.
      // It is intentionally weaker than the required transaction-origin after route.
      const expectedTimelineUrl = new URL(timelineUrl, page.url()).toString();
      for (let step = 0; step < 8 && page.url() !== expectedTimelineUrl; step += 1) {
        await page.goBack();
        await expectLiveViewConnected(page);
      }
      await expect(page).toHaveURL(expectedTimelineUrl);
      await expect(page.locator("#filter-from")).toHaveValue(investigationFrom);
      await expect(page.locator("#filter-to")).toHaveValue(investigationTo);
      await expect(page.locator("#filter-table")).toHaveValue(rowTable);
      await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);

      const restoredRow = page.getByTestId("timeline-row")
        .filter({ hasText: closeCorrelation })
        .filter({ hasText: rowTable });
      const historyLink = restoredRow.getByTestId("timeline-row-history-link");
      const historyHref = await historyLink.getAttribute("href");
      expect(historyHref).not.toBeNull();
      const historyUrl = new URL(historyHref!, page.url());
      expect(historyUrl.pathname).toBe(`/audit/rows/${rowTable}/${replyChange.table_pk.id}`);
      expect(historyUrl.searchParams.get("origin")).toBe("timeline");
      for (const key of ["from", "to", "table", "correlation_id"] as const) {
        expect(historyUrl.searchParams.get(key)).toBe(new URL(timelineUrl, page.url()).searchParams.get(key));
      }
      await historyLink.click();
      await expectPath(page, historyUrl.pathname);
      await expectLiveViewConnected(page);
      const drawer = page.getByTestId("row-history-drawer");
      await expect(drawer).toBeVisible();
      await expect(drawer).toContainText("Row timeline");
      await expect(drawer).toContainText("Thanks — we're closing this out.");
      await expect(drawer).toContainText("[REDACTED]");
      await expect(drawer.locator("h3")).toHaveAttribute("title", `${rowTable} / ${replyChange.table_pk.id}`);
      const drawerEventTime = await drawer.locator("time").first().getAttribute("datetime");
      expect(drawerEventTime).not.toBeNull();
      expect(new Date(drawerEventTime!).toISOString()).toBe("2026-05-26T14:30:00.000Z");
      const drawerRendered = await drawer.evaluate((element) => {
        const values = [element.textContent ?? ""];
        for (const node of [element, ...Array.from(element.querySelectorAll("*"))]) {
          for (const attribute of Array.from(node.attributes)) values.push(attribute.value);
        }
        return values.join("\n");
      });
      expect(drawerRendered).not.toContain("synthetic-secret-canary-239-6f71");
      await captureInvestigationCheckpoint(page, browser, info, "reply-history", "timeline-origin-reply-history");

      await drawer.getByRole("link", { name: "Close", exact: true }).click();
      await expectPath(page, "/audit/timeline");
      await expectLiveViewConnected(page);
      expect(new URL(page.url()).search).toBe(new URL(timelineUrl, page.url()).search);
      await expect(page.locator("#filter-from")).toHaveValue(investigationFrom);
      await expect(page.locator("#filter-to")).toHaveValue(investigationTo);
      await expect(page.locator("#filter-table")).toHaveValue(rowTable);
      await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);
    }

    if (half === "before") {
      const copy = page.locator(`.tl-ref button[data-tl-copy="${replyChange.table_pk.id}"]`).first();
      await expect(copy).toBeVisible();
      await copy.focus();
      await page.keyboard.press("Enter");
      const status = copy.locator("xpath=..").locator("[data-tl-copy-status]");
      await expect(status).toHaveText("Copying…");
      await expect(copy).toBeFocused();
      await expect(copy).not.toHaveClass(/is-copied/);
      const calls = await page.evaluate(() => (window as any).__threadlinePhase250Clipboard.calls);
      expect(calls).toEqual([{ value: replyChange.table_pk.id, trustedActivation: true }]);
      await page.evaluate(() => (window as any).__threadlinePhase250Clipboard.resolveNext());
      await expect(status).toHaveText("Copied.");
      await expect(copy).toBeFocused();
      expect(await page.evaluate(() => (window as any).__threadlinePhase250Clipboard.fallbackCalls)).toBe(0);
    }

    const currentUrl = new URL(page.url());
    const filtersRestored = currentUrl.pathname === "/audit/timeline" &&
      currentUrl.searchParams.get("from") === investigationFrom && currentUrl.searchParams.get("to") === investigationTo &&
      currentUrl.searchParams.get("table") === rowTable && currentUrl.searchParams.get("correlation_id") === closeCorrelation;
    expect(filtersRestored).toBe(true);
    const journey = {
      timelineUrl: currentUrl.pathname + currentUrl.search,
      actionId: action.id,
      transactionId: transaction.id,
      changeIds: actualChangeIds,
      replyId: replyChange.table_pk.id,
      ticketId: ticketChange.table_pk.id,
      actorId: action.actor_ref.id,
      eventTime: transaction.occurred_at,
      actionInsertedAt: action.inserted_at,
      copyValue: replyChange.table_pk.id,
      copyStatus: "Copied.",
      keyboardActivation: true,
      filtersRestored,
      navigationMode: half === "before" ? "legacy-before" : "strict-after",
      copyContext: half === "before" ? "timeline" : "transaction-history",
      returnMode: half === "before" ? "browser-back" : "ui-links",
    };
    await captureInvestigationHalf(page, browser, info, journey);
  });

  test("Home record lookup reaches first-class row history", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);

    await page.goto("/audit");
    await expectLiveViewConnected(page);

    const form = page.locator("#tl-record-lookup");
    await expect(form).toBeVisible();
    await expect(form.getByLabel("Table")).toBeVisible();
    await expect(form.getByLabel("Record id")).toBeVisible();
    await form
      .locator('select[name="record_lookup[table]"]')
      .selectOption(rowTable);
    await form
      .locator('input[name="record_lookup[record_id]"]')
      .fill(ticketReplyRecordId);
    await form.getByRole("button", { name: "Open row history" }).click();

    await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText("Row history:")).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("direct first-class row-history route opens without a transaction first", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);

    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    await expectLiveViewConnected(page);

    await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await expect(drawer.getByText(`Row history: ${rowTable}`)).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("Timeline-origin row history preserves committed filters and safe return", async ({
    page,
  }) => {
    const from = "2020-01-01T00:00";
    const to = "2099-01-01T00:00";
    await page.goto(
      `/audit/timeline?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&table=${encodeURIComponent(rowTable)}`,
    );
    await expectLiveViewConnected(page);

    const rowHistoryLink = page
      .getByTestId("timeline-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("timeline-row-history-link");
    await expect(rowHistoryLink).toBeVisible();
    const href = await rowHistoryLink.getAttribute("href");
    expect(href).not.toBeNull();
    const rowHistoryUrl = new URL(href!, page.url());
    expect(rowHistoryUrl.searchParams.get("origin")).toBe("timeline");
    expect(rowHistoryUrl.searchParams.get("from")).toBe(from);
    expect(rowHistoryUrl.searchParams.get("to")).toBe(to);
    expect(rowHistoryUrl.searchParams.get("table")).toBe(rowTable);

    await rowHistoryLink.click();
    await expectPath(page, rowHistoryUrl.pathname);
    await expectLiveViewConnected(page);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();

    const asOf = "2026-10-10T10:00";
    await drawer.locator('input[name="as_of"]').fill(asOf);
    await expect
      .poll(() => new URL(page.url()).searchParams.get("as_of"))
      .toBe("2026-10-10T10:00:00Z");
    const selectedUrl = new URL(page.url());
    expect(selectedUrl.searchParams.get("origin")).toBe("timeline");
    expect(selectedUrl.searchParams.get("from")).toBe(from);
    expect(selectedUrl.searchParams.get("to")).toBe(to);
    expect(selectedUrl.searchParams.get("table")).toBe(rowTable);

    await drawer.getByRole("link", { name: "Close", exact: true }).click();
    await expectPath(page, "/audit/timeline");
    const returnUrl = new URL(page.url());
    expect(returnUrl.searchParams.get("from")).toBe(from);
    expect(returnUrl.searchParams.get("to")).toBe(to);
    expect(returnUrl.searchParams.get("table")).toBe(rowTable);
    expect(returnUrl.searchParams.has("origin")).toBe(false);
    await expect(page.locator("#filter-table")).toHaveValue(rowTable);
    await expectNoHorizontalOverflow(page);
  });

  test("Timeline-origin row history stays reachable at actual 200% zoom", async ({}, testInfo) => {
    test.skip(
      testInfo.project.name !== "desktop-chromium",
      "The real tab-zoom extension runs only in desktop-chromium",
    );

    await withIsolatedZoomContext(chromium, async (context, page) => {
      const baseURL = testInfo.project.use.baseURL ?? "http://127.0.0.1:4002";
      await page.goto(new URL("/users/log_in", String(baseURL)).toString());
      const form = page.locator("#login_form");
      await form.getByLabel("Email").fill(adminEmail);
      await form.getByLabel("Password").fill(password);
      await form.getByRole("button", { name: /log in/i }).click();
      await expect(page).toHaveURL(new URL("/", String(baseURL)).toString(), {
        timeout: 30_000,
      });

      await page.goto(
        new URL(
          `/audit/timeline?table=${encodeURIComponent(rowTable)}&correlation_id=${encodeURIComponent(closeCorrelation)}`,
          String(baseURL),
        ).toString(),
      );
      await expect(page.locator("[data-phx-main].phx-connected")).toBeVisible();
      const zoom = await setAndReadTabZoom(context, page);
      expect(zoom.zoomFactor).toBe(2);

      const rowHistoryLink = page
        .getByTestId("timeline-row")
        .filter({ hasText: rowTable })
        .first()
        .getByTestId("timeline-row-history-link");
      await expect(rowHistoryLink).toBeVisible();
      await rowHistoryLink.click();
      await expect(page.getByTestId("row-history-drawer")).toBeVisible();
      const drawerZoom = await setAndReadTabZoom(context, page);
      expect(drawerZoom.tabId).toBe(zoom.tabId);
      expect(drawerZoom.zoomFactor).toBe(2);
      await expect(
        page.getByTestId("row-history-drawer").getByRole("link", {
          name: "Close",
          exact: true,
        }),
      ).toBeVisible();
      await expect(
        page.getByTestId("row-history-drawer").locator('input[name="as_of"]'),
      ).toBeVisible();
      await expectNoHorizontalOverflow(page);
    });
  });

  test("transaction-origin row history returns to the same transaction", async ({
    page,
  }) => {
    await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
    await expectLiveViewConnected(page);
    const transactionLink = page
      .getByTestId("timeline-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("transaction-link");
    await expect(transactionLink).toBeVisible();
    const transactionHref = await transactionLink.getAttribute("href");
    expect(transactionHref).not.toBeNull();
    const transactionUrl = new URL(transactionHref!, page.url());
    const transactionId = transactionUrl.pathname.split("/").at(-1)!;

    await page.goto(transactionUrl.toString());
    await expect(page).toHaveURL(transactionUrl.toString());
    await expectLiveViewConnected(page);
    const rowHistoryLink = page
      .getByTestId("transaction-change-row")
      .filter({ hasText: rowTable })
      .first()
      .getByTestId("row-history-link");
    await expect(rowHistoryLink).toBeVisible();
    const href = await rowHistoryLink.getAttribute("href");
    expect(href).not.toBeNull();
    const rowHistoryUrl = new URL(href!, page.url());
    expect(rowHistoryUrl.pathname).toContain(
      `/audit/transactions/${transactionId}/history/`,
    );

    await rowHistoryLink.click();
    await expectPath(page, rowHistoryUrl.pathname);
    await expectLiveViewConnected(page);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer).toBeVisible();
    await drawer.locator('input[name="as_of"]').fill("2026-10-10T10:00");
    await expect
      .poll(() => new URL(page.url()).searchParams.get("as_of"))
      .toBe("2026-10-10T10:00:00Z");

    await drawer.getByRole("link", { name: "Close", exact: true }).click();
    await expectPath(page, `/audit/transactions/${transactionId}`);
    await expect(page.getByTestId("transaction-change-row").first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test("Home correlation lookup lands on Timeline correlation filter", async ({
    page,
  }) => {
    await page.goto("/audit");
    await expectLiveViewConnected(page);

    const form = page.locator("#tl-correlation-lookup");
    await expect(form).toBeVisible();
    await expect(form.getByLabel("Correlation id")).toBeVisible();
    await form
      .locator('input[name="correlation[correlation_id]"]')
      .fill(closeCorrelation);
    await form.getByRole("button", { name: "Open the timeline" }).click();

    await expectPath(page, "/audit/timeline");
    expect(new URL(page.url()).searchParams.get("correlation_id")).toBe(
      closeCorrelation,
    );
    await expect(page.locator("#filter-correlation-id")).toHaveValue(
      closeCorrelation,
    );
    await expectNoHorizontalOverflow(page);
  });

  test("filtered Timeline context carries into Exports", async ({
    page,
  }) => {
    await page.goto(
      `/audit/timeline?table=${encodeURIComponent(rowTable)}&correlation_id=${encodeURIComponent(
        closeCorrelation,
      )}`,
    );
    await expectLiveViewConnected(page);

    await expect(page.locator("#filter-correlation-id")).toHaveValue(
      closeCorrelation,
    );

    await page.getByRole("button", { name: "Filters" }).click();
    const filterDrawer = page.getByRole("dialog", { name: "Filters and handoff" });
    await expect(filterDrawer).toBeVisible();

    const carry = filterDrawer.getByRole("link", { name: "Carry to Exports" });
    await expect(carry).toBeVisible();
    await expect(carry).toHaveAttribute("href", /\/audit\/exports\?/);
    await carry.click();

    await expectPath(page, "/audit/exports");
    const url = new URL(page.url());
    expect(url.searchParams.get("table")).toBe(rowTable);
    expect(url.searchParams.get("correlation_id")).toBe(closeCorrelation);

    const context = page.getByTestId("timeline-export-context");
    await expect(context).toBeVisible();
    await expect(context.getByText("Timeline export context")).toBeVisible();
    await expect(context.locator("dt", { hasText: "table" })).toBeVisible();
    await expect(
      context.locator("dd", { hasText: rowTable }).locator(".tl-secondary-ref"),
    ).toHaveAttribute("data-tl-copy", rowTable);
    await expect(context.locator("dt", { hasText: "correlation_id" })).toBeVisible();
    await expect(
      context.locator("dd", { hasText: closeCorrelation }).locator(".tl-secondary-ref"),
    ).toHaveAttribute("data-tl-copy", closeCorrelation);
    await expect(context.locator("dt", { hasText: "source" })).toHaveCount(0);
    await expect(context.locator("dt", { hasText: "subject_ref_json" })).toHaveCount(0);
    await expectNoHorizontalOverflow(page);
  });

  test("filtered Evidence context carries into Exports", async ({
    page,
  }) => {
    await page.goto("/audit/evidence");
    await expectLiveViewConnected(page);

    const proofHistory = page
      .getByRole("link", { name: "View proof history" })
      .first();
    await expect(proofHistory).toBeVisible();
    await expect(proofHistory).toHaveAttribute(
      "href",
      /\/audit\/evidence\?.*mode=history/,
    );
    const proofHistoryHref = await proofHistory.getAttribute("href");
    expect(proofHistoryHref).not.toBeNull();
    await proofHistory.click();
    // The route updates in LiveView, but Playwright's browser transport loses its
    // page execution context after the same-document patch. Poll the local URL,
    // then use authenticated HTTP to inspect the rendered handoff and destination.
    await expect.poll(() => page.url()).toMatch(/\/audit\/evidence\?.*mode=history/);

    const historyUrl = new URL(page.url());
    expect(historyUrl.searchParams.get("mode")).toBe("history");
    expect(historyUrl.searchParams.get("subject")).toBe("export_delivery");
    expect(historyUrl.searchParams.get("subject_ref_json")).toBe(
      JSON.stringify({ export_id: "acme-4521-close", format: "csv" }),
    );

    const historyResponse = await page.context().request.get(historyUrl.toString());
    expect(historyResponse.status()).toBe(200);
    const historyHtml = await historyResponse.text();
    expect(historyHtml).toContain("append-only proof history");
    const carryLink = historyHtml.match(
      /<a\b[^>]*href="([^"]*\/audit\/exports\?[^"]+)"[^>]*>[\s\S]*?Carry to Exports[\s\S]*?<\/a>/,
    );
    expect(carryLink).not.toBeNull();
    const carryUrl = new URL(carryLink![1]!.replaceAll("&amp;", "&"), historyUrl);
    expect(carryUrl.pathname).toBe("/audit/exports");
    expect(carryUrl.searchParams.get("source")).toBe("evidence");
    expect(carryUrl.searchParams.get("mode")).toBe("history");
    expect(carryUrl.searchParams.get("subject")).toBe("export_delivery");
    expect(carryUrl.searchParams.get("subject_ref_json")).toBe(
      JSON.stringify({ export_id: "acme-4521-close", format: "csv" }),
    );

    const exportResponse = await page.context().request.get(carryUrl.toString());
    expect(exportResponse.status()).toBe(200);
    const exportHtml = await exportResponse.text();
    expect(exportHtml).toContain('data-testid="evidence-export-context"');
    expect(exportHtml).toContain("Evidence export context");
    expect(exportHtml).toContain("acme-4521-close");
  });
});


test("Phase251 retained-context recovery", async ({ page }) => {
  await installControlledClipboard(page);
  await login(page);
  const seeded = await seedPaths(page);
  const message = "Some Timeline filters could not be restored. Return to Timeline to choose filters before continuing.";
  const transactionPath = new URL(seeded.transaction, page.url()).pathname;
  const drawerPath = new URL(seeded.drawer, page.url()).pathname;
  for (const path of [transactionPath, seeded.row, drawerPath]) {
    await page.goto(`${path}?origin=timeline&unsupported_only=private-value`);
    const notice = page.getByTestId("timeline-context-loss");
    await expect(notice).toBeVisible();
    await expect(notice).toHaveText(message);
    const drawer = page.getByTestId("row-history-drawer");
    if (await drawer.isVisible()) {
      const close = drawer.getByRole("link", { name: "Close", exact: true });
      await close.focus();
      await page.evaluate("new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))");
      await expect(close).toBeFocused();
      expect(await page.evaluate(() => (window as any).__phase251CopyCounter.installed)).toBe(true);
      await page.keyboard.press("Enter");
    } else {
      await page.getByRole("navigation", { name: "Breadcrumb", exact: true }).getByRole("link", { name: "Timeline", exact: true }).click();
    }
    const recoveryPath = path === drawerPath ? transactionPath : "/audit/timeline";
    await expect.poll(() => new URL(page.url()).pathname).toBe(recoveryPath);
    expect(new URL(page.url()).searchParams.has("unsupported_only")).toBe(false);
    if (recoveryPath === transactionPath) {
      await page.getByRole("navigation", { name: "Breadcrumb", exact: true }).getByRole("link", { name: "Timeline", exact: true }).click();
      await expect.poll(() => new URL(page.url()).pathname).toBe("/audit/timeline");
    }
  }

  await page.goto(investigationSearch());
  const expected = [...new URL(page.url()).searchParams.entries()];
  await page.getByTestId("timeline-row").first().getByTestId("transaction-link").click();
  await expect(page.getByTestId("timeline-context-loss")).toHaveCount(0);
  await page.getByTestId("transaction-change-row").filter({ hasText: rowTable }).getByTestId("row-history-link").first().click();
  await expect(page.getByTestId("row-history-drawer")).toBeVisible();
  await expect(page.getByTestId("timeline-context-loss")).toHaveCount(0);
  await page.getByTestId("row-history-drawer").getByRole("link", { name: "Close", exact: true }).click();
  const timelineReturn = page.getByRole("navigation", { name: "Breadcrumb", exact: true }).getByRole("link", { name: "Timeline", exact: true });
  const returnHref = await timelineReturn.getAttribute("href");
  expect(returnHref).toBeTruthy();
  expect([...new URL(returnHref!, page.url()).searchParams.entries()]).toEqual(expected);
  await timelineReturn.click();
  await expect.poll(() => new URL(page.url()).pathname).toBe("/audit/timeline");
  expect([...new URL(page.url()).searchParams.entries()]).toEqual(expected);
  await expectNoHorizontalOverflow(page);
  expect(await page.evaluate(() => (window as any).__phase251CopyCounter.count)).toBe(0);
});


test("Phase251 standalone snapshot intent", async ({ page }) => {
  await installControlledClipboard(page);
  await login(page);
  const seeded = await seedPaths(page);
  const path = new URL(seeded.row, page.url()).pathname;
  const retained = "origin=timeline&from=&table=tickets";
  for (const value of ["not-a-date", "2026-02-30T12:00:00Z"]) {
    await page.goto(`${path}?${retained}&as_of=${encodeURIComponent(value)}`);
    const drawer = page.getByTestId("row-history-drawer");
    await expect(drawer.getByRole("alert")).toContainText("This snapshot time is invalid. Enter a valid date and time, or clear the field to view the latest snapshot.");
    await expect(drawer.getByRole("heading", { name: /^Snapshot as of/ })).toHaveCount(0);
    await expect(drawer.getByRole("link", { name: "Close", exact: true })).toBeFocused();
  }
  await page.goto(`${path}?${retained}&as_of=2026-05-26T16%3A30%3A00%2B02%3A00`);
  let drawer = page.getByTestId("row-history-drawer");
  await expect(drawer.getByRole("heading", { name: /^Snapshot as of/ }).locator("time")).toHaveAttribute("datetime", "2026-05-26T14:30:00Z");
  await page.reload();
  drawer = page.getByTestId("row-history-drawer");
  await drawer.getByLabel("View snapshot at", { exact: true }).fill("");
  await expect.poll(() => new URL(page.url()).searchParams.has("as_of")).toBe(false);
  expect(new URL(page.url()).searchParams.get("from")).toBe("");
  expect(new URL(page.url()).searchParams.get("table")).toBe("tickets");
  await expect(drawer.getByRole("heading", { name: /^Snapshot as of/ })).toBeVisible();
  await expectNoHorizontalOverflow(page);
  expect(await page.evaluate(() => (window as any).__phase251CopyCounter.count)).toBe(0);
});
