# Roadmap: Threadline v1.36 Operator Surface Light Mode

**Status:** Phase 166 complete — light-lane design review before Phase 167
**Milestone:** v1.36 Operator Surface Light Mode (Phases 166–170)
**Opened:** 2026-06-12
**Last shipped:** v1.35 Unified Logo & Brand Book v2 (2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
**Source:** Decision [165-01] + `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-LIGHT-MODE-RECOMMENDATION.md` (approved strategy — its v1.36 phase breakdown is the pre-decided structure) + `165-RESEARCH-SURFACE.md` (change-surface map with file:line sizing)

## Goal

Implement decision [165-01] (supersedes dark-only [136-01]): `theme: :dark | :light | :system` host config on `threadline_operator_surface/2`, default `:dark`, rendered server-side as a `data-tl-theme` attribute on the LiveView roots driving a pure-CSS light token lane — zero JS, zero FOUC, CSP-proof, designed-not-recolored. Dark stays the default and the brand; `:system` becomes the documented daytime-use recommendation.

## Non-goals

- **Runtime theme toggle UI** — `theme-toggle` ban retained verbatim by [165-01]; host config covers v1; the cookie-based upgrade path is documented, not built.
- **localStorage / `<head>`-script theming** — structurally wrong for a mounted library (FOUC on every dead render, dies under CSP); rejected in 165 research.
- **Light or `:system` as the literal default** — changes existing adopters' surface without their choosing; dilutes the dark-first brand. `:system` is the documented recommendation only.
- **HexDocs / landing / marketing light themes** — brand/docs surfaces stay with the brand book; HEXDOCS-BRAND-01 / LANDING-01 remain deferred.
- **Touching the uncommitted nav-overhaul lane** — ~29 files under lib/, examples/, test/ belong to another lane; never staged, edited, or reverted (including its 3 pre-existing test failures).

## Phases

- [x] **Phase 166: unfreeze-token-lane-mechanism** - Atomic opening wave: superseding decision recorded, 45-token light lane (status tints decided here), `data-tl-theme` on the 10 LiveView roots, compile-validated `theme:` router option, contract tests amended same-wave (completed 2026-06-13)
- [ ] **Phase 167: component-retune** - ~9 dark-effect families individually retuned, verification pass over the ~20 tint-riders, explicit light design review of coverage/timeline/diff (the Grafana lesson)
- [ ] **Phase 168: accessibility-verification** - AA mirror test for the light lane with alpha-aware token parsing; focus-visible + interaction states verified per mode
- [ ] **Phase 169: screenshots-example-docs** - `__light__` baseline lane (local-only), example app demonstrates `theme: :system`, guides + doc-contract coverage of the new option
- [ ] **Phase 170: brand-alignment-closeout** - tokens.json/css 45-token parity, brand book UI-theming posture note, pressure-test dual-mode addendum, milestone audit prep

## Execution Order

166 → 167 → (168 ∥ 169) → 170

| Phase | Size | Depends on | Requirements |
|---|---|---|---|
| 166. unfreeze-token-lane-mechanism | 1/1 | Complete    | 2026-06-13 |
| 167. component-retune | L (largest) | 166 | COMP-01, COMP-02 |
| 168. accessibility-verification | S-M | 167 | A11Y-01, A11Y-02 |
| 169. screenshots-example-docs | S-M | 167 (can overlap 168) | EVID-01, EVID-02 |
| 170. brand-alignment-closeout | S | 168, 169 | BRAND-01, BRAND-02 |

## Phase Details

### Phase 166: unfreeze-token-lane-mechanism

**Goal**: The light token lane exists, the theme mechanism threads host config to first-paint-correct rendering, and the dark-only contract is amended source-first — all in one atomic wave (the contract test reads `style.ex` directly, so the test flip and the `color-scheme: light` introduction are inseparable).

**Depends on**: Nothing (first phase)

**Requirements**: THEME-01, THEME-02, THEME-03, THEME-04, TOKEN-01, TOKEN-02, TOKEN-03

**Scope notes**: Superseding decision [165-01] over [136-01] recorded in STATE; light lane for all 45 color-bearing tokens (19 seeded from the brand light lane, 26 designed — the status-tint system is decided HERE as the keystone: tinted backgrounds + darkened text); `data-tl-theme` rendered server-side on the 10 LiveView roots (shared helper, no 10-way drift); router `theme:` option compile-validated naming the allowed triad; the stray `style.ex` shell-nav inset rgba tokenized in both lanes; `style.ex` + `style_contract_test.exs` amended in the SAME wave — the seven `prefers-color-scheme`/`color-scheme: light` refutes become theme-aware assertions, the `theme-toggle` ban retained verbatim.

**Success Criteria** (what must be TRUE):

  1. A host mounting with `theme: :system` gets `data-tl-theme="system"` on the dead render of every operator-surface root — first paint correct with zero JS, no localStorage, no `<head>` injection; invalid theme values raise at compile time naming `:dark | :light | :system`.
  2. All 45 color-bearing `--tl-*` tokens render light-lane values (19 seeded from `brandbook/tokens.json` `semantic.light`, 26 designed as one coherent system), and the `style.ex` shell-nav active inset rgba sits behind a `--tl-*` token with values in both lanes.
  3. `:system` follows the OS via scoped `@media (prefers-color-scheme: light)` CSS only, and `color-scheme` flips scoped within `.threadline-ui` so native controls/scrollbars match the active mode.
  4. Existing adopters see zero behavior change: default `:dark`, dark stays the canonical base token block, and the frozen dark-hex catalog assertions pass untouched.
  5. `mix test` is green with the amended contract in the same wave — theme-aware assertions replace the seven refutes, the `theme-toggle` ban is retained, and decision [165-01] superseding [136-01] is recorded in STATE.

**Plans**:

- `166-01-PLAN.md` — Atomic unfreeze: compile-validated `theme:` host option, server-rendered `data-tl-theme`, additive light/system token lanes, tokenized active-nav inset, same-wave source contract amendment, and [165-01] decision ledger update.

**UI hint**: yes

### Phase 167: component-retune

**Goal**: Every dark-tuned visual effect renders as an explicitly designed light treatment — nothing ships into light unreviewed or merely recolored.

**Depends on**: Phase 166

**Requirements**: COMP-01, COMP-02

**Scope notes**: The ~9 dark-effect families individually retuned (glass chrome ×4: topbar / shell-nav / toolbar / coverage-command + subview header, drawer scrim + shadow, focus glow, home-card signature effects, shell-nav active inset) plus a verification pass over the ~20 tint-riding families that resolve through the Phase 166 status-tint decision. Largest phase by visual iteration.

**Success Criteria** (what must be TRUE):

  1. The ~9 dark-effect component families (glass chrome ×4, drawer scrim + shadow, focus glow, home-card effects, shell-nav inset) render correctly on light with explicitly designed treatments — no near-invisible dark-tuned alphas washing out on white.
  2. The ~20 tint-riding families (chips, alerts, op badges, redaction rows, policy drift, job errors) render correctly from the shared status-tint system without per-component overrides.
  3. Coverage, timeline, and diff views pass an explicit light-mode design review — no dark-tuned content ships unreviewed into light (the Grafana lesson).
  4. Dark mode is visually unchanged: light remains an additive override lane, never a rewrite of the base block.

**Plans**: 2 plans

Plans:
**Wave 1**

- [ ] 167-01-PLAN.md — Review-first gate: live 3-mode (:dark/:light/:system) render review producing LIGHT-REVIEW.md disposition fail-list (COMP-01 confirm + COMP-02 data-viz)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 167-02-PLAN.md — Additive dual-branch light overrides for proven-fail families (confirm-strict) + style_contract_test.exs D-07(a)/(b) guard (same wave)

**UI hint**: yes

### Phase 168: accessibility-verification

**Goal**: The light lane is provably accessible — contrast and interaction affordances hold in both modes, enforced by the contract rather than by eyeball.

**Depends on**: Phase 167

**Requirements**: A11Y-01, A11Y-02

**Success Criteria** (what must be TRUE):

  1. The style contract carries a light-lane AA contrast mirror test with alpha-aware token parsing in `color_tokens/1`; no text-bearing token falls below WCAG AA in either mode, and `mix test` proves it.
  2. The focus ring meets non-text contrast on both backgrounds, with focus-visible verified per mode.
  3. Hover/active/disabled/selected interaction states are verified per mode (including the accessibility e2e affordance checks re-run under the light lane).

**Plans**: TBD
**UI hint**: yes

### Phase 169: screenshots-example-docs

**Goal**: Adopters can see, run, and read about the theme option — evidence and documentation cover both modes truthfully.

**Depends on**: Phase 167 (can overlap Phase 168)

**Requirements**: EVID-01, EVID-02

**Success Criteria** (what must be TRUE):

  1. Screenshot baselines gain a `__light__` lane alongside dark covering the operator-surface screen set in both modes — local-only (the visual guard stays CI-skipped per cf0e8e2).
  2. The example app mounts the operator surface with `theme: :system` and runs end-to-end.
  3. `guides/operator-surface.md` and adopter-facing docs document the `theme:` option with the daytime-use recommendation, and doc-contract coverage locks the new option literal.

**Plans**: TBD

### Phase 170: brand-alignment-closeout

**Goal**: The brand SSOT and the shipped UI lane state the same settled truth, and the milestone closes audit-ready.

**Depends on**: Phase 168, Phase 169

**Requirements**: BRAND-01, BRAND-02

**Success Criteria** (what must be TRUE):

  1. `brandbook/tokens.json` and `tokens.css` reach full parity with the shipped 45-token UI lane.
  2. The brand book carries the settled-truth "UI theming posture" note: dark-primary, light supported via host config (stated only now that it is true — the v1.33 lesson).
  3. `pressure-test.md` carries a dual-mode addendum verifying brand assets and UI tokens stay consistent across both lanes.
  4. All 15 v1.36 requirements are traceable to verified phases and the milestone audit prep is complete.

**Plans**: TBD

## Human Gates

| Gate | When | What |
|---|---|---|
| Light-lane design review | After Phase 166, before Phase 167 | User eyeballs the rendered light surface (token lane on real screens) before the retune effort is spent — the status-tint keystone gets human sign-off while course-correction is still cheap. |
| End-of-milestone UAT | After Phase 170, before closeout | User walks the operator surface in dark, light, and system modes; confirms brand posture, docs, and example app match the shipped behavior. |

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---:|---|---|
| 166. unfreeze-token-lane-mechanism | v1.36 | 0/1 | Planned | - |
| 167. component-retune | v1.36 | 0/TBD | Not started | - |
| 168. accessibility-verification | v1.36 | 0/TBD | Not started | - |
| 169. screenshots-example-docs | v1.36 | 0/TBD | Not started | - |
| 170. brand-alignment-closeout | v1.36 | 0/TBD | Not started | - |

## Prior Milestones

- ✅ **v1.35 Unified Logo & Brand Book v2** — Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- ✅ **v1.34 Local Docker Admin UI DX** — Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`
- ✅ **v1.33 Brand Review + Direction Selection** — Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- ✅ **v1.32 Brand System Foundation** — Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`
