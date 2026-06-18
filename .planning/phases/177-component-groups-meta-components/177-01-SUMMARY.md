---
phase: 177-component-groups-meta-components
plan: 01
subsystem: ui
tags: [phoenix-liveview, function-components, css-tokens, tdd, brand-parity, connection-lifecycle, motion]

# Dependency graph
requires:
  - phase: 176-data-display-operator-patterns
    provides: state family (empty/loading/error/stale/no_data/permission/unavailable), data_table/kv/pager/ref, per-state focus rules (D-176-15)
  - phase: 175-navigation-app-shell-runtime-theme-picker
    provides: page_header/1 with breadcrumbs list attr, CSP-hardening posture
provides:
  - RED token-parity scaffold for --tl-gap-inline/--tl-gap-stack/--tl-gap-section across tokens.css/tokens.json/style.ex
  - RED style-contract scaffold for the offline group anchor (.threadline-ui.phx-loading/.phx-error) + overlay JS-transition utility classes + data-panel region cross-fade
  - RED render/coordination scaffold for stack/1, cluster/1, data_panel/1, toolbar/1, detail_header/1 + a passing breadcrumbs-trail assertion
  - Bound resolution of the two locked-decision-vs-reality conflicts (LiveView root anchor; breadcrumbs attr-keep)
