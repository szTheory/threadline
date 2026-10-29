---
phase: "247"
slug: "ci-critical-path-and-suite-lanes"
status: verified
threats_open: 2
threats_blocking: 0
threats_open_nonblocking: 2
block_on: high
asvs_level: 1
register_authored_at_plan_time: true
threats_total: 102
threats_closed: 100
created: "2026-10-26"
---

# Phase 247 — Security

The initial register was verified by the security auditor; subsequent gap threats, including Plans 20–21, were rechecked inline under the configured ASVS L1 short circuit against implementation, tests and receipts. Blocking threshold: high. The earlier 44 distinct threat IDs retain their recorded L1 dispositions. Plan 22 adds three IDs: T-247-45 is closed; T-247-46 and T-247-47 remain medium-severity open controls. The Plans 23–25 incremental audit adds six threats; T-247-48 was high and OPEN at Plan 25 closeout; offline repair 8c9f1541 closes it with raw-derived terminal verification and regression controls. All six additions are now closed on the scoped source evidence. This does not close performance acceptance: B4 CI-02 is INCOMPLETE and CI-03 MISS; full-five verification is not claimed.

## Trust Boundaries

| Boundary | Control |
|----------|---------|
| Local branch → protected main | Proven tree, green CI required, exact landing head |
| Browser matrix → receipt → required gate | Run-scoped artifacts, complete inventory reconciliation, unconditional receipt |
| Test process → diagnostic artifacts | Bounded process inspection, bounded output and retention |
| CI timing inputs → committed assignment weights | Validated numeric rows, deterministic ingestion and atomic output |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-247-01 | Tampering | land/v1.47-a1 content | high | mitigate | Tree proof `git diff --quiet 4b2c3f89^ HEAD -- . ':!.planning'` (or a full ci.all when main moved), plus `CI required` green on the PR before merge; no hand-resolved conflicts Source: 247-01-PLAN.md | closed |
| T-247-02 | Information disclosure | `.planning` sync published on main | medium | mitigate | `bin/verify-repo-hygiene` exit 0 on the land worktree before push (home-path shapes, username); stage exact paths only Source: 247-01-PLAN.md | closed |
| T-247-SC | Tampering | Install boundaries and new action pin | high (pin); low (no-install facets) | mitigate / accept | New download-artifact action uses full SHA + provenance comment; pin/runtime contracts and Dependabot remain. The no-new-install facets explicitly accepted in the plans are transcribed in AR-247-02. | closed |
| T-247-03 | Tampering | removal squash content | high | mitigate | Readiness check exit 0 + slice proof exit 0 + `CI required` green before merge; nine named picks only Source: 247-02-PLAN.md | closed |
| T-247-04 | Repudiation | archive tag target | medium | mitigate | Tag on `$SQUASH^` verified with `git merge-base --is-ancestor`; the message records both SHAs and the diffstat; never `--tags` Source: 247-02-PLAN.md | closed |
| T-247-05 | Tampering | slow-specs.ts Markdown output | medium | mitigate | Escape `\\|` and newlines, cap title length, `SAFE_NAME` for projects, numbers/names only in the summary; tested in slow-specs.test.ts Source: 247-03-PLAN.md | closed |
| T-247-06 | Denial of service | slow-specs.ts input | low | mitigate | `MAX_REPORT_BYTES` 20 MiB cap via `statSync` before reading; fail-soft warning Source: 247-03-PLAN.md | closed |
| T-247-07 | Elevation of privilege | bin/measure-main-ci gh boundary | high | mitigate | Closed symbolic `gh_read` operations, digit-validated ids, 40-hex `--since`, no write verbs; the fake-gh contract proves write verbs never reach gh Source: 247-03-PLAN.md | closed |
| T-247-08 | Information disclosure | HANG stack dump | medium | mitigate | Dump only `current_stacktrace`, `registered_name`, `status` and `message_queue_len`, never process dictionaries, messages or state; written to the partition log/stdout only, never the step summary (D-14) Source: 247-04-PLAN.md | closed |
| T-247-09 | Tampering | --ingest-weights input | low | mitigate | awk parses numeric ms and `test/...*_test.exs` paths only, rejects other rows, atomic mktemp+mv write; the committed result is still checked by the weights-inventory contract Source: 247-04-PLAN.md | closed |
| T-247-10 | Denial of service | process-group kill scope | high | mitigate | Signal only `-- -PGID` of groups this script created (PGID == the recorded subshell PID) plus a pre-kill descendant snapshot of that PGID; never `pkill -f` patterns or PGID 0; self-test sentinel proves no leftover and no collateral Source: 247-05-PLAN.md | closed |
| T-247-11 | Information disclosure | step summary / artifacts | medium | mitigate | Summary carries the row and ≤ 10 capped in-flight names only; stacks and log tails go to stdout/partition log; artifacts are 14-day, same-repo, scoped by lane + run_id Source: 247-05-PLAN.md | closed |
| T-247-12 | Tampering | artifact name collisions | low | mitigate | Names include `${{ matrix.lane }}` and `${{ github.run_id }}` (upload-artifact v4+ 409s on collisions) Source: 247-05-PLAN.md | closed |
| T-247-14 | Tampering | THREADLINE_TEST_SCOPE value | low | mitigate | Unknown values exit 2; the scope contract pins the env to min/latest rows only (rule `scope-rows`); the exactly-once check runs on the filtered set Source: 247-06-PLAN.md | closed |
| T-247-13 | Repudiation / coverage loss | `@moduletag :repo_contract` misuse | high | mitigate | D-09(a) invocation-shaped denylist plus the lib-module set computed at test time; D-09(b) every contract is classified; Node direction; the failure direction is safe (untagged runs everywhere); mutation controls prove each marker Source: 247-07-PLAN.md | closed |
| T-247-27 | Denial of service / coverage loss | min/latest Node removal | low | mitigate | Node steps are guarded only after the Node-direction rule proves every Node-executing test is tagged; browser_journey_evidence asserts the steps still exist with the current-only guard Source: 247-07-PLAN.md | closed |
| T-247-15 | Tampering | B1 content on main | high | mitigate | Milestone ci.all green + tree proof + `CI required` green on the PR (including the min lane) before merge Source: 247-08-PLAN.md | closed |
| T-247-16 | Denial of service | throwaway hang run | low | mitigate | Bounded by the 480 s watchdog and the 20-min job timeout; a single dispatch on a non-main branch; the branch is deleted after reading; never merged Source: 247-08-PLAN.md | closed |
| T-247-17 | Information disclosure | downloaded artifacts | low | accept | Same-repository scratch-artifact risk explicitly accepted in the plan; recorded in AR-247-01. Source: 247-08-PLAN.md | closed |
| T-247-18 | Tampering | receipt N-file inputs | medium | mitigate | `MAX_REPORT_BYTES` cap per file; unchanged `validateEvidence`/`uniqueIndex` (duplicates rejected, missing journeys fail); same-run artifacts only (enforced in 247-10) Source: 247-09-PLAN.md | closed |
| T-247-19 | Repudiation / coverage loss | browser-full-projects matrix resolution | high | mitigate | Fail closed (exit 1) on any unresolvable `${{ }}`, an include-only or empty list; contract fixtures prove each; a matrix list missing a project moves it to Browser-full rather than dropping it Source: 247-09-PLAN.md | closed |
| T-247-20 | Tampering | artifact poisoning / collisions | high | mitigate | Same-run downloads only (no `run-id`/`github-token` inputs); names scoped by project + run_id; the download patterns exclude the receipt artifact; the receipt re-validates with `uniqueIndex` + inventory Source: 247-10-PLAN.md | closed |
| T-247-21 | Elevation of privilege | token scope of the fan-in | medium | mitigate | Workflow stays `permissions: contents: read`; if same-run download needs `actions: read` (RESEARCH A1), it is added job-scoped in 247-13 together with a `@job_read_grants` entry in ci_token_permissions_contract_test, never workflow-wide Source: 247-10-PLAN.md | closed |
| T-247-23 | Tampering | Markdown summary injection from test titles | low | mitigate | slow-specs escaping from 247-03 applies per leg Source: 247-10-PLAN.md | closed |
| T-247-22 | Elevation of privilege | skipped fan-in reads green | high | mitigate | Fan-in has no `if:`; `ci-required` keeps `if: always()` + alls-green with no `allowed-skips`, so a skipped receipt fails; contract rule `receipt-unconditional` with a mutation control Source: 247-11-PLAN.md | closed |
| T-247-28 | Repudiation / coverage loss | matrix project list drift | medium | mitigate | Rule `matrix-projects` pins the matrix to the inventory `votingProjects`; rule `leg-artifact-name` prevents cross-leg artifact overwrite; both mutation-controlled Source: 247-11-PLAN.md | closed |
| T-247-24 | Tampering | weights from artifacts | low | mitigate | Artifacts are same-repo, downloaded read-only by run id; ingest parses numbers/paths only; the inventory contract validates the result; a bad weight only skews balance (every file still runs exactly once) Source: 247-12-PLAN.md | closed |
| T-247-25 | Tampering | B2 on main / required gate integrity | high | mitigate | Milestone ci.all + tree proof + PR run green on both legs, the receipt and `CI required`; `bin/verify-branch-protection` read-only after merge confirms the single required context Source: 247-13-PLAN.md | closed |
| T-247-26 | Repudiation | measurement honesty | medium | mitigate | Attempt-1 endpoint only; cancelled/failed runs listed as excluded; thresholds fixed; miss path documented; read-only script with fake-gh contract (247-03) Source: 247-13-PLAN.md | closed |

