import { chromium, expect, test, type Locator, type Page, type WebSocketRoute } from "@playwright/test";
import { randomUUID } from "node:crypto";
import { login, seedPaths, startEvidence } from "../support/operator-browser-evidence.js";
import { setAndReadTabZoom, withIsolatedZoomContext } from "../support/operator-tab-zoom.js";

// Passing this suite means observed states have source-bound evidence. Existing
// product failures are recorded for the later refinement phases, not repaired here.
test.use({ trace: "off", screenshot: "off", contextOptions: { reducedMotion: "reduce" } });
test.beforeEach(async ({}, info) => {
  if ([
    "Timeline delayed query exposes pending then real empty result with a long unbroken filter",
    "Timeline keeps populated query identity while an applied replacement is pending",
    "real host denial under Acme support is distinct from busy and disabled",
    "saved searches keep canonical sharing, long summaries, and destructive actions reachable",
    "saved search actions stay in bounds at verified 200% browser zoom",
    "actor and correlation pivots re-enter Timeline with only their supported filters",
    "Timeline pagination appends the next page without changing the applied search URL",
    "Clipboard success waits for confirmation on direct entry and after patches",
    "Clipboard failure shows manual recovery without claiming success",
    "Clipboard fallback confirms success and restores focus and selection",
    "Copy feedback fits long URLs and redacted values stay non-copyable",
  ].includes(info.title)) return;
  test.skip(process.env.THREADLINE_E2E_EVIDENCE !== "1" || !["desktop-chromium", "desktop-chromium-light"].includes(info.project.name), "Bounded evidence lanes only");
});

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(1);
}

function copyStatus(control: Locator) {
  return control.locator("xpath=..").locator("[data-tl-copy-status]");
}

test("theme preference, effective cascade and reduced motion are distinct observed facts", async ({ page, browser }, info) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await login(page);
  const e = await startEvidence(page, browser, info);
  await page.goto("/audit");
  const light = info.project.name === "desktop-chromium-light";
  const reducedDuration = await page.locator(".tl-home__card").first().evaluate((el) => getComputedStyle(el).animationDuration);
  expect(reducedDuration).toBe("0.001s");
  const initial = await e.capture("state.theme.initial", "/audit", "initial-theme", { reducedDuration });
  expect(initial.mountedTheme).toBe(light ? "system" : "dark");
  expect(initial.preference).toBe(light ? "system" : "dark");
  expect(initial.effectiveTheme).toBe(light ? "light" : "dark");
  expect(initial.background).toBe(light ? "rgb(247, 249, 252)" : "rgb(11, 16, 32)");
  expect(initial.reducedMotion).toBe(true);
  expect(initial.resolvedValues["--tl-color-bg"]).toBeTruthy();
  for (const preference of ["light", "dark", "system"]) {
    await page.locator(`input[name="theme"][value="${preference}"]`).check();
    await page.getByRole("button", { name: "Apply theme" }).click();
    await expect(page.locator(".threadline-ui")).toHaveAttribute("data-tl-theme", preference);
    const observed = await e.capture(`state.theme.${preference}`, "/audit", `preference-${preference}`);
    expect(observed.preference).toBe(preference);
    expect(observed.effectiveTheme).toBe(preference === "system" ? (observed.osLight ? "light" : "dark") : preference);
  }
  e.finish("state.theme", "/audit", "theme-and-motion");
});

for (const [name, path] of [["Evidence", "/audit/evidence"], ["Exports", "/audit/exports?table=tickets&correlation_id=walk-acme-4521-close"], ["Retention", "/audit/policy/retention"]]) {
  test(`fresh direct-entry Copy on ${name}: completion or binding failure is observed`, async ({ page, context, browser }, info) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await login(page);
    const e = await startEvidence(page, browser, info);
    // No prior operator navigation in this context may preload delegated handlers.
    await page.goto(path);
    const copy = page.locator("button[data-tl-copy]").first();
    await expect(copy).toBeVisible();
    const value = await copy.getAttribute("data-tl-copy");
    expect(value).toBeTruthy();
    await page.evaluate(() => navigator.clipboard.writeText("threadline-evidence-sentinel"));
    await copy.click();
    const observed = await page.evaluate(async () => ({ clipboardMatches: await navigator.clipboard.readText() !== "threadline-evidence-sentinel", handlerBound: Boolean((window as any).__tlCopyBound), copiedFeedback: Boolean(document.querySelector("button[data-tl-copy].is-copied")) }));
    const clipboard = await page.evaluate(() => navigator.clipboard.readText());
    const exactMatch = clipboard === value;
    await e.capture(`state.copy.${name.toLowerCase()}`, path, exactMatch ? "copy-completed" : "copy-did-not-complete", { ...observed, exactMatch, rank: exactMatch ? "covered" : "high", ownerPhase: 242, deniedClipboardLimitation: !observed.handlerBound ? "No handler attempts clipboard access on fresh entry; denial handling cannot be exercised through this control." : "Browser permission failure is probed separately on the bound Timeline control." });
    e.finish(`state.copy.${name.toLowerCase()}`, path, exactMatch ? "copy-completed" : "copy-did-not-complete");
  });
}

