---
phase: 198-green-bringup
plan: 50
subsystem: e2e
tags: [playwright, accessibility, focus, evidence, tdd]
requires:
  - phase: 198-45
    provides: named row-history accessibility scenario and historical non-reproduction record
provides:
  - fail-closed RED-then-GREEN proof for the protected focus assertion
  - structured active-element, geometry, viewport, scroll, repeat, project, and trace evidence
  - fast source and argv integrity contract for row-history focus evidence
affects: [198-security-reaudit, GREEN-06]
tech-stack:
  added: []
  patterns: [scenario-local negative control, JSON Playwright attachment, fixture-captured argv]
key-files:
  created:
    - bin/verify-row-history-focus-red-control
    - test/threadline/row_history_focus_evidence_contract_test.exs
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - .planning/audits/198-row-history-focus-regression.md
key-decisions:
  - "Treat the opt-in obscurer as proof of current assertion sensitivity, not proof of the historical failure's cause."
  - "Keep the red-control environment read inside the single named scenario and reject unknown non-empty values explicitly."
  - "Persist synthetic DOM identifiers and geometry only; exclude field values, cookies, headers, credentials, and environment data."
requirements-completed: [GREEN-06]
coverage:
  - id: D1
    description: "The named row-history assertion fails under a deterministic obscurer and passes cleanly under identical bounded argv."
    requirement: GREEN-06
    verification:
      - kind: e2e
        ref: "bash bin/verify-row-history-focus-red-control: expected RED at expectNonObscuredFocused, then clean GREEN"
        status: pass
      - kind: test
        ref: "row_history_focus_evidence_contract_test.exs: 5 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 15 min
completed: 2026-09-09
status: complete
actuals:
  tokens: 4171
  tasks: 2
  commits: 4
---

# Phase 198 Plan 50: Row-history Focus Evidence Summary

The row-history accessibility assertion now carries a deterministic fail-first control and a durable measured geometry record while preserving the honest conclusion that the historical failure's original cause is not established.

## Accomplishments

- Added an exact-value, test-only obscurer inside the named row-history scenario; cleanup is unconditional and asserts that no marker remains.
- Added a defensive prover that requires the protected non-obscured assertion to fail before running byte-identical clean argv.
- Attached project, viewport, attempt identity, active element, dialog/input rectangles, scroll offsets, visibility, and trace-path metadata as JSON.
- Added a fast ExUnit contract that protects scenario scope, browser bounds, argv ordering, semantic/focus/overflow assertions, masking prohibitions, and durable audit results.
- Recorded a measured 393×727 mobile run, 10/10 mobile repeats, and a green desktop adjacency run without product, screenshot, workflow, or Playwright-config changes.

## Task Commits

1. **Task 1 RED: Define the fail-first contract** — `6a2dd1b1`
2. **Task 1 GREEN: Implement the scoped red control and prover** — `ca9e0ec4`
3. **Task 2 RED: Define the structured evidence contract** — `73509ebe`
4. **Task 2 GREEN: Attach and persist measured focus evidence** — `5831e9b5`

## Verification

- `mix test test/threadline/row_history_focus_evidence_contract_test.exs --only red_control_contract` — 3 tests, 0 failures.
- `mix test test/threadline/row_history_focus_evidence_contract_test.exs` — 5 tests, 0 failures.
- `bash bin/verify-row-history-focus-red-control` — known-bad failed at `expectNonObscuredFocused`; identical clean argv passed.
- Mobile named scenario with `--repeat-each=10` — 10/10 passed in 8.9 seconds.
- Desktop row-history adjacency selection — 1/1 passed in 1.0 seconds.
- Supplemental JSON-reporter run — passed and exposed the final structured attachment with the expected active element and geometry.
- TypeScript `--noEmit`, `bash -n`, and `git diff --check` — passed.

## TDD Gate Compliance

- RED commits `6a2dd1b1` and `73509ebe` each demonstrated the intended missing behavior before implementation.
- GREEN commits `ca9e0ec4` and `5831e9b5` follow their corresponding RED commits and pass the complete contract.
- No refactor commit was needed.

## Deviations from Plan

None in Plan 50 implementation. The first real browser attempt exposed the already-completed Plan 48 preflight's non-portable lowercase `Location` handling on macOS; Plan 48 repaired its owned files in `cf5878b2`, after which every Plan 50 browser gate passed. Plan 50 did not modify that external scope.

## Issues Encountered

- The initial browser proof stopped before Playwright because macOS `awk` ignored `IGNORECASE=1` in the Plan 48 preflight. The owning plan replaced that parser with portable normalization and its 6/6 contract passed before this plan reran.
- Hex printed an expired-session warning while restoring unchanged public dependencies, but restoration and all browser gates completed successfully; no authentication-gated resource was required.
- The dependency restore reported existing upstream advisories. No dependency graph or lockfile changed in this plan.

## Known Stubs

None.

## Threat Review

- T-198-45-01: closed by the structured measured attachment and exact-command audit.
- T-198-45-02: closed by the protected-assertion RED control and prohibition scan.
- T-198-50-01: mitigated by exact-value, named-test-local flag handling and unconditional cleanup.
- T-198-50-02: mitigated by one focused scenario, one browser project per proof, existing timeouts, and one worker.
- T-198-50-03: mitigated by recording synthetic geometry and identifiers only.
- No unplanned endpoint, authentication, file-access, schema, or dependency trust boundary was introduced.

## Self-Check: PASSED

- All four declared artifacts exist.
- All four task commits are present in history.
- Fast, browser, TypeScript, shell, and diff verification passed.
