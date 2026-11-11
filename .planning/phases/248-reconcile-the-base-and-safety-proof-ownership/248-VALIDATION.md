---
phase: "248"
slug: "reconcile-the-base-and-safety-proof-ownership"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-10"
---

# Phase 248 — Validation Strategy

## Current diagnostic outcome and narrow correction — 2026-11-11

Plan 248-04 remains halted and ADM-04 incomplete. The approved instrumented nine-run alias failed its first suite on `8bdb4ac0`: 32 properties, 3,400 tests, one formatter timeout, three exclusions; 727.45 seconds wall, suite exit 2 / capture 0 / wrapper 1, classifier `broken`. No later suites ran. The one-invocation grant is consumed. [Exact diagnostic receipt](248-INSTRUMENTED-DIAGNOSTIC-RECEIPT.json).

Current source `ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb` changes only the synthetic overlap input to the exact existing representative, preserving production formatter configs/globs, all 12 representatives, exact overlap/uncovered assertions, async settings and timeouts. A post-run check showed the old recursive fixture glob returned 107 files, including 97 under dependencies/build output, while the literal returned the one required representative. This is scope evidence, not a latency or exclusive-cause claim. Focused test, format and strict Credo pass; two private control mutants fail as intended; independent 33-file recheck has no active findings (32 exact reads reused, one changed file fully read). [Correction and bounded proof](248-OVERLAP-PROOF.md), [review](248-OVERLAP-REVIEW.md).

No current full-root or plain nine-run pass is claimed. During the timeout, sampled file-server counters kept advancing with changing operations and queued requests; the observer had material variable overhead, so no single continuous stall, sole cause or reliable speedup is established. PostgreSQL is stopped after zero clients; shared services untouched. The next concrete decision is one plain acceptance invocation with the same nine-run / scale 5 / max-cases 36 / 55-minute plus 60-second limits; authorization is false. [Current readiness](248-OVERLAP-READINESS.md). Formal post-gates, acceptance and phases 249–253 remain pending; no external authority inferred.

## Prior source-specific evidence (current status superseded)

## Current correction and proof boundary — 2026-11-11

Plan 248-04 remains halted; ADM-04 and phase acceptance remain incomplete. Current reviewed source is `9b695ca25b41be882902ddfb06716141e5a462db`. The latest plain repeat completed three clean suites, then five file-operation timeouts in iteration 4; its one-invocation user grant is consumed. No further full repeat is authorized.

The intermediate pressure refactor accidentally passed nine benign fixture bodies without the required tagged-source wrapper. Those assertions bypassed the detector. That defect and the earlier clean review are explicitly superseded: current source restores the wrapper and asserts the premise for every fixture. The intentional raw direct controls retain fresh default inventories. Current focused checks, formatting, strict Credo and one ordinary full-root observation pass. A private mutant removing the wrapper fails at the new premise assertion as expected; it is not a current-source failure. The independent 33-file review has no active findings (32 exact-identity reads reused, one changed file fully read). See [current proof](248-FILE-PRESSURE-PROOF.md) and [superseding review](248-NEGATIVE-PREMISE-REVIEW.md).

The corrected ordinary root run passed 32 properties / 3,400 tests / 0 failures / 3 exclusions in 332.17 seconds; its benign fixture loop took 34.60 seconds. The earlier 234.24-second intermediate run had vacuous negative controls and is invalid as complete coverage. The corrected observation does not establish a reliable speedup, an exclusive timeout cause or a passing nine-run gate. Assertions, fixture bodies, exclusions, scale, concurrency and timeouts are preserved.

Task-owned PostgreSQL 15.17 is stopped after zero remaining clients; shared services were untouched. A checked private observer and one bounded diagnostic proposal are prepared, with authorization false. An instrumented pass would be diagnostic only; the required plain repeat remains outstanding. [Current readiness and next decision](248-PRESSURE-READINESS.md) supersedes older readiness snapshots. Formal post-gates and phases 249–253 remain pending. No push, merge, publication or package-version authority is inferred.

## Earlier source-specific record (superseded as current status)

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
| 248-04-02 | ADM-04 | Nine-run scale5 proof, true exit/elapsed/capture/classifier | `MIX_ENV=test THREADLINE_PROPERTY_SCALE=5 timeout --signal=TERM --kill-after=60s 55m mix verify.flake`; unchanged classifier and 9 clean summaries/headers | BLOCKED — latest user-approved invocation on `10442d31` consumed; wrapper 1, suite 2, capture 0, 1,582.26 seconds; three clean then five file-server timeouts in iteration 4 at seed `579775`, classifier `flaky`; no passing receipt or further repeat authority |
| 248-04-03 | ADM-01–04 | Source-bound integration, affected proof, reviews and preservation | Historical `mix ci.all` plus focused file-pressure checks, one ordinary root invocation and inventory validator | PARTIAL — the prior isolated PG15 alias on `ab65c014` remains 417 first-pass / 1 retry-pass / 56 configured skips; clipboard evidence is separately scoped. The three file-pressure contracts pass 38/0, strict format/Credo pass, one root invocation on `eaedaf5e` passed 3,400/0/3 in 234.24 seconds, and the candidate inventory validator passed 15 checks. This is not a nine-run receipt; the independent source review is pending. |

Each PASS above is backed by its plan summary, final assembled check, or this plan's detailed proof ledger. All failed full-repeat receipts remain failures; the latest is five clean runs followed by a public-reference test timeout in iteration 6, and no receipt is converted into acceptance. Four serial waves contain 2, 3, 2 and 3 tasks respectively. The 17-file fixture task is a justified mount-option-only fan-out within the requested four-plan structure.

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

**Approval:** the focused file-pressure contracts, format, strict Credo and one ordinary root invocation pass on the current committed source. A prior root invocation's Git metadata permission failure remains historical; this scoped run used the required access. The historical canonical alias retains one browser retry. Nine-run acceptance remains blocked and the latest repeat grant is consumed.

## Current proof reconciliation

The bounded public-surface and file-pressure changes preserve their subjects, owners, exceptions, assertions and negative controls; the heading-15 guide probe also confirms inherited pipelines without product/router changes. Current file-pressure checks and limits are in [248-FILE-PRESSURE-PROOF.md](248-FILE-PRESSURE-PROOF.md). The parent owns PostgreSQL lifecycle and independent source review. Nyquist compliance and phase acceptance remain false until the required nine-run proof exists; no routine human verification is requested.
