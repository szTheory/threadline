---
phase: 70
plan: "70-01"
subsystem: docs
tags:
  - readme
  - onboarding
  - operator-surface
  - doc-contract
provides:
  - COMPAT-03
  - ADOPT-09
key_files:
  created:
    - .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-01-SUMMARY.md
  modified:
    - README.md
    - guides/getting-started-saas.md
    - guides/operator-surface.md
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
decisions:
  - Keep generic install docs on the root `threadline ~> 0.4` posture and push exact proof pins back to `guides/upgrade-path.md`.
  - Preserve one canonical surface-first onboarding path while attaching capture-only parity commands to the same operator steps.
  - Keep the operator-surface guide scoped to mount/auth/screens instead of turning it into a proof-pin ledger.
---

# Phase 70 Plan 70-01 Summary

Refreshed the generic install and first-hour docs so they now teach the current
root package posture, defer exact proof pins to the lane docs, and keep
capture-only parity visible at the same operator steps as the surface-first
story.

## Completed Tasks

| Task | Outcome |
| --- | --- |
| 1 | Updated `README.md`, `guides/getting-started-saas.md`, and `guides/operator-surface.md` from stale `~> 0.3` wording to the current `~> 0.4` root posture while keeping exact Phoenix/Sigra proof pins out of the generic docs. |
| 2 | Added explicit parity reminders for `mix threadline.incident`, `mix threadline.health.coverage`, and `mix threadline.policy.show` in the first-hour and operator-surface docs. |
| 3 | Tightened the focused contract tests and the release artifact README assertion so the refreshed package posture cannot silently drift back. |

## Verification

- `rg -n 'mix threadline\.(incident|health\.coverage|policy\.show)|guides/upgrade-path\.md|guides/integrations/sigra\.md' README.md guides/getting-started-saas.md guides/operator-surface.md`
  Result: matched the expected parity commands and lane-guide pointers across the generic doc surfaces.
- `mix test test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs --max-failures 1`
  Result: passed.

## Deviations from Plan

### Auto-fixed Issues

**1. Release artifact README contract still expected `~> 0.3`**
- **Found during:** final `mix ci.all`
- **Fix:** updated `test/threadline/release_artifact_contract_test.exs` to lock the current `~> 0.4` README installer snippet.
- **Files modified:** `test/threadline/release_artifact_contract_test.exs`

## Known Stubs

None.

## Threat Flags

None.

## Self-Check

PASSED
