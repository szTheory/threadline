# Phase 96: Evidence Persistence And Public API - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 3 likely files/modules
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/evidence.ex` | service | CRUD | `lib/threadline/export.ex`, `lib/threadline/investigation.ex`, `lib/threadline.ex` | role-match |
| `lib/threadline/governance/evidence_record.ex` | model | CRUD | `lib/threadline/governance/retention_run.ex`, `lib/threadline/governance/export_job.ex` | exact |
| `test/threadline/evidence_test.exs` | test | CRUD | follow existing public-context test shape near `Threadline.Export` / `Threadline.Query` callers | partial |

## Pattern Assignments

### `lib/threadline/evidence.ex` (public context, CRUD)

**Primary analogs**

- `lib/threadline/export.ex`
- `lib/threadline/investigation.ex`
- `lib/threadline.ex`

**Imports and boundary shape**  
Copy the small public-context style: aliases only, explicit `repo:` at the edge, delegate or compose lower-level modules rather than exposing schemas directly.

From [lib/threadline/export.ex](/Users/jon/projects/threadline/lib/threadline/export.ex:48):
```elixir
import Ecto.Query

alias NimbleCSV.RFC4180, as: RFC4180
alias Threadline.Query
alias Threadline.Semantics.ActorRef
```

From [lib/threadline/investigation.ex](/Users/jon/projects/threadline/lib/threadline/investigation.ex:9):
```elixir
alias Threadline.Query
alias Threadline.Query.TimelinePage
```

**Root/public API restraint**  
Do not add broad root-module CRUD. Existing root helpers are selective delegates, not a flat subsystem index.

From [lib/threadline.ex](/Users/jon/projects/threadline/lib/threadline.ex:122):
```elixir
def timeline(filters \\ [], opts \\ []), do: Threadline.Query.timeline(filters, opts)

def timeline_page(filters \\ [], opts \\ []), do: Threadline.Query.timeline_page(filters, opts)
```

**Repo option convention**  
Public entrypoints either `Keyword.fetch!` a required repo or resolve it through a dedicated helper. Phase 96 should keep evidence APIs explicit and Phoenix-optional.

From [lib/threadline/investigation.ex](/Users/jon/projects/threadline/lib/threadline/investigation.ex:200):
```elixir
defp linked_changes(changes, opts) when is_list(changes) do
  repo = Query.timeline_repo!([], opts)

  changes
  |> Query.preload_investigation_context(repo)
  |> to_linked_changes()
end
```

From [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:212):
```elixir
@spec timeline_repo!(keyword(), keyword()) :: module()
def timeline_repo!(filters \\ [], opts \\ []) when is_list(filters) and is_list(opts) do
  case Keyword.get(opts, :repo) || Keyword.get(filters, :repo) do
    nil ->
      raise ArgumentError,
            "missing :repo for timeline/export — pass `repo: MyApp.Repo` in filters or opts " <>
              "(see `Threadline.Query.timeline/2` and `Threadline.Export`)."
```

**Helper naming and return-shape conventions**  
Use small explicit verbs. Lists stay lists. Singular helpers return one record or `nil`. Separate eager history from convenience latest helpers; do not use options that change return shape.

From [lib/threadline/investigation.ex](/Users/jon/projects/threadline/lib/threadline/investigation.ex:25):
```elixir
def row_history(schema_module, id, filters \\ [], opts \\ []) do
  filters = validate_helper_filters!(filters, @allowed_row_history_filter_keys, :row_history)

  schema_module
  |> Query.row_history(id, filters, opts)
  |> linked_changes(opts)
end
```

From [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:108):
```elixir
@spec audit_transaction(term(), keyword()) :: AuditTransaction.t() | nil
def audit_transaction(transaction_id, opts) do
```

From [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:364):
```elixir
def history(schema_module, id, opts) do
  repo = Keyword.fetch!(opts, :repo)
```

**Append-only latest/history split**  
Use history as canonical truth, then project latest from ordered history. Existing query code consistently orders newest-first and keeps singular read helpers separate from list helpers.

From [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:370):
```elixir
AuditChange
|> where([ac], ac.table_name == ^table)
|> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
|> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
|> order_by([ac], desc: ac.captured_at)
|> repo.all()
```

From [lib/threadline/query.ex](/Users/jon/projects/threadline/lib/threadline/query.ex:407):
```elixir
snapshot =
  AuditChange
  |> where([ac], ac.table_name == ^table)
  |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
  |> where([ac], ac.captured_at <= ^timestamp)
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> order_by([ac], desc: ac.captured_at)
  |> order_by([ac], desc: ac.id)
  |> limit(1)
  |> repo.one()
