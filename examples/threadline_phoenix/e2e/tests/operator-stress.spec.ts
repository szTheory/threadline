import { expect, Page, test } from "@playwright/test";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { join, resolve } from "node:path";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const viewportWidths = [320, 375, 768, 1024, 1440];
const ledgerPath = resolve(
  process.cwd(),
  "../../..",
  ".planning/design-system-ledger.json",
);
const repoRoot = resolve(process.cwd(), "../../..");
const selectedTierCStressStories = [
  "page.home.happy",
  "state.unavailable-down",
  "state.permission-denied",
  "state.pagination-boundary",
];

function ledger() {
  return JSON.parse(readFileSync(ledgerPath, "utf8"));
}

function ciScreenshotAllowlist() {
  return ledger().screenshot_allowlist.ci;
}

function ledgerEntryForStory(storyId: string) {
  return ledger().entries.find(
    (entry: { id: string; story_id?: string }) =>
      entry.id === storyId || entry.story_id === storyId,
  );
}

function desktopSnapshotPath(baselineRef: string) {
  const snapshotName = baselineRef.replace(/\.png$/, "-desktop-chromium.png");

  return resolve(
    process.cwd(),
    "tests/operator-stress.spec.ts-snapshots",
    snapshotName,
  );
}

function dynamicMasks(page: Page) {
  return [
    page.locator("time"),
    page.locator('[data-dynamic="true"]'),
    page.getByTestId("stress-run-id"),
  ];
}

function stressScreenshotOutputDir() {
  const outputDir = process.env.OPERATOR_STRESS_SCREENSHOT_DIR;

  if (!outputDir) return undefined;

  return resolve(repoRoot, outputDir);
}

function stressPacketName(storyId: string, theme: string, viewport: number) {
  const slug = storyId.replace(/[^a-z0-9]+/gi, "-");

  return `stress-${slug}-${theme}-${viewport}.png`;
}

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

