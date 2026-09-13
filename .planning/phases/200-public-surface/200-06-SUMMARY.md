---
phase: 200-public-surface
plan: 06
subsystem: documentation
tags: [exdoc, public-api, module-visibility, governance, operator-surface]
requires:
  - phase: 200-public-surface
    provides: six-role ExDoc skeleton and source-derived visibility/reference contracts
provides:
  - audit-backed hidden visibility for governance schemas and migration generators
  - hidden health, policy, retention, semantics, theme, and font implementation helpers
  - preserved public facade, task, configuration, and extension contracts
affects: [200-07, 200-08, 200-11, 200-12, 200-14]
actuals:
  tokens: 1341
  tasks: 2
  commits: 2
plan_head_before: 70be28663f8503ec9f4c5045c9dbb8a1b0c7eea0
tech-stack:
  added: []
  patterns: [consumer-contract visibility audit, hidden plumbing via moduledoc false, runtime-preserving documentation changes]
key-files:
  created: []
  modified:
    - lib/threadline/governance/export_job.ex
    - lib/threadline/governance/migration.ex
    - lib/threadline/governance/retention_run.ex
    - lib/threadline/governance/saved_view.ex
    - lib/threadline/health/coverage_schemas.ex
    - lib/threadline/policy/redaction_presenter.ex
    - lib/threadline/retention/pruner.ex
    - lib/threadline/semantics/migration.ex
    - lib/threadline/operator_surface/controllers/theme_controller.ex
key-decisions:
  - "Governance export, retention, and saved-view schemas are internal persistence records; public Export and Retention functions return stable result values rather than these structs."
  - "Governance and semantics migration generators, coverage schema validation, redaction presentation, and retention scheduling remain implementation details behind supported Mix tasks, facades, and configuration."
  - "ThemeController and Fonts remain hidden operator implementation helpers; documentation visibility changes do not alter redirect, theme, CSS, font, or runtime behavior."
patterns-established:
  - "A module remains public only when adopters call it, receive it, configure it, or implement its contract; internal Ecto schemas and supervised workers stay callable but undocumented."
  - "Visibility-only audits change module documentation metadata while preserving function definitions, schemas, callbacks, and rendered behavior byte-for-byte."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-07]
coverage:
  - id: D1
    description: "Governance and health persistence, migration, and validation plumbing is hidden while supported public facades and returned values remain unchanged."
    requirement: SURFACE-03
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only module_visibility_governance"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_governance"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Policy, retention, semantics, theme-controller, and font helpers are absent from public module navigation without executable or rendered behavior changes."
    requirement: SURFACE-04
    verification:
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only module_visibility_domain_tail"
        status: pass
      - kind: integration
        ref: "test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_domain_tail"
        status: pass
      - kind: other
        ref: "function-signature and scoped source-vocabulary diff scans"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 06: Governance and Domain-Tail Visibility Summary

**Ten governance, health, policy, retention, semantics, and operator candidates now have consumer-contract visibility decisions, with public facades intact and runtime behavior unchanged.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-12T09:38:22Z
- **Completed:** 2026-09-12T09:45:03Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Hid four governance persistence/generation modules and the coverage-schema boundary helper after tracing every source, test, task, and operator caller.
- Hid the shared redaction presenter, supervised retention pruner, semantics migration generator, and theme controller behind their supported public facades and task/configuration entrypoints.
- Confirmed the font helper was already correctly hidden and left its embedded assets, configuration key, CSS output, and runtime implementation untouched.
- Proved both five-module cohorts with nonempty compiled-document visibility and source-derived public-reference projections.

## Task Commits

1. **Task 1: Audit governance and health plumbing without hiding returned contracts** — `a2ad04d3` (docs)
2. **Task 2: Finish the domain audit and two isolated operator helpers** — `767bac82` (docs)

## Files Created/Modified

- `lib/threadline/governance/export_job.ex` — hidden internal export lifecycle persistence schema.
- `lib/threadline/governance/migration.ex` — hidden install-task migration generator.
- `lib/threadline/governance/retention_run.ex` — hidden internal retention-run persistence schema.
- `lib/threadline/governance/saved_view.ex` — hidden operator saved-view persistence schema.
- `lib/threadline/health/coverage_schemas.ex` — hidden edge-validation helper used by supported health, continuity, and Mix-task surfaces.
- `lib/threadline/policy/redaction_presenter.ex` — hidden shared task/LiveView report builder.
- `lib/threadline/retention/pruner.ex` — hidden application-supervised retention worker.
- `lib/threadline/semantics/migration.ex` — hidden install-task migration generator.
- `lib/threadline/operator_surface/controllers/theme_controller.ex` — explicitly hidden mounted-route implementation.

`lib/threadline/operator_surface/fonts.ex` was audited as the tenth candidate and was already correctly marked `@moduledoc false`; it required no change.

## Decisions Made

| Module cohort | Consumer-contract evidence | Documentation result |
| --- | --- | --- |
| Governance export job, retention run, and saved view | Created, queried, and updated by Threadline internals; public operations return `:ok`, error tuples, or documented result maps rather than these schemas | Hidden |
| Governance and semantics migrations | Called by `mix threadline.install`; adopters use the task rather than generator modules | Hidden |
| Coverage schema helper | Internal validation shared by public tasks, continuity, and operator surfaces | Hidden |
| Redaction presenter | Internal report builder shared by a supported Mix task and LiveView | Hidden |
| Retention pruner | Application-supervised worker triggered through the operator flow; `Threadline.Retention` remains the public lifecycle facade | Hidden |
| Theme controller and font helper | Private route/CSS implementation behind `Threadline.OperatorSurface.Router` and public configuration | Hidden |

The audit changes ExDoc visibility only. No schema fields, functions, callbacks, public return shapes, application configuration, routes, redirect rules, CSS, DOM, font bytes, or rendered operator output changed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan's trailing `-x` is unsupported by the pinned Mix 1.17.3 task runner, as established by earlier Phase 200 plans. Each exact path/tag command was run without only that invalid option; all four selections were nonempty and green.
- The first development compile rebuilt stale dependencies and exceeded the initial 30-second command capture window. The process completed, and a fresh serialized `mix compile --warnings-as-errors` passed before either task was finalized.

## Known Stubs

None.

## Threat Flags

None. This plan narrows generated documentation visibility and adds no endpoint, authorization path, file-access behavior, data schema, or runtime trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 200-07 and 200-08 can finish the remaining operator implementation audit against the same consumer-contract rule.
- Plans 200-11 and 200-12 can replace public guide references to hidden implementation modules with facade, task, and domain language.
- Plan 200-14 can run final module equality, warnings-as-errors docs, and unpacked-archive gates after every bounded owner finishes.

## Self-Check: PASSED

- All nine modified files exist, and the already-hidden font helper exists at its expected path.
- Task commits `a2ad04d3` and `767bac82` exist after the persisted `plan_head_before`; the measured task-commit count is 2.
- All four bounded visibility/reference tags, warnings-as-errors compilation, scoped formatting, vocabulary scans, and diff whitespace checks pass on the pinned toolchain.
- The realized source diff adds no function, schema, field, route, callback, or placeholder.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
