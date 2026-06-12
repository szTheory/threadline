# Phase 165 — Research Lane C: Threadline Light-Mode Change Surface

**Researched:** 2026-06-12
**Lane:** Repo-internal change-surface map (no web sources; every claim is file:line evidence from this tree)
**Confidence:** HIGH — all findings verified by direct source reading
**Question answered:** If Threadline adds a light theme to the operator surface in a future milestone (candidate v1.36), what exactly changes, what risks exist per component, and what process unfreezes the dark-only decision [136-01]?

---

## Summary

The operator surface is architecturally ready for a second theme lane and contractually forbidden from having one. All color flows through `--tl-*` custom properties declared once on the `.threadline-ui` scope (`lib/threadline/operator_surface/style.ex:19-184`), with exactly **one** hardcoded color outside the token block (`style.ex:489`). A light lane is a single override block (`.threadline-ui--light` or `[data-theme="light"]`) re-declaring **45 color-bearing tokens** plus `color-scheme: light` — no per-component CSS rewrites are structurally required.

The real work is not plumbing; it is (a) **design**: 27 of the 45 color-bearing tokens — every alpha tint, glass surface, shadow, overlay, and the focus-ring glow — have **no counterpart** in the brand light lane (`brandbook/tokens.json:56-76` covers only 19 base semantic tokens) and were tuned specifically for "luminosity over dark"; and (b) **governance**: the freeze is enforced by seven distinct `refute` sites in `test/threadline/operator_surface/style_contract_test.exs` that literally ban the strings `prefers-color-scheme`, `color-scheme: light`, and `theme-toggle`, plus a recorded decision ([136-01], `.planning/STATE.md:102`) and a documented anti-pattern list (`.planning/milestones/v1.31-DESIGN-SYSTEM.md:127-134`). Unfreezing is an explicit, decision-recorded, source-first amendment — exactly what Phase 165's checkpoint and a v1.36 milestone exist to do.

**Primary finding:** light mode is a **token-design + contract-amendment** project, not a CSS-architecture project. The component retune phase is the largest single slice; the mechanism phase is mostly threading one `theme:` option from the router macro to ten LiveView root divs.

---

## 1. `style.ex` — Token Seam Analysis

### 1.1 Single-scope token contract

All design tokens are declared in one block on the `.threadline-ui` class selector, emitted inline by `Threadline.OperatorSurface.Style.css/1`:

- `lib/threadline/operator_surface/style.ex:9-17` — `css/1` function component renders one `<style>` tag (plus base64 `@font-face` from `font_face_style/0`, defined at `style.ex:3531`).
- `style.ex:19` — `.threadline-ui {` opens the token block, annotated `Phase 144 token freeze: this block is the source contract for the final v1.31 design-system catalog` (`style.ex:20-21`).
- `style.ex:184` — block closes. Everything below consumes `var(--tl-*)`.

**Confirmed: every color in the 3,538-line stylesheet flows through the token block, with one exception** (§1.3). Verified by grepping for hex/rgb/hsl literals past line 184 — exactly one hit.

### 1.2 Color-token census — what needs a light-lane value

The token block defines **47** `--tl-color-*` tokens. Six are pure `var()` aliases that retheme for free; **41 carry raw color values**. Adding the 3 shadow tokens and the focus ring, **45 tokens need a light-lane value**:

| Group | Tokens (style.ex lines) | Count |
|---|---|---|
| Backgrounds/surfaces | `bg` (56), `surface` (58), `surface-raised` (60), `surface-hover` (61), `surface-selected` (62) | 5 |
| Glass/overlay (alpha) | `surface-tint` (63), `surface-tint-strong` (64), `backdrop` (65) | 3 |
| Borders | `border` (66), `border-strong` (68), `border-focus` (69) | 3 |
| Text | `text` (70), `muted` (72), `muted-soft` (74) | 3 |
| Accent | `accent` (75), `accent-strong` (77), `accent-soft` (78, alpha), `accent-wash` (79, alpha), `accent-border` (80, alpha), `on-accent` (82) | 6 |
| Signal | `signal` (84), `signal-bg` (86, alpha), `signal-border` (87, alpha) | 3 |
| Ink/paper | `ink` (88), `paper` (89) | 2 |
| Status tints | `danger` (90), `danger-bg` (91), `danger-border` (92), `warning-bg` (93), `warning-text` (94), `warning-border` (95), `success-bg` (96), `success-text` (97), `success-border` (98), `info-bg` (99), `info-text` (100), `info-border` (101), `neutral-bg` (102), `neutral-text` (103), `neutral-border` (104) | 15 |
| Brand | `brand-rail` (111) | 1 |
| Shadows | `--tl-shadow-subtle` (120), `--tl-shadow-popover` (121), `--tl-shadow-raised` (122) — all `rgba(2, 4, 10, …)` dark-ambient | 3 |
| Focus | `--tl-focus-ring` (155) — `rgba(127, 169, 255, 0.42)` glow + 1px `border-focus` | 1 |
| **Total needing light values** | | **45** |

