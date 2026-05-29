# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- ✅ **v1.26 Auth Lane Breadth** — Phases 119-121, shipped 2026-05-28. Archive: `.planning/milestones/v1.26-ROADMAP.md`
- ✅ **v1.27 Distribution & First-Hour Finish** — Phases 122-127, shipped 2026-05-28. Archive: `.planning/milestones/v1.27-ROADMAP.md`
- ✅ **v1.29 First-Hour Parity** — Phases 128-130, shipped 2026-05-29. Audit: `.planning/v1.29-MILESTONE-AUDIT.md`

## Current Planning State

**Milestone:** v1.29 — First-Hour Parity — **Complete** (2026-05-29)
**Status:** Hold — v1.28 External Pilot signal-gated; no adopter signal
**Last shipped:** v1.29 — First-Hour Parity (2026-05-29)
**Next step:** `/gsd-complete-milestone v1.29`

**Assessment:** v1.29 Phases 128–130 complete; Phase 130.1 closes audit planning-metadata remainder. Post-v1.27 path-to-done ~92%; remaining delta is doc parity + verify hygiene, not missing engine. No adopter signal — v1.28 deferred.

**Non-goals:** External pilot (v1.28); compliance DEFER trio; second reference app; evidence auto-population; Pow/bearer lane; Hex semver bump.

## Phases

- [x] **Phase 128: README + phx-gen-auth Mount Parity** — Close README Quick Start and phx-gen-auth mount footguns
- [x] **Phase 129: WALKTHROUGH Truth** — Fix verify cwd and row-history URL honesty in maintainer runbook (completed 2026-05-29)
- [x] **Phase 130: Verify & Planning Hygiene** — Nyquist finalize on Phase 125; SUMMARY frontmatter convention (completed 2026-05-28)

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

1. WALKTHROUGH optional verify uses `mix threadline.verify_coverage` from `examples/threadline_phoenix/` cwd (WALKTHROUGH §0). Contributor root gate: `mix verify.threadline` from repo root — alias to coverage policy per root mix.exs; not a walk-step command.
2. Row-history URLs in WALKTHROUGH match shipped transaction-scoped route or clearly distinguish shorthand from canonical path with navigation steps.
3. Doc-contract test locks verify cwd and row-history URL truth.

---

### Phase 130: Verify & Planning Hygiene

**Goal:** Close non-blocking planning debt from v1.27 gap-closure without widening product scope.

**Depends on:** Phases 128–129 (prefer adopter-facing truth green before planning metadata closeout).

**Requirements:** NYQ-01, PLAN-01

**Success Criteria:**

1. `125-VALIDATION.md` under `.planning/milestones/v1.27-phases/125-authority-surface-reconciliation/` signed `nyquist_compliant: true` with recorded green verification bundle.
2. SUMMARY frontmatter convention documents `requirements-completed` (hyphenated SSOT per `.planning/conventions/summary-frontmatter.md`); v1.27 gap-closure SUMMARYs (125–127) backfilled with GAP IDs.
3. `mix verify.doc_contract` and `mix ci.all` green at milestone closeout.

---

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 128 README + phx-gen-auth Mount Parity | v1.29 | 2/2 | Complete    | 2026-05-28 |
| 129 WALKTHROUGH Truth | v1.29 | 2/2 | Complete    | 2026-05-29 |
| 130 Verify & Planning Hygiene | v1.29 | 2/2 | Complete    | 2026-05-29 |
| 130.1 Planning Metadata Hygiene | v1.29 | 2/2 | Complete    | 2026-05-29 |

### Phase 130.1: Address tech debt: planning metadata hygiene (INSERTED)

**Goal:** Close residual v1.29 audit planning-metadata drift — align active ROADMAP/REQUIREMENTS authority with shipped product truth, document 130-VALIDATION honesty and Nyquist waivers for doc-only phases 128–129, without code changes or milestone archive.

**Requirements:** (audit-driven; no new REQ-IDs)
**Depends on:** Phase 130
**Plans:** 2/2 plans complete

**Success Criteria:**

1. ROADMAP header + Current Planning State reflect v1.29 Complete / Hold — not in-progress or ready for Phase 128.
2. ROADMAP Phase 129 SC#1 + REQUIREMENTS WALK-01 describe `mix threadline.verify_coverage` from `examples/threadline_phoenix/` cwd; root `mix verify.threadline` contributor alias only.
3. ROADMAP Phase 130 SC#2 uses hyphenated `requirements-completed` and cites `.planning/conventions/summary-frontmatter.md`.
4. `130-VALIDATION.md` Status column superseded footnote; `v1.29-MILESTONE-AUDIT.md` Nyquist waiver rows for 128–129.
5. `130.1-VERIFICATION.md` closure table + Tier 1 greps green + session-close `mix ci.all` green.

Plans:

**Wave 1** *(no dependencies)*

- [x] 130.1-01-PLAN.md — ROADMAP + REQUIREMENTS authority reconciliation + partial Tier 1 greps

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 130.1-02-PLAN.md — 130-VALIDATION footnote + audit Nyquist waiver + VERIFICATION closeout + STATE + `mix ci.all`

**Cross-cutting constraints:**

- No retroactive `128-VALIDATION.md` / `129-VALIDATION.md` with `nyquist_compliant: true` without rerun
- Charter test literal update deferred to `/gsd-complete-milestone v1.29` (D-130.1-08)
- Single `mix ci.all` at session close only — not per intermediate plan
