# Phase 178: Per-page & flow stress pass (all 11 pages) - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Stress every operator page (all 11: Home, Timeline, Transaction, Row history, Actor, Coverage, Evidence, Redaction, Retention, Exports, plus the shell) across every path × theme × viewport × keyboard × reduced-motion × LiveView reconnect; eliminate the 11 named footgun classes; and fix the desktop centering bug. Delivers PAGE-01, PAGE-02, PAGE-03.

**Critical reframe (mirrors 175/176/177):** this is the **integration / compose-and-audit** pass, not greenfield. The 11 pages are already assembled from the primitives (173), form controls (174), shell/nav (175), data-display components (176), and groups/meta-components (177) that prior phases extracted and audited *in isolation*. Phase 178 audits them *as whole pages under ugly data* — does each page hold together coherently across the full stress matrix, and do the footgun classes survive composition? The job is: (1) stand up per-page path stories on the stress harness and ratchet them in the ledger, (2) write guard-first detectors for the 11 footgun classes and fix to green, (3) fix the transaction centering bug, (4) fold in SEED-005 (mount the reconnect banner in the shell + wire real mutating controls). The 0-human-UAT campaign (Tier A render-contract + Tier B Playwright) continues here — see [[shift-left-uat-automation]].

**In scope:** per-page path stories (`page.<x>.{happy,empty,loading,error,permission,boundary,advanced}`) on `/audit/__stress`, ratcheted in the design-system ledger; guard-first automated detectors for all 11 footgun classes (Tier A CSS-source/DOM + Tier B geometry/computed-style/focus); the transaction-page `justify-self` centering fix + its regression guard; SEED-005 — extract a shared shell/chrome component, mount `reconnect_banner/1` once, wire `data-tl-mutating` onto real mutating controls, and a real socket-drop Playwright spec replacing the 177 probe; representative Tier B sampling across the matrix; hybrid real-LiveView coverage for the genuinely-live flows (loading→terminal, reconnect).

**Out of scope (other phases):** microcopy / information-architecture sweep (Phase 179 — page copy is decided alongside each fix, not swept); accessibility verification, motion compliance & adversarial closeout (Phase 180 — we *build to* WCAG 2.2 AA here, the formal scan + screen-reader pass + sign-off land there); any public/host-facing component API (v1.31 freeze); capture & semantics layers (untouched); no chart library / zero new runtime deps / inline assets only. No new operator capabilities (e.g. bulk actions — rejected D-176-19) — this is stress/fix of what already exists.

</domain>

<decisions>
## Implementation Decisions

