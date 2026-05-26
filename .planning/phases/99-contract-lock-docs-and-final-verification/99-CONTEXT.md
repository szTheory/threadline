# Phase 99: Contract Lock, Docs, And Final Verification - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 99 freezes the public evidence-plane claim for v1.22. The work is not
new evidence functionality; it is the final contract pass across README,
guides, support-matrix wording, changelog posture, and current-tree
verification so adopters can tell exactly what Threadline proves, what remains
host-owned, and what stronger claims Threadline still does not make.

This phase does not widen the evidence subject set, reopen mounted auth/scope
semantics, add a compliance workflow product, or turn milestone closeout into
an automatic release-cut phase. It locks the claim around the code and proof
already shipped in Phases 95-98.

</domain>

<decisions>
## Implementation Decisions

### README and front-door contract

- **D-01:** Keep `README.md` as the front door and map, not the full evidence
  contract manual.
- **D-02:** Add a compact evidence-plane claim strip to the README: one tight
  summary of what evidence Threadline proves, one explicit host-owned/non-goal
  boundary block, and links to the canonical deeper guides.
- **D-03:** Do not restate support matrices, dependency versions, or detailed
  proof bundles in the README. Those remain canonical in guide-level contract
  docs and verification artifacts.
- **D-04:** README wording should optimize for least surprise: enough detail to
  prevent readers from inferring “Threadline is now a compliance platform,” but
  not so much detail that the README becomes a shadow spec.

### Support-matrix wording for evidence access

- **D-05:** Treat the evidence plane as a separately gated capability under the
  existing `phoenix-surface` lane, not as a capability that automatically
  inherits the broad `/audit` support claim.
- **D-06:** `guides/upgrade-path.md` should keep the named lane model
  (`capture-only`, `phoenix-surface`, `sigra-reference`) and add only the
  minimum extra wording needed to state that `/audit/evidence` is a narrower,
  explicitly authorized capability on the mounted surface.
- **D-07:** Public wording must preserve the shipped Phase 98 semantics:
  evidence access is fail-closed by default, host-owned through
  `evidence_authorize_fn`, and can render an explicit unsupported state even
  when the broader `/audit` lane is mounted and otherwise available.
- **D-08:** Avoid a full lane-by-capability matrix unless future phases add
  enough new gated operator capabilities that the narrower wording stops being
  legible.

### Negative-claim publication strategy

- **D-09:** Publish one canonical public non-goals list, most naturally near
  the front-door “what Threadline is / is not” framing, then echo only the
  locally relevant negatives in deeper guides.
- **D-10:** The canonical list must explicitly reject at least:
  legal hold, immutable-storage guarantees beyond the host runtime/storage
  contract, generic compliance packs, vendor-specific reporting suites, and
  Threadline-owned RBAC or tenancy DSLs.
- **D-11:** Guide-local echoes must stay short and contextual. They should not
  become alternate rewritten copies of the full list.
- **D-12:** Negative claims are part of the product contract and should be
  test-locked like other support-language surfaces; they are not incidental
  prose that can drift release to release.

### Final verification bar

- **D-13:** Phase 99 should close on a balanced claim-shaped rerun bundle, not
  on the minimal targeted suite alone and not on “just run everything” theater.
- **D-14:** The authoritative DOC-03 evidence bar should include:
  current-tree reruns of the phase-owned evidence tests, mounted evidence
  tests, relevant root integration tests, `mix verify.doc_contract`, and
  `mix verify.example`.
- **D-15:** `mix ci.all` is useful repo-health evidence but should not be the
  sole authority for closing the evidence-plane claim, because it is both
  broader than the claim in some ways and narrower than it in others.
- **D-16:** The final verification artifact should record the exact rerun
  bundle and treat that bundle, not summary prose, as the authoritative closeout
  proof.
- **D-17:** Known unrelated failures outside the evidence-plane claim, such as
  the existing CI-topology alias drift called out in state/phase notes, must be
  named explicitly rather than silently inherited into Phase 99 truth.

### Changelog and release posture

- **D-18:** Treat Phase 99 as docs/verification closeout, not as an implicit
  release-cut phase.
- **D-19:** Update `CHANGELOG.md` under `## [Unreleased]` with focused,
  evidence-plane additions/changes if changelog visibility is desired on `main`.
  Do not write a release-style narrative that reads like a shipped `0.6.0`
  announcement before a real version/tag exists.
