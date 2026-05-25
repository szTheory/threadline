# Milestone v1.21: Scoped Support / Operator Proof

**Status:** Active
**Phases:** 85-94
**Total Plans:** 22 tracked

## Overview

v1.21 is a narrow adopter-proof milestone. It turns the existing host-owned
`authorize_fn` + `scope_query_fn` seam into a truthful, first-party support
lane on the shipped `/audit` surface without widening Threadline into an auth,
tenancy, or compliance platform.

The milestone strategy is:

- keep one canonical `/audit` mount
- keep auth and tenant semantics host-owned
- keep exports as a separate privileged capability
- prove one exact support-lane claim on the current tree: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams
- keep coverage and policy surfaces explicit as admin/global or unsupported for support-scoped sessions
- lock docs, example behavior, and tests around that exact proven claim

## Phases

### Phase 85: Support-Lane Surface Audit & Claim Narrowing

**Goal**: The milestone claim, non-goals, and supported surface list are explicit before implementation starts.  
**Depends on**: Nothing  
**Plans**: 2 plans

- [x] 85-01: Support-lane surface audit and requirement lock
- [x] 85-02: Packaging / scope guard and support-matrix wording lock

### Phase 86: Scoped Read-Path Closure

**Goal**: Every support-visible read path is either scope-enforced or explicitly unavailable with proof.  
**Depends on**: Phase 85  
**Plans**: 3 plans

- [ ] 86-01-PLAN.md — Coverage dashboard authorization and routing
- [ ] 86-02-PLAN.md — Coverage UI badge explicit gating
- [ ] 86-03-PLAN.md — Row history and As-Of scoping implementation

### Phase 87: Canonical Mount Recipe & Example-App Proof

**Goal**: Adopters get one copy-pasteable `/audit` recipe and a runnable example that proves admin + support personas honestly.  
**Depends on**: Phase 86  
**Plans**: 2 plans

- [ ] 87-01-PLAN.md — Canonical `/audit` mount recipe and minimal surface controls
- [ ] 87-02-PLAN.md — Example Phoenix support-lane proof and doc alignment

### Phase 88: Denial / Fallback UX Closure

**Goal**: Support-scoped operators see least-surprise UX around unavailable actions and routes, especially export posture.  
**Depends on**: Phase 86, Phase 87  
**Plans**: 2 plans

- [x] 88-01: Export denial / affordance parity across LiveView and HTTP
- [x] 88-02: Unsupported-surface messaging and fallback transport closure

### Phase 89: Contract Lock & Final Verification

**Goal**: The named support lane is contract-tested, docs-locked, and verified on the current tree.  
**Depends on**: Phase 87, Phase 88  
**Plans**: 2 plans

- [x] 89-01: Public docs, support matrix, and example contract lock
- [x] 89-02: End-to-end verification and Nyquist closeout

### Phase 90: Phase 85 Verification Backfill

**Goal**: Close the unverified Phase 85 claim boundary with explicit current-tree proof and requirement closure.  
**Depends on**: Phase 89  
**Requirements**: SCOPE-03, AUTH-02, ADOPT-03  
**Gap Closure**: Closes Phase 85 verification-chain gaps from the v1.21 audit  
**Plans**: 1-2 plans

- [x] 90-01: Re-verify Phase 85 support-lane claim, callback contract, and minimal-controls boundary
- [x] 90-02: Add Phase 85 verification artifact and requirement closure evidence

### Phase 91: Phase 86 Verification Backfill

**Goal**: Close the unverified Phase 86 scoped read-path work with explicit proof for support-scoped visibility and row-history / as-of behavior.  
**Depends on**: Phase 90  
**Requirements**: SCOPE-01, SCOPE-02  
**Gap Closure**: Closes Phase 86 verification-chain gaps from the v1.21 audit  
**Plans**: 1-2 plans

- [x] 91-01: Re-verify scoped read-path enforcement on the current tree
- [x] 91-02: Add Phase 86 verification artifact and evidence for row-history / as-of truth

### Phase 92: Phase 87 Verification Backfill

**Goal**: Close the unverified canonical mount and example-app proof with explicit adopter-facing verification artifacts.  
**Depends on**: Phase 91  
**Requirements**: ADOPT-01, ADOPT-02  
**Gap Closure**: Closes Phase 87 verification-chain gaps from the v1.21 audit  
**Plans**: 1-2 plans

- [x] 92-01: Re-verify the canonical `/audit` mount recipe and example-app proof
- [x] 92-02: Add Phase 87 verification artifact and requirement closure evidence

### Phase 93: Phase 88 Verification Backfill

**Goal**: Close the unverified denial / fallback UX work with explicit proof across LiveView, HTTP, docs, and tests.  
**Depends on**: Phase 92  
**Requirements**: AUTH-01, UX-01, UX-02  
**Gap Closure**: Closes Phase 88 verification-chain gaps from the v1.21 audit  
**Plans**: 1-2 plans

- [x] 93-01: Re-verify export denial, fallback UX, and support-lane guidance on the current tree
- [x] 93-02: Add Phase 88 verification artifact and requirement closure evidence

### Phase 94: Authority-Surface Reconciliation & Milestone Re-Audit

**Goal**: Reconcile the active milestone authority surfaces around the exact proven support-lane clause, then re-run closeout readiness on the repaired tree.  
**Depends on**: Phase 93  
**Requirements**: DOC-01, DOC-02  
**Gap Closure**: Closes the last authority-surface drift and milestone closeout flow gaps from the v1.21 audit  
**Plans**: 2 plans

- [ ] 94-01: Reconcile active milestone authority surfaces with the verified support-lane contract
- [ ] 94-02: Re-run milestone verification and audit for v1.21 closeout readiness

## Milestone Summary

**Target outcomes:**

- Support-lane operator access is a real first-party Threadline lane, not just a callback pattern plus prose.
- The active milestone contract repeats the exact proven set: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams.
- Adopters get one canonical `/audit` recipe with host-owned auth and scope semantics.
- The example app, guides, and tests all prove the same support-lane story.

**Explicit non-goals:**

- No Threadline-owned RBAC, role DSL, or tenancy DSL.
- No separate first-class support UI family.
- No broad policy/compliance expansion in this milestone.
- No new package split or `threadline_web` extraction work.
in this milestone.
- No new package split or `threadline_web` extraction work.