test.describe("operator stress route semantics", () => {
  test("requires authentication before rendering the stress lab", async ({
    page,
  }) => {
    await page.goto("/audit/__stress");

    await expect(page).toHaveURL(/\/users\/log_in/);
    await expect(page.getByTestId("stress-lab")).toHaveCount(0);
  });

  test.describe("authenticated stress lab", () => {
    test.beforeEach(async ({ page }) => {
      await login(page);
    });

    test("renders the real operator shell, theme scope, story metadata, and preview", async ({
      page,
    }) => {
      await page.goto("/audit/__stress?story=page.timeline.empty");

      await expect(page.getByTestId("operator-header")).toBeVisible();
      const shell = page.locator(".threadline-ui").first();
      await expect(shell).toBeVisible();
      await expect(shell).toHaveAttribute("data-tl-theme", /^(dark|light|system)$/);
      await expect(page.locator("#tl-main")).toBeVisible();
      await expect(page.getByTestId("stress-story-id")).toHaveText(
        "page.timeline.empty",
      );
      await expect(page.getByTestId("stress-preview")).toBeVisible();
      await expect(page.getByTestId("stress-ledger-score")).toBeVisible();
      await expect(page.getByTestId("stress-screenshot-status")).toBeVisible();
    });

    test("marks the active category with current-state semantics", async ({
      page,
    }) => {
      await page.goto("/audit/__stress?category=foundation");

      const nav = page.getByTestId("stress-category-nav");
      await expect(nav).toBeVisible();
      await expect(nav.getByRole("link", { name: "foundation" })).toHaveAttribute(
        "aria-current",
        "page",
      );
    });

    test("folds bad params to an empty or default story state without crashing", async ({
      page,
    }) => {
      await page.goto(
        "/audit/__stress?story=not-real&category=not-real&theme=purple&viewport=9999",
      );

      await expect(page.getByTestId("stress-lab")).toBeVisible();
      await expect(page.locator("#tl-main")).toBeVisible();
      await expect(
        page
          .getByTestId("stress-story-id")
          .or(page.getByText("No stress stories registered")),
      ).toBeVisible();
    });

    for (const width of viewportWidths) {
      test(`keeps the stress route within the ${width}px viewport`, async ({
        page,
      }) => {
        await page.setViewportSize({ width, height: 900 });
        await page.goto("/audit/__stress?story=page.timeline.empty");

        await expect(page.getByTestId("stress-preview")).toBeVisible();
        await expectNoHorizontalOverflow(page);
      });
    }

    test("renders folded reserved cases with exact future-phase copy", async ({
      page,
    }) => {
      for (const [story, copy] of [
        ["future.theme-picker-idiomatic-ui", "Reserved for Phase 175"],
        ["footgun.coverage-schema-card-declutter", "Reserved for Phase 176"],
        [
          "footgun.transaction-page-left-push-desktop",
          "Reserved for Phase 178",
        ],
      ]) {
        await page.goto(`/audit/__stress?story=${story}`);
        await expect(page.getByText(copy)).toBeVisible();
      }
    });

    test("renders Phase 179 copy-state evidence on existing stress stories", async ({
      page,
    }) => {
      const copyStates = [
        {
          story: "state.permission-denied",
          copy: [
            "You do not have access to this audit object.",
            "The audit object exists; your account needs `audit.read`.",
          ],
        },
        {
          story: "state.unavailable-down",
          copy: [
            "Audit source is temporarily unavailable.",
            "This is not a permissions issue.",
            "Retry, then check operator logs.",
          ],
        },
        {
          story: "state.unavailable-redacted",
          copy: [
            "This field was redacted by the redaction policy.",
            "This is not a permissions issue.",
          ],
        },
        {
          story: "state.unavailable-pruned",
          copy: [
            "This audit history was permanently pruned by the retention window.",
            "This is not a permissions issue.",
          ],
        },
        {
          story: "state.stale",
          copy: ["Could not refresh - showing last known audit data", "Retry."],
        },
        {
          story: "page.evidence.happy",
          copy: [
            "Evidence shows the current audit posture.",
            "Open proof history only for append-only evidence detail.",
          ],
        },
        {
          story: "page.retention.happy",
          copy: [
            "Retention window status names the permanent pruning consequence",
            "review before running another prune",
          ],
        },
        {
          story: "group.modal-destructive.current",
          copy: [
            "Prune retention window permanently?",
            "This permanently deletes audit records older than the retention window.",
            "Type `default` to confirm.",
          ],
        },
      ];

      for (const { story, copy } of copyStates) {
        await page.goto(`/audit/__stress?story=${story}`);
        const preview = page.getByTestId("stress-preview");
        await expect(page.getByTestId("stress-story-id")).toHaveText(story);

        for (const text of copy) {
          await expect(preview).toContainText(text);
        }
      }

      await page.goto("/audit/__stress?story=page.evidence.happy");
      const evidenceText = await page.getByTestId("stress-preview").innerText();
      expect(evidenceText.replace(/proof history/gi, "")).not.toMatch(
        /\bproofs?\b/i,
      );
    });
  });
});

test("light/system Playwright lane includes the stress route spec", () => {
  const configPath = resolve(process.cwd(), "playwright.config.ts");
  const config = readFileSync(configPath, "utf8");

  expect(config).toContain(
    "operator-(accessibility|motion|screenshots|screenshot-regression|stress)",
  );
});

// ---------------------------------------------------------------------------
// Ledger-owned Tier C stress cells — STRUCTURAL + GEOMETRY, baseline-free.
//
// These three `screenshot_allowlist.ci` cells were pixel-diffed against committed PNGs
// (`toHaveScreenshot`, maxDiffPixelRatio 0.01). All three went red on CI run 33344382035
// as stale-baseline drift from real, intended UI work in phases 195-197. The failures
// named no defect, and the only available "fix" — re-recording the PNGs — asserts nothing
// about whether the new pixels are correct.
//
// Measured before replacing them (stress_live.ex:194-225 plus show_ui_matrix?/1 at :794):
// for a `page`/`footgun` cell the preview renders ONLY the header, the four-row ledger
// `dl`, and one copy paragraph — the primitives matrix is gated to
// foundation/primitive/form_control/group/state. So the retired baselines were
// pixel-diffing stress-lab chrome plus a sentence, which is exactly why global token work
// broke them: their real sensitivity was to the harness, not to these stories.
//
// WHAT IS NO LONGER ASSERTED ANYWHERE (D-23 honesty; see 198-TRIAGE.md): sub-threshold
// visual drift inside the preview panel at dark/1024 — spacing, type scale, border radii,
// and exact colour values that clear the luminance band below. Tier A mechanical
// scorecards cover the `page.*` twins; nothing covers the stress-lab chrome itself.
// ---------------------------------------------------------------------------

