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
  - "component_contract_test reads of ui.ex go through SourceFamily.read!/1 (ui.ex + ui/*.ex)"
affects: [204-06, source-size-gate, storybook-contracts]

actuals:
  tokens: 25079    # chars/4 over the realized diff base..HEAD (moved code counted as removed + added)
  tasks: 2         # of 3; Task 3 (UI.Data) not started
  commits: 2
plan_head_before: 0a4c1ff536c10590bb13fce67543ffe1cdaab960

tech-stack:
  added: []
  patterns:
    - "Family module header: if Code.ensure_loaded?(Phoenix.Component), @moduledoc false, use Phoenix.Component, only the aliases the family uses"
    - "Cross-family calls from ui.ex use a family alias (<Display.kv>), not the old local <.kv>"

key-files:
  created:
    - lib/threadline/operator_surface/ui/actions.ex
    - lib/threadline/operator_surface/ui/display.ex
  modified:
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/live/*.ex (9 LiveViews)
    - examples/threadline_phoenix/storybook/**/*.story.exs (8 stories)
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/source_family_test.exs

key-decisions:
  - "ui.ex dropped `import Phoenix.Component, except: [link: 1]` once link/1 moved: nothing left in ui.ex calls <.link>, and `use Phoenix.Component` already imports the module. UI.Actions carries the except import."
  - "ui.ex dropped the Presentation alias once ref/1 moved (unused alias fails --warnings-as-errors)."
  - "The ZOC browser gate went red on Task 2 with two extra assertion failures, and per the dispatch rules the plan halted there instead of re-running."

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
        ref: "mix verify.example_browser on 1fe2d345: 326 passed / 8 failed (exactly the known screenshot-regression :108/:115/:136/:145 x desktop+mobile) / 16 skipped; baselines clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "UI.Display family module with every call site and storybook marker renamed"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "same library test set (898 tests, 0 failures); mix credo --strict on touched lib files: no issues"
        status: pass
      - kind: integration
        ref: "mix verify.example (117 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser on 8d6e69c6: 324 passed / 10 failed / 16 skipped; the 8 known plus 2 extra desktop-only assertion failures"
        status: fail
    human_judgment: true
    rationale: "Browser lane went red with two extra failures. The dispatch rules forbid a re-run for assertion failures, so a human or the orchestrator has to decide whether to re-run or revert 8d6e69c6."
  - id: D3
    description: "UI.Data family module"
    requirement: STRUCT-03
    verification: []
    human_judgment: true
    rationale: "Not started: the plan halted at the Task 2 browser gate."

duration: 28 min
completed: 2026-09-23
status: halted
---

# Phase 204 Plan 05: UI Family Split, Actions and Display (HALTED at the Task 2 browser gate)

**`UI.Actions` (3 components) and `UI.Display` (12 components) are now their own `@moduledoc false` modules. Every call site and every storybook contract marker names the family, and ui.ex went from 1686 lines to 1390. The Task 2 browser lane then showed 10 failures instead of 8. Both extra failures are desktop-only assertion timeouts after a user interaction. The dispatch rules allow a re-run only for a teardown hang with no assertion, so the plan halted before Task 3 (`UI.Data`).**

## Performance

- **Duration:** about 28 min
- **Started:** 2026-09-23T20:32:58Z
- **Halted:** 2026-09-23T21:00:51Z
- **Tasks:** 2 of 3 committed
- **Files modified:** 28

## HALT: Task 2 browser gate

Run: `mix verify.example_browser` on `8d6e69c6`, log in `/tmp/p204-05-browser-t2.log`. Result: **324 passed / 10 failed / 16 skipped**. The Playwright screenshot baselines are clean.

The 8 known failures are all present: `operator-screenshot-regression.spec.ts` :108, :115, :136, :145 on desktop and mobile. The two extra failures:

1. `[desktop-chromium] operator-screenshots.spec.ts:90` "admin investigation and governance surfaces". The test clicks the `30d` button on the Actor page (spec :135), then `expect(getByRole('button', {name: '30d', pressed: true})).toBeVisible()` at :165 times out after 15s. The page snapshot still shows `24h` pressed, so the click never reached the LiveView.
2. `[desktop-chromium] operator-timeline-investigation-flow.spec.ts:583` "restores URL-backed filters and proves Timeline route handoffs". The test fills `#filter-correlation-id` and presses Enter. `expect.poll(... searchParams.get("table")).toBe("ticket_replies")` at :400 then times out with `null`, so the filter submit never patched the URL.

