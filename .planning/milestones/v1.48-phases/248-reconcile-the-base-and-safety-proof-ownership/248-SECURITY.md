---
phase: "248"
slug: "reconcile-the-base-and-safety-proof-ownership"
status: verified
threats_open: 0
threats_total: 18
threats_closed: 18
register_authored_at_plan_time: true
asvs_level: 1
block_on: high
created: "2026-11-11"
---

# Phase248 — Security

The authored four-plan register has18 plan-scoped rows, all closed at the configured ASVS1 grep-depth boundary; no open high/critical or below-threshold rows remain. The secure-phase short-circuit applies (authored register, level1, zero open), so no deeper auditor is spawned. This verifies stated controls; it does not claim a new general penetration audit or a complete CI toolchain matrix.

## Trust Boundaries

Preserved source to baseline; recorded GSD descriptor to actual isolated executor; host mount options to generated routes; callback results to HTTP/LiveView scoped reads; existing locked package graph to runtime; and actual run output to readiness claims. No new login/white-label/public API, publication authority or risk waiver is introduced.

## Threat Register

| Plan | Threat | Category | Component | Severity | Authored disposition | Verified mitigation/evidence | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 248-01 | T-248-01 | Tampering | Preserved source and disposition ledger | high | mitigate | Baseline validator15 checks and six rejecting controls;31 unchanged retained blobs/patch/status and three approved brand identities. See248-01-SUMMARY and248-CANDIDATE-BASELINE. | closed |
| 248-01 | T-248-02 | Spoofing | Executor cwd/fork | high | mitigate | Recorded GSD adapter descriptor, expected base, actual child cwd/root/HEAD and isolated ancestry; cleanup validated original manifest/base. See248-ISOLATION.json and248-WORKTREE-RECONCILIATION. | closed |
| 248-01 | T-248-03 | Repudiation | Baseline proof ledger | medium | mitigate | Source-bound summaries and receipts name commands, true exits, limits and pending live receipts; historical failures remain failures. | closed |
| 248-01 | T-248-SC | Tampering | Package installation | high | accept | No package installation in this slice; scope exclusion verified from plan/source, not acceptance of a runtime risk. | closed |
| 248-02 | T-248-04 | Elevation of privilege | Router compile guard | high | mitigate | Public macro requires usable unary callback or exact literal acknowledgement; current router and compile/runtime contracts pass in all nine root suites. | closed |
| 248-02 | T-248-05 | Information disclosure | Auth, export/theme plugs and scoped reads | high | mitigate | Existing auth/export/theme/query-scope contracts retain deny/error and tenant scope;85 focused/operator843 historical checks plus current root nine suites. | closed |
| 248-02 | T-248-06 | Tampering | Callback AST inspection | high | mitigate | Recognizable AST/arity is inspected without executing callback bodies; opaque expressions retain runtime fail-closed validation. Existing router tests cover both boundaries. | closed |
| 248-02 | T-248-07 | Information disclosure | CompileError | medium | mitigate | CompileError contract asserts actionable call-site file/line and full remedy option names; compiler/doc review and actual-snippet probes preserve no scoped payload exposure. | closed |
| 248-02 | T-248-SC | Tampering | Package installation | high | accept | No package installation in this slice; scope exclusion verified from plan/source, not acceptance of a runtime risk. | closed |
| 248-03 | T-248-08 | Tampering | Ecto/Phoenix.HTML/Bandit lock graph | high | mitigate | Mix-generated fixed Ecto/Phoenix.HTML/Bandit lock tuples with reviewed collateral/provenance; current receipt binds all three unchanged locks. | closed |
| 248-03 | T-248-09 | Information disclosure | Audit readiness evidence | high | mitigate | Complete all-lock audit outputs recorded zero findings;86 policy tests and current nine root suites preserve non-blocking finding visibility and failure classification. | closed |
| 248-03 | T-248-10 | Denial of service | Dependency compatibility | medium | mitigate | Approved dependency declarations/floors unchanged; source-bound compile/bench/example/canonical stages and tier contracts pass. Complete toolchain matrix is explicitly unclaimed. | closed |
| 248-03 | T-248-SC | Tampering | Package installation | high | mitigate | Existing locked package tooling only; Mix checksum/provenance review or pinned Node/committed npmci lock. No new package family, registry or install contract. | closed |
| 248-04 | T-248-11 | Tampering | verify-flake setup | high | mitigate | Existing verify-flake job has pinned setup-node and lockednpmci before its original repeat under the original gate; scoped regressions pass in current root suites. | closed |
| 248-04 | T-248-12 | Denial of service | Repeat suite resource use | medium | mitigate | Single explicit grant, source/tools/caches preflight,3300s limit plus60s grace; actual3045s terminal pass, ownedPG stopped after zero clients. No automatic repeat. | closed |
| 248-04 | T-248-13 | Repudiation | Suite classification/evidence | high | mitigate | Exact plain receipt retains source/log digest, true0 exits, nine headers/clean summaries and unchanged classifierpass; all prior failures and observer limitations retained. | closed |
| 248-04 | T-248-14 | Information disclosure | Integrated mounted example | high | mitigate | Existing real mounted example/browser canonical evidence and current HTTP/auth/scoped-read/root contracts; clipboard fix proved with retries disabled; browser/history limits disclosed. | closed |
| 248-04 | T-248-SC | Tampering | npm install | high | mitigate | Existing locked package tooling only; Mix checksum/provenance review or pinned Node/committed npmci lock. No new package family, registry or install contract. | closed |

The repeated `T-248-SC` labels are scoped by plan, not collapsed into one threat. In Plans01/02 the authored `accept` shorthand describes a no-install scope boundary; closure is supported by absence of that operation, not by a newly accepted runtime risk. All actual dependency/install changes in Plans03/04 use existing reviewed locked tooling and retain their dedicated controls.

## Accepted Risks Log

No accepted runtime risks. No unreviewed or indifferent response is treated as risk acceptance. Live issue/scheduled hosted receipts and REL-01 remain separately unclaimed.

## Audit Evidence and Limits

[Passing plain receipt](248-PLAIN-REPEAT-RECEIPT.json), [validation map](248-VALIDATION.md), [worktree reconciliation](248-WORKTREE-RECONCILIATION.md), four plan summaries, mount-fix proof and existing integration/canonical receipts support these closures. Current runtime/test/protected identities match the passing worktree; final code review includes the retained instruction-only delta. Earlier canonical browser retry and scoped later clipboard proof stay distinct; no fresh broad browser or full matrix result is inferred. Historical failed runs are not relabeled. No shared service was modified; owned PostgreSQL is stopped.

## Sign-Off

- [x] All18 plan-scoped threats have an evidence-backed disposition.
- [x] No accepted runtime risk was invented.
- [x] `threats_open: 0` at configured high threshold; all rows closed.
- [x] `status: verified` set; phase-goal verification still follows.

Approval: security register verified2026-11-11 at ASVS1.

## Security Audit 2026-11-11

| Metric | Count |
|---|---|
| Threats found | 18 |
| Closed | 18 |
| Open | 0 |
