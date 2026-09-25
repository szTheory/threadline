---
phase: 204-structure
plan: 05
subsystem: operator-surface
tags: [refactor, phoenix-component, ui-split, storybook, source-pins, zero-output-change]

requires:
  - phase: 204-structure
    provides: "204-01 size gate and CSS byte lock; 204-02 Threadline.Test.SourceFamily reader"
provides:
  - "Threadline.OperatorSurface.UI.Actions (button, icon_button, link), @moduledoc false"
  - "Threadline.OperatorSurface.UI.Display (badge, alert, divider, spinner, avatar, card, stack, cluster, stat_tile, ref, kv, code_block), @moduledoc false"
  - "Threadline.OperatorSurface.UI.Data (data_table, data_panel, data_state, empty_state, error_state, loading_state, stale_banner), @moduledoc false"
  - "component_contract_test reads of ui.ex go through SourceFamily.read!/1 (ui.ex + ui/*.ex)"
affects: [204-06, source-size-gate, storybook-contracts]

actuals:
  tokens: 24002    # chars/4 over the changed lines of lib/test/examples, 0a4c1ff5..3dd1f64f (moved code counted as removed + added)
  tasks: 3         # all three family commits landed; both browser halts were cleared as flakes by orchestrator re-runs
  commits: 5       # MEASURED: git rev-list --count 0a4c1ff5..HEAD = 3 task commits + 2 docs commits from the first halt
plan_head_before: 0a4c1ff536c10590bb13fce67543ffe1cdaab960

tech-stack:
  added: []
  patterns:
    - "Family module header: if Code.ensure_loaded?(Phoenix.Component), @moduledoc false, use Phoenix.Component, only the aliases the family uses"
    - "Cross-family calls use a family alias (<Display.spinner> inside UI.Data and ui.ex), not the old local <.spinner>"

key-files:
  created:
    - lib/threadline/operator_surface/ui/actions.ex
    - lib/threadline/operator_surface/ui/display.ex
    - lib/threadline/operator_surface/ui/data.ex
  modified:
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/live/*.ex (9 LiveViews)
    - examples/threadline_phoenix/storybook/**/*.story.exs (8 stories)
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/operator_surface/ui_test.exs
    - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
    - test/threadline/operator_surface/ui_stress_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/source_family_test.exs

key-decisions:
  - "ui.ex dropped `import Phoenix.Component, except: [link: 1]` once link/1 moved: nothing left in ui.ex calls <.link>, and `use Phoenix.Component` already imports the module. UI.Actions carries the except import."
  - "ui.ex dropped the Presentation alias once ref/1 moved (unused alias fails --warnings-as-errors)."
  - "UI.Data aliases JS, Icon, and Display only. Its components call each other locally (<.empty_state>, <.error_state>, <.data_state>, <.loading_state>, <.stale_banner>). It has no Actions call, so no Actions alias."
  - "ui.ex keeps its JS, Icon, Script, and Display aliases. All four are still used by the remaining Page/Overlay/Form components."
  - "The Task 2 browser failure was ruled a flake after an orchestrator re-run. The Task 3 browser gate then went red with a different extra assertion failure, so the plan halted again, per the dispatch rule."

requirements-completed: []
requirements-advanced: [STRUCT-03]

coverage:
  - id: D1
    description: "UI.Actions family module with every call site and storybook marker renamed; zero output change"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface + source_size + public_surface + source_family + release_artifact (898 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures, incl. storybook_stories_test)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser on 1fe2d345: 326 passed / 8 failed (the known 8) / 16 skipped; baselines clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "UI.Display family module with every call site and storybook marker renamed"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "same library test set (898 tests, 0 failures); credo --strict on touched lib files: no issues"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "executor run on 8d6e69c6: 324/10/16 (2 extra desktop-only). Orchestrator re-run on the unchanged code: 326 passed / 8 failed (the known 8) / 16 skipped"
        status: pass
    human_judgment: false
  - id: D3
    description: "UI.Data family module with every call site and storybook marker renamed"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "library test set incl. style_byte_lock_test (898 tests, 0 failures); full mix test 1769 tests, 0 failures, 1 excluded; credo --strict on touched lib files: no issues"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser on 3dd1f64f: 325 passed / 9 failed / 16 skipped; the known 8 plus desktop-only operator-accessibility.spec.ts:620"
        status: fail
    human_judgment: true
    rationale: "One extra failure, and it is an assertion failure (toBeFocused), not a teardown hang. The dispatch rules forbid a re-run for that, so the orchestrator has to decide whether to re-run or revert 3dd1f64f."

