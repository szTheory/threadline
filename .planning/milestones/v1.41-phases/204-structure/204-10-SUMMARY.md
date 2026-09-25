---
phase: 204-structure
plan: 10
subsystem: operator-surface
tags: [refactor, liveview, function-components, size-gate, credo, structural-register]
status: complete

requires:
  - phase: 204-structure
    provides: "Threadline.Test.SourceFamily reader (204-05/06), size gate at measured ceilings (204-02), credo register at 19 (204-09), carved render pattern (204-08/09)"
provides:
  - "RetentionHistoryLive: private run_history/1 and prune_modal/1 components; render/1 186 -> 79 lines"
  - "ExportStatusLive: private workflow_summary/1, timeline_context/1, evidence_context/1; render/1 254 -> 66 lines"
  - "Threadline.OperatorSurface.Live.ExportStatusLive.Components (lib/threadline/operator_surface/live/export_status_live/components.ex): public job_history/1 plus the job display helpers"
  - "TransactionLive: private transaction_header/1 and change_list/1 components; render/1 183 -> 77 lines"
  - "export_workflow_summary/1 register site drained; credo register 19 -> 18 (Nesting 15, CyclomaticComplexity 3)"
  - "Size gate function exceptions down to actor, coverage, and start render/1 (for 204-11)"
affects: [204-11, 204-15, source-size-contract, credo-config-contract, release-artifact-contract, copy-contract, STRUCT-03, STRUCT-07]

actuals:
  tokens: 10200     # chars/4 over the realized diff 9adc0fa8..f97dc924 (40883 chars)
  tasks: 3
  commits: 5        # MEASURED: git rev-list --count 9adc0fa8..HEAD before the SUMMARY commit
plan_head_before: 9adc0fa8

tech-stack:
  added: []
  patterns:
    - "Moved markup keeps its original absolute indentation inside the component's ~H, so the rendered bytes are unchanged, whitespace included (same technique as 204-09)"
    - "A render-time capture harness: a telemetry handler on [:phoenix, :live_view, :render, :start] re-renders the target LiveView from socket.assigns, rendering live components as placeholders. It captured 88 renders across the three pages' tests and compared them byte-for-byte after each commit"

key-files:
  created:
    - lib/threadline/operator_surface/live/export_status_live/components.ex
  modified:
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - test/threadline/source_size_contract_test.exs
    - test/threadline/credo_config_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs

key-decisions:
  - "Only the export job list moved to the ExportStatusLive.Components sibling, together with the helpers that only it reads (status_role, time_label, job_modifier, actor_path, timeline_search_path, download_link_attrs). With all of it in-module the LiveView would have been about 855 lines. The three context sections stay as private components in the LiveView, following the D-08 default. The LiveView is now 687 lines and the sibling is 182."
  - "download_link_attrs/1 sits last in the sibling module. copy_contract's export download block reads from `defp download_link_attrs` to the end of the text, and its refutations (aria-disabled, tabindex, data-tl-mutating) then cover only that function."
  - "timeline_context/1 receives threadline_scope, threadline_export_scope, and threadline_actor_ref as attrs defaulting to nil. That keeps the semantics of the old assigns[:key] reads."
  - "The register drain splits export_workflow_summary/1 into context_workflow_summary/1, which returns nil when no handoff is active, and jobs_workflow_summary/1. A new export_job_noun/1 replaces the three inline plural ifs. Every one of the seven branches appears in the capture set and renders identically."
  - "The :if for prune_modal moved from the <UI.Overlay.modal> tag to the <.prune_modal> call. A false :if renders nothing in either position."

requirements-completed: []
requirements-advanced: [STRUCT-03, STRUCT-07]  # 204-11 carves actor, start, coverage; 18 register sites remain for later 204 plans

