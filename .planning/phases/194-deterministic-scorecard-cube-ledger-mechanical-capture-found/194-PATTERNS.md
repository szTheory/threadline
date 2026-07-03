# Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation — Pattern Map

**Mapped:** 2026-07-03
**Files analyzed:** 13
**Analogs found:** 12 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/design-system-ledger.json` | config | transform (v1→v2 in-place migration) | itself (v1 shape) | self |
| `test/threadline/operator_surface/stress_ledger_test.exs` | test | batch (guard loop over entries) | itself (10 existing test blocks to extend) | self |
| `lib/threadline/operator_surface/mechanical_checker.ex` | utility | batch (JSON read → arithmetic → violations list) | `test/threadline/brandbook_token_parity_test.exs` (LOCKED-constant idiom) + `lib/threadline/operator_surface/style.ex` (module-attribute token constants) | role-match |
| `test/threadline/operator_surface/mechanical_checker_test.exs` | test | batch (pure filesystem + arithmetic) | `test/threadline/brandbook_token_parity_test.exs` + `test/threadline/operator_surface/stress_ledger_test.exs` | exact |
| `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` | test (e2e) | request-response (browser capture loop) | `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` | exact |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | config | — | itself (add tier-a projects) | self |
| `lib/threadline/operator_surface/stress_fixtures.ex` | utility | — | itself (@viewports) | self |
| `lib/threadline/operator_surface/live/stress_live.ex` | — | — | itself (verify @viewport_allowlist derives from StressFixtures) | self |
| `mix.exs` | config | — | itself (existing verify.* + verify_example_browser/1 pattern) | self |
| `DESIGN-SYSTEM.md` | documentation | transform | itself (add per-lens columns) | self |
| `.planning/scorecards/<cell-id>.json` + `.aria.yml` | config | — | `.planning/design-system-ledger.json` (committed diffable artifact pattern) | role-match |
| `.gitignore` | config | — | itself | self |
| `examples/threadline_phoenix/e2e/package.json` | config | — | itself | self |

---

## Pattern Assignments

### `.planning/design-system-ledger.json` (v1 → v2 in-place migration)

**Analog:** itself (current v1 shape)

**Current v1 top-level keys** (enforced by `@top_level_keys` in guard test, lines 10–18):
```
entries, phase, ratchet, ratchet_rule, required_inventory, screenshot_allowlist, version
```

**v2 additions — new top-level keys (add in sorted order):**
```
cube_axes, mechanical_floors
```
New sorted v2 set: `cube_axes, entries, mechanical_floors, phase, ratchet, ratchet_rule, required_inventory, screenshot_allowlist, version`

**`cube_axes` block pattern** (RESEARCH.md Area 9, lines 919–948):
```json
"cube_axes": {
  "personas": [
    {"slug": "P1", "label": "Change actor-first", "lens_weights": ["hierarchy", "density"]},
    {"slug": "P2", "label": "Plain / low-density", "lens_weights": ["hierarchy", "density"]},
    {"slug": "P3", "label": "Verdict-first", "lens_weights": ["hierarchy", "density"]},
    {"slug": "P4", "label": "TBD", "lens_weights": ["hierarchy", "density"]},
    {"slug": "P5", "label": "TBD", "lens_weights": ["hierarchy", "density"]}
  ],
  "lenses": [
    {"slug": "hierarchy",      "method": "critic-only",          "kind": "judged",  "authority": "signoff"},
    {"slug": "density",        "method": "mechanical+critic",    "kind": "hybrid",  "authority": "auto+signoff"},
    {"slug": "rhythm",         "method": "mechanical+critic",    "kind": "hybrid",  "authority": "auto+signoff"},
    {"slug": "typography",     "method": "mechanical+critic",    "kind": "hybrid",  "authority": "auto+signoff"},
    {"slug": "color_contrast", "method": "mechanical+critic",    "kind": "hybrid",  "authority": "auto+signoff"},
    {"slug": "brand_fidelity", "method": "mechanical-veto+critic","kind": "veto",   "authority": "auto"}
  ]
}
```

**Per-entry v2 shape** (RESEARCH.md lines 872–909; field order must be sorted for guard test 2):
```json
{
  "category": "page",
  "current_score": 62,
  "evidence_ref": null,
  "fixture_key": "page.home.happy",
  "id": "page.home.happy",
  "kind": "page",
  "legacy_score": 72,
  "notes": "...",
  "owner_phase": 171,
  "ratchet_score": 62,
  "reset_rationale": null,
  "screenshot_baseline_refs": ["stress-page-home-happy-dark-1024.png"],
  "scores": {
    "P1.density":          {"current": null, "floor": 0, "status": "unrated"},
    "P1.hierarchy":        {"current": null, "floor": 0, "status": "unrated"},
    "P2.density":          {"current": null, "floor": 0, "status": "unrated"},
    "P2.hierarchy":        {"current": null, "floor": 0, "status": "unrated"},
    "P3.density":          {"current": null, "floor": 0, "status": "unrated"},
    "P3.hierarchy":        {"current": null, "floor": 0, "status": "unrated"},
    "P4.density":          {"current": null, "floor": 0, "status": "unrated"},
    "P4.hierarchy":        {"current": null, "floor": 0, "status": "unrated"},
    "P5.density":          {"current": null, "floor": 0, "status": "unrated"},
    "P5.hierarchy":        {"current": null, "floor": 0, "status": "unrated"},
    "all.brand_fidelity":  {"current": null, "floor": 0, "status": "unrated"},
    "all.color_contrast":  {"current": null, "floor": 0, "status": "unrated"},
    "all.rhythm":          {"current": null, "floor": 0, "status": "unrated"},
    "all.typography":      {"current": null, "floor": 0, "status": "unrated"}
  },
  "source": "Threadline.OperatorSurface.StressFixtures",
  "status": "baseline",
  "story_id": "page.home.happy",
  "stress_path": "/audit/__stress?story=page.home.happy",
  "target_score": 90
}
```

**Critical constraints:**
- `current_score` and `target_score` MUST remain top-level on every entry (guard test 9 / `inventory_row/1` checks these exact field names at line 245–247 of `stress_ledger_test.exs`).
- `current_score` becomes the guard-recomputed `min()` over all non-null cells (null cells count as 0). The old opaque value goes in `legacy_score`.
- `scores` cell keys use `persona.lens` dotted grammar, sorted. Persona-invariant lenses use `"all"` as persona prefix.
- `evidence_ref` is optional (only present when `current_score > ratchet_score`) — add to `@optional_entry_keys`, not `@entry_keys`.
- `legacy_score` and `scores` are REQUIRED after migration — add to `@entry_keys`.

**`mechanical_floors` block pattern:**
```json
"mechanical_floors": {
  "page.home.happy": {
    "all.color_contrast": {"dark_375": 0, "dark_768": 0, "dark_1280": 0, "light_375": 0, "light_768": 0, "light_1280": 0},
    "all.rhythm":         {"dark_375": 0, "dark_768": 0, "dark_1280": 0, "light_375": 0, "light_768": 0, "light_1280": 0}
  }
}
```

**`ratchet.signoffs` addition** (append-only block for judged-lens floor bumps):
```json
"ratchet": {
  "locked_ids": [...],
  "minimum_scores": {...},
  "resets": {},
  "signoffs": []
}
```

---

### `test/threadline/operator_surface/stress_ledger_test.exs` (MODIFY — extend guard)

**Analog:** itself (all 10 existing test blocks)

**Module structure to preserve** (lines 1–69):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressLedgerTest do
    use ExUnit.Case, async: true

    alias Threadline.OperatorSurface.StressFixtures

    @ledger_path ".planning/design-system-ledger.json"
    @design_system_path "DESIGN-SYSTEM.md"
    # ... module attributes
  end
end
```

