# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- 🚧 **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118 (in progress)

## Current Planning State

**Milestone:** v1.25 — Adopter-Ready Release & First-Hour Truth
**Status:** Requirements defined; ready for phase planning
**Last shipped:** v1.24 — Audited Write Path & Adopter Truth (2026-05-27)

**Assessment:** Post-v1.24 adopter lens (~88–92% done for stated scope). Hex 0.5.0 stale vs in-repo stack; first-hour doc/example friction is the primary synthetic wedge. Thread: `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md`.

**Boundary contract:**

- **Phase 114** — `mix.exs` / CHANGELOG / ExDoc / `mix verify.release` for **0.6.0**; adoption-pilot version SSOT
- **Phase 115** — `guides/how-threadline-works.md` + narrative cross-links to `Audit.transaction/3`
- **Phase 116** — `examples/threadline_phoenix/README.md` first-hour friction (auth staging, demo.seed path, generator clarity)
- **Phase 117** — Evidence-plane doc authority + semver-not-milestone adopter prose
- **Phase 118** — Optional pilot-prep (backlog counts + evaluator one-pager)

**Non-goals:** No compliance packs / legal hold / immutable archive; no new Evidence subjects; no Threadline-owned RBAC; no second walkthrough; no `threadline_web` split; phx.gen.auth deferred to v1.26.

## Phases

- [x] **Phase 114: Release 0.6.0 Packaging** — Cut threadline 0.6.0 with changelog, ExDoc, verify.release, and adoption-pilot version SSOT. (completed 2026-05-27)
- [x] **Phase 115: Narrative Doc Sync** — Align how-threadline-works and cross-links to `Audit.transaction/3` as blessed write path. (completed 2026-05-27)
- [x] **Phase 116: Example First-Hour Fixes** — Repair example README auth staging, setup vs demo.seed, and generator/migration clarity. (completed 2026-05-27)
- [x] **Phase 117: Evidence Plane Doc Authority** — Single evidence-plane entry point; semver vocabulary in adopter prose. (completed 2026-05-27)
- [ ] **Phase 118: Pilot Prep (Optional)** — Refresh adoption-pilot counts; external evaluator one-pager.

## Phase Details

### Phase 114: Release 0.6.0 Packaging

**Goal:** Ship a truthful Hex release that packages the v1.22–v1.24 in-repo stack so evaluators are not stuck on 0.5.0.

**Depends on:** Nothing (first phase of v1.25).

**Requirements:** REL-01, REL-02, REL-03, REL-04

**Scope guard:** `mix.exs`, `CHANGELOG.md`, ExDoc config, release verify aliases, adoption-pilot + README version literals. No new library features unless release packaging exposes a doc gap.

**Success Criteria** (what must be TRUE):

1. `threadline` **0.6.0** is declared with a complete CHANGELOG section covering Evidence, Audit.transaction, and operator/evidence surfaces since 0.5.0.
2. ExDoc publishes `Threadline.Audit` and related new public modules in sensible module groups.
3. `mix verify.release` passes; adoption-pilot backlog and README doc contracts lock **0.6.0** / `~> 0.6`.

**Plans:** 3/3 plans complete

---

### Phase 115: Narrative Doc Sync

**Goal:** One coherent story for how audited writes work — centered on `Audit.transaction/3`, not legacy hand-rolled recipes.

**Depends on:** Phase 114 (recommended — version literals should match 0.6.0 narrative).

**Requirements:** NARR-01, NARR-02, NARR-03

**Scope guard:** `guides/how-threadline-works.md`, README/getting-started cross-links, doc-contract tests. No example app code changes unless snippets must match.

**Success Criteria** (what must be TRUE):

1. A first-time adopter reading how-threadline-works sees `Audit.transaction/3` as the primary write-path pattern.
2. README → getting-started → how-threadline-works discovery order is consistent (no conflicting `record_action/2`-first guidance).
3. Doc-contract tests lock at least one narrative literal for the blessed write path.

**Plans:** 2/2 plans complete

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1 | 01 | Retarget how-threadline-works + NARR-03 contract locks |
| 2 | 02 | README/getting-started discovery sync + cross-doc contracts + verify alias |

---

### Phase 116: Example First-Hour Fixes

**Goal:** A maintainer or evaluator can clone the example app and reach a first audited write without README traps.

**Depends on:** Phase 115 (recommended — narrative should match example runbook).

**Requirements:** EXAMPLE-01, EXAMPLE-02, EXAMPLE-03, EXAMPLE-04

**Scope guard:** `examples/threadline_phoenix/README.md`, example doc-contract tests, `mix verify.example`. No new domain features.

**Success Criteria** (what must be TRUE):

1. `POST /api/posts` curl examples document how to authenticate or explicitly label auth prerequisites.
2. Clean-clone path vs `mix demo.seed` / `mix demo.reset` is unambiguous in the README.
3. Threadline vs Ecto vs demo task responsibilities are clear; `mix verify.example` green.

**Plans:** 2/2 plans complete

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1 | 01 | API auth staging: router session plugs, sigra_conn fix, cookie curl docs, contract locks |
| 2 | 02 | README install restructure: Track A/B, mix task ownership, demo.seed clarity |

---

### Phase 117: Evidence Plane Doc Authority

**Goal:** Evaluators find evidence-plane documentation without dead links; adopter prose speaks in semver, not internal milestone labels.

**Depends on:** Phase 114 (version SSOT); may run partial fixes in parallel with 115–116.

**Requirements:** DOC-01, DOC-02, DOC-03

**Scope guard:** `guides/` evidence cross-links, PROJECT/README adopter bands, doc-contract tests. Optional thin `guides/evidence-plane.md` hub only if it reduces drift.

**Success Criteria** (what must be TRUE):

1. No adopter-facing doc references a missing evidence-plane guide without a redirect/hub.
2. Adopter paths (README, getting-started, adoption-pilot) use Hex semver vocabulary consistently.
3. `mix verify.doc_contract` green.

**Plans:** 2/2 plans complete

---

### Phase 118: Pilot Prep (Optional)

**Goal:** Lower friction for an external evaluator or pilot host without claiming maintainer STG attestation.

**Depends on:** Phases 114–117 (recommended — one-pager should describe shipped 0.6.0 truth).

**Requirements:** PILOT-01, PILOT-02

**Scope guard:** `guides/adoption-pilot-backlog.md`, README maintainer/evaluator band or short guide section. No new library APIs.

**Success Criteria** (what must be TRUE):

1. Adoption-pilot backlog test/verify counts match current tree entrypoints.
2. Evaluator one-pager states what 0.6.0 proves, host-owned boundaries, and canonical `mix verify.*` commands — without false STG claims.

**Plans:** 0 plans

---

*Roadmap created: 2026-05-27 — milestone v1.25*
