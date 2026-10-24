---
phase: "236"
slug: "support-floor-and-partition-weights"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 236 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CI workflow to adopter support claim | A workflow value becomes a published compatibility promise. | PostgreSQL version and tested-lane meaning |
| Mix and workflow source to guide table | Source toolchain values are rendered as an adopter decision aid. | Elixir, OTP, and PostgreSQL version tokens |
| Test inventory to committed measurements | Discovered test paths must be represented by exactly one timing row. | Repository file paths and integer timing values |
| Local database service to validation claim | The complete test result must be attributed to the claimed database major. | PostgreSQL server version and test results |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-236-01 | Tampering | verify-test minimum matrix row | high | mitigate | The topology contract requires PostgreSQL 15 exactly and mutation controls reject adjacent majors; the PostgreSQL 15 aggregate run passed. | closed |
| T-236-02 | Repudiation | support guide and CHANGELOG | medium | mitigate | The guide contract compares its isolated policy table with Mix, CI, and `.tool-versions`, and pins the Unreleased floor and adopter action. | closed |
| T-236-03 | Tampering | `test/partition_weights.txt` | medium | mitigate | The inventory contract checks every discovered path, unique sorted integer rows, and names a deliberately omitted real path; all 265 paths are present. | closed |
| T-236-04 | Repudiation | PostgreSQL 15 aggregate evidence | high | mitigate | `server_version_num` returned 150018 before the partitioned suite and `mix ci.all`; both gates passed on that service. | closed |
| T-236-SC | Tampering | npm/pip/cargo installs | high | mitigate | This phase installed no packages and added no dependencies; the package-legitimacy audit remains a prerequisite for any future package-install task. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 5 | 5 | 0 | Codex (plan-time register, ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-07