coverage:
  - id: D1
    description: "Retention history render carved (tracer)"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "ZOC suite: operator_surface/live, transaction_live, rendered_output_contract, copy_contract, coverage_doc, ui_form_policy, style_byte_lock, source_size, credo_config, component_contract (331 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after 1cb1f032: 326 passed / 8 failed / 16 skipped, exactly the 8 known screenshot cases, baselines clean"
        status: pass
      - kind: other
        ref: "render capture: 88 renders byte-identical to base after masking"
        status: pass
    human_judgment: false
  - id: D2
    description: "Export status render carved, job list sibling created, register site drained"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "ZOC suite plus release_artifact_contract, style_contract, card_nesting, router (411 tests, 0 failures after 833a4272; 350 after dd16f256)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after 833a4272 and after dd16f256: 326/8/16, known 8, baselines clean"
        status: pass
      - kind: other
        ref: "render capture byte-identical after each commit; all seven workflow-summary branches present in the capture"
        status: pass
    human_judgment: false
  - id: D3
    description: "Transaction render carved"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "ZOC suite plus timeline_browse_doc_contract, style_contract (394 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after 3827e718: 326/8/16, known 8, baselines clean"
        status: pass
      - kind: other
        ref: "full mix test 1769 tests / 0 failures; MIX_ENV=dev mix verify.dialyzer exit 0; mix credo --strict no issues"
        status: pass
    human_judgment: false

duration: 37 min
completed: 2026-09-24
---

# Phase 204 Plan 10: Retention, Export Status, and Transaction Render Carve Summary

**Three page `render/1` functions are carved into function components with byte-identical output: retention history 186 to 79 lines, export status 254 to 66, and transaction 183 to 77. The export job list moved to a new `ExportStatusLive.Components` sibling, and the export workflow summary register site is drained, bringing the credo register from 19 to 18.**

## Performance

- **Duration:** about 37 min
- **Started:** 2026-09-24T01:14Z
- **Completed:** 2026-09-24T01:51Z
- **Tasks:** 3
- **Files:** 9 (1 created, 8 modified)

## Render lengths

| Page | render/1 before | render/1 after | Longest clause after | File lines before -> after |
|------|-----------------|----------------|----------------------|----------------------------|
| retention_history_live.ex | 186 | 79 | run_history/1, 90 | 501 -> 529 |
| export_status_live.ex | 254 | 66 | handle_event/3, 70 | 796 -> 687 |
| export_status_live/components.ex | (new) | n/a | job_history/1, 103 | 0 -> 182 |
| transaction_live.ex | 183 | 77 | change_list/1, 68 | 439 -> 457 |

## Components

- **RetentionHistoryLive (private):** `run_history/1` holds the summary cards, prune button, count line, and runs table; the stream is passed as `runs`. `prune_modal/1` holds the type-to-confirm modal.
- **ExportStatusLive (private):** `workflow_summary/1`, `timeline_context/1`, and `evidence_context/1`.
- **ExportStatusLive.Components (public, `@moduledoc false`):** `job_history/1`. The private `time_label/1` component and five helpers moved with it.
- **TransactionLive (private):** `transaction_header/1` holds the breadcrumbs and detail metadata. `change_list/1` holds the streamed change rows, with the stream passed as `changes`.

## Zero-output-change evidence

- **Render capture (not committed):** a throwaway test file (`/tmp/p204_10_capture.exs`, copied into `test/` only while it ran, then deleted) attached a telemetry handler to `[:phoenix, :live_view, :render, :start]`. For every render of the three LiveViews, it re-rendered `socket.assigns` through the current `render/1` and walked the Rendered tree, with live components written as placeholders. That captured 88 renders across the retention, export-status, transaction, card-nesting, and router tests, with `--seed 0`. Masked fields were phx ids, CSRF-length tokens, timestamps, UUID and hex fragments, `H:MM AM` clock text, and `tl-empty-heading-N` ids. Two base runs were identical after masking. After each of the four code commits, all 88 renders were byte-identical to base, whitespace included.
- **Browser lane:** after each of the four code commits, `mix verify.example_browser` gave 326 passed / 8 failed / 16 skipped. Each time, the 8 failures were exactly `operator-screenshot-regression.spec.ts` lines :108, :115, :136, and :145 on desktop and mobile chromium. Snapshot baselines stayed clean, and the scorecard fixtures were restored after every run. No re-runs were needed.
- **Plan-level checks:** the full `mix test` run passed 1769 tests with 0 failures (1 excluded). `MIX_ENV=dev mix verify.dialyzer` reported 0 errors. `mix credo --strict` found no issues, and `mix format --check-formatted` is clean.

