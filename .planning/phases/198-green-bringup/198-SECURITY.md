---
phase: "198"
slug: "green-bringup"
status: blocked
threats_open: 5
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
threats_total: 239
threats_closed: 231
threats_open_total: 8
created: "2026-09-08"
updated: "2026-09-09"
---

# Phase 198 — Security

> ASVS L1 verification of the plan-authored STRIDE register. Plans 01–42 remain
> verified; the post-Plan-47 audit found five blocking and three non-blocking open
> threats in Plans 44–47. Remote state was observed read-only; no push, merge,
> ruleset change, bypass window, rebase, squash, or force update occurred.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub repository policy | Local helpers and workflows inspect or enforce hosted branch/ruleset state | Ruleset JSON, protection APIs, check-run conclusions, release authorization |
| CI dependency boundary | Required workflows delegate behavior to local and third-party actions | Job results, aggregate-gate verdicts, release credentials |
| Evidence persistence | CI and local measurement tools create durable attestation artifacts | Run metadata, digests, logs, requirement evidence |
| Demo database session | Reset/seed helpers temporarily alter connection and application state | Advisory locks, PostgreSQL session settings, retention configuration |
| Operator LiveView input | Browser events become server-side filter/window values | User-controlled event parameters and query state |

## Threat Register — Blocking Open

| Threat ID | Severity | Expected mitigation | Audit result |
|-----------|----------|---------------------|--------------|
| T-198-44-02 | high | Strict schema/evidence joins; reject unknown keys and duplicate IDs with mutation fixtures | The evaluator checks selected fields only; tests cover empty timeouts and one overrun. |
| T-198-44-05 | high | Explicit read-only command allowlist; reject dispatch, rerun, and write verbs | The observer hardcodes reads, but the declared allowlist/rejection contract is absent. |
| T-198-45-01 | high | Record traces, geometry, active element, commands, and repeat counts | Commands/counts exist; trace, active-element, and measured-geometry evidence does not. |
| T-198-45-02 | high | Prohibition scan plus a red-control proof | The audit explicitly records that no red control was performed. |
| T-198-46-01 | high | Executable exact-15-entry allowlist and unchanged-entry diff guard | The all-summary classifier exists, but no exact-entry or unchanged-entry guard exists. |

The 13 rows previously listed here were inaccurate supply-chain metadata, not accepted risks: locked dependency restoration may occur during verification, but no dependency graph mutation is committed. Their canonical plan entries use evidence-backed `mitigate` dispositions and valid `low` severity.

## Threat Register — Non-Blocking Open

| Threat ID | Severity | Expected mitigation | Audit result |
|-----------|----------|---------------------|--------------|
| T-198-44-03 | medium | Emit predicted, observed, intersection, extra, and missing sets | Output includes target, exact, missing, and extra only. |
| T-198-46-05 | low | Explicit documented maintainer acceptance | No accepted-risk entry exists. |
| T-198-47-06 | low | Explicit documented maintainer acceptance | No accepted-risk entry exists. |

Twelve earlier rows were corrected to evidence-backed `mitigate` dispositions, and the 15 residual risks explicitly approved by the maintainer on 2026-09-08 remain recorded in the accepted-risk log below. The two new `accept` dispositions above are not treated as approved.

## Metadata Corrections

These 25 entries were reviewed individually and corrected in their canonical `198-NN-PLAN.md` registers. They describe controls already present or non-applicable mutation paths, so recording them as unapproved accepted risks was inaccurate.

