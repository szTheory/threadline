# Phase 96: Evidence Persistence And Public API - Research

**Researched:** 2026-05-25
**Domain:** evidence persistence, public context API shape, Ecto query helpers, and Phoenix-optional verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

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
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Public library APIs can create and read evidence records without requiring Phoenix or the mounted operator surface. [VERIFIED: .planning/REQUIREMENTS.md] | Public `Threadline.Evidence` context, subject-focused write helpers, generic history/latest readers, explicit `repo:` options, and ExUnit + PostgreSQL verification preserve the requirement without adding Phoenix coupling. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline.ex, mix.exs, test/test_helper.exs] |
</phase_requirements>

## Summary

Phase 95 already locked the durable evidence row contract in `Threadline.Governance.EvidenceRecord`, the closed subject inventory in `Threadline.Evidence.Subject`, and the install-time DDL for `threadline_evidence_records`; Phase 96 should add the public context and query layer on top of those primitives rather than changing the storage model. [VERIFIED: lib/threadline/governance/evidence_record.ex, lib/threadline/evidence/subject.ex, lib/threadline/governance/migration.ex]

The current public API style is consistent across `Threadline`, `Threadline.Query`, `Threadline.Export`, and `Threadline.Retention`: require explicit `repo:` at the edge, keep list and singular return shapes stable, validate unknown options loudly, and keep schema changesets behind context-style modules. [VERIFIED: lib/threadline.ex, lib/threadline/query.ex, lib/threadline/export.ex, lib/threadline/retention.ex] That repo-local pattern matches Phoenix context guidance and Ecto’s separation between changeset validation and persistence calls. [CITED: https://hexdocs.pm/phoenix/contexts.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**Primary recommendation:** add a new public `Threadline.Evidence` context with six subject-focused `record_*` helpers, a private shared insert builder, generic `list_*` history readers, and explicit `latest_*` projections; keep provenance narrow and mechanical, and never infer it from process- or Phoenix-scoped state. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline.ex, lib/threadline/query.ex] [CITED: https://hexdocs.pm/elixir/process-anti-patterns.html]

## Project Constraints (from CLAUDE.md)

- Keep capture, semantics, and exploration/operations responsibilities separate; this phase belongs in the exploration/operations layer and must not reopen capture-mechanism or host-auth scope. [VERIFIED: CLAUDE.md]
- Use the project’s domain terms consistently, especially `ActorRef` and audit/evidence boundary language. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints such as `mix verify.test` and `mix ci.all` over ad-hoc commands in planner guidance. [VERIFIED: CLAUDE.md, mix.exs]
- Preserve the product boundary: Threadline is not a SIEM, not an auth library, not a tenancy DSL, and not a generic compliance platform. [VERIFIED: CLAUDE.md, .planning/ROADMAP.md, .planning/REQUIREMENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public evidence write API | API / Backend | Database / Storage | The public contract belongs in a context module that validates inputs and writes durable rows through Ecto. [VERIFIED: lib/threadline.ex, lib/threadline/retention.ex] |
| Evidence row validation | Database / Storage | API / Backend | `Threadline.Governance.EvidenceRecord` already owns row shape and required-field validation; Phase 96 should extend that ownership only to persistence invariants. [VERIFIED: lib/threadline/governance/evidence_record.ex] |
| Subject boundary enforcement | API / Backend | Database / Storage | `Threadline.Evidence.Subject` is the explicit guardrail against unsupported subjects before a row is inserted. [VERIFIED: lib/threadline/evidence/subject.ex, test/threadline/evidence/subject_test.exs] |
| History/latest read helpers | API / Backend | Database / Storage | Read ergonomics should live with the public context, while Ecto queries remain the implementation detail that projects the append-only table. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline/query.ex] |
| Phoenix-optional proof path | API / Backend | — | `PROOF-01` is satisfied by library APIs plus ExUnit/PostgreSQL integration tests; Phoenix remains optional in `mix.exs`. [VERIFIED: .planning/REQUIREMENTS.md, mix.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Runtime and public library surface. | Local environment and project support are already aligned here. [VERIFIED: `elixir --version`, mix.exs] |
| Ecto | 3.13.5 | Changesets, queries, and Repo persistence. | The evidence API should reuse the same validation/query substrate as the rest of Threadline. [VERIFIED: mix.lock, lib/threadline/query.ex, lib/threadline/governance/evidence_record.ex] |
| Ecto SQL | 3.13.5 | PostgreSQL query execution and migrations. | Existing migration and integration-test flows already depend on it. [VERIFIED: mix.lock, lib/threadline/governance/migration.ex, test/test_helper.exs] |
| PostgreSQL | 14.17 client available | JSONB storage, GIN index support, and append-only evidence queries. | Evidence rows already use JSONB `subject_ref`, `provenance`, and `detail` fields in the governance migration. [VERIFIED: `psql --version`, lib/threadline/governance/migration.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | 1.8.7 optional | Not required for Phase 96 runtime. | Only later mounted `/audit` consumers need it; Phase 96 APIs must not. [VERIFIED: mix.lock, mix.exs, .planning/REQUIREMENTS.md] |
| ExUnit | bundled with Elixir | Unit and integration verification. | Use for context, schema, and query contract tests. [VERIFIED: test/test_helper.exs, test/support/data_case.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Threadline.Evidence` public context | Root-level `Threadline.record_*` delegates | Reject for now because the root module intentionally exposes only the highest-value verbs and Phase 96 explicitly avoids broad root evidence CRUD. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline.ex] |
| Subject-focused public writers | One generic public `record_evidence/2` | Reject because it weakens the Phase 95 subject boundary and encourages host-policy meanings that Threadline does not own. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline/evidence/subject.ex] |
| One `list/2` query DSL with mode switches | Small explicit history/latest functions | Recommend small functions because existing public APIs prefer stable shapes over option-driven mode changes. [VERIFIED: lib/threadline.ex, lib/threadline/query.ex, lib/threadline/export.ex] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Dependency versions above were verified from the checked-in `mix.lock`, and runtime/tool availability was verified from local commands rather than training memory. [VERIFIED: mix.lock, `elixir --version`, `mix --version`, `psql --version`]

## Architecture Patterns

### System Architecture Diagram

```text
caller
  -> Threadline.Evidence.record_* helper
  -> validate repo/options + normalize subject_ref + build provenance
  -> Threadline.Evidence.Subject.validate/1
  -> Threadline.Governance.EvidenceRecord.changeset/2
  -> repo.insert/1
  -> threadline_evidence_records

caller
  -> Threadline.Evidence.list_* / latest_* helper
  -> validate repo/options + normalize subject_ref
  -> Ecto query builder
  -> repo.all/1 or repo.one/1
  -> evidence rows or nil
```

### Recommended Project Structure

```text
lib/
├── threadline/evidence.ex        # public context: record/list/latest helpers
├── threadline/evidence/query.ex  # internal query builders for history/latest projections
├── threadline/evidence/subject.ex
└── threadline/governance/evidence_record.ex
```

`Threadline.Evidence.Query` is a recommendation for internal organization, not a required public surface; private functions inside `Threadline.Evidence` are also acceptable if the module stays small. [ASSUMED]

### Pattern 1: Subject-Focused Writers Over a Private Shared Insert Builder

**What:** Expose one public helper per supported subject family and funnel them through one private normalization/insert function. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**When to use:** Use this for all Phase 96 writes because the subject list is closed and public meaning must stay explicit. [VERIFIED: lib/threadline/evidence/subject.ex, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Recommended helper family:** `record_redaction_policy/3`, `record_trigger_coverage/3`, `record_retention_run/3`, `record_retention_policy/3`, `record_export_delivery/3`, and `record_support_scope_posture/3`. [ASSUMED]

**Recommended argument shape:** `record_<subject>(subject_ref, attrs, opts \\ [])` where `attrs` must contain `:summary_status` and `:detail`, may contain `:actor_ref` and `:recorded_at`, and `opts` must contain `:repo`. [ASSUMED]

**Why this shape fits the repo:** `Threadline.record_action/2` already keeps `repo:` in `opts` while building attrs internally, and `Threadline.Retention.purge/1` keeps public orchestration separate from schema details. [VERIFIED: lib/threadline.ex, lib/threadline/retention.ex]

**Example:**
```elixir
# Source basis: lib/threadline.ex, lib/threadline/retention.ex
def record_retention_run(subject_ref, attrs, opts \\ []) do
  record_subject("retention_run", subject_ref, attrs, opts,
    provenance: %{"writer" => "threadline", "entrypoint" => "record_retention_run"}
  )
end
```

### Pattern 2: Context Owns Option Validation; Schema Owns Row Invariants

**What:** Validate public API options and supported subjects in `Threadline.Evidence`; keep `Threadline.Governance.EvidenceRecord.changeset/2` responsible for durable row validity. [VERIFIED: lib/threadline/governance/evidence_record.ex, lib/threadline/health/policy.ex]

**When to use:** Always; it matches existing context/query modules and keeps callers away from raw changesets. [VERIFIED: lib/threadline.ex, lib/threadline/query.ex, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Concrete ownership split:** Public layer should validate `:repo`, allowed opt keys, positive `:limit`, and normalized subject/subject_ref input; schema layer should enforce required fields, non-empty summary status, supported subject membership, map fields, and positive `schema_version`. [ASSUMED]

**Why this split fits Ecto:** Ecto changesets are the documented place for data casting and validation, while contexts define the public API boundary around them. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [CITED: https://hexdocs.pm/phoenix/contexts.html]

### Pattern 3: Generic History Reads Plus Explicit `latest_*` Projections

**What:** Keep history as the source of truth and layer latest helpers on top of the same table. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**When to use:** Use list helpers for drill-down and latest helpers for Phase 97/98 overview surfaces. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Recommended read family:** `list_subject_history/2`, `list_subject_ref_history/3`, `get_latest_subject_ref/3`, and `list_latest_subject_refs/2`. [ASSUMED]

**Recommended filters:** `:repo` required everywhere; `:limit`, `:from`, `:to`, and optional `:summary_status` on list helpers only. [ASSUMED]

**Repo-local rationale:** `Threadline.Query` and `Threadline.Export` already use small helper families, explicit repo resolution, and bounded filter vocabularies instead of one polymorphic reader. [VERIFIED: lib/threadline/query.ex, lib/threadline/export.ex]

**Example:**
```elixir
# Source basis: lib/threadline/query.ex
def get_latest_subject_ref(subject, subject_ref, opts) do
  repo = Keyword.fetch!(opts, :repo)

  subject
  |> subject_ref_history_query(subject_ref, opts)
  |> order_by([er], desc: er.recorded_at, desc: er.inserted_at, desc: er.id)
  |> limit(1)
  |> repo.one()
end
```

### Pattern 4: Use Deterministic Ecto Ordering for Latest Queries

**What:** Order latest queries by `recorded_at DESC, inserted_at DESC, id DESC` so ties are deterministic even when two rows share the same business timestamp. [VERIFIED: lib/threadline/governance/evidence_record.ex, lib/threadline/governance/migration.ex]

**When to use:** Apply this ordering to both singular `get_latest_*` queries and latest-per-subject-ref list projections. [ASSUMED]

**Viable query shapes:** `DISTINCT ON (subject_ref)` is compact and PostgreSQL-native; a `row_number()` window partition is more explicit but more verbose; an application-side reducer should be rejected because it loads unnecessary history and hides ordering semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: lib/threadline/governance/migration.ex] [ASSUMED]

**Recommendation:** Prefer `DISTINCT ON` for `list_latest_subject_refs/2` because Threadline is PostgreSQL-first, the table already has modest initial indexing, and Ecto exposes Postgres `distinct` ordering directly. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: lib/threadline/governance/migration.ex] If the planner expects higher per-subject evidence volume later, reserve a follow-up optimization to switch that helper to a window-function subquery without changing the public API. [ASSUMED]

### Anti-Patterns to Avoid

- **Public schema changesets:** Do not expose `Threadline.Governance.EvidenceRecord.changeset/2` as the supported write surface. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline/governance/evidence_record.ex]
- **Ambient provenance capture:** Do not read `Plug.Conn`, process dictionary, ETS, Logger metadata, or sockets to backfill provenance. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/process-anti-patterns.html]
- **Option-driven return-shape changes:** Do not make one reader return a list in one mode and one row in another. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]
- **Generic public evidence writer:** Do not add a `record/2` or `create_evidence/1` escape hatch in Phase 96. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public evidence semantics | Free-form writer DSL | Subject-focused helper family in `Threadline.Evidence` | Boundary enforcement is the main product requirement here, not raw write throughput. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] |
| Provenance discovery | Process- or Phoenix-scoped context lookup | Explicit attrs plus helper-owned provenance defaults | Hidden process state is explicitly forbidden and fragile across async boundaries. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/process-anti-patterns.html] |
| Latest projections | App-side `Enum.group_by` reducers over full history | Ordered Ecto query with `DISTINCT ON` or window projection | Query-time projection keeps history canonical and avoids unnecessary row loading. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| Option intake | Permissive keyword lists with ignored keys | Fail-loud validation matching `Threadline.Query` and `Threadline.Health.Policy` | The repo consistently treats unknown API/filter keys as programmer errors. [VERIFIED: lib/threadline/query.ex, lib/threadline/health/policy.ex] |

**Key insight:** The hard part of Phase 96 is boundary-safe public meaning, not raw persistence plumbing, because the storage primitive already exists. [VERIFIED: lib/threadline/governance/evidence_record.ex, lib/threadline/evidence/subject.ex]

## Common Pitfalls

### Pitfall 1: Letting the Public API Bypass the Closed Subject Inventory

**What goes wrong:** A generic public writer or public provenance override turns the evidence plane into a host-policy escape hatch. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Why it happens:** The storage table is flexible enough to hold arbitrary JSONB, so discipline has to live in the context boundary. [VERIFIED: lib/threadline/governance/evidence_record.ex, lib/threadline/governance/migration.ex]

**How to avoid:** Validate supported subjects before insert and keep public writers per subject family. [VERIFIED: lib/threadline/evidence/subject.ex, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Warning signs:** A proposed public function accepts raw `subject`, raw `provenance`, or a catch-all `attrs` map with no helper-specific meaning. [ASSUMED]

### Pitfall 2: Putting Semantic Defaults in the Changeset

**What goes wrong:** The schema starts inventing business meaning instead of validating durable rows. [VERIFIED: lib/threadline/governance/evidence_record.ex]

**Why it happens:** It is tempting to hide subject names, timestamps, and provenance inside one generic changeset call. [ASSUMED]

**How to avoid:** Normalize mechanical defaults in the context and keep the changeset focused on storage invariants. [CITED: https://hexdocs.pm/phoenix/contexts.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**Warning signs:** `EvidenceRecord.changeset/2` begins calling `DateTime.utc_now/1`, reading application env, or branching on helper-specific semantics. [ASSUMED]

### Pitfall 3: Returning “Current State” APIs That Hide History Semantics

**What goes wrong:** Callers treat evidence as mutable state instead of append-only history. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Why it happens:** “Current” naming and overloaded readers are easier to reach for than explicit history/latest helpers. [ASSUMED]

**How to avoid:** Use `latest_*` naming only for projections over history and preserve separate list/singular functions. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

**Warning signs:** Proposed functions named `current_*` or `get_*` with `mode: :latest | :history`. [ASSUMED]

### Pitfall 4: Losing Determinism on Equal Timestamps

**What goes wrong:** Latest helpers can return different rows when two records share the same `recorded_at`. [VERIFIED: lib/threadline/governance/evidence_record.ex, lib/threadline/governance/migration.ex]

**Why it happens:** The table is append-only and `recorded_at` is caller- or helper-supplied, so ties are possible. [VERIFIED: lib/threadline/governance/evidence_record.ex]

**How to avoid:** Always add `inserted_at` and `id` to descending latest-order clauses. [ASSUMED]

**Warning signs:** Queries that sort only by `recorded_at DESC`. [ASSUMED]

## Code Examples

Verified patterns from repo and official docs:

### Public Context Writer Pattern
```elixir
# Source basis: lib/threadline.ex, lib/threadline/retention.ex, https://hexdocs.pm/phoenix/contexts.html
def record_export_delivery(subject_ref, attrs, opts \\ []) do
  repo = Keyword.fetch!(opts, :repo)
  normalized_ref = normalize_subject_ref!(subject_ref)

  attrs =
    attrs
    |> Map.new()
    |> Map.put_new(:recorded_at, DateTime.utc_now(:microsecond))
    |> Map.put_new(:schema_version, 1)
    |> Map.put(:subject, "export_delivery")
    |> Map.put(:subject_ref, normalized_ref)
    |> Map.put(:provenance, %{"writer" => "threadline", "entrypoint" => "record_export_delivery"})

  "export_delivery"
  |> Threadline.Evidence.Subject.validate()
  |> case do
    :ok -> repo.insert(Threadline.Governance.EvidenceRecord.changeset(%Threadline.Governance.EvidenceRecord{}, attrs))
    error -> error
  end
end
```

### Generic Latest-Projection Query Pattern
```elixir
# Source basis: lib/threadline/query.ex, https://hexdocs.pm/ecto/Ecto.Query.html
def list_latest_subject_refs(subject, opts) do
  repo = Keyword.fetch!(opts, :repo)
  limit = Keyword.get(opts, :limit, 50)

  Threadline.Governance.EvidenceRecord
  |> where([er], er.subject == ^subject)
  |> order_by([er], asc: er.subject_ref, desc: er.recorded_at, desc: er.inserted_at, desc: er.id)
  |> distinct([er], er.subject_ref)
  |> limit(^limit)
  |> repo.all()
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct schema primitive only | Public context over the schema primitive | Phase 96 recommendation after Phase 95 locked the row contract. [VERIFIED: .planning/phases/95-evidence-model-lock-and-scope-guard/95-RESEARCH.md, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] | Keeps persistence private while making Phoenix-optional usage possible. [VERIFIED: .planning/REQUIREMENTS.md] |
| Implicit “current” mental model | Explicit history plus `latest_*` projections | Locked in Phase 96 context decisions. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] | Prevents accidental mutable-state semantics in later Mix/UI phases. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**
- Public schema or root-module-first evidence APIs are not the recommended shape for this phase. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Threadline.Evidence.Query` should exist as an internal module rather than private functions inside `Threadline.Evidence`. | Architecture Patterns | Low; this is an organization choice, not a public contract. |
| A2 | The public writer family should use `record_<subject>(subject_ref, attrs, opts \\ [])` rather than a different explicit arity. | Architecture Patterns | Low; naming/arity can change as long as the locked shape stays subject-focused and explicit. |
| A3 | `DISTINCT ON (subject_ref)` is the best first implementation for latest-per-subject-ref helpers on this tree. | Architecture Patterns | Medium; a window-function subquery may be better if evidence volume or JSONB ordering behavior becomes a concern. |

## Open Questions

1. **No blocking phase-scope question remains.** The only remaining implementation discretion is naming and internal module placement, which Phase 96 explicitly leaves to the agent. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | context implementation and tests | ✓ | 1.19.5 | — |
| Mix | verification aliases and compilation | ✓ | 1.19.5 | — |
| PostgreSQL client | integration-test connectivity checks | ✓ | 14.17 | — |
| Local PostgreSQL server | `Threadline.DataCase` and `test/test_helper.exs` migrations | ✓ | accepting connections on `localhost:5432` | none for integration tests |
| Phoenix | mounted UI phases only | optional / not required | 1.8.7 in lockfile | Skip entirely in Phase 96 |

**Missing dependencies with no fallback:**
- None. [VERIFIED: `elixir --version`, `mix --version`, `psql --version`, `pg_isready`]

**Missing dependencies with fallback:**
- None for this phase. [VERIFIED: mix.exs, config/test.exs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Ecto/PostgreSQL integration tests. [VERIFIED: test/test_helper.exs, test/support/data_case.ex, mix.exs] |
| Config file | `test/test_helper.exs` plus `config/test.exs`. [VERIFIED: test/test_helper.exs, config/test.exs] |
| Quick run command | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs --max-failures 1` for primitive regressions, plus new Phase 96 evidence-context tests once added. [VERIFIED: test/threadline/governance/evidence_record_test.exs, test/threadline/evidence/subject_test.exs] |
| Full suite command | `mix verify.test` and phase gate `mix ci.all`. [VERIFIED: mix.exs, CLAUDE.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Subject-focused public helpers insert evidence rows with explicit `repo:` and no Phoenix/runtime ambient provenance. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] | integration | `mix test test/threadline/evidence_test.exs --max-failures 1` | ❌ Wave 0 |
| PROOF-01 | Generic history/latest readers return stable list/singular shapes from the append-only table. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] | integration | `mix test test/threadline/evidence_test.exs --max-failures 1` | ❌ Wave 0 |
| PROOF-01 | Option validation rejects missing repo and unknown keys loudly. [VERIFIED: lib/threadline/query.ex, lib/threadline/health/policy.ex] | unit | `mix test test/threadline/evidence_test.exs --max-failures 1` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/evidence_test.exs --max-failures 1` once the new file exists. [ASSUMED]
- **Per wave merge:** `mix verify.test`. [VERIFIED: mix.exs]
- **Phase gate:** `mix ci.all`. [VERIFIED: mix.exs, CLAUDE.md]

### Wave 0 Gaps

- [ ] `test/threadline/evidence_test.exs` — public context write/read contract, latest ordering, and explicit repo/option validation. [VERIFIED: test/threadline/governance/evidence_record_test.exs, test/threadline/evidence/subject_test.exs]
- [ ] Add a deterministic latest-tie test with identical `recorded_at` and different inserted rows. [ASSUMED]
- [ ] Add a “no ambient provenance” regression test by calling public helpers without any Plug/process setup and asserting helper-owned provenance only. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host auth remains out of scope for this phase. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] |
| V3 Session Management | no | No session surface is added in Phase 96. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | The API is library-facing and Phoenix-optional; mounted auth is deferred to Phase 98. [VERIFIED: .planning/ROADMAP.md, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] |
| V5 Input Validation | yes | Explicit opt validation plus supported-subject validation plus changeset required fields. [VERIFIED: lib/threadline/evidence/subject.ex, lib/threadline/governance/evidence_record.ex, lib/threadline/query.ex] |
| V6 Cryptography | no | No crypto surface is added here. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsupported subject injection | Tampering | Validate against `Threadline.Evidence.Subject` before insert and avoid a generic public writer. [VERIFIED: lib/threadline/evidence/subject.ex, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] |
| Forged or hidden provenance | Repudiation | Keep provenance helper-owned and explicit; forbid ambient process/Phoenix derivation. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md] [CITED: https://hexdocs.pm/elixir/process-anti-patterns.html] |
| Unbounded history reads | Denial of service | Bound list helpers with validated `:limit` and preserve explicit latest helpers for overview consumers. [VERIFIED: lib/threadline/query.ex, lib/threadline/export.ex] [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `CLAUDE.md` - project architecture, terminology, and verification directives.
- `.planning/ROADMAP.md` - Phase 96 goal, dependency position, and non-goal boundary.
- `.planning/REQUIREMENTS.md` - `PROOF-01`.
- `.planning/STATE.md` - current milestone posture.
- `.planning/MILESTONE-ARC.md` - v1.22 evidence-plane scope.
- `.planning/research/v1.22-policy-evidence-plane.md` - milestone-level evidence-plane strategy.
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md` - prior locked evidence boundary.
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-RESEARCH.md` - prior primitive recommendation.
- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` - locked decisions for this phase.
- `lib/threadline.ex` - public API style and explicit `repo:` pattern.
- `lib/threadline/governance/evidence_record.ex` - current evidence schema and changeset.
- `lib/threadline/evidence/subject.ex` - closed subject inventory.
- `lib/threadline/governance/migration.ex` - evidence table DDL and indexes.
- `lib/threadline/retention.ex` - governance write orchestration pattern.
- `lib/threadline/export.ex` - stable list-return/export helper and option-validation pattern.
- `lib/threadline/query.ex` - explicit repo/filter validation and keyset helper pattern.
- `lib/threadline/health/policy.ex` - fail-loud bounded validation pattern.
- `lib/threadline/policy/redaction_presenter.ex` - machine-readable posture precedent.
- `mix.exs`, `mix.lock`, `config/test.exs`, `test/test_helper.exs`, `test/support/data_case.ex`, `test/threadline/governance/evidence_record_test.exs`, `test/threadline/evidence/subject_test.exs`, `test/threadline/retention_test.exs` - dependency, environment, and test-shape verification.

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/phoenix/contexts.html` - context-boundary guidance.
- `https://hexdocs.pm/ecto/Ecto.Changeset.html` - changeset responsibility guidance.
- `https://hexdocs.pm/ecto/Ecto.Query.html` - `distinct` / ordering query support.
- `https://hexdocs.pm/elixir/process-anti-patterns.html` - warning against hidden process-scoped state.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and runtime availability were verified from `mix.lock` and local commands. [VERIFIED: mix.lock, `elixir --version`, `mix --version`, `psql --version`, `pg_isready`]
- Architecture: HIGH - the recommended public shape matches locked Phase 96 decisions and existing repo-local API/query patterns. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline.ex, lib/threadline/query.ex, lib/threadline/retention.ex]
- Pitfalls: HIGH - the main failure modes are explicit in the locked context plus existing strict-validation and no-ambient-state guidance. [VERIFIED: .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md, lib/threadline/health/policy.ex] [CITED: https://hexdocs.pm/elixir/process-anti-patterns.html]

**Research date:** 2026-05-25
**Valid until:** 2026-06-24
