---
phase: 114-release-0-6-0-packaging
plan: 01
subsystem: infra
tags: [hex, exdoc, changelog, semver, release]

requires: []
provides:
  - "@version 0.6.0 in mix.exs"
  - "CHANGELOG [0.6.0] adopter-ready release narrative"
  - "ExDoc Evidence group and Core API audit modules"
  - "Release artifact contract locks for module groups"
affects: [114-02, 114-03]

tech-stack:
  added: []
  patterns: ["ExDoc groups_for_modules IA for Evidence plane"]

key-files:
  created: []
  modified:
    - mix.exs
    - CHANGELOG.md
    - test/threadline/release_artifact_contract_test.exs

key-decisions:
  - "0.6.0 opener avoids internal milestone refs (v1.22) per D-114-01e"

patterns-established:
  - "Evidence plane gets dedicated ExDoc sidebar group"

requirements-completed: [REL-01, REL-02]

duration: 5min
completed: 2026-05-27
---

# Phase 114 Plan 01 Summary

**0.6.0 semver, adopter-ready CHANGELOG narrative, and ExDoc module IA with Evidence plane group**

## Performance

- **Duration:** 5 min
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Bumped `@version` to `0.6.0` in `mix.exs`
- Cut dated `[0.6.0]` CHANGELOG section with Added/Changed/Deprecated/Breaking/Upgrade blocks
- Extended `groups_for_modules` with Evidence, Core API audit modules, and new Mix tasks
- Added contract test locking Evidence group and Core API Audit membership

## Task Commits

1. **Task 1: Bump @version to 0.6.0** - `8e9d3ec`
2. **Task 2: Cut CHANGELOG [0.6.0] section** - `704eda6`
3. **Task 3: Extend ExDoc groups_for_modules** - `f652037`

## Deviations from Plan

None - plan executed as specified.

## Issues Encountered

None

## Next Phase Readiness

Ready for plan 02 install-snippet SSOT sweep (`~> 0.6`).

---
*Phase: 114-release-0-6-0-packaging*
*Completed: 2026-05-27*