| Threat ID | Corrected disposition | Evidence-backed control |
|-----------|-----------------------|-------------------------|
| T-198-01-04 | mitigate | The complete run log is already committed as durable evidence. |
| T-198-03-02 | mitigate | The aggregate action is pinned to a full immutable commit SHA. |
| T-198-04-03 | mitigate | The test-only query uses fixed metadata identifiers and reads no application data. |
| T-198-09-03 | mitigate | The compile-time roster contract introduces no query, authentication, capture, or data-flow surface. |
| T-198-10-04 | mitigate | PostgreSQL credentials are fixed test-only values scoped to an ephemeral hosted job. |
| T-198-13-05 | mitigate | Classic branch-protection inspection is separate and fail-closed for every error except HTTP 404 absence. |
| T-198-14-SC | mitigate | Verification may restore locked dependencies; no manifest or lockfile mutation is committed. |
| T-198-15-04 | mitigate | The former subprocess shell boundary was removed when coverage moved to Playwright. |
| T-198-15-SC | mitigate | Browser verification restores the committed lockfile only; no dependency graph mutation is committed. |
| T-198-16-SC | mitigate | Browser verification restores committed locks and the lockfile-selected browser only. |
| T-198-17-SC | mitigate | Browser verification restores committed locks and the lockfile-selected browser only. |
| T-198-18-SC | mitigate | CI may restore lockfile-pinned dependencies; no dependency graph mutation is committed. |
| T-198-21-05 | mitigate | Contract tests read repository-local files and add no permission, secret, or network surface. |
| T-198-30-SC | mitigate | Demo-reset changes add, remove, or upgrade no dependency. |
| T-198-31-SC | mitigate | Browser verification restores lockfile-pinned dependencies without graph mutation. |
| T-198-32-SC | mitigate | Verification may restore declared Mix dependencies without graph mutation. |
| T-198-33-SC | mitigate | Browser verification restores lockfile-pinned dependencies without graph mutation. |
| T-198-34-SC | mitigate | CI restores lockfile-pinned dependencies and removes transient artifacts; no graph mutation is committed. |
| T-198-35-SC | mitigate | Retention-tail changes add, remove, or upgrade no dependency. |
| T-198-36-SC | mitigate | The plan changes planning Markdown only; manifests and lockfiles are unchanged. |
| T-198-37-SC | mitigate | Observed CI may restore locked dependencies; committed changes contain no graph mutation. |
| T-198-38-05 | mitigate | Every advisory-lock operation uses the shared namespaced class ID. |
| T-198-38-SC | mitigate | Lock changes add, remove, or upgrade no dependency. |
| T-198-39-SC | mitigate | The plan changes planning records only; manifests and lockfiles are unchanged. |
| T-198-40-SC | mitigate | CI may restore locked dependencies; measurement records commit no graph mutation. |

## Repaired Mitigations Closed on Re-Audit

| Threat ID | Severity | Verified evidence | Status |
|-----------|----------|-------------------|--------|
| T-198-03-01 | high | The required aggregate action is pinned to a full immutable SHA in `.github/workflows/ci.yml`; the pin contract passes in `ci_topology_contract_test.exs`. | closed |
| T-198-06-01 | critical | The release workflow filters exact SHA/main/push, orders by creation time plus run ID, and evaluates only the authoritative newest run; `release_ci_gate_contract_test.exs` passes. | closed |
| T-198-07-01 | high | `bin/verify-branch-protection` treats only HTTP 404 as absence and fails closed for API/transport errors; fixtures cover 403, 429, 500, and 503. | closed |
| T-198-07-03 | medium | The same fail-closed inspection prevents stacked protection from being silently treated as absent. | closed |
| T-198-35-01 | high | The retention sandbox uses `Application.fetch_env/2` and restores either the prior value or true absence in `after`; its contract test passes. | closed |

## Closed Register

Of 239 registered threats, 231 are closed: the 213 previously verified entries plus 18 verified mitigations from Plans 43–47. This compact index preserves the plan-level mapping; the source threat definitions remain canonical in each `198-NN-PLAN.md`.

