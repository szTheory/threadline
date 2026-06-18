import { expect, Locator, Page, test } from "@playwright/test";

// Shift-left automation of the Phase 177 human-verification items (177-UAT.md).
// The fast, deterministic DOM/contract halves of UAT #2 and UAT #4 live in the core
// lib at test/threadline/operator_surface/component_contract_test.exs. This spec owns
// the parts that genuinely need a real browser:
//   UAT #1 — the 12 component-group stories hold together at every viewport (320..1440).
//   UAT #3 — overlay enter motion + prefers-reduced-motion collapse.
//   UAT #4 — the reconnect/offline CSS contract actually computes in a browser engine.

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

// The 12 Phase 177 group stories (stress_fixtures.ex @group_stories).
const groupStories = [
  "group.page-header.current",
  "group.toolbar.current",
  "group.data-panel.current",
  "group.stats-chart-table.current",
  "group.detail-header.current",
  "group.modal-destructive.current",
  "group.drawer-form.reference",
  "group.toast-update.current",
  "group.tabs-subviews.reference",
  "group.empty-cta.current",
  "group.permission-denied.current",
  "group.offline.current",
];

// 320 proves the no-horizontal-scroll floor; 1440 the wide end. Matches the
// viewports the manual UAT enumerated (stress_fixtures.ex @viewports).
const viewportWidths = [320, 375, 768, 1024, 1440];

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

async function transitionDuration(locator: Locator): Promise<string> {
  await expect(locator).toBeVisible();
  return locator.evaluate((el) => getComputedStyle(el).transitionDuration);
}

function expectEveryDuration(
  value: string,
  predicate: (part: string) => boolean,
  message: string,
) {
  const parts = value.split(",").map((part) => part.trim());
  expect(parts.length, `expected at least one duration in "${value}"`).toBeGreaterThan(0);
  expect(parts.every(predicate), `${message} (got "${value}")`).toBe(true);
}

// --- UAT #1: group catalog holds together at every viewport -----------------

test.describe("Phase 177 UAT #1 — group catalog holds together at every viewport", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  for (const story of groupStories) {
    test(`${story} stays within every viewport without horizontal scroll`, async ({
      page,
    }) => {
      for (const width of viewportWidths) {
        await test.step(`${width}px`, async () => {
          await page.setViewportSize({ width, height: 900 });
          await page.goto(`/audit/__stress?story=${encodeURIComponent(story)}`);

          const preview = page.getByTestId("stress-preview");
          await expect(preview).toBeVisible();
          // Theme comes from the running lane: the default run is dark; the
          // `desktop-chromium-light` lane (THREADLINE_E2E_THEME=system, colorScheme
          // light) re-runs this file for light/system coverage.
          await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
            "data-tl-theme",
            /^(dark|light|system)$/,
          );

          // The load-bearing guarantee: no element pushes past the 320px floor.
          await expectNoHorizontalOverflow(page);
          await expectBoxWithinViewport(preview, width);
        });
      }
    });
  }
});

// --- UAT #3: overlay motion + reduced-motion collapse -----------------------
//
// The stress preview matrix renders the modal + drawer overlays for every story
// (the same kitchen-sink matrix), so any group story exercises them. show_modal/
// show_drawer add the token-synced transition classes (tl-rise-in / tl-slide-in-
// right) to `#{id}-content`. Default motion keeps a real duration; reduced motion
// collapses every transition to 0.001s via the operator surface's media query.
// (Real-page overlay/drawer motion is additionally covered by operator-motion.spec.ts.)

const motionStory = "group.modal-destructive.current";

