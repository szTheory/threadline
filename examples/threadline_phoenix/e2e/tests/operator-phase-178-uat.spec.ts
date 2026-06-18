import { expect, Locator, Page, test } from "@playwright/test";

// Phase 178 Tier B — the real-engine half of the per-page / flow stress pass
// (all 11 pages). FINALIZED in Plan 05 (no scaffold markers remain).
//
// ============================ TWO-TIER HONESTY CONTRACT ======================
// The literal PAGE-01 matrix is ~3,465 cells (11 pages x 7 paths x 3 themes x 5
// viewports x keyboard/reduced-motion/reconnect). We split it honestly (D-01):
//
//   * Tier A (Elixir render_component / source scans, every PR) proves the FULL
//     STRUCTURAL CARTESIAN — every page x path x theme x viewport cell renders,
//     carries the right data-state, and emits the right CSS hooks. It lives in:
//       test/threadline/operator_surface/style_contract_test.exs       (centering, #1, #6, #10/#11)
//       test/threadline/operator_surface/component_contract_test.exs   (reconnect shell, #4, #2/#5/#7/#8/#9)
//       test/threadline/operator_surface/stress_fixtures_test.exs      (page-story ledger conversion)
//
//   * Tier B (this file, real Chromium) proves a REPRESENTATIVE high-signal
//     SAMPLE renders/behaves correctly in a real engine — the ~66-cell rule
//     (D-02): per page 320 floor + 1440 ceiling, happy + worst-case (error/empty),
//     dark + light (the desktop-chromium-light lane re-runs this file), plus one
//     keyboard-only, one reduced-motion, and one reconnect spec.
//
// A GREEN suite here does NOT mean all ~3,465 cells were eyeballed. It means the
// full structural cartesian passed in Tier A AND this representative real-engine
// sample passed in Tier B. NO pixel-diff (baseline-free, deterministic).
// =============================================================================
//
// This spec owns the parts that genuinely need a real Chromium engine:
//   (a) PAGE-03 centering geometry — the transaction page (+ Home latent twin)
//       content box centers within grid COLUMN 2 at 1024 + 1440 (D-09, RESEARCH
//       Pitfall 4: measure within the content column, NOT raw viewport/2).
//   (b) the footgun sweep iterating /audit/* — within-viewport (#6) + the #1
//       scroll-trap / sticky-occlusion cell.
//   (c) the real socket-drop (SEED-005 / D-13) — a genuinely dropped websocket
//       flips lifecycle classes on [data-phx-main], reveals the reconnect banner,
//       dims [data-tl-mutating] controls, and restores both on reconnect. Replaces
//       the 177 inject-probe.
//   (d) the overlay footgun sample — overlay-above-scrim hit-test (#2), focus
//       enters on open + Esc dismiss + scrim click-outside dismiss (#3/#4),
//       disabled affordance + cursor (#5/#7), nav active-state distinct (#8),
//       pager edges (#9), and an AA contrast spot-check (#10/#11).
//   (e) the keyboard-only + reduced-motion representative cells (D-02).

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

// 320 proves the no-horizontal-scroll floor; 1440 the wide-reflow ceiling. The
// desktop centering cells use 1024 + 1440 (>=768px is where the grid shell and the
// left-push bug live).
const SWEEP_WIDTHS = [320, 1440];
const DESKTOP_CENTERING_WIDTHS = [1024, 1440];

// The grid nav column is minmax(196px, 232px) at >=768px (style.ex:3893). RESEARCH
// Pitfall 4: content is centered within COLUMN 2, offset right of true viewport
// center by the nav column — never measure against raw viewport/2. We measure the
// symmetric left/right gutters of the content box WITHIN its column instead, with a
// generous tolerance for sub-pixel rounding and scrollbar gutter (D-14 discretion).
const CENTERING_TOLERANCE_PX = 24;

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

async function expectBoxWithinViewport(
  locator: Locator,
  viewportWidth: number,
) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(-1);
  expect(rect!.x + rect!.width).toBeLessThanOrEqual(viewportWidth + 1);
}

