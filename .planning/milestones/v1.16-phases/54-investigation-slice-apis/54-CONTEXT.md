# Phase 54: investigation-slice-apis - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning
**Source:** Repo-derived planning fallback (`$gsd-plan-phase 54` without prior discuss-phase)

<domain>
## Phase Boundary

Phase 54 is the first packaging layer on top of the paging/query foundation that
Phase 53 shipped. Its job is to turn the operator questions already taught in
the docs into stable library helpers so adopters stop composing investigations
manually from `history/3`, `timeline/2`, `timeline_page/2`, ad-hoc filter maps,
and transaction joins.

The docs and codebase already point to the target questions:

- row history for one domain record over time
- actor-window reads across tables
- correlation-bundle reads for one shared `correlation_id`
- transaction drill-down as a reusable investigation primitive

Phase 54 should package those questions into higher-level library-first APIs
that are easier to discover and harder to misuse than the current low-level
composition path. It should reuse the shipped Phase 53 paging contract wherever
large investigation windows need incremental traversal.

It is **not** the phase for packaging the final incident bundle surface for one
transaction (Phase 55), for broad doc-story convergence across all public
surfaces (Phase 56), or for introducing a UI/operator shell.

</domain>

<decisions>
## Implementation Decisions

### Product boundary and audience
- **D-01:** Phase 54 must satisfy `EXPLORE-02` by shipping helper APIs for the
  canonical operator questions already taught in `guides/domain-reference.md`,
  not by adding more low-level query knobs.
- **D-02:** The new helpers should be library-first and public on the top-level
  `Threadline` surface whenever the helper is meant for adopters, not hidden in
  example-only controller composition or `Threadline.Query` internals.
- **D-03:** The helpers should reduce the amount of ad-hoc joining/filter wiring
  the adopter has to remember after install, while keeping the underlying low-
  level primitives available for edge cases.

### Relationship to Phase 53
- **D-04:** Phase 54 must build on the Phase 53 keyset paging contract rather
  than inventing a second traversal model. Any helper that can produce large
  result sets should either expose a paged path directly or delegate to
  `Threadline.timeline_page/2` semantics behind a clear contract.
- **D-05:** The stable ordering contract remains `captured_at DESC, id DESC`
  wherever `AuditChange` rows are traversed; Phase 54 must not loosen or
  reinterpret that order.
- **D-06:** Correlation semantics remain strict inner-join semantics against
  linked `audit_actions`; helper APIs must not broaden `:correlation_id` into
  “best effort” or orphan-inclusive behavior.

### Helper surface shape
- **D-07:** The roadmap split implies two planning buckets:
  1. introduce the higher-level investigation helper APIs
  2. align returned shapes and focused tests around linked transaction/action
     context rather than raw, repeated ad-hoc composition
- **D-08:** The helpers should map directly to the operator questions already
  named in the docs: row history, actor window, correlation bundle, and
  transaction-oriented reads.
- **D-09:** Where the current surface already has a strong primitive
  (`history/3`, `actor_history/2`, `audit_changes_for_transaction/2`,
  `timeline_page/2`, `change_diff/2`), Phase 54 should compose those primitives
  into clearer investigation contracts instead of replacing them.
- **D-10:** Return shapes should be explicit and future-friendly. If helpers
  return maps/structs that bundle filters, transactions, actions, or change
  rows, those shapes should make later Phase 55 incident packaging easier rather
  than forcing another rewrite.

### Validation, proof, and compatibility posture
- **D-11:** Existing public APIs (`history/3`, `actor_history/2`,
  `timeline/2`, `timeline_page/2`, `audit_changes_for_transaction/2`) must
  remain backward-compatible. Phase 54 adds helper layers; it does not break the
  already shipped primitives.
- **D-12:** Tests should prove that the new helpers answer the documented
  operator questions with less manual composition, preserve ordering and
  filtering semantics, and keep transaction/action linkage explicit where
  promised.
- **D-13:** Focused proof is better than broad snapshots. Prefer narrow ExUnit
  coverage around helper semantics, result shapes, and delegation boundaries.
- **D-14:** If docs are touched in this phase, changes should stay minimal and
  support discoverability of the new APIs, but broad exploration-story cleanup
  still belongs to Phase 56.

### the agent's Discretion
- Exact helper names, as long as they are discoverable and align with the
  existing Threadline naming style.
- Whether paged and eager variants live as separate helpers or as clear
  companion entrypoints, provided the contract does not blur return shapes.
- The exact result wrapper structs/maps for linked investigation slices, as long
  as they keep transaction/action/change context explicit and testable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 54 goal, dependency, and plan split.
