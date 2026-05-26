# Phase 97: Mix-Task And Machine-Readable Proof - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 97 gives Threadline a stable no-Phoenix proof path for the evidence plane.
Operators, CI, and procurement/audit handoff should be able to inspect the
closed evidence inventory through a Mix-task surface and a machine-readable JSON
contract built directly on the Phase 96 public evidence API.

This phase is not a compliance-pack generator, not a host-policy verifier, not
a new write workflow, and not a mounted `/audit` UI phase. It must stay within
the Phase 95-96 boundary: Threadline proves Threadline-owned governance facts,
labels posture honestly, and names unsupported claims explicitly.

</domain>

<decisions>
## Implementation Decisions

### Canonical Mix-task shape

- **D-01:** Phase 97 should ship one canonical evidence viewer under a
  `threadline.evidence` Mix-task namespace rather than a family of per-subject
  tasks.
- **D-02:** The strongest recommended task shape is a viewer-style command such
  as `mix threadline.evidence.show`, not `mix threadline.proof` and not any
  `threadline.compliance.*` naming. The task name should stay narrow and
  Threadline-owned.
- **D-03:** The Mix task should be a thin wrapper over `Threadline.Evidence`
  read helpers. It should not introduce task-local SQL, task-local reducers, or
  a second evidence query model.
- **D-04:** The task is a viewer/exporter, not a CI gate. Default successful
  proof inspection should exit `0`. If a real policy gate is needed later, it
  should be a separate task such as `threadline.evidence.verify`.

### Subject coverage and workflow

- **D-05:** Phase 97 should expose the full closed six-subject evidence set now:
  `redaction_policy`, `trigger_coverage`, `retention_run`,
  `retention_policy`, `export_delivery`, and `support_scope_posture`.
- **D-06:** Do not ship a narrower starter subset. Omitting already-supported
  subject families would create misleading absence, weaken `PROOF-02`, and make
  Phase 98 mounted parity harder.
- **D-07:** Default workflow should be overview-first: one human-readable view
  that shows the latest relevant evidence across the closed inventory before the
  operator has to choose a subject.
- **D-08:** Drill-down should happen through bounded filters, not through extra
  tasks. Recommended filter family:
  - `--subject`
  - `--subject-ref-json` or equivalent explicit subject-ref input
  - `--latest` and `--history`
  - `--from`
  - `--to`
  - `--limit`
- **D-09:** Keep the read model aligned with Phase 96 semantics: `latest` is a
  projection over append-only history, not a second mutable state contract.

### Machine-readable JSON contract

- **D-10:** `--json` should emit one canonical wrapped proof document, not a
  bare array and not serialized human terminal text.
- **D-11:** The wrapped JSON should be versioned and jq-friendly. The
  recommended top-level shape is:
  - `format_version`
  - `generated_at`
  - `proof_type`
  - `subject`
  - `mode`
  - `filters`
  - `summary`
  - `claim_assessment`
  - `records`
- **D-12:** `records` should stay as close as possible to the stable evidence
  row shape already implied by `Threadline.Evidence` and
  `Threadline.Governance.EvidenceRecord`.
- **D-13:** JSON keys should stay stable and additive: snake_case keys,
  machine-stable enums, ISO-8601 UTC timestamps, arrays instead of shape-
  switching maps, and string-keyed nested maps.
- **D-14:** Human output, machine JSON, and future mounted UI serialization are
  three different surfaces. The proof JSON is the machine contract; it must not
  embed UI concerns such as tabs, route state, pagination widgets, or auth-view
  state.
- **D-15:** NDJSON may be added later as an additive large-history/export mode,
  but it should not be the primary Phase 97 proof contract.

### Proof-language boundary

- **D-16:** Phase 97 should use a layered verdict model. Successful proof
  outputs classify claims as:
  - `proven`
  - `inferred_posture`
  - `unsupported`
- **D-17:** Error outcomes stay separate from semantic proof outcomes:
  - `invalid_request`
  - `runtime_failure`
- **D-18:** `proven` is only for claims directly backed by Threadline-owned
  evidence records or deterministic derivations over that evidence. Proven may
  be positive or negative.
- **D-19:** `inferred_posture` is allowed for honest synthesis over owned facts
  or config/posture snapshots, but it must never be presented as proof of
  host-owned behavior or guarantees outside Threadline’s authority.
- **D-20:** `unsupported` means “Threadline does not claim authority here,” not
  false and not an operational failure. Unsupported claims should return valid
  machine-readable output, not crash.
- **D-21:** Unsupported claims should be explicit in the payload. Do not force
  consumers to infer unsupported from missing data or prose.
- **D-22:** Negative evidence that Threadline does own, such as denied or
  failed posture, is still `proven` when the record directly supports it.

### Boundary discipline and DX

- **D-23:** Keep proof semantics in the payload, not in marketing-style command
  names. The task should inspect evidence honestly, not imply a broad
  compliance-pack or attestation product.
- **D-24:** Do not infer provenance, actor meaning, auth meaning, or claim
  semantics from `Plug.Conn`, process-local state, Logger metadata, ETS, or any
  other ambient runtime context.
- **D-25:** Mix-task ergonomics should follow existing Threadline viewer
  patterns: human-readable default, explicit `--json`, bounded flags, and no
  shape-switching return contract hidden behind options.
- **D-26:** Prefer Mix-task idioms that match library OSS expectations:
  explicit help text, discoverable `@shortdoc` / `@moduledoc`, and narrow
  task/bootstrap behavior aligned with the current repo’s viewer commands.

