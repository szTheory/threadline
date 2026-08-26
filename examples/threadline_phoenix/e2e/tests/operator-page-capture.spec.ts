import { expect, Page, test } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

// Real operator-route capture lane (Phase 196) — the critic's REALISTIC-PAGE source.
//
// Storybook `story.*` cells render real components but in isolation with static
// fixtures (a swatch grid, a button matrix) — great for component-level lenses,
// useless for "does this assembled screen guide an operator?" (hierarchy/density).
// The Tier-A `page.*` cells are fullPage captures of the /audit/__stress dev lab
// (harness chrome) — invalid for critique.
//
// This spec authenticates against the seeded example app (run-e2e.sh runs
// `mix demo.seed`), navigates to the REAL `/audit/*` operator routes, and clips
// to the operator content region (`#tl-main`) — excluding the persistent nav
// sidebar (a sibling above #tl-main inside `.threadline-ui`). The output is the
// same evidence-bundle shape the critic reads, so `critic:score --page route.*`
// judges a fully-assembled page with realistic audit data.
//
// Determinism: fixed viewport, deviceScaleFactor:1, reducedMotion:"reduce"
// (global), fonts.ready before observing styles, dynamic <time>/[data-dynamic]
// masks so live timestamps/ids don't perturb the pixels.

const repoRoot = resolve(process.cwd(), "../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/routes",
);

// Pinned for cross-machine byte-stability — never `new Date()` / installed version.
const PLAYWRIGHT_VERSION = "1.61.1";
const CAPTURE_SOURCE = "route";
const SCHEMA_VERSION = 1;
// Single desktop hero view for the Phase-196 proof; widen later if it proves out.
const BREAKPOINTS = [1280] as const;

// Card / panel selector set for the card-nesting-depth DOM walk (matches Tier-A).
const CARD_SELECTOR =
  '.tl-home__card, .tl-home__earned-panel, [class*="-panel"], [class*="-card"]';

// The themed operator root (token/theme source) and the content region we clip to.
const ROOT = ".threadline-ui[data-tl-theme]";
const CONTENT = "#tl-main";

// Auth (reused from operator-screenshots.spec.ts): the seeded demo admin.
const ADMIN_EMAIL = "admin@example.com";
const ADMIN_PASSWORD = process.env.DEMO_SEED_PASSWORD ?? "password123456";

// Ranking trust-test (Phase 196): a deliberately-DEGRADED twin of the same page,
// same data — off-brand generic font, garish clashing recolor of every accent,
// a collapsed single type size, flattened weight, and destroyed vertical rhythm.
// It targets the exact properties the trusted lenses (brand_fidelity, rhythm) and
// typography/color_contrast judge. A working critic must RANK the real page above
// this twin — that's the validated strength (ranking), not absolute per-page finds.
const DEGRADE_CSS = `
  #tl-main, #tl-main * { font-family: "Times New Roman", Times, serif !important; }
  #tl-main * {
    font-size: 13px !important;
    font-weight: 400 !important;
    letter-spacing: normal !important;
    border-radius: 0 !important;
  }
  /* Garish off-brand recolor of every accent/badge/chip/action — clashing,
     undocumented, uniform: exactly what designed_not_recolored penalizes. */
  #tl-main [class*="op-"], #tl-main [class*="badge"], #tl-main [class*="chip"],
  #tl-main [class*="tag"], #tl-main [class*="fact"], #tl-main button, #tl-main a {
    background-color: #ff2ec4 !important;
    color: #39ff14 !important;
    border-color: #ff2ec4 !important;
  }
  /* Destroy vertical cadence: cram every row/list/table gap to 1px. */
  #tl-main [class*="row"], #tl-main [class*="event"], #tl-main [class*="timeline"],
  #tl-main li, #tl-main tr, #tl-main [class*="fact"] {
    margin: 1px !important;
    padding: 1px !important;
    gap: 1px !important;
  }
`;

// The curated real operator routes. ledger id → authed route path. `degrade` marks
// the ranking-test twin. The five weakest-page candidates (196-D8), each backed by a
// committed `page.<x>.happy` twin in `mechanical_floors` for the deterministic floor
// the forward-only gate gates on (see CONTRIBUTING.md → route ↔ page twin table).
//
// Paths are the REAL router mounts (lib/threadline/operator_surface/router.ex):
//   /timeline, /coverage, /evidence are direct; retention lives under
//   /policy/retention; an actor page needs a concrete kind/id — we point at the
//   deterministic seeded `service_account/zendesk-sync` actor (demo Manifest), a
//   valid `@actor_kinds` member so the page renders under the seeded-login flow.
const ROUTES: { id: string; path: string; degrade?: boolean }[] = [
  { id: "route.timeline", path: "/audit/timeline" },
  { id: "route.timeline.degraded", path: "/audit/timeline", degrade: true },
  { id: "route.coverage", path: "/audit/coverage" },
  { id: "route.retention", path: "/audit/policy/retention" },
  { id: "route.actor", path: "/audit/actors/service_account/zendesk-sync" },
  { id: "route.evidence", path: "/audit/evidence" },
];

