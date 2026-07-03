# Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation — Research

**Researched:** 2026-07-03
**Domain:** Design-system ledger v1→v2 migration, scorecard cube schema, WCAG mechanical checkers, Playwright deterministic capture
**Confidence:** HIGH (grounded in current repo code; all claims cite specific files and line numbers)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01: Lens taxonomy — 6 frozen lenses**
Committed lens vocabulary (cube's 3rd axis): `hierarchy` · `density` · `rhythm` · `typography` · `color_contrast` · `brand_fidelity`. JSON keys are stable snake_case strings; the Elixir SSOT is `@lenses ~w(hierarchy density rhythm typography color_contrast brand_fidelity)a`. Persona-weighted: `hierarchy`, `density`. Persona-invariant (stored once at `persona: "all"`): `rhythm`, `typography`, `color_contrast`, `brand_fidelity`. 14 lens-cells per page entry. `hierarchy` = critic-only (no mechanical floor); `density`/`rhythm`/`typography`/`color_contrast` = mechanical+critic; `brand_fidelity` = mechanical-veto+critic. Critics map onto lenses (not vice-versa). Lens vocabulary frozen — adding/removing is a human-ratified guard-the-guards change.

**D-02: Cube migration & floor seeding**
Migration is versioned in-place redefinition (`version` 1 → 2), NOT parallel-additive, NOT scalar-dropping full-replace. Keep `current_score`/`ratchet_score`/`target_score` field names but redefine them as guard-recomputed `min()` rollups over a new sparse per-cell `scores` map. Add top-level `cube_axes` block. Preserve old opaque number as `legacy_score`. Cell keys = compound `persona.lens` dotted strings. Sparsity by omission — cell exists iff capture matrix declares it applicable. Seeding: every new cell born `current: null, floor: 0, status: "unrated"`. Old opaque score NEVER propagated into cell floors. Evidence-on-gain: `current > floor` requires a `File.exists?`-true `evidence_ref`. Floor bumps for judged lenses require Phase-196 sign-off in append-only `ratchet.signoffs`. Guard invariants (pure Elixir, async:true, no LLM/network): rollup integrity, per-cell monotonicity, evidence-on-gain, axis validity, floor-bump authority.

**D-03: Capture matrix (Tier A) & evidence storage**
Band 1 (floor smoke): all 11 pages × `happy` × 3 bp × 2 themes = 66 cells. Band 2 (deep): 3 lowest-scoring target pages × {empty, error, permission-denied} × 3 bp × 2 themes = 54 cells. Breakpoints: mobile 375 / tablet 768 / desktop 1280 px. 320 = cheap overflow-only assertion only. 1440 dropped. Themes: dark + light (both, non-negotiable). Evidence storage: committed `.planning/scorecards/<cell-id>.json` (mechanical metrics + a11y summary + resolved `--tl-*` tokens + meta); for deep band, `.planning/scorecards/<cell-id>.aria.yml` (via `locator.ariaSnapshot()`). Gitignore + regenerate: `examples/threadline_phoenix/e2e/artifacts/tier-a/<cell-id>/` (PNG/DOM/raw a11y binaries). Cell-id = `{ledger_id}__{theme}-{breakpoint}` e.g. `page.timeline.empty__dark-1280`. `evidence_ref` = repo-relative path. Regeneration: `mix verify.capture` → `npm run capture:tier-a`; `--update` flag = separate reviewed commit only.

**D-04: Mechanical gate policy — two modes**
MODE A (absolute hard blocker): WCAG contrast (text 4.5:1, large ≥24px/≥18.66px-bold 3:1, non-text/UI 3:1, dark + light independently) + token-grid/spacing-on-scale/radius/shadow/motion conformance against `style.ex`. Violation fails `mix ci.all`. This set == Phase-196 auto-apply whitelist. MODE B (ratchet-floor hard gate): type-size count, interactive-control count, card-nesting depth, scroll-cost/breakpoint, distinct-accent-hue. Regression below committed floor fails CI. Far ceilings: card-nesting depth >3 and distinct-accent-hue >3 are absolute MODE-B ceilings (brand-anchored, not auto-fixed). Threshold provenance: MODE A = LOCKED spec constants; MODE B = RATCHET floors in `mechanical_floors` block. Linear is the Phase-195 critic's reference bar only — NEVER a committed CI number. Named entrypoint: `mix verify.mechanical`, folded into `mix ci.all`. Reads Tier-A evidence-bundle JSON at assert time (no browser). Every violation emits located, actionable, fix-carrying message.

### Claude's Discretion
- Exact JSON field spelling within a cell (beyond the locked shape), the precise `cube_axes` metadata keys, and test-name wording — planner/executor choose, consistent with the existing `stress_ledger_test.exs` style.
- Which 3 pages are the "lowest-scoring targets" for Band 2 — derive from the current ledger scores at plan time.
- Whether the 3 legacy 1024 Tier C baselines rebaseline to 1280 or stay 1024.

### Deferred Ideas (OUT OF SCOPE)
- Full 11-page × 7-state Tier A sweep — deferred (FUT-01); Phase 197.
- 320/1440 breakpoints as full bundle cells — deferred.
- loading/pagination-boundary/advanced states in Tier A deep band — deferred to 197.
- Claude-vision critic panel, golden set, forward-only gate, first proven improvement — Phases 195-197.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LEDGER-01 | Ledger records `page × persona × lens` scorecard cube per entry (replacing single opaque score), each lens tracked independently | D-02 cell schema; v2 migration mechanics; `scores` map; `cube_axes` block |
| LEDGER-02 | `stress_ledger_test.exs` enforces per-lens monotonicity — no lens score drops below committed floor without ratchet reset + rationale | Guard extension pattern; existing monotonicity test; per-cell invariants |
| LEDGER-03 | Every score increase carries `evidence_ref` to a committed scorecard artifact; bump lacking evidence fails ratchet test | `File.exists?` pattern; `.planning/scorecards/` path; evidence-on-gain assertion |
| LEDGER-04 | `DESIGN-SYSTEM.md` projection regenerates with per-lens columns and stays freshness-tested per row | Current freshness row format; `inventory_row/1` function; lens column order (D-01) |
| LEDGER-05 | Ledger and its guards run inside `mix ci.all` deterministically — no LLM, no network | `async: true`, pure filesystem; ci.all composition |
| MECH-01 | Deterministic checkers compute per-page mechanical metrics: token-grid conformance, spacing-on-scale, type-size count, radius/shadow/motion token conformance — from source/computed styles | WCAG formula; token sets from style.ex; Playwright evaluate() pattern |
| MECH-02 | Deterministic checkers compute WCAG contrast (dark + light), interactive-control count, card-nesting depth, scroll-cost per breakpoint, distinct-accent-hue count | WCAG relative luminance formula; getComputedStyle; evaluate() patterns |
| MECH-03 | Mechanical checks act as ratchet-floor gates — violation blocks proposed change independently of LLM judgment | MODE-A/B gate mechanics; mix verify.mechanical in ci.all |
| MECH-04 | Playwright capture lane emits complete evidence bundle per cell (screenshot + rendered DOM + ARIA/a11y tree + resolved `--tl-*` tokens + meta) driven from `/audit/__stress` | locator.ariaSnapshot(); evaluate() for tokens; capture matrix spec |
| MECH-05 | Capture is tiered and documented — Tier A deterministic (all cells, CI) / Tier B LLM sample (curated subset, local) / Tier C pixel allowlist (CI) — with explicit page × state × breakpoint × theme matrix | D-03 matrix; existing Tier C allowlist pattern; npm run capture:tier-a |
</phase_requirements>

---

## Summary

Phase 194 extends the shipped design-system ledger (`.planning/design-system-ledger.json`, guarded by `test/threadline/operator_surface/stress_ledger_test.exs`) from a flat single-score-per-entry schema (version 1, ~130 entries) into a `page × persona × lens` scorecard cube (version 2), lands 9-metric deterministic mechanical checkers as the ratchet floor, and builds a tiered Playwright capture lane emitting per-cell evidence bundles from `/audit/__stress`. The entire deterministic spine runs inside `mix ci.all` with no LLM and no network.

The critical constraint is that ~80% of the substrate already exists and must be extended, not replaced. The existing `stress_ledger_test.exs` has 10 specific test blocks whose assertions must continue to pass (or be explicitly extended) after migration. The guard's `@top_level_keys`, `@entry_keys`, `@allowed_kinds`, `@design_sections`, and `@forbidden_terms` module attributes are the concrete invariants to preserve and extend. The `DESIGN-SYSTEM.md` freshness row format `"| \`#{entry["id"]}\` | #{entry["status"]} | #{entry["current_score"]} | #{entry["target_score"]} |"` must remain valid, meaning `current_score` and `target_score` must stay as top-level entry fields (they become guard-recomputed rollups rather than hand-set values).

The Playwright substrate (`operator-stress.spec.ts`, `playwright.config.ts`) already provides `reducedMotion: "reduce"`, `scale: "css"` for Tier C captures, and dynamic masking. The new Tier A capture lane needs `deviceScaleFactor: 1` in a dedicated Playwright project config, plus `locator.ariaSnapshot()` (YAML), `evaluate()` for CSS custom property resolution, and a `npm run capture:tier-a` npm script. Playwright 1.52 is installed and supports all required APIs.

**Primary recommendation:** Treat the migration as a 3-wave sequence: (W1) v2 schema + guard extension; (W2) Tier A capture lane + evidence bundles; (W3) mechanical checker module + `mix verify.mechanical` + `ci.all` wiring. This ordering ensures the guard is always ahead of the score producer.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Ledger schema v2 (cube_axes, scores, legacy_score) | Planning/Config files (.planning/) | — | Non-runtime, committed JSON artifact |
| Guard test extensions (per-cell monotonicity, evidence-on-gain) | Test Layer (ExUnit) | — | Pure Elixir, async:true, no runtime dep |
| DESIGN-SYSTEM.md projection | Documentation | Test Layer | Projection is generated, freshness verified by guard |
| Mechanical checker module (WCAG, token conformance) | Test/Dev Elixir module | — | Reads committed JSON; never calls browser at assert time |
| Playwright Tier A capture (screenshots, DOM, aria, tokens) | E2E / Node.js | `/audit/__stress` route | Browser at capture time only; output committed |
| `mix verify.mechanical` | mix alias | ci.all | Reads `.planning/scorecards/*.json`; no browser |
| `mix verify.capture` | mix alias | — | Wraps `npm run capture:tier-a`; NOT in ci.all |
| `/audit/__stress` fixture surface | Frontend Server (Phoenix LiveView) | StressFixtures module | DB-free, fail-closed in :prod |
| Scorecard JSON + aria.yml artifacts | Planning/Config files (.planning/scorecards/) | E2E spec | Committed diff-friendly artifacts |
| gitignored binaries (PNG/DOM/raw a11y) | E2E artifacts (gitignored) | — | Regenerated deterministically from capture |

---

## Area 1: Existing Ledger Schema (v1) — Full Inventory

**File:** `.planning/design-system-ledger.json` [VERIFIED: direct file read]

### Top-Level Keys (exact set enforced by guard test)

```
entries, phase, ratchet, ratchet_rule, required_inventory, screenshot_allowlist, version
```

Guard test module attribute: `@top_level_keys ~w(entries phase ratchet ratchet_rule required_inventory screenshot_allowlist version)` (stress_ledger_test.exs line 10–18). The test asserts `sorted_keys(ledger) == @top_level_keys`.

**v2 impact:** Adding `cube_axes` and `mechanical_floors` breaks this test. The guard test's `@top_level_keys` must be extended. New v2 set: `cube_axes`, `entries`, `mechanical_floors`, `phase`, `ratchet`, `ratchet_rule`, `required_inventory`, `screenshot_allowlist`, `version`.

### Entry Keys

**Required (all must be present):**
```
category, current_score, fixture_key, id, kind, notes, owner_phase, ratchet_score,
screenshot_baseline_refs, source, status, story_id, stress_path, target_score
```

**Optional:**
```
reset_rationale, reserved_for_phase
```

Guard test module attributes (stress_ledger_test.exs lines 21–37). Assertion: `sorted_keys(entry) -- allowed_keys == []` (no extra) AND `@entry_keys -- sorted_keys(entry) == []` (none missing).

**v2 impact:** Adding `scores`, `legacy_score`, `evidence_ref` to entries requires:
- Adding them to `@entry_keys` (if always required) OR `@optional_entry_keys`
- The `scores` map (per-cell) is required once cells are seeded → add to `@entry_keys`
- `legacy_score` is always present after migration → add to `@entry_keys`
- `evidence_ref` is optional (present only when `current_score > ratchet_score`) → add to `@optional_entry_keys`

### Allowed Kinds

```elixir
@allowed_kinds ~w(form_control footgun foundation future_reserved group page primitive state)
```

(stress_ledger_test.exs lines 39–48). No new kinds needed for v2.

### Entry Count and Score Distribution

Exact counts from ledger:
- `footgun`: 2 entries (current_score 25)
- `form_control`: 7 entries (current_score 35)
- `foundation`: 8 entries (current_score 62)
- `future_reserved`: 1 entry (current_score 20)
- `group`: 12 entries (current_score 62)
- `page`: 77 entries = 11 pages × 7 states (current_score 62; exceptions: `page.home.happy`=72, `page.timeline.empty`=72)
- `primitive`: 4 entries (3 at 35, 1 at 72: `primitive.surface-header.current`)
- `state`: ~22 entries (current_score 62)
- **Total: ~133 entries** [VERIFIED: direct ledger parse]

### Ratchet Block

```json
"ratchet": {
  "locked_ids": [...],       // ~130 IDs, enforces entries cannot be silently removed
  "minimum_scores": {...},   // {id: min_score}, current guard floor
  "resets": {}               // currently empty — no active resets
}
```

`ratchet_rule`: `"Scores may only stay level or increase unless an explicit reset with rationale is recorded in ratchet.resets and reset_rationale."`

**v2 addition:** `ratchet.signoffs` block for judged-lens floor bumps (Phase-196 human sign-off). The `resets` key stays.

### Screenshot Allowlist (Tier C — existing)

Currently exactly 3 entries in both `ci` and `local_review`:
```json
[
  {"baseline_ref": "stress-page-home-happy-dark-1024.png", "ledger_id": "page.home.happy", "story_id": "page.home.happy", "theme": "dark", "viewport": 1024},
  {"baseline_ref": "stress-page-timeline-empty-dark-1024.png", "ledger_id": "page.timeline.empty", "story_id": "page.timeline.empty", "theme": "dark", "viewport": 1024},
  {"baseline_ref": "stress-footgun-transaction-desktop-centering-dark-1024.png", "ledger_id": "footgun.transaction-page-left-push-desktop", "story_id": "footgun.transaction-page-left-push-desktop", "theme": "dark", "viewport": 1024}
]
```

Physical snapshot files confirmed at: `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts-snapshots/` [VERIFIED: directory listing]

Existing test asserts: `expect(ci).toHaveLength(3)` (operator-stress.spec.ts line 345). The guard test asserts `sorted_keys(allowlist) == ["ci", "local_review"]`.

**v2 impact:** Tier C allowlist stays exactly as-is for Phase 194. Planner's call on whether to rebaseline the 3 existing 1024 baselines to 1280.

### Required Inventory Block

```json
"required_inventory": {
  "folded_future_cases": [...],
  "form_controls": ["checkbox","date-range","input","radio","search","select","textarea"],
  "foundations": ["color","typography","spacing","radius","shadow","z-index","density","motion"],
  "groups": ["data-panel","detail-header","drawer-form","empty-cta","modal-destructive","offline","page-header","permission-denied","stats-chart-table","tabs-subviews","toast-update","toolbar"],
  "pages": ["actor","coverage","evidence","exports","home","redaction","retention","row-history","shell","timeline","transaction"],
  "primitives": ["icon","logo","surface-header","unsupported-view"]
}
```

Note: `required_inventory` does NOT have a test that checks against this block structurally — the guard uses `@category_allowlist` and `StressFixtures.all()` to check coverage. The `required_inventory` block is documentation-grade. This block may need a `states` key added for state categories.

---

## Area 2: Guard Test Mechanics — All 10 Test Blocks

**File:** `test/threadline/operator_surface/stress_ledger_test.exs` [VERIFIED: direct file read]

All tests run with `async: true` — pure filesystem reads, no shared state.

### Test 1: "ledger JSON has the required top-level shape" (lines 71–79)
Asserts `sorted_keys(ledger) == @top_level_keys`. Must update `@top_level_keys` for v2.

### Test 2: "ledger entries are sorted and use only the contracted keys" (lines 81–99)
- `ids == Enum.sort(ids)` — entries must be alphabetically sorted by id
- `sorted_keys(entry) -- allowed_keys == []` — no extra keys
- `@entry_keys -- sorted_keys(entry) == []` — no missing required keys
- `entry["kind"] in @allowed_kinds` — kind must be in allowlist
- **v2 impact:** Must add `scores` and `legacy_score` to `@entry_keys`, `evidence_ref` to `@optional_entry_keys`

### Test 3: "scores can only ratchet upward unless an explicit reset is recorded" (lines 101–126)
```elixir
if entry["current_score"] < entry["ratchet_score"] do
  assert id in reset_ids
  assert is_binary(entry["reset_rationale"]) and entry["reset_rationale"] != ""
else
  assert entry["current_score"] >= entry["ratchet_score"]
end
```
This is the SCALAR monotonicity. **v2 extension:** Also assert per-cell monotonicity: `cell.current >= cell.floor` unless cell key is in `ratchet.resets`. The scalar check stays for the `min()` rollup values.

### Test 4: "locked IDs and minimum scores are enforced" (lines 128–142)
- `locked_ids` entry must exist in entries
- `current_score >= minimum_scores[id]`
- **v2 extension:** Also assert `mechanical_floors` block entries are per-cell: `cell.current >= mechanical_floors[entry_id][cell_key]`

### Test 5: "fixture registry stories are present in the ledger and link back by story and fixture key" (lines 144–155)
Cross-checks with `StressFixtures.all()`. Entry must have matching `story_id` and `fixture_key`. No v2 schema change needed here.

### Test 6: "ledger-owned fixture references round-trip through StressFixtures" (lines 157–180)
`assigns_for/1` must succeed OR entry is `status: "reserved"` with `reserved_for_phase`. No v2 schema change needed here.

### Test 7: "screenshot allowlist references real ledger entries and named review dimensions" (lines 182–199)
Checks `ci` and `local_review` arrays; items need `story_id`, `theme`, `viewport`, `baseline_ref`. No v2 schema change needed.

**v2 new assertion needed:** The scorecard evidence allowlist (committed JSON artifacts in `.planning/scorecards/`) needs a corresponding test: `File.exists?(".planning/scorecards/#{cell_id}.json")` for every cell where `current > floor`. This implements LEDGER-03 evidence-on-gain.

### Test 8: "DESIGN-SYSTEM projection contains deterministic inventory sections" (lines 201–208)
```elixir
@design_sections ["Ratchet Rule","Foundations","Primitives","Form Controls","Groups","Pages","Known Footguns","Future Reserved Cases"]
```
**v2 addition:** The new `DESIGN-SYSTEM.md` needs a "Scorecard Cube" or per-lens column section. Add to `@design_sections` or add a new lens-table test.

### Test 9: "DESIGN-SYSTEM projection is fresh for every ledger row" (lines 210–219)
```elixir
defp inventory_row(entry) do
  "| `#{entry["id"]}` | #{entry["status"]} | #{entry["current_score"]} | #{entry["target_score"]} |"
end
```
**Critical v2 constraint:** `current_score` and `target_score` must remain as top-level entry fields. They become guard-recomputed `min()` rollups but the field names and locations stay. The DESIGN-SYSTEM row format stays compatible.

**v2 extension:** For the per-lens table: add a new per-row format check: `"| \`#{entry["id"]}\` | #{scores_by_lens_display} |"` or a column-per-lens table row. Since the per-persona × per-lens cell is the new representation, the DESIGN-SYSTEM must show one row per `(entry × persona)` per D-02. This is a new `inventory_row_per_persona/2` function.

### Test 10: "ledger and markdown avoid frontmatter and banned external/service copy" (lines 221–233)
```elixir
@forbidden_terms ["---", "PhoenixStorybook", "Tailwind", "Chromatic", "Percy", "Applitools", "immutable ledger"]
```
Checks both ledger source and DESIGN-SYSTEM.md. No v2 change needed. The `Lost Pixel` forbidden term from CONTEXT.md is NOT in the current test — it should be added in v2.

---

## Area 3: Token SSOT from style.ex

**File:** `lib/threadline/operator_surface/style.ex` lines 22–194 [VERIFIED: direct file read]

### Spacing Scale (9 values — MODE A conformance set)

```css
--tl-space-1: 4px
--tl-space-2: 8px
--tl-space-3: 12px
--tl-space-4: 16px
--tl-space-5: 20px
--tl-space-6: 24px
--tl-space-8: 32px
--tl-space-10: 40px
--tl-space-12: 48px
```
Note: no `--tl-space-7`, `--tl-space-9`, `--tl-space-11` — gaps in the numeric sequence are intentional.

### Font Size Scale (8 distinct sizes — MODE A conformance)

```css
--tl-font-size-xs: 12px
--tl-font-size-sm: 13px     (= --tl-font-size-dense: 13px, same value)
--tl-font-size-label: 14px
--tl-font-size-ui: 15px
--tl-font-size-body: 16px
--tl-font-size-heading: 20px
--tl-font-size-title: 24px
--tl-font-size-display: 32px
```

WCAG "large text" threshold: ≥24px normal OR ≥18.66px bold. `--tl-font-size-title` (24px) and `--tl-font-size-display` (32px) qualify as large. The checker must retrieve `font-size` AND `font-weight` computed values to classify.

### Radius Scale (6 values — MODE A conformance)

```css
--tl-radius-xs: 3px
--tl-radius-sm: 4px
--tl-radius-md: 6px
--tl-radius-lg: 8px    ← brand book "capped at 8px for most UI components"
--tl-radius-xl: 12px   ← modals/drawers/popovers only
--tl-radius-pill: 999px
```

**Brand book constraint** (brand-book.md line 342): "Rounded corners capped at 8px for most UI components." `--tl-radius-xl: 12px` is legitimate for overlays, not for cards/buttons. The MODE-A checker for radius conformance checks that any element's `border-radius` computed value is one of the 6 token values above (nearest-token matching). The MODE-B ceiling for card-nesting depth and distinct-accent-hue is separate (>3).

### Shadow Scale (4 values — MODE A conformance)

```css
--tl-shadow-border: inset 0 0 0 1px var(--tl-color-border)
--tl-shadow-subtle: 0 1px 2px rgba(2,4,10,0.50), 0 1px 3px rgba(2,4,10,0.34)
--tl-shadow-popover: 0 10px 28px rgba(2,4,10,0.55)
--tl-shadow-raised: 0 18px 48px rgba(2,4,10,0.66)
```

### Motion Tokens (MODE A conformance for transition-duration)

```css
--tl-motion-fast: 120ms
--tl-motion-base: 180ms
--tl-motion-slow: 240ms
--tl-motion-distance-sm: 8px
--tl-motion-distance-md: 16px
--tl-motion-stagger: 40ms
```

### Accent Palette (5 raw brand accent hues — MODE B distinct-accent-hue ceiling)

```css
--tl-color-thread-blue: #4F8CFF    (hue ≈ 218°)
--tl-color-stitch-blue: #4781E6   (hue ≈ 218°, close to thread-blue)
--tl-color-signal-cyan: #4EDFD1   (hue ≈ 176°)
--tl-color-iris: #8A7CFF           (hue ≈ 257°)
--tl-color-ember: #FF8A5B          (hue ≈ 18°)
```

The brand book says "5-accent 'two blues two jobs' palette." For distinct-accent-hue counting: Thread Blue and Stitch Blue are different tokens but nearly identical hues (≈218°), so they count as 1 distinct hue bucket. The 5 raw accents resolve to approximately 4 distinct hues: ~218° (blues), ~176° (cyan), ~257° (iris), ~18° (ember). However, Stitch Blue is UI-excluded from the surface layer (it's logo-only). For the SURFACE's distinct accent hues, only tokens actually applied via CSS on a given page contribute.

**MODE B far ceiling: >3 distinct accent hues on a single page is a brand violation.** This matches the brand book's 5-accent system (max 3 visible simultaneously on any operational screen).

### Breakpoint Tokens (documentation-only, not usable in @media)

```css
--tl-breakpoint-phone-proof: 375px
--tl-breakpoint-tablet: 768px
--tl-breakpoint-desktop: 1280px
```

These match D-03 Tier A breakpoints exactly. The 1280 desktop breakpoint is already in `style.ex` as `--tl-breakpoint-desktop`. [VERIFIED: style.ex lines 169–171]

### Semantic Gap Tokens (already validated by brandbook_token_parity_test.exs)

```css
--tl-gap-inline: var(--tl-space-2)    /* 8px */
--tl-gap-stack: var(--tl-space-4)     /* 16px */
--tl-gap-section: var(--tl-space-8)   /* 32px */
```

(style.ex lines 175–177). These are verified to be in `brandbook/tokens.css` and `brandbook/tokens.json` by the parity test.

---

## Area 4: Brandbook Token Parity Meta-Test Pattern

**File:** `test/threadline/brandbook_token_parity_test.exs` [VERIFIED: direct file read]

### Pattern for pinning MODE-A LOCKED thresholds

The existing test pins thresholds by asserting specific string content in source files:

```elixir
# From brandbook_token_parity_test.exs lines 110–116:
assert String.contains?(style, "#{gap}: var(#{space});"),
       "#{@style_path} must declare #{gap}: var(#{space});"
```

For MODE-A mechanical checker thresholds, reuse this EXACT pattern:
1. Define a new `@threshold_module` path (e.g., `lib/threadline/operator_surface/mechanical_checker.ex`)
2. Assert that specific strings appear in that module: `assert String.contains?(source, "@wcag_text_contrast 4.5")` or similar
3. The meta-test LOCKS these constants — they cannot drift without failing the parity test

The test is registered as `async: true` (pure file reads). Follow the same "one concern per test block, custom failure messages" house style from the existing test's module doc (lines 14–20).

**Source file structure pattern:**
```elixir
# In mechanical_checker.ex — these become pinned by meta-test
@wcag_text_contrast_ratio 4.5
@wcag_large_text_contrast_ratio 3.0
@wcag_non_text_contrast_ratio 3.0
@wcag_large_text_px 24
@wcag_large_text_bold_px 18.66
@mode_b_card_nesting_ceiling 3
@mode_b_distinct_accent_hue_ceiling 3
@spacing_scale_px [4, 8, 12, 16, 20, 24, 32, 40, 48]
@radius_scale_px [3, 4, 6, 8, 12, 999]
@motion_duration_ms [120, 180, 240]
```

The meta-test asserts each constant is present in `mechanical_checker.ex` using `String.contains?`.

---

## Area 5: Playwright Capture Substrate — Concrete API Details

**File:** `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` [VERIFIED: direct file read]
**File:** `examples/threadline_phoenix/e2e/playwright.config.ts` [VERIFIED: direct file read]
**Package version:** `@playwright/test: "^1.52.0"` (installed: Version 1.61.1) [VERIFIED: npm output]

### Existing Helpers to Reuse (operator-stress.spec.ts)

```typescript
// Returns the path for a Tier C baseline PNG:
function desktopSnapshotPath(baselineRef: string) {
  const snapshotName = baselineRef.replace(/\.png$/, "-desktop-chromium.png");
  return resolve(process.cwd(), "tests/operator-stress.spec.ts-snapshots", snapshotName);
}

// Dynamic masks for deterministic screenshots (mask time elements, dynamic testids):
function dynamicMasks(page: Page) {
  return [
    page.locator("time"),
    page.locator('[data-dynamic="true"]'),
    page.getByTestId("stress-run-id"),
  ];
}

// Screenshot output dir from env:
function stressScreenshotOutputDir() {
  const outputDir = process.env.OPERATOR_STRESS_SCREENSHOT_DIR;
  if (!outputDir) return undefined;
  return resolve(repoRoot, outputDir);
}

// Packet name convention:
function stressPacketName(storyId: string, theme: string, viewport: number) {
  const slug = storyId.replace(/[^a-z0-9]+/gi, "-");
  return `stress-${slug}-${theme}-${viewport}.png`;
}
```

### Playwright Config — Key Facts

```typescript
// Current projects:
{ name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } }
// Already 1280px wide — Tier A desktop breakpoint matches existing desktop-chromium viewport!