test("bound Timeline Copy observes exact completion and real denied permission separately", async ({ page, context, browser }, info) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await login(page);
  const e = await startEvidence(page, browser, info);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  const copy = page.locator("button[data-tl-copy]").first();
  await expect(copy).toBeVisible();
  const expected = await copy.getAttribute("data-tl-copy");
  await copy.click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(expected);
  await e.capture("state.clipboard.completed", "/audit/timeline", "copy-completed", { exactMatch: true });
  const cdp = await context.newCDPSession(page);
  await context.clearPermissions();
  const { targetInfo } = await cdp.send("Target.getTargetInfo");
  await cdp.send("Browser.setPermission", { permission: { name: "clipboard-write", allowWithoutSanitization: true }, setting: "denied", origin: new URL(page.url()).origin, browserContextId: targetInfo.browserContextId });
  const permission = await page.evaluate(async () => (await navigator.permissions.query({ name: "clipboard-write" as PermissionName })).state);
  await copy.click();
  await e.capture("state.clipboard.denied", "/audit/timeline", permission === "denied" ? "clipboard-permission-denied" : "clipboard-denial-probe-unavailable", { permission, copiedFeedback: await copy.evaluate((el) => el.classList.contains("is-copied")), limitation: permission === "denied" ? "Legacy execCommand fallback may succeed despite Clipboard API denial; this is not proof of failed fallback or truthful failure feedback." : "This Chromium context does not report denied after permission clear and context-specific Browser.setPermission denied. Actual clipboard denial remains unverified; no denial pass claimed." });
  e.finish("state.clipboard", "/audit/timeline", "clipboard-completed-and-denial-probe");
});

test("Clipboard success waits for confirmation on direct entry and after patches", async ({ page }) => {
  await page.addInitScript(() => {
    const probe = {
      calls: [] as Array<{ value: string; userActivation: boolean }>,
      pending: [] as Array<() => void>,
      resolveNext() {
        this.pending.shift()?.();
      },
    };
    (window as any).__threadlineCopyProbe = probe;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText(value: string) {
          probe.calls.push({ value, userActivation: (navigator as any).userActivation?.isActive === true });
          return new Promise<void>((resolve) => probe.pending.push(resolve));
        },
      },
    });
  });

  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const copy = page.locator("button[data-tl-copy]").first();
  await expect(copy).toBeVisible();
  const expected = await copy.getAttribute("data-tl-copy");
  expect(expected).toBeTruthy();
  await copy.click();

  const status = copyStatus(copy);
  await expect(status).toHaveText("Copying…");
  expect(await copy.evaluate((element) => element.classList.contains("is-copied"))).toBe(false);
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.calls)).toEqual([
    { value: expected, userActivation: true },
  ]);

  await page.evaluate(() => (window as any).__threadlineCopyProbe.resolveNext());
  await expect(status).toHaveText("Copied.");
  await expect(copy).toHaveClass(/is-copied/);

  await page.locator("#filter-table").fill("ticket_replies");
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect(page).toHaveURL(/table=ticket_replies/);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const patchedCopy = page.locator("button[data-tl-copy]").first();
  const patchedExpected = await patchedCopy.getAttribute("data-tl-copy");
  await patchedCopy.click();
  const patchedStatus = copyStatus(patchedCopy);
  await expect(patchedStatus).toHaveText("Copying…");
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.calls)).toHaveLength(2);
  await page.evaluate(() => (window as any).__threadlineCopyProbe.resolveNext());
  await expect(patchedStatus).toHaveText("Copied.");
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.calls[1])).toEqual({
    value: patchedExpected,
    userActivation: true,
  });
});