```

**Write-side insert pattern**  
Keep schema changesets behind the context boundary. The public helper should build attrs, call the schema changeset internally, and return `{:ok, schema}` or `{:error, changeset}`.

From [lib/threadline.ex](/Users/jon/projects/threadline/lib/threadline.ex:44):
```elixir
result =
  with :ok <- validate_repo(repo),
       {:ok, validated_ref} <- validate_actor(actor_ref) do
    attrs = build_attrs(name, validated_ref, opts)
    changeset = AuditAction.changeset(attrs)
    repo.insert(changeset)
  end
```

**Planner guidance for evidence API names**

- Write helpers should follow the repo’s explicit helper style: `record_redaction_policy/2`, `record_trigger_coverage/2`, `record_retention_run/2`, `record_retention_policy/2`, `record_export_delivery/2`, `record_support_scope_posture/2`.
- Read helpers should follow list/singular split: `list_evidence_history/2`, `list_subject_history/3`, `get_latest_evidence/2`, `get_latest_subject/3` or similarly explicit names.
- Prefer `latest_` over `current_`.

---

### `lib/threadline/governance/evidence_record.ex` (schema, CRUD)

**Primary analogs**

- `lib/threadline/governance/retention_run.ex`
- `lib/threadline/governance/export_job.ex`
- existing `lib/threadline/governance/evidence_record.ex`

**Schema/changeset boundary**  
The repo uses plain Ecto schemas with `@doc false` changesets. Validation should stay narrow and structural here; semantic meaning belongs in the public context helper.

From [lib/threadline/governance/evidence_record.ex](/Users/jon/projects/threadline/lib/threadline/governance/evidence_record.ex:15):
```elixir
schema "threadline_evidence_records" do
  field(:subject, :string)
  field(:subject_ref, :map)
  field(:summary_status, :string)
  field(:recorded_at, :utc_datetime_usec)
  field(:actor_ref, Threadline.Semantics.ActorRef)
  field(:provenance, :map)
  field(:detail, :map)
  field(:schema_version, :integer)
  field(:inserted_at, :utc_datetime_usec)
end
```

From [lib/threadline/governance/evidence_record.ex](/Users/jon/projects/threadline/lib/threadline/governance/evidence_record.ex:37):
```elixir
@doc false
def changeset(record \\ %__MODULE__{}, attrs) do
  record
  |> cast(attrs, [
    :subject,
    :subject_ref,
    :summary_status,
    :recorded_at,
    :actor_ref,
    :provenance,
    :detail,
    :schema_version
  ])
  |> validate_required(@required_fields)
end
```

Supporting analogs:

From [lib/threadline/governance/retention_run.ex](/Users/jon/projects/threadline/lib/threadline/governance/retention_run.ex:25):
```elixir
@doc false
def changeset(run \\ %__MODULE__{}, attrs) do
  run
  |> cast(attrs, [
    :status,
    :deleted_count,
    :duration_ms,
    :error_message,
    :started_at,
    :completed_at
  ])
  |> validate_required([:status])
end
```

From [lib/threadline/governance/export_job.ex](/Users/jon/projects/threadline/lib/threadline/governance/export_job.ex:27):
```elixir
@doc false
def changeset(job \\ %__MODULE__{}, attrs) do
  job
  |> cast(attrs, [
    :status,
    :query_params,
    :actor_ref,
    :file_path,
    :error_message,
    :started_at,
    :completed_at,
    :expires_at
  ])
  |> validate_required([:status, :query_params])
end
```

**Planner guidance**

- Keep `subject_ref`, `provenance`, and `detail` machine-readable maps.
- Normalize keys before the changeset if the public API promises string-keyed maps.
- Do not push subject-policy validation or provenance derivation into the schema changeset.

---

### `test/threadline/evidence_test.exs` (public API tests, CRUD)

**Primary analogs**

- Public API tests around `Threadline.Query`-style helper contracts
- Public API tests around export/list helper return maps

**What to verify**

- Every public evidence entrypoint requires explicit `repo:`.
- Unsupported subjects are rejected via `Threadline.Evidence.Subject`.
- History helpers always return lists, including `[]`.
- Latest helpers return one `%EvidenceRecord{}` or `nil`; they must not switch to lists via options.
- Subject-focused write helpers require explicit semantic fields and only auto-fill mechanical defaults.

## Shared Patterns

### Closed subject boundary
**Source:** [lib/threadline/evidence/subject.ex](/Users/jon/projects/threadline/lib/threadline/evidence/subject.ex:10)  
**Apply to:** all public write helpers

```elixir
@supported_subjects [
  "redaction_policy",
  "trigger_coverage",
  "retention_run",
  "retention_policy",
  "export_delivery",
  "support_scope_posture"
]
```

```elixir
@spec validate(subject_descriptor()) :: :ok | {:error, {:unsupported_subject, term()}}
def validate(subject) do
  case normalize(subject) do
    value when value in @supported_subjects -> :ok
    value -> {:error, {:unsupported_subject, value}}
  end