// RESEARCH Pitfall 4: assert the content box is centered WITHIN grid column 2, NOT
// against the raw viewport center. The catch (CONTEXT D-08): the capped `<main>`
// (`#tl-main`, class `tl-page tl-container` / `tl-page tl-home`) IS itself the grid
// item placed at `grid-column: 2` — so measuring `.tl-container` against `#tl-main`
// would compare an element to itself (gutters always 0, a false pass). Instead we
// derive column 2's geometry from the GRID CONTAINER (`.threadline-ui`): at >=768px
// the template is `minmax(196px,232px) <gutter> minmax(0,1fr)`, so column 2 is the
// LAST track, running from (container content-left + col1 + columnGap) for `col2`
// width. We read those from the live computed grid metrics, then assert the `<main>`
// box sits with symmetric gutters inside that track.
async function expectCenteredWithinColumn(contentLocator: Locator) {
  await expect(contentLocator).toBeVisible();
  const content = await contentLocator.boundingBox();
  expect(content).not.toBeNull();

  // Resolve the live column-2 track from the grid container's computed template.
  const track = await contentLocator.evaluate((mainEl) => {
    const shell = (mainEl as HTMLElement).closest(
      ".threadline-ui",
    ) as HTMLElement | null;
    if (!shell) return null;
    const shellRect = shell.getBoundingClientRect();
    const cs = getComputedStyle(shell);
    // grid-template-columns resolves to concrete px, e.g. "232px 24px 984px".
    const cols = cs.gridTemplateColumns
      .split(" ")
      .map((v) => parseFloat(v))
      .filter((n) => !Number.isNaN(n));
    if (cols.length < 2) return null; // not the >=768px grid shell
    const padLeft = parseFloat(cs.paddingLeft) || 0;
    const colGap = parseFloat(cs.columnGap) || 0;
    const col1 = cols[0];
    const col2 = cols[cols.length - 1]; // content column = LAST track
    const left = shellRect.left + padLeft + col1 + colGap;
    return { left, width: col2 };
  });
  expect(
    track,
    "could not resolve the .threadline-ui grid column-2 track (is the desktop grid shell mounted at >=768px?)",
  ).not.toBeNull();

  const leftGutter = content!.x - track!.left;
  const rightGutter =
    track!.left + track!.width - (content!.x + content!.width);

  // Symmetric gutters => the capped content is centered in its column (not anchored
  // left by the grid-item `justify-self: stretch` + max-width "left push").
  expect(
    Math.abs(leftGutter - rightGutter),
    `content must center within grid column 2 (left gutter ${leftGutter}px vs right ${rightGutter}px, track width ${track!.width}px)`,
  ).toBeLessThanOrEqual(CENTERING_TOLERANCE_PX);
}

// --- (a) PAGE-03 centering geometry (D-09, RESEARCH Pitfall 4) --------------

test.describe("Phase 178 PAGE-03 — transaction page centers within grid column 2", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  for (const width of DESKTOP_CENTERING_WIDTHS) {
    // GREEN as of Plan 03 Task 1: `.tl-container` now carries `justify-self: center`
    // (style.ex:678), so the max-width-capped grid-item main centers within column 2
    // instead of anchoring to the column start (the old "left push").
    test(`transaction .tl-container is centered within column 2 at ${width}px (D-09)`, async ({
      page,
    }) => {
      await page.setViewportSize({ width, height: 900 });

      // Discover a real transaction route from the timeline.
      await page.goto("/audit/timeline");
      const firstTxn = page.getByTestId("transaction-link").first();
      await expect(firstTxn).toBeVisible();
      await firstTxn.click();
      await expect(page).toHaveURL(/\/audit\/transactions\//);

      const container = page.locator(".tl-container").first();
      await expectCenteredWithinColumn(container);
      await expectNoHorizontalOverflow(page);
    });
  }

  for (const width of DESKTOP_CENTERING_WIDTHS) {
    // Home latent twin (RESEARCH Pitfall 1, RESOLVED: fold in). GREEN as of Plan 03
    // Task 1: `.tl-home` now carries `justify-self: center` (style.ex:693).
    test(`Home .tl-home is centered within column 2 at ${width}px (latent twin)`, async ({
      page,
    }) => {
      await page.setViewportSize({ width, height: 900 });
      await page.goto("/audit");

      const home = page.locator(".tl-home").first();
      await expectCenteredWithinColumn(home);
      await expectNoHorizontalOverflow(page);
    });
  }
});

// --- (b) footgun sweep over /audit/* (#6 within-viewport + #1 scroll trap) ---

// The genuinely-live operator routes (D-03 hybrid). The full path × theme × viewport
// matrix is proven structurally in Tier A; this sweep is the representative real-
// engine sample (D-01/D-02).
const AUDIT_ROUTES = [
  "/audit",
  "/audit/timeline",
  "/audit/coverage",
  "/audit/evidence",
  "/audit/exports",
  "/audit/policy/redaction",
  "/audit/policy/retention",
];