### PAGE-01 — Verification coverage strategy (how we *prove* the matrix, 0-human)
- **D-01:** **Full Tier A cartesian + representative Tier B sample.** The literal PAGE-01 matrix is ~3,465 cells (11 pages × 7 paths × 3 themes × 5 viewports × keyboard/reduced-motion/reconnect). Make it tractable *and honest* by splitting: **Tier A** (Elixir `render_component`/`rendered_to_string` DOM + CSS-source assertions, every PR via `verify-test`) proves the **full structural cartesian** (~1,155 page×path×theme×viewport cells render, carry the right `data-state`, don't loud-fail, emit the right keyboard/reduced-motion/reconnect CSS hooks). **Tier B** (Playwright real-engine) proves a **representative high-signal sample**. Never pixel-diff (deterministic, baseline-free — confirmed preference, 177-VERIFICATION.md). State the split explicitly in the verification doc: "Tier A proves the full matrix structurally; Tier B proves a representative sample renders correctly in a real engine."
- **D-02:** **Tier B sampling rule (the honest core):** per page, ~6 high-signal cells — **320 floor + 1440 ceiling** only, **happy + worst-case path** (error or empty), **dark + light** lanes, plus **one** keyboard-only, **one** reduced-motion, and **one** reconnect spec. ≈ 66 browser cells vs 3,465. High-signal rationale: 320 = overflow floor, 1440 = wide-reflow, error/empty = most layout-fragile, light lane = where theme regressions hide. (320 floor + 1440 ceiling are the established 177 Tier B widths.)
- **D-03:** **Audit substrate = static fixtures + hybrid real-LiveView for live flows.** Audit the 7-path × theme × viewport matrix via deterministic **static fixtures on `/audit/__stress`** (DB-free, no flake — the 171–177 pattern; pages get ugly data from the `@required_cases` fixture library). Drive the genuinely-*live* flows — `loading → terminal` resolution and **reconnect / socket-drop** — against **real `/audit/*` LiveViews** in a small set of Tier B specs. This closes the 177 unmounted-banner follow-up gap exactly where a fixture can't (a real dropped socket), while keeping the bulk matrix deterministic.
- **D-04:** **Ledger ratchet for pages.** Convert each of the 11 reserved page entries (`page.<x>.reserved`, status `reserved`, score 35, owner 178 in `design-system-ledger.json`) into real fixture-backed path stories; raise `current_score` toward `target_score: 90` per the upward-only ratchet (`stress_ledger_test.exs`), maintain `story_id`/`fixture_key` parity, and refresh the `DESIGN-SYSTEM.md` projection (asserted fresh). **"Done" per page** = all 7 paths fixture-backed, score at ratchet target, both tier suites green. The two existing baselines (`page.home.happy`, `page.timeline.empty`, score 62) get raised too.

### PAGE-02 — Footgun elimination (all 11 classes)
- **D-05:** **Guard-first, not fix-first.** For each of the 11 named footgun classes, **write the failing detector first**, watch it fail on today's surface, then fix to green — the ratchet ethos that 173/175/177 already used. Each footgun becomes a *permanent* CI assertion, so "fixed but silently regressed" is structurally impossible. Tier A guards run free every PR; Tier B on `verify-example-browser`.
- **D-06:** **Layered global + per-page detectors.** Make **global cross-page guards** (one Tier-A scan of `style.ex` source + one Tier-B sweep iterating all `/audit/*` routes, which auto-covers new pages) for the classes that are surface-wide: scroll traps, misalignment/chopped-padding/spacing, unreadable contrast, same-color text-on-bg, plus the structural halves of hover/focus-on-non-interactive and disabled-looks-enabled. Make **per-page / per-component** detectors (hosted on the `__stress` story matrix) for the ones needing a specific overlay or pager mounted: modal/drawer scrim & float, overlay focus enter/restore, escape/click-outside, tab active-state, pagination edges.
- **D-07:** **All 11 are automatable — reuse existing infra, don't reinvent.** The detectors extend in-repo patterns: WCAG `contrast_ratio/2` engine (`style_contract_test.exs:697-854`, handles composited tints) covers #10/#11; z-token ascending guard (`component_contract_test.exs:243-261`) + `elementFromPoint` hit-test (173 spec) covers #2; `JS.focus_first`/`phx-mounted` presence (Tier A) + `toBeFocused`/Esc-returns-focus (Tier B) covers #3/#4; cursor/`not-allowed`/`toBeDisabled` (173 spec) covers #5/#7; `aria-current`/`aria-selected` distinct-bg + non-color cue covers #8; pager disabled-edge covers #9; `boundingBox` within-viewport (`177-uat.spec.ts`) covers #6. **Residual manual = essentially zero** — only sub-pixel optical-balance and "focus landed somewhere *sensible*" beyond "inside the overlay" are documented as an *optional, non-blocking* spot-check note (not a UAT gate), per the 0-human-UAT goal.

### PAGE-03 — Transaction-page desktop centering fix
- **D-08:** **Root cause is locked: `margin:0 auto` doesn't center a CSS-grid item.** The transaction page is the only one putting `.tl-container { max-width:1000px; margin:0 auto }` (`style.ex:675-678`) on its `<main>` (`transaction_live.ex:100`), which at ≥768px is a **grid item** (`grid-column:2`, `style.ex:3891-3931`). Under default `justify-self:stretch`, `max-width` caps the item below the column width then anchors it to the **start (left)** — the "left push." Coverage/timeline center because they use bare `tl-page` (no max-width, fill column 2 by design).
- **D-09:** **Fix: add `justify-self: center` to `.tl-container`** (`style.ex:675`), keeping `max-width:1000px`. One-line, markup-untouched, consistent with the shell's grid convention. **Guard:** Tier A asserts `.tl-container` carries `justify-self: center` (guards silent reversion to bare `margin:0 auto` on a grid item); Tier B loads `/audit/transactions/:id` at 1024 + 1440 and asserts the content bounding box is horizontally centered (`|center_x − viewport/2| ≤ tolerance`). The reserved `footgun.transaction-page-left-push-desktop` story (`stress_fixtures.ex:455-461`, score 25 → 90) is the natural Tier-B fixture peg.
- **D-09b [informational]:** Discretionary / opportunistic — NOT a tracked acceptance requirement (explicitly "not required for PAGE-03 acceptance"; see Deferred Ideas). Watch the secondary inconsistency (not the bug itself, fix opportunistically): the inner `tl-transaction tl-short-content` wrapper (`max-width:72ch; margin-inline:auto`, `style.ex:2887-2890`) only wraps the page header, not `#changes-list`/`tl-viewport` — so the changes list is full-width even after the outer fix. Planner to decide whether to align it for visual consistency.

### SEED-005 — Reconnect banner shell mount + mutating-control wiring (folded in)
- **D-10:** **Extract a shared shell/chrome component.** There is **no shared shell** today — all 11 LiveViews duplicate `<div class="threadline-ui">…<Style.css/>…<surface_header/>…<main id="tl-main">`. Pull that wrapper into one internal `@doc false` shell/chrome function component and route all 11 through it. This gives `reconnect_banner/1` a **single mount point** (once, above `#tl-main`, inside `.threadline-ui`) and kills 11-way drift. Larger diff now, but the correct structural home and makes future shell changes one-touch. (Overturns the minimal "inline the banner into 11 renders" option — the wrapper is already hand-maintained 11×; this is the moment to converge it.)
- **D-11 (superseded by 178-05 real-engine evidence; corrected in 178-06):** **Connection-class anchor is `[data-phx-main].phx-*` with `.threadline-ui` descendant scoping.** The earlier locked premise that the LiveView render-root *is* `.threadline-ui` and receives lifecycle classes directly was false for this app. Real Chromium socket-drop proof showed phoenix_live_view applies `phx-loading` / `phx-error` / `phx-client-error` to the `[data-phx-main]` container, which is a parent of `.threadline-ui`. The banner CSS must therefore anchor on `[data-phx-main].phx-loading`, `[data-phx-main].phx-error`, and `[data-phx-main].phx-client-error`, then descend through `.threadline-ui` to `.tl-reconnect-banner` and `[data-tl-mutating]`. **Never** `<body>`, **never** the legacy `.phx-disconnected`.
- **D-12:** **`data-tl-mutating` scope = genuine state-changers now; download links get `aria-disabled`; no-op stubs skipped.** Primary set (real DB mutation): `prune_now` submit (`retention_history_live.ex:299`, destructive — the seed's start point), `save-view` submit (`timeline_live.ex:703`), `delete-view` (`timeline_live.ex:720`). Download/export side-effect **links** (timeline CSV/JSON/NDJSON `:709-733`, export download `export_status_live.ex:296`) carry `data-tl-mutating` **plus** `aria-disabled="true" tabindex="-1"` (Pitfall-6, `ui.ex:1066` — links can't take `disabled`). The no-op export "queue" stubs (`timeline_live.ex:652`, `export_status_live.ex:174`) are skipped — no real mutation. `policy_redaction_live.ex` is read-only (config-driven) — no controls to wire.
- **D-13:** **Real socket-drop Playwright spec replaces the 177 inject-probe.** `window.liveSocket` is exposed globally (`app.js:12`). UAT #4 becomes: `window.liveSocket.disconnect()` → assert the **real** `.tl-reconnect-banner` becomes visible and the **real** `[data-tl-mutating]` prune control computes `opacity:0.55`/`pointer-events:none`; then `window.liveSocket.connect()` → banner hidden, control re-enabled. Drive on `/audit/policy/retention` (real prune button) after opening the prune modal. Fallback if `disconnect()` doesn't reliably set `.phx-error`: `page.context().setOffline(true)` or `page.routeWebSocket("**/live/**", ws => ws.close())`.

### Claude's Discretion (handle per existing conventions)
- **D-14:** Exact new fixture/story IDs and the per-path fixture shapes, the shared-shell component name/slot API, detector test-file organization (global vs per-page split into modules), the Tier B `tolerance` for centering geometry, and whether to add the 768 mid-breakpoint error cell — match the 171–177 conventions, the `@required_cases` fixture idiom, and the ledger parity rules. Page copy touched during a footgun fix follows brand voice but the systematic IA/microcopy sweep is Phase 179 (do not pre-empt it).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — PAGE-01, PAGE-02, PAGE-03; v1.37 invariants (no public API, zero new runtime deps, inline CSS only, CSP-proof, WCAG 2.2 AA, mobile-first 320–1440, brand-token parity, dev/test-gated stress route).
- `.planning/ROADMAP.md` §"Phase 178" — goal + 3 success criteria (the literal stress matrix, the 11 named footgun classes, the transaction centering fix); milestone invariants block.

### The shift-left UAT playbook (the verification contract this phase continues)
- `.planning/phases/177-component-groups-meta-components/177-VERIFICATION.md` + `177-UAT.md` — the proven Tier A/Tier B shift-left pattern; the unmounted-banner follow-up (`:125`) that SEED-005 closes; baseline-free / no-pixel-diff stance.
- `.planning/phases/173-primitive-components-extract-audit-each-in-isolation/` VERIFICATION + UAT — origin of the Tier A/Tier B isolation-audit pattern.
- `.planning/seeds/SEED-005-reconnect-banner-shell-mount.md` — the folded-in implementation follow-up (mount point, mutating controls, real socket-drop done-when).
- `.planning/threads/2026-06-18-shift-left-uat-173-175.md` — handoff note pointing SEED-005 into this phase.

### The idempotency ledger (PAGE-01's worklist + ratchet)
- `DESIGN-SYSTEM.md` + `.planning/design-system-ledger.json` — the 11 reserved `page.<x>.reserved` entries (score 35, owner 178) are PAGE-01's worklist; `footgun.transaction-page-left-push-desktop` (score 25, owner 178) is the PAGE-03 peg; ratchet rule (upward-only) enforced by `test/threadline/operator_surface/stress_ledger_test.exs`.

### Prior phase context (the conventions this phase composes on top of)
- `.planning/phases/177-component-groups-meta-components/177-CONTEXT.md` — **most load-bearing, with Phase 178 D-11 superseding its offline anchor premise.** Keep `stack`/`cluster`/`data_panel`/`toolbar`/`detail_header`/`reconnect_banner`, group motion + reduced-motion blanket, and cross-child state coordination; use `[data-phx-main].phx-* .threadline-ui` for the reconnect/offline anchor. The pages are assembled from these.
- `.planning/phases/176-data-display-operator-patterns/176-CONTEXT.md` — state taxonomy (empty/loading/error/stale/no-data/permission/unavailable), per-state focus/role rules, async branching, "one card boundary per logical unit," charts-inline. The 7 audit paths map onto this taxonomy.
- `.planning/phases/175-navigation-app-shell-runtime-theme-picker/175-CONTEXT.md` — `surface_header`/`page_header`, app-shell + theme picker, CSP-hardening, no-color-alone active-state.

### Code (the pages, the harness, the CSS)
- `lib/threadline/operator_surface/live/*.ex` — the 11 LiveViews (the shared `threadline-ui` + `#tl-main` wrapper to extract; mutating controls to wire). Key pegs: `transaction_live.ex:100` (centering), `retention_history_live.ex:144-145` (banner slot), `:299` (prune); `timeline_live.ex:703/720/709-733` (mutating controls/links).
- `lib/threadline/operator_surface/style.ex` (~3900 lines) — `.tl-container:675-678` (centering fix), grid shell `:3891-3931`, reconnect/offline CSS `:3405-3424`; the source-of-truth for all footgun CSS-source detectors.
- `lib/threadline/operator_surface/stress_fixtures.ex` — `@required_cases:5-19` (ugly-data fixtures); `:455-461` (transaction footgun reserved story); add per-page path stories here.
- `lib/threadline/operator_surface/live/stress_live.ex` — the `/audit/__stress` story browser (theme/viewport params); hosts the page path stories + per-page footgun detectors.
- `lib/threadline/operator_surface/ui.ex` — `reconnect_banner/1:1055` + Pitfall-6 mutating-link contract `:1066`; the shell component composes the existing `surface_header`/`page_header`.
- `examples/threadline_phoenix/` — `priv/static/assets/app.js:12` (`window.liveSocket`), `e2e/tests/operator-phase-177-uat.spec.ts` (overflow/within-viewport/focus/inject-probe helpers to extend), `e2e/tests/operator-accessibility.spec.ts` (`expectFocused`), `playwright.config.ts` (dark + `desktop-chromium-light` lanes).
- `test/threadline/operator_surface/component_contract_test.exs` (Tier A DOM/z-order/reconnect patterns), `style_contract_test.exs:697-854` (`contrast_ratio/2` WCAG engine — reuse for footguns #10/#11), `stress_ledger_test.exs` (ratchet enforcement), `stress_fixtures_test.exs` (reserved-story assertions).

### Brand & domain
- `brandbook/brand-book.md` + `brandbook/tokens.{json,css}` — voice (plainspoken, sentence case, no "!"), non-color-alone rule, focus/hover, 8px radius cap, `--tl-space-*` / motion tokens / contrast pairs (footgun detectors assert against these).
- `prompts/threadline-elixir-oss-dna.md` — quality bar: fail-closed, deterministic tests, explicit composition, no-public-API discipline.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — connection lifecycle (`.phx-loading`/`.phx-error`), `JS` transitions, `assign_async`/`async_result` (the live loading/reconnect flows in D-03).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (extend/compose, don't rebuild)
- **The 11 pages already exist** and are composed from audited 173–177 components. 178 does not build pages — it stresses, guards, and fixes them. The single largest structural change is extracting the duplicated `threadline-ui` + `#tl-main` shell wrapper into one shared component (D-10).
- **Verification infra is already in place:** `contrast_ratio/2` WCAG engine (`style_contract_test.exs:697`), z-order token guard + reconnect Tier-A pattern (`component_contract_test.exs:243-296`), Playwright cursor/disabled/stacking/Esc/overflow/within-viewport/focus helpers (173 + 177 + accessibility specs), light/system Playwright lane (`playwright.config.ts`). Detectors **extend** these — almost no new harness code.
- **Ledger + ratchet** machinery (`design-system-ledger.json` ⇄ `DESIGN-SYSTEM.md` ⇄ `stress_ledger_test.exs`) already enforces upward-only scoring; 178 fills in the reserved page rows.

### Established Patterns
- 171–177: stress-route isolation audit → Tier A render-contract + Tier B Playwright → flip `human_needed → passed` with `covered_by:` pointers; structural + geometry assertions, never pixel-diff.
- Connection lifecycle rides phoenix_live_view's own client classes on `.threadline-ui` (`.phx-loading`/`.phx-error`) — zero new JS/deps, catches a *dropped* socket mid-session.
- Reduced-motion blanket already collapses transitions (`style.ex:3868`); new work inherits it.

### Integration Points
- All 11 LiveViews route through the new shared shell (D-10); the prune/save-view/delete-view controls + download links gain `data-tl-mutating` (D-12).
- `/audit/__stress` gains per-page path stories; a small set of Tier B specs hit the real `/audit/*` routes for live loading + reconnect (D-03).
- `style.ex:675` one-line centering fix (D-09); footgun CSS-source detectors scan `style.ex`; Tier B geometry/contrast/focus detectors iterate `/audit/*` + the stress story matrix.

</code_context>

<specifics>
## Specific Ideas

- This phase is the milestone's *integration honesty check*: components passed in isolation (173–177); now do the **assembled pages** hold together under ugly data at every viewport/theme, and do the footguns survive composition? PAGE-02's whole point is that a footgun can be absent per-component yet present once composed onto a page.
- The verification framing must be **explicit about what each tier proves** — Tier A = full structural cartesian, Tier B = representative real-engine sample. Don't let a green suite imply "every one of 3,465 cells was eyeballed."
- SEED-005 is where the 177 reconnect work becomes *real*: the banner+CSS were proven to compute, but nothing mounted them and no control was `data-tl-mutating`. Mounting + a true socket-drop e2e is the load-bearing closure.
- The transaction bug is a textbook grid-item-centering trap, not a Threadline-specific quirk — fix it the grid-native way (`justify-self`) and guard it so it can't silently come back.

</specifics>

<deferred>
## Deferred Ideas

- **Microcopy / IA sweep of the pages** — copy touched while fixing a footgun follows brand voice, but the systematic GOV.UK least-surprise / banned-vocabulary / domain-language pass is **Phase 179**. Do not pre-empt it.
- **Formal accessibility + motion + adversarial sign-off** — we *build to* WCAG 2.2 AA and motion-token compliance here, but the automated axe scan on opened dialogs/menus, manual keyboard + screen-reader pass, and the adversarial regression closeout are **Phase 180**.
- **Thicker Tier B sampling (768 mid-breakpoint error cell, per-page keyboard/reconnect granularity)** — start with the ~66-cell high-signal sample (D-02); promote specific cells to Tier B only if a real regression slips through Tier A.
- **Real-LiveView audit of the *full* 7-path matrix** — kept to static fixtures for determinism (D-03); only the live loading/reconnect flows run against real LiveViews. Revisit only if fixtures prove unfaithful for a specific page.
- **Aligning the inner `tl-short-content` wrapper to also constrain the changes list** (D-09b) — opportunistic during the centering fix; not required for PAGE-03 acceptance.

None outside scope — discussion stayed within the phase boundary.

</deferred>

---

*Phase: 178-Per-page & flow stress pass (all 11 pages)*
*Context gathered: 2026-06-18*
