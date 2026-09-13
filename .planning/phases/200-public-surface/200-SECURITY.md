---
phase: "200"
slug: "public-surface"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-13"
---

# Phase 200 — Security

> Per-phase security contract for public documentation, packaged artifacts, contribution intake, and hosted GitHub routing.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| source/configuration → generated public docs | Only supported modules, tasks, aliases, and configuration keys may become adopter-visible contracts | Public API and configuration vocabulary |
| repository → Hex package | Maintainer/planning language and private project resources must not ship in the release archive | Source, docs, and package metadata |
| guide author → contributor/adopter | Procedures, links, anchors, commands, and ownership must stay exact and non-duplicated | Operational instructions |
| unaffiliated reporter → public issue/PR intake | Reporter text may contain secrets, personal data, production audit records, or vulnerability details | Untrusted and potentially sensitive text |
| security/conduct reporter → GitHub private routes | Vulnerability and abuse reports require distinct third-party private destinations | Sensitive vulnerability or abuse reports |
| local repository → hosted default branch | Local files do not by themselves prove GitHub recognition, settings, or rendering | Community files and repository settings |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-200-01 | Information disclosure | public module/config/task inventory | medium | mitigate | AST and compiled-doc exact-set contracts, nonempty sentinels, hidden-member rejection, and public-reference validation | closed |
| T-200-02 | Information disclosure | shipped Hex archive/source | high | mitigate | Fresh unpacked-archive scan, exact source-owner union, stable sentinels, external-resource absence, and injected positive controls | closed |
| T-200-03 | Information disclosure | issue/PR intake | high | mitigate | Three bounded forms, repeated private-data warnings, disabled blanks, no Discussions route, and private vulnerability routing | closed |
| T-200-04 | Denial of service / elevation of privilege | optional export callback and operator authorization/session paths | high | mitigate | No-path adapter regression plus focused delivery, authorization, session, and LiveView preservation suites | closed |
| T-200-05 | Tampering | public module/task/alias/config references | medium | mitigate | Source-derived exact inventories and bounded public-document reference equality | closed |
| T-200-06 | Information disclosure | adapter/config examples | low | accept | Examples use fictional modules and supported option shapes only; exact public-reference contracts reject unsupported identifiers | closed |
| T-200-07 | Tampering | release documentation command | medium | mitigate | Sole release-lane ownership and contract for warnings-as-errors ExDoc generation | closed |
| T-200-08 | Tampering | duplicated adoption/operator procedures | medium | mitigate | Canonical-owner contracts and exact caller deep links | closed |
| T-200-09 | Denial of service | guide paths and anchors | medium | mitigate | Exact 18-node graph, resolved relative paths/anchors, distinct successors, negative fixtures, and warnings-as-errors docs | closed |
| T-200-10 | Tampering | operator stress fixtures and form/record record flows | high | mitigate | Coupled source/evidence updates, identity/cardinality/path controls, and focused behavior/auth/rendering suites | closed |
| T-200-11 | Repudiation | contact and response promises | medium | mitigate | SECURITY promises acknowledgment only as practical and distinguishes support, vulnerability, conduct, and abuse routes | closed |
| T-200-12 | Tampering | hosted GitHub recognition/rendering | medium | transfer | Default-branch API/public-content read-back, 100% community health, green hosted CI, and explicit maintainer acceptance of the login-gated outsider-render residual | closed |
| T-200-13 | Elevation of privilege | private-reporting setting mutation | low | accept | One authenticated maintainer-scoped enable/read-back; no credentials printed and no other repository setting changed | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-200-01 | T-200-06 | Fictional, supported configuration examples are necessary public documentation; exact reference contracts bound the disclosure surface. | Phase plan | 2026-09-12 |
| AR-200-02 | T-200-13 | Enabling GitHub private vulnerability reporting is a narrow authenticated maintainer action with immediate read-back and no credential output. | Phase plan | 2026-09-12 |
| AR-200-03 | T-200-12 | GitHub requires login before showing creation forms to signed-out visitors, and no separate non-maintainer identity was available. Structural/API/public-content evidence passed; the maintainer approved the residual UI observation gap. | Maintainer | 2026-09-13 |

---

## Verification Evidence

- Public-surface, guide-graph, community-health, release-artifact, and focused operator contracts passed locally.
- The clean-clone verifier passed with `.planning/` absent and `AGGREGATE_RESULT=PASS`.
- GitHub Actions run `34732689921` passed all 15 checks, including required CI, minimum/current version lanes, Tier A, and browser E2E.
- PR #35 merged to `main` as `18fe87f5f107f155a1a98c1f33b8a64cca3741e3`.
- All seven community files exist on `main` and public raw contents matched locally checked files byte-for-byte.
- GitHub reports community health 100% and private vulnerability reporting enabled.
- SECURITY routes only to the private-advisory endpoint; CODE_OF_CONDUCT routes private abuse to GitHub Report Abuse.
- GitHub's legacy community-profile `files.issue_template issue_template` field remains `null` for the YAML forms despite the 100% profile. This external inconsistency and the separate-account UI limitation are retained as accepted evidence constraints, not hidden.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-13 | 13 | 13 | 0 | Codex / maintainer-approved hosted disposition |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-13
