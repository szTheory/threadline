---
phase: 204-structure
plan: 11
subsystem: operator-surface
tags: [refactor, liveview, function-components, size-gate, banners, credo, structural-register]
status: complete

requires:
  - phase: 204-structure
    provides: "carved-render pattern and render-capture harness (204-08/09/10), size gate at measured pins (204-01), credo register at 18 (204-10)"
provides:
  - "ActorLive: private not_found_state/1, actor_header/1, actor_activity/1; render/1 149 -> 43 lines"
  - "ActorLive: activity_presence/4 replaces the nested case in mount/3; register site drained"
  - "StartLive: private home_header/1, task_cards/1, record_lookup/1, correlation_lookup/1, saved_views/1; render/1 190 -> 47 lines; 6 banner lines gone"
  - "CoverageLive: private coverage_header/1, coverage_table/1; render/1 135 -> 59 lines; 3 banner lines gone"
  - "Size gate: @function_exceptions %{}; banner entries left only for export_controller (9) and actor_ref (3), both owned by 204-12"
  - "Credo register 18 -> 17 (Nesting 14, CyclomaticComplexity 3)"
affects: [204-12, 204-15, source-size-contract, credo-config-contract, STRUCT-03, STRUCT-04, STRUCT-07]

actuals:
  tokens: 5500      # chars/4 over the realized diff 273a8001..461d66a4 (22188 chars)
  tasks: 2
  commits: 4        # MEASURED: git rev-list --count 273a8001..HEAD before the SUMMARY commit
plan_head_before: 273a8001

tech-stack:
  added: []
  patterns:
    - "Moved markup keeps its original absolute indentation inside the component's ~H, so HEEx template trimming plus the unchanged call-site whitespace give byte-identical output (same technique as 204-09/10)"
    - "Render-capture harness (/tmp/p204_11_capture.exs, adapted from 204-10) captured 70 renders of the three pages across their LiveView, copy_contract, and rendered_output tests; compared byte-for-byte after each commit"

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/start_live.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - test/threadline/source_size_contract_test.exs
    - test/threadline/credo_config_contract_test.exs

key-decisions:
  - "All three pages were carved in-module (D-08 default). No file approaches 800 lines (actor 509, start 530, coverage 548), so no sibling module was needed and no source pin had to be repointed."
  - "start_live's two helper-section banners (Health aggregation; Recent/saved fast-path) lost their rule lines and kept their heading text as plain comments, matching the 204-04 'prose comment' disposition. The helpers stay in StartLive: a sibling module would have forced repointing start_live_test's source pins (defp storage_opts) for no legibility gain."
  - "coverage_live's mount/3 banner dropped its rule lines and the redundant '# mount/3' title. Its explanation stays as a comment on mount/3. The single-line 'private helpers' rule was deleted."
  - "ActorLive passes the whole @streams map to actor_activity/1 so the moved markup keeps @streams.transactions verbatim. actor_header/1 takes threadline_scope as an attr defaulting to nil, which keeps the semantics of the old assigns[:threadline_scope] read."
  - "StartLive task_cards/1 receives the feature flags under short attr names (coverage_enabled, evidence_enabled, policy_enabled, exports_enabled). No test pins the old @threadline_*_enabled text inside the cards, and a nil flag still renders nothing through :if."

patterns-established:
  - "An empty size-gate function register (@function_exceptions %{}): any new lib clause over 120 lines now fails the gate outright"

requirements-completed: []
requirements-advanced: [STRUCT-03, STRUCT-04, STRUCT-07]  # STRUCT-03 function-length side done; banners/register finish in 204-12+

