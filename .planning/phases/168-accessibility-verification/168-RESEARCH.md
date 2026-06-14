# Phase 168: accessibility-verification - Research

**Researched:** 2026-06-13
**Domain:** WCAG 2.1 contrast verification as source-first Elixir test contracts (alpha-aware CSS token compositing) + Playwright light-lane affordance re-run
**Confidence:** HIGH (all findings verified against in-repo source; no external/training-only claims for the load-bearing math)

## Summary

Phase 168 is a verification/enforcement phase. It proves the existing Phase 166/167 light token lane is WCAG 2.1 accessible by turning the contrast and interaction-affordance guarantees into source-first test contracts in `style_contract_test.exs`, plus a Playwright re-run of the existing affordance spec under the light branch. It invents no tokens, colors, type, or layout. The deliverable is PROOF, not pixels.

The technical heart is the **alpha-aware compositing parser**. The current `color_tokens/1` helper (`style_contract_test.exs:1058-1062`) matches only `#RRGGBB` and silently drops every `rgba(...)` token — so status text is never actually measured against the tint background it paints over. Making the parser alpha-aware and compositing-aware (`effective = src.rgb*a + base.rgb*(1-a)` over the correct per-mode opaque base before luminance) unlocks the composited-tint rows the dark test cannot see. The WCAG relative-luminance and contrast-ratio math already exists in the test file (`relative_luminance/1`, `linear_channel/1`, `contrast_ratio/2` at `:1064-1091`) and is correct per WCAG 2.1 — it is **extended, not re-derived**.

**Primary recommendation:** Extend `color_tokens/1` into an alpha-aware parser that returns `{r,g,b,a}` tuples (or composites to opaque hex against a caller-named per-mode base), keep the existing `contrast_ratio/2` / `relative_luminance/2` math untouched, and add a light-lane mirror test that re-uses the dark test's structure across both the `[data-tl-theme="light"]` block (`style.ex:188-237`) and the `@media (prefers-color-scheme: light) [data-tl-theme="system"]` block (`style.ex:240-289`). For the e2e re-run, resolve the `theme: :dark` default tension (see Pitfall 1) before wiring a `colorScheme: "light"` Playwright project.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Playwright `colorScheme: 'light'` emulation** to re-run `operator-accessibility.spec.ts` against the existing operator surface, driving the `[data-tl-theme="system"]` light branch. Chosen over a dedicated `theme: :light` example-app route for zero example-app code footprint, verbatim spec reuse, and to prove the `:system` light render path. The re-run must assert the *same* affordance set (focus `box-shadow` non-`none`, chip border non-`0px`/non-`none`, `aria-current`, `aria-pressed`, dialog semantics, no horizontal overflow). **See Pitfall 1 — the example app mount currently defaults `theme: :dark`; this must be reconciled.**
- **D-02: Bounded alpha autonomy (carry Phase 167 D-04).** If a composited pair falls below 4.5:1 (or focus edge below 3:1), execution autonomously alpha/value-tunes the EXISTING light-lane tokens uniformly at the lane root (the `LIGHT-REVIEW.md` item-A pattern: strengthen `*-bg`/`*-border` alpha across all riders), never per-component, never a hue change. Both `light` and mirrored `system` branches edited in the same task. Execution does not pause for these in-lane tunes.
- **D-03: New-token halt (carry Phase 167 D-05).** A genuinely new hue, primitive, or any value NOT derivable from the existing 45-token lane is FLAGGED and PAUSES for a user decision — never silently invented.
- **D-04: Disabled-text strict-by-default, bounded exemption fallback.** Assert `--tl-color-muted-soft` at 4.5:1 against `surface`/`surface-raised` in both modes. ONLY if a tune cannot reach 4.5:1 without breaking the "disabled looks disabled" read may the planner downgrade the disabled-token rows ONLY to "exempt — documented" with an explicit code comment citing WCAG 1.4.3 (inactive controls). No other contrast row is exemptable.

### Claude's Discretion

- **Parser placement** — extend `color_tokens/1` in place vs. add a sibling alpha-aware parser (the SPEC permits either), provided it parses `#RRGGBB`, `rgba(r,g,b,a)` (and `#RRGGBBAA` if any appear) and composites translucent tokens over the correct per-mode opaque base (`#141B2D`/`#FFFFFF` for surface tints, page bg for page-level) before luminance math.
- **Exact form/organization** of the new contract assertions and the light-mirror token-pair table within `style_contract_test.exs`, provided every row in the SPEC's "Token pairs the mirror MUST assert" table is covered in both modes.
- **Lowest-friction wiring** of the Playwright `colorScheme` re-run (new spec project/config vs. parameterized existing spec), provided the same affordance set is asserted.