**`@top_level_keys` — replace with v2 set** (currently lines 10–18):
```elixir
@top_level_keys ~w(
  cube_axes
  entries
  mechanical_floors
  phase
  ratchet
  ratchet_rule
  required_inventory
  screenshot_allowlist
  version
)
```

**`@entry_keys` — add `legacy_score` and `scores`** (currently lines 20–35):
```elixir
@entry_keys ~w(
  category
  current_score
  fixture_key
  id
  kind
  legacy_score
  notes
  owner_phase
  ratchet_score
  screenshot_baseline_refs
  scores
  source
  status
  story_id
  stress_path
  target_score
)
```

**`@optional_entry_keys` — add `evidence_ref`** (currently line 37):
```elixir
@optional_entry_keys ~w(evidence_ref reset_rationale reserved_for_phase)
```

**`@forbidden_terms` — add `Lost Pixel`** (currently lines 61–69):
```elixir
@forbidden_terms [
  "---",
  "PhoenixStorybook",
  "Tailwind",
  "Chromatic",
  "Percy",
  "Applitools",
  "Lost Pixel",
  "immutable ledger"
]
```

**New guard assertions to ADD (new test blocks following the existing style):**

Test block: per-cell monotonicity (LEDGER-02):
```elixir
test "per-cell scores can only ratchet upward or be unrated" do
  ledger = ledger()
  reset_ids = Map.keys(Map.get(ledger["ratchet"], "resets", %{}))
  cube_axes = ledger["cube_axes"]
  valid_cell_keys = valid_cell_keys(cube_axes)

  for entry <- ledger["entries"], entry["kind"] in ~w(page group foundation) do
    id = entry["id"]
    scores = entry["scores"] || %{}

    for {cell_key, cell} <- scores do
      assert cell_key in valid_cell_keys,
             "#{id} cell key #{inspect(cell_key)} is not declared in cube_axes"

      current = cell["current"]
      floor = cell["floor"] || 0

      if not is_nil(current) do
        if current < floor do
          assert id in reset_ids,
                 "#{id} cell #{cell_key}: current #{current} is below floor #{floor} without a ratchet reset"
        else
          assert current >= floor,
                 "#{id} cell #{cell_key}: current #{current} must be >= floor #{floor}"
        end
      end
    end
  end
end
```

