---
phase: 225-suite-baseline-and-partitioned-ci
plan: 02
subsystem: testing
tags: [telemetry, exunit, async, elixir]

requires:
  - phase: 225-suite-baseline-and-partitioned-ci
    plan: 01
    provides: "SUITE-01 baseline (225-BASELINE.md local median 137.0s) that this plan's D-20 delta compares against"
provides:
  - "test/support/telemetry_helpers.ex: Threadline.TelemetryHelpers.attach_telemetry!/1, reusable by Phase 228's telemetry tests"
  - "Three operator-surface auth telemetry test files running async: true, isolated by emitting-process identity"
  - "225-EVIDENCE.md ## SUITE-03: D-17 mutation red/green, D-18 200-repeat proof, D-20 local delta"
affects: [225-03, 225-04, 228]

actuals:
  tokens: 8561
  tasks: 2
  commits: 2
  plan_head_before: 278e6049f621f24b13a1b67989b8ee3b82b6d3eb
  plan_head_after: f6e3ba94fbacd0ad695b660e1c1974349b7c53a4

tech-stack:
  added: []
  patterns:
    - "Emitting-process identity filter for :telemetry handlers: forward only when self() == test_pid or test_pid in Process.get(:\"$callers\", []) — a unique handler id or ref alone does not isolate VM-global handlers"
    - "LIFO on_exit ordering used to prove detachment: register a checking on_exit before the helper's attach call so the helper's own detach on_exit (registered later, runs first) completes before the check runs"

key-files:
  created:
    - test/support/telemetry_helpers.ex
    - test/threadline/telemetry_helpers_test.exs
    - .planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md
  modified:
    - test/threadline/operator_surface/auth_test.exs
    - test/threadline/operator_surface/export_auth_plug_test.exs
    - test/threadline/operator_surface/theme_auth_plug_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "Used :persistent_term (not a linked Agent) to carry the ref into the on_exit detachment check — a linked Agent does not reliably survive into ExUnit's separate on_exit-runner process."
  - "Old auth_test.exs telemetry-assertion count was 10, not the plan's stated baseline of 10 confirmed by direct git show count against caabf12c (my first grep undercounted by missing the :mismatch_telemetry_event/:export_telemetry_event tags; recounted with a combined pattern)."

patterns-established:
  - "attach_telemetry!/1 is the standard way to make a telemetry-asserting ExUnit test async: true in this repo going forward."

requirements-completed: [SUITE-03]

coverage:
  - id: D1
    description: "attach_telemetry!/1 forwards only events from the attaching test process or a $callers child (Task); an unrelated spawned process's emission is filtered out"
    requirement: SUITE-03
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_helpers_test.exs (4 tests)"
        status: pass
      - kind: unit
        ref: "D-17 mutation control: filter removed -> test 3 red; filter restored -> green (225-EVIDENCE.md)"
        status: pass
    human_judgment: false
  - id: D2
    description: "auth_test.exs, export_auth_plug_test.exs, theme_auth_plug_test.exs run async: true through the helper, with every assertion pinning ^telemetry_ref plus the full event name (auth 10, export 7, theme 5 assertions, all >= prior counts)"
    requirement: SUITE-03
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/{auth,export_auth_plug,theme_auth_plug}_test.exs test/threadline/telemetry_helpers_test.exs"
        status: pass
      - kind: unit
        ref: "mix test ... --repeat-until-failure 200 (201 iterations, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Deferred files (telemetry_test.exs, health_test.exs, health/trigger_findings_test.exs, export_queue/task_adapter_test.exs, retention/pruner_test.exs, operator_surface/live/retention_history_live_test.exs, operator_surface/stress_router_test.exs) unchanged and CONTRIBUTING.md documents the async rule"
    requirement: SUITE-03
    verification:
      - kind: unit
        ref: "git diff --quiet caabf12c -- <seven deferred files>"
        status: pass
      - kind: unit
        ref: "grep attach_telemetry!/1 CONTRIBUTING.md; bin/verify-repo-hygiene"
        status: pass
    human_judgment: false
  - id: D4
    description: "225-EVIDENCE.md ## SUITE-03 records the D-17 red/green, D-18 200-repeat summary, and the D-20 local delta table vs 225-BASELINE.md's median"
    requirement: SUITE-03
    verification:
      - kind: unit
        ref: "grep '## SUITE-03' .planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-30
status: complete
---

# Phase 225 Plan 02: Async operator-surface auth telemetry tests (SUITE-03) Summary

