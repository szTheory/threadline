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
  // Tier A deterministic capture lane (Phase 194, MECH-04). Two projects — one per
  // theme — drive operator-tier-a-capture.spec.ts at the 1280 desktop breakpoint;
  // the spec resizes to 375/768 per cell via page.setViewportSize. deviceScaleFactor:1
  // is set at PROJECT level (never global) so it does not perturb the 3 existing
  // Tier C 1024 baselines (Pitfall 5). reducedMotion:"reduce" is already global.
  {
    name: "tier-a-capture",
    testMatch: /operator-tier-a-capture\.spec\.ts/,
    use: {
      ...devices["Desktop Chrome"],
      viewport: { width: 1280, height: 900 },
      deviceScaleFactor: 1,
      colorScheme: "dark" as const,
    },
  },
  {
    name: "tier-a-capture-light",
    testMatch: /operator-tier-a-capture\.spec\.ts/,
    use: {
      ...devices["Desktop Chrome"],
      viewport: { width: 1280, height: 900 },
      deviceScaleFactor: 1,
      colorScheme: "light" as const,
    },
  },
  ...(lightLane
    ? [
        {
          name: "desktop-chromium-light",
          testMatch: [
            /operator-(accessibility|motion|screenshots|screenshot-regression|stress)\.spec\.ts/,
            /operator-shell-home-phase183\.spec\.ts/,
            /operator-coverage-readiness\.spec\.ts/,
            /operator-storybook\.spec\.ts/,
            /operator-timeline-investigation-flow\.spec\.ts/,
            /operator-phase-177-uat\.spec\.ts/,
            /operator-phase-178-uat\.spec\.ts/,
          ],
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
