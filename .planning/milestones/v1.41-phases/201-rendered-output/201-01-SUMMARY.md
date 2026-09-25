---
phase: 201-rendered-output
plan: 01
subsystem: operator-surface
tags: [liveview, lazy-html, playwright, rendered-output, corpus-integrity]
requires:
  - phase: 200-public-surface
    provides: accepted final operator copy, CSS, stress fixtures, and mechanical floor
  - phase: 198-green-bringup
    provides: green fixture and mechanical verification lanes
provides:
  - positive-controlled guard for owned visible copy, emitted CSS comments, and planning provenance
  - seven-node normalized structural receipt and immutable reference-corpus evidence
  - durable behavior-first shell and Home browser specification
affects: [201-02, 201-03, 201-04, rendered-output, operator-surface]
actuals:
  tokens: 6888
  tasks: 3
  commits: 3
plan_head_before: 73328bccb6bd74fe087f1b10a92ebc6adc8acd4c
tech-stack:
  added: []
  patterns: [positive-controlled static-copy scan, structure-only LazyHTML receipt, path-equality-before-byte-equality]
key-files:
  created:
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - .planning/audits/201-rendered-output-evidence.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts
    - examples/threadline_phoenix/e2e/playwright.config.ts
key-decisions:
  - "Canonical receipts mount real routes, fix time-dependent inputs, normalize only nondeterministic CSRF values, and otherwise preserve meaningful structure."
  - "Reference comparison requires exact sorted path identity before any per-path byte digest comparison."
  - "Shell and Home browser coverage uses existing form IDs, accessible labels, roles, and visible hierarchy instead of roadmap taxonomy attributes."
patterns-established:
  - "Rendered-copy guards scan only Threadline-owned static output and keep runtime adopter data outside the input boundary."
  - "Compact structural receipts ignore text and the three planned provenance attributes while detecting behavioral markup changes."
requirements-completed: [RENDER-01, RENDER-03, RENDER-04, RENDER-05, RENDER-06]
coverage:
  - id: D1
    description: "Owned visible copy and emitted CSS comments reject fixed planning vocabulary while host data remains outside the scan boundary."
    requirement: RENDER-01
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/rendered_output_contract_test.exs (6 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Accepted blobs, seven normalized structures, and 427 immutable reference paths have durable pre-edit evidence."
    requirement: RENDER-03
    verification:
      - kind: integration
        ref: "operator_surface_fixture_contract_test.exs and mix verify.mechanical"
        status: pass
      - kind: other
        ref: "exact git diff and object identity commands in 201-rendered-output-evidence.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "The renamed shell and Home specification preserves desktop and mobile behavior through semantic anchors."
    requirement: RENDER-06
    verification:
      - kind: automated_ui
        ref: "mix verify.example_browser --project=desktop-chromium --project=mobile-chromium operator-shell-home.spec.ts (18 tests)"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix mix precommit (114 tests)"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-09-13
status: complete
---

# Phase 201 Plan 01: Rendered Output Baseline Summary

**Positive-controlled rendered-copy scans, seven real-route structural receipts, immutable corpus evidence, and a behavior-first shell/Home browser contract now establish the pre-edit baseline.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-09-13T19:48:03Z
- **Completed:** 2026-09-13T20:00:48Z
- **Tasks:** 3
- **Files modified:** 4 logical files

## Accomplishments

- Added a planning-independent ExUnit guard over tracked render owners, selected real LiveView output, emitted Style CSS comments, positive controls, and the exact seven structural nodes.
- Sealed accepted Style/stress blob attribution plus 427 sorted, duplicate-free corpus paths and mutation-sensitive fixture/mechanical evidence without changing any accepted owner or reference byte.
- Preserved shell/Home browser history under a durable filename and replaced taxonomy-coupled locators with existing forms, labels, buttons, and visible hierarchy; all 18 desktop/mobile tests pass.

## Task Commits

Each task was committed atomically:

1. **Task 1: Trace owned static copy and emitted CSS through a positive-controlled render guard** — `2babd4de` (test)
2. **Task 2: Seal accepted landed blobs and the immutable pre-edit reference receipt** — `e1d6e756` (docs)
3. **Task 3: Preserve shell/Home behavior under a durable browser-spec name** — `62143014` (test)

## Files Created/Modified

- `test/threadline/operator_surface/rendered_output_contract_test.exs` — positive-controlled vocabulary/attribute/CSS scanners and seven compact structure receipts mounted from real routes.
- `.planning/audits/201-rendered-output-evidence.md` — accepted blob attribution, structural hashes, immutable corpus identity, zero-entry exception registry, and residual inventory.
- `examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts` — history-preserved durable browser spec using semantic Home controls.
- `examples/threadline_phoenix/e2e/playwright.config.ts` — exact light-lane discovery update for the durable filename.

## Decisions Made

- Fixed Row History's `as_of` input in the receipt route and normalized only the hidden CSRF value so repeated runs are deterministic without discarding meaningful IDs, classes, roles, destinations, ARIA, form, or LiveView event attributes.
- Kept host/adopter values outside the static-copy corpus by scanning selected Threadline-owned output rather than entire pages.
- Required exact path equality before byte hashes in the evidence schema so additions, removals, duplicates, and renames remain distinct failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed nondeterminism from the Row History structural receipt**

- **Found during:** Task 1 (seven-node receipt verification)
- **Issue:** The default Row History route emitted the current time and a random CSRF token, causing its structure hash to change between otherwise identical runs.
- **Fix:** Mounted the route with a fixed `as_of` value and canonicalized only the hidden `_csrf_token` input value.
- **Files modified:** `test/threadline/operator_surface/rendered_output_contract_test.exs`
- **Verification:** Two consecutive full contract runs each passed 6 tests with 0 failures.
- **Committed in:** `2babd4de`

---

**Total deviations:** 1 auto-fixed bug (Rule 1)
**Impact on plan:** The fix was required for a truthful stable receipt and did not broaden runtime scope.

## Issues Encountered

- The first example-wide `mix precommit` run hit a transient 60-second DB ownership timeout in the unrelated demo seed idempotency test immediately after browser verification. The exact failed test then passed in isolation (13 tests, 12 excluded), and a clean full rerun passed all 114 tests.
- The browser runner reported an expired optional Hex user session while resolving unchanged public dependencies; resolution, compilation, unit tests, and all browser tests completed successfully without private resources.

## Known Stubs

None. Empty-list assertions are deliberate exact-clean/non-vacuity contracts, not UI placeholders or unwired data.

## Threat Flags

None. The plan adds test/evidence surfaces and renames a browser spec; it adds no endpoint, authorization path, filesystem behavior, schema, dependency, or runtime trust boundary. The unchanged stress-route auth and production fail-close contracts passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 201-02 through 201-04 can compare their edits against the exact seven pre-edit receipts and immutable corpus identity.
- The current 21 provenance attributes across seven nodes remain explicitly recorded as work for Plan 04, not an allowlist or clean result.
- No blockers remain.

## Self-Check: PASSED

- All four logical implementation/evidence files and this summary exist.
- Task commits `2babd4de`, `e1d6e756`, and `62143014` exist after the recorded `plan_head_before`; the measured task-commit count is 3.
- Contract, stress-route, fixture, mechanical, desktop/mobile browser, and example precommit verification all passed.
- Stub and threat-surface scans found no unresolved placeholder or new runtime security boundary.

---
*Phase: 201-rendered-output*
*Completed: 2026-09-13*
