# Phase 47: saas-adopter-onramp - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/getting-started-saas.md` | config | request-response | `examples/threadline_phoenix/README.md` | partial |
| `guides/adoption-pilot-backlog.md` | config | transform | `guides/adoption-pilot-backlog.md` | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | transform | `test/threadline/stg_doc_contract_test.exs` | role-match |
| `test/support/getting_started_fixtures.ex` | utility | file-I/O | `test/support/readme_quickstart_fixtures.ex` | role-match |
| `examples/threadline_phoenix/` source marker edits | utility | file-I/O | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` and `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` | exact |
| `mix.exs` ExDoc extras changes if needed | config | transform | `mix.exs` | exact |

## Pattern Assignments

### `guides/getting-started-saas.md` (config, request-response)

**Primary analog:** `examples/threadline_phoenix/README.md`

**Stepwise quickstart structure** (`examples/threadline_phoenix/README.md:32-61`):
```markdown
## Installation (Threadline capture + first audited table)

1. Install Hex deps and compile:

   ```bash
   mix deps.get
   mix compile
   ```

...

4. Generate and apply Threadline base schema migrations, then add triggers for the reference `posts` table, then migrate:

   ```bash
   mix threadline.install
   mix threadline.gen.triggers --tables posts
   mix ecto.migrate
   ```
```

**Run + first audited write narration** (`examples/threadline_phoenix/README.md:73-91`):
```markdown
## Run the API

After migrations succeed:

```bash
mix phx.server
```

...

## Audited HTTP path (`POST /api/posts`)

The example wires **`ThreadlinePhoenixWeb.SigraContextPlug`** and **`Threadline.Plug`** on the `:api` pipeline ...
```

**Historical read patterns for steps 7-8** (`examples/threadline_phoenix/README.md:99-147`):
```elixir
case Threadline.as_of(ThreadlinePhoenix.Post, post_id, as_of: as_of_at, repo: ThreadlinePhoenix.Repo) do
  {:ok, post} -> post
  {:error, :deleted_record} -> :deleted
  {:error, :before_audit_horizon} -> :no_history_yet
end

filters = [
  table: "posts",
  correlation_id: "demo-corr",
  repo: ThreadlinePhoenix.Repo
]
```

**Closing pointer block style** (`examples/threadline_phoenix/README.md:155-160`):
```markdown
## Documentation & production adoption

- **[Production checklist](../../guides/production-checklist.md)** ...
- **[Adoption pilot / STG backlog](../../guides/adoption-pilot-backlog.md)** ...
```

**Source-backed code block inputs to extract into the guide:**
- Router pipeline: `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4-8`
- Transaction flow: `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:32-75`
- Optional actor callback snippet: `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1-5`

### `guides/adoption-pilot-backlog.md` modifications (config, transform)

**Primary analog:** existing `guides/adoption-pilot-backlog.md`

**Insert location and rubric context** (`guides/adoption-pilot-backlog.md:29-47`):
```markdown
## STG audited write paths (STG-02)

STG-AUDITED-PATH-RUBRIC

Use this matrix for **HTTP handlers** and **Oban (or other job) paths** ...

- **OK** requires a **reproducible pointer**: Mix/CI command, test path, PR, doc path, or scripted steps ...
```

**Existing evidence-pointer vocabulary** (`guides/adoption-pilot-backlog.md:47-51`):
```markdown
**CI-PGBOUNCER-TOPOLOGY-CONTRACT:** GitHub Actions job **`verify-pgbouncer-topology`** runs ...

| Question | Answer | Matches prod? |
|----------|--------|----------------|
| App → pooler → Postgres? | **CI:** `verify-test` / `mix ci.all` use **direct** Postgres; **`verify-pgbouncer-topology`** adds ...
```

**Status-table style to mirror for walked example rows** (`guides/adoption-pilot-backlog.md:57-119`):
```markdown
### 1. Capture and triggers

| Checklist item (summary) | Status | Evidence |
|--------------------------|--------|----------|
| `verify_coverage` + `expected_tables` in CI / prod-like | OK | ... |
```

**Marker/comment precedent for invisible contract anchors:** use HTML comments like `<!-- PERF-01 -->` and `<!-- LIVE-JOIN-WARNING -->` from `guides/performance.md` and `guides/incident-playbook.md`; the new disclaimer should follow that style.

### `test/threadline/getting_started_saas_doc_contract_test.exs` (test, transform)

**Primary analog:** `test/threadline/stg_doc_contract_test.exs`

**Pure file-read helper pattern** (`test/threadline/stg_doc_contract_test.exs:1-9`):
```elixir
defmodule Threadline.StgDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end
end
```

**Literal-lock assertion style** (`test/threadline/stg_doc_contract_test.exs:11-26`):
```elixir
test "adoption pilot backlog retains STG template and rubric markers" do
  doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
  assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
  assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
end
```

**Looped heading assertions** (`test/threadline/performance_doc_contract_test.exs:20-30`):
```elixir
for heading <- [
      "## Workload Presets",
      "## Throughput Baselines",
      ...
    ] do
  assert String.contains?(doc, heading)
