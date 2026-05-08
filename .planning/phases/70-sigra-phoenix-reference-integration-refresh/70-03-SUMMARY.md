---
phase: 70
plan: "70-03"
subsystem: docs
tags:
  - example-app
  - sigra-reference
  - parity
  - doc-contract
provides:
  - ADOPT-09
  - COMPAT-03
  - INTEG-02
key_files:
  created:
    - .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-03-SUMMARY.md
  modified:
    - examples/threadline_phoenix/README.md
    - test/threadline/example_phoenix_readme_contract_test.exs
decisions:
  - Keep the example README as the runnable proof artifact behind the canonical guide, not a second onboarding owner.
  - Preserve exact Sigra/Phoenix proof pins in the example README while keeping `/audit` explicitly behind host-owned admin auth and `authorize_fn`.
  - Name the capture-only parity commands directly in the example proof path at the same incident/coverage/policy steps.
---

# Phase 70 Plan 70-03 Summary

Refreshed the Phoenix example README so it now reads as the narrow runnable
proof of the current `sigra-reference` lane, with explicit host-owned `/audit`
auth and direct parity reminders for capture-only operators.

## Completed Tasks

| Task | Outcome |
| --- | --- |
| 1 | Repositioned `examples/threadline_phoenix/README.md` as the proof artifact behind `guides/getting-started-saas.md` while preserving the exact current Sigra/Phoenix proof pins. |
| 2 | Added explicit parity reminders for `mix threadline.incident`, `mix threadline.health.coverage`, and `mix threadline.policy.show` to the example path. |
| 3 | Extended `test/threadline/example_phoenix_readme_contract_test.exs` so the example fails fast if it drops proof pins, auth-boundary wording, or parity reminders. |

## Verification

- `mix test test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
  Result: passed.
- `mix verify.example`
  Result: passed (`19 tests, 0 failures`).

## Deviations from Plan

None. The slice executed as planned.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check

PASSED