const CI_CELL_VIEWPORT = 1024;
// style.ex:4223 opens `@media (min-width: 1280px)`; :4248 sets the two-track template.
const TWO_COLUMN_BREAKPOINT = 1280;

// Dark/light separation band. Measured surfaces sit near the extremes, so this band
// separates the themes with an order of magnitude of slack and pins no token value.
const DARK_LUMINANCE_CEILING = 0.25;
const LIGHT_LUMINANCE_FLOOR = 0.5;

// Identity and copy owned by lib/threadline/operator_surface/stress_fixtures.ex
// (`page_data/2` :summary, `assigns_for/1` :body) and by the ledger entry itself. Pinned
// exactly: a legitimate change here fails with a one-line, reviewable source diff, unlike
// a re-recorded PNG. The generic fallback these guard against is "Synthetic stress
// fixture." (stress_live.ex:787).
const CELL_CONTRACTS: Record<
  string,
  { scenario: string; body: string; status: string; fixtureKey: string }
> = {
  "page.home.happy": {
    scenario: "Home page happy path",
    body: "Home page happy path with synthetic lookup launchers and coverage status.",
    status: "baseline",
    fixtureKey: "page.home.happy",
  },
  "page.timeline.empty": {
    scenario: "Timeline page empty path",
    body: "Timeline empty state with no captured changes matching this synthetic window.",
    status: "baseline",
    fixtureKey: "page.timeline.empty",
  },
  "footgun.transaction-page-left-push-desktop": {
    scenario: "Transaction page desktop centering baseline",
    body: "Reserved for Phase 178. This baseline records the current issue; do not fix it in Phase 171.",
    status: "reserved",
    fixtureKey: "footgun.transaction_page.left_push_desktop",
  },
};

// Placeholder copy the operator surface forbids (137-CONTEXT.md D-23). A pixel diff could
// never state this rule, and the empty-state cell is exactly where it would regress.
const FORBIDDEN_PLACEHOLDERS = [
  /^\s*No data\s*$/im,
  /^\s*No results\s*$/im,
  /Nothing here/i,
];

async function ledgerTableValues(preview: Locator) {
  return preview.locator(".tl-stress__ledger-table").evaluate((dl) =>
    Object.fromEntries(
      Array.from(dl.querySelectorAll(":scope > div")).map((row) => [
        row.querySelector("dt")?.textContent?.trim() ?? "",
        row.querySelector("dd")?.textContent?.trim() ?? "",
      ]),
    ),
  );
}

// WCAG relative luminance of the first OPAQUE painted ancestor at or above #tl-main.
// Walking up matters: .threadline-ui itself can compute to rgba(0,0,0,0), and a naive
// read of a transparent background would pass vacuously against black.
async function surfaceLuminance(page: Page): Promise<number> {
  const value = await page.evaluate(() => {
    let el: HTMLElement | null = document.querySelector("#tl-main");
    while (el) {
      const parts = getComputedStyle(el)
        .backgroundColor.match(/[\d.]+/g)
        ?.map(Number);
      if (parts && (parts.length < 4 || parts[3] > 0)) {
        const lin = (c: number) => {
          const s = c / 255;
          return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
        };
        return 0.2126 * lin(parts[0]) + 0.7152 * lin(parts[1]) + 0.0722 * lin(parts[2]);
      }
      el = el.parentElement;
    }
    return null;
  });

  expect(
    value,
    "no opaque painted background at or above #tl-main — the theme check would pass vacuously",
  ).not.toBeNull();

  return value!;
}

async function gridTrackCount(page: Page, selector: string): Promise<number> {
  return page
    .locator(selector)
    .evaluate((el) =>
      getComputedStyle(el as HTMLElement)
        .gridTemplateColumns.split(" ")
        .map((v) => parseFloat(v))
        .filter((n) => !Number.isNaN(n)).length,
    );
}

