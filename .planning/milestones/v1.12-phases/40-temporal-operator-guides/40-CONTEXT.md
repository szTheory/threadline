# Phase 40: Temporal Operator Guides - Context

**Gathered:** 2026-04-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Write user-facing documentation for time travel features in `guides/domain-reference.md` and the Phoenix example README. This phase documents the existing single-row `as_of/4` contract; it does not add new reconstruction capabilities.

</domain>

<decisions>
## Implementation Decisions

### Guide framing
- **D-01:** Add one `## Time Travel (As-of)` hub section to `guides/domain-reference.md` instead of creating a separate guide.
- **D-02:** Place that section alongside the existing operator/reference material near exploration routing and support incident queries.
- **D-03:** Keep the section compact and semantic: define what `as_of/4` is for, then document the default map return plus the deleted-record, genesis-gap, and `cast: true` behaviors.

### README walkthrough
- **D-04:** Extend `examples/threadline_phoenix/README.md` with one short, runnable walkthrough rather than turning it into a second API reference.
- **D-05:** Put the new walkthrough in the main usage flow of the README, not in a hidden appendix.
- **D-06:** Use the README to teach usage and operator ergonomics; let `guides/domain-reference.md` carry the canonical semantics and edge cases.

### Edge-case coverage
- **D-07:** Explicitly call out deleted records, genesis gaps, and `cast: true` in the docs.
- **D-08:** Present those behaviors as a small behavior table or equivalent compact block, not as a long prose paragraph.
- **D-09:** Keep `cast: true` framed as the only opt-in variant; do not introduce extra cast knobs in the docs.

### Concrete examples
- **D-10:** Use `ThreadlinePhoenix.Post` as the concrete example schema in the README walkthrough.
- **D-11:** Show one historical lookup, one deleted-record note, and one `cast: true` example.
- **D-12:** Keep the examples short and copy-pasteable; do not duplicate the full public API reference in the README.

### the agent's Discretion
- Exact prose, section titles, and the precise placement of code fences.
- Whether the guide uses a tiny table or bullet list for the edge cases, as long as the behaviors remain explicit.

</decisions>

<specifics>
## Specific Ideas

- The docs should mirror Threadline’s existing pattern: `guides/domain-reference.md` as the semantic hub, and the Phoenix example README as the runnable walkthrough.
- The example app already has a `posts` schema (`ThreadlinePhoenix.Post`), which is the right concrete surface for the time-travel walkthrough.
- Keep the documentation aligned with Phase 39’s locked behavior: map by default, `cast: true` opt-in, explicit cast errors, and no additional cast toggles.

</specifics>

<canonical_refs>
## Canonical References

### Core phase context
- `.planning/ROADMAP.md` — Phase 40 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — ASOF-06 documentation requirement.
- `.planning/STATE.md` — current project state and phase sequencing.

### Reconstruction contract
- `.planning/phases/39-reification-schema-safety/39-CONTEXT.md` — locked struct-reification and loose-casting decisions.
- `.planning/phases/40-temporal-operator-guides/40-RESEARCH.md` — phase 40 research findings and recommended direction.
- `lib/threadline/query.ex` — `as_of/4` behavior, error cases, and `cast: true` implementation contract.
- `test/threadline/query_test.exs` — regression coverage for deleted records, genesis gaps, and cast behavior.

### Documentation surfaces
- `guides/domain-reference.md` — current operator/reference hub structure to extend.
- `guides/production-checklist.md` — existing doc pattern for linking reference material without duplicating it.
- `examples/threadline_phoenix/README.md` — walkthrough surface to extend with one historical reconstruction example.
- `examples/threadline_phoenix/lib/threadline_phoenix/post.ex` — concrete example schema for the README walkthrough.

### Prior phase handoff
- `.planning/phases/38-core-as-of-reconstruction/38-01-SUMMARY.md` — locked map-only reconstruction pattern and phase 38 context.
- `.planning/phases/39-reification-schema-safety/39-01-SUMMARY.md` — loose-casting, explicit cast errors, and preserved contract details.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Query.as_of/4`: already documents the authoritative `as_of/4` contract and error cases.
- `ThreadlinePhoenix.Post`: small, readable schema that makes a time-travel walkthrough easy to follow.
- `guides/domain-reference.md`: already structured as a hub doc with linked operator subsections.
- `examples/threadline_phoenix/README.md`: already organized as a workflow-oriented walkthrough, which is the right pattern to extend.

### Established Patterns
- Threadline docs separate semantic reference material from runnable examples.
- The project prefers compact, explicit docs with cross-links over duplicated long-form explanations.
- Phase 39 locked the core behavioral contract, so Phase 40 should document it rather than re-litigate it.

### Integration Points
- Add the new time-travel hub section to `guides/domain-reference.md` near the existing exploration material.
- Add the README walkthrough in `examples/threadline_phoenix/README.md` as part of the main usage flow.
- Keep the docs aligned with the public `Threadline.as_of/4` contract rather than inventing a separate documentation vocabulary.

</code_context>

<deferred>
## Deferred Ideas

- A separate `guides/time-travel.md` unless the hub section becomes too large.
- `as_of_all/4`, association travel, or broader historical comparison examples.
- A full API-reference rewrite in the example README.
- Any new cast toggles beyond `cast: true`.

</deferred>

---

*Phase: 40-temporal-operator-guides*
*Context gathered: 2026-04-25*