**Free riders (no light value needed — pure aliases):**
- `--tl-color-op-insert/update/delete-bg/-text` (`style.ex:105-110`) — alias the status tints; operation chips retheme automatically once status tints flip.
- `--tl-shadow-border` (`style.ex:119`) — `inset 0 0 0 1px var(--tl-color-border)`.
- `--tl-muted-bg` (`style.ex:153`) — aliases `--tl-color-surface`.
- All spacing/typography/radius/z/motion/breakpoint/size tokens (`style.ex:23-54, 113-118, 123-173`) — theme-neutral.

### 1.3 Hardcoded color OUTSIDE the token block — exactly one

```
style.ex:489    box-shadow: inset 0 0 0 1px rgba(127, 169, 255, 0.16);
```

Selector: `.threadline-ui .tl-shell-nav__item--active, .threadline-ui .tl-shell-nav__item[aria-current="page"]` (`style.ex:485-492`). This is a faint accent inset on the active nav item, layered over `--tl-color-accent-soft` + `--tl-color-accent-border`. It is invisible-by-design on dark and would read as a pale haze on white. **Action:** tokenize (e.g., fold into `--tl-color-accent-border` or a new `--tl-color-accent-inset`) during the token-lane phase. Note: it evades the contract tests' hex bans (`style_contract_test.exs:90,123,170,198` ban only 6-digit hex via `~r/#[0-9a-fA-F]{6}/`; rgba passes).

Also theme-relevant but token-clean:
- `style.ex:1436` — `box-shadow: 0 0 0 3px color-mix(in srgb, currentColor 14%, transparent)` (chip status dot halo) — theme-agnostic by construction; no change needed.
- No scrollbar styling, no `::selection`, no chart colors exist anywhere in the file (verified by grep). The only `@media (prefers-…)` query is `prefers-reduced-motion` (`style.ex:3506`) — allowed under the freeze.

### 1.4 `color-scheme: dark` and where the light lane attaches

- `style.ex:176` — `color-scheme: dark;` sits in the root `.threadline-ui` declaration (lines 175-183, alongside base `color`/`background`). It governs native form controls, scrollbars, and UA defaults; a light lane must flip it to `light` — a string the contract test currently refutes (`style_contract_test.exs:13`).
- **Attachment point:** immediately after the token block closes at `style.ex:184`, add a `.threadline-ui--light { … }` (or `.threadline-ui[data-theme="light"] { … }`) override re-declaring the 45 color-bearing tokens + `color-scheme: light`. Because all 3,300+ subsequent lines consume `var(--tl-*)`, the cascade does the rest. The modifier class lands on the same root `<div class="threadline-ui">` each LiveView renders (§5).
- Gradients are token-composed (`style.ex:583, 594, 785, 1595, 2888` — all `var()`-based), so they follow the lane automatically, though the *result* needs visual retune (§2).

---

## 2. Component Risk Table — `.tl-*` Families

74 distinct `.tl-*` family prefixes exist in `style.ex`. Risk classification by mechanism:

- **FREE** — consumes only base surface/border/text/accent tokens; rethemes correctly the moment the 19 brand-mapped tokens flip.
- **TINT** — relies on low-alpha color washes composited over dark backgrounds (`*-bg`, `*-soft`, `*-wash` tokens). Alpha values tuned for dark (0.09–0.18) will be near-invisible on white; light lanes typically need either higher-alpha tints or opaque pastel values. Rethemes only after tint design work.
- **GLASS** — alpha surface tints + `backdrop-filter: blur()` over dark. Needs light glass values.
- **GLOW/SHADOW** — luminous focus glow or dark ambient shadows; needs per-lane values.

