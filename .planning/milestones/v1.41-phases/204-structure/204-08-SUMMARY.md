---
phase: 204-structure
plan: 08
subsystem: operator-surface
tags: [refactor, liveview, timeline, function-components, size-gate, banners, credo, structural-register]

requires:
  - phase: 204-structure
    provides: "Threadline.Test.SourceFamily reader (204-05/06), source_size_contract_test at measured ceilings (204-02), credo register at 23 (204-07)"
provides:
  - "Threadline.OperatorSurface.Live.TimelineLive.Helpers (lib/threadline/operator_surface/live/timeline_live/helpers.ex): presentation helpers for rows, the window summary, filter messages, and empty states"
  - "Threadline.OperatorSurface.Live.TimelineLive.Filters (lib/threadline/operator_surface/live/timeline_live/filters.ex): public timeline_command/1 and timeline_filter_drawer/1 with attr declarations, carved into six private sub-components"
  - "timeline_live.ex at 608 lines (from 1399), with no size exception, no banners, and no register sites"
  - "The per-page shell scan (component_contract_test) and the :formless form scan (ui_form_policy_contract_test) read each page's source family, so markup moved into live/<page>/ siblings stays inside both refutation scopes"
  - "Credo register 23 -> 21 (Nesting 15, CyclomaticComplexity 6), @ceiling 21"
affects: [204-09, 204-10, 204-11, 204-15, source-size-contract, credo-config-contract, STRUCT-03, STRUCT-04, STRUCT-07]

actuals:
  tokens: 24100     # chars/4 over the realized diff ab10e331..3c629670 (96365 chars)
  tasks: 3
  commits: 5        # MEASURED: git rev-list --count ab10e331..HEAD before the SUMMARY commit
plan_head_before: ab10e331db874eb6053bf75517ed5fda76338db2

tech-stack:
  added: []
  patterns:
    - "LiveView sibling modules live under live/<page>/ and are read by pins through Threadline.Test.SourceFamily; the line-1 file-scope guard pin stays a single-file read"
    - "Public function components in a sibling declare attrs for exactly the assigns they read; the LiveView passes only those (declared attrs make undeclared ones a compile warning)"
    - "A stream container moves into a function component as a whole (container plus :for), with the LiveStream passed as an attr"
    - "handle_params error paths share one defp; the filtered load keeps its Task.async/await order verbatim in a defp"

key-files:
  created:
    - lib/threadline/operator_surface/live/timeline_live/helpers.ex
    - lib/threadline/operator_surface/live/timeline_live/filters.ex
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
    - test/threadline/operator_surface/exports_doc_contract_test.exs
    - test/threadline/operator_surface/ui_form_policy_contract_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/credo_config_contract_test.exs

key-decisions:
  - "Task 2's extraction and filter carving landed as one commit. Two separate commits would have needed the two function exceptions re-keyed onto filters.ex in between, which amounts to adding a size exception. The plan forbids that."
  - "The window-summary helpers stay public in Helpers, and Filters aliases Helpers. They are not copied into Filters as private functions. Helpers.default_window_hours/0 is now the single owner of the 24-hour default, and handle_params reads it."
  - "The LiveView passes timeline_command only the five assigns it reads. It used to pass eight more that it never read. That drops render/1 from 165 to 157 lines."
  - "The carved templates use natural indentation. HEEx drops whitespace between tags, so the only byte change is indentation inside text nodes. After whitespace collapsing and attribute sorting, the HTML is identical across all 22 captures (see Zero-output-change evidence)."
  - "scope_aware_opts, preload_visible_context, count_opts, storage_opts, future_window_empty?, safe_validate, build_canonical_query, and the export-error helpers stay in the LiveView. They are query or state code, not presentation."

requirements-completed: []
requirements-advanced: [STRUCT-03, STRUCT-04, STRUCT-07]  # timeline family done; other files and 21 register sites belong to later 204 plans (ready-ids: 0/3 ready)