test("Clipboard failure shows manual recovery without claiming success", async ({ page }) => {
  await page.addInitScript(() => {
    const probe = { fallbackCalls: 0 };
    (window as any).__threadlineCopyProbe = probe;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: () => Promise.reject(new DOMException("denied", "NotAllowedError")) },
    });
    document.execCommand = () => {
      probe.fallbackCalls += 1;
      return false;
    };
  });

  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  const copy = page.locator("button[data-tl-copy]").first();
  await expect(copy).toBeVisible();
  const expected = await copy.getAttribute("data-tl-copy");
  await copy.click();

  const status = copyStatus(copy);
  await expect(status).toHaveText("Copy failed. Select the value and copy it manually.");
  await expect(status).toHaveAttribute("role", "status");
  await expect(status).toHaveAttribute("aria-live", "polite");
  await expect(copy).not.toHaveClass(/is-copied/);
  await expect(copy).toBeFocused();
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.fallbackCalls)).toBe(1);
  await expect(page.locator("textarea[data-tl-copy-fallback]")).toHaveCount(0);
  await expect(status).not.toContainText(expected ?? "");
});

test("Clipboard fallback confirms success and restores focus and selection", async ({ page }) => {
  await page.addInitScript(() => {
    const probe = { fallbackCalls: 0 };
    (window as any).__threadlineCopyProbe = probe;
    Object.defineProperty(navigator, "clipboard", { configurable: true, value: undefined });
    document.execCommand = () => {
      probe.fallbackCalls += 1;
      return true;
    };
  });

  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const source = page.locator(".tl-ref .tl-secondary-ref").first();
  await expect(source).toBeVisible();
  const selected = await source.evaluate((element) => {
    const range = document.createRange();
    range.selectNodeContents(element);
    const selection = window.getSelection()!;
    selection.removeAllRanges();
    selection.addRange(range);
    return range.toString();
  });
  expect(selected).not.toBe("");
  await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
  await expect.poll(() => page.evaluate(() => window.getSelection()?.toString())).toBe(selected);

  const copy = source.locator("xpath=..").locator("button[data-tl-copy]").first();
  await copy.click();
  await expect(copyStatus(copy)).toHaveText("Copied.");
  await expect(copy).toBeFocused();
  await expect.poll(() => page.evaluate(() => window.getSelection()?.toString())).toBe(selected);
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.fallbackCalls)).toBe(1);
  await expect(page.locator("textarea[data-tl-copy-fallback]")).toHaveCount(0);
});

test("Copy feedback fits long URLs and redacted values stay non-copyable", async ({ page }) => {
  await page.addInitScript(() => {
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: () => Promise.resolve() },
    });
  });

  await login(page);
  const correlation = `copy-long-${"x".repeat(180)}`;
  const appliedUrl = `/audit/timeline?table=ticket_replies&correlation_id=${encodeURIComponent(correlation)}`;
  await page.goto(appliedUrl);
  await page.getByRole("button", { name: "Filters", exact: true }).click();
  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  const copySearch = drawer.getByRole("button", { name: "Copy search URL", exact: true });
  await expect(copySearch).toHaveAttribute("data-tl-copy", appliedUrl);
  await expect(copyStatus(copySearch)).toHaveCount(1);
  await copySearch.click();
  const status = copyStatus(copySearch);
  await expect(status).toHaveText("Copied.");
  await expectNoHorizontalOverflow(page);

  const geometry = await page.evaluate(() => {
    const button = document.querySelector('button[aria-label="Copy search URL"]')!;
    const status = button.parentElement!.querySelector<HTMLElement>("[data-tl-copy-status]")!;
    const buttonRect = button.getBoundingClientRect();
    const statusRect = status.getBoundingClientRect();
    return {
      overlaps: buttonRect.left < statusRect.right && buttonRect.right > statusRect.left && buttonRect.top < statusRect.bottom && buttonRect.bottom > statusRect.top,
      statusInsideViewport: statusRect.left >= 0 && statusRect.right <= document.documentElement.clientWidth + 1,
      statusText: status.textContent,
    };
  });
  expect(geometry.overlaps).toBe(false);
  expect(geometry.statusInsideViewport).toBe(true);
  expect(geometry.statusText).toBe("Copied.");

  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await page.getByTestId("timeline-row").first().getByTestId("transaction-link").click();
  const reference = page.locator(".tl-ref").filter({ has: page.locator("button[data-tl-copy]") }).first();
  const referenceCopy = reference.locator("button[data-tl-copy]").first();
  await expect(referenceCopy).toBeVisible();
  await referenceCopy.click();
  await expect(copyStatus(referenceCopy)).toHaveText("Copied.");
  await expectNoHorizontalOverflow(page);
  const referenceGeometry = await reference.evaluate((element) => {
    const value = element.querySelector(".tl-secondary-ref")!;
    const button = element.querySelector("button[data-tl-copy]")!;
    const status = element.querySelector<HTMLElement>("[data-tl-copy-status]")!;
    const rect = (node: Element) => node.getBoundingClientRect();
    const valueRect = rect(value);
    const buttonRect = rect(button);
    const statusRect = rect(status);
    const overlaps = (a: DOMRect, b: DOMRect) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
    return {
      overlapsValue: overlaps(valueRect, statusRect),
      overlapsButton: overlaps(buttonRect, statusRect),
      statusInsideViewport: statusRect.left >= 0 && statusRect.right <= document.documentElement.clientWidth + 1,
    };
  });
  expect(referenceGeometry).toEqual({ overlapsValue: false, overlapsButton: false, statusInsideViewport: true });

  await page.goto("/audit/timeline?table=ticket_replies");
  const redactedUpdate = page
    .getByTestId("timeline-row")
    .filter({ hasText: "UPDATE" })
    .filter({ hasText: "ticket_replies" })
    .first();
  await redactedUpdate.getByTestId("transaction-link").click();
  const redacted = page.locator(".tl-value--redacted").first();
  await expect(redacted).toBeVisible();
  const cell = redacted.locator("xpath=ancestor::div[contains(@class, 'tl-diff__cell')]");
  await expect(cell.locator("[data-tl-copy]")).toHaveCount(0);
  await expect(page.locator('button[data-tl-copy="[REDACTED]"]')).toHaveCount(0);
  await expect(page.locator("#tl-main")).not.toContainText("Internal: route to tier-2");
  await expect(page.locator("#tl-main")).not.toContainText("Confirmed tier-2 resolved. Closing.");
  await expect(
    page.locator("[data-tl-copy-status]").filter({ hasText: "Internal: route to tier-2" }),
  ).toHaveCount(0);
});

