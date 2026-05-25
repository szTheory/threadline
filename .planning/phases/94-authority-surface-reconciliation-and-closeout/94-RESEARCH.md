# Phase 94 Research: Authority Surface Reconciliation & Closeout

**Date:** 2026-05-25  
**Phase:** 94  
**Status:** Complete

## Question

How should Phase 94 reconcile the active milestone authority surfaces with the
verified current-tree support-lane contract, then rerun the v1.21 closeout gate
honestly without reopening broader product or doc scope?

## Current-Tree Findings

### 1. The verified proof chain is now stronger than the active milestone audit

- `86-VERIFICATION.md` closes `SCOPE-01` and `SCOPE-02` and explicitly says
  support-scoped row history / as-of is proven on the current tree.
- `88-VERIFICATION.md` closes `AUTH-01`, `UX-01`, and `UX-02`.
- `90`, `92`, and `93` finalized the missing phase-verification chain for the
  remaining v1.21 requirements except `DOC-01` and `DOC-02`.
- `.planning/STATE.md` already reflects this later truth: Phase 93 is complete,
  9 of 10 phases are complete, and Phase 94 is the only remaining execution
  step.

### 2. The old v1.21 audit is stale in a specific, bounded way

`.planning/v1.21-MILESTONE-AUDIT.md` still reports:

- phases `85-88` as lacking verification artifacts
- `DOC-01` and `DOC-02` as partial because `89-03` was still pending
- row history / as-of drift as an unresolved contradiction
- milestone closeout as blocked on missing backfills that now exist

That audit was honest at `2026-05-25T09:15:00Z`, but it no longer reflects the
current tree after Phases 90-93.

### 3. Active authority is split by concern, not by one-file SSOT

The current repo already encodes a workable authority hierarchy:

- `.planning/ROADMAP.md` is the active milestone contract and remaining-work map
- `.planning/v1.21-MILESTONE-AUDIT.md` is the closeout gate
- `.planning/STATE.md` is the execution snapshot
- `.planning/PROJECT.md` is the narrative current-state surface
- public guides and example docs are product/proof surfaces, not planning truth

Phase 94 should preserve this split instead of collapsing everything into one
artifact.

### 4. One narrow public narrative doc still carries stale future framing

`guides/how-threadline-works.md` still says several v1.20+ capabilities are
future roadmap work:

- retention admin / pruning
- queued or scheduled exports
- saved views

That guide is intentionally a crash-course narrative, not a contract surface,
but it should not contradict already-shipped capabilities or the current
milestone thesis.

## Recommendation

Use a two-plan closeout:

1. **Plan 94-01:** reconcile the authoritative milestone surfaces plus one
   narrow crash-course narrative doc.
2. **Plan 94-02:** rerun the named proof surfaces, write the final Phase 94
   verification and validation artifacts, refresh the milestone audit, and
   close `DOC-01` / `DOC-02` only if the rerun evidence remains green.

This keeps truth repair and audit closure distinct while still moving them in
the same phase.

## Why This Split Is Correct

### Authority repair first

The audit rerun should not happen while the authority layer still contains stale
pre-Phase-90 assumptions. Reconcile first so the rerun evaluates the actual
current-tree story, not a known-contradictory set of planning files.

### Re-audit second

`DOC-01` and `DOC-02` should close only after:

- the authority wording is current
- the named rerun surfaces still pass
- the milestone audit is regenerated against the repaired tree

That prevents “artifact-only closure.”

## Exact Truth Phase 94 Should Carry

The active authority layer should repeat one exact proven-set support-lane
clause:

- shared `/audit` timeline
- actor
- transaction
- support-scoped row history / as-of
- export denial posture through host-owned seams

Coverage and policy surfaces remain admin/global or unsupported for
support-scoped sessions and should stay described that way.

## Required Artifacts

### Plan 94-01 target surfaces

- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `guides/how-threadline-works.md`
- `test/threadline/how_threadline_works_doc_contract_test.exs` only if the
  guide correction needs a lock update

### Plan 94-02 target surfaces

- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-VERIFICATION.md`
- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-VALIDATION.md`
- `.planning/v1.21-MILESTONE-AUDIT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`

## Verification Surfaces Phase 94 Should Trust

- `mix verify.doc_contract`
- `mix verify.example`
- targeted current-tree root proof already used by Phases 86 and 88:
  - scoped read-path tests
  - denial/fallback operator-surface tests
- grep-based authority checks across the planning files and the repaired guide

## Anti-Patterns To Avoid

- Treating the milestone audit as the only truth source
- Reopening public contract docs that are already aligned and verified
- Reintroducing Phase 89’s older narrowed row-history wording after Phase 91
  re-proved the support-scoped row history / as-of path
- Turning `guides/how-threadline-works.md` into a second support-matrix or
  planning ledger
- Closing `DOC-01` / `DOC-02` before the rerun evidence and refreshed audit are
  both green

## Conclusion

Phase 94 is a bounded truth-and-closeout phase. The code and proof chain are
already largely in place; the remaining work is to make the authority layer,
the crash-course narrative, and the milestone audit all describe the same
current-tree reality, then close the final documentation requirements with a
fresh rerun ledger.