// Global config:
reducedMotion: "reduce",   // already set — neutralizes CSS animations for determinism
scale: "css"               // used in Tier C packet screenshot calls

// NO deviceScaleFactor set globally — must add for Tier A byte-stable captures
```

### New Playwright APIs for Tier A

**1. `locator.ariaSnapshot()` — YAML output** [VERIFIED: Playwright 1.52+ includes this API, which was introduced in 1.41]

```typescript
const snapshot = await page.locator('#tl-main').ariaSnapshot();
// Returns YAML string, e.g.:
// - heading "Timeline" [level=1]
// - link "Filter"
// - list:
//   - listitem: "No changes in this window"
```

Output is deterministic for static content. Save as `.planning/scorecards/<cell-id>.aria.yml`.

**2. `evaluate()` for resolving `--tl-*` CSS custom properties**

```typescript
const tokens = await page.evaluate(() => {
  const root = document.querySelector('.threadline-ui');
  if (!root) return {};
  const style = getComputedStyle(root);
  return {
    '--tl-space-1': style.getPropertyValue('--tl-space-1').trim(),
    '--tl-space-2': style.getPropertyValue('--tl-space-2').trim(),
    '--tl-space-3': style.getPropertyValue('--tl-space-3').trim(),
    '--tl-space-4': style.getPropertyValue('--tl-space-4').trim(),
    '--tl-space-5': style.getPropertyValue('--tl-space-5').trim(),
    '--tl-space-6': style.getPropertyValue('--tl-space-6').trim(),
    '--tl-space-8': style.getPropertyValue('--tl-space-8').trim(),
    '--tl-space-10': style.getPropertyValue('--tl-space-10').trim(),
    '--tl-space-12': style.getPropertyValue('--tl-space-12').trim(),
    '--tl-font-size-xs': style.getPropertyValue('--tl-font-size-xs').trim(),
    '--tl-font-size-sm': style.getPropertyValue('--tl-font-size-sm').trim(),
    '--tl-font-size-label': style.getPropertyValue('--tl-font-size-label').trim(),
    '--tl-font-size-ui': style.getPropertyValue('--tl-font-size-ui').trim(),
    '--tl-font-size-body': style.getPropertyValue('--tl-font-size-body').trim(),
    '--tl-font-size-heading': style.getPropertyValue('--tl-font-size-heading').trim(),
    '--tl-font-size-title': style.getPropertyValue('--tl-font-size-title').trim(),
    '--tl-font-size-display': style.getPropertyValue('--tl-font-size-display').trim(),
    '--tl-radius-xs': style.getPropertyValue('--tl-radius-xs').trim(),
    '--tl-radius-sm': style.getPropertyValue('--tl-radius-sm').trim(),
    '--tl-radius-md': style.getPropertyValue('--tl-radius-md').trim(),
    '--tl-radius-lg': style.getPropertyValue('--tl-radius-lg').trim(),
    '--tl-radius-xl': style.getPropertyValue('--tl-radius-xl').trim(),
    '--tl-motion-fast': style.getPropertyValue('--tl-motion-fast').trim(),
    '--tl-motion-base': style.getPropertyValue('--tl-motion-base').trim(),
    '--tl-motion-slow': style.getPropertyValue('--tl-motion-slow').trim(),
    // Accent colors for hue analysis:
    '--tl-color-thread-blue': style.getPropertyValue('--tl-color-thread-blue').trim(),
    '--tl-color-stitch-blue': style.getPropertyValue('--tl-color-stitch-blue').trim(),
    '--tl-color-signal-cyan': style.getPropertyValue('--tl-color-signal-cyan').trim(),
    '--tl-color-iris': style.getPropertyValue('--tl-color-iris').trim(),
    '--tl-color-ember': style.getPropertyValue('--tl-color-ember').trim(),
    // Text and background colors for WCAG:
    '--tl-color-text': style.getPropertyValue('--tl-color-text').trim(),
    '--tl-color-bg': style.getPropertyValue('--tl-color-bg').trim(),
    '--tl-color-muted': style.getPropertyValue('--tl-color-muted').trim(),
    '--tl-color-accent': style.getPropertyValue('--tl-color-accent').trim(),
  };
});
```

**3. Per-element style metrics for mechanical metrics**

```typescript
// WCAG contrast: requires foreground + background colors per element
const colorPairs = await page.evaluate(() => {
  const elements = document.querySelectorAll('p, h1, h2, h3, h4, h5, h6, a, button, label, span, td, th');
  return Array.from(elements).map(el => {
    const style = getComputedStyle(el);
    return {
      selector: el.tagName + (el.className ? '.' + el.className.split(' ')[0] : ''),
      color: style.color,
      backgroundColor: style.backgroundColor,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
    };
  });
});