| T-247-29 | Tampering | `--ingest-weights` artifact input | medium | mitigate | API provenance for three B2 main attempt-1 successes; validate_lane_timings checks three distinct complete four-partition runs and exact inventories; both Bash corruption/interruption self-tests green; 206/206/269 committed rows. | closed |
| T-247-30 | Tampering | `--output` and lane selection | medium | mitigate | lane_weights accepts only unset/current/min/latest; strict output matches the three allowed paths; missing/unknown routes fail before compile; fake-mix assignment equality and current-for-latest mutation verified. | closed |
| T-247-31 | Denial of service | assignment balance and watchdog | medium | mitigate | N=4, colocation, verify_assignment, 480 s watchdog and warning-only ratio remain; original hang/failure self-tests green and first three main runs pass all Build and test jobs. Numeric CI-03 MISS remains separate from DoS mitigation. | closed |
| T-247-32 | Tampering | candidate and required CI topology | high | mitigate | Exact land9fa28fad ci.all exit0, PR96 run40432374330 17/17 green, expected-head guarded squash89add23e, non-planning tree equality and post-merge sole CI required@15368 readback. | closed |
| T-247-33 | Repudiation | ratio/median measurement | medium | mitigate | Captured canonical attempt-1 JSON has five first qualifying successes, failed40435657557 exclusion and fixed nine ratios; Plan15 live evidence gate confirms PASS/met for CI-02 and MISS/unmet for CI-03 in both evidence files. | closed |
| T-247-34 | Denial of service | repeated dispatch | low | mitigate | Six chronological distinct runs were serial, each dispatched after its predecessor completed; five successes plus one explicit failure, every run_attempt1. No workflow/job rerun; dispatch stopped at five qualifying successes. | closed |

