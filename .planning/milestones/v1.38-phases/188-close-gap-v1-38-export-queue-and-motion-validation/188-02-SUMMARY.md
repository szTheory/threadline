---
phase: 188-close-gap-v1-38-export-queue-and-motion-validation
plan: 02
plan_id: 188-02
title: Copy Motion Source Contract Closure
subsystem: operator-surface-motion
tags:
  - operator-surface
  - motion
  - css
  - source-contract
  - tl-copy
requires:
  - phase: 187-accessibility-motion-docs-and-adversarial-closeout
    provides: MOTION-01 source and browser proof posture with reduced-motion governance.
  - phase: 188-close-gap-v1-38-export-queue-and-motion-validation
    provides: Plan 01 queued export replay closure for the other v1.38 audit gaps.
provides:
  - .tl-copy now declares explicit transition properties instead of relying on implicit all-property shorthand.
  - StyleContractTest now rejects token-only transition shorthand and pins the copy control property list.
  - Existing .tl-copy hover, copied state, Copied chip, and tl-copy-pulse selectors remain present.
affects:
  - MOTION-01
  - CLOSE-01
  - Phase 188 closeout
tech-stack:
  added: []
  patterns:
    - Prefer source-level CSS governance for bounded motion fixes before adding browser proof.
    - Declare transition-property, transition-duration, and transition-timing-function separately when a compact control must avoid implicit all-property motion.
key-files:
  created:
    - .planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/style_contract_test.exs
key-decisions:
  - "No browser proof was added because the source contract directly validates the .tl-copy property list and rejects token-only shorthand."
  - ".tl-copy keeps tl-copy-pulse as its only copy-specific animation; no keyframes, tokens, dependencies, routes, or screenshot baselines were added."
patterns-established:
  - "StyleContractTest extracts the .tl-copy block and asserts exact governed transition properties, duration, and easing."
  - "Source-wide transition shorthand scanning allows existing property-named shorthands while rejecting all-property and token-only shorthand forms."
requirements-completed:
  - MOTION-01
  - CLOSE-01
duration: 3min
completed: 2026-06-30T20:33:42Z
status: complete
---

# Phase 188 Plan 02: Copy Motion Source Contract Closure Summary

`.tl-copy` motion now uses explicit color/border/background/shadow transitions, with source tests blocking implicit all-property shorthand from returning.

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-30T20:30:39Z
- **Completed:** 2026-06-30T20:33:42Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added RED source-contract coverage for `.tl-copy` requiring `color`, `border-color`, `background-color`, and `box-shadow` transition properties.
- Added a source-wide shorthand guard that rejects transition declarations starting with `all` or a token instead of a governed property name.
- Replaced `.tl-copy`'s token-only shorthand with explicit `transition-property`, `transition-duration`, and `transition-timing-function` declarations.
- Preserved existing `.tl-copy:hover`, `.tl-copy.is-copied`, `.tl-copy.is-copied::after`, and `tl-copy-pulse` behavior.

## Task Commits

| Task | Name | Result | Commit |
|------|------|--------|--------|
| 1 | Add source contract for implicit-all copy transitions | RED test committed; `mix test test/threadline/operator_surface/style_contract_test.exs` failed as expected with one `.tl-copy` assertion failure | 299c5ff1 |
| 2 | Replace .tl-copy shorthand with explicit governed properties | CSS fixed and style contract green | 8bc2f5e6 |

## Files Created/Modified

- `lib/threadline/operator_surface/style.ex` - Replaces `.tl-copy` transition shorthand with explicit property, duration, and easing declarations.
- `test/threadline/operator_surface/style_contract_test.exs` - Adds `.tl-copy` source-contract coverage and a source-wide transition shorthand guard.
- `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-02-SUMMARY.md` - Plan completion record.

## Verification

| Command | Result |
|---------|--------|
| `mix test test/threadline/operator_surface/style_contract_test.exs` before Task 2 | RED as expected - 51 tests, 1 failure on the new `.tl-copy` explicit-property assertion |
| `mix test test/threadline/operator_surface/style_contract_test.exs` after Task 2 | PASS - 51 tests, 0 failures |
| `rg -n "transition-property: color, border-color, background-color, box-shadow;|transition-duration: var\\(--tl-motion-fast\\);|transition-timing-function: var\\(--tl-ease-standard\\);|\\.tl-copy:hover|\\.tl-copy\\.is-copied|\\.tl-copy\\.is-copied::after|@keyframes tl-copy-pulse" lib/threadline/operator_surface/style.ex` | PASS - required declarations and preserved selectors found |
| `git diff --check -- lib/threadline/operator_surface/style.ex test/threadline/operator_surface/style_contract_test.exs` | PASS |

## Decisions Made

- Kept verification source-focused rather than adding Playwright proof; the new test extracts the `.tl-copy` block and validates the exact CSS source contract.
- Preserved the existing motion inventory and keyframe allowlist; no new copy animation was introduced.
- Left export replay, milestone audit, GOV-02 metadata, routes, selectors, feature gates, and closeout artifacts untouched because they belong to 188-01 or 188-03.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; no browser matrix, screenshot, route, selector, token, keyframe, dependency, public API, or visual redesign changes.

## Issues Encountered

None.

## Auth Gates

None.

## Known Stubs

None. Stub scan over the modified files found no runtime TODO/FIXME/placeholder text or hardcoded empty UI data placeholders. Existing empty-string/list assertions in tests are contract assertions, not product stubs.

## Threat Flags

None. This plan touched the planned source CSS to browser-rendering trust boundary and mitigated it with source contracts; no unplanned endpoint, auth path, schema, dependency, or file-access surface was introduced.

## Next Phase Readiness

Plan 188-03 can use this summary and the targeted verification evidence to close the MOTION-01 audit finding and complete v1.38 closeout metadata/audit work.

## Self-Check: PASSED

- Found summary file: `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-02-SUMMARY.md`
- Found modified files: `lib/threadline/operator_surface/style.ex`, `test/threadline/operator_surface/style_contract_test.exs`
- Found task commits: `299c5ff1`, `8bc2f5e6`
- Final targeted verification passed: 51 tests, 0 failures

---
*Phase: 188-close-gap-v1-38-export-queue-and-motion-validation*
*Completed: 2026-06-30*