// Interactive control count:
const interactiveCount = await page.evaluate(() =>
  document.querySelectorAll('button, input, select, textarea, [role="button"], [role="link"], a[href]').length
);

// Card nesting depth:
const cardNestingDepth = await page.evaluate(() => {
  const cards = document.querySelectorAll('.tl-home__card, [class*="card"], [class*="-panel"]');
  let maxDepth = 0;
  cards.forEach(card => {
    let depth = 0;
    let el = card.parentElement;
    while (el) {
      if (el.matches('.tl-home__card, [class*="card"], [class*="-panel"]')) depth++;
      el = el.parentElement;
    }
    maxDepth = Math.max(maxDepth, depth + 1);
  });
  return maxDepth;
});

// Scroll cost (page height ÷ viewport):
const scrollCost = await page.evaluate(() =>
  document.documentElement.scrollHeight / window.innerHeight
);

// Type size count (distinct computed font sizes):
const fontSizes = await page.evaluate(() => {
  const sizes = new Set<string>();
  document.querySelectorAll('*').forEach(el => {
    const size = getComputedStyle(el).fontSize;
    if (size) sizes.add(size);
  });
  return Array.from(sizes);
});
```

**4. New Playwright project config for Tier A (add to playwright.config.ts)**

```typescript
{
  name: "tier-a-capture",
  testMatch: /operator-tier-a-capture\.spec\.ts/,
  use: {
    ...devices["Desktop Chrome"],
    viewport: { width: 1280, height: 900 },
    deviceScaleFactor: 1,    // NEW: byte-stable pixel output
    reducedMotion: "reduce", // already in global config
    colorScheme: "dark" as const,
  },
}
// Second project for light theme:
{
  name: "tier-a-capture-light",
  testMatch: /operator-tier-a-capture\.spec\.ts/,
  use: {
    ...devices["Desktop Chrome"],
    viewport: { width: 1280, height: 900 },
    deviceScaleFactor: 1,
    reducedMotion: "reduce",
    colorScheme: "light" as const,
  },
}
```

**Note on 375/768 breakpoints:** The Tier A spec uses `page.setViewportSize({ width: 375, height: 900 })` etc. within the test, not separate projects per breakpoint.

### StressFixtures Viewport Mismatch — Integration Risk

`StressFixtures.viewports()` returns `[320, 375, 768, 1024, 1440]` (stress_fixtures.ex line 25).
The new Tier A breakpoints (D-03) are 375 / 768 / 1280. The value `1280` is NOT in `@viewports`.

**Required change:** Add `1280` to `@viewports` in `stress_fixtures.ex`. This affects the `@viewport_allowlist` in `stress_live.ex` (line 14: `StressFixtures.viewports() |> Enum.map(&Integer.to_string/1)`). The `1024` entry can stay for backward compatibility with the 3 existing Tier C baselines.

### Existing Tier C Baseline Snapshot Files

The 3 existing baselines use `viewport: 1024`:
- `stress-page-home-happy-dark-1024-desktop-chromium.png`
- `stress-page-timeline-empty-dark-1024-desktop-chromium.png`
- `stress-footgun-transaction-desktop-centering-dark-1024-desktop-chromium.png`

**Planner's call (Claude's Discretion):** Rebaseline to 1280 (one-time update to snapshot files) OR keep 1024 for these 3. The `desktop-chromium` project already uses 1280×900, so the existing Tier C tests currently run against 1280px (`test.beforeEach` calls `page.setViewportSize({ width: 1024, height: 900 })` within the test, overriding the project viewport). These 3 baselines explicitly set 1024 inside the test — they will keep working at 1024 regardless of the project viewport.

---

## Area 6: WCAG Contrast + Mechanical Metric Algorithms

All computations run in Elixir from captured JSON. No browser at assert time. [ASSUMED where no official spec URL was directly cited — these are the WCAG 2.1 standard formulas]

### WCAG 2.x Relative Luminance

```
For each RGB channel C_8bit in [0..255]:
  C_srgb = C_8bit / 255

  if C_srgb <= 0.04045:
    C_lin = C_srgb / 12.92
  else:
    C_lin = ((C_srgb + 0.055) / 1.055) ^ 2.4