**The three operator-surface auth telemetry test files (`auth_test.exs`, `export_auth_plug_test.exs`, `theme_auth_plug_test.exs`) now run `async: true`, isolated by a new emitting-process-identity `attach_telemetry!/1` helper, proven by a red/green mutation control and a clean 200-repeat local run.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-09-30 (approx)
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments
- `Threadline.TelemetryHelpers.attach_telemetry!/1` (`test/support/telemetry_helpers.ex`): attaches a handler whose config holds `test_pid` and a fresh `ref`; forwards `{event, ref, measurements, metadata}` only to the attaching test process or a `$callers` child; registers `on_exit` detachment.
- `test/threadline/telemetry_helpers_test.exs`: 4 tests — same-process delivery, `Task.async/await` (`$callers` child) delivery, bare-`spawn` non-delivery (the D-17 isolation proof), and on_exit detachment (via a `:persistent_term`-carried ref and LIFO `on_exit` ordering, since a linked `Agent` does not reliably survive into ExUnit's separate on_exit-runner process).
- `auth_test.exs`, `export_auth_plug_test.exs`, `theme_auth_plug_test.exs` converted to `async: true`, using `attach_telemetry!/1` in place of direct `:telemetry.attach` calls; every assertion now pins `^telemetry_ref` plus the full event name (stricter than the old wildcard-event, message-tag patterns). Stale "async: false" header comments removed.
- `CONTRIBUTING.md`'s telemetry rule replaced: async is allowed via `attach_telemetry!/1` when the code under test emits in-process; events from other processes still require `async: false`.
- `225-EVIDENCE.md` `## SUITE-03`: D-17 mutation red/green transcripts, D-18's 200-repeat 0-failure summary, and D-20's local delta table (new median 133.0s vs `225-BASELINE.md`'s 137.0s, about -2.9%, within local noise).

## Task Commits

Each task's work, per the plan's explicit combined-commit instruction (all five code/doc paths in one commit, evidence in a second):

1. **Task 1 + Task 2 (combined per plan):** `test(225-02): run the operator-surface auth telemetry tests async` — `3d2acef2` (test) — `test/support/telemetry_helpers.ex`, `test/threadline/telemetry_helpers_test.exs`, `test/threadline/operator_surface/auth_test.exs`, `test/threadline/operator_surface/export_auth_plug_test.exs`, `test/threadline/operator_surface/theme_auth_plug_test.exs`, `CONTRIBUTING.md`.
2. **Evidence:** `docs(225): record the async telemetry evidence` — `f6e3ba94` (docs) — `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md`.

**Plan metadata:** (pending, this commit)

## Files Created/Modified
- `test/support/telemetry_helpers.ex` — new `attach_telemetry!/1` helper, isolated by emitting-process identity
- `test/threadline/telemetry_helpers_test.exs` — 4 tests proving delivery/non-delivery/detachment
- `test/threadline/operator_surface/auth_test.exs` — converted to async, 10 pinned assertions
- `test/threadline/operator_surface/export_auth_plug_test.exs` — converted to async, 7 pinned assertions
- `test/threadline/operator_surface/theme_auth_plug_test.exs` — converted to async, 5 pinned assertions
- `CONTRIBUTING.md` — telemetry rule replaced
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md` — SUITE-03 evidence

## Decisions Made
- `:persistent_term` instead of a linked `Agent` to carry the ref across into the `on_exit` check (an Agent linked to the test process does not reliably survive to be queried once ExUnit's on_exit-runner process takes over).
- Recounted `auth_test.exs`'s old telemetry-assertion total directly from `git show caabf12c:...` with a combined pattern matching all three message tags (`:telemetry_event`, `:mismatch_telemetry_event`, `:export_telemetry_event`) after an initial narrower grep undercounted; confirmed 10, matching the plan's stated figure.

## Deviations from Plan

None - plan executed as written. The two commit-ordering and technical choices above are implementation details within the plan's own "Claude's Discretion" scope, not deviations.

## Issues Encountered
- Local Postgres check (`pg_stat_activity`) showed 0 non-idle connections before the D-20 timing runs, so no contention wait was needed this time.
- The third D-20 timing run (164.6s) was a clear outlier vs the other two (128.4s, 133.0s) — attributed to local machine noise (224/225-BASELINE.md both document ±55s local swings on this shared setup), not a suite regression; noted explicitly in 225-EVIDENCE.md so the delta isn't over-read.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUITE-03 is complete: three files async, isolated, proven by mutation control and 200 local repeats, documented in CONTRIBUTING.md.
- `attach_telemetry!/1` is available for Phase 228's new telemetry tests.
- No blockers for 225-03 (SUITE-02 partitioning) or 225-04 (the Flake Detection re-measurement, gated on a maintainer push/dispatch grant per D-14c).

## Self-Check: PASSED

All created files found on disk (`test/support/telemetry_helpers.ex`, `test/threadline/telemetry_helpers_test.exs`, `225-EVIDENCE.md`); commits `3d2acef2` and `f6e3ba94` found in `git log --oneline --all`.

---
*Phase: 225-suite-baseline-and-partitioned-ci*
*Completed: 2026-09-30*
