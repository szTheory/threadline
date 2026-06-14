# Phase 169: screenshots-example-docs - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 6 (4 modify, 1 add-or-modify, 1 new)
**Analogs found:** 6 / 6 (all in-file or sibling self-analogs — this is a reuse/evidence phase)

> **Read-only note for planner:** This phase invents no new infrastructure. Every
> "analog" is an existing pattern *in the same file* or a *sibling file in the same
> directory*. The planner should treat the listed line ranges as the literal code to
> extend, not as a distant template. Source files under `lib/threadline/operator_surface/`
> (`router.ex`, `auth.ex`, `style.ex`) are **read-only references** for accurate docs —
> NO edits. The uncommitted nav-overhaul lane (app.html.heex, page_controller, live views,
> style.ex source edits, operator e2e specs) is OUT OF BOUNDS.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` (MODIFY) | test (e2e capture harness) | file-I/O (PNG emit) | itself — `__default__` suffix + `screenshotViewport()` (lines 41–62) | exact (in-file extend) |
| `examples/threadline_phoenix/e2e/playwright.config.ts` (MODIFY) | config | request-response (project routing) | itself — `desktop-chromium-light` project (lines 19–31) | exact (in-file widen) |
| `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` (MODIFY / reuse-under-light) | test (visual guard) | request-response + file-I/O | itself — CI-skip + `beforeEach` viewport gate (lines 78–95) | exact (in-file / project reuse) |
| `guides/operator-surface.md` (MODIFY) | doc | n/a (prose) | "1-Minute Mount" + options prose (lines 12–53) | role-match (sibling section) |
| `README.md` (MODIFY) | doc | n/a (prose) | "Operator Surface" para — "dark, branded admin surface" (line 126) | role-match (one-line additive) |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` (NEW) | test (doc-contract literal-pin) | transform (read-file + assert) | `coverage_doc_contract_test.exs` / `timeline_browse_doc_contract_test.exs` | exact (literal-pin family) |

## Pattern Assignments

### `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` (test, file-I/O) — MODIFY

**Analog:** itself (durable-capture harness is the single chokepoint for `__light__`).

**Suffix + durable emit pattern** (lines 41–51) — the literal block to teach the light suffix:
```typescript
const outputDir = process.env.OPERATOR_SCREENSHOT_DIR;
const viewport = screenshotViewport(testInfo);
if (outputDir && viewport && durableScreenshotNames.has(name)) {
  mkdirSync(outputDir, { recursive: true });
  await page.screenshot({
    path: join(outputDir, `${name}__default__${viewport}.png`),  // <- `__default__` is hardcoded here
    fullPage: true,
    scale: "css",
  });
}
```
Plan: derive the suffix from the lane. Per CONTEXT D-01 + Claude's-Discretion (line 105),
either `testInfo.project.name === "desktop-chromium-light"` or
`process.env.THREADLINE_E2E_THEME === "system"` selects `__light__`; the dark lane keeps
emitting `__default__`. D-02: **no rename** of `__default__`.

