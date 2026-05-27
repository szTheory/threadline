# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, 21 plans, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, 18 plans, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, 24 plans, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- 🚧 **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113 (in progress)

## Current Planning State

**Milestone:** v1.24 — Audited Write Path & Adopter Truth
**Status:** Defining requirements (roadmap drafted 2026-05-27)
**Last shipped:** v1.23 — realistic-demo walkthrough (2026-05-27)

**Assessment:** Milestone-next-step adopter lens (~83% done for stated scope). Confirmed scope without sustained external adopter signal. Thread: `.planning/threads/2026-05-27-milestone-next-step-v1.24.md`.

**Boundary contract:**

- **Phase 111** — `lib/threadline/` helper + tests + guide/doc contracts for helper API
- **Phase 112** — `examples/threadline_phoenix/` + `guides/getting-started-saas.md` adopt helper
- **Phase 113** — `examples/` + `guides/` doc truth (`evidence_authorize_fn`, 0.5.x pilot table, evidence CLI naming, WR-110-001); no new Evidence subjects

**Non-goals:** No compliance packs / legal hold / immutable archive; no Threadline-owned RBAC; no second walkthrough; no help-desk product expansion.

## Phases

- [ ] **Phase 111: Audited Write-Path Helper** — Ship `Threadline.Audit.transaction/2` (or equivalent) with PostgreSQL integration tests and doc contracts.
- [ ] **Phase 112: Reference App Adopts Helper** — Refactor example write paths and getting-started guide to use the helper; keep correlation/audit tests green.
- [ ] **Phase 113: Adopter Truth & Doc Sync** — Wire `evidence_authorize_fn` in example mount; sync adoption-pilot to 0.5.x; align evidence CLI naming; fix WALK-03-02 prose (WR-110-001).

## Phase Details

### Phase 111: Audited Write-Path Helper

**Goal:** Make the trustworthy capture+semantics write path a single documented library call instead of a copy-pasted transaction recipe.

**Depends on:** Nothing (first phase of v1.24).

**Requirements:** AUDIT-TXN-01, AUDIT-TXN-02, AUDIT-TXN-03, AUDIT-TXN-04

**Scope guard:** `lib/threadline/` + `test/threadline/` + `guides/` (helper documentation only). Example app deferred to Phase 112.

**Success Criteria** (what must be TRUE):

1. A Phoenix SaaS developer can wrap audited writes in one helper call and receive `audit_transaction_id` when applicable.
2. Strict `:correlation_id` timeline filters work when the helper records and links an action in the same transaction.
3. Doc-contract tests lock the public helper signature and at least one getting-started/integration-contract snippet.

**Plans:** 0 plans drafted

---

### Phase 112: Reference App Adopts Helper

**Goal:** Prove the helper on the sigra-reference example app and align the first-hour guide with the same pattern.

**Depends on:** Phase 111.

**Requirements:** ADOPT-HELPER-01, ADOPT-HELPER-02, ADOPT-HELPER-03

**Scope guard:** `examples/threadline_phoenix/` + `guides/getting-started-saas.md` + README cross-links. `lib/` read-only except bugfixes blocking example adoption.

**Success Criteria** (what must be TRUE):

1. Primary example write paths use the helper; hand-rolled `set_config` blocks are removed or reduced to documented escape hatches.
2. `mix verify.example` and existing audit/correlation tests pass without weakened assertions.
3. Getting-started guide snippets match example app implementation.

**Plans:** 0 plans drafted

---

### Phase 113: Adopter Truth & Doc Sync

**Goal:** Repair reference and doc drift so 0.5.x evaluators see an honest sigra-reference lane including evidence UI and aligned CLI/version literals.

**Depends on:** Phase 112 (recommended; may run partial doc fixes in parallel if helper unchanged).

**Requirements:** TRUTH-01, TRUTH-02, TRUTH-03, TRUTH-04, TRUTH-05

**Scope guard:** `examples/threadline_phoenix/`, `guides/`, doc-contract tests. No new Evidence subjects; no `lib/` unless TRUTH-03 alias requires a thin Mix task wrapper.

**Success Criteria** (what must be TRUE):

1. Admin users on the example app can open `/audit/evidence` when `evidence_authorize_fn` grants access; docs state support denial explicitly.
2. Adoption-pilot backlog cites **0.5.0** / `~> 0.5` consistently with README and `mix.exs`.
3. Evidence CLI naming is single-canonical with doc-contract coverage; WR-110-001 prose fixed.
4. `mix verify.doc_contract` and `mix verify.example` green.

**Plans:** 0 plans drafted

---

## Prior milestone phases (archived)

v1.23 phases 104–110 remain under `.planning/phases/` for reference. Archive target on v1.24 closeout: `.planning/milestones/v1.23-phases/`.