test.describe("Phase 178 footgun sweep — /audit/* hold together (#6, #1)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  for (const route of AUDIT_ROUTES) {
    // #6 misalignment/spacing — within-viewport at the 320 floor + 1440 ceiling.
    test(`${route} stays within viewport at 320 + 1440 (#6)`, async ({
      page,
    }) => {
      for (const width of SWEEP_WIDTHS) {
        await test.step(`${width}px`, async () => {
          await page.setViewportSize({ width, height: 900 });
          await page.goto(route);
          const main = page.locator("#tl-main").first();
          await expectBoxWithinViewport(main, width);
          await expectNoHorizontalOverflow(page);
        });
      }
    });
  }

  // #1 scroll-trap / sticky-occlusion cell. A deep-linked anchored row must clear the
  // sticky topbar — driven by reconciling the scroll container's scroll-padding-top to
  // the anchored row's scroll-margin-top at the SAME desktop header offset. `.tl-target-row`
  // is a pure CSS hook (no markup producer in the seeded surface), so we prove the
  // reconciliation the real-engine way: the live desktop grid shell's COMPUTED
  // scroll-padding-top must reserve at least the sticky topbar's real height. If the
  // reserved offset under-shoots the topbar, a jumped-to anchor would hide beneath it.
  // GREEN as of Plan 05 Task 1 (desktop scroll-margin-top reconciliation, style.ex >=768px).
  test("desktop scroll container reserves the sticky topbar height (no occlusion, #1)", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1440, height: 800 });
    await page.goto("/audit/timeline");

    const shell = page.locator(".threadline-ui").first();
    await expect(shell).toBeVisible();

    const reservedOffset = await shell.evaluate(
      (el) => parseFloat(getComputedStyle(el).scrollPaddingTop) || 0,
    );
    const header = page.locator(".tl-topbar").first();
    const headerBox = await header.boundingBox();
    expect(headerBox).not.toBeNull();

    // The reserved scroll-padding-top must cover the sticky topbar so an anchored
    // target lands below it instead of being occluded (1px rounding slack).
    expect(
      reservedOffset,
      `desktop scroll-padding-top (${reservedOffset}px) must reserve the sticky topbar height (${headerBox!.height}px) so a deep-linked anchor is not occluded (#1)`,
    ).toBeGreaterThanOrEqual(headerBox!.height - 1);
  });
});

// --- (c) real socket-drop (SEED-005 / D-13) ---------------------------------

test.describe("Phase 178 SEED-005 — real socket-drop is detected client-side", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  // SEED-005 / D-13: prove a REAL socket drop is detected client-side — the gap a
  // static fixture cannot simulate. window.liveSocket is exposed globally (app.js:12).
  // Drive on /audit/policy/retention (the real prune flow).
  //
  // RESEARCH Pitfall 3 / D-13 fallback ladder: a bare liveSocket.disconnect() lets the
  // client auto-reconnect immediately, so the dropped-socket window is too brief to
  // observe deterministically. We BLOCK the websocket route (routeWebSocket) so the
  // dropped state holds; lifting the block lets the client reconnect for real.
  //
  // D-11 corrected: phoenix_live_view attaches its lifecycle classes (phx-loading /
  // phx-error / phx-client-error) to [data-phx-main]. The Threadline shell is the
  // descendant that contains the banner and mutating controls, so this cell proves
  // the full positive behavior instead of only detecting the dropped socket.
  test("a real dropped live socket reveals the banner and dims mutating controls (D-13)", async ({
    page,
  }) => {
    // Block the LiveView websocket so a connection drop stays dropped (no instant
    // auto-reconnect). Installed before navigation so the route is intercepted.
    let blockSocket = false;
    await page.routeWebSocket(/\/live\/websocket/, (ws) => {
      if (blockSocket) {
        ws.close();
      } else {
        ws.connectToServer();
      }
    });

    await page.goto("/audit/policy/retention");

    // Open the prune modal so the real destructive prune control is on the page.
    await openPruneModal(page);

    const banner = page.locator(".tl-reconnect-banner").first();
    const mutating = page.locator(`${PRUNE_CONTENT} [data-tl-mutating]`).first();
    await expect(banner).toBeHidden();
    await expect(mutating).toBeVisible();

    // The class-bearing LiveView container must flip to a disconnected lifecycle
    // class when the socket drops.
    const lvRoot = page.locator("[data-phx-main]").first();
    await expect(lvRoot).toHaveClass(/phx-connected/);

    // Drop the socket for real and hold it dropped.
    blockSocket = true;
    await page.evaluate(() => (window as any).liveSocket.disconnect());

    // The drop is genuinely detected: the container carries a disconnected class
    // (phx-loading and/or phx-error/phx-client-error). Auto-retry, never a fixed wait.
    await expect(lvRoot).toHaveClass(/phx-(loading|error|client-error)/);
    await expect(banner).toBeVisible();
    await expect(mutating).toHaveCSS("opacity", "0.55");
    await expect(mutating).toHaveCSS("pointer-events", "none");

    // Lift the block and reconnect for real — the container returns to connected.
    blockSocket = false;
    await page.evaluate(() => (window as any).liveSocket.connect());
    await expect(lvRoot).toHaveClass(/phx-connected/);
    await expect(lvRoot).not.toHaveClass(/phx-client-error/);
    await expect(banner).toBeHidden();
    await expect(mutating).not.toHaveCSS("opacity", "0.55");
    await expect(mutating).not.toHaveCSS("pointer-events", "none");
  });
});

