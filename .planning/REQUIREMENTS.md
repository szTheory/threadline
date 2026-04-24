# Requirements: Threadline — v1.6

**Defined:** 2026-04-23  
**Milestone:** v1.6 — Host staging / pooler parity (STG-01)  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.6 Requirements

Formal acceptance for **host-owned** staging or production-like proof beyond **`verify-pgbouncer-topology`** on `main`. Library CI already exercises **PgBouncer `POOL_MODE=transaction`** for **`mix verify.topology`** and **`mix verify.threadline`** — see **`guides/adoption-pilot-backlog.md`** and archived [v1.5 STG-01](milestones/v1.5-REQUIREMENTS.md#stg-01).

### Staging / topology (STG)

- [ ] **STG-01**: Integrator publishes a **topology narrative** for their **staging or production-like** environment: **application → pooler (if any) → PostgreSQL**, pooler product and **mode** (e.g. transaction vs session) when a pooler exists, and **matches production topology: yes / no / partial** with a one-paragraph rationale.
- [ ] **STG-02**: Integrator records **≥ one HTTP-request** path that performs an audited write (rows appear in Threadline audit tables with expected **actor / transaction** linkage) and **≥ one asynchronous job path** (e.g. Oban) using **`Threadline.Job`** (or documented equivalent), each with status **OK**, **Issue**, or **N/A** plus **evidence** (log excerpt, SQL, redacted config, or link to issue/PR).
- [ ] **STG-03**: **`guides/adoption-pilot-backlog.md`** (or a **linked host-maintained** copy noted in the backlog intro) is updated so **Connection topology** and any rows **STG-01** implies reflect the integrator outcome — no **OK** without evidence pointer.

## Future Requirements

_Defer beyond v1.6 unless STG evidence opens a tracked defect._

- **`Threadline.Query` / `Threadline.Export` expansions** — only when pilots file repeated concrete pain (per `PROJECT.md`).
- **In-repo Phoenix sample app** — deferred; guides remain the integration surface.

## Out of Scope

| Item | Reason |
|------|--------|
| New capture / trigger / redaction semantics | v1.6 is evidence and documentation for existing behavior |
| LiveView or operator UI | Unchanged product boundary |
| Maintainer claiming third-party staging URLs | Evidence is **integrator-owned**; maintainers merge doc updates and optional templates only |
| Automated `mix hex.publish` policy change | Unchanged release process |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| STG-01 | Phase 21 | Pending |
| STG-02 | Phase 21 | Pending |
| STG-03 | Phase 21 | Pending |

**Coverage:** v1.6 requirements: **3** total — mapped: **3** — unmapped: **0** ✓

---
*Requirements defined: 2026-04-23 — milestone v1.6*  
*Last updated: 2026-04-23 after `/gsd-new-milestone` (research + roadmap)*
