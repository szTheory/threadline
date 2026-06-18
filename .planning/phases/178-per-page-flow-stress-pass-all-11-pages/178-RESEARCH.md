# Phase 178: Per-page & flow stress pass (all 11 pages) - Research

**Researched:** 2026-06-18
**Domain:** Elixir/Phoenix LiveView operator-surface integration audit — CSS-grid item centering, Tier A render-contract + Tier B Playwright detectors, LiveView connection-lifecycle (socket-drop) testing, ledger ratchet parity
**Confidence:** HIGH (codebase-grounded — every locked code peg in CONTEXT was verified against live source this session)

## Summary

This is a narrow, high-confidence verification pass over an exceptionally detailed CONTEXT.md (D-01..D-14) that already carries exact code pegs, detector strategies, fixture conventions, and a full canonical-reference list. **The locked approaches all check out against the live codebase** — the centering bug is real and correctly diagnosed, the reconnect CSS contract exists and is correct, the WCAG/`contrast_ratio` engine and z-order/focus Tier A patterns are present, the Playwright lanes (dark + `desktop-chromium-light`, `reducedMotion: "reduce"`) exist, `window.liveSocket` is exposed, the 11 `threadline-ui` wrappers are genuinely duplicated, and the ledger ratchet test enforces upward-only scoring. Minor line drift exists in a few pegs (documented below) but nothing material moved.

The research delivers three concrete value-adds beyond confirming CONTEXT: (1) a **latent twin of the PAGE-03 bug on the Home page** — `.tl-home` (`style.ex:689-692`) carries the *identical* `max-width:1000px; margin:0 auto` pattern and is placed on a grid-item `<main class="tl-page tl-home">` in `start_live.ex`, so it almost certainly left-pushes at ≥768px exactly like the transaction page, yet it is NOT in PAGE-03 scope; (2) a set of technique-specific pitfalls for the detectors in play (grid-item centering, `rendered_to_string` substring assertions, real socket-drop flakiness, alpha-aware contrast); and (3) the REQUIRED `## Validation Architecture` section the Nyquist gate consumes.

**Primary recommendation:** Execute exactly as CONTEXT locks. Apply the D-09 `justify-self: center` fix to `.tl-container` *and* flag `.tl-home` as the same bug class — the planner should decide whether to extend the one-line fix to `.tl-home` (cheap, same root cause) or scope it to PAGE-03's literal `tl-container`. Use `rendered_to_string` + `=~` substring assertions for Tier A (the existing, parser-agnostic idiom — no Floki/LazyHTML concern). For Tier B socket-drop, lead with `window.liveSocket.disconnect()` and keep `routeWebSocket`/`setOffline` as the documented fallback (D-13).

## User Constraints (from CONTEXT.md)

### Locked Decisions

