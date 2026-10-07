---
phase: 237-upgrade-guide-and-1-0-0
plan: 02
subsystem: release
tags: [release-please, bash, exunit, ci]
requires:
  - phase: 237-upgrade-guide-and-1-0-0
    provides: 1.0 adopter guide, human-owned changelog coverage, and upgrade contract
provides:
  - Strict committed-candidate rehearsal targeting the exact Release-As 1.0.0 footer
  - Release Please pre-major config and parser/CI topology controls
affects: [phase-237-candidate-rehearsal, release-ci, release-contracts]
actuals:
  tokens: 3806
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 903b1ebb00215f822f50fd496472ce720705b5d4
plan_head_after: 3ca8420a287808357ca204c2c778b8a1bedc897a
tech-stack:
  added: []
  patterns: [candidate metadata preflight before clone creation, sourceable pure shell parser for fixture contracts]
key-files:
  created: []
  modified:
    - release-please-config.json
    - bin/verify-bump-rehearsal
    - test/threadline/changelog_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
key-decisions:
  - "Candidate mode is opt-in; ordinary CI keeps the generic next-minor rehearsal as its default."
  - "Local candidate artifact simulation reports SOURCE_SHA and explicitly makes no live Release Please claim."
patterns-established:
  - "Candidate validation is a pure shell helper so fixture controls can prove fail-closed metadata checks without cloning or fetching dependencies."
requirements-completed: [REL-01, REL-03]
coverage:
  - id: D1
    description: "Strict candidate mode binds local artifact simulation to one committed feat! candidate with an exact 1.0.0 footer and explicit JSON false setting."
    requirement: REL-01
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
      - kind: other
        ref: "bash -n bin/verify-bump-rehearsal"
        status: pass
      - kind: other
        ref: "THREADLINE_BUMP_REHEARSAL_MODE=candidate bin/verify-bump-rehearsal (non-candidate HEAD rejected before clone)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Parser mutation fixtures reject invalid candidate metadata while required routine CI remains connected to generic rehearsal mode."
    requirement: REL-03
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mix verify.format"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-10-07
status: complete
---

# Phase 237 Plan 02: Candidate-Bound Release Rehearsal Summary

**The release rehearsal can validate a committed 1.0.0 candidate while routine CI retains its generic next-minor path.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-10-07T20:23:05Z
- **Completed:** 2026-10-07T20:26:08Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Set `bump-minor-pre-major` to the explicit JSON boolean `false` and updated the changelog contract to pin the 1.0 landing configuration.
- Added opt-in candidate mode to `bin/verify-bump-rehearsal`. Before clone creation it requires a conventional `feat!` subject, exactly one unindented `Release-As: 1.0.0` footer, and the explicit false config value; it uses that validated footer as the target. The clone path asserts the manifest target and generated changelog entry, then retains the existing release artifact gates and source-tree identity checks.
- Kept generic mode as the default for the stable required CI job. Candidate reports identify `SOURCE_SHA`, call the run a local artifact rehearsal, and state that live Release Please was not invoked.
- Added parser fixtures for valid scoped and unscoped breaking subjects and fail-closed controls for non-feat subjects, missing/duplicate/malformed footers, 0.13.0, and true/string config values.

## Task Commits

1. **Task 1: Bind the 1.0 simulation to candidate HEAD controls** — `94008b56` (`feat`)
2. **Task 2: Prove candidate rejection cases and preserve CI gate wiring** — `3ca8420a` (`test`)

## Files Created/Modified

- `release-please-config.json` — disables pre-major minor bumps for the 1.0 landing.
- `bin/verify-bump-rehearsal` — validates candidate metadata and reports the local target honestly while retaining generic mode.
- `test/threadline/changelog_contract_test.exs` — asserts the new JSON setting and existing changelog ownership boundary.
- `test/threadline/ci_topology_contract_test.exs` — protects routine CI wiring and tests candidate parser acceptance/rejection.

## Decisions Made

- Candidate mode is explicit and opt-in; non-candidate pull requests continue to run the generic rehearsal.
- The candidate report proves local artifact gates only and does not claim a live Release Please action.

## Deviations from Plan

None — plan executed as written. The complete disposable-clone run remains assigned to Plan 237-03, which runs it on the committed candidate.

## Verification

- `bash -n bin/verify-bump-rehearsal` — passed.
- `mix verify.test test/threadline/changelog_contract_test.exs` — 9 tests, 0 failures.
- `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/changelog_contract_test.exs` — 35 tests, 0 failures.
- `mix verify.format` — passed.
- Candidate mode against the current non-candidate HEAD — rejected the subject during preflight, before clone creation.

## Issues Encountered

The sandbox initially denied writing the GSD plan ledger under `.git`; the captured pre-plan HEAD was then persisted through the managed escalation path. The measured ledger range contains the two task commits.

## User Setup Required

None.

## Next Phase Readiness

Plan 237-03 can prepare the committed candidate and run the full candidate-specific clone/artifact rehearsal before any separately granted external release action.

## Self-Check: PASSED

- All four plan-owned product/test files exist.
- Task commits `94008b56` and `3ca8420a` are ancestors of the recorded plan head.
- Stub scan found no implementation stubs; the only `FAILED_GATE` match is the script's empty status variable.
- Unrelated pre-existing planning, toolchain, and `AGENTS.md` dirt remains unstaged.

---
*Phase: 237-upgrade-guide-and-1-0-0*
*Completed: 2026-10-07*
