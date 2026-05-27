# Requirements: Threadline v1.25 — Adopter-Ready Release & First-Hour Truth

**Defined:** 2026-05-27
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Milestone goal:** Make the shipped v1.22–v1.24 stack truthfully adoptable from Hex and remove first-hour doc/example friction — without compliance expansion or a second synthetic walkthrough.

**Assessment source:** `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md` (~88–92% done for stated scope; no sustained real-adopter signal).

---

## v1 Requirements

### Release (Phase 114) — threadline 0.6.0

- [x] **REL-01**: Bump `threadline` to **0.6.0** with a dated CHANGELOG entry covering the v1.22–v1.24 in-repo stack (`Threadline.Evidence`, `Threadline.Audit.transaction/3`, operator/evidence surfaces, audited write-path helper).
- [x] **REL-02**: ExDoc module groups include `Threadline.Audit` and related public API docs introduced since 0.5.0.
- [x] **REL-03**: `mix verify.release` and release packaging checks pass on the current tree.
- [x] **REL-04**: `guides/adoption-pilot-backlog.md`, root README, and doc-contract SSOT reflect **threadline 0.6.0** / `~> 0.6`.

### Narrative docs (Phase 115) — Blessed write path

- [ ] **NARR-01**: `guides/how-threadline-works.md` centers `Threadline.Audit.transaction/3` as the recommended audited write path (not hand-rolled `record_action/2` recipes).
- [x] **NARR-02**: README, getting-started, and how-threadline-works cross-links agree on write-path guidance and discovery order.
- [x] **NARR-03**: Doc-contract tests lock at least one canonical `Audit.transaction/3` narrative literal in how-threadline-works (or equivalent SSOT guide).

### Example first-hour (Phase 116) — Reference app README

- [ ] **EXAMPLE-01**: `examples/threadline_phoenix/README.md` documents API auth staging for `POST /api/posts` curl examples (session/token or documented skip path).
- [ ] **EXAMPLE-02**: Clean-clone setup path distinguishes base install from `mix demo.seed` / `mix demo.reset` recovery — no implied seed on plain `ecto.setup`.
- [ ] **EXAMPLE-03**: Generator/migration confusion resolved (what `mix threadline.*` vs `mix ecto.*` vs demo tasks do; no contradictory first-hour steps).
- [ ] **EXAMPLE-04**: `mix verify.example` green after README/runbook changes; example doc-contract tests updated if literals change.

### Doc authority (Phase 117) — Evidence plane + semver prose

- [ ] **DOC-01**: Evidence-plane documentation has a single authoritative entry point — either a thin `guides/evidence-plane.md` hub cross-linking existing guides **or** PROJECT/README references fixed to point at the actual split guides (no dead `guides/evidence-plane.md` references).
- [ ] **DOC-02**: Adopter-facing prose uses Hex semver and package version vocabulary; internal milestone labels (v1.xx) relegated to maintainer/planning context only in adopter paths.
- [ ] **DOC-03**: `mix verify.doc_contract` green after evidence-plane and semver prose changes.

### Pilot prep (Phase 118) — Optional narrow slice

- [ ] **PILOT-01**: `guides/adoption-pilot-backlog.md` test counts and verification pointers refreshed to match current tree (`mix verify.*` totals, not stale phase counts).
- [ ] **PILOT-02**: External evaluator one-pager (README band or short guide section) states what 0.6.0 proves, what is host-owned, and canonical verify entrypoints — without STG attestation claims.

---

## v2 Requirements

Deferred until after v1.25 or on sustained adopter signal.

- **AUTH-BREADTH** — phx.gen.auth cookbook + proof path (queued v1.26)
- **EXTERNAL-PILOT** — pilot unblockers when sustained real-adopter signal exists
- **COMPLIANCE-PACK** — SOC2/HIPAA-flavored evidence bundles (v1.22 DEFER-01)
- **LEGAL-HOLD** — freeze against retention purge (v1.22 DEFER-02)
- **IMMUTABLE-ARCHIVE** — storage guarantees beyond append-only schema (v1.22 DEFER-03)
- **CONTAINER-WALK** — full docker-compose maintainer walk (discussed v1.23; not seeded unless demand)

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| New `Threadline.Evidence` subjects | v1.22 narrow plane unchanged |
| Threadline-owned RBAC / tenancy DSL | Boundary since v1.15 |
| Second full synthetic walkthrough | v1.23 satisfied maintainer path |
| Help-desk product UI expansion | Reference app stays sigra-reference |
| `threadline_web` package split | No adopter version-matrix pressure |
| Compliance packs / legal hold / immutable archive | DEFER trio — no sustained adopter signal |
| Container compose walk | Deferred unless explicit demand |
| phx.gen.auth breadth | Queued v1.26 — largest reach gap but separate milestone |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | 114 | Complete |
| REL-02 | 114 | Complete |
| REL-03 | 114 | Complete |
| REL-04 | 114 | Complete |
| NARR-01 | 115 | Pending |
| NARR-02 | 115 | Complete |
| NARR-03 | 115 | Complete |
| EXAMPLE-01 | 116 | Pending |
| EXAMPLE-02 | 116 | Pending |
| EXAMPLE-03 | 116 | Pending |
| EXAMPLE-04 | 116 | Pending |
| DOC-01 | 117 | Pending |
| DOC-02 | 117 | Pending |
| DOC-03 | 117 | Pending |
| PILOT-01 | 118 | Pending |
| PILOT-02 | 118 | Pending |

**Coverage:**

- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after milestone v1.25 kickoff*
