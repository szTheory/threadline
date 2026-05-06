# Phase 56: docs-contracts-and-arc-alignment - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Teach one canonical exploration story across the public docs and contract tests
now that the v1.16 investigation surfaces are shipped, while preserving
`.planning/MILESTONE-ARC.md` as the standing strategic source for future
milestone sequencing.

This phase is a consolidation and drift-reduction pass. It should align
`README.md`, the domain reference, the Phoenix quickstart/example docs, the
incident playbook, and the doc-contract coverage around the shipped
investigation APIs and the host-owned auth/policy boundary. It should also make
the planning docs point to one canonical milestone-arc truth instead of
repeating strategy in multiple places.

It is **not** the phase for new runtime behavior, new investigation APIs,
authorization framework work, UI work, or a broad planning-system redesign.

</domain>

<decisions>
## Implementation Decisions

### Canonical investigation story
- **D-01:** `Threadline.incident_bundle/2` is the canonical transaction
  drill-down story for v1.16 docs. It should be taught as the default answer to
  "show me one transaction incident" across the README-adjacent docs, domain
  reference, quickstart, example README, and incident playbook.
- **D-02:** `Threadline.audit_changes_for_transaction/2`,
  `Threadline.transaction_context/2`, and `Threadline.change_diff/2` remain
  public, stable lower-level building blocks. They should be documented as the
  underlying primitives for advanced/custom composition, not as a co-equal
  first-choice path for new adopters.
- **D-03:** Avoid a dual-canonical story. Docs may explain layering, but they
  should not force new readers to choose between raw composition and the
  packaged incident bundle when one path is clearly the intended default.

### README scope and top-level DX
- **D-04:** Keep `README.md` concise and library-idiomatic: short value
  proposition, install path, one happy-path snippet, and a compact investigation
  routing map that exposes the modern exploration surface without becoming a
  second domain guide.
- **D-05:** The README should explicitly mention the investigation-surface
  hierarchy: use `Threadline.timeline/2` for smaller eager slices,
  `Threadline.timeline_page/2` for large stable windows, higher-level
  investigation helpers for common support questions, and
  `Threadline.incident_bundle/2` for transaction drill-down.
- **D-06:** Keep semantics details, auth/tenancy caveats, SQL, and richer
  operator examples in the guides and example README, not duplicated in the root
  README.

### Contract-test posture
- **D-07:** Phase 56 should use targeted literal assertions, anchored snippet
  extraction, and a small number of cross-doc invariant checks. This matches the
  existing ExUnit/doc-contract style and provides the best signal-to-noise ratio.
- **D-08:** Lock public contractual truth, not editorial prose. Stable items
  include API names, section anchors, copied router/example snippets, the
  canonical "which API first?" routing, the eager-vs-paged rule, the promoted
  `incident_bundle/2` story, and the host-owned auth/policy honesty lines.
- **D-09:** Do not adopt whole-file snapshots or broad exact-string contracts
  for README/guides/planning docs. They create high-noise CI and freeze harmless
  editorial improvements.
- **D-10:** Do not make doctest/doctest-file the primary Phase 56 strategy.
  They are useful for small pure code examples, but they are a poor fit for the
  prose-heavy, side-effectful guide surfaces involved here.

### Planning-arc propagation
- **D-11:** `.planning/MILESTONE-ARC.md` remains the single canonical strategic
  recommendation file. It owns the ranked forward arc and rationale.
- **D-12:** `.planning/ROADMAP.md`, `.planning/PROJECT.md`, and
  `.planning/STATE.md` should summarize and point to `MILESTONE-ARC.md`, not
  restate the candidate milestone table or duplicate the ranking logic.
- **D-13:** Future planning docs should reference the arc when they inherit or
  override it, but they should copy only the local consequence of that decision,
  not the full strategic table.

### Execution style and decision-making preference
- **D-14:** Prefer cohesive, one-shot recommendations that fit the existing
  architecture and project goals. Downstream agents should resolve ordinary
  design/documentation tradeoffs decisively instead of escalating every choice.
- **D-15:** Escalate to the user only for genuinely high-impact product or
  architectural choices that could materially change the project's direction,
  semantics, or trust boundary.
- **D-16:** Preserve least surprise for both maintainers and adopters: one
  canonical public path per common investigation question, explicit layering for
  advanced users, host-owned authorization boundaries, and low-noise drift
  guards.

### the agent's Discretion
- Exact wording of the README routing map, provided it stays concise and points
  readers to the deeper guides for detail.
- Whether to introduce one new narrow cross-doc contract test or extend the
  existing doc-contract files, provided the contract posture above is preserved.
- The exact degree of planning-doc wording refresh in `PROJECT.md` and `STATE.md`,
  provided `MILESTONE-ARC.md` remains the canonical strategic source.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase framing and active milestone context
- `.planning/ROADMAP.md` — Phase 56 goal, dependency, and two-plan split.
- `.planning/REQUIREMENTS.md` — `ADOPT-04` requirement text for canonical
  exploration guidance.
