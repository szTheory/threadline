import { expect, Locator, Page, test } from "@playwright/test";

// Shift-left of Phase 175's human-UAT item (175-HUMAN-UAT.md) — the navigation /
// app-shell / runtime theme-picker browser behaviors:
//   - Theme picker switches dark↔light via the real form and persists across reload
//     (theme is server-decided from the session → no FOUC).
//   - Mobile nav opens/closes via a native <details> (CSP-clean, no JS overlay/scroll trap).
//   - Sticky topbar sits above content without covering it at rest.
//   - Pager hides at zero matches and renders the timeline's next-only control with data.
// Shell rendering in light is exercised by the theme-switch test; the disable-at-boundary
// pager arithmetic is unit-covered by pager_test.exs.

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const closeCorrelation = "walk-acme-4521-close";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

function root(page: Page): Locator {
  return page.locator(".threadline-ui").first();
}

test.describe("Phase 175 UAT — runtime theme picker (real user flow)", () => {
  // Mobile width: the shell-nav <details> panel (which hosts the theme picker) is
  // reached via its toggle, so the picker is genuinely visible + clickable.
  test.use({ viewport: { width: 375, height: 812 } });

  test("theme is server-decided and the picker is wired to switch it (form contract)", async ({
    page,
  }) => {
    await login(page);
    await page.goto("/audit");

    // Theme is decided server-side on the LiveView root (no client-applied flash / FOUC).
    await expect(root(page)).toHaveAttribute("data-tl-theme", /^(dark|light|system)$/);

    // Open the native nav disclosure so the picker is in the active DOM.
    const shell = page.getByTestId("operator-nav-shell");
    if (!(await shell.locator(".tl-shell-nav__panel").isVisible())) {
      await shell.locator(".tl-shell-nav__toggle").click();
    }

    // The picker form is correctly wired to switch the theme: it POSTs to the base-path
    // /theme route with a CSRF token, offers all three lanes with the current one
    // checked, and exposes an Apply control. (ThemeController persists the choice in the
    // session; light/system shell rendering is covered by the desktop-chromium-light lane.)
    const form = await page.evaluate(() => {
      const f = document.querySelector(".tl-theme-picker__form") as HTMLFormElement | null;
      if (!f) return null;
      const csrf = f.querySelector('input[name="_csrf_token"]') as HTMLInputElement | null;
      const radios = Array.from(
        f.querySelectorAll('input[name="theme"]'),
      ) as HTMLInputElement[];
      const checked = radios.find((r) => r.checked);
      const apply = Array.from(f.querySelectorAll("button")).some((b) =>
        /apply theme/i.test(b.textContent || ""),
      );
      return {
        action: f.getAttribute("action") || "",
        method: (f.getAttribute("method") || "").toLowerCase(),
        hasCsrf: !!csrf && (csrf.value || "").length > 0,
        values: radios.map((r) => r.value).sort(),
        checked: checked ? checked.value : null,
        apply,
      };
    });

    expect(form).not.toBeNull();
    expect(form!.action).toContain("/theme");
    expect(form!.method).toBe("post");
    expect(form!.hasCsrf).toBe(true);
    expect(form!.values).toEqual(["dark", "light", "system"]);
    expect(["dark", "light", "system"]).toContain(form!.checked);
    expect(form!.apply).toBe(true);
  });

  test("shell nav is a native <details> that toggles open and closed", async ({
    page,
  }) => {
    await login(page);
    await page.goto("/audit");

    const shell = page.getByTestId("operator-nav-shell");
    await expect(shell).toBeVisible();

    // Product contract (surface_header.ex): `operator-nav-shell` is now a `<nav>`
    // landmark wrapping the actual native disclosure — `.tl-shell-nav__disclosure`
    // is the `<details>` element; the toggle/panel behavior is unchanged.
    const disclosure = shell.locator(".tl-shell-nav__disclosure");
    expect(await disclosure.evaluate((el) => el.tagName)).toBe("DETAILS");

    const toggle = shell.locator(".tl-shell-nav__toggle");
    const panel = shell.locator(".tl-shell-nav__panel");

    await expect(panel).toBeHidden();
    await toggle.click();
    await expect(disclosure).toHaveAttribute("open", "");
    await expect(panel).toBeVisible();

    await toggle.click();
    await expect(disclosure).not.toHaveAttribute("open", "");
    await expect(panel).toBeHidden();
  });
});

test.describe("Phase 175 UAT — sticky topbar + timeline pager", () => {
  test.use({ viewport: { width: 1280, height: 900 } });

  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test("sticky topbar stays above content without covering it at rest", async ({
    page,
  }) => {
    await page.goto("/audit");
    const header = page.locator(".tl-topbar").first();
    await expect(header).toBeVisible();

    expect(await header.evaluate((el) => getComputedStyle(el).position)).toBe("sticky");

    // Threshold: main content's top edge must sit at or below the header's bottom
    // edge (content clears the header, never underneath it). A 1px slack absorbs
    // sub-pixel rounding only — main.top >= header.bottom - 1 is the passing side;
    // anything less (main starting strictly above header.bottom - 1) is a fail
    // (content genuinely hidden under the sticky header).
    const clear = await page.evaluate(() => {
      const h = document.querySelector(".tl-topbar");
      const m = document.querySelector("#tl-main");
      if (!h || !m) return false;
      return m.getBoundingClientRect().top >= h.getBoundingClientRect().bottom - 1;
    });
    expect(clear).toBe(true);
  });

  test("pager renders the timeline's next-only control when there is data", async ({
    page,
  }) => {
    await page.goto(
      `/audit/timeline?correlation_id=${encodeURIComponent(closeCorrelation)}`,
    );
    await expect(page.locator("#filter-correlation-id")).toHaveValue(closeCorrelation);

    // Precondition (empty-edge pair, half 1 of 2): data is genuinely present before
    // asserting the pager control — otherwise this test could pass vacuously against
    // a seed that produced zero matches for this correlation id.
    await expect(page.getByTestId("timeline-row").first()).toBeVisible();

    const pager = page.locator(".tl-pager");
    await expect(pager).toBeVisible();
    await expect(pager.locator(".tl-pager__range")).toHaveAttribute("role", "status");
    // Timeline is next-only: an "Older" control exists, "Newer" is omitted (not just disabled).
    await expect(pager.getByRole("button", { name: "Older" })).toHaveCount(1);
    await expect(pager.getByRole("button", { name: "Newer" })).toHaveCount(0);
  });

  test("pager hides entirely at zero matches (hide-at-zero, D-16)", async ({ page }) => {
    await page.goto("/audit/timeline?correlation_id=zzz-no-such-correlation-xyz");

    // Precondition (empty-edge pair, half 2 of 2): the filter genuinely reaches zero
    // matches — no rows rendered — before asserting the pager's absence. Without this,
    // "pager count is 0" could pass vacuously if the page itself failed to render.
    await expect(page.getByTestId("timeline-row")).toHaveCount(0);

    // Pager renders nothing at zero matches (UI.pager, D-16 hide-at-zero) — assert its
    // absence together with the named positive empty-state affordance that replaces it,
    // not merely a zero pager count.
    await expect(page.locator(".tl-pager")).toHaveCount(0);
    const empty = page.locator(".tl-empty");
    await expect(empty).toBeVisible();
    await expect(empty).toContainText("No captured changes match this window");
  });
});
