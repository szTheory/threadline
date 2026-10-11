---
phase: 239-investigation-entry-and-transaction-composition
plan: "06"
subsystem: operator-surface
tags: [elixir, phoenix, liveview, playwright, accessibility, theme, overlay]
requires:
  - phase: 239-01
    provides: mounted investigation journey
provides:
  - Session-backed theme selection and computed OS appearance proof
  - Layer-scoped Escape, idempotent dismissal and focus recovery through actual patches
  - Empty and disabled-child focus, removed-opener fallback and short-viewport touch proof
affects: [239-05, 239-07, operator-surface, accessibility]
actuals:
  tokens: 9094
  tasks: 2
  commits: 3
  plan_head_before: 9433cf5fa407afea382ad2adb514836216a02fa0
  plan_head_after: e130ff605a6878516a7f56708659cd511d3252d7
tech-stack:
  added: []
  patterns:
    - Native Phoenix focus_wrap with an inner panel fallback
    - Scoped JS.exec targets exclude hidden layers and focused child menus
    - Removal runs focus restoration only while its layer is still visible
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/ui/overlay.ex
    - lib/threadline/operator_surface/style/08_overlays_motion.css
    - lib/threadline/operator_surface/live/stress_live.ex
    - lib/threadline/operator_surface/live/stress_live/sections.ex
    - lib/threadline/operator_surface/live/timeline_live/filters.ex
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/ui_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
key-decisions:
  - Keep the existing server session as the sole theme preference source.
  - Restore the opener via Phoenix focus stack, with the existing focusable main region as surviving fallback.
  - Keep toast feedback until explicit dismissal; Escape is scoped to the focused visible toast.
requirements-completed: [UIA-02, UIA-03]
coverage:
  - id: D1
    description: Chosen theme and effective colors remain independently correct across reload and navigation.
    requirement: UIA-02
    verification:
      - kind: integration
        ref: test/threadline/operator_surface/live/start_live_test.exs
        status: pass
      - kind: e2e
        ref: operator-accessibility.spec.ts — System appearance journey in desktop and System/light lanes
        status: pass
    human_judgment: false
  - id: D2
    description: Overlay layers preserve focus and one-layer Escape through actual LiveView patches, empty controls and removed opener.
    requirement: UIA-03
    verification:
      - kind: e2e
        ref: operator-accessibility.spec.ts — layered toast, three repeated story patches and three server-patch edge cases
        status: pass
      - kind: e2e
        ref: operator-component-contracts.spec.ts — 320x420 touch, long content, local scrolling and reduced motion
        status: pass
    human_judgment: false
status: complete
duration: 161min
completed: 2026-10-09
---

# Phase 239 Plan 06 Summary

**Theme preference remains truthful, and shared overlays now dismiss and restore focus correctly through real LiveView patches.**

## Performance

- Started: 2026-10-09T14:18:37.507Z (recorded executor launch).
- Completed: 2026-10-09T16:59:46.296502+00:00.
- Wall duration: 161 minutes, including the stalled worker and authorized inline recovery. Diff-derived token estimate is not billed model usage.
- Two tasks complete; three source/test commits plus partial and final summary commits.

## Accomplishments

- System remains selected while rendered foreground, background and border follow the emulated OS. Explicit Light and Dark persist across navigation and reload. Invalid submissions do not create a saved preference cookie.
- Modal/drawer Escape now targets the container's actual dismissal command. Hidden layers do not consume Escape; a focused child menu closes before its drawer. Toast input preserves the dialog beneath it.
- Native focus wrapping preserves Tab order. An inner focusable panel handles no enabled child controls; the existing main region is the fallback when a patch removes the opener.
- Conditional removal prevents duplicate focus-stack pops when server cancellation also removes a dialog. The focus wrapper itself stays nonfocusable so show-end cannot steal focus from a selected field.
- Dialog/toast content scrolls locally at short heights. Long unbroken labels wrap. Real Chromium touch activation closes long-content overlays at 320×420 without document overflow. Existing normal/reduced-motion checks remain green.
- The dev/test-only stress lab now uses genuine link patches and mounted events. Tests retain the LiveView root ID and a same-document marker, exercise three repeated story patches, then independently remove controls, disable controls, and remove the opener. Page-error assertions remain empty.

## Files Created/Modified