| Family (selector evidence) | Risk | Dark-specific dependency | Light-mode action |
|---|---|---|---|
| `.tl-topbar` (style.ex:291) | GLASS | `surface-tint` rgba(20,27,45,.94) + blur(8px) | new light glass tint |
| `.tl-shell-nav` (371), `__panel` (418) | GLASS | `surface-tint` + blur | new light glass tint |
| `.tl-shell-nav__item--active` (485-492) | TINT + **hardcoded** | `accent-soft`, `accent-border`, raw rgba inset (489) | tokenize 489; light tint values |
| `.tl-toolbar` (870-873) | GLASS | `surface-tint-strong` rgba(11,16,32,.96) + blur | new light glass tint |
| `.tl-coverage-command` (2951) | GLASS | `surface-tint-strong` | same |
| `.tl-subview-backdrop` (2623) | OVERLAY | `backdrop` rgba(2,4,10,.62) + blur veil (2624) | light scrim (darker alpha on light is conventional; pure design choice) |
| `.tl-subview` (2637), `__header` (2655) | GLOW/SHADOW + GLASS | `shadow-raised` 0 18px 48px rgba(2,4,10,.66); header `surface-tint` | light shadow + glass values |
| `.tl-chip` — 6 status variants (1441-1511) | TINT | `info/warning/danger/success/neutral/signal-bg` + alpha borders + dark-lifted text (`#9AB9FF` etc. illegible on white) | full status-tint light design (15 tokens); text from brand light lane |
| `.tl-alert` — 4 variants (1525-1545) | TINT | same status tints | free once chips solved (same tokens) |
| `.tl-change__op` insert/update/delete (1810; tokens 105-110) | TINT (aliased) | op tokens alias status tints | free once status tints solved |
| `.tl-button` base/secondary/active/disabled (1236-1264) | FREE | surface/border/text tokens | none |
| `.tl-button--primary` (1295-1299) | FREE* | `accent` + `on-accent` | brand light lane flips `accent-text` to `#FFFFFF` (tokens.json:69) — handled by token flip |
| `.tl-button--quiet-primary` (1280-1293) | TINT | `info-bg`, `accent-soft`, `accent-border` | tint design |
| `.tl-button--ghost:hover` (1342) | TINT | `neutral-bg` | tint design |
| `.tl-button--danger:hover` (1357) | TINT | `danger-bg` | tint design |
| `.tl-segmented__item[aria-pressed]` (858-860) | TINT | `accent-soft` + `accent-border` inset | tint design |
| `.tl-home__card` (560-567) | SHADOW | `shadow-subtle` rgba(2,4,10,.50/.34) | light shadow lane (brandbook shadow values at tokens.json:138-143 use .18/.12/.30/.40 alphas — plausible light starting point) |
| `.tl-home__card--primary` (578-586) | TINT | `accent-wash` gradient veil over `surface-raised` | retune wash alpha for light |
| `.tl-home__card--primary::before` thread-draw (588-598) | FREE* | `signal` gradient | brand light `signal` `#0F8F85` (tokens.json:71) flips it; verify 2px line still reads on white |
| `.tl-home__card-kicker` (605-607) | TINT | `accent-border` + `accent-soft` | tint design |
| `.tl-card` + stripe variants (1620-1655) | SHADOW (stripes FREE) | `shadow-border` (alias, free) + `shadow-subtle`; stripes use opaque `danger`/`warning-border`/`success-text`/`info-text`/`signal` | light shadows; stripe colors flip with base tokens |
| `.tl-table`, `.tl-table-wrap`, responsive card mode (59 uses) | FREE | surface/border/text only | none |
| `.tl-empty` (1589-1591), `--unsupported` gradient (1595) | FREE | dashed `border-strong`, surface gradient | none |
| `.tl-empty--error` (1585) | TINT | `danger-bg` | free once status tints solved |
| `.tl-value` base, `.tl-kv`, `.tl-diff`, `.tl-code` | FREE | text/surface tokens | none |
| `.tl-value--redacted` (2146), `.tl-remediation__command` (2240), `.tl-row-action[open]` summary (2311), `.tl-policy__cell--drift` (2594) | TINT | `warning-bg` | free once status tints solved |
| `.tl-job__note--error` (2471) | TINT | `danger-bg` | same |
| `.tl-policy__success` (3179) | TINT | `success-bg` | same |
| `.tl-copy.is-copied::after` (2795) | TINT | `signal-bg` | light signal tint |
| `.tl-copy` pulse halo (1436) | FREE | `color-mix` on currentColor | none — theme-agnostic |
| `.tl-journey-rail::before` (2888) | FREE* | `signal` → `signal-border` gradient | follows signal tokens; visual check |
| `.tl-orientation--investigation` (1602) | FREE* | `brand-rail` stripe = Threadline Black `#0B1020` | decide: keep black rail on light (works as ink) or remap |
| `.tl-skip-link` (230-241) | FREE | `accent` + `on-accent` | none |
| `.tl-icon`, chevrons (1125-1126, 1378-1380) | FREE | `currentColor` | none |
| Focus ring — all `:focus-visible` (219-226, token 155) | GLOW | luminous rgba(127,169,255,.42) glow tuned for dark | light lane needs darker ring (brand light accent `#1557C0`); AA non-text contrast check |
| Remaining layout-only families (`.tl-page`, `.tl-filter-grid`, `.tl-summary-grid`, `.tl-section`, `.tl-kv`, etc.) | FREE | spacing/typography only | none |

