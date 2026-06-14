# Phase 170: brand-alignment-closeout - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 6 (2 new, 4 modified)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/threadline/brandbook_token_parity_test.exs` | test | transform | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `.planning/milestones/v1.36-MILESTONE-AUDIT.md` | config/doc | batch | `.planning/milestones/v1.35-MILESTONE-AUDIT.md` | exact |
| `brandbook/tokens.json` | config | CRUD | self — curated subset of `lib/threadline/operator_surface/style.ex` semantic block | role-match |
| `brandbook/tokens.css` | config | CRUD | self — `.tl-theme-dark` / `.tl-theme-light` blocks | role-match |
| `brandbook/brand-book.md` | config/doc | CRUD | self — §Dark/light strategy + §Color (~lines 217–288) | role-match |
| `brandbook/pressure-test.md` | config/doc | CRUD | self — §11 Token rigor + mechanical suite | role-match |
| `.planning/REQUIREMENTS.md` | config/doc | CRUD | self — Traceability table (~lines 57–80) | role-match |

---

## Pattern Assignments

### `test/threadline/brandbook_token_parity_test.exs` (test, transform)

**Primary analog:** `test/threadline/operator_surface_doc_contract_test.exs`
**Secondary analog:** `test/threadline/v1_23_charter_doc_contract_test.exs`
**Tertiary analog:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs`

**Module header pattern** (from `operator_surface_doc_contract_test.exs` lines 1–3):
```elixir
defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true
```

**Module-attribute path alias pattern** (from `v1_23_charter_doc_contract_test.exs` lines 9–12):
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**Test alternative — module-attribute path constants** (from `timeline_browse_doc_contract_test.exs` lines 6–9):
```elixir
@router_path "lib/threadline/operator_surface/router.ex"
@lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
```

**Core assert pattern — File.read! + String.contains?** (from `operator_surface_doc_contract_test.exs` lines 5–8):
```elixir
test "README declares the operator surface mount macro" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "threadline_operator_surface")
end
```

**Negative-assert pattern — refute String.contains?** (from `operator_surface_doc_contract_test.exs` lines 38–41):
```elixir
refute String.contains?(guide, "support_roles =")
refute String.contains?(guide, "permissions_dsl")
```

**Custom failure message pattern** (from `timeline_browse_doc_contract_test.exs` lines 17–20):
```elixir
assert String.contains?(router_src, ~s|live("/", StartLive, :index)|),
       "expected #{@router_path} to declare `live(\"/\", StartLive, :index)` inside the live_session :threadline scope"
```

**Multi-assert single test pattern** (from `operator_surface_doc_contract_test.exs` lines 24–31):
```elixir
test "operator surface guide details fail-closed security and auth options" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(guide, "fail-closed")
  assert String.contains?(guide, ":authorize_fn")
  assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