**Evidence that this is flake rather than an output change (for the orchestrator's decision; the halt itself is not in question):**
- The same two specs passed on `mobile-chromium` in the same run, against the same server and the same rendered HTML.
- Both failures are a lost interaction (a click or Enter that never reached the server). Neither is a markup assertion. The `30d` control is `segmented_control` and the filter form is in `timeline_live`, and this commit moved neither.
- The server log has no `[error]` lines and no crash. `--warnings-as-errors` compile passed, so every remote `<UI.Display.*>` call resolves.
- Every rendered-output check was green on this commit: the style byte lock, `rendered_output_contract`, component contract render assertions, `ui_test`, `pager_test`, `page_header_test`, and all 117 example-app tests, including story rendering.
- The Task 1 commit `1fe2d345` had the same kind of change (tag renames only) and got exactly the 8 known failures.

**Not done because of the halt:** no re-run of the browser lane, no revert of `8d6e69c6`, and Task 3 (`UI.Data`) not started. The plan-level full `mix test`, `verify.xref_cycles`, and `verify.dialyzer` were not run either.

**Options for the orchestrator:** (a) re-run `mix verify.example_browser` on `8d6e69c6` with nothing changed. If it comes back at exactly the known 8, resume at Task 3. (b) Revert `8d6e69c6` and retry the Display move, as the plan's HALT clause says.

## Accomplishments

- **UI.Actions (Task 1, tracer):** button, icon_button, and link moved verbatim with their `attr`/`slot` declarations and `@doc false`. Nothing else in ui.ex called them, so ui.ex needed no Actions alias. The tracer gate (end-of-phase mode, automated verify only) re-ran green, so expansion went ahead.
- **UI.Display (Task 2):** twelve components moved verbatim, and so did the prose comments above `ref/1` and `kv/1`. ui.ex's remaining `detail_header` and `loading_state` call `<Display.cluster>`, `<Display.kv>`, and `<Display.spinner>` through `alias Threadline.OperatorSurface.UI.Display`.
- **Pins:** `component_contract_test` now reads the family (`SourceFamily.read!/1`) at all 7 former `File.read!` sites of ui.ex, including the reconnect-anchor loop. So 204-06 can retire ui.ex without breaking those reads.
- **No `defdelegate`** in ui.ex, actions.ex, or display.ex. **Story `doc/0` prose unchanged**: the "Covered primitives: UI.button, …" line is untouched.

## Family membership (as moved)

| Family | Module | Components | Aliases | Lines |
|---|---|---|---|---|
| Actions | `Threadline.OperatorSurface.UI.Actions` | button, icon_button, link | none (`import Phoenix.Component, except: [link: 1]`) | 85 |
| Display | `Threadline.OperatorSurface.UI.Display` | badge, alert, divider, spinner, avatar, card, stack, cluster, stat_tile, ref, kv, code_block | Icon, Presentation, Script | 226 |
| Data | `Threadline.OperatorSurface.UI.Data` | data_table, data_panel, data_state, empty_state, error_state, loading_state, stale_banner | (JS, Icon, Display) | not started |

## Call-site rewrites per family

Counts are family-qualified references added in each commit. Open and close tags count separately.

| Family | lib LiveViews | storybook stories | tests (incl. markers) | inside ui.ex |
|---|---|---|---|---|
| Actions (`1fe2d345`) | 42 (all in stress_live, fully qualified `Threadline.OperatorSurface.UI.Actions.*`) | 46 | 11 | 0 |
| Display (`8d6e69c6`) | 56 (9 LiveViews) | 138 | 48 | 5 (`Display.spinner/cluster/kv`) |

## Storybook markers rewritten per commit

- `1fe2d345`: `"<UI.button"`, `"<UI.icon_button"`, `"<UI.link"` became `"<UI.Actions.button"`, `"<UI.Actions.icon_button"`, `"<UI.Actions.link"`.
- `8d6e69c6`: `"<UI.badge"`, `"<UI.alert"`, `"<UI.divider"`, `"<UI.spinner"`, `"<UI.avatar"`, `"<UI.card"`, `"<UI.stack"`, `"<UI.cluster"`, `"<UI.stat_tile"`, `"<UI.ref"`, `"<UI.kv"`, `"<UI.code_block"` became `"<UI.Display.<fn>"`.
- In both commits, list membership, labels, and `rendered_or_source_backed?/3` are unchanged.

## Task Commits

1. **Task 1: Tracer, UI.Actions end-to-end.** `1fe2d345` (refactor)
2. **Task 2: Move UI.Display.** `8d6e69c6` (refactor). The browser gate went red after this commit (see HALT).
3. **Task 3: Move UI.Data.** Not started.

## ZOC log

| Commit | compile --warnings-as-errors | lib tests (898) | verify.example (117) | browser lane | credo --strict (touched lib) |
|---|---|---|---|---|---|
| `1fe2d345` Actions | pass | 0 failures | 0 failures | 326 / 8 known / 16, baselines clean | no issues |
| `8d6e69c6` Display | pass | 0 failures | 0 failures | **324 / 10 / 16** (8 known + 2 extra desktop-only) | no issues |

The lib test set was `test/threadline/operator_surface`, `source_size_contract_test`, `public_surface_contract_test`, `source_family_test`, and `release_artifact_contract_test`. The tracked scorecard fixtures were restored after each browser run.

Task 1 acceptance criteria, all PASS:
- the unqualified call-site grep printed nothing
- 0 stale markers, and `"<UI.Actions.button"` appears exactly once
- the marker-only diff check exited 0
- `defdelegate` count is 0 in both files
- the story-prose diff check exited 0

Task 2: the unqualified Display call-site grep exited 0, and display.ex has 226 lines (at most 800).

## Size gate

The ui.ex file exception went from 1686 to 1607 at Task 1, then to 1390 at Task 2. No function-length pin moved, because the call-site rewrites change line length, not line count.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

**1. [Rule 3 - Blocking] `source_family_test` used ui.ex as its "file with no sibling directory" example.**
- **Found during:** Task 1.
- **Issue:** `test/threadline/source_family_test.exs:18` asserted `SourceFamily.files!("lib/threadline/operator_surface/ui.ex") == [ui.ex]`. That stops being true as soon as `ui/actions.ex` exists. The file was not in the plan's list.
- **Fix:** Pointed the example at `lib/threadline/query/filter_params.ex`, which has no sibling directory. The assertion itself is unchanged.
- **Committed in:** `1fe2d345`.

**2. [Rule 3 - Blocking] ui.ex import and alias cleanup.**
- ui.ex removed `import Phoenix.Component, except: [link: 1]` (Task 1) and `alias ...Presentation` (Task 2). Both were left unused by the moves.
- The plan's suggested `alias ...UI.Actions` in ui.ex was not added, because ui.ex has no Actions call sites. An unused alias would fail `--warnings-as-errors`.

**Total deviations:** 2 auto-fixed (both blocking). **Impact:** none on output.

## Issues Encountered

- The HALT described above.
- Comment-only mentions of `UI.ref/1` remain in `lib/threadline/operator_surface/presentation.ex:80` and in three test comments. They are prose, not call sites, and were left as is.
- **Broken-windows ledger not appended:** `.planning/WINDOWS.md` is a protected path for this dispatch.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Blocked until the orchestrator resolves the Task 2 browser gate (re-run or revert). After that, Task 3 (`UI.Data`) resumes, then the plan-level full `mix test`, `verify.xref_cycles`, and `MIX_ENV=dev mix verify.dialyzer`.

---
*Phase: 204-structure*
*Halted: 2026-09-23*

## Self-Check: PASSED

- `lib/threadline/operator_surface/ui/actions.ex` and `ui/display.ex` exist, and each has `@moduledoc false`.
- Commits `1fe2d345` and `8d6e69c6` resolve. The ledger count (`git rev-list --count 0a4c1ff5..HEAD`) is 2, matching `actuals.commits`.
- `status: halted` is recorded honestly. The plan is not complete.