### Recommendation-first workflow posture

- **D-27:** For this phase, research converged on one clear architecture:
  one canonical namespaced viewer task, full closed-subject-set parity, wrapped
  versioned JSON, and layered proof-language semantics. Planning should proceed
  from that recommendation without reopening the decision unless implementation
  evidence exposes a real contradiction.

### the agent's Discretion

- Exact task name inside the `threadline.evidence` namespace, as long as it
  stays a single canonical viewer and avoids product-boundary widening.
- Exact human-readable table/summary layout for the default terminal output, as
  long as overview-first remains the default and JSON stays the machine
  contract.
- Exact field names inside `summary` and `claim_assessment`, as long as the
  layered semantics above remain explicit and machine-stable.
- Exact flag spelling for explicit subject-ref input, as long as it remains
  bounded, explicit, and machine-friendly.

</decisions>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  ship one overview-first evidence viewer task, backed directly by
  `Threadline.Evidence`, with explicit drill-down filters and one versioned JSON
  envelope that makes the proof boundary obvious.
- The strongest ecosystem lesson is:
  high-trust developer tooling wins by separating machine contracts from human
  output, naming blind spots plainly, and keeping viewer semantics separate
  from gate semantics.
- The strongest product-boundary lesson is:
  Threadline should put “proof” in structured evidence semantics, not in a
  broader command family that sounds like a compliance platform.
- The strongest DX rule is:
  users should be able to answer “what can Threadline prove right now?” without
  knowing the internal evidence architecture first.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase contract
- `.planning/ROADMAP.md` — Phase 97 goal, plan slots, and dependency position
- `.planning/REQUIREMENTS.md` — `PROOF-02` and `PROOF-03`
- `.planning/MILESTONE-ARC.md` — v1.22 product boundary and non-goals
- `.planning/STATE.md` — current milestone status and next-step posture
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md` —
  locked evidence subject inventory and negative-claim boundary
- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` —
  locked public API shape and latest/history semantics
- `.planning/phases/96-evidence-persistence-and-public-api/96-RESEARCH.md` —
  public evidence API rationale and Phase 97 split expectations

### Existing code and task patterns
- `lib/threadline/evidence.ex` — public history/latest evidence API that Phase
  97 must prove rather than bypass
- `lib/threadline/evidence/subject.ex` — closed supported-subject inventory
- `lib/threadline/governance/evidence_record.ex` — stable evidence row shape
- `lib/mix/tasks/threadline.health.coverage.ex` — viewer-only Mix-task pattern
  with stable `--json`
- `lib/mix/tasks/threadline.policy.show.ex` — viewer-only parity task with
  compact human output and additive machine contract
- `lib/mix/tasks/threadline.incident.ex` — existing no-Phoenix drill-down task
  precedent
- `lib/mix/tasks/threadline.export.ex` and `lib/threadline/export.ex` —
  strongest local precedent for versioned wrapped JSON and additive NDJSON

### Docs and authority surfaces
- `guides/operator-surface.md` — mounted parity philosophy and no-Phoenix task
  posture
- `guides/domain-reference.md` — existing operational task language and machine
  contract style
- `guides/integration-contracts.md` — host-owned auth/scope boundary that proof
  outputs must not overclaim
- `guides/how-threadline-works.md` — product-boundary framing
- `guides/upgrade-path.md` — authority wording for what Threadline does and
  does not own

### Research and prompt corpus
- `.planning/research/v1.22-policy-evidence-plane.md` — milestone-level evidence
  plane rationale
- `prompts/threadline-elixir-oss-dna.md` — Threadline OSS product and API
  posture
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`
  — ecosystem shape, product-boundary, and DX guidance
- `prompts/audit-lib-domain-model-reference.md` — domain-model guidance for
  audit/evidence systems
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Evidence` already exposes the exact latest/history split that
  Phase 97 should surface through Mix tasks.
- Existing viewer tasks (`health.coverage`, `policy.show`, `incident`) already
  establish the preferred bootstrap and human-vs-JSON split.
- `Threadline.Export` already proves that Threadline prefers versioned wrapped
  JSON as the canonical machine document and uses NDJSON only as an additive
  alternative.

### Established Patterns
- Threadline prefers one truthful library-first public surface with optional
  mounted parity layered later.
- Threadline keeps viewer semantics separate from gate semantics.
- Threadline treats docs/tests/examples as product surfaces and is sensitive to
  overclaiming.
- Threadline avoids hidden ambient provenance or host-owned semantic inference.

### Integration Points
- Phase 97 should build directly on `Threadline.Evidence` instead of creating a
  parallel evidence query path.
- Phase 98 mounted `/audit` evidence views should be able to reuse the same
  overview-first and drill-down mental model from the Phase 97 task.
- The JSON proof envelope should be designed once in Phase 97 so later mounted
  views and docs can align to the same claim language rather than inventing a
  second wording family.

</code_context>

<deferred>
## Deferred Ideas

- Per-subject evidence Mix tasks as the primary public surface
- Compliance-pack / procurement-pack generator task naming or workflows
- A separate CI-gate proof verifier in the same phase
- NDJSON as the primary proof contract
- Any host-auth, tenancy, legal-hold, immutable-storage, or generic compliance
  claims beyond the Threadline-owned evidence boundary

</deferred>

---

*Phase: 97-mix-task-and-machine-readable-proof*
*Context gathered: 2026-05-25*
