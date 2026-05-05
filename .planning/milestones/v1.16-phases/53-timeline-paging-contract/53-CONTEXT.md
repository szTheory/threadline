# Phase 53: timeline-paging-contract - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning
**Source:** Repo-derived planning fallback (`$gsd-plan-phase 53` without prior discuss-phase)

<domain>
## Phase Boundary

Phase 53 is the foundation slice for v1.16's investigation ergonomics work.
Its job is to turn today's eager, full-list `Threadline.timeline/2` path into a
stable, explicit paging contract for large investigation windows while
preserving the existing descending total order on `(captured_at, id)`.

The codebase already has the critical building blocks:

- `Threadline.Query.timeline_query/1` builds the shared filtered timeline query
- `Threadline.Query.timeline/2` validates filters and returns full `%AuditChange{}`
  lists
- `Threadline.Export.stream_changes/2` already pages internally via a keyset on
  `(captured_at, id)`

This phase should extract and formalize that paging shape for investigation
reads rather than leaving keyset behavior implicit inside export or pushing
adopters toward offset pagination or ad-hoc `LIMIT` composition.

It is **not** the phase for shipping the higher-level investigation helper APIs
themselves (Phase 54), incident bundle packaging (Phase 55), or broad docs arc
cleanup (Phase 56).

</domain>

<decisions>
## Implementation Decisions

### Paging contract and ordering
- **D-01:** The paging contract must preserve the existing total order:
  `captured_at DESC, id DESC`. Random UUID `id` values are only a tiebreaker,
  not an independent chronology.
- **D-02:** The public contract should be keyset-based, not offset-based. No
  plan should bless `offset` / page-number pagination for investigation reads.
- **D-03:** Cursor advancement must be defined in the same terms as export's
  current internal stream implementation: rows "after" a page are those with
  `(captured_at, id) < cursor` under descending order.
- **D-04:** The contract must be explicit about whether cursors are opaque or
  structured, but downstream APIs must not require callers to reverse-engineer
  internal Ecto predicates.

### Shared query and validation posture
- **D-05:** Prefer factoring shared paging/query logic into `Threadline.Query`
  so `timeline`, future investigation helpers, and export can converge on one
  definition instead of duplicating cursor predicates.
- **D-06:** Filter validation should stay aligned with the existing shared
  timeline/export vocabulary (`:repo`, `:table`, `:actor_ref`, `:from`, `:to`,
  `:correlation_id`) unless a new paging-specific key is intentionally added and
  documented.
- **D-07:** Paging validation should reject ambiguous or partial cursor input
  early with `ArgumentError`-style developer-facing errors, consistent with the
  current validation posture in `Threadline.Query`.
- **D-08:** Preserve correlation semantics exactly: `:correlation_id` continues
  to mean a strict inner join to `audit_actions`. Paging must not change which
  rows match.

### Public API shape
- **D-09:** Keep `Threadline.timeline/2` usable for today's eager list
  workflows; Phase 53 should add a first-class paged usage path rather than
  silently changing return types on existing callers.
- **D-10:** The new public surface should be library-first and composable so
  Phase 54 can build higher-level investigation helpers on top of it without
  private examples-only glue.
- **D-11:** The top-level `Threadline` module should expose the intended path
  cleanly if the underlying query contract becomes public. Avoid making adopters
  import `Threadline.Query` internals unless that is an explicit, documented
  product choice.

### Docs and proof posture
- **D-12:** Documentation and fixtures should teach one canonical paging story
  for investigation windows. The phase should not leave multiple competing
  examples (for example, raw `LIMIT` snippets implying offset-style paging).
- **D-13:** Tests should lock both semantics and stability edges: ordering,
  cursor advancement, no duplicates across pages, no skipped rows on equal
  `captured_at`, and parity with the unpaged timeline result for equivalent
  filters.
