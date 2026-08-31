import { expect, Page, test } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";

// Tier A deterministic capture lane (Phase 194, MECH-04 / MECH-05).
//
// This spec drives /audit/__stress and emits, per matrix cell:
//   - gitignored binaries under examples/threadline_phoenix/e2e/artifacts/tier-a/<cell-id>/
//     (screenshot.png + dom.html + a11y.json)
//   - a COMMITTED, diffable RAW-inputs scorecard at .planning/scorecards/<cell-id>.json
//   - for the deep band (Band 2) a COMMITTED .planning/scorecards/<cell-id>.aria.yml
//
// Determinism contract (byte-stable regeneration): the committed JSON carries NO
// wall-clock timestamp and NO machine-derived values. Every mechanical VERDICT
// (WCAG contrast, hue bucketing, token conformance) is computed later in Elixir
// (Plan 03) over these raw inputs — the browser never runs the WCAG formula. That
// browser/Elixir split, plus deviceScaleFactor:1 + global reducedMotion:"reduce" +
// #tl-main aria subtree + DB-free static fixtures, is the determinism guarantee.

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

const repoRoot = resolve(process.cwd(), "../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/tier-a",
);

// Pinned for cross-machine byte-stability — never `new Date()` / installed version.
const PLAYWRIGHT_VERSION = "1.61.1";
const CAPTURE_TIER = "A";
const SCHEMA_VERSION = 1;
const BREAKPOINTS = [375, 768, 1280] as const;

// Card / panel selector set for the card-nesting-depth DOM walk (locked decision 6).
const CARD_SELECTOR =
  '.tl-home__card, .tl-home__earned-panel, [class*="-panel"], [class*="-card"]';

// Band 1 (floor smoke): all 11 operator pages × happy = 11 ledger stories.
const BAND_1_STORIES = [
  "actor",
  "coverage",
  "evidence",
  "exports",
  "home",
  "redaction",
  "retention",
  "row-history",
  "shell",
  "timeline",
  "transaction",
].map((subject) => `page.${subject}.happy`);

// Band 2 (deep): the 3 lowest-scoring target pages (locked decision 1) × 3 states.
// The ledger path for "permission-denied" is the `permission` audit path.
const BAND_2_STORIES = ["transaction", "coverage", "retention"].flatMap(
  (subject) =>
    ["empty", "error", "permission"].map((state) => `page.${subject}.${state}`),
);

// Band R (refute): gestalt-twin polished + flawed poles for the 6 gestalt lenses
// (Plan 195-03 / CRITIC-02 D-03 partition rule). Band 1 depth (no aria.yml capture).
// The veto-ordering twin's FLAWED pole is intentionally excluded: the off-token raw-hex
// accent is exercised at the panel layer in Plan 06, not via a committed MODE-A scorecard.
// The veto-ordering POLISHED pole is included so its on-token reference scorecard exists.
const REFUTE_STORIES = [
  "refute.rhythm.doubled-padding.polished",
  "refute.rhythm.doubled-padding.flawed",
  "refute.density.card-section-wrap.polished",
  "refute.density.card-section-wrap.flawed",
  "refute.hierarchy.flattened.polished",
  "refute.hierarchy.flattened.flawed",
  "refute.typography.scale-collapse.polished",
  "refute.typography.scale-collapse.flawed",
  "refute.brand-fidelity.mis-jobbed-accent.polished",
  "refute.brand-fidelity.mis-jobbed-accent.flawed",
  "refute.density.chrome-bloat.polished",
  "refute.density.chrome-bloat.flawed",
  "refute.veto-ordering.off-token-accent.polished",
];

function themeForProject(projectName: string): "dark" | "light" {
  return projectName.endsWith("-light") ? "light" : "dark";
}

function cellId(ledgerId: string, theme: string, breakpoint: number): string {
  return `${ledgerId}__${theme}-${breakpoint}`;
}

function scorecardPath(id: string): string {
  return resolve(scorecardsDir, `${id}.json`);
}

function ariaSnapshotPath(id: string): string {
  return resolve(scorecardsDir, `${id}.aria.yml`);
}

function dynamicMasks(page: Page) {
  return [
    page.locator("time"),
    page.locator('[data-dynamic="true"]'),
    page.getByTestId("stress-run-id"),
  ];
}

function writeJson(path: string, value: unknown) {
  // Two-space indent + trailing newline: matches the committed ledger convention
  // and keeps `git diff` on the scorecards byte-stable across regeneration.
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

// Resolve every --tl-* token off the themed root so the scorecard records the
// theme-resolved token values (getComputedStyle resolves all var() aliases).
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
    for (const name of names) {
      out[name] = style.getPropertyValue(name).trim();
    }
    return out;
  });
}