// At 1024 `.tl-stress__layout` is a single 1fr track (two columns are gated to >=1280px),
// so the preview must fill that track exactly — no left anchor, no spill.
async function expectPreviewFillsItsTrack(page: Page, viewportWidth: number) {
  const layout = await page.locator(".tl-stress__layout").boundingBox();
  const preview = await page.getByTestId("stress-preview").boundingBox();
  expect(layout && preview, "layout and preview must both have a box").toBeTruthy();

  expect(
    Math.abs(preview!.x - layout!.x),
    "preview is left-pushed off its track",
  ).toBeLessThanOrEqual(1);

  expect(
    Math.abs(preview!.x + preview!.width - (layout!.x + layout!.width)),
    "preview does not fill, or overflows, its track",
  ).toBeLessThanOrEqual(1);

  expect(layout!.x + layout!.width).toBeLessThanOrEqual(viewportWidth + 1);

  const internalOverflow = await page
    .getByTestId("stress-preview")
    .evaluate((el) => el.scrollWidth - el.clientWidth);

  expect(
    internalOverflow,
    "preview content overflows the preview box horizontally",
  ).toBeLessThanOrEqual(1);
}

test.describe("ledger-owned stress structural cells", () => {
  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(
      testInfo.project.name !== "desktop-chromium",
      "ledger-owned stress cells run once on desktop-chromium",
    );

    await page.setViewportSize({ width: CI_CELL_VIEWPORT, height: 900 });
    await login(page);
  });

  for (const item of ciScreenshotAllowlist()) {
    test(`${item.story_id} ${item.theme} ${item.viewport}px holds its ledger-declared structure and geometry`, async ({
      page,
    }) => {
      const contract = CELL_CONTRACTS[item.story_id];
      expect(
        contract,
        `screenshot_allowlist.ci carries ${item.story_id} but this spec declares no structural contract for it — add one rather than letting the cell run unasserted`,
      ).toBeTruthy();

      await page.goto(
        `/audit/__stress?story=${item.story_id}&theme=${item.theme}&viewport=${item.viewport}`,
      );

      const preview = page.getByTestId("stress-preview");
      await expect(preview).toBeVisible();
      await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
        "data-tl-theme",
        item.theme,
      );
      await expect(page.getByTestId("stress-story-id")).toHaveText(item.story_id);

      // Ledger identity actually reaches the rendered cell.
      const values = await ledgerTableValues(preview);
      expect(values["Ledger item"]).toBe(item.ledger_id);
      expect(values["Fixture key"]).toBe(contract.fixtureKey);
      expect(values["Status"]).toBe(contract.status);
      await expect(preview.locator(".tl-stress__preview-title")).toHaveText(
        contract.scenario,
      );
      await expect(preview.locator(".tl-chip")).toHaveText(
        `${item.theme} / ${item.viewport}px`,
      );

      // The fixture's own copy, not the generic fallback; and no loud-fail state.
      await expect(preview.locator(".tl-stress__fixture-preview")).toHaveText(
        contract.body,
      );
      await expect(page.getByTestId("stress-empty-state")).toHaveCount(0);
      await expect(page.locator(".tl-alert--error")).toHaveCount(0);

      // The theme param drives resolved tokens — asserted in both directions, so a
      // stylesheet that stopped applying cannot pass by looking uniformly dark.
      expect(await surfaceLuminance(page)).toBeLessThan(DARK_LUMINANCE_CEILING);
      await page.goto(
        `/audit/__stress?story=${item.story_id}&theme=light&viewport=${item.viewport}`,
      );
      await expect(page.getByTestId("stress-preview")).toBeVisible();
      expect(
        await surfaceLuminance(page),
        "theme=light resolves to the same surface as theme=dark — the theme param is not driving tokens",
      ).toBeGreaterThan(LIGHT_LUMINANCE_FLOOR);
      await page.goto(
        `/audit/__stress?story=${item.story_id}&theme=${item.theme}&viewport=${item.viewport}`,
      );

      // Geometry, plus the responsive contract the 1024 shot implicitly held.
      await expectNoHorizontalOverflow(page);
      await expectPreviewFillsItsTrack(page, CI_CELL_VIEWPORT);
      expect(await gridTrackCount(page, ".tl-stress__layout")).toBe(1);

      await page.setViewportSize({
        width: TWO_COLUMN_BREAKPOINT,
        height: 900,
      });
      expect(
        await gridTrackCount(page, ".tl-stress__layout"),
        `.tl-stress__layout must become two-column at ${TWO_COLUMN_BREAKPOINT}px (style.ex:4223/4248)`,
      ).toBe(2);
      await page.setViewportSize({ width: CI_CELL_VIEWPORT, height: 900 });
    });
  }

  test("page.timeline.empty states its emptiness instead of a bare placeholder", async ({
    page,
  }) => {
    await page.goto(
      "/audit/__stress?story=page.timeline.empty&theme=dark&viewport=1024",
    );
    const body = await page.getByTestId("stress-preview").innerText();

    for (const pattern of FORBIDDEN_PLACEHOLDERS) {
      expect(
        body,
        `empty cell fell back to a bare placeholder matching ${pattern}`,
      ).not.toMatch(pattern);
    }
  });
});