Test block: evidence-on-gain (LEDGER-03):
```elixir
test "score increases carry a File.exists?-true evidence_ref" do
  for entry <- entries() do
    id = entry["id"]

    if entry["current_score"] > entry["ratchet_score"] do
      ref = entry["evidence_ref"]
      assert is_binary(ref) and ref != "",
             "#{id} has a score increase but evidence_ref is missing or empty"
      assert File.exists?(ref),
             "#{id} has a score increase but evidence_ref path does not exist: #{inspect(ref)}"
    end
  end
end
```

Test block: cube_axes axis validity (LEDGER-01):
```elixir
test "cube_axes declares all 6 lenses in the correct frozen order" do
  ledger = ledger()
  cube_lenses = Enum.map(ledger["cube_axes"]["lenses"], & &1["slug"])

  assert cube_lenses == ~w(hierarchy density rhythm typography color_contrast brand_fidelity),
         "cube_axes lenses must match the D-01 frozen vocabulary in fixed order"
end
```

Test block: floor-bump authority (D-02 guard invariant 5):
```elixir
test "mechanical-authority cells do not carry signoff floor bumps" do
  ledger = ledger()
  auto_lenses = ~w(density rhythm typography color_contrast brand_fidelity)
  signoffs = Map.get(ledger["ratchet"], "signoffs", [])

  for signoff <- signoffs do
    lens = signoff["cell_key"] |> String.split(".") |> List.last()
    refute lens in auto_lenses,
           "signoff for #{signoff["cell_key"]} targets a mechanical-authority lens (auto lenses ratchet automatically, not via signoff)"
  end
end
```

**Private helpers to add:**
```elixir
defp valid_cell_keys(cube_axes) do
  personas = Enum.map(cube_axes["personas"], & &1["slug"])
  lenses = Enum.map(cube_axes["lenses"], & &1["slug"])
  invariant_lenses = ~w(rhythm typography color_contrast brand_fidelity)

  persona_keyed =
    for p <- personas, l <- lenses, l not in invariant_lenses, do: "#{p}.#{l}"

  invariant_keyed = for l <- invariant_lenses, do: "all.#{l}"

  Enum.sort(persona_keyed ++ invariant_keyed)
end
```

**Existing test 8 extension** — add a `@design_sections` entry or new lens-table section check:
```elixir
# Add to @design_sections list:
"Scorecard Cube"
```

**Existing `inventory_row/1` must stay unchanged** (line 245–247):
```elixir
defp inventory_row(entry) do
  "| `#{entry["id"]}` | #{entry["status"]} | #{entry["current_score"]} | #{entry["target_score"]} |"
