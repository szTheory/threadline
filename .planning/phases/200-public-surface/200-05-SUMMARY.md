---
phase: 200-public-surface
plan: 05
subsystem: documentation
tags: [exdoc, public-api, module-visibility, capture, operator-surface]
requires:
  - phase: 200-public-surface
    provides: six-role ExDoc skeleton and source-derived visibility/reference contracts
provides:
  - audited hidden visibility for operator, migration, capture, and export implementation modules
  - preserved public Evidence.Subject data contract and threadline.gen.triggers adopter task
  - chronology-free source comments and module documentation across the nine-file cohort
affects: [200-06, 200-07, 200-08, 200-14]
actuals:
  tokens: 7791
  tasks: 2
  commits: 2
plan_head_before: 147745175531b7796ee84e24577ac646c74313e0
tech-stack:
  added: []
  patterns: [consumer-contract visibility audit, hidden plumbing via moduledoc false, durable invariant prose]
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/capture/migration.ex
    - lib/threadline/evidence/subject.ex
    - lib/mix/tasks/threadline.gen.triggers.ex
    - lib/threadline/capture/redaction_policy.ex
    - lib/threadline/capture/trigger_capture_config.ex
    - lib/threadline/capture/trigger_sql.ex
    - lib/threadline/export/cleanup_task.ex
key-decisions:
  - "Style, UI, and Capture.Migration are implementation-only; Evidence.Subject and Mix.Tasks.Threadline.Gen.Triggers remain public because they are supported data and task contracts."
  - "RedactionPolicy, TriggerCaptureConfig, TriggerSQL, and CleanupTask are internal plumbing reached only through Threadline-owned tasks, migrations, supervision, tests, and benchmarks."
  - "Visibility changed only at the documentation boundary; all functions, returned structs, runtime behavior, and supported adopter entrypoints remain intact."
patterns-established:
  - "Consumer-contract audit: public status requires a supported call path, returned type, configuration seam, or extension role—not merely a callable module."
  - "Source prose states durable behavior and rationale without milestone IDs, requirement codes, decision labels, or release chronology."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-07]
coverage:
  - id: D1
    description: "The seed cohort exposes only the supported Evidence.Subject data contract and threadline.gen.triggers task while hiding operator and migration implementation modules."
    requirement: SURFACE-03
    verification:
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only module_visibility_seed"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_seed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Capture configuration, trigger SQL generation, redaction normalization, and export cleanup remain callable internally but are absent from the public documentation surface."
    requirement: SURFACE-03
    verification:
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only module_visibility_capture"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/public_surface_contract_test.exs --only public_doc_refs_module_capture"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D3
    description: "All nine owned files use stable domain language and contain no Phase 200, decision, requirement, capture, cleanup, or release-version chronology tokens."
    requirement: SURFACE-07
    verification:
      - kind: other
        ref: "scoped rg chronology-vocabulary scan over the nine owned modules"
        status: pass
      - kind: other
        ref: "mix format --check-formatted over the nine owned modules"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-09-12
status: complete
---

# Phase 200 Plan 05: Seed and Capture Visibility Audit Summary

**Nine operator, migration, capture, and export modules now present a consumer-shaped documentation surface: supported data and task contracts stay public while implementation plumbing is hidden without runtime change.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-12T09:10:09Z
- **Completed:** 2026-09-12T09:22:31Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Audited every seed module by actual call sites and adopter contracts, hiding `OperatorSurface.Style`, `OperatorSurface.UI`, and `Capture.Migration` while retaining public documentation for `Evidence.Subject` and `Mix.Tasks.Threadline.Gen.Triggers`.
- Hid redaction-policy normalization, trigger-capture configuration, trigger SQL generation, and the supervised export cleanup worker from ExDoc while preserving every callable function and runtime behavior.
- Replaced planning chronology in the owned source cohort with stable explanations of accessibility, responsive layout, theme behavior, capture recursion prevention, and validation invariants.
- Proved both cohorts through non-vacuous compiled-document visibility and public-reference contracts, warnings-as-errors compilation, scoped formatting, and module-vocabulary checks.

## Task Commits

