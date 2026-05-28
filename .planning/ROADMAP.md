# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- 🚧 **v1.26 Auth Lane Breadth** — Phases 119-121 (in progress)

## Current Planning State

**Milestone:** v1.26 — Auth Lane Breadth
**Status:** Requirements defined; ready for `/gsd-discuss-phase 119` or `/gsd-plan-phase 119`
**Last shipped:** v1.25 — Adopter-Ready Release & First-Hour Truth (2026-05-28)

**Assessment:** Diminishing-returns review (~88–92% done for stated scope). Largest reach gap is **phx.gen.auth-style** proof outside `sigra-reference`. Thread: `.planning/threads/2026-05-27-diminishing-returns-assessment.md`.

**Boundary contract:**

- **Phase 119** — `guides/integrations/phx-gen-auth.md` + `phx-gen-auth-reference` lane in upgrade-path
- **Phase 120** — Root integration tests proving Plug + authorize_fn patterns (no example-app auth swap)
- **Phase 121** — Getting-started auth neutrality + doc-contract locks

**Non-goals:** Second reference app; replace Sigra example; Threadline-owned auth; compliance DEFER trio; external pilot (deferred until sustained adopter signal).

**Maintainer ops (parallel):** Push tag **`v0.6.0`** when ready — hex.pm latest is still **0.5.0**; see `guides/adoption-pilot-backlog.md` Distribution preflight.

## Phases

- [x] **Phase 119: phx.gen.auth Integration Guide & Lane** — Cookbook + upgrade-path `phx-gen-auth-reference` lane. (pending) (completed 2026-05-28)
- [ ] **Phase 120: Root Auth Integration Proof** — CI-backed tests for Plug actor + operator authorize_fn without Sigra. (pending)
- [ ] **Phase 121: Adopter Doc Neutrality** — Getting-started §5 neutrality; README/evaluator cross-links; doc contracts. (pending)

## Phase Details

### Phase 119: phx.gen.auth Integration Guide & Lane

**Goal:** Document the majority Phoenix auth lane with the same honesty as `guides/integrations/sigra.md`, and name it in the upgrade-path matrix.

**Depends on:** Nothing (first phase of v1.26).

**Requirements:** AUTH-GUIDE-01, AUTH-GUIDE-02, AUTH-GUIDE-03, AUTH-LANE-01, AUTH-LANE-02

**Success Criteria:**

1. An integrator on `phx.gen.auth` can copy Plug and operator mount snippets without reading Sigra docs.
2. Upgrade path lists `phx-gen-auth-reference` with `reference` claim type and proof pointers (guide + tests).
3. Guide non-goals match PROJECT.md host-owned auth boundary.

---

### Phase 120: Root Auth Integration Proof

**Goal:** CI proves the cookbook patterns work — without mutating the Sigra reference example app.

**Depends on:** Phase 119 (snippets and lane name must exist).

**Requirements:** AUTH-PROOF-01, AUTH-PROOF-02, AUTH-PROOF-03

**Success Criteria:**

1. Root tests exercise `actor_ref` from phx.gen.auth-shaped conn assigns.
2. Tests exercise allow/deny for a minimal `authorize_fn` admin gate.
3. `mix verify.test` and `mix verify.doc_contract` green.

---

### Phase 121: Adopter Doc Neutrality

**Goal:** First-hour docs do not read as Sigra-required; discovery points at both reference lanes.

**Depends on:** Phases 119–120 (guide and proof must exist).

**Requirements:** ADOPT-AUTH-01, ADOPT-AUTH-02, ADOPT-AUTH-03

**Success Criteria:**

1. Getting-started §5 is auth-agnostic first; Sigra is an optional reference link.
2. README and evaluating guide link phx.gen.auth guide and upgrade-path lane.
3. Doc-contract tests lock neutrality literals and lane matrix row.

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 119 phx.gen.auth Guide & Lane | v1.26 | 2/2 | Complete   | 2026-05-28 |
| 120 Root Auth Proof | v1.26 | 0/? | Pending | — |
| 121 Adopter Doc Neutrality | v1.26 | 0/? | Pending | — |