## Task Commits

1. **Task 1 (tracer): carve retention_history_live:** `1cb1f032`. The tracer verify passed (tests plus browser) before the expansion tasks started.
2. **Task 2: export status:**
   - `833a4272`: carve, create the sibling, delete the size exception, and repoint pins
   - `dd16f256`: drain the register site; register 19 -> 18
3. **Task 3: carve transaction_live:** `3827e718`
4. **Follow-up:** `f97dc924` aliases SourceFamily in copy_contract to fix a credo design suggestion.

## Acceptance criteria

- `grep -c 'retention_history_live.ex' test/threadline/source_size_contract_test.exs` prints 0. PASS
- `grep -c '^    attr(' lib/threadline/operator_surface/live/retention_history_live.ex` prints 7. PASS
- `grep -c 'export_status_live.ex' test/threadline/source_size_contract_test.exs` prints 0. PASS
- export_status_live.ex is 687 lines (at most 800), and `grep -c 'Structural debt:'` in it prints 0. PASS
- `grep -cE 'retention_history_live.ex|export_status_live.ex|transaction_live.ex' test/threadline/source_size_contract_test.exs` prints 0. PASS
- `MIX_ENV=dev mix verify.dialyzer` exits 0. PASS
- The ZOC browser chain passed after every code commit. PASS (invariant form; see deviation 3)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repointed the export download pin in copy_contract to SourceFamily**
- **Found during:** Task 2
- **Issue:** `copy_contract_test` extracts the download-link attrs and job-actions blocks from `export_status_live.ex` alone. That text moved to the sibling.
- **Fix:** The test now reads the page through `Threadline.Test.SourceFamily.read!/1`. No assertion or pinned string changed. The plan allows this under "repoint pins whose text moved".
- **Files modified:** test/threadline/operator_surface/copy_contract_test.exs
- **Commit:** 833a4272 (plus the alias in f97dc924)

**2. [Rule 2 - Coverage] Added the sibling to style_contract's motion scan**
- **Found during:** Task 2
- **Issue:** The keyframes and transition refutation lists page modules by path. Without a change, the moved job-list markup would have left that scan.
- **Fix:** Added `export_status_live/components.ex` to the list. This test file is not in the plan's file list.
- **Commit:** 833a4272

**3. [Verify-path substitution] Browser gate**
- The plan's `grep '82 passed'` chain is stale, per the dispatch rules. The invariant was checked instead (326/8/16, exactly the 8 known screenshot failures, clean baselines), using `/tmp/p20410_browser_check.sh`.

**4. [Rule 1 - Lint] Credo design suggestion from the repoint**
- **Found during:** plan-level `mix credo --strict`
- **Issue:** The fully qualified `Threadline.Test.SourceFamily.read!` call raised a "nested modules could be aliased" suggestion.
- **Fix:** Added an alias. The commit uses the `test` type so that release-please does not pick it up.
- **Commit:** f97dc924

---

**Total deviations:** 3 auto-fixed (1 blocking repoint, 1 coverage, 1 lint), plus 1 verify substitution.
**Impact on plan:** None on scope or output. Three size exceptions were removed, none were added, and the register went down by one.

## Issues Encountered

- The first capture attempt used `rendered_to_string`, which raises on the transaction page's `RowHistoryComponent` live component. A custom Rendered walker that writes live components as placeholders replaced it.
- The raw captures differed between two base runs: wall-clock times, UUID-derived short ids, and unique heading ids. After masking those, the captures were deterministic.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 204-11. The remaining function exceptions are actor_live render/1 (149), coverage_live render/1 (135), and start_live render/1 (190).
- The credo register is at 18 (Nesting 15, CyclomaticComplexity 3).

---
*Phase: 204-structure*
*Completed: 2026-09-24*

## Self-Check: PASSED

- components.ex exists. All five commits (1cb1f032, 833a4272, dd16f256, 3827e718, f97dc924) are in `git log`.
- All acceptance criteria above were re-run and pass.
