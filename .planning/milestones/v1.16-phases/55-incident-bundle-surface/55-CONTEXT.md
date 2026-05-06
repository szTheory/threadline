# Phase 55: incident-bundle-surface - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning
**Source:** Discuss-phase with parallel advisor research across all identified gray areas

<domain>
## Phase Boundary

Phase 55 turns the Phase 54 transaction drill-down helper into a first-class
incident bundle contract. The deliverable is a library-level surface that
packages one audit transaction's ordered changes, linked transaction/action
context, and JSON-ready diffs together, then proves that the Phoenix example
incident endpoint can use that packaged surface directly instead of bespoke
controller composition.

This phase is about stabilizing the contract and proving it through the example
app. It is not the phase for broader auth/policy expansion, UI work, or the
cross-doc canonical story cleanup reserved for Phase 56.

</domain>

<decisions>
## Implementation Decisions

### Public contract shape
- **D-01:** Phase 55 should add a distinct top-level incident bundle surface
  rather than stretching `transaction_context/2` into a shape-changing helper.
- **D-02:** The recommended public entrypoint is a dedicated
  `Threadline.incident_bundle/2`-style API that returns a typed Elixir-first
  bundle contract, not a JSON-first nested map.
- **D-03:** The bundle should be represented by explicit structs, with one
  parent bundle struct containing transaction/action context and one per-change
  wrapper carrying the linked raw change plus its diff projection.
- **D-04:** The Phase 54 raw helper contract remains valid and separate:
  `transaction_context/2` stays the lower-level linked investigation primitive
  for callers who want raw structs without incident packaging.

### Diff policy
- **D-05:** The new incident bundle surface should always include JSON-ready
  `change_diff` for every bundled change.
- **D-06:** Phase 55 should not introduce an `include_change_diff?` or similar
  shape-changing option on the bundle contract. Different functions should mean
  different contracts; one function should not sometimes return diffs and
  sometimes not.
- **D-07:** `Threadline.change_diff/2` remains the underlying projection
  primitive, but Phase 55 packages it once at the bundle layer so Phoenix and
  host code stop repeating ad-hoc `Enum.map` composition.

### Existence and empty-state semantics
- **D-08:** The new incident bundle helper should distinguish a missing parent
  transaction from an existing transaction whose change list is empty.
- **D-09:** The library contract should be existence-aware:
  `{:ok, bundle}` when the `audit_transactions` row exists and
  `{:error, :not_found}` when it does not.
- **D-10:** An existing transaction with no retained/captured child changes is
  still a valid incident bundle result and should return `{:ok, bundle}` with
  `changes: []`.
- **D-11:** The low-level `Threadline.audit_changes_for_transaction/2` contract
  stays backward-compatible and unchanged even though the richer incident bundle
  surface becomes more explicit.

### Example Phoenix endpoint contract
- **D-12:** The Phoenix example incident endpoint should move to the new bundled
  surface and teach the full incident bundle as the canonical endpoint contract,
  not keep the older minimal payload as the headline story.
- **D-13:** The endpoint should still render through a Phoenix JSON layer rather
  than dumping library structs directly. The library stays Elixir-native while
  the HTTP contract stays curated and stable.
- **D-14:** The HTTP mapping should be:
  malformed UUID -> `400`,
  authenticated request for missing transaction -> `404`,
  authenticated request for existing transaction -> `200`, including the case
  where `changes` is empty.
- **D-15:** The example app should keep the Phase 51 auth boundary unchanged:
  incident drill-down requires an authenticated actor, while tenancy and richer
  authorization remain host-owned.

### DX, architecture, and contract posture
- **D-16:** The Phase 55 surface should optimize for least surprise in the
  Elixir/Phoenix ecosystem: explicit structs, explicit tagged outcomes for
  singular lookups, and no controller-local contract assembly.
- **D-17:** The bundle contract should preserve access to raw linked structs so
  adopters can build richer host views without reverse-engineering a JSON-first
  payload.
- **D-18:** Avoid duplicate canonical shapes. After Phase 55 lands, the library
  contract, example endpoint, and docs should all point to the bundled drill-
  down story rather than teaching both a thin legacy projection and a richer
  bundle.
- **D-19:** Focused proof is preferred: tests should lock the incident bundle
  shape, diff presence, ordering, not-found semantics, empty-change semantics,
  and example-endpoint parity with the library contract.

### the agent's Discretion
- Exact struct module names, as long as they clearly communicate "incident
  bundle" vs the raw Phase 54 transaction-context types.
- The exact JSON field naming in the Phoenix renderer, provided the shape is
  explicit, curated, and aligned with the library bundle semantics.
- Whether to expose one or more small helper functions under
  `Threadline.Investigation` to support the top-level bundle entrypoint, as long
  as the primary adopter-facing contract stays on `Threadline`.