- **D-20:** Release-specific semantics, package metadata, and `verify.release`
  remain separate concerns unless a later phase explicitly turns the milestone
  closeout into a release-cut.

### Cross-area cohesion rules

- **D-21:** README, upgrade-path, integration-contracts, operator-surface,
  how-threadline-works, and domain-reference wording must reinforce one another
  instead of each trying to become the canonical source for all evidence-plane
  nuance.
- **D-22:** The strongest cohesive posture is:
  README gives the thesis and narrow boundary,
  `guides/upgrade-path.md` owns lane/support proof wording,
  `guides/integration-contracts.md` owns host-owned seams,
  `guides/operator-surface.md` owns mounted capability and fallback posture,
  `guides/domain-reference.md` owns evidence vocabulary and proof semantics.
- **D-23:** All public claim wording should stay aligned with the repo’s core
  OSS values from the prompt corpus: proof-first support claims, least surprise,
  SQL-native truth, strong DX, and explicit operational boundaries.

### Recommendation-first closure

- **D-24:** Research across all five gray areas converged on one coherent
  recommendation set: medium-plus README claim strip, separately gated evidence
  capability wording, one canonical non-goals list plus short echoes, balanced
  claim-shaped rerun bundle, and focused `Unreleased` changelog updates only.
- **D-25:** No unresolved high-impact breakpoint remains. Planning should
  proceed directly from this recommendation set unless current-tree code or doc
  evidence exposes a contradiction.

### the agent's Discretion

- Exact README section title and placement for the evidence-plane claim strip,
  as long as it stays compact and clearly subordinate to the canonical guides.
- Exact guide wording for the evidence capability note, as long as it preserves
  fail-closed host-owned authorization and avoids broad `/audit` inheritance.
- Exact test file mix for the balanced rerun bundle, as long as the selected
  bundle demonstrably covers README/guides/example/mounted/API/CLI evidence
  claims on the current tree.
- Exact `CHANGELOG.md` bullet wording under `Unreleased`, as long as it remains
  honest about branch state and avoids implying a tagged release.

</decisions>

<specifics>
## Specific Ideas

- The strongest front-door shape is:
  one concise README evidence strip plus a canonical non-goals block near “what
  Threadline is / is not,” with links outward rather than a long contract dump.
- The strongest support-lane shape is:
  `phoenix-surface` remains the lane, while `/audit/evidence` is documented as
  a separately authorized mounted capability, similar in posture to narrower
  policy/coverage surfaces rather than the broad timeline path.
- The strongest closeout proof rule is:
  a named rerun bundle is the authority, not milestone prose. Record the exact
  commands and their current-tree outcomes in the phase verification artifact.
- Ecosystem lessons worth preserving:
  README-as-map from Phoenix/Ecto/Oban,
  narrow capability claims from GitLab/Grafana/Kubernetes,
  explicit product-boundary language from Prometheus/pgAudit,
  and avoidance of drift-heavy duplicated claim lists seen in older audit
  libraries across Ruby, Django, and Elixir.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase contract
- `.planning/ROADMAP.md` — Phase 99 goal, plan slots, and dependency position
- `.planning/REQUIREMENTS.md` — `DOC-01`, `DOC-02`, `DOC-03`
- `.planning/PROJECT.md` — product thesis, current milestone framing, and
  host-owned boundary language
- `.planning/STATE.md` — current-tree milestone status, prior closeout lessons,
  and known unrelated verification drift
- `.planning/MILESTONE-ARC.md` — v1.22 strategic thesis and non-goal boundary
- `.planning/research/v1.22-policy-evidence-plane.md` — milestone-level
  evidence-plane rationale and proof posture

### Prior phase decisions that lock Phase 99
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md` —
  fixed evidence scope and negative-claim boundary
- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` —
  public evidence API shape and explicit semantic defaults
- `.planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md` —
  proof vocabulary (`proven`, `inferred_posture`, `unsupported`) and viewer
  posture
- `.planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md` —
  mounted evidence route, parity, and gating decisions
- `.planning/phases/98-mounted-evidence-views-on-audit/98-01-SUMMARY.md` —
  mounted `/audit/evidence` overview/history implementation summary
- `.planning/phases/98-mounted-evidence-views-on-audit/98-02-SUMMARY.md` —
  `evidence_authorize_fn` and shared semantic-parity summary
- `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` —
  current validation plan/draft state for the mounted evidence work