### Deferred Ideas (OUT OF SCOPE)

- `__light__` screenshot baseline lane + example-app `theme: :system` demonstration + adopter docs → **Phase 169** (appearance proof; this phase proves behavior/affordance only).
- Brandbook `tokens.json` / `tokens.css` 45-token parity → **Phase 170**.
- `coverage-schema-card-declutter.md` (item C), `theme-picker-idiomatic-ui.md` (item D, blocked by `[165-01]` theme-toggle ban), `transaction-page-left-push-desktop.md` (item E) — none are a11y-verification scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| A11Y-01 | Style contract gains a light-lane AA contrast mirror test (with alpha-aware token parsing in `color_tokens/1`); no text-bearing token falls below WCAG AA in either mode. | Parser gap confirmed at `:1058-1062` (hex-only regex drops `rgba`); compositing formula + per-mode bases enumerated below; token-pair table from UI-SPEC mapped to source token values; existing luminance math at `:1073-1091` is correct and reusable. |
| A11Y-02 | Focus-visible and interaction states (hover/active/disabled/selected) verified per mode; focus ring meets non-text 3:1 on both backgrounds. | Focus-ring token shapes confirmed (`style.ex:157` dark / `:236` light); 1px solid edge = `--tl-color-border-focus`; `:focus-visible` restore guard at `style.ex:350-356` + behavioral test at `:688-714`; interaction-state source anchors verified; e2e affordance set enumerated from `operator-accessibility.spec.ts`. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| AA contrast mirror (A11Y-01) | Test layer (`style_contract_test.exs` reading `style.ex`) | — | Source-first contract; the test parses CSS source directly. No runtime tier involved. |
| Alpha-aware compositing parser | Test layer (helper fn) | — | Pure parsing/math helper inside the test module; not library runtime. |
| Focus-ring 3:1 (A11Y-02 p1) | Test layer (source assert) | — | Asserted in-source against token values; the existing `:focus-visible` behavioral guard already lives in the test. |
| Interaction-state per-mode deltas (A11Y-02 p2) | Test layer (source assert) | E2E layer (Playwright) | Source asserts token-backed rules resolve to a delta; the affordance suite proves runtime behavior under the light branch. |
| e2e light-lane affordance re-run | E2E layer (Playwright spec/project) | Example-app mount (theme wiring) | Browser proves focus/chip/aria affordances are mode-independent; requires the served surface to resolve the light branch (see Pitfall 1). |
| Any contrast fix (D-02) | Library CSS (`style.ex` light + system lanes) | Test layer (assertion lands same wave) | Additive light-lane token-alpha tune; moves with its assertion per the 166 D-05 same-wave rule. |

## Standard Stack

No new packages. This phase is pure verification using existing project infrastructure.

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| ExUnit | bundled w/ Elixir | Source-first contract assertions | Established `style_contract_test.exs` pattern (phase 143) |
| `@playwright/test` | `^1.52.0` (already in `e2e/package.json`) | Light-lane affordance re-run | Existing e2e harness; `colorScheme` is a first-class `use` option |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `mix verify.test` / `mix test` | project alias | Run the contract test | Per-task + phase gate (CLAUDE.md canonical entrypoint) |
| `examples/threadline_phoenix/e2e/run-e2e.sh` | in-repo | Boot example app + run Playwright | The e2e re-run driver |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| In-source contrast math | Runtime `axe-core` / contrast library | EXPLICITLY FORBIDDEN by UI-SPEC Hard Constraint 1 — no runtime axe dependency added to the library. Source-first only. |
| `colorScheme: "light"` Playwright project (D-01) | Dedicated `theme: :light` example route | SPEC lists the dedicated route first; D-01 selects emulation as lowest-friction. But emulation requires the served mount to resolve `:system` (see Pitfall 1). |

**Installation:** None. All tooling present.

## Package Legitimacy Audit

Not applicable — this phase installs zero external packages. The library adds no runtime dependency (Hard Constraint 1). Playwright `^1.52.0` is already present in `examples/threadline_phoenix/e2e/package.json` and is unchanged by this phase.

## Architecture Patterns

### System Architecture Diagram