end
```

**House style conventions** (from existing module docstring lines 16–20):
- One concern per test block.
- Custom failure messages on every `assert`/`refute` (include `id`, field name, observed value, expected value).
- `async: true` — pure filesystem reads, no shared state.
- `File.read!` inside test or private helper at top of each test, not a module-level macro.

---

### `lib/threadline/operator_surface/mechanical_checker.ex` (CREATE)

**Analog:** `test/threadline/brandbook_token_parity_test.exs` (LOCKED-constant + meta-test idiom) + `lib/threadline/operator_surface/style.ex` (module-attribute token SSOT pattern)

**Module skeleton pattern** (mirrors brandbook_token_parity_test.exs structure: pure computation, no Phoenix dep, file-level `if Code.ensure_loaded?` NOT needed since this is a plain utility module):
```elixir
defmodule Threadline.OperatorSurface.MechanicalChecker do
  @moduledoc false

  # MODE-A LOCKED constants — pinned by mechanical_checker_test.exs meta-test.
  # These may NEVER be loosened; only WCAG can change them.
  @wcag_text_contrast_ratio 4.5
  @wcag_large_text_contrast_ratio 3.0
  @wcag_non_text_contrast_ratio 3.0
  @wcag_large_text_px 24
  @wcag_large_text_bold_px 18.66

  # MODE-B far ceilings — brand-anchored absolute limits (>3 = violation).
  @mode_b_card_nesting_ceiling 3
  @mode_b_distinct_accent_hue_ceiling 3

  # Token scale constants (from style.ex, cross-validated by meta-test).
  @spacing_scale_px [4, 8, 12, 16, 20, 24, 32, 40, 48]
  @radius_scale_px [3, 4, 6, 8, 12, 999]
  @motion_duration_ms [120, 180, 240]
  @font_size_scale_px [12, 13, 14, 15, 16, 20, 24, 32]

  @scorecards_dir ".planning/scorecards"

  @doc """
  Run all mechanical checks against committed scorecard JSON artifacts.
  Returns {:ok, []} on pass or {:error, violations} on failure.
  Each violation is a map with :cell_id, :metric, :mode, :selector,
  :observed, :expected, :fix keys.
  """
  def run(opts \\ []) do
    scorecard_dir = Keyword.get(opts, :scorecard_dir, @scorecards_dir)

    violations =
      scorecard_dir
      |> list_scorecards()
      |> Enum.flat_map(&check_scorecard/1)

    if violations == [], do: {:ok, []}, else: {:error, violations}
  end

  # ... private implementation
end
```

**WCAG relative luminance formula** (from RESEARCH.md Area 6 — implement verbatim, not simplified):
```elixir
defp relative_luminance({r, g, b}) do
  [r, g, b]
  |> Enum.map(fn c ->
    srgb = c / 255.0
    if srgb <= 0.04045 do
      srgb / 12.92
    else
      :math.pow((srgb + 0.055) / 1.055, 2.4)
    end
  end)
  |> then(fn [r_lin, g_lin, b_lin] ->
    0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin
  end)
end

defp contrast_ratio(l1, l2) do
  {lighter, darker} = if l1 >= l2, do: {l1, l2}, else: {l2, l1}
  (lighter + 0.05) / (darker + 0.05)
end
```

**Violation message format** (from D-04 — located, actionable, fix-carrying):
```elixir
# Each violation map must carry:
%{
  cell_id: "page.home.happy__dark-1280",
  metric: "wcag_contrast",
  mode: "A",
  selector: "h1.tl-home__title",
  observed: "3.2:1",
  expected: "4.5:1",
  fix: "Change foreground to --tl-color-text (computed: #E8ECF4) for 7.1:1 ratio"
}
```

**No Phoenix LiveView guard** — this module has no LiveView dependency; omit the `if Code.ensure_loaded?(Phoenix.LiveView) do` wrapper used in `stress_ledger_test.exs` and `style.ex`. It is pure Elixir computation over JSON.

---

### `test/threadline/operator_surface/mechanical_checker_test.exs` (CREATE)

**Analogs:**
1. `test/threadline/brandbook_token_parity_test.exs` — LOCKED-constant meta-test idiom (pin that constants exist in the source file as strings)
2. `test/threadline/operator_surface/stress_ledger_test.exs` — house style (async:true, custom failure messages, one concern per test)

**Module skeleton** (mirrors `brandbook_token_parity_test.exs` lines 1–21):
```elixir
defmodule Threadline.OperatorSurface.MechanicalCheckerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # Meta-test: locks MODE-A LOCKED constants in mechanical_checker.ex.
  # Mirrors the brandbook_token_parity_test.exs "correct by default" idiom.
  # These constants cannot drift without failing CI.

  @checker_path "lib/threadline/operator_surface/mechanical_checker.ex"
  @scorecards_dir ".planning/scorecards"

  # ... tests
