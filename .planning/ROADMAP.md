# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- ✅ **v1.26 Auth Lane Breadth** — Phases 119-121, shipped 2026-05-28. Archive: `.planning/milestones/v1.26-ROADMAP.md`
- 🚧 **v1.27 Distribution & First-Hour Finish** — Phases 122-124 (in progress)

## Current Planning State

**Milestone:** v1.27 — Distribution & First-Hour Finish
**Status:** Roadmap defined; ready for `/gsd-discuss-phase 122` or `/gsd-plan-phase 122`
**Last shipped:** v1.26 — Auth Lane Breadth (2026-05-28)

**Assessment:** Post-v1.26 thread (~90–93% done for stated scope). Remaining delta is distribution truth (hex.pm 0.5.0 vs in-repo 0.6.0) and first-hour footguns (`ecto_repos`, doc carry-forward). Thread: `.planning/threads/2026-05-28-milestone-next-step-post-v1.26.md`.

**Boundary contract:**

- **Phase 122** — Hex 0.6.0 publish + adoption-pilot / CHANGELOG distribution truth
- **Phase 123** — `ecto_repos` in getting-started + doc contract + production-checklist
- **Phase 124** — §6 neutrality, ADOPT-AUTH strict contracts, `:schemas` + evidence host-write docs, integration-contracts four-lane SSOT

**Non-goals:** External pilot (v1.28); compliance DEFER trio; second reference app; evidence auto-population; Pow/bearer lane.

## Phases

- [x] **Phase 122: Release & Distribution Truth** — Publish 0.6.0 to hex.pm; honest adoption-pilot and CHANGELOG surfaces (2026-05-28)
- [x] **Phase 123: First-Hour Config** — Document `ecto_repos` for mix tasks and operator fallbacks (2026-05-28)
- [ ] **Phase 124: Adopter Doc Finish** — Close v1.26 audit carry-forward and operator expectation gaps (pending)

## Phase Details

### Phase 122: Release & Distribution Truth

**Goal:** Evaluators can install the shipped stack from hex.pm at **0.6.0**; maintainer and adopter docs no longer imply 0.5.0 is latest.

**Depends on:** Nothing (first phase of v1.27).

**Requirements:** DIST-01, DIST-02, DIST-03

**Success Criteria:**

1. Tag **`v0.6.0`** pushed; CI hex publish succeeds; hex.pm **`threadline`** latest is **0.6.0**.
2. Adoption-pilot backlog **Published** row and distribution preflight match hex.pm reality.
3. CHANGELOG 0.6.0 entry documents four-lane matrix including **phx-gen-auth-reference**.

---

### Phase 123: First-Hour Config

**Goal:** Adopters discover `ecto_repos` on day one — before any mix task fails with an opaque repo resolution error.

**Depends on:** Phase 122 (optional parallel; no hard code dependency — prefer 122 first so evaluators test against published Hex).

**Requirements:** CFG-01, CFG-02, CFG-03

**Success Criteria:**

1. Getting-started Base install includes `config :threadline, ecto_repos: [MyApp.Repo]` with brief rationale.
2. Doc-contract test fails if `ecto_repos` guidance is removed or misplaced.
3. Production checklist points operators at the same config for mix tasks and mounted surface.

---

### Phase 124: Adopter Doc Finish

**Goal:** First-hour and operator docs match shipped behavior; v1.26 audit soft-gaps are contract-locked.

**Depends on:** Phases 122–123 (evaluator path and config truth should exist before polish).

**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05

**Success Criteria:**

1. Getting-started §6 does not read as Sigra-only for session/cookie staging.
2. ADOPT-AUTH strict literals are doc-contract locked.
3. Operator-surface guide documents **`:schemas`** for row history.
4. Evidence host-write expectation is explicit in narrative docs.
5. Integration-contracts and upgrade-path share the same four-lane vocabulary; doc contract green.

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 122 Release & Distribution Truth | v1.27 | 3/3 | Complete    | 2026-05-28 |
| 123 First-Hour Config | v1.27 | 2/2 | Complete | 2026-05-28 |
| 124 Adopter Doc Finish | v1.27 | 0/0 | Pending | — |
