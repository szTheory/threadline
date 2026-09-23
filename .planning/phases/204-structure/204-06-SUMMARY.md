---
phase: 204-structure
plan: 06
subsystem: operator-surface
tags: [refactor, phoenix-component, ui-split, storybook, source-pins, zero-output-change]

requires:
  - phase: 204-structure
    provides: "204-05 UI.Actions/Display/Data families; 204-02 Threadline.Test.SourceFamily reader; 204-01 size gate and CSS byte lock"
provides:
  - "Threadline.OperatorSurface.UI.Overlay (modal, drawer, toast, show_/hide_ JS helpers, reconnect_banner, tooltip, popover, dropdown, accordion), @moduledoc false"
  - "Threadline.OperatorSurface.UI.Page (page_header + breadcrumb_trail, pager + pager_total, toolbar, detail_header, shell, tabs, segmented_control), @moduledoc false"
  - "Threadline.OperatorSurface.UI.Form (label, error, help, input, field, error_summary, field_group, radio, switch, combobox), @moduledoc false, history carried from ui.ex by git mv"
  - "lib/threadline/operator_surface/ui.ex retired; no size-gate entry; visibility seed lists the six families"
affects: [204-07, 204-08, source-size-gate, storybook-contracts, public-surface-contract]

actuals:
  tokens: 27000    # chars/4 over the changed lines of lib/test/examples, 53f5c4e3..5006395b (moved code counted as removed + added)
  tasks: 3
  commits: 4       # MEASURED: git rev-list --count 53f5c4e3..HEAD (3 refactor + 1 docs prose commit)
plan_head_before: 53f5c4e3

tech-stack:
  added: []
  patterns:
    - "Family module header: if Code.ensure_loaded?(Phoenix.Component), @moduledoc false, use Phoenix.Component, only the aliases used"
    - "Cross-family mounts go through a family alias (<Overlay.reconnect_banner /> in UI.Page.shell), never an import"
    - "Source-order pins over a split family locate the owning file via SourceFamily.files!/1 and measure ordering inside that file only"

key-files:
  created:
    - lib/threadline/operator_surface/ui/overlay.ex
    - lib/threadline/operator_surface/ui/page.ex
    - lib/threadline/operator_surface/ui/form.ex (git mv from ui.ex)
  modified:
    - lib/threadline/operator_surface/live/*.ex (12 LiveViews/components)
    - lib/threadline/operator_surface/presentation.ex (comment only)
    - examples/threadline_phoenix/storybook/**/*.story.exs (8 stories, call sites only)
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/source_size_contract_test.exs
  deleted:
    - lib/threadline/operator_surface/ui.ex (renamed to ui/form.ex)

key-decisions:
  - "ui.ex's size-gate entry was deleted in the Overlay commit, not lowered: at 654 lines the gate rejects any pin at or under the 800-line limit as stale."
  - "The timeline drawer field pin regex (~r/<UI\\.field\\b.../) is a rename pin for a component the Form commit moved, so it was rewritten to <UI\\.Form\\.field in that commit, with its logic unchanged."
  - "UI.Page aliases Script, Display, and Overlay. UI.Overlay aliases JS and Icon. UI.Form keeps JS only."

requirements-completed: [STRUCT-03]

coverage:
  - id: D1
    description: "UI.Overlay family with every call site, storybook marker, and the reconnect-banner shell pin rewritten; zero output change"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface + source_size + public_surface (874 tests, 0 failures) on 9e604767"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures) on 9e604767"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser on 9e604767: 326 passed / 8 failed (the known 8) / 16 skipped; baselines clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "UI.Page family, including the page-shell pin rewrite (UI.shell -> UI.Page.shell)"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "library test set 874 tests, 0 failures on 2f240c5a; credo --strict clean"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser on 2f240c5a: 326 / 8 known / 16; baselines clean"
        status: pass
    human_judgment: false
  - id: D3
    description: "ui.ex retired into UI.Form via git mv; visibility seed swapped; family names in prose"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "library test set incl. style_byte_lock_test + source_family_test (879 tests, 0 failures) on c22b6b08; full mix test 1769 tests, 0 failures, 1 excluded on 5006395b"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures) on c22b6b08"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser on c22b6b08: 326 / 8 known / 16; baselines clean"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix verify.dialyzer (0 errors); mix verify.xref_cycles (no cycles) on 5006395b"
        status: pass
    human_judgment: false

duration: 36 min
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 06: UI Family Split, Overlay, Page, and Form

