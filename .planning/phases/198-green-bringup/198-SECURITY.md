---
phase: "198"
slug: "green-bringup"
status: blocked
threats_open: 13
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
threats_total: 213
threats_closed: 173
threats_open_total: 40
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

## Repaired Mitigations Closed on Re-Audit

| Threat ID | Severity | Verified evidence | Status |
|-----------|----------|-------------------|--------|
| T-198-03-01 | high | The required aggregate action is pinned to a full immutable SHA in `.github/workflows/ci.yml`; the pin contract passes in `ci_topology_contract_test.exs`. | closed |
| T-198-06-01 | critical | The release workflow filters exact SHA/main/push, orders by creation time plus run ID, and evaluates only the authoritative newest run; `release_ci_gate_contract_test.exs` passes. | closed |
| T-198-07-01 | high | `bin/verify-branch-protection` treats only HTTP 404 as absence and fails closed for API/transport errors; fixtures cover 403, 429, 500, and 503. | closed |
| T-198-07-03 | medium | The same fail-closed inspection prevents stacked protection from being silently treated as absent. | closed |
| T-198-35-01 | high | The retention sandbox uses `Application.fetch_env/2` and restores either the prior value or true absence in `after`; its contract test passes. | closed |

## Closed Register

All 173 `mitigate` dispositions are closed by present implementation or immutable evidence. This compact index preserves the plan-level mapping; the source threat definitions remain canonical in each `198-NN-PLAN.md`.

| Plans | Closed threat IDs | Principal verified controls |
|-------|-------------------|-----------------------------|
| 01–05 | 18 | Credential sweeps and audit artifacts; Credo/mechanical checks; zero-skip and UI policy contracts; bounded CI/browser jobs and caches; immutable required-aggregate pin. |
| 06–10 | 21 | Authoritative release-run selection; fail-closed protection inspection; release topology/classifier controls; active ruleset and emitted-context checks; storage-schema masks/call-site contracts; optional-dependency roster. |
| 11–15 | 17 | Executable flake classifier; zero-skip/storage checks; ruleset and archive evidence; bounded storage scanner; stress-router and aggregate identity contracts. |
| 16–20 | 21 | Tier-A byte stability; Playwright diagnosis/bounds; CI measurement ledger; exact demo DB target and credential scoping; aggregate decision evidence. |
| 21–25 | 25 | CI topology/ruleset parity; exact run/SHA ledger; demo-seed and walkthrough red/green evidence; timeout override guard. |
| 26–30 | 28 | Pinned Playwright/browser inventory; post-merge visual disposition; exact-SHA CI accounting; bounded namespaced demo lock and production reset guard. |
| 31–35 | 12 | JSON-quoted selectors; discriminating walkthrough assertions; support/admin coverage; canonical presentation functions; exact retention-state restoration and cutoff checks. |
| 36–40 | 22 | Tree-backed review ledger; exact-run prediction/measurement; pinned advisory-lock region; verbatim no-mutation decisions; append-only Round-6 evidence. |
| 41–42 | 9 | Immutable subject/run ledger; atomic lifecycle proof; double ruleset digest; deterministic exact-main-SHA run selection; sealed Round-7 evidence. |

Closed count check: `18 + 21 + 17 + 21 + 25 + 28 + 12 + 22 + 9 = 173`.

## Unregistered Review Flags

The previously unregistered CR-04, WR-01, and WR-03 findings are resolved. The converged 90-file code review reports zero Critical, Warning, or Info findings.

No unregistered open flags remain.

## Accepted Risks Log

No accepted risks. The 40 `accept` dispositions above are candidates only and require explicit maintainer approval before they may be moved here.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open total | Blocking open | Run By |
|------------|---------------|--------|------------|---------------|--------|
| 2026-09-08 | 213 | 168 | 45 | 17 | gsd-security-auditor / Codex orchestrator |
| 2026-09-08 | 213 | 173 | 40 | 13 | post-fix gsd-security-auditor / Codex orchestrator |

## Sign-Off

- [x] All registered threats have a disposition.
- [ ] Accepted risks are maintainer-approved and documented.
- [ ] `threats_open: 0` confirmed.
- [ ] `status: verified` set in frontmatter.

**Approval:** blocked — all implementation mitigations are closed; resolve or explicitly accept the 40 risk candidates, then rerun `$gsd-secure-phase 198`.