end
```

**Parity test implementation guidance** (from CONTEXT.md decisions D-01, D-03):
- Parse the dark base block of `style.ex` with a regex over `--tl-color-*:` lines to extract `{token_name, value}` pairs.
- Parse `brandbook/tokens.json` via `File.read!/1` + `Jason.decode!/1` (or `JSON.decode!/1` in Elixir 1.18+), walking `semantic.dark` and `semantic.light` maps.
- Assert value-equality only on the **intersection** of token names — not count equality.
- Assert the documented exclusion list by asserting that runtime-only tokens (`op-insert/update/delete-*`, `accent-soft`, `accent-wash`, `accent-inset`, `accent-border`, `surface-tint`, `surface-tint-strong`, `signal-bg`, `signal-border`, `brand-rail`, `backdrop`, `border-focus`) are **absent** from `tokens.json`'s semantic block (using `refute Map.has_key?/2` on the decoded JSON).
- Token name mapping: `tokens.json` key `"accent-text"` maps to `style.ex` variable `--tl-color-on-accent`; `"text-muted"` maps to `--tl-color-muted`; `"text-soft"` maps to `--tl-color-muted-soft`; `"error-text"` maps to `--tl-color-danger`. Derive the full mapping from live files before asserting.
- The posture-note literal lock (D-06) can live in a second `describe` block within this same file, checking `brandbook/brand-book.md` for the settled-truth sentence.

---

### `.planning/milestones/v1.36-MILESTONE-AUDIT.md` (config/doc, batch)

**Primary analog:** `.planning/milestones/v1.35-MILESTONE-AUDIT.md`
**Secondary analog:** `.planning/milestones/v1.33-MILESTONE-AUDIT.md`

**YAML front-matter skeleton** (from `v1.35-MILESTONE-AUDIT.md` lines 1–12):
```yaml
---
milestone: v1.35
milestone_name: Unified Logo & Brand Book v2
audited: 2026-06-12T21:45:32Z
status: passed
closeout_readiness: yellow
requirements_total: 31
requirements_satisfied: 31
phases: [159, 160, 161, 162, 163, 164, 165]
verification_records: 7/7
auditor: Claude (gsd-verifier)
---
```

For v1.36 this becomes:
```yaml
---
milestone: v1.36
milestone_name: Operator Surface Light Mode
audited: 2026-06-14
status: passed
closeout_readiness: pending-uat
requirements_total: 15
requirements_satisfied: 15
phases: [166, 167, 168, 169, 170]
verification_records: 5/5
auditor: Claude (gsd-verifier)
---
```

**Simpler YAML front-matter pattern** (from `v1.33-MILESTONE-AUDIT.md` lines 1–8):
```yaml
---
milestone: v1.33
name: Brand Review + Direction Selection
audited: 2026-06-06
status: passed
requirements: "6/6"
phases: "4/4"
---
```

**Verdict section** (from `v1.33-MILESTONE-AUDIT.md` lines 10–14):
```markdown
## Verdict

Passed.

The milestone made the v1.32 brandbook artifacts reviewable...
```

**Requirement audit table** (from `v1.33-MILESTONE-AUDIT.md` lines 16–28):
```markdown
## Requirement Audit

| Requirement | Phase | Status | Evidence |
|---|---|---|---|
| REVIEW-PACKET-01 | 150 | Satisfied | Review packet inventoried... |
| REVIEW-DECISION-01 | 151 | Satisfied | Human review selected... |
```

**Phase coverage table** (from `v1.35-MILESTONE-AUDIT.md` lines 20–30):
```markdown
## Phase Verification Ledger

| Phase | Name | Verification | Status | Score |
|-------|------|--------------|--------|-------|
| 159 | brand-audit-and-research | `159-VERIFICATION.md` (pre-existing) | passed | 6/6 |
```

**Integration audit section** (from `v1.33-MILESTONE-AUDIT.md` lines 30–36):
```markdown
## Integration Audit

- The reviewed brandbook direction remains source-first and specific to Threadline.
- ...
```

**Risks accepted section** (from `v1.33-MILESTONE-AUDIT.md` lines 38–43):
```markdown
## Risks Accepted

- Human legal/trademark review is not complete and remains deferred.
```

**Closeout readiness section** (from `v1.33-MILESTONE-AUDIT.md` lines 45–46 — the v1.36 version must mark PENDING per D-11):
```markdown
## Closeout Readiness

