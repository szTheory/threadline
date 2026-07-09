import { expect, Page, test } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

// Storybook capture lane (Phase 195-09) — the critic's REAL-UI golden-set source.
//
// The Tier-A `/audit/__stress` `page.*` cells render only a text summary (not the
// real page), so they cannot be judged for visual design. Phoenix Storybook
// (`/dev/storybook`, dev/test-only) renders the REAL production
// `Threadline.OperatorSurface.UI.*` components with static fixtures — deterministic,
// no DB, no auth. This spec captures each story's `.threadline-ui` sandbox (clipped,
// excluding Storybook's own chrome) into the same evidence-bundle shape the critic
// reads, so `critic:score` / `mix critic.measure` judge real component/pattern UI.
//
// Determinism: fixed viewport per cell, deviceScaleFactor:1, reducedMotion:"reduce"
// (global), fonts.ready before observing styles, dynamic masks, static fixtures.
// Mechanical VERDICTS are computed later in Elixir over these raw inputs.

const repoRoot = resolve(process.cwd(), "../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/storybook",
);

// Pinned for cross-machine byte-stability — never `new Date()` / installed version.
const PLAYWRIGHT_VERSION = "1.61.1";
const CAPTURE_SOURCE = "storybook";
const SCHEMA_VERSION = 1;
const BREAKPOINTS = [375, 768, 1280] as const;

// Card / panel selector set for the card-nesting-depth DOM walk (matches Tier-A).
const CARD_SELECTOR =
  '.tl-home__card, .tl-home__earned-panel, [class*="-panel"], [class*="-card"]';

// The Storybook sandbox — the real component render, excluding Storybook chrome.
const SANDBOX = '.threadline-ui[data-tl-theme]';

// The 8 curated `:page` stories (real UI). ledger id → storybook route path.
const STORIES: { id: string; path: string }[] = [
  { id: "story.foundations.index", path: "foundations/index" },
  { id: "story.primitives.button", path: "primitives/button" },
  { id: "story.forms.field", path: "forms/field" },
  { id: "story.states.data_state", path: "states/data_state" },
  { id: "story.overlays.modal", path: "overlays/modal" },
  { id: "story.data_display.data_table", path: "data_display/data_table" },
  { id: "story.groups.operator_groups", path: "groups/operator_groups" },
  { id: "story.patterns.operator_patterns", path: "patterns/operator_patterns" },
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

// Resolve every --tl-* token off the themed sandbox root.
async function resolvedTokens(page: Page): Promise<Record<string, string>> {
  return page.evaluate((sandboxSel) => {
    const root = document.querySelector(sandboxSel);
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
  }, SANDBOX);
}

// RAW mechanical inputs, scoped to the sandbox (real UI, excludes Storybook chrome).
// NO WCAG / hue / conformance math here — that lives in Elixir.
async function rawInputs(page: Page, cardSelector: string) {
  return page.evaluate(
    ({ cardSel, sandboxSel }) => {
      const main = document.querySelector(sandboxSel);
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
    { cardSel: cardSelector, sandboxSel: SANDBOX },
  );
}

async function captureCell(page: Page, ledgerId: string, path: string, breakpoint: number) {
  await page.setViewportSize({ width: breakpoint, height: 900 });
  await page.goto(`/dev/storybook/${path}`, { waitUntil: "load" });

  const sandbox = page.locator(SANDBOX).first();
  await sandbox.waitFor({ state: "visible", timeout: 15_000 });
  // Stories author their own theme (dark/light/system) in <.threadline_preview>;
  // record the sandbox's actual theme rather than asserting one.
  const theme = (await sandbox.getAttribute("data-tl-theme")) ?? "dark";
  const id = cellId(ledgerId, theme, breakpoint);
  await expect(sandbox).toBeVisible();
  await page.evaluate(() => (document as unknown as { fonts: { ready: Promise<unknown> } }).fonts.ready);

  const artifactDir = resolve(artifactsRoot, id);
  mkdirSync(artifactDir, { recursive: true });

  // Clip to the sandbox element — real component render, excludes Storybook chrome.
  await sandbox.screenshot({
    path: resolve(artifactDir, "screenshot.png"),
    scale: "css",
    mask: dynamicMasks(page),
  });
  writeFileSync(resolve(artifactDir, "dom.html"), await sandbox.innerHTML(), "utf8");
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

  const relDir = `examples/threadline_phoenix/e2e/artifacts/storybook/${id}`;
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
      storybook_path: path,
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

test.describe("operator Storybook deterministic capture", () => {
  test("emits the Storybook real-UI evidence bundle", async ({ page }, testInfo) => {
    test.skip(
      testInfo.project.name !== "storybook-capture",
      "Storybook capture runs only under the storybook-capture project",
    );
    test.setTimeout(900_000);

    for (const story of STORIES) {
      for (const bp of BREAKPOINTS) {
        await captureCell(page, story.id, story.path, bp);
      }
    }
  });
});
