# Phase 97: Mix-Task And Machine-Readable Proof - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/threadline.evidence.show.ex` | mix task | CLI -> context -> render | `lib/mix/tasks/threadline.policy.show.ex` | strong |
| `lib/threadline/evidence/proof.ex` | serializer / presenter | context -> transform -> JSON/human | `lib/threadline/export.ex` | role-match |
| `lib/threadline/evidence.ex` | public read boundary | query -> transform | `lib/threadline/evidence.ex` | exact |
| `test/mix/tasks/threadline.evidence_show_test.exs` | task test | CLI -> output | `test/mix/tasks/threadline.export_test.exs` | strong |
| `test/threadline/evidence/proof_test.exs` | serializer integration test | transform | `test/threadline/export_test.exs` | strong |
| `test/threadline/evidence_test.exs` | public API integration | CRUD | `test/threadline/evidence_test.exs` | exact |
| `.planning/phases/97-mix-task-and-machine-readable-proof/97-RESEARCH.md` | research artifact | transform | `.planning/phases/96-evidence-persistence-and-public-api/96-RESEARCH.md` | role-match |
| `.planning/phases/97-mix-task-and-machine-readable-proof/97-VALIDATION.md` | validation artifact | transform | `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` | role-match |
| `.planning/ROADMAP.md` | planning authority | transform | `.planning/ROADMAP.md` current phase slot pattern | exact |
| `.planning/REQUIREMENTS.md` | planning authority | transform | `.planning/REQUIREMENTS.md` traceability blocks | exact |
| `guides/domain-reference.md` | guide / contract | transform | `guides/domain-reference.md` export JSON contract section | exact |
| `lib/mix/tasks/threadline.export.ex` | wrapped JSON precedent | CLI -> serializer | `lib/mix/tasks/threadline.export.ex` | exact |
| `lib/mix/tasks/threadline.incident.ex` | narrow viewer precedent | CLI -> one resource | `lib/mix/tasks/threadline.incident.ex` | strong |

## Pattern Assignments

### `lib/mix/tasks/threadline.evidence.show.ex` (mix task, CLI -> context -> render)

**Analog:** `lib/mix/tasks/threadline.policy.show.ex`

Use the same viewer bootstrap shape: parse bounded flags, run `app.config`,
start `:ssl`, `:postgrex`, and `:ecto_sql`, resolve the configured repo, then
delegate to one library surface for the actual proof payload.

**Bootstrap pattern** (`lib/mix/tasks/threadline.policy.show.ex:20-39`):
```elixir
{opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean])
json? = Keyword.get(opts, :json, false)

Mix.Task.run("app.config", [])
{:ok, _} = Application.ensure_all_started(:ssl)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

repo = resolve_repo!()
ensure_repo_started!(repo)
```

**Viewer-not-gate posture** (`lib/mix/tasks/threadline.health.coverage.ex:52-58`):
```elixir
if json? do
  render_json(schema, coverage)
else
  render_table(schema, coverage)
end

:ok
```

Follow that posture for evidence proof runs: valid unsupported/provisional
payloads should still return `:ok`.

### `lib/threadline/evidence/proof.ex` (serializer / presenter, context -> transform)

**Analog:** `lib/threadline/export.ex`

Use a reusable builder module that produces one wrapped JSON document and a
parallel human-readable projection, rather than encoding JSON directly inside
the Mix task.

**Wrapped JSON precedent** (`lib/threadline/export.ex` / tests):
```elixir
%{
  "format_version" => 1,
  "generated_at" => generated_at,
  "changes" => ...
}
```

Phase 97 should keep the same additive wrapper discipline, but replace
`changes` with the locked proof fields:
`proof_type`, `subject`, `mode`, `filters`, `summary`, `claim_assessment`, and
`records`.

### `test/mix/tasks/threadline.evidence_show_test.exs` (task test, CLI -> output)

**Analog:** `test/mix/tasks/threadline.export_test.exs`

Reuse `ExUnit.CaptureIO` for CLI assertions, reenable the Mix task between
tests, and assert output bytes or decoded JSON rather than shell prose alone.

**Task-test shape** (`test/mix/tasks/threadline.export_test.exs` pattern):
```elixir
setup do
  Mix.Task.reenable("threadline.export")
  :ok
end

test "..." do
  output =
    capture_io(fn ->
      Mix.Tasks.Threadline.Export.run([...])
    end)

  ...
end
```

### `test/threadline/evidence/proof_test.exs` (serializer integration, transform)

**Analog:** `test/threadline/export_test.exs`

Seed deterministic evidence rows with fixed timestamps and subject refs, then
decode the JSON output and assert exact top-level keys and verdict values.

**Stable JSON assertion pattern** (`test/threadline/export_test.exs:148-171`):
```elixir
doc = Jason.decode!(IO.iodata_to_binary(data))
assert doc["format_version"] == 1
assert is_binary(doc["generated_at"])
```

Add the same style of assertions for `proof_type`, `mode`, `claim_assessment`,
and `records`.

### `lib/threadline/evidence.ex` (public read boundary, query -> transform)

**Analog:** itself plus planned Phase 97 read reuse

Treat this as the only query surface Phase 97 may consume. New proof work
should call the existing helpers instead of adding task-local SQL or ad-hoc
record reducers.

**Relevant seam** (`lib/threadline/evidence.ex`):
```elixir
def list_history(filters, opts \\ []) when is_list(filters) and is_list(opts)
def list_subject_ref_history(subject, subject_ref, filters, opts)
def list_latest_subject_refs(subject, filters, opts)
def get_latest_subject_ref(subject, subject_ref, opts)
```

## Implementation Notes

- Prefer one new library seam under `Threadline.Evidence.*` for proof shaping
  instead of pushing serialization logic into the Mix task.
- Keep task flags bounded and validated at the edge, following existing viewer
  tasks.
- Reuse the export module’s wrapped JSON discipline, but not its domain
  payload.
- Keep docs/tests aligned by treating top-level JSON keys and verdict enums as
  contract-level values, not incidental implementation details.
