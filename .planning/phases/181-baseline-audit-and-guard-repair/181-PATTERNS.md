# Phase 181: Baseline audit and guard repair - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md` | documentation | batch, transform | `.planning/milestones/v1.37-MILESTONE-AUDIT.md` | role-match |
| `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` | documentation | file-I/O, batch | `.planning/milestones/v1.31-phases/143-accessibility-consistency-sweep-regression/143-SCREENSHOT-DIFF.md` | role-match |
| `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` | documentation | transform, request-response | `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-AUTOMATED-A11Y-EVIDENCE.md` | role-match |
| `.planning/phases/181-baseline-audit-and-guard-repair/181-VERIFICATION.md` | documentation | batch | `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` | test | request-response, file-I/O | `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | test | request-response, file-I/O | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` | test | request-response, file-I/O | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` | exact |
| `test/threadline/operator_surface/stress_ledger_test.exs` | test | file-I/O, transform | `test/threadline/operator_surface/stress_ledger_test.exs` | exact |
| `test/threadline/operator_surface/stress_fixtures_test.exs` | test | transform | `test/threadline/operator_surface/stress_fixtures_test.exs` | exact |
| `test/threadline/operator_surface/stress_router_test.exs` | test | request-response | `test/threadline/operator_surface/stress_router_test.exs` | exact |
| `test/threadline/operator_surface/surface_header_test.exs` | test | transform, request-response | `test/threadline/operator_surface/surface_header_test.exs` | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | test | transform | `test/threadline/operator_surface/style_contract_test.exs` | exact |
| `lib/threadline/operator_surface/stress_fixtures.ex` | service | transform | `lib/threadline/operator_surface/stress_fixtures.ex` | exact |
| `lib/threadline/operator_surface/live/stress_live.ex` | component | request-response | `lib/threadline/operator_surface/live/stress_live.ex` | exact |
| `lib/threadline/operator_surface/components/surface_header.ex` | component | request-response | `lib/threadline/operator_surface/components/surface_header.ex` | exact |
| `lib/threadline/operator_surface/router.ex` | route | request-response | `lib/threadline/operator_surface/router.ex` | exact |
| `lib/threadline/operator_surface/style.ex` | config | transform | `lib/threadline/operator_surface/style.ex` | exact |
| `.planning/design-system-ledger.json` | config | file-I/O, batch | `.planning/design-system-ledger.json` | exact |
| `DESIGN-SYSTEM.md` | documentation | transform | `DESIGN-SYSTEM.md` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |

## Pattern Assignments

### `.planning/phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md` (documentation, batch/transform)

**Analog:** `.planning/milestones/v1.37-MILESTONE-AUDIT.md`

**Front matter and closeout metadata pattern** (lines 1-25):
```markdown
---
milestone: v1.37
milestone_name: Operator Surface Design-System Stress Test & Component System
audited: 2026-06-20T09:45:00-04:00
status: passed
scope: closeout
scores:
  requirements: 33/33
  phases: 10/10
  plans: 47/47
  integration: passed-with-inherited-ci-residuals
  flows: passed-with-bounded-automation
gaps:
  requirements: []
  integration: []
  flows: []
intentional_deferrals:
  - "DATA-04 Redact destructive flow remains deferred by recorded checkpoint; no runtime backend exists without touching capture, which v1.37 explicitly forbids."
  - "No real assistive-technology UAT is claimed; Phase 180 replaced the manual checkpoint with bounded Playwright accessibility-tree evidence and explicit proof limits."
  - "mix ci.all remains non-green only for inherited Phase 179 documentation/demo-seed failures classified in 180-RESIDUAL-CI.md."
---
```

**Requirement/page matrix pattern** (lines 33-46):
```markdown
## Requirements Coverage

| Bucket | Reqs | Status |
|---|---:|---|
| DS-01..06 | 6 | Complete |
| COMP-01..06 | 6 | Complete |
| NAV-01..04 | 4 | Complete |
| DATA-01..05 | 5 | Complete |
| GROUP-01..02 | 2 | Complete |
| PAGE-01..03 | 3 | Complete |
| COPY-01..03 | 3 | Complete |
| A11Y-01..02 | 2 | Complete |
| MOTION-01..02 | 2 | Complete |
| Total | 33 | 33/33 complete |
```

**Evidence and deferral pattern** (lines 65-80):
```markdown
## Closeout Evidence

- `180-VERIFICATION.md` closes A11Y-01, A11Y-02, MOTION-01, and MOTION-02 with tiered proof.
- `180-AUTOMATED-A11Y-EVIDENCE.md` records browser accessibility-tree evidence and explicitly bounds what it proves.
- `180-ADVERSARIAL-REVIEW.md` records the final adversarial pass with no blocking Phase 180 issue remaining.
- `180-RESIDUAL-CI.md` classifies remaining `mix ci.all` failures as inherited Phase 179 documentation/demo-seed residuals, not Phase 180-owned regressions.

## Known Deferred Items