**PAGE-01 — Verification coverage strategy:**
- **D-01:** Full Tier A cartesian + representative Tier B sample. Tier A (`render_component`/`rendered_to_string` DOM + CSS-source assertions, every PR via `verify-test`) proves the **full structural cartesian** (~1,155 page×path×theme×viewport cells render, carry the right `data-state`, don't loud-fail, emit the right keyboard/reduced-motion/reconnect CSS hooks). Tier B (Playwright real-engine) proves a **representative high-signal sample**. Never pixel-diff. State the split explicitly in the verification doc.
- **D-02:** Tier B sampling rule: per page ~6 high-signal cells — 320 floor + 1440 ceiling only, happy + worst-case path (error or empty), dark + light lanes, plus one keyboard-only, one reduced-motion, one reconnect spec. ≈66 browser cells vs 3,465.
- **D-03:** Audit substrate = static fixtures on `/audit/__stress` (DB-free, deterministic) for the 7-path × theme × viewport matrix; **hybrid real `/audit/*` LiveViews** for genuinely-live flows (loading→terminal resolution, reconnect/socket-drop) in a small set of Tier B specs.
- **D-04:** Ledger ratchet for pages. Convert each of the 11 reserved `page.<x>.reserved` entries (score 35, owner 178) into real fixture-backed path stories; raise `current_score` toward `target_score: 90` (upward-only); maintain `story_id`/`fixture_key` parity; refresh `DESIGN-SYSTEM.md`. "Done" per page = all 7 paths fixture-backed, score at ratchet target, both tiers green. Raise the two existing baselines too (`page.home.happy`, `page.timeline.empty`, score 62).

**PAGE-02 — Footgun elimination (all 11 classes):**
- **D-05:** Guard-first, not fix-first. Write the failing detector first, watch it fail, fix to green. Each footgun becomes a permanent CI assertion. Tier A guards run every PR; Tier B on `verify-example-browser`.
- **D-06:** Layered global + per-page detectors. Global cross-page guards (one Tier-A `style.ex` source scan + one Tier-B sweep over all `/audit/*` routes) for surface-wide classes (scroll traps, misalignment/spacing, contrast, same-color text-on-bg, structural halves of hover/focus-on-non-interactive and disabled-looks-enabled). Per-page/per-component detectors on the `__stress` story matrix for the ones needing a specific overlay/pager mounted (modal/drawer scrim & float, overlay focus enter/restore, escape/click-outside, tab active-state, pagination edges).
- **D-07:** All 11 are automatable — reuse existing infra. WCAG `contrast_ratio/2` (#10/#11); z-token ascending guard + `elementFromPoint` hit-test (#2); `JS.focus_first`/`phx-mounted` + `toBeFocused`/Esc-returns-focus (#3/#4); cursor/`not-allowed`/`toBeDisabled` (#5/#7); `aria-current`/`aria-selected` distinct-bg + non-color cue (#8); pager disabled-edge (#9); `boundingBox` within-viewport (#6). Residual manual ≈ zero (only sub-pixel optical balance and "focus landed somewhere sensible" as optional, non-blocking notes).

**PAGE-03 — Transaction-page desktop centering fix:**
- **D-08:** Root cause locked: `margin:0 auto` doesn't center a CSS-grid item. The transaction page is the only one putting `.tl-container { max-width:1000px; margin:0 auto }` (`style.ex:675-678`) on its `<main>` (`transaction_live.ex:100`), which at ≥768px is a grid item (`grid-column:2`). Under default `justify-self:stretch`, `max-width` caps the item below column width then anchors it to start (left) — the "left push." Coverage/timeline center because they use bare `tl-page`.
- **D-09:** Fix: add `justify-self: center` to `.tl-container` (`style.ex:675`), keeping `max-width:1000px`. One-line, markup-untouched. Guard: Tier A asserts `.tl-container` carries `justify-self: center`; Tier B loads `/audit/transactions/:id` at 1024 + 1440 and asserts the content bounding box is horizontally centered (`|center_x − viewport/2| ≤ tolerance`). The reserved `footgun.transaction-page-left-push-desktop` story (`stress_fixtures.ex:455-461`, score 25 → 90) is the Tier-B fixture peg.
- **D-09b:** Watch the secondary inconsistency (fix opportunistically, not the bug itself): the inner `tl-transaction tl-short-content` wrapper (`max-width:72ch; margin-inline:auto`, `style.ex:2887-2890`) only wraps the page header, not `#changes-list`/`tl-viewport`. Planner decides whether to align it.

**SEED-005 — Reconnect banner shell mount + mutating-control wiring:**
- **D-10:** Extract a shared shell/chrome component. There is no shared shell today — all 11 LiveViews duplicate `<div class="threadline-ui">…<Style.css/>…<surface_header/>…<main id="tl-main">`. Pull that wrapper into one internal `@doc false` shell/chrome function component; route all 11 through it. Gives `reconnect_banner/1` a single mount point (once, above `#tl-main`, inside `.threadline-ui`) and kills 11-way drift.
- **D-11:** Connection-class anchor confirmed: `.threadline-ui.phx-loading` / `.threadline-ui.phx-error`. The LiveView render-root is `.threadline-ui` in all 11 views; phoenix_live_view applies its client classes directly there — no parent indirection. Banner CSS at `style.ex:3405-3424` is already correct. **Never** `<body>`, **never** the legacy `.phx-disconnected`.
- **D-12:** `data-tl-mutating` scope = genuine state-changers now; download links get `aria-disabled`; no-op stubs skipped. Primary set: `prune_now` submit (`retention_history_live.ex:299`), `save-view` submit (`timeline_live.ex:703`), `delete-view` (`timeline_live.ex:720`). Download/export links carry `data-tl-mutating` **plus** `aria-disabled="true" tabindex="-1"` (Pitfall-6, links can't take `disabled`). No-op export "queue" stubs skipped. `policy_redaction_live.ex` is read-only — no controls to wire.
- **D-13:** Real socket-drop Playwright spec replaces the 177 inject-probe. `window.liveSocket` is exposed globally (`app.js:12`). UAT #4: `window.liveSocket.disconnect()` → assert real `.tl-reconnect-banner` visible and real `[data-tl-mutating]` prune control computes `opacity:0.55`/`pointer-events:none`; then `window.liveSocket.connect()` → banner hidden, control re-enabled. Drive on `/audit/policy/retention` (real prune button) after opening the prune modal. Fallback if `disconnect()` doesn't reliably set `.phx-error`: `page.context().setOffline(true)` or `page.routeWebSocket("**/live/**", ws => ws.close())`.

### Claude's Discretion
- **D-14:** Exact new fixture/story IDs and per-path fixture shapes; the shared-shell component name/slot API; detector test-file organization (global vs per-page module split); the Tier B `tolerance` for centering geometry; whether to add the 768 mid-breakpoint error cell — match the 171–177 conventions, the `@required_cases` fixture idiom, and the ledger parity rules. Page copy touched during a footgun fix follows brand voice but the systematic IA/microcopy sweep is Phase 179 (do not pre-empt).

### Deferred Ideas (OUT OF SCOPE)
- **Microcopy / IA sweep** — Phase 179. Copy touched while fixing a footgun follows brand voice, but the systematic GOV.UK least-surprise / banned-vocabulary / domain-language pass is 179. Do not pre-empt.
- **Formal accessibility + motion + adversarial sign-off** — Phase 180. We *build to* WCAG 2.2 AA and motion-token compliance here, but the automated axe scan on opened dialogs/menus, manual keyboard + screen-reader pass, and adversarial regression closeout land in 180.
- **Thicker Tier B sampling** (768 mid-breakpoint error cell, per-page keyboard/reconnect granularity) — start with the ~66-cell high-signal sample (D-02); promote cells only if a real regression slips through Tier A.
- **Real-LiveView audit of the full 7-path matrix** — kept to static fixtures for determinism (D-03); only live loading/reconnect run against real LiveViews.
- **Aligning inner `tl-short-content` to constrain the changes list** (D-09b) — opportunistic, not required for PAGE-03 acceptance.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-01 | Each of 11 pages audited against happy/empty/loading/error/permission-denied/boundary/advanced × dark/light/system × 320/375/768/1024/1440 × keyboard-only × reduced-motion × LiveView reconnect, recorded in the ledger | Tier A `rendered_to_string`+`=~` idiom verified in `component_contract_test.exs:30-55`; `@required_cases` taxonomy verified (`stress_fixtures.ex:4-21`); `@theme_modes`/`@viewports` verified; ledger ratchet test verified (`stress_ledger_test.exs:101-120`); 11 reserved `page.*.reserved` entries (score 35, owner 178) verified in `design-system-ledger.json` |
| PAGE-02 | 11 named footgun classes eliminated | `contrast_ratio/2`+`composite` engine verified (`style_contract_test.exs:723,751-773`); z-order ascending guard + reconnect Tier-A verified (`component_contract_test.exs:243-275`); Playwright `boundingBox`/within-viewport (`operator-phase-177-uat.spec.ts:54,83`) + `expectFocused`/Esc (`operator-accessibility.spec.ts:18,88`) verified |
| PAGE-03 | Transaction page centers correctly at desktop (resolves `transaction-page-left-push-desktop`) | Bug confirmed: `transaction_live.ex:100` uniquely puts `tl-container` on grid-item `<main>`; `.tl-container` (`style.ex:675-678`) has `max-width:1000px; margin:0 auto`; grid item is `grid-column:2` (`style.ex:3926-3936`); no `justify-self` anywhere in `style.ex` today; reserved footgun story verified (`stress_fixtures.ex:455-461`) |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Page composition / shell wrapper | Frontend (LiveView render) | — | The 11 LiveViews + the new shared shell component own DOM structure; `@doc false` private function components, no public API |
| Connection-lifecycle UI (reconnect banner, mutating-control dimming) | Browser (CSS keyed off phoenix client classes) | Frontend (LiveView mounts banner once) | `.threadline-ui.phx-loading/.phx-error` classes are applied client-side by phoenix_live_view JS; the banner + `[data-tl-mutating]` dimming is pure CSS — zero new JS/deps (D-11) |
| Layout centering (PAGE-03) | Browser (CSS grid) | — | Pure CSS-grid item alignment; `justify-self` is a browser layout property, not server logic |
| Tier A structural assertions | Test (Elixir, ExUnit + `Phoenix.LiveViewTest`) | — | `render_component`/`rendered_to_string` execute in-process, DB-free; assert DOM substrings + CSS source |
| Tier B geometry/contrast/focus | Test (Playwright real-engine) | Browser (real Chromium computes layout) | Only a real engine yields true `boundingBox`, computed `opacity`/`pointer-events`, and live focus order; required for centering + socket-drop |
| Destructive mutation enforcement (prune) | API/Backend (LiveView `handle_event` server-side) | — | `secure_compare` + authz re-check + audit-the-action are server-enforced (`retention_history_live.ex:48-80`); `data-tl-mutating` is affordance only, never enforcement (Pitfall-6) |

## Standard Stack

No new packages. v1.37 invariant: **zero new runtime deps, inline assets only**. The phase composes and guards existing infra.

### Core (already in place — verified versions)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.30 [VERIFIED: mix.lock:34] | The 11 operator LiveViews; connection-lifecycle client classes | Project's render layer; `.phx-loading`/`.phx-error` are LV's own client classes |
| `phoenix` | ~> 1.7 (optional) [VERIFIED: mix.exs:60] | Web framework | Host-app integration; optional dep per OSS-lib discipline |
| `lazy_html` | 0.1.11 (test only) [VERIFIED: mix.lock:21] | LiveViewTest DOM backend (LV 1.1 replaced Floki) | Test-only; **does not affect** the locked Tier A idiom (see Pitfall 2) |
| Playwright | (example app e2e) [VERIFIED: examples/.../e2e/] | Tier B real-engine geometry/contrast/focus/socket-drop | Established 173/175/177 Tier B harness |

### Supporting (verification entrypoints — cite verbatim per CLAUDE.md)
| Entrypoint | Purpose | When to Use |
|---------|---------|-------------|
| `mix verify.test` [VERIFIED: mix.exs:15] | Run Tier A contract suite | Every PR — proves full structural cartesian |
| `mix ci.all` [VERIFIED: mix.exs:12] | Full verification | Pre-merge gate |
| `examples/threadline_phoenix/e2e/run-e2e.sh` [VERIFIED: file exists] | Tier B Playwright (incl. `--project=desktop-chromium-light`) | `verify-example-browser` lane |

**Installation:** None. `mix deps.get` already satisfied; no new deps permitted (v1.37 invariant).

## Package Legitimacy Audit

Not applicable — this phase installs **no external packages** (zero-new-runtime-deps invariant). All tooling (phoenix_live_view, lazy_html, Playwright) is pre-existing and verified present in `mix.lock` / the example app. No registry verification required.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────────────────────┐
   PR push ───────────►  │  Tier A: mix verify.test (ExUnit, in-proc)    │
                         │  render_component / rendered_to_string + =~   │
                         │  ┌─────────────────────────────────────────┐ │
   @required_cases ────► │  │ stress_fixtures → /audit/__stress stories │ │  proves FULL
   (static, DB-free)     │  │ page.<x>.{7 paths} × theme × viewport     │ │  structural
                         │  └─────────────────────────────────────────┘ │  cartesian
                         │  + global style.ex source scans (footguns)    │  (~1,155 cells)
                         │  + ledger ratchet parity (stress_ledger_test) │
                         └───────────────────┬─────────────────────────┘
                                             │ green required
                                             ▼
                         ┌─────────────────────────────────────────────┐
   verify-example ─────► │  Tier B: Playwright real Chromium             │
   -browser              │  ┌─────────────┐   ┌──────────────────────┐  │  proves
                         │  │ static       │   │ REAL /audit/* views   │  │  representative
                         │  │ /audit/__    │   │ • loading→terminal    │  │  sample
   liveSocket ─────────► │  │ stress       │   │ • socket-drop:        │  │  (~66 cells)
   .disconnect()         │  │ geometry/    │   │   liveSocket.disconnect│ │
   /.connect()           │  │ contrast/    │   │   → .tl-reconnect-banner│ │
                         │  │ focus        │   │   visible, [data-tl-   │  │
                         │  │ (66 cells)   │   │   mutating] opacity .55 │  │
                         │  └─────────────┘   └──────────────────────┘  │
                         └─────────────────────────────────────────────┘
                                             │
                                             ▼
                         ┌─────────────────────────────────────────────┐
   shared shell ──────►  │  Runtime: .threadline-ui (LV render-root)     │
   (D-10 new)            │  ├─ reconnect_banner (mounted ONCE, D-10/D-11)│
                         │  ├─ #tl-main grid-item (grid-column: 2)        │
                         │  │   └─ .tl-container justify-self:center (D-09)│
                         │  └─ phx-loading/phx-error → banner + dim CSS   │
                         └─────────────────────────────────────────────┘
```

### Recommended Project Structure (where new work lands)
```
lib/threadline/operator_surface/
├── ui.ex                    # + shared shell/chrome function component (D-10); reconnect_banner/1 mounted here
├── style.ex                 # .tl-container += justify-self:center (D-09); footgun CSS source-of-truth
├── stress_fixtures.ex       # + page.<x>.{7-path} stories; transaction footgun story (:455-461)
├── live/
│   ├── *_live.ex            # all 11 routed through the shared shell; mutating controls += data-tl-mutating (D-12)
│   └── stress_live.ex       # /audit/__stress hosts page path stories + per-page footgun detectors
test/threadline/operator_surface/
├── component_contract_test.exs   # Tier A: z-order, reconnect structural, focus hooks
├── style_contract_test.exs       # Tier A: contrast_ratio footguns #10/#11; justify-self guard (#PAGE-03 Tier A)
├── stress_ledger_test.exs        # ratchet parity (upward-only)
└── stress_fixtures_test.exs      # reserved-story assertions
examples/threadline_phoenix/e2e/tests/
└── operator-phase-178-uat.spec.ts (new)  # Tier B: centering geometry, footgun sweep, real socket-drop
```

### Pattern 1: Tier A render-contract via substring assertion (parser-agnostic)
**What:** Assert DOM structure and CSS hooks by string-matching `rendered_to_string(~H"...")` output with `=~`, not by Floki/LazyHTML tree traversal.
**When to use:** All Tier A footgun and structural detectors. This is the established 173/175/177 idiom.
**Example:**
```elixir
# Source: test/threadline/operator_surface/component_contract_test.exs:30-40 [VERIFIED]
html =
  rendered_to_string(~H"""
  <UI.data_panel ...>
  """)

assert html =~ ~s(data-state="ok")
assert html =~ ~s(<span id="pager">1 of 3</span>)
assert html =~ "tl-data-panel__pager"
```

### Pattern 2: CSS-grid item centering (PAGE-03 fix)
**What:** Center a `max-width`-capped element that is a grid item using `justify-self: center`, NOT `margin: 0 auto`.
**When to use:** Any grid-item that must center within its column. `margin: 0 auto` works for *block* flow but a grid item under default `justify-self: stretch` ignores auto-margins for centering once `max-width` caps it — it anchors to the column start (left).
**Example:**
```css
/* Source: style.ex:675-678 (current — buggy on grid item) [VERIFIED] */
.tl-container { max-width: 1000px; margin: 0 auto; }
/* Fix (D-09): add justify-self: center, keep max-width */
.tl-container { max-width: 1000px; margin: 0 auto; justify-self: center; }
```

### Pattern 3: Real socket-drop via exposed liveSocket (D-13)
**What:** Drive a genuine dropped socket in Playwright to exercise the real `.phx-error` class path.
**When to use:** The one reconnect Tier B spec per the sampling rule. Fixtures cannot simulate a real dropped socket — this is the gap SEED-005 closes.
**Example:**
```javascript
// Source: app.js:12 exposes window.liveSocket [VERIFIED]
await page.evaluate(() => window.liveSocket.disconnect());
await expect(page.locator(".tl-reconnect-banner")).toBeVisible();
await expect(page.locator("[data-tl-mutating]").first())
  .toHaveCSS("pointer-events", "none");   // computed, real engine
await page.evaluate(() => window.liveSocket.connect());
await expect(page.locator(".tl-reconnect-banner")).toBeHidden();
// Fallback if disconnect() doesn't reliably set .phx-error:
//   await page.context().setOffline(true)
//   await page.routeWebSocket("**/live/**", ws => ws.close())
```

### Anti-Patterns to Avoid
- **`margin: 0 auto` to center a grid item** — root cause of PAGE-03; reverting to it silently reintroduces the left-push (the Tier A `justify-self` guard exists precisely to make this impossible).
- **Keying reconnect CSS off `<body>` or `.phx-disconnected`** — D-11 forbids; the render-root `.threadline-ui` is the correct and only anchor (legacy `.phx-disconnected` is a phoenix_live_view <1.0 class).
- **Floki tree traversal in Tier A** — the codebase uses substring `=~` assertions; introducing Floki/LazyHTML traversal diverges from the idiom for no gain (see Pitfall 2).
- **Treating `data-tl-mutating` / `aria-disabled` as enforcement** — affordance only (Pitfall-6, `ui.ex:1065-1071`); server-side `secure_compare`+authz is the real gate for prune.
- **Pixel-diff / screenshot baselines** — explicitly forbidden (deterministic, baseline-free). Note: `operator-screenshot-regression.spec.ts` exists but the locked stance is structural/geometry assertions, not new pixel baselines.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WCAG contrast for footguns #10/#11 | A new contrast calculator | `contrast_ratio/2` + `composite/2` (`style_contract_test.exs:723,751-773`) | Already handles alpha-composited tints over per-mode opaque bases; battle-tested in 168 |
| Overlay stacking check (#2) | Manual z-index reasoning | z-token ascending guard (`component_contract_test.exs:243-260`) + `elementFromPoint` hit-test (173 spec) | Token-order invariant catches reordering regressions structurally |
| Focus enter/restore (#3/#4) | Custom focus tracking | `JS.focus_first`/`phx-mounted` presence (Tier A) + `toBeFocused`/`expectFocused` (`operator-accessibility.spec.ts:18`) | LiveView-native; real-engine focus is the only honest check |
| Within-viewport / no-h-scroll (#6) | Custom overflow math | `boundingBox` within-viewport helper (`operator-phase-177-uat.spec.ts:54,83`) | Real Chromium layout; extend, don't reinvent |
| Disabled affordance (#5/#7) | New disabled styling | existing `not-allowed`/`toBeDisabled` + `is-disabled`+`aria-disabled` (`ui.ex:710`) | Pitfall-6 link-vs-button distinction already encoded |
| Ledger ratchet enforcement | Manual score bookkeeping | `stress_ledger_test.exs:101-120` upward-only assertion | Structurally prevents silent score regressions |
| Shell wrapper per page | Inline banner into 11 renders | One shared `@doc false` shell component (D-10) | The wrapper is already hand-maintained 11×; converging it is the correct structural home |

**Key insight:** Nearly every detector this phase needs already exists as in-repo infra. The phase is composition + guarding + one CSS line, not new tooling. The single largest *structural* change is extracting the duplicated shell (verified: 11 files carry `class="threadline-ui"`).

## Runtime State Inventory

This is an integration/audit/fix phase touching CSS, LiveView markup, fixtures, and tests — **no datastore, no OS-registered state, no secrets are renamed or migrated**. Explicit per-category findings:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — phase audits rendered pages with static `@required_cases` fixtures (DB-free) and a small set of read-only real-LiveView Tier B specs; no schema/data changes | None |
| Live service config | None — no external services; `/audit/__stress` is dev/test-gated route config already present | None |
| OS-registered state | None — no schedulers, daemons, or process registrations involved | None |
| Secrets/env vars | None — prune flow uses existing server-side `secure_compare`; no new secrets/env vars | None |
| Build artifacts | The `DESIGN-SYSTEM.md` projection is a generated artifact asserted-fresh against `design-system-ledger.json` (D-04); raising scores requires regenerating/refreshing it so the freshness test stays green | Refresh `DESIGN-SYSTEM.md` projection after ledger score raises |

## Common Pitfalls

### Pitfall 1: `.tl-home` is a latent twin of the PAGE-03 bug (NOT in scope — flag for planner)
**What goes wrong:** `.tl-home` (`style.ex:689-692`) carries the *identical* `max-width:1000px; margin:0 auto` and is placed on a grid-item `<main class="tl-page tl-home">` in `start_live.ex`. At ≥768px it is a grid item (`grid-column:2` via the `.threadline-ui > :not(...)` catch-all at `style.ex:3933-3936`), so it almost certainly left-pushes exactly like the transaction page.
**Why it happens:** Same root cause (D-08) — `margin:0 auto` doesn't center a grid item. The CONTEXT claim that "Coverage/timeline center because they use bare `tl-page`" is correct, but Home is NOT bare — it adds the same capping wrapper.
**How to avoid:** Planner decides: (a) extend the one-line `justify-self: center` fix to `.tl-home` (cheap, same class, prevents a known-good page from silently shipping the bug), or (b) scope strictly to PAGE-03's `tl-container` and capture Home as a follow-up. The PAGE-01 Tier B Home cell (320+1440) should detect it regardless — but only if the centering assertion runs on Home, not just transactions.
**Warning signs:** Home content visibly left-anchored at 1440 with empty right gutter inside column 2. `[ASSUMED]` that Home left-pushes — confirmed structurally (same CSS + same grid placement) but not visually rendered this session.

### Pitfall 2: Floki→LazyHTML migration (LV 1.1) — a non-issue for the locked idiom
**What goes wrong:** LiveView 1.1 moved `LiveViewTest` from Floki to LazyHTML; teams sometimes assume Tier A DOM assertions break.
**Why it happens:** `mix.lock` shows `lazy_html 0.1.11` as a test dep — looks like a parsing-backend change.
**How to avoid:** The codebase asserts via `rendered_to_string(...) =~ "..."` substring matching (`component_contract_test.exs:30-55`), which is **parser-agnostic** — it operates on the raw HTML string, not a parsed tree. No detector needs `Floki.find`. Keep using `=~`. [VERIFIED: component_contract_test.exs uses only `rendered_to_string` + `=~`, no Floki import]

### Pitfall 3: Real socket-drop flakiness in Tier B
**What goes wrong:** `window.liveSocket.disconnect()` may not deterministically apply `.phx-error` (vs `.phx-loading`) before the assertion, or the auto-reconnect fires before the banner-visible assert.
**Why it happens:** LiveView's reconnect backoff and the client-class transition (`phx-loading` during reconnect attempts, `phx-error` on failure) are timing-sensitive.
**How to avoid:** Assert against *either* `.phx-loading` or `.phx-error` for banner-visible (the CSS reveals on both — `style.ex:3409-3410`). Use the D-13 fallback ladder: `disconnect()` → `setOffline(true)` → `routeWebSocket(..., ws => ws.close())` for a hard, sustained drop. Use Playwright `expect().toBeVisible()` auto-retry rather than a fixed wait.
**Warning signs:** Intermittent banner-not-visible failures; banner flickers then hides before assert.

### Pitfall 4: Tier B centering tolerance too tight
**What goes wrong:** `|center_x − viewport/2| ≤ tolerance` (D-09 guard) fails on sub-pixel rounding or scrollbar-gutter offsets.
**Why it happens:** `boundingBox` returns fractional pixels; a vertical scrollbar shifts the effective viewport center; `column-gap`/nav-column asymmetry means content center ≠ viewport center (content is centered within **column 2**, not the full viewport).
**How to avoid:** Center the assertion on the **grid column 2 region**, not the raw viewport — or set a generous tolerance (D-14 leaves this to discretion). At ≥768px the nav column (`minmax(196px,232px)`) offsets content right of true viewport center by design. Measure centering *within the available content column*, or assert symmetric left/right gutters of the `.tl-container` inside its column.
**Warning signs:** Centering test fails at 1024 but the page looks correct — almost always the nav-column offset being measured against full viewport.

### Pitfall 5: `data-tl-mutating` on the wrong control set
**What goes wrong:** Marking no-op stubs or read-only controls disabled-on-disconnect, or forgetting `aria-disabled`+`tabindex=-1` on links.
**Why it happens:** Several timeline/export controls look mutating but are queue stubs or downloads; links can't take HTML `disabled`.
**How to avoid:** Follow D-12 exactly — primary set is `prune_now` (`retention_history_live.ex:299`), `save-view` (`timeline_live.ex:703`), `delete-view` (`timeline_live.ex:720`); download/export **links** get `data-tl-mutating` + `aria-disabled="true" tabindex="-1"` (Pitfall-6, `ui.ex:1065-1071`); skip the no-op queue stubs; `policy_redaction_live.ex` is read-only. [VERIFIED: handle_event names + form pegs in timeline_live.ex and retention_history_live.ex]

### Pitfall 6: Ledger ratchet — raising a score below `ratchet_score` without a reset
**What goes wrong:** A `current_score` raise that accidentally lands below the recorded `ratchet_score` fails `stress_ledger_test.exs` and requires a `reset_rationale` in `ratchet.resets`.
**Why it happens:** The upward-only invariant (`stress_ledger_test.exs:112-120`) treats any drop below `ratchet_score` as a regression.
**How to avoid:** When converting `reserved` (35) → fixture-backed, raise `current_score` monotonically toward `target_score: 90`; maintain `story_id`/`fixture_key` parity; refresh `DESIGN-SYSTEM.md`. Never lower a score without an explicit reset entry. [VERIFIED: stress_ledger_test.exs:101-120]

## Code Examples

### Footgun #10/#11 contrast detector (reuse the engine)
```elixir
# Source: test/threadline/operator_surface/style_contract_test.exs:723,751-773 [VERIFIED]
assert contrast_ratio(tokens[text_token], tokens[background_token]) >= 4.5
# alpha-composited tints (catches same-color-text-on-bg, #11):
over_dark = composite(danger_bg, "#141B2D")
assert contrast_ratio("#A33434", over_dark) >= 4.5
```

### Footgun #2 z-order ascending guard
```elixir
# Source: test/threadline/operator_surface/component_contract_test.exs:243-260 [VERIFIED]
# z-layer tokens must be strictly ascending so overlays stack above scrim above page
assert values == Enum.sort(values),
  "z-layer tokens must be strictly ascending, got: #{inspect(Enum.zip(layers, values))}"
```

### Reconnect Tier A structural half
```elixir
# Source: component_contract_test.exs:267-275 [VERIFIED]
html = rendered_to_string(~H"<UI.reconnect_banner />")
assert html =~ "tl-reconnect-banner"  # + role=status + refresh glyph
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `LiveViewTest` on Floki | `LiveViewTest` on LazyHTML | LiveView 1.1 | None here — codebase uses substring `=~`, not tree traversal (Pitfall 2) [CITED: phoenix-live-view-best-practices-deep-research.md:1] |
| Inline banner per render / 11-way duplication | Single shared shell component, banner mounted once (D-10) | This phase | Kills drift; correct structural home for shell changes |
| 177 inject-probe simulating reconnect | Real `window.liveSocket.disconnect()` socket-drop (D-13) | This phase | Closes the 177 unmounted-banner gap with a genuine dropped socket |
| `margin: 0 auto` centering on grid item | `justify-self: center` (D-09) | This phase | Grid-native centering; guarded against silent revert |

**Deprecated/outdated:**
- `.phx-disconnected` — legacy phoenix_live_view <1.0 class; D-11 forbids. Current classes are `.phx-loading`/`.phx-error` on the render-root `.threadline-ui`. [CITED: phoenix-live-view-best-practices-deep-research.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `.tl-home` visually left-pushes at ≥768px (same as transaction) | Pitfall 1 | LOW — structurally identical CSS + grid placement confirmed; only the rendered visual not eyeballed this session. If wrong, Home simply needs no fix; the Tier B Home centering cell will confirm either way |
| A2 | `window.liveSocket.disconnect()` reliably triggers the banner in the example app's Chromium | Pattern 3 / Pitfall 3 | LOW — `window.liveSocket` exposure verified (`app.js:12`); D-13 already documents the `setOffline`/`routeWebSocket` fallback ladder if timing is flaky |

**Note:** All other claims are `[VERIFIED]` against live source this session — every CONTEXT code peg was checked.

## Open Questions (RESOLVED)

1. **Should the D-09 fix extend to `.tl-home`?**
   - What we know: `.tl-home` has identical capping CSS on a grid-item `<main>`; the same root cause applies.
   - What's unclear: Whether PAGE-03 acceptance is scoped strictly to `tl-container`/transactions, or whether the planner folds in the cheap one-line `.tl-home` fix.
   - Recommendation: Add `justify-self: center` to `.tl-home` too (same line, same risk profile) and add a Home centering Tier B cell — this is well within "fix opportunistically when the same footgun class is found" and avoids shipping a known latent bug. Flag explicitly so it's a conscious planner decision, not an accidental scope creep.
   - **RESOLVED:** Fold in. Backed by D-09 + Pitfall 1. Plan 178-01 authors the `.tl-home` `justify-self: center` Tier A RED guard + Home centering Tier B cell; Plan 178-03 Task 1 applies the one-line fix to `.tl-home` (style.ex:689) alongside `.tl-container`, as an explicit, visibly-noted deliverable (neither silently dropped nor silently expanded).

2. **Centering tolerance and the nav-column offset (D-14 discretion).**
   - What we know: At ≥768px content lives in grid column 2, offset right of true viewport center by the nav column width.
   - What's unclear: Whether the Tier B centering assertion measures within column 2 or against full viewport.
   - Recommendation: Measure symmetric gutters of `.tl-container` within its column (or assert against column-2 center), not raw `viewport/2` — see Pitfall 4. Planner picks the tolerance.
   - **RESOLVED:** Measure within grid column 2 (not raw `viewport/2`), per Pitfall 4. Locked to D-14 planner/executor discretion; Plan 178-03 Task 2 selects the concrete tolerance.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix + ExUnit | Tier A contract suite | ✓ | (project toolchain) | — |
| `phoenix_live_view` | LiveViews + connection classes | ✓ | 1.1.30 | — |
| `lazy_html` (test) | LiveViewTest backend | ✓ | 0.1.11 | — |
| Playwright + Chromium | Tier B geometry/contrast/focus/socket-drop | ✓ | example-app e2e (`run-e2e.sh`, `playwright.config.ts` lanes verified) | — |
| `desktop-chromium-light` lane | Light-theme Tier B | ✓ | `playwright.config.ts:22-30` | — |
| `reducedMotion: "reduce"` project | Reduced-motion Tier B | ✓ | `playwright.config.ts:52` | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — all Tier A and Tier B infra is present and verified.

## Validation Architecture

> Nyquist validation is enabled (`config.json: "nyquist_validation": true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework (Tier A) | ExUnit + `Phoenix.LiveViewTest` (phoenix_live_view 1.1.30, lazy_html backend) |
| Framework (Tier B) | Playwright (example app), Chromium real-engine |
| Config file (Tier A) | `mix.exs` test env / `test/test_helper.exs` |
| Config file (Tier B) | `examples/threadline_phoenix/e2e/.../playwright.config.ts` (dark, `desktop-chromium-light`, `reducedMotion: "reduce"` lanes) |
| Quick run command | `mix verify.test` |
| Full suite command | `mix ci.all` (Tier A) + `examples/threadline_phoenix/e2e/run-e2e.sh` (Tier B) |

### The Two-Tier Honesty Contract (load-bearing — state verbatim in the verification doc)
The literal PAGE-01 matrix is ~3,465 cells (11 pages × 7 paths × 3 themes × 5 viewports × keyboard/reduced-motion/reconnect). A green suite must **never** imply all 3,465 cells were eyeballed. The split:
- **Tier A proves the FULL structural cartesian** (~1,155 page×path×theme×viewport cells): each renders, carries the right `data-state`, doesn't loud-fail, and emits the right keyboard/reduced-motion/reconnect CSS hooks. Runs every PR via `mix verify.test`. In-process, DB-free, deterministic.
- **Tier B proves a REPRESENTATIVE high-signal sample** (~66 cells): per page 320 floor + 1440 ceiling, happy + worst-case (error/empty), dark + light, plus one keyboard-only, one reduced-motion, one reconnect spec. Runs on `verify-example-browser`. Real Chromium — the only honest source of geometry, computed style, and live focus/socket behavior.
- **Never pixel-diff** (deterministic, baseline-free).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Tier | Automated Command | File Exists? |
|--------|----------|-----------|------|-------------------|-------------|
| PAGE-01 | All 11 pages × 7 paths × 3 themes × 5 viewports render, carry `data-state`, don't loud-fail, emit kbd/reduced-motion/reconnect hooks | structural (full cartesian) | A | `mix verify.test` | ✅ extend `component_contract_test.exs` + `stress_fixtures_test.exs` |
| PAGE-01 | Representative ~66 cells render correctly in real engine (320/1440 × happy/worst × dark/light + kbd + reduced-motion + reconnect) | geometry/render | B | `run-e2e.sh` | ❌ Wave 0: `operator-phase-178-uat.spec.ts` |
| PAGE-01 | 11 reserved page entries → fixture-backed, score→90, parity + projection fresh | ledger ratchet | A | `mix verify.test` | ✅ `stress_ledger_test.exs` (extend ledger data) |
| PAGE-02 #1 scroll traps | no nested-scroll trap; sticky never occludes; `overscroll-behavior:contain`/`100svh` | CSS-source + sweep | A+B | both | ✅ A scan style.ex / ❌ B sweep route |
| PAGE-02 #2 modal behind scrim | z-token ascending + `elementFromPoint` hit-test | structural + hit-test | A+B | both | ✅ `component_contract_test.exs:243` / extend 173 spec |
| PAGE-02 #3/#4 focus enter/restore + Esc/click-outside | `JS.focus_first`/`phx-mounted` present; `toBeFocused`/Esc-returns-focus | structural + real focus | A+B | both | ✅ `operator-accessibility.spec.ts:18` |
| PAGE-02 #5/#7 hover-on-non-interactive / disabled-looks-enabled | no `cursor:pointer`/hover on non-interactive; real `disabled`/`aria-disabled`+`not-allowed` | CSS-source + computed | A+B | both | ✅ `ui.ex:710` pattern + 173 spec |
| PAGE-02 #6 misalignment/spacing | spacing resolves to `--tl-space-*`/gap tokens; `boundingBox` within-viewport 320–1440 | CSS-source + geometry | A+B | both | ✅ A token scan / ❌ B `operator-phase-177-uat.spec.ts:83` extend |
| PAGE-02 #8 missing tab active-state | `aria-current`/`aria-selected` distinct-bg + non-color cue | structural | A+B | both | ✅ extend contract test |
| PAGE-02 #9 weird pagination | `UI.pager` disabled-at-edge, hide-at-zero, honest cap caption | structural + real | A+B | both | ✅ `component_contract_test.exs:39` pager pattern |
| PAGE-02 #10/#11 contrast / same-color text-on-bg | `contrast_ratio/2`+`composite` ≥4.5 both themes, alpha-aware | unit (engine) | A | `mix verify.test` | ✅ `style_contract_test.exs:723,751-773` extend per role |
| PAGE-03 | `.tl-container` carries `justify-self: center` (guards silent revert) | CSS-source | A | `mix verify.test` | ❌ Wave 0: add `justify-self` assertion to `style_contract_test.exs` |
| PAGE-03 | transaction content bounding box centered at 1024 + 1440 (`|center − col-center| ≤ tol`) | geometry | B | `run-e2e.sh` | ❌ Wave 0: `operator-phase-178-uat.spec.ts` |
| SEED-005 | real socket-drop: banner visible + `[data-tl-mutating]` opacity .55/pointer-events none; reconnect re-enables | real socket lifecycle | B | `run-e2e.sh` | ❌ Wave 0: `operator-phase-178-uat.spec.ts` (replaces 177 inject-probe) |
| SEED-005 | reconnect_banner mounted once in shared shell; structural reconnect contract | structural | A | `mix verify.test` | ✅ `component_contract_test.exs:267` extend for shell |

### Sampling Rate
- **Per task commit:** `mix verify.test` (Tier A — fast, full structural cartesian + footgun guards + ledger ratchet)
- **Per wave merge:** `mix ci.all` + `examples/threadline_phoenix/e2e/run-e2e.sh` (Tier A full + Tier B representative sample)
- **Phase gate:** Both tiers green before `/gsd-verify-work`; `DESIGN-SYSTEM.md` projection asserted fresh; all 11 reserved page entries at ratchet target.

### Wave 0 Gaps
- [ ] `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` — new Tier B spec: centering geometry (PAGE-03), footgun sweep over `/audit/*`, real socket-drop (SEED-005, replaces 177 probe), the ~66-cell high-signal sample
- [ ] `style_contract_test.exs` — add `.tl-container` `justify-self: center` assertion (PAGE-03 Tier A guard); extend `contrast_ratio` coverage to every text/bg role pairing in both themes
- [ ] `stress_fixtures.ex` — add `page.<x>.{happy,empty,loading,error,permission,boundary,advanced}` stories for all 11 pages (D-14 IDs/shapes)
- [ ] `design-system-ledger.json` — convert 11 reserved page entries to fixture-backed, raise scores; raise `footgun.transaction-page-left-push-desktop` (25→90) and the two baselines
- [ ] No framework install needed — Tier A (ExUnit/LiveViewTest) and Tier B (Playwright) are both present.

## Security Domain

> `security_enforcement` not explicitly disabled — included. This phase is audit/fix of an existing surface; the only mutating path touched is the prune flow, whose enforcement is pre-existing and server-side.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth changes; host-app owns auth |
| V3 Session Management | partial | LiveView socket lifecycle (reconnect) — UI affordance only, not a security boundary |
| V4 Access Control | yes (unchanged) | Prune re-checks authz server-side (`retention_history_live.ex:48-80`); `data-tl-mutating`/`aria-disabled` are affordance, NOT enforcement (Pitfall-6) |
| V5 Input Validation | yes (unchanged) | Prune type-to-confirm via server-side `secure_compare(typed, canonical)`; client confirm is UX only |
| V6 Cryptography | yes (unchanged) | `secure_compare` (constant-time) for prune confirmation — never hand-roll string equality |

### Known Threat Patterns for the operator surface
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Client-disabled control treated as enforcement | Elevation of Privilege | `data-tl-mutating`+`aria-disabled` are affordance only; server-side authz + `secure_compare` + fail-closed is the gate (D-12, Pitfall-6) — DO NOT weaken during shell extraction |
| Inline CSS/JS under CSP | Tampering | Inline assets only, CSP-proof, zero new JS/deps (v1.37 invariant) — reconnect uses LV's own client classes, no new script |
| Stress route exposed in prod | Information Disclosure | `/audit/__stress` is dev/test-gated (existing route config) — must stay gated |

**Critical preservation note:** D-10's shell extraction must NOT route mutating events around the existing server-side prune enforcement. The shell wraps chrome (banner, header, `#tl-main`); `handle_event("prune_now", ...)` enforcement (`retention_history_live.ex:48-80`) stays in the page LiveView untouched.

## Sources

### Primary (HIGH confidence — verified against live source this session)
- `lib/threadline/operator_surface/style.ex` — `.tl-container:675-678`, `.tl-home:689-692`, grid shell `:3890-3936`, reconnect/offline CSS `:3405-3424`, `.tl-short-content:2887`, no `justify-self` present today
- `lib/threadline/operator_surface/live/*.ex` — 11 `threadline-ui` wrappers; `transaction_live.ex:100` (only page with `tl-container` on main); mutating-control pegs in `timeline_live.ex` (`save-view:197`, `delete-view:231`, links `:667-694`) and `retention_history_live.ex` (`prune_now:67`)
- `lib/threadline/operator_surface/ui.ex` — `reconnect_banner/1:1075`, Pitfall-6 contract `:1065-1071`, disabled toolbar pattern `:710`
- `lib/threadline/operator_surface/stress_fixtures.ex` — `@required_cases:4-21`, transaction footgun reserved story `:455-461`
- `test/threadline/operator_surface/component_contract_test.exs` — `rendered_to_string`+`=~` idiom `:30-55`, z-order guard `:243-260`, reconnect structural `:267-275`
- `test/threadline/operator_surface/style_contract_test.exs` — `contrast_ratio/2`+`composite` `:723,751-773`
- `test/threadline/operator_surface/stress_ledger_test.exs` — upward-only ratchet `:101-120`
- `examples/threadline_phoenix/priv/static/assets/app.js:12` — `window.liveSocket` exposed
- `examples/threadline_phoenix/e2e/.../playwright.config.ts` — dark + `desktop-chromium-light:22-30` + `reducedMotion:"reduce":52` lanes
- `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts:54,83` (boundingBox/within-viewport) + `operator-accessibility.spec.ts:18,88` (`expectFocused`)
- `mix.exs` / `mix.lock` — phoenix_live_view 1.1.30, lazy_html 0.1.11, verify.* aliases

### Secondary (MEDIUM confidence)
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LV 1.1 connection lifecycle (`.phx-loading`/`.phx-error`), Floki→LazyHTML, `assign_async`/`async_result`, JS transitions

### Tertiary (LOW confidence)
- None — no WebSearch needed; phase is fully codebase-grounded.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all versions verified in mix.lock
- Architecture/locked decisions: HIGH — every CONTEXT code peg verified against live source (minor line drift documented; nothing material moved)
- PAGE-03 root cause: HIGH — bug confirmed structurally (unique `tl-container` on grid-item main, no `justify-self` today)
- Pitfalls: HIGH for the verified ones; A1 (Home left-push) MEDIUM (structurally certain, not visually rendered)
- Validation architecture: HIGH — both tiers' infra verified present and extensible

**Research date:** 2026-06-18
**Valid until:** 2026-07-18 (stable internal codebase; re-verify line pegs only if `style.ex`/LiveViews are edited before planning)