L = 0.2126 × R_lin + 0.7152 × G_lin + 0.0722 × B_lin
```

### WCAG Contrast Ratio

```
ratio = (L_lighter + 0.05) / (L_darker + 0.05)
where L_lighter >= L_darker
```

### MODE-A Hard Thresholds

| Check | Threshold | Condition |
|-------|-----------|-----------|
| Normal text contrast | 4.5:1 | font-size < 24px AND (not bold OR bold < 18.66px) |
| Large text contrast | 3.0:1 | font-size >= 24px OR (bold AND font-size >= 18.66px) |
| Non-text UI elements | 3.0:1 | buttons, inputs, icons, graphical elements |
| Spacing on scale | exact match | spacing values must be in [4,8,12,16,20,24,32,40,48] px |
| Radius on scale | exact match | border-radius must be in [3,4,6,8,12,999] px |
| Shadow on scale | pattern match | box-shadow must match one of 4 token patterns |
| Motion duration | exact match | transition-duration must be in [120,180,240] ms |
| Font size on scale | exact match | font-size must be in [12,13,14,15,16,20,24,32] px |

### MODE-B Ratchet-Floor Metrics

| Metric | How to compute | Far ceiling |
|--------|----------------|-------------|
| Type-size count | Count distinct computed `font-size` values (px) | None (MODE B ratchet only) |
| Interactive-control count | Count `button, input, select, textarea, [role="button"], [role="link"], a[href]` | None |
| Card-nesting depth | Walk DOM: max ancestor count where ancestor matches card/panel selectors | >3 is a hard MODE-B ceiling |
| Scroll-cost (per breakpoint) | `document.documentElement.scrollHeight / window.innerHeight` at each of 375/768/1280 | None (ratchet only) |
| Distinct-accent-hue count | Extract hue from colors applied to non-background elements; bucket by ±15° window; count buckets for Thread Blue, Signal Cyan, Iris, Ember families | >3 is a hard MODE-B ceiling |

### Color-Space Subtleties

1. **Parsed color format from `getComputedStyle`:** Always returns `rgb(R, G, B)` or `rgba(R, G, B, A)` — never hex. Parse these strings directly.
2. **Alpha channels:** Elements with `rgba(...)` where A < 0.1 should be skipped (fully transparent). For partially transparent text (0.1 <= A < 1.0), composite against the background before computing luminance.
3. **CSS var() in source:** The Playwright `getComputedStyle` resolves all custom properties, so the checker always receives resolved `rgb(...)` values.
4. **Hue bucketing for distinct-accent-hue:** Convert RGB to HSL. Group hues by ±15° window. Only count hues from chromatic colors (saturation > 20% to exclude grays).

---

## Area 7: mix.exs Wiring

**File:** `mix.exs` [VERIFIED: direct file read]

### Current `ci.all` Chain (lines 102–114)

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
  "verify.example_browser"   # Browser e2e last (slowest)
]
```

