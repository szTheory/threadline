# Phase 96: Evidence Persistence And Public API - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 96 turns the Phase 95 evidence primitive into a usable library contract:
Threadline must be able to persist and read evidence records through public,
Phoenix-optional APIs. The phase is about stable create/read semantics and
query shape, not Mix-task output formatting, mounted `/audit` UI, or public
claim language.

This phase does not widen Threadline into a compliance platform, host-owned
auth layer, tenancy DSL, or mutable policy engine. Evidence remains limited to
Threadline-owned governance facts and support posture.

</domain>

<decisions>
## Implementation Decisions

### Public API placement

- **D-01:** The primary public evidence boundary should live under a dedicated
  `Threadline.Evidence` context, not directly on `Threadline` and not on the
  schema module.
- **D-02:** `Threadline` should not gain a broad new evidence CRUD surface in
  Phase 96. Optional root delegates can be considered later only if one or two
  evidence entrypoints become clearly canonical.
- **D-03:** Persistence details stay behind
  `Threadline.Governance.EvidenceRecord`; callers should not interact with the
  schema changeset as the public API.

### Write-side contract

- **D-04:** Public writes should be **subject-focused helpers**, not one open
  generic public writer that accepts arbitrary evidence meaning.
- **D-05:** A private or internal shared insert builder is acceptable to remove
  duplication, but it is not the supported public contract.
- **D-06:** Phase 96 write helpers should stay anchored to the Phase 95 closed
  subject set: redaction posture, trigger coverage posture, retention
  run/policy, export delivery/posture, and support-scope posture.
- **D-07:** The main reason to avoid a generic public writer is boundary
  enforcement: it would make it too easy for adopters or future code to encode
  host RBAC, tenancy semantics, approvals, legal hold, or generic compliance
  claims as if Threadline owned them.

### Read-side contract

- **D-08:** Reads should be generic and history-first: the append-only ledger
  is the canonical truth surface.
- **D-09:** Phase 96 should expose both history reads and latest helpers, with
  `latest` defined as a convenience projection over append-only history rather
  than a second mutable state model.
- **D-10:** Read helpers should support the Phase 97/98 split naturally:
  summary/overview consumers use latest-per-subject-ref helpers, while drill-
  down consumers use history for one subject or one subject reference.
- **D-11:** Use `latest_*` naming, not `current_*`, so append-only semantics
  stay explicit.
- **D-12:** Do not use option-driven functions that change return shape. Lists
  return lists; singular latest/get helpers return one record or `nil`.

### Defaults and provenance

- **D-13:** Threadline should auto-fill only **mechanical, library-owned**
  defaults on evidence writes.
- **D-14:** Safe defaults include normalized `subject`, normalized string-keyed
  `subject_ref`, `recorded_at`, `schema_version`, and a narrow provenance
  envelope such as `writer` / `entrypoint`.
- **D-15:** Semantic meaning stays explicit. Callers or subject-specific
  helpers must provide `summary_status`, `detail`, and any `actor_ref`; the
  library must not invent these implicitly.
- **D-16:** The evidence API must not derive actor/request/provenance context
  from `Plug.Conn`, sockets, the process dictionary, ETS, Logger metadata, or
  any other ambient runtime state.
- **D-17:** If a low-level generic record function exists internally, it should
  require an explicit provenance source; only subject-focused helpers may
  safely auto-label the source because they own the meaning.

### Elixir/Ecto/Phoenix idiom and DX

- **D-18:** The evidence contract should follow the same general shape as the
  rest of Threadline: explicit `repo:` at the edge, context module public API,
  schemas and changesets behind the boundary, and stable return shapes.
- **D-19:** The evidence API should favor small explicit functions over a
  single option-heavy query DSL or mode-switching entrypoint.
- **D-20:** The contract should optimize for one-shot operator/developer
  clarity: overview first, drill-down second, no hidden mutable cache, and no
  Phoenix requirement.

### Recommendation-first closure

- **D-21:** No high-impact gray area remains open after research. Planning
  should proceed using the cohesive recommendation above without another user
  decision gate.

### the agent's Discretion

- Exact function names inside `Threadline.Evidence`, as long as the shape stays:
  namespaced context, subject-focused write helpers, generic history reads, and
  explicit latest helpers.
- Exact pagination and filter naming, as long as return shapes remain stable
  and Phoenix-optional.
- Exact provenance envelope keys, as long as they stay narrow, machine-
  readable, and clearly library-owned.

</decisions>

<specifics>
## Specific Ideas

- The cleanest shape is:
  `Threadline.Evidence` as the public context, with subject-focused
  `record_*` helpers and generic `list_*` / `get_latest_*` read helpers.
- The mental model should be:
  Threadline records append-only evidence facts; “latest” is just a query
  convenience over the ledger, never a mutable current-state table.
- The practical DX rule should be:
  default mechanics, never default meaning.
- Avoid:
  root-module evidence sprawl, generic public write-anything APIs, and ambient
  Phoenix/process magic for provenance.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract and phase boundary