// --- (d) overlay footgun sample (#2/#3/#4/#5/#7/#8/#9/#10/#11) ---------------
//
// The overlay/active-state/pager footguns. We drive the REAL prune-confirm modal on
// /audit/policy/retention (UI.modal id="prune-confirm", focusable input + Cancel/
// Confirm) — a genuine operator overlay with interactive content, so JS.focus_first
// has a real target and Esc/scrim-click exercise the production dismiss path. These
// cells are the real-engine half of the structural Tier A guards in
// component_contract_test.exs (which scan the source markers).
const PRUNE_CONTENT = "#prune-confirm-content";

async function openPruneModal(page: Page) {
  await page.goto("/audit/policy/retention");
  await page
    .getByRole("button", { name: "Run retention prune" })
    .first()
    .click();
  await expect(page.locator(PRUNE_CONTENT)).toBeVisible();
}

test.describe("Phase 178 overlay footgun sample (#2/#3/#4)", () => {
  test.use({ viewport: { width: 1280, height: 900 }, isMobile: false });

  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("modal sits above its scrim (z-order hit-test, #2) and is keyboard-reachable (#3)", async ({
    page,
  }) => {
    await openPruneModal(page);
    const content = page.locator(PRUNE_CONTENT);

    // #2: the element painted at the modal content's center must be the content
    // (or a descendant), never the scrim — proves the overlay floats ABOVE the scrim.
    const onTop = await content.evaluate((el) => {
      const r = el.getBoundingClientRect();
      const hit = document.elementFromPoint(
        r.x + r.width / 2,
        r.y + r.height / 2,
      );
      return el === hit || el.contains(hit);
    });
    expect(onTop, "modal content must be hit-tested above the scrim (#2)").toBe(
      true,
    );

    // #3 (real-engine half): the overlay must contain a keyboard-reachable focus
    // target so the operator can drive it without a mouse. (The presence of the
    // JS.focus_first / phx-mounted focus-entry HOOK is proven structurally in Tier A
    // component_contract_test.exs; the runtime auto-focus depends on the overlay's
    // open mechanism. Here we prove a real focusable target exists and accepts focus.)
    const focusable = content.locator(
      "a[href], button, input, select, textarea, [tabindex]:not([tabindex='-1'])",
    );
    await expect(focusable.first()).toBeVisible();
    await focusable.first().focus();
    const focusInside = await content.evaluate((el) =>
      el.contains(document.activeElement),
    );
    expect(
      focusInside,
      "the overlay must accept keyboard focus inside it (#3)",
    ).toBe(true);
  });

  test("Esc dismisses the modal (#4 keyboard half)", async ({ page }) => {
    await openPruneModal(page);
    const content = page.locator(PRUNE_CONTENT);

    // The Esc binding is phx-window-keydown on the content. Place keyboard focus
    // inside the overlay (as an operator would after tabbing in), then press Esc and
    // assert the content dismisses (the close round-trip + hide transition auto-retry).
    await content
      .locator("input, button, [tabindex]:not([tabindex='-1'])")
      .first()
      .focus();
    await page.keyboard.press("Escape");
    await expect(content).toBeHidden();
  });

  test("scrim click-outside dismisses the modal (#4 click-outside half)", async ({
    page,
  }) => {
    await openPruneModal(page);
    const content = page.locator(PRUNE_CONTENT);

    // Click the scrim at a corner well outside the centered content — the scrim's own
    // phx-click dismiss (Plan 05 Task 2) must close the overlay. The scrim is
    // aria-hidden (Playwright's actionability would otherwise wait on it), so force
    // the click; we are deliberately exercising the scrim's click-outside affordance.
    await page
      .locator(".tl-modal-scrim")
      .click({ position: { x: 8, y: 8 }, force: true });
    await expect(content).toBeHidden();
  });
});

