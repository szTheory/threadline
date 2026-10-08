---
phase: 236-support-floor-and-partition-weights
plan: 01
subsystem: ci
tags: [postgresql, exunit, ci, docs]
requires:
  - phase: 235-stability-contract-and-adopter-guides
    provides: The adopter-guide and contract patterns used to publish the support policy.
provides:
  - PostgreSQL 15 as the exact minimum CI lane and supported floor.
  - A source-derived Elixir, OTP, and PostgreSQL policy table.
  - README and Unreleased changelog statements with the PostgreSQL 14 upgrade action.
affects: [236-02, 237-upgrade-guide-and-1-0-0]
actuals:
  tokens: 5965
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Compare complete version tokens in a guide contract sourced from Mix, CI, and .tool-versions.
    - Use mutation controls for stale source values, policy rows, and adopter-facing claims.
key-files:
  created:
    - test/threadline/guides/upgrade_path_contract_test.exs
  modified:
    - .github/workflows/ci.yml
    - mix.exs
    - guides/upgrade-path.md
    - test/threadline/ci_topology_contract_test.exs
    - README.md
    - CHANGELOG.md
key-decisions:
  - The min CI lane is the supported floor; current and latest remain tested-on evidence.
requirements-completed: [FLOOR-01, FLOOR-02]
coverage:
  - id: D1
    description: CI and Mix pin PostgreSQL 15 as the minimum, protected by adjacent-major mutation controls.
    requirement: FLOOR-01
    verification:
      - kind: unit
        ref: test/threadline/ci_topology_contract_test.exs#the verify-test minimum lane pins PostgreSQL 15 exactly (FLOOR-01)
        status: pass
      - kind: integration
        ref: PostgreSQL 15 focused contract run, server_version_num 150018
        status: pass
    human_judgment: false
  - id: D2
    description: The guide has one exact source-derived support table with min, current, and latest claim meanings.
    requirement: FLOOR-02
    verification:
      - kind: unit
        ref: test/threadline/guides/upgrade_path_contract_test.exs#one toolchain support table matches the declared support and CI lanes (FLOOR-01/02)
        status: pass
    human_judgment: false
  - id: D3
    description: README and Unreleased changelog state the PostgreSQL 15 floor and the PostgreSQL 14 adopter action.
    requirement: FLOOR-01
    verification:
      - kind: unit
        ref: test/threadline/guides/upgrade_path_contract_test.exs#README and Unreleased changelog state the PostgreSQL 15 floor and adopter action
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-10-07
status: complete
---

# Phase 236 Plan 01 Summary

**PostgreSQL 15 is the tested CI floor, with one source-checked support table and aligned adopter guidance**

## Performance

- **Duration:** 30 min
- **Started:** 2026-10-07T16:26:04Z
- **Completed:** 2026-10-07T16:55:43Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Changed only the verify-test min PostgreSQL value to 15, updated the Mix support comment, and preserved the Elixir, OTP, current, and latest lane values.
- Added one guide table checked against the Elixir constraint, CI lane pins, and .tool-versions, including mutation controls for source and table drift.
- Updated the README and Unreleased breaking entry; a contract checks the floor, guide link, and PostgreSQL 14 adopter action.

## Task Commits

1. **Task 1: Connect the minimum lane to the support table** — RED test commit 83302bff; GREEN implementation commit f068eea0; source/test contract-link closure commit 5895d39d.
2. **Task 2: Align README and breaking-change record** — 1c600cc9.

## Files Created/Modified

- .github/workflows/ci.yml — min lane is PostgreSQL 15; other matrix values and job identity are unchanged.
- mix.exs — support comment now matches PostgreSQL 15 minimum.
- guides/upgrade-path.md — one toolchain support-policy table with tested-on distinctions.
- test/threadline/ci_topology_contract_test.exs — exact min-lane assertion and 14/16 mutation controls.
- test/threadline/guides/upgrade_path_contract_test.exs — source-derived table plus README and changelog contracts.
- README.md — current PostgreSQL floor and link to the policy table.
- CHANGELOG.md — Unreleased PostgreSQL 15 minimum and the PostgreSQL 14 upgrade action.

## Decisions Made

The minimum lane alone states the supported floor. The current and latest lanes remain tested-on evidence, matching their CI roles.

## Verification

- The focused topology and guide contracts passed together: 26 tests, 0 failures, against PostgreSQL 15 (server_version_num 150018) at local port 55433.
- mix verify.format passed.
- Both TDD RED target runs failed on the intended assertions; gsd-tools check tdd-red-evidence returned RED_EVIDENCE_OK for each before implementation.
- The phase-goal review found that the ROADMAP's same-commit CI/topology-contract criterion needed an explicit source link. A deletion mutation went red before adding the adjacent CI comment, and commit 5895d39d couples the CI lane comment with the topology contract that enforces it; the focused topology and parity contracts then passed (74 tests, 0 failures), followed by format and Credo checks.

## Deviations from Plan

- PostgreSQL 15 ran on port 55433 because port 55432 was already bound to an unrelated PostgreSQL 16 container. That container was left untouched; all phase database commands use 55433.
- The TDD evidence checker does not parse ExUnit's text output. A temporary ExUnit formatter emitted TAP from the actual test events for the RED runs; it lives under /private/tmp and is not committed.

## Issues Encountered

The workspace sandbox initially blocked Git from creating .git/index.lock. The same narrow GSD commits succeeded with sandbox escalation. No unrelated dirty files were staged.

## User Setup Required

None. The PostgreSQL 15 service was started automatically and remains available for Plan 02.

## Next Phase Readiness

Plan 02 is ready to add the measured-weight completeness contract, regenerate the final inventory, and run the partitioned and aggregate gates against the verified PostgreSQL 15 service.

---
*Phase: 236-support-floor-and-partition-weights*
*Completed: 2026-10-07*
