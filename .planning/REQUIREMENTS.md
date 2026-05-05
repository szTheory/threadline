# Requirements: Threadline

**Defined:** 2026-05-05
**Milestone:** v1.15 — Host Integration Completion
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.15 Requirements

### PLUG — Native Host Context Overrides

- [x] **PLUG-01**: Phoenix hosts can supply additive request-derived audit context through `Threadline.Plug` without introducing a companion pre-plug solely for correlation or request metadata overrides.
- [x] **PLUG-02**: `Threadline.Plug` rejects invalid override shapes deterministically so hosts get a tight, testable public contract for `:context_overrides_fn`.

### SIGRA — Direct Sigra Host Wiring

- [x] **SIGRA-04**: `Threadline.Integrations.Sigra` composes directly with `Threadline.Plug` through native actor and context-override callbacks while preserving the soft-dependency contract.
- [x] **SIGRA-05**: The shipped Phoenix example app demonstrates the direct Sigra wiring pattern without an example-only companion plug.

### INCIDENT — Authenticated Incident Drill-down

- [x] **INCIDENT-03**: The example incident drill-down endpoint requires an authenticated actor before returning transaction changes.
- [x] **INCIDENT-04**: Incident drill-down docs distinguish the shipped auth baseline from host-owned tenancy and richer authorization rules, so adopters do not mistake the example for a full security model.

### ADOPT — Docs and Contract Alignment

- [x] **ADOPT-03**: Getting-started, Sigra integration, incident, and example runbook docs all align on the new native host-wiring pattern and are locked by targeted tests.

## Future Requirements (carried forward)

- **SIGRA-06**: Worked impersonation walkthrough beyond the base host-wiring contract, once adopter feedback confirms the exact operator story.
- **INCIDENT-05**: Tenant-scoped incident drill-down reference pattern once the example app carries a stable tenancy model.
- **UI-01**: Operator UI / `threadline_web` exploration surface after the host integration API settles and real adopter demand is clearer.

## Out of Scope

| Feature | Reason |
|---------|--------|
| LiveView operator UI | Still premature until the host integration and operator API surface stabilize further. |
| New capture / retention / export semantics | v1.15 is focused on host wiring and adoption completeness, not a core audit engine redesign. |
| Full tenancy framework in the example app | The milestone should demonstrate the auth boundary clearly without inventing a generic multi-tenant policy system. |
| Additional auth adapters beyond Sigra | Finish the current host-integration path before widening adapter breadth. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PLUG-01 | Phase 49 | Complete |
| PLUG-02 | Phase 49 | Complete |
| SIGRA-04 | Phase 50 | Complete |
| SIGRA-05 | Phase 50 | Complete |
| INCIDENT-03 | Phase 51 | Complete |
| INCIDENT-04 | Phase 51 | Complete |
| ADOPT-03 | Phase 52 | Complete |

**Coverage:**
- v1.15 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

---
*Requirements defined: 2026-05-05*
*Last updated: 2026-05-05 after Phase 52 execution*
