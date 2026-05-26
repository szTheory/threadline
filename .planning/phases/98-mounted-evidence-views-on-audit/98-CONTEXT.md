# Phase 98: Mounted Evidence Views On `/audit` - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 98 mounts the evidence plane on the existing `/audit` operator surface.
The work is read-only and must reuse the current operator family, current
host-owned authorization boundary, and the same evidence truth already exposed
through `Threadline.Evidence` and `mix threadline.evidence.show`.

This phase does not create a new UI family, new permission model, new evidence
subject set, or a specialist analyst console. It should give operators one
truthful mounted answer to “what can Threadline prove right now?” while keeping
history, unsupported states, and host-owned access boundaries explicit.

</domain>

<decisions>
## Implementation Decisions

### Mounted entry and route shape

- **D-01:** Phase 98 should add one canonical mounted landing page at
  `/audit/evidence`, not distribute the evidence plane purely across existing
  policy/coverage/export pages.
- **D-02:** Existing `/audit/coverage`, `/audit/policy/redaction`,
  `/audit/policy/retention`, and export-related views may deep-link into
  filtered evidence state, but they should not become independent evidence
  subsystems with page-local reducers or page-local truth contracts.
- **D-03:** The mounted evidence route remains a sibling inside the existing
  `/audit` family, matching the repo’s current operator-surface pattern of one
  canonical entry plus narrower sibling workflows.

### Default workflow and information architecture

- **D-04:** The mounted evidence view should open with a cross-subject overview
  first: “what can Threadline prove right now?”
- **D-05:** The default overview should reuse the Phase 97 mental model:
  latest-per-subject-reference summaries across the fixed evidence inventory,
  not a subject picker and not a raw history dump.
- **D-06:** Subject-focused views should be secondary drill-downs reached
  through URL-driven narrowing on the same `/audit/evidence` surface.

### History and drill-down depth

- **D-07:** Mounted evidence should treat `latest` as the primary operator
  entrypoint but keep append-only history available as explicit drill-down.
- **D-08:** History remains canonical truth, but it should not be the default
  first-class mounted workflow in Phase 98. Doing so would make `/audit` feel
  like a separate evidence-analysis console and would drift from the overview-
  first API/CLI contract already locked in Phase 97.
- **D-09:** The mounted UI must state clearly that “latest” is a convenience
  projection over append-only evidence history, not a second mutable state
  model.

### Mounted parity style

- **D-10:** The mounted UI should translate the proof into an operator-facing
  presentation rather than literally mirroring the Mix-task proof document.
- **D-11:** The mounted layer must preserve the exact underlying proof facts,
  subject inventory, and verdict vocabulary (`proven`, `inferred_posture`,
  `unsupported`) from the evidence proof contract.
- **D-12:** The machine JSON envelope remains the machine contract; mounted UI
  layout should not be forced to expose proof-envelope fields such as
  `format_version` or `proof_type` as first-class UI chrome.
- **D-13:** Parity should be locked through shared presenter/view-model code
  plus tests, not by making LiveView render the CLI/JSON shape verbatim.

### Access posture and unsupported states

- **D-14:** Mounted evidence should behave like a proof/policy-adjacent surface,
  not like the broad timeline. It should use an explicit gated /
  unsupported-view posture rather than automatically inheriting the main
  `/audit` authorization.
- **D-15:** The gate should stay host-owned and align with the existing
  coverage/policy style rather than inventing Threadline-owned RBAC or persona
  semantics.
- **D-16:** When evidence access is denied or unavailable for the current
  transport/access tier, the mounted surface should render an explicit
  unsupported state with CLI/API fallback guidance instead of silently hiding
  the truth surface.
- **D-17:** Support-safe operator sessions must not gain accidental mounted
  evidence visibility just because they can access the main timeline. The
  support-scope posture subject makes this boundary especially important.

### Architectural shape and implementation discipline

- **D-18:** Mounted evidence should be a thin LiveView layer over
  `Threadline.Evidence` and/or `Threadline.Evidence.Proof`, not a second query
  model.
