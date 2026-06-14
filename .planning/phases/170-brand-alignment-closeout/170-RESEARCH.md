# Phase 170: brand-alignment-closeout - Research

**Researched:** 2026-06-14
**Domain:** Brand token parity, doc-contract testing, milestone audit authoring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**A — Token parity: definition + enforcement (BRAND-01)**
- D-01: "Full parity" = curated-subset parity. For every token the brandbook claims to mirror, name + value must equal the shipped lane exactly, in both dark and light blocks.
- D-02: Runtime-only structural tokens are explicitly out of brand scope and must be documented as such.
- D-03: Enforce with an automated parity test — `test/threadline/brandbook_token_parity_test.exs`. Asserts value-equality on the intersection; asserts the documented exclusion list so drift is caught in both directions.

**B — UI theming posture note: placement + framing (BRAND-01)**
- D-04: Add a short "UI theming posture" subsection inside `brandbook/brand-book.md`, near lines 217–287 (Dark/light strategy + Color sections).
- D-05: Content states: dark-primary; light is fully shipped and supported via host config (`theme: :system | :light | :dark`); per-operator runtime toggle deferred to real adopter demand (THEME-TOGGLE-01; localStorage remains rejected).
- D-06: Pin the keystone sentence with a doc-contract literal assertion (extend an existing brand/doc-contract test or add to the parity test file).

**C — pressure-test dual-mode addendum: form (BRAND-02)**
- D-07: Do NOT add a dimension #16. Augment existing dimension #11 "Token rigor" with a dual-mode pass condition, cross-referencing #5 "Dark/light versatility."
- D-08: Plus one mechanical-suite assertion (shell-runnable) that runs the same parity check — so the brand pressure-test is tied to actual UI token truth.

**D — Milestone audit prep: scope**
- D-09: Phase 170 authors `.planning/milestones/v1.36-MILESTONE-AUDIT.md` following the v1.33/v1.35 template.
- D-10: Update `.planning/REQUIREMENTS.md` traceability table to mark all 15 v1.36 requirements verified against their closing phases.
- D-11: Closeout readiness marked PENDING the End-of-milestone UAT human gate.

### Claude's Discretion
- Exact token name reconciliation (final in-scope vs. excluded lists) — derive from code.
- Parser implementation details for the parity test.
- Whether the posture-note literal lock lives in a new test file or extends an existing brand doc-contract test.

### Deferred Ideas (OUT OF SCOPE)
- THEME-TOGGLE-01 — per-operator runtime switching.
- Milestone archival + version bump — belongs to `/gsd-complete-milestone` after UAT.
- SOCIAL-PNG-01 / HEXDOCS-BRAND-01 / LANDING-01 — out of v1.36 scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRAND-01 | `brandbook/tokens.json`/`tokens.css` reach full parity with the shipped 45-token UI lane; brand book gains the settled-truth "UI theming posture" note | Token reconciliation table below; parity test mechanics; doc-contract pattern |
| BRAND-02 | `pressure-test.md` gains a dual-mode addendum verifying brand assets and UI tokens stay consistent across both lanes | Existing mechanical suite format documented; dim #11 + #5 augmentation approach |
</phase_requirements>

---

## Summary

Phase 170 is a docs/closeout + alignment phase with zero new runtime capabilities. Its keystone artifact is an automated Elixir parity test (`test/threadline/brandbook_token_parity_test.exs`) that enforces value-equality between the curated brandbook token set and the shipped runtime lane (`style.ex`). This is "correct by default" applied to brand governance.

The research reveals that the current brandbook and style.ex are substantially aligned but have four concrete discrepancies the phase must fix before the parity test can pass: two token name mismatches (`text-muted`/`muted`, `text-soft`/`muted-soft`), one name mismatch where the brandbook says `error-text` but style.ex says `danger`, and two value mismatches on `warning-text` (dark: brandbook `#FFD166` vs style.ex `#F6C86B`; light: brandbook `#7A5400` vs style.ex `#8A5512`). Style.ex wins on all conflicts — brandbook must be corrected.

The curated parity intersection is **18 tokens** (same 18 in both dark and light mode): `bg`, `surface`, `surface-raised`, `surface-hover`, `surface-selected`, `border`, `border-strong`, `text`, `muted`, `muted-soft`, `accent`, `accent-strong`, `on-accent`, `signal`, `success-text`, `warning-text`, `danger`, `info-text`. The `logo-arc` token is brandbook-exclusive (not present in style.ex) and must be explicitly documented as such. All other style.ex tokens are runtime-structural exclusions.

**Primary recommendation:** Fix brandbook name+value discrepancies to align with style.ex, then author the parity test that will fail CI permanently if any future drift occurs in either direction.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Brand token values (truth) | `brandbook/tokens.json` + `tokens.css` | — | Brand SSOT; these files define the canonical brand palette |
| Runtime UI token values (truth) | `lib/threadline/operator_surface/style.ex` | — | Frozen Phase-144 contract; shipped truth; wins on conflicts |
| Parity enforcement | `test/threadline/brandbook_token_parity_test.exs` | CI (`mix test`) | Automated link between brandbook and runtime lane |
| Brand posture narrative | `brandbook/brand-book.md` | — | Human-readable settled truth for brand consumers |
| Pressure-test gate | `brandbook/pressure-test.md` | mechanical suite shell commands | Brand quality scorecard; this phase augments dimension #11 |
| Milestone audit record | `.planning/milestones/v1.36-MILESTONE-AUDIT.md` | `.planning/REQUIREMENTS.md` | Traceability and closeout readiness |

---

## Standard Stack

### Core (No New Dependencies)

This phase installs zero new packages. All work uses existing project tooling:

| Tool | Version | Purpose |
|------|---------|---------|
| ExUnit | built-in | Elixir test framework; parity test lives here |
| Jason | existing dep | JSON parsing for `tokens.json` in parity test |
| File.read! | Elixir stdlib | Reading `style.ex` and brandbook files in tests |
| Regex | Elixir stdlib | Parsing CSS custom property declarations in `style.ex` |