duration: 28 min (first run) + about 35 min (resume)
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 05: UI Family Split, Actions, Display, and Data

**All three families (`UI.Actions`, `UI.Display`, `UI.Data`) are now `@moduledoc false` modules. Every call site and every storybook contract marker names the family, and ui.ex went from 1686 lines to 1047. Every rendered-output check is green, and so are the full `mix test`, `verify.xref_cycles`, and `verify.dialyzer`. The Task 3 browser lane then showed 9 failures: the known 8 plus one desktop-only focus assertion in the row-history drawer. That is an assertion failure, not a teardown hang, so the plan halted without a re-run. The orchestrator then re-ran the lane on the unchanged `3dd1f64f` and got exactly 326/8/16. The extra failure was a flake, and the plan is complete.**

## Performance

- **First run:** 2026-09-23T20:32:58Z to 21:00:51Z. Tasks 1 and 2 committed, then halted at the Task 2 browser gate.
- **Resume:** Task 3 committed as `3dd1f64f`, then halted at the Task 3 browser gate.
- **Tasks:** 3 of 3 committed. The plan is not complete because the Task 3 browser gate is red.

## HALT: Task 3 browser gate (resolved as a flake)

**Resolution:** the orchestrator re-ran `mix verify.example_browser` on the unchanged `3dd1f64f` and got exactly **326 passed / 8 failed / 16 skipped**. The failures were the known 8 only, and `operator-accessibility.spec.ts:620` passed on desktop. It was a flake, not a regression, so option (a) applied and nothing was reverted.

Run: `mix verify.example_browser` on `3dd1f64f`, log in `/tmp/p204-05-browser-t3.log`. Result: **325 passed / 9 failed / 16 skipped**. The screenshot baselines are clean, and the scorecard fixtures were restored after the run.

The known 8 all failed as expected: `operator-screenshot-regression.spec.ts` :108, :115, :136, :145 on desktop and mobile. The extra failure:

- `[desktop-chromium] operator-accessibility.spec.ts:620` "keeps row-history drawer dialog semantics and visible focus". At spec :755, `expectNonObscuredFocused` calls `expect(locator).toBeFocused()`. The locator is the drawer's `View snapshot at` input (`#row-history-as-of`). It resolved 34 times but stayed `inactive` until the 15s timeout ran out.

**Evidence for the orchestrator (the halt itself is not in question):**
- The same spec passed on `mobile-chromium` in the same run, against the same server and the same HTML.
- It is a focus-timing assertion. It is not a markup or content assertion.
- The drawer is rendered by `row_history_live.ex` and `row_history_component.ex`, and this commit touched neither. The spec first visits the transaction page. In `transaction_live.ex`, the commit only renamed the `<UI.error_state>` and `<UI.empty_state>` tags, and neither one renders on a successful load.
- Every rendered-output check was green on `3dd1f64f`: compile with `--warnings-as-errors`, the style byte lock, `rendered_output_contract`, component contract render assertions, `ui_test`, `pager_test`, `page_header_test`, and all 117 example-app tests, including story rendering.
- The Task 2 halt had the same shape (a desktop-only interaction timeout in an untouched component), and the orchestrator's re-run of that unchanged code came back at exactly the known 8.

**Options for the orchestrator:** (a) re-run `mix verify.example_browser` on `3dd1f64f` with nothing changed. If it comes back at exactly the known 8, the plan is complete, because every other plan-level check has already passed (see below). (b) Revert `3dd1f64f` and retry the Data move, as the plan's HALT clause says.

## Accomplishments