**`Threadline.OperatorSurface.UI` is now six `@moduledoc false` family modules (Actions, Display, Data, Overlay, Page, Form), each under 800 lines. ui.ex was retired into `ui/form.ex` with `git mv`, so its history follows. Every call site, storybook marker, and source pin names its family. Rendered output did not change: the browser lane came back at exactly 326 passed / 8 known failures / 16 skipped after each of the three move commits, with no re-runs.**

## Performance

- **Duration:** about 36 min
- **Started:** 2026-09-23T21:41:02Z
- **Completed:** 2026-09-23T22:17Z
- **Tasks:** 3 of 3 (4 commits)
- **Files modified:** 41 across lib, test, and examples

## Final six-family membership

| Family | Module | Components | Aliases | Lines |
|---|---|---|---|---|
| Actions | `UI.Actions` | button, icon_button, link | none (`import Phoenix.Component, except: [link: 1]`) | 85 |
| Display | `UI.Display` | badge, alert, divider, spinner, avatar, card, stack, cluster, stat_tile, ref, kv, code_block | Icon, Presentation, Script | 226 |
| Data | `UI.Data` | data_table, data_panel, data_state, empty_state, error_state, loading_state, stale_banner | JS, Icon, Display | 352 |
| Overlay | `UI.Overlay` | modal, drawer, toast, show_/hide_ modal/drawer/toast, reconnect_banner, tooltip, popover, dropdown, accordion | JS, Icon | 401 |
| Page | `UI.Page` | page_header (+ breadcrumb_trail), pager (+ pager_total), toolbar, detail_header, shell, tabs, segmented_control | Script, Display, Overlay | 359 |
| Form | `UI.Form` (git mv of ui.ex) | label, error, help, input, field, error_summary, field_group, radio, switch, combobox | JS | 301 |

## Call-site counts per family (this plan)

These are the family-qualified references each commit added. Open and close tags count separately.

| Family (commit) | lib LiveViews | storybook stories | library tests | example test (markers) |
|---|---|---|---|---|
| Overlay (`9e604767`) | 27 | 20 | 15 | 7 |
| Page (`2f240c5a`) | 59 | 25 | 33 | 6 |
| Form (`c22b6b08`) | 24 | 26 | 20 | 10 |

## Storybook markers rewritten per commit

- `9e604767`: `"<UI.modal"`, `"<UI.drawer"`, `"<UI.toast"`, `"<UI.tooltip"`, `"<UI.popover"`, `"<UI.dropdown"`, `"<UI.accordion"` became `"<UI.Overlay.*"`.
- `2f240c5a`: `"<UI.page_header"`, `"<UI.pager"`, `"<UI.toolbar"`, `"<UI.detail_header"`, `"<UI.tabs"`, `"<UI.segmented_control"` became `"<UI.Page.*"`.
- `c22b6b08`: `"<UI.field"`, `"<UI.input"`, `"<UI.label"`, `"<UI.help"`, `"<UI.error"`, `"<UI.error_summary"`, `"<UI.field_group"`, `"<UI.radio"`, `"<UI.switch"`, `"<UI.combobox"` became `"<UI.Form.*"`. The `type="checkbox"`, `select`, and `textarea` markers are HTML attributes, so they stayed.
- List membership, labels, and `rendered_or_source_backed?/3` are unchanged. `grep -cE '"<UI\.[a-z_]+"'` on the file now prints 0.

## Pins

- **Reconnect-banner shell pin (Overlay commit):** the occurrence arithmetic is unchanged. The total count of `reconnect_banner` stays 2: the definition in overlay.ex plus the `<Overlay.reconnect_banner />` mount. Only the inline comment changed. The commit added an exactly-one-`def reconnect_banner(` check and an exactly-one-mount check (`~r/<(?:\.|Overlay\.|UI\.Overlay\.)reconnect_banner\b/`). It also locates the single family file containing `def shell(assigns)` through `SourceFamily.files!/1`, and asserts `threadline-ui` < mount < `tl-main` inside that file. The Page commit then moved `shell` into page.ex, and the test passed unedited.
- **Page-shell pin (Page commit):** in the Page commit, `component_contract_test.exs` changed in exactly two ways. The `assert src =~ "UI.shell"` literal became `"UI.Page.shell"`. Three `<UI.toolbar>` render call sites became `<UI.Page.toolbar>` (compile-required call sites, not pin edits). The `threadline-ui` and `tl-main` refutations and the reconnect-banner test were not touched.
- **Visibility seed:** Overlay and Page were appended in their own commits. The Form commit replaced `Threadline.OperatorSurface.UI` with `Threadline.OperatorSurface.UI.Form`, so the seed now lists the six families.
- **Size gate:** the ui.ex entry was removed in the Overlay commit (see Deviations). No function pins moved.
- The storybook fallback `source =~ "Threadline.OperatorSurface.UI"` still holds through the retained `alias Threadline.OperatorSurface.UI` lines. `SourceFamily.read!("lib/threadline/operator_surface/ui.ex")` now returns the six `ui/*.ex` files, with the parent gone.