PENDING End-of-milestone UAT human gate. Runs after Phase 170 per ROADMAP Human Gates.
Green once UAT passes and `/gsd-complete-milestone` executes.
```

---

### `brandbook/tokens.json` (config, CRUD)

**Source of truth:** `lib/threadline/operator_surface/style.ex` — dark base block (`.threadline-ui`, lines ~56–113) and light override block (`[data-tl-theme="light"]`, lines ~188–237).

**Current JSON structure** (`brandbook/tokens.json` lines 34–76 — the section to align):
```json
"semantic": {
  "dark": {
    "bg": "#0B1020",
    "surface": "#141B2D",
    "surface-raised": "#1B253A",
    "surface-hover": "#202B42",
    "surface-selected": "#22304D",
    "border": "#23304A",
    "border-strong": "#2E3D5C",
    "text": "#D7DEEA",
    "text-muted": "#A3AFC2",
    "text-soft": "#8F9DB5",
    "accent": "#4F8CFF",
    "accent-strong": "#6FA1FF",
    "accent-text": "#08101F",
    "logo-arc": "#4781E6",
    "signal": "#4EDFD1",
    "success-text": "#5AE0A2",
    "warning-text": "#FFD166",
    "error-text": "#FF8585",
    "info-text": "#9AB9FF"
  },
  "light": {
    "bg": "#F7F9FC",
    ...
    "accent": "#1557C0",
    "accent-strong": "#0E459B",
    "accent-text": "#FFFFFF",
    "logo-arc": "#4781E6",
    "signal": "#0F8F85",
    "success-text": "#136C47",
    "warning-text": "#7A5400",
    "error-text": "#A33434",
    "info-text": "#1557C0"
  }
}
```

**Key value deltas to verify against `style.ex`** (planner must reconcile these):
- `semantic.dark.text-muted` = `#A3AFC2` vs `style.ex` `--tl-color-muted: #A3AFC2` — matches
- `semantic.dark.text-soft` = `#8F9DB5` vs `style.ex` `--tl-color-muted-soft: #8F9DB5` — matches
- `semantic.dark.accent-text` = `#08101F` vs `style.ex` `--tl-color-on-accent: #08101F` — matches
- `semantic.dark.error-text` = `#FF8585` vs `style.ex` `--tl-color-danger: #FF8585` — matches
- `semantic.dark.warning-text` = `#FFD166` vs `style.ex` `--tl-color-warning-text: #F6C86B` — **MISMATCH** (style.ex uses `#F6C86B`, tokens.json has `#FFD166`)
- `semantic.light.warning-text` = `#7A5400` vs `style.ex` `--tl-color-warning-text: #8A5512` — **MISMATCH**
- `semantic.light.success-text` = `#136C47` vs `style.ex` `--tl-color-success-text: #136C47` — matches
- `semantic.light.error-text` = `#A33434` vs `style.ex` `--tl-color-danger: #A33434` — matches

**Exclusion documentation pattern** (to add as a top-level key or a comment convention): Tokens explicitly out of brand scope per D-02 (planner adds an `"excluded_from_brand_scope"` key or a `"_notes"` key to document the gap).

---

### `brandbook/tokens.css` (config, CRUD)

**Current structure** (`brandbook/tokens.css` lines 81–142):
```css
.tl-theme-dark,
:root {
  color-scheme: dark;
  --tl-color-bg: #0B1020;
  --tl-color-surface: #141B2D;
  ...
  --tl-color-warning-text: #FFD166;
  --tl-color-error-text: #FF8585;
  --tl-color-info-text: #9AB9FF;
}

.tl-theme-light {
  color-scheme: light;
  --tl-color-bg: #F7F9FC;
  ...
  --tl-color-warning-text: #7A5400;
  --tl-color-error-text: #A33434;
  --tl-color-info-text: #1557C0;
}
```

**Source of truth (`style.ex`) dark block selectors** (`.threadline-ui` lines ~56–186).
**Source of truth (`style.ex`) light block selectors** (`.threadline-ui[data-tl-theme="light"]` lines ~188–237).

**Alignment rule:** Every CSS var in `tokens.css` dark/light blocks must match the corresponding `--tl-color-*` value in `style.ex`. The CSS var names in `tokens.css` already follow the same `--tl-color-*` convention as `style.ex`, so value comparison is direct. The same warning-text and any other mismatches found in `tokens.json` will also need correcting here.

---

### `brandbook/brand-book.md` (config/doc, CRUD)

**Insertion target** (`brandbook/brand-book.md` lines 217–288 — §Dark/light strategy through §Color):

Lines 217–228 contain "Dark/light strategy:" through the `<picture>` HTML snippet.
Lines 248–291 contain "## Color System" through "Rules:".

**New subsection placement:** Insert "### UI Theming Posture" immediately after the "Dark/light strategy" block closes (after line ~244, before the "Usage:" section at line ~230, or as a standalone subsection after the closing rules around line ~244). The posture note is brand-scoped (logo asset strategy), so it belongs adjacent to the Dark/light strategy paragraph, not inside §Color.