- **UI.Actions (Task 1, tracer):** button, icon_button, and link moved verbatim with their `attr`/`slot` declarations and `@doc false`.
- **UI.Display (Task 2):** twelve components moved verbatim, including the prose comments above `ref/1` and `kv/1`. ui.ex's `detail_header` calls `<Display.cluster>` and `<Display.kv>` through a `Display` alias.
- **UI.Data (Task 3):** seven components moved verbatim, with their attrs, slots, and comment blocks, including the locked data_panel coordination-rules comment. `data_panel` still raises `ArgumentError` when a permission or unavailable state has no reason. `loading_state` calls `<Display.spinner>`. The internal `<.empty_state>`, `<.error_state>`, `<.data_state>`, `<.loading_state>`, and `<.stale_banner>` calls stay local because all of them now live in the same module.
- **Pins:** `component_contract_test` reads the family through `SourceFamily.read!/1` at all 7 former `File.read!` sites of ui.ex. Task 3 needed no new pin repoints.
- **No `defdelegate`** in ui.ex or any family module. **Story `doc/0` prose unchanged**: `data_table.story.exs:18` "Covered data display: UI.ref, UI.kv, UI.data_table, …" is untouched. The prose mention of `UI.data_state/1` in the `data_state_mapping_wave0_test` moduledoc is also unchanged.

## Family membership (as moved)

| Family | Module | Components | Aliases | Lines |
|---|---|---|---|---|
| Actions | `Threadline.OperatorSurface.UI.Actions` | button, icon_button, link | none (`import Phoenix.Component, except: [link: 1]`) | 85 |
| Display | `Threadline.OperatorSurface.UI.Display` | badge, alert, divider, spinner, avatar, card, stack, cluster, stat_tile, ref, kv, code_block | Icon, Presentation, Script | 226 |
| Data | `Threadline.OperatorSurface.UI.Data` | data_table, data_panel, data_state, empty_state, error_state, loading_state, stale_banner | JS, Icon, Display | 352 |

## Call-site rewrites per family

Counts are the family-qualified references each commit added. Open and close tags count separately.

| Family | lib LiveViews | storybook stories | tests (incl. markers) | inside ui.ex |
|---|---|---|---|---|
| Actions (`1fe2d345`) | 42 (all in stress_live, fully qualified) | 46 | 11 | 0 |
| Display (`8d6e69c6`) | 56 (9 LiveViews) | 138 | 48 | 5 |
| Data (`3dd1f64f`) | 37 (7 LiveViews; 17 in stress_live, fully qualified) | 33 (4 stories) | 63 (5 files, incl. 2 markers) | 0 |

## Storybook markers rewritten per commit

- `1fe2d345`: `"<UI.button"`, `"<UI.icon_button"`, `"<UI.link"` became `"<UI.Actions.*"`.
- `8d6e69c6`: `"<UI.badge"`, `"<UI.alert"`, `"<UI.divider"`, `"<UI.spinner"`, `"<UI.avatar"`, `"<UI.card"`, `"<UI.stack"`, `"<UI.cluster"`, `"<UI.stat_tile"`, `"<UI.ref"`, `"<UI.kv"`, `"<UI.code_block"` became `"<UI.Display.*"`.
- `3dd1f64f`: `"<UI.data_table"` and `"<UI.data_panel"` became `"<UI.Data.data_table"` and `"<UI.Data.data_panel"`.
- In all three commits, list membership, labels, and `rendered_or_source_backed?/3` are unchanged.

## Task Commits

1. **Task 1: Tracer, UI.Actions end-to-end.** `1fe2d345` (refactor)
2. **Task 2: Move UI.Display.** `8d6e69c6` (refactor)
3. **Task 3: Move UI.Data.** `3dd1f64f` (refactor). The browser gate went red after this commit (see HALT).

The first run's halt records are `6ddf5b94` (SUMMARY) and `2ea4da2e` (STATE blocker).

## ZOC log

| Commit | compile --warnings-as-errors | lib tests (898) | verify.example (117) | browser lane | credo --strict (touched lib) |
|---|---|---|---|---|---|
| `1fe2d345` Actions | pass | 0 failures | 0 failures | 326 / 8 known / 16, baselines clean | no issues |
| `8d6e69c6` Display | pass | 0 failures | 0 failures | executor 324/10/16; **orchestrator re-run 326 / 8 known / 16** | no issues |
| `3dd1f64f` Data | pass | 0 failures (incl. style_byte_lock_test) | 0 failures | **325 / 9 / 16** (8 known + accessibility.spec.ts:620 desktop) | no issues |

