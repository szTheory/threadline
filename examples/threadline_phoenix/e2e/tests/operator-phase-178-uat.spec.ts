import { expect, Locator, Page, test } from "@playwright/test";

// Phase 178 Tier B scaffold — the real-engine half of the per-page / flow stress
// pass (all 11 pages). The fast, deterministic Tier A halves live in the core lib:
//   test/threadline/operator_surface/style_contract_test.exs       (centering, #1, #6, contrast)
//   test/threadline/operator_surface/component_contract_test.exs   (reconnect shell, #4, #5/#7/#8/#9)
//   test/threadline/operator_surface/stress_fixtures_test.exs      (page-story ledger conversion)
//
// This spec owns the parts that genuinely need a real Chromium engine:
//   (a) PAGE-03 centering geometry — the transaction page (+ Home latent twin)
//       content box centers within grid COLUMN 2 at 1024 + 1440 (D-09, RESEARCH
//       Pitfall 4: measure within the content column, NOT raw viewport/2).
//   (b) the footgun sweep iterating /audit/* — within-viewport (#6) + the #1
//       scroll-trap / sticky-occlusion cell.
//   (c) the real socket-drop (SEED-005 / D-13) — window.liveSocket.disconnect()
//       reveals the real .tl-reconnect-banner and dims [data-tl-mutating]; reconnect
//       re-enables. Replaces the 177 inject-probe.
//
// Many cells assert behaviour that Wave 0 has NOT yet built (centering, mounted
// banner, scrim dismiss). Those are marked test.fixme so the scaffold is RED-by-
// design without failing CI for unbuilt surface — the centering and socket-drop
// specs are AUTHORED (real assertions), never empty stubs, so the later waves flip
// fixme -> active against a real check. NO pixel-diff (baseline-free, deterministic).
//
// Sampling (D-02, the ~66-cell high-signal rule): 320 floor + 1440 ceiling, happy +
// worst-case (error/empty), dark + light (the desktop-chromium-light lane re-runs
// this file), one keyboard-only, one reduced-motion (global reducedMotion: "reduce"),
// one reconnect. The lanes are wired via the existing playwright projects.

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

async function expectBoxWithinViewport(locator: Locator, viewportWidth: number) {
  await expect(locator).toBeVisible();
  const rect = await locator.boundingBox();
  expect(rect).not.toBeNull();
  expect(rect!.x).toBeGreaterThanOrEqual(-1);
  expect(rect!.x + rect!.width).toBeLessThanOrEqual(viewportWidth + 1);
}

// RESEARCH Pitfall 4: assert the content box is centered WITHIN its grid column
// (symmetric gutters between the content box and the column edges), not against the
// raw viewport center. `columnLocator` is the grid column 2 region the content sits
// in (#tl-main's grid cell); `contentLocator` is the capped .tl-container / .tl-home.
async function expectCenteredWithinColumn(
  contentLocator: Locator,
  columnLocator: Locator,
) {
  await expect(contentLocator).toBeVisible();
  const content = await contentLocator.boundingBox();
  const column = await columnLocator.boundingBox();
  expect(content).not.toBeNull();
  expect(column).not.toBeNull();

  const leftGutter = content!.x - column!.x;
  const rightGutter = column!.x + column!.width - (content!.x + content!.width);

  // Symmetric gutters => the capped content is centered in its column (not anchored
  // left by the grid-item `justify-self: stretch` + max-width "left push").
  expect(
    Math.abs(leftGutter - rightGutter),
    `content must center within its grid column (left gutter ${leftGutter}px vs right ${rightGutter}px)`,
  ).toBeLessThanOrEqual(CENTERING_TOLERANCE_PX);
}

// --- (a) PAGE-03 centering geometry (D-09, RESEARCH Pitfall 4) --------------