- `lib/threadline/operator_surface/ui/overlay.ex` — shared Escape, focus wrapping and idempotent removal.
- `lib/threadline/operator_surface/style/08_overlays_motion.css` — local scrolling and long-label wrapping.
- Existing LiveView fixtures and browser/ExUnit files listed in frontmatter supply mounted regression coverage.

## Task Commits

1. `76d955f8` — session theme and OS appearance regressions.
2. `b222f86e` — initial toast/drawer pointer and focus repair.
3. `e130ff60` — complete layered Escape, focus recovery, genuine patch and touch regressions.

Historical partial summary `c29cb7b8` correctly recorded open acceptance. It is superseded by this verified summary; history is preserved.

## Recovery and Deviations

The worker stopped making progress after its halted summary. After the configured stall threshold, the maintainer explicitly approved stopping PID 88679 and completing inline. Root stopped it at 15:19:10Z and preserved all prior commits and local edits.

The diagnosed Escape defect was a JS.exec call against a missing `phx-remove` attribute on an inner panel. Subsequent real-browser regressions exposed global toast click-away, duplicate removal focus restoration, and focus-wrap show-end behavior; each was corrected at the shared owner. The Timeline drawer's duplicate window handler was removed so the shared component owns dismissal.

The existing stress lab needed scoped fixture changes to establish actual patches instead of full-page navigation; it remains dev/test gated with no new public route or API. Existing tests were adjusted for shared lowercase Escape, explicit toast dismissal, and the Phase 239-04 filtered-empty wording. Two old browser cases raced the LiveView connection; both now wait for `phx-connected` before interactive input. Test selectors retain stable IDs when deliberately changing an accessible name, and the long catalog keyboard traversal has an explicit 160-tab bound.

Initial red runs and one intentionally stopped outdated-fixture run are diagnostic history, not acceptance. No tests were weakened to waive a product defect. No dependencies, client preference store, public API, host authorization or tenant-scope changes were added.

## Checks Run

- `mix test test/threadline/operator_surface/live/start_live_test.exs` — worker 23/23 passed.
- `mix test test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/ui_test.exs` — final 92/92 passed, seed 510898.
- `MIX_TEST_PARTITION=tl239_wave2 mix test test/threadline/operator_surface/stress_router_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` — 77/77 passed, seed 784767.
- Combined desktop command: `mix verify.example_browser --project=desktop-chromium operator-accessibility.spec.ts operator-component-contracts.spec.ts operator-timeline-investigation-flow.spec.ts operator-transaction-evidence.spec.ts operator-route-states.spec.ts` — 34 active cases passed; two connection-race cases were then corrected and passed 2/2 with `--grep 'opens stress rendered|captures accessibility-tree'`. Thus all 36 active cases have passing coverage on the final product source across the integration run and affected rerun, not a claim of a single green 36-case invocation. Nine evidence-only cases were skipped by their existing mode gate and remain Plan 07-owned.
- `mix verify.example_browser_light --project=desktop-chromium-light operator-accessibility.spec.ts` — 14/14 passed on the final candidate, including all new overlay and corrected readiness cases.
- Each browser invocation also ran 21/21 Node runner contracts. Desktop integration partition/port: `tl239_wave2c`/4424; affected rerun: `tl239_ready`/4425; System/light: `tl239_light2`/4426. Cached Chromium revision 1223 matches pinned Playwright 1.60.0; the temporary installer shim only bypasses redundant installation, not browser execution.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and `git diff --check` — exit 0.
- Wave gates: schema drift clear; codebase drift skipped because no STRUCTURE.md; UI safety gate sees UI files and UI-SPEC, block=false. These are structural gates, not rendered acceptance.

## Remaining Phase Work

Plan 05 owns shared role floors/reflow and strict actual-zoom acceptance. Plan 07 owns the forward custody receipt, source-bound before/after review, final evidence-mode matrix, full suite and explicit disposition of all flagged edge rows. UIA-02's flagged probe row remains unclassified until that reconciliation; these tests do not silently change the probe. No whole-phase completion, Linux CI, remote CI, release or publication is claimed here.

## Self-Check: PASSED

- Both planned tasks have passing runtime evidence and scoped commits.
- Layered Escape, genuine patches, empty/disabled controls, opener fallback, narrow touch and theme behavior were observed in Chromium.
- Original local-edit preservation hashes remain unchanged; accepted Phase 238 custody and captures remain immutable.
