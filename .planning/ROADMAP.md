# Roadmap: v1.20 - Scale and Governance Depth

## Phases

- [ ] **Phase 75: Governance Infrastructure & State** - Introduce core DB schemas and backend Behaviours for storage and queuing.
- [x] **Phase 76: Batched Retention & UI** - Implement autovacuum-aware DB pruning and a Retention History LiveView. (completed 2026-05-22)
- [ ] **Phase 77: Saved Views Ergonomics** - Allow operators to save and manage timeline queries using host actor ownership.
- [ ] **Phase 78: Async Exports & UI** - Shift massive CSV exports to background tasks with a status page and file cleanup.
- [ ] **Phase 79: Scale Adapters** - Provide opt-in S3 and Oban integrations for multi-node deployments.

## Phase Details

### Phase 75: Governance Infrastructure & State
**Goal**: Foundations for background operations and DB state are established.
**Depends on**: Nothing
**Requirements**: INFRA-01, INFRA-02
**Success Criteria** (what must be TRUE):
  1. Adopters can run DB migrations to create `threadline_export_jobs`, `threadline_retention_runs`, and `threadline_saved_views` schemas.
  2. Developers can reference explicit `Threadline.Storage` and `Threadline.ExportQueue` behaviours for custom backend implementations.
**Plans**: TBD

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
- [ ] 77-02-PLAN.md — Saved Views UI
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
**Plans**: TBD
**UI hint**: yes

### Phase 79: Scale Adapters
**Goal**: Enterprise teams can use Threadline with standard scale-out tools.
**Depends on**: Phase 75, Phase 78
**Requirements**: ADAPT-01, ADAPT-02
**Success Criteria** (what must be TRUE):
  1. Adopter can configure Threadline to use Oban for managing the background export queue in multi-node environments.
  2. Adopter can configure Threadline to stream completed export CSVs to S3 instead of local disk for distributed accessibility.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 75. Governance Infrastructure & State | 1/1 | Planned | - |
| 76. Batched Retention & UI | 2/2 | Complete   | 2026-05-22 |
| 77. Saved Views Ergonomics | 1/2 | In Progress|  |
| 78. Async Exports & UI | 0/0 | Not started | - |
| 79. Scale Adapters | 0/0 | Not started | - |