`mix format --check-formatted` passed on `3dd1f64f`.

**Plan-level verification on `3dd1f64f`** (run after the halt, as evidence for the orchestrator):
- full `mix test`: 1769 tests, 0 failures, 1 excluded
- `mix verify.xref_cycles`: exit 0, no cycles
- `MIX_ENV=dev mix verify.dialyzer`: exit 0, 0 errors

**Task 3 acceptance:**
- The unqualified Data call-site grep over lib, the storybook, the example lib and test, and test printed nothing.
- data.ex has 352 lines (at most 800).
- `defdelegate` count is 0.

## Size gate

The ui.ex file exception went 1686 → 1607 (Task 1) → 1390 (Task 2) → 1047 (Task 3). No function-length pin moved.

## Deviations from Plan

**1. [Rule 3 - Blocking] `source_family_test` used ui.ex as its "file with no sibling directory" example** (Task 1, `1fe2d345`). Pointed it at `lib/threadline/query/filter_params.ex` instead. The assertion is unchanged.

**2. [Rule 3 - Blocking] ui.ex import and alias cleanup.** Removed `import Phoenix.Component, except: [link: 1]` (Task 1) and the `Presentation` alias (Task 2), both unused after the moves. The plan's suggested `alias ...UI.Actions` in ui.ex was not added, because ui.ex has no Actions call sites.

**3. [Gate] Task 2 browser flake, resolved by the orchestrator.** The first executor saw 324 passed / 10 failed / 16 skipped on `8d6e69c6`. The two extras were desktop-only interaction timeouts: `operator-screenshots.spec.ts:90` and `operator-timeline-investigation-flow.spec.ts:583`. It halted, per the rules. The orchestrator re-ran `mix verify.example_browser` on that unchanged code and got exactly 326 passed / 8 failed / 16 skipped, the known 8 only, with both extras passing. It ruled them a flake, not a regression, and Tasks 1 and 2 were kept.

**4. [Gate] Task 3 browser flake, resolved by the orchestrator.** The executor saw 325/9/16 on `3dd1f64f`, with one extra failure: a desktop-only `toBeFocused` timeout in the row-history drawer. The orchestrator re-ran that unchanged code and got exactly 326/8/16. It was a flake. See HALT.

**5. [Rule 3 - Blocking] Root-pin guard script denied by the permission classifier.** Running `bash .../root-pin.sh` was blocked by the auto-mode classifier. It was not a guard failure. As the equivalent check, `git rev-parse --show-toplevel` was confirmed to equal the pinned root `/Users/jon/projects/threadline` before the edit and before the commit. The branch was also confirmed as `fix/branch-protection-actions-capability`, which is not protected.

## Issues Encountered

- The two browser halts above. Both were desktop-only lost-input flakes, and each was cleared by one unchanged re-run.
- Comment and prose mentions of `UI.ref/1`, `UI.data_table`, `UI.data_panel`, and `UI.data_state/1` remain in `presentation.ex:80`, the story `doc/0` prose, and test moduledocs and comments. They are prose, not call sites, and they were left as is.
- **Broken-windows ledger not appended:** `.planning/WINDOWS.md` is a protected path for this dispatch.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Ready: 204-06 (Overlay, Page, Form, and retiring ui.ex) can start.

---
*Phase: 204-structure*
*Completed: 2026-09-23*

## Self-Check: PASSED

- `lib/threadline/operator_surface/ui/actions.ex`, `ui/display.ex`, and `ui/data.ex` exist, and each has `@moduledoc false`.
- Commits `1fe2d345`, `8d6e69c6`, and `3dd1f64f` resolve. The ledger count (`git rev-list --count 0a4c1ff5..HEAD`) was 5 when this SUMMARY was written, matching `actuals.commits`.
- `status: complete` is set by the orchestrator after a clean browser re-run (326/8/16) on `3dd1f64f`.
