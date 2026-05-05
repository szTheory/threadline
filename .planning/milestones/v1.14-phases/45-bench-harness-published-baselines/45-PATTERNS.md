# Phase 45: Bench Harness & Published Baselines - Pattern Map

**Mapped:** 2024
**Files analyzed:** 5
**Analogs found:** 4 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | configuration | `mix.exs` | exact |
| `test/threadline/performance_doc_contract_test.exs` | test | assertion | `test/threadline/audit_indexing_doc_contract_test.exs` | exact |
| `scripts/seed_audit_changes.exs` | utility | batch/CRUD | `priv/ci/topology_bootstrap.exs` | role-match |
| `guides/performance.md` | config | docs | `guides/audit-indexing.md` | exact |
| `bench/` (various harness scripts) | utility | batch/runner | none | N/A |

## Pattern Assignments

### `mix.exs` (config, configuration)

**Analog:** `mix.exs`

**Alias Pattern** (lines 61-75):
Adding a new `verify.bench` alias and ensuring it hooks into CI (or stays distinct if it's too slow for general CI). Existing pattern:
```elixir
  defp aliases do
    [
      "verify.format": ["format --check-formatted"],
      "verify.credo": ["credo --strict"],
      "verify.test": ["test"],
      "verify.threadline": ["threadline.verify_coverage"],
      "verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
      "verify.topology": ["threadline.verify_topology"],
      "verify.example": &verify_example/1,
      "verify.bench": ["run bench/run_benchmarks.exs"], # Example of new addition
      "ci.all": [
        # ...
        "verify.doc_contract"
      ]
    ]
  end
```

**Hex Release Exclusion Pattern** (lines 92-100):
Excluding the `bench/` and `scripts/` directories from the Hex tarball package.
```elixir
  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/#{doc_source_ref()}/CHANGELOG.md"
      },
      # Explicitly only include necessary production files
      files: ~w(lib guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
    ]
  end
```

**ExDoc Extras Pattern** (lines 102-120):
Registering the new guide.
```elixir
  defp docs do
    [
      # ...
      extras: [
        "README.md",
        "guides/domain-reference.md",
        "guides/production-checklist.md",
        "guides/audit-indexing.md",
        "guides/performance.md", # New addition
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Overview: ~r/README/,
        Reference: ~r{^guides/},
        Project: ~r/(CONTRIBUTING|CHANGELOG)/
      ],
      # ...
    ]
  end
```

---

### `test/threadline/performance_doc_contract_test.exs` (test, assertion)

**Analog:** `test/threadline/audit_indexing_doc_contract_test.exs`

**Doc Contract Assertion Pattern** (lines 1-29):
Read the target markdown file and assert critical headings, markers (like `PERF-01`), and literals.
```elixir
defmodule Threadline.PerformanceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "performance guide retains PERF marker and operator spine" do
    doc = read_rel!(["guides", "performance.md"])

    # Enforce performance presets exist in text
    assert String.contains?(doc, "PERF-01")
    assert String.contains?(doc, "PERF-02")
    assert String.contains?(doc, "PERF-03")

    for heading <- [
          "## Workload Presets",
          "## Throughput Baselines",
          "## Impact on Primary Transactions"
        ] do
      assert String.contains?(doc, heading)
    end
  end
end
```

---

### `scripts/seed_audit_changes.exs` (utility, batch/CRUD)

**Analog:** `priv/ci/topology_bootstrap.exs`

**Script Bootstrapping Pattern** (lines 1-23):
Standalone scripts that require Ecto/Postgres need to explicitly start applications and repos.
```elixir
# Run with: MIX_ENV=test mix run scripts/seed_audit_changes.exs

unless Mix.env() == :test do
  IO.puts(:stderr, "Use MIX_ENV=test")
  System.halt(1)
end

{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

# Start your target Repo
{:ok, pid} = Threadline.Test.Repo.start_link()

try do
  # Perform heavy database inserts / seeding for the benchmark
  # Ecto.Multi or chunked Repo.insert_all
  
  IO.puts("Threadline: benchmark seeding complete")
after
  GenServer.stop(pid, :normal, :infinity)
end
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `bench/*` | utility | batch | No existing Benchee or custom benchmark harness scripts currently exist in the codebase. Will rely on standard Benchee structure or custom timing modules as outlined in research/requirements. |

## Metadata

**Analog search scope:** `test/**/*_doc_contract_test.exs`, `priv/**/*.exs`, `mix.exs`
**Files scanned:** 15
**Pattern extraction date:** 2024-06-03
