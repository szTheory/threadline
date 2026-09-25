---
phase: 200-public-surface
plan: 07
subsystem: documentation
tags: [exdoc, public-api, module-visibility, operator-surface, authorization]
requires:
  - phase: 200-public-surface
    provides: six-role ExDoc skeleton and source-derived visibility/reference contracts
provides:
  - audit-backed hidden visibility for export delivery and coverage implementation modules
  - audit-backed hidden visibility for router-installed authorization and session plugs
  - preserved public Router and Auth contracts with unchanged operator behavior
affects: [200-08, 200-11, 200-12, 200-14]
actuals:
  tokens: 2385
  tasks: 2
  commits: 2
plan_head_before: 39cf6721ead44670b561d0b0d18940441f51a72f
tech-stack:
  added: []
  patterns: [consumer-contract visibility audit, hidden plumbing via moduledoc false, behavior-preserving documentation changes]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/operator_surface/coverage/on_mount.ex
    - lib/threadline/operator_surface/coverage/snapshot.ex
    - lib/threadline/operator_surface/export_auth_plug.ex
    - lib/threadline/operator_surface/session_plug.ex
    - lib/threadline/operator_surface/theme_auth_plug.ex
key-decisions:
  - "ExportController, Coverage.OnMount, and Coverage.Snapshot are internal delivery and presentation plumbing behind the supported Router and Auth boundary."
  - "ExportAuthPlug, SessionPlug, and ThemeAuthPlug are router-installed implementation modules; supported mounting and authorization remain documented through Router and Auth."
  - "The visibility audit changes compiled documentation metadata and durable source comments only; routes, callback bodies, response semantics, polling, snapshots, sessions, and authorization decisions remain unchanged."
patterns-established:
  - "Operator implementation modules remain callable for router expansion and runtime dispatch while @moduledoc false keeps them out of the supported HexDocs surface."
  - "Public operator documentation belongs on the mounting and authorization facades, not on generated controllers, hooks, state carriers, or plugs."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-07]
coverage:
  - id: D1
    description: "Export delivery and coverage helpers are hidden from public module navigation while delivery, polling, snapshot, and rendered behavior remain unchanged."
    requirement: SURFACE-03
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only module_visibility_operator_coverage"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_operator_coverage"
        status: pass
      - kind: integration
        ref: "focused export-controller, coverage-hook, and coverage-live tests (48 tests)"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Authorization and session plugs are hidden behind Router and Auth without changing decisions, sessions, routes, status codes, telemetry, or rendered copy."
    requirement: SURFACE-04
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only module_visibility_operator_plugs"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_operator_plugs"
        status: pass
      - kind: integration
        ref: "focused export, session, and theme authorization plug tests (20 tests)"
        status: pass
      - kind: other
        ref: "scoped format, vocabulary, and source-diff checks"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 07: Operator Delivery and Authorization Visibility Summary

**Six operator delivery, coverage, authorization, and session implementation modules are now hidden behind Threadline's supported Router and Auth contracts with runtime behavior unchanged.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-12T09:47:25Z
- **Completed:** 2026-09-12T09:51:16Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Hid the export controller, coverage mount hook, and coverage snapshot after confirming they are internal router/rendering implementation rather than adopter call, return, configuration, or extension contracts.
- Hid the export authorization, actor-session, and theme authorization plugs while preserving `Threadline.OperatorSurface.Router` and `Threadline.OperatorSurface.Auth` as the supported mounting and authorization boundary.
- Removed release chronology, decision identifiers, and troubleshooting shorthand from the task-owned source without changing executable function bodies.
- Proved both visibility/reference cohorts, warning-free compilation, scoped formatting, and 68 focused operator behavior tests.

## Task Commits

1. **Task 1: Audit export delivery and coverage helpers** — `23451dc1` (docs)
2. **Task 2: Audit authorization and session plugs** — `a0154680` (docs)

## Files Created/Modified

- `lib/threadline/operator_surface/controllers/export_controller.ex` — hidden HTTP export implementation; replaced a chronology-tagged comment with the durable Plug header-order invariant.
- `lib/threadline/operator_surface/coverage/on_mount.ex` — hidden coverage polling hook and removed roadmap-era documentation language.
- `lib/threadline/operator_surface/coverage/snapshot.ex` — hidden operator-only coverage state carrier and removed speculative/versioned notes.
- `lib/threadline/operator_surface/export_auth_plug.ex` — hidden router-installed export authorization plug and removed release-specific authorization prose.
- `lib/threadline/operator_surface/session_plug.ex` — hidden router-installed actor-session bridge.
- `lib/threadline/operator_surface/theme_auth_plug.ex` — hidden router-installed theme endpoint guard.

## Decisions Made

| Module cohort | Consumer-contract evidence | Documentation result |
| --- | --- | --- |
| Export controller and coverage hook | Installed and invoked by `Threadline.OperatorSurface.Router`; adopters mount the public router macro rather than calling these modules | Hidden |
| Coverage snapshot | Internal LiveView state carrier consumed only by Threadline operator components and pages; not a public return or configuration type | Hidden |
| Export/session/theme plugs | Inserted by the public router macro to implement its authorization, actor-session, and theme contracts | Hidden |
| Router and Auth | Supported adopter mounting and authorization seams | Remain public and unchanged |

The audit changes `@moduledoc` metadata and comments only. No function definition, callback, route, option, response header/body/status, telemetry event, polling interval, snapshot field, session key, authorization decision, or rendered copy changed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan's trailing `-x` is unsupported by the pinned Mix 1.17.3 task runner, as established by prior Phase 200 execution. Each exact path/tag selection was run without only that invalid option; every selection executed one nonempty test and passed.

## Known Stubs

None. The existing user-facing “Export download is not available” response is established runtime error copy, not placeholder implementation.

## Threat Flags

None. This plan narrows generated documentation visibility and introduces no endpoint, authentication path, authorization behavior, file-access pattern, schema, dependency, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 200-08 can finish the remaining operator helper audit with the same facade-first visibility rule.
- Plans 200-11 and 200-12 can replace guide references to hidden implementation modules with public Router/Auth and domain wording.
- Plan 200-14 can enforce complete module equality, documentation warnings, and unpacked-archive vocabulary gates after all bounded owners finish.

## Self-Check: PASSED

- All six modified operator source files and this summary exist at their expected paths.
- Task commits `23451dc1` and `a0154680` exist after `plan_head_before`; the measured task-commit count is 2.
- All four bounded visibility/reference selections are nonempty and green; warning-free compilation, scoped formatting, vocabulary scans, and 68 focused behavior tests pass.
- Coverage metadata parses with two fully automated deliverables and no schema errors.
- The realized source diff changes only module documentation metadata and comments; no executable function body or public Router/Auth contract changed.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
