---
phase: 198-green-bringup
plan: 43
subsystem: ci
tags: [integration, playwright, github-actions, release]
requires: []
provides:
  - fixture-tested CI issue create-or-update behavior
  - hermetic Playwright maxFailures and trace-retention smoke
  - offline release environment and publish-boundary contract
affects: [198-46]
tech-stack:
  added: []
  patterns: [injectable CLI adapter, behavioral control-plane smoke]
key-files:
  created: [bin/upsert-ci-issue, bin/verify-playwright-fail-fast, test/threadline/ci_issue_upsert_contract_test.exs, test/threadline/playwright_fail_fast_contract_test.exs, test/threadline/release_control_plane_contract_test.exs]
  modified: [.github/workflows/browser-full.yml, .github/workflows/flake-detection.yml]
key-decisions:
  - "Nightly/live events are not verification prerequisites; workflow side effects delegate to fixture-testable scripts."
  - "The release reviewer remains an operational control while its wiring is verified offline."
requirements-completed: [GREEN-06, GREEN-07, GREEN-10, GREEN-11]
coverage:
  - id: D1
    description: "Browser-full and flake tracking create once and update the same issue thereafter."
    requirement: GREEN-11
    verification:
      - {kind: integration, ref: "mix test test/threadline/ci_issue_upsert_contract_test.exs", status: pass}
    human_judgment: false
  - id: D2
    description: "Playwright CI stops a seven-failure synthetic suite at five and retains five traces."
    requirement: GREEN-06
    verification:
      - {kind: e2e, ref: "bin/verify-playwright-fail-fast -> failures=5 skipped=2 traces=5", status: pass}
    human_judgment: false
  - id: D3
    description: "The only Hex publisher remains behind production-hex and gate-ci-green with one auth region."
    requirement: GREEN-10
    verification:
      - {kind: unit, ref: "mix test test/threadline/release_control_plane_contract_test.exs", status: pass}
    human_judgment: false
duration: 8 min
completed: 2026-09-08
status: complete
---

# Phase 198 Plan 43: Shift-left CI control paths Summary

CI issue deduplication, Playwright fail-fast/trace behavior, and release gating now have executable local evidence without waiting for nightly runs, duplicate failures, or a publish.

## Accomplishments

- Extracted one injection-safe issue upsert helper and wired both reporting workflows to it.
- Proved the production Playwright configuration stops at five failures and retains five traces.
- Locked the sole-publisher, production environment, CI dependency, and auth-region shape offline.

## Deviations from Plan

- The release workflow keeps its existing dry-run branch; verification asserts the two publish invocations live in the same gated step rather than assuming one literal command.

## Verification

- 16 focused ExUnit tests passed.
- `bin/verify-playwright-fail-fast` reported `failures=5 skipped=2 traces=5`.

## Self-Check: PASSED

Ready for 198-46.