- **D-14:** Where possible, reuse export paging tests/patterns as analogs
  because `Threadline.Export.stream_changes/2` already proves the repo can page
  through the full ordered set correctly.

### the agent's Discretion
- Exact naming of the cursor/page structs or maps.
- Whether the public API returns a page wrapper struct/map or a tuple, provided
  the contract is explicit and future-friendly.
- Which docs/tests best lock the canonical usage path in Phase 53 versus
  leaving broader investigation teaching to Phase 56.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 53 goal, dependency, and plan split.
- `.planning/REQUIREMENTS.md` — `EXPLORE-01` requirement text.
- `.planning/STATE.md` — v1.16 strategy and explicit note to skip fresh
  research for this milestone.
- `.planning/MILESTONE-ARC.md` — why investigation ergonomics comes before UI
  or broader integration work.

### Current implementation seams
- `lib/threadline/query.ex` — current timeline query, validation, ordering, and
  transaction drill-down APIs.
- `lib/threadline/export.ex` — existing keyset paging implementation in
  `stream_changes/2` that should inform the Phase 53 contract.
- `lib/threadline.ex` — public library surface and current exposure of timeline
  vs other investigation helpers.

### Existing proof and user-facing guidance
- `test/threadline/query_test.exs` — current timeline validation and ordering
  coverage.
- `test/threadline/export_test.exs` — existing keyset paging parity proof for
  streaming exports.
- `README.md` — top-level public API inventory that may need the new path added
  once shipped.
- `guides/domain-reference.md` — current "which API first?" story and SQL
  guidance that should not drift from the new paging contract.
- `guides/getting-started-saas.md` — adopter-facing quickstart that currently
  uses `Threadline.timeline(filters)`.

### Forward dependency context
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs`
  — real host path using current timeline filters, useful to ensure paging does
  not break correlation investigations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Export.stream_changes/2` already pages by `(captured_at, id)`
  using a cursor of `{captured_at, id}` and a strict `<` predicate.
- `Threadline.Query.timeline_order/1` already centralizes the descending total
  order used by timeline and transaction drill-down.
- `Threadline.Query.validate_timeline_filters!/1` already enforces a narrow,
  explicit API shape with clear `ArgumentError` messages.

### Established Patterns
- This codebase favors explicit keyword-list validation and precise,
  user-facing error messages over silent coercion.
- Public contract tests usually lock exact semantics with focused ExUnit cases,
  not broad snapshots.
- The repo already treats query/export parity as a first-class contract; Phase
  53 should preserve that posture for paging parity.

### Risks to Plan Around
- Equal `captured_at` timestamps require `id` as a true tiebreaker or pages can
  duplicate/skip rows.
- Export and timeline can drift if paging logic is copied instead of shared.
- Changing `Threadline.timeline/2` return shape would create an unnecessary
  compatibility risk for existing examples and docs.

</code_context>

<specifics>
## Specific Ideas

- The natural roadmap split still looks right:
  1. define the paging contract in `Threadline.Query`, validation, and tests
  2. expose the approved public API at `Threadline`, then document and lock the
     intended usage path
- A strong acceptance check is page-parity: concatenating all pages for a filter
  should equal today's unpaged `Threadline.timeline/2` result exactly.
- Another strong check is tie safety: multiple rows sharing the same
  `captured_at` must still page deterministically without duplicates or skips.
- The docs should probably teach paging for large investigation windows while
  preserving `Threadline.timeline/2` as the simple eager path for small slices.

</specifics>

<deferred>
## Deferred Ideas

- Phase 54's higher-level row-history, actor-window, correlation-bundle, and
  transaction-oriented helper APIs.
- Phase 55's first-class incident bundle contract.
- Broader docs-story convergence across README, guides, and milestone arc
  beyond the minimal Phase 53 surface alignment.
- Any UI/operator surface work.

</deferred>

---

*Phase: 53-timeline-paging-contract*
*Context gathered: 2026-05-05 via repo-derived planning fallback*
