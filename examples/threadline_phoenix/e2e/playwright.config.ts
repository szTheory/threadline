import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.E2E_BASE_URL ?? "http://127.0.0.1:4002";

export default defineConfig({
  testDir: "./tests",
  timeout: 120_000,
  snapshotPathTemplate: "{testDir}/{testFilePath}-snapshots/{arg}-{projectName}{ext}",
  expect: { timeout: 15_000 },
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? [["github"], ["list"]] : [["list"]],
  use: {
    baseURL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    // Neutralize the operator surface's CSS motion (via its prefers-reduced-motion
    // rules) so timing/artifacts are deterministic across runs — the one flake
    // risk for a non-pixel-diff suite.
    reducedMotion: "reduce",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
    { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
    // Light-lane affordance re-run (Phase 168, A11Y-02 part 2): colorScheme "light"
    // emulates prefers-color-scheme: light so the served operator surface resolves
    // the [data-tl-theme="system"] light branch. Pair with THREADLINE_E2E_THEME=system
    // (run-e2e.sh) so the mount is served :system; this project re-runs the SAME
    // affordance spec verbatim — proving the affordances are mode-independent.
    {
      name: "desktop-chromium-light",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 }, colorScheme: "light" },
    },
  ],
});