**Surrounding structure to match** (from `brandbook/brand-book.md` lines 217–229):
```markdown
Dark/light strategy:

- Every light-surface rendition is designed, never recolored from dark.
- The stitch arc keeps Stitch Blue `#4781E6` on both surfaces...
- On GitHub, serve both primaries with the `<picture>` element...

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg">
  <img alt="Threadline" src="brandbook/logo-primary-light.svg" width="420">
</picture>
```

**New subsection content target** (per D-04, D-05, D-06):
```markdown
### UI Theming Posture

Dark-primary. Light is fully shipped and supported, enabled via host config
(`theme: :system | :light | :dark`); per-operator runtime toggle is deferred
to real adopter demand (THEME-TOGGLE-01). This is settled truth as of v1.36,
the first version in which light shipped.
```

The sentence "Dark-primary. Light is fully shipped and supported, enabled via host config (`theme: :system | :light | :dark`)" must appear verbatim (this is the literal-lock assertion target for D-06).

---

### `brandbook/pressure-test.md` (config/doc, CRUD)

**Mechanical suite section** (from `brandbook/pressure-test.md` lines 9–39):
```sh
# Hard-constraint gate (HC-1..6, tagging, hygiene, tagline isolation) — exit 0 required
node .planning/phases/162-brand-book-v2/tools/brand-gate.mjs brandbook

# Zero live text in any SVG (GitHub's sandbox never loads fonts)
grep -rln '<text' brandbook/ --include='*.svg'        # must return nothing
...
# Text-only formats, no binaries
git ls-files brandbook/ | grep -vE '[.](svg|html|css|json|md|mjs)$'   # must return nothing
```

**New mechanical gate line format** (must match the existing comment style — `# description` then the command with `# outcome`):
```sh
# Token parity: brandbook semantic tokens match the shipped UI lane in both modes
mix test test/threadline/brandbook_token_parity_test.exs --color  # must exit 0
```

**Scorecard row target** (from `brandbook/pressure-test.md` line 66):
```markdown
| 11 | Token rigor | 8 / 10 | `tokens.json` parses; JSON and CSS lanes carry identical values; raw/semantic layering intact; product-UI contract (`lib/threadline/operator_surface/style.ex`) untouched |
```

**Dimension #11 body target** (from `brandbook/pressure-test.md` lines 203–213):
```markdown
### 11. Token rigor

**Pass condition:** dual-format tokens (JSON + CSS) with raw/semantic layering and
dark/light lanes that carry identical values; brand tokens never leak into the
product-UI contract.
**Check:** `node -e "JSON.parse(require('fs').readFileSync('brandbook/tokens.json'))"`
exits 0; every custom property in `tokens.css` has a matching `tokens.json` entry;
`lib/threadline/operator_surface/style.ex` contains no brandbook-driven change.
**Score: 8/10.** Both formats parse, values match, and the product contract is
untouched. The known debt holds the score: JSON and CSS are hand-duplicated with no
generated sync check, so drift is prevented by review rather than tooling.
```

**Dimension #5 cross-ref target** (from `brandbook/pressure-test.md` lines 125–137):
```markdown
### 5. Dark/light versatility

**Pass condition:** every single-slot or auto-switching surface gets a working asset...
**Score: 9/10.** All four mechanisms are committed and render correctly under both
color schemes via direct file open.
```

**Augmentation pattern for D-07** — add a "Dual-mode addendum" paragraph at the end of §11 body, cross-referencing #5:
```markdown
**Dual-mode addendum (v1.36):** The brand token lane now carries parity-verified
dark and light semantic values aligned to the shipped operator-surface token contract.
Pass condition extends to: `mix test test/threadline/brandbook_token_parity_test.exs`
exits 0 — value-equality on the intersection of named brand tokens, both modes.
See also dimension #5 (Dark/light versatility) for the asset-layer dual-mode proof.
```

---

### `.planning/REQUIREMENTS.md` (config/doc, CRUD)

