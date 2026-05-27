# Phase 95: Evidence Model Lock And Scope Guard - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 95 defines the durable evidence primitive for v1.22 before public API,
Mix-task, or mounted `/audit` expansion begins. The phase should lock the
subject inventory, the append-only record contract, and the explicit negative
claim boundary so later phases build on one stable truth model.

This phase is not a generic compliance feature drop. It should not add a
Threadline-owned auth model, tenancy DSL, approval workflow, legal-hold flow,
or vendor-reporting suite. UI and task surfaces remain deferred to later
phases once the evidence primitive is stable.

</domain>

<decisions>
## Implementation Decisions

### Evidence scope and ownership

- **D-01:** Evidence is limited to Threadline-owned governance facts and
  posture, not host business-policy meaning.
- **D-02:** The initial supported subject families should be anchored in facts
  the repo already owns today: redaction posture, trigger-coverage posture,
  retention runs/posture, export delivery/posture, and support-lane proof
  posture.
- **D-03:** Host-owned concepts such as role membership, tenancy semantics,
  approval chains, legal hold, and customer-specific compliance states must be
  rejected as first-class evidence subjects in v1.22.
- **D-04:** Support-lane evidence may describe what Threadline enforces or
  proves about scoped reads, but it must not encode host authorization
  decisions as Threadline truth.

### Record contract

- **D-05:** The durable primitive should be a new append-only governance record
  rather than mutating existing export/retention/saved-view rows into an
  overloaded ledger.
- **D-06:** The record contract should include, at minimum: stable `subject`,
  stable `subject_ref`, `recorded_at`, actor/provenance metadata,
  machine-readable `detail`, and a summary field that later phases can render
  consistently across API, Mix, and mounted UI.
- **D-07:** The contract should be versioned explicitly so later subject
  payloads can evolve without redefining the table shape.
- **D-08:** Append-only semantics should be enforced in both schema/API shape
  and verification: evidence rows are inserted as new facts, not updated in
  place to represent new posture.

### Sequencing and milestone boundary

- **D-09:** Phase 95 should land the evidence primitive and boundary guard
  before public create/read APIs (Phase 96), machine-readable proof outputs
  (Phase 97), or mounted evidence views (Phase 98).
- **D-10:** Migration generation must stay aligned with `mix threadline.install`
  so adopters get the evidence table through the existing install path rather
  than a separate setup story.
- **D-11:** Public docs may be touched narrowly to lock the non-goal boundary,
  but broad claim-shaping and end-user guidance remain Phase 99 work.

### Recommendation-first posture

- **D-12:** Prefer boring Elixir/Ecto shapes: one governance table, one schema
  module, one subject inventory/boundary module, strict changesets, and
  explicit tests.
- **D-13:** Negative claims are part of the product contract, not incidental
  prose. The phase should lock them in code/test/doc surfaces early enough that
  later phases cannot silently drift into platform expansion.

### the agent's Discretion

- Exact module names under a coherent `Threadline.Evidence*` namespace, as long
  as the contract remains Phoenix-optional and library-first.
- Exact subject vocabulary within the supported Threadline-owned families, as
  long as unsupported host-owned/compliance-platform subjects are denied
  explicitly.
- Exact field naming for summary/provenance/version columns, as long as the
  contract remains machine-readable and append-only.

</decisions>

<specifics>
## Specific Ideas

- The strongest phase shape is:
  introduce a new `threadline_evidence_records` table plus a schema/subject
  contract, then add boundary-lock tests and narrow doc wording that state what
  evidence Threadline will never pretend to own.
- The cleanest subject model is:
  a stable subject family plus `subject_ref` map, not a giant polymorphic blob
  with implicit meaning.
- The cleanest boundary lock is:
  supported-subject validation plus doc-contract proof for the explicit
  non-goals (`RBAC`, tenancy DSL, legal hold, vendor packs, compliance
  workflow).

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 95 goal, plan slots, and dependency position
- `.planning/REQUIREMENTS.md` — `EVID-01`, `EVID-02`, `EVID-03`
- `.planning/STATE.md` — active milestone state and current next step
- `.planning/MILESTONE-ARC.md` — v1.22 strategic thesis and non-goal boundary
- `.planning/research/v1.22-policy-evidence-plane.md` — milestone-level shape for the evidence plane
- `.planning/research/v1.21-option-3-policy-compliance-shape.md` — narrow evidence-plane recommendation and anti-overreach guardrails

### Existing governance and operator truth surfaces
- `lib/threadline/governance/migration.ex` — current governance-table install path
- `lib/mix/tasks/threadline.install.ex` — migration generation and adopter setup flow
- `lib/threadline/governance/export_job.ex` — existing governance schema pattern
- `lib/threadline/governance/retention_run.ex` — existing governance schema pattern
- `lib/threadline/governance/saved_view.ex` — existing governance schema pattern
- `lib/threadline/retention.ex` — current retention-run recording shape
- `lib/threadline/policy/redaction_presenter.ex` — existing machine-readable posture presenter
- `lib/threadline/health/policy.ex` — strict config validation pattern for bounded subject inputs
- `guides/how-threadline-works.md` — crash-course product boundary and host-owned seam language
- `guides/integration-contracts.md` — host-owned auth/scope semantics that evidence work must not reopen
- `guides/operator-surface.md` — mounted `/audit` boundary and current support-lane claim

### Tests and contract surfaces
- `test/threadline/retention_test.exs` — governance-write proof pattern
- `test/threadline/health/policy_test.exs` — strict validator pattern
- `test/threadline/operator_surface/policy_show_mix_test.exs` — stable machine-readable output expectations
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` — mounted parity expectations for posture surfaces
- `test/threadline/how_threadline_works_doc_contract_test.exs` — crash-course doc-contract lock point
- `test/threadline/integration_contracts_doc_contract_test.exs` — host-owned seam boundary lock point

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Governance persistence already has a clean pattern: one migration source plus
  one Ecto schema per table.
- Redaction and coverage posture already produce machine-readable summaries, so
  evidence records can snapshot stable posture without inventing a new product
  family.
- Retention already records durable runs, which gives the evidence primitive an
  obvious first-class source of owned facts.

### Established Patterns
- Threadline prefers Phoenix-optional library seams with Mix-task and mounted
  parity layered later.
- Config and boundary validation are explicit and fail-loud rather than
  heuristic.
- Public docs and contract tests are treated as product surfaces when a
  non-goal boundary matters.

### Integration Points
- `mix threadline.install` must emit the evidence table through the existing
  governance migration path.
- Subject vocabulary should line up with current posture producers so later API,
  Mix, and mounted surfaces can read the same contract.
- Negative-claim wording must remain aligned with the host-owned auth/scope
  boundary already locked in the docs.

</code_context>

<deferred>
## Deferred Ideas

- Public create/read evidence APIs
- Mix-task JSON export and parity surfaces
- Mounted `/audit` evidence pages
- Generic compliance packs, vendor reports, legal-hold flows, or approval
  workflows
- Threadline-owned RBAC, tenancy DSL, or policy engine semantics

</deferred>

---

*Phase: 95-evidence-model-lock-and-scope-guard*
*Context gathered: 2026-05-25*
