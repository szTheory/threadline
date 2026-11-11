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
| 248-01-01 | ADM-01 | Actual GSD fork/descriptor/cwd, one retained edit and three brand identities | `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-tracer` | PASS — Plan 248-01 summary records the tracer check before commit; final inventory validation reconfirmed provenance |
| 248-01-02 | ADM-01 | Exactly 31 sorted unique dispositions, full path-set/hash equality, unchanged preserved patch; malformed inventory negative controls | `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check --self-test` | PASS — all six negative controls rejected; final `--check-inventory --self-test` passed 15 checks |
| 248-02-01 | ADM-02 | Compile matrix, synchronous diagnostic/file/line/full option names, valid routes, runtime grant/deny/HTTP/scope | `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/query/scope_fail_closed_test.exs` | PASS — Plan 248-02 and mount-fix summaries record 85-test focused coverage; assembled `mix ci.all` also passed |
| 248-02-02 | ADM-02 | Explicit auth intent at all 17 affected fixture files; existing behavior retained | `mix test test/threadline/operator_surface` | PASS — Plan 248-02 mount-fix summary records 843 tests with 0 failures; assembled `mix ci.all` passed |
| 248-02-03 | ADM-02 | Truthful migration guidance and exact deliberate public acknowledgement | `mix test test/threadline/operator_surface_doc_contract_test.exs` | PASS — Plan 248-02 records all three guide contracts passing; current walkthrough repair passed in the 16-test focused run |
| 248-03-01 | ADM-03 | Compatible root fixes; inspect root findings and name remaining bench/example findings | `mix verify.deps_audit`; `mix compile --warnings-as-errors` | PASS — Plan 248-03 records root compile and complete audit; final `mix ci.all` audited all three lockfiles with 0 non-blocking findings |
| 248-03-02 | ADM-03 | Patched bench/example; zero reported findings across all three locks and unchanged tier contracts | `mix verify.deps_audit`; `mix test test/threadline/deps_audit_contract_test.exs test/threadline/deps_audit_gate_test.exs` | PASS — Plan 248-03 records clean all-lock audit and 86 audit-policy tests with 0 failures; final `mix ci.all` audit also passed |
| 248-04-01 | ADM-04 | Single actual pre-setup missing-CLI ExUnit reproduction, locked setup repair, same seeded real-discovery pass and job-scoped workflow regression | `mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664` before/after setup; four existing workflow contracts; final focused browser and walkthrough contracts | PASS for setup repair and targeted contracts; first command invocation stopped before ExUnit until locked Mix deps were restored |
| 248-04-02 | ADM-04 | Nine-run scale5 proof, true exit/elapsed/capture/classifier | `MIX_ENV=test THREADLINE_PROPERTY_SCALE=5 timeout --signal=TERM --kill-after=60s 55m mix verify.flake`; unchanged classifier and9 clean summaries/headers | BLOCKED — user-approved invocation consumed; suite 2 / capture 0,2,611 seconds,six clean then iteration 7 timeout,classifier `flaky`; current test fixes do not replace the missing nine-run receipt |
| 248-04-03 | ADM-01–04 | Source-bound integration, affected proof, reviews and preservation | Actual `mix ci.all` receipt plus current scoped first-attempt browser/discovery checks and inventory validator | PARTIAL — isolated PG15 alias exit 0 on `ab65c014` retained with417 first-pass/1 retry-pass/56 configured skips; current clipboard test `ac260b47` passes6 first-attempt cases and41/11 across52 file instances with retries disabled; discovery9/0,validator15,independent reviews clean; no fresh full alias or nine-run acceptance claimed |

Each PASS above is backed by its plan summary, final assembled check, or this plan's detailed proof ledger. Both failed full-repeat receipts remain failures; the latest is six clean runs then a formatter timeout, and neither is converted into acceptance. Four serial waves contain 2, 3, 2 and 3 tasks respectively. The 17-file fixture task is a justified mount-option-only fan-out within the requested four-plan structure.

The three resolved inventory edges map to 248-01-02; the three resolved diagnostic considerations map to 248-02-01. The ADM-02/03/04 unclassified edge rows remain flagged assumptions alongside substantive compile/runtime, all-lock-audit and suite/setup tests. The descriptor-less transparency prohibition is flagged-unverified; local results never imply hosted CI, live issue closure or publication. Original probe artifacts are preserved.

## Wave 0 Requirements

Existing test infrastructure covers the phase. Install existing locked Mix and E2E dependencies in isolated executor environments. Confirm PostgreSQL availability and avoid modifying unrelated services/processes. No new framework, CI job or dependency is required.

## Manual-Only Verifications

None for local acceptance. Actual push/hosted CI, live issue closure and publication retain their authority boundaries; disclose unavailable live receipts rather than asking for human retesting.

## Validation Sign-Off

- [x] All tasks have runnable automated verification and stated failure signals.
- [x] Required negative paths and dependency findings are observed at their real boundary.
- [ ] Integrated checks and the affected repeat proof have current candidate evidence. The final canonical integration passed; the required nine-run repeat remains blocked.
- [x] Independent review findings are resolved or explicitly blocking; see [248-WORKFLOW-REVIEW.md](248-WORKFLOW-REVIEW.md).
- [x] No unverified item has been recorded as passing.

**Approval:** current scoped fixes and reviews pass; the actual canonical alias exit 0 retains its one browser retry. Nine-run acceptance remains blocked and requires a new one-invocation grant.

## Current proof reconciliation

The two new test-only fixes preserve production rendering, all assertions, concurrency, timeouts and global retries. Current affected proofs and limitations are in [248-POSTFIX-READINESS.md](248-POSTFIX-READINESS.md). The task-owned PostgreSQL15 instance is stopped. Nyquist compliance and phase acceptance remain false until the required nine-run proof exists; no routine human verification is requested.