```
                         A11Y-01 / A11Y-02 part 1 (source-first)
  style.ex (CSS source)
    ├─ .threadline-ui base block (DARK tokens)   ── frozen; byte-stable; phase-143 test
    ├─ [data-tl-theme="light"] block  (:188-237) ─┐
    └─ @media(prefers-color-scheme:light)         │  light token values
         [data-tl-theme="system"]   (:240-289) ───┘
              │
              │  File.read! + selector_block!(block) + alpha-aware color_tokens/1
              ▼
  style_contract_test.exs
    ├─ parse #RRGGBB | rgba(r,g,b,a)  →  {r,g,b,a}
    ├─ composite translucent token over PER-MODE opaque base
    │     effective = src.rgb*a + base.rgb*(1-a)
    ├─ relative_luminance/1 (existing, WCAG 2.1)  ── UNCHANGED
    ├─ contrast_ratio/2 (existing)                ── UNCHANGED
    └─ assert >= 4.5 (text) | >= 3.0 (focus edge), in BOTH light + system blocks

                         A11Y-02 part 2 (runtime affordance)
  operator-accessibility.spec.ts (existing assertions, verbatim)
              │  re-run under colorScheme:"light"  →  served surface must resolve
              ▼                                        [data-tl-theme="system"] light branch
  example app /audit operator surface (Playwright Desktop Chrome)
    └─ assert: focus box-shadow != none, chip border != 0px/none,
               aria-current, aria-pressed, dialog semantics, no h-overflow
```

### Pattern 1: Per-mode block extraction before token parsing
**What:** Extract the specific theme block from `style.ex` source, then run `color_tokens/1` over only that block, so light/system tokens don't collide with dark base tokens (which share names).
**When to use:** For every light/system assertion. The dark test uses `selector_block!(src, ".threadline-ui")` (`:658`) to scope to the base block. Mirror with `selector_block!(src, ~s|.threadline-ui[data-tl-theme="light"]|)` and a `@media`-scoped extraction for the system branch.
**Note:** `selector_block_pattern/2` (`:1054`) is a `[^}]*` non-nested matcher — it stops at the FIRST `}`. The `@media (prefers-color-scheme: light)` wrapper is a nested block, so `selector_block!` cannot extract the `[data-tl-theme="system"]` block directly through the media wrapper. The planner must extract the system block via a media-aware split (see `media_section/2` at `:1010` for the existing `@media (min-width:)` precedent), or split on `@media (prefers-color-scheme: light) {` then `selector_block!` the inner selector. This is a known parsing-helper constraint, not a blocker.

### Pattern 2: Alpha-aware compositing (the technical heart)
**What:** A token like `--tl-color-danger-bg: rgba(163, 52, 52, 0.10)` is the *visible* background a status pill's text sits on only after compositing over the panel surface. The text (`--tl-color-danger: #A33434`, opaque) must be measured against `composite(danger-bg, surface)`, not against raw `#FFFFFF`.
**Formula (per channel, alpha in 0..1):** `effective = round(src*a + base*(1-a))`, applied to R, G, B independently, base fully opaque.
**Per-mode opaque base selection (caller-named, never assumed single base):**

| Composited token | Light base | Dark base |
|------------------|-----------|-----------|
| `*-bg` status tints over a panel | `--tl-color-surface` = `#FFFFFF` | `--tl-color-surface` = `#141B2D` |
| `accent-soft` / `accent-wash` over raised | `--tl-color-surface-raised` = `#EEF3FA` | `#1B253A` |
| Page-level washes | `--tl-color-bg` = `#F7F9FC` | `#0B1020` |
| Focus halo (reported only) | over control surface | over control surface |

**Example (Elixir-shaped; verify exact arithmetic in test):**
```elixir
# Source pattern: extends existing relative_luminance/1 (style_contract_test.exs:1073)
# Parse rgba into {r,g,b,a}; composite over an opaque base hex; feed existing luminance math.
defp composite({r, g, b, a}, base_hex) do
  {br, bg, bb} = hex_to_rgb(base_hex)
  blend = fn s, base -> round(s * a + base * (1 - a)) end
  "#" <> Enum.map_join([{r, br}, {g, bg}, {b, bb}], "", fn {s, base} ->
    blend.(s, base) |> Integer.to_string(16) |> String.pad_leading(2, "0")
  end)
end
# Opaque hex passes through unchanged; result feeds contrast_ratio/2 verbatim.
```

### Pattern 3: Dual-branch additive discipline (166/167)
**What:** Every light override edits BOTH `[data-tl-theme="light"]` and the mirrored `@media (prefers-color-scheme: light) [data-tl-theme="system"]` block in the same task. The mirror test asserts BOTH. Currently those two blocks are byte-identical in token values (`style.ex:188-237` vs `:240-289`) — confirmed by reading.
**When to use:** Any D-02 token tune. Never edit one branch without the other.

