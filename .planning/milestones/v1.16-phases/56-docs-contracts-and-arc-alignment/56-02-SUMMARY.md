---
phase: 56
plan: "56-02"
title: Doc-contract lockstep and milestone-arc pointer cleanup
date: 2026-05-05
files_changed:
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/exploration_routing_doc_contract_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/incident_playbook_doc_contract_test.exs
  - test/threadline/example_phoenix_readme_contract_test.exs
  - .planning/PROJECT.md
  - .planning/STATE.md
commits:
  - 7d236a7 test(56-02): lock bundled incident doc contracts
  - 7a17172 docs(56-02): point planning summaries at arc
verification:
  - command: mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1
    result: passed - 30 tests, 0 failures
  - command: mix verify.test
    result: passed - 270 tests, 0 failures (1 excluded)
  - command: rg -n "MILESTONE-ARC|next candidate|Operator-surface foundation|Adoption and policy hardening|Integration Breadth|Scale and Governance Depth" .planning/PROJECT.md .planning/STATE.md .planning/MILESTONE-ARC.md
    result: passed - PROJECT and STATE now defer ranked future-milestone naming to MILESTONE-ARC while the canonical arc file retains the strategic table
  - command: mix ci.all
    result: failed - blocked by pre-existing format drift in untouched files outside Phase 56 scope
---

# Phase 56 Plan 56-02 Summary

Locked the final Phase 56 wording with narrow ExUnit doc-contract assertions and updated the planning summaries so `.planning/MILESTONE-ARC.md` remains the only ranked forward-strategy source.

## What Changed

- Extended the existing focused doc-contract suites so README, domain-reference, quickstart, playbook, and example README drift when they lose the routing hierarchy, `incident_bundle/2` default path, or the host-owned auth/policy boundary.
- Kept the contract posture narrow: targeted `String.contains?/2` checks and section-scoped assertions instead of snapshots or whole-file locking.
- Rewrote the active forward-looking bullets in `.planning/PROJECT.md` into a pointer back to `.planning/MILESTONE-ARC.md`.
- Rolled `.planning/STATE.md` forward to Phase 56 complete and updated the current-focus / continuity wording so milestone closeout is the next workflow step.

## Verification

- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
  - Passed: `30 tests, 0 failures`
- `mix verify.test`
  - Passed: `270 tests, 0 failures (1 excluded)`
- `rg -n "MILESTONE-ARC|next candidate|Operator-surface foundation|Adoption and policy hardening|Integration Breadth|Scale and Governance Depth" .planning/PROJECT.md .planning/STATE.md .planning/MILESTONE-ARC.md`
  - Passed: only `.planning/MILESTONE-ARC.md` carries the ranked future arc
- `mix ci.all`
  - Failed: formatter check reports pre-existing drift in untouched files such as `test/support/getting_started_fixtures.ex`, `lib/threadline/investigation.ex`, and `test/threadline/stg_doc_contract_test.exs`

## Deviations

**[Rule 1 - Verification Environment] Pre-existing formatter drift outside Phase 56** — Found during: plan-level `mix ci.all` verification | Issue: `mix ci.all` fails on `mix format --check-formatted` for untouched files outside the Phase 56 write set | Fix: formatted the Phase 56-changed contract files and reran the focused suites plus `mix verify.test`; left unrelated repo-wide formatting cleanup out of scope for this docs/contracts phase | Files modified: none outside the Phase 56 plan set | Verification: `mix format --check-formatted` still reports only untouched files | Commit hash: n/a

**Total deviations:** 1 auto-contained verification deviation. **Impact:** Phase 56 changes are verified locally, but repo-wide `mix ci.all` remains blocked until the pre-existing formatting drift is cleaned up separately.
