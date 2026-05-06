# Roadmap: Threadline

## Milestones

- 🚧 **v1.16 — Investigation Table Stakes** — Phases 53-56 (planned 2026-05-05) — [requirements](REQUIREMENTS.md)
- ✅ **v1.15 — Host Integration Completion** — Phases 49-52 (shipped 2026-05-05) — [requirements](milestones/v1.15-REQUIREMENTS.md) · [archive](milestones/v1.15-ROADMAP.md)
- ✅ **v1.14 — Drop-in Production Adopter Slice** — Phases 44-48 (shipped 2026-05-05) — [requirements](milestones/v1.14-REQUIREMENTS.md) · [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Docs Contract Repair** — Phases 41-43 (shipped 2026-04-26) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Temporal Truth & Safety** — Phases 38-40 (shipped 2026-04-25) — [archive](milestones/v1.12-ROADMAP.md)

## Active Milestone

- **v1.16 — Investigation Table Stakes**
- **Goal:** Make Threadline materially easier to use for the first real support and incident questions by shipping stable, paged investigation APIs and a first-class incident bundle surface.
- **Why this milestone first:** The library already captures and correlates rich audit data, but adopters still need custom query/controller composition to answer common investigation questions. That is the current table-stakes gap.
- **Strategic context:** See `.planning/MILESTONE-ARC.md` for the standing candidate order after v1.16.

## Phases

### Phase 53: Timeline Paging Contract

**Goal**: Add an explicit paging contract to timeline-style investigation reads without breaking the existing stable `(captured_at, id)` ordering.
**Depends on**: Phase 52
**Requirements**: EXPLORE-01
**Plans**: 2 plans

Plans:

- [x] 53-01: Define and implement the public paging contract, validations, and query tests for investigation timelines
- [x] 53-02: Expose the new usage path cleanly at the library surface and lock the intended semantics in docs or fixtures where needed

**Details:**

- Added a shared query-layer keyset paging contract anchored on descending `(captured_at, id)` order and exposed it publicly as `Threadline.timeline_page/2` without changing eager `timeline/2`.
- Refactored `Threadline.Export.stream_changes/2` to reuse the same paging primitive so investigation reads and export streaming cannot drift semantically.
- Updated README and investigation-facing guides to teach one canonical eager-vs-paged traversal story, then locked that wording with focused doc-contract coverage.

### Phase 54: Investigation Slice APIs

**Goal**: Package the canonical support questions as higher-level library helpers instead of leaving adopters to compose them manually from low-level queries and joins.
**Depends on**: Phase 53
**Requirements**: EXPLORE-02
**Plans**: 2 plans

Plans:

- [x] 54-01: Add the new investigation helper surface for row, actor, and correlation-driven reads
- [x] 54-02: Align the returned shapes and focused tests around linked transaction/action context instead of raw ad-hoc composition

**Details:**

- Added public `Threadline` helper entrypoints for row-history, actor-window, and correlation-bundle reads, with paged paths reusing the shipped Phase 53 keyset contract.
- Introduced linked investigation result wrappers plus `transaction_context/2` so transaction/action context is packaged at the library layer instead of in controller-local composition.
- Added focused helper and compatibility coverage that proves the richer investigation surface works while older raw primitives stay backward-compatible and `change_diff`-based incident bundling remains deferred to Phase 55.

### Phase 55: Incident Bundle Surface

**Goal**: Turn transaction drill-down into a first-class library contract that packages ordered changes, linked semantics, and JSON-ready diffs together.
**Depends on**: Phase 54
**Requirements**: INCIDENT-06, INCIDENT-07
**Plans**: 2 plans

Plans:

- [ ] 55-01: Ship the incident bundle API and the focused projections it needs
- [ ] 55-02: Converge the Phoenix example incident endpoint on the new public surface and prove it with request-path coverage

### Phase 56: Docs, Contracts, and Arc Alignment

**Goal**: Teach one canonical exploration story across docs while preserving the standing forward arc for future milestone planning.
**Depends on**: Phase 55
**Requirements**: ADOPT-04
**Plans**: 2 plans

Plans:

- [ ] 56-01: Align README, domain reference, example docs, and adoption guidance around the shipped investigation API choices
- [ ] 56-02: Lock the wording with doc-contract coverage and refresh the strategic planning docs so future milestones inherit the recorded ordering
