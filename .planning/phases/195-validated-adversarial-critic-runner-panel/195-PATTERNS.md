# Phase 195: Validated Adversarial Critic Runner & Panel — Pattern Map

**Mapped:** 2026-07-03
**Files analyzed:** 20 new/modified files across two surfaces (TypeScript CLI + pure-Elixir guards)
**Analogs found:** 17 / 20 (3 net-new with no close existing analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `e2e/critic/run.ts` | CLI entry / orchestrator | request-response | `e2e/tests/operator-tier-a-capture.spec.ts` | role-match (orchestration pattern, repoRoot convention) |
| `e2e/critic/panel.ts` | service / fan-out | event-driven | `e2e/tests/operator-tier-a-capture.spec.ts` (captureCell loop) | role-match |
| `e2e/critic/bundle.ts` | utility / file-I/O | file-I/O | `e2e/tests/operator-tier-a-capture.spec.ts` (scorecard read/path helpers) | role-match |
| `e2e/critic/prompt.ts` | utility / transform | transform | `e2e/tests/operator-tier-a-capture.spec.ts` (rawInputs builder) | partial-match |
| `e2e/critic/schema.ts` | model / validation | transform | `e2e/tests/operator-tier-a-capture.spec.ts` (scorecard shape) | partial-match |
| `e2e/critic/client.ts` | service / request-response | request-response | **No analog** — Anthropic SDK wrapper is net-new | none |
| `e2e/critic/cache.ts` | utility / file-I/O | file-I/O | `e2e/tests/operator-tier-a-capture.spec.ts` (`writeJson` + path helpers) | partial-match |
| `e2e/critic/scorecard.ts` | utility / file-I/O | file-I/O | `e2e/tests/operator-tier-a-capture.spec.ts` (`writeJson` / `scorecardPath`) | role-match |
| `e2e/critic/report.ts` | utility / transform | transform | `e2e/tests/operator-tier-a-capture.spec.ts` (DESIGN-SYSTEM.md projection from ledger) | partial-match |
| `e2e/critic/refute.ts` | utility / batch | batch | `e2e/tests/operator-tier-a-capture.spec.ts` (cell loop) | partial-match |
| `e2e/critic/label.ts` | CLI / interactive | request-response | **No analog** — keyboard-driven labeler is net-new | none |
| `e2e/critic/rubrics/*.md` | config / content | — | **No analog** — versioned lens rubrics are net-new | none |
| `e2e/package.json` | config | — | `e2e/package.json` (existing, additive change only) | exact |
| `test/…/critic_trust_test.exs` | test / guard | CRUD | `test/…/stress_ledger_test.exs` | exact |
| `mix.exs` (aliases + ci.all) | config | — | `mix.exs` (lines 81–127: `verify.flake`, `verify.mechanical`, `verify.capture`) | exact |
| `.planning/design-system-ledger.json` (critic_trust block) | config / model | CRUD | `.planning/design-system-ledger.json` (existing cube structure) | exact |
| `.planning/golden/golden-set.json` | model / oracle | CRUD | `.planning/scorecards/*.json` (committed diffable JSON shape) | role-match |
| `.planning/golden/rounds/r1.json` + `r2.json` | model / oracle | CRUD | `.planning/scorecards/*.json` | role-match |
| `.planning/critic-scores/**/*.json` | model / output | CRUD | `.planning/scorecards/*.json` (shape analog; physically separate) | role-match |
| `CRITIQUE.md` | report / projection | transform | `DESIGN-SYSTEM.md` (freshness-tested projection mechanic) | role-match |

---

## Pattern Assignments

### `e2e/critic/run.ts` (CLI entry, orchestrator)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts`

**Path/ESM resolution pattern** (lines 23–28):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:23-28
const repoRoot = resolve(process.cwd(), "../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/tier-a",
);
```
Copy: replace `process.cwd()` with `dirname(fileURLToPath(import.meta.url))` for ESM modules (see RESEARCH.md Pattern 4 — `__dirname` is undefined in ESM). `run.ts` is a module, not a Playwright entry; use `import.meta.url`.

**Pinned constants pattern** (lines 33–34):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:33-34
const PLAYWRIGHT_VERSION = "1.61.1";
const CAPTURE_TIER = "A";
const SCHEMA_VERSION = 1;
```
Copy: define `MODEL_ID = "claude-opus-4-8"` and `SCHEMA_VERSION = 1` as pinned constants, never `Date.now()` or dynamic values in committed output.

**Two-space JSON write helper** (lines 86–90):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:86-90
function writeJson(path: string, value: unknown) {
  // Two-space indent + trailing newline: matches the committed ledger convention
  // and keeps `git diff` on the scorecards byte-stable across regeneration.
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}
```
Copy verbatim into `scorecard.ts` and `cache.ts`. The two-space-indent + trailing-newline is the project's byte-stable JSON convention (matches the committed scorecards and ledger).

**CLI no-op on missing env var:** see `verify.ui_critique` in mix.exs pattern below — the Elixir alias shells out only when `ANTHROPIC_API_KEY` is set. The Node side receives the key from env (never checks itself); clean exit 0 is the Elixir layer's responsibility.

---

### `e2e/critic/panel.ts` (critic→lens map, veto ordering, fan-out)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts`

**Outer loop / cell iteration pattern** (lines 376–384):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:376-384
for (const ledgerId of BAND_1_STORIES) {
  for (const bp of BREAKPOINTS) {
    await captureCell(page, ledgerId, theme, bp, false);
  }
}
```
Copy: replace with a `for (const cell of scopedCells)` loop driving `scoreOneCell(cell, lens, persona)`. Maintain sequential ordering inside a `rubric_version × model_id` prefix group to keep the 5-min cache TTL alive (D-04/D-06).

**Cell-id construction** (lines 66–68):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:66-68
function cellId(ledgerId: string, theme: string, breakpoint: number): string {
  return `${ledgerId}__${theme}-${breakpoint}`;
}
```
Copy verbatim — `panel.ts` parses existing scorecard JSON and reconstructs cell-ids using this same formula.

---

### `e2e/critic/bundle.ts` (reads scorecard JSON + screenshot + aria)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts`

**Path helper pattern** (lines 70–77):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:70-77
function scorecardPath(id: string): string {
  return resolve(scorecardsDir, `${id}.json`);
}
function ariaSnapshotPath(id: string): string {
  return resolve(scorecardsDir, `${id}.aria.yml`);
}
```
Copy: `bundle.ts` reads `scorecardPath(cellId)` for the deterministic input and follows `scorecard.artifacts.screenshot` (a relative repo path) to load the PNG. The `artifact.aria` field is the aria snapshot path for Band-2 cells.

**Scorecard shape** (lines 321–348):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:321-348
const scorecard = {
  schema_version: SCHEMA_VERSION,
  cell_id: id,
  ledger_id: ledgerId,
  theme,
  breakpoint,
  capture_tier: CAPTURE_TIER,
  band: deepBand ? 2 : 1,
  tokens,            // --tl-* resolved values
  color_pairs,       // mechanical WCAG raw inputs
  mode_b,            // type_size_count, interactive_control_count, card_nesting_depth, scroll_cost
  a11y_summary,
  artifacts: {
    screenshot: `${relDir}/screenshot.png`,
    dom: `...`,
    a11y: `...`,
    aria: deepBand ? `.planning/scorecards/${id}.aria.yml` : null,
  },
};
```
`bundle.ts` reads this shape. Key fields for the critic: `tokens` (brand-veto token-parity check), `mode_b` (mechanical evidence lines), `artifacts.screenshot` (PNG path for vision call), `artifacts.aria` (aria snapshot for suffix). See RESEARCH.md Code Examples for the full scorecard JSON shape.

---

### `e2e/critic/prompt.ts` (cached prefix builder)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts` (rawInputs builder, partial)

No direct analog for the three-strata prompt structure (system / cached-prefix / uncached-suffix). Follow RESEARCH.md Pattern 1 (structured output call) and Pattern 3 (adaptive thinking) verbatim. Key invariants from RESEARCH.md:

- `cache_control: { type: "ephemeral" }` must go on the **last block of the cached prefix** (after the two pole images + rubric text), NOT on every block.
- Persona clause is in the **uncached suffix, last** — never in the prefix (one cached prefix per lens, not per persona).
- Prefix must exceed 4,096 tokens; assert `usage.cache_creation_input_tokens > 4096` on first call (RESEARCH.md Pattern 2).
- Screenshot: base64 `image` block, `~1092px` long edge (no `detail` knob on Anthropic).

---

### `e2e/critic/schema.ts` (Zod schema for per-dimension structured output)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts` (scorecard shape, partial)

Net-new TypeScript shape. Copy RESEARCH.md Pattern 1 exactly:

```typescript
// RESEARCH.md Pattern 1 (verified against @anthropic-ai/sdk 0.110.0)
import { z } from "zod";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";

const CriticDimensionSchema = z.object({
  lens: z.enum(["hierarchy", "density", "rhythm", "typography", "color_contrast", "brand_fidelity"]),
  score: z.number().int(),        // SDK strips min/max → clamp 0-100 client-side after parse
  band: z.enum(["fail", "weak", "ok", "strong", "exemplary"]),
  pass: z.boolean(),
  evidence: z.object({
    kind: z.enum(["region", "selector", "mechanical_line"]),
    locator: z.string(),          // required — CRITIC-05 enforced at schema layer
    observation: z.string(),
  }),
  rationale: z.string(),
});
```

`evidence` and its sub-fields are `required` (not `.optional()`). A parse failure on a response without a located citation discards the score, never records it.

---

### `e2e/critic/client.ts` (Anthropic SDK wrapper, N-sample loop, retry)

**Analog:** None — net-new. This is the only module with no existing codebase analog.

Follow RESEARCH.md Pattern 1 (full `messages.parse()` call), Pattern 2 (cache verification), Pattern 3 (adaptive thinking). Key invariants:

- Do NOT send `temperature`, `top_p`, or `top_k` — returns 400 on Opus 4.8.
- Do NOT send `budget_tokens` — returns 400 on Opus 4.8.
- Use `thinking: { type: "adaptive", display: "summarized" }` explicitly.
- Use `output_config: { format: zodOutputFormat(CriticDimensionSchema) }` (not deprecated `output_format`).
- SDK handles retry/backoff on 429/5xx automatically.
- N-sample loop: call N times, compute `median(raw_scores)`, check band-mode stability. Escalate N=3→7 when: no strict majority band, OR `median` within ±2 pts of a band cut, OR within ≤5 pts of floor/target.
- Clamp score client-side: `Math.max(0, Math.min(100, result.score))` after `parsed_output`.

---

### `e2e/critic/cache.ts` (verdict cache, resume/replay)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts` (`writeJson` helper)

Cache key: `{cell_id}__{dimension}__{rubric_hash}__{model_id}` → `<cache-dir>/<key>.json`. On hit, skip the API call and return the cached result. This is the same "write JSON, read JSON" file-I/O pattern as `writeJson` in the capture spec.

```typescript
// Derived from e2e/tests/operator-tier-a-capture.spec.ts:86-90
function cacheKey(cellId: string, dimension: string, rubricHash: string, modelId: string): string {
  return `${cellId}__${dimension}__${rubricHash}__${modelId}`;
}
function cachePath(key: string): string {
  return resolve(cacheDir, `${key}.json`);
}
```

Use `existsSync` before `readFileSync`; write with `writeJson` (same two-space + trailing newline convention).

---

### `e2e/critic/scorecard.ts` (writes to `.planning/critic-scores/`)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts` (`writeJson`, `mkdirSync` + path construction)

**Directory creation pattern** (lines 294–295):
```typescript
// e2e/tests/operator-tier-a-capture.spec.ts:294-295
const artifactDir = resolve(artifactsRoot, id);
mkdirSync(artifactDir, { recursive: true });
```
Copy: `mkdirSync(resolve(criticScoresRoot, cellId, lens), { recursive: true })` before writing per-dimension output.

**Critic-score file shape** (from RESEARCH.md Code Examples):
```json
{
  "cell_id": "page.actor.happy__dark-1280",
  "lens": "hierarchy",
  "dimension": "entry_point_clarity",
  "model_id": "claude-opus-4-8",
  "rubric_version": "hierarchy@1.0.0+ab3f1234",
  "n": 3,
  "scores_raw": [58, 62, 60],
  "score": 60,
  "band": "ok",
  "band_mode": "ok",
  "iqr": 4,
  "range": 4,
  "stable": true,
  "pass": false,
  "evidence": { "kind": "selector", "locator": "...", "observation": "..." },
  "rationale": "...",
  "scored_at": "2026-07-03T12:00:00Z"
}
```

**NEVER write to `.planning/scorecards/`** — guard asserted in `critic_trust_test.exs`.

---

### `e2e/critic/report.ts` (CRITIQUE.md projection)

**Analog:** `stress_ledger_test.exs` freshness guard (lines 215–243); `DESIGN-SYSTEM.md` projection (same mechanic)

The Elixir guard in `stress_ledger_test.exs` tests that `DESIGN-SYSTEM.md` contains a specific row per ledger entry:

```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:224-233
test "DESIGN-SYSTEM projection is fresh for every ledger row" do
  markdown = design_system()
  for entry <- entries() do
    row = inventory_row(entry)
    assert String.contains?(markdown, row),
           "#{@design_system_path} is stale for #{entry["id"]}; missing row #{inspect(row)}"
  end
end
```

`report.ts` emits `CRITIQUE.md` using the same "one row per (page × persona), one column per lens" table pattern. The companion test in `critic_trust_test.exs` asserts the Betterer idiom: a row per (cell × persona) is a substring of the committed `CRITIQUE.md`. `report.ts` reads `.planning/critic-scores/` and writes `CRITIQUE.md`; it never reads the nondeterministic store and writes the deterministic bundle.

---

### `e2e/critic/refute.ts` (refute-battery runner)

**Analog:** `e2e/tests/operator-tier-a-capture.spec.ts` (cell-loop pattern)

Same iteration pattern as Band-2 stories: loop over committed refute fixtures (from `stress_fixtures.ex` idiom), score each twin, assert directional gate (polished > flawed, correct lens, located evidence). The `--refute-only` CLI flag in `run.ts` routes here.

---

### `e2e/critic/label.ts` (critic label CLI, blind-round labeler)

**Analog:** None — keyboard-driven single-annotator labeling with ID masking and blind-round enforcement is net-new. Follow D-09 spec directly. Key invariants: r1 writes to `.planning/golden/rounds/r1.json`; `--round r2` refuses until r1 is committed; `--reconcile` is the only writer of `golden-set.json`.

---

### `e2e/critic/rubrics/*.md` (per-lens versioned rubric files)

**Analog:** None — these are net-new authored content files. The versioning header format is:
```
<!-- lens: hierarchy | version: 1.0.0 | sha8: <computed-on-commit> -->
```
The `sha8` is the hash of the file's bytes, computed by the `critic rubric lint` CLI command and asserted equal to the committed value by `critic_trust_test.exs`. Each file has: `## Dimensions` (2–3 adversarial pass/fail dimensions), `## Reference bar` (prose reference to Linear/Vercel/Stripe/Grafana), `## Anchors` (named pass-pole + fail-pole golden cell-ids). Text-only rubric is ~2–2.5k tokens — below the 4,096-token cache floor; pole exemplar images in the prompt prefix are load-bearing padding.

---

### `e2e/package.json` (additive: adds devDependencies)

**Analog:** `e2e/package.json` (current file — exact, additive change)

**Current shape** (full file):
```json
{
  "name": "threadline-phoenix-e2e",
  "private": true,
  "scripts": {
    "test": "playwright test",
    "test:headed": "playwright test --headed",
    "capture:tier-a": "playwright test --project=tier-a-capture --project=tier-a-capture-light operator-tier-a-capture.spec.ts"
  },
  "devDependencies": {
    "@playwright/test": "^1.52.0"
  }
}
```

Add to `devDependencies`: `"@anthropic-ai/sdk": "^0.110.0"`, `"zod": "^3.x"`.
Add to `scripts`: `"critic:score": "tsx critic/run.ts score"`, `"critic:validate": "tsx critic/run.ts validate"`, `"critic:label": "tsx critic/run.ts label"`.

**Invariant:** `@anthropic-ai/sdk` and `zod` are `devDependencies` only — NEVER in the root `mix.exs` deps (RUNNER-05).

---

### `test/threadline/operator_surface/critic_trust_test.exs` (pure-Elixir CI guard)

**Analog:** `test/threadline/operator_surface/stress_ledger_test.exs` — exact template

**Module declaration + async pattern** (lines 1–8):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:1-8
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressLedgerTest do
    use ExUnit.Case, async: true
    @ledger_path ".planning/design-system-ledger.json"
```
Copy: use `async: true`, read `design-system-ledger.json` and `golden-set.json` via `File.read!` + `Jason.decode!`, no LLM, no network, no browser.

**Shape-assertion pattern** (lines 80–88):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:80-88
test "ledger JSON has the required top-level shape" do
  ledger = ledger()
  assert sorted_keys(ledger) == @top_level_keys,
         "#{@ledger_path} top-level keys drifted: #{inspect(sorted_keys(ledger))}"
end
```
Copy: assert `critic_trust` block exists; assert each validated lens has `alpha`, `raw_agreement`, `pairwise_acc`, `n`, `ci95`, `golden_rubric_version`, `model_id`, `validated` keys.

**Monotonicity / invariant pattern** (lines 110–135):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:110-135
test "scores can only ratchet upward unless an explicit reset is recorded" do
  ...
  if entry["current_score"] < entry["ratchet_score"] do
    assert id in reset_ids, "..."
  end
end
```
Copy structure: assert that any lens with `validated: true` has `alpha >= 0.67 AND n >= 20 AND raw_agreement >= 80`. Assert `golden_rubric_version` matches the hash on disk for the corresponding `rubrics/<lens>.md`. Assert `model_id == "claude-opus-4-8"`.

**Forbidden-terms pattern** (lines 69–78, 246–258):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:69-78
@forbidden_terms [
  "---", "PhoenixStorybook", "Tailwind", "Chromatic", "Percy",
  "Applitools", "Lost Pixel", "immutable ledger"
]
```
Copy: add `@forbidden_terms` to `critic_trust_test.exs` for brand-doc terms that must not appear in `CRITIQUE.md` (e.g., external SaaS visual-diff tool names per the locked milestone invariant).

**File.exists? evidence pattern** (lines 304–326):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:304-326
test "a score increase carries a File.exists?-true evidence_ref for every cited cell" do
  for entry <- ledger["entries"], entry["current_score"] > entry["ratchet_score"] do
    for {cell_key, path} <- ref do
      assert File.exists?(path), "#{id} evidence_ref[#{cell_key}] path does not exist: #{inspect(path)}"
    end
  end
end
```
Copy: assert every `golden-set.json` item's `cell_id` resolves to an existing `.planning/scorecards/<cell_id>.json`; assert every item has non-empty `r1.evidence` and `r2.evidence`.

**DESIGN-SYSTEM freshness idiom for CRITIQUE.md** (lines 224–243):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:235-243
test "Scorecard Cube projection is fresh for every page-entry × persona row" do
  markdown = design_system()
  for entry <- entries(), entry["kind"] == "page", persona <- @scorecard_personas do
    row = scorecard_row(entry, persona)
    assert String.contains?(markdown, row), "..."
  end
end
```
Copy: assert `CRITIQUE.md` contains one row per `(ledger_id × persona)` for every entry in `critic-scores/`. Row format: `| \`{cell_id}\` | {persona} | {hierarchy} | {density} | {rhythm} | {typography} | {color_contrast} | {brand_fidelity} | {rollup} |`.

**Helper pattern** (lines 360–365):
```elixir
# test/threadline/operator_surface/stress_ledger_test.exs:360-365
defp ledger, do: @ledger_path |> File.read!() |> Jason.decode!()
defp sorted_keys(map), do: map |> Map.keys() |> Enum.sort()
```
Copy verbatim; add `defp golden_set, do: ".planning/golden/golden-set.json" |> File.read!() |> Jason.decode!()`.

---

### `mix.exs` — new aliases + ci.all update

**Analog:** `mix.exs` (lines 81–219) — exact

**`verify.flake` local-only pattern** (lines 108–109) — the precedent for `verify.ui_critique`:
```elixir
# mix.exs:108-109
# Flake detection: re-run the suite until a failure surfaces (each repeat
# uses a fresh seed). Opt-in / nightly — not part of `ci.all` so per-PR CI
# stays fast. See the "Deterministic tests" section in CONTRIBUTING.md.
"verify.flake": ["test --repeat-until-failure 50"],
```
The doc-contract comment above the alias is load-bearing — `verify.ui_critique` needs an identical "local-only / excluded from ci.all" comment.

**`verify.capture` / `verify.example_browser` shell-out pattern** (lines 162–178, 213–219):
```elixir
# mix.exs:162-178
defp verify_example_browser(args) do
  script = Path.expand("examples/threadline_phoenix/e2e/run-e2e.sh")
  env = System.get_env() |> Enum.map(fn {k, v} -> {k, v} end) |> Kernel.++([...])
  case System.cmd("bash", [script | args], env: env, into: IO.stream(:stdio, :line)) do
    {_output, 0} -> :ok
    {_output, status} -> Mix.raise("verify.example_browser failed (#{status})")
  end
end
```
Copy for `verify_ui_critique/1`: check `System.get_env("ANTHROPIC_API_KEY")` first; if nil/empty, `IO.puts("mix verify.ui_critique: ANTHROPIC_API_KEY not set — skipping (local-only)")` and return (clean exit 0). Otherwise `System.cmd("npm", ["run", "critic:score" | args], cd: e2e_dir, env: [...], into: IO.stream(:stdio, :line))`.

**`ci.all` list pattern** (lines 110–126):
```elixir
# mix.exs:110-126
"ci.all": [
  "verify.format", "verify.credo", "compile --warnings-as-errors",
  "verify.compile_no_optional", "verify.test", "verify.threadline",
  "verify.example", "verify.doc_contract",
  # Deterministic mechanical gate
  "verify.mechanical",
  "verify.example_browser"
]
```
Add `"verify.critic_trust"` BEFORE `"verify.mechanical"` (pure Elixir, no LLM, fast). Do NOT add `"verify.ui_critique"` (local-only, LLM, excluded).

**`verify.mechanical` single-file test pattern** (line 100):
```elixir
# mix.exs:100
"verify.mechanical": ["test test/threadline/operator_surface/mechanical_checker_test.exs"],
```
Copy verbatim for `verify.critic_trust`:
```elixir
"verify.critic_trust": ["test test/threadline/operator_surface/critic_trust_test.exs"],
```

---

### `.planning/design-system-ledger.json` (add `critic_trust` block)

**Analog:** `.planning/design-system-ledger.json` (existing cube — additive only)

Add a `critic_trust` top-level key alongside existing `cube_axes`, `entries`, `mechanical_floors`, `ratchet`, etc. Shape from RESEARCH.md:
```json
"critic_trust": {
  "hierarchy": {
    "alpha": null,
    "raw_agreement": null,
    "pairwise_acc": null,
    "n": 0,
    "ci95": null,
    "golden_rubric_version": null,
    "model_id": "claude-opus-4-8",
    "validated": false
  },
  "density":       { "alpha": null, "n": 0, "validated": false },
  "rhythm":        { "alpha": null, "n": 0, "validated": false },
  "typography":    { "alpha": null, "n": 0, "validated": false },
  "color_contrast":{ "alpha": null, "n": 0, "validated": false },
  "brand_fidelity":{ "alpha": null, "n": 0, "validated": false }
}
```
All lenses start `validated: false`, `n: 0`; `stress_ledger_test.exs` top-level key assertion will need `critic_trust` added to `@top_level_keys`.

---

### `.planning/golden/golden-set.json` (new oracle file)

**Analog:** `.planning/scorecards/*.json` (committed diffable JSON shape)

Same two-space-indent + trailing-newline convention. Item shape from RESEARCH.md:
```json
{
  "id": "gs_001",
  "cell_id": "page.actor.happy__dark-1280",
  "kind": "single",
  "lens": "hierarchy",
  "r1": { "verdict": "borderline", "evidence": "...", "blind": true },
  "r2": { "verdict": "borderline", "evidence": "...", "blind": true },
  "kept": true
}
```
Top-level fields: `version`, `model_pin`, `rubric_rev`, `held_out_ids`, `items`. `held_out_ids` are frozen (CLI refuses to enqueue them). Start with an empty items array and `held_out_ids: []`.

---

### `.planning/critic-scores/**/*.json` (nondeterministic LLM output tree)

**Analog:** `.planning/scorecards/*.json` (shape analog; physically separate)

Same JSON convention; see `scorecard.ts` section above for the per-dimension file shape. Add to `.gitignore` if regenerable (D-07: "gitignored?" is at planner's discretion; RESEARCH.md suggests this tree may be gitignored given its nondeterministic nature). Guard in `critic_trust_test.exs` asserts the critic never writes a file under `.planning/scorecards/`.

---

### `CRITIQUE.md` (regenerated projection)

**Analog:** `DESIGN-SYSTEM.md` (freshness-tested mechanic from `stress_ledger_test.exs`)

Same pattern: generated by `report.ts`, never hand-edited, committed, freshness-tested by `critic_trust_test.exs`. Header declares baseline: `@v1.37 → @HEAD`. Symbol legend prints once at top (not color-only; survives grep/screen-reader). Table: one row per `(cell_id × persona)`, columns `rollup | hierarchy | density | rhythm | typography | color_contrast | brand_fidelity | flags`.

---

## Shared Patterns

### JSON byte-stability (applies to all committed JSON files)
**Source:** `e2e/tests/operator-tier-a-capture.spec.ts` lines 86–90 + `e2e/tests/operator-tier-a-capture.spec.ts` line 329 (pinned `PLAYWRIGHT_VERSION`)
**Apply to:** `golden-set.json`, `critic-scores/**/*.json`, `design-system-ledger.json` writes, `cache.ts`
```typescript
function writeJson(path: string, value: unknown) {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}
```
No `Date.now()` in committed output; use a committed `scored_at` ISO string only for human-readable provenance, never as a cache key.

### Pure-Elixir guard structure (applies to all CI-gate test modules)
**Source:** `test/threadline/operator_surface/stress_ledger_test.exs` lines 1–8, 360–365
**Apply to:** `critic_trust_test.exs`
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.<ModuleName>Test do
    use ExUnit.Case, async: true
    defp ledger, do: @ledger_path |> File.read!() |> Jason.decode!()
    defp sorted_keys(map), do: map |> Map.keys() |> Enum.sort()
  end
end
```

### Local-only mix alias (applies to `verify.ui_critique`)
**Source:** `mix.exs` line 109 (`verify.flake`) + lines 162–178 (`verify_example_browser`)
**Apply to:** `mix.exs` `verify_ui_critique/1` function
Env-var check → clean exit 0 if missing → `System.cmd("npm", ..., into: IO.stream(:stdio, :line))` if present. Excluded from `ci.all`.

### `mix.exs` `preferred_envs` (applies to all new mix aliases)
**Source:** `mix.exs` lines 10–23
```elixir
"verify.critic_trust": :test,
```
Add to `preferred_envs` so the ExUnit test runs in the `:test` env (same as `verify.mechanical`).

### `repoRoot` convention for cross-directory file access (TypeScript)
**Source:** `e2e/tests/operator-tier-a-capture.spec.ts` line 23
```typescript
const repoRoot = resolve(process.cwd(), "../../..");
```
In `e2e/critic/` modules, use:
```typescript
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");  // critic/ → e2e/ → threadline_phoenix/ → examples/ → repo
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `e2e/critic/client.ts` | service | request-response | Anthropic SDK wrapper is net-new; no API client pattern exists in the codebase |
| `e2e/critic/label.ts` | CLI / interactive | request-response | Keyboard-driven single-annotator labeling with ID masking and blind-round enforcement has no existing analog |
| `e2e/critic/rubrics/*.md` | config / content | — | Versioned adversarial lens rubrics with `sha8` version header are net-new authored content |

For these three files, the planner should draw directly from RESEARCH.md Patterns 1–4 (SDK API) and D-09 (labeler CLI spec). There is no existing codebase structure to copy.

---

## Metadata

**Analog search scope:** `test/threadline/operator_surface/`, `examples/threadline_phoenix/e2e/`, `mix.exs`, `.planning/`
**Files scanned:** 6 (stress_ledger_test.exs, operator-tier-a-capture.spec.ts, playwright.config.ts, package.json, mix.exs, stress_fixtures.ex)
**Pattern extraction date:** 2026-07-03