test("Exports seeded pending, failed, completed, unavailable and invalid context stay distinct", async ({ page, browser }, info) => {
  await login(page);
  const e = await startEvidence(page, browser, info);
  await page.goto("/audit/exports");
  const jobs = page.getByTestId("export-jobs");
  for (const heading of ["Ready to hand off", "Preparing", "Needs attention", "Unavailable"]) await expect(jobs.getByRole("heading", { name: heading, exact: true })).toBeVisible();
  await expect(jobs.getByText("Export failed.").first()).toBeVisible();
  await expect(jobs.getByRole("link", { name: "Download export" }).first()).toBeVisible();
  await e.capture("state.exports.seeded", "/audit/exports", "seeded-pending-failed-completed-unavailable", { stateSource: "Demo.Seed.Exports synthetic jobs; not a newly completed mutation" });
  await page.goto("/audit/exports?subject_type=invalid&subject_ref_json=%7B");
  await expect(page.locator("#tl-main [role=alert]").first()).toBeVisible();
  await e.capture("state.exports.invalid", "/audit/exports?subject_type=invalid&subject_ref_json=%7B", "invalid-context-alert");
  e.finish("state.exports", "/audit/exports", "seeded-status-and-invalid-context");
});

test("Timeline delayed query exposes pending then real empty result with a long unbroken filter", async ({ page, browser }, info) => {
  let hold = false;
  let held: { server: WebSocketRoute; message: string | Buffer } | undefined;
  await page.routeWebSocket(/\/live\/websocket/, (ws) => {
    const server = ws.connectToServer();
    ws.onMessage((message) => {
      if (hold && String(message).includes('"event"')) held = { server, message };
      else server.send(message);
    });
  });
  await login(page);
  const e = process.env.THREADLINE_E2E_EVIDENCE === "1" ? await startEvidence(page, browser, info) : undefined;
  await page.goto("/audit/timeline");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const long = "unmatched_correlation_" + "x".repeat(210);
  const filter = page.locator("#filter-correlation-id");
  await filter.fill(long);
  hold = true;
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect.poll(() => Boolean(held)).toBe(true);
  await expect(page.locator("#timeline-filters")).toHaveClass(/phx-submit-loading/);
  await expect(page.locator("#timeline-filters").getByRole("button", { name: "Applying filters…", exact: true })).toBeVisible();
  if (e) await e.capture("state.timeline.pending", "/audit/timeline", "delayed-query-pending", { requestHeld: true, longValueLength: long.length, priorDataRetained: await page.getByTestId("timeline-row").count() });
  hold = false;
  held!.server.send(held!.message);
  await expect(page.locator("#timeline-filters")).not.toHaveClass(/phx-submit-loading/);
  await expect(page.getByTestId("timeline-row")).toHaveCount(0);
  await expect(page.getByRole("heading", { name: "No changes match these filters", exact: true })).toBeVisible();
  await expect(page.locator("#tl-main")).toContainText("Adjust the time range or filters, then apply again.");
  await expect(filter).toHaveValue(long);
  expect(long).toHaveLength(232);
  await page.setViewportSize({ width: 375, height: 900 });
  if (e) {
    await e.capture("state.timeline.empty-long", "/audit/timeline", "empty-long-filter-narrow", { longValueLength: long.length, fullValueRetained: await filter.inputValue() === long });
    e.finish("state.timeline", "/audit/timeline", "delayed-empty-long-value");
  }
});

