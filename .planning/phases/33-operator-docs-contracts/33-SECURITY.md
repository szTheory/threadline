---
phase: 33
slug: operator-docs-contracts
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 33 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Published guides ↔ integrator | `guides/domain-reference.md` and `guides/production-checklist.md` are read by operators and library consumers; they must not misrepresent the public API surface. | Intent-to-API mappings (documentation accuracy; no secrets). |
| Doc contracts ↔ CI | `ExplorationRoutingDocContractTest` reads repo files on disk in test runs. | File contents only; no production data. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-33-01 | Tampering (misrepresentation) | `guides/domain-reference.md` routing table | mitigate | Rows cite `Threadline.history/3`, `Threadline.Query.timeline/2`, `Threadline.audit_changes_for_transaction/2`, `Threadline.Query.audit_changes_for_transaction/2`, `Threadline.change_diff/2`, `Threadline.ChangeDiff`, `Threadline.actor_history/2`, `Threadline.Export` — verified against `lib/threadline.ex` and `lib/threadline/query.ex` (2026-04-24 secure-phase). | closed |
| T-33-02 | Tampering (silent drift) | Guide headings / contract marker | mitigate | `test/threadline/exploration_routing_doc_contract_test.exs` asserts `## Exploration API routing (v1.10+)`, `XPLO-03-API-ROUTING`, key API strings, and `domain-reference.md#exploration-api-routing-v110` in production checklist. | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|-----------------|--------|------|--------|
| 2026-04-24 | 2 | 2 | 0 | gsd-secure-phase (Cursor agent) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-24
