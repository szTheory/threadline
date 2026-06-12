// Phase 160 overlay evidence capture (GLYPH-02).
//
// Reuses the EXISTING Playwright install under examples/threadline_phoenix/e2e —
// installs nothing. Node resolves bare imports from the importing file's location,
// never cwd, so a plain `import '@playwright/test'` from this phase dir would fail;
// we resolve through createRequire anchored at the e2e directory instead (same
// pattern text-to-paths.mjs uses for ephemeral fontkit).
//
// Run from any cwd:
//   node .planning/phases/160-glyph-outline-pipeline/tools/capture-overlay.mjs

import module from "node:module";

const E2E_DIR = "/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/";
const PHASE_DIR =
  "/Users/jon/projects/threadline/.planning/phases/160-glyph-outline-pipeline";
const SPECIMEN = `${PHASE_DIR}/overlay-specimen.html`;
const OUT = `${PHASE_DIR}/overlay-evidence-2x.png`;

const require = module.createRequire(E2E_DIR);
const { chromium } = require("@playwright/test");

const browser = await chromium.launch();
try {
  const page = await browser.newPage({
    viewport: { width: 1400, height: 1100 },
    deviceScaleFactor: 2, // the "2x zoom" in overlay-evidence-2x.png
  });
  await page.goto(`file://${SPECIMEN}`);
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: OUT, fullPage: true });
  console.log(`wrote ${OUT}`);
} finally {
  await browser.close();
}