end
```

**Meta-test pattern for pinning LOCKED constants** (mirrors brandbook_token_parity_test.exs lines 109–116):
```elixir
test "MODE-A LOCKED constants are present in mechanical_checker.ex" do
  source = File.read!(@checker_path)

  for {constant, value} <- [
    {"@wcag_text_contrast_ratio", "4.5"},
    {"@wcag_large_text_contrast_ratio", "3.0"},
    {"@wcag_non_text_contrast_ratio", "3.0"},
    {"@wcag_large_text_px", "24"},
    {"@wcag_large_text_bold_px", "18.66"},
    {"@mode_b_card_nesting_ceiling", "3"},
    {"@mode_b_distinct_accent_hue_ceiling", "3"}
  ] do
    assert String.contains?(source, "#{constant} #{value}"),
           "#{@checker_path} must declare #{constant} #{value} — MODE-A LOCKED constants may never be loosened"
  end
end

test "spacing and token scale constants match style.ex values" do
  source = File.read!(@checker_path)

  assert String.contains?(source, "@spacing_scale_px [4, 8, 12, 16, 20, 24, 32, 40, 48]"),
         "#{@checker_path} @spacing_scale_px must match the 9-step --tl-space-* scale from style.ex"

  assert String.contains?(source, "@radius_scale_px [3, 4, 6, 8, 12, 999]"),
         "#{@checker_path} @radius_scale_px must match the 6-value --tl-radius-* scale from style.ex"

  assert String.contains?(source, "@motion_duration_ms [120, 180, 240]"),
         "#{@checker_path} @motion_duration_ms must match --tl-motion-fast/base/slow from style.ex"

  assert String.contains?(source, "@font_size_scale_px [12, 13, 14, 15, 16, 20, 24, 32]"),
         "#{@checker_path} @font_size_scale_px must match the 8-step --tl-font-size-* scale from style.ex"
end
```

**Checker unit tests** (mirrors stress_ledger_test.exs one-concern-per-block style):
```elixir
test "WCAG relative luminance formula uses 2.4 gamma exponent" do
  # #FFFFFF → L = 1.0; #000000 → L = 0.0
  assert MechanicalChecker.relative_luminance({255, 255, 255}) == 1.0
  assert MechanicalChecker.relative_luminance({0, 0, 0}) == 0.0
  # Mid-tone verification: #4F8CFF (--tl-color-thread-blue) luminance ~0.24
  # (fails 4.5:1 for normal text on #0B1020 bg but passes 3:1 for non-text)
  thread_blue_lum = MechanicalChecker.relative_luminance({79, 140, 255})
  dark_bg_lum = MechanicalChecker.relative_luminance({11, 16, 32})
  ratio = MechanicalChecker.contrast_ratio(thread_blue_lum, dark_bg_lum)
  assert ratio < 4.5, "thread-blue on dark bg must fail 4.5:1 normal text threshold"
  assert ratio >= 3.0, "thread-blue on dark bg must pass 3:1 non-text threshold"
end

test "spacing conformance check detects off-scale values" do
  # ... unit-test the pure-Elixir check functions with fixture JSON
end

test "run/1 returns :ok when scorecards directory is empty or all cells pass" do
  # ... integration test against empty or minimal fixture scorecards
end
```

---

### `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` (CREATE)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` (exact)

**Imports and constants to copy from analog** (lines 1–19):
```typescript
import { expect, Page, test } from "@playwright/test";
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const ledgerPath = resolve(process.cwd(), "../../..", ".planning/design-system-ledger.json");
const repoRoot = resolve(process.cwd(), "../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const artifactsDir = resolve(repoRoot, "examples/threadline_phoenix/e2e/artifacts/tier-a");
```