1. **Task 1: Audit seed module visibility and durable vocabulary** — `5752e357`
2. **Task 2: Audit capture and export implementation visibility** — `0b0b15a5`

## Files Created/Modified

- `lib/threadline/operator_surface/style.ex` — hidden CSS implementation module with planning chronology replaced by stable layout, theme, and motion rationale.
- `lib/threadline/operator_surface/ui.ex` — retained hidden component implementation status and rewrote internal comments around user-visible behavior and accessibility.
- `lib/threadline/capture/migration.ex` — hidden migration generator behind the documented install task.
- `lib/threadline/evidence/subject.ex` — preserved the public returned data contract and removed release-specific wording.
- `lib/mix/tasks/threadline.gen.triggers.ex` — preserved the public adopter task while removing hidden-module references and internal decision codes from user-facing text.
- `lib/threadline/capture/redaction_policy.ex` — hidden internal redaction configuration normalizer.
- `lib/threadline/capture/trigger_capture_config.ex` — hidden internal trigger-capture configuration loader.
- `lib/threadline/capture/trigger_sql.ex` — hidden internal SQL generator and replaced decision-code commentary with the invariant it protects.
- `lib/threadline/export/cleanup_task.ex` — hidden the application-supervised cleanup worker.

## Decisions Made

| Module | Consumer-contract evidence | Documentation result |
| --- | --- | --- |
| `Threadline.OperatorSurface.Style` | Called by internal UI rendering; example storybook use is maintainer tooling | Hidden |
| `Threadline.OperatorSurface.UI` | Internal component renderer with no supported component API | Hidden |
| `Threadline.Capture.Migration` | Invoked behind the documented install task | Hidden |
| `Threadline.Evidence.Subject` | Returned and validated through the public evidence workflow | Public |
| `Mix.Tasks.Threadline.Gen.Triggers` | Direct adopter command and supported setup path | Public |
| `Threadline.Capture.RedactionPolicy` | Internal normalization used by Threadline generators | Hidden |
| `Threadline.Capture.TriggerCaptureConfig` | Internal loader used by the trigger-generation task | Hidden |
| `Threadline.Capture.TriggerSQL` | Generator called by tasks, migrations, tests, and benchmarks | Hidden |
| `Threadline.Export.CleanupTask` | Application-supervised background worker | Hidden |

The audit deliberately separates Elixir callability from public support. Hidden modules retain their implementations for Threadline-owned composition; the documented surface reflects the smallest coherent adopter contract.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan's trailing `-x` is unsupported by the pinned Mix runner. As established by prior Phase 200 execution, each exact path/tag command was run without only that invalid flag; every command selected one test and passed.
- An optional broader DB-backed regression bundle could not connect to PostgreSQL on the configured local port 5433. This was outside the plan's required gates; all four bounded documentation contracts, compilation, formatting, and vocabulary checks completed successfully without database access.
- An unrelated untracked `.tool-versions` file appeared during final verification and did not select a default Elixir version. It was preserved untouched; verification used the already-installed Homebrew Elixir 1.19.5 toolchain explicitly.

## Known Stubs

None.

## Threat Flags

None. The plan changes documentation visibility and source prose only; it adds no endpoint, authentication path, file-access behavior, schema, or runtime trust boundary.

## User Setup Required

None.

## Next Phase Readiness

- Plans 200-06 through 200-08 can continue bounded module audits against the same consumer-contract rule without reopening this cohort.
- Plan 200-14 can build and verify final HexDocs knowing these internal modules will not leak into public navigation or generate orphan-reference warnings.
- No public API, returned data shape, operator UI, or supported behavior was widened or removed.

## Self-Check: PASSED

- All nine modified source files and this summary exist at their expected paths.
- Task commits `5752e357` and `0b0b15a5` exist after the persisted `plan_head_before`; the measured task-commit count is 2.
- All four bounded visibility/reference tags, warnings-as-errors compilation, scoped formatting, chronology-vocabulary scan, and diff whitespace check pass from the committed tree.
- Coverage classification reports all three deliverables automatically covered with no errors or human-only checks.

---
*Phase: 200-public-surface*
*Completed: 2026-09-12*
