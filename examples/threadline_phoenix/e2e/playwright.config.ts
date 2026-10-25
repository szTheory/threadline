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

// The bare `chromium` project was deleted in Phase 198 (D-15 step 1). It was
// `devices["Desktop Chrome"]` with no viewport override — i.e. desktop-chromium
// at 1280x720 instead of 1280x900 — and it carried ZERO snapshot baselines: both
// specs that assert on snapshots already excluded it by name
// (operator-screenshot-regression.spec.ts:83 `test.skip(... === "chromium")`,
// operator-stress.spec.ts:268 `!== "desktop-chromium"`). Deleting it removes ~a
// third of the browser lane's serialized invocations for zero coverage loss.
const projects = [
  { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
  // Route render smoke (Phase 196; Browser-full's only project since 246). Drives
  // operator-page-capture.spec.ts against the seeded, authed /audit/* routes at
  // 1280/768/375 and, in evidence mode, writes the route scorecards. deviceScaleFactor:1
  // at project level; dark hero view.
  {
    name: "route-capture",
    testMatch: /operator-page-capture\.spec\.ts/,
    use: {
      ...devices["Desktop Chrome"],
      viewport: { width: 1280, height: 900 },
      deviceScaleFactor: 1,
      colorScheme: "dark" as const,
      contextOptions: { reducedMotion: "reduce" as const },
    },
  },
  ...(lightLane
    ? [
        {
          name: "desktop-chromium-light",
          testMatch: [
            /operator-(accessibility|motion|screenshots|screenshot-regression|stress)\.spec\.ts/,
            /operator-shell-home\.spec\.ts/,
            /operator-coverage-readiness\.spec\.ts/,
            /operator-storybook\.spec\.ts/,
            /operator-timeline-investigation-flow\.spec\.ts/,
            /operator-component-contracts\.spec\.ts/,
            /operator-phase-178-uat\.spec\.ts/,
            /operator-route-states\.spec\.ts/,
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
  // Systemic-break bound (Phase 198, D-18). A broken operator mount used to make
  // every one of ~382 serialized invocations burn its own 120s timeout, which is
  // where the ~1h33m CI wall clock came from. Abort after 5 failures on CI;
  // unbounded (0) locally, where a developer wants the whole picture.
  //
  // Deliberately maxFailures, NOT `-x`/bail-on-first-failure: the `trace:`
  // setting below only pays off if more than one failure is allowed to happen.
  // Failing fast and DIAGNOSING fast are different requirements — five retained
  // traces are a diagnostic sample, one is an anecdote.
  maxFailures: process.env.CI ? 5 : 0,
  workers: 1,
  reporter: process.env.PLAYWRIGHT_JSON_OUTPUT_FILE
    ? [["github"], ["json"]]
    : process.env.CI
      ? [["github"], ["list"]]
      : [["list"]],
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