## Historical verification evidence before gap execution

- Fresh validation: 212 ExUnit contracts and 39 Node tests passed; partition watchdog self-tests passed on Bash 5 and Bash 3.2 with process inspection available.
- A1 PR run 40354035917; A2 40375604860; B1 40392212575; B2 40412545694: success, with landing tree equality and corrected A2 slice proof documented in 247-LANDING.md.
- Throwaway hang-shape run 40387548421 failed as designed within the partition budget; remote scratch branch absent.
- Read-only branch-protection check: CI required@15368 is the sole required context.
- T-247-21 provisional receipt-permission concern closed by successful live receipt execution without additional permissions.

## Gap execution L1 verification (2026-10-27)

The six additional plan-authored threats were checked against actual source, mutation/self-test results, exact-head local CI and live PR/main receipts above. The register was authored in the plans, every mitigation is found and ASVS level is 1; the workflow therefore permits the no-open-threat short circuit without a deeper auditor dispatch. Existing accepted risks are unchanged. Five qualifying main runs each have 17 successful jobs, receipt31 and all required timing artifacts; one failed attempt is explicitly excluded. CI-03 remains a performance MISS, not an accepted security exception.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-247-01 | T-247-17 | Same-repository throwaway-run diagnostics may appear in scratch artifacts; this low-severity exposure was explicitly assigned accept in the approved plan. No new acceptance decision is made here. | Approved 247 plan disposition | 2026-10-26 |
| AR-247-02 | T-247-SC (low facets) | Plans that add no package installs explicitly accept their existing supply-chain exposure. The separate high-severity new-action-pin facet is mitigated and verified. | Approved 247 plan dispositions | 2026-10-26 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-26 | 29 | 29 | 0 | gsd-security-auditor + orchestrator |

## Sign-Off

- [x] All threats have a disposition.
- [x] Existing plan-accepted risks recorded.
- [x] Current high-threshold clearance: offline repair 8c9f1541 and independent review close T-247-48; zero high threats remain.
- [x] Current status is verified at the high threshold; two inherited medium controls remain open. Main performance acceptance remains incomplete.

Security verification does not complete phase 247: CI-03 is still MISS.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 35 |
| Closed | 35 |
| Open | 0 |


## B4 gap-plan register additions (ASVS L1)

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|---|---|---|---|---|---|---|
| T-247-35 | Tampering | timing artifact ingest | medium | mitigate | Fixed three B3 main attempt-1 SHAs/artifacts checked; strict 12-TSV lane ingest, exact 269/206 inventories, positive sorted weights and interrupted atomic-replace self-test pass. | closed |
| T-247-36 | Tampering | non-additive assignment | high | mitigate | Long-async RED/GREEN and floor-removal mutation, exact-once guard, colocation, full/scoped runs and Linux/macOS self-tests. GNU awk scalar correction independently reviewed; real CI self-test failed closed before correction and passes after. | closed |
| T-247-37 | Tampering | browser motion acceptance | medium | mitigate | Keyboard Enter/toast-hidden/motion assertions retained; focused 2/2 and full 24/24 no-retry browser runs, exact full gate and PR receipts. Historical failed run unchanged. | closed |
| T-247-38 | Tampering | main landing | high | mitigate | Exact 4ff7af65 full local gate and hosted run 40448573344; PR 97 SHA-guarded squash 02d115a3; fetched main/tested non-planning tree equality and sole CI required@15368 readback. | closed |
| T-247-39 | Tampering | main measurement record | high | mitigate | Main identity stayed fixed; six-run/five-dispatch cap stopped with four successes and two explicit failures. Fresh canonical insufficient payload equals persisted JSON and both incomplete projections. Median null; complete B4 file/blocks absent; phase/requirements remain pending. Full-five reconciliation/negative controls are blocked and expressly not credited. | closed |