**No `npm install`, no new hex packages, no toolchain additions.**

---

## Package Legitimacy Audit

> Not applicable — this phase installs zero external packages.

---

## Token Reconciliation (Keystone Investigation)

### style.ex Structure

`lib/threadline/operator_surface/style.ex` uses an `~H` sigil (HEEx template) with inline CSS. The CSS custom properties are declared as literal text — no Elixir-generated token values, no dynamic computation. A regex parser over the raw file string is the correct approach for the parity test.

**Dark base block** — inside `.threadline-ui { ... }` (approx. lines 19–186):
- 49 total `--tl-color-*` lines
- 43 unique-value declarations (6 are `var()` aliases for `op-insert/update/delete-*`)

**Light override block** — inside `.threadline-ui[data-tl-theme="light"] { ... }` (approx. lines 188–237):
- 43 unique `--tl-color-*` declarations (no `var()` aliases — op-* tokens are not overridden in light)
- Additionally overrides `--tl-shadow-subtle`, `--tl-shadow-popover`, `--tl-shadow-raised`, `--tl-focus-ring`

**System block** — inside `@media (prefers-color-scheme: light) { .threadline-ui[data-tl-theme="system"] { ... } }`:
- Identical values to the light override block
- The parity test targets the `[data-tl-theme="light"]` block as the canonical light source

### tokens.json / tokens.css Structure

`brandbook/tokens.json` has this shape:
- `raw.color.*` — palette swatches (raw named colors, not semantic)
- `semantic.dark.*` — dark-mode semantic tokens (19 entries)
- `semantic.light.*` — light-mode semantic tokens (19 entries)
- `typography`, `spacing`, `radius`, `shadow`, `focus`, `code`, `callout`, `state` — non-color brand tokens

`brandbook/tokens.css` emits:
- `:root, .tl-brand { ... }` — shared/non-semantic tokens (spacing, typography, radius, raw colors)
- `.tl-theme-dark, :root { ... }` — 19 semantic dark tokens + code/callout tokens
- `.tl-theme-light { ... }` — 19 semantic light tokens + code tokens (no shadow block)

### Full Token Reconciliation Table

**Curated parity intersection (18 tokens, both dark and light):**

| style.ex token name | tokens.css/json name (CURRENT) | Dark: style.ex value | Dark: brandbook value | Status |
|---|---|---|---|---|
| `--tl-color-bg` | `--tl-color-bg` / `bg` | `#0B1020` | `#0B1020` | MATCH |
| `--tl-color-surface` | `--tl-color-surface` / `surface` | `#141B2D` | `#141B2D` | MATCH |
| `--tl-color-surface-raised` | `--tl-color-surface-raised` / `surface-raised` | `#1B253A` | `#1B253A` | MATCH |
| `--tl-color-surface-hover` | `--tl-color-surface-hover` / `surface-hover` | `#202B42` | `#202B42` | MATCH |
| `--tl-color-surface-selected` | `--tl-color-surface-selected` / `surface-selected` | `#22304D` | `#22304D` | MATCH |
| `--tl-color-border` | `--tl-color-border` / `border` | `#23304A` | `#23304A` | MATCH |
| `--tl-color-border-strong` | `--tl-color-border-strong` / `border-strong` | `#2E3D5C` | `#2E3D5C` | MATCH |
| `--tl-color-text` | `--tl-color-text` / `text` | `#D7DEEA` | `#D7DEEA` | MATCH |
| `--tl-color-muted` | `--tl-color-text-muted` / `text-muted` | `#A3AFC2` | `#A3AFC2` | NAME MISMATCH (values match) |
| `--tl-color-muted-soft` | `--tl-color-text-soft` / `text-soft` | `#8F9DB5` | `#8F9DB5` | NAME MISMATCH (values match) |
| `--tl-color-accent` | `--tl-color-accent` / `accent` | `#4F8CFF` | `#4F8CFF` | MATCH |
| `--tl-color-accent-strong` | `--tl-color-accent-strong` / `accent-strong` | `#6FA1FF` | `#6FA1FF` | MATCH |
| `--tl-color-on-accent` | `--tl-color-on-accent` / `accent-text` | `#08101F` | `#08101F` | MATCH |
| `--tl-color-signal` | `--tl-color-signal` / `signal` | `#4EDFD1` | `#4EDFD1` | MATCH |
| `--tl-color-success-text` | `--tl-color-success-text` / `success-text` | `#5AE0A2` | `#5AE0A2` | MATCH |
| `--tl-color-warning-text` | `--tl-color-warning-text` / `warning-text` | `#F6C86B` | `#FFD166` | **VALUE MISMATCH — brandbook wrong** |
| `--tl-color-danger` | `--tl-color-error-text` / `error-text` | `#FF8585` | `#FF8585` | NAME MISMATCH (values match) |
| `--tl-color-info-text` | `--tl-color-info-text` / `info-text` | `#9AB9FF` | `#9AB9FF` | MATCH |

**Light lane — same 18 tokens, value check:**