| Item | Closeout handling |
|---|---|
```

Apply this shape to the Phase 181 page/JTBD matrix. Replace requirement buckets with the 11 `/audit` surfaces, route/render evidence, issue taxonomy, guard disposition, and later-phase owner.

---

### `.planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md` (documentation, file-I/O/batch)

**Analog:** `.planning/milestones/v1.31-phases/143-accessibility-consistency-sweep-regression/143-SCREENSHOT-DIFF.md`

**Capture command and matrix pattern** (lines 3-10):
```markdown
## Capture

- Baseline: `.planning/milestones/v1.31-screenshots/baseline/`
- Final: `.planning/milestones/v1.31-screenshots/final/`
- Matrix: 12 screens x 2 viewports = 24 baseline PNGs and 24 final PNGs.
- Final capture command:
  - `cd examples/threadline_phoenix/e2e && OPERATOR_SCREENSHOT_DIR=/Users/jon/projects/threadline/.planning/milestones/v1.31-screenshots/final E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-screenshots.spec.ts`
- Result: 6 tests, 0 failures.
```

**Per-screen disposition table pattern** (lines 14-27):
```markdown
| Screen | 1280 baseline -> final | 375 baseline -> final | Delta | Status |
|---|---:|---:|---|---|
| home | 1280x900 -> 1280x1130 | 375x1111 -> 375x1905 | Intentional: Phase 139 Home/nav orientation plus Phase 140 EF1/EF4 workflow launchers add content below the hero. | explained |
| timeline | 1280x3928 -> 1280x3959 | 375x8312 -> 375x8463 | Intentional: Phase 138 find polish adds richer row values, empty/future copy support, and stable refs. | explained |
```

**Unexplained-delta closure pattern** (lines 29-37):
```markdown
## Unchanged Surfaces

- Desktop 900px-height screens that remain same-height: Actor, Retention, Row history, Transaction.
- Final file names match the Phase 134 baseline naming scheme exactly.
- No generated Playwright `test-results` screenshot artifacts are part of the durable final matrix.

## Unexplained Deltas

None. Every final delta is intentional and traced to phases 135-143.
```

Also copy the screenshot capture helper from `operator-screenshots.spec.ts` when documenting local packet output.

**Capture helper** (`examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` lines 34-54):
```typescript
async function capture(page: Page, testInfo: TestInfo, name: string) {
  await page.waitForLoadState("networkidle");
  await page.screenshot({
    path: testInfo.outputPath(`${name}.png`),
    fullPage: true,
  });

  const outputDir = process.env.OPERATOR_SCREENSHOT_DIR;
  const viewport = screenshotViewport(testInfo);
  if (outputDir && viewport && durableScreenshotNames.has(name)) {
    mkdirSync(outputDir, { recursive: true });
    const laneInfix =
      testInfo.project.name === "desktop-chromium-light" ? "__light__" : "__default__";
    await page.screenshot({
      path: join(outputDir, `${name}${laneInfix}${viewport}.png`),
      fullPage: true,
      scale: "css",
    });
  }
}
```

---

### `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` (documentation, transform/request-response)

**Analog:** `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-AUTOMATED-A11Y-EVIDENCE.md`

**Scope and proof-limits pattern** (lines 11-16):
```markdown
## Scope

This artifact replaces the originally planned manual screen-reader checkpoint with deterministic browser evidence. It records what Playwright proved and what it did not prove.

No real screen reader, assistive-technology pairing, or human UAT session was run or claimed.
```

**Surfaces-tested table pattern** (lines 27-37):
```markdown
## Surfaces Tested

| Surface | Evidence |
|---------|----------|
| Home | Main landmark, H1, system-health status, Timeline link, table combobox, record-id textbox, row-history action |
| Timeline filters | Investigation region, primary filters, advanced filters drawer, search grouping, status output |
| Row-history drawer | Dialog role/name, close link, snapshot-at input, row timeline list |
```

**Limits section pattern** (lines 56-65):
```markdown
## Limits Of Proof

This evidence proves that the sampled rendered states expose expected roles, names, headings, controls, expanded state, dialog/drawer structure, status/alert structure, and keyboard focus behavior in Chromium's accessibility tree.

This evidence does not prove:

- Real screen-reader announcement timing or verbosity.
- Rotor/quick-nav behavior in VoiceOver, NVDA, JAWS, Narrator, or TalkBack.
- User comprehension or operator task success with assistive technology.
```

For stale guard repairs, copy the "source/failure message is the contract" style from `stress_fixtures_test.exs`, but update stale RED comments when the invariant is now green.

**Stale guard source-comment pattern to repair** (`test/threadline/operator_surface/stress_fixtures_test.exs` lines 390-400):
```elixir
# --- Phase 178 (PAGE-01 / D-04): page-story reserved -> current conversion --
#
# RED Wave-0 scaffold. The 11 `page.<x>.reserved` entries (status "reserved",
# cases ["warning"]) are PAGE-01's worklist. D-04 converts each into a real
# fixture-backed CURRENT path story carrying the 7 audit paths
# (happy/empty/loading/error/permission/boundary/advanced).
```

---

### `.planning/phases/181-baseline-audit-and-guard-repair/181-VERIFICATION.md` (documentation, batch)

**Analog:** `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md`

**Front matter and verdict pattern** (lines 1-13):
```markdown
---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
verified: 2026-06-20
status: passed-with-inherited-ci-residuals
requirements: [A11Y-01, A11Y-02, MOTION-01, MOTION-02]
---

