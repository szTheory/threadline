---
phase: 177-component-groups-meta-components
plan: 03
subsystem: ui
tags: [phoenix-liveview, function-components, meta-components, state-coordination, css-tokens, responsive, tdd]

# Dependency graph
requires:
  - phase: 177-component-groups-meta-components
    plan: "02"
    provides: UI.stack/1 + UI.cluster/1 layout primitives and semantic --tl-gap-* tokens (data_panel/toolbar/detail_header compose on these)
  - phase: 177-component-groups-meta-components
    plan: "01"
    provides: RED render/coordination scaffolds for data_panel/toolbar/detail_header + the breadcrumbs-trail assertion; bound D-14 attr-keep decision
  - phase: 176-data-display-operator-patterns
    provides: the named state family (loading_state/empty_state/error_state/stale_banner/data_state) with per-state focus rules (D-176-15) that data_panel delegates to
provides:
  - UI.data_panel/1 — state-coordinating shell composing the existing state family (D-03/D-06/D-06c)
  - UI.toolbar/1 — disabled-coordination row on the cluster mechanism (D-06, Pitfall 6)
  - UI.detail_header/1 — <h2> title + kv metadata + actions cluster (D-03)
  - breadcrumb narrow-viewport truncation on the existing page_header list attr (D-04 via D-14)
  - .tl-data-panel/.tl-data-panel__region(cross-fade)/.tl-toolbar/.tl-detail-header CSS