- `.planning/REQUIREMENTS.md` — `EXPLORE-02` requirement text.
- `.planning/STATE.md` — milestone strategy, Phase 53 completion, and the
  standing decision to skip fresh research for v1.16.
- `.planning/MILESTONE-ARC.md` — why investigation ergonomics is the current
  product priority.

### Upstream dependency context
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md`
  — locked paging decisions and deferred helper scope.
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-01-SUMMARY.md`
  — what the query-layer paging contract actually shipped.
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-02-SUMMARY.md`
  — what public API/docs surface now exists after Phase 53.
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-VERIFICATION.md`
  — verified truths Phase 54 must build on, not reopen.

### Current implementation seams
- `lib/threadline.ex` — current public investigation API inventory.
- `lib/threadline/query.ex` — low-level primitives: `history/3`,
  `actor_history/2`, `timeline/2`, `timeline_page/2`,
  `audit_changes_for_transaction/2`, and their ordering/filter semantics.
- `lib/threadline/export.ex` — parity example for correlation/timeline filter
  vocabulary and shared traversal semantics.
- `lib/threadline/change_diff.ex` — existing JSON-friendly field diff projection
  that may be part of higher-level helper shapes.

### Existing proof and user-facing guidance
- `test/threadline/query_test.exs` — current proof for the low-level read APIs.
- `test/threadline/export_test.exs` — correlation and timeline parity coverage.
- `guides/domain-reference.md` — the canonical operator-question routing story
  that Phase 54 should package into library helpers.
- `README.md` — current public API inventory.
- `guides/getting-started-saas.md` — first-hour adopter flow now teaching
  `timeline_page/2`.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex`
  — real controller composition using `audit_changes_for_transaction/2` and
  `change_diff/2`.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs`
  — real host path proving correlation-driven timeline usage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.history/3` already answers single-row history but only for one PK
  at a time and without a higher-level investigation wrapper.
- `Threadline.actor_history/2` returns `AuditTransaction` rows for one actor,
  but callers still compose separate change listing manually when they need row-
  level slices across tables.
- `Threadline.timeline/2` and `Threadline.timeline_page/2` now share a stable
  keyset contract and can power large-window actor or correlation investigations.
- `Threadline.audit_changes_for_transaction/2` already provides one stable
  transaction drill-down primitive.
- `Threadline.change_diff/2` already gives deterministic JSON-friendly diffs
  that can be embedded in richer helper results.

### Established Patterns
- The top-level `Threadline` module is the intended discovery surface for
  adopters; low-level Query functions still exist but public helpers should not
  require doc readers to stitch internals together.
- Query/filter validation is explicit and raises precise `ArgumentError`
  messages; helper APIs should preserve that posture instead of silently
  coercing bad inputs.
- The repo prefers focused, behavior-level ExUnit coverage and doc-contract
  drift guards over broad snapshots.

### Risks to Plan Around
- If helper APIs simply mirror the existing low-level primitives without adding
  a clearer contract, the milestone will not close the adoption gap.
- If helper result shapes hide ordering, pagination, or transaction/action
  linkage, Phase 55 will inherit a muddy foundation for incident bundles.
- If Phase 54 overreaches into docs cleanup or incident packaging, it will blur
  the milestone split and make verification less crisp.

</code_context>

<specifics>
## Specific Ideas

- A natural split still looks like:
  1. add the new investigation helper entrypoints and any supporting structs
  2. tighten result shapes/tests so linked transaction/action/change context is
     explicit and reusable
- Strong candidates for packaging are:
  - one row-history helper that speaks in investigation terms instead of raw
    schema/PK wiring alone
  - one actor-window helper that returns change rows, not just transaction rows
  - one correlation-bundle helper that packages the strict filter plus linked
    semantics context
  - one transaction-oriented helper layer that prepares for Phase 55 incident
    bundles without fully shipping them yet
- The Phoenix example’s transaction drill-down controller is a concrete proof of
  the composition pain Phase 54 should reduce at the library layer.

</specifics>

<deferred>
## Deferred Ideas

- Phase 55’s full incident bundle packaging for one transaction, including final
  JSON-ready incident-facing contract decisions.
- Phase 56’s broad doc-story convergence and cross-surface wording cleanup.
- Any operator UI, LiveView surface, or `threadline_web` packaging.
- Broader adapter/auth/policy expansion unrelated to the core investigation
  helper layer.

</deferred>

---

*Phase: 54-investigation-slice-apis*
*Context gathered: 2026-05-05 via repo-derived planning fallback*
