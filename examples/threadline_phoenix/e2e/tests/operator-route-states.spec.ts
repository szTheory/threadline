import { expect, test, type WebSocketRoute } from "@playwright/test";
import { login, seedPaths, startEvidence } from "../support/operator-browser-evidence.js";

// Passing this suite means observed states have source-bound evidence. Existing
// product failures are recorded for the later refinement phases, not repaired here.
test.use({ trace: "off", screenshot: "off", contextOptions: { reducedMotion: "reduce" } });
test.beforeEach(async ({}, info) => {
  if ([
    "Timeline delayed query exposes pending then real empty result with a long unbroken filter",
    "Timeline keeps populated query identity while an applied replacement is pending",
    "real host denial under Acme support is distinct from busy and disabled",
  ].includes(info.title)) return;
  test.skip(process.env.THREADLINE_E2E_EVIDENCE !== "1" || !["desktop-chromium", "desktop-chromium-light"].includes(info.project.name), "Bounded evidence lanes only");
});

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