**Traceability table** (`REQUIREMENTS.md` lines 57–80):
```markdown
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| THEME-01 | Phase 166 | Complete |
| THEME-02 | Phase 166 | Complete |
| THEME-03 | Phase 166 | Complete |
| THEME-04 | Phase 166 | Complete |
| TOKEN-01 | Phase 166 | Complete |
| TOKEN-02 | Phase 166 | Complete |
| TOKEN-03 | Phase 166 | Complete |
| COMP-01 | Phase 167 | Pending |
| COMP-02 | Phase 167 | Pending |
| A11Y-01 | Phase 168 | Complete |
| A11Y-02 | Phase 168 | Complete |
| EVID-01 | Phase 169 | Complete |
| EVID-02 | Phase 169 | Complete |
| BRAND-01 | Phase 170 | Pending |
| BRAND-02 | Phase 170 | Pending |
```

**Modification pattern:** Change `Pending` to `Complete` for `BRAND-01` and `BRAND-02`. Also update the requirement checkboxes at lines ~39–40 (the `[ ]` before `**BRAND-01**` and `**BRAND-02**` become `[x]`). Match the existing row format exactly — no column additions.

---

## Shared Patterns

### doc-contract literal-lock
**Source:** `test/threadline/operator_surface_doc_contract_test.exs`
**Apply to:** `test/threadline/brandbook_token_parity_test.exs`
```elixir
# Pattern: one File.read! per file at the top of each test, then String.contains? asserts.
# async: true is correct — all reads are pure filesystem, no DB.
test "brand book states the settled UI theming posture" do
  book = File.read!("brandbook/brand-book.md")
  assert String.contains?(book, "Dark-primary. Light is fully shipped and supported, enabled via host config")
  assert String.contains?(book, "theme: :system | :light | :dark")
  assert String.contains?(book, "THEME-TOGGLE-01")
end
```

### refute for exclusion drift
**Source:** `test/threadline/operator_surface_doc_contract_test.exs` lines 39–41
**Apply to:** `test/threadline/brandbook_token_parity_test.exs` exclusion assertions
```elixir
# Asserts the exclusion list: runtime-only tokens must NOT appear in tokens.json semantic block.
refute Map.has_key?(dark_tokens, "accent-soft"),
       "accent-soft is a runtime-only token and must not appear in the brand semantic block"
```

### milestone audit YAML front matter
**Source:** `.planning/milestones/v1.35-MILESTONE-AUDIT.md` lines 1–12
**Apply to:** `.planning/milestones/v1.36-MILESTONE-AUDIT.md`
Use `closeout_readiness: pending-uat` (not `yellow`, not `green`) to reflect D-11 — gate runs after Phase 170.

### mechanical suite comment style
**Source:** `brandbook/pressure-test.md` lines 14–38
**Apply to:** new mechanical parity gate line in `brandbook/pressure-test.md`
Format: `# Description sentence` on its own line, then the command, then `# must <outcome>` inline comment.

---

## No Analog Found

None. All target files have structural analogs in the codebase.

---

## Token Name Mapping Reference

The following brand-token names in `tokens.json` diverge from their `style.ex` CSS variable names. The parity test must account for this mapping:

| `tokens.json` key | `style.ex` CSS variable | Dark value (style.ex) |
|-------------------|------------------------|----------------------|
| `accent-text` | `--tl-color-on-accent` | `#08101F` |
| `text-muted` | `--tl-color-muted` | `#A3AFC2` |
| `text-soft` | `--tl-color-muted-soft` | `#8F9DB5` |
| `error-text` | `--tl-color-danger` | `#FF8585` |
| `logo-arc` | `--tl-color-logo-arc` (not in style.ex base — uses `--tl-color-accent-inset` area; actually comes from `brandbook/tokens.css` `--tl-color-logo-arc`) | see tokens.css |

Note: `style.ex` uses `--tl-color-muted` not `--tl-color-text-muted`; `tokens.css` emits `--tl-color-text-muted`. The parity test should parse `tokens.css` vars (which already follow the `--tl-color-*` naming) against `style.ex` vars directly.

---

## Metadata

**Analog search scope:** `test/threadline/`, `.planning/milestones/`, `brandbook/`, `lib/threadline/operator_surface/`
**Files scanned:** 10
**Pattern extraction date:** 2026-06-14