# Phase 180 Verification

## Verdict

Phase 180 is complete. The targeted accessibility, APG, motion, stress, screenshot, and adversarial guardrails pass.
```

**Tiered proof table pattern** (lines 14-20):
```markdown
| Tier | Evidence | Proves | Does Not Prove |
|------|----------|--------|----------------|
| Tier A: Source contracts | ExUnit style/component/UI/stress/router/card/retention tests | Tokens, APG/source contracts, no card nesting regression, stress fixture/ledger/router continuity, retention modal server-side test alignment | Browser rendering, screenshots, real AT behavior |
| Tier B: Browser rendered checks | Playwright accessibility, motion, Phase 178 UAT, stress, screenshot regression specs | Rendered role/name/focus behavior, keyboard reachability samples, motion/reduced-motion computed styles, route/socket/drop/overlay stability, screenshot baseline stability | Every possible data row, browser, OS, host app, or assistive technology |
| Tier C: Automated accessibility-tree evidence | Playwright ARIA snapshots attached from `operator-accessibility.spec.ts` | Sampled Home, Timeline, row-history drawer, stress menu/modal/drawer expose expected browser accessibility-tree structure | Real screen-reader announcement timing, verbosity, rotor behavior, or human UAT |
```

**Command/result pattern** (lines 22-31):
```markdown
## Verification Commands

| Command | Result |
|---------|--------|
| `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` | 15 tests, 0 failures |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts tests/operator-motion.spec.ts tests/operator-phase-178-uat.spec.ts tests/operator-stress.spec.ts` | 150 passed, 6 skipped |
| `mix ci.all` | Root: 1120 tests, 1 failure, 1 excluded. Example: 95 tests, 7 failures. Residuals inherited and classified. |
```

**Requirement closure pattern** (lines 33-44):
```markdown
## Requirement Closure

| Requirement | Status | Evidence |
|-------------|--------|----------|
| A11Y-01 | Complete | Rendered keyboard/focus checks plus ARIA accessibility-tree snapshots in `operator-accessibility.spec.ts`; bounded in `180-AUTOMATED-A11Y-EVIDENCE.md`. |

## Residual Risk

The only residual CI risk is inherited demo/documentation drift from Phase 179. The only accessibility proof gap is that no real screen-reader/human UAT run occurred.
```

---

### `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` (test, request-response/file-I/O)

**Analog:** same file

**Imports and durable matrix pattern** (lines 1-23):
```typescript
import { test, expect, Page, TestInfo } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const durableScreenshotNames = new Set([
  "actor",
  "coverage",
  "evidence",
  "exports",
  "home",
  "redaction",
  "retention",
  "row-history",
  "timeline",
  "timeline-dense",
  "timeline-empty",
  "transaction",
]);
```

**Auth helper pattern** (lines 25-32):
```typescript
async function login(page: Page, email = adminEmail) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(email);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}
```

**Route/render evidence pattern** (lines 85-151):
```typescript
test("admin investigation and governance surfaces", async ({ page }, testInfo) => {
  await login(page);

  await page.goto("/audit");
  await expect(page.getByTestId("operator-header")).toBeVisible();
  await capture(page, testInfo, "home");

  await page.goto("/audit/timeline");
  await expect(page.getByTestId("operator-header")).toBeVisible();
  await capture(page, testInfo, "timeline");

  await page.goto("/audit/evidence");
  await expect(page.getByTestId("evidence-table").first()).toBeVisible();
  await capture(page, testInfo, "evidence");

  await page.goto("/audit/exports");
  await expect(page.getByRole("heading", { name: "Exports" })).toBeVisible();
  await capture(page, testInfo, "exports");
});
```

Use this file as the primary source for Tier C local screenshot packet generation. Keep route paths and durable names stable unless a later phase explicitly owns a breaking change.

---

### `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` (test, request-response/file-I/O)

**Analog:** same file

**Ledger-backed imports and allowlist pattern** (lines 1-35):
```typescript
import { expect, Page, test } from "@playwright/test";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";

const viewportWidths = [320, 375, 768, 1024, 1440];
const ledgerPath = resolve(process.cwd(), "../../..", ".planning/design-system-ledger.json");
const expectedCiScreenshots = [
  {
    baseline_ref: "stress-page-home-happy-dark-1024.png",
    ledger_id: "page.home.happy",
    story_id: "page.home.happy",
    theme: "dark",
    viewport: 1024,
  },
];
```

**Dynamic mask pattern** (lines 51-56):
```typescript
function dynamicMasks(page: Page) {
  return [
    page.locator("time"),
    page.locator('[data-dynamic="true"]'),
    page.getByTestId("stress-run-id"),
  ];
}
```