| Plans | Closed threat IDs | Principal verified controls |
|-------|-------------------|-----------------------------|
| 01–05 | 24 | Credential sweeps and audit artifacts; Credo/mechanical checks; zero-skip and UI policy contracts; bounded CI/browser jobs and caches; immutable required-aggregate pin. |
| 06–10 | 23 | Authoritative release-run selection; fail-closed protection inspection; release topology/classifier controls; active ruleset and emitted-context checks; storage-schema masks/call-site contracts; optional-dependency roster. |
| 11–15 | 23 | Executable flake classifier; zero-skip/storage checks; ruleset and archive evidence; bounded storage scanner; stress-router and aggregate identity contracts. |
| 16–20 | 28 | Tier-A byte stability; Playwright diagnosis/bounds; CI measurement ledger; exact demo DB target and credential scoping; aggregate decision evidence. |
| 21–25 | 27 | CI topology/ruleset parity; exact run/SHA ledger; demo-seed and walkthrough red/green evidence; timeout override guard. |
| 26–30 | 30 | Pinned Playwright/browser inventory; post-merge visual disposition; exact-SHA CI accounting; bounded namespaced demo lock and production reset guard. |
| 31–35 | 19 | JSON-quoted selectors; discriminating walkthrough assertions; support/admin coverage; canonical presentation functions; exact retention-state restoration and cutoff checks. |
| 36–40 | 29 | Tree-backed review ledger; exact-run prediction/measurement; pinned advisory-lock region; verbatim no-mutation decisions; append-only Round-6 evidence. |
| 41–42 | 10 | Immutable subject/run ledger; atomic lifecycle proof; double ruleset digest; deterministic exact-main-SHA run selection; sealed Round-7 evidence. |
| 43–47 | 18 | Safe issue upsert and release gates; exact-main observer boundaries; row-history synchronization; zero-human evaluator integrity; read-only Plan-47 reconciliation. |

Closed count check: `24 + 23 + 23 + 28 + 27 + 30 + 19 + 29 + 10 + 18 = 231`.

## Unregistered Review Flags

The previously unregistered CR-04, WR-01, and WR-03 findings are resolved. The converged 90-file code review reports zero Critical, Warning, or Info findings.

No unregistered open flags remain.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-198-01 | T-198-02-04 | Provider-candidate verification discloses bounded credential metadata only to the issuing provider that already holds the credential. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-02 | T-198-04-05 | The destructive database reset is explicit, test-only, and scoped to `Threadline.Test.Repo`. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-03 | T-198-05-05 | Failure artifacts contain synthetic test data only and expire after 14 days. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-04 | T-198-11-05 | The classifier job needs issue write access; repository contents remain read-only. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-05 | T-198-13-02 | D-30 authorizes permanent public planning disclosure after the D-28 sensitive-data scan. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-06 | T-198-16-04 | The browser verification capture is bounded to 35 minutes. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-07 | T-198-18-05 | D-30 authorizes permanent public planning disclosure after the D-28 sensitive-data scan. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-08 | T-198-19-02 | PostgreSQL superuser credentials are fixed test-only values in an ephemeral CI service. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-09 | T-198-20-04 | D-30 authorizes the public CI decision brief after the D-28 sensitive-data scan. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-10 | T-198-22-04 | D-30 and D-28 authorize public planning and CI diagnostics after sensitive-data review. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-11 | T-198-29-05 | D-30 authorizes permanent public planning disclosure after the D-28 sensitive-data scan. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-12 | T-198-31-03 | Playwright artifacts contain synthetic test data only and expire after 14 days. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-13 | T-198-33-03 | Administrative coverage artifacts contain fictional identities and synthetic data only. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-14 | T-198-38-03 | Reset capability is demo-only and guarded against production unless an explicit override is set. | maintainer (explicit GSD-session approval) | 2026-09-08 |
| AR-198-15 | T-198-41-04 | The durable capture contains public GitHub metadata and explicitly excludes secrets and tokens. | maintainer (explicit GSD-session approval) | 2026-09-08 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open total | Blocking open | Run By |
|------------|---------------|--------|------------|---------------|--------|
| 2026-09-08 | 213 | 168 | 45 | 17 | gsd-security-auditor / Codex orchestrator |
| 2026-09-08 | 213 | 173 | 40 | 13 | post-fix gsd-security-auditor / Codex orchestrator |
| 2026-09-08 | 213 | 213 | 0 | 0 | maintainer-approved risk disposition / Codex orchestrator |
| 2026-09-09 | 239 | 231 | 8 | 5 | post-Plan-47 gsd-security-auditor / Codex orchestrator |

## Sign-Off

- [x] All registered threats have a plan-authored disposition.
- [x] Accepted risks are maintainer-approved and documented.
- [ ] The two new accepted-risk dispositions have explicit maintainer approval.
- [ ] `threats_open: 0` confirmed.
- [x] `status: blocked` set in frontmatter while five high-severity threats remain open.

**Approval:** blocked 2026-09-09 — five high-severity mitigations are unverified;
three lower-severity threats also remain open. No new risk acceptance was inferred.