**Aggregate:** of 74 families, roughly **45 are FREE** (token-pure), **~20 ride on the shared status-tint system** (one design decision, 15 tokens, fixes all of them), and **~9 need individual attention** (glass chrome ×4, drawer overlay/shadow, focus ring, home-card signature effects, active-nav inset, shadows). The tint usage census: 39 `var(--tl-color-*-bg|*-soft|*-wash|*-tint|backdrop)` consumption sites; 31 shadow-token consumption sites.

---

## 3. Contract and Test Surface — What Enforces the Freeze

### 3.1 `test/threadline/operator_surface/style_contract_test.exs` (1,033 lines)

The dark-only ban appears at **seven enforcement sites**:

1. **Lines 8-14** — the headline contract:
   ```elixir
   test "operator surface stays dark-only and token-driven" do
     src = File.read!(@style_path)
     assert String.contains?(src, "color-scheme: dark;")
     refute String.contains?(src, "prefers-color-scheme")
     refute String.contains?(src, "color-scheme: light")
   end
   ```
2. **Lines 86-87** (Find-cluster section): `refute String.contains?(find_section, "prefers-color-scheme")` / `refute String.contains?(find_section, "color-scheme: light")`
3. **Lines 121-122** (topbar/shell-nav section): same pair of refutes.
4. **Lines 168-169** (home orientation section): same pair.
5. **Lines 196-197** (home earned-flow section): same pair.
6. **Lines 824-834** — the Phase 144 anti-pattern ban, including `theme-toggle`:
   ```elixir
   for anti_pattern <- [
         "@tailwind",
         "prefers-color-scheme",
         "color-scheme: light",
         "theme-toggle",
         "shadcn",
         "daisyui",
         "heroicons"
       ] do
     refute String.contains?(src, anti_pattern), "phase 144 forbids #{anti_pattern}"
   end
   ```
7. **Section hex bans** at lines 90, 123, 170, 198 — `refute Regex.match?(~r/#[0-9a-fA-F]{6}/, section)` keep component sections token-pure (a useful guard to **keep** for the light lane; note it does not catch rgba — see §1.3).

**Tests a light lane must mirror, not just amend:**
- **Lines 644-674** — `"phase 143 accessibility tokens meet dark-surface contrast baseline"`: programmatic WCAG AA (≥4.5) checks of 8 text tokens × 4 background tokens plus accent-on-raised, computed from hex via `color_tokens/1` (lines 999-1003) + `contrast_ratio/2` (lines 1005-1032). A light lane needs a parallel test parsing the `.threadline-ui--light` block. **Caveat:** `color_tokens/1` parses only `#rrggbb` declarations — alpha-tint tokens are invisible to it; light tint contrast needs either opaque light tints or alpha-compositing math added to the helper.
- **Lines 16-25** — dark interaction tokens (hover/focus) presence; light lane needs equivalents.
- **Lines 27-36** — status borders presence (token names are lane-neutral; survives as-is if light lane reuses token names).
- **Lines 764-835** — Phase 144 frozen token catalog asserts exact dark hex values (e.g., `--tl-color-bg: #0B1020;` at line 776). Adding a light lane does not break these as long as dark values stay canonical in the base block.

### 3.2 The frozen decision and its records

