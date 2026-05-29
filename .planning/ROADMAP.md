# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- ✅ **v1.26 Auth Lane Breadth** — Phases 119-121, shipped 2026-05-28. Archive: `.planning/milestones/v1.26-ROADMAP.md`
- ✅ **v1.27 Distribution & First-Hour Finish** — Phases 122-127, shipped 2026-05-28. Archive: `.planning/milestones/v1.27-ROADMAP.md`
- 🚧 **v1.29 First-Hour Parity** — Phases 128-130 (in progress)

## Current Planning State

**Milestone:** v1.29 — First-Hour Parity
**Status:** Requirements defined; ready for Phase 128
**Last shipped:** v1.27 — Distribution & First-Hour Finish (2026-05-28)
**Next step:** `/gsd-discuss-phase 128` or `/gsd-plan-phase 128`

**Assessment:** Post-v1.27 path-to-done ~92%; remaining delta is doc parity + verify hygiene, not missing engine. No adopter signal — v1.28 deferred.

**Non-goals:** External pilot (v1.28); compliance DEFER trio; second reference app; evidence auto-population; Pow/bearer lane; Hex semver bump.

## Phases

- [x] **Phase 128: README + phx-gen-auth Mount Parity** — Close README Quick Start and phx-gen-auth mount footguns
- [x] **Phase 129: WALKTHROUGH Truth** — Fix verify cwd and row-history URL honesty in maintainer runbook (completed 2026-05-29)
- [ ] **Phase 130: Verify & Planning Hygiene** — Nyquist finalize on Phase 125; SUMMARY frontmatter convention

## Phase Details

### Phase 128: README + phx-gen-auth Mount Parity

**Goal:** Evaluators following README Quick Start or the phx-gen-auth lane hit no silent config failures and see a canonical scope-shaped mount example.

**Depends on:** Nothing (first phase of v1.29).

**Requirements:** README-01, README-02, TRIG-01, AUTH-MOUNT-01, AUTH-MOUNT-02

**Success Criteria:**

1. README Quick Start includes `config :threadline, ecto_repos: [MyApp.Repo]` before `mix threadline.install` / verify mix tasks.
2. Doc-contract test fails if README omits or misplaces `ecto_repos`.
3. README trigger step cross-links getting-started or production-checklist for table-selection SSOT.
4. phx-gen-auth guide mount snippet is scope-first and consistent with getting-started §9 / root integration test.
5. Doc-contract test locks phx-gen-auth mount literals.

---

### Phase 129: WALKTHROUGH Truth

**Goal:** Maintainers and evaluators walking `WALKTHROUGH.md` on a clean clone do not hit cwd lies or misleading row-history URLs.

**Depends on:** Phase 128 (prefer first-hour doc spine aligned before walkthrough polish).

**Requirements:** WALK-01, WALK-02, WALK-03

**Success Criteria:**

1. WALKTHROUGH `mix verify.threadline` instructions run from repo root or document cwd explicitly.
2. Row-history URLs in WALKTHROUGH match shipped transaction-scoped route or clearly distinguish shorthand from canonical path with navigation steps.
3. Doc-contract test locks verify cwd and row-history URL truth.

---

### Phase 130: Verify & Planning Hygiene

**Goal:** Close non-blocking planning debt from v1.27 gap-closure without widening product scope.

**Depends on:** Phases 128–129 (prefer adopter-facing truth green before planning metadata closeout).

**Requirements:** NYQ-01, PLAN-01

**Success Criteria:**

1. `125-VALIDATION.md` signed `nyquist_compliant: true` with recorded green verification bundle.
2. SUMMARY frontmatter convention documents `requirements_completed`; v1.27 phase SUMMARY files or planning note updated.
3. `mix verify.doc_contract` and `mix ci.all` green at milestone closeout.

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 128 README + phx-gen-auth Mount Parity | v1.29 | 2/2 | Complete    | 2026-05-28 |
| 129 WALKTHROUGH Truth | v1.29 | 2/2 | Complete    | 2026-05-29 |
| 130 Verify & Planning Hygiene | v1.29 | 0/? | Pending | — |