test.describe("Phase 177 UAT #3 — overlay motion (default motion)", () => {
  test.use({ reducedMotion: "no-preference" });

  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "no-preference" });
    await login(page);
  });

  test("modal enters with a real (non-collapsed) transition duration", async ({
    page,
  }) => {
    await page.goto(`/audit/__stress?story=${motionStory}`);
    await page.getByRole("button", { name: "Show Modal" }).click();

    const duration = await transitionDuration(page.locator("#stress-modal-content"));
    expectEveryDuration(
      duration,
      (part) => part !== "0.001s" && part !== "0s",
      "modal transition should not be collapsed under default motion",
    );
  });

  test("drawer enters with a real (non-collapsed) transition duration", async ({
    page,
  }) => {
    await page.goto(`/audit/__stress?story=${motionStory}`);
    await page.getByRole("button", { name: "Show Drawer" }).click();

    const duration = await transitionDuration(page.locator("#stress-drawer-content"));
    expectEveryDuration(
      duration,
      (part) => part !== "0.001s" && part !== "0s",
      "drawer transition should not be collapsed under default motion",
    );
  });
});

test.describe("Phase 177 UAT #3 — overlay motion collapses under reduced motion", () => {
  test.use({ reducedMotion: "reduce" });

  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page);
  });

  test("modal transition collapses to ~instant", async ({ page }) => {
    await page.goto(`/audit/__stress?story=${motionStory}`);
    await page.getByRole("button", { name: "Show Modal" }).click();

    const duration = await transitionDuration(page.locator("#stress-modal-content"));
    expectEveryDuration(
      duration,
      (part) => part === "0.001s",
      "modal motion should collapse to 0.001s under reduced motion",
    );
  });

  test("drawer transition collapses to ~instant", async ({ page }) => {
    await page.goto(`/audit/__stress?story=${motionStory}`);
    await page.getByRole("button", { name: "Show Drawer" }).click();

    const duration = await transitionDuration(page.locator("#stress-drawer-content"));
    expectEveryDuration(
      duration,
      (part) => part === "0.001s",
      "drawer motion should collapse to 0.001s under reduced motion",
    );
  });
});

// --- UAT #4: reconnect/offline CSS contract (computed in-browser) ------------
//
// The reconnect banner + [data-tl-mutating] disabling are pure CSS, keyed off the
// phoenix_live_view client classes (.phx-loading / .phx-error). The banner COMPONENT
// is verified at the source/render level in component_contract_test.exs; here we prove
// the stylesheet actually *computes* the contract in a real browser by mounting the
// documented markup and toggling the connection class exactly as a dropped socket
// would. NOTE: the reconnect_banner component is not yet wired into the operator shell
// (it exists but is unmounted), so this probes the CSS mechanism rather than a live
// shell element — see 177-VERIFICATION.md for the follow-up.

test.describe("Phase 177 UAT #4 — reconnect/offline CSS contract", () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("phx-error reveals the banner and dims [data-tl-mutating]; connected hides/enables", async ({
    page,
  }) => {
    await page.goto("/audit");
    await expect(page.locator(".threadline-ui").first()).toBeVisible();

    const result = await page.evaluate(() => {
      const root = document.querySelector(".threadline-ui");
      if (!root) {
        return { error: "no .threadline-ui root on /audit" };
      }

      const banner = document.createElement("div");
      banner.className = "tl-reconnect-banner";
      root.prepend(banner);

      const button = document.createElement("button");
      button.setAttribute("data-tl-mutating", "");
      button.textContent = "Prune now";
      root.prepend(button);

      const read = () => ({
        bannerDisplay: getComputedStyle(banner).display,
        buttonOpacity: getComputedStyle(button).opacity,
        buttonPointerEvents: getComputedStyle(button).pointerEvents,
      });

      const connected = read();
      root.classList.add("phx-error");
      const errored = read();
      root.classList.remove("phx-error");

      return { connected, errored };
    });

    expect(result.error, result.error).toBeUndefined();

    // Connected: banner hidden, mutating control fully interactive.
    expect(result.connected!.bannerDisplay).toBe("none");
    expect(result.connected!.buttonPointerEvents).not.toBe("none");

    // Disconnected: banner revealed, mutating control dimmed + click-blocked.
    expect(result.errored!.bannerDisplay).toBe("flex");
    expect(result.errored!.buttonOpacity).toBe("0.55");
    expect(result.errored!.buttonPointerEvents).toBe("none");
  });
});
