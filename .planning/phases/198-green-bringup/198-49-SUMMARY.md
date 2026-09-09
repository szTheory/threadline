---
phase: 198-green-bringup
plan: 49
subsystem: evidence-automation
tags: [jq, bash, github-actions, policy-validation, security]
requires:
  - phase: 198-44
    provides: Phase-198 evidence policy and exact-main observer baseline
provides:
  - Strict versioned policy schema with repository evidence-subject joins
  - Stable complete prediction-set accounting with separate target and composition scores
  - Two-operation read-only GitHub CLI dispatcher with exact argv construction
affects: [phase-198-security, phase-198-verification, GREEN-03, GREEN-04, GREEN-07]
actuals:
  tokens: 8546
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [exact recursive JSON schema, subject-keyed evidence join, symbolic read-only subprocess dispatcher, NUL-safe argv capture]
key-files:
  created: []
  modified:
    - .planning/audits/198-automation-policy.json
    - bin/verify-phase198-evidence
    - test/threadline/phase198_automation_policy_test.exs
    - bin/observe-main-ci
    - test/threadline/main_ci_observer_contract_test.exs
key-decisions:
  - "Evidence subjects, not copied narrative prose, are the primary keys for policy joins."
  - "The GitHub boundary accepts only list-main-runs and view-run-jobs symbolic operations and constructs every argv token internally."
patterns-established:
  - "Fail-closed policy validation: reject structure, type, identity, join, and semantic errors before derivation."
  - "Prediction reports sorted predicted, observed, intersection, extra, and missing sets plus independent target and composition states."
requirements-completed: [GREEN-03, GREEN-04, GREEN-07]
coverage:
  - id: D1
    description: "The Phase-198 policy evaluator validates an exact versioned schema, unique IDs, bounded values, and repository evidence-subject joins before deriving a result."
    requirement: GREEN-03
    verification:
      - kind: integration
        ref: "mix test test/threadline/phase198_automation_policy_test.exs — 6 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Prediction output emits stable predicted, observed, intersection, extra, and missing sets with separate target and composition scores."
    requirement: GREEN-04
    verification:
      - kind: integration
        ref: "bin/verify-phase198-evidence --policy .planning/audits/198-automation-policy.json --format json | jq -e prediction contract"
        status: pass
    human_judgment: false
  - id: D3
    description: "The exact-main observer can execute only fixed run-list and numeric-ID run-view jobs reads; write verbs, malformed IDs, API errors, and unknown argv fail closed."
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/main_ci_observer_contract_test.exs — 5 tests, 0 failures"
        status: pass
      - kind: other
        ref: "read-only live observation of origin/main a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2 selected run 33138291361 and returned state=failure"
        status: pass
    human_judgment: false
duration: 15 min
completed: 2026-09-09
status: complete
---

# Phase 198 Plan 49: Strict Evidence Automation Summary

**Versioned evidence validation now joins every measured subject to repository evidence, while exact-main GitHub observation is mechanically limited to two fixed read commands.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-09T17:16:34Z
- **Completed:** 2026-09-09T17:31:36Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Upgraded the Phase-198 automation policy to schema v2 with exact recursive key/type validation, unique source and collection IDs, repository-relative evidence paths, and subject joins verified against cited content.
- Added stable complete prediction accounting: predicted, observed, intersection, extra, and missing sets, with target and composition scored independently and non-comparable populations explicitly abstaining.
- Centralized GitHub CLI execution behind two symbolic reads whose argv is constructed internally; NUL-safe fake-gh tests prove write verbs, extra flags, hostile IDs, malformed JSON, and API failures never fall through to another operation.
- Re-observed `origin/main` read-only: SHA `a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2`, run `33138291361`, state `failure`. This confirms evaluator success remains separate from GREEN-07's D-39-governed Pending disposition.

## Task Commits

1. **Task 1 RED: Define strict evidence policy contract** — `33378e9a`
2. **Task 1 GREEN: Enforce evidence-joined policy validation** — `324a0d4e`
3. **Task 2 RED: Define exact read-only gh argv contract** — `ae0b7ab9`
4. **Task 2 GREEN: Confine GitHub observer to read-only argv** — `52248ea2`

## Files Created/Modified

- `.planning/audits/198-automation-policy.json` — versioned policy sources, subjects, IDs, bounded values, and prediction inputs.
- `bin/verify-phase198-evidence` — strict recursive validator, repository evidence join, population comparison, and complete prediction result.
- `test/threadline/phase198_automation_policy_test.exs` — mutation matrix for schema, join, identity, numeric, timeout, population, and prediction controls.
- `bin/observe-main-ci` — fixed two-operation read-only GitHub dispatcher with decimal run-ID validation.
- `test/threadline/main_ci_observer_contract_test.exs` — NUL-safe argv capture, exact allowlist, negative write-verb/hostile-ID fixtures, and non-success API behavior.

## Decisions Made

- Evidence identity is joined mechanically: each policy collection references one unique evidence record whose subject matches the collection's primary identity and is present in the cited file.
- Prediction composition uses sorted set output and reports `exact`, `partial`, or `miss` independently of the target-count `hit`/`miss` result.
- GitHub CLI callers cannot supply verbs or flags; the observer selects one of two symbolic operations and constructs the exact argv itself.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial evidence discriminators referenced prose that did not contain the exact literal; corrected the policy references to existing authoritative UAT text before the GREEN commit.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The observer's empty `sha` and aggregate variables are intentional runtime initialization, not values flowing to a UI.

## Threat Flags

None. The only subprocess trust boundary was already registered in the plan and was narrowed to fixed read-only argv.

## Verification

- Combined focused suite: 11 tests, 0 failures.
- Evaluator JSON contract: `.checks.failed == 0` and all five prediction sets present.
- `git diff --check`: passed.
- Live observer: exact `origin/main` SHA selected completed run `33138291361` with one `CI required` job and honest `failure` state.
- GREEN-07 remains Pending in `.planning/REQUIREMENTS.md`; no requirement promotion or external mutation occurred.

## Self-Check: PASSED

- All five declared implementation/test files exist.
- All four task commits exist in git history.
- Both focused verification suites and the plan-level evaluator/live-observer checks passed.

## Next Phase Readiness

- T-198-44-02, T-198-44-03, and T-198-44-05 now have executable closing controls.
- Ready for Plan 198-50. GREEN-07 remains Pending under D-39 until its independent ancestry and exact-main success predicates change.

---
*Phase: 198-green-bringup*
*Completed: 2026-09-09*