The new fixture failures are retained as unresolved execution evidence; they are not accepted risks or success samples. No waiver of 1.15/540 s, publication, hidden retry, or additional CI spend occurred. The ASVS L1 workflow permits inline closure after authored-register controls are found; no L2/L3 claim is made.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 40 |
| Closed | 40 |
| Open | 0 |

## Local diagnostic additions (ASVS L1)

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|---|---|---|---|---|---|---|
| T-247-41 | Tampering | image/formatter/probe inputs | medium | mitigate | Probe check_receipt verifies exact runtime/architecture, immutable image identity, historical producer/runner/formatter and generated-case hashes; producer mutations fail. Actual observed arm fails closed as INVALID; image-after comparison remains. | closed |
| T-247-42 | Denial of service | Docker child and timing loop | medium | mitigate | Fixed 15 s child / 150 s overall caps, bounded arm loop, unique owned container and process group, timeout cleanup in run_child/execute_run. Actual series stopped after one invalid warmup with no replacements. No timing rerun during repair. | closed |
| T-247-43 | Tampering | frozen artifact and source replay | medium | mitigate | Source blobs, cohort/run/head/attempt identity, exclusions, inventory and payload digests checked before parsing; valid-schema payload mutations rejected. Diagnostic TSVs bind directly to saved manifest digests. B3/B4 bind to the SHA-pinned original replay: later substitution detected, original upstream archive/member authenticity unproven because archives were not retained. | closed |
| T-247-44 | Repudiation | local diagnostic verdict | medium | mitigate | Report/validation projections, report body and automated-review receipt hashes checked; changed acceptance/causal fields rejected. Printed ratios remain authoritative, CI-02 INCOMPLETE / CI-03 MISS / cause UNPROVEN. Independent final tool review has no blockers. | closed |

L1 closure means the planned controls are present and their scoped negative checks pass. It does not establish upstream B3/B4 authenticity, validate the failed canary, or assert L2/L3 security coverage. The tooling fixes and trace-only test are recorded in 247-LOCAL-TOOLS-FIX-SUMMARY.md and independently re-reviewed in 247-REVIEW.md. No new risk acceptance is made.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 44 |
| Closed | 44 |
| Open | 0 |

## Plan 22 incremental audit — 2026-10-27

Independent auditor: `/root/audit_247_22_security` (`gsd-security-auditor`, ASVS L1, block_on high). The shared T-247-SC entry is deduplicated; Plan 22 installed nothing and used `--pull=never`. Register totals: 47 distinct, 45 closed, 2 open medium, 0 blocking high. `threats_open` counts all open controls honestly; `threats_blocking` records the severity threshold separately.

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|---|---|---|---|---|---|---|
| T-247-45 | Tampering | old/new receipt provenance | high | mitigate | Committed source, image/runtime/preflight and historical SHA bindings; false-status and rebind regression tests; old/new saved receipt verifiers pass; original three hashes unchanged. | closed |
| T-247-46 | Denial of service | Docker child and local loop | medium | mitigate | Explicit one-series decision, reservation and bounded loop exist. Missing owned preflight identities/timeout cleanup and redacted attempted-arm identity leave ownership evidence incomplete. Terminal first-warmup compile failure is preserved; no retry. | open |
| T-247-47 | Repudiation | local report versus CI verdict | medium | mitigate | JSON projection verifies. Independent review checks narrative and inputs; final body re-attested with reproducible hash 6f6525d1490bfcb46e6f3b7be3049827e4b4cbfa557ef7027b28f69f8336eb58. CLI does not itself verify narrative/review-attestation claims, so reusable verification coverage remains open. | open |

The original review-body hash mismatch was corrected through independent re-attestation of the final body; no raw receipt or source changed. Pure evidence checks: 13 mocked tests, synthetic round trip, old/new saved receipt/report verification and historical hashes pass. The observed result remains INVALID after one compiler-failed warmup. CI-02 INCOMPLETE, CI-03 MISS and Phase 247 2/4 remain unchanged.

## Plans 23–25 incremental security audit — 2026-10-27