| style.ex token name | Light: style.ex value | Light: brandbook value | Status |
|---|---|---|---|
| `--tl-color-bg` | `#F7F9FC` | `#F7F9FC` | MATCH |
| `--tl-color-surface` | `#FFFFFF` | `#FFFFFF` | MATCH |
| `--tl-color-surface-raised` | `#EEF3FA` | `#EEF3FA` | MATCH |
| `--tl-color-surface-hover` | `#E7ECF4` | `#E7ECF4` | MATCH |
| `--tl-color-surface-selected` | `#DDE8FF` | `#DDE8FF` | MATCH |
| `--tl-color-border` | `#C9D3E2` | `#C9D3E2` | MATCH |
| `--tl-color-border-strong` | `#A7B4C8` | `#A7B4C8` | MATCH |
| `--tl-color-text` | `#0F1728` | `#0F1728` | MATCH |
| `--tl-color-muted` | `#3B4762` | `#3B4762` (in json as `text-muted`) | NAME MISMATCH (values match) |
| `--tl-color-muted-soft` | `#73819C` | `#73819C` (in json as `text-soft`) | NAME MISMATCH (values match) |
| `--tl-color-accent` | `#1557C0` | `#1557C0` | MATCH |
| `--tl-color-accent-strong` | `#0E459B` | `#0E459B` | MATCH |
| `--tl-color-on-accent` | `#FFFFFF` | `#FFFFFF` (as `accent-text`) | MATCH |
| `--tl-color-signal` | `#0F8F85` | `#0F8F85` | MATCH |
| `--tl-color-success-text` | `#136C47` | `#136C47` | MATCH |
| `--tl-color-warning-text` | `#8A5512` | `#7A5400` | **VALUE MISMATCH — brandbook wrong** |
| `--tl-color-danger` | `#A33434` | `#A33434` (as `error-text`) | NAME MISMATCH (values match) |
| `--tl-color-info-text` | `#1557C0` | `#1557C0` | MATCH |

### Brandbook-Exclusive Token (NOT in style.ex)

| brandbook token | Value (dark) | Value (light) | Classification |
|---|---|---|---|
| `--tl-color-logo-arc` / `logo-arc` | `#4781E6` | `#4781E6` | BRAND-EXCLUSIVE: stays in brandbook; not a runtime UI token. Must be documented in the exclusion list. |

### Runtime-Only Exclusion Set (tokens in style.ex NOT in curated parity set)

These 31 dark-base tokens are explicitly out of brand scope (per D-02). The light block adds overrides for most of these too. None appear in tokens.json semantic blocks.

**Structural/compositional exclusions (rgba, compound values, var() refs):**
- `--tl-color-surface-tint` (dark: `rgba(20, 27, 45, 0.94)` / light: `rgba(255, 255, 255, 0.92)`)
- `--tl-color-surface-tint-strong` (dark: `rgba(11, 16, 32, 0.96)` / light: `rgba(247, 249, 252, 0.96)`)
- `--tl-color-backdrop` (dark: `rgba(2, 4, 10, 0.62)` / light: `rgba(15, 23, 40, 0.42)`)
- `--tl-color-border-focus` (dark: `#7FA9FF` / light: `#1557C0`)
- `--tl-color-accent-soft` (dark: `rgba(79, 140, 255, 0.18)` / light: `rgba(21, 87, 192, 0.12)`)
- `--tl-color-accent-wash` (dark: `rgba(79, 140, 255, 0.09)` / light: `rgba(21, 87, 192, 0.06)`)
- `--tl-color-accent-border` (dark: `rgba(127, 169, 255, 0.48)` / light: `rgba(21, 87, 192, 0.28)`)
- `--tl-color-accent-inset` (dark: `rgba(127, 169, 255, 0.16)` / light: `rgba(21, 87, 192, 0.16)`)
- `--tl-color-signal-bg` (dark: `rgba(78, 223, 209, 0.12)` / light: `rgba(15, 143, 133, 0.12)`)
- `--tl-color-signal-border` (dark: `rgba(78, 223, 209, 0.30)` / light: `rgba(15, 143, 133, 0.30)`)
- `--tl-color-ink` (dark: `#0F1728`)
- `--tl-color-paper` (dark: `#F7F9FC`)

**Status tint system (designed for light but runtime-structural):**
- `--tl-color-danger-bg`, `--tl-color-danger-border`
- `--tl-color-warning-bg`, `--tl-color-warning-dot`, `--tl-color-warning-border`
- `--tl-color-success-bg`, `--tl-color-success-border`
- `--tl-color-info-bg`, `--tl-color-info-border`
- `--tl-color-neutral-bg`, `--tl-color-neutral-text`, `--tl-color-neutral-border`

**Op badge aliases (var() references):**
- `--tl-color-op-insert-bg`, `--tl-color-op-insert-text`
- `--tl-color-op-update-bg`, `--tl-color-op-update-text`
- `--tl-color-op-delete-bg`, `--tl-color-op-delete-text`

**Brand rail:**
- `--tl-color-brand-rail` (dark: `#0B1020` / light: `#0F1728`)

**Verification against D-02 candidate list:**
- D-02 lists: `op-insert/update/delete-*`, `accent-soft`, `accent-wash`, `accent-inset`, `accent-border`, `surface-tint`, `surface-tint-strong`, `signal-bg`, `signal-border`, status `*-bg`/`*-border`, `op badges`, `brand-rail`, `backdrop`, `border-focus`
- All confirmed present in style.ex and absent from the parity intersection. MATCH.
- D-02 did NOT list `ink` or `paper` explicitly, but they are functional runtime tokens (ink=product-dark-bg, paper=product-light-bg) rather than brand-defining; they are excluded from parity scope and are brand-adjacent values visible in the raw color palette only.
- D-02 did NOT list `warning-dot` or `neutral-text` explicitly; both are runtime-structural and confirmed excluded.

### Existing brandbook/tools Inventory

`brandbook/tools/` contains:
- `README.md` — documents the glyph pipeline tool
- `text-to-paths.mjs` — converts fonts to SVG paths (Phase 160 artifact, unrelated)

**No existing token lint or parity harness exists.** The parity test is a net-new Elixir test file. No "plug into" opportunity exists.

---

## Parity Test Mechanics

### Parser Strategy

`style.ex` uses an `~H` sigil with inline CSS — not a heredoc, not a function-built string. The CSS is literal text embedded in the Elixir module. The correct parser approach:

1. `File.read!("lib/threadline/operator_surface/style.ex")` — read raw source
2. Extract dark block: isolate the `.threadline-ui {` base block (everything before the `[data-tl-theme=` selectors). A safe approach: split on `[data-tl-theme=` and take the first segment.
3. Extract light block: isolate the `.threadline-ui[data-tl-theme="light"] {` block. Regex: `~r/\[data-tl-theme="light"\]\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}/s` (or a simpler string split on known delimiters).
4. Parse tokens: `Regex.scan(~r/--tl-color-([^:]+):\s*([^;]+?)\s*;/, block)` — captures name and value.
5. Build maps: `Map.new(scan_results, fn [_, name, value] -> {name, String.trim(value)} end)`.

For `tokens.json`:
1. `File.read!("brandbook/tokens.json") |> Jason.decode!()` — Jason is already a project dep.
2. Access `data["semantic"]["dark"]` and `data["semantic"]["light"]`.

### Name Mapping Required

After renaming brandbook tokens to match style.ex (the phase's correction task), the parity test can do direct name equality. If the planner prefers NOT to rename brandbook tokens (keeping `text-muted`, `text-soft`, `error-text`), the test needs a name-mapping table:

```elixir
# Recommended: rename brandbook tokens to match style.ex names
# Then test uses the intersection directly with same key names

# Alternative (if rename is not done): explicit name bridge
@name_bridge %{
  "text-muted" => "muted",
  "text-soft" => "muted-soft",
  "error-text" => "danger",
  "accent-text" => "on-accent"
}
```

**Recommendation:** rename the brandbook tokens to match style.ex names directly. This makes the parity test clean (`assert Map.get(dark_style, name) == Map.get(dark_brand, name)`) and removes a name-bridging maintenance burden.

### Parity Test Structure

```elixir
defmodule Threadline.BrandbookTokenParityTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"
  @tokens_json_path "brandbook/tokens.json"

  # The curated intersection: tokens the brandbook claims to mirror.
  # Names use style.ex conventions (muted, not text-muted; danger, not error-text).
  @parity_intersection ~w[
    bg surface surface-raised surface-hover surface-selected
    border border-strong text muted muted-soft
    accent accent-strong on-accent signal
    success-text warning-text danger info-text
  ]

  # Brand-exclusive: in brandbook but not in style.ex (intentional, not drift)
  @brand_exclusive ~w[logo-arc]

  # Runtime-only: in style.ex but not in parity set (intentional)
  @runtime_only ~w[
    surface-tint surface-tint-strong backdrop border-focus
    accent-soft accent-wash accent-border accent-inset
    signal-bg signal-border ink paper
    danger-bg danger-border warning-bg warning-dot warning-border
    success-bg success-border info-bg info-border
    neutral-bg neutral-text neutral-border
    op-insert-bg op-insert-text op-update-bg op-update-text
    op-delete-bg op-delete-text brand-rail
  ]

  # ... parse style.ex dark+light, parse tokens.json semantic.dark+light ...
  # ... assert value equality on @parity_intersection for both modes ...
  # ... assert @brand_exclusive tokens NOT in style.ex ...
  # ... assert @runtime_only tokens NOT in brandbook semantic blocks ...
end
```

### Doc-Contract Literal Lock Pattern

From `operator_surface_doc_contract_test.exs` and `theme_doc_contract_test.exs`:

```elixir
# House style: File.read!/1 + String.contains?/2, individual assertions per fragment
test "brand book states UI theming posture keystone sentence" do
  brand_book = File.read!("brandbook/brand-book.md")
  assert String.contains?(brand_book, "dark-primary")
  assert String.contains?(brand_book, "theme: :system | :light | :dark")
  assert String.contains?(brand_book, "per-operator runtime toggle is deferred")
end
```

**Recommendation:** The posture-note literal lock belongs in the same new `brandbook_token_parity_test.exs` file (not in a separate file, since it is testing the same brandbook artifacts). This consolidates all brand alignment enforcement in one place. The file is already named `brandbook_token_parity_test.exs` per D-03 — the doc-contract assertions can live in their own named test block within it.

### Tokens.css Parity

tokens.css uses different token names in the dark semantic block than style.ex:
- `--tl-color-text-muted` vs `--tl-color-muted`
- `--tl-color-text-soft` vs `--tl-color-muted-soft`
- `--tl-color-error-text` vs `--tl-color-danger`
- `--tl-color-logo-arc` (brand-exclusive, absent from style.ex)

The parity test should primarily target `tokens.json` (authoritative source) rather than parsing `tokens.css` (generated from JSON). This avoids dual-parser complexity. However, a secondary test asserting that tokens.css is consistent with tokens.json (matching values for the same semantic path) is worth including.

---

## Doc-Contract Test Patterns

### Established House Style

From `operator_surface_doc_contract_test.exs`:
```elixir
use ExUnit.Case, async: true

test "descriptive name" do
  file = File.read!("path/to/file.md")
  assert String.contains?(file, "exact literal string")
  refute String.contains?(file, "banned pattern")
end
```

From `theme_doc_contract_test.exs`:
```elixir
test "guide documents the theme: option literal" do
  src = File.read!(@guide_path)
  assert String.contains?(src, "theme:"),
         "expected #{@guide_path} to document the `theme:` mount option literal"
end
```

Key idioms:
- Each assertion is its own named `test` block (fine-grained failure attribution)
- File paths stored as module attributes
- Optional custom failure message as second argument to `assert`
- `async: true` — these are pure file reads, no shared state

### Where the Posture Lock Lives

**Decision: in `brandbook_token_parity_test.exs`** (not extending an existing test). Rationale:
- The posture note lives in `brandbook/brand-book.md` — same brandbook artifact family as tokens.json/tokens.css
- Keeps all brandbook alignment enforcement in one file
- The `operator_surface_doc_contract_test.exs` tests guide/README docs, not brandbook files
- The `v1_23_charter_doc_contract_test.exs` tests planning docs (`.planning/PROJECT.md`, `MILESTONE-ARC.md`)

---

## Pressure-Test Addendum Mechanics

### Existing Mechanical Suite Format

`brandbook/pressure-test.md` mechanical suite (top of file, before scorecard):

```sh
# Example from current suite:
grep -rln '<text' brandbook/ --include='*.svg'        # must return nothing
node -e "JSON.parse(require('fs').readFileSync('brandbook/tokens.json'))"  # in dimension #11
```

The format is shell commands with inline comments explaining the expected outcome. Commands run from repo root. Each command is self-contained and exits 0 on success (or returns empty output where that's the contract).

### New Mechanical Suite Line (D-08)

The new parity gate line for the suite must match this format and run the same check the parity test runs:

```sh
# Brandbook token parity: curated dark+light intersection must equal shipped UI lane
mix test test/threadline/brandbook_token_parity_test.exs  # exit 0 = no drift
```

This is appropriate because:
- The existing mechanical suite already references `lib/threadline/operator_surface/style.ex` in dimension #11's pass condition ("brand tokens never leak into the product-UI contract")
- A `mix test` command is shell-runnable from repo root, consistent with the `node -e` pattern
- It directly reuses the parity test rather than duplicating logic

### Dimension #11 Augmentation (D-07)

Current dimension #11 text:
```
**Pass condition:** dual-format tokens (JSON + CSS) with raw/semantic layering and
dark/light lanes that carry identical values; brand tokens never leak into the
product-UI contract.
**Check:** `node -e "JSON.parse(...)"` exits 0; every custom property in `tokens.css`
has a matching `tokens.json` entry; `lib/threadline/operator_surface/style.ex`
contains no brandbook-driven change.
**Score: 8/10.** ... The known debt holds the score: JSON and CSS are hand-duplicated
with no generated sync check, so drift is prevented by review rather than tooling.
```

Augmentation approach:
- Add a "dual-mode pass condition" to the existing pass condition text: "for every token in the curated intersection, its value in `tokens.json semantic.dark` matches the dark lane of `style.ex`, and `semantic.light` matches the light lane."
- Add the mechanical parity check command to the Check: line.
- Update the score justification: the "known debt" note no longer holds, because the parity test is now a generated sync check (drift is automated, not review-based). Score can increase from 8/10 to 9/10 on this dimension.
- Add cross-reference to dimension #5: "See dimension #5 for the logo dual-mode pass; this dimension governs the UI token lane dual-mode."

---

## Milestone Audit Doc Template

### Template Structure (from v1.33 and v1.35)

**YAML front matter fields (v1.35 is the richer template — use this):**
```yaml
---
milestone: v1.36
milestone_name: Operator Surface Light Mode
audited: 2026-06-14
status: pending
closeout_readiness: PENDING — end-of-milestone UAT gate required
requirements_total: 15
requirements_satisfied: 15
phases: [166, 167, 168, 169, 170]
verification_records: 5/5
auditor: Claude (phase-170-research)
---
```

**Sections (follow v1.35 structure, which is more detailed than v1.33):**

1. `## Phase Verification Ledger` — table of phase / name / verification file / status / score
2. `## 1. Requirements Completeness — N/15 satisfied` — per-req table with evidence pointer
3. `## 2. Cross-Phase Integration` — what flows across phases (theme mechanism → component retune → accessibility → docs → brand)
4. `## 3. Human-Gate Ledger` — table of gates, when they fired, verbatim records
5. `## 4. Deferred Ledger` — what was explicitly deferred (THEME-TOGGLE-01, COMP-01/02 partial per Phase 167 status)
6. `## 5. Findings` — any gaps, bookkeeping issues, open items
7. `## Verdict` — status + closeout_readiness

**Key difference for v1.36:** Closeout readiness must be `PENDING` (not green) because the End-of-milestone UAT human gate runs after Phase 170, before `/gsd-complete-milestone`.

### v1.36 Requirement → Phase Mapping (for audit table)

| Requirement | Closing Phase | Status |
|-------------|---------------|--------|
| THEME-01 | 166 | Complete |
| THEME-02 | 166 | Complete |
| THEME-03 | 166 | Complete |
| THEME-04 | 166 | Complete |
| TOKEN-01 | 166 | Complete |
| TOKEN-02 | 166 | Complete |
| TOKEN-03 | 166 | Complete |
| COMP-01 | 167 | Pending (Phase 167 Wave 2 not complete per ROADMAP) |
| COMP-02 | 167 | Pending (Phase 167 Wave 2 not complete per ROADMAP) |
| A11Y-01 | 168 | Complete |
| A11Y-02 | 168 | Complete |
| EVID-01 | 169 | Complete |
| EVID-02 | 169 | Complete |
| BRAND-01 | 170 | In progress (this phase) |
| BRAND-02 | 170 | In progress (this phase) |

**Important note on COMP-01 / COMP-02:** ROADMAP.md shows Phase 167 has `167-01-PLAN.md` complete (design review gate) but `167-02-PLAN.md` NOT complete (the actual retune implementation). The audit doc must accurately reflect this — if the audit is authored after Phase 170 completes but before COMP-01/02 are verified, the audit should note COMP-01/COMP-02 as a known gap that requires follow-up or documents the design review gate outcome.

**Resolution for audit:** Read the actual Phase 167 verification record status before populating the audit table. The ROADMAP shows `component-retune` is `In Progress` (not complete). The milestone cannot cleanly close until this is resolved. The audit doc should document this as a finding.

---

## Architecture Patterns

### Recommended Project Structure (new files only)

```
test/threadline/
└── brandbook_token_parity_test.exs   # NEW: parity test (D-03)
.planning/milestones/
└── v1.36-MILESTONE-AUDIT.md          # NEW: milestone audit doc (D-09)
```

**Modified files:**
```
brandbook/tokens.json                 # Fix: rename text-muted->muted, text-soft->muted-soft,
                                      #      error-text->danger; fix warning-text values
brandbook/tokens.css                  # Fix: rename --tl-color-text-muted, text-soft, error-text;
                                      #      fix warning-text values in both blocks
brandbook/brand-book.md               # Add: "UI theming posture" subsection (D-04/D-05)
brandbook/pressure-test.md            # Augment: dim #11 + mechanical suite line (D-07/D-08)
.planning/REQUIREMENTS.md             # Update: traceability table (D-10)
```

### Pattern: Parity Test Data Flow

```
brandbook/tokens.json  ──parse──►  semantic.dark / semantic.light maps
                                          │
                                    value-equality
                                    assertion on
                                    @parity_intersection
                                          │
lib/threadline/operator_surface/  ─parse──►  dark_tokens / light_tokens maps
style.ex (regex over raw text)
```

### Pattern: Regex Block Extraction from style.ex

```elixir
# Extract dark base block (content before first [data-tl-theme=...])
[dark_section | _] = String.split(src, ~r/\.threadline-ui\[data-tl-theme/)

# Extract light override block
[_, light_body | _] = Regex.split(~r/\[data-tl-theme="light"\]\s*\{/, src)
[light_section | _] = String.split(light_body, "}")

# Parse token declarations
parse_tokens = fn block ->
  Regex.scan(~r/--tl-color-([^:]+):\s*([^;]+?)\s*;/, block)
  |> Map.new(fn [_, name, value] -> {String.trim(name), String.trim(value)} end)
end
```

### Anti-Patterns to Avoid

- **Don't assert a token count.** The "45-token lane" is a planning-doc phrase. The runtime dark block has 49 `--tl-color-*` lines (43 unique-value + 6 var() aliases). Assert value-equality on named intersection tokens, not counts.
- **Don't parse tokens.css for parity.** Use `tokens.json` as the authoritative source. tokens.css is a derived format; parsing both creates double-maintenance without adding safety.
- **Don't add a new pressure-test dimension.** D-07 explicitly locks this — augment #11, do not add #16.
- **Don't mark closeout readiness green.** D-11 explicitly requires PENDING until the End-of-milestone UAT gate runs.
- **Don't touch style.ex.** The phase corrects brandbook to match style.ex — not the other way.

---

## Common Pitfalls

### Pitfall 1: Token Name Drift Between brandbook and style.ex
**What goes wrong:** brandbook uses `text-muted`, style.ex uses `muted`. Parity test passes incorrectly if the intersection map is built with the wrong key convention.
**Why it happens:** brandbook tokens were authored with a different naming convention (`text-*` prefix for muted variants) than the shipped runtime lane.
**How to avoid:** The phase must rename brandbook tokens to match style.ex names BEFORE writing the parity test (or implement an explicit mapping table with the same effect). The renaming is part of "achieving parity."
**Warning signs:** Parity test passes trivially because the intersection set maps to zero matching keys.

### Pitfall 2: Warning-text Value Mismatch Causes Test Failure
**What goes wrong:** The parity test fails immediately on `warning-text` if brandbook is not corrected first.
**Why it happens:** brandbook dark `warning-text` is `#FFD166`; style.ex dark is `#F6C86B`. brandbook light `warning-text` is `#7A5400`; style.ex light is `#8A5512`. These diverged during Phase 166 light lane design.
**How to avoid:** Correct `tokens.json` and `tokens.css` `warning-text` values to match style.ex before running the parity test.
**Warning signs:** Test fails with "expected #F6C86B, got #FFD166."

### Pitfall 3: Parsing the System Block Instead of the Light Block
**What goes wrong:** The `@media (prefers-color-scheme: light) .threadline-ui[data-tl-theme="system"]` block has identical values to the light override block but a different selector. Regex over the full file may capture system-block tokens instead of the canonical light block.
**How to avoid:** Split on `[data-tl-theme="light"]` specifically (not the system selector). The system block is inside a `@media` wrapper — split strategy accounts for this by anchoring to the exact selector string.

### Pitfall 4: tokens.css Not Updated to Match tokens.json
**What goes wrong:** tokens.json is corrected but tokens.css is hand-duplicated and not updated, so they diverge.
**Why it happens:** No generated sync between the two files (this is the pre-existing "known debt" per pressure-test dimension #11).
**How to avoid:** Update both files atomically in the same commit. The parity test verifies tokens.json against style.ex; the pressure-test dimension #11 prose verifies CSS and JSON match. A secondary test assertion can compare the CSS and JSON values for the intersection tokens.

### Pitfall 5: Audit Doc Misrepresents COMP-01/COMP-02 Status
**What goes wrong:** Audit doc marks all 15 requirements "satisfied" when Phase 167 Wave 2 (the actual component retune) is not complete per ROADMAP.md.
**Why it happens:** The audit is authored in Phase 170 but Phase 167 is incomplete. ROADMAP shows 167-02-PLAN.md is not complete.
**How to avoid:** The audit doc must accurately reflect COMP-01/COMP-02 as pending. Closeout readiness is PENDING (per D-11) which naturally covers this. The human gate after Phase 170 is the right mechanism for resolving this before milestone closure.

---

## Code Examples

### Parity Test Skeleton
```elixir
# Source: derived from operator_surface_doc_contract_test.exs + theme_doc_contract_test.exs patterns
defmodule Threadline.BrandbookTokenParityTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"
  @tokens_json_path "brandbook/tokens.json"

  # Curated intersection: names use style.ex conventions
  @parity_intersection ~w[
    bg surface surface-raised surface-hover surface-selected
    border border-strong text muted muted-soft
    accent accent-strong on-accent signal
    success-text warning-text danger info-text
  ]

  # Brand-exclusive tokens (in brandbook, intentionally absent from style.ex)
  @brand_exclusive ~w[logo-arc]

  # Runtime-only tokens (in style.ex, intentionally absent from brandbook parity set)
  @runtime_only ~w[
    surface-tint surface-tint-strong backdrop border-focus
    accent-soft accent-wash accent-border accent-inset
    signal-bg signal-border ink paper
    danger-bg danger-border warning-bg warning-dot warning-border
    success-bg success-border info-bg info-border
    neutral-bg neutral-text neutral-border
    op-insert-bg op-insert-text op-update-bg op-update-text
    op-delete-bg op-delete-text brand-rail
  ]

  defp parse_style_tokens(src, selector) do
    [_, body | _] = Regex.split(~r/#{Regex.escape(selector)}\s*\{/, src)
    [block | _] = String.split(body, ~r/^\s*\}/m)
    Regex.scan(~r/--tl-color-([^:]+):\s*([^;]+?)\s*;/, block)
    |> Map.new(fn [_, name, value] -> {String.trim(name), String.trim(value)} end)
  end

  defp load_style do
    File.read!(@style_path)
  end

  defp load_tokens_json do
    File.read!(@tokens_json_path) |> Jason.decode!()
  end

  test "curated dark token intersection: brandbook values match style.ex" do
    src = load_style()
    [dark_section | _] = String.split(src, ~r/\.threadline-ui\[data-tl-theme/)
    style_dark = Regex.scan(~r/--tl-color-([^:]+):\s*([^;]+?)\s*;/, dark_section)
                 |> Map.new(fn [_, n, v] -> {String.trim(n), String.trim(v)} end)

    brand_dark = load_tokens_json()["semantic"]["dark"]

    for name <- @parity_intersection do
      style_val = Map.get(style_dark, name)
      brand_val = Map.get(brand_dark, name)
      assert style_val == brand_val,
             "dark --tl-color-#{name}: style.ex=#{inspect(style_val)}, brandbook=#{inspect(brand_val)}"
    end
  end

  test "curated light token intersection: brandbook values match style.ex" do
    # ... same pattern for light block ...
  end

  test "brand-exclusive tokens are absent from style.ex" do
    src = load_style()
    for name <- @brand_exclusive do
      refute String.contains?(src, "--tl-color-#{name}:"),
             "--tl-color-#{name} should be brand-exclusive but was found in style.ex"
    end
  end

  test "runtime-only tokens are absent from brandbook semantic blocks" do
    tokens = load_tokens_json()
    dark_keys = Map.keys(tokens["semantic"]["dark"])
    light_keys = Map.keys(tokens["semantic"]["light"])
    brand_keys = Enum.uniq(dark_keys ++ light_keys)

    for name <- @runtime_only do
      refute name in brand_keys,
             "#{name} should be runtime-only but was found in brandbook semantic tokens"
    end
  end

  test "brand book states UI theming posture note" do
    brand_book = File.read!("brandbook/brand-book.md")
    assert String.contains?(brand_book, "UI theming posture"),
           "brandbook/brand-book.md should contain UI theming posture subsection"
    assert String.contains?(brand_book, "dark-primary"),
           "posture note should state dark-primary"
    assert String.contains?(brand_book, "theme: :system | :light | :dark"),
           "posture note should cite the theme config triad"
  end
end
```

### brand-book.md Posture Subsection Location

Insert after the existing "Dark/light strategy:" block (approx. line 219 in brand-book.md) and before the "Usage:" block:

```markdown
### UI theming posture

The operator surface is dark-primary: Threadline Black is the canonical brand
background and the shipped default. Light mode is fully shipped and supported —
it is enabled via host configuration (`theme: :system | :light | :dark`) with
no extra packages, no JavaScript, and no FOUC. The `:system` value follows the
OS color-scheme preference via scoped CSS.

Per-operator runtime theme toggling is deferred until real adopter demand
emerges. localStorage is permanently rejected (FOUC on dead render, CSP
incompatible). The upgrade path to cookie-based toggling is documented.

State this only because it is true as of v1.36 — the v1.33 lesson: dark-primary
claims were settled; light-supported claims wait until light actually ships.
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual review for brandbook/style.ex sync | Automated parity test (this phase) | Phase 170 | Drift caught in CI permanently |
| Dark-only operator surface | Dark-primary, light+system supported via host config | Phase 166 | Brand posture must reflect this |
| pressure-test dim #11 "review prevents drift" | parity test + dim #11 augmented | Phase 170 | Score can increase from 8/10 to 9/10 |
| brandbook text-muted/text-soft/error-text names | muted/muted-soft/danger (matching style.ex) | Phase 170 | Enables direct name-equality parity test |

**Deprecated/outdated:**
- brandbook token names `text-muted`, `text-soft`, `error-text`: replaced by `muted`, `muted-soft`, `danger` (matching the shipped runtime lane per D-01)
- Warning-text values: `#FFD166` (dark) and `#7A5400` (light) in brandbook are wrong; replaced by `#F6C86B` (dark) and `#8A5512` (light) to match style.ex

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 167 Wave 2 (`167-02-PLAN.md`) is not complete — COMP-01/COMP-02 remain pending | Milestone Audit section | If actually complete, the audit's requirements_satisfied count changes from 13/15 to 15/15, and closeout_readiness can be green after UAT |
| A2 | The `logo-arc` token is intentionally absent from style.ex (brand-exclusive) | Token reconciliation | If style.ex ever adds a `--tl-color-logo-arc` token, the parity test's brand-exclusive assertion would fail — this is the desired behavior |
| A3 | Shadows in tokens.css/json are brand-design values (not in the parity set) | Token reconciliation | If shadows were meant to be in the parity set, the tokens.css dark shadow values differ from style.ex dark shadow values (lighter opacities) and would fail immediately |

---

## Open Questions

1. **COMP-01/COMP-02 completeness for the audit**
   - What we know: ROADMAP.md shows Phase 167 `component-retune` with 167-01-PLAN done (design review) and 167-02-PLAN NOT done (actual retune). The ROADMAP phase table shows Phase 167 as "In Progress."
   - What's unclear: Have COMP-01 and COMP-02 been partially or fully addressed by Phase 167 Wave 1 alone, or do they require Wave 2?
   - Recommendation: Planner should read `167-01-PLAN.md` and `ROADMAP.md` Phase 167 section carefully before populating audit table. If Wave 2 is genuinely incomplete, the audit should record COMP-01/02 as pending and flag it as a finding. The UAT gate naturally holds closeout until this is resolved.

2. **tokens.css secondary assertion scope**
   - What we know: tokens.css duplicates tokens.json values by hand. The parity test targets tokens.json as the authoritative source.
   - What's unclear: Should the parity test also verify tokens.css emits the same values as tokens.json for the intersection tokens? This would catch the hand-duplication drift.
   - Recommendation: Add a lightweight secondary assertion in the parity test that reads tokens.css and checks the 18 intersection token values match tokens.json. This closes the "known debt" from pressure-test #11 and removes the last manual check.

---

## Environment Availability

> Step 2.6: SKIPPED (no external dependencies identified — this phase is code/config/docs-only using existing project tooling).

---

## Validation Architecture

> Nyquist validation is enabled for this phase.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/threadline/brandbook_token_parity_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BRAND-01 | Dark token intersection values match style.ex | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ Wave 0 |
| BRAND-01 | Light token intersection values match style.ex | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ Wave 0 |
| BRAND-01 | Brand-exclusive tokens absent from style.ex | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ Wave 0 |
| BRAND-01 | Runtime-only tokens absent from brandbook semantics | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ Wave 0 |
| BRAND-01 | brand-book.md contains UI theming posture note + keystone sentence | unit | `mix test test/threadline/brandbook_token_parity_test.exs` | ❌ Wave 0 |
| BRAND-02 | pressure-test.md dimension #11 augmented with dual-mode pass condition | doc-contract (manual-readable) | grep check or assertion | ❌ Wave 0 |
| BRAND-02 | pressure-test.md mechanical suite contains parity gate line | unit | `grep "brandbook_token_parity_test" brandbook/pressure-test.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/brandbook_token_parity_test.exs`
- **Per wave merge:** `mix ci.all`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/threadline/brandbook_token_parity_test.exs` — covers all BRAND-01 assertions and the posture-note doc-contract
- [ ] Framework install: none needed (ExUnit is built-in; Jason is existing dep)

---

## Security Domain

> Not applicable — this phase touches only test files, documentation markdown, and brand JSON/CSS. No authentication, session management, input validation, cryptography, or user-facing endpoints are modified.

---

## Project Constraints (from CLAUDE.md)

- Use `mix verify.*` / `mix ci.all` entrypoints in task actions — not ad-hoc test commands as the canonical CI reference.
- Named test file: `test/threadline/brandbook_token_parity_test.exs` (matches project's `test/threadline/` convention for library-level tests).
- Domain language: this is a docs/brand phase — no `AuditTransaction`, `AuditChange`, etc. terms needed.
- Three-layer architecture: this phase only touches the brandbook (brand SSOT) and test files — no capture, semantics, or exploration layer code is modified.
- `mix compile --warnings-as-errors` must pass (no warnings in any modified Elixir files).
- `mix format` must be applied to the new test file.
- Never touch the uncommitted nav-overhaul lane (~29 files).

---

## Sources

### Primary (HIGH confidence)
- `lib/threadline/operator_surface/style.ex` — direct read; all token values extracted and verified [VERIFIED: live codebase]
- `brandbook/tokens.json` — direct read; all semantic token values extracted [VERIFIED: live codebase]
- `brandbook/tokens.css` — direct read; CSS emission of tokens.json [VERIFIED: live codebase]
- `brandbook/pressure-test.md` — direct read; mechanical suite format + dimension #11 wording [VERIFIED: live codebase]
- `brandbook/brand-book.md` lines 200–320 — direct read; placement for posture subsection [VERIFIED: live codebase]
- `test/threadline/operator_surface_doc_contract_test.exs` — direct read; house style for doc-contract tests [VERIFIED: live codebase]
- `test/threadline/operator_surface/theme_doc_contract_test.exs` — direct read; exact pattern for individual-assertion doc-contract tests [VERIFIED: live codebase]
- `.planning/milestones/v1.33-MILESTONE-AUDIT.md` — direct read; audit template (shorter form) [VERIFIED: live codebase]
- `.planning/milestones/v1.35-MILESTONE-AUDIT.md` — direct read; audit template (richer form — use this) [VERIFIED: live codebase]
- `.planning/phases/170-brand-alignment-closeout/170-CONTEXT.md` — direct read; locked decisions [VERIFIED: live codebase]
- `.planning/REQUIREMENTS.md` — direct read; all 15 v1.36 requirements and traceability [VERIFIED: live codebase]
- `.planning/ROADMAP.md` — direct read; Phase 167 completion status [VERIFIED: live codebase]

### Secondary (MEDIUM confidence)
- `brandbook/tools/README.md` — direct read; confirmed no existing token/lint harness [VERIFIED: live codebase]
- `test/threadline/v1_23_charter_doc_contract_test.exs` — direct read; planning-doc doc-contract pattern (not used here but cross-referenced) [VERIFIED: live codebase]

---

## Metadata

**Confidence breakdown:**
- Token reconciliation: HIGH — derived directly from live file reads with exact grep/parse verification
- Parity test mechanics: HIGH — parser pattern is straightforward regex over known CSS structure
- Doc-contract pattern: HIGH — read directly from existing house-style tests
- Pressure-test addendum: HIGH — read directly from existing document format
- Milestone audit template: HIGH — read from v1.33 and v1.35 templates directly
- COMP-01/COMP-02 status: MEDIUM — based on ROADMAP.md state; actual verification records for Phase 167 not read

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 (stable artifacts; tokens.json/style.ex values won't change until another milestone)