**Auth and semantic stress route pattern** (lines 77-108):
```typescript
test.describe("operator stress route semantics", () => {
  test("requires authentication before rendering the stress lab", async ({ page }) => {
    await page.goto("/audit/__stress");

    await expect(page).toHaveURL(/\/users\/log_in/);
    await expect(page.getByTestId("stress-lab")).toHaveCount(0);
  });

  test("renders the real operator shell, theme scope, story metadata, and preview", async ({ page }) => {
    await page.goto("/audit/__stress?story=page.timeline.empty");

    await expect(page.getByTestId("operator-header")).toBeVisible();
    const shell = page.locator(".threadline-ui").first();
    await expect(shell).toHaveAttribute("data-tl-theme", /^(dark|light|system)$/);
    await expect(page.getByTestId("stress-preview")).toBeVisible();
  });
});
```

**Bounded screenshot ratchet pattern** (lines 256-301):
```typescript
test.describe("ledger-owned stress screenshots", () => {
  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(
      testInfo.project.name !== "desktop-chromium",
      "stress screenshot ratchet runs only on desktop-chromium",
    );

    await page.setViewportSize({ width: 1024, height: 900 });
    await login(page);
  });

  for (const item of expectedCiScreenshots) {
    test(`${item.story_id} ${item.theme} ${item.viewport}px matches its ledger baseline`, async ({ page }) => {
      await page.goto(`/audit/__stress?story=${item.story_id}&theme=${item.theme}&viewport=${item.viewport}`);
      const preview = page.getByTestId("stress-preview");
      await expect(preview).toHaveScreenshot(item.baseline_ref, {
        maxDiffPixelRatio: 0.01,
        mask: dynamicMasks(page),
      });
    });
  }
});
```

---

### `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` (test, request-response/file-I/O)

**Analog:** same file

**Semantic discovery over brittle seed constants** (lines 16-39):
```typescript
async function discoverRowHistoryHref(page: Page) {
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
  await expect(page.locator("#filter-table")).toHaveValue(rowTable);

  const transactionLink = page
    .getByTestId("timeline-row")
    .filter({ hasText: rowTable })
    .first()
    .getByTestId("transaction-link");
  await expect(transactionLink).toBeVisible();
  const transactionHref = await transactionLink.getAttribute("href");
  expect(transactionHref).not.toBeNull();
  await page.goto(transactionHref!);
}
```

**Local-only screenshot guard pattern** (lines 76-99):
```typescript
test.describe("operator screenshot regression guard", () => {
  test.skip(
    !!process.env.CI,
    "visual screenshot baselines are platform-sensitive; run this guard locally before updating PNG snapshots",
  );

  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");

    if (testInfo.project.name === "desktop-chromium") {
      await page.setViewportSize({ width: 1280, height: 900 });
    }

    await login(page);
  });
});
```

**Role/test-id assertion mix pattern** (lines 127-141):
```typescript
test("Retention safety hierarchy stays stable", async ({ page }) => {
  await page.goto("/audit/policy/retention");
  await expect(page.getByRole("heading", { name: "Retention window" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Run retention prune" }).last()).toBeVisible();
  await expectOperatorScreenshot(page, "retention");
});
```

---

### `test/threadline/operator_surface/stress_ledger_test.exs` (test, file-I/O/transform)

**Analog:** same file

**Optional LiveView dependency guard and file paths** (lines 1-9):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressLedgerTest do
    use ExUnit.Case, async: true

    alias Threadline.OperatorSurface.StressFixtures

    @ledger_path ".planning/design-system-ledger.json"
    @design_system_path "DESIGN-SYSTEM.md"
```

**Ledger schema and forbidden-term pattern** (lines 10-69):
```elixir
@top_level_keys ~w(
  entries
  phase
  ratchet
  ratchet_rule
  required_inventory
  screenshot_allowlist
  version
)

@forbidden_terms [
  "---",
  "PhoenixStorybook",
  "Tailwind",
  "Chromatic",
  "Percy",
  "Applitools",
  "immutable ledger"
]
```

**Ratchet and parity tests** (lines 101-199):
```elixir
test "scores can only ratchet upward unless an explicit reset is recorded" do
  ledger = ledger()
  reset_ids = Map.get(ledger["ratchet"], "resets", [])

  for entry <- ledger["entries"] do
    id = entry["id"]

    if entry["current_score"] < entry["ratchet_score"] do
      assert id in reset_ids,
             "#{id} lowered current_score below ratchet_score without being listed in ratchet.resets"

      assert is_binary(entry["reset_rationale"]) and entry["reset_rationale"] != "",
             "#{id} lowered current_score below ratchet_score without a reset_rationale"
    else
      assert entry["current_score"] >= entry["ratchet_score"]
    end
  end
end
```

**Projection freshness pattern** (lines 201-218):
```elixir
test "DESIGN-SYSTEM projection is fresh for every ledger row" do
  markdown = design_system()

  for entry <- entries() do
    row = inventory_row(entry)

    assert String.contains?(markdown, row),
           "#{@design_system_path} is stale for #{entry["id"]}; missing row #{inspect(row)}"
  end
end
```

---

### `.planning/design-system-ledger.json` and `DESIGN-SYSTEM.md` (config/documentation, file-I/O/transform)

**Analogs:** same files

**Projection rule** (`DESIGN-SYSTEM.md` lines 1-8):
```markdown
# Threadline Operator Surface Design System

