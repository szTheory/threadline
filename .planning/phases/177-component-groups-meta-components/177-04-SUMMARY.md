---
phase: 177-component-groups-meta-components
plan: 04
subsystem: ui
tags: [phoenix-liveview, motion, css-tokens, connection-lifecycle, overlay-transitions, csp, accessibility]

# Dependency graph
requires:
  - phase: 177-component-groups-meta-components
    plan: "03"
    provides: data_panel region cross-fade (.tl-data-panel__region opacity transition on --tl-motion-fast) this plan's overlay motion syncs to
  - phase: 177-component-groups-meta-components
    plan: "01"
    provides: RED style_contract scaffolds (offline anchor + overlay JS-transition utility classes) + the bound LiveView-root anchor decision (.threadline-ui, NOT body/.phx-disconnected)
  - phase: 176-data-display-operator-patterns
    provides: modal/drawer/toast overlay components (JS.show/hide transition tuples whose utility CSS was deferred to this group-motion phase)
provides:
  - Overlay JS-transition utility CLASS selectors (.tl-fade-in/out, .tl-rise-in/out, .tl-slide-in/out-right, .opacity-0/100, .translate-y-0/4, .translate-x-0/full, .hidden)
  - Overlay shells (.tl-modal-container/scrim/wrapper/.tl-modal, .tl-drawer-container/scrim/wrapper/.tl-drawer, .tl-toast)
  - Token-synced overlay motion (explicit time: 180 = --tl-motion-base on every overlay JS.show/hide) + toast fade-up entrance (show_toast/2)
  - Reconnect/offline group CSS keyed off .threadline-ui.phx-loading/.phx-error (banner reveal + [data-tl-mutating] disable)
  - UI.reconnect_banner/1 (@doc false role=status strip + the data-tl-mutating marker contract)
