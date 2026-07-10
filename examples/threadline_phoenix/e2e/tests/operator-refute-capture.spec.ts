import { expect, Page, test } from "@playwright/test";
import { existsSync } from "node:fs";
import { resolve } from "node:path";

// Refute-pole clean re-capture lane (Phase 195-09 follow-up).
//
// The refute-twin poles were originally captured by operator-tier-a-capture.spec.ts
// with `fullPage: true`, so each pole PNG was a ~1280×17000px page dominated by the
// `/audit/__stress` "Internal stress lab" sidebar/header — unusable for the golden-set
// labeling surface (the maintainer judges the twin's DESIGN, not the lab chrome).
//
// This spec re-emits ONLY the 10 refute pole `screenshot.png` binaries, clipped to
// `[data-testid="refute-matrix"]` (the innermost twin content, excluding the lab
// header/sidebar AND the ledger-metadata table). It writes to the SAME gitignored
// paths the committed scorecards already reference, so:
//   - no committed scorecard changes (raw inputs stay byte-identical),
//   - the web labeler + critic:score now see a clean, tight twin render.
//
// Determinism: fixed dark/1280 cell, deviceScaleFactor:1 (project), reducedMotion
// "reduce" (global), fonts.ready before shooting, dynamic masks. Run twice → identical.

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";

const repoRoot = resolve(process.cwd(), "../../..");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/tier-a",
);

const THEME = "dark" as const;
const BREAKPOINT = 1280;

// The 10 refute pole ledger ids (dark/1280 cells) that seed the critic golden set.
// Ledger id → cell id is `${ledgerId}__dark-1280`; the PNG lives under that cell dir.
const REFUTE_POLES = [
  "refute.hierarchy.flattened.polished",
  "refute.hierarchy.flattened.flawed",
  "refute.density.card-section-wrap.polished",
  "refute.density.card-section-wrap.flawed",
  "refute.rhythm.doubled-padding.polished",
  "refute.rhythm.doubled-padding.flawed",
  "refute.typography.scale-collapse.polished",
  "refute.typography.scale-collapse.flawed",
  "refute.brand-fidelity.mis-jobbed-accent.polished",
  "refute.brand-fidelity.mis-jobbed-accent.flawed",
];

function cellId(ledgerId: string): string {
  return `${ledgerId}__${THEME}-${BREAKPOINT}`;
}

function dynamicMasks(page: Page) {
  return [
    page.locator("time"),
    page.locator('[data-dynamic="true"]'),
    page.getByTestId("stress-run-id"),
  ];
}

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function recapturePole(page: Page, ledgerId: string) {
  const id = cellId(ledgerId);
  await page.setViewportSize({ width: BREAKPOINT, height: 900 });
  await page.goto(
    `/audit/__stress?story=${ledgerId}&theme=${THEME}&viewport=${BREAKPOINT}`,
    { waitUntil: "load" },
  );

  await expect(page.getByTestId("stress-story-id")).toHaveText(ledgerId);
  await expect(page.locator(".threadline-ui").first()).toHaveAttribute(
    "data-tl-theme",
    THEME,
  );

  // The twin content (excludes lab header/sidebar AND the ledger-metadata table).
  const matrix = page.getByTestId("refute-matrix");
  await expect(matrix).toBeVisible();
  await page.evaluate(() =>
    (document as unknown as { fonts: { ready: Promise<unknown> } }).fonts.ready,
  );

  // Overwrite the gitignored PNG in place — same path the committed scorecard cites.
  const artifactDir = resolve(artifactsRoot, id);
  await matrix.screenshot({
    path: resolve(artifactDir, "screenshot.png"),
    scale: "css",
    mask: dynamicMasks(page),
  });
}

test.describe("operator refute pole clean re-capture", () => {
  test("re-emits the 10 refute pole PNGs clipped to the twin content", async ({
    page,
  }, testInfo) => {
    test.skip(
      testInfo.project.name !== "refute-capture",
      "Refute re-capture runs only under the refute-capture project",
    );
    test.setTimeout(300_000);

    // Every pole's cell dir must already exist (its committed scorecard was emitted
    // by the Tier-A lane); we only replace the screenshot binary, never the dir.
    for (const ledgerId of REFUTE_POLES) {
      const dir = resolve(artifactsRoot, cellId(ledgerId));
      expect(
        existsSync(dir),
        `missing tier-a cell dir for ${ledgerId} — run the tier-a-capture lane first`,
      ).toBe(true);
    }

    await login(page);
    for (const ledgerId of REFUTE_POLES) {
      await recapturePole(page, ledgerId);
    }
  });
});