- **D-19:** Shareable state should live in the URL through `handle_params/3`
  and normal LiveView navigation patterns, following the current `/audit`
  surface style.
- **D-20:** Reuse existing operator-surface assets where possible:
  `SurfaceHeader`, `UnsupportedView`, current coverage/policy enabled flags,
  and the sibling-route mount pattern already established in the router.
- **D-21:** Do not introduce page-local semantics that reinterpret evidence
  meaning, host authorization meaning, tenant meaning, or “compliance”
  meaning beyond what the proof payload and prior phases already lock.

### Recommendation-first closure

- **D-22:** Research across all five gray areas converged on one coherent shape:
  `/audit/evidence` as a canonical mounted landing page, overview-first
  latest-summary default, explicit history drill-down, operator-facing
  translation of proof facts, and explicit proof/policy-style gating.
- **D-23:** No major unresolved architectural decision remains for Phase 98.
  Planning should proceed from this cohesive recommendation set unless current
  tree implementation evidence reveals a contradiction.

### the agent's Discretion

- Exact query-param vocabulary and route-state shape for subject/history
  drill-down, as long as it stays URL-driven and additive to the mounted
  `/audit` family.
- Exact grouping and table/card presentation for the overview screen, as long
  as the fixed verdict vocabulary and proof boundary remain explicit.
- Exact presenter/view-model module names and file layout, as long as the
  LiveView layer stays thin over the shared evidence truth model.
- Whether the mounted evidence gate should be a dedicated
  `evidence_authorize_fn` or reuse the existing policy-style seam, as long as
  the access boundary stays explicit, host-owned, and testable.

</decisions>

<specifics>
## Specific Ideas

- The strongest mounted shape is:
  one `/audit/evidence` landing page that answers “what can Threadline prove
  right now?” using latest-per-subject-ref summaries, grouped for scanability,
  with clear claim language and links into bounded history.
- The strongest parity rule is:
  one shared evidence presenter/view-model layer that maps the same proof facts
  into Mix human output, machine JSON, and mounted UI without letting the UI
  drift into a second truth contract.
- The strongest access rule is:
  treat evidence like policy/coverage, not like the broad timeline. If the host
  does not explicitly allow it, render an unsupported state with an honest CLI
  fallback.
- The biggest footguns to avoid are:
  page-local evidence reducers, subject-by-subject mini-surfaces, literal
  proof-document dumping into LiveView, silent omission of denied sections, and
  any support-lane overexposure that weakens the support-safe claim itself.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase contract
- `.planning/ROADMAP.md` — Phase 98 goal, plan slots, and dependency position
- `.planning/REQUIREMENTS.md` — `SURF-01`, `SURF-02`, `SURF-03`
- `.planning/PROJECT.md` — current milestone framing and `/audit` baseline
- `.planning/STATE.md` — active milestone state and current next step
- `.planning/MILESTONE-ARC.md` — v1.22 strategic thesis and non-goal boundary
- `.planning/research/v1.22-policy-evidence-plane.md` — milestone-level shape
  for the evidence plane
- `.planning/research/v1.21-cross-ecosystem-lessons.md` — admin/operator,
  host-auth, and scoped-surface lessons
- `.planning/research/v1.21-option-3-policy-compliance-shape.md` — narrow
  evidence-plane and anti-overreach guidance

### Prior phase decisions that lock Phase 98
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md` —
  fixed evidence subject inventory and negative-claim boundary
- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` —
  `Threadline.Evidence` public API shape, history/latest semantics, explicit
  `repo:` posture
- `.planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md` —
  canonical Mix-task workflow, proof JSON contract, overview-first semantics,
  and proof-language vocabulary
- `.planning/phases/64-raw-timeline-browse-and-filter-form/64-CONTEXT.md` —
  canonical `/audit` entrypoint and URL-as-state browse pattern

### Existing mounted surface and evidence code
- `guides/operator-surface.md` — mounted `/audit` contract, parity philosophy,
  fallback posture, and current screen family
- `guides/domain-reference.md` — evidence proof vocabulary and machine contract
- `lib/threadline/evidence.ex` — canonical evidence read helpers including
  `list_overview/2`, `list_latest_subject_refs/3`, and history APIs
