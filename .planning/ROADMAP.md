# Roadmap: Threadline

## Milestones

- ✅ **v1.21 Scoped Support / Operator Proof** — Phases 85-94, 21 plans, shipped 2026-05-25. Archive: `.planning/milestones/v1.21-ROADMAP.md`
- 🚧 **v1.22 Policy / Evidence Plane** — Phases 95-103, opened 2026-05-25

## Current Planning State

- Active milestone: **v1.22 Policy / Evidence Plane**
- This milestone builds on the shipped support-safe `/audit` lane without widening Threadline into a compliance platform.
- Use `.planning/MILESTONE-ARC.md` and `.planning/research/v1.22-policy-evidence-plane.md` as the authority surfaces for milestone scope.

## Milestone v1.22: Policy / Evidence Plane

**Status:** Gap closure planned
**Phases:** 95-103
**Total Plans:** 18 tracked

## Overview

v1.22 is a narrow evidence-plane milestone. It adds durable, append-only
evidence records for Threadline-owned governance facts, then exposes those
facts consistently through library APIs, Mix tasks, and read-only mounted
operator views. The milestone deliberately avoids becoming a compliance
platform, auth model, or legal-hold system.

The milestone strategy is:

- keep the host-owned auth and scope boundary intact
- keep evidence limited to Threadline-owned facts and posture
- reuse the existing `/audit` family for any mounted readouts
- provide no-Phoenix proof via API and Mix-task parity first
- lock public claims and negative claims with tests and docs

## Phases

### Phase 95: Evidence Model Lock And Scope Guard

**Goal**: Define the append-only evidence contract, subject set, and negative-claim boundary before UI or task expansion.
**Depends on**: Nothing
**Requirements**: EVID-01, EVID-02, EVID-03
**Plans**: 2 plans

- [x] 95-01: Evidence subject inventory, schema contract, and append-only semantics
- [x] 95-02: Boundary lock for host-owned auth/tenancy and non-goals

### Phase 96: Evidence Persistence And Public API

**Goal**: Persist evidence records and expose them through Phoenix-optional public APIs.
**Depends on**: Phase 95
**Requirements**: PROOF-01
**Plans**: 2 plans

- [ ] 96-01: Evidence persistence, changesets, and provenance capture
- [ ] 96-02: Public context/API for create/read flows

### Phase 97: Mix-Task And Machine-Readable Proof

**Goal**: Give operators and CI a stable no-Phoenix path to generate and inspect evidence outputs.
**Depends on**: Phase 96
**Requirements**: PROOF-02, PROOF-03
**Plans**: 2 plans

- [x] 97-01: Mix-task parity and stable JSON output
- [x] 97-02: Proof-language boundary and unsupported-claim handling

### Phase 98: Mounted Evidence Views On `/audit`

**Goal**: Present evidence records on the existing operator surface without adding a new UI family or permission model.
**Depends on**: Phase 96, Phase 97
**Requirements**: SURF-01, SURF-02, SURF-03
**Plans**: 2 plans

- [ ] 98-01: Read-only evidence navigation and view models on the existing `/audit` surface
- [ ] 98-02: Mounted/API/CLI parity and host-owned authorization wiring

### Phase 99: Contract Lock, Docs, And Final Verification

**Goal**: Freeze the evidence-plane claim with doc contracts, integration proof, and explicit non-goal language.
**Depends on**: Phase 98
**Requirements**: DOC-01, DOC-02, DOC-03
**Plans**: 2 plans

- [x] 99-01: Public docs, support-matrix wording, and negative-claim lock
- [x] 99-02: Current-tree verification, contract tests, and milestone closeout evidence

### Phase 100: Phase 95 Verification Backfill

**Goal**: Close the unverified Phase 95 evidence-model boundary with explicit current-tree proof and requirement closure.
**Depends on**: Phase 99
**Requirements**: EVID-01, EVID-02, EVID-03
**Gap Closure**: Closes Phase 95 verification-chain gaps from the v1.22 audit
**Plans**: 2 plans

- [x] 100-01: Re-verify the append-only evidence contract, subject inventory, and scope boundary on the current tree
- [x] 100-02: Add the Phase 95 verification artifact and requirement-closure evidence

### Phase 101: Phase 96 Verification Backfill

**Goal**: Close the unverified Phase 96 persistence and public API work with explicit proof for write/read behavior and Phoenix-optional usage.
**Depends on**: Phase 100
**Requirements**: PROOF-01
**Gap Closure**: Closes Phase 96 verification-chain gaps from the v1.22 audit
**Plans**: 2 plans

- [x] 101-01: Re-verify evidence persistence, provenance capture, and public create/read flows on the current tree
- [x] 101-02: Add the Phase 96 verification artifact and PROOF-01 closure evidence

### Phase 102: Phase 98 Verification Backfill

**Goal**: Close the unverified mounted evidence surface with explicit proof for `/audit` parity and host-owned authorization behavior.
**Depends on**: Phase 101
**Requirements**: SURF-01, SURF-02, SURF-03
**Gap Closure**: Closes Phase 98 verification-chain gaps from the v1.22 audit
**Plans**: 2 plans

- [x] 102-01: Re-verify mounted `/audit/evidence` navigation, parity, and fallback behavior on the current tree
- [x] 102-02: Add the Phase 98 verification artifact and SURF requirement-closure evidence

### Phase 103: Authority-Surface Reconciliation And Milestone Re-Audit

**Goal**: Reconcile the active milestone authority surfaces with the repaired evidence-plane status, then re-run closeout readiness on the current tree.
**Depends on**: Phase 102
**Gap Closure**: Closes the stale milestone-surface drift and final closeout-flow gaps from the v1.22 audit
**Plans**: 2 plans

- [ ] 103-01: Reconcile ROADMAP.md, REQUIREMENTS.md, and STATE.md with the repaired v1.22 closure state
- [ ] 103-02: Re-run milestone verification and audit for v1.22 closeout readiness

## Milestone Summary

**Target outcomes:**

- Threadline can persist durable evidence about its own governance and operator
  posture instead of relying only on runtime inspection and docs.

- The same evidence facts are available through public APIs, Mix tasks, and
  read-only mounted operator views.

- The project can answer procurement and audit-of-audit questions more
  credibly without inventing a compliance workflow product.

- Public docs state exactly what is proven and exactly what remains out of
  scope.

- The milestone authority surfaces and audit artifacts agree on the exact
  repaired status before closeout.

**Explicit non-goals:**

- No Threadline-owned RBAC, role DSL, or tenancy DSL.
- No legal-hold or policy approval workflow engine.
- No immutable-storage guarantee beyond the host runtime/storage contract.
- No vendor-specific reporting suite or generic compliance pack.