This inventory is projected from `.planning/design-system-ledger.json`. Update the JSON ledger first, then keep this table projection fresh.

## Ratchet Rule

Scores may only stay level or increase unless an explicit reset with rationale is recorded in the ledger. Locked entries cannot be silently removed, and minimum scores are enforced by `mix test test/threadline/operator_surface/stress_ledger_test.exs`.
```

**Ratchet rule and locked IDs** (`.planning/design-system-ledger.json` lines 2104-2351):
```json
"ratchet": {
  "locked_ids": [
    "footgun.coverage-schema-card-declutter",
    "footgun.transaction-page-left-push-desktop",
    "page.home.happy",
    "page.timeline.empty"
  ],
  "minimum_scores": {
    "footgun.transaction-page-left-push-desktop": 25,
    "page.home.happy": 72,
    "page.timeline.empty": 72
  },
  "resets": {}
},
"ratchet_rule": "Scores may only stay level or increase unless an explicit reset with rationale is recorded in ratchet.resets and reset_rationale."
```

**Screenshot allowlist shape** (`.planning/design-system-ledger.json` lines 2411-2458):
```json
"screenshot_allowlist": {
  "ci": [
    {
      "baseline_ref": "stress-page-home-happy-dark-1024.png",
      "ledger_id": "page.home.happy",
      "story_id": "page.home.happy",
      "theme": "dark",
      "viewport": 1024
    }
  ],
  "local_review": [
    {
      "baseline_ref": "stress-page-home-happy-dark-1024.png",
      "ledger_id": "page.home.happy",
      "story_id": "page.home.happy",
      "theme": "dark",
      "viewport": 1024
    }
  ]
}
```

---

### `test/threadline/operator_surface/stress_fixtures_test.exs` and `lib/threadline/operator_surface/stress_fixtures.ex` (test/service, transform)

**Analogs:** same files

**Fixture registry contract** (`test/threadline/operator_surface/stress_fixtures_test.exs` lines 155-183):
```elixir
test "required_cases returns the DS-04 ugly-data matrix in sorted order" do
  assert StressFixtures.required_cases() == @required_cases
end

test "theme modes and viewport matrix are fixed" do
  assert StressFixtures.theme_modes() == ["dark", "light", "system"]
  assert StressFixtures.viewports() == [320, 375, 768, 1024, 1440]
end

test "every story exposes the canonical fixture contract" do
  stories = StressFixtures.all()

  for story <- stories do
    assert is_binary(story.id), "story id must be a string: #{inspect(story)}"
    assert is_binary(story.kind), "#{story.id} kind must be a string"
    assert is_binary(story.category), "#{story.id} category must be a string"
    assert integer_list?(story.viewports), "#{story.id} viewports must be a list of integers"
  end
end
```

**Package-free source guard** (`test/threadline/operator_surface/stress_fixtures_test.exs` lines 220-242):
```elixir
test "fixture registry source stays synthetic and package-free" do
  source = File.read!(@source_path)

  forbidden = [
    "ThreadlinePhoenix",
    "Repo.",
    "Ecto.Query",
    "String.to_atom",
    "PhoenixStorybook",
    "Tailwind"
  ]

  for term <- forbidden do
    refute source =~ term, "stress fixture source must not reference #{term}"
  end
end
```

**Page/JTBD structural matrix source** (`lib/threadline/operator_surface/stress_fixtures.ex` lines 98-135):
```elixir
@page_subjects ~w(
  actor
  coverage
  evidence
  exports
  home
  redaction
  retention
  row-history
  shell
  timeline
  transaction
)

@page_paths [
  {"happy", ["one", "many", "mixed_severity"]},
  {"empty", ["empty", "zero_count"]},
  {"loading", ["reconnecting", "stale"]},
  {"error", ["error"]},
  {"permission", ["permission_denied"]},
  {"boundary", ["pagination_boundary", "timezone_boundary"]},
  {"advanced", ["non_ascii", "null_fields"]}
]
```

**Story builder pattern** (`lib/threadline/operator_surface/stress_fixtures.ex` lines 573-596):
```elixir
defp story(attrs) do
  id = Map.fetch!(attrs, :id)

  %{
    id: id,
    kind: Map.fetch!(attrs, :kind),
    category: Map.fetch!(attrs, :category),
    scenario: Map.fetch!(attrs, :scenario),
    fixture_key: Map.fetch!(attrs, :fixture_key),
    ledger_id: Map.get(attrs, :ledger_id, id),
    cases: Map.fetch!(attrs, :cases) |> Enum.sort(),
    themes: @theme_modes,
    viewports: @viewports,
    owner_phase: Map.get(attrs, :owner_phase, 171),
    status: Map.fetch!(attrs, :status),
    data: Map.fetch!(attrs, :data),
    metadata:
      %{synthetic: true, source: "Threadline.OperatorSurface.StressFixtures"}
      |> Map.merge(Map.get(attrs, :metadata, %{}))
  }
