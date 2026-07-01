---
phase: 185
slug: coverage-and-audit-readiness
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-29
---

# Phase 185 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser -> CoverageLive params/events | User-controlled `schema` query params, schema selector submissions, and refresh events enter the LiveView process. | Schema names, form events, refresh intent |
| CoverageLive -> CoverageSchemas | UI-facing validation crosses from LiveView orchestration into database-backed schema discovery. | Candidate schema name and PostgreSQL namespace lookup |
| CoverageLive -> Threadline.Health.trigger_coverage/1 | A valid selected schema drives coverage reads without changing the trusted programmatic contract. | Selected schema and coverage snapshot request |
| CoverageLive -> Timeline links | Covered row table/schema values become `/audit/timeline` query state. | Table name, optional non-public table schema |
| CoverageLive -> command copy | Table/schema identifiers influence visible remediation labels and optional copyable generator commands. | Table names, schema names, maintainer shell guidance |
| Operator docs -> maintainer terminal | Documentation and command copy can be pasted into a maintainer shell. | Verifier and generator command text |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-185-01 | Tampering | Schema URL/form validation | mitigate | Schema params are validated through `CoverageSchemas.validate/2`; invalid schema tests cover escaped rejected values, recovery copy, and no stale public rows rendered as selected-schema readiness. | closed |
| T-185-02 | Spoofing / Information Disclosure | Selected-schema verdict and stale refresh | mitigate | The verdict is derived from selected-schema `Coverage.Snapshot` data; stale refresh behavior preserves the last-good selected-schema timestamp and marks the state stale instead of presenting a failed check as fresh. | closed |
| T-185-03 | Information Disclosure | Non-public Timeline links | mitigate | Covered row actions include `table_schema=NAME&table=TABLE` only for contextual row links, and generic page-level Timeline CTAs remain absent. | closed |
| T-185-04 | Tampering / Elevation of Privilege | Row remediation command copy | mitigate | `Presentation.coverage_remediation/2` emits copyable generator commands only for safe public identifiers; unsafe or non-public identifiers receive precise non-copyable follow-up guidance. | closed |
| T-185-05 | Tampering / XSS | Schema/table-name rendering | mitigate | Schema, table, verdict, and docs-generated copy render through HEEx/source-checked text paths; source and behavior tests cover rejected schema rendering and avoid raw HTML injection. | closed |
| T-185-06 | Repudiation / Information Disclosure | Docs and stale public header badge | mitigate | Docs and tests distinguish selected-schema page readiness from the public-schema shell badge and explicitly document stale/refresh semantics. | closed |
| T-185-07 | Denial of Service | Browser proof and Playwright lanes | accept | Phase 185 reuses the existing light/system browser lane and adds a narrow behavior proof only; no screenshot matrix or new Playwright project is introduced. | closed |
| T-185-SC | Tampering | Package installs | accept | Phase 185 adds no dependency manifest changes or package-manager installs; existing Elixir/Phoenix/Playwright dependencies are reused. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Verification Evidence

| Evidence | Result |
|----------|--------|
| `185-VERIFICATION.md` | Canonical status `passed`; 6/6 observable truths verified; full-suite residuals classified outside Phase 185. |
| `185-REVIEW.md` | Code review status `clean`; stale snapshot, schema failure, invalid refresh, docs, and browser focus findings resolved. |
| `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs test/threadline/operator_surface/formless_pages_test.exs` | 117 tests, 0 failures. |
| `mix verify.example_browser_light tests/operator-coverage-readiness.spec.ts` | 7 browser tests passed for the admitted light/system lane. |
| `mix verify.format` | Passed. |
| `mix verify.credo` | 230 source files checked, 0 issues. |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-185-01 | T-185-07 | The browser proof intentionally stays narrow to avoid adding a denial-of-service maintenance burden through broad screenshot matrices or new Playwright projects. Coverage-specific mobile, focus, disclosure, copy, and link behavior are still tested. | GSD Phase 185 plan and security audit | 2026-06-29 |
| AR-185-02 | T-185-SC | No dependency manifests, package-manager installs, JS ORM schema pushes, or new runtime packages are part of Phase 185, so no new supply-chain review is required for this phase. | GSD Phase 185 plan and security audit | 2026-06-29 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-29 | 8 | 8 | 0 | Codex / GSD secure-phase hook |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-29
