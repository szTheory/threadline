# Phase 56 Discussion Log

**Date:** 2026-05-05
**Phase:** 56 - Docs, Contracts, and Arc Alignment

## Prompt Log

### User selection
- Selected all identified gray areas for discussion.

### User guidance
- Requested subagent-backed research for each area.
- Requested pros/cons/tradeoffs for each approach.
- Requested ecosystem guidance grounded in idiomatic Elixir/Plug/Ecto/Phoenix
  practice and lessons from successful libraries/apps, including prior art from
  other ecosystems where useful.
- Requested one-shot, coherent recommendations that emphasize strong software
  architecture, least surprise, DX, and user-friendliness where applicable.
- Requested that this "decide by default unless truly high-impact" preference be
  shifted left within the GSD workflow where possible.

## Areas Discussed

### 1. Primary drill-down story
- Research covered:
  - `Threadline.incident_bundle/2` as the canonical story
  - a co-equal dual-track story
  - keeping raw transaction change composition primary
- Locked decision:
  - `Threadline.incident_bundle/2` becomes the canonical transaction incident
    story.
  - `audit_changes_for_transaction/2`, `transaction_context/2`, and
    `change_diff/2` remain documented as lower-level building blocks.

### 2. README investigation surface
- Research covered:
  - thin README + routing map
  - expanded README with more examples
  - install-only teaser README
- Locked decision:
  - keep the README concise, but explicitly expose the modern investigation
    surface and the canonical path into deeper guides.

### 3. Doc-contract scope
- Research covered:
  - targeted literal/invariant contracts
  - doctest-heavy strategy
  - snapshot/exact-string strategy
- Locked decision:
  - use targeted literal assertions, anchored snippet extraction, and a few
    cross-doc invariants; avoid snapshots and broad prose locking.

### 4. Planning-arc propagation
- Research covered:
  - `MILESTONE-ARC.md` as canonical with summary pointers elsewhere
  - `PROJECT.md` as canonical
  - duplicated/synced strategic tables across files
  - ADR-only replacement
- Locked decision:
  - keep `.planning/MILESTONE-ARC.md` as the single canonical strategic source,
    with `ROADMAP`, `PROJECT`, and `STATE` acting as pointer-based consumers.

## Canonical References Raised During Discussion

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md`
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md`
- `.planning/milestones/v1.16-phases/54-investigation-slice-apis/54-CONTEXT.md`
- `.planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md`
- `README.md`
- `guides/domain-reference.md`
- `guides/getting-started-saas.md`
- `guides/incident-playbook.md`
- `examples/threadline_phoenix/README.md`
- `test/threadline/readme_doc_contract_test.exs`
- `test/threadline/exploration_routing_doc_contract_test.exs`
- `test/threadline/getting_started_saas_doc_contract_test.exs`
- `test/threadline/incident_playbook_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`
- `test/threadline/investigation_test.exs`

## Outcome

The discussion resolved all four gray areas in one pass. The resulting context
favors decisive downstream recommendations, limits escalations to high-impact
choices, and converges the docs/contracts story on the shipped v1.16
investigation surface.
