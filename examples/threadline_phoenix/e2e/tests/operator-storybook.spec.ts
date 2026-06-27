import { expect, Page, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const storybookIndexPath = "/dev/storybook";
const representativeStories = [
  { category: "foundation", path: "/dev/storybook/foundations/index", marker: "Foundation rules" },
  { category: "primitive", path: "/dev/storybook/primitives/button", marker: "Primitive variation groups" },
  { category: "form", path: "/dev/storybook/forms/field", marker: "Form variation groups" },
  { category: "state", path: "/dev/storybook/states/data_state", marker: "Data-state variation groups" },
  { category: "overlay", path: "/dev/storybook/overlays/modal", marker: "Overlay and disclosure contracts" },
  { category: "data display", path: "/dev/storybook/data_display/data_table", marker: "Data Display contracts" },
  { category: "group", path: "/dev/storybook/groups/operator_groups", marker: "Recurring operator groups" },
  { category: "pattern", path: "/dev/storybook/patterns/operator_patterns", marker: "Small operator patterns" },
];
const viewportWidths = [320, 375, 768];

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => {
    const root = document.documentElement;
    return root.scrollWidth - root.clientWidth;
  });

  expect(overflow).toBeLessThanOrEqual(1);
}

async function expectThreadlinePreview(page: Page, marker: string) {
  const preview = page.locator(".threadline-ui[data-tl-theme]").first();

  await expect(preview).toBeVisible();
  await expect(preview).toHaveAttribute("data-tl-theme", /^(dark|light|system)$/);
  await expect(preview).toContainText(marker);
  await expectNoHorizontalOverflow(page);
}

test.describe("operator Storybook maintainer lane", () => {
  test("light/system Playwright lane includes only the bounded Storybook smoke", () => {
    const config = readFileSync(resolve(process.cwd(), "playwright.config.ts"), "utf8");

    expect(config).toContain("desktop-chromium-light");
    expect(config).toContain("operator-storybook\\.spec\\.ts");
    expect(config).not.toContain("operator-.*\\.spec\\.ts");
  });

  test("renders the Storybook index with local assets and Threadline framing", async ({
    page,
  }) => {
    await page.goto(storybookIndexPath);

    await expect(page).toHaveURL(/\/dev\/storybook/);
    await expect(page.locator("body")).toContainText(/Storybook|Threadline/i);
    await expect(
      page.locator(
        '[href*="/dev/storybook/assets"], [src*="/dev/storybook/assets"]',
      ).first(),
    ).toBeAttached();
  });

  for (const story of representativeStories) {
    test(`renders the representative ${story.category} story`, async ({
      page,
    }) => {
      await page.goto(story.path);

      await expectThreadlinePreview(page, story.marker);
    });
  }

  for (const width of viewportWidths) {
    test(`keeps representative stories within the ${width}px viewport`, async ({
      page,
    }) => {
      await page.setViewportSize({ width, height: 900 });

      for (const story of representativeStories) {
        await page.goto(story.path);
        await expectThreadlinePreview(page, story.marker);
      }
    });
  }
});
