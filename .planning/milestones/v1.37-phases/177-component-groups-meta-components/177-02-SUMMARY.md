---
phase: 177-component-groups-meta-components
plan: 02
subsystem: ui
tags: [phoenix-liveview, function-components, css-tokens, layout-primitives, brand-parity, tdd]

# Dependency graph
requires:
  - phase: 177-component-groups-meta-components
    plan: "01"
    provides: RED token-parity scaffold (--tl-gap-*) and RED stack/cluster render assertions in ui_test
provides:
  - UI.stack/1 + UI.cluster/1 internal layout primitives (@doc false)
  - semantic gap tokens --tl-gap-inline/--tl-gap-stack/--tl-gap-section, value-aligned across tokens.css / tokens.json / style.ex
  - .tl-stack / .tl-cluster CSS owning the group spacing rhythm via flexbox gap
affects: [177-03, 177-04, 177-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Parity-first token landing: gap tokens added to tokens.css + tokens.json + style.ex in ONE task so brandbook_token_parity_test never drifts red mid-change (DS-05)"
    - "Layout primitives own inter-child spacing via flexbox `gap` over semantic --tl-gap-* tokens — never raw child margins (GROUP-01 / D-02)"
    - "stack/cluster follow the card/1 class-list idiom exactly: [\"tl-x\", \"tl-x--#{@variant}\", @class] + attr(:rest, :global) + slot(:inner_block, required: true)"

key-files:
  created:
    - .planning/phases/177-component-groups-meta-components/177-02-SUMMARY.md
  modified:
    - brandbook/tokens.css
    - brandbook/tokens.json
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/ui.ex

key-decisions:
  - "stack/1 gap values = stack|section|inline|tight; default 'stack' (--tl-gap-stack/16px). 'tight' maps to --tl-space-1 (4px) directly since there is no semantic tight gap token, per the plan action."
  - "cluster/1 justify values = start|between|end; default 'start'. justify modifiers map to flex justify-content (flex-start/space-between/flex-end)."
  - "data_panel/toolbar/detail_header RED scaffolds left RED by design — Plan 02 task scope + verification_note assign them to Plan 03, despite some test-name tags reading '[RED — Plan 02]'. Did NOT implement out-of-scope components to chase green."

patterns-established:
  - "tight gap (4px) on stack uses --tl-space-1 directly; the three SEMANTIC gap tokens cover inline/stack/section only (the names the parity test pins)"

requirements-completed: [GROUP-01]

# Metrics
duration: ~10min
completed: 2026-06-18
status: complete
---

# Phase 177 Plan 02: Layout primitives + semantic gap tokens Summary

**Shipped `UI.stack/1` + `UI.cluster/1` internal layout primitives and the three semantic gap tokens (`--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section`) they consume, turning the Plan-01 gap-parity and stack/cluster RED scaffolds GREEN with flexbox `gap` owning the spacing rhythm — zero new deps, no public component API.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-18
- **Completed:** 2026-06-18
- **Tasks:** 2
- **Files modified:** 4 (2 brandbook token sources + style.ex + ui.ex)

## Accomplishments

- **Task 1 (gap tokens, parity-first):** Added `--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section` to `tokens.css`, a matching `gap` block (8px/16px/32px) to `tokens.json`, and `--tl-gap-section: var(--tl-space-8)` to `style.ex` (inline/stack already present at L175-176). Landed in all three sources in one commit so `brandbook_token_parity_test` never drifted red mid-change. Map: inline→space-2 (8px), stack→space-4 (16px), section→space-8 (32px).
- **Task 2 (stack/cluster):** Added `@doc false` `stack/1` (`gap: stack|section|inline|tight`, default `stack`) and `cluster/1` (`justify: start|between|end`, default `start`) to `ui.ex` following the `card/1` class-list idiom exactly. Added `.tl-stack`/`.tl-cluster` CSS to `style.ex` — flexbox `gap` over `--tl-gap-*` tokens, with `tight` mapping to `--tl-space-1` (4px). No raw child margins.

## Task Commits

1. **Task 1: add semantic --tl-gap-* tokens across all three sources** — `8d701e8` (feat)
2. **Task 2: implement UI.stack/1 + UI.cluster/1 layout primitives** — `38005a3` (feat)

**Plan metadata:** see final docs commit.

## Files Created/Modified

- `brandbook/tokens.css` — added the three `--tl-gap-*` declarations aliasing `--tl-space-2/4/8`.
- `brandbook/tokens.json` — added a `gap` block keyed `inline`/`stack`/`section` → `8px`/`16px`/`32px`.
- `lib/threadline/operator_surface/style.ex` — added `--tl-gap-section: var(--tl-space-8)`; added `.tl-stack`/`.tl-stack--tight|inline|stack|section` and `.tl-cluster`/`.tl-cluster--start|between|end` rules (flexbox `gap`, no child margins).
- `lib/threadline/operator_surface/ui.ex` — added `@doc false` `stack/1` and `cluster/1` function components.

## RED Scaffold Ledger — what went GREEN this plan, what remains RED

| Scaffold (test) | File | Status after Plan 02 | Owning plan |
|---|---|---|---|
| `--tl-gap-*` parity across 3 sources | brandbook_token_parity_test | **GREEN** | 02 (this plan) |
| `stack/1` gap classes + no inline margin | ui_test | **GREEN** | 02 (this plan) |
| `cluster/1` tl-cluster + justify | ui_test | **GREEN** | 02 (this plan) |
| `data_panel/1` :ok data+pager | ui_test | RED (by design) | 03 |
| `data_panel/1` :loading suppresses data, shows status | ui_test | RED (by design) | 03 |
| `data_panel/1` :permission collapses body | ui_test | RED (by design) | 03 |
| `data_panel/1` stale banner ABOVE region | ui_test | RED (by design) | 03 |
| `toolbar/1` aria-disabled + is-disabled + HTML-disabled | ui_test | RED (by design) | 03 |
| `toolbar/1` enabled (no disabled signals) | ui_test | RED (by design) | 03 |
| `detail_header/1` `<h2>` + kv + actions cluster | ui_test | RED (by design) | 03 |
| offline anchor / overlay utility classes / region cross-fade | style_contract_test | RED (by design) | 04 |

## Verification

- `mix test test/threadline/brandbook_token_parity_test.exs` — **4 tests, 0 failures** (gap parity GREEN in both dark and light lanes).
- `mix test test/threadline/brandbook_token_parity_test.exs test/threadline/operator_surface/ui_test.exs` — **66 tests, 7 failures**. All 7 failures are the out-of-scope `data_panel`/`toolbar`/`detail_header` RED scaffolds owned by Plan 03; the 2 stack and 1 cluster scaffolds plus the gap-parity block are GREEN.
- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` — clean (whole project).
- `mix credo --strict lib/threadline/operator_surface/ui.ex lib/threadline/operator_surface/style.ex` — no issues.
- Acceptance: `grep -v '^#' brandbook/tokens.css | grep -c 'tl-gap-section'` = 1.

The 7 remaining failures are RED-by-design per this plan's `<verification_note>`: data_panel/toolbar/detail_header → 177-03; overlay/offline → 177-04. Not chased green here.

## Decisions Made

1. **`stack/1` `tight` gap → `--tl-space-1` (4px) directly.** The three SEMANTIC gap tokens cover inline/stack/section only (the names the parity test pins). `tight` is a stack-local convenience modifier mapping straight to the numeric `--tl-space-1` step, per the plan's Task 2 action ("tight maps to `--tl-space-1`/4px"). No new semantic gap token was minted for it, keeping the parity intersection exactly the three the test asserts.
2. **`cluster/1` justify modifiers map to `justify-content`.** `start`→`flex-start`, `between`→`space-between`, `end`→`flex-end`. Default `start` so the bare `<UI.cluster>` is a left-aligned wrapping row.
3. **Left data_panel/toolbar/detail_header RED.** Some ui_test scaffold names read `[RED — Plan 02]`, but the authoritative Plan-02 task list (Tasks 1–2 only) and the executor `<verification_note>` assign those components to Plan 03. Implementing them here would be out-of-scope scope-creep, so they remain RED by design.

## Deviations from Plan

None — plan executed exactly as written. Both tasks landed with the exact token map, component API, and CSS approach the plan specified.

## Known Stubs

None — both shipped primitives are fully wired (gap tokens consumed by `.tl-stack`/`.tl-cluster`; components render real flex containers). No placeholder/empty-data paths introduced.

## Issues Encountered

None.

## User Setup Required

None — pure presentational layer; zero new dependencies (v1.37 zero-new-dep invariant; package-legitimacy gate vacuously satisfied).

## Next Phase Readiness

- The gap rhythm is now token-driven and parity-locked, so Plan 03 (data_panel/toolbar/detail_header) and Plan 05 (stress stories) can compose `stack`/`cluster` without re-deriving spacing.
- Plan 03 turns the remaining data_panel/toolbar/detail_header RED scaffolds GREEN; Plan 04 owns the offline/overlay style scaffolds.
- No blockers.

## Self-Check: PASSED

- `177-02-SUMMARY.md` exists at the planned path.
- Task 1 commit `8d701e8` present in git log.
- Task 2 commit `38005a3` present in git log.
- `UI.stack/1` and `UI.cluster/1` defined in `lib/threadline/operator_surface/ui.ex`.
- `--tl-gap-section` present in all three of tokens.css / tokens.json / style.ex.

---
*Phase: 177-component-groups-meta-components*
*Completed: 2026-06-18*