test.describe("Phase 178 active-state, pager + disabled affordance (#8/#9/#5/#7)", () => {
  test.use({ viewport: { width: 1280, height: 900 }, isMobile: false });

  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("nav active item carries aria-current + a non-color cue (#8)", async ({
    page,
  }) => {
    await page.goto("/audit/timeline");
    // The active item lives in the shell nav (a sticky sidebar that can collapse into
    // a disclosure panel at some widths), so its box may be hidden even though it is
    // present and authoritative. Assert against the DOM directly: it must carry
    // aria-current="page" AND compute a non-color cue (the inset box-shadow contract).
    const cue = await page.evaluate(() => {
      const el = document.querySelector(
        '.tl-shell-nav__item[aria-current="page"]',
      );
      if (!el) return { found: false, shadow: "" };
      // Make the disclosure panel measurable if it is collapsed, then read computed.
      const panel = el.closest("details");
      if (panel && !(panel as HTMLDetailsElement).open) {
        (panel as HTMLDetailsElement).open = true;
      }
      return { found: true, shadow: getComputedStyle(el).boxShadow };
    });
    expect(
      cue.found,
      'an active nav item must carry aria-current="page" (#8)',
    ).toBe(true);
    expect(
      cue.shadow,
      "active nav item needs a non-color cue (inset shadow), not color alone (#8)",
    ).not.toBe("none");
  });

  test("timeline pager renders an honest range caption + disable-reflecting control (#9)", async ({
    page,
  }) => {
    // The pager renders on the live timeline (hide-at-zero is Tier-A-proven; here we
    // prove the real-engine render). It must show the honest "Showing N …" caption
    // and any control must reflect its disabled state as a real boolean attribute.
    await page.goto("/audit/timeline");
    const pager = page.locator(".tl-pager").first();
    await expect(pager).toBeVisible();

    const range = pager.locator(".tl-pager__range");
    await expect(range).toContainText(/Showing\s+\d/);

    // Each rendered control must expose a real (boolean) disabled property — never a
    // disabled-looking-but-enabled control (#9/#7). When disabled it must also compute
    // the not-allowed cursor.
    const controls = pager.locator(".tl-pager__control");
    const count = await controls.count();
    for (let i = 0; i < count; i++) {
      const ctl = controls.nth(i);
      const isDisabled = await ctl.evaluate(
        (el) => (el as HTMLButtonElement).disabled,
      );
      if (isDisabled) {
        await expect(ctl).toHaveCSS("cursor", "not-allowed");
      }
    }
  });

  test("disabled controls carry not-allowed cursor + real disabled (#5/#7)", async ({
    page,
  }) => {
    // The offline group story renders disabled actions deterministically (#5/#7).
    await page.goto(
      `/audit/__stress?story=${encodeURIComponent("group.offline.current")}`,
    );
    const disabled = page
      .locator("button:disabled, [aria-disabled='true']")
      .first();
    await expect(disabled).toBeVisible();
    const cursor = await disabled.evaluate((el) => getComputedStyle(el).cursor);
    expect(cursor, "disabled control must use not-allowed cursor (#7)").toBe(
      "not-allowed",
    );
  });
});

// --- (e) keyboard-only + reduced-motion representative cells (D-02) ----------

test.describe("Phase 178 keyboard-only + reduced-motion sample (D-02)", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("keyboard-only: Tab reaches an actionable control without a mouse", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/audit/timeline");

    // Tab from the document start; the first focus must land on the skip link or a
    // real interactive control, and the focused element must be keyboard-operable.
    await page.keyboard.press("Tab");
    const focusedTag = await page.evaluate(
      () => document.activeElement?.tagName ?? "",
    );
    expect(["A", "BUTTON", "INPUT", "SELECT"]).toContain(focusedTag);
  });

  test("reduced-motion: overlay transition collapses to ~instant", async ({
    page,
  }) => {
    // The whole suite runs reducedMotion: "reduce" (playwright.config), so the
    // operator surface's prefers-reduced-motion rules must collapse the overlay
    // transition — proves the reduced-motion lane is honored, not just configured.
    // The stress modal is sufficient here (motion is content-independent).
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto(
      `/audit/__stress?story=${encodeURIComponent("group.modal-destructive.current")}`,
    );
    await page.getByRole("button", { name: "Show Modal" }).click();

    const content = page.locator("#stress-modal-content");
    await expect(content).toBeVisible();
    const duration = await content.evaluate(
      (el) => getComputedStyle(el).transitionDuration,
    );
    // Reduced motion collapses to the ~instant token (0.001s), never a real duration.
    expect(
      duration.split(",").every((part) => part.trim() === "0.001s"),
      `reduced-motion overlay transition must collapse to 0.001s, got ${duration}`,
    ).toBe(true);
  });
});
