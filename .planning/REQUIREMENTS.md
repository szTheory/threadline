# Requirements: v1.21 - Scoped Support / Operator Proof

**Defined:** 2026-05-24
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1 Requirements

### Scoped Read Paths (SCOPE)

- [ ] **SCOPE-01**: Support-scoped operators can only see records allowed by the host-owned scope across the supported `/audit` read paths.
- [ ] **SCOPE-02**: Row history / as-of behavior for support-scoped sessions is honest and enforced end to end: either scope-aware with proof, or explicitly unavailable with proof and user-facing messaging.
- [ ] **SCOPE-03**: The support-lane claim names exactly which operator surfaces are proven safe today and excludes the rest.

### Authorization & Export Posture (AUTH)

- [ ] **AUTH-01**: Support-scoped operators are read-only by default and cannot use export endpoints unless the host explicitly opts in through `export_authorize_fn`.
- [ ] **AUTH-02**: One shared `%{assigns: assigns}` authorization callback remains the canonical contract across LiveView and HTTP export faces, with stable telemetry on granted / denied / error outcomes.

### Adopter Recipes & Minimal Controls (ADOPT)

- [ ] **ADOPT-01**: Threadline ships one canonical `/audit` mount recipe showing admin and support personas on the same host-owned route tree.
- [ ] **ADOPT-02**: The example Phoenix app proves the canonical support lane with host-owned `scope_query_fn` narrowing and admin-only export posture.
- [ ] **ADOPT-03**: Any new surface controls added in this milestone stay minimal and additive; Threadline does not introduce a role DSL, tenancy DSL, or policy engine.

### Operator UX & Proof (UX)

- [ ] **UX-01**: Support-scoped operators get least-surprise UX: export affordances hidden when unavailable, export URLs still deny server-side, and unsupported support-lane views show explicit fallback messaging.
- [ ] **UX-02**: Support-lane docs and example behavior stay aligned on fallback transports and “what to do instead” when a support-scoped operator hits an unavailable surface.

### Documentation & Verification (DOC)

- [ ] **DOC-01**: Public guides, example docs, and support-matrix guidance explicitly distinguish what Threadline proves, what remains host-owned, and what is out of scope for v1.21.
- [ ] **DOC-02**: Contract and integration tests lock the named support lane end to end on the current tree.

## v2 Requirements

### Policy / Evidence Plane

- **EVID-01**: Durable policy snapshots and audit-of-audit evidence for Threadline-owned governance surfaces.
- **EVID-02**: Read-only operator evidence views plus Mix-task parity for procurement and compliance handoff.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Threadline-owned RBAC or role DSL | Auth and role meaning stay host-owned; adding a DSL would overreach the library boundary. |
| Threadline-owned tenancy DSL | Host apps own org / tenant semantics; Threadline carries opaque scopes only. |
| Separate first-class `/support` product tree | The least-surprise recipe is one canonical `/audit` mount with scoped support behavior, not a second UI family. |
| Broad policy / compliance expansion | This belongs in a later narrow evidence-plane milestone after the support lane is honestly proven. |
| Support export access by default | Export is a separate privileged capability and should remain explicit, not inherited from read-only support access. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCOPE-01 | Phase 86 | Pending |
| SCOPE-02 | Phase 86 | Pending |
| SCOPE-03 | Phase 85 | Pending |
| AUTH-01 | Phase 88 | Pending |
| AUTH-02 | Phase 85 | Pending |
| ADOPT-01 | Phase 87 | Pending |
| ADOPT-02 | Phase 87 | Pending |
| ADOPT-03 | Phase 85 | Pending |
| UX-01 | Phase 88 | Pending |
| UX-02 | Phase 88 | Pending |
| DOC-01 | Phase 89 | Pending |
| DOC-02 | Phase 89 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after milestone v1.21 definition*