Reviewer: `/root/security_247_closeout` (`gsd-security-auditor`, ASVS L1). Verified only the plan-authored register against current source, pure mutation controls and committed evidence. No new Docker, network, compiler or hosted observation was performed by this audit. Prior 45 closed threats remain historical; no new accepted risk is introduced.

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|---|---|---|---|---|---|---|
| T-247-48 | Tampering | old/new receipt dispatch | high | mitigate | FIXED 8c9f1541: both preflight statuses are derived from raw output/runtime/image/CID evidence; inconsistent INVALID reasons and compile projections fail. INVALID series reasons are also checked. Producer-bound schema and current-source execution gates remain. 37 tests and clean independent offline review corroborate the fix. Historical receipts are unchanged. | closed |
| T-247-49 | Repudiation | owned Docker launches | medium | mitigate | Owned CID and inspected name gate CID-only removal; collision/missing/mismatch mocked controls exist. Plan 25 sole child has matching name/CID and successful removal. Historical Plan 22 missing identity stays disclosed. | closed |
| T-247-50 | Elevation of privilege | scope checkpoint | high | mitigate | Dated human authorization records actual maintainer answer and approved hashes; strict machine grant binds post-approval HEAD before reservation. Exact-match rejection controls cover incidental/duplicate/mismatched grants. | closed |
| T-247-51 | Elevation of privilege | one-shot reservation and launch | high | mitigate | Durable reservation precedes Docker launch; pull=never/network=none; INVALID preflight caused zero arms and no retry or series JSON. Only one grant was consumed. | closed |
| T-247-52 | Tampering | image/compiler/container provenance | high | mitigate | Committed producer/runner/formatter binding and actual cached ARM64 identity; Elixir 1.15.8 / OTP 26.2.5.21 child exit 0 plus compile marker. Unused-variable stderr correctly stops this observed preflight as INVALID; owned CID matches. False VALID is rejected. This does not close T-247-48's false INVALID direction. | closed |
| T-247-53 | Repudiation | local-to-CI interpretation | medium | mitigate | Exact report projection and independent disposition retain warning-only INVALID, zero arms, historical AMD64 cause UNPROVEN, CI-02 INCOMPLETE/null median, CI-03 MISS and future scope gates. | closed |

Current counts: 50/53 closed, 3 open (one high blocking, two inherited medium nonblocking). The raw preflight lacks elapsed-duration fields, so timeout enforcement in source is not empirical cap proof. No source repair or new observation is authorized by this audit. UI review is reused as N/A; this local tool/evidence slice has no frontend changes.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 53 |
| Closed | 50 |
| Open | 3 |

## Offline repair security closure

T-247-48 is closed by 8c9f1541 and independent 247-OFFLINE-REPAIR-REVIEW.md. Current counts: 51/53 closed, two inherited medium open (T-247-46/47), zero high blocking. No new risk acceptance or measurement grant. New /2 timings verify recorded arithmetic, caps and containment; coherent rewriting of all raw observations remains a provenance limit requiring independent attestation. Historical Plan 25 timing stays absent. Main CI-02/03 acceptance remains unproved.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 53 |
| Closed | 51 |
| Open | 2 |

## Plans 26–28 incremental security audit — 2026-10-28