test("Timeline keeps populated query identity while an applied replacement is pending", async ({ page }) => {
  let hold = false;
  let held: { server: WebSocketRoute; message: string | Buffer } | undefined;
  await page.routeWebSocket(/\/live\/websocket/, (ws) => {
    const server = ws.connectToServer();
    ws.onMessage((message) => {
      if (hold && String(message).includes('"event"')) held = { server, message };
      else server.send(message);
    });
  });

  await login(page);
  await seedPaths(page);
  const queryA = "walk-acme-4521-close";
  await page.goto(`/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&correlation_id=${queryA}`);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByTestId("timeline-row").first()).toBeVisible();
  const queryARowCount = await page.getByTestId("timeline-row").count();
  expect(queryARowCount).toBeGreaterThan(0);
  await expect(page.locator(".tl-filter-summary")).toContainText(queryA);

  const queryB = "timeline-query-b-" + "x".repeat(215);
  expect(queryB).toHaveLength(232);
  await page.locator("#filter-correlation-id").fill(queryB);
  hold = true;
  const apply = page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true });
  await apply.click();
  await expect.poll(() => Boolean(held)).toBe(true);

  await expect(page.locator("#timeline-filters")).toHaveClass(/phx-submit-loading/);
  await expect(page.locator("#timeline-filters").getByRole("button", { name: "Applying filters…", exact: true })).toBeVisible();
  await expect(page.getByTestId("timeline-row")).toHaveCount(queryARowCount);
  await expect(page.locator(".tl-filter-summary")).toContainText(queryA);
  await expect(page.locator(".tl-filter-summary")).not.toContainText(queryB);
  await expect(page.locator("#timeline-filters").getByRole("button", { name: "Applying filters…", exact: true })).toBeVisible();

  hold = false;
  held!.server.send(held!.message);
  await expect(page.getByTestId("timeline-row")).toHaveCount(0);
  await expect(page.locator(".tl-filter-summary")).toContainText(queryB);
  await expect(page.getByRole("heading", { name: "No changes match these filters", exact: true })).toBeVisible();
  await expect(page.locator("#tl-main")).toContainText("Adjust the time range or filters, then apply again.");
  await expect(page.locator("#filter-correlation-id")).toHaveValue(queryB);
  const completedApply = page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true });
  await expect(completedApply).toBeVisible();
  await expect(completedApply.locator("svg")).toHaveCount(1);
});

for (const input of ["pointer", "keyboard"] as const) {
  test(`offline Exports ${input} activation and reconnect record actual mutation outcome`, async ({ page, browser }, info) => {
    let block = false;
    await page.routeWebSocket(/\/live\/websocket/, (ws) => block ? ws.close() : ws.connectToServer());
    await login(page);
    const e = await startEvidence(page, browser, info);
    const path = "/audit/exports?table=tickets";
    await page.goto(path);
    const root = page.locator("[data-phx-main]");
    await expect(root).toHaveClass(/phx-connected/);
    const queue = page.getByRole("button", { name: "Queue Timeline export" });
    await expect(queue).toBeVisible();
    const count = await page.getByRole("link", { name: "Reopen source search" }).count();
    block = true;
    await page.evaluate(() => (window as any).liveSocket.disconnect());
    await expect(root).toHaveClass(/phx-(loading|error|client-error)/);
    await expect(page.locator(".tl-reconnect-banner")).toBeVisible();
    const before = await queue.evaluate((el) => ({ disabled: (el as HTMLButtonElement).disabled, ariaDisabled: el.getAttribute("aria-disabled"), mutationMarker: el.hasAttribute("data-tl-mutating"), pointerEvents: getComputedStyle(el).pointerEvents }));
    if (input === "pointer") await queue.click({ timeout: 3000 });
    else { await queue.focus(); await page.keyboard.press("Enter"); }
    await e.capture(`state.offline.${input}`, path, "offline-export-activation", { input, ...before, rank: before.disabled || before.ariaDisabled === "true" ? "covered" : "high", ownerPhase: 241 }, false);
    block = false;
    await page.evaluate(() => (window as any).liveSocket.connect());
    await expect(root).toHaveClass(/phx-connected/);
    await expect(page.locator(".tl-reconnect-banner")).toBeHidden();
    await page.waitForLoadState("networkidle");
    const after = await page.getByRole("link", { name: "Reopen source search" }).count();
    expect(after - count).toBeGreaterThanOrEqual(0);
    expect(after - count, "One offline activation must not create duplicate jobs").toBeLessThanOrEqual(1);
    await e.capture(`state.reconnect.${input}`, path, "reconnected-export-outcome", { input, jobsBefore: count, jobsAfter: after, observedAddedJobs: after - count, completionClaim: false, limitation: "A queued job is not a completed export; observe seeded completion separately." });
    e.finish(`state.offline.${input}`, path, "offline-reconnect");
  });
}

