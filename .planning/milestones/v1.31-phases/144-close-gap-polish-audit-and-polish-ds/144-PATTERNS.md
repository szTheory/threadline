# Phase 144: Close Gap Polish Audit And Polish DS - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md` | documentation | transform | `.planning/phases/143-accessibility-consistency-sweep-regression/143-AUDIT-CLOSURE.md` | exact |
| `.planning/milestones/v1.31-DESIGN-SYSTEM.md` | documentation | transform | `.planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` + `.planning/milestones/v1.31-UI-AUDIT.md` | role-match |
| `lib/threadline/operator_surface/style.ex` | component/style source | transform | existing `lib/threadline/operator_surface/style.ex` primitive sections | exact |
| `lib/threadline/operator_surface/presentation.ex` | utility | transform | existing `lib/threadline/operator_surface/presentation.ex` status/value helpers | exact |
| `lib/threadline/operator_surface/live/*.ex` | component | request-response | `lib/threadline/operator_surface/live/policy_redaction_live.ex` usage of `Presentation.status_modifier/1` | role-match |
| `test/threadline/operator_surface/style_contract_test.exs` | test | transform | existing `test/threadline/operator_surface/style_contract_test.exs` source contracts | exact |
| `test/threadline/operator_surface/presentation_test.exs` | test | transform | existing `test/threadline/operator_surface/presentation_test.exs` helper tests | exact |
| `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` | test | file-I/O | existing screenshot capture spec | exact |
| `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` | test | request-response | existing screenshot regression guard | exact |
| `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-VERIFICATION.md` | documentation | batch | `.planning/phases/143-accessibility-consistency-sweep-regression/143-VERIFICATION.md` | exact |
| `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-*-SUMMARY.md` | documentation | batch | `.planning/phases/143-accessibility-consistency-sweep-regression/143-01-SUMMARY.md` + `.planning/conventions/summary-frontmatter.md` | role-match |
| `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` | config/documentation | batch | existing v1.31 traceability sections | exact |
| `.planning/v1.31-MILESTONE-AUDIT.md` | documentation | batch | existing milestone audit frontmatter/body | exact |

## Pattern Assignments

### `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-AUDIT-ERRATA.md` (documentation, transform)

**Analog:** `.planning/phases/143-accessibility-consistency-sweep-regression/143-AUDIT-CLOSURE.md`

**Evidence binding pattern** (lines 1-15):
```markdown
# Phase 143 Audit Closure Registry

Source audit: `.planning/milestones/v1.31-UI-AUDIT.md` (Phase 134 baseline).

## Closure Evidence

- Phase 135: seed enrichment, IA lock-in, saved views, named actors, operation variety, demo manifest.
- Phase 136: dark token and interaction contrast foundation.
- Phase 143: accessibility contracts, focused browser spec, browser-suite repair, final screenshot matrix.
```

**Registry pattern** (lines 16-24):
```markdown
## Registry

| ID | Status | Evidence |
|---|---|---|
| F-101 | closed | Phase 136 token foundation and Phase 137/138 screen polish converge status primitives; final screenshots show consistent chip treatment. |
| F-102 | closed | Phase 136/143 status contracts and source tests require non-color chip shape plus readable semantic color. |
```

**Apply to Phase 144:** Start with an explicit provenance sentence: "This is not an original Phase 134 execution record." Then bind `POLISH-AUDIT` to `.planning/milestones/v1.31-UI-AUDIT.md`, baseline/final screenshot counts, `143-SCREENSHOT-DIFF.md`, `143-AUDIT-CLOSURE.md`, and the original Phase 134 success criteria from `.planning/ROADMAP.md`.

---

### `.planning/milestones/v1.31-DESIGN-SYSTEM.md` (documentation, transform)

**Analogs:** `.planning/phases/141-motion-micro-animation/141-MOTION-INVENTORY.md`, `.planning/milestones/v1.31-UI-AUDIT.md`

**Frontmatter/source-contract doc pattern** (lines 1-10):
```markdown
---
phase: 141-motion-micro-animation
artifact: motion-inventory
status: source-contract
requirements: [POLISH-MOTION]
---

# Phase 141 Motion Inventory

This inventory is the source-testable contract for Threadline operator-surface motion.
```

