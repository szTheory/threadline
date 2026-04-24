# Requirements: Threadline — milestone v1.7

**Defined:** 2026-04-23  
**Milestone:** v1.7 — Reference integration for SaaS  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.7 Requirements

Requirements for this milestone. Each maps to **one** roadmap phase (see traceability).

### Reference application (REF)

- [x] **REF-01**: Repository contains a **non-published** example Phoenix application (recommended path: `examples/threadline_phoenix/` or equivalent) that depends on **`threadline` via `:path`** to the repo root; **README** documents prerequisites (Elixir/OTP/Postgres), **`mix setup`** or equivalent, how to run the server, and how to run tests.
- [x] **REF-02**: Example applies **`mix threadline.install`** (or equivalent checked-in migrations), **`mix threadline.gen.triggers`** for at least **one** audited domain table, and **documents** the same **`MIX_ENV`** caveats as the root README for trigger regeneration.
- [x] **REF-03**: Example **HTTP stack** includes **`Threadline.Plug`** in the browser/API pipeline used for audited writes; a **controller or context** performs at least one **audited insert or update**; **automated test** or **documented curl/httpie** steps prove **`audit_changes`** (and transaction linkage) for that path.
- [ ] **REF-04**: Example includes an **Oban** worker that performs an **audited write** in a job using **`Threadline.Job`** (or a documented equivalent pattern from `Threadline.Job` docs); **automated test** covers actor/job linkage expectations.
- [ ] **REF-05**: Example includes at least **`record_action/2`** invocation for a representative intent (e.g. role or settings change) with a **short comment or guide note** explaining when to prefer actions vs row capture alone.
- [ ] **REF-06**: Example **README** links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** (STG audited-path rubric), stating that **host-class** evidence remains integrator-owned.

## Future Requirements

_Defer beyond v1.7 unless scope is explicitly reopened._

- **`Threadline.Query` / `Threadline.Export` expansions** — when pilots file repeated concrete pain (see archived v1.6 Future).
- **LiveView operator UI** — remains out of product scope for v0.x per `PROJECT.md`.

## Out of Scope

| Item | Reason |
|------|--------|
| Published Hex companion (`threadline_web`, umbrella split) | v1.7 is **example-only** integration surface |
| New capture / redaction / retention semantics | Integration milestone; library behavior already shipped |
| Maintainer attestation of third-party staging URLs | STG remains integrator-owned per v1.6 |
| Automated Hex publish policy change | Unchanged release process |

## Traceability

| Requirement | Phase | Status |
|---------------|-------|--------|
| REF-01 | Phase 22 | Complete |
| REF-02 | Phase 22 | Complete |
| REF-03 | Phase 23 | Complete |
| REF-04 | Phase 24 | Open |
| REF-05 | Phase 24 | Open |
| REF-06 | Phase 24 | Open |

**Coverage:** v1.7 requirements: **6** total — mapped: **6** — unmapped: **0** ✓
