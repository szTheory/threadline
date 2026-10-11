---
phase: 239-investigation-entry-and-transaction-composition
plan: "05"
subsystem: ui
tags: [phoenix, liveview, responsive-css, playwright, operator-surface]
requires:
  - phase: 239-01 through 239-04
    provides: Investigation baseline, UI contract, and transaction evidence seams
provides:
  - Responsive 232-character Timeline filter proof and layout repair
  - Home and transaction evidence proof across 320, 375, 768, and 1280 CSS px
  - Strict actual 200% browser zoom proof across Home, Timeline, and Transaction
affects: [239-06, 239-07, operator-preview]
actuals:
  tokens: 10825
  tasks: 2
  commits: 4
plan_head_before: b6e6e0366d3c481985ad9fcf0747db646bf9701e
plan_head_after: d6367d33266c5654e00430745c14fdba0818f7a6
tech-stack:
  added: []
  patterns: [native disclosure for complete values, real browser zoom readback, viewport-bound control checks]
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts
    - lib/threadline/operator_surface/style/01_tokens.css
    - lib/threadline/operator_surface/style/04_controls.css
    - lib/threadline/operator_surface/style/07_find_detail.css
    - lib/threadline/operator_surface/style/08_overlays_motion.css
    - lib/threadline/operator_surface/style/09_responsive.css
    - test/threadline/operator_surface/style_contract_test.exs
key-decisions:
  - "Keep the expanded mobile navigation in normal page flow so theme controls remain reachable at real 200% zoom."
  - "Treat Before evidence as operation-dependent and keep static axis labels visible while reachability checks target interactive controls."
requirements-completed: [UIS-01, UIS-03, UII-01, UII-02, UII-03, UIA-01]
coverage:
  - id: D1
    description: "The complete 232-character correlation filter applies and returns its exact Timeline row without clipping at 320, 375, 768, and 1280 CSS px."
    requirement: UIS-01
    verification:
      - kind: e2e
        ref: "mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts#long applied correlation at 320/375/768/1280"
        status: pass
    human_judgment: false
  - id: D2
    description: "Home hierarchy, exact Timeline identity boundary, transaction row, complete Unicode value disclosure, and short-viewport controls remain usable across the responsive cases."
    requirement: UII-01
    verification:
      - kind: e2e
        ref: "mix verify.example_browser --project=desktop-chromium operator-transaction-evidence.spec.ts#responsive Home and transaction evidence"
        status: pass
      - kind: unit
        ref: "mix test test/threadline/operator_surface/style_contract_test.exs#phase 239 role floors"
        status: pass
    human_judgment: false
  - id: D3
    description: "A single isolated Chromium tab reports actual 200% zoom while Home, Timeline, and Transaction controls remain reachable with no document overflow."
    requirement: UIA-01
    verification:
      - kind: e2e
        ref: "THREADLINE_ZOOM_ACCEPT=1 mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts#actual zoom journey"
        status: pass
    human_judgment: false
duration: 85 min
completed: 2026-10-09
status: complete
---

# Phase 239 Plan 05: Investigation Entry and Transaction Composition Summary

**Responsive operator investigation preserves complete 232-character Timeline filters and transaction evidence through actual 200% browser zoom.**

## Performance

- **Duration:** 85 min
- **Started:** 2026-10-09T17:00:52Z
- **Completed:** 2026-10-09T18:25:25Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Applied a full 232-character correlation filter at 320, 375, 768, and 1280 CSS px; the browser proof asserts the exact visible result row, excludes the distinct correlation control, and checks the query and controls remain within the document.
- Verified Home hierarchy, computed paper/ink roles, button typography and hit-area floors, exact transaction/change identities, complete selectable Unicode value disclosure, and short-viewport control access.
- Repaired the expanded mobile navigation so it flows with the page at 200% zoom, then proved one real Chromium tab stayed at zoomFactor 2 across Home, Timeline, and Transaction with 0 px document overflow and reachable interactive controls.

## Task Commits

1. **Task 1: Apply a 232-character Timeline filter without losing the page or controls** - `589c4c93` (test)
2. **Task 1: Apply a 232-character Timeline filter without losing the page or controls** - `649cff01` (fix)
3. **Task 2: Reflow Home and transaction evidence with shared role floors** - `0bb41cdb` (fix)

4. **Parent integration correction: prove paired updates and enforce control floors** - `d6367d33` (fix)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts` - Responsive Home and transaction evidence proof, including exact identity controls and long Unicode text selection.
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` - Long-filter responsive regression proof.
- `examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts` - Actual zoom journey checks for native disclosures, operation-dependent Before evidence, and interactive control reachability.
- `lib/threadline/operator_surface/style/01_tokens.css`, `04_controls.css`, `07_find_detail.css`, `08_overlays_motion.css`, and `09_responsive.css` - Token, control, detail, and responsive layout repairs.
- `test/threadline/operator_surface/style_contract_test.exs` - Computed-role and responsive CSS contract assertions.

## Decisions Made