### Anti-Patterns to Avoid
- **Re-deriving the luminance math:** The existing `relative_luminance/1` + `linear_channel/1` (`:1073-1091`) is correct WCAG 2.1 (sRGB linearization threshold `0.03928`, coefficients `0.2126/0.7152/0.0722`). Extend the PARSER, not the math.
- **Editing dark tokens or base rules:** Hard Constraint 2 — dark byte-stability. The phase-143 dark test (`:653`) and frozen-hex catalog must pass unchanged.
- **Per-component contrast fixes:** D-02 requires uniform lane-root token-alpha tunes. A per-selector override is a TOKEN-02 violation.
- **Assuming a single composite base across modes:** UI-SPEC §"parsing gap" step 3 — dark text-on-tint composites over `#141B2D`, light over `#FFFFFF`. Name the base per mode.
- **Masking a focus failure with the halo:** Assert the opaque 1px `border-focus` edge for the 3:1 pass/fail; composite-and-REPORT the translucent 3px halo, never let a low-alpha halo carry the pass.
- **Granting the WCAG large-text 3:1 carve-out:** Threadline holds ALL text-bearing tokens (incl. ≥18px headings) to 4.5:1, matching the dark contract.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Relative luminance / contrast ratio | New WCAG math | Existing `relative_luminance/1`, `contrast_ratio/2` (`:1064-1091`) | Already correct WCAG 2.1; re-deriving risks divergence from the dark test |
| Runtime contrast checking | axe-core / pa11y in the library | In-source assertions reading `style.ex` | Hard Constraint 1 forbids runtime axe dependency |
| Theme block extraction | Bespoke CSS parser | `selector_block!/2` + `media_section/2` precedent (`:1010,1045`) | Existing helpers; only the media-wrapper nesting needs care (Pattern 1) |
| Affordance assertions for light | New Playwright assertions | Re-run `operator-accessibility.spec.ts` verbatim | D-01 + UI-SPEC require the SAME affordance set, proving mode-independence |

**Key insight:** Almost everything needed already exists in-repo. The single genuinely new piece of logic is the alpha-aware parse + composite step bolted onto the existing luminance pipeline. Everything else is mirroring an existing pattern across two new CSS blocks.

## Runtime State Inventory

This is a test/contract + e2e-config phase, not a rename/migration. No stored data, live-service config, OS-registered state, or secrets are renamed or migrated.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB keys/collections touched. | None |
| Live service config | None — no external services reconfigured. | None |
| OS-registered state | None. | None |
| Secrets/env vars | E2E reads `DEMO_SEED_PASSWORD`, `E2E_BASE_URL`, `THREADLINE_E2E` (existing, unchanged). | None — referenced, not renamed |
| Build artifacts | None — no package rename; `examples/.../e2e/node_modules` unchanged (no new dep). | None |

**Nothing found in any migration category — verified by reading the phase scope (test + e2e config only) and confirming no `style.ex` token NAMES change (only possibly alpha values under D-02).**

## Common Pitfalls

### Pitfall 1: D-01 "zero example-app footprint" collides with the `theme: :dark` default (HIGH-IMPACT — planner must resolve)
**What goes wrong:** D-01 says re-run the spec under `colorScheme: "light"` to drive the `[data-tl-theme="system"]` light branch with zero example-app code footprint. But the example app's single operator-surface mount (`examples/.../router.ex:174` `threadline_operator_surface("/")`) does NOT pass `theme:`, so `Auth.on_mount` defaults `theme = :dark` (`auth.ex:14`, `normalize_theme/1` `:177-179`). The rendered root is `data-tl-theme="dark"` regardless of browser `prefers-color-scheme`. **`colorScheme: "light"` alone will render the DARK lane** — the `[data-tl-theme="system"]` light branch only activates when the served surface is mounted with `theme: :system`.
**Why it happens:** The CSS `@media (prefers-color-scheme: light)` rule only matches the `[data-tl-theme="system"]` selector; with `data-tl-theme="dark"` no light branch exists.
**How to resolve (planner decision — three options, all small):**
1. Change the example mount to `theme: :system` (one line in `examples/.../router.ex`). Then `colorScheme: "light"` resolves the light branch. **BUT** this flips the example app's default for ALL existing e2e runs to system (dark under default `colorScheme`, which Playwright defaults to `light`/`no-preference` per platform — verify) — a behavior change that touches the deferred Phase-169 "example-app `theme: :system` demonstration" lane. Risk: scope bleed into 169.
2. Add a dedicated test-only route mounted with `theme: :system`, run the light spec against it. Small example-app footprint (a route), keeps the default mount dark. This is the SPEC's first-listed option in spirit.
3. Gate the mount theme on an env var (e.g. `THREADLINE_E2E_THEME`) so the existing dark runs stay dark and a second Playwright project sets `colorScheme: "light"` + the env to `:system`. Zero default-behavior change; small config footprint.
**Recommendation:** Option 3 or 2 — preserve the existing dark e2e default, add a narrowly-scoped light path. Flag to the user that strict "zero example-app footprint" is not literally achievable given the `:dark` default; the minimal footprint is one route or one env-gated theme line. This is a D-01 reconciliation, not a D-03 halt (no new token), but it IS a planning decision worth surfacing.
**Warning signs:** Light e2e "passes" but computed focus-ring/chip colors are the dark values → the surface never entered the light branch.