- **`.planning/STATE.md:102`** — `[136-01]: Dark-only remains intentional; no \`prefers-color-scheme\`, no light mode, no theme toggle.` (companion at line 103: contrast-first token work). STATE.md:109 points to `.planning/PROJECT.md` Key Decisions as the full log; PROJECT.md records the v1.31 shipped summary "locks the `.tl-*` class catalog, `--tl-*` token contract, and dark-only brand constraints" (PROJECT.md, "Design-system hardening" bullet).
- **`.planning/milestones/v1.31-phases/136-design-system-hardening/136-CONTEXT.md:14`** — decision origin, verbatim: *"Dark-only remains intentional brand direction: 'night infrastructure with luminous signal lines.' Do not add `prefers-color-scheme`, `color-scheme: light`, or a theme toggle."*
- **Phase 144 freeze scope** — `.planning/milestones/v1.31-phases/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md`, decision **D-07** (line 33): *"…BEM `.tl-*` classes and `--tl-*` tokens in `lib/threadline/operator_surface/style.ex`; no Tailwind, no build step, no light/system theme, no external design-system dependency."* and **D-09** (line 35): the freeze is *"explicit and test-backed"* via narrow source contracts in `style_contract_test.exs`.
- **STATE.md:121-122** — Phase 144 closeout decisions: *"[Phase 144-03]: The v1.31 design-system freeze is source-first: style.ex and style_contract_test.exs govern the catalog."* and *"[Phase 144-03]: Phase 144 documents the local .tl-* and --tl-* system without … light/system theme support…"*
- **`.planning/milestones/v1.31-DESIGN-SYSTEM.md:127-134`** — Anti-Patterns section bans (line 133-134): *"Light theme, system theme, `prefers-color-scheme`, or `color-scheme: light`."* / *"Any theme toggle or `theme-toggle` behavior."* The amendment rule is given at line 18: *"If a future change updates a token, primitive, or anti-pattern rule, update source and the narrow source contract first, then update this catalog."*

### 3.3 The unfreeze procedure (per GSD conventions in this repo)

`.planning/ROADMAP.md:39` states the gate verbatim: *"NO implementation (operator-surface light mode = candidate milestone v1.36; dark-only decision [136-01] unfrozen only by explicit choice)."* Concretely, the recorded process is:

1. **Phase 165 checkpoint (human):** user reads `165-LIGHT-MODE-RECOMMENDATION.md`; AskUserQuestion → approve/adjust/defer; decision recorded **verbatim** in the phase SUMMARY (`165-01-PLAN.md:28`, protocol step 3).
2. **New decision entry** superseding [136-01] in `.planning/STATE.md` `### Decisions` (the same ledger where [136-01] lives, lines 100-124) — by convention decisions are appended with phase tags, not edited in place; the new entry states what replaces "dark-only" (e.g., "dark-primary, light supported via host opt-in").
3. **v1.36 milestone opens** with its own REQUIREMENTS/ROADMAP under `.planning/` (pattern: every milestone v1.31-v1.35 in `.planning/milestones/`), containing the implementation phases.
4. **Source-first amendment order** (per v1.31-DESIGN-SYSTEM.md:18 and 144-CONTEXT D-09): change `style.ex` and `style_contract_test.exs` **in the same phase/commit** — flip the line-8 test from "stays dark-only" to "dark-primary with governed light lane", remove `prefers-color-scheme`/`color-scheme: light`/`theme-toggle` from the line-824 anti-pattern list (or scope them: e.g., keep banning `prefers-color-scheme` if selection stays host-config-only), update the four section refutes, add the light contrast mirror test — **then** update the `v1.31-DESIGN-SYSTEM.md` catalog (or supersede it with a v1.36 edition) and the STATE decision.

### 3.4 Screenshot / Playwright surfaces needing light-mode runs

`examples/threadline_phoenix/e2e/tests/` (13 spec files; run via `mix verify.example_browser`, mix.exs:87):

- **`operator-screenshot-regression.spec.ts`** — 5 tests (lines 97, 104, 111, 123, 132: global chrome/Home, dense Timeline, row-history drawer, Exports, Retention) × desktop+mobile = **10 committed PNG baselines** in `operator-screenshot-regression.spec.ts-snapshots/` (verified: 10 files, chromium only). Commit `cf0e8e2` added `test.skip(!!process.env.CI, "visual screenshot baselines are platform-sensitive; run this guard locally…")` — so light baselines are a **local-only** doubling (10 → 20), not a CI cost. `maxDiffPixelRatio: 0.01` with dynamic masks (spec lines 42-60).
- **`operator-screenshots.spec.ts`** — durable screenshot matrix gated by `OPERATOR_SCREENSHOT_DIR` (line 41), names suffixed `__default__<viewport>` (line 46). Light mode implies a `__light__` variant lane in the naming scheme.
- **`operator-accessibility.spec.ts`** — 4 tests (lines 82, 138, 178, 214) covering keyboard focus/skip-link/nav state, filter naming, drawer dialog semantics + visible focus, and non-color status chips. None assert colors directly (no axe/contrast assertions — contrast lives in the ExUnit contract test), but "visible focus" (line 178) and chip shape markers (line 214) must be **re-run under the light lane** to prove the affordances survive.
- Other specs (`operator-motion`, `operator-features`, `operator-find-mobile`, `operator-home-nav-mobile`, `operator-prove-mobile`, `operator-responsive-mobile-first`, `operator-earned-flows`, `operator-phase-135-uat`, `operator.spec`, `register.spec`) assert structure/behavior, not color — a single smoke pass in light mode suffices; no per-spec forking needed.