- Expanded mobile navigation returns to normal page flow while open; collapsed navigation retains its sticky behavior.
- Before-axis evidence depends on the captured operation and field data. Static Before/After labels are checked for visibility, while actual controls are checked for focus and viewport reachability.
- Existing palette, typography, native disclosure, and browser tooling remain in use; no dependency or public API was added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Keep expanded mobile navigation controls reachable at 200% zoom**
- **Found during:** Task 2 (strict zoom proof)
- **Issue:** The sticky expanded navigation placed the System theme control below the short zoomed viewport.
- **Fix:** Allow the open mobile navigation to flow with the page; preserve stickiness when collapsed.
- **Files modified:** `lib/threadline/operator_surface/style/09_responsive.css`, `test/threadline/operator_surface/style_contract_test.exs`
- **Verification:** Strict zoom proof reported actual zoomFactor 2, 0 px overflow, and reachable controls on all three routes.
- **Committed in:** `0bb41cdb`

**2. [Rule 1 - Test contract] Align existing assertions with served layout and native transaction semantics**
- **Found during:** Tasks 1 and 2
- **Issue:** The style contract expected a non-constraining `1fr` track after the layout repair; the zoom proof treated static axis labels as interactive and assumed every non-INSERT row has a Before axis.
- **Fix:** Assert the `minmax(0, 1fr)` track, keep axis-label visibility checks separate from interactive-control reachability, and require Before absence for INSERT rows only. Use the native transaction ID disclosure label.
- **Files modified:** `test/threadline/operator_surface/style_contract_test.exs`, `examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts`
- **Verification:** Style contract passed 51/51; strict actual-zoom proof passed 1/1.
- **Committed in:** `649cff01`, `0bb41cdb`

**Total deviations:** 2 auto-fixed (2 Rule 1). **Impact:** Required to make the responsive and zoom acceptance criteria reflect the rendered interface and captured operation semantics.

## Parent Integration Review

- The original responsive cases used INSERTs only. The parent added a captured reply UPDATE with exact original/updated body values to every responsive case and to the real-zoom proof. The initial ticket UPDATE fixture was correctly rejected because that host trigger stores no before-values; the reply trigger explicitly stores them. No capture policy or audit data was changed.
- The new browser regression reproduced a real wide-layout omission at 768px: Before and After were 59.59375px apart vertically. Shared responsive CSS now pairs them at 768/1280 and retains stacking at 320/375, short height, and actual 2× zoom. The rule lives in the existing centralized 768px breakpoint block.
- Actual geometry exposed a 32px row-history target and a later Copy override of 24px high / 12px text. Compact buttons and Copy now use the existing 40px hit-area token and Copy uses the 14px label token. Browser assertions check actual nonempty control sets, target dimensions and computed typography.
- Native disclosure checks now wait for LiveView connection before interaction, removing the initial-render/connected-render race from this acceptance path. The final complete responsive suite passed; acceptance does not rely on the earlier isolated 768px rerun.
- Historical strict-zoom corrections distinguished static labels from interactive controls. The final proof is stronger: it requires an actual UPDATE with exact Before and After evidence and verifies stacked geometry at zoomFactor 2.

## Checks Run

- `mix test test/threadline/operator_surface/style_contract_test.exs` — 51/51 passed.
- `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts` — 21/21 runner unit checks and 15/15 browser tests passed.
- `mix verify.example_browser --project=desktop-chromium operator-transaction-evidence.spec.ts` — 21/21 runner unit checks and 6/6 browser tests passed, including all five responsive cases.
- `THREADLINE_ZOOM_ACCEPT=1 mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts` — 21/21 runner unit checks and 1/1 strict browser proof passed; observed zoomFactor 2 on Home, Timeline, and Transaction, with 0 px overflow on each route.
- Parent combined integration: 22/22 browser tests plus 21/21 Node contracts passed in fresh `tl239_wave3_done`, port 4505; log `/tmp/threadline-239-wave3-done.log`.
- After placing the equivalent layout rule in the centralized breakpoint block, affected final browser rerun: 7/7 plus 21/21 Node contracts passed in `tl239_wave3_close`, port 4506; log `/tmp/threadline-239-wave3-close.log`. Chromium 148.0.7778.96 / Playwright 1.60.0; Home, Timeline, Transaction read back zoomFactor 2 with zero overflow, plus explicit paired UPDATE geometry and 40px row-history target.
- Final style contract: 51/51 passed, seed 659153. Compile with warnings-as-errors, format and diff checks passed.
- Schema/UI wave gates did not block; codebase drift skipped absent STRUCTURE.md. These structural gates are not visual approval.
- No new ExUnit file was created. Original protected-edit hashes remain unchanged. Final full suite and source-bound capture remain Plan 07-owned.
- `git diff --check` — passed.

## Issues Encountered

- The strict zoom proof exposed stale assumptions about a static label and operation-dependent Before evidence. The assertions now check visible labels separately and test reachability only for interactive controls.
- A short-lived export cleanup task emitted an Ecto registry bootstrap diagnostic during seeded browser startup; the final browser runs completed and their seeded browser assertions passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 05 is complete; Plan 06 was already integrated in Wave 2. Next is Plan 07 (Wave 4), then independent phase verification. Parent-owned state, roadmap, and requirements tracking remain untouched.
- No new dependency, route, public API, or persistent schema was introduced.

---
*Phase: 239-investigation-entry-and-transaction-composition*
*Completed: 2026-10-09*

## Self-Check: PASSED

- The nine source and test files listed above exist.
- Task commits `589c4c93`, `649cff01`, `0bb41cdb`, and `d6367d33` are ancestors of the current plan head.
- Acceptance evidence checks exact Timeline and transaction identities, boundary-specific negative controls, native complete-text disclosure, responsive widths, and a read-back 2× browser zoom.
