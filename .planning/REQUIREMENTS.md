# Requirements: Threadline

**Defined:** 2026-04-23  
**Milestone:** v1.5 — Adoption feedback loop  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.5 Requirements

Integrator-led slice: tighten **operator documentation** and a **repeatable pilot backlog** so production adoption surfaces evidence-backed issues. No LiveView UI; no capture semantics change.

### Adoption — pilot process (Phase 19–20)

- [x] **ADOP-01**: Repository includes **`guides/adoption-pilot-backlog.md`** (shipped under `guides/` in the Hex package) with a checklist matrix aligned to **`guides/production-checklist.md`**, distribution preflight rows, in-repo CI parity notes, and an empty prioritized-issues table for the host team.
- [x] **ADOP-02**: Root **`README.md`** Documentation section links the adoption pilot backlog alongside the production checklist.
- [ ] **ADOP-03**: After the first external pilot, the backlog tables record at least one section as **`OK`** or **`Issue`** with evidence (logs, SQL, or issue links); maintainers triage **`Issue`** rows into GitHub issues or v1.6 requirements.

### Telemetry — operator reference (Phase 19)

- [x] **TELEM-01**: **`guides/domain-reference.md`** documents every **`[:threadline, …]`** `:telemetry.execute/3` event the library emits, including measurements and metadata maps, and states that retention purge is log-based unless the host wraps it.
- [x] **TELEM-02**: **`guides/production-checklist.md`** observability items link to the domain reference telemetry anchor.

## Future Requirements

_Defer beyond v1.5 unless pilot evidence forces reprioritization._

- Exploration-layer API expansions (`Threadline.Query` / `Threadline.Export`) — only when pilots file concrete repeated pain.
- LiveView or rich operator UI — remains out of scope per **`PROJECT.md`** until API-first adoption matures.

## Out of Scope (v1.5)

| Item | Reason |
|------|--------|
| New capture / trigger / redaction semantics | v1.5 is adoption feedback and docs |
| Automated `mix hex.publish` from CI policy change | Unchanged maintainer policy |
| Example Phoenix apps in-repo | README + guides first |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADOP-01 | Phase 19 | Complete |
| ADOP-02 | Phase 19 | Complete |
| TELEM-01 | Phase 19 | Complete |
| TELEM-02 | Phase 19 | Complete |
| ADOP-03 | Phase 20 | Pending |

**Coverage:** v1.5 requirements: 5 total — 4 complete in Phase 19; 1 pending Phase 20 (external pilot).

---
*Requirements defined: 2026-04-23 — milestone v1.5 opened.*