---

## 4. Starting Values — `brandbook/tokens.json` Light Lane Mapping

### 4.1 The brand light lane

`brandbook/tokens.json:56-76`, `semantic.light` — **19 tokens** (note: not 24; the lane has exactly 19 keys, same shape as `semantic.dark` at lines 35-55):

```
bg #F7F9FC · surface #FFFFFF · surface-raised #EEF3FA · surface-hover #E7ECF4 ·
surface-selected #DDE8FF · border #C9D3E2 · border-strong #A7B4C8 · text #0F1728 ·
text-muted #3B4762 · text-soft #73819C · accent #1557C0 · accent-strong #0E459B ·
accent-text #FFFFFF · logo-arc #4781E6 · signal #0F8F85 · success-text #136C47 ·
warning-text #7A5400 · error-text #A33434 · info-text #1557C0
```

Supplementary light-relevant values elsewhere in the file: `code.light-bg #EEF3FA / light-border #C9D3E2 / light-text #0F1728` (tokens.json:152-154); raw palette `mist #E7ECF4`, `storm #3B4762`, `paper #F7F9FC`, `ink #0F1728` (tokens.json:15-18). The light accents are already contrast-retuned (accent darkens from `#4F8CFF` to `#1557C0` for white backgrounds), confirming the brand book anticipated "designed, not recolored."

### 4.2 Token mapping table — brand light lane → `style.ex` tokens

**Map 1:1 (18 style.ex tokens get a light value directly):**

| style.ex token (line) | brand light key (tokens.json:56-76) | light value |
|---|---|---|
| `--tl-color-bg` (56) | `bg` | `#F7F9FC` |
| `--tl-color-surface` (58) | `surface` | `#FFFFFF` |
| `--tl-color-surface-raised` (60) | `surface-raised` | `#EEF3FA` |
| `--tl-color-surface-hover` (61) | `surface-hover` | `#E7ECF4` |
| `--tl-color-surface-selected` (62) | `surface-selected` | `#DDE8FF` |
| `--tl-color-border` (66) | `border` | `#C9D3E2` |
| `--tl-color-border-strong` (68) | `border-strong` | `#A7B4C8` |
| `--tl-color-text` (70) | `text` | `#0F1728` |
| `--tl-color-muted` (72) | `text-muted` | `#3B4762` |
| `--tl-color-muted-soft` (74) | `text-soft` | `#73819C` |
| `--tl-color-accent` (75) | `accent` | `#1557C0` |
| `--tl-color-accent-strong` (77) | `accent-strong` | `#0E459B` |
| `--tl-color-on-accent` (82) | `accent-text` | `#FFFFFF` |
| `--tl-color-signal` (84) | `signal` | `#0F8F85` |
| `--tl-color-success-text` (97) | `success-text` | `#136C47` |
| `--tl-color-warning-text` (94) | `warning-text` | `#7A5400` |
| `--tl-color-danger` (90) | `error-text` | `#A33434` |
| `--tl-color-info-text` (100) | `info-text` | `#1557C0` |

(Brand `logo-arc` has no style.ex token — it lives in the SVG logo assets. `--tl-color-ink`/`--tl-color-paper` (88-89) map trivially from raw `ink`/`paper`.)

**NO brand-lane counterpart — needs design work (27 values):**

