---
phase: "198"
slug: "green-bringup"
status: blocked
threats_open: 17
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
threats_total: 213
threats_closed: 168
threats_open_total: 45
created: "2026-09-08"
updated: "2026-09-08"
---

# Phase 198 — Security

> ASVS L1 verification of the plan-authored STRIDE register. Remote state was observed read-only; no push, merge, ruleset change, bypass window, rebase, squash, or force update occurred.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub repository policy | Local helpers and workflows inspect or enforce hosted branch/ruleset state | Ruleset JSON, protection APIs, check-run conclusions, release authorization |
| CI dependency boundary | Required workflows delegate behavior to local and third-party actions | Job results, aggregate-gate verdicts, release credentials |
| Evidence persistence | CI and local measurement tools create durable attestation artifacts | Run metadata, digests, logs, requirement evidence |
| Demo database session | Reset/seed helpers temporarily alter connection and application state | Advisory locks, PostgreSQL session settings, retention configuration |
| Operator LiveView input | Browser events become server-side filter/window values | User-controlled event parameters and query state |

## Threat Register — Blocking Open

| Threat ID | Category | Component | Severity | Disposition | Missing or failed mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------------------------|--------|
| T-198-03-01 | Elevation of Privilege | Required CI aggregate | high | mitigate | `.github/workflows/ci.yml:751-773` delegates the sole required verdict to mutable `re-actors/alls-green@release/v1`; see `198-REVIEW.md` CR-03. | open |
| T-198-06-01 | Elevation of Privilege | Release authorization | critical | mitigate | `.github/workflows/release.yml:256-276` can accept an older successful run instead of requiring the authoritative/latest run for the SHA; see CR-02. | open |
| T-198-07-01 | Elevation of Privilege | Branch-protection verifier | high | mitigate | `bin/verify-branch-protection:95-106` treats every classic-protection API failure as absence, so the verifier is not fail-closed; see CR-01. | open |
| T-198-35-01 | Denial of Service | Retention-tail sandbox | high | mitigate | `retention_tail.ex:82-105` restores a previously absent retention setting as an explicitly present empty list; see WR-02. | open |
| T-198-14-SC | Tampering | Plan 14 supply-chain boundary | high | accept | Accepted-risk candidate has no maintainer-approved entry in this file. | open |
| T-198-15-SC | Tampering | Plan 15 supply-chain boundary | high | accept | Accepted-risk candidate has no maintainer-approved entry in this file. | open |
| T-198-16-SC | Tampering | Plan 16 supply-chain boundary | high | accept | Accepted-risk candidate has no maintainer-approved entry in this file. | open |
| T-198-17-SC | Tampering | Plan 17 supply-chain boundary | high | accept | Accepted-risk candidate has no maintainer-approved entry in this file. | open |
| T-198-18-SC | Tampering | Plan 18 supply-chain boundary | high | accept | Accepted-risk candidate has no maintainer-approved entry in this file. | open |
| T-198-30-SC | Tampering | Plan 30 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-31-SC | Tampering | Plan 31 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-32-SC | Tampering | Plan 32 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-33-SC | Tampering | Plan 33 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-34-SC | Tampering | Plan 34 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-35-SC | Tampering | Plan 35 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-36-SC | Tampering | Plan 36 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |
| T-198-37-SC | Tampering | Plan 37 supply-chain boundary | critical | accept | Declared severity `n/a` is unparseable and therefore fail-closed to critical; no accepted-risk entry exists. | open |

## Threat Register — Non-Blocking Open