**Viewport map pattern** (lines 53–62) — must learn the light project name:
```typescript
function screenshotViewport(testInfo: TestInfo) {
  switch (testInfo.project.name) {
    case "desktop-chromium":
      return "1280";
    case "mobile-chromium":
      return "375";
    default:               // <- "desktop-chromium-light" currently falls here → returns null → no durable emit
      return null;
  }
}
```
Plan: add `case "desktop-chromium-light": return "1280";` (D-01: "teach `screenshotViewport()`
the `desktop-chromium-light` project name → `1280`"). Desktop-only — NO mobile-light (D-03).

**Durable set is the coverage contract** (lines 10–23) — the 12 screens captured in both lanes:
```typescript
const durableScreenshotNames = new Set([
  "actor", "coverage", "evidence", "exports", "home", "redaction",
  "retention", "row-history", "timeline", "timeline-dense",
  "timeline-empty", "transaction",
]);
```
Unchanged — D-03 reuses this exact set for the light lane (full durable set, desktop-only).

**beforeEach viewport gate** (lines 65–77) — currently only sizes `desktop-chromium` /
`mobile-chromium`; if the light project relies on its config-level `viewport: {1280,900}`
no change is needed, but confirm the light project is sized (config sets it at line 26).

---

### `examples/threadline_phoenix/e2e/playwright.config.ts` (config, request-response) — MODIFY

**Analog:** itself — the `desktop-chromium-light` project definition.

**Project + testMatch pattern** (lines 19–31) — widen `testMatch`:
```typescript
...(lightLane
  ? [
      {
        name: "desktop-chromium-light",
        testMatch: /operator-accessibility\.spec\.ts/,   // <- widen this regex
        use: {
          ...devices["Desktop Chrome"],
          viewport: { width: 1280, height: 900 },
          colorScheme: "light" as const,
        },
      },
    ]
  : []),
```
Plan (D-01): widen the `testMatch` regex to also match `operator-screenshots.spec.ts`
(and, if the regression mirror reuses this project, `operator-screenshot-regression.spec.ts`).
A union regex such as `/operator-(accessibility|screenshots|screenshot-regression)\.spec\.ts/`
keeps the gate explicit. `lightLane` env gate (line 13) and `colorScheme: "light"` are
already correct — do NOT change them.

**Snapshot path template** (line 37) — load-bearing for the regression mirror's PNG names:
```typescript
snapshotPathTemplate: "{testDir}/{testFilePath}-snapshots/{arg}-{projectName}{ext}",
```
`{projectName}` already disambiguates `desktop-chromium-light` snapshots from
`desktop-chromium`, so the light regression guard's baselines auto-namespace — no template change.

---

### `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` (test, visual guard) — MODIFY / reuse-under-light

**Analog:** itself — the 5-screen guard runs verbatim under the light project per
Claude's-Discretion (line 108: reuse existing spec under the light project vs parameterized variant).

**CI-skip posture** (lines 78–81) — MUST be inherited by the light lane (cf0e8e2 local-only):
```typescript
test.describe("operator screenshot regression guard", () => {
  test.skip(
    !!process.env.CI,
    "visual screenshot baselines are platform-sensitive; run this guard locally before updating PNG snapshots",
  );
```

**Project-gated viewport sizing** (lines 83–95) — extend the `beforeEach` to admit the light project:
```typescript
test.beforeEach(async ({ page }, testInfo) => {
  test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");

  if (testInfo.project.name === "desktop-chromium") {
    await page.setViewportSize({ width: 1280, height: 900 });
  }
  if (testInfo.project.name === "mobile-chromium") {
    await page.setViewportSize({ width: 375, height: 812 });
  }
  await login(page);
});
```
Plan (D-03): if the spec is added to the light project's `testMatch`, it auto-runs under
`desktop-chromium-light` (viewport from config). Guard the **same 5 screens** (home,
timeline-dense, row-history, exports, retention) — they already exist as tests at
lines 97, 104, 111, 123, 132. `{projectName}` in the snapshot template gives light baselines
their own PNGs, so no test renaming is needed.

**Mask + screenshot helper** (lines 42–75) — reused verbatim; `dynamicMasks()` and
`expectOperatorScreenshot()` are mode-independent. No change.

---

### `guides/operator-surface.md` (doc) — MODIFY

**Analog:** the "1-Minute Mount" section + options prose (lines 12–53) — same heading depth,
same fenced-`elixir` convention, same adopter voice. The new "Theme" subsection slots near here.

**Section/heading convention** (lines 12, 33–53):
```markdown
## 1-Minute Mount
...
```elixir
    threadline_operator_surface "/",
      actor_fn: &MyApp.Audit.current_actor/1,
      authorize_fn: &MyApp.Audit.authorize_operator/1,
      schemas: %{...},
      repo: MyApp.Repo
```
...
Admin-first recipe:
- ...
```
Plan (D-05 + Claude's-Discretion line 111): add a new **"### Theme"** (or `## Theme`)
subsection near the 1-Minute Mount / options area. It MUST:
- document the `theme:` option with all three values **`:dark`** (default), **`:light`**, **`:system`**;
- describe what each renders (grounded in source — see read-only refs below);
- carry the **D-04 daytime recommendation** with the settled precedent phrasing:
  *"Dark stays the default and the brand; `:system` becomes the documented daytime-use
  recommendation."*
- frame light as a **readability/accessibility** choice (dense audit text; astigmatism
  prevalence) — **NEVER** a medical eye-strain claim (165 lesson).
- Do **NOT** add `theme:` to the canonical mount snippet here (D-05 — keep dark-default clean).

**Read-only source truth for the prose** (do not edit these files):
- `lib/threadline/operator_surface/router.ex` lines 52–55 + 63–72 — option doc + compile-time
  validation `:dark | :light | :system`, default `:dark`:
  ```elixir
  - `:theme` (`:dark | :light | :system`, default `:dark`) — selects the
    server-rendered operator-surface theme lane. `:system` follows the
    visitor's OS preference through scoped CSS only; Threadline does not add
    JavaScript, local storage, or a runtime theme toggle.
  ```
- `lib/threadline/operator_surface/style.ex` — dark base (~:178), `[data-tl-theme="light"]`
  forced lane (~:188–237), `@media (prefers-color-scheme: light) [data-tl-theme="system"]`
  OS-auto branch (~:239–289). Confirms: `:system` = OS-auto (pure CSS, no JS/FOUC),
  `:light` = forced, `:dark` = default.
- `lib/threadline/operator_surface/auth.ex` ~:14, 177–179 — `normalize_theme/1` → `data-tl-theme`
  socket assign.

---

### `README.md` (doc) — MODIFY

**Analog:** the "Operator Surface" paragraph (line 126) — one additive sentence, no snippet change.

**Insertion anchor** (line 126):
```markdown
Threadline ships an optional, drop-in LiveView **operator console** — a dark,
branded admin surface for investigating the audit trail natively in your app,
```
Plan (D-05): add a **one-line `theme: :system` daytime pointer** near this "dark, branded
admin surface" line (e.g., a trailing sentence pointing daytime/bright-environment teams to
`theme: :system`, linking the operator-surface guide's Theme subsection). The **1-Minute
Mount snippet (lines 142–156) MUST stay UNCHANGED** — it is the dark-default adopter example
and 3 snippet doc-contract tests assert it verbatim (D-05).

---

### `test/threadline/operator_surface/theme_doc_contract_test.exs` (test, transform) — NEW

**Analog:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` (cleanest
minimal literal-pin) and `coverage_doc_contract_test.exs` (richer set). Per Claude's-Discretion
(line 114), this may be a separate file **or** assertions appended to an existing operator-surface
doc-contract test — separate file recommended for clarity.

**Module + path-constant + read-and-pin pattern** (timeline_browse lines 1–28):
```elixir
defmodule Threadline.OperatorSurface.TimelineBrowseDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  ...

  test "router declares the timeline browse live route at /timeline" do
    router_src = File.read!(@router_path)

    assert String.contains?(router_src, ~s|live("/timeline", TimelineLive, :index)|),
           "expected #{@router_path} to declare ... inside the live_session :threadline scope"
  end
end
```

**Coverage-style guide literal pin** (coverage lines 56–62 — `String.contains?` on a doc/source path):
```elixir
src = File.read!(@surface_header_path)
assert String.contains?(src, "All tables captured"),
       "expected #{@surface_header_path} to render the literal \"All tables captured\""
```

Plan: new test pins `guides/operator-surface.md` (use a `@guide_path
"guides/operator-surface.md"` constant). Assert via `String.contains?` that the guide
documents (D-05 lock — each literal asserted individually so CI pinpoints the regressed line):
- the `theme:` option literal,
- each of `:dark`, `:light`, `:system`,
- the daytime-use recommendation phrasing (the D-04 precedent one-liner, or a stable fragment
  of it such as `"daytime-use recommendation"` / `":system"` + `"daytime"`).
Use `async: true` (pure source-reading, like timeline_browse). Do NOT add runtime/Mix-task
assertions (coverage's `capture_io` blocks are out of scope here).

**Do NOT touch** the 3 existing snippet contract tests (`getting_started_saas_doc_contract_test.exs`,
`example_phoenix_readme_contract_test.exs`, `example_phoenix_schemas_mount_contract_test.exs`) —
they assert the canonical dark-default mount verbatim (D-05, specifics line 248).

## Shared Patterns

### Literal-pin doc-contract (read-file + `String.contains?` assert)
**Source:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` (whole file),
`test/threadline/operator_surface/coverage_doc_contract_test.exs` lines 56–62.
**Apply to:** the new `theme_doc_contract_test.exs`.
```elixir
src = File.read!(@guide_path)
assert String.contains?(src, ~s|theme:|), "expected #{@guide_path} to document the theme: option"
```
Each literal gets its own assertion + a message naming the file and the expected fragment.

### Lane gating (compile-time `:system` + CI-skip local-only)
**Source:** `playwright.config.ts` line 13 (`THREADLINE_E2E_THEME === "system"` → `lightLane`);
`operator-screenshot-regression.spec.ts` lines 78–81 (`test.skip(!!process.env.CI, ...)`);
`run-e2e.sh` lines 93–99 (forced router recompile for the compile-time theme gate).
**Apply to:** the screenshots spec light-suffix branch and the light regression mirror — both
inherit the existing env gate and the CI-skip posture. No new gate is invented (cf0e8e2 / 168 D-01).

### Project-name viewport switch
**Source:** `operator-screenshots.spec.ts` lines 53–62; `operator-screenshot-regression.spec.ts`
lines 83–92.
**Apply to:** teaching both specs the `desktop-chromium-light` project name (→ `1280`, desktop-only).

## No Analog Found

None. Every file in this phase extends an existing in-file or sibling pattern. This is the
expected shape of an evidence + documentation phase that reuses Phase-168 light plumbing.

## Metadata

**Analog search scope:**
- `examples/threadline_phoenix/e2e/tests/` and `examples/threadline_phoenix/e2e/` (Playwright lane)
- `test/threadline/operator_surface/*_doc_contract_test.exs` (literal-pin family)
- `guides/operator-surface.md`, `README.md` (doc surfaces)
- `lib/threadline/operator_surface/{router,auth,style}.ex` (read-only source-truth for docs)

**Files scanned:** 8 (3 e2e specs, 1 playwright config, 1 run-e2e.sh, 2 doc-contract tests,
1 guide + README excerpt + router.ex excerpt)
**Pattern extraction date:** 2026-06-14
