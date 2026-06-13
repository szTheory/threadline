# Phase 167: component-retune - Research

**Researched:** 2026-06-13
**Domain:** CSS additive light-lane retune + source-contract testing (Elixir/Phoenix LiveView operator surface)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 Review-first.** User eyeballs the *current* Phase 166 token-recolor rendered live across `:dark` / `:light` / `:system` BEFORE override-authoring. That review produces the disposition list (pass/fail per family) that drives which override tasks exist. Satisfies the STATE human gate ("eyeball the rendered light surface before retune effort is spent") and the UI-SPEC confirm-first default.
- **D-02.** The planner MUST structure the live review as an explicit *early gate* whose output (the proven fail-list) is the input to the override-authoring tasks — NOT an end-of-phase check.
- **D-03 Confirm-strict.** Author an additive override ONLY for families the live review proves fail. No pre-judging. The flagged high-risk trio (#1 glass topbar, #5 drawer scrim, #8 home-card signal-line) get explicit review but are NOT pre-authored.
- **D-04 Bounded alpha autonomy.** Pre-authorize bounded alpha tuning of *existing* tokens (e.g. lowering glass `surface-tint` alpha, bumping `backdrop` scrim alpha) — UI-SPEC calls this "still additive." Execution proceeds without pausing. (Blur radii may reuse `--tl-blur-*`.)
- **D-05.** A genuinely NEW token (new hue, new non-blur primitive, any value not derivable from the 45-token lane) is FLAGGED and PAUSES for a user decision — not silently invented.
- **D-06.** Proof = BOTH a source-contract test AND a committed review checklist.
- **D-07 Source-contract test** — extend `style_contract_test.exs` to assert: (a) each authored light override selector is present in the light lane, and (b) **no stray per-component `[data-tl-theme="light"]` selector exists for the ~20 tint-riders**. CI guard for the TOKEN-02 "out of contract unless proven" invariant.
- **D-08 Committed review checklist** (`LIGHT-REVIEW.md` or equivalent in the phase dir) records per-family disposition for the ~9 families and named-criteria pass/override-needed outcome for each data-viz surface (coverage / timeline / diff).

### Claude's Discretion
- Exact name/location of the review-checklist artifact (must live in phase dir, record dispositions explicitly).
- Exact form of the new `style_contract_test.exs` assertions, provided they prove D-07 (a) and (b) against the `style.ex` source.
- Internal organization of the additive override blocks within `style.ex`.

### Deferred Ideas (OUT OF SCOPE)
- Screenshot `__light__` baseline lane — Phase 169 (visual proof backstop).
- AA contrast mirror test + focus-visible/interaction-state a11y audit — Phase 168.
- Brandbook `tokens.json` / `tokens.css` 45-token parity — Phase 170.
- Example-app `theme: :system` demonstration + adopter docs — Phase 169.
- Runtime theme-toggle UI, segmented control, or theme settings surface (the `theme-toggle` ban is permanent).
- The uncommitted nav-overhaul lane (~29 files; incl. its 3 pre-existing failures) — never stage, edit, or revert.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-01 | The ~9 dark-effect component families (glass chrome ×4, drawer scrim + shadow, focus glow, home-card signature effects, shell-nav inset) render correctly on light with explicitly designed treatments. | Architectural Responsibility Map + Family Source-Anchor Inventory (all 9 anchors verified by file:line); additive-override mechanism (166 D-03) documented with exact dual-branch shape; Don't Hand-Roll table; Pitfalls. |
| COMP-02 | Data-viz-adjacent surfaces (coverage, timeline, diff) pass an explicit light-mode design review — no dark-tuned content shipped unreviewed (the Grafana lesson). | Data-Viz Review Criteria (from UI-SPEC §Data-Viz), live-render mechanism for the review gate, committed-checklist artifact pattern (D-08), Validation Architecture mapping each criterion to checklist vs deferred screenshot lane. |
| TOKEN-02 (verify-only) | The ~20 tint-riders resolve through the shared status-tint system without per-component overrides. | Tint-Rider Inventory (7 families, anchors verified); D-07(b) absence-assertion shape; current baseline confirmed (exactly 1 `data-tl-theme="light"` occurrence in source = the lane selector itself, zero per-component). |
</phase_requirements>

## Summary

Phase 167 is a **retune + verification** phase, not greenfield design. Phase 166 already shipped a complete 45-token light lane (`style.ex:187–235`) plus a mirrored `@media (prefers-color-scheme: light)` system branch (`:237–287`). The base `.threadline-ui` block stays dark (`:19–185`, `color-scheme: dark`). This phase does NOT re-derive tokens — it confirms-or-overrides ~9 dark-effect families on light, verifies ~20 tint-riders resolve through shared tokens, and runs an explicit light-mode design review of the coverage/timeline/diff data-viz surfaces.

The work is unusually well-specified. The approved `167-UI-SPEC.md` is a locked design contract that pre-states, per family, the *light intent* and the *exact additive treatment* — and every source anchor it cites was independently verified during this research (all 14 file:line claims land exactly on the named selector). The mechanism is fully established by Phase 166: every override is an additive `.threadline-ui[data-tl-theme="light"]` rule PLUS a mirrored `@media (prefers-color-scheme: light) .threadline-ui[data-tl-theme="system"]` rule, written in the **same task**. No base `.tl-*` rule is ever rewritten; no dark token value is ever touched (byte-stability is CI-enforced by `style_contract_test.exs`).

The single material gap is *operational*, not informational: the review-first gate (D-01/D-02) requires rendering the surface live in all three theme modes, but the example app currently mounts the operator surface with the default `:dark` theme (`examples/.../router.ex:174`, no `theme:` option). The planner must give the reviewer a concrete way to see `:light` and `:system` without permanently editing the example router (the example `theme: :system` demo itself is deferred to Phase 169).

**Primary recommendation:** Structure the plan as four sequenced concerns: (1) an **early live-review gate** that renders `:dark`/`:light`/`:system` and produces a committed `LIGHT-REVIEW.md` disposition fail-list; (2) **confirm-strict override authoring** for ONLY the proven failures, each editing both the `light` and `system` branches in one task, anchored to existing tokens (alpha tuning autonomous per D-04; new tokens FLAG+PAUSE per D-05); (3) the **data-viz design review** recorded against the UI-SPEC named criteria in the same checklist; (4) a same-wave **`style_contract_test.exs` extension** proving D-07(a) authored-override presence and D-07(b) tint-rider absence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Light-lane glass/scrim/shadow/focus/home-card treatment | CSS value lane (`style.ex` `[data-tl-theme]` selectors) | — | Light is a *value* lane, not a layout/markup lane. All visual treatment lives in CSS custom-property overrides; LiveView roots already emit `data-tl-theme` (166 D-02). No `.ex` LiveView changes. |
| Theme attribute emission on roots | Frontend server (LiveView `on_mount`) | — | Already done in Phase 166 (`auth.ex` on_mount, ten roots). **No root changes this phase.** Listed only to assert it is out of scope. |
| Tint-rider resolution (chips/alerts/op-badges/etc.) | CSS shared status-tint tokens | — | These ride entirely on Phase 166 `*-bg`/`*-text`/`*-border` tokens. No per-component CSS permitted unless a family is *proven* to misresolve. |
| Source-contract enforcement | Test tier (`style_contract_test.exs`, reads source as string) | — | The contract test treats `style.ex` as a raw string and asserts selector presence/absence + frozen hexes. Extension is pure string-assertion, no rendering. |
| Live design review (eyeball) + recorded judgment | Human gate + committed Markdown artifact | Live-render harness (example app or test render) | UI-SPEC requires data-viz review be "human-gateable judgment recorded... not just a passing test." The checklist is the deliverable. |
| Screenshot visual backstop | DEFERRED (Phase 169) | — | Not this phase. The committed checklist substitutes here. |

## Standard Stack

This phase introduces **zero new dependencies**. The "stack" is the existing in-repo design system and test harness.

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `lib/threadline/operator_surface/style.ex` | in-repo (3641 lines) | Hand-authored `--tl-*` CSS design system; dark base + light/system lanes. All override authoring happens here. | [VERIFIED: source read] Single source of truth; no Tailwind, no build step, no external UI deps (UI-SPEC §Design System, Registry Safety). |
| `test/threadline/operator_surface/style_contract_test.exs` | in-repo (1042 lines) | Source-first style contract; reads `style.ex` as a string, asserts selector presence/absence + frozen hexes + theme-aware lane assertions. | [VERIFIED: source read] Already contains the theme-aware lane test (lines 8–29) and the `theme-toggle` ban (lines 28, 837); natural home for D-07. |
| ExUnit | bundled with Elixir | Test runner for the contract test (`async: true`). | [VERIFIED: test header line 3] Project standard; runs under `mix test` / `mix verify.test`. |

### Supporting (live-review render harness — for the D-01 gate only)
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `examples/threadline_phoenix` (Phoenix app) | in-repo | Runs the operator surface at `http://localhost:4000/audit` via `mix phx.server`. | [VERIFIED: README lines 174/207] The realistic surface for the eyeball review. Currently mounts default `:dark` (router.ex:174 has no `theme:` opt). |
| Playwright (`@playwright/test`) | in `examples/.../e2e` | Existing browser-automation harness; could script a 3-mode render walk for review prep (NOT a screenshot baseline — that is Phase 169). | [VERIFIED: e2e/playwright.config.ts] Optional aid for the reviewer; `reducedMotion: "reduce"` already set. baseURL `127.0.0.1:4002`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Eyeball review via example app at default `:dark` | Temporarily pass `theme: :system` / `:light` in example router for the review session, then revert | Editing the example router risks touching the uncommitted nav-overhaul lane and the `theme: :system` *demo* is explicitly Phase 169. Prefer a non-committed local mechanism (see Pitfall 4). |
| Per-mode manual browser visit | DevTools "Emulate prefers-color-scheme: light" for the `:system` path | `:system` mirrors `:light` values but is a *distinct render path* (`@media` branch). UI-SPEC §Specifics + STATE require all three be reviewed. DevTools emulation is the cleanest way to exercise the `:system` branch without OS-level changes. |

**Installation:** None. No `mix deps.get` change, no npm install. Phase adds CSS rules and test assertions to existing files only.

## Package Legitimacy Audit

> Not applicable. This phase installs **no external packages** (no Hex deps, no npm deps, no registries). UI-SPEC §Registry Safety: "hand-authored `style.ex`, zero external UI dependencies, no shadcn, no third-party registries." Slopcheck/registry verification is moot — there is nothing to verify.

## Architecture Patterns

### System Architecture Diagram

```
                          PHASE 167 WORK SURFACE (CSS values + test + checklist only)

  reviewer (human)                                   planner / executor
        |                                                    |
        | 1. render live                                     | 4. (same wave) extend contract test
        v                                                    v
  ┌─────────────────────┐                          ┌──────────────────────────────────┐
  │ operator surface     │   produces fail-list     │ style_contract_test.exs           │
  │ rendered in 3 modes  │ ───────────────────────► │  (a) authored-override present     │
  │  :dark  :light  :sys │                          │  (b) NO per-component tint-rider   │
  └─────────────────────┘                          │      [data-tl-theme="light"]       │
        |        ▲                                  └──────────────────────────────────┘
        |        │ reads tokens from                          ▲ reads as string
        |        │                                            │
        v        │                                  ┌──────────────────────────────────┐
  ┌─────────────────────────────────────────────┐  │ style.ex                          │
  │ LiveView roots (×10) emit data-tl-theme      │  │  base .threadline-ui  (DARK, :19) │
  │   (UNCHANGED — Phase 166 already did this)   │──┤  [data-tl-theme="light"] (:187)   │
  └─────────────────────────────────────────────┘  │  @media light → [system] (:237)   │
        |                                           │  + NEW additive overrides for     │
        | 2. disposition → 3. author overrides      │    PROVEN-FAIL families only       │
        |    (confirm-strict)                       └──────────────────────────────────┘
        v
  ┌─────────────────────┐
  │ LIGHT-REVIEW.md      │  committed deliverable: per-family disposition (9) +
  │ (phase dir)          │  per-data-viz-surface named-criteria outcome (3)
  └─────────────────────┘
```

### Recommended Plan Structure (concerns, not files)
```
1. EARLY GATE   → live 3-mode review → LIGHT-REVIEW.md disposition fail-list   (D-01/D-02)
2. OVERRIDES    → author additive [light] + [system] rules for PROVEN fails    (D-03/D-04/D-05)
                  (one task per family; both branches edited together)
3. DATA-VIZ     → coverage/timeline/diff review against UI-SPEC criteria        (COMP-02/D-08)
                  → recorded in same LIGHT-REVIEW.md
4. CONTRACT     → extend style_contract_test.exs (same wave as any override)    (D-07 a+b)
```

### Pattern 1: Additive Dual-Branch Override (the core mechanism)
**What:** Every light treatment is expressed twice — once under `[data-tl-theme="light"]`, once under the mirrored `@media (prefers-color-scheme: light) [data-tl-theme="system"]`.
**When to use:** Any family the live review proves fails. Never for a confirm-only family.
**Example (token-alpha tune of glass tint, the D-04 autonomous case):**
```css
/* Source pattern: style.ex:187 (light lane) + :237 (system branch). */
/* Override authored ONLY if review proves the .92 glass collapses to flat white. */
.threadline-ui[data-tl-theme="light"] {
  --tl-color-surface-tint: rgba(255, 255, 255, 0.82);  /* lowered from .92 */
}
@media (prefers-color-scheme: light) {
  .threadline-ui[data-tl-theme="system"] {
    --tl-color-surface-tint: rgba(255, 255, 255, 0.82);  /* mirror — same task */
  }
}
```
[CITED: 167-UI-SPEC.md COMP-01 family #1] — alpha tuning of existing tokens is "still additive."

### Pattern 2: Confirm-Only (default disposition)
**What:** The Phase 166 token-recolor already produces the correct light effect; the plan *verifies and records*, authors nothing.
**When to use:** Default for all 9 families and all 20 tint-riders. UI-SPEC marks #2, #3, #4, #6, #7, #9 as likely confirm-only; #1, #5, #8 flagged for explicit attention but still confirm-first.

### Anti-Patterns to Avoid
- **Pre-authoring the high-risk trio.** D-03 forbids it. #1/#5/#8 get explicit *review*, not pre-built overrides. (UI-SPEC "Rule for #1–#9".)
- **Per-component override for a tint-rider.** OUT of contract unless the shared token is *proven* to fail for that specific family (UI-SPEC §Tint-Rider). D-07(b) is the CI guard against this.
- **Editing only one branch.** An override in `[light]` without the mirrored `[system]` branch silently breaks OS-preference users. Both branches, same task (166 D-03).
- **Touching a base `.tl-*` rule or a dark token value.** Forbidden by Hard Constraint 1 & 3; `style_contract_test.exs` asserts the frozen dark hexes (lines 787–812) and would go red.
- **Inventing an unanchored literal.** D-05: a value not derivable from the 45-token lane FLAGs and PAUSEs. (Blur radii may reuse `--tl-blur-*`: `--tl-blur-panel: 8px`, `--tl-blur-veil: 1px` at `style.ex:168–169`.)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Light values for confirm-only families | New light hexes/alphas | The existing 45-token lane (`style.ex:187–235`) | Every needed light value already exists; overrides reference tokens, never literals (CONTEXT §Reusable Assets). |
| System (OS-preference) branch | A JS theme detector / localStorage | The existing `@media (prefers-color-scheme: light) [data-tl-theme="system"]` branch (`:237–287`) | 166 D-03: no JS, no localStorage, no runtime toggle. The CSS `@media` branch already handles it. |
| Theme attribute on roots | New markup / on_mount edits | Already emitted by Phase 166 `auth.ex` on_mount across ten roots | CONTEXT §Integration Points: "no root changes this phase." |
| Selector presence/absence proof | A new bespoke test framework | Extend `style_contract_test.exs` helpers (`selector_block!`, `assert_selector_contains`, string `contains?`/`refute`) | The file already has the exact helper vocabulary (lines 971–1006) and reads source as a string. |
| Non-color status differentiation | New CSS for diff/coverage states | Existing `::before` status markers + `currentColor` dots (UI-SPEC: "never color alone"; test lines 724–734 already assert chip `::before` markers) | Brand Book §10 rule already encoded; data-viz review confirms it holds on white. |

**Key insight:** This phase is deliberately *subtractive of effort* — the design contract pre-decided the answers and Phase 166 pre-built the values. The risk is over-building (authoring overrides for families that pass), not under-building. Confirm-strict (D-03) is the governing discipline.

## Family Source-Anchor Inventory (COMP-01 — the ~9 dark-effect families)

All anchors **[VERIFIED: source read 2026-06-13]** — every UI-SPEC file:line claim lands on the named selector.

| # | Family | Anchor (verified) | Token(s) it rides | UI-SPEC disposition |
|---|--------|-------------------|-------------------|---------------------|
| 1 | Glass: topbar | `style.ex:384` `.tl-topbar` | `surface-tint` + `--tl-blur-panel` (8px) + `border` | Confirm; **flagged** (glass-vs-page distinctness). Override path: lower light `surface-tint` alpha (D-04 autonomous). |
| 2 | Glass: shell-nav | `style.ex:470` `.tl-shell-nav` | same `surface-tint` + bottom border | Confirm with #1 (shared token). |
| 3 | Glass: toolbar | `style.ex:966` `.tl-toolbar` | `surface-tint-strong` + `shadow-border,shadow-subtle` + blur | Confirm shadow visible on white (light `shadow-subtle` = `rgba(15,23,40,.08/.06)`, `style.ex:231`). |
| 4 | Glass: coverage-command + subview header | `style.ex:3047` `.tl-coverage-command`, `:2748` `.tl-subview__header` | `surface-tint-strong` / `surface-tint` + blur | Confirm shared with #1/#3. |
| 5 | Drawer scrim | `style.ex:2722` `.tl-subview-backdrop` | `backdrop` (light `rgba(15,23,40,0.42)`, `:196`) + `--tl-blur-veil` (1px) | Confirm; **single most likely-to-fail.** Override path: bump `backdrop` alpha (D-04 autonomous). |
| 6 | Drawer shadow | `style.ex:2740` `box-shadow: var(--tl-shadow-raised)` | `shadow-raised` (light `0 18px 48px rgba(15,23,40,0.24)`, `:233`) | Confirm shadow renders on `#FFFFFF`. |
| 7 | Focus glow | `style.ex:156`/`322` `--tl-focus-ring` + `:focus-visible`; also chip dot glow `:1539` (`color-mix … currentColor 14%`) | `--tl-focus-ring` (light at `:234`) | Confirm perceptible; non-text contrast formally proven in Phase 168 (not here). Chip dot is `currentColor`-based → auto-adapts, confirm-only. |
| 8 | Home-card signature effects | `style.ex:681` `.tl-home__card--primary`, `:692` `::before` thread line | `accent-wash` (light `rgba(21,87,192,0.06)`, `:206`) + `signal` (light `#0F8F85`, `:210`) | Confirm; **flagged** (designed inversion: luminous-on-dark → saturated-on-light). |
| 9 | Shell-nav active inset | `style.ex:588` `.tl-shell-nav__item--active` | `accent-inset` (light `rgba(21,87,192,0.16)`, `:208`) + `accent-soft` + `accent-border` | Confirm; this is the token un-stray-ed in Phase 166 (TOKEN-03). |

**Flagged trio for explicit live review (UI-SPEC §Specifics):** #5 (scrim strength), #1 (glass-vs-page distinctness), #8 (signal-line read). Review explicitly; do NOT pre-author.

## Tint-Rider Inventory (COMP-01/TOKEN-02 — confirm-only, no new CSS)

All anchors **[VERIFIED: source read]**. **Baseline confirmed:** `grep -c 'data-tl-theme="light"' style.ex` returns exactly **1** — the lane selector itself (`:187`). There are currently **zero** per-component `[data-tl-theme="light"]` overrides, so the D-07(b) absence assertion starts green.

| Family | Anchor | Rides tokens |
|--------|--------|--------------|
| Status chips (info/warning/danger/success/accent/muted/neutral) | `style.ex:1529–1602` | `*-bg`, `*-text`/`*-border`, status-dot `currentColor` |
| Alerts | `style.ex:1735–1755` | `*-bg`, `*-border`, status-stripe `inset` rail |
| Timeline facts | `style.ex:1022` `.tl-timeline-fact` | `info/warning/success-text`/`-border` rail |
| Op badges (insert/update/delete) | `style.ex:1881–1894` | `op-*-bg`/`op-*-text` → alias `success/info/danger` |
| Redaction rows | `style.ex:1813–1829` | status `*-bg`/`*-text` + rail |
| Policy drift rows | (status-tint family) | `warning`/`danger` tint set |
| Job error states | `style.ex:2123` (status stripe) | `danger` rail + tint |

**Verification deliverable:** a checklist line per family confirming it renders correctly on white via shared tokens — NOT new CSS. A per-component override here is out of contract unless the shared token is *proven* to fail.

## Data-Viz Review Criteria (COMP-02 — the Grafana lesson)

Recorded in `LIGHT-REVIEW.md` as human-gateable judgment, one outcome (pass / override-needed) per surface, per named criterion.

| Surface | Anchor (verified) | Named criteria (must ALL hold on white) |
|---------|-------------------|------------------------------------------|
| Coverage matrix/command | `style.ex:3047` `.tl-coverage-command` | Status pills/metrics legible at dense sizes; covered/uncovered/partial distinguishable by tint AND non-color cue; raised command panel reads as focal not flat; mono metadata (`font-size-xs/sm`) readable on `#FFFFFF`. |
| Timeline | `style.ex:980` `.tl-timeline-command`, `:1022` facts | Status-rail stripes (`inset 3px`) visible on white; "thread" reading survives — rails/dividers (`border #C9D3E2`) must not vanish; dense rows keep row-to-row separation; tabular-nums timestamps legible. |
| Diff | `style.ex:2262` `.tl-diff`, `:2277` `.tl-diff__arrow` | Before/after distinguishable; `#FFFFFF` panel + border reads as contained block; mono diff text legible; `→` arrow (`muted #3B4762`) visible but not louder than values; add/remove/change carried by tint + non-color cue. |

**Override path if a criterion fails:** anchored to existing tokens (UI-SPEC example: promote a divider from `border` to `border-strong #A7B4C8`). Record every outcome explicitly.

## Runtime State Inventory

> This is a CSS-value + test + Markdown phase — no stored data, services, OS state, secrets, or build artifacts are renamed or migrated. Categories assessed for completeness:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified: phase touches only `style.ex` CSS values, a test, and a phase-dir Markdown file. No DB, no datastore. | None |
| Live service config | None — verified: no external service config; the operator surface CSS is server-rendered inline from `style.ex`. | None |
| OS-registered state | None — verified: no OS registrations involved. | None |
| Secrets/env vars | None — verified: no secrets or env vars referenced. | None |
| Build artifacts | None — verified: no build step (UI-SPEC §Design System: "no Tailwind, no build step"). CSS is emitted at render time from compiled Elixir. | None |

## Common Pitfalls

### Pitfall 1: Authoring an override for a confirming family
**What goes wrong:** Override is written for #1/#5/#8 (or any family) "to be safe" before the live review proves it fails.
**Why it happens:** The flagged trio reads as "needs work" — but flagged means *review explicitly*, not *pre-build*.
**How to avoid:** Confirm-strict (D-03). The gate's fail-list is the ONLY input to override tasks. No fail entry → no override task.
**Warning signs:** An override task exists with no corresponding `LIGHT-REVIEW.md` "fail" disposition.

### Pitfall 2: Editing one branch but not the mirror
**What goes wrong:** `[data-tl-theme="light"]` gets the override; the `@media … [system]` branch (`:237–287`) does not. OS-light users see the un-fixed effect.
**Why it happens:** The two branches are 50 lines apart and look redundant.
**How to avoid:** Treat the dual edit as atomic — both branches in the same task (166 D-03, CONTEXT §Established Patterns). Optionally, the contract test can assert that any authored selector appears in BOTH lanes (D-07a strengthened).
**Warning signs:** A `--tl-*` override appears once in the file when grepped, not twice.

### Pitfall 3: D-07(b) regex over- or under-matching
**What goes wrong:** The absence assertion either misses a real per-component tint-rider override or false-positives on the lane selector itself (`:187`).
**Why it happens:** `[data-tl-theme="light"]` appears legitimately once (the lane root). A naive `refute contains?` would fail on the legitimate occurrence.
**How to avoid:** Assert absence of `[data-tl-theme="light"]` *combined with a tint-rider class* (e.g. `refute Regex.match?(~r/\.tl-chip[^{]*\[data-tl-theme="light"\]/, src)` for each rider family), NOT bare absence of the attribute. Baseline today: exactly 1 occurrence (the lane root) — any per-component addition increases the count of *class-qualified* matches.
**Warning signs:** Test goes red on the untouched Phase 166 source, or stays green after deliberately adding a per-component override (write a scratch failing case to validate the assertion).

### Pitfall 4: Disturbing the uncommitted nav-overhaul lane during the live review
**What goes wrong:** To render `:light`/`:system`, someone edits the example router's `threadline_operator_surface(...)` call (router.ex:174) and accidentally stages/commits part of the ~29-file nav-overhaul lane, or its 3 pre-existing failures get attributed to this phase.
**Why it happens:** The example router has no `theme:` opt today (verified), so the natural instinct is to add one.
**How to avoid:** Prefer a non-committed render path for the review: (a) DevTools "Emulate prefers-color-scheme: light" exercises the `:system` branch with zero source edits; (b) if a `theme: :light` mount is needed, do it as a local, un-staged, reverted-after change and stage explicit paths only (166 D-07). The example `theme: :system` *demo* is Phase 169 — do not land it here.
**Warning signs:** `git status` shows example-app or nav-overhaul files staged alongside `style.ex`.

### Pitfall 5: Dark byte-stability regression
**What goes wrong:** An override accidentally edits a base rule or a dark token value; `style_contract_test.exs` frozen-hex assertions (lines 787–812) go red.
**Why it happens:** Override blocks placed near base rules invite stray edits.
**How to avoid:** Keep all new overrides in additive `[data-tl-theme]` blocks only; never touch the `.threadline-ui {` base block (`:19–185`). Hard Constraint 3.
**Warning signs:** Any diff line inside the base block or the frozen dark hex set.

## Code Examples

### D-07(a): assert an authored override is present in BOTH lanes
```elixir
# Extends test/threadline/operator_surface/style_contract_test.exs.
# Only assert for selectors actually authored (driven by the fail-list).
test "authored light overrides appear in both light and system branches" do
  src = File.read!(@style_path)

  # Example: IF the scrim alpha override was authored, both branches carry it.
  if String.contains?(src, "--tl-color-backdrop: rgba(15, 23, 40, 0.5") do
    light = light_lane_block(src)     # split on [data-tl-theme="light"] { ... }
    system = system_lane_block(src)   # split on @media (prefers-color-scheme: light) { ... }
    assert String.contains?(light, "--tl-color-backdrop:")
    assert String.contains?(system, "--tl-color-backdrop:")
  end
end
```

### D-07(b): assert NO per-component tint-rider override exists
```elixir
# The lane root [data-tl-theme="light"] is legitimate (style.ex:187).
# Forbid the attribute *qualified by a tint-rider class*.
test "tint-riders carry no per-component light override (TOKEN-02 invariant)" do
  src = File.read!(@style_path)

  for klass <- ~w(tl-chip tl-alert tl-timeline-fact tl-change__op
                  tl-redaction tl-policy tl-job) do
    refute Regex.match?(
             ~r/\.#{klass}[A-Za-z0-9_-]*[^{]*\[data-tl-theme="light"\]/,
             src
           ),
           "#{klass} must ride the shared status-tint tokens, not a per-component light override"
  end
end
```
[Pattern source: existing helpers `selector_block!`, `Regex.match?` usage in style_contract_test.exs:103/134/180.]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dark-only, `[136-01]` no light mode | Dark default + `[data-tl-theme]` light/system lanes, `[165-01]` | Phase 166 (v1.36) | This phase retunes within that mechanism; no mechanism change. |
| Hardcoded shell-nav inset rgba | `--tl-color-accent-inset` token in both lanes | Phase 166 (TOKEN-03) | Family #9 is confirm-only because of this. |

**Deprecated/outdated:** Runtime theme toggle — permanently banned (`theme-toggle` refute, test lines 28/837). Any plan suggesting a toggle is out of scope.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The cleanest `:system`-branch render path for the review is DevTools `prefers-color-scheme: light` emulation (no source edit). | Standard Stack / Pitfall 4 | Low — if it doesn't suffice, a local un-staged `theme:` edit (reverted) is the fallback; either way no commit to example router. |
| A2 | Policy-drift rows have no single distinct selector anchor (UI-SPEC lists "(status-tint family)"). | Tint-Rider Inventory | Low — they ride the shared `warning`/`danger` set regardless; the verification is "renders correctly," not "has a unique anchor." |

**All other claims are [VERIFIED: source read] or [CITED: 167-UI-SPEC.md / 166-CONTEXT.md / STATE.md].**

## Open Questions

1. **Exact LIGHT-REVIEW.md schema.**
   - What we know: must record per-family disposition (9) + per-data-viz-surface named-criteria outcome (3); lives in phase dir (D-08, Claude's discretion).
   - What's unclear: table vs checklist format; whether it should be machine-parseable like the motion inventory (which `style_contract_test.exs` parses).
   - Recommendation: Use a table with explicit `pass | override-needed` cells so the reviewer's judgment is unambiguous; a parseable format is optional (the data-viz review is human judgment, not a test).

2. **Should D-07(a) assert dual-branch presence, or single-lane?**
   - What we know: D-07(a) says "each authored light override selector is present in the light lane."
   - What's unclear: literal reading = light lane only; safety = both branches (Pitfall 2).
   - Recommendation: Assert both branches (strictly stronger, catches the mirror-omission bug). Within Claude's discretion on assertion form (CONTEXT).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/`mix` | Contract test (`mix test` / `mix verify.test`) | ✓ (project toolchain) | repo-pinned | — |
| `mix phx.server` (example app) | Live review render | ✓ | examples/threadline_phoenix | DevTools emulation for `:system` |
| Browser w/ DevTools | `:light` + `:system` eyeball review | ✓ (reviewer machine) | any modern | — |
| Playwright (e2e) | Optional review-prep automation | ✓ | examples/.../e2e | manual browsing |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** `:system` render path — example router has no `theme:` opt today; use DevTools `prefers-color-scheme: light` emulation (no source edit) as the primary path.

## Validation Architecture

> nyquist_validation is `true` in `.planning/config.json` — this section is REQUIRED.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir), `async: true` |
| Config file | `test/test_helper.exs` (project standard) |
| Quick run command | `mix test test/threadline/operator_surface/style_contract_test.exs` |
| Full suite command | `mix verify.test` (alias → `mix test`); `mix ci.all` for the gate |

### Phase Requirements → Validation Map
| Req | Behavior | Validation Type | Command / Artifact | Exists? |
|-----|----------|-----------------|--------------------|---------|
| COMP-01 (override authored) | Each authored light override present (both branches) | source-contract test | `mix test …/style_contract_test.exs` (D-07a, new) | ❌ Wave (extend) |
| COMP-01 (confirm-only families) | Family renders correctly on white via 166 tokens | committed review checklist | `LIGHT-REVIEW.md` per-family disposition (D-08) | ❌ Wave (create) |
| COMP-01/TOKEN-02 (tint-riders) | No per-component `[data-tl-theme="light"]` for the 20 riders | source-contract test | `mix test …/style_contract_test.exs` (D-07b, new) | ❌ Wave (extend) |
| COMP-02 (data-viz) | Coverage/timeline/diff pass named criteria on white | committed review checklist (human judgment) | `LIGHT-REVIEW.md` per-surface, per-criterion outcome (D-08) | ❌ Wave (create) |
| Dark byte-stability | No dark token/base-rule change | existing source-contract test | frozen-hex assertions (style_contract_test.exs:787–812) | ✅ exists |
| `theme-toggle` ban | No runtime toggle introduced | existing source-contract test | refute (lines 28, 837) | ✅ exists |
| Pixel-level light fidelity | Screenshot baseline | DEFERRED — Phase 169 | `__light__` screenshot lane | n/a (out of scope) |
| AA contrast on light | Non-text + text contrast | DEFERRED — Phase 168 | AA mirror test | n/a (out of scope) |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/style_contract_test.exs`
- **Per wave merge:** `mix verify.test` (full suite) + `mix verify.format`
- **Phase gate:** `mix ci.all` green AND `LIGHT-REVIEW.md` committed with all 9 family dispositions + all 3 data-viz surfaces recorded, before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `LIGHT-REVIEW.md` (phase dir) — covers COMP-01 confirm-only dispositions + COMP-02 data-viz judgment (D-08). Must exist before override tasks (it IS the fail-list).
- [ ] `style_contract_test.exs` extension — D-07(a) authored-override presence + D-07(b) tint-rider absence. Same wave as any override (166 D-05 source-first amendment).
- Framework install: none — ExUnit + `mix` already present.

## Security Domain

> No `security_enforcement` key in `.planning/config.json`. This is a CSS-value/test/Markdown phase with **no input handling, no auth, no crypto, no data flow, no new endpoints**. ASVS categories V2–V6 do not apply: there is no new attack surface — only CSS custom-property values and string-assertion tests. The only adjacent security-relevant invariant (focus-ring perceptibility / non-text contrast) is explicitly *formal-proofed in Phase 168 (A11Y-02)*, not here; this phase only confirms perceptibility by eyeball. No threat patterns introduced.

## Sources

### Primary (HIGH confidence — source read this session)
- `lib/threadline/operator_surface/style.ex` (lines 1–340 base + lanes read in full; all 14 family/rider/data-viz anchors verified by `sed`) — dark base, light lane (`:187–235`), system branch (`:237–287`), blur tokens (`:168–169`), focus ring (`:156`).
- `test/threadline/operator_surface/style_contract_test.exs` (full, 1042 lines) — existing theme-aware lane test (`:8–29`), `theme-toggle` ban (`:28`, `:837`), frozen dark hexes (`:787–812`), helper vocabulary (`:971–1006`).
- `.planning/phases/167-component-retune/167-CONTEXT.md` — D-01..D-08, flagged trio, scope.
- `.planning/phases/167-component-retune/167-UI-SPEC.md` — locked design contract: per-family table, tint-rider table, data-viz criteria, hard constraints.
- `.planning/phases/166-unfreeze-token-lane-mechanism/166-CONTEXT.md` — D-03 mechanism, D-07 worktree safety.
- `.planning/STATE.md` — human gate (`:73`), nav-overhaul standing caution (`:75`), `[165-01]`.
- `.planning/REQUIREMENTS.md` — COMP-01/02, TOKEN-02 definitions + status table.
- `.planning/config.json` — `nyquist_validation: true`, `verify.*`/`ci.all` aliases.
- `mix.exs` (`:75–102`) — `verify.test`, `verify.format`, `ci.all` alias definitions.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:174` — operator mount (no `theme:` opt → defaults `:dark`).
- `examples/threadline_phoenix/e2e/playwright.config.ts` — e2e harness (baseURL `127.0.0.1:4002`, `reducedMotion: reduce`).

### Secondary / Tertiary
- None — no web/external sources needed; phase is fully constrained by in-repo locked contract.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; all components read in source.
- Architecture / mechanism: HIGH — Phase 166 mechanism verified in source; all anchors confirmed.
- Family/rider/data-viz anchors: HIGH — every UI-SPEC file:line independently verified by `sed`.
- Live-review operational path: MEDIUM — render mechanism understood; exact reviewer workflow (DevTools vs local mount) is A1 assumption, low risk.

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable — in-repo locked contract; no fast-moving external deps)