coverage:
  - id: D1
    description: "Actor page render carved (tracer) and its mount register site drained"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "ZOC suite: operator_surface/live, transaction_live, rendered_output_contract, copy_contract, coverage_doc, ui_form_policy, style_byte_lock, source_size, credo_config, component_contract, timeline_browse_doc, style_contract, release_artifact (413 tests, 0 failures) after 7dbad154 and e0c57630"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after 7dbad154 and after e0c57630: 326 passed / 8 failed / 16 skipped, exactly the 8 known screenshot cases, baselines clean"
        status: pass
      - kind: other
        ref: "render capture: 70 renders byte-identical to base after masking (ActorLive 15, StartLive 29, CoverageLive 26)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Start and coverage renders carved; their 9 banner lines removed"
    requirement: STRUCT-04
    verification:
      - kind: unit
        ref: "ZOC suite (413 tests, 0 failures) after bb2ba87d and 461d66a4; banner grep prints 0 for both files"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after bb2ba87d and 461d66a4: 326/8/16, the 8 known screenshot cases, baselines clean"
        status: pass
      - kind: other
        ref: "render capture byte-identical to base after each commit"
        status: pass
    human_judgment: false
  - id: D3
    description: "No lib def/defp clause exceeds 120 lines; size gate @function_exceptions is %{}"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#function length; full mix test 1769 tests, 0 failures"
        status: pass
    human_judgment: false

duration: 37min
completed: 2026-09-24
---

# Phase 204 Plan 11: Actor, Start, and Coverage Render Carve Summary

**The actor, start, and coverage `render/1` functions are now 43, 47, and 59 lines. Their markup moved verbatim into ten private, attr-typed function components. The start and coverage banners are gone, the actor mount register site is drained (register 18 -> 17), and the size gate carries no function exception. The HTML is byte-identical and the browser lane still fails on exactly the known 8.**

## Performance

- **Duration:** 37 min
- **Started:** 2026-09-24T01:53:57Z
- **Completed:** 2026-09-24T02:30:31Z
- **Tasks:** 2
- **Files modified:** 5

## Render lengths (AST-measured, per clause)

| Page | render/1 before | render/1 after | Components (lines) | File lines |
|---|---|---|---|---|
| actor_live.ex | 149 | 43 | not_found_state (29), actor_header (41), actor_activity (73) | 455 -> 509 |
| start_live.ex | 190 | 47 | home_header, task_cards (63), record_lookup (40), correlation_lookup (33), saved_views | 473 -> 530 |
| coverage_live.ex | 135 | 59 | coverage_header, coverage_table (67) | 524 -> 548 |

evidence_live render/1 (114) and policy_redaction_live render/1 (111) were not edited and remain under 120. A tree-wide AST scan reports no clause over 120 lines.

## Accomplishments

- Actor page: three components. `activity_presence/4` is a two-clause function (an empty page runs the latest-activity lookup, any other page returns `{true, nil}`). It replaced the `case` nested in an `if` in mount/3. The `Structural debt:` line and its Nesting disable are gone.
- Start page: five components. The `<section class="tl-home__earned-flow">` wrapper stays in render/1 around the two lookup panels. All 6 banner lines are gone, and the page overview paragraph stays as a plain comment.
- Coverage page: header and table components. The stale alert, verdict, and empty state stay in render/1. All 3 banner lines are gone.
- Size gate: `@function_exceptions %{}`. `@banner_exceptions` holds only export_controller (9) and actor_ref (3), both 204-12 files. `@file_exceptions` holds only stress_fixtures.

## Zero-output-change evidence (after every code commit)

- **Compile:** `mix compile --force --warnings-as-errors` was clean each time.
- **ZOC unit suite:** the plan's list plus component_contract, timeline_browse_doc, style_contract, and release_artifact gave 413 tests, 0 failures, after each of the 4 commits. `mix credo --strict <file>` and `mix format --check-formatted` were clean.
- **Render capture:** a telemetry handler on `[:phoenix, :live_view, :render, :start]` re-rendered each target view from its socket assigns. It captured 70 renders (Actor 15, Start 29, Coverage 26) from actor/start/coverage LiveView tests, copy_contract, and rendered_output_contract. The 204-10 masks, plus masks for `_NNN`/`NNNN` unique-integer suffixes, made two base runs identical. After each commit, all 70 renders were byte-identical to base, whitespace included. The captures cover the actor not-found, never-acted, empty-window, and populated-list states; start health, lookup-error, and saved-view states; and coverage invalid-schema, stale, disabled, and all three table row kinds. The coverage "No audited tables found" branch was not captured, and its markup did not move.
- **Browser lane:** after each of the 4 commits, `mix verify.example_browser` gave 326 passed / 8 failed / 16 skipped. The failing set was exactly `operator-screenshot-regression.spec.ts` :108, :115, :136, :145 on desktop and mobile. Baselines stayed clean, and scorecard fixtures were restored after each run. No re-runs were needed.
- **Plan-level:** full `mix test` gave 1769 tests, 0 failures (1 excluded). `MIX_ENV=dev mix verify.dialyzer` reported 0 errors. Repo-wide `mix credo --strict` found no issues, and `mix verify.compile_no_optional` is clean.