### Pitfall 2: `selector_block!` cannot extract the system block through the `@media` wrapper
**What goes wrong:** `selector_block_pattern/2` uses `[^}]*` (non-nested). Calling `selector_block!(src, ~s|.threadline-ui[data-tl-theme="system"]|)` against the full source stops at the first inner `}` of the media block or mismatches.
**How to avoid:** Split on `"@media (prefers-color-scheme: light) {"` first (mirror `media_section/2` at `:1010`), then `selector_block!` the inner `[data-tl-theme="system"]` selector within that slice. The `[data-tl-theme="light"]` block at `:188-237` is top-level and extracts cleanly.
**Warning signs:** System-branch token map is empty or missing tokens vs the light-branch map.

### Pitfall 3: Compositing the wrong base, or compositing opaque text
**What goes wrong:** Compositing a status-tint `*-bg` over the page `--tl-color-bg` instead of the panel `--tl-color-surface`, or attempting to composite an opaque text hex (no alpha).
**How to avoid:** Per the per-mode base table above, status pills sit on `surface`, not page bg. All `*-text`/`danger`/`accent-strong` tokens are opaque hex (verified: `style.ex:201-227`) — pass them through unchanged. Per UI-SPEC step 2, if any translucent TEXT token ever appears, composite it over its background AND flag it (none exist today).
**Warning signs:** A composited ratio that's suspiciously high (text measured against page bg, which is lighter than the tinted surface) — a false pass.

### Pitfall 4: Touching the uncommitted nav-overhaul lane
**What goes wrong:** The working tree has ~29 modified files (the nav-overhaul lane, incl. 3 pre-existing test failures). Staging/editing/reverting any of them violates the standing v1.36 caution (STATE.md:75).
**How to avoid:** Touch ONLY `style_contract_test.exs`, `style.ex` (light/system blocks only, if D-02 fires), and the Playwright config/spec wiring. When running `mix test`, scope to the contract test file to avoid conflating the 3 known nav-lane failures with this phase's results.
**Warning signs:** `git status` showing a nav-lane file newly staged by your tooling.

### Pitfall 5: Expecting failures where Phase 167 already fixed them
**What goes wrong:** Treating a green-on-arrival mirror as suspicious. Phase 167 already fixed the two known light failures: LIGHT-REVIEW item A (danger/warning tint strength on white, uniform lane-root `*-bg`/`*-border` alpha) and item B (coverage `.tl-table` hover polarity, `style.ex:299-315`).
**How to avoid:** A green mirror is the EXPECTED outcome. D-02/D-03 exist only for anything the formal math NEWLY surfaces. Don't manufacture a fix.
**Warning signs:** Re-tuning danger/warning tints that already pass — that's re-litigating 167.

## Code Examples

### Existing WCAG math to extend (DO NOT rewrite)
```elixir
# Source: style_contract_test.exs:1064-1091 (verified in-repo, WCAG 2.1 correct)
defp contrast_ratio(foreground, background) do
  fg = relative_luminance(foreground)
  bg = relative_luminance(background)
  (max(fg, bg) + 0.05) / (min(fg, bg) + 0.05)
end

defp relative_luminance("#" <> hex) do
  [r, g, b] =
    hex |> String.graphemes() |> Enum.chunk_every(2)
    |> Enum.map(fn pair ->
      pair |> Enum.join() |> String.to_integer(16) |> Kernel./(255) |> linear_channel()
    end)
  0.2126 * r + 0.7152 * g + 0.0722 * b
end

defp linear_channel(c) when c <= 0.03928, do: c / 12.92
defp linear_channel(c), do: :math.pow((c + 0.055) / 1.055, 2.4)
```

