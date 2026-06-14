# Requirements: Threadline v1.36 Operator Surface Light Mode

**Defined:** 2026-06-12
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Source:** Decision [165-01] + `165-LIGHT-MODE-RECOMMENDATION.md` (approved at the v1.35 Phase 165 checkpoint). All requirements implement the already-approved strategy; none reopen it.

## v1.36 Requirements

### Theme Mechanism

- [x] **THEME-01**: Host can mount with `theme: :dark | :light | :system` on `threadline_operator_surface/2`; default `:dark` (zero behavior change for existing adopters); invalid values raise at compile time naming the allowed triad.
- [x] **THEME-02**: The configured theme renders server-side as a `data-tl-theme` attribute on every operator-surface LiveView root — first paint is correct on the dead render (zero FOUC), with no JavaScript, no localStorage, and no `<head>` injection.
- [x] **THEME-03**: `:system` follows the OS via scoped `@media (prefers-color-scheme: light)` CSS only, and `color-scheme` flips scoped within `.threadline-ui` so native controls/scrollbars match the active mode.
- [x] **THEME-04**: `style.ex` and `style_contract_test.exs` are amended in the SAME wave (source-first): the seven `prefers-color-scheme`/`color-scheme: light` refutes become theme-aware assertions; the `theme-toggle` ban is RETAINED verbatim; the superseding decision [165-01] over [136-01] is recorded in STATE.

### Light Token Lane

- [x] **TOKEN-01**: All 45 color-bearing `--tl-*` tokens have light-lane values — 19 seeded from `brandbook/tokens.json` `semantic.light`, 26 designed (never recolored): status tints, glass surfaces, shadows, focus ring/border, accent tints, brand-rail.
- [x] **TOKEN-02**: The status-tint system is redesigned for light as one coherent decision (tinted backgrounds + darkened text), and the ~20 tint-riding component families (chips, alerts, op badges, redaction rows, policy drift, job errors) render correctly from it without per-component overrides.
- [x] **TOKEN-03**: The stray hardcoded color outside the token block (`style.ex` shell-nav active inset rgba) is moved behind a `--tl-*` token with values in both lanes.

### Component Retune

- [~] **COMP-01**: The ~9 dark-effect component families (glass chrome ×4, drawer scrim + shadow, focus glow, home-card signature effects, shell-nav inset) render correctly on light with explicitly designed treatments. *(Verified (source pending): built + user-approved live both modes; `style.ex` source uncommitted, ships with the nav-overhaul lane — see `v1.36-MILESTONE-AUDIT.md` F1 + `167-02-SUMMARY.md`.)*
- [~] **COMP-02**: Data-viz-adjacent surfaces (coverage, timeline, diff views) pass an explicit light-mode design review — no dark-tuned content shipped unreviewed into light (the Grafana lesson). *(Verified (source pending): coverage row hover-polarity fix + data-viz light review done and user-approved live; `style.ex` source uncommitted — see `v1.36-MILESTONE-AUDIT.md` F1 + `167-02-SUMMARY.md`.)*

### Accessibility

- [x] **A11Y-01**: The style contract gains a light-lane AA contrast mirror test (with alpha-aware token parsing in `color_tokens/1`); no text-bearing token falls below WCAG AA in either mode.
- [x] **A11Y-02**: Focus-visible and interaction states (hover/active/disabled/selected) are verified per mode — focus ring meets non-text contrast on both backgrounds.

### Verification Surfaces & Docs

- [x] **EVID-01**: Screenshot baselines gain a `__light__` lane alongside dark (local-only — the visual guard stays CI-skipped per cf0e8e2), covering the operator-surface screen set in both modes.
- [x] **EVID-02**: The example app demonstrates `theme: :system`; `guides/operator-surface.md` and adopter-facing docs document the `theme:` option with the daytime-use recommendation; doc-contract coverage for the new option literal.

### Brand Alignment

- [x] **BRAND-01**: `brandbook/tokens.json`/`tokens.css` reach full parity with the shipped 45-token UI lane, and the brand book gains the settled-truth "UI theming posture" note (dark-primary, light supported via host config).
- [x] **BRAND-02**: `pressure-test.md` gains a dual-mode addendum verifying brand assets and UI tokens stay consistent across both lanes.

## Future Requirements

- **THEME-TOGGLE-01**: Per-operator runtime switching (Backpex-style cookie + plug, zero-JS form) — only on real adopter demand; localStorage remains rejected.
- **SOCIAL-PNG-01**: Social-card raster export — when a downstream channel requires it.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Runtime theme toggle UI | `theme-toggle` ban retained by [165-01]; host config covers v1; upgrade path documented, not built. |
| localStorage / `<head>`-script theming | Structurally wrong for a mounted library (FOUC on dead render, dies under CSP) — rejected in 165 research. |
| Light/`:system` as the literal default | Changes existing adopters' surface without their choosing; dilutes the dark-first brand. `:system` is the documented recommendation only. |
| Marketing/docs-site light themes | Brand/docs surfaces already handled by the brand book; HexDocs/landing remain HEXDOCS-BRAND-01/LANDING-01 (deferred). |
| Touching the user's uncommitted nav-overhaul lane | ~29 files under lib//examples//test/ belong to another lane; never staged, edited, or reverted (incl. its 3 pre-existing test failures). |

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
| COMP-01 | Phase 167 | Verified (source pending) |
| COMP-02 | Phase 167 | Verified (source pending) |
| A11Y-01 | Phase 168 | Complete |
| A11Y-02 | Phase 168 | Complete |
| EVID-01 | Phase 169 | Complete |
| EVID-02 | Phase 169 | Complete |
| BRAND-01 | Phase 170 | Complete |
| BRAND-02 | Phase 170 | Complete |

**Coverage:**
- v1.36 requirements: 15 total
- Mapped to phases: 15 ✓ (Phases 166–170 per `.planning/ROADMAP.md`)
- Unmapped: 0

---
*Requirements defined: 2026-06-12*
*Last updated: 2026-06-14 — Phase 170 closeout (BRAND-01/02 Complete; COMP-01/02 Verified (source pending), agreeing with `v1.36-MILESTONE-AUDIT.md`)*