### New Aliases Required

```elixir
# Add to aliases/0:
"verify.mechanical": &verify_mechanical/1,
"verify.capture": &verify_capture/1,
```

**`verify.mechanical` behavior:**
- Pure Elixir test call: `["test test/threadline/operator_surface/mechanical_checker_test.exs"]`
- OR a custom function that calls the mechanical checker module directly
- Reads `.planning/scorecards/*.json` — no browser
- Must run in `:test` env (add to `preferred_envs` in `cli/0`)
- Must be added to `ci.all` BEFORE `verify.example_browser`

**`verify.capture` behavior:**
- Similar to `verify_example_browser/1` but runs `npm run capture:tier-a`
- NOT added to `ci.all` — local-only regeneration
- Must add to `preferred_envs` as `:test` or `:dev`

### Updated `ci.all` (after Phase 194)

```elixir
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.compile_no_optional",
  "verify.test",           # includes stress_ledger_test.exs (guard tests)
  "verify.threadline",
  "verify.example",
  "verify.doc_contract",
  "verify.mechanical",     # NEW: reads committed scorecard JSON, no browser
  "verify.example_browser" # Browser e2e last
]
```

### `cli/0` preferred_envs addition

```elixir
"verify.mechanical": :test,
"verify.capture": :test,
```