function cellId(ledgerId: string, theme: string, breakpoint: number): string {
  return `${ledgerId}__${theme}-${breakpoint}`;
}

function scorecardPath(id: string): string {
  return resolve(scorecardsDir, `${id}.json`);
}

function dynamicMasks(page: Page) {
  return [page.locator("time"), page.locator('[data-dynamic="true"]')];
}

function writeJson(path: string, value: unknown) {
  // Two-space indent + trailing newline: byte-stable `git diff` on regeneration.
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(ADMIN_EMAIL);
  await form.getByLabel("Password").fill(ADMIN_PASSWORD);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

// Resolve every --tl-* token off the themed operator root.
async function resolvedTokens(page: Page): Promise<Record<string, string>> {
  return page.evaluate((rootSel) => {
    const root = document.querySelector(rootSel);
    if (!root) return {};
    const style = getComputedStyle(root);
    const names = [
      "--tl-space-1", "--tl-space-2", "--tl-space-3", "--tl-space-4",
      "--tl-space-5", "--tl-space-6", "--tl-space-8", "--tl-space-10",
      "--tl-space-12",
      "--tl-font-size-xs", "--tl-font-size-sm", "--tl-font-size-label",
      "--tl-font-size-ui", "--tl-font-size-body", "--tl-font-size-heading",
      "--tl-font-size-title", "--tl-font-size-display",
      "--tl-radius-xs", "--tl-radius-sm", "--tl-radius-md", "--tl-radius-lg",
      "--tl-radius-xl", "--tl-radius-pill",
      "--tl-motion-fast", "--tl-motion-base", "--tl-motion-slow",
      "--tl-color-thread-blue", "--tl-color-stitch-blue",
      "--tl-color-signal-cyan", "--tl-color-iris", "--tl-color-ember",
      "--tl-color-text", "--tl-color-bg", "--tl-color-muted",
      "--tl-color-accent", "--tl-color-border",
    ];
    const out: Record<string, string> = {};
    for (const name of names) out[name] = style.getPropertyValue(name).trim();
    return out;
  }, ROOT);
}

// RAW mechanical inputs, scoped to the content region (#tl-main) — the same
// region the screenshot clips to, so mechanical + visual evidence agree.
// NO WCAG / hue / conformance math here — that lives in Elixir.
async function rawInputs(page: Page, cardSelector: string) {
  return page.evaluate(
    ({ cardSel, contentSel }) => {
      const main = document.querySelector(contentSel);
      if (!main) {
        return {
          color_pairs: [],
          element_styles: [],
          applied_colors: [],
          mode_b: {
            type_size_count: 0,
            interactive_control_count: 0,
            card_nesting_depth: 0,
            scroll_cost: 0,
            font_sizes: [],
          },
          a11y_summary: { headings: 0, landmarks: 0, interactive_elements: 0 },
        };
      }

      const selector = (el: Element): string => {
        const tag = el.tagName.toLowerCase();
        const cls =
          el.className && typeof el.className === "string"
            ? "." + el.className.trim().split(/\s+/)[0]
            : "";
        return tag + cls;
      };

      const textSel = "p, h1, h2, h3, h4, h5, h6, a, button, label, span, td, th";
      const colorPairs = Array.from(main.querySelectorAll(textSel)).map((el) => {
        const s = getComputedStyle(el);
        return {
          selector: selector(el),
          color: s.color,
          background_color: s.backgroundColor,
          font_size: s.fontSize,
          font_weight: s.fontWeight,
        };
      });

      const styleSel =
        "h1, h2, h3, h4, h5, h6, p, a, button, label, input, select, textarea, " +
        cardSel;
      const elementStyles = Array.from(main.querySelectorAll(styleSel)).map(
        (el) => {
          const s = getComputedStyle(el);
          return {
            selector: selector(el),
            border_radius: s.borderRadius,
            box_shadow: s.boxShadow,
            transition_duration: s.transitionDuration,
            font_size: s.fontSize,
            font_weight: s.fontWeight,
            margin_top: s.marginTop,
            margin_bottom: s.marginBottom,
            padding_top: s.paddingTop,
            padding_bottom: s.paddingBottom,
          };
        },
      );

      const appliedColors = Array.from(
        new Set(
          Array.from(main.querySelectorAll(textSel)).map(
            (el) => getComputedStyle(el).color,
          ),
        ),
      ).sort();

      const fontSizes = Array.from(
        new Set(
          Array.from(main.querySelectorAll("*")).map(
            (el) => getComputedStyle(el).fontSize,
          ),
        ),
      )
        .filter((v) => v && v.endsWith("px"))
        .sort((a, b) => parseFloat(a) - parseFloat(b));

      const interactiveSel =
        'button, input, select, textarea, [role="button"], [role="link"], a[href]';
      const interactiveControlCount = main.querySelectorAll(interactiveSel).length;

      let cardNestingDepth = 0;
      for (const card of Array.from(main.querySelectorAll(cardSel))) {
        let depth = 1;
        let el: Element | null = card.parentElement;
        while (el) {
          if (el.matches(cardSel)) depth += 1;
          el = el.parentElement;
        }
        if (depth > cardNestingDepth) cardNestingDepth = depth;
      }

      const scrollCost =
        Math.round(
          (document.documentElement.scrollHeight /
            Math.max(window.innerHeight, 1)) *
            1000,
        ) / 1000;

      const landmarkSel =
        'main, nav, header, footer, aside, [role="main"], [role="navigation"], ' +
        '[role="banner"], [role="contentinfo"], [role="complementary"], ' +
        '[role="region"], [role="search"]';

      return {
        color_pairs: colorPairs,
        element_styles: elementStyles,
        applied_colors: appliedColors,
        mode_b: {
          type_size_count: fontSizes.length,
          interactive_control_count: interactiveControlCount,
          card_nesting_depth: cardNestingDepth,
          scroll_cost: scrollCost,
          font_sizes: fontSizes,
        },
        a11y_summary: {
          headings: main.querySelectorAll("h1, h2, h3, h4, h5, h6").length,
          landmarks: main.querySelectorAll(landmarkSel).length,
          interactive_elements: interactiveControlCount,
        },
      };
    },
    { cardSel: cardSelector, contentSel: CONTENT },
  );
}

async function captureCell(
  page: Page,
  ledgerId: string,
  path: string,
  breakpoint: number,
  degrade = false,
) {
  await page.setViewportSize({ width: breakpoint, height: 900 });
  await page.goto(path, { waitUntil: "load" });

  const root = page.locator(ROOT).first();
  await root.waitFor({ state: "visible", timeout: 15_000 });
  const content = page.locator(CONTENT).first();
  await content.waitFor({ state: "visible", timeout: 15_000 });
  // Let the LiveView settle (rows/table stream in) so the hero shot is populated.
  await page.waitForLoadState("networkidle");

  // Ranking-test twin: inject the degradation stylesheet AFTER the page settles,
  // so it recolors/reflows the real rendered content in place.
  if (degrade) {
    await page.addStyleTag({ content: DEGRADE_CSS });
    await page.waitForTimeout(200);
  }

  const theme = (await root.getAttribute("data-tl-theme")) ?? "dark";
  const id = cellId(ledgerId, theme, breakpoint);
  await page.evaluate(() => (document as unknown as { fonts: { ready: Promise<unknown> } }).fonts.ready);

  const artifactDir = resolve(artifactsRoot, id);
  mkdirSync(artifactDir, { recursive: true });

  // Clip to #tl-main — the assembled page content, excluding the nav sidebar.
  await content.screenshot({
    path: resolve(artifactDir, "screenshot.png"),
    scale: "css",
    mask: dynamicMasks(page),
    // Playwright's default mask color is #FF00FF, which the LLM critic scores as
    // the most salient element on the page (a harness artifact, not the UI).
    // Mask with the dark surface token instead so masked regions stay non-salient.
    maskColor: "#0B1020",
  });
  writeFileSync(resolve(artifactDir, "dom.html"), await content.innerHTML(), "utf8");
  let rawA11y: unknown = null;
  try {
    rawA11y = await page.accessibility.snapshot();
  } catch {
    rawA11y = null;
  }
  writeFileSync(
    resolve(artifactDir, "a11y.json"),
    `${JSON.stringify(rawA11y, null, 2)}\n`,
    "utf8",
  );

  const tokens = await resolvedTokens(page);
  const raw = await rawInputs(page, CARD_SELECTOR);

  const relDir = `examples/threadline_phoenix/e2e/artifacts/routes/${id}`;
  const scorecard = {
    schema_version: SCHEMA_VERSION,
    cell_id: id,
    ledger_id: ledgerId,
    theme,
    breakpoint,
    capture_source: CAPTURE_SOURCE,
    band: 1,
    meta: {
      playwright_version: PLAYWRIGHT_VERSION,
      device_scale_factor: 1,
      viewport: { width: breakpoint, height: 900 },
      color_scheme: theme,
      route_path: path,
    },
    tokens,
    color_pairs: raw.color_pairs,
    element_styles: raw.element_styles,
    applied_colors: raw.applied_colors,
    mode_b: raw.mode_b,
    a11y_summary: raw.a11y_summary,
    artifacts: {
      screenshot: `${relDir}/screenshot.png`,
      dom: `${relDir}/dom.html`,
      a11y: `${relDir}/a11y.json`,
      aria: null,
    },
  };
  writeJson(scorecardPath(id), scorecard);
}

test.describe("operator real-route deterministic capture", () => {
  test("emits the real operator-page evidence bundle", async ({ page }, testInfo) => {
    test.skip(
      testInfo.project.name !== "route-capture",
      "Route capture runs only under the route-capture project",
    );
    test.setTimeout(900_000);

    await login(page);

    for (const route of ROUTES) {
      for (const bp of BREAKPOINTS) {
        await captureCell(page, route.id, route.path, bp, route.degrade ?? false);
      }
    }
  });
});
