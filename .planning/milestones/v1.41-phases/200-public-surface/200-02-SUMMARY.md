---
phase: 200-public-surface
plan: 02
subsystem: documentation
tags: [configuration, mix-tasks, developer-experience, exdoc, public-api]
requires:
  - phase: 200-public-surface
    provides: source-derived runtime-key, Mix-task, alias, and public-reference contracts
provides:
  - canonical reference for all fourteen supported Threadline runtime keys
  - exact adopter, repository-only, and maintainer-only command classifications
  - explicit dynamic adapter-module configuration seam and operator polling boundaries
affects: [200-03, 200-04, 200-09, 200-10, 200-12, 200-13, 200-14]
actuals:
  tokens: 3509
  tasks: 2
  commits: 3
plan_head_before: c9091bb332ed4e6e20c966fd0778fe4c073182b7
tech-stack:
  added: []
  patterns: [source-derived exact inventories, host-vs-repository command boundary, canonical compatibility reference]
key-files:
  created:
    - guides/configuration-and-commands.md
  modified:
    - test/threadline/public_surface_contract_test.exs
key-decisions:
  - "All fourteen literal :threadline runtime keys are documented as the supported application-environment contract, while adapter-module options remain a distinct dynamic key class."
  - "Only threadline.* Mix tasks are host-project commands; root verify.*, test.*, and ci.all aliases remain repository-local, with credentialed and corpus-specific tools classified maintainer-only."
patterns-established:
  - "Reference rows pair every runtime key with purpose, accepted shape, absence behavior, and its owning public module or guide."
  - "Command documentation states availability before purpose so dependency-provided tasks cannot be confused with root-project aliases."
requirements-completed: [SURFACE-07]
coverage:
  - id: D1
    description: Every discovered literal runtime key and the dynamic adapter-module key seam have source-accurate documentation.
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only runtime_key_reference"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_doc_refs_config"
        status: pass
    human_judgment: false
  - id: D2
    description: Every discovered Mix task and repository alias is classified without presenting repository aliases as host commands.
    requirement: SURFACE-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only command_reference"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_inventory"
        status: pass
      - kind: other
        ref: "source inventory check: 13 tasks and 24 aliases documented, none missing"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 02: Configuration and Command Reference Summary

**One compatibility-grade guide now documents every supported Threadline runtime key and separates adopter tasks from repository and maintainer commands.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-09-12T07:16:38Z
- **Completed:** 2026-09-12T07:42:11Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Documented all fourteen literal application keys with purpose, accepted shape, defaults or absence behavior, safe examples, and primary ownership.
- Kept adapter-module options as a separate dynamic configuration class and distinguished operator UI polling from worker and cleanup schedules.
- Classified all 13 source-discovered Mix tasks and all 24 root aliases into adopter, repository-only, or maintainer-only lanes.
- Added concise Adopt and Operate successors without duplicating an installation or operator tutorial.

## Task Commits

1. **Task 1: Trace every supported runtime key into the canonical reference** — `7c83cbd1`
2. **Task 2 deviation: Repair known-alias validation in the source-derived contract** — `acf695e3`
3. **Task 2: Classify adopter tasks and repository commands without alias leakage** — `b650e479`

## Files Created/Modified

- `guides/configuration-and-commands.md` — canonical runtime configuration and command reference.
- `test/threadline/public_surface_contract_test.exs` — corrected command-reference validation so known aliases are actually subtracted before reporting unknown commands.

## Decisions Made

- Followed the locked public-surface classifications: every literal runtime key is supported, adapter-module options remain dynamically owned, and no nested configuration namespace was introduced.
- Kept every root alias repository-local even when useful to contributors; dependency installation exposes task modules, not the dependency project's aliases.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Contract bug] Corrected chained list subtraction in alias-reference validation**

- **Found during:** Task 2 command-reference verification
- **Issue:** `refs.commands -- known_task_names -- inventory.aliases` was parsed so the known alias list was not removed, causing all 24 valid aliases to be reported as unknown.
- **Fix:** Subtracted the combined known-task and known-alias lists in one explicit operation.
- **Files modified:** `test/threadline/public_surface_contract_test.exs`
- **Verification:** The command-reference, public-inventory, and config-reference projections all pass; a separate source scan found 13 tasks, 24 aliases, and no missing guide entries.
- **Committed in:** `acf695e3`

**Total deviations:** 1 auto-fixed (Rule 1)

**Impact on plan:** The correction restores the intended source-derived contract without changing runtime behavior or expanding public surface.

## Issues Encountered

- The plan's trailing `-x` remains unsupported by the pinned Mix 1.17.3 task runner. Its exact invocation was confirmed to fail with `-x : Unknown option`; each specified selection was then run with the same path and tag after removing only that unsupported flag.

## User Setup Required

None.

## Next Phase Readiness

- Plan 200-03 can extend this canonical reference with the detailed storage and export-queue behavior contracts and repair the optional storage callback path.
- Later Adopt and Operate documentation slices can link this reference from their canonical lane owners.
- No public API, router mount option, runtime namespace, dependency, or operator UI changed.

## Self-Check: PASSED

- The canonical guide, contract test, and summary exist on disk.
- All three task/deviation commits exist in history.
- Runtime-key, command, public-inventory, and config-reference projections pass with one selected test each and no failures.
- Coverage metadata classifies both deliverables as fully automated and passing.
- The source inventory confirms all 13 tasks and 24 aliases are documented with no missing member.
- Format, whitespace, stub, and threat-surface checks pass.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
