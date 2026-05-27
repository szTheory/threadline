# Phase 95: Evidence Model Lock And Scope Guard - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/governance/evidence_record.ex` | schema | persistence | `lib/threadline/governance/retention_run.ex` | exact |
| `lib/threadline/governance/migration.ex` | migration source | install-time DDL | existing governance table blocks in `migration.ex` | exact |
| `lib/mix/tasks/threadline.install.ex` | generator | install-time file generation | existing governance migration branch | exact |
| `lib/threadline/evidence/subject.ex` | validator / contract registry | boundary validation | `lib/threadline/health/policy.ex` | exact |
| `test/threadline/governance/evidence_record_test.exs` | schema contract test | persistence verification | `test/threadline/retention_test.exs` | partial |
| `test/threadline/evidence/subject_test.exs` | validator contract test | unit | `test/threadline/health/policy_test.exs` | exact |
| `guides/how-threadline-works.md` | boundary doc | public contract | existing "What Threadline is not" section | exact |
| `test/threadline/how_threadline_works_doc_contract_test.exs` | doc-contract test | documentation verification | existing guide heading/value assertions | exact |

## Pattern Assignments

### `lib/threadline/governance/evidence_record.ex`

**Analog:** `lib/threadline/governance/retention_run.ex`

**Schema + changeset pattern:**
```elixir
schema "threadline_retention_runs" do
  field(:status, :string)
  field(:deleted_count, :integer)
  field(:duration_ms, :integer)
  field(:error_message, :string)
  field(:started_at, :utc_datetime_usec)
  field(:completed_at, :utc_datetime_usec)

  timestamps(type: :utc_datetime)
end
```

Apply the same boring Ecto shape: explicit fields, explicit required list,
binary UUID primary key, no hidden macros.

### `lib/threadline/governance/migration.ex`

**Analog:** existing `CREATE TABLE IF NOT EXISTS threadline_retention_runs`
block.

**DDL pattern:**
```elixir
execute \"\"\"
CREATE TABLE IF NOT EXISTS threadline_retention_runs (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  status         text        NOT NULL,
  deleted_count  integer,
  duration_ms    integer,
  error_message  text,
  started_at     timestamptz,
  completed_at   timestamptz,
  inserted_at    timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
)
\"\"\"
```

Phase 95 should add one more governance table block in this style rather than a
new migration-generation subsystem.

### `lib/mix/tasks/threadline.install.ex`

**Analog:** existing `governance_written` branch.

**Pattern:**
```elixir
governance_written =
  if existing_governance_migration?(path) do
    Mix.shell().info("Threadline governance schema migration already exists — skipping.")
    false
  else
    file = Path.join(path, "#{timestamp()}_threadline_governance_schema.exs")
    create_file(file, Threadline.Governance.Migration.migration_content())
    true
  end
```

Phase 95 should preserve this one-shot installer story while extending the
governance migration content.

### `lib/threadline/evidence/subject.ex`

**Analog:** `lib/threadline/health/policy.ex`

**Strict validator pattern:**
```elixir
def validate!(opts) when is_list(opts) do
  if Keyword.keyword?(opts) do
    validate!(Map.new(opts))
  else
    raise ArgumentError,
          "Threadline.Health.Policy: expected a keyword list or map, got: #{inspect(opts)}"
  end
end
```

Phase 95 should mirror this approach with a closed subject inventory and
explicit unsupported-subject errors rather than accepting free-form inputs.

### `test/threadline/governance/evidence_record_test.exs`

**Analog:** `test/threadline/retention_test.exs`

**Pattern to reuse:**
- insert durable governance rows through a changeset
- assert required fields and persisted timestamps
- prove behavior on repeated inserts rather than updates

### `guides/how-threadline-works.md`

**Analog:** existing "The Line of Diminishing Returns" section.

**Boundary-language pattern:**
- state what Threadline is
- state what Threadline is not
- keep host-owned auth/RBAC out of library-owned scope

Phase 95 should add the evidence-plane non-goal language to that existing
boundary surface instead of inventing a new standalone doc.

## Shared Patterns

### Machine-readable posture vocabulary

**Source:** `Threadline.Policy.RedactionPresenter` and its tests

Use stable enum-like strings and fixed top-level keys. Later phases will need
the same discipline for evidence JSON/output parity.

### Governance-first persistence

**Source:** `RetentionRun` plus `Retention.purge/1`

Persist governance facts in dedicated tables and let later services/UI read
them. Do not hide the contract inside mounted-surface state.

## Metadata

**Analog search scope:** `lib/threadline/governance/*`, `lib/threadline/health/policy.ex`, `test/threadline/*doc_contract*`, `test/threadline/retention_test.exs`
**Pattern extraction date:** 2026-05-25
