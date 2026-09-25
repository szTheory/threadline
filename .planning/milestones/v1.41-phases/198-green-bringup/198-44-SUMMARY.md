---
phase: 198-green-bringup
plan: 44
subsystem: verification
tags: [policy, attestations, ci, automation]
requires: []
provides: [machine-readable Phase 198 evidence policy, exact-SHA main-CI observer, post-repair attestation contracts]
affects: [198-46]
tech-stack: {added: [], patterns: [strict JSON policy, explicit non-success states]}
key-files:
  created: [.planning/audits/198-automation-policy.json, bin/verify-phase198-evidence, bin/observe-main-ci, test/threadline/phase198_automation_policy_test.exs, test/threadline/main_ci_observer_contract_test.exs]
  modified: [test/threadline/ci_attestation_contract_test.exs, test/threadline/phase198_nyquist_contract_test.exs]
key-decisions:
  - "Evaluator correctness is separate from underlying requirement success."
  - "Capped and unbounded populations report not_comparable; prediction target and composition are scored separately."
requirements-completed: [GREEN-03, GREEN-04, GREEN-06, GREEN-07]
coverage:
  - id: D1
    description: "Sizing, differential diagnosis, search_path arithmetic, timeout budgets, populations, and prediction outcomes are evaluated from versioned data."
    verification:
      - kind: integration
        ref: "mix test test/threadline/phase198_automation_policy_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact-SHA main CI reports not_observed, incomplete, failure, or success without substituting an older run."
    requirement: GREEN-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/main_ci_observer_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Committed post-repair attestations prove required test, browser, capture, and aggregate jobs green."
    requirement: GREEN-04
    verification:
      - kind: unit
        ref: "mix test test/threadline/ci_attestation_contract_test.exs test/threadline/phase198_nyquist_contract_test.exs"
        status: pass
    human_judgment: false
duration: 6 min
completed: 2026-09-08
status: complete
---

# Phase 198 Plan 44: Evidence automation Summary

Phase 198's remaining evidence judgments now resolve through a strict policy evaluator, a read-only exact-SHA main-run observer, and attestation contracts.

## Accomplishments

- Encoded formerly subjective derivations and their edge behavior in versioned JSON.
- Added explicit main-CI states without remote mutation or green substitution.
- Bound the post-repair green lanes to committed attestations.

## Deviations from Plan

- Requirements prose is preserved until Plan 46 performs the coordinated metadata cutover.

## Verification

- 19 focused ExUnit tests passed.
- `bin/verify-phase198-evidence --format json` reported zero failed policy checks.

## Self-Check: PASSED

Ready for 198-46.
