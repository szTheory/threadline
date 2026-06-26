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

test.describe("ledger-owned stress screenshots", () => {
  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(
      testInfo.project.name !== "desktop-chromium",
      "stress screenshot ratchet runs only on desktop-chromium",
    );

    await page.setViewportSize({ width: 1024, height: 900 });
    await login(page);
  });

  for (const item of ciScreenshotAllowlist()) {
    test(`${item.story_id} ${item.theme} ${item.viewport}px matches its ledger baseline`, async ({
      page,
    }) => {
      await page.goto(
        `/audit/__stress?story=${item.story_id}&theme=${item.theme}&viewport=${item.viewport}`,
      );
      const preview = page.getByTestId("stress-preview");
      await expect(preview).toBeVisible();
      await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
        "data-tl-theme",
        item.theme,
      );
      await expect(page.getByTestId("stress-story-id")).toHaveText(
        item.story_id,
      );

      await expect(preview).toHaveScreenshot(item.baseline_ref, {
        maxDiffPixelRatio: 0.01,
        mask: dynamicMasks(page),
      });
    });
  }
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

test("ledger CI screenshot allowlist is bounded and baseline-backed", () => {
  const ci = ciScreenshotAllowlist();

  expect(ci).toHaveLength(3);

  for (const item of ci) {
    expect(item.baseline_ref).toBeTruthy();
    expect(existsSync(desktopSnapshotPath(item.baseline_ref))).toBe(true);
  }
});