- `lib/threadline/evidence/proof.ex` — proof document shape and verdict mapping
- `lib/mix/tasks/threadline.evidence.show.ex` — overview-first Mix-task UX and
  bounded proof workflow
- `lib/threadline/operator_surface/router.ex` — sibling-route mount pattern and
  current `/audit` route family
- `lib/threadline/operator_surface/auth.ex` — host-owned auth flow and current
  capability booleans for exports/coverage/policy
- `lib/threadline/operator_surface/components/surface_header.ex` — mounted
  header badge/navigation pattern
- `lib/threadline/operator_surface/components/unsupported_view.ex` — truthful
  unsupported-state UI primitive
- `lib/threadline/operator_surface/unsupported.ex` — CLI fallback descriptors
- `lib/threadline/operator_surface/live/timeline_live.ex` — URL-driven default
  state and canonical mounted browse flow
- `lib/threadline/operator_surface/live/coverage_live.ex` — operator-readable
  policy/status presentation pattern
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` — grouped
  status sections and proof-facing read-only surface pattern
- `lib/threadline/operator_surface/live/retention_history_live.ex` — policy-
  adjacent mounted history surface pattern

### Research and prior-art prompts
- `prompts/threadline-elixir-oss-dna.md` — Threadline OSS quality bar, docs,
  contract tests, and operator-surface discipline
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`
  — audit-platform product shape, proof-vs-UX lessons, and ecosystem footguns
- `prompts/audit-lib-domain-model-reference.md` — capture/semantics/exploration
  layering and operator-surface mental model
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md`
  — Phoenix boundary and context guidance
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md`
  — LiveView URL-state, thin-view, and stream/async guidance
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
  — OSS library least-surprise and explicit-configuration guidance

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Evidence.list_overview/2` already gives the right mounted default:
  latest-per-subject-ref overview across the fixed evidence inventory.
- `Threadline.Evidence.Proof` already separates the proof document from human
  rendering, which gives Phase 98 a clean seam for a mounted presenter/view-
  model layer.
- `Threadline.OperatorSurface.Components.UnsupportedView` and
  `Threadline.OperatorSurface.Unsupported` already solve truthful mounted
  fallback messaging for narrower capability surfaces.
- `Threadline.OperatorSurface.Components.SurfaceHeader` already gives the
  mounted surface a shared badge/header grammar that new evidence navigation can
  extend instead of replacing.

### Established Patterns
- The router uses one canonical `/audit` family with sibling routes for
  specialized workflows rather than proliferating separate UI families.
- Mounted views are thin LiveViews over explicit library/context APIs and
  present domain truth in operator-facing tables/sections rather than mirroring
  CLI output literally.
- Capability gating is explicit: broad auth grants the mounted surface, while
  narrower proof/policy/export areas use dedicated enabled flags plus truthful
  unsupported states.
- URL state and `handle_params/3` are already the normal way this repo models
  shareable mounted navigation and filtered operator state.

### Integration Points
- Phase 98 should add one new sibling mounted route under the current operator
  surface router and wire it into existing header/navigation affordances.
- The mounted evidence LiveView should consume `Threadline.Evidence` /
  `Threadline.Evidence.Proof` through shared presenters instead of building
  route-local reducers or direct SQL.
- Access gating should hook into the current `Auth.on_mount/4` capability fan-
  out and reuse the unsupported-state path already established for coverage and
  policy views.
- Existing policy/coverage/export screens should be able to deep-link into
  filtered `/audit/evidence` state rather than duplicating evidence display
  logic locally.

</code_context>

<deferred>
## Deferred Ideas

- A specialist evidence-analysis console where append-only history is the
  default first-class mounted workflow
- Separate evidence UI families, packages, or route trees outside the existing
  `/audit` family
- Threadline-owned RBAC, tenant DSLs, or role semantics for evidence access
- Subject-specific mini-apps that each own their own evidence query logic
- Broader compliance-report packs, approval workflows, or legal-hold UX

</deferred>

---

*Phase: 98-mounted-evidence-views-on-audit*
*Context gathered: 2026-05-26*
