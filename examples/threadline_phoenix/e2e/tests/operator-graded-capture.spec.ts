import { expect, Page, test } from "@playwright/test";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

// Graded-ladder capture lane (Phase 195 D-12 — the synthetic twin oracle).
//
// The graded refute stories (lens × scenario × severity rung) render inside
// /audit/__stress at `[data-testid="refute-matrix"]`. This spec captures each one
// clipped to the twin content (no lab chrome) and emits the SAME evidence-bundle
// shape the critic reads (committed scorecard + gitignored PNG), so `critic:score`
// / `mix critic.measure --source synthetic` can score real graded UI.
//
// The cell list is the single source of truth: `.planning/golden/synthetic-set.json`
// (written by `mix critic.synth`). Each cell_id is `<story-id>__dark-1280`.
//
// Determinism: dark/1280 per cell, deviceScaleFactor:1 (project), reducedMotion
// "reduce" (global), fonts.ready before observing, dynamic masks. Run twice → identical.

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

const repoRoot = resolve(process.cwd(), "../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const syntheticSetPath = resolve(repoRoot, ".planning/golden/synthetic-set.json");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/graded",
);

// Pinned for cross-machine byte-stability — never `new Date()` / installed version.
const PLAYWRIGHT_VERSION = "1.61.1";
const CAPTURE_SOURCE = "graded";
const SCHEMA_VERSION = 1;
const THEME = "dark" as const;
const BREAKPOINT = 1280;

// The twin content region (excludes the lab header/sidebar AND the ledger-metadata table).
const MATRIX = '[data-testid="refute-matrix"]';

// Card / panel selector set for the card-nesting-depth DOM walk (matches Tier-A).
const CARD_SELECTOR =
  '.tl-home__card, .tl-home__earned-panel, [class*="-panel"], [class*="-card"]';

function storyIdFor(cellId: string): string {
  return cellId.replace(`__${THEME}-${BREAKPOINT}`, "");
}

function gradedCells(): { cellId: string; storyId: string; lens: string }[] {
  if (!existsSync(syntheticSetPath)) {
    throw new Error(
      `missing ${syntheticSetPath} — run \`mix critic.synth\` before capturing`,
    );
  }
  const set = JSON.parse(readFileSync(syntheticSetPath, "utf8")) as {
    items: { cell_id: string; lens: string }[];
  };
  return set.items
    .map((it) => ({ cellId: it.cell_id, storyId: storyIdFor(it.cell_id), lens: it.lens }))
    .sort((a, b) => a.cellId.localeCompare(b.cellId));
}

function dynamicMasks(page: Page) {
  return [
    page.locator("time"),
    page.locator('[data-dynamic="true"]'),
    page.getByTestId("stress-run-id"),
  ];
}

function writeJson(path: string, value: unknown) {
  // Two-space indent + trailing newline: byte-stable `git diff` on regeneration.
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

// Resolve every --tl-* token off the themed root (getComputedStyle resolves var() aliases).
async function resolvedTokens(page: Page): Promise<Record<string, string>> {
  return page.evaluate(() => {
    const root = document.querySelector(".threadline-ui");
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
  });
}

// RAW mechanical inputs scoped to the graded twin content (the refute matrix). NO
// WCAG / hue / conformance math here — that lives in Elixir over these raw inputs.
async function rawInputs(page: Page, cardSelector: string) {
  return page.evaluate(
    ({ cardSel, matrixSel }) => {
      const main = document.querySelector(matrixSel);
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
      const elementStyles = Array.from(main.querySelectorAll(styleSel)).map((el) => {
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
      });

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
    { cardSel: cardSelector, matrixSel: MATRIX },
  );
}

async function captureCell(page: Page, cellId: string, storyId: string, lens: string) {
  await page.setViewportSize({ width: BREAKPOINT, height: 900 });
  await page.goto(
    `/audit/__stress?story=${storyId}&theme=${THEME}&viewport=${BREAKPOINT}`,
    { waitUntil: "load" },
  );

  await expect(page.getByTestId("stress-story-id")).toHaveText(storyId);
  await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
    "data-tl-theme",
    THEME,
  );
  const matrix = page.getByTestId("refute-matrix");
  await expect(matrix).toBeVisible();
  await page.evaluate(() =>
    (document as unknown as { fonts: { ready: Promise<unknown> } }).fonts.ready,
  );

  const artifactDir = resolve(artifactsRoot, cellId);
  mkdirSync(artifactDir, { recursive: true });

  await matrix.screenshot({
    path: resolve(artifactDir, "screenshot.png"),
    scale: "css",
    mask: dynamicMasks(page),
  });
  writeFileSync(resolve(artifactDir, "dom.html"), await matrix.innerHTML(), "utf8");
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

  const relDir = `examples/threadline_phoenix/e2e/artifacts/graded/${cellId}`;
  const scorecard = {
    schema_version: SCHEMA_VERSION,
    cell_id: cellId,
    ledger_id: storyId,
    theme: THEME,
    breakpoint: BREAKPOINT,
    capture_source: CAPTURE_SOURCE,
    lens,
    band: 1,
    meta: {
      playwright_version: PLAYWRIGHT_VERSION,
      device_scale_factor: 1,
      viewport: { width: BREAKPOINT, height: 900 },
      color_scheme: THEME,
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
  writeJson(resolve(scorecardsDir, `${cellId}.json`), scorecard);
}

test.describe("operator graded-ladder deterministic capture", () => {
  test("emits the graded twin evidence bundle (synthetic oracle)", async ({
    page,
  }, testInfo) => {
    test.skip(
      testInfo.project.name !== "graded-capture",
      "Graded capture runs only under the graded-capture project",
    );
    test.setTimeout(900_000);

    mkdirSync(scorecardsDir, { recursive: true });
    const cells = gradedCells();
    await login(page);

    for (const { cellId, storyId, lens } of cells) {
      await captureCell(page, cellId, storyId, lens);
    }
  });
});