**Reuse ALL FOUR helpers verbatim from operator-stress.spec.ts** (lines 46–66):
```typescript
// Copy these four functions unchanged:
function dynamicMasks(page: Page) { ... }    // lines 46–51
function stressScreenshotOutputDir() { ... } // lines 53–60
function stressPacketName(...) { ... }        // lines 62–66
// Also reuse desktopSnapshotPath() only if referencing Tier C baselines
```

**Cell-id convention** (D-03 — mirrors `stressPacketName` slug convention):
```typescript
function tierACellId(ledgerId: string, theme: string, breakpoint: number): string {
  // e.g. "page.home.happy__dark-1280"
  return `${ledgerId}__${theme}-${breakpoint}`;
}

function scorecardPath(cellId: string): string {
  return resolve(scorecardsDir, `${cellId}.json`);
}

function ariaSnapshotPath(cellId: string): string {
  return resolve(scorecardsDir, `${cellId}.aria.yml`);
}
```

**`evaluate()` for token resolution** (RESEARCH.md Area 5, lines 470–514 — copy verbatim):
```typescript
const tokens = await page.evaluate(() => {
  const root = document.querySelector('.threadline-ui');
  if (!root) return {};
  const style = getComputedStyle(root);
  return {
    '--tl-space-1': style.getPropertyValue('--tl-space-1').trim(),
    // ... (all 25+ token entries from RESEARCH.md lines 476–513)
  };
});
```

**`locator.ariaSnapshot()` pattern** (RESEARCH.md Area 5, lines 459–467):
```typescript
// Use '#tl-main' subtree to exclude dynamic header/timestamp content (Pitfall 6)
const ariaYaml = await page.locator('#tl-main').ariaSnapshot();
writeFileSync(ariaSnapshotPath(cellId), ariaYaml, 'utf8');
```

**Determinism stack** (must apply to EVERY capture call):
```typescript
// Set per-test (not per-project) for 375/768 breakpoints:
await page.setViewportSize({ width: 375, height: 900 });
// deviceScaleFactor: 1 is set at project level in playwright.config.ts
// reducedMotion: "reduce" is set globally in playwright.config.ts
// dynamicMasks() applied to all screenshots
```

**Scorecard JSON emission** (RESEARCH.md lines 827–868 schema):
```typescript
const scorecard = {
  cell_id: cellId,
  ledger_id: ledgerId,
  theme,
  breakpoint,
  captured_at: new Date().toISOString(),
  playwright_version: "1.61.1",
  tokens,
  metrics: {
    mode_a: { spacing_violations: [], radius_violations: [], /* ... */ wcag_violations: [] },
    mode_b: { type_size_count, interactive_control_count, card_nesting_depth, scroll_cost, distinct_accent_hue_count }
  },
  a11y_summary: { headings, landmarks, interactive_elements },
  artifacts: {
    screenshot: `examples/threadline_phoenix/e2e/artifacts/tier-a/${cellId}/screenshot.png`,
    dom: `examples/threadline_phoenix/e2e/artifacts/tier-a/${cellId}/dom.html`,
    aria: `.planning/scorecards/${cellId}.aria.yml`
  }
};
writeFileSync(scorecardPath(cellId), JSON.stringify(scorecard, null, 2), 'utf8');
```

**Tier A matrix structure:**
- Band 1: all 11 pages × `happy` × [375, 768, 1280] × [dark, light] = 66 cells
- Band 2: [transaction, coverage, retention] × [empty, error, permission-denied] × [375, 768, 1280] × [dark, light] = 54 cells

---

### `examples/threadline_phoenix/e2e/playwright.config.ts` (MODIFY — add tier-a projects)

**Analog:** itself (existing `desktop-chromium-light` conditional project, lines 19–39)

**Pattern to copy** (the conditional project pattern, lines 19–39):
```typescript
// Add AFTER existing projects array — two new tier-a projects:
{
  name: "tier-a-capture",
  testMatch: /operator-tier-a-capture\.spec\.ts/,
  use: {
    ...devices["Desktop Chrome"],
    viewport: { width: 1280, height: 900 },
    deviceScaleFactor: 1,   // CRITICAL: byte-stable pixel output (Pitfall 5)
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
```