end
```

---

### `test/threadline/operator_surface/stress_router_test.exs`, `lib/threadline/operator_surface/router.ex`, and `lib/threadline/operator_surface/live/stress_live.ex` (test/route/component, request-response)

**Analogs:** same files

**Router macro auth and theme validation** (`lib/threadline/operator_surface/router.ex` lines 59-73):
```elixir
defmacro threadline_operator_surface(path, opts \\ []) do
  has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
  has_actor_fn? = Keyword.has_key?(opts, :actor_fn)
  has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
  exports_enabled? = Keyword.get(opts, :exports, true)
  theme = Keyword.get(opts, :theme, :dark)

  unless theme in [:dark, :light, :system] do
    raise CompileError,
      file: caller_file,
      line: caller_line,
      description: "Threadline Operator Surface theme must be one of :dark | :light | :system"
  end
```

**Route registration pattern** (`lib/threadline/operator_surface/router.ex` lines 102-123):
```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", StartLive, :index)
    live("/timeline", TimelineLive, :index)
    live("/evidence", EvidenceLive, :index)
    live("/coverage", CoverageLive, :index)
    live("/exports", ExportStatusLive, :index)
    live("/policy/redaction", PolicyRedactionLive, :index)
    live("/policy/retention", RetentionHistoryLive, :index)
    live("/rows/:table/:record_id", RowHistoryLive, :show)
    live("/transactions/:id", TransactionLive, :show)
    live("/actors/:kind/:id", ActorLive, :show)
  end
end
```

**Stress route prod/auth guard tests** (`test/threadline/operator_surface/stress_router_test.exs` lines 189-258, 337-345):
```elixir
test "private prod stress_env hook raises at compile time and normal hook compiles" do
  assert_raise CompileError,
               ~r/Threadline stress surface is dev\/test-only/,
               fn ->
                 Code.compile_quoted(
                   quote do
                     defmodule Threadline.OperatorSurface.StressRouterTest.ProdHookRouter do
                       use Phoenix.Router
                       require Threadline.OperatorSurface.StressRouter

                       Threadline.OperatorSurface.StressRouter.threadline_operator_surface_stress(
                         "/__stress",
                         stress_env: :prod,
                         authorize_fn: &__MODULE__.authorize/1
                       )
                     end
                   end
                 )
               end
end

test "unauthenticated stress LiveView access follows the operator auth path", %{conn: conn} do
  Application.put_env(:threadline, :stress_router_authorized, false)

  assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/audit/__stress")

  conn = get(conn, "/audit/__stress")
  assert redirected_to(conn) == "/"
  refute response(conn, 302) =~ ~s|data-testid="stress-lab"|
end
```

**StressLive param allowlist and error handling** (`lib/threadline/operator_surface/live/stress_live.ex` lines 35-70, 488-554):
```elixir
def handle_params(params, uri, socket) do
  {ledger_entries, ledger_error} = load_ledger_entries()
  stories = ledger_stories(ledger_entries)
  categories = stories |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()

  filter_category = allow(params["category"], @category_allowlist)
  filter_status = allow(params["status"], @status_allowlist)
  selected_theme = allow(params["theme"], @theme_allowlist) || socket.assigns.threadline_theme
  selected_viewport = allow(params["viewport"], @viewport_allowlist) || "1024"

  {:noreply, assign(socket, :ledger_error, ledger_error)}
end

defp load_ledger_entries do
  case ledger_path() do
    nil -> {[], "missing ledger"}
    path ->
      try do
        entries = path |> File.read!() |> Jason.decode!() |> Map.fetch!("entries")
        {entries, nil}
      rescue
        _ -> {[], "invalid ledger"}
      end
  end
end

defp allow(value, allowed) when is_binary(value) do
  if value in allowed, do: value, else: nil
end
```

---

### `test/threadline/operator_surface/surface_header_test.exs` and `lib/threadline/operator_surface/components/surface_header.ex` (test/component, request-response/transform)

**Analogs:** same files

**Component attrs and stable hook pattern** (`lib/threadline/operator_surface/components/surface_header.ex` lines 16-32):
```elixir
use Phoenix.Component

attr(:coverage, :map, required: true)
attr(:base_path, :string, required: true)
attr(:error, :string, default: nil)
attr(:coverage_enabled, :boolean, default: false)
attr(:policy_enabled, :boolean, default: false)
attr(:evidence_enabled, :boolean, default: false)
attr(:exports_enabled, :boolean, default: false)
attr(:current, :atom, default: nil)
attr(:scoped, :boolean, default: false)
attr(:theme, :string, default: "dark")