test("Retention keyboard Escape focus return and Chromium touch navigation are observed", async ({ page, browser }, info) => {
  await login(page);
  const e = await startEvidence(page, browser, info);
  await page.goto("/audit/policy/retention");
  const prune = page.getByRole("button", { name: "Run retention prune" }).last();
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await prune.focus();
  await page.keyboard.press("Enter");
  const dialog = page.locator("#prune-confirm");
  await expect(dialog).toBeVisible();
  const focusedInside = await dialog.evaluate((el) => el.contains(document.activeElement));
  await e.capture("state.focus.open", "/audit/policy/retention", "keyboard-confirmation-open", { focusedInside });
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  const returned = await prune.evaluate((el) => el === document.activeElement);
  await e.capture("state.focus.return", "/audit/policy/retention", "escape-focus-return", { returned, rank: returned ? "covered" : "high", ownerPhase: 242 });
  e.finish("state.focus", "/audit/policy/retention", "keyboard-focus-return");
  const touchContext = await browser.newContext({ baseURL: new URL(page.url()).origin, viewport: { width: 375, height: 900 }, hasTouch: true, reducedMotion: "reduce", colorScheme: info.project.name.endsWith("light") ? "light" : "dark" });
  try {
    const touch = await touchContext.newPage();
    await login(touch);
    const te = await startEvidence(touch, browser, info);
    await touch.goto("/audit");
    const toggle = touch.locator(".tl-shell-nav__toggle");
    await expect(toggle).toBeVisible();
    await toggle.tap();
    await expect(touch.locator(".tl-shell-nav__panel")).toBeVisible();
    await te.capture("state.touch.nav", "/audit", "chromium-touch-nav-open", { input: "emulated-touch", physicalDevice: false });
    te.finish("state.touch", "/audit", "touch-navigation");
  } finally { await touchContext.close(); }
});