### Existing parser gap to close
```elixir
# Source: style_contract_test.exs:1058-1062 — HEX-ONLY, drops every rgba(...)
defp color_tokens(src) do
  ~r/(--tl-color-[a-z-]+):\s*(#[0-9a-fA-F]{6});/
  |> Regex.scan(src)
  |> Map.new(fn [_match, token, hex] -> {token, hex} end)
end
# Extend: also match  rgba\(\s*(\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\s*\)
# and (if any appear) #RRGGBBAA. Return {r,g,b,a} for translucent tokens;
# composite to opaque hex against a caller-named per-mode base before contrast_ratio/2.
```

### Existing dark contrast assertion to mirror
```elixir
# Source: style_contract_test.exs:653-686 — the structure to mirror per light + system block
tokens = src |> selector_block!(".threadline-ui") |> color_tokens()
for text_token <- [...], background_token <- backgrounds do
  assert contrast_ratio(tokens[text_token], tokens[background_token]) >= 4.5
end
```

### Focus-ring token shapes (verified)
```css
/* dark — style.ex:157 */
--tl-focus-ring: 0 0 0 3px rgba(127, 169, 255, 0.42), 0 0 0 1px var(--tl-color-border-focus);
/* light — style.ex:236 (and system :288, byte-identical) */
--tl-focus-ring: 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus);
/* 1px solid edge = --tl-color-border-focus  (#7FA9FF dark / #1557C0 light) → assert 3:1 vs surface + surface-raised */
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hex-only contrast parse (drops rgba) | Alpha-aware compositing parse | This phase (168) | Composited-tint rows become measurable for the first time |
| Dark-only contrast contract (phase 143) | Dark + light + system mirror | This phase | Both lanes provably AA |
| Affordances proven dark-only | Affordances re-run under light branch | This phase (D-01) | Mode-independence of focus/chip/aria proven |

**Deprecated/outdated:** None. This phase is additive over a 2026-current codebase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Playwright defaults `colorScheme` to the platform/`"light"`; the dark e2e runs currently rely on the served `data-tl-theme="dark"` to stay dark regardless of emulation. The exact default depends on Playwright `^1.52.0` behavior. | Pitfall 1 | If the default already emulates light, existing runs are still dark only because the mount is `:dark` — strengthens Pitfall 1's conclusion. Verify with `npx playwright test` config introspection during planning. |
| A2 | The `[data-tl-theme="light"]` and `[data-tl-theme="system"]` token blocks are byte-identical in values today (so D-02 must edit both to keep them so). | Pattern 3 | Verified by reading `style.ex:188-237` vs `:240-289` — they match. Low risk; re-confirm if 167 nav-lane edits touched them (they are not in the nav-overhaul lane). |
| A3 | No translucent TEXT tokens exist (all `*-text`/`danger`/`accent-strong` are opaque hex). | Pitfall 3 | Verified by reading the light block; if a future token is translucent, UI-SPEC step 2 says composite-and-flag. Low risk. |

## Open Questions

1. **e2e light-branch activation mechanism (the only real design choice).**
   - What we know: D-01 wants `colorScheme: "light"` + `[data-tl-theme="system"]`; the mount defaults `theme: :dark`.
   - What's unclear: whether to flip the example mount to `:system`, add a test route, or env-gate the theme (Pitfall 1 options 1-3).
   - Recommendation: env-gated theme (option 3) or dedicated route (option 2) to preserve the existing dark e2e default and avoid bleeding into Phase 169's `theme: :system` demonstration lane. Surface to the user as a D-01 reconciliation; it is NOT a D-03 new-token halt.

2. **Disabled-text `muted-soft` 4.5:1 outcome.**
   - What we know: light `--tl-color-muted-soft: #73819C` on `#FFFFFF` / `#EEF3FA`; D-04 asserts 4.5:1 strict-by-default.
   - What's unclear: whether `#73819C` clears 4.5:1 on `#EEF3FA` (the raised surface) — borderline (mid-grey on light grey).
   - Recommendation: Let the math decide. If it fails AND a uniform tune can't reach 4.5:1 without breaking the "disabled looks disabled" read, apply the D-04 bounded exemption (disabled rows ONLY, with WCAG 1.4.3 code comment). Do not pre-exempt.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix + ExUnit | contract test | ✓ (project) | project mix | — |
