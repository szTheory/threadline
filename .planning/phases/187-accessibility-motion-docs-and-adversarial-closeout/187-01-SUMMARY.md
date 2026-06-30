---
phase: 187-accessibility-motion-docs-and-adversarial-closeout
plan: 01
subsystem: docs
tags: [operator-surface, docs, exunit, theme-picker, csp]
requires:
  - phase: 175-shell-navigation-theme-picker
    provides: Runtime server-posted theme picker and CSP-proof shell contracts.
  - phase: 185-coverage-and-audit-readiness
    provides: Selected-schema Coverage docs and doc-contract tests.
provides:
  - Source-aligned operator guide for the runtime dark/light/system theme picker.
  - Executable doc contracts for runtime theme picker, Storybook/stress, export auth, CSP, and private-component boundaries.
  - DOC-01 evidence that docs match current source truth without behavior changes.
affects: [operator-surface-docs, doc-contracts, phase-187-closeout]
tech-stack:
  added: []
  patterns:
    - Source-reading ExUnit doc contracts pin guide literals against current runtime source truth.
    - Runtime theme docs distinguish host default `theme:` from operator-selected server-posted session state.
key-files:
  created:
    - .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-01-SUMMARY.md
  modified:
    - guides/operator-surface.md
    - test/threadline/operator_surface/theme_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
key-decisions:
  - "DOC-01 source truth follows the current runtime server-posted theme picker, not older host-only theme prose."
  - "Storybook remains example-app dev/test maintainer tooling; /audit/__stress remains authenticated stress proof, not production public component documentation."
patterns-established:
  - "Theme docs contract: pin POST `{base_path}/theme`, CSRF, native radios, allowlisted modes, session/cookie/plug resolution, no JavaScript, and no localStorage in the Theme section."
requirements-completed: [DOC-01]
duration: 5 min
completed: 2026-06-30
status: complete
---

# Phase 187 Plan 01: Runtime Theme Picker And Operator Docs Truth Repair Summary

**Operator docs now describe the implemented server-posted runtime theme picker and preserve operator-surface production/security boundaries.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-30T15:06:17Z
- **Completed:** 2026-06-30T15:11:08Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED doc-contract assertions for the runtime dark/light/system picker: `POST {base_path}/theme`, `_csrf_token`, native radios, allowlisted values, session/cookie/plug resolution, no JavaScript, and no `localStorage`.
- Repaired `guides/operator-surface.md` so `theme:` remains the host default lane while operators can select a runtime server-posted theme through the shell.
- Preserved and pinned Storybook dev/test boundaries, authenticated `/audit/__stress`, direct export route authorization, CSP posture, selected-schema Coverage docs, production exclusions, and private-component status.

## Task Commits

1. **Task 1: Pin runtime theme and operator-boundary doc contracts** - `8c19f7e9` (`test`)
2. **Task 2: Repair operator guide to source truth** - `23d71d77` (`docs`)

## Files Created/Modified

- `guides/operator-surface.md` - runtime theme picker and operator-boundary docs repaired against current source truth.
- `test/threadline/operator_surface/theme_doc_contract_test.exs` - Theme-section source-reading doc contracts added.
- `test/threadline/operator_surface_doc_contract_test.exs` - Storybook/stress/export/CSP/private-component doc contracts sharpened.

## Verification

- `mix test test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` - RED after Task 1: 56 tests, 8 expected failures against stale guide text.
- `mix test test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` - PASS after guide repair: 56 tests, 0 failures.
- `mix format --check-formatted test/threadline/operator_surface/theme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs` - PASS.
- Acceptance greps confirmed runtime picker, Storybook/stress, export auth, CSP, Coverage, and stale-theme-language contracts in `guides/operator-surface.md`.

## Decisions Made

- Treated `router.ex`, `surface_header.ex`, `theme_controller.ex`, and `Auth.on_mount/4` as source truth for runtime theme behavior.
- Kept Coverage contract tests unchanged because selected-schema readiness, invalid-schema recovery, non-public row links, stale last-good behavior, and `--schema=NAME` verifier docs were already pinned.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial GREEN run found two guide phrases split across markdown lines; the guide text was adjusted so the committed doc contracts pin exact literals.

## Known Stubs

None. Stub scan hits were false positives in existing redaction policy terminology (`mask placeholder`) rather than UI stubs or mock data.

## Auth Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 187-02 can proceed with accessibility and motion proof closure. DOC-01 docs drift for runtime theme picker and operator boundaries is repaired and guarded.

## Self-Check: PASSED

- Found summary file at `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-01-SUMMARY.md`.
- Found modified plan files: `guides/operator-surface.md`, `test/threadline/operator_surface/theme_doc_contract_test.exs`, `test/threadline/operator_surface_doc_contract_test.exs`, and `test/threadline/operator_surface/coverage_doc_contract_test.exs`.
- Found task commits `8c19f7e9` and `23d71d77` in git history.
- Post-commit deletion checks after each task found no tracked-file deletions.

---
*Phase: 187-accessibility-motion-docs-and-adversarial-closeout*
*Completed: 2026-06-30*
