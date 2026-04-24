# Requirements: Threadline

**Defined:** 2026-04-24
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.12 Requirements (Temporal Truth & Safety)

Focus on providing a stable, correct, and developer-friendly foundation for point-in-time row reconstruction.

### Core Reconstruction

- [ ] **ASOF-01**: `Threadline.as_of(Repo, Schema, id, timestamp)` returns a **Map** with string keys representing the record state at that point in time.
- [ ] **ASOF-02**: `as_of/4` works for **deleted records** (reconstructs from the last known state in `audit_changes`).
- [ ] **ASOF-03**: `as_of/4` supports an opt-in **`:cast`** option to return the data as an **Ecto Struct**.

### DX & Safety

- [ ] **ASOF-04**: **Loose Casting**: When `:cast` is used, the system ignores fields in the audit log that no longer exist in the current Ecto schema (permissive loading).
- [ ] **ASOF-05**: **Genesis Gap**: `as_of/4` returns `{:error, :before_audit_horizon}` if the timestamp predates the first audit entry for that record.
- [ ] **ASOF-06**: **Documentation**: Add a "Time Travel (As-of)" section to `guides/domain-reference.md` and update the Phoenix example README.

## Future Requirements

### Collection & Bulk (v1.13+)

- **COLL-01**: `Threadline.as_of_all(Repo, Schema, query, timestamp)` for point-in-time collection queries.
- **COLL-02**: `LATERAL JOIN` optimization for bulk reconstruction performance.

### Associations

- **ASOC-01**: As-of association loading (reconstruct relationships at time T).

## Out of Scope

| Feature | Reason |
|---------|--------|
| LiveView operator UI | Explicitly deferred until capture + semantics are proven stable. |
| Automated DDL/Index recommendations | Deferred to future ops-tooling milestone. |
| SIEM / event sourcing | Outside of project's defined product category. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ASOF-01 | Phase 38 | Pending |
| ASOF-02 | Phase 38 | Pending |
| ASOF-03 | Phase 39 | Pending |
| ASOF-04 | Phase 39 | Pending |
| ASOF-05 | Phase 38 | Pending |
| ASOF-06 | Phase 40 | Pending |

**Coverage:**
- v1.12 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-24*
*Last updated: 2026-04-24 after v1.12 initialization.*
