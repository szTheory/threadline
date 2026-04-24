# Roadmap: Threadline

## Phases

- [ ] **Phase 38: Core As-of Reconstruction** - Basic historical state retrieval as Maps including deleted record support and genesis gap detection.
- [ ] **Phase 39: Reification & Schema Safety** - Casting historical data to Ecto structs with drift-tolerant loose casting.
- [ ] **Phase 40: Temporal Operator Guides** - User-facing documentation for time travel features in guides and example apps.

## Phase Details

### Phase 38: Core As-of Reconstruction
**Goal**: Basic historical state retrieval as Maps.
**Depends on**: Phase 37
**Requirements**: ASOF-01, ASOF-02, ASOF-05
**Success Criteria** (what must be TRUE):
  1. `Threadline.as_of/4` returns a Map representing the record at the requested timestamp.
  2. Querying a deleted record returns its state at the requested historical point.
  3. Querying before the first audit entry returns `{:error, :before_audit_horizon}`.
**Plans**: TBD

### Phase 39: Reification & Schema Safety
**Goal**: Casting historical data to Ecto structs with drift tolerance.
**Depends on**: Phase 38
**Requirements**: ASOF-03, ASOF-04
**Success Criteria** (what must be TRUE):
  1. `Threadline.as_of(..., cast: true)` returns an Ecto struct.
  2. Struct loading succeeds even if the audit log contains fields not present in the current schema (loose casting).
**Plans**: TBD

### Phase 40: Temporal Operator Guides
**Goal**: User-facing documentation for time travel features.
**Depends on**: Phase 39
**Requirements**: ASOF-06
**Success Criteria** (what must be TRUE):
  1. "Time Travel" guide section is live in `guides/domain-reference.md`.
  2. Phoenix example README demonstrates historical reconstruction.
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 38. Core As-of Reconstruction | 0/1 | Not started | - |
| 39. Reification & Schema Safety | 0/1 | Not started | - |
| 40. Temporal Operator Guides | 0/1 | Not started | - |