| Threat ID | Category | Severity | Disposition | Reason open | Status |
|-----------|----------|----------|-------------|-------------|--------|
| T-198-07-03 | Tampering | medium | mitigate | Classic-protection inspection shares the fail-open API handling in `bin/verify-branch-protection:95-97`. | open — below high threshold |
| T-198-01-04 | Repudiation | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-02-04 | Information Disclosure | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-03-02 | Tampering | medium | accept | Missing accepted-risk log entry; CR-03 confirms the risk remains active. | open — below high threshold |
| T-198-04-03 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-04-05 | Tampering | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-05-05 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-09-03 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-10-04 | Spoofing | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-11-05 | Elevation of Privilege | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-13-02 | Information Disclosure | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-13-05 | Spoofing | medium | accept | Missing accepted-risk log entry and affected by CR-01. | open — below high threshold |
| T-198-15-04 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-16-04 | Denial of Service | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-18-05 | Information Disclosure | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-19-02 | Elevation of Privilege | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-20-04 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-21-05 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-22-04 | Information Disclosure | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-29-05 | Information Disclosure | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-31-03 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-33-03 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-38-03 | Tampering | medium | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-38-05 | Elevation of Privilege | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-38-SC | Tampering | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-39-SC | Tampering | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-40-SC | Tampering | low | accept | Missing accepted-risk log entry. | open — below high threshold |
| T-198-41-04 | Information Disclosure | low | accept | Missing accepted-risk log entry. | open — below high threshold |

## Closed Register

The remaining 168 registered threats are closed by present implementation or immutable evidence. This compact index preserves the plan-level mapping; the source threat definitions remain canonical in each `198-NN-PLAN.md`.

| Plans | Closed threat IDs | Principal verified controls |
|-------|-------------------|-----------------------------|
| 01–05 | 17 | Credential sweeps and audit artifacts; Credo/mechanical checks; zero-skip and UI policy contracts; bounded CI/browser jobs and caches. |
| 06–10 | 18 | Release topology/classifier controls; active ruleset and emitted-context checks; storage-schema masks/call-site contracts; optional-dependency roster; stable CI identity and schema isolation. |
| 11–15 | 17 | Executable flake classifier; zero-skip/storage checks; ruleset and archive evidence; bounded storage scanner; stress-router and aggregate identity contracts. |
| 16–20 | 21 | Tier-A byte stability; Playwright diagnosis/bounds; CI measurement ledger; exact demo DB target and credential scoping; aggregate decision evidence. |
| 21–25 | 25 | CI topology/ruleset parity; exact run/SHA ledger; demo-seed and walkthrough red/green evidence; timeout override guard. |
| 26–30 | 28 | Pinned Playwright/browser inventory; post-merge visual disposition; exact-SHA CI accounting; bounded namespaced demo lock and production reset guard. |
| 31–35 | 11 | JSON-quoted selectors; discriminating walkthrough assertions; support/admin coverage; canonical presentation functions; cross-org retention/cutoff checks. |
| 36–40 | 22 | Tree-backed review ledger; exact-run prediction/measurement; pinned advisory-lock region; verbatim no-mutation decisions; append-only Round-6 evidence. |
| 41–42 | 9 | Immutable subject/run ledger; atomic lifecycle proof; double ruleset digest; deterministic exact-main-SHA run selection; sealed Round-7 evidence. |

Closed count check: `17 + 18 + 17 + 21 + 25 + 28 + 11 + 22 + 9 = 168`.

## Unregistered Review Flags

These present-HEAD findings do not increment `threats_open` because no Phase 198 registered threat maps to them. They remain actionable review findings:

| Finding | Security classification | Evidence |
|---------|-------------------------|----------|
| CR-04 | warning in this register; Critical in code review | `bin/record-ci-attestation:61-100` truncates the prior evidence target before rendering and validation succeed. |
| WR-01 | warning | `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:100-105` leaks session-wide `lock_timeout` into the pool. |
| WR-03 | warning | `lib/threadline/operator_surface/live/actor_live.ex:253-255` lets forged `hours` input raise through `String.to_integer/1`. |

## Accepted Risks Log

No accepted risks. The 40 `accept` dispositions above are candidates only and require explicit maintainer approval before they may be moved here.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open total | Blocking open | Run By |
|------------|---------------|--------|------------|---------------|--------|
| 2026-09-08 | 213 | 168 | 45 | 17 | gsd-security-auditor / Codex orchestrator |

## Sign-Off

- [x] All registered threats have a disposition.
- [ ] Accepted risks are maintainer-approved and documented.
- [ ] `threats_open: 0` confirmed.
- [ ] `status: verified` set in frontmatter.

**Approval:** blocked — remediate the four failed mitigations and resolve or explicitly accept the 40 risk candidates, then rerun `$gsd-secure-phase 198`.