**Key:** `reducedMotion: "reduce"` is already in the global `use:` block (line 57) — do NOT add it per-project. `deviceScaleFactor: 1` is new and must be in the project-level `use:`, not global (it would break Tier C baselines if set globally). The existing `scale: "css"` is used only in individual screenshot calls in the spec, not in config.

---

### `lib/threadline/operator_surface/stress_fixtures.ex` (MODIFY — add 1280 to @viewports)

**Analog:** itself (line 25)

**Current** (line 25):
```elixir
@viewports [320, 375, 768, 1024, 1440]
```

**Change to:**
```elixir
@viewports [320, 375, 768, 1024, 1280, 1440]
```

This propagates to `stress_live.ex`'s `@viewport_allowlist` automatically (it derives from `StressFixtures.viewports()`). Keep `1024` for backward compat with 3 existing Tier C baselines.

---

### `lib/threadline/operator_surface/live/stress_live.ex` (VERIFY ONLY)

**Analog:** itself

**Verify** that after adding `1280` to `StressFixtures.viewports()`, the `@viewport_allowlist` in `stress_live.ex` (which derives from `StressFixtures.viewports() |> Enum.map(&Integer.to_string/1)`) automatically includes `"1280"`. No code change needed — just confirm the derivation is dynamic. If it is hardcoded, update it to match `StressFixtures.viewports()`.

---

### `mix.exs` (MODIFY — new aliases + ci.all wiring)

**Analog:** existing `verify_operator_stress/1` (line 194–196) for the `verify_capture` pattern; `"verify.compile_no_optional"` inline list (line 97) for simple list-delegate; `cli/0` preferred_envs block (lines 7–21) for env additions.

**New alias entries** (add to `aliases/0` block, sorted position):
```elixir
"verify.capture": &verify_capture/1,
"verify.mechanical": ["test test/threadline/operator_surface/mechanical_checker_test.exs"],
```

**New private function** (mirrors `verify_operator_stress/1` at lines 194–196):
```elixir
# Wraps npm run capture:tier-a — local-only regeneration, NOT in ci.all.
# Mirrors verify_operator_stress/1 / verify_example_browser/1 pattern.
defp verify_capture(args),
  do: verify_example_browser(["--project=tier-a-capture" | args])
```

**`ci.all` update** (add `"verify.mechanical"` before `"verify.example_browser"`, lines 102–114):
```elixir
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.compile_no_optional",
  "verify.test",
  "verify.threadline",
  "verify.example",
  "verify.doc_contract",
  "verify.mechanical",       # NEW: reads committed scorecard JSON, no browser
  "verify.example_browser"   # Browser e2e last (slowest)
]
```

**`cli/0` preferred_envs additions** (add to the `preferred_envs` keyword list, lines 11–20):
```elixir
"verify.mechanical": :test,
"verify.capture": :test,
```

---

### `DESIGN-SYSTEM.md` (MODIFY — add per-lens columns projection)

**Analog:** itself (current `inventory_row/1` format verified in guard test 9 at `stress_ledger_test.exs` line 245–247)

**Existing row format that must continue to work** (guard test 9):
```
| `page.home.happy` | baseline | 62 | 90 |
```

**New per-lens table to add** (one row per `(entry × persona)`, one column per lens per D-02):
```markdown
## Scorecard Cube

| Entry | Persona | hierarchy | density | rhythm | typography | color_contrast | brand_fidelity | Score |
|-------|---------|-----------|---------|--------|------------|----------------|----------------|-------|
| `page.home.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.home.happy` | P2 | — | — | — | — | — | — | 62 |
```

- `—` renders for `"unrated"` cells per D-02.
- Column order = D-01 frozen lens order: `hierarchy · density · rhythm · typography · color_contrast · brand_fidelity`.
- Persona-invariant lenses (`rhythm`, `typography`, `color_contrast`, `brand_fidelity`) show the same value for each persona row (they are stored once at `"all"` but displayed per persona row for readability).
- The guard test must add a new `inventory_row_per_persona/2` helper and assert it appears for each entry × persona combination.

---

### `.planning/scorecards/<cell-id>.json` + `<cell-id>.aria.yml` (CREATE — evidence artifacts)