| style.ex token (line) | Category | Why design work |
|---|---|---|
| `surface-tint` (63), `surface-tint-strong` (64) | glass | alpha glass over dark; light glass needs new base+alpha |
| `backdrop` (65) | overlay | scrim darkness over light content is a design choice |
| `border-focus` (69) | focus | `#7FA9FF` is dark-lane; tokens.json `focus` (144-147) is single-lane dark |
| `accent-soft` (78), `accent-wash` (79), `accent-border` (80) | accent tints | 0.09-0.48 alphas tuned for dark |
| `signal-bg` (86), `signal-border` (87) | signal tints | same |
| `danger-bg/border` (91-92), `warning-bg/border` (93,95), `success-bg/border` (96,98), `info-bg/border` (99,101), `neutral-bg/text/border` (102-104) | status tints | tokens.json `callout.*` (160-181) provides bg/border tints but they are the **dark** values (rgba over dark); no light callout lane exists |
| `brand-rail` (111) | brand | `#0B1020` rail on light: keep-as-ink decision |
| `--tl-shadow-subtle/popover/raised` (120-122) | shadows | dark ambient .50/.55/.66 alphas; tokens.json `shadow` (138-143) carries lighter alphas (.18/.12/.30/.40) — a plausible light starting point, but single-lane |
| `--tl-focus-ring` (155) | focus | glow architecture itself is dark-tuned; light ring wants a darker, possibly thinner treatment |

**Net:** 18/45 light values come straight from the brand book; **27/45 are new design decisions** — and a brandbook `tokens.json` v1.2 should grow the light lane (tints, shadows, focus, glass) so the SSOT relationship between brandbook and `style.ex` is preserved.

---

## 5. Mount/Config Seam — Where `theme:` Threads Through

- **Macro entry:** `Threadline.OperatorSurface.Router.threadline_operator_surface(path, opts \\ [])` — `lib/threadline/operator_surface/router.ex:54`. The documented option list (router.ex:27-51) currently covers `:exports`, `:scope_query_fn`, `:export_authorize_fn`, `:coverage_authorize_fn`, `:policy_authorize_fn`, `:evidence_authorize_fn` (plus `:authorize_fn`/`:actor_fn`/`:adopter_acknowledges_unauthenticated` handled at lines 55-57). A `theme:` opt (e.g., `:dark | :light`, default `:dark`) slots naturally into this keyword list.
- **Opts already flow to LiveViews:** the full `opts` keyword is passed verbatim into `live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}, {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}]` (router.ex:89-93) and to `Threadline.OperatorSurface.SessionPlug` (router.ex:83-87). The established pattern is on_mount assigning `threadline_*` assigns (e.g., `@threadline_coverage_enabled`, `@threadline_policy_enabled` — visible in `start_live.ex:111-127`). A `@threadline_theme` assign from the Auth/Coverage on_mount (or a tiny dedicated on_mount) is the zero-new-machinery path.
- **Rendered root element:** there is **no shared layout/root template** — each LiveView renders its own `<div class="threadline-ui">` + `<Threadline.OperatorSurface.Style.css />` (e.g., `start_live.ex:117-118`). All **10 root divs**:
  - `lib/threadline/operator_surface/live/start_live.ex:117`
  - `lib/threadline/operator_surface/live/timeline_live.ex:323`
  - `lib/threadline/operator_surface/live/evidence_live.ex:54`
  - `lib/threadline/operator_surface/live/coverage_live.ex:94`
  - `lib/threadline/operator_surface/live/export_status_live.ex:114`
  - `lib/threadline/operator_surface/live/policy_redaction_live.ex:43`
  - `lib/threadline/operator_surface/live/retention_history_live.ex:73`
  - `lib/threadline/operator_surface/live/row_history_live.ex:33`
  - `lib/threadline/operator_surface/live/transaction_live.ex:85`
  - `lib/threadline/operator_surface/live/actor_live.ex:88`

  Each would become `class={["threadline-ui", @threadline_theme == :light && "threadline-ui--light"]}` (or a shared helper to avoid 10-way drift — a `Style.surface_class(@threadline_theme)` helper keeps it single-sourced). `unsupported_view.ex` and `surface_header.ex` render **inside** these roots (no `threadline-ui` of their own — verified) so they inherit for free.
- **Host-page note:** the surface is a mounted island; it never owns `<html>`. `color-scheme` on `.threadline-ui` and the opaque `background: var(--tl-color-bg)` (style.ex:181) mean the host's own theme never bleeds in — true in both lanes. No FOUC risk for host-config selection (`theme:` is compile/mount-time); FOUC only enters if a future runtime toggle/persistence mechanism is chosen (out of scope for this lane's evidence).

---

## 6. Sizing and Sequencing — Candidate v1.36 "Operator Surface Light Mode"

Relative sizing is anchored to the measurements above (45 tokens / 27 new designs / 1 hardcoded fix / 7 test refute sites / 39 tint + 31 shadow consumption sites / 10 LiveView roots / 10 screenshot baselines).

