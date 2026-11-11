---
phase: "248"
slug: "reconcile-the-base-and-safety-proof-ownership"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-10"
---

# Phase 248 — Validation Strategy

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing ExUnit, real Playwright discovery and shell workflow contracts |
| Config | `mix.exs`, `test/test_helper.exs`, existing E2E package lock and workflows |
| Quick mount check | `mix test test/threadline/operator_surface/router_test.exs` |
| Quick reported-failure check | `mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664` |
| Advisory gate | `mix verify.deps_audit` (inspect all findings, not only exit) |
| Integrated gate | `mix ci.all` |
| Affected repeat proof | One `mix verify.flake` after the setup repair; no blind retries |
| Runtime | Measure during execution; no invented duration or shortened required gate |

## Sampling Rate

Run the smallest directly affected check after each code task. Run integrated checks after fixes are assembled, reusing same-source evidence rather than repeating expensive suites for documentation-only bookkeeping. Diagnose a failure before any bounded retest. Do not run parallel suites against a shared test database. No watch commands.

## Per-Task Verification Map

| Task | Requirement | Secure behavior or proof | Automated command / assertion | Status |
| --- | --- | --- | --- | --- |
| 248-01-01 | ADM-01 | Actual GSD fork/descriptor/cwd, one retained edit and three brand identities | `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-tracer` | Pending execution; validator created by task |
| 248-01-02 | ADM-01 | Exactly 31 sorted unique dispositions, full path-set/hash equality, unchanged preserved patch; malformed inventory negative controls | `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check --self-test` | Pending execution |
| 248-02-01 | ADM-02 | Compile matrix, synchronous diagnostic/file/line/full option names, valid routes, runtime grant/deny/HTTP/scope | `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/query/scope_fail_closed_test.exs` | Pending execution |
| 248-02-02 | ADM-02 | Explicit auth intent at all 17 affected fixture files; existing behavior retained | `mix test test/threadline/operator_surface` | Pending execution |
| 248-02-03 | ADM-02 | Truthful migration guidance and exact deliberate public acknowledgement | `mix test test/threadline/operator_surface_doc_contract_test.exs` | Pending execution |
| 248-03-01 | ADM-03 | Compatible root fixes; inspect root findings and name remaining bench/example findings | `mix verify.deps_audit`; `mix compile --warnings-as-errors` | Pending execution; zero exit alone insufficient |
| 248-03-02 | ADM-03 | Patched bench/example; zero reported findings across all three locks and unchanged tier contracts | `mix verify.deps_audit`; `mix test test/threadline/deps_audit_contract_test.exs test/threadline/deps_audit_gate_test.exs` | Pending execution; inspect complete output |
| 248-04-01 | ADM-04 | Single known pre-setup missing-CLI failure, then same seeded real-discovery pass; job-scoped pinned setup/order proof | `mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664` before/after setup; `mix test test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/flake_classifier_contract_test.exs test/threadline/property_scale_contract_test.exs` | Pending execution; expected initial failure is not acceptance |
| 248-04-02 | ADM-04 | One unchanged bounded nine-run repeat proof; true exit/elapsed/log and classifier | Run task 248-04-02's complete self-contained `bash -c` verification once: captures `THREADLINE_PROPERTY_SCALE=5 timeout --signal=TERM --kill-after=60s 55m mix verify.flake` into a fresh temporary evidence directory, records true suite/tee status and elapsed, invokes unchanged classifier with those captured values, asserts literal `pass` and nine completed clean summaries plus nine suite headers | Pending execution; missing evidence, non-pass output, failed capture/run, over-budget elapsed or incomplete nine-run evidence fail closed; no inherited repeat variables or automatic repeat retry |
| 248-04-03 | ADM-01–04 | Canonical current-candidate integration, independent review and preserved baseline | `mix ci.all`; `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test` | Pending execution and independent review |

Every command's immediate `fails_when` predicate lives in its task. No tests were run during planning and no green result is claimed. Four serial waves contain 2, 3, 2 and 3 tasks respectively. The 17-file fixture task is a justified mount-option-only fan-out within the requested four-plan structure.

The three resolved inventory edges map to 248-01-02; the three resolved diagnostic considerations map to 248-02-01. The ADM-02/03/04 unclassified edge rows remain flagged assumptions alongside substantive compile/runtime, all-lock-audit and suite/setup tests. The descriptor-less transparency prohibition is flagged-unverified; local results never imply hosted CI, live issue closure or publication. Original probe artifacts are preserved.

## Wave 0 Requirements

Existing test infrastructure covers the phase. Install existing locked Mix and E2E dependencies in isolated executor environments. Confirm PostgreSQL availability and avoid modifying unrelated services/processes. No new framework, CI job or dependency is required.

## Manual-Only Verifications

None for local acceptance. Actual push/hosted CI, live issue closure and publication retain their authority boundaries; disclose unavailable live receipts rather than asking for human retesting.

## Validation Sign-Off

- [ ] All tasks have runnable automated verification and stated failure signals.
- [ ] Required negative paths and dependency findings are observed at their real boundary.
- [ ] Integrated checks and the affected repeat proof have current candidate evidence.
- [ ] Independent review findings are resolved or explicitly blocking.
- [ ] No unverified item has been recorded as passing.

**Approval:** pending execution and verification
