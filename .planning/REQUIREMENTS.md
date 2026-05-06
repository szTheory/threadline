# Requirements: Threadline

**Defined:** 2026-05-05
**Milestone:** v1.16 — Investigation Table Stakes
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.16 Requirements

### EXPLORE - Paged Investigation Workflows

- [x] **EXPLORE-01**: `Threadline.timeline/2` and the underlying query surface expose an explicit stable paging contract for large investigation windows, preserving the existing `(captured_at, id)` ordering without pushing adopters toward ad-hoc offset pagination.
- [x] **EXPLORE-02**: The library ships higher-level investigation helpers for the core operator questions already taught in the docs, so teams can answer row-history, actor-window, correlation-bundle, and transaction-drill-down questions without hand-writing joins around low-level structs.

### INCIDENT - First-class Incident Bundles

- [ ] **INCIDENT-06**: Threadline ships a first-class incident bundle surface for one audit transaction that returns ordered changes, linked transaction/action context, and JSON-ready field diffs in a single library-level contract.
- [ ] **INCIDENT-07**: The Phoenix example incident drill-down path uses the packaged incident bundle surface rather than bespoke controller composition, proving the public contract is sufficient for real host endpoints.

### ADOPT - Canonical Exploration Guidance

- [ ] **ADOPT-04**: README, domain reference, example docs, and contract tests converge on one canonical "which API for which investigation question" story, and the milestone arc records the standing next-milestone order for future planning.

## Deferred Requirements

- **UI-01**: Publish a lightweight operator-facing surface on top of the stabilized investigation APIs.
- **ADOPT-05**: Compress first-hour adoption further once the new investigation APIs and example paths are real enough to teach directly.
- **POLICY-01**: Revisit richer policy and governance guardrails once real adopter workflows expose the sharpest gaps.
- **INTEG-01**: Broaden the integration surface beyond Phoenix + Sigra after the investigation backbone is easier to reuse across hosts.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Full LiveView operator UI | Valuable, but still better as a follow-on once the exploration contract stops moving under it. |
| Additional auth or framework adapters | Breadth is less urgent than making the current audit data materially easier to investigate. |
| Retention, redaction, or capture-engine redesign | v1.16 is about usable investigation workflows, not changing the capture substrate. |
| Generic tenancy or authorization policy framework | The example should keep proving host-owned boundaries, not invent an all-purpose policy layer. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EXPLORE-01 | Phase 53 | Complete |
| EXPLORE-02 | Phase 54 | Complete |
| INCIDENT-06 | Phase 55 | Pending |
| INCIDENT-07 | Phase 55 | Pending |
| ADOPT-04 | Phase 56 | Pending |

**Coverage:**
- v1.16 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0

---
*Requirements defined: 2026-05-05 after opening v1.16.*