| # | Phase | Contents (evidence-based) | Relative size |
|---|---|---|---|
| 1 | **Token lane + brandbook light extension** | Design the 27 missing light values (status tints ×15, glass ×3, shadows ×3, focus ×2, accent tints ×3, brand-rail); extend `brandbook/tokens.json` semantic.light + callout/shadow/focus light lanes; tokenize `style.ex:489`; emit `.threadline-ui--light` override block after style.ex:184 with `color-scheme: light`. Blocked on contract amendment (phase 3) landing in the same wave or before. | **M-L** (design-heavy: 27 decisions; mechanically small) |
| 2 | **Mechanism: `theme:` router opt → root class** | Add `theme:` to `threadline_operator_surface` opts (router.ex:54, docs 27-51); on_mount assign; shared root-class helper; update 10 LiveView roots; example app mount demo. | **S-M** (mechanical, 12 files, established opts pattern) |
| 3 | **Contract-test amendment (the unfreeze)** | Record superseding decision in STATE.md Decisions; flip `style_contract_test.exs:8-14`; prune/rescope anti-pattern list (824-834) and 4 section refutes (86-87, 121-122, 168-169, 196-197); add light contrast mirror of 644-674 (extend `color_tokens/1` at 999-1003 to parse the light block; handle alpha tints); update `v1.31-DESIGN-SYSTEM.md:127-134` anti-patterns per the line-18 source-first rule. | **M** (precise, high-blast-radius; must be same-wave with phase 1) |
| 4 | **Component retune on light** | Walk the §2 risk table: glass chrome (topbar/shell-nav/toolbar/subview header), drawer scrim+shadow, focus-ring visibility, home-card wash + thread-draw legibility, segmented/quiet-primary/ghost/danger hover tints, status chips/alerts non-color markers on light, nav active inset. ~25 high/medium selectors; 45 families theme free. | **L** (the bulk of visual iteration) |
| 5 | **Accessibility verification (light)** | Automated AA matrix green for light lane (phase 3's mirror test); re-run `operator-accessibility.spec.ts` 4 tests under `theme: :light` (focus visibility line 178, chip markers line 214); verify `color-scheme: light` form-control rendering. | **S-M** |
| 6 | **Screenshot baselines + docs/example** | Light variants of the 10 local-only regression baselines (CI-skipped per cf0e8e2); `__light__` lane in `operator-screenshots.spec.ts` durable naming; README.md:121 "a dark, …" copy update; example app README/router demo; design-system catalog light section; brand-book posture statement (dark-primary, light supported). | **S-M** |

**Sequencing:** 3 → 1 → 2 can collapse into one opening wave (the unfreeze + token lane must land atomically or `mix verify.test` is red between commits — the contract test reads `style.ex` directly, so the test flip and the `color-scheme: light` introduction are inseparable). Then 4 (largest, iterative), then 5 ∥ 6. **Dark stays the base lane and the canonical token block** — the Phase 144 frozen-hex assertions (`style_contract_test.exs:764-802`) survive untouched, which keeps the amendment surgical: light is additive override, never a rewrite.

**Single biggest risk to budget for:** the status-tint system (15 tokens, consumed by ~20 component families). One good design decision there collapses most of phase 4; a weak one ripples through chips, alerts, op badges, redaction/warning rows, policy drift, and job errors simultaneously.

---

## Sources (all repo-internal, HIGH confidence)

- `lib/threadline/operator_surface/style.ex` — full read of token block (19-184) + grep-verified census of color literals, tint/shadow/gradient consumers
- `test/threadline/operator_surface/style_contract_test.exs` — full read (1-1033)
- `brandbook/tokens.json` — full read (1-196)
- `lib/threadline/operator_surface/router.ex` — full read (1-151)
- `lib/threadline/operator_surface/live/*.ex` root divs; `components/unsupported_view.ex`, `components/surface_header.ex`
- `.planning/STATE.md` (85-124), `.planning/ROADMAP.md` (39, 123), `.planning/PROJECT.md` (v1.31 shipped summary)
- `.planning/milestones/v1.31-phases/136-design-system-hardening/136-CONTEXT.md`; `…/144-close-gap-polish-audit-and-polish-ds/144-CONTEXT.md` (D-06–D-11)
- `.planning/milestones/v1.31-DESIGN-SYSTEM.md` (12-28, 117, 127-134)
- `examples/threadline_phoenix/e2e/tests/` — `operator-screenshot-regression.spec.ts` (+ 10 committed snapshots, CI-skip from commit `cf0e8e2`), `operator-screenshots.spec.ts`, `operator-accessibility.spec.ts`
- `mix.exs` verification aliases (77-99)
