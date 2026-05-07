---
phase: 68
plan: 02
subsystem: lifecycle-ergonomics
tags:
  - docs
  - optional-deps
  - compatibility
  - doc-contract
requires:
  - mix.exs optional dependency declarations
  - mix.lock current surface resolution
  - .github/workflows/ci.yml stable CI job IDs
provides:
  - canonical upgrade-path guide
  - scoped operator-surface cross-link
  - doc-contract coverage for support matrix and deprecation policy
affects:
  - guides/upgrade-path.md
  - guides/operator-surface.md
  - CHANGELOG.md
  - mix.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/upgrade_path_doc_contract_test.exs
completed_at: 2026-05-07T21:07:48Z
---

# Phase 68 Plan 02: Upgrade Path Summary

Canonical upgrade-path guide for Threadline's optional operator-surface lifecycle policy, with support claims constrained to declared deps, current lock resolution, and current CI coverage.

## Completed Work

- Added `guides/upgrade-path.md` as the canonical answer for track detection, compatibility support, minor-upgrade guidance, break symptoms when Phoenix/LiveView floors move, and the surface-only deprecation/removal overlap policy.
- Kept `guides/operator-surface.md` scoped to mount/auth/screens by linking out to `guides/upgrade-path.md` instead of absorbing lifecycle policy.
- Added the new guide to ExDoc extras in `mix.exs`.
- Added an unreleased changelog entry pointing readers at the new upgrade-path guide.
- Extended `test/threadline/operator_surface_doc_contract_test.exs` for the cross-link and scope boundary.
- Added `test/threadline/upgrade_path_doc_contract_test.exs` to lock the required section headings, matrix headers, track-detection language, narrow support wording, deprecation/removal overlap policy, `mix verify.compile_no_optional` proof point, and ExDoc extras wiring.

## Verification

- `mix test test/threadline/operator_surface_doc_contract_test.exs` — PASS
- `MIX_ENV=dev mix docs` — PASS
  - ExDoc emitted pre-existing warnings outside this plan's owned files; the build completed successfully.
- `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/ci_topology_contract_test.exs` — PASS
- `mix verify.compile_no_optional` — PASS

## Commits

- `652be2d` `docs(68-02): add canonical upgrade path guide`
- `a824775` `test(68-02): lock upgrade path doc contracts`

## Decisions Made

- `guides/upgrade-path.md` is the sole compatibility/deprecation authority for the optional operator surface.
- Surface-mounted support claims remain limited to the declared ranges in `mix.exs`, the current `mix.lock` resolution, and the current CI jobs in `.github/workflows/ci.yml`.
- `guides/operator-surface.md` remains a usage guide, not a lifecycle policy guide.

## Deviations from Plan

None - plan tasks executed as written.

## Execution Notes

- Shared planning artifacts such as `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` were intentionally not modified because the workspace ownership constraints for this run explicitly forbade changing them.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/68-lifecycle-ergonomics/68-02-SUMMARY.md`.
- Commit `652be2d` exists in git history.
- Commit `a824775` exists in git history.