// RAW mechanical inputs. NO WCAG / hue / conformance math here — that lives in
// Elixir (Plan 03). We only observe resolved computed styles and structural counts.
async function rawInputs(page: Page, cardSelector: string) {
  return page.evaluate((cardSel) => {
    // Scope evidence to the product surface under test (the rendered story),
    // NOT the /audit/__stress harness chrome (sidebar category-nav, filters,
    // metric labels) which shares the #tl-main region but never ships in prod.
    const main = document.querySelector('[data-testid="stress-preview"]');
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

    // WCAG contrast raw inputs: per text/UI element, foreground + background +
    // font metrics. Elixir composites/thresholds these.
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

    // Token-conformance raw inputs: per element, the token-bearing computed props.
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

    // Distinct-accent-hue raw inputs: every distinct foreground color applied to
    // a non-background text/UI element. Elixir buckets hues (±15°, chromatic only).
    const appliedColors = Array.from(
      new Set(
        Array.from(main.querySelectorAll(textSel)).map(
          (el) => getComputedStyle(el).color,
        ),
      ),
    ).sort();

    // MODE-B structural counts (ratchet-floor inputs).
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
    const interactiveControlCount =
      main.querySelectorAll(interactiveSel).length;

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

    // Scroll cost is the PRODUCT surface's content height in viewports — scoped to
    // `main` like every sibling field above, NOT `document.documentElement`. On
    // /audit/__stress the document is ~98.5% harness-sidebar story catalog (35726px
    // of 36374px measured; the preview itself is 502px), so a document-wide read
    // grows with every newly registered story and carries no per-page signal at all.
    // See .planning/audits/198-tier-a-byte-stability.md (198-16 diagnosis).
    const scrollCost =
      Math.round((main.scrollHeight / Math.max(window.innerHeight, 1)) * 1000) /
      1000;

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
  }, cardSelector);
}

async function captureCell(
  page: Page,
  ledgerId: string,
  theme: "dark" | "light",
  breakpoint: number,
  deepBand: boolean,
) {
  const id = cellId(ledgerId, theme, breakpoint);

  await page.setViewportSize({ width: breakpoint, height: 900 });
  await page.goto(
    `/audit/__stress?story=${ledgerId}&theme=${theme}&viewport=${breakpoint}`,
    { waitUntil: "load" },
  );

  const preview = page.getByTestId("stress-preview");
  await expect(preview).toBeVisible();
  await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
    "data-tl-theme",
    theme,
  );
  await expect(page.getByTestId("stress-story-id")).toHaveText(ledgerId);
  // Fonts affect computed sizes / scroll-cost — settle before observing styles.
  await page.evaluate(() => (document as unknown as { fonts: { ready: Promise<unknown> } }).fonts.ready);

  const artifactDir = resolve(artifactsRoot, id);
  mkdirSync(artifactDir, { recursive: true });

  // Gitignored, regenerable binaries.
  await page.screenshot({
    path: resolve(artifactDir, "screenshot.png"),
    fullPage: true,
    scale: "css",
    mask: dynamicMasks(page),
  });
  writeFileSync(resolve(artifactDir, "dom.html"), await page.content(), "utf8");
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

  const relDir = `examples/threadline_phoenix/e2e/artifacts/tier-a/${id}`;
  const scorecard = {
    schema_version: SCHEMA_VERSION,
    cell_id: id,
    ledger_id: ledgerId,
    theme,
    breakpoint,
    capture_tier: CAPTURE_TIER,
    band: deepBand ? 2 : 1,
    meta: {
      playwright_version: PLAYWRIGHT_VERSION,
      device_scale_factor: 1,
      viewport: { width: breakpoint, height: 900 },
      color_scheme: theme,
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
      aria: deepBand ? `.planning/scorecards/${id}.aria.yml` : null,
    },
  };
  writeJson(scorecardPath(id), scorecard);

  if (deepBand) {
    // Scope to the product preview surface (excludes the app-shell header/timestamp
    // AND the /audit/__stress harness sidebar chrome). (Pitfall 6.)
    const ariaYaml = await page.locator('[data-testid="stress-preview"]').ariaSnapshot();
    writeFileSync(
      ariaSnapshotPath(id),
      ariaYaml.endsWith("\n") ? ariaYaml : `${ariaYaml}\n`,
      "utf8",
    );
  }
}

test.describe("operator Tier A deterministic capture", () => {
  test("emits the Tier A evidence bundle for this theme project", async ({
    page,
  }, testInfo) => {
    test.skip(
      !testInfo.project.name.startsWith("tier-a-capture"),
      "Tier A capture runs only under the tier-a-capture / tier-a-capture-light projects",
    );
    // 60 cells per project (browser round-trips) — well beyond the 120s default.
    test.setTimeout(900_000);

    const theme = themeForProject(testInfo.project.name);
    mkdirSync(scorecardsDir, { recursive: true });
    await login(page);

    for (const ledgerId of BAND_1_STORIES) {
      for (const bp of BREAKPOINTS) {
        await captureCell(page, ledgerId, theme, bp, false);
      }
    }

    for (const ledgerId of BAND_2_STORIES) {
      for (const bp of BREAKPOINTS) {
        await captureCell(page, ledgerId, theme, bp, true);
      }
    }

    // Band R: refute-twin gestalt poles (Plan 195-03, CRITIC-02).
    // Shallow Band 1 depth (no aria.yml). Committed scorecards prove the partition rule:
    // verify.mechanical passes for all gestalt twins even with the injected design flaw.
    for (const ledgerId of REFUTE_STORIES) {
      for (const bp of BREAKPOINTS) {
        await captureCell(page, ledgerId, theme, bp, false);
      }
    }
  });
});
