---
phase: "248"
slug: "reconcile-the-base-and-safety-proof-ownership"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-10"
validated: "2026-11-11"
---

# Phase248 — Validation Strategy

Every requirement has automated coverage at its actual boundary. No missing test boundary was found, so the validate-phase no-gap branch updates this existing strategy without generating tests or spawning a gap-filling auditor. This is coverage validation, not the final phase-goal verdict.

## Test Infrastructure

Existing ExUnit, real Playwright CLI discovery, workflow/lock/doc contracts, compiled host-router probes and the phase-local provenance validator. Use `mix verify.test`, `mix verify.format`, `mix verify.credo`, `mix verify.deps_audit`, and the original `mix verify.flake` / `mix ci.all` entrypoints as scoped in receipts. No new framework or dependency was introduced; no parallel database suites or manual UAT are required.

## Per-Task Verification Map

| Task | Requirement | Observable boundary | Automated evidence | Status |
| --- | --- | --- | --- | --- |
| 248-01-01 | ADM-01 | Actual executor/fork/cwd, retained tracer and approved brand provenance | Recorded isolation proof and baseline validator tracer; Plan01 summary | COVERED |
| 248-01-02 | ADM-01 | 31-row exact retained inventory and six rejecting negative controls | `verify-candidate-baseline.py --check-inventory --self-test`:15 checks pass after assembly | COVERED |
| 248-02-01 | ADM-02 | Compile-time explicit auth policy, actionable diagnostic, runtime deny and scope | Existing router/auth/export/theme/scoped-read contracts;85 focused checks and current nine root suites | COVERED |
| 248-02-02 | ADM-02 | 17 fixture mounts preserve real capability and query-scope behavior | Existing operator-surface suite:843/0 recorded; same runtime/test sources included in current nine root suites | COVERED |
| 248-02-03 | ADM-02 | Truthful migration guides, actual inherited host pipelines and intentional public opt-out | Guide contracts and corrected actual-snippet compiler probe; current root documentation contracts pass | COVERED |
| 248-03-01 | ADM-03 | Compatible fixed root lock, complete advisory findings and compile boundary | Mix-generated lock/provenance proof, root compile and all-lock audit; unchanged locks in passing receipt | COVERED |
| 248-03-02 | ADM-03 | Fixed bench/example locks and unchanged supported-tier policy | Three-lock audit0 with86 audit-policy tests; canonical bench/example source-bound stages and current root contracts | COVERED |
| 248-04-01 | ADM-04 | Actual missing-CLI reproduction, locked setup and same real discovery boundary | Browser-journey discovery contract plus scoped workflow setup regressions; current root suites use prepared locked CLI | COVERED |
| 248-04-02 | ADM-04 | Original nine-run/scale/timeout/classifier and genuine zero exits | 248-PLAIN-REPEAT-RECEIPT.json:9 headers/9 clean summaries, suite/capture/wrapper0,classifierpass,3045s within3300 | COVERED |
| 248-04-03 | ADM-01–04 | Trustworthy assembled proof, regression review and preservation | Current plain root repeat; historical canonical stages with explicit browser retry limits, scoped clipboard/control proofs, reviewed diagnostics and15 inventory controls | COVERED |

## Evidence Limits

The [plain repeat](248-PLAIN-REPEAT-RECEIPT.json) passed nine suites on its exact source with unchanged assertions, scale5, max-cases36, configured exclusions and55m+60s bounds. The [reconciliation record](248-WORKTREE-RECONCILIATION.md) distinguishes the parent's later instruction-only safeguard from tested runtime/test identities.

The earlier canonical alias exit0 is source-bound history: root3400/0, example132/0, Dialyzer0 and live slice17/0; its browser lane retains417 first passes, one retry-passed clipboard case and56 configured skips. The later clipboard test fix has separate retries-disabled focused proof. No fresh full canonical/browser or complete min/current/latest toolchain matrix is claimed. Source-equivalent stages are reused with those bounds; the final goal verifier assesses acceptance.

All failed repeats remain failures. Intermediate `eaedaf5e` negative-fixture coverage was vacuous and is invalid as complete coverage or speedup evidence; the explicit premise correction and current nine-run result supersede it. No sole cause or permanent flake-elimination claim is made.

The three resolved inventory edges map to248-01-02; three resolved diagnostic considerations map to248-02-01. Unclassified ADM02/03/04 edge rows remain flagged research assumptions alongside substantive tests. The descriptor-less transparency prohibition remains flagged-unverified as a policy limitation; actual recorded executor binding is verified. Local proof does not close live issues, scheduled hosted receipts or REL-01, and grants no external action authority.

## Wave0 Requirements

Existing infrastructure and locked tools were prepared before the bounded attempt. No new Wave0 tests are missing. PostgreSQL15.17 was task-owned, stopped after zero clients, and shared services were untouched.

## Manual-Only Verifications

None for local coverage. External push/hosted CI, live issue closure and publication retain their separate authority boundaries; no maintainer retesting is requested.

## Validation Sign-Off

- [x] All ten tasks map to runnable automated verification and observable failure signals.
- [x] Required negative controls, actual discovery and explicit authorization/scoping behavior are exercised.
- [x] The required plain nine-run proof is current and passing.
- [x] Historical integration, browser and toolchain limits are preserved without relabeling.
- [x] No test gap or manual-only local acceptance task is hidden.

Approval: coverage validated2026-11-11; phase goal verification follows. Source-review recheck of the retained instruction-only delta is part of the required post-gates.

## Validation Audit 2026-11-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