end
```

### Fail-loud helper validation
**Source:** [lib/threadline/health/policy.ex](/Users/jon/projects/threadline/lib/threadline/health/policy.ex:44), [lib/threadline/investigation.ex](/Users/jon/projects/threadline/lib/threadline/investigation.ex:183)  
**Apply to:** evidence filter helpers and provenance/input normalization helpers

```elixir
defp validate_known_keys!(opts) do
  unknown = Map.keys(opts) -- @known_keys

  if unknown != [] do
    raise ArgumentError,
          "Threadline.Health.Policy: unknown config key(s): #{inspect(unknown)}. " <>
            "Known keys: #{inspect(@known_keys)}."
  end
end
```

```elixir
defp validate_helper_filters!(filters, allowed_keys, helper_name) when is_list(filters) do
  Enum.each(filters, fn {key, _value} ->
    if key not in allowed_keys do
      allowed = Enum.map_join(allowed_keys, ", ", &inspect/1)

      raise ArgumentError,
            "unknown #{helper_name} filter key #{inspect(key)}. Allowed: #{allowed}"
    end
  end)

  filters
end
```

### Machine-readable record envelope
**Source:** [lib/threadline/export.ex](/Users/jon/projects/threadline/lib/threadline/export.ex:127)  
**Apply to:** provenance conventions and any public evidence serialization

```elixir
doc = %{
  "format_version" => 1,
  "generated_at" => generated_at_iso(),
  "changes" => changes
}
```

Planner implication:

- Favor string-keyed, machine-readable envelopes.
- Version explicit wire/data shapes.
- Prefer narrow stable keys like `"writer"` / `"entrypoint"` in `provenance` over ad hoc nested blobs.

### Mechanical defaults, explicit meaning
**Source:** [lib/threadline/retention.ex](/Users/jon/projects/threadline/lib/threadline/retention.ex:78), [lib/threadline.ex](/Users/jon/projects/threadline/lib/threadline.ex:44)  
**Apply to:** evidence write helpers

```elixir
run_record =
  repo.insert!(
    RetentionRun.changeset(%RetentionRun{}, %{
      status: "running",
      started_at: started_at
    })
  )
```

```elixir
with :ok <- validate_repo(repo),
     {:ok, validated_ref} <- validate_actor(actor_ref) do
  attrs = build_attrs(name, validated_ref, opts)
  changeset = AuditAction.changeset(attrs)
  repo.insert(changeset)
end
```

Planner implication:

- Auto-fill only mechanical fields such as normalized subject, normalized `subject_ref`, `recorded_at`, `schema_version`, and narrow provenance markers.
- Require callers or subject helpers to provide `summary_status`, `detail`, and any `actor_ref` semantics explicitly.

## Naming And Return-Shape Conventions

- Prefer public context helpers over schema calls.
- Prefer `list_*` for list returns and `get_latest_*` or `latest_*` for singular convenience projections.
- Keep `filters` and `opts` separate when both exist.
- Put paging controls in `opts`, not in `filters`.
- Use `repo:` explicitly; do not discover repo from application env, process state, `Plug.Conn`, socket assigns, ETS, or Logger metadata.
- Return plain structs/maps/lists, not mode-dependent tagged unions for read helpers.
- For write helpers, the repo precedent is `{:ok, struct}` / `{:error, changeset}`.

## Anti-Patterns To Avoid

- Do not add a generic public `record_evidence(attrs, opts)` API that lets callers encode arbitrary governance meaning.
- Do not expose `Threadline.Governance.EvidenceRecord.changeset/2` as the public contract.
- Do not add root-level `Threadline` evidence sprawl in this phase.
- Do not use one option-heavy function that toggles between list, latest, count, or history return shapes.
- Do not derive provenance from ambient runtime state.
- Do not store opaque provenance blobs with mixed atom/string keys when the public shape can be normalized once.
- Do not introduce mutable “current evidence” state; latest must remain a projection over append-only rows.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/evidence.ex` latest-per-subject-ref convenience helpers | service | CRUD | No existing module exposes `latest_*` naming yet; use `history` + `as_of` split from `Threadline.Query` as the closest precedent |

## Metadata

**Analog search scope:** `lib/threadline*.ex`, `lib/threadline/**`  
**Files scanned:** 13  
**Pattern extraction date:** 2026-05-25