**Locked scale table pattern** (lines 12-31):
```markdown
## Locked Motion Scale

| token_or_keyframe | contract |
|---|---|
| `--tl-motion-fast` | `120ms` |
| `--tl-motion-base` | `180ms` |
| `tl-drawer-in` | Drawer/subview entry only; transform + opacity. |
```

**Finding/catalog table pattern** (lines 42-54):
```markdown
| ID | Sev | Finding | Proposed resolution |
|----|:--:|---------|---------------------|
| F-101 | HIGH | **One status vocabulary, four renderings.** ... | Single `.tl-status-badge` keyed off a status enum; deprecate ad-hoc per-screen pills. |
```

**Apply to Phase 144:** Use frontmatter with `artifact: design-system-catalog`, `status: source-contract`, and `requirements: [POLISH-DS]`. Catalog by primitive family: tokens, chips/status/verdicts, buttons/actions, empty/error states, cards, tables/responsive, copy, drawer/subview, motion, focus/accessibility, deprecated/consolidated classes, anti-patterns.

---

### `lib/threadline/operator_surface/style.ex` (component/style source, transform)

**Analog:** existing `lib/threadline/operator_surface/style.ex`

**Phoenix-optional CSS emission pattern** (lines 1-18):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc """
    Provides isolated CSS for the Threadline Operator Surface.
    """

    import Phoenix.Component

    def css(assigns) do
      assigns =
        assign(assigns, :fonts_html, Phoenix.HTML.raw(font_face_style()))

      ~H"""
      {@fonts_html}<style>
```

**Frozen token scale pattern** (lines 20-53, 110-165):
```css
--tl-space-1: 4px;
--tl-space-2: 8px;
--tl-font-size-body: 14px;
--tl-color-bg: #0B1020;
--tl-radius-md: 6px;
--tl-control-height: 40px;
--tl-breakpoint-tablet: 768px;
--tl-motion-fast: 120ms;
--tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);
```

**Button/chip primitive pattern** (lines 891-1089):
```css
.tl-button {
  min-height: var(--tl-hit-area);
  display: inline-flex;
  border-radius: var(--tl-radius-md);
  transition-property: color, background-color, border-color, box-shadow, transform;
}

.tl-chip {
  min-height: var(--tl-control-height-chip);
  border: 1px solid var(--tl-color-border);
  border-radius: var(--tl-radius-pill);
}

.tl-chip--danger {
  border-color: var(--tl-color-danger-border);
  background: var(--tl-color-danger-bg);
  color: var(--tl-color-danger);
}
```

**Canonical card comment and status stripe pattern** (lines 1191-1222):
```css
/* Canonical card primitive. New surfaces use `.tl-card` + slots; the older
   `.tl-summary-card` / `.tl-job` / `.tl-record-card` share its visual language
   (surface-raised, radius-lg, inset border + subtle shadow, optional status stripe). */
.tl-card {
  display: grid;
  gap: var(--tl-space-3);
  box-shadow: var(--tl-shadow-border), var(--tl-shadow-subtle);
}
```

**Find/value primitive pattern** (lines 1684-1812):
```css
/* Find cluster primitives: shared value, diff, filter, actor, and remediation seams. */
.tl-value {
  font-family: var(--tl-font-mono);
  overflow-wrap: anywhere;
}

.tl-value--redacted {
  background: var(--tl-color-warning-bg);
  color: var(--tl-color-warning-text);
}

.tl-diff {
  display: grid;
  border: 1px solid var(--tl-color-border);
}
```

**Drawer/copy/motion pattern** (lines 2090-2102, 2219-2248):
```css
.tl-subview {
  position: fixed;
  width: 100vw;
  min-height: 100dvh;
  animation: tl-drawer-in var(--tl-motion-base) var(--tl-ease-standard);
}

/* C2 - copy id affordance. Vanilla embedded JS toggles .is-copied on success. */
.tl-copy.is-copied {
  color: var(--tl-color-signal);
  animation: tl-copy-pulse var(--tl-motion-base) var(--tl-ease-out);
}
```

**Responsive table pattern** (lines 2513-2548, 2776-2818):
```css
.tl-table-wrap .tl-table--responsive {
  min-width: 0;
}

.tl-table--responsive td::before {
  content: attr(data-label);
}

@media (min-width: 1280px) {
  .tl-table-wrap .tl-table--responsive {
    min-width: var(--tl-table-min-width);
  }
  .tl-table--responsive thead {
    display: table-header-group;
  }
}
```

**Reduced-motion pattern** (lines 2821-2836):
```css
@media (prefers-reduced-motion: reduce) {
  .threadline-ui *,
  .threadline-ui *::before,
  .threadline-ui *::after,
  .tl-policy__row::details-content {
    transition-duration: 1ms !important;
    animation-duration: 1ms !important;
  }
}
```

---

### `lib/threadline/operator_surface/presentation.ex` (utility, transform)

**Analog:** existing `lib/threadline/operator_surface/presentation.ex`

**Status semantic helper pattern** (lines 70-110):
```elixir
@spec status_modifier(String.t() | atom() | nil) :: String.t()
def status_modifier(status) do
  case normalize_status(status) do
    status when status in ~w(completed covered proven configured config_matches_deployed) ->
      "tl-chip--success"

    status when status in ~w(failed error uncovered unsupported invalid) ->
      "tl-chip--danger"

    _ ->
      "tl-chip--neutral"
  end
end
```

**Value/KV helper pattern** (lines 220-275):
```elixir
@spec value_token(term()) :: %{required(:text) => String.t(), required(:modifier) => String.t(), optional(:title) => String.t()}
def value_token(nil), do: %{text: "null", modifier: "tl-value--null"}

def value_token(%DateTime{} = value) do
  %{text: human_time(value), title: exact_time(value), modifier: "tl-value--time"}
end

def change_value_token(field, axis) when is_map(field) do
  case fetch_axis(field, axis) do
    {:ok, value} -> value_token(value)
    :error -> %{text: "(omitted)", modifier: "tl-value--omitted"}
  end
end
```

**Safety pattern for generated copy commands** (lines 281-305):
```elixir
@safe_generator_identifier ~r/\A[a-z_][a-z0-9_]{0,62}\z/

if schema == "public" and safe_generator_identifier?(table_name) do
  %{command: "mix threadline.gen.triggers --tables #{table_name}"}
else
  %{command: nil, follow_up: "Generate a trigger migration ... after confirming the identifier"}
end
```

**Apply to Phase 144:** Consolidate by adding or reusing pure helpers in this module, then update LiveViews to consume helpers. Do not add a public Phoenix component API.

---

### `lib/threadline/operator_surface/live/*.ex` (component, request-response)

**Analog:** `lib/threadline/operator_surface/live/policy_redaction_live.ex`

**Presentation helper consumption pattern** (research grep found current usage):
```elixir
<span class={["tl-chip", Presentation.status_modifier(row.status)]}>
  <%= status_label(row.status) %>
</span>
```

**Apply to Phase 144:** Prefer markup changes that swap ad-hoc status/class choices for `Presentation.status_modifier/1`, `Presentation.status_label/1`, `Presentation.value_token/1`, and `data-status` row/card patterns. Keep route, query, schema, and business logic unchanged.

---

### `test/threadline/operator_surface/style_contract_test.exs` (test, transform)

**Analog:** existing `test/threadline/operator_surface/style_contract_test.exs`

**Source contract setup pattern** (lines 1-13):
```elixir
defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"

  test "operator surface stays dark-only and token-driven" do
    src = File.read!(@style_path)
    assert String.contains?(src, "color-scheme: dark;")
    refute String.contains?(src, "prefers-color-scheme")
  end
end
```

**Catalog loop pattern** (lines 52-88):
```elixir
for class <- [
      ".tl-value",
      ".tl-value--null",
      ".tl-diff",
      ".tl-filter-summary",
      ".tl-remediation__command"
    ] do
  assert String.contains?(src, class)
end

refute String.contains?(find_section, "@tailwind")
refute Regex.match?(~r/#[0-9a-fA-F]{6}/, find_section)
```

**Frozen token pattern** (lines 208-232):
```elixir
for token <- [
      "--tl-motion-fast: 120ms;",
      "--tl-motion-base: 180ms;",
      "--tl-motion-slow: 240ms;"
    ] do
  assert String.contains?(src, token), "missing locked motion token #{token}"
end
```

**Helper pattern for CSS selector assertions** (lines 625-645):
```elixir
defp assert_selector_contains(section, selector, declarations) do
  block = selector_block!(section, selector)

  for declaration <- declarations do
    assert String.contains?(block, declaration),
           "#{selector} is missing #{declaration}"
  end
end
```

**Apply to Phase 144:** Add narrow tests for frozen token scales, canonical/deprecated/consolidated `.tl-*` families, semantic status/verdict map, action hierarchy, copy/drawer/table responsive primitives, dark-only constraints, and explicit anti-patterns.

---

### `test/threadline/operator_surface/presentation_test.exs` (test, transform)

**Analog:** existing `test/threadline/operator_surface/presentation_test.exs`

**Pure helper test pattern** (lines 1-7, 80-120):
```elixir
defmodule Threadline.OperatorSurface.PresentationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Presentation

  describe "find value tokens" do
    test "renders nil, redacted strings, and ordinary primitives as escaped text data" do
      assert Presentation.value_token(nil) == %{text: "null", modifier: "tl-value--null"}
      assert Presentation.value_token("[REDACTED]") == %{text: "[REDACTED]", modifier: "tl-value--redacted"}
    end
  end
end
```

**Apply to Phase 144:** If `presentation.ex` changes, add helper tests here rather than proving helper behavior through LiveView/browser tests.

---

### `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` (test, file-I/O)

**Analog:** existing screenshot capture spec

**Durable screenshot naming and write pattern** (lines 10-23, 34-50):
```typescript
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

const outputDir = process.env.OPERATOR_SCREENSHOT_DIR;
const viewport = screenshotViewport(testInfo);
if (outputDir && viewport && durableScreenshotNames.has(name)) {
  mkdirSync(outputDir, { recursive: true });
  await page.screenshot({ path: join(outputDir, `${name}__default__${viewport}.png`), fullPage: true, scale: "css" });
}
```

**Capture flow pattern** (lines 79-145):
```typescript
await page.goto("/audit");
await expect(page.getByTestId("operator-header")).toBeVisible();
await capture(page, testInfo, "home");

await page.goto("/audit/timeline");
await expect(page.getByTestId("operator-header")).toBeVisible();
await capture(page, testInfo, "timeline");
```

**Apply to Phase 144:** Do not add a new screenshot harness. If final proof is needed, rerun this with `OPERATOR_SCREENSHOT_DIR=.planning/milestones/v1.31-screenshots/final`.

---

### `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` (test, request-response)

**Analog:** existing screenshot regression guard

**Masked screenshot assertion pattern** (lines 36-55):
```typescript
async function expectOperatorScreenshot(page: Page, name: string, options: { fullPage?: boolean; maxDiffPixelRatio?: number } = {}) {
  await page.waitForLoadState("networkidle");
  await expect(page).toHaveScreenshot(`${name}.png`, {
    fullPage: options.fullPage ?? true,
    maxDiffPixelRatio: options.maxDiffPixelRatio ?? 0.01,
    mask: dynamicMasks(page),
  });
}

function dynamicMasks(page: Page): Locator[] {
  return [page.locator("time"), page.locator(".tl-table__date"), page.locator(".tl-copy.is-copied")];
}
```

**Fixed viewport pattern** (lines 57-70):
```typescript
test.beforeEach(async ({ page }, testInfo) => {
  test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");
  if (testInfo.project.name === "desktop-chromium") await page.setViewportSize({ width: 1280, height: 900 });
  if (testInfo.project.name === "mobile-chromium") await page.setViewportSize({ width: 375, height: 812 });
  await login(page);
});
```

**Apply to Phase 144:** Run this guard after CSS/presentation consolidation. Only update snapshots if the design-system catalog and audit errata explain the delta.

---

### `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-VERIFICATION.md` (documentation, batch)

**Analog:** `.planning/phases/143-accessibility-consistency-sweep-regression/143-VERIFICATION.md`

**Verification report pattern** (lines 1-19):
```markdown
# Phase 143 Verification

## Verdict

Phase 143 passes verification.

## Must-Haves

| Check | Result | Evidence |
|---|---|---|
| Accessibility source contracts | PASS | `mix test test/threadline/operator_surface/style_contract_test.exs` -> 19 tests, 0 failures |
| Full browser lane | PASS | `mix verify.example_browser` -> 133 passed, 5 skipped |
```

**Apply to Phase 144:** Include must-haves for `144-AUDIT-ERRATA.md`, `v1.31-DESIGN-SYSTEM.md`, `style_contract_test.exs`, screenshot evidence count, screenshot regression or browser lane, requirements/roadmap/state updates, and milestone audit rerun.

---

### `.planning/phases/144-close-gap-polish-audit-and-polish-ds/144-*-SUMMARY.md` (documentation, batch)

**Analogs:** `.planning/phases/143-accessibility-consistency-sweep-regression/143-01-SUMMARY.md`, `.planning/conventions/summary-frontmatter.md`

**Summary body pattern** (lines 1-7, 23-37):
```markdown
# Phase 143-01 Summary: Accessibility Primitive Baseline

## Scope

Locked the first accessibility baseline for the operator surface with source-level contracts and a focused browser regression spec.

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs`
  - 19 tests, 0 failures
```

**Frontmatter convention pattern** (lines 19-26, 84-99):
```yaml
---
phase: 128-readme-phx-gen-auth-mount-parity
plan: 01
requirements-completed: [README-01, README-02, TRIG-01]
duration: 8min
completed: 2026-05-28
---
```

**Apply to Phase 144:** New summaries must use hyphenated `requirements-completed`, not `requirements_completed`. For this phase, use milestone IDs `POLISH-AUDIT` and/or `POLISH-DS` because it is closing active v1.31 requirements, not post-shipment GAP IDs.

---

### `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` (config/documentation, batch)

**Analogs:** existing v1.31 authority sections

**Requirements checkbox/traceability pattern** (lines 11-19, 58-69):
```markdown
- [ ] **POLISH-AUDIT**: An operator can review an objective current-state baseline ...
- [ ] **POLISH-DS**: The design system pays reuse dividends ...

| Requirement | Phase | Status |
|-------------|-------|--------|
| POLISH-AUDIT | Phase 134 - Baseline Audit & Screenshot Inventory | Pending |
| POLISH-DS | Phase 136 - Design-System Hardening | Pending |
```

**Roadmap phase pattern** (lines 35-44, 61-71, 186-194):
```markdown
### Phase 136: Design-System Hardening
**Goal**: Dedupe and formalize the token scales ...
**Requirements**: POLISH-DS
**Success Criteria** (what must be TRUE):
  1. The `--tl-*` token scales are deduplicated and formalized ...
**Plans**: 1 plan
- [x] 136-01-PLAN.md - Dark token and interaction contrast foundation
```

**State continuity pattern** (lines 25-31, 101-112):
```markdown
## Current Position

Phase: 144
Plan: Not started
Status: Not planned
Resume: `.planning/phases/144-close-gap-polish-audit-and-polish-ds/`

## Operator Next Steps

- **Plan Phase 144** - Close gap: POLISH-AUDIT and POLISH-DS
```

**Apply to Phase 144:** Update only enough to make closure legible. Do not erase chronology: keep Phase 134/136 original ownership, but note Phase 144 verified/closed the missing evidence.

---

### `.planning/v1.31-MILESTONE-AUDIT.md` (documentation, batch)

**Analog:** existing milestone audit frontmatter/body

**Audit frontmatter gap pattern** (lines 1-27):
```yaml
---
milestone: v1.31
status: gaps_found
scores:
  requirements: "8/10"
gaps:
  requirements:
    - id: "POLISH-AUDIT"
      status: "orphaned"
      evidence: "Baseline artifacts and screenshots exist, but the assigned phase was never verified."
    - id: "POLISH-DS"
      status: "unsatisfied"
      evidence: "v1.31-DESIGN-SYSTEM.md is missing ... token scale is not frozen."
---
```

**Required closure pattern** (lines 156-160):
```markdown
## Required Closure

1. Close `POLISH-AUDIT`: either reconstruct Phase 134 with a verification record that binds the existing baseline screenshots and `v1.31-UI-AUDIT.md`, or insert a closure phase that verifies those artifacts against the original Phase 134 success criteria.
2. Close `POLISH-DS`: complete design-system catalog/freeze work or explicitly re-scope the requirement, then re-run Phase 136 verification.
3. Re-run the milestone audit after both requirements have verification evidence and SUMMARY frontmatter where applicable.
```

**Apply to Phase 144:** The planner should expect this file to be regenerated or updated after implementation by the milestone audit tool; final expected status should no longer list `POLISH-AUDIT` or `POLISH-DS` as blocking gaps.

## Shared Patterns

### Phoenix-Optional Boundary
**Source:** `lib/threadline/operator_surface/style.ex` lines 1-18
**Apply to:** `style.ex`, LiveView call sites, design-system docs

Keep `Code.ensure_loaded?(Phoenix.LiveView)`, `import Phoenix.Component`, scoped `.threadline-ui`, and embedded CSS. No Tailwind, no build step, no external design-system dependency.

### Dark-First Token Freeze
**Source:** `lib/threadline/operator_surface/style.ex` lines 52-168; `style_contract_test.exs` lines 8-35
**Apply to:** design catalog and style contracts

Freeze tokens from actual source: spacing, typography, colors, radius, shadow, z-index, control sizes, breakpoints, focus ring, motion, table/drawer scales. Preserve `color-scheme: dark;` and keep `prefers-color-scheme` / light mode out of source.

### Source-Contract Tests
**Source:** `test/threadline/operator_surface/style_contract_test.exs` lines 52-88, 208-232, 625-645
**Apply to:** `style_contract_test.exs`

Use `File.read!`, `String.contains?`, section extraction with `String.split`, and helper assertions. Favor narrow token/class contracts over broad screenshot or prose parsing.

### Pure Presentation Helpers
**Source:** `lib/threadline/operator_surface/presentation.ex` lines 70-110, 220-275; `presentation_test.exs` lines 80-140
**Apply to:** `presentation.ex`, LiveViews, presentation tests

Consolidate semantic labels/modifiers and value tokens as pure functions with deterministic return maps. Test helpers directly in `presentation_test.exs`.

### Screenshot Evidence
**Source:** `operator-screenshots.spec.ts` lines 10-50; `143-SCREENSHOT-DIFF.md` lines 3-10
**Apply to:** audit errata and verification

The durable matrix is 12 screen names x 2 viewports = 24 PNGs per directory. Use `OPERATOR_SCREENSHOT_DIR` for durable writes; keep generated Playwright artifacts out of milestone screenshots.

### Three-Source Traceability
**Source:** `.planning/conventions/summary-frontmatter.md` lines 9-26
**Apply to:** summaries, verification, requirements

`REQUIREMENTS.md`, `*-SUMMARY.md` `requirements-completed`, and `*-VERIFICATION.md` must agree. Use hyphenated `requirements-completed`.

### Subtree Verification Instructions
**Source:** `examples/threadline_phoenix/AGENTS.md` found by repo search
**Apply to:** any changed files under `examples/threadline_phoenix`

If execution touches the example subtree, planner should require `mix precommit` when all changes are done and preserve local Phoenix conventions. No new HTTP library or unsafe atom conversion is relevant to Phase 144.

## No Analog Found

All inferred files have usable local analogs. No file requires planner fallback to research-only patterns.

## Metadata

**Analog search scope:** `.planning/`, `lib/threadline/operator_surface/`, `test/threadline/operator_surface/`, `examples/threadline_phoenix/e2e/tests/`
**Files scanned:** 24 focused files plus targeted `style.ex` ranges
**Pattern extraction date:** 2026-06-04