Reviewer: `gsd-security-auditor` (ASVS L1, block_on high), read-only, at HEAD 6e1e0b28. The register was authored in the plans. The auditor re-derived T-247-57, -58, -60, -61 and -62 live from code, git history and the GitHub API. The T-247-54 mutation runs and the exact-head local `ci.all` for T-247-60 are documentary evidence only.

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|---|---|---|---|---|---|---|
| T-247-54 | Tampering | retention worker and shared export directory fixtures | high | mitigate | Test-owned `Task.Supervisor` through `task_start` in pruner_test.exs and retention_history_live_test.exs, each with an ownership regression. Export colocation group is pinned by ci_topology_contract_test.exs:264. Red/green mutation controls recorded on the pinned min image (Elixir 1.15.8 / OTP 26.2.5.21, postgres 15.18). Controlled files are byte-identical to HEAD. Min job green on all five B5 main runs. | closed |
| T-247-55 | Repudiation | fix evidence | medium | mitigate | A single MIN-FIXTURE-AUDIT-JSON block parses with toolchain digests, partition-list sha256, seeds, per-class search commands and red/green counts. Natural reproduction: exactly 3 attempts, recorded honestly. | closed |
| T-247-56 | Denial of service | masking a race | medium | mitigate | `git diff 02d115a3 HEAD -- test/` adds 0 mask markers and 0 timing lines. The 2 removed asserts were moved inside the lock helper, and both are justified. Full suite 3384/0. | closed |
| T-247-57 | Tampering | B4 timing artifacts | high | mitigate | FROZEN_REPLAY hash pinned at min_balance.py:58. Per-TSV pin and exact 20-file fetch. Lane, inventory and run-count validation is strict. A live re-fetch plus `derive --rule max` reproduced the weights file byte for byte (cb833068…b187). | closed |
| T-247-58 | Repudiation | favorable-candidate selection | high | mitigate | R1–R5 at 425a3965 equal the recorded rule. Commit ancestry orders pre-registration before the first numbers and the selection commit 8ef4b801 before the holdouts (b46d935c). A scratch recomputation reproduces both candidates, the training spreads and the R3 choice of B. The disclosure is present. | closed |
| T-247-59 | Spoofing | model fit claimed as balance | medium | mitigate | `ci03_expectation` is labelled advisory. The CI-03 verdict comes from measured main ratios, and the miss landed on a lane the model did not predict. | closed |
| T-247-60 | Tampering | land branch → main | high | mitigate | PR #98 has 0 force-push events and one head, 14f95621. PR run 40690983585 ran on attempt 1, 17/17 green. The full tree of 824c2851 equals 14f95621. lib/, bin/, .github/ and the mix files have 0 diff lines since B4. | closed |
| T-247-61 | Denial of service | hosted spend | medium | mitigate | 5 runs out of a cap of 6 at 824c2851, all attempt 1 and green. Serial dispatch is proven from attempt-1 timestamps. The weights precondition hash matches. | closed |
| T-247-62 | Repudiation | B5 verdicts | medium | mitigate | A fresh `bin/measure-main-ci` read is byte-equal to 247-B5-MEASUREMENT.json, a single unedited commit. The two B5-GATE-JSON projections are byte-identical, and recomputed verdicts match them. | closed |
| T-247-63 | Elevation of privilege | scope creep after a miss | medium | mitigate | The CI-03 miss is recorded as a maintainer scope question in 247-VERIFICATION.md. Nothing was re-sampled, deps_audit_gate_test.exs is unchanged, and the thresholds are unchanged. | closed |
| T-247-SC | Tampering | package installs | low | accept | Covered by AR-247-02. No manifest, lockfile, .tool-versions or workflow changes. The tool uses the standard library only. | closed |

Inherited T-247-46 and T-247-47 stay open, medium and nonblocking. D-26 descoping removes future canary exposure, but it is not a recorded risk acceptance, and nothing in plans 26–28 implements their mitigations. Closing them needs an explicit maintainer AR entry that cites D-26.

Observations, not register gaps:
- 247-MIN-FIXTURE-AUDIT.md says no async flag changed. In fact `test/threadline/storage/local_test.exs` went from async to sync in 136bb932, as 247-B5-WEIGHTS.md records.
- Round-3 review warnings R3-WR-03 (the weights tool overwrites the live lane file) and R3-WR-04 (no documented max-rule regeneration path) are follow-up integrity items.

Current counts: 61/63 closed, 2 open (T-247-46/47, medium, nonblocking), 0 high blocking.

## Security Audit 2026-10-28

| Metric | Count |
|---|---|
| Threats found | 63 |
| Closed | 61 |
| Open | 2 |

## Plans 34–37 register (authored at plan time; audited 2026-10-28)

These threats were authored in 247-34..37-PLAN.md and are listed here for the auditor. They are not yet audited, so the frontmatter counts above are unchanged. The round ended on path S (success), so every threat below was reached, including T-247-99 (cohort spend) and T-247-100 (B6 verdicts). Evidence paths are relative to this phase directory unless they start at the repository root.