affects: [177-02, 177-03, 177-04, 177-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wave-0 RED-first scaffolding: extend the existing File.read! source-assertion idiom (style_contract / brandbook_token_parity) and render_component idiom (ui_test) before any production code"
    - "Offline group keys off the LiveView ROOT element (.threadline-ui), not <body>; uses .phx-loading/.phx-error, never .phx-disconnected (LiveView 1.x)"
    - "Semantic gap tokens (--tl-gap-*) layered over the numeric --tl-space-* scale, parity-enforced across tokens.css/json/style.ex"

key-files:
  created:
    - .planning/phases/177-component-groups-meta-components/177-01-SUMMARY.md
  modified:
    - test/threadline/brandbook_token_parity_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/ui_test.exs

key-decisions:
  - "Offline CSS anchor = .threadline-ui.phx-loading / .threadline-ui.phx-error (LiveView root), NOT <body>, NEVER .phx-disconnected — confirmed 11/11 audit LiveViews render <div class=\"threadline-ui\"> as their render root (corrects D-08 literal wording per RESEARCH Pitfall 1)"
  - "Keep page_header/1's existing attr(:breadcrumbs, :list); do NOT add a same-named :breadcrumbs slot (would fail to compile). Deviation from D-04's literal 'slot' wording, justified by D-14 discretion (breadcrumbs are location DATA, not arbitrary markup) and RESEARCH Pitfall 4"
  - "--tl-gap-section maps to --tl-space-8 (32px); --tl-gap-inline to --tl-space-2 (8px); --tl-gap-stack to --tl-space-4 (16px) (D-09 discretion, RESEARCH Pattern 2 / A1)"

patterns-established:
  - "RED scaffolds are tagged in their describe/test names with the owning downstream plan ([RED — Plan 02]/[Plan 03]/Plan 04) so the orchestrator can trace each red test to the plan that turns it green"
  - "Overlay utility-class assertions are keyed to the class-selector form (.x { / .x,) so the pre-existing @keyframes tl-fade-in/tl-rise-in cannot false-green them"

requirements-completed: [GROUP-01, GROUP-02]

# Metrics
duration: ~20min
completed: 2026-06-18
status: complete
---

# Phase 177 Plan 01: Wave-0 conflict resolution + RED test scaffolds Summary

**Bound the two locked-decision-vs-reality conflicts (LiveView-root offline anchor; keep the breadcrumbs list attr) and laid 12 failing (RED) test scaffolds — 3 source/parity + 9 component-render — that Plans 02–05 turn green, with zero production code.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-18
- **Completed:** 2026-06-18
- **Tasks:** 3
- **Files modified:** 3 (all test files)

## Accomplishments

- **Task 1 (investigation/decision-binding):** Confirmed by grep that all 11 audit LiveViews render `<div class="threadline-ui" ...>` as their render root (the 12th `live/` file, `row_history_component.ex`, is a sub-component, not a LiveView root — score 0 as expected). Bound both conflict resolutions in writing (see Decisions Made).
- **Task 2 (RED token/style scaffolds):** 3 RED source/parity assertions — gap-token parity across tokens.css/json/style.ex; offline-group anchor on `.threadline-ui.phx-loading/.phx-error` with refutes of `.phx-disconnected`/`body.phx-`; overlay JS-transition utility classes as class selectors + data-panel region cross-fade.
- **Task 3 (RED component scaffolds):** 9 RED render/coordination assertions for `stack/1`, `cluster/1`, `data_panel/1` (×4: ok / loading / permission / stale-banner-above), `toolbar/1` (×2), `detail_header/1`, plus 1 GREEN breadcrumbs-trail assertion that extends the existing list attr.

## Task Commits

Each task was committed atomically:

1. **Task 1: Confirm LiveView connection-class anchor + bind the two conflicts** — no source change (deliverable is these SUMMARY notes); verified via grep (`coverage_live`/`timeline_live` each `class="threadline-ui"` = 1).
2. **Task 2: RED token-parity + style source scaffolds** — `bede897` (test)
3. **Task 3: RED render + coordination scaffolds for the 5 new components** — `4b7e304` (test)

**Plan metadata:** see final docs commit.

## Files Created/Modified

- `test/threadline/brandbook_token_parity_test.exs` — added one RED parity test block asserting `--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section` exist + are value-aligned (8/16/32px → `--tl-space-2/4/8`) in tokens.css, tokens.json (new `gap` block), and style.ex.
- `test/threadline/operator_surface/style_contract_test.exs` — added two RED test blocks: (a) offline-group anchor `.threadline-ui.phx-loading`/`.phx-error` with refutes of `.phx-disconnected` and `body.phx-`; (b) overlay JS-transition utility classes as class selectors (`.tl-fade-in`, `.tl-fade-out`, `.tl-rise-in/out`, `.tl-slide-in/out-right`, `.opacity-0/100`, `.translate-y-0/4`, `.translate-x-0/full`, `.tl-modal-container`, `.tl-drawer-container`) + `.tl-data-panel__region` opacity cross-fade on `--tl-motion-fast`.
- `test/threadline/operator_surface/ui_test.exs` — added 10 RED render/coordination tests (9 fail today — the 5 component functions are undefined; 1 breadcrumbs test passes against the existing attr).

## RED Scaffold Ledger (which downstream plan turns each green)

| Scaffold (test) | File | Status today | Owning plan |
|---|---|---|---|
| `--tl-gap-*` parity across 3 sources | brandbook_token_parity_test | RED | 02 (tokens) + 04 (style.ex gap-section) |
| offline anchor `.threadline-ui.phx-loading/.phx-error` (refute body/.phx-disconnected) | style_contract_test | RED | 04 |
| overlay JS-transition utility classes + region cross-fade | style_contract_test | RED | 04 |
| `stack/1` gap classes + no inline margin | ui_test | RED | 02 |
| `cluster/1` tl-cluster + justify | ui_test | RED | 02 |
| `data_panel/1` :ok data+pager | ui_test | RED | 02 |
| `data_panel/1` :loading suppresses data, shows status | ui_test | RED | 02 |
| `data_panel/1` :permission collapses body, delegates focus | ui_test | RED | 02 |
| `data_panel/1` stale banner ABOVE region | ui_test | RED | 02 |
| `toolbar/1` aria-disabled + is-disabled + HTML-disabled | ui_test | RED | 02 |
| `toolbar/1` enabled (no disabled signals) | ui_test | RED | 02 |
| `detail_header/1` `<h2>` + kv + actions cluster | ui_test | RED | 03 |
| `page_header` breadcrumbs trail (last crumb non-linked) | ui_test | **GREEN** | (extends existing attr; Plan 03 adds truncation) |

**RED delta:** 12 new failing tests (3 source/parity + 9 component renders). The breadcrumbs trail test is the 1 new GREEN test (it exercises the already-shipped list attr).

## Verification (RED-by-design)

- Three target files: **102 tests, 12 failures** — every failure is a new Phase 177 scaffold; all pre-existing assertions GREEN.
- Full suite: **1071 tests, 12 failures** — the exact same 12 new scaffolds; no pre-existing test regressed.
- `mix format --check-formatted` passes on all three touched test files.

This RED state is the deliverable, not a regression: the verification note for this plan states the new scaffolds are expected to fail until Plans 02–05 add production code. Do NOT add production code to green them in this plan.

## Decisions Made

1. **LiveView connection-class anchor = `.threadline-ui` (the LiveView ROOT).** Grep confirmed all 11 audit LiveViews render their top-level element as `<div class="threadline-ui" ...>`. The offline-group CSS (Plan 04) MUST key off `.threadline-ui.phx-loading` and `.threadline-ui.phx-error`, NOT `<body>`, and MUST NOT use `.phx-disconnected` (which does not exist in LiveView 1.x — the dropped-socket state re-applies `.phx-loading`). This corrects the literal wording of D-08/UI-SPEC per RESEARCH Pitfall 1 and resolves Open Question 1 / Assumption A2. If any future audit page's LiveView root were NOT `.threadline-ui`, the selector anchor would need adjusting — but today all 11 use it.

2. **Keep the breadcrumbs list attr; do NOT add a same-named slot.** `page_header/1` already declares `attr(:breadcrumbs, :list)` (ui.ex L189), rendered by private `breadcrumb_trail/1` (L232). Phoenix forbids an attr and a slot sharing a name, so a literal reading of D-04 (`:breadcrumbs` *slot*) would fail to compile. Breadcrumbs are location DATA (`%{label, href}`), not arbitrary markup, so the list attr is the cleaner contract. This is a deliberate deviation from D-04's literal "slot" wording, justified by D-14 discretion ("exact slot API … match existing idioms") and RESEARCH Pitfall 4. Plan 03 audits/extends `breadcrumb_trail/1` for narrow-viewport truncation only.

3. **`--tl-gap-section` → `--tl-space-8` (32px)** (with `--tl-gap-inline` → `--tl-space-2`/8px and `--tl-gap-stack` → `--tl-space-4`/16px). D-09 discretion; matches RESEARCH Pattern 2 / Assumption A1 and the UI-SPEC semantic-gap proposal.

## Deviations from Plan

None — plan executed exactly as written.

One mechanical adjustment worth noting (not a scope deviation): the `data_panel`/`pager` slot bodies in the new ui_test render snippets originally used `<table>`/`<nav>` opener tags inside `<:data>`/`<:pager>` slots, which the HEEx tokenizer rejects (it requires well-formed tags within a slot). Switched the slot bodies to self-contained `<div id="...">…</div>` wrappers. This is a test-authoring fix, not a contract change — the assertions (data-slot present/suppressed, pager present only when `:ok`, stale banner ordering) are unchanged.

## Issues Encountered

- HEEx tokenizer rejected unclosed `<table>`/`<nav>` tags inside test slot bodies (`missing opening tag for </data>`). Resolved by using well-formed `<div id="...">` markers inside the slots; the id-based assertions still verify slot suppression/rendering.

## User Setup Required

None — pure presentational test-scaffolding phase; zero new dependencies (v1.37 zero-new-dep invariant; package-legitimacy gate vacuously satisfied).

## Next Phase Readiness

- The component render contract and the source/parity contract are now pinned by RED tests, so Plans 02 (stack/cluster/data_panel/toolbar + gap tokens), 03 (detail_header + breadcrumb truncation), and 04 (offline CSS + overlay utility classes + region cross-fade) are fully test-driven.
- Selector anchor for the offline group is confirmed and bound (`.threadline-ui`), removing the medium-risk A2 ambiguity before any offline CSS is written.
- No blockers.

## Self-Check: PASSED

- `177-01-SUMMARY.md` exists at the planned path.
- Task 2 commit `bede897` present in git log.
- Task 3 commit `4b7e304` present in git log.

---
*Phase: 177-component-groups-meta-components*
*Completed: 2026-06-18*