</decisions>

<specifics>
## Specific Ideas

- The coherent package is:
  1. keep `transaction_context/2` raw and unchanged
  2. add a dedicated `incident_bundle/2` surface for transaction drill-down
  3. make bundled changes always include `change_diff`
  4. render that bundle through a dedicated Phoenix JSON layer in the example
- Successful patterns to learn from:
  - keep the canonical library contract typed and self-describing rather than
    JSON-first
  - keep diff packaging explicit at the incident layer instead of smearing it
    across all investigation helpers
  - teach one canonical endpoint shape in the reference app once the packaged
    surface is real
- Footguns to avoid:
  - shape-changing boolean flags on the new bundle API
  - preserving the current controller-local `Enum.map` diff assembly after the
    bundle surface exists
  - returning `404` merely because `changes == []`
  - making raw structs inaccessible behind an opaque JSON-oriented contract
- User preference for this project and GSD flow: prefer cohesive one-shot
  recommendations by default, trust researched defaults unless a decision is
  truly high-impact, and avoid interactive menu churn for non-critical choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 55 goal, dependency, and two-plan split.
- `.planning/REQUIREMENTS.md` — `INCIDENT-06` and `INCIDENT-07` requirement
  text.
- `.planning/STATE.md` — current v1.16 position, prior phase decisions, and
  milestone strategy.
- `.planning/MILESTONE-ARC.md` — why investigation ergonomics comes before UI
  or broader policy breadth.

### Upstream dependency context
- `.planning/milestones/v1.16-phases/53-timeline-paging-contract/53-CONTEXT.md`
  — locked paging and ordering decisions Phase 55 must preserve.
- `.planning/milestones/v1.16-phases/54-investigation-slice-apis/54-CONTEXT.md`
  — locked decision that raw linked investigation helpers ship in Phase 54 and
  incident packaging is deferred to Phase 55.

### Current implementation seams
- `lib/threadline.ex` — public investigation API inventory and where the new
  top-level incident bundle entrypoint should live.
- `lib/threadline/investigation.ex` — current linked helper implementations,
  especially `transaction_context/2`.
- `lib/threadline/investigation/linked_change.ex` — current linked struct shapes
  that the incident bundle should build on rather than replace.
- `lib/threadline/change_diff.ex` — JSON-ready diff projection primitive that
  the incident bundle should package.
- `lib/threadline/query.ex` — low-level transaction drill-down primitive and
  current empty-result semantics that remain backward-compatible.

### Example-app proof and docs
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex`
  — current bespoke incident JSON composition to replace.
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs`
  — current request-path proof to evolve around the bundled contract.
- `examples/threadline_phoenix/README.md` — current incident drill-down story
  that should converge on the new bundled surface.
- `guides/domain-reference.md` — current example incident JSON and exploration
  routing story.
- `guides/incident-playbook.md` — operator-facing incident diagnosis examples
  built on the current transaction + diff composition.
- `guides/getting-started-saas.md` — adopter-facing walk-through that currently
  teaches the older drill-down path.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.transaction_context/2` already packages linked transaction and
  action context for one transaction and is the natural raw foundation for the
  richer Phase 55 bundle.
- `Threadline.audit_changes_for_transaction/2` already preserves the canonical
  transaction drill-down ordering contract.
- `Threadline.change_diff/2` already provides deterministic JSON-ready diff
  maps; Phase 55 should package that output, not re-invent diff semantics.

### Established Patterns
- The top-level `Threadline` module is the intended discovery surface for
  adopters; Phase 55 should keep the main public bundle API there.
- The repo favors explicit validation and precise outcomes over silent
  coercion; the incident bundle should follow that posture with explicit
  not-found handling.
- The example Phoenix app already treats auth as endpoint-local policy while the
  library remains framework-agnostic; Phase 55 should preserve that boundary.

### Integration Points
- `lib/threadline.ex` and `lib/threadline/investigation.ex` are the main library
  seams for the bundled drill-down contract.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex`
  plus the app's JSON rendering layer are the main host seams for proving the
  canonical endpoint contract.
- Doc-contract and request-path tests already exist and should be extended
  rather than replaced.

</code_context>

<deferred>
## Deferred Ideas

- Broader docs-arc convergence across README, domain reference, getting-started,
  and milestone narrative beyond the minimum needed to teach the new bundle
  contract cleanly. That belongs to Phase 56.
- New authorization, tenancy, or policy framework behavior for incident
  drill-down. Hosts continue to own those boundaries.
- Operator UI or `threadline_web` packaging on top of the new bundle surface.
- Broader config knobs for alternative diff/bundle shapes unless real adopters
  later prove a need.

</deferred>

---

*Phase: 55-incident-bundle-surface*
*Context gathered: 2026-05-05 via interactive discuss-phase plus parallel advisor research*