def surface_header(assigns) do
  ~H"""
  <a class="tl-skip-link" href="#tl-main">Skip to main content</a>
  <header class="tl-topbar" data-testid="operator-header">
```

**Feature-gated nav and aria-current pattern** (`lib/threadline/operator_surface/components/surface_header.ex` lines 57-87, 121-128):
```elixir
<nav class="tl-shell-nav" data-testid="operator-nav-shell" aria-label="Audit navigation">
  <section :if={@coverage_enabled} class="tl-shell-nav__group" aria-labelledby="tl-shell-nav-verify">
    <h2 id="tl-shell-nav-verify" class="tl-shell-nav__label">Audit readiness</h2>
    <.nav_link href={"#{@base_path}/coverage"} current={@current} page={:coverage}>Coverage</.nav_link>
  </section>
  <section :if={@evidence_enabled or @policy_enabled or @exports_enabled}>
    <.nav_link :if={@evidence_enabled} href={"#{@base_path}/evidence"} current={@current} page={:evidence}>Evidence</.nav_link>
    <.nav_link :if={@policy_enabled} href={"#{@base_path}/policy/redaction"} current={@current} page={:policy}>Redaction</.nav_link>
  </section>
</nav>

<a
  class={["tl-shell-nav__item", @current == @page && "tl-shell-nav__item--active"]}
  aria-current={if @current == @page, do: "page", else: nil}
  data-testid={@test_id || "operator-nav-#{@page}"}
>
```

**Component contract tests** (`test/threadline/operator_surface/surface_header_test.exs` lines 10-60, 62-85):
```elixir
test "renders grouped rail IA and preserved header affordances" do
  html = render_header()

  assert html =~ ~s|href="/audit"|
  assert html =~ ~s|data-testid="operator-nav-shell"|
  assert html =~ ~s|aria-label="Audit navigation"|
  assert html =~ ~s|data-testid="operator-nav-overview"|
  assert html =~ ~s|data-testid="operator-scope"|

  for page <- [:timeline, :coverage, :evidence, :policy, :retention, :exports] do
    assert html =~ ~s|data-testid="operator-nav-#{page}"|
  end
end

test "uses current atom as the single aria-current source" do
  for page <- [:start, :timeline, :coverage, :evidence, :policy, :retention, :exports] do
    html = render_header(%{current: page})
    tag = nav_tag!(html, page)

    assert aria_current_count(html) == 1
    assert tag =~ ~s|aria-current="page"|
    assert tag =~ "tl-shell-nav__item--active"
  end
end
```

---

### `test/threadline/operator_surface/style_contract_test.exs` and `lib/threadline/operator_surface/style.ex` (test/config, transform)

**Analogs:** same files

**Theme and token source contract** (`test/threadline/operator_surface/style_contract_test.exs` lines 8-28):
```elixir
test "operator surface is dark-primary with governed light and system token lanes" do
  src = File.read!(@style_path)

  assert String.contains?(src, "color-scheme: dark;")
  assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="light"]|)
  assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="system"]|)
  assert String.contains?(src, "@media (prefers-color-scheme: light)")
  assert String.contains?(src, "color-scheme: light;")
end
```

**CSP-proof nav and scroll source contract** (`test/threadline/operator_surface/style_contract_test.exs` lines 30-61):
```elixir
test "operator shell is CSP-proof: native [open] nav + pure-CSS picker cue + hardened scroll (NAV-03/NAV-04)" do
  src = File.read!(@style_path)

  assert String.contains?(src, ".tl-shell-nav__disclosure[open]"),
         "mobile nav must key off the native <details> [open] attribute"

  refute String.contains?(src, ".tl-shell-nav__control:checked"),
         "the JS-driven hidden-checkbox nav toggle must be gone (CSP-proof shell)"

  assert String.contains?(src, "scroll-padding-top")
  assert String.contains?(src, "100svh")
end
```

**Style token implementation** (`lib/threadline/operator_surface/style.ex` lines 160-220):
```elixir
--tl-hit-area: 40px;
--tl-focus-ring: 0 0 0 3px rgba(127, 169, 255, 0.42), 0 0 0 1px var(--tl-color-border-focus);
--tl-motion-fast: 120ms;
--tl-motion-base: 180ms;
--tl-motion-slow: 240ms;
--tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);

color-scheme: dark;

.threadline-ui[data-tl-theme="light"] {
  color-scheme: light;
  --tl-color-bg: #F7F9FC;
  --tl-color-surface: #FFFFFF;
}
```

**Native nav and scroll implementation** (`lib/threadline/operator_surface/style.ex` lines 430-575):
```elixir
min-height: 100svh;
scroll-padding-top: calc(var(--tl-header-height-mobile) + var(--tl-space-4));
overscroll-behavior: contain;

.tl-shell-nav__toggle {
  min-height: var(--tl-hit-area);
}

.tl-shell-nav__disclosure[open] .tl-shell-nav__toggle::after {
  transform: rotate(225deg);
}

.tl-shell-nav__disclosure[open] .tl-shell-nav__panel {
  display: grid;
}
```

**Reduced-motion implementation** (`lib/threadline/operator_surface/style.ex` lines 4356-4384):
```elixir
@media (prefers-reduced-motion: reduce) {
  .threadline-ui *,
  .threadline-ui *::before,
  .threadline-ui *::after,
  .tl-policy__row::details-content {
    transition-duration: 1ms !important;
    animation-duration: 1ms !important;
    animation-delay: 0ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
  }
}
```

---

### `mix.exs` (config, batch)

**Analog:** same file

**Verification alias pattern** (lines 77-103 and 88-93 from `rg`):
```elixir
"verify.format": ["format --check-formatted"],
"verify.credo": ["credo --strict"],
"verify.test": ["test"],
"verify.example_browser_light": &verify_example_browser_light/1,
"verify.operator_stress": &verify_operator_stress/1,
"verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
"ci.all": [
  "verify.format",
  "verify.credo",
  "verify.compile_no_optional",
  "verify.test",
]
```

Use named aliases in `181-VERIFICATION.md`. Do not invent ad hoc CI-facing commands when an alias exists.

## Shared Patterns

### Optional Phoenix/LiveView Boundary

**Source:** `lib/threadline/operator_surface/router.ex`, `test/threadline/operator_surface/stress_ledger_test.exs`
**Apply to:** all source/test changes under `lib/threadline/operator_surface` and `test/threadline/operator_surface`

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressLedgerTest do
    use ExUnit.Case, async: true
  end
end
```

Keep root package Phoenix/LiveView optional. Add source contracts rather than new root dependencies.

### Authentication And Route Gates

**Source:** `lib/threadline/operator_surface/router.ex` lines 86-106, `test/threadline/operator_surface/stress_router_test.exs` lines 337-345
**Apply to:** router, stress route, Playwright route checks, verification docs

```elixir
if not (_has_pipe? or unquote(has_auth_fn?) or unquote(has_ack?)) do
  raise CompileError,
    description:
      "Threadline Operator Surface must be mounted inside a secure pipeline. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`."
end

live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
```

### Selector Policy

**Source:** `operator-screenshot-regression.spec.ts` lines 127-141, `operator-screenshots.spec.ts` lines 88-150
**Apply to:** all Playwright repair tasks

```typescript
await expect(page.getByRole("heading", { name: "Retention window" })).toBeVisible();
await expect(page.getByRole("button", { name: "Run retention prune" }).last()).toBeVisible();
await expect(page.getByTestId("operator-header")).toBeVisible();
```

Prefer role/label/text/URL for operator-visible semantics. Use `getByTestId` where stable IDs are the contract.

### Screenshot Guarding

**Source:** `operator-stress.spec.ts` lines 51-56 and 256-301; `operator-screenshots.spec.ts` lines 34-54
**Apply to:** screenshot inventory, bounded CI allowlist, local packet generation

```typescript
await expect(preview).toHaveScreenshot(item.baseline_ref, {
  maxDiffPixelRatio: 0.01,
  mask: dynamicMasks(page),
});
```

Keep CI screenshots bounded to the ledger allowlist. Use `OPERATOR_SCREENSHOT_DIR` for local packet evidence.

### Ledger Projection And Ratchet

**Source:** `test/threadline/operator_surface/stress_ledger_test.exs` lines 101-218
**Apply to:** `.planning/design-system-ledger.json`, `DESIGN-SYSTEM.md`, stress fixture changes

```elixir
assert entry["current_score"] >= entry["ratchet_score"],
       "#{id} current_score must be greater than or equal to ratchet_score"

assert String.contains?(markdown, row),
       "#{@design_system_path} is stale for #{entry["id"]}; missing row #{inspect(row)}"
```

Update JSON first, projection second, tests third. Do not lower ratchets or remove locked IDs without explicit reset rationale.

### Param Validation And Error Handling

**Source:** `lib/threadline/operator_surface/live/stress_live.ex` lines 35-70 and 488-554
**Apply to:** stress route/source repairs

```elixir
filter_category = allow(params["category"], @category_allowlist)
filter_status = allow(params["status"], @status_allowlist)
selected_theme = allow(params["theme"], @theme_allowlist) || socket.assigns.threadline_theme
selected_viewport = allow(params["viewport"], @viewport_allowlist) || "1024"

defp allow(value, allowed) when is_binary(value) do
  if value in allowed, do: value, else: nil
end
```

Keep allowlists explicit. Do not use `String.to_atom/1` on route/query params.

### Theme, Motion, And CSS Source Contracts

**Source:** `test/threadline/operator_surface/style_contract_test.exs`, `lib/threadline/operator_surface/style.ex`
**Apply to:** `style.ex`, header/nav hooks, proof-gap classification

```elixir
assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="light"]|)
assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="system"]|)
refute Regex.match?(~r/transition:\s*all\b/, src)
```

Theme is server/CSS scoped. Motion must be token-backed and reduced-motion aware. No Tailwind/shadcn migration in Phase 181.

## No Analog Found

No files lack a usable analog. `181-GUARD-REPAIR.md` has no exact same-name prior artifact, but `180-AUTOMATED-A11Y-EVIDENCE.md`, `180-VERIFICATION.md`, and the current source-contract tests provide a close role-match.

## Metadata

**Analog search scope:** `.planning/milestones`, `.planning/phases/181-baseline-audit-and-guard-repair`, `lib/threadline/operator_surface`, `test/threadline/operator_surface`, `examples/threadline_phoenix/e2e/tests`, `mix.exs`, `DESIGN-SYSTEM.md`, `.planning/design-system-ledger.json`

**Files scanned:** primary `rg --files` scan covered 60+ operator source/test/E2E files; pattern extraction stopped after the strongest analog families were loaded.

**Project instructions loaded:** `CLAUDE.md`, `examples/threadline_phoenix/AGENTS.md`

**Project skills checked:** no project-local `.claude/skills`, `.agents/skills`, or `.codex/skills` directories exist.

**Pattern extraction date:** 2026-06-26