---

## Area 8: "Lowest-Scoring Target Pages" — Concrete Recommendation

**Context:** All 77 page entries have uniform `current_score = 62` EXCEPT:
- `page.home.happy`: 72 (Phase 171 baseline)
- `page.timeline.empty`: 72 (Phase 171 baseline)

Since scores do not differentiate pages beyond this, the planner must use design-debt signals. [VERIFIED: full ledger scan]

**Signal 1 — Explicit footguns:**
- `footgun.transaction-page-left-push-desktop` (score 25): Transaction page has known layout centering issue
- `footgun.coverage-schema-card-declutter` (score 25): Coverage page has known nested-card issue

**Signal 2 — Home/Timeline are HIGHER-scored pages** (happy state at 72), so they are NOT the lowest-scoring targets.

**Recommendation for Band 2 (3 pages):**
1. **`transaction`** — explicit footgun (centering/layout), complex data display
2. **`coverage`** — explicit footgun (nested cards), complex coverage schema
3. **`retention`** — complex destructive action flows, permission warnings, important for audit correctness narrative; no explicit footgun but structurally the most complex of the remaining pages

Planner may substitute `row-history` or `exports` for #3 based on visual inspection at plan time. The key criterion: pick pages where mechanical checkers are most likely to surface concrete violations.

---

## Area 9: Determinism + Gitignore Mechanics

### What to Commit (Diffable)

```
.planning/scorecards/
  page.home.happy__dark-375.json         # Band 1
  page.home.happy__dark-768.json         # Band 1
  page.home.happy__dark-1280.json        # Band 1
  page.home.happy__light-375.json        # Band 1
  ...
  page.transaction.empty__dark-375.json  # Band 2
  page.transaction.empty__dark-768.json  # Band 2
  ...
  page.timeline.empty__dark-1280.aria.yml   # Band 2 deep band only
  page.transaction.empty__dark-1280.aria.yml
  page.coverage.empty__dark-1280.aria.yml
  ...
```

Cell-id format: `{ledger_id}__{theme}-{breakpoint}` — the same convention as `stressPacketName()` in the existing spec (kebab-slug instead of dots) [per D-03].

### What to Gitignore + Regenerate

```
examples/threadline_phoenix/e2e/artifacts/
  tier-a/
    page.home.happy__dark-375/
      screenshot.png
      dom.html
      a11y.json
    ...
```

Add to `.gitignore` (root level):
```
/examples/threadline_phoenix/e2e/artifacts/tier-a/
```

Add to `examples/threadline_phoenix/e2e/.gitignore`:
```
artifacts/tier-a/
```

### Determinism Guarantees

The full determinism stack:
1. `reducedMotion: "reduce"` — neutralizes CSS transitions (already in config)
2. `deviceScaleFactor: 1` — stabilizes pixel output (must add)
3. `scale: "css"` — existing pattern from Tier C, reuse for Tier A PNG
4. `dynamicMasks` — masks `time`, `[data-dynamic="true"]`, `stress-run-id` (existing helper)
5. DB-free fixtures via `StressFixtures` — no database calls, no dynamic server state
6. `@reducedMotion: "reduce"` — `/audit/__stress` raises in :prod, static fixture surface

---

## Architecture Patterns

### Evidence Bundle Schema (per cell)

`.planning/scorecards/<cell-id>.json`:

```json
{
  "cell_id": "page.home.happy__dark-1280",
  "ledger_id": "page.home.happy",
  "theme": "dark",
  "breakpoint": 1280,
  "captured_at": "2026-07-03T...",
  "playwright_version": "1.61.1",
  "tokens": {
    "--tl-space-1": "4px",
    "--tl-space-2": "8px",
    ...
  },
  "metrics": {
    "mode_a": {
      "spacing_violations": [],
      "radius_violations": [],
      "shadow_violations": [],
      "motion_violations": [],
      "font_size_violations": [],
      "wcag_violations": []
    },
    "mode_b": {
      "type_size_count": 5,
      "interactive_control_count": 12,
      "card_nesting_depth": 2,
      "scroll_cost": 1.4,
      "distinct_accent_hue_count": 2
    }
  },
  "a11y_summary": {
    "headings": 3,
    "landmarks": 4,
    "interactive_elements": 12
  },
  "artifacts": {
    "screenshot": "examples/threadline_phoenix/e2e/artifacts/tier-a/page.home.happy__dark-1280/screenshot.png",
    "dom": "examples/threadline_phoenix/e2e/artifacts/tier-a/page.home.happy__dark-1280/dom.html",
    "aria": ".planning/scorecards/page.home.happy__dark-1280.aria.yml"
  }
}
```

### Ledger v2 Entry Schema

```json
{
  "id": "page.home.happy",
  "current_score": 62,           // guard-recomputed min() rollup
  "ratchet_score": 62,           // historic watermark
  "target_score": 90,
  "legacy_score": 72,            // old opaque pre-cube score
  "scores": {
    "P1.hierarchy": {"current": null, "floor": 0, "status": "unrated"},
    "P1.density":   {"current": null, "floor": 0, "status": "unrated"},
    "P3.hierarchy": {"current": null, "floor": 0, "status": "unrated"},
    "P3.density":   {"current": null, "floor": 0, "status": "unrated"},
    "all.rhythm":          {"current": null, "floor": 0, "status": "unrated"},
    "all.typography":      {"current": null, "floor": 0, "status": "unrated"},
    "all.color_contrast":  {"current": null, "floor": 0, "status": "unrated"},
    "all.brand_fidelity":  {"current": null, "floor": 0, "status": "unrated"},
    "P2.hierarchy": {"current": null, "floor": 0, "status": "unrated"},
    "P2.density":   {"current": null, "floor": 0, "status": "unrated"},
    "P4.hierarchy": {"current": null, "floor": 0, "status": "unrated"},
    "P4.density":   {"current": null, "floor": 0, "status": "unrated"},
    "P5.hierarchy": {"current": null, "floor": 0, "status": "unrated"},
    "P5.density":   {"current": null, "floor": 0, "status": "unrated"}
  },
  "evidence_ref": null,          // null when unrated; set when current > floor
  "category": "page",
  "fixture_key": "page.home.happy",
  "kind": "page",
  "notes": "...",
  "owner_phase": 171,
  "ratchet_score": 62,
  "screenshot_baseline_refs": ["stress-page-home-happy-dark-1024.png"],
  "source": "Threadline.OperatorSurface.StressFixtures",
  "status": "baseline",
  "story_id": "page.home.happy",
  "stress_path": "/audit/__stress?story=page.home.happy",
  "target_score": 90
}
```

**Note on `scores` key structure:** The cell key format `"P1.hierarchy"` follows the `persona.lens` dotted grammar per D-01/D-02. Persona-invariant lenses use `"all"` as the persona prefix. The exact persona slugs (P1..P5) should match the `cube_axes` block definition.

### Ledger v2 Top-Level Additions