- `.planning/ROADMAP.md` — Phase 96 goal, plan slots, and dependency position
- `.planning/REQUIREMENTS.md` — `PROOF-01` and the evidence-plane boundary
- `.planning/STATE.md` — current milestone state and next-step posture
- `.planning/MILESTONE-ARC.md` — v1.22 strategic thesis and non-goal boundary
- `.planning/research/v1.22-policy-evidence-plane.md` — milestone-level recommended evidence-plane shape
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md` — locked evidence subject and boundary decisions from the prior phase
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-RESEARCH.md` — prior-phase evidence contract and boundary rationale

### Existing code patterns and integration points
- `lib/threadline.ex` — current public API style: explicit `repo:`, stable return shapes, library-first helpers
- `lib/threadline/governance/evidence_record.ex` — append-only evidence schema introduced in Phase 95
- `lib/threadline/evidence/subject.ex` — closed supported-subject inventory and boundary validator
- `lib/threadline/governance/migration.ex` — evidence-table indexes and persistence shape
- `lib/threadline/retention.ex` — governance write pattern with explicit repo and library-owned semantics
- `lib/threadline/export.ex` — generic read/export helper style and filter ergonomics
- `lib/threadline/query.ex` — explicit query-helper conventions, validation style, and stable result-shape precedent
- `lib/threadline/health/policy.ex` — strict bounded validation pattern
- `lib/threadline/policy/redaction_presenter.ex` — machine-readable posture presenter precedent

### Project-local research and prior-art prompts
- `prompts/audit-lib-domain-model-reference.md` — layered audit-platform model and public API/product guidance
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — product-shape, DX, and footgun guidance from adjacent audit libraries
- `prompts/threadline-elixir-oss-dna.md` — Threadline repo norms, API restraint, and verification posture
- `prompts/THREADLINE-GSD-IDEA.md` — project intent and Phoenix/Ecto/Oban composability expectations
- `prompts/prior-art/SOURCE-CANONICAL.md` — prompt-corpus provenance
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — Ecto context and changeset design guidance
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md` — library API and maintainability guidance
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — OSS library ergonomics and supportability guidance
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — boundary, layering, and Phoenix-optional design guidance
- `prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md` — actor/context boundary lessons relevant to evidence provenance
- `prompts/prior-art/from-sigra/Building the gold-standard Elixir:Phoenix authentication library.md` — public API and least-surprise library-shape lessons

### External ecosystem references called out during discussion
- `https://hexdocs.pm/phoenix/contexts.html` — Phoenix context-boundary guidance
- `https://hexdocs.pm/ecto/Ecto.Changeset.html` — changeset responsibilities and validation boundaries
- `https://hexdocs.pm/elixir/main/library-guidelines.html` — Elixir library API guidance
- `https://hexdocs.pm/elixir/process-anti-patterns.html` — warning against hidden process-scoped magic
- `https://hexdocs.pm/carbonite/Carbonite.html` — closest adjacent Elixir audit substrate precedent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Governance.EvidenceRecord` already provides the storage contract
  and append-only schema.
- `Threadline.Evidence.Subject` already closes the supported subject set and
  should remain the guardrail for public evidence APIs.
- `Threadline.Query` and `Threadline.Export` already demonstrate the preferred
  style for explicit filters, validation, pagination, and stable result shapes.
- `Threadline.Health.Policy` shows the repo’s preference for bounded,
  fail-loud validation over permissive free-form options.

### Established Patterns
- Threadline uses context-style public modules with explicit `repo:` options
  rather than hidden repo resolution or web-coupled helpers.
- Root `Threadline` exposes the highest-value core verbs while deeper modules
  own domain-specific behavior; it is intentionally not a flat index of every
  subsystem.
- The codebase prefers machine-readable, queryable data and explicit boundary
  language over magic callbacks or opaque storage.

### Integration Points
- Phase 96 should introduce a `Threadline.Evidence` public context that sits
  between callers and `Threadline.Governance.EvidenceRecord`.
- Later Mix-task and mounted `/audit` work should consume the same history and
  latest read helpers instead of inventing separate reducers or mutable caches.
- Any internal evidence writing from retention/export/operator surfaces should
  route through the same public-context semantics so Phase 97 and 98 inherit
  one truth surface.

</code_context>

<deferred>
## Deferred Ideas

- Root-level `Threadline.*` delegates for evidence APIs unless usage proves one
  or two are clearly canonical
- Mix-task output shape, JSON proof wording, and unsupported-claim handling
  (Phase 97)
- Mounted `/audit` evidence navigation, view models, and authorization wiring
  (Phase 98)
- Public docs and support-matrix wording for the final evidence-plane claim
  (Phase 99)
- Any generic compliance pack, legal-hold flow, approval workflow, RBAC model,
  or tenancy DSL semantics

</deferred>

---

*Phase: 96-evidence-persistence-and-public-api*
*Context gathered: 2026-05-25*
