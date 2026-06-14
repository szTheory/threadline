import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.E2E_BASE_URL ?? "http://127.0.0.1:4002";

// Light-lane affordance re-run (Phase 168, A11Y-02 part 2). The light project is
// registered ONLY when the example app is compiled to serve the :system lane
// (THREADLINE_E2E_THEME=system) and is scoped to the affordance spec, so:
//   - a default (dark) run never executes a misnamed "light" project against the
//     dark mount (no false-confidence pass), and
//   - the dark projects are never dragged onto a :system mount.
// run-e2e.sh sets the env and targets --project=desktop-chromium-light for this
// lane (use `mix verify.example_browser_light`).
const lightLane = process.env.THREADLINE_E2E_THEME === "system";

const projects = [
  { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
  ...(lightLane
    ? [
        {
          name: "desktop-chromium-light",
          testMatch: /operator-(accessibility|screenshots|screenshot-regression|stress)\.spec\.ts/,
          use: {
            ...devices["Desktop Chrome"],
            viewport: { width: 1280, height: 900 },
            colorScheme: "light" as const,
          },
        },
      ]
    : []),
];

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
  projects,
});