test.describe("Phase 178 PAGE-03 — transaction page centers within grid column 2", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  for (const width of DESKTOP_CENTERING_WIDTHS) {
    // RED until Plan 03 adds `justify-self: center` to .tl-container (D-09): today
    // the max-width-capped main is a grid item anchored to the column start (left).
    test.fixme(
      `transaction .tl-container is centered within column 2 at ${width}px (D-09)`,
      async ({ page }) => {
        await page.setViewportSize({ width, height: 900 });

        // Discover a real transaction route from the timeline.
        await page.goto("/audit/timeline");
        const firstTxn = page.getByTestId("transaction-link").first();
        await expect(firstTxn).toBeVisible();
        await firstTxn.click();
        await expect(page).toHaveURL(/\/audit\/transactions\//);

        const container = page.locator(".tl-container").first();
        const column = page.locator("#tl-main").first();
        await expectCenteredWithinColumn(container, column);
        await expectNoHorizontalOverflow(page);
      },
    );
  }

  for (const width of DESKTOP_CENTERING_WIDTHS) {
    // Home latent twin (RESEARCH Pitfall 1, RESOLVED: fold in). RED until Plan 03
    // adds `justify-self: center` to .tl-home (style.ex:689).
    test.fixme(
      `Home .tl-home is centered within column 2 at ${width}px (latent twin)`,
      async ({ page }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto("/audit");

        const home = page.locator(".tl-home").first();
        const column = page.locator("#tl-main").first();
        await expectCenteredWithinColumn(home, column);
        await expectNoHorizontalOverflow(page);
      },
    );
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
    test(`${route} stays within viewport at 320 + 1440 (#6)`, async ({ page }) => {
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

  // #1 scroll-trap / sticky-occlusion cell on the worst-case (densest) page. The
  // sticky topbar must never occlude an anchored/focused target: after scrolling to
  // an anchored row, the row's top must sit BELOW the sticky header's bottom (the
  // reconciled scroll-padding-top / scroll-margin-top offset, Tier A #1 half). RED
  // until Plan 04 reconciles the desktop offset (style.ex:2647 desktop override).
  test.fixme(
    "timeline sticky header never occludes an anchored row after scroll (#1)",
    async ({ page }) => {
      await page.setViewportSize({ width: 1440, height: 800 });
      await page.goto("/audit/timeline");

      // Body still scrolls (no nested-scroll trap); overscroll-behavior:contain holds
      // the inner region (verified in Tier A source scan; here we assert the body is
      // the scroll surface and the anchored target clears the sticky header).
      const firstTxn = page.getByTestId("transaction-link").first();
      await expect(firstTxn).toBeVisible();
      await firstTxn.click();
      await expect(page).toHaveURL(/\/audit\/transactions\//);

      // Navigate to an in-page anchor (a target row) and assert it is not occluded.
      const target = page.locator(".tl-target-row").first();
      await target.scrollIntoViewIfNeeded();

      const header = page.locator(".tl-topbar").first();
      const headerBox = await header.boundingBox();
      const targetBox = await target.boundingBox();
      expect(headerBox).not.toBeNull();
      expect(targetBox).not.toBeNull();

      // The anchored target's top must clear the sticky header's bottom — otherwise
      // the header occludes the row the operator just jumped to.
      expect(
        targetBox!.y,
        "anchored target must sit below the sticky header bottom (no occlusion)",
      ).toBeGreaterThanOrEqual(headerBox!.y + headerBox!.height - 1);
    },
  );
});

// --- (c) real socket-drop (SEED-005 / D-13) ---------------------------------

test.describe("Phase 178 SEED-005 — real socket-drop reveals reconnect banner", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  // RED until SEED-005 (Plan 05) mounts the banner in the shared shell and wires
  // [data-tl-mutating] onto the real prune control. window.liveSocket is exposed
  // globally (app.js:12). Drive on /audit/policy/retention (the real prune flow).
  test.fixme(
    "liveSocket.disconnect() reveals .tl-reconnect-banner and dims [data-tl-mutating]; reconnect re-enables",
    async ({ page }) => {
      await page.goto("/audit/policy/retention");

      // Open the prune modal so the real destructive prune control is on the page.
      const prune = page
        .getByRole("button", { name: "Run retention prune" })
        .last();
      await expect(prune).toBeVisible();
      await prune.click();

      const mutating = page.locator("[data-tl-mutating]").first();
      await expect(mutating).toBeVisible();

      // Drop the socket for real — exercises the genuine .phx-error / .phx-loading
      // class path on the .threadline-ui render root (D-11), the gap a fixture
      // cannot simulate.
      await page.evaluate(() => (window as any).liveSocket.disconnect());

      // RESEARCH Pitfall 3: the banner reveals on EITHER .phx-loading or .phx-error
      // (style.ex reveals on both). Use auto-retry, never a fixed wait.
      await expect(page.locator(".tl-reconnect-banner")).toBeVisible();
      await expect(mutating).toHaveCSS("pointer-events", "none");
      await expect(mutating).toHaveCSS("opacity", "0.55");

      // Reconnect — banner hides, control re-enables.
      await page.evaluate(() => (window as any).liveSocket.connect());
      await expect(page.locator(".tl-reconnect-banner")).toBeHidden();
      await expect(mutating).not.toHaveCSS("pointer-events", "none");

      // Fallback ladder (D-13) if disconnect() does not reliably set .phx-error:
      //   await page.context().setOffline(true);
      //   await page.routeWebSocket("**/live/**", (ws) => ws.close());
    },
  );
});