```json
{
  "version": 2,
  "cube_axes": {
    "personas": [
      {"slug": "P1", "label": "Change actor-first", "lens_weights": ["hierarchy", "density"]},
      {"slug": "P2", "label": "Plain / low-density", "lens_weights": ["hierarchy", "density"]},
      {"slug": "P3", "label": "Verdict-first", "lens_weights": ["hierarchy", "density"]},
      {"slug": "P4", "label": "...", "lens_weights": ["hierarchy", "density"]},
      {"slug": "P5", "label": "...", "lens_weights": ["hierarchy", "density"]}
    ],
    "lenses": [
      {"slug": "hierarchy",       "method": "critic-only",         "kind": "judged",     "authority": "signoff"},
      {"slug": "density",         "method": "mechanical+critic",   "kind": "hybrid",     "authority": "auto+signoff"},
      {"slug": "rhythm",          "method": "mechanical+critic",   "kind": "hybrid",     "authority": "auto+signoff"},
      {"slug": "typography",      "method": "mechanical+critic",   "kind": "hybrid",     "authority": "auto+signoff"},
      {"slug": "color_contrast",  "method": "mechanical+critic",   "kind": "hybrid",     "authority": "auto+signoff"},
      {"slug": "brand_fidelity",  "method": "mechanical-veto+critic", "kind": "veto",   "authority": "auto"}
    ]
  },
  "mechanical_floors": {
    "page.home.happy": {
      "all.color_contrast":  {"dark_375": 0, "dark_768": 0, "dark_1280": 0, "light_375": 0, "light_768": 0, "light_1280": 0},
      "all.rhythm":          {"dark_375": 0, "dark_768": 0, "dark_1280": 0, "light_375": 0, "light_768": 0, "light_1280": 0}
    }
  },
  "ratchet": {
    "locked_ids": [...],
    "minimum_scores": {...},
    "resets": {},
    "signoffs": []
  }
}
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WCAG contrast formula | Custom color math | Standard sRGB piecewise linearization formula (verbatim above) | Edge cases: gamma correction exponent is 2.4 (not 2.2), the breakpoint is 0.04045 not 0.03928 |
| CSS custom property resolution | Regex on style.ex source | `page.evaluate(() => getComputedStyle(el).getPropertyValue('--tl-*'))` | Only resolved computed values are correct; source may have `var()` aliases |
| Byte-stable pixel captures | Custom screenshot code | `deviceScaleFactor: 1` + `reducedMotion: "reduce"` + `scale: "css"` + masks | Precisely the determinism stack already proving out in Tier C |
| aria snapshot format | Custom DOM walker | `locator.ariaSnapshot()` | Returns standardized YAML; deterministic for static content; built-in Playwright 1.41+ |
| JSON schema validation for v2 | Custom parser | ExUnit pattern assertions (same as existing guard) | Already proven approach; no extra dep needed |
| Dist-accent-hue computation | Reinventing HSL conversion | Standard RGB→HSL formula: H = atan2(sqrt(3)*(G-B), 2R-G-B), normalized to 0-360 | Edge: achromatic colors (R=G=B) have undefined hue — skip them |

**Key insight:** The mechanical checker runs in Elixir reading JSON. Do not call the browser at assert time. The Playwright capture and the Elixir assertion are separated by the committed JSON artifact — this is the determinism guarantee.

---

## Common Pitfalls

### Pitfall 1: Breaking the guard test's top-level-keys assertion
**What goes wrong:** Adding `cube_axes`, `mechanical_floors`, or `ratchet.signoffs` to the ledger JSON without updating `@top_level_keys` in the guard test causes `mix test` to fail immediately.
**Why it happens:** The test does `assert sorted_keys(ledger) == @top_level_keys` — exact match.
**How to avoid:** Update `@top_level_keys` in the test atomically with adding keys to the ledger. Migration script and guard update must be in the same commit.
**Warning signs:** `"#{@ledger_path} top-level keys drifted: ..."` failure message.

### Pitfall 2: The DESIGN-SYSTEM freshness row format requires current_score/target_score on entries
**What goes wrong:** If v2 migration removes `current_score` or `target_score` from the entry top-level, the `inventory_row/1` function breaks the freshness test for all 133 entries.
**Why it happens:** D-02 redefines these as `min()` rollups but keeps the field names. Forgetting to keep them as top-level fields — even as computed rollups — breaks 133 freshness assertions.
**How to avoid:** The `current_score` field must always be set on every entry as the computed `min()` over its cells. A null cell counts as 0 for this computation.
**Warning signs:** Mass test failures with `"DESIGN-SYSTEM.md is stale for page.*.* ; missing row ..."`.

### Pitfall 3: StressFixtures.viewports() missing 1280
**What goes wrong:** The new Tier A capture uses `viewport: 1280`, but `StressFixtures.viewports()` returns `[320, 375, 768, 1024, 1440]` — 1280 is absent. The `@viewport_allowlist` in `stress_live.ex` will reject `?viewport=1280` as an invalid param.
**Why it happens:** 1280 was added to `style.ex` as `--tl-breakpoint-desktop` but never to `StressFixtures.viewports()`.
**How to avoid:** Add `1280` to `@viewports` in `stress_fixtures.ex` as part of the capture lane setup.
**Warning signs:** StressLive renders default viewport (1024) when `?viewport=1280` is passed; capture screenshots show 1024px layout instead of 1280px.

### Pitfall 4: WCAG formula uses wrong gamma exponent
**What goes wrong:** Using `^2.2` instead of `^2.4` in the sRGB linearization gives systematically wrong luminance values for mid-tone colors, causing false-pass or false-fail WCAG assertions.
**Why it happens:** Common confusion between sRGB standard (2.4 with a linear low-end segment) and simplified gamma.
**How to avoid:** Use the piecewise formula exactly as specified above: linear for `C_srgb <= 0.04045`, otherwise `((C + 0.055) / 1.055) ^ 2.4`.
**Warning signs:** Blue `#4F8CFF` on `#0B1020` should fail 4.5:1 for normal text but pass 3:1 for non-text. If your checker says otherwise, the gamma is wrong.

### Pitfall 5: deviceScaleFactor not set → non-byte-stable PNG captures
**What goes wrong:** Tier A screenshots captured on different machines (with different DPR) produce different PNG files despite identical HTML, breaking the "deterministic regeneration" contract.
**Why it happens:** When `deviceScaleFactor` is not set, Playwright inherits the OS DPI — 1x on standard displays, 2x on Retina/HiDPI. Different CI environments have different DPR.
**How to avoid:** Always set `deviceScaleFactor: 1` explicitly in the Tier A Playwright project config.
**Warning signs:** Scorecard JSON regenerated on CI doesn't match the locally-generated JSON (pixel coordinates differ).

### Pitfall 6: ariaSnapshot() output differs between story states
**What goes wrong:** The aria.yml committed for `page.timeline.empty__dark-1280` includes dynamic text (like timestamps or run IDs) that changes on re-capture, breaking the "committed = deterministic" contract.
**Why it happens:** `locator.ariaSnapshot()` captures ALL accessible text, including dynamic content not covered by `dynamicMasks` (which only applies to screenshot masking, not aria snapshot).
**How to avoid:** Either (a) call `ariaSnapshot()` on a subtree that excludes dynamic data (`page.locator('#tl-main')` rather than `page.locator('body')`), or (b) post-process the YAML to redact known-dynamic selectors before committing.
**Warning signs:** `git diff` shows aria.yml changing on every capture run despite no UI changes.

### Pitfall 7: evidence_ref must use File.exists?-true path
**What goes wrong:** The `evidence_ref` field in an entry points to `.planning/scorecards/page.home.happy__dark-1280.json` using an absolute path or incorrect relative path. `File.exists?` returns false, failing the evidence-on-gain assertion.
**Why it happens:** Path resolution from the project root vs from the test file location.
**How to avoid:** Use repo-relative paths: `".planning/scorecards/<cell-id>.json"`. The existing guard test already uses `@ledger_path ".planning/design-system-ledger.json"` as a relative path — follow the same pattern.
**Warning signs:** `"#{id} has a score increase but evidence_ref path does not exist: ..."`.

---

## Standard Stack

No new packages needed for this phase.

**Existing stack in use:**
- Elixir / ExUnit (`async: true` guard tests) — already in project
- `Jason` (JSON decode for ledger) — already in deps
- `@playwright/test ^1.52.0` (installed: 1.61.1) — already in e2e devDependencies
- `Node.js v22.14.0` — already available [VERIFIED: environment check]

The Elixir mechanical checker module is pure computation (parsing JSON, arithmetic) with no new deps.

---

## Package Legitimacy Audit

No new packages are introduced in Phase 194. All functionality is implemented in pure Elixir (mechanical checker) and with the existing Playwright installation. This section is not applicable.

---

## mix.exs ci.all — Key Integration Detail

The `ci.all` alias runs `verify.example_browser` last (slowest, needs Node + Playwright). The new `verify.mechanical` is pure Elixir and must run BEFORE `verify.example_browser` so failures are caught faster. The `verify.capture` is explicitly NOT in `ci.all` — it is a local-only regeneration command.

The `preferred_envs` in `cli/0` needs these additions:
```elixir
"verify.mechanical": :test,
"verify.capture": :test,
```

The `verify.mechanical` implementation can be either:
- A delegating test file: `"test test/threadline/operator_surface/mechanical_checker_test.exs"`
- Or a direct Mix task invocation if a `Threadline.MechanicalChecker` task is registered

