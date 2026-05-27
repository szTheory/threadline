# Requirements: v1.22 - Policy / Evidence Plane

**Defined:** 2026-05-25
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1 Requirements

### Evidence Records (EVID)

- [x] **EVID-01**: Threadline persists append-only evidence records for its owned governance subjects instead of relying only on live runtime inspection or prose.
- [x] **EVID-02**: Each evidence record captures a stable subject, timestamp, actor/provenance metadata, summary status, and machine-readable detail payload suitable for later audit review.
- [x] **EVID-03**: Evidence capture is limited to Threadline-owned facts and posture; it does not encode host business roles, tenancy semantics, or compliance workflow state.

### Library and CLI Proof (PROOF)

- [x] **PROOF-01**: Public library APIs can create and read evidence records without requiring Phoenix or the mounted operator surface.
- [x] **PROOF-02**: Mix-task parity exists for the milestone's evidence subjects, including stable machine-readable output for CI, procurement, or audit handoff.
- [x] **PROOF-03**: Evidence outputs clearly distinguish proven facts, inferred posture, and unsupported claims.

### Operator Surface Readouts (SURF)

- [x] **SURF-01**: Read-only evidence views live on the existing `/audit` surface rather than a new operator UI family.
- [x] **SURF-02**: Mounted evidence views show the same evidence facts and boundary language as the library API and Mix-task paths.
- [x] **SURF-03**: Host-owned authorization remains the gate for mounted evidence views; Threadline does not introduce RBAC or tenant DSL semantics.

### Documentation and Boundaries (DOC)

- [x] **DOC-01**: Public docs, support matrix guidance, and examples state exactly what evidence Threadline can prove and what remains host-owned.
- [x] **DOC-02**: Public docs explicitly reject stronger claims that this milestone does not deliver, including legal hold, immutable-storage guarantees, generic compliance packs, and vendor-specific reporting suites.
- [x] **DOC-03**: Contract and integration tests lock the evidence-plane claim end to end on the current tree.

## v2 Requirements

### Deferred Expansion

- **DEFER-01**: Vendor-specific compliance report packs or procurement bundles beyond stable JSON evidence outputs.
- **DEFER-02**: Legal-hold, reviewer approval flows, or policy-change workflow engines.
- **DEFER-03**: Immutable archive guarantees stronger than the host storage/runtime can prove.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Threadline-owned RBAC or role DSL | Auth and permission meaning remain host-owned; evidence work must not become a policy engine. |
| Threadline-owned tenancy DSL | Support-safe scoping is already host-owned; v1.22 should not reopen that boundary. |
| Generic compliance platform positioning | The milestone is about evidence truth for Threadline-owned facts, not a full compliance product. |
| Legal-hold workflows or immutable storage guarantees | These create stronger durability claims than the current runtime/storage contract can honestly support. |
| Separate evidence UI family or package split | Reuse the existing `/audit` surface and keep packaging pressure evidence-based. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVID-01 | Phase 100 | Complete |
| EVID-02 | Phase 100 | Complete |
| EVID-03 | Phase 100 | Complete |
| PROOF-01 | Phase 101 | Complete |
| PROOF-02 | Phase 97 | Complete |
| PROOF-03 | Phase 97 | Complete |
| SURF-01 | Phase 102 | Complete |
| SURF-02 | Phase 102 | Complete |
| SURF-03 | Phase 102 | Complete |
| DOC-01 | Phase 99 | Complete |
| DOC-02 | Phase 99 | Complete |
| DOC-03 | Phase 99 | Complete |

**Coverage:**

- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-27 after Phase 103 reconciled the SURF closure chain*