- `.planning/PROJECT.md` — current v1.16 milestone framing and the strategic
  thesis behind investigation-first product work.
- `.planning/STATE.md` — current sequencing, v1.16 status, and the explicit
  note that Phase 56 is the next execution target.
- `.planning/MILESTONE-ARC.md` — canonical forward milestone ordering and the
  rationale for keeping strategy separate from execution tracking.

### Upstream phase decisions that constrain this phase
- `.planning/milestones/v1.15-phases/52-docs-and-contract-alignment/52-CONTEXT.md`
  — prior docs-alignment approach, contract-test posture, and cross-doc
  consistency rules.
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md`
  — canonical eager-vs-paged timeline story and ordering rules.
- `.planning/milestones/v1.16-phases/54-investigation-slice-apis/54-CONTEXT.md`
  — packaged investigation-helper philosophy and public surface direction.
- `.planning/milestones/v1.16-phases/55-incident-bundle-surface/55-CONTEXT.md`
  — locked decision that `Threadline.incident_bundle/2` is the packaged
  transaction drill-down surface and the example endpoint should teach it.

### Primary public docs to align
- `README.md` — root public API and first-hour adoption surface.
- `guides/domain-reference.md` — canonical "which API first?" routing and the
  reference incident JSON story.
- `guides/getting-started-saas.md` — copy-paste quickstart and first operator
  investigation path.
- `guides/incident-playbook.md` — operator-facing support and incident
  diagnosis scenarios.
- `examples/threadline_phoenix/README.md` — runnable Phoenix reference app
  narrative and bundled incident endpoint story.
- `guides/production-checklist.md` — downstream links into exploration routing
  that should remain consistent.

### Existing contract-test and proof surfaces
- `test/threadline/readme_doc_contract_test.exs` — root README public API and
  guide-link drift guard.
- `test/threadline/exploration_routing_doc_contract_test.exs` — domain
  reference routing and incident JSON anchor guard.
- `test/threadline/getting_started_saas_doc_contract_test.exs` — quickstart
  walkthrough and host-boundary guard.
- `test/threadline/incident_playbook_doc_contract_test.exs` — incident
  playbook scenario and auth-boundary guard.
- `test/threadline/example_phoenix_readme_contract_test.exs` — example README
  direct-callback and incident-boundary guard.
- `test/threadline/investigation_test.exs` — current truth for the higher-level
  investigation helpers and `incident_bundle/2`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing doc-contract tests already cover nearly every public surface Phase 56
  cares about; the likely path is to tighten and realign them, not create a new
  testing framework.
- `Threadline.incident_bundle/2` is already shipped and exercised in
  `test/threadline/investigation_test.exs`, so Phase 56 can align docs/tests to
  current behavior rather than inventing a new contract.
- The Phoenix example README already teaches the bundled incident story and the
  authenticated-actor baseline, giving the phase a strong anchor to converge on.

### Established Patterns
- This repo prefers focused `String.contains?` assertions and extracted snippet
  literals over snapshots.
- Public docs favor explicit host-owned boundaries over library-owned magic.
- The planning system already learned that duplicated truth across planning docs
  creates drift and closeout toil; the milestone arc should therefore remain
  canonical in one place.

### Integration Points
- The main doc edit cluster is `README.md`, `guides/domain-reference.md`,
  `guides/getting-started-saas.md`, `guides/incident-playbook.md`, and
  `examples/threadline_phoenix/README.md`.
- The main test edit cluster is the existing doc-contract files in
  `test/threadline/`.
- The main planning-doc refresh seam is the relationship between
  `.planning/MILESTONE-ARC.md` and summary references in `.planning/PROJECT.md`
  and `.planning/STATE.md`.

</code_context>

<specifics>
## Specific Ideas

- The cleanest execution shape remains the roadmap split:
  1. align README/domain-reference/example/quickstart/playbook wording around
     the shipped investigation surface
  2. lock that wording with focused doc-contract coverage and planning-doc arc
     alignment
- The canonical investigation routing should feel like Phoenix/Ecto/Oban-style
  layering:
  - top-level public API for the common question
  - lower-level primitives preserved for advanced composition
  - framework/app-specific JSON rendering and authorization left to the host
- User preference for this repo and GSD flow:
  - favor decisive, coherent, one-shot recommendations
  - shift non-critical design decisions left into agent judgment where possible
  - reserve user escalation for truly impactful choices

</specifics>

<deferred>
## Deferred Ideas

- Any new investigation API beyond the shipped v1.16 surface.
- New auth/tenancy/policy framework behavior beyond the current host-owned
  boundary.
- UI/operator-surface work or `threadline_web`-style packaging.
- Broader planning-system redesign beyond making `MILESTONE-ARC.md` the
  canonical strategic source and keeping other docs pointer-based.

</deferred>

---

*Phase: 56-docs-contracts-and-arc-alignment*
*Context gathered: 2026-05-05*
