---
phase: 199-decouple
plan: "02"
subsystem: testing
tags: [elixir, phoenix-liveview, exunit, fixtures, dependency-injection]

requires:
  - phase: 199-decouple
    provides: "Plan 199-01 explicit MechanicalChecker scorecard and mechanical-floor inputs"
provides:
  - "Example-owned decoded stress-ledger session provider with task-oriented failures"
  - "StressLive consumption of validated injected evidence with no repository discovery"
  - "One ExUnit fixture-path authority for ledger, scorecards, golden, refute, and critic-output roots"
affects: [DECOUPLE-01, 199-08-fixture-move, operator-surface-tests]

actuals:
  tokens: 4971
  tasks: 2
  commits: 6
plan_head_before: 8883f6de86d13fd3585526d66992feb6634a05b5

tech-stack:
  added: []
  patterns:
    - "Repository files are decoded at the example edge and passed through a LiveView session MFA"
    - "Runtime evidence boundaries validate non-empty decoded values and fail closed"
    - "ExUnit corpus paths descend from one __DIR__-anchored test-support root"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/threadline_stress_session.ex
    - test/support/operator_surface_fixtures.ex
  modified:
    - lib/threadline/operator_surface/stress_router.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - test/threadline/operator_surface/mechanical_checker_test.exs
    - test/threadline/operator_surface/refute_partition_test.exs
    - test/threadline/operator_surface/stress_ledger_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs

key-decisions:
  - "Use exact session key threadline_stress_ledger_entries and validate a non-empty list of maps at the StressLive boundary."
  - "Keep the test adapter rooted at the current tracked .planning corpus so Plan 199-08 can flip one root when moving bytes."
  - "Pass an explicit empty mechanical-floor map for refute partition checks because that suite intentionally exercises absolute ceilings only."

patterns-established:
  - "Internal router options are popped before public auth/coverage options are forwarded."
  - "Example-only repository readers report resolved path, repository-only status, and one recovery command."

requirements-completed: [DECOUPLE-01]

coverage:
  - id: D1
    description: "Decoded stress-ledger evidence flows from an example-owned source anchor through LiveView session injection without runtime file IO."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/stress_router_test.exs#session injection and malformed-session controls"
        status: pass
      - kind: unit
        ref: "examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs#stress session adapter source contract"
        status: pass
    human_judgment: false
  - id: D2
    description: "Four ExUnit evidence suites share one source-anchored corpus path authority ready for the atomic fixture move."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "mix test mechanical_checker_test.exs refute_partition_test.exs stress_ledger_test.exs stress_router_test.exs (75 tests)"
        status: pass
    human_judgment: false

duration: 2h52m
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 02: Elixir Edge-Owned Fixture Discovery Summary

**Decoded stress-ledger evidence now enters StressLive through a validated session boundary, while four ExUnit suites share one source-anchored corpus adapter.**

## Performance

- **Duration:** 2h52m
- **Started:** 2026-09-11T11:25:15Z
- **Completed:** 2026-09-11T14:17:28Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Removed repository path discovery, file reads, and rescue-to-empty behavior from `StressLive`; decoded ledger entries are injected under the exact `threadline_stress_ledger_entries` key.
- Added an example-private, `__DIR__`-anchored provider that validates the required ledger shape and reports actionable repository-only recovery diagnostics.
- Added `Threadline.Test.OperatorSurfaceFixtures` with six named path functions and migrated the mechanical, refute, ledger, and stress-router suites to it.
- Repaired the Plan-199-01 handoff in `RefutePartitionTest` by supplying explicit empty mechanical floors for its intentionally ceiling-only check.

## Task Commits

1. **Task 1 RED — injected ledger behavior:** `76974861` (test)
2. **Task 1 GREEN — edge-to-LiveView session plumbing:** `0819e105` (feat)
3. **Task 1 RED — malformed session behavior:** `be22873e` (test)
4. **Task 1 GREEN — fail-closed validation and diagnostics:** `0fe0d62e` (feat)
5. **Task 2 RED — shared fixture authority contract:** `b00ecde9` (test)
6. **Task 2 GREEN — adapter and four-suite migration:** `ac1b789e` (feat)

## TDD Gate Compliance