| Threat ID | Category | Component | Severity | Disposition | This round's evidence | Status |
|---|---|---|---|---|---|---|
| T-247-87 | Tampering | `lane_tail_k` map | high | mitigate | `bin/ci-test-partitions` (`lane_tail_k`, `tq-lane-k`), `test/threadline/ci_topology_contract_test.exs` (lane_tail_k test with the min mutant), 247-B6-LOCAL-2.md, 247-34-SUMMARY.md | closed |
| T-247-88 | Repudiation | CONTRIBUTING claims every lane queues | medium | mitigate | `CONTRIBUTING.md`, the doc-parity test in `test/threadline/ci_topology_contract_test.exs`, 247-34-SUMMARY.md | closed |
| T-247-89 | Denial of service | self-test cost on CI-02 | medium | mitigate | 247-B6-LOCAL-2.md (D-34 interleaved samples), 247-CONTEXT.md D-31/D-34, 247-34-SUMMARY.md | closed |
| T-247-90 | Repudiation | dropped coverage under per-lane K | high | mitigate | 247-B6-LOCAL-2.md (lane totals, claims), 247-LANDING.md `## Land B6` (`current_partitioned`: 12 queued, 12 claimed) | closed |
| T-247-91 | Tampering | failed round-1 records rewritten | high | mitigate | 247-B6-PREDICTION.md (sha256 33fbbc3f…cefe09), 247-B6-LOCAL.md, 247-33-PLAN.md, 247-B6-ESCALATION.md prefix | closed |
| T-247-92 | Repudiation | post-hoc lane subset (forking path) | high | mitigate | 247-B6-PREDICTION-2.md (TQ-PREREG-2 block and disclosure), 247-35-SUMMARY.md, git ancestry | closed |
| T-247-93 | Tampering | round-1 records | high | mitigate | 247-B6-PREDICTION.md sha256, 247-B6-PREDICTION-2.md `round1.prediction_sha256`, 247-B6-ESCALATION.md prefix | closed |
| T-247-94 | Tampering | timing artifacts | high | mitigate | `tools/tail_queue_replay.py` (`PINNED_TSV_SHA256`, frozen pins), 247-B6-PREDICTION-2.md | closed |
| T-247-95 | Spoofing | min/latest balance claimed from a replay | medium | mitigate | 247-B6-PREDICTION-2.md (min/latest labelled informational), B6-GATE-JSON in 247-MEASUREMENT.md (measured CI-03) | closed |
| T-247-96 | Elevation of privilege | hosted spend despite a FAIL | high | mitigate | 247-B6-PREDICTION-2.md (gate PASS), 247-LANDING.md `## Land B6` precondition | closed |
| T-247-97 | Tampering | land branch → main | high | mitigate | 247-LANDING.md `## Land B6` (exact-head gate, PR #99 one head, `--match-head-commit` squash 11234b01, tree and scope proofs) | closed |
| T-247-98 | Elevation of privilege | spend after a failed gate or preflight | high | mitigate | 247-B6-PREFLIGHT.json (GO), `tools/tail_queue_replay.py preflight`, 247-LANDING.md | closed |
| T-247-99 | Denial of service | hosted spend | medium | mitigate | 247-LANDING.md `## B6 bounded main chronology` (5/6 runs, serial, no re-runs), 247-B6-MEASUREMENT.json | closed |
| T-247-100 | Repudiation | B6 verdicts and continuity | medium | mitigate | 247-B6-MEASUREMENT.json, B6-GATE-JSON in 247-MEASUREMENT.md and 247-VALIDATION.md, 247-36-SUMMARY.md | closed |
| T-247-101 | Elevation of privilege | scope creep after a miss | medium | mitigate | 247-B6-ESCALATION.md (`## Resolution — D-32` and `## D-32 round outcome`). Path S needed no fallback, so there is no 247-B6-ESCALATION-2.md and no SEED-009 | closed |
| T-247-102 | Repudiation | round-closure records | medium | mitigate | 247-37 Task 1/2 `<automated>` checks, 247-37-SUMMARY.md | closed |

## Plans 29–37 incremental security audit — 2026-10-28

Reviewer: `gsd-security-auditor` (ASVS L1, block_on high). It was read-only, at HEAD fc7e0811; the non-planning tree of main 11234b01 is identical. The register was authored in 247-29..37-PLAN.md, and the auditor verified mitigations rather than scanning for new threats. Live checks: `bin/ci-test-partitions --self-test` exits 0 under Bash 5.2 and /bin/bash 3.2; `mix test test/threadline/ci_topology_contract_test.exs` gives 35 tests, 0 failures; the `min_balance.py` and `tail_queue_replay.py` self-tests exit 0. Fresh `gh` reads (GET only, no hosted spend) reproduce 247-B6-PREFLIGHT.json and 247-B6-MEASUREMENT.json byte for byte. T-247-87..T-247-102 above are now closed on that evidence.

| Threat ID | Category | Component | Severity | Disposition | Evidence | Status |
|---|---|---|---|---|---|---|
| T-247-64 | Tampering | `--ingest-weights` min-lane rule | high | mitigate | `lane_rule()` bin/ci-test-partitions:360-367; a mismatched `--rule` dies with exit 2 before any read or temp file (:1569-1571); `lane-rule: ok` self-test; contract min→median mutant (:565-605); test/partition_weights_min.txt sha256 cb833068…b187 unchanged since 824c2851 | closed |
| T-247-65 | Tampering | `min_balance.py --weights` | medium | mitigate | `placed()` removed; `stage_copy()` uses mkdtemp (:220-224); self-test asserts the live file's bytes and mtime are unchanged; `git status test/` clean after the run | closed |
| T-247-66 | Repudiation | degenerate assignment hidden by `ratio_of` | low | mitigate | `ratio_of` (min_balance.py:159-166) rejects no, empty and zero-cost partitions; three self-test cases pass | closed |
| T-247-67 | Tampering | queue drops or repeats a file | high | mitigate | `verify_tail_queue` (:599-617) runs before compile; `verify_claims` (:620-635) sets fail=1 (:1417); tq-basic and tq-contention ×2 pass | closed |
| T-247-68 | Denial of service | lock wedge or hang | high | mitigate | Owner-index mkdir lock (:650-694), stale break (:666-673), bounded LOCK_WAIT_S (:674-677), release in `stop_over_budget` (:1040) and `kill_all` (:1325); tq-hang and tq-lock-stale pass | closed |
| T-247-69 | Repudiation | failing claim masked by a later pass | high | mitigate | First non-zero exit wins (:1376); tq-fail asserts exit 1 and `exit=1` on the claim line | closed |
| T-247-70 | Tampering | test-only seams reaching CI | medium | mitigate | Seams documented as test-only (:179-209); none appear in .github/ or mix.exs; contract `tail-queue-seams` rule with mutants | closed |
| T-247-71 | Information disclosure | step summary | low | mitigate | Tail queue rows (:806-829) come only from claim seq, path and integers; no log text in GITHUB_STEP_SUMMARY | closed |
| T-247-72 | Tampering | queue disabled or resized | high | mitigate | K=4 mutant (contract :351-376), seam absence, single invocation site, doc parity for TAIL_QUEUE_K=12 with mutants | closed |
| T-247-73 | Repudiation | dropped coverage claimed green | high | mitigate | 247-B6-LOCAL.md: whole suite 3387 equals each current-lane partitioned sum; 12/12 queued and claimed | closed |
| T-247-74 | Denial of service | unnamed hang in a queued file | high | mitigate | `queued_hang_proof`: 90 s budget, 64 s elapsed, `test/zz_queued_hang_test.exs:4` named, claim exit 1, no leftover BEAM; repeated in B6-LOCAL-2 (65 s) | closed |
| T-247-75 | Tampering | negative control weakened | medium | mitigate | Contract :265-292 keeps the `export fixture overlap` assertion with `CI_TEST_PARTITIONS_TAIL_K=0` and a comment giving the reason | closed |
| T-247-76 | Tampering | B3/B4/B5 timing artifacts | high | mitigate | `verify_digest` (:404-409); `FROZEN_REPLAY_SHA256` matches the live file (5bbf55a8…a6f1); `PINNED_TSV_SHA256` check (:723-751); unavailable runs listed, not substituted | closed |
| T-247-77 | Repudiation | post-hoc parameter choice | high | mitigate | TQ-PREREG at 6a1e8a16 is byte-equal to `pre_registered_rule`; it is an ancestor of e9bb16ca, b25c3c29, 59966463 and 1f1ede48 | closed |
| T-247-78 | Spoofing | model fit shown as balance | medium | mitigate | 247-B6-PREDICTION.md:78-85 labels the replay an expectation; `ci03_expectation` is advisory | closed |
| T-247-79 | Elevation of privilege | spend despite a failing gate | high | mitigate | Round-1 FAIL committed at 1f1ede48 (18:26Z); 0 hosted runs before the PR #99 run at 21:43Z | closed |
| T-247-80 | Tampering | preflight judged by eye | medium | mitigate | P8 `cmd_preflight` (:1096) is committed code; its fail-closed self-tests cover 1.16 NO_GO, 8001 and a missing claim | closed |
| T-247-81..85 | — | 247-33 land, spend, verdicts, scope | high/medium | mitigate | Not reached: 247-33 was superseded and never executed (`executed: false`, `hosted_runs_spent: 0`; no execution commit; 33-PLAN unchanged since 0c5903ab). Superseded by T-247-97..101. | closed (not reached) |
| T-247-86 | Denial of service | self-test cost on CI-02 | medium | mitigate | 247-30-SUMMARY: env +14 s, /bin/bash +15 s, both within the +20 s cap; hosted CI-02 median 461 s | closed |

Findings that limit these closures (not register gaps):
- R4-WR-01..03 (247-REVIEW.md) are still open and untriaged, and they sit inside the T-247-67/68/74 claim-path controls now on main. They are: stale-break ABA leading to a double claim; an ownerless lock that is never broken; a spent-deadline partition that keeps claiming and prints false `HANG:` lines; and a claim row left by a TERM during `claim_next`. Every path fails closed, so L1 closure holds, but they corrupt diagnosis. Do not treat the stale-break sub-control as proven; triage them in a follow-up hardening plan.
- D-34 changed the T-247-89 measurement method after the cap halted the round. The change is disclosed, the halted series is kept, and the hosted CI-02 median of 461 s backs the outcome.
- After the T-247-102 check window, REVIEW-DISPOSITION.md lost its `open:`/`total:` frontmatter in 8a8e8357, and the verifier checked CI-01..04 in REQUIREMENTS (allowed by 37-PLAN).

Inherited T-247-46 and T-247-47 are unchanged by plans 29–37. They stay open, medium and nonblocking, and closing them still needs an explicit maintainer AR entry citing D-26. `threats_open` keeps this file's convention of counting all open controls; `threats_blocking` is 0.

Current counts: 100/102 closed, 2 open (T-247-46/47, medium, nonblocking), 0 high blocking.

## Security Audit 2026-10-28

| Metric | Count |
|---|---|
| Threats found | 102 |
| Closed | 100 |
| Open | 2 |
