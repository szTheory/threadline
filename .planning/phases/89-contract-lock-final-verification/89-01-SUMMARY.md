---
phase: 89-contract-lock-final-verification
plan: "01"
subsystem: docs
tags: [documentation, operator-surface, support-lane, sigra, contract-tests]
requires:
  - phase: 88-denial-fallback-ux-closure
    provides: truthful export denial and admin/global unsupported-surface posture
provides:
  - narrowed support-lane contract that excludes unproven support-scoped row history / as-of
  - explicit lane hierarchy between root phoenix-surface claims and the narrower sigra-reference example
  - doc-contract coverage for scope_query_fn and export_authorize_fn as the host-owned seams
affects: [phase-89, docs, examples, verification]
tech-stack:
  added: []
  patterns: [truth-first contract narrowing, layered doc authority by concern]
key-files:
  created: [.planning/phases/89-contract-lock-final-verification/89-01-SUMMARY.md]
  modified:
    - guides/operator-surface.md
    - guides/upgrade-path.md
    - guides/getting-started-saas.md
    - guides/integration-contracts.md
    - examples/threadline_phoenix/README.md
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/upgrade_path_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/integration_contracts_doc_contract_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
key-decisions:
  - "Narrowed support-lane row-history / as-of claims instead of widening the example router without same-pass proof."
  - "Kept upgrade-path as lane taxonomy authority while operator-surface owns screen-level truth and the example README stays a narrower reference artifact."
patterns-established:
  - "Support-lane docs must distinguish mounted route availability from support-scoped proof."
  - "Example proof cannot silently become broader product authority when the root lane claim is narrower or differently proven."
requirements-completed: [DOC-01]
duration: in-session
completed: 2026-05-25
---

# Phase 89: Contract Lock & Final Verification Summary

**The public support-lane docs now tell one truthful story: mounted support proof covers timeline, actor, transaction, and export denial, while support-scoped row history / as-of remains intentionally unclaimed.**

## Performance

- **Duration:** In-session
- **Started:** 2026-05-25T06:30:00Z
- **Completed:** 2026-05-25T07:25:00Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Narrowed the screen-level `/audit` contract so row history and as-of are no longer overclaimed for support-scoped sessions.
- Aligned `upgrade-path`, `getting-started`, `integration-contracts`, and the example README around the layered lane authority split.
- Locked the new wording with root doc-contract tests so the example remains the `sigra-reference` proof path rather than broader `phoenix-surface` authority.

## Task Commits

No task commits were created in this run.

The worktree already contained related in-progress edits in several of the same Phase 89 guide and test files, so atomic plan commits would have mixed pre-existing local work with this execution pass.

## Files Created/Modified

- `guides/operator-surface.md` - Marks support-scoped row history / as-of as unclaimed while preserving the mounted route and API fallback references.
- `guides/upgrade-path.md` - Clarifies that v1.21 mounted proof covers shared `/audit` scope and export seams, not support-scoped row history.
- `guides/getting-started-saas.md` - Keeps the first-hour recipe focused on the mounted proof that actually exists and pushes row history back to direct APIs unless separately proven.
- `guides/integration-contracts.md` - Promotes `scope_query_fn` alongside `authorize_fn` and `export_authorize_fn` as the host-owned seam contract.
- `examples/threadline_phoenix/README.md` - Reframes the example as proof of the narrower support-scoped timeline/actor/transaction/export-denial path only.
- `test/threadline/*doc_contract_test.exs` - Pins the narrowed claim and the lane hierarchy in the doc-contract suite.

## Decisions Made

- Preferred claim narrowing over a speculative router expansion because the current example router does not yet prove `:row_history` scoping for support sessions.
- Kept row history visible as a product capability while changing only the support-scoped proof claim, preserving the broader admin/current-host story.

## Deviations from Plan

None beyond the no-commit constraint from the pre-existing dirty worktree.

## Issues Encountered

- Several target files already had local edits when execution began. The plan was completed by layering the Phase 89 contract changes on top of those edits instead of trying to separate or revert them.

## User Setup Required

None.

## Next Phase Readiness

- Phase `89-02` can now verify the narrower contract honestly instead of inventing support-scoped row-history proof.
- If the repo later wants support-scoped row history back in the named lane, it now needs explicit router and behavioral proof rather than doc implication.

---
*Phase: 89-contract-lock-final-verification*
*Completed: 2026-05-25*