test("real host denial under Acme support is distinct from busy and disabled", async ({ page, browser }, info) => {
  const unauthenticated = await page.request.get("/audit/timeline?correlation_id=walk-acme-4521-close", { maxRedirects: 0 });
  expect(unauthenticated.status()).toBe(302);
  expect(unauthenticated.headers().location).toContain("/users/log_in");

  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  await page.locator("#login_form").getByLabel("Email").fill("support@acme.example.com");
  await page.locator("#login_form").getByLabel("Password").fill(process.env.DEMO_SEED_PASSWORD ?? "password123456");
  await page.locator("#login_form").getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL(/\/(?:audit\/timeline(?:\?[^#]*)?)?$/);
  const e = process.env.THREADLINE_E2E_EVIDENCE === "1"
    ? await startEvidence(page, browser, info, "seeded-support-acme-read-only")
    : undefined;
  await page.goto("/audit/timeline");
  await expect(page.locator("#timeline-filters")).toBeVisible();
  const denied = await page.request.get("/audit/exports/changes.csv");
  expect(denied.status()).toBe(403);
  await expect(page).toHaveURL(/\/audit\/timeline(?:\?|$)/);
  if (e) {
    await e.capture("state.denied", "/audit/timeline", "real-export-http-denied", { httpStatus: denied.status(), role: "Acme support read-only", scopeDecision: "host callback", timelineAllowed: true, unauthenticatedTimelineStatus: unauthenticated.status(), notPending: true });
    e.finish("state.denied", "/audit/timeline", "real-host-denial");
  }
});

test("saved searches keep canonical sharing, long summaries, and destructive actions reachable", async ({ page }) => {
  await login(page);
  const id = randomUUID();
  const correlation = `saved-search-${id}-` + "x".repeat(170);
  const name = `Escalation review ${"weekly priorities ".repeat(9)}${id}`;
  const appliedUrl = `/audit/timeline?table=ticket_replies&correlation_id=${encodeURIComponent(correlation)}`;

  await page.goto(appliedUrl);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);

  // Edits that have not been applied remain drafts; sharing still describes the URL query.
  await page.locator("#filter-table").fill("draft_table_should_not_be_shared");
  await page.locator("#filter-correlation-id").fill("draft-correlation-should-not-be-shared");

  const filters = page.getByRole("button", { name: "Filters", exact: true });
  await filters.click();
  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  await expect(drawer).toBeVisible();
  await expect(drawer.getByRole("region", { name: "Saved searches" })).toBeVisible();
  await expect(drawer).toContainText("This URL shares the applied filters. Results and access are determined by the receiving host.");

  const copySearch = drawer.getByRole("button", { name: "Copy search URL", exact: true });
  await expect(copySearch).toHaveAttribute("data-tl-copy", appliedUrl);
  await drawer.locator("#save-view-form").getByLabel("Saved search name").fill(name);
  await drawer.getByRole("button", { name: "Save search", exact: true }).click();

  const applySavedSearch = drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true });
  await expect(applySavedSearch).toBeVisible();
  const savedItem = applySavedSearch.locator("xpath=ancestor::li");
  await expect(savedItem.locator(".tl-saved-search__summary")).toContainText(correlation);
  const deleteSavedSearch = savedItem.getByRole("button", { name: `Delete ${name}`, exact: true });
  await expect(deleteSavedSearch).toBeVisible();

  // Change the committed query, then resume the saved search through Timeline validation.
  await drawer.getByRole("button", { name: "Close", exact: true }).click();
  await expect(drawer).toBeHidden();
  await page.locator("#filter-correlation-id").fill("replacement-correlation");
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect(page).toHaveURL(/correlation_id=replacement-correlation/);
  await filters.click();
  await expect(drawer).toBeVisible();
  await drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true }).click();
  await expect.poll(() => {
    const current = new URL(page.url());
    return `${current.pathname}${current.search}`;
  }).toBe(appliedUrl);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);

  await page.setViewportSize({ width: 375, height: 900 });
  await expect(drawer).toBeVisible();
  await expectNoHorizontalOverflow(page);
  await expect(drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true })).toBeVisible();
  await expect(drawer.getByRole("button", { name: `Delete ${name}`, exact: true })).toBeVisible();

  await drawer.getByRole("button", { name: `Delete ${name}`, exact: true }).click();
  const confirmation = page.getByRole("dialog", { name: "Delete saved search" });
  await expect(confirmation).toContainText(`Delete saved search “${name}”? This removes it from your saved searches.`);
  await confirmation.getByRole("button", { name: "Keep saved search", exact: true }).click();
  await expect(confirmation).toBeHidden();

  await drawer.getByRole("button", { name: `Delete ${name}`, exact: true }).click();
  await page.getByRole("dialog", { name: "Delete saved search" }).getByRole("button", { name: "Delete search", exact: true }).click();
  await expect(drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true })).toHaveCount(0);
});