### Public docs and support-language surfaces
- `README.md` — front-door product map and top-level adopter narrative
- `guides/how-threadline-works.md` — product boundary, “what Threadline is /
  is not,” and evidence-plane scope framing
- `guides/domain-reference.md` — evidence proof contract and exact verdict
  vocabulary
- `guides/integration-contracts.md` — host-owned auth/scope boundary and
  evidence-plane non-goal language
- `guides/operator-surface.md` — mounted `/audit` capability wording and
  fallback posture
- `guides/upgrade-path.md` — canonical support-matrix and lane wording
- `CHANGELOG.md` — current public release surface and `Unreleased` bucket

### Proof and test anchors
- `mix.exs` — named `mix verify.*` / `mix ci.*` entrypoints and release
  metadata posture
- `.github/workflows/ci.yml` — current CI topology and stable proof-job naming
- `test/threadline/readme_doc_contract_test.exs` — README contract lock points
- `test/threadline/upgrade_path_doc_contract_test.exs` — support-matrix contract
  lock points
- `test/threadline/integration_contracts_doc_contract_test.exs` — host-owned
  seam and non-goal lock points
- `test/threadline/operator_surface_doc_contract_test.exs` — mounted-surface
  contract lock points
- `test/threadline/evidence_test.exs` — evidence API truth surface
- `test/threadline/evidence/proof_test.exs` — proof-document and verdict
  semantics
- `test/mix/tasks/threadline.evidence_show_test.exs` — CLI/viewer parity and
  unsupported semantics
- `test/threadline/operator_surface/live/evidence_live_test.exs` — mounted
  evidence overview/history/unsupported flows
- `test/threadline/operator_surface/auth_test.exs` — fail-closed evidence
  gating behavior
- `examples/threadline_phoenix/README.md` — reference-host proof surface

### Prompt corpus and architectural guidance
- `prompts/threadline-elixir-oss-dna.md` — OSS verification, doc-contract, and
  release-surface discipline
- `prompts/audit-lib-domain-model-reference.md` — layered audit-platform
  mental model and operator/contract posture
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`
  — audit-library prior art, footguns, and DX guidance
- `prompts/THREADLINE-GSD-IDEA.md` — project vision, non-goals, and maintainer
  intent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The current doc-contract suite already locks README, operator-surface,
  upgrade-path, integration-contracts, getting-started, and example-host
  surfaces, so Phase 99 can extend a mature pattern rather than inventing a new
  documentation-verification mechanism.
- `Threadline.Evidence`, `Threadline.Evidence.Proof`, and the mounted evidence
  tests already provide the semantic center that Phase 99 must describe rather
  than reinterpret.
- `mix.exs` already exposes a layered verification model (`verify.doc_contract`,
  `verify.example`, `verify.test`, `ci.all`, `verify.release`) that supports a
  claim-shaped rerun bundle.

### Established Patterns
- Threadline treats README as the front door and the deeper guides as canonical
  detail surfaces; the README is intentionally not the full support matrix or
  screen-by-screen manual.
- Support claims in this repo are narrow, evidence-backed, and lane-oriented,
  not ecosystem-wide compatibility promises.
- Host-owned auth/scope semantics are fixed boundaries and must not be softened
  by docs phrasing around mounted evidence.
- Verification artifacts are first-class product surfaces, and rerun-backed
  current-tree evidence is preferred over inherited milestone prose.

### Integration Points
- Phase 99 should update README, `how-threadline-works`, `upgrade-path`,
  `integration-contracts`, `operator-surface`, and `CHANGELOG.md` as one
  coherent claim set.
- The doc-contract tests should be extended where needed to lock the new
  evidence-plane wording and non-goal echoes.
- The final verification artifact should cite the exact rerun bundle that
  proves the public claim on the current tree and explicitly separate that from
  unrelated repo-health drift.

</code_context>

<deferred>
## Deferred Ideas

- Turning the v1.22 closeout into a release-cut phase with a version bump, tag,
  and `verify.release` authority bundle
- A full lane-by-capability support matrix if future phases add enough gated
  operator surfaces to justify the extra complexity
- Broader compliance-product positioning, legal-hold flows, immutable archive
  guarantees, vendor-specific report suites, or Threadline-owned RBAC/tenancy
  semantics
- Any README expansion that turns the front door into the full canonical manual
  for every support-lane and evidence-plane edge case

</deferred>

---

*Phase: 99-contract-lock-docs-and-final-verification*
*Context gathered: 2026-05-26*