## Task Commits

1. **Task 1 (tracer): actor**
   - `7dbad154`: carve render and delete the actor_live function exception
   - `e0c57630`: drain the mount register site; Nesting 15 -> 14, ceiling 18 -> 17
   - Tracer gate: the tracer verify (tests plus browser) passed after e0c57630, before expansion.
2. **Task 2: start and coverage**
   - `bb2ba87d`: carve start, remove its 6 banner lines, and delete its function exception and banner entry
   - `461d66a4`: carve coverage, remove its 3 banner lines, and delete the last function exception and the coverage banner entry

## Acceptance criteria

- `grep -c 'actor_live.ex' test/threadline/source_size_contract_test.exs` prints 0. PASS
- `grep -c 'Structural debt:' lib/threadline/operator_surface/live/actor_live.ex` prints 0. PASS
- `grep -cE 'start_live.ex|coverage_live.ex' test/threadline/source_size_contract_test.exs` prints 0. PASS
- `grep -c '@function_exceptions %{}' test/threadline/source_size_contract_test.exs` prints 1. PASS
- The banner grep prints 0 for start_live.ex and coverage_live.ex. PASS
- The ZOC browser chain passed after every commit. PASS (invariant form, see deviation 1)

## Files Created/Modified

- `lib/threadline/operator_surface/live/actor_live.ex`: three components, plus activity_presence/4
- `lib/threadline/operator_surface/live/start_live.ex`: five components; banners removed
- `lib/threadline/operator_surface/live/coverage_live.ex`: two components; banners removed
- `test/threadline/source_size_contract_test.exs`: three function exceptions and two banner entries deleted
- `test/threadline/credo_config_contract_test.exs`: register lowered to Nesting 14, ceiling 17

## Decisions Made

See key-decisions in the frontmatter. The main ones:
- Everything was carved in-module. No file needed a sibling module, and no source pin moved.
- The helper-section banners in start_live became plain-comment headings, not sibling modules.

## Deviations from Plan

### Verify-path substitutions

**1. Browser gate in invariant form**
- The plan's `grep '82 passed'` chain is stale, per the dispatch rules. After each commit I checked the invariant instead (326/8/16, exactly the 8 known screenshot failures, clean baselines) with `/tmp/p20411_browser_check.sh`.

**2. ZOC unit suite widened**
- I added component_contract, timeline_browse_doc, style_contract, and release_artifact to the plan's ZOC list. Each of them reads one of the three LiveView sources. No test or assertion was edited apart from the size gate and credo register pins.

---

**Total deviations:** 0 auto-fixed, plus 2 verify-path substitutions.
**Impact on plan:** None. No pins were repointed, no exceptions were added, and no baselines were touched.

## Issues Encountered

- The first two base captures differed on test-generated actor ids (`actor_mixed_16066` vs `_16450`). An added mask for unique-integer suffixes made the base captures deterministic.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 204-12. The only size-gate entries left are banner entries for export_controller (9) and actor_ref (3), plus the stress_fixtures file exception.
- The credo register is at 17 (Nesting 14, CyclomaticComplexity 3).

---
*Phase: 204-structure*
*Completed: 2026-09-24*

## Self-Check: PASSED

- All four commits (7dbad154, e0c57630, bb2ba87d, 461d66a4) are in `git log`, and the three modified LiveView files exist.
- All acceptance criteria above were re-run after the last commit and pass.
