# Requirements: Threadline — v1.10

**Defined:** 2026-04-24  
**Milestone:** v1.10 — Support-grade exploration primitives  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.10 Requirements

### Exploration — support-grade primitives

- [x] **XPLO-01**: Integrator can obtain a **deterministic, JSON-serializable** structure describing **per-field** adds, updates, and removes for a single `%AuditChange{}`, using `data_after`, `changed_fields`, and `changed_from` when present; documented, explicit behavior for **INSERT** / **UPDATE** / **DELETE** and when **`changed_from` is `nil`** (no prior values).
- [ ] **XPLO-02**: Integrator can load **all** `%AuditChange{}` rows for a given **`audit_transactions.id`** via a documented **`Threadline.Query`** function and a **`Threadline`** delegator, with **stable ordering** (for incident reconstruction and API responses).
- [ ] **XPLO-03**: **`guides/domain-reference.md`** includes a **concise decision guide** (when to use `history/3`, `timeline/2`, export, correlation filters, transaction-scoped listing, diff helpers); at least one **cross-link** from existing **support** or **production-checklist** material; **doc contract test(s)** lock any **new** stable anchors introduced for v1.10.

## Future (after v1.10)

_Defer unless a later milestone explicitly reopens._

- LiveView or other **hosted** operator UI.
- **As-of** row reconstruction across arbitrary history (higher complexity than field diff on one change).
- **Automated** index or DDL recommendations from library code (integrator-owned DDL remains default).

## Out of scope (v1.10)

| Item | Reason |
|------|--------|
| LiveView operator UI | Explicit product deferral (`PROJECT.md`) |
| Published `threadline_web` companion | Packaging / umbrella deferral |
| New capture / redaction / retention **semantics** or migrations | Milestone is exploration **consumers** of existing capture |
| Maintainer attestation of third-party STG URLs | Unchanged integrator-owned policy |
| Hex semver bump | Separate release decision |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| XPLO-01 | Phase 31 | Complete |
| XPLO-02 | Phase 32 | Pending |
| XPLO-03 | Phase 33 | Pending |

**Coverage:** v1.10 requirements: **3** total — mapped: **3** — unmapped: **0** ✓

---

*Requirements defined: 2026-04-24 — milestone v1.10*
