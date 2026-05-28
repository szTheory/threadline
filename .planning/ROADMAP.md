# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- ✅ **v1.26 Auth Lane Breadth** — Phases 119-121, shipped 2026-05-28. Archive: `.planning/milestones/v1.26-ROADMAP.md`
- 🚧 **v1.27 Distribution & First-Hour Finish** — Phases 122-127 (gap closure; audit: `.planning/milestones/v1.27-MILESTONE-AUDIT.md`)

## Current Planning State

**Milestone:** v1.27 — Distribution & First-Hour Finish
**Status:** Phases 122–124 complete; gap closure phases 125–127 added (2026-05-28 audit)
**Last shipped:** v1.26 — Auth Lane Breadth (2026-05-28) — v1.27 ship pending Phase 125
**Next step:** `/gsd-plan-phase 125`

**Assessment:** v1.27 requirements satisfied (11/11); closeout hygiene remains — doc-contract charter drift, stale `STATE.md` / `MILESTONE-ARC.md`, Nyquist sign-off, optional example-app `:schemas` demo.

**Gap closure contract (from v1.27 audit):**

- **Phase 125** — Authority-surface reconciliation + `mix verify.doc_contract` green
- **Phase 126** — Nyquist validation sign-off for phases 122–124
- **Phase 127** — Example app `:schemas` demonstration (D-14 deferred in 124)

**Non-goals:** External pilot (v1.28); compliance DEFER trio; second reference app; evidence auto-population; Pow/bearer lane.

## Phases

- [x] **Phase 122: Release & Distribution Truth** — Publish 0.6.0 to hex.pm; honest adoption-pilot and CHANGELOG surfaces (2026-05-28)
- [x] **Phase 123: First-Hour Config** — Document `ecto_repos` for mix tasks and operator fallbacks (2026-05-28)
- [x] **Phase 124: Adopter Doc Finish** — Close v1.26 audit carry-forward and operator expectation gaps (completed 2026-05-28)
- [ ] **Phase 125: Authority-Surface Reconciliation** — Fix charter doc contract; reconcile STATE, MILESTONE-ARC, ROADMAP; green `mix verify.doc_contract`
- [ ] **Phase 126: Nyquist Validation Sign-off (122–124)** — Sign off `nyquist_compliant` on phases 122–124 VALIDATION.md
- [ ] **Phase 127: Example App `:schemas` Demonstration** — Wire runnable `:schemas` contract in `examples/threadline_phoenix` (D-14)

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

### Phase 125: Authority-Surface Reconciliation

**Goal:** Reconcile planning authority surfaces with shipped v1.27 evidence and restore a green doc-contract gate.

**Depends on:** Phase 124

**Gap Closure:** Closes v1.27 audit integration gaps (charter doc contract, STATE.md, MILESTONE-ARC.md, ROADMAP closeout)

**Success Criteria:**

1. `v1_23_charter_doc_contract_test.exs` aligns with `PROJECT.md` `## Latest Milestone Shipped:` heading pattern.
2. `.planning/STATE.md` reflects v1.27 shipped posture (not executing / v1.26 last shipped).
3. `.planning/MILESTONE-ARC.md` lists v1.27 shipped and Hex **0.6.0** thesis.
4. `mix verify.doc_contract` and `mix ci.all` pass on the reconciled tree.

---

### Phase 126: Nyquist Validation Sign-off (122–124)

**Goal:** Close Nyquist validation drift on all three v1.27 delivery phases.

**Depends on:** Phase 125 (prefer authority surfaces reconciled first)

**Gap Closure:** Closes v1.27 audit tech debt — `nyquist_compliant: false` on phases 122–124

**Success Criteria:**

1. `122-VALIDATION.md` signed `nyquist_compliant: true` via `/gsd-validate-phase 122`.
2. `123-VALIDATION.md` signed `nyquist_compliant: true` via `/gsd-validate-phase 123`.
3. `124-VALIDATION.md` signed `nyquist_compliant: true` via `/gsd-validate-phase 124`.

---

### Phase 127: Example App `:schemas` Demonstration

**Goal:** Runnable reference app demonstrates operator-surface `:schemas` row-history reification (docs-only gap from Phase 124 D-14).

**Depends on:** Phase 125 (optional parallel with 126)

**Gap Closure:** Closes v1.27 audit flow gap — first-hour `:schemas` path documented but not demonstrated in example app

**Success Criteria:**

1. `examples/threadline_phoenix` router mounts operator surface with `:schemas` for help-desk tables.
2. Getting-started §9 mount snippet matches runnable wiring.
3. Contract or walkthrough evidence proves `/audit/rows/:table/:pk` reification path.

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 122 Release & Distribution Truth | v1.27 | 3/3 | Complete    | 2026-05-28 |
| 123 First-Hour Config | v1.27 | 2/2 | Complete    | 2026-05-28 |
| 124 Adopter Doc Finish | v1.27 | 3/3 | Complete    | 2026-05-28 |
| 125 Authority-Surface Reconciliation | v1.27 | 0/0 | Not started | — |
| 126 Nyquist Validation Sign-off (122–124) | v1.27 | 0/0 | Not started | — |
| 127 Example App `:schemas` Demonstration | v1.27 | 0/0 | Not started | — |
