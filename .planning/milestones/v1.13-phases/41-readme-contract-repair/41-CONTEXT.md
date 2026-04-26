# Phase 41: README Contract Repair - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the root `README.md` so it matches the shipped public API surface, quickstart flow, feature overview, and guide links. This phase does not touch the Phoenix example README; that is reserved for Phase 42.

</domain>

<decisions>
## Implementation Decisions

### README contract
- **D-01:** Keep the root README as the first-stop document for evaluation, integration, and contribution.
- **D-02:** Make the public entrypoints explicit in the README surface: `Threadline.Plug`, `Threadline.record_action/2`, `Threadline.history/3`, `Threadline.timeline/2`, `Threadline.export_json/2`, and `Threadline.as_of/4`.
- **D-03:** Preserve the existing capture / semantics / exploration / operations framing, but tighten the wording so it mirrors the shipped API rather than a generic audit overview.

### Documentation links
- **D-04:** Keep the README links to `guides/domain-reference.md`, `guides/production-checklist.md`, `guides/adoption-pilot-backlog.md`, and `CONTRIBUTING.md` intact and visible in the main document flow.
- **D-05:** Keep the README contract test focused on the root README literals for Phase 41 and leave the example README assertions in place for Phase 42.

### Agent discretion
- Exact prose for the summary, quickstart labels, and section ordering.
- Whether the feature overview names `as_of` in the main list or in a short adjacent note, as long as the public API surface is explicit.

</decisions>

<specifics>
## Specific Ideas

- The current README already has the right skeleton: short summary, quick start, feature overview, and documentation links.
- `test/support/readme_quickstart_fixtures.ex` already mirrors the quickstart paths, so keep any code-sample changes aligned with those compile-checked helpers.
- The example Phoenix README remains a separate doc-contract repair slice in Phase 42.

</specifics>

<canonical_refs>
## Canonical References

### Core phase context
- `.planning/ROADMAP.md` - Phase 41 goal and milestone placement.
- `.planning/REQUIREMENTS.md` - DOC-01 and DOC-03 requirements.
- `.planning/STATE.md` - current project state and phase sequencing.

### Root README contract
- `README.md` - root docs surface to repair.
- `test/threadline/readme_doc_contract_test.exs` - contract assertions for README literals and doc links.
- `test/support/readme_quickstart_fixtures.ex` - compile-checked quickstart helper shapes.

### Public API surface
- `lib/threadline.ex` - public entrypoints documented in the README.
- `lib/threadline/query.ex` - query entrypoints used by the feature overview and quickstart.

### Guide targets
- `guides/domain-reference.md` - canonical operator/reference guide.
- `guides/production-checklist.md` - production link target already surfaced from the README.
- `guides/adoption-pilot-backlog.md` - linked follow-up guide for operators.

</canonical_refs>

<deferred>
## Deferred Ideas

- `examples/README.md` and `examples/threadline_phoenix/README.md` contract repair, which belong to Phase 42.
- Any broad README rewrite beyond the minimum needed to align the shipped public surface.

</deferred>

---

*Phase: 41-readme-contract-repair*
*Context gathered: 2026-04-26*