affects: [177-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Overlay JS-transition tuples {transition_classes, from, to} need real CLASS selectors (not the same-named @keyframes): the transition class sets the tokenized transition-property, from/to set start/end opacity/transform. Keyframes drive CSS animation: mount reveals — a different mechanism."
    - "Every overlay JS.show/hide passes an explicit time: 180 (= --tl-motion-base) so the motion token, not LiveView's 200ms default, is the single source of truth (Pitfall 3)."
    - "The reconnect/offline group rides phoenix_live_view's CLIENT-applied connection classes on the LiveView ROOT (.threadline-ui in this app) — NOT <body>, and NEVER a .phx-disconnected selector (does not exist in LiveView 1.x; a dropped socket re-applies .phx-loading). Zero new JS/deps, CSP-clean, catches a dropped socket mid-session unlike a mount-time connected?/1 assign."
    - "Source-governance gotcha (carried from Plan 03): the offline-anchor style_contract test does refute String.contains?(src, \".phx-disconnected\") which scans COMMENTS too — a comment mentioning the literal class name reddens it. Comments must paraphrase (\"the legacy disconnected class\")."

key-files:
  created:
    - .planning/phases/177-component-groups-meta-components/177-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/ui.ex

key-decisions:
  - "Overlay transition durations use var(--tl-motion-base) (180ms) in CSS; the JS time: literal is 180 in ui.ex (Elixir, NOT scanned by the style.ex ungoverned-duration regex). The data-region cross-fade keeps --tl-motion-fast (120ms) from Plan 03."
  - "translate-y-4 maps to var(--tl-motion-distance-md) (16px) — an existing motion-distance token, not an off-scale literal (RESEARCH Pitfall 2 sketch)."
  - "Overlay shells (modal/drawer/toast container/scrim/wrapper) were ALSO undefined in style.ex (not just the utility classes) — added them as token-backed layout/stacking layers (z-index var(--tl-z-subview), surfaces/borders/radius from the catalog) so the overlays both animate AND lay out."
  - "Reconnect banner is warning-tinted (--tl-color-warning-text/-bg/-border) with the refresh icon + 'Reconnecting…' copy (calm/transient/no '!', per UI-SPEC) — icon + text, never color alone (A11Y-02)."
  - "Mutating links carry aria-disabled + tabindex=-1 in markup (documented in reconnect_banner/1 docstring + the contract example) because pointer-events:none is affordance, not enforcement (Pitfall 6)."

patterns-established:
  - "When adding CSS comments to style.ex, never write a literal selector/class name that a style_contract refute assertion forbids (.phx-disconnected, body.phx-, a second 768 min-width literal, a bare \\d+ms) — paraphrase. The source-governance assertions scan comments."

requirements-completed: []

# Metrics
duration: ~12min
completed: 2026-06-18
status: complete
---

# Phase 177 Plan 04: Overlay motion + reconnect/offline group Summary

**Completed the motion + connection-lifecycle layer — defined the previously-missing overlay JS-transition utility CLASS selectors + overlay shells (so modal/drawer/toast actually animate), token-synced every overlay JS.show/hide to `time: 180` (= `--tl-motion-base`) with a toast fade-up entrance, and built the reconnect/offline group keyed off the LiveView-root `.threadline-ui.phx-loading`/`.phx-error` connection classes — all GPU-only, CSP-clean, reduced-motion-safe, zero new deps; turned the two remaining Plan-01 style_contract RED scaffolds GREEN.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-06-18
- **Completed:** 2026-06-18
- **Tasks:** 2
- **Files modified:** 2 (style.ex + ui.ex)

## Accomplishments

- **Task 1 — overlay JS-transition utilities + token-synced motion:** Added the overlay JS-transition utility CLASS selectors to `style.ex` — `.tl-fade-in`/`.tl-fade-out` (opacity transition on `--tl-motion-base`), `.tl-rise-in`/`.tl-rise-out` (opacity + transform), `.tl-slide-in-right`/`.tl-slide-out-right` (transform), `.opacity-0/100`, `.translate-y-0/4` (4 → `var(--tl-motion-distance-md)`), `.translate-x-0/full`, and `.hidden` (backs the modal/drawer `if(!@show, do: "hidden")` toggle). Also added the overlay SHELLS that were equally undefined: `.tl-modal-container/scrim/wrapper/.tl-modal`, `.tl-drawer-container/scrim/wrapper/.tl-drawer`, `.tl-toast` — token-backed positioning/stacking (`var(--tl-z-subview)`), surfaces, borders, radius. In `ui.ex`, passed an explicit `time: 180` to every overlay `JS.show`/`JS.hide` in `show_modal`/`hide_modal`/`show_drawer`/`hide_drawer`/`hide_toast` (10 calls) so the token is the single source of truth (Pitfall 3), and wired the toast fade-up ENTRANCE via a new `show_toast/2` on `phx-mounted` (reusing `tl-rise-in`/`opacity-*`/`translate-y-*`; manual/`phx-click` dismiss only — auto-dismiss out of scope). The Plan-01 overlay-utility-class scaffold went GREEN.
- **Task 2 — reconnect/offline group:** Added the connection-lifecycle CSS keyed off the LiveView ROOT `.threadline-ui.phx-loading`/`.threadline-ui.phx-error` (per the Plan-01 binding + Pitfall 1) — the reconnect banner is `display:none` by default, revealed as a warning-tinted `display:flex` strip while loading/erroring; mutating `[data-tl-mutating]` controls disable via `pointer-events:none` + `opacity:0.55` under the same anchors. Added `UI.reconnect_banner/1` (`@doc false`) rendering `<div class="tl-reconnect-banner" role="status">` with the refresh icon + "Reconnecting…" copy, and documented the `data-tl-mutating` marker contract + the mutating-link `aria-disabled`/`tabindex="-1"` requirement (Pitfall 6) in its docstring. Zero new JS, zero inline `on*=`, zero new deps. The Plan-01 offline-anchor scaffold went GREEN.

## Task Commits

1. **Task 1: overlay JS-transition utility classes + token-sync overlay motion** — `da4a36d` (feat)
2. **Task 2: reconnect/offline group on the LiveView root connection classes** — `f1695a1` (feat)

**Plan metadata:** see final docs commit.

## Files Created/Modified

- `lib/threadline/operator_surface/style.ex` — added the overlay JS-transition utility class selectors, the modal/drawer/toast shells, and the reconnect/offline group CSS (`.tl-reconnect-banner` + `.threadline-ui.phx-loading/.phx-error` reveal/disable rules), inserted just after the `@keyframes tl-fade-in` block. No new `--tl-*` token; no new `@keyframes` (the locked keyframe set stays exactly `tl-drawer-in tl-rise-in tl-thread-draw tl-fade-in tl-copy-pulse`).
- `lib/threadline/operator_surface/ui.ex` — added `time: 180` to every overlay `JS.show`/`JS.hide`; added `show_toast/2` + wired it on `toast/1` `phx-mounted`; added `UI.reconnect_banner/1`.

## RED Scaffold Ledger — what went GREEN this plan, what remains RED

| Scaffold (test) | File | Status after Plan 04 | Owning plan |
|---|---|---|---|
| overlay JS-transition utility classes (`.tl-fade-in`, `.translate-x-full`, … as class selectors) | style_contract_test | **GREEN** | 04 (this plan) |
| `.tl-data-panel__region` opacity cross-fade on `--tl-motion-fast` (D-10.2) | style_contract_test | **GREEN** (shipped Plan 03, asserted in the same overlay block) | 03/04 |
| offline group anchor (`.threadline-ui.phx-loading/.phx-error`, refute body/.phx-disconnected) | style_contract_test | **GREEN** | 04 |
| stress stories / ledger 12-config map | stress_fixtures / stress_live | not-yet-authored as RED tests | 05 |

## Verification

- `mix test test/threadline/operator_surface/style_contract_test.exs` — **36 tests, 0 failures** (both Plan-04 overlay + offline scaffolds GREEN; all phase-141/142 source-governance assertions intact).
- `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/style_contract_test.exs` — **98 tests, 0 failures**.
- `mix test` (full suite) — **1071 tests, 0 failures (1 excluded)**. The two RED-by-design Plan-04 scaffolds present at the start of this plan are now GREEN; no pre-existing test regressed. Plan 05's stress-story/ledger scaffolds are not yet authored as failing tests, so the suite is fully green at this wave (no remaining RED to report).
- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` — clean (whole project).
- `mix credo --strict` — **2115 mods/funs, found no issues.**
- `mix test test/threadline/brandbook_token_parity_test.exs` — **4 tests, 0 failures** (no new tokens minted; brand-token parity intact).

### Acceptance-criteria greps

- `.tl-fade-in` class selectors in style.ex: 2 (≥1 ✓); `tl-modal-container`/`tl-drawer-container`/`.hidden` each present (1 ✓).
- `threadline-ui.phx-loading`: 2; `threadline-ui.phx-error`: 2; `phx-disconnected`: 0 ✓; `body.phx-`: 0 ✓.
- `data-tl-mutating` in ui.ex: 3 (contract example + docstring); `time: 180` calls: 10 (every overlay JS.show/hide).

## Remaining RED

None at this wave. The two Plan-04 style_contract scaffolds are GREEN; Plan 05 owns the stress-story/ledger work and will author its own scaffolds. GROUP-01/GROUP-02 are deliberately NOT marked complete (phase-spanning; Plan 05 lands the 12-config audit and final closure).

## Decisions Made

1. **Overlay durations: CSS uses `var(--tl-motion-base)` (180ms), JS uses `time: 180`.** The `style.ex` ungoverned-duration regex (`\b\d+ms\b`) scans only `style.ex`; the `time: 180` literal lives in `ui.ex` (Elixir), so it is governed-by-token-intent without tripping the source check. The Plan-03 data-region cross-fade stays on `--tl-motion-fast` (120ms).
2. **Defined the overlay SHELLS, not just the utility classes.** Grep confirmed `tl-modal-container`/`tl-modal-scrim`/`tl-modal-wrapper`/`tl-modal`/`tl-drawer-*`/`tl-toast` were ALL absent from `style.ex` (D-176 extracted the overlay components but deferred their CSS). Added them as token-backed layout/stacking layers so the overlays both animate (utility classes) and lay out (shells).
3. **`translate-y-4` → `var(--tl-motion-distance-md)`** (16px, the existing token), per the RESEARCH Pitfall 2 sketch — no off-scale literal.
4. **Reconnect banner is warning-tinted, icon + text.** `--tl-color-warning-text/-bg/-border` + refresh icon + "Reconnecting…" (calm, transient, no "!"); never color alone (A11Y-02).
5. **No new keyframes, no new tokens.** The locked `@keyframes` set is unchanged; the utility classes are pure `transition:`/`transform:`/`opacity:` selectors, so the phase-141 keyframe-lock and animation-keyword guards stay GREEN.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Self-introduced `.phx-disconnected` literal in a CSS comment reddened the offline-anchor test**
- **Found during:** Task 2 (caught by the per-task style_contract run)
- **Issue:** My first reconnect/offline comment block paraphrased the binding as "NEVER `.phx-disconnected` (which does not exist…)". The `phase 177 offline group` test does `refute String.contains?(src, ".phx-disconnected")`, which scans the WHOLE source including comments — the literal class name in my comment failed the refute (exactly the comment-scanning gotcha Plan 03 logged for `\d+ms` literals).
- **Fix:** Rephrased the comment to "the legacy disconnected class" — same intent, no forbidden literal.
- **Files modified:** lib/threadline/operator_surface/style.ex
- **Commit:** `f1695a1` (folded into Task 2)

### Additional Scope (within plan intent)

- **Overlay shells added (Decision 2).** The plan's action named `.tl-modal-container`/`.tl-drawer-container`/`.hidden` explicitly; I also added the scrim/wrapper/`.tl-modal`/`.tl-drawer`/`.tl-toast` shells because they were equally undefined and the overlays would have no surface/positioning without them. This is in-scope realization of "the overlay enter/exit motion actually animates" (a transparent, unlaid-out overlay is not a working overlay). No new tokens; all values from the existing catalog.

## Known Stubs

None — the overlay utilities and shells are fully defined and consumed by the existing `modal`/`drawer`/`toast` components; `reconnect_banner/1` renders a real `role="status"` strip wired to the live `.phx-*` connection classes. No placeholder/empty-data paths introduced. (Page-level adoption of the reconnect banner across the 11 pages is Phase 178, per the plan; this plan ships the shell-level group + its contract, as scoped.)

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. T-177-07 (CSP overlay motion) is mitigated: motion is Phoenix.LiveView.JS + CSS utility classes only, no inline `on*=`. T-177-08 (offline action-disable) is mitigated: `[data-tl-mutating]` disable rides client connection classes for affordance, with the markup-level `aria-disabled`/`tabindex=-1` contract documented for mutating links (CSS is affordance, not server trust). T-177-09/T-177-SC (supply chain): zero new JS dep, zero package installs.

## Issues Encountered

The style_contract source-governance assertions scan comments (a literal `.phx-disconnected` in a comment failed the offline refute) — same class of gotcha Plan 03 hit with `\d+ms`. Resolved within Task 2 (see Deviations); lesson recorded in `patterns-established`.

## User Setup Required

None — pure presentational/motion layer; zero new dependencies (v1.37 zero-new-dep invariant; package-legitimacy gate vacuously satisfied).

## Next Phase Readiness

- Overlay motion is real and token-synced, the reconnect/offline group rides the correct LiveView-root connection classes, and the data-region cross-fade (Plan 03) is in place — so Plan 05 can assemble and audit all 12 group stress-story configurations against working motion + connection states.
- GROUP-01/GROUP-02 remain open (Plan 05 owns final closure).
- No blockers.

## Self-Check: PASSED

- `177-04-SUMMARY.md` exists at the planned path.
- Task 1 commit `da4a36d` present in git log.
- Task 2 commit `f1695a1` present in git log.
- `.tl-fade-in`/`.tl-modal-container`/`.tl-drawer-container`/`.hidden` defined as class selectors in `lib/threadline/operator_surface/style.ex`.
- `.threadline-ui.phx-loading`/`.threadline-ui.phx-error` reconnect/offline rules present; `.phx-disconnected` and `body.phx-` absent.
- `UI.reconnect_banner/1` and `UI.show_toast/2` defined in `lib/threadline/operator_surface/ui.ex`; `time: 180` on every overlay JS.show/hide.

---
*Phase: 177-component-groups-meta-components*
*Completed: 2026-06-18*