affects: [177-04, 177-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "data_panel is a coordinating SHELL, not a taxonomy owner: a cond maps the generic state atom (ok|loading|empty|no_data|error|permission|unavailable) onto the EXISTING named state family — no variant= mega-switch, no reinvented focus logic (D-176-13, D-06c)"
    - "stale_banner sits ABOVE the region as a sibling of the cond, never a clause in it — it coexists with :ok data (D-176-14)"
    - "toolbar disabled is affordance (is-disabled / pointer-events) + a documented page contract to also set HTML disabled on the controls (Pitfall 6 — affordance is not enforcement)"
    - "responsive breadcrumb truncation uses max-width: clamp(...) instead of a new @media literal, so the phase-142 breakpoint-governance source contract (exactly 768px+1280px) stays intact"

key-files:
  created:
    - .planning/phases/177-component-groups-meta-components/177-03-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/style.ex

key-decisions:
  - "data_panel state->region map: :ok->data slot; :loading->loading_state; :empty->empty_state(role=status); :no_data->data_state(:no_data); :error->error_state; :permission/:unavailable->data_state(@reason) (collapse + focus rescue). @reason flows straight to data_state for the typed forensic distinction."
  - "toolbar emits aria-disabled as an explicit string via to_string(@disabled) so it renders aria-disabled=\"true\"/\"false\" (a bare boolean attr would drop the value and fail the assertion). Built on tl-cluster for wrap/spacing."
  - "detail_header maps its <:metadata key=...> slots onto kv/1's <:item key=...> slot; actions render in a justify=end cluster on the same top row as the <h2>."
  - "breadcrumb_trail marks the last crumb with .tl-transaction__breadcrumbs-current and truncates it with max-width: clamp(12ch,50vw,40ch) — no new @media literal (kept list attr per D-14, NOT a slot)."

patterns-established:
  - "When adding responsive caps to style.ex, prefer clamp()/min()/vw over a new @media literal — the phase-142 StyleContractTest pins the exact set of allowed min-width media literals."
  - "Avoid literal '<n>ms' strings even in CSS comments — the phase-141 ungoverned-duration source check regex (\\b\\d+ms\\b) scans comments too."

requirements-completed: []

# Metrics
duration: ~5min
completed: 2026-06-18
status: complete
---

# Phase 177 Plan 03: data_panel / toolbar / detail_header + breadcrumb truncation Summary

**Shipped the three named meta-components — `UI.data_panel/1` (state-coordinating shell over the existing state family, owning region-swap + focus delegation + stale-above-data), `UI.toolbar/1` (disabled-coordination on the cluster mechanism), `UI.detail_header/1` (`<h2>` + kv + actions) — and reconciled breadcrumbs on the single canonical `page_header` with narrow-viewport truncation, turning the Plan-01 component RED scaffolds GREEN with zero new deps and no public API.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-18
- **Completed:** 2026-06-18
- **Tasks:** 3
- **Files modified:** 2 (ui.ex + style.ex)

## Accomplishments

- **Task 1 — `UI.data_panel/1`:** Added a `@doc false` coordinating shell. A `cond` maps the generic `state` atom onto the existing named family — `:ok`→`:data` slot, `:loading`→`loading_state`, `:empty`→`empty_state(role=status)`, `:no_data`→`data_state(:no_data)`, `:error`→`error_state`, `:permission`/`:unavailable`→`data_state(@reason)` (collapses the body, delegating the family's focus rescue). `stale_banner` renders ABOVE the region as a sibling (never a cond clause). Pager slot rendered only when `@pager != [] and @state == :ok`. Added `.tl-data-panel` + `.tl-data-panel__region` (opacity cross-fade on `--tl-motion-fast`, D-10.2) + `.tl-data-panel__pager` CSS — flat page-stack section, no card wrapper (D-176-11).
- **Task 2 — `UI.toolbar/1` + `UI.detail_header/1`:** `toolbar` (`@doc false`) renders `role="search"` + `aria-disabled` (explicit string) + `is-disabled` on a `tl-cluster`, documenting the page's HTML-`disabled`-on-controls contract (Pitfall 6). `detail_header` (`@doc false`) renders an `<h2>` (page_header owns the single `<h1>`, D-175-03), a `justify=end` actions cluster, and a `kv` metadata block from its `<:metadata key=...>` slots. Added `.tl-toolbar`/`.tl-toolbar.is-disabled` + `.tl-detail-header`/`__top`/`__title`/`__actions` CSS. No new tokens.
- **Task 3 — breadcrumb truncation:** Per the Plan-01 binding (D-14 over D-04's literal "slot"), KEPT the existing `attr(:breadcrumbs, :list)` + `breadcrumb_trail/1` — no slot added. Marked the last/current crumb with `.tl-transaction__breadcrumbs-current` and gave it `max-width: clamp(12ch,50vw,40ch)` + ellipsis so the header never forces horizontal scroll at 320px while scaling up on wide viewports.

## Task Commits

1. **Task 1: implement UI.data_panel/1 state-coordinating shell** — `1f4d6d7` (feat)
2. **Task 2: implement UI.toolbar/1 + UI.detail_header/1** — `2b082f8` (feat)
3. **Task 3: add narrow-viewport breadcrumb truncation** — `19ef009` (feat)

**Plan metadata:** see final docs commit.

## Files Created/Modified

- `lib/threadline/operator_surface/ui.ex` — added `@doc false` `data_panel/1`, `toolbar/1`, `detail_header/1`; updated private `breadcrumb_trail/1` to mark the last crumb with a `__current` class.
- `lib/threadline/operator_surface/style.ex` — added `.tl-data-panel`/`__region`(cross-fade)/`__pager`, `.tl-toolbar`/`.is-disabled`, `.tl-detail-header`/`__top`/`__title`/`__actions`, and `.tl-transaction__breadcrumbs-current` truncation rules.

## RED Scaffold Ledger — what went GREEN this plan, what remains RED

| Scaffold (test) | File | Status after Plan 03 | Owning plan |
|---|---|---|---|
| `data_panel/1` :ok data+pager | ui_test | **GREEN** | 03 (this plan) |
| `data_panel/1` :loading suppresses data, shows status | ui_test | **GREEN** | 03 |
| `data_panel/1` :permission collapses body, delegates focus | ui_test | **GREEN** | 03 |
| `data_panel/1` stale banner ABOVE region | ui_test | **GREEN** | 03 |
| `toolbar/1` aria-disabled + is-disabled + HTML-disabled | ui_test | **GREEN** | 03 |
| `toolbar/1` enabled (no disabled signals) | ui_test | **GREEN** | 03 |
| `detail_header/1` `<h2>` + kv + actions cluster | ui_test | **GREEN** | 03 |
| `page_header` breadcrumbs trail + narrow truncation | ui_test / page_header_test | **GREEN** | 03 (truncation) |
| offline group anchor (`.threadline-ui.phx-loading/.phx-error`) | style_contract_test | RED (by design) | 04 |
| overlay JS-transition utility classes (`.tl-fade-in`, `.translate-x-full`, …) | style_contract_test | RED (by design) | 04 |
| stress stories / ledger 12-config map | stress_fixtures / stress_live | RED/pending (by design) | 05 |

## Verification

- `mix test test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/page_header_test.exs` — **64 tests, 0 failures** (all data_panel/toolbar/detail_header + breadcrumb assertions GREEN).
- `mix test` (full suite) — **1071 tests, 2 failures (1 excluded)**. The 2 failures are the RED-by-design Plan-04 scaffolds (offline group anchor + overlay JS-transition utility classes); verified identical to the pre-plan baseline (`ac78693`) in a throwaway worktree. No pre-existing test regressed.
- `mix compile --warnings-as-errors` — clean.
- `mix verify.format` (`mix format --check-formatted`) — clean (whole project).
- `mix verify.credo` (`mix credo --strict`) — **2113 mods/funs, found no issues.**
- `mix test test/threadline/brandbook_token_parity_test.exs` — **4 tests, 0 failures** (brand-token parity intact; no new tokens minted).

## Decisions Made

1. **`data_panel` state→region map.** `:ok`→`:data` slot; `:loading`→`loading_state`; `:empty`→`empty_state(role=status)`; `:no_data`→`data_state(:no_data)`; `:error`→`error_state`; `:permission`/`:unavailable`→`data_state(@reason)` (the typed reason — e.g. `:unauthorized`/`:source_down` — flows straight through so the distinct lock/cloud_off icon shape + heading + focus rescue survive the collapse). The cond never converts a permission denial to a generic empty (T-177-04, D-176-16, ASVS V4).
2. **`toolbar` `aria-disabled` as an explicit string.** `aria-disabled={to_string(@disabled)}` renders `aria-disabled="true"`/`"false"`; a bare HEEx boolean would drop the value and fail the assertion. Built on `tl-cluster` so it wraps at narrow widths (D-13).
3. **`detail_header` maps `<:metadata key=...>` onto `kv/1`'s `<:item key=...>`.** Actions render in a `justify=end` cluster sharing the top row with the `<h2>`; metadata is a `--tl-space-6` break below (UI-SPEC rhythm).
4. **Breadcrumb truncation uses `clamp()`, not a new `@media`.** Kept the list attr (D-14, NOT a slot per D-04 literal — Pitfall 4) and marked the current crumb; `max-width: clamp(12ch,50vw,40ch)` gives a tight cap at 320px and a generous one on wide viewports without adding a media literal (see Deviations — this also fixed a self-introduced governance regression).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Self-introduced phase-142 breakpoint-governance regression**
- **Found during:** Task 3 (caught by the full-suite run, not by the per-task grep)
- **Issue:** My first breadcrumb-truncation draft added a `@media (min-width: 768px)` block for a wider crumb cap. The `phase 142 breakpoint scale is tokenized and source-governed` StyleContractTest asserts the source contains exactly the min-width literals `["1280", "768"]`; a second `768` literal broke that assertion, and the cascade shifted `base_responsive_section/1`'s split point, also reddening two adjacent phase-142/141 mobile-first/trust-rail source assertions.
- **Fix:** Replaced the `@media` block with a media-query-free `max-width: clamp(12ch, 50vw, 40ch)` on the current crumb — same responsive intent, zero new media literal.
- **Files modified:** lib/threadline/operator_surface/style.ex
- **Commit:** `19ef009` (folded into Task 3)

**2. [Rule 1 - Bug] Self-introduced phase-141 ungoverned-duration regression**
- **Found during:** Task 3 (same full-suite run)
- **Issue:** The `phase 141 rejects ad-hoc motion and ungoverned duration drift` test scans every source line (including comments) for `\b\d+ms\b`. My `.tl-data-panel__region` comment said the reduced-motion blanket "collapses this to ~1ms" — the literal `1ms` tripped the check.
- **Fix:** Rephrased the comment to "collapses this near-instantly" — no literal duration in a comment.
- **Files modified:** lib/threadline/operator_surface/style.ex
- **Commit:** `19ef009` (folded into Task 3)

Both were caught and fixed within the plan; the full suite returned to the exact 2 RED-by-design failures present at baseline. No out-of-scope (Plan-04/05) work was done to chase green.

## Known Stubs

None — all three components are fully wired (data_panel composes the live state family + slots; toolbar/detail_header render real cluster/kv containers). No placeholder/empty-data paths introduced.

## Threat Flags

None — no new network endpoints, auth paths, file access, or schema changes. The permission/unavailable forensic distinction (T-177-04) is preserved by delegating to `data_state(@reason)`; the toolbar disabled-coordination (T-177-05) documents the HTML-`disabled`-on-controls enforcement contract; all new functions are `@doc false` internal (T-177-06); zero package installs (T-177-SC).

## Issues Encountered

The phase-141/142 StyleContractTest source-governance assertions are sensitive in ways the per-task `grep` verification didn't surface: a new `@media` literal and a `Nms` token in a comment both reddened tests outside the touched component. Resolved within Task 3 (see Deviations). Lesson recorded in `patterns-established`.

## User Setup Required

None — pure presentational layer; zero new dependencies (v1.37 zero-new-dep invariant; package-legitimacy gate vacuously satisfied).

## Next Phase Readiness

- `data_panel`/`toolbar`/`detail_header` are live and composable, so Plan 05's stress stories can assemble the 12 group configurations from real meta-components.
- Plan 04 still owns the offline-group anchor CSS and the overlay JS-transition utility classes (the 2 remaining RED style_contract scaffolds) + the region cross-fade source assertion (the `.tl-data-panel__region` opacity transition shipped here partially satisfies it; Plan 04 completes the overlay/offline source contract).
- GROUP-01/GROUP-02 deliberately NOT marked complete — they are phase-spanning and complete only when Plan 05 lands the full 12-config audit.
- No blockers.

## Self-Check: PASSED

- `177-03-SUMMARY.md` exists at the planned path.
- Task 1 commit `1f4d6d7` present in git log.
- Task 2 commit `2b082f8` present in git log.
- Task 3 commit `19ef009` present in git log.
- `UI.data_panel/1`, `UI.toolbar/1`, `UI.detail_header/1` defined in `lib/threadline/operator_surface/ui.ex`.
- `.tl-data-panel`, `.tl-toolbar`, `.tl-detail-header`, `.tl-transaction__breadcrumbs-current` present in `lib/threadline/operator_surface/style.ex`.

---
*Phase: 177-component-groups-meta-components*
*Completed: 2026-06-18*