// `footgun.transaction-page-left-push-desktop` is a `status: "reserved"` placeholder
// (stress_fixtures.ex:665-672 -> assigns_for(%{status: "reserved"})), so its retired PNG
// never contained a left-push layout at all. The real desktop-centering invariant lives on
// the REAL transaction page in operator-phase-178-uat.spec.ts. Pin the pointer so this cell
// cannot keep claiming coverage that has been deleted elsewhere.
test("the left-push footgun's real invariant is still asserted in the Phase 178 spec", () => {
  const spec = readFileSync(
    resolve(process.cwd(), "tests/operator-phase-178-uat.spec.ts"),
    "utf8",
  );

  expect(spec).toContain("expectCenteredWithinColumn");
  expect(spec).toContain("DESKTOP_CENTERING_WIDTHS = [1024, 1440]");
});

test.describe("selected Tier C stress state packet", () => {
  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(
      !stressScreenshotOutputDir(),
      "set OPERATOR_STRESS_SCREENSHOT_DIR to capture local-only selected stress packet evidence",
    );
    test.skip(
      testInfo.project.name !== "desktop-chromium",
      "selected stress packet captures one stable desktop local lane",
    );

    await page.setViewportSize({ width: 1024, height: 900 });
    await login(page);
  });

  test("captures selected Tier C stress state packet", async ({ page }) => {
    const outputDir = stressScreenshotOutputDir();
    expect(outputDir).toBeTruthy();
    mkdirSync(outputDir!, { recursive: true });

    for (const storyId of selectedTierCStressStories) {
      expect(
        ledgerEntryForStory(storyId),
        `${storyId} must be represented in the design-system ledger before local packet capture`,
      ).toBeTruthy();

      await page.goto(
        `/audit/__stress?story=${storyId}&theme=dark&viewport=1024`,
      );
      const preview = page.getByTestId("stress-preview");
      await expect(preview).toBeVisible();
      await expect(page.getByTestId("stress-story-id")).toHaveText(storyId);

      await preview.screenshot({
        path: join(outputDir!, stressPacketName(storyId, "dark", 1024)),
        scale: "css",
      });
    }
  });
});

test("ledger CI stress allowlist is bounded, structurally backed, and pixel-free", () => {
  const ci = ciScreenshotAllowlist();

  // The Tier C cell list stays bounded at 3 (MECH-05). Only what backs each cell changed.
  expect(ci).toHaveLength(3);

  for (const item of ci) {
    expect(
      item.structural_ref,
      `${item.story_id} must name the structural cell that asserts it`,
    ).toBeTruthy();
    expect(
      CELL_CONTRACTS[item.story_id],
      `${item.story_id} has no structural contract in this spec`,
    ).toBeTruthy();

    // Retirement is recorded, not silent.
    const retired = item.pixel_baseline_retired;
    expect(retired?.retired_baseline_ref).toBeTruthy();
    expect(retired?.reason).toBeTruthy();
    expect(retired?.evidence_ref).toBeTruthy();

    // Anti-zombie: the retired PNG must be GONE. A re-recorded baseline reappearing on
    // disk means the pixel lane was resurrected without a ledger change.
    expect(
      existsSync(desktopSnapshotPath(retired.retired_baseline_ref)),
      `${retired.retired_baseline_ref} is back on disk — the retired pixel lane was resurrected silently`,
    ).toBe(false);
  }

  // Self-scan (the zero_skips_contract_test idiom, which is Elixir-only and cannot see
  // this file): this spec may not reacquire a pixel-diff for the ledger-owned cells
  // without failing here first.
  const self = readFileSync(
    resolve(process.cwd(), "tests/operator-stress.spec.ts"),
    "utf8",
  );
  expect(self.includes("toHaveScreenshot" + "(")).toBe(false);
});