coverage:
  - id: D1
    description: "TimelineLive.Helpers extracted; pins repointed through SourceFamily; formless-scan and shell-scan hardening"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "mix test timeline_live_test, timeline_browse/exports doc contracts, rendered_output_contract, style_byte_lock, source_size, credo_config, release_artifact, ui_form_policy, component_contract (198 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser: 326 passed / 8 failed / 16 skipped; failures are exactly operator-screenshot-regression.spec.ts :108/:115/:136/:145 on desktop and mobile; baselines clean"
        status: pass
    human_judgment: false
  - id: D2
    description: "TimelineLive.Filters with typed attrs; timeline_command, timeline_filter_drawer, and render/1 all at most 120 lines; no timeline function exception remains"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs (real-tree function and file tests) + copy_contract_test + doc contracts (211 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after each commit: 326/8/16, known 8 only, baselines clean"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 10 timeline_live.ex banner lines removed; both timeline register sites drained; register 23 -> 21"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "test/threadline/credo_config_contract_test.exs + source_size_contract_test.exs; mix credo --strict (whole repo, no issues)"
        status: pass
      - kind: integration
        ref: "DB_PORT=5433 mix test (1769 tests, 0 failures, 1 excluded); MIX_ENV=dev mix verify.dialyzer (Total errors: 0)"
        status: pass
    human_judgment: false

duration: 47min
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 08: Timeline LiveView split Summary

**timeline_live.ex goes from 1,399 lines to 608. Presentation helpers moved to `TimelineLive.Helpers`, and the filter toolbar and drawer moved to `TimelineLive.Filters` as typed function components. render/1 was carved, and the file has no banners and no Credo register sites. The canonical HTML is identical and the browser lane still fails on exactly the known 8.**

## Performance

- **Duration:** 47 min
- **Started:** 2026-09-23T22:33:58Z
- **Completed:** 2026-09-23T23:20:25Z
- **Tasks:** 3
- **Files:** 2 created, 8 modified

## Line counts

| File | Before | After |
|------|--------|-------|
| lib/threadline/operator_surface/live/timeline_live.ex | 1399 | 608 |
| lib/threadline/operator_surface/live/timeline_live/helpers.ex | (new) | 455 |
| lib/threadline/operator_surface/live/timeline_live/filters.ex | (new) | 434 |

| Function | Before | After |
|----------|--------|-------|
| TimelineLive.render/1 | 165 | under 120 (exception deleted) |
| timeline_command/1 | 130 | under 120, now Filters.timeline_command/1 |
| timeline_filter_drawer/1 | 202 | under 120, now Filters.timeline_filter_drawer/1 |
| handle_params/3 | 116 | shorter: split into filter_error/2 and load_filtered_page/2 |

Size-gate entries removed: the timeline_live.ex file exception, its three function exceptions, and its banner exception. `grep -c 'live/timeline_live' test/threadline/source_size_contract_test.exs` prints 0.

## Carved components

- **In the LiveView (private):** `change_list/1`, which holds the streamed row list and its `phx-update="stream"` container. Attrs: changes, cursor, base_path, timeline_path, schemas.
- **Filters (public):** `timeline_command/1` (5 attrs) and `timeline_filter_drawer/1` (10 attrs).
- **Filters (private):** `command_facts/1`, `active_filter_summary/1`, `advanced_filters/1`, `check_links/1`, `export_actions/1`, `saved_views_group/1`.
- The `timeline-filters` form stays whole inside `timeline_command/1`, because the doc-contract pin regex-extracts it. Filters has 31 `attr(` declarations. There is no `embed_templates`, no `.heex`, and no `defdelegate`.

## Register sites drained

| Site | Technique | Commit |
|------|-----------|--------|
| handle_params/3 (Nesting) | `with` over parse and validate; `filter_error/2` and `load_filtered_page/2` extracted. The count and page tasks start and are awaited in the original order. | 0933ab27 |
| Helpers.schema_for_public_table/2 (Nesting; moved out of timeline_live.ex in 3eed5527) | multi-clause `atom_key_schema/2` | 3c629670 |

The register is now Nesting 15 + CyclomaticComplexity 6 = 21, with `@ceiling 21`.

## Zero-output-change evidence (D-00b)

After every commit:
- `mix compile --force --warnings-as-errors` is clean.
- The ZOC test set is green: timeline_live_test, the timeline_browse and exports doc contracts, rendered_output_contract, style_byte_lock, source_size, credo_config, release_artifact, ui_form_policy, and component_contract, plus copy_contract for Task 2.
- `mix credo --strict` on the timeline family reports no issues.
- `mix verify.example_browser` ran after all 5 commits. Each run was **326 passed / 8 failed / 16 skipped**. The failing set was exactly `operator-screenshot-regression.spec.ts:108/:115/:136/:145` on desktop-chromium and mobile-chromium. The snapshot baselines were clean each time, and the scorecard fixtures were restored after each run.

Extra evidence (not committed): a throwaway ExUnit capture rendered 11 URL scenarios through the real router, both the static and the connected render. The scenarios covered rows with actor, correlation, and row-history links, all filters, anonymous actor kind, an unknown table, first run, an invalid filter, a future window, a partial window, a 7-day window, saved views, and the no-actor endpoint. The baseline came from the plan-base source.
- After the Helpers commit, the normalized HTML (UUIDs and CSRF tokens masked) was **byte-identical**.
- After the carving commits, the only byte differences were indentation runs inside text nodes. HEEx already drops whitespace between tags. Visible text and tag structure did not change.
- From the render-carve commit on, `UI.Form.field` emits the correlation-id input's `maxlength` and `placeholder` attributes in swapped order. That component and its caller did not change in that commit. The order comes from the VM's small-map atom-key order, not from the source.
- A canonical compare collapsed whitespace and sorted each tag's attributes. It was **identical for all 22 captures** after every commit.

## Task Commits

1. **Task 1 (tracer): extract TimelineLive.Helpers:** `3eed5527`. The tracer verify was re-run green, then the plan continued.
2. **Task 2: Filters extraction and component carving:** `836a6c38` (extract plus carve both filter components), `789cf8ab` (carve render/1)
3. **Task 3: banners and register drain:** `0933ab27` (banners plus handle_params), `3c629670` (Helpers schema_for_public_table)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 2 commits 1 and 2 folded into one**
- **Found during:** Task 2
- **Issue:** Moving the two components to filters.ex before carving them would leave both over 120 lines in a new file. The size gate would then need two function exceptions keyed to filters.ex, and the HALT clause forbids adding a size exception.
- **Fix:** Carved them in the same commit that extracted them. The render/1 carve stayed a separate commit.
- **Commit:** 836a6c38

**2. [Rule 3 - Blocking] timeline_command call trimmed to the assigns it reads**
- **Found during:** Task 2
- **Issue:** Once a remote component declares attrs, passing undeclared ones is a compile warning, which `--warnings-as-errors` rejects. Eight of the thirteen assigns passed to timeline_command were never read.
- **Fix:** Attrs are declared for the five assigns that are read, and the call passes only those. This does not affect output. The render/1 pin was lowered from 165 to 157 in that commit.
- **Commit:** 836a6c38

**3. [Scope note] Helper placement**
- The plan's "plus their private helpers" for Filters was satisfied by keeping the window-summary, count, and coverage helpers public in Helpers, with Filters aliasing it. They are shared presentation code, and moving them would only add churn. The one exception is `advanced_filter_count`, which now runs inside the `advanced_filters/1` sub-component instead of at the drawer's top level. Output is the same.
- Helpers has no `use Phoenix.Component` because it defines no components. Filters has it.
- `@default_window_hours` moved to Helpers, and `default_window_hours/0` is its single owner. Keeping a second copy in the LiveView would have let the two drift.

**4. [Verify-path substitution] Browser gate**
- The plan's `grep '82 passed'` chain is stale, per the dispatch rules. The invariant was checked instead: exactly 8 failures, all from the known screenshot set, and clean baselines. No re-run was needed.

**5. [Note] component_contract reconnect scan**
- The reconnect-anchor scan already read through `SourceFamily` (it changed in 204-05). Only the shared-shell test switched from `File.read!` in this plan. Both awk acceptance greps print 0.

---

**Total deviations:** 2 auto-fixed (both blocking), plus 3 notes.
**Impact on plan:** None on scope or output. Every size exception was removed, and none was added.

## Issues Encountered

- The zsh `$VAR:l` modifier broke one `git show "$BASE:lib/..."` command when the baseline was captured. It errored out before any file was touched, and the command was re-run with `${BASE}`.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- LiveView sibling pattern for 204-09/10/11: create `live/<page>/*.ex`. The shell scan, formless scan, and doc pins already read the source family. Add each sibling to its `@source_owners` list in release_artifact_contract_test.
- 21 register sites remain. `mix credo --strict` is clean. The full suite passes (1769 tests, 0 failures). `verify.dialyzer` reports 0 errors.

---
*Phase: 204-structure*
*Completed: 2026-09-23*

## Self-Check: PASSED

- helpers.ex and filters.ex exist, and timeline_live.ex is 608 lines.
- All 5 task commits (3eed5527, 836a6c38, 789cf8ab, 0933ab27, 3c629670) are in `git log`.
- Acceptance: 0 banners and 0 `Structural debt:` in timeline_live.ex; 0 `live/timeline_live` entries in the size test; `defp preload_visible_context(...)` is pinned once; helpers.ex and filters.ex are archive owners; 0 `File.read!` in both component_contract per-page scans.