| `@playwright/test` | e2e re-run | ✓ | `^1.52.0` (`e2e/package.json`) | — |
| PostgreSQL | e2e app boot (`run-e2e.sh` `DB_HOST/PORT`) | assumed (existing e2e harness) | — | — |
| Playwright browsers (Chromium) | e2e | assumed (existing e2e harness) | — | `npx playwright install` if absent |

**Missing dependencies with no fallback:** None identified. The e2e harness already runs in this repo (existing spec + `run-e2e.sh`).
**Note:** The contract-test deliverable (A11Y-01 + A11Y-02 part 1) has NO external dependency — pure Elixir source assertions. Only the A11Y-02 part 2 e2e re-run needs the browser/DB harness, which already exists.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework (contract) | ExUnit (`use ExUnit.Case, async: true`) |
| Config file (contract) | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| Full suite command | `mix verify.test` (or `mix ci.all` for format+credo+test) |
| Framework (e2e) | Playwright `^1.52.0` |
| E2E run command | `bash examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-accessibility.spec.ts` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| A11Y-01 | Every text-bearing token ≥ 4.5:1 in light + system, incl. status text composited over its own tint | unit (source) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ extend existing |
| A11Y-01 | `color_tokens/1` (or sibling) parses `#RRGGBB` + `rgba(...)` and composites over per-mode base | unit (source) | same | ✅ extend (`:1058-1062`) |
| A11Y-02 p1 | Focus 1px `border-focus` edge ≥ 3:1 vs `surface`/`surface-raised`, both modes; translucent halo reported | unit (source) | same | ✅ extend |
| A11Y-02 p1 | `outline:none` blanket forbidden; `:focus-visible` restores `--tl-focus-ring` per mode | unit (source) | same (`phase 143 focus` test `:688`) | ✅ holds, re-confirm per mode |
| A11Y-02 p2 | Hover/active/disabled/selected resolve to perceptible delta per mode; coverage-hover polarity holds (`:299-315`) | unit (source) | same | ✅ extend |
| A11Y-02 p2 | Affordance set (focus box-shadow≠none, chip border≠0px/none, aria-current, aria-pressed, dialog, no h-overflow) holds under light branch | e2e | `bash examples/.../e2e/run-e2e.sh tests/operator-accessibility.spec.ts` (light project) | ✅ re-run existing spec |
| Guard | Dark byte-stability: phase-143 dark test + frozen-hex catalog pass unchanged | unit (source) | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ must stay green |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/style_contract_test.exs` (+ `mix format --check-formatted`)
- **Per wave merge:** `mix verify.test` (full Elixir suite) — scope-aware of the 3 known nav-lane failures (do not conflate)
- **Phase gate:** Full contract test green in both modes + dark test unchanged + e2e affordance re-run green under the light branch, before `/gsd:verify-work`

### Observable proof that closes each requirement
- **A11Y-01 closed:** `style_contract_test.exs` carries a light + system AA mirror with alpha-aware/compositing parsing; `mix test` shows every text-bearing token ≥ 4.5:1 in both modes incl. composited status-on-tint rows; dark test still green.
- **A11Y-02 part 1 closed:** source assertions show the 1px `border-focus` edge ≥ 3:1 on `surface` and `surface-raised` in both modes; the `:focus-visible` restore guard asserts per mode.
- **A11Y-02 part 2 closed:** per-mode interaction-state deltas asserted in source; `operator-accessibility.spec.ts` re-run under the light branch passes the same affordance set.

### Wave 0 Gaps
- [ ] Resolve the D-01 e2e light-branch activation mechanism (Pitfall 1 / Open Question 1) BEFORE wiring the Playwright project — this is a prerequisite, not a code gap.
- [ ] No new test FILES needed — all assertions extend `style_contract_test.exs` and re-run `operator-accessibility.spec.ts`. No `conftest`/fixture equivalent needed.
- [ ] No framework install — ExUnit + Playwright present.

*(Net: the only Wave-0 prerequisite is the D-01 mechanism decision; otherwise existing infra covers all requirements.)*

## Security Domain

This phase is a verification/test + e2e-config change with no new attack surface: no new packages, no runtime dependency, no new routes serving user input (option 2/3 test routes, if chosen, are auth-gated example-app routes mirroring the existing `/audit` mount). ASVS categories largely N/A.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth logic changed; e2e re-uses existing `login()` flow |
| V3 Session Management | no | Unchanged |
| V4 Access Control | no | Operator surface authorize_fn unchanged; any test route inherits existing `:operator_auth` pipeline |
| V5 Input Validation | no | No new user input; CSS source parsing is over a trusted in-repo file |
| V6 Cryptography | no | None |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Test route leaking unauthenticated operator data (if option 2 chosen) | Information disclosure | Mount any e2e light route behind the same `:operator_browser`/`:operator_auth` pipeline as `/audit`; or prefer env-gated theme (option 3) with no new route |

**Primary security note:** Accessibility IS a security-adjacent correctness property here (focus visibility prevents keyboard-user lockout). The phase strengthens it. No new secrets, no new network calls, no new dependencies.

## Sources

### Primary (HIGH confidence — in-repo, read directly this session)
- `lib/threadline/operator_surface/style.ex` — dark base block (tokens `:56-113`, focus ring `:157`), light block (`:188-237`), system block (`:240-289`), coverage-hover override (`:299-315`), `:focus-visible` restore (`:350-356`)
- `test/threadline/operator_surface/style_contract_test.exs` — theme-aware + theme-toggle-ban assertions (`:8-30`), dark contrast test (`:653-686`), focus/non-color guard (`:688-735`), `color_tokens/1` (`:1058-1062`), WCAG math (`:1064-1091`), `selector_block!`/`media_section` helpers (`:1010-1056`)
- `lib/threadline/operator_surface/auth.ex` — `theme` default `:dark` (`:14`), `normalize_theme/1` (`:177-179`)
- `lib/threadline/operator_surface/router.ex` — `theme` opt threading + default `:dark` (`:52-71`)
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — operator mount with NO `theme:` opt (`:174-187`)
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` — full affordance set
- `examples/threadline_phoenix/e2e/playwright.config.ts` — projects (chromium/desktop/mobile), `use` options, `reducedMotion`
- `.planning/phases/168-accessibility-verification/168-UI-SPEC.md` — locked verification contract
- `.planning/phases/168-accessibility-verification/168-CONTEXT.md` — D-01..D-04 decisions
- `.planning/phases/167-component-retune/LIGHT-REVIEW.md` — item A (uniform lane-root tint-alpha tune) + item B fix patterns
- `.planning/STATE.md` — `[165-01]` theme-toggle ban (`:108`), nav-overhaul standing caution (`:75`)
- `.planning/REQUIREMENTS.md` — A11Y-01 / A11Y-02 (`:29-30`)
- `./CLAUDE.md` — `mix verify.*` / `mix ci.all` canonical entrypoints, three-layer architecture, dual-branch discipline