## Task Commits

1. **Task 1: Tracer, UI.Overlay end-to-end.** `9e604767` (refactor). Tracer gate: the browser re-verified end-to-end before expansion.
2. **Task 2: Move UI.Page.** `2f240c5a` (refactor)
3. **Task 3: Retire ui.ex into UI.Form.** `c22b6b08` (refactor). Then the family names went into prose in `5006395b` (docs; 14 files, every one changed line-for-line).

## ZOC log

| Commit | compile --warnings-as-errors | lib tests | verify.example (117) | browser lane | credo --strict (touched lib) |
|---|---|---|---|---|---|
| `9e604767` Overlay | pass | 874, 0 failures | 0 failures | 326 / 8 known / 16, baselines clean | no issues |
| `2f240c5a` Page | pass | 874, 0 failures | 0 failures | 326 / 8 known / 16, baselines clean | no issues |
| `c22b6b08` Form | pass | 879, 0 failures (incl. style_byte_lock, source_family) | 0 failures | 326 / 8 known / 16, baselines clean | no issues |
| `5006395b` prose | pass | 874, 0 failures | n/a (no rendered code) | n/a | no issues |

The known 8 each time were `operator-screenshot-regression.spec.ts` :108, :115, :136, :145 on desktop and mobile. There were no re-runs. After each run, the scorecard fixtures were restored with `git checkout -- test/fixtures/operator_surface/scorecards/`. The plan's grep for "82 passed" is stale, so the gate was the invariant from the dispatch rules.

**Plan-level, on `5006395b`:** full `mix test` ran 1769 tests with 0 failures and 1 excluded. `mix verify.xref_cycles` found no cycles. `MIX_ENV=dev mix verify.dialyzer` reported 0 errors. `mix format --check-formatted` passed.

**Task 3 acceptance:** ui.ex is gone. There are 6 family files, none over 800 lines. No `<UI.<fn>` HEEx call remains. No unqualified marker remains. `operator_surface/ui.ex` appears 0 times in source_size_contract_test. The unqualified-prose grep prints nothing (ui_form_policy_contract_test excluded). The docs commit numstat is line-for-line. `git log --follow` on form.ex shows 44 commits, more than this plan's 4. `UI.Form` is present in the seed.

## Decisions Made

See key-decisions in the frontmatter. No `defdelegate` facades were added. Story `doc/0` prose was not edited: modal.story.exs:18-19 and data_table.story.exs:18 still say `UI.modal`, `UI.ref`, and so on.

## Deviations from Plan

**1. [Rule 3 - Blocking] The ui.ex size pin was deleted in Task 1 instead of lowered.** After the Overlay move, ui.ex measured 654 lines. `source_size_contract_test` fails any exception at or under the 800-line limit as stale ("delete the pin"). The entry was removed in `9e604767`, not in Task 3. The end state is the one the plan specifies.

**2. [Rule 3 - Blocking] The timeline drawer field pin regex was rewritten in the Form commit.** `timeline_browse_doc_contract_test.exs`'s `field_source/2` matched `~r/<UI\.field\b…/` against timeline_live.ex source. It failed after the Form rename. It is a source-text rename pin for a component moved in that same commit, so the literal became `<UI\.Form\.field\b` in `c22b6b08`, and its lookahead and assertions are unchanged. The plan's Form task did not list that pin explicitly, but its "every source-text pin updated in the same commit" truth covers it.

**3. The Page commit's component_contract_test diff includes three toolbar call sites** besides the `UI.shell` literal. They are `<UI.toolbar>` render call sites that had to be renamed to compile. The reconnect-banner test was unedited, as required.

---

**Total deviations:** 2 auto-fixed (both Rule 3), plus 1 noted scope clarification. **Impact:** none on output. Both fixes were rename pins or gate mechanics.

## Issues Encountered

- **Broken-windows ledger not appended:** `.planning/WINDOWS.md` is a protected path for this dispatch. There were no stubs or skipped tests to record anyway.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- STRUCT-03's UI split is complete: six families and no ui.ex. 204-08 still owns `ui_form_policy_contract_test`'s message, and the page-shell refutation widening.

---
*Phase: 204-structure*
*Completed: 2026-09-23*