test("saved search actions stay in bounds at verified 200% browser zoom", async ({}, info) => {
  test.skip(info.project.name !== "desktop-chromium", "The actual tab-zoom proof runs in desktop Chromium");

  await withIsolatedZoomContext(chromium, async (context, page) => {
    const baseURL = String(info.project.use.baseURL ?? "http://127.0.0.1:4002");
    await page.goto(new URL("/users/log_in", baseURL).toString(), { waitUntil: "domcontentloaded" });
    const loginForm = page.locator("#login_form");
    await loginForm.getByLabel("Email").fill("admin@example.com");
    await loginForm.getByLabel("Password").fill(process.env.DEMO_SEED_PASSWORD ?? "password123456");
    await loginForm.getByRole("button", { name: /log in/i }).click();
    await expect(page).toHaveURL(new URL("/", baseURL).toString());

    const correlation = `zoom-saved-search-${randomUUID()}-` + "z".repeat(170);
    const name = `Zoom support search ${"unusual naming ".repeat(9)}${randomUUID()}`;
    await page.goto(new URL(`/audit/timeline?table=ticket_replies&correlation_id=${encodeURIComponent(correlation)}`, baseURL).toString());
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const zoom = await setAndReadTabZoom(context, page);
    expect(zoom.zoomFactor).toBe(2);

    await page.getByRole("button", { name: "Filters", exact: true }).click();
    const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
    await expect(drawer).toBeVisible();
    await drawer.locator("#save-view-form").getByLabel("Saved search name").fill(name);
    await drawer.getByRole("button", { name: "Save search", exact: true }).click();
    const apply = drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true });
    const remove = drawer.getByRole("button", { name: `Delete ${name}`, exact: true });
    await expect(apply).toBeVisible();
    await expect(remove).toBeVisible();
    await expectNoHorizontalOverflow(page);

    const controlsInsideViewport = await Promise.all([apply, remove].map((control) => control.evaluate((element) => {
      const rect = element.getBoundingClientRect();
      return rect.left >= 0 && rect.right <= document.documentElement.clientWidth + 1;
    })));
    expect(controlsInsideViewport).toEqual([true, true]);
    await expect(drawer.locator(".tl-saved-search__summary").filter({ hasText: correlation })).toBeVisible();
  });
});

test("actor and correlation pivots re-enter Timeline with only their supported filters", async ({ page }) => {
  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.getByTestId("timeline-row").first()).toBeVisible();

  const row = page.getByTestId("timeline-row").first();
  const correlationLink = row.getByTitle("View correlated changes in Timeline");
  const actorLink = row.getByTitle("View actor activity");
  const correlationHref = await correlationLink.getAttribute("href");
  const actorHref = await actorLink.getAttribute("href");
  expect(correlationHref).toMatch(/^\/audit\/timeline\?correlation_id=/);
  expect(actorHref).toMatch(/^\/audit\/actors\/(?:user|admin|service_account|job|system)\//);

  await correlationLink.click();
  await expect.poll(() => new URL(page.url()).searchParams.get("correlation_id")).toBe("walk-acme-4521-close");
  await expect(page.locator("#filter-correlation-id")).toHaveValue("walk-acme-4521-close");
  await expect(page.locator("#tl-main")).not.toContainText("incident/walk-acme-4521-close");

  await page.goto(actorHref!);
  await expect(page.getByRole("heading", { name: "Actor activity", exact: true })).toBeVisible();
  await page.getByRole("link", { name: "Open timeline", exact: true }).first().click();
  await expect(page).toHaveURL(/\/audit\/timeline\?actor_kind=[^&]+&actor_id=/);
  const actorQuery = new URL(page.url()).searchParams;
  expect(actorQuery.get("actor_kind")).toBeTruthy();
  expect(actorQuery.get("actor_id")).toBeTruthy();
  expect([...actorQuery.keys()].sort()).toEqual(["actor_id", "actor_kind"]);
  await expect(page.locator("#filter-correlation-id")).toHaveValue("");
});

test("Timeline pagination appends the next page without changing the applied search URL", async ({ page }) => {
  await login(page);
  const appliedUrl = "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=tickets";
  await page.goto(appliedUrl);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const rows = page.getByTestId("timeline-row");
  await expect(rows).toHaveCount(50);
  const pager = page.getByRole("navigation", { name: "Timeline pagination" });
  await expect(pager).toContainText(/Showing 50 of [\d,]+ matching changes/);
  const older = pager.getByRole("button", { name: "Older", exact: true });
  await expect(older).toBeEnabled();

  const before = await rows.first().getAttribute("id");
  await older.click();
  await expect.poll(() => rows.count()).toBeGreaterThan(50);
  const shownCount = await rows.count();
  const range = (await pager.innerText()).match(/Showing ([\d,]+) of ([\d,]+) matching changes/);
  expect(range).not.toBeNull();
  expect(Number(range![1].replaceAll(",", ""))).toBe(shownCount);
  expect(Number(range![2].replaceAll(",", ""))).toBeGreaterThan(shownCount);
  await expect.poll(() => {
    const current = new URL(page.url());
    return `${current.pathname}${current.search}`;
  }).toBe(appliedUrl);
  expect(await rows.first().getAttribute("id")).toBe(before);

  const rowMotion = await rows.first().evaluate((element) => {
    const style = getComputedStyle(element);
    return { animationName: style.animationName, animationDuration: style.animationDuration, animationDelay: style.animationDelay };
  });
  expect(rowMotion.animationName).toBe("none");
  expect(rowMotion.animationDelay.split(",").every((delay) => Number.parseFloat(delay) === 0)).toBe(true);
});