- **Task 1 RED cycle 1:** The named rendered-score assertion failed because `StressLive` still loaded `.planning` itself; the persisted evidence record returned `RED_EVIDENCE_OK`.
- **Task 1 GREEN cycle 1:** The focused injected-score test passed before `0819e105`.
- **Task 1 RED cycle 2:** The named malformed-session assertion failed because a map was accepted instead of a non-empty list; the persisted evidence record returned `RED_EVIDENCE_OK`.
- **Task 1 GREEN cycle 2:** The malformed control and full 19-test router suite passed before `0fe0d62e`; the automatic tracer feedback rerun passed root 19/19 and example 10/10.
- **Task 2 RED:** The named adapter contract failed on an assertion because the test-support module did not exist; the persisted evidence record returned `RED_EVIDENCE_OK`.
- **Task 2 GREEN:** All four migrated suites passed 75/75 before `ac1b789e`.
- **REFACTOR:** No separate refactor commit was needed; the GREEN implementations remained narrow after formatting and expanded verification.

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix_web/threadline_stress_session.ex` — source-anchored ledger decoder and LiveView session provider.
- `test/support/operator_surface_fixtures.ex` — six named test-only corpus paths with actionable missing-path diagnostics.
- `lib/threadline/operator_surface/stress_router.ex` — internal `:ledger_session` extraction and LiveView session forwarding.
- `lib/threadline/operator_surface/live/stress_live.ex` — injected-ledger validation and consumption with no repository IO.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — supplies the example-private session MFA on both stress mounts.
- `test/threadline/operator_surface/{mechanical_checker,refute_partition,stress_ledger,stress_router}_test.exs` — shared path authority adoption and injection contracts.
- `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` — example adapter source-anchor and fail-closed contract.

## Decisions Made

- The stress session must contain a non-empty list of maps; missing, empty, or malformed values fail at the runtime boundary instead of becoming an empty UI.
- The example owns JSON decoding and repository location, while the library router owns only value plumbing.
- Refute partition checks pass `%{}` as their explicit floors because refute cells deliberately have no ratchet-floor entries and the suite tests absolute mechanical ceilings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported combined verification command**

- **Found during:** Task 1 verification.
- **Issue:** The installed Mix task rejects bare `-x`, and the example test's source-relative paths require its own Mix-project working directory.
- **Fix:** Used `--max-failures 1` and ran the root and example suites from their owning project directories.
- **Files modified:** None.
- **Verification:** Root router suite passed 19/19 and example Storybook suite passed 10/10, including the tracer feedback rerun.

**2. [Rule 1 - Bug] Escaped the missing-provider default as quoted AST**

- **Found during:** Task 1 expanded GREEN verification.
- **Issue:** Unquoting a runtime `%{}` default while compiling a throwaway router raised `tried to unquote invalid AST`.
- **Fix:** Made the default `quote(do: %{})`, preserving compile-only route contracts while runtime requests still fail closed without injected ledger data.
- **Files modified:** `lib/threadline/operator_surface/stress_router.ex`.
- **Verification:** Full stress-router suite passed 19/19, including throwaway-router compilation.
- **Committed in:** `0fe0d62e`.

**3. [Rule 3 - Blocking] Reconciled the refute partition suite with Plan 199-01's explicit checker input**

- **Found during:** Task 2 migration.
- **Issue:** `RefutePartitionTest` still called `MechanicalChecker.run/1` without the now-required `:mechanical_floors`, blocking the dependent plan's focused suite.
- **Fix:** Passed `%{}` explicitly because the suite deliberately tests absolute ceilings and refute cells have no floor entries.
- **Files modified:** `test/threadline/operator_surface/refute_partition_test.exs`.
- **Verification:** All four migrated suites passed 75/75.
- **Committed in:** `ac1b789e`.

**4. [Rule 3 - Blocking] Reconciled roadmap progress after the canonical handler declined the legacy layout**

- **Found during:** Plan metadata synchronization.
- **Issue:** `roadmap.update-plan-progress 199` found 14 plans and eight summaries but returned `missing_phase_details`, leaving Plan 02 and already-completed Plan 12 unchecked and the phase row at `7/14`.
- **Fix:** Marked the two summary-backed plans complete and set the Phase 199 row to `8/14 In Progress`, matching the handler's live counts.
- **Files modified:** `.planning/ROADMAP.md`.
- **Verification:** Eight Phase 199 summaries exist, eight plan checklist entries are checked, and six plans remain unchecked.

---

**Total deviations:** 4 auto-fixed (1 bug, 3 blocking execution issues).
**Impact on plan:** Each change was required to execute or verify the planned boundary contracts; no runtime API or fixture bytes changed.

## Issues Encountered

- The checkout has no active asdf Elixir/Erlang selection. Verification used installed Elixir `1.19.5-otp-27` and Erlang `27.3.4.15` through command-scoped variables without changing the user's untracked `.tool-versions`.
- The example application required one cold dependency/build pass; subsequent adapter tests completed in under a second.

## Known Stubs

None introduced. Existing empty-state and deliberately blank stress-fixture values were unchanged by this plan and do not block injected evidence flow.

## Automated Evidence

- Root focused suites: **PASS**, 75 tests, 0 failures.
- Example Storybook/session-adapter suite: **PASS**, 10 tests, 0 failures.
- `mix compile --warnings-as-errors`: **PASS** for Threadline; one dependency-local Elixir typing warning was emitted by `sweet_xml` during its cold compile and did not fail the application build.
- Targeted formatter check across all ten plan files: **PASS**.
- Source scan: `StressLive` contains no file IO, repository path, application-env locator, or rescued empty ledger.
- Stub/skip scan: no new stub, TODO, FIXME, skipped test, or unrun verification remains.

## User Setup Required

None.

## Next Phase Readiness

- Plan 199-08 can move the corpus and change the single test-support root without rewriting each ExUnit suite.
- Example stress rendering is independent of caller CWD and runtime repository discovery.
- No blocker remains for DECOUPLE-01's fixture migration wave.

## Self-Check: PASSED

- Both created adapter files and the summary exist on disk.
- All six measured RED/GREEN plan commits are present after `plan_head_before`.
- Both coverage deliverables classify as fully automated with passing evidence and no schema errors.
- Three persisted RED records validate as `RED_EVIDENCE_OK`; the final 75-test root suite, 10-test example suite, compile, formatter, and runtime-boundary scans pass.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