**Analog:** `.planning/design-system-ledger.json` (committed diffable JSON artifact pattern)

**Cell-id convention:** `{ledger_id}__{theme}-{breakpoint}` (e.g. `page.home.happy__dark-1280`)

**Scorecard JSON schema** (RESEARCH.md lines 827–868 — full schema reproduced in operator-tier-a-capture.spec.ts section above).

**Aria YAML source:** `locator('#tl-main').ariaSnapshot()` — scoped to `#tl-main` subtree to exclude dynamic header timestamps (Pitfall 6).

**Path convention:** `evidence_ref` in ledger entries points to `.planning/scorecards/<cell-id>.json` (repo-relative path, same pattern as `@ledger_path ".planning/design-system-ledger.json"` in the guard test). The `File.exists?` guard check resolves from the project root.

---

### `.gitignore` (MODIFY)

**Add at root `.gitignore`:**
```
/examples/threadline_phoenix/e2e/artifacts/tier-a/
```

**Add at `examples/threadline_phoenix/e2e/.gitignore`** (create if not exists):
```
artifacts/tier-a/
```

---

### `examples/threadline_phoenix/e2e/package.json` (MODIFY — add capture:tier-a script)

**Current** (lines 4–7):
```json
"scripts": {
  "test": "playwright test",
  "test:headed": "playwright test --headed"
}
```

**Add:**
```json
"scripts": {
  "test": "playwright test",
  "test:headed": "playwright test --headed",
  "capture:tier-a": "playwright test --project=tier-a-capture --project=tier-a-capture-light operator-tier-a-capture.spec.ts"
}
```

---

## Shared Patterns

### async: true + pure filesystem reads
**Source:** `test/threadline/operator_surface/stress_ledger_test.exs` line 3 + `test/threadline/brandbook_token_parity_test.exs` line 3
**Apply to:** ALL new Elixir test files in this phase
```elixir
use ExUnit.Case, async: true
```
All tests read only committed files from `.planning/` or `lib/` — no DB, no network, no LiveView process required.

### Custom failure messages on every assert
**Source:** `stress_ledger_test.exs` lines 74–97 (every assert has a custom message)
**Apply to:** ALL new test assertions
```elixir
assert condition,
       "#{id} field #{inspect(field)}: observed #{inspect(observed)}, expected #{inspect(expected)}"
```

### `if Code.ensure_loaded?(Phoenix.LiveView) do` guard
**Source:** `stress_ledger_test.exs` line 1
**Apply to:** `stress_ledger_test.exs` (already has it). Do NOT apply to `mechanical_checker_test.exs` or `mechanical_checker.ex` — those have no LiveView dependency.

### Dotted-key ID grammar
**Source:** `design-system-ledger.json` entry IDs (`page.home.happy`, `foundation.color`)
**Apply to:** scorecard cell keys (`P1.hierarchy`, `all.color_contrast`), cell-id separator pattern (`page.home.happy__dark-1280` uses `__` to separate ledger_id from theme-breakpoint qualifier)

### verify.* function shape for Playwright-wrapping aliases
**Source:** `mix.exs` lines 194–196:
```elixir
defp verify_operator_stress(args),
  do: verify_example_browser(["operator-stress.spec.ts" | args])
```
**Apply to:** `verify_capture/1` — one-liner delegating to `verify_example_browser/1` with a `--project` flag prepended.

### Repo-relative evidence paths
**Source:** `stress_ledger_test.exs` line 7: `@ledger_path ".planning/design-system-ledger.json"`
**Apply to:** All `evidence_ref` values in ledger entries and all `File.exists?` checks in guard tests. Never use absolute paths.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/operator_surface/mechanical_checker.ex` (core logic) | utility | batch JSON→arithmetic→violations | No existing pure-computation checker module in the codebase; the constant-pinning pattern is well-analogized from `brandbook_token_parity_test.exs`, but the WCAG luminance formula and mechanical metric functions are novel to this codebase. The RESEARCH.md Area 6 formulas are the authoritative source. |

---

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/`, `test/threadline/`, `examples/threadline_phoenix/e2e/`, `mix.exs`
**Files scanned:** 10 source files read directly
**Key pitfalls cross-referenced:** 7 (from RESEARCH.md Common Pitfalls section)
**Pattern extraction date:** 2026-07-03
