# Roadmap: v1.20 - Scale and Governance Depth

## Phases

- [x] **Phase 75: Governance Infrastructure & State** - Introduce core DB schemas and backend Behaviours for storage and queuing.
- [x] **Phase 76: Batched Retention & UI** - Implement autovacuum-aware DB pruning and a Retention History LiveView.
- [ ] **Phase 77: Saved Views Ergonomics** - Allow operators to save and manage timeline queries using host actor ownership.
- [ ] **Phase 78: Async Exports & UI** - Shift massive CSV exports to background tasks with a status page and file cleanup.
- [x] **Phase 79: Scale Adapters** - Provide opt-in S3 and Oban integrations for multi-node deployments.
- [x] **Phase 80: Governance Verification & Milestone Surface Repair** - Reconcile milestone evidence and planning state with the audit before closeout resumes.
- [x] **Phase 81: Retention Runtime Closure** - Finish retention supervision and verification so pruning works end to end by default.
- [ ] **Phase 82: Saved Views Session Handoff Repair** - Repair actor/session handoff so saved views are reliably actor-owned in normal mounts.
- [ ] **Phase 83: Built-In Async Export Lifecycle Repair** - Make the default background export runtime and cleanup path operational and verified.
- [ ] **Phase 84: Export Delivery & Scale Adapter Integration Repair** - Complete download, Oban, and S3 integration for real export delivery across adapters.

## Phase Details

### Phase 75: Governance Infrastructure & State
**Goal**: Foundations for background operations and DB state are established.
**Depends on**: Nothing
**Requirements**: INFRA-01, INFRA-02
**Success Criteria** (what must be TRUE):
  1. Adopters can run DB migrations to create `threadline_export_jobs`, `threadline_retention_runs`, and `threadline_saved_views` schemas.
  2. Developers can reference explicit `Threadline.Storage` and `Threadline.ExportQueue` behaviours for custom backend implementations.
**Plans**: 1 plan
- [x] 75-01-PLAN.md — Governance migrations, schemas, and backend behaviours

### Phase 76: Batched Retention & UI
**Goal**: Operators can safely prune old records and monitor deletions.
**Depends on**: Phase 75
**Requirements**: RET-01, RET-02, RET-03
**Success Criteria** (what must be TRUE):
  1. System administrator can run a retention pruner that deletes rows in chunked batches, avoiding long-running table locks.
  2. The system accurately tracks start/stop times and deleted row counts for each run.
  3. Operator can view a history of past and active retention runs inside the LiveView UI.
**Plans**: 2 plans
- [x] 76-01-PLAN.md — Core Batched Pruning and Run Tracking
- [x] 76-02-PLAN.md — Retention History LiveView
**UI hint**: yes

### Phase 77: Saved Views Ergonomics
**Goal**: Operators can save and re-run common filter states.
**Depends on**: Phase 75
**Requirements**: VIEW-01, VIEW-02
**Success Criteria** (what must be TRUE):
  1. Operator can save their current timeline filter combination with a custom name.
  2. Operator can see a list of their previously saved views and click one to apply it to the timeline.
  3. Operators only see saved views owned by their specific host actor identity.
**Plans**: 2 plans
- [x] 77-01-PLAN.md — Core Session Plug & Auth updates
- [x] 77-02-PLAN.md — Saved Views UI
**UI hint**: yes

### Phase 78: Async Exports & UI
**Goal**: Operators can generate massive CSV exports in the background and download them safely.
**Depends on**: Phase 75
**Requirements**: EXP-01, EXP-02, EXP-03, EXP-04
**Success Criteria** (what must be TRUE):
  1. Operator can request a background export of the current timeline that streams massive datasets to local storage without blocking the UI.
  2. Operator can navigate to an Export Status page and see the real-time progress of their background requests.
  3. Operator can download the completed CSV once finished.
  4. System automatically cleans up local storage export artifacts older than a configurable threshold.
**Plans**: 3 plans
- [x] 78-01-PLAN.md — Core Async Export Engine & Defect Fix
- [x] 78-02-PLAN.md — Export Artifact Cleanup & Download Route
- [x] 78-03-PLAN.md — Export Status UI & Trigger Integration
**UI hint**: yes

### Phase 79: Scale Adapters
**Goal**: Enterprise teams can use Threadline with standard scale-out tools.
**Depends on**: Phase 75, Phase 78
**Requirements**: ADAPT-01, ADAPT-02
**Success Criteria** (what must be TRUE):
  1. Adopter can configure Threadline to use Oban for managing the background export queue in multi-node environments.
  2. Adopter can configure Threadline to stream completed export CSVs to S3 instead of local disk for distributed accessibility.
**Plans**: 3 plans
- [x] 79-01-PLAN.md — Core Configuration & Behaviours
- [x] 79-02-PLAN.md — Oban Queue Adapter
- [x] 79-03-PLAN.md — S3 Storage Adapter