### Secondary (MEDIUM)
- WCAG 2.1 SC 1.4.3 (text 4.5:1), SC 1.4.11 (non-text 3:1), 1.4.3 inactive-control exemption — encoded literals confirmed against the existing test's correct implementation (no external fetch needed; the math is already in-repo and matches the W3C formula).

### Tertiary (LOW)
- None — no unverified web claims load-bearing in this research.

## Project Constraints (from CLAUDE.md)

- Use `mix verify.*` / `mix ci.*` named entrypoints in CI/docs, not ad-hoc commands. Cite `mix test test/threadline/operator_surface/style_contract_test.exs` for the targeted run.
- `mix compile --warnings-as-errors` and `mix format --check-formatted` must pass.
- Honest default tests: do not silently exclude suites without updating `test/test_helper.exs` + docs together.
- Three-layer architecture respected — this is exploration/operations-layer (operator surface) UI verification; do not conflate with capture/semantics layers.
- Doc-contract tests stay aligned (the source-first `style_contract_test.exs` IS the contract; keep it the SSOT).
- GSD `state.begin-phase` uses POSITIONAL args (`phase`, `slug`, `plan_count`) — flag-style invocations can corrupt STATE.md.
- Standing caution: never stage/edit/revert the uncommitted nav-overhaul lane (~29 files, 3 known failures).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all tooling read in-repo
- Architecture (parser/compositing/mirror): HIGH — exact source lines verified; math already correct in-repo
- Pitfalls: HIGH — Pitfall 1 (theme default) confirmed by reading `auth.ex` + example `router.ex`; Pitfall 2 (media-wrapper extraction) confirmed by reading `selector_block_pattern/2`
- e2e wiring decision: MEDIUM — the mechanism is a genuine planner choice (3 viable options); Playwright `colorScheme` default behavior (A1) worth a 30-second introspection during planning

**Research date:** 2026-06-13
**Valid until:** ~2026-07-13 (stable in-repo target; only the nav-overhaul lane landing could shift line numbers — re-grep anchors if it merges)
