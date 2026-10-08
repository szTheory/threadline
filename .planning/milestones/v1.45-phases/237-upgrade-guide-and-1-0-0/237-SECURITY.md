---
phase: "237"
slug: "upgrade-guide-and-1-0-0"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-08"
---

# Phase 237 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|-----------|-------------|---------------|
| Human release notes to adopter procedure | A source breaking-change statement becomes an actionable migration step. | Release guidance and change identifiers |
| Local script to disposable clone | Release-looking artifacts are generated and tested without contacting live release services. | Candidate metadata and generated artifacts |
| Commit metadata to release simulator | Commit subject and footer select a publicly meaningful version. | Git subject and Release-As footer |
| CI and release workflow to external publication | Exact candidate state crosses protected CI and Hex publication boundaries. | Candidate SHA, tag, package, and approval |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-237-01 | Tampering | CHANGELOG.md and guide ID mapping | high | mitigate | Focused guide contract rejects wrong-scope, duplicate, missing, and extra IDs and requires one scoped ID per source bullet. | closed |
| T-237-02 | Repudiation | Trigger and association upgrade wording | medium | mitigate | The guide states the distinction, but the contract only pins the no-trigger statement and checks for entity/field names; it does not pin the exploration-hydration versus capture-persistence distinction. | open — below high threshold (non-blocking) |
| T-237-03 | Tampering | Candidate footer parser | high | mitigate | Candidate preflight requires a feat! subject, one exact Release-As: 1.0.0 footer, JSON false, and negative controls before clone creation. | closed |
| T-237-04 | Repudiation | Rehearsal report | medium | mitigate | Candidate report records SOURCE_SHA, labels the run as local, and disclaims a live Release Please invocation. | closed |
| T-237-05 | Tampering | Candidate squash and milestone range | high | mitigate | Verification records both ranges and SHAs, confirms ancestry and tree reconciliation, and records the candidate rehearsal. | closed |
| T-237-06 | Repudiation | Verification record | medium | mitigate | Exact commands, exit statuses, lane pins, candidate SHA, and local-only scope are recorded. | closed |
| T-237-07 | Elevation of privilege | Candidate push and milestone merge | high | mitigate | Separate blocking-human grants were bound to the exact candidate SHA and PR; no auto-selection or action on silence was used. | closed |
| T-237-08 | Tampering | Squash message and CI evidence | high | mitigate | The landed candidate has the required feat! subject and one target footer; required CI, PostgreSQL 15 minimum, and latest lanes passed. | closed |
| T-237-09 | Elevation of privilege | Release PR merge | high | mitigate | PR #79 merged from its exact head after required CI passed and release artifacts were reviewed under a separate grant. | closed |
| T-237-10 | Elevation of privilege | production-hex approval | high | mitigate | Publication used the required-reviewer production-hex environment and a separate grant tied to the exact tag and run. | closed |
| T-237-11 | Spoofing | Hex publication claim | high | mitigate | Public Hex metadata for 1.0.0 matches the successful protected publish job and recorded checksum. | closed |
| T-237-SC | Tampering | Package installation | high | mitigate | Phase 237 introduced no package install or dependency-graph mutation. Existing mix deps.get paths restore locked dependencies; repository precedent treats unchanged lockfile restoration as outside this threat. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-08 | 12 | 11 | 1 below blocking threshold | GSD security auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed at the configured high threshold
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-08