### Phase 80: Governance Verification & Milestone Surface Repair
**Goal**: Milestone evidence and planning artifacts truthfully reflect implementation status before closeout resumes.
**Depends on**: Phase 75, Phase 79
**Requirements**: INFRA-01, INFRA-02
**Gap Closure**: Closes audit evidence and planning-surface drift from `v1.20-MILESTONE-AUDIT.md`.
**Success Criteria** (what must be TRUE):
  1. Phase 75 has verification and validation artifacts that prove the infrastructure requirements are actually closed.
  2. Phase 79 evidence drift is repaired, including the missing `79-02` summary trail and roadmap bookkeeping.
  3. `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` agree on v1.20 status and no file claims the milestone is already complete.
**Plans**: 2 plans
- [x] 80-01-PLAN.md — Phase 75 closeout evidence and Phase 79 adapter-evidence repair
- [x] 80-02-PLAN.md — Authoritative milestone-surface reconciliation and PROJECT narrative repair

### Phase 81: Retention Runtime Closure
**Goal**: Retention pruning and retention history work through a supervised runtime path and are formally verified.
**Depends on**: Phase 76
**Requirements**: RET-01, RET-02, RET-03
**Gap Closure**: Closes retention runtime and verification gaps from `v1.20-MILESTONE-AUDIT.md`.
**Success Criteria** (what must be TRUE):
  1. `Threadline.Retention.Pruner` runs from a built-in supervised path instead of depending on an unsupervised manual process.
  2. Retention history and manual trigger flows use that supervised runtime path successfully.
  3. Phase 76 verification and validation artifacts exist in the expected milestone closeout format.
**Plans**: 2 plans
- [x] 81-01-PLAN.md — Built-in retention supervision and runtime-path repair
- [x] 81-02-PLAN.md — Phase 76 verification and Nyquist validation closeout
**UI hint**: yes

### Phase 82: Saved Views Session Handoff Repair
**Goal**: Saved views behave as actor-owned features in the default operator surface mount path.
**Depends on**: Phase 77
**Requirements**: VIEW-01, VIEW-02
**Gap Closure**: Closes saved-view handoff and verification gaps from `v1.20-MILESTONE-AUDIT.md`.
**Success Criteria** (what must be TRUE):
  1. `SessionPlug` is installed in the normal operator surface path so actor identity reaches LiveView mounts reliably.
  2. Saved-view create/apply/delete flows work for standard `actor_fn`-driven host mounts without special setup.
  3. Phase 77 verification and validation artifacts prove the actor-owned behavior end to end.
**Plans**: TBD
**UI hint**: yes

### Phase 83: Built-In Async Export Lifecycle Repair
**Goal**: The default export runtime can enqueue, execute, track, and clean up exports without extra adapters.
**Depends on**: Phase 78
**Requirements**: EXP-01, EXP-02, EXP-04
**Gap Closure**: Closes built-in async export lifecycle gaps from `v1.20-MILESTONE-AUDIT.md`.
**Success Criteria** (what must be TRUE):
  1. The built-in `Task.Supervisor` export execution path is started by default and enqueue failures are surfaced.
  2. Export jobs record lifecycle fields needed for status and cleanup, including `started_at` and `expires_at`.
  3. Cleanup workers are supervised and old export artifacts are removed end to end.
  4. Phase 78 verification and validation artifacts cover the repaired built-in runtime path.
**Plans**: TBD

### Phase 84: Export Delivery & Scale Adapter Integration Repair
**Goal**: Completed exports can be delivered correctly across local and adapter-backed storage/queue backends.
**Depends on**: Phase 79, Phase 83
**Requirements**: EXP-03, ADAPT-01, ADAPT-02
**Gap Closure**: Closes S3 download, export status, and adapter integration gaps from `v1.20-MILESTONE-AUDIT.md`.
**Success Criteria** (what must be TRUE):
  1. Export downloads work for both local-path storage and adapter-backed storage using the correct storage API.
  2. The operator surface export status and download flow works end to end with reliable actor handoff.
  3. Oban and S3 adapters have startup and integration proof, not just isolated module implementations.
  4. Phase 79 evidence is complete and the remaining export delivery gaps are closed.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 75. Governance Infrastructure & State | 1/1 | Complete | 2026-05-23 |
| 76. Batched Retention & UI | 2/2 | Complete via Phase 81 closure | 2026-05-23 |
| 77. Saved Views Ergonomics | 2/2 | Gap closure required | - |
| 78. Async Exports & UI | 3/3 | Gap closure required | - |
| 79. Scale Adapters | 3/3 | Evidence repaired; runtime closure owned by Phase 84 | 2026-05-23 |
| 80. Governance Verification & Milestone Surface Repair | 2/2 | Complete | 2026-05-23 |
| 81. Retention Runtime Closure | 2/2 | Complete | 2026-05-23 |
| 82. Saved Views Session Handoff Repair | 0/0 | Planned | - |
| 83. Built-In Async Export Lifecycle Repair | 0/0 | Planned | - |
| 84. Export Delivery & Scale Adapter Integration Repair | 0/0 | Planned | - |
