---
phase: "247"
slug: "ci-critical-path-and-suite-lanes"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-26"
---

# Phase 247 — Security

Verified by the security auditor against the plan-authored register, actual implementation, landing tree proofs, successful PR runs and read-only branch-protection inspection. Blocking threshold: high. All 29 distinct threat IDs are closed. CI-03 remains an unmet performance acceptance gate.

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

## Verification Evidence

- Fresh validation: 212 ExUnit contracts and 39 Node tests passed; partition watchdog self-tests passed on Bash 5 and Bash 3.2 with process inspection available.
- A1 PR run 40354035917; A2 40375604860; B1 40392212575; B2 40412545694: success, with landing tree equality and corrected A2 slice proof documented in 247-LANDING.md.
- Throwaway hang-shape run 40387548421 failed as designed within the partition budget; remote scratch branch absent.
- Read-only branch-protection check: CI required@15368 is the sole required context.
- T-247-21 provisional receipt-permission concern closed by successful live receipt execution without additional permissions.

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
- [x] threats_open: 0 confirmed at high threshold.
- [x] status: verified set.

Security verification does not complete phase 247: CI-03 is still MISS.