Following the existing pattern in `verify.operator_stress` → `verify_example_browser(["operator-stress.spec.ts" | args])`, the simplest implementation is a named test file.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + `@playwright/test` 1.61.1 (Node) |
| Config file | `test/test_helper.exs` (Elixir) + `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick run command | `mix test test/threadline/operator_surface/stress_ledger_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LEDGER-01 | v2 schema has `cube_axes`, `scores` map, `legacy_score` per entry | unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ (extend existing) |
| LEDGER-02 | Per-cell monotonicity guard fails on score drop without reset | unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ (extend existing) |
| LEDGER-03 | evidence_ref File.exists? check fails bump without artifact | unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ (extend existing) |
| LEDGER-04 | DESIGN-SYSTEM.md has per-lens columns + freshness rows | unit | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ (extend existing) |
| LEDGER-05 | Guard runs in ci.all with async:true, no LLM/network | integration | `mix ci.all` | ✅ |
| MECH-01 | Token-grid/spacing/radius/font-size conformance checkers compute correctly | unit | `mix verify.mechanical` | ❌ Wave 0 |
| MECH-02 | WCAG contrast + MODE-B metrics compute correctly | unit | `mix verify.mechanical` | ❌ Wave 0 |
| MECH-03 | Violation in committed scorecard JSON fails verify.mechanical | integration | `mix verify.mechanical` | ❌ Wave 0 |
| MECH-04 | Playwright capture emits complete bundle per cell | e2e | `mix verify.capture` | ❌ Wave 0 |
| MECH-05 | Tier A matrix is documented; Tier C allowlist stays bounded at 3 | contract | `mix test test/threadline/operator_surface/stress_ledger_test.exs` | ✅ (partial) |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/operator_surface/stress_ledger_test.exs`
- **Per wave merge:** `mix ci.all` (includes verify.mechanical after Wave 2)
- **Phase gate:** Full `mix ci.all` green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/mechanical_checker_test.exs` — covers MECH-01, MECH-02, MECH-03
- [ ] `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts` — covers MECH-04
- [ ] `lib/threadline/operator_surface/mechanical_checker.ex` — the checker module itself
- [ ] `.planning/scorecards/` directory (first JSON artifacts from capture)
- [ ] `examples/threadline_phoenix/e2e/artifacts/tier-a/` in `.gitignore`

---

## Security Domain

Phase 194 is dev/test tooling only. No user-facing endpoints, no new authentication, no data handling changes. The `/audit/__stress` route already enforces authentication (raises in :prod, requires login in dev/test) — no changes needed.

ASVS V5 (Input Validation): The ledger JSON is read from `.planning/` (trusted repository artifact). No user-controlled input enters the checker pipeline. The `allow/2` function in `stress_live.ex` already validates `story`, `theme`, `viewport`, `category` params against allowlists.

`security_enforcement` is not explicitly set to `false` in `.planning/config.json`, but this phase introduces no attack surface.

---

## Open Questions

1. **Persona slug canonical names (P1–P5 labels)**
   - What we know: D-01 describes P1 (change/actor-first), P2 (plain/low-density), P3 (verdict-first); P4 and P5 are not fully named in CONTEXT.md
   - What's unclear: P4 and P5 persona labels for the `cube_axes` block
   - Recommendation: Check `.planning/research/SUMMARY.md` and `prompts/audit-lib-domain-model-reference.md` for P4/P5 definitions. If not found, use placeholder slugs `P4` and `P5` and fill in labels later (Phase 195 rubrics define these).

2. **Card-nesting depth selector strategy**
   - What we know: brand book says "use cards for individual repeated items, not page sections inside cards"; ceiling is >3
   - What's unclear: exact CSS class selectors that constitute a "card" in the Threadline component system
   - Recommendation: Use `.tl-home__card`, `.tl-home__earned-panel`, `[class*="-panel"]`, `[class*="-card"]` as the card detection set. Confirm via grep in `lib/threadline/operator_surface/style.ex`.

3. **`evidence_ref` schema for multi-breakpoint evidence**
   - What we know: `evidence_ref` is a single field on the entry; but evidence exists per-cell (6 theme×breakpoint combos for Band 1)
   - What's unclear: Does `evidence_ref` point to the per-cell JSON, or a directory, or is it a map?
   - Recommendation: Make `evidence_ref` a flat map of `{cell_id: path}` at the entry level, OR a per-cell field within the `scores` map. The D-02 text says "a present, `File.exists?`-true `evidence_ref`" — it can be an array or map of cell-keyed paths.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Playwright capture, npm scripts | ✓ | v22.14.0 | — |
| npm | Playwright package management | ✓ | v11.1.0 | — |
| Playwright | Tier A capture lane | ✓ | 1.61.1 | — |
| Elixir / Mix | All Elixir work | ✓ | 1.19.5 (OTP 28) | — |
| PostgreSQL | Example app (for login flow in capture) | Unknown | — | Use pre-seeded dev DB |
| Phoenix example app | `/audit/__stress` route for capture | Unknown | — | `mix verify.example` starts it |

**Missing dependencies with no fallback:** None confirmed.
**Note:** The Playwright capture requires the Phoenix example app to be running. The existing `verify_example_browser/1` function in mix.exs handles starting the app. The new `verify_capture` function should follow the same pattern.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `locator.ariaSnapshot()` is available and returns deterministic YAML for static content in Playwright 1.52+ | Area 5 | If API differs, use `page.accessibility.snapshot()` as fallback (older API, different format) |
| A2 | `getComputedStyle` from `page.evaluate()` resolves CSS custom properties in all Chromium versions used by Playwright 1.52+ | Area 5 | If not, must use inline style fallback or a Playwright-native CSS property resolution API |
| A3 | Distinct-accent-hue hue bucketing at ±15° window is sufficient to distinguish the 5 Threadline accent families | Area 6 | Thread Blue (218°) and Stitch Blue (218°) are intentionally nearly identical and should be 1 bucket; if bucketing is too narrow they split incorrectly |
| A4 | The card nesting depth selector `.tl-home__card, [class*="-panel"]` captures all card-like elements in the Threadline system | Area 6 | If missed, card nesting depth is undercounted; remedy by grepping style.ex for card patterns |
| A5 | P4 and P5 persona slugs from D-01 are not yet canonically defined in committed planning documents | Open Questions | If defined in SUMMARY.md, use those names in cube_axes |

**If this table were empty:** All claims were verified or cited — no user confirmation needed.

---

## Sources

### Primary (HIGH confidence)
- `.planning/design-system-ledger.json` — full ledger schema, entry counts, score values, ratchet block
- `test/threadline/operator_surface/stress_ledger_test.exs` — all 10 guard tests with exact line numbers
- `lib/threadline/operator_surface/style.ex` — complete `--tl-*` token SSOT (lines 22–194)
- `test/threadline/brandbook_token_parity_test.exs` — meta-test pattern for threshold pinning
- `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` — Playwright helper functions and capture pattern
- `examples/threadline_phoenix/e2e/playwright.config.ts` — project config, reducedMotion, viewport
- `lib/threadline/operator_surface/stress_fixtures.ex` — StressFixtures module, viewports, themes, stories
- `lib/threadline/operator_surface/live/stress_live.ex` — /audit/__stress LiveView, viewport allowlist
- `brandbook/brand-book.md` — radius ≤8px cap, card constraint, 5-accent palette, logo floor
- `mix.exs` — ci.all composition, existing verify.* aliases
- `.planning/config.json` — nyquist_validation: true confirmed
- `DESIGN-SYSTEM.md` — current freshness row format and sections

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — LEDGER-01..05, MECH-01..05 verbatim requirements
- `.planning/ROADMAP.md` — Phase 194 success criteria
- `.planning/phases/194-deterministic-scorecard-cube-ledger-mechanical-capture-found/194-CONTEXT.md` — locked decisions D-01..D-04

### Tertiary (LOW confidence)
- WCAG 2.1 relative luminance and contrast ratio formulas — standard formulas from training knowledge [ASSUMED: exact per W3C WCAG 2.1 §1.4.3]
- `locator.ariaSnapshot()` API behavior — known Playwright 1.41+ feature [ASSUMED from version number]

---

## Metadata

**Confidence breakdown:**
- Ledger schema + guard mechanics: HIGH — read directly from source files
- Token SSOT: HIGH — read directly from style.ex
- Playwright APIs: HIGH for existing patterns; MEDIUM for ariaSnapshot behavior details
- WCAG formula: MEDIUM — standard well-known formula but not verified against W3C spec URL this session
- Score ranking for "3 lowest pages": MEDIUM — ledger scores don't differentiate; derived from footgun signals

**Research date:** 2026-07-03
**Valid until:** 2026-08-03 (stable codebase; low churn expected in OSS-DNA conventions)