end
```

**More structural assertion precedent** (`test/threadline/incident_playbook_doc_contract_test.exs:40-64`):
```elixir
Enum.each(scenarios, fn scenario ->
  header = "## Scenario: " <> scenario
  assert String.contains?(content, header)
  ...
end)
```

**Planner guidance:** base the new test on the `StgDocContractTest` helper shape, add a loop for the eight headings like `PerformanceDocContractTest`, and call the new fixture with `String.contains?(guide_md, extracted_block)` for each marker-backed anchor.

### `test/support/getting_started_fixtures.ex` (utility, file-I/O)

**Primary analog:** `test/support/readme_quickstart_fixtures.ex`

**Module placement + lightweight helper style** (`test/support/readme_quickstart_fixtures.ex:23-50`):
```elixir
defmodule Threadline.ReadmeQuickstartFixtures do
  @moduledoc """
  Compile-checked mirrors of README Quick Start paths (TOOL-03).
  """

  alias Threadline.Semantics.ActorRef

  def trigger_coverage_call do
    Threadline.Health.trigger_coverage(repo: Threadline.Test.Repo)
  end
end
```

**Test-support load path source of truth** (`mix.exs:44-45`):
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

**Planner guidance:** keep the new module as a small plain helper in `test/support`, with a public `extract!/2` API and descriptive `raise` on missing markers; no DB, no `DataCase`, no compile-time mirrors beyond the extraction helper itself.

### `examples/threadline_phoenix` source marker edits (utility, file-I/O)

**Primary analogs:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`, `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex`

**Router anchor candidate** (`examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4-8`):
```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug(ThreadlinePhoenixWeb.SigraContextPlug)
  plug(Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1)
end
```

**Transaction anchor candidate** (`examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:32-75`):
```elixir
Repo.transaction(fn ->
  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])

  case Repo.insert(Post.changeset(%Post{}, attrs)) do
    {:error, changeset} ->
      Repo.rollback(changeset)

    {:ok, post} ->
      opts = [
        repo: Repo,
        actor: actor_ref,
        correlation_id: audit_context.correlation_id,
        request_id: audit_context.request_id
      ]

      case Threadline.record_action(:post_created_via_api, opts) do
        ...
      end
  end
end)
```

**Optional callback anchor candidate** (`examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1-5`):
```elixir
defmodule ThreadlinePhoenix.AuditActor do
  @moduledoc false

  defdelegate from_conn(conn), to: Threadline.Integrations.Sigra, as: :actor_ref_from_conn
end
```

**Evidence pointers that the walked-example matrix can cite after edits land:**
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:9-43`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs:6-37`

### `mix.exs` ExDoc extras changes if needed (config, transform)

**Primary analog:** root `mix.exs`

**Existing docs extras list** (`mix.exs:121-142`):
```elixir
defp docs do
  [
    main: "Threadline",
    source_ref: doc_source_ref(),
    source_url: @source_url,
    extras: [
      "README.md",
      "guides/performance.md",
      "guides/domain-reference.md",
      "guides/brownfield-continuity.md",
      "guides/production-checklist.md",
      "guides/adoption-pilot-backlog.md",
      "guides/audit-indexing.md",
      "guides/integrations/sigra.md",
      "CONTRIBUTING.md",
      "CHANGELOG.md"
    ],
    groups_for_extras: [
      Overview: ~r/README/,
      Reference: ~r{^guides/},
      Project: ~r/(CONTRIBUTING|CHANGELOG)/
    ],
```

**Pattern assignment:** add `guides/getting-started-saas.md` in the existing `extras:` list only. Do not reorganize groups in Phase 47; Phase 47 context explicitly defers broader ExDoc ordering to Phase 48.

## Shared Patterns

### Pure file-read doc-contract tests
**Sources:** `test/threadline/stg_doc_contract_test.exs:1-26`, `test/threadline/performance_doc_contract_test.exs:1-31`

Apply to all new Phase 47 tests:
```elixir
use ExUnit.Case, async: true

@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

### Invisible markdown contract markers
**Sources:** `guides/performance.md` via `test/threadline/performance_doc_contract_test.exs:11-18`, `guides/incident-playbook.md` via `test/threadline/incident_playbook_doc_contract_test.exs:24-37`

Apply to the new disclaimer banner and any future drift sentinels:
```elixir
assert String.contains?(doc, "<!-- PERF-01 -->")
assert content =~ "<!-- LIVE-JOIN-WARNING -->"
```

### Example-app-as-source-of-truth
**Sources:** `examples/threadline_phoenix/README.md:87-91`, `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4-8`, `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:32-75`

Apply to `guides/getting-started-saas.md`: prose can be editorial, but copy-paste Elixir blocks should be extracted from example app source rather than rewritten in the guide.

### In-repo evidence-pointer discipline
**Sources:** `guides/adoption-pilot-backlog.md:43-51`, `guides/adoption-pilot-backlog.md:61-119`

Apply to the walked STG example: evidence cells should point at CI jobs, test paths, or mix commands in repo language, not prose-only claims or third-party URLs.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `guides/getting-started-saas.md` | config | request-response | No existing top-level guide combines eight-step onboarding with marker-extracted source blocks; closest content analog is the example app README, while closest test analog is the doc-contract suite. |

## Metadata

**Analog search scope:** `guides/`, `test/threadline/`, `test/support/`, `examples/threadline_phoenix/`, root `mix.exs`
**Files scanned:** 14
**Pattern extraction date:** 2026-05-05
