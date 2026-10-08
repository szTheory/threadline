# Phase 236: Support Floor and Partition Weights - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 7 planned change targets (including generated weights)  
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` | config | request-response (CI job execution) | `.github/workflows/ci.yml` existing `verify-test` matrix | exact |
| `test/threadline/ci_topology_contract_test.exs` | test | transform (workflow/source checks and mutation controls) | same file, `partition_topology_errors/3` and its controls | exact |
| `test/threadline/guides/upgrade_path_contract_test.exs` (recommended new file) | test | transform (source metadata to documentation contract) | `test/threadline/ci_coverage_doc_contract_test.exs` | role-match |
| `guides/upgrade-path.md` | config/documentation | transform (support metadata to adopter-facing table) | `guides/upgrade-path.md` existing compatibility matrix | exact |
| `CHANGELOG.md` | config/documentation | transform (change record to release notes) | same file, Unreleased breaking changes | exact |
| `test/threadline/ci_topology_contract_test.exs` (weights completeness contract) | test | transform (test inventory vs measured entries) | same file, `partition_topology_errors/3` plus mutation controls | role-match |
| `test/partition_weights.txt` | config/data | batch (per-file timing weights consumed by partition runner) | same file's existing sorted measurement format | exact |

The recommended focused upgrade-path contract is named in RESEARCH.md but does not yet exist. The roadmap allows it to live alongside the topology test; whichever placement is selected should follow the same ExUnit source-read conventions below. No changes to `mix.exs` are proposed by research: its declared Elixir floor remains authoritative, while its PostgreSQL support comment should be updated only if the plan explicitly includes it.

## Pattern Assignments

### `.github/workflows/ci.yml` (`verify-test` matrix)

**Analog:** `.github/workflows/ci.yml` (tracked)

The existing matrix already distinguishes the minimum, current, and latest lanes. Preserve the job identity and matrix shape; the requirement changes only the min lane's PostgreSQL image. The downstream test step already runs the partitioned full suite for every lane.

**Matrix pattern** (lines 600-616):

```yaml
      matrix:
        lane: [min, current, latest]
        include:
          - lane: min
            elixir: "1.15.8"
            otp: "26.2.5.21"
            pg: "14"
            runner: "ubuntu-24.04"
          - lane: current
            version-file: ".tool-versions"
            pg: "16"
            runner: "ubuntu-24.04"
          - lane: latest
            elixir: "1.20.4"
            otp: "29.1.1"
            pg: "18.6"
            runner: "ubuntu-24.04"
```

Change the `min` row database value to `"15"`. Keep `verify-test` (job ID) and its test steps intact; AGENTS.md requires stable job IDs and full-suite proof on the minimum lane.

### `test/threadline/ci_topology_contract_test.exs` (minimum PG assertion and weight inventory)

**Analog:** `test/threadline/ci_topology_contract_test.exs`

This contract reads repository inputs through a private helper and verifies topology with focused assertions. The existing partition contract also has a pure helper returning error strings and checks mutation variants against it. Extend this file for the minimum PG value, and either place weight completeness here or extract a distinct focused test if that keeps the checks clearer.

**Input-reading pattern** (lines 5, 15-17, 336-341):

```elixir
  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "verify-test runs the suite in fail-closed partitions after compile (SUITE-02)" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    mix_exs = read_rel!(["mix.exs"])
    script = read_rel!(["bin", "ci-test-partitions"])

    assert partition_topology_errors(yaml, mix_exs, script) == []
```

**Pure contract and mutation-control pattern** (lines 269-334, 343-451):

```elixir
  defp partition_topology_errors(yaml, mix_exs, script) do
    job = workflow_job(yaml, "verify-test")
    run_tests_step = workflow_step(job, "Run tests")

    [
      {run_tests_step =~ ~r/^        run: mix verify\.test_partitioned\s*$/m,
       "Run tests must run exactly `mix verify.test_partitioned`"},
      {String.contains?(script, "WEIGHTS_REL=\"test/partition_weights.txt\"") and
         File.exists?(Path.join(@repo_root, "test/partition_weights.txt")),
       "bin/ci-test-partitions must read the committed test/partition_weights.txt"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  for {label, y, mexs, s} <- mutation_controls do
    refute {y, mexs, s} == {yaml, mix_exs, script}, "#{label} control did not change the input"
    assert partition_topology_errors(y, mexs, s) != [], "#{label} mutation must make the contract fail"
  end
```

For the PG floor, parse/select the `lane: min` include row and assert `pg: "15"`; mutate the min value to prove the contract fails. For CI-01, enumerate all `test/**/*_test.exs` paths and compare with parsed non-comment weight paths. Include a deliberately omitted weight in the test input to prove missing coverage is rejected. Keep paths relative to repository root and avoid treating runner assignment coverage as measured-weight coverage.

### `test/threadline/guides/upgrade_path_contract_test.exs` (new support-policy doc contract)

**Analog:** `test/threadline/ci_coverage_doc_contract_test.exs`

The CI coverage contract is the closest analog because it compares a human-facing Markdown table against executable configuration and treats empty scans as failures. A focused new contract was recommended by research; no analog file currently uses that exact name.

**Root/path and table-row extraction pattern** (`ci_coverage_doc_contract_test.exs`, lines 31-39, 53-74):

```elixir
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @coverage_heading "## CI Coverage"

  defp row(section, project) do
    case Regex.run(~r/^\|\s*`#{Regex.escape(project)}`\s*\|.*$/m, section) do
      [row] -> row
      nil -> flunk("CONTRIBUTING.md `#{@coverage_heading}` has no table row for `#{project}`")
    end
  end
```

**Non-vacuous drift assertion pattern** (lines 76-102):

```elixir
  test "the derive source finds Playwright projects at all" do
    projects = projects_in_workflows()
    assert projects != [], "derive source returned no projects; the table contract would pass vacuously"
  end

  test "every default-config project appears in the CI Coverage table" do
    section = coverage_section()
    for project <- projects_in_workflows() do
      row_regex = ~r/^\|\s*`#{Regex.escape(project)}`\s*\|/m
      assert Regex.match?(row_regex, section)
    end
  end
```

Adapt this to read `guides/upgrade-path.md`, `mix.exs`, and `.github/workflows/ci.yml`; assert the support table exists, and compare its Elixir/OTP/PG minimum and lane values to the parsed source values. A literal target assertion alone does not detect drift from the sources. `test/threadline/version_truth_doc_contract_test.exs` lines 143-156 is also a concise same-guide assertion style, but it checks upgrade-version text rather than a table.

### `guides/upgrade-path.md` (support-policy table)

**Analog:** `guides/upgrade-path.md` (tracked)

The guide already has a Markdown compatibility table and explains that support claims come from in-repo proof.

**Table introduction and row pattern** (lines 50-64):

```markdown
## Supported compatibility matrix

Support claims in this table come from current in-repo proof only:

1. declared optional dependency ranges in `mix.exs`
2. current lock resolution in `mix.lock`
3. current CI coverage in `.github/workflows/ci.yml`

| Lane | Claim type | Declared support | Current tested resolution | Proof / CI coverage |
| --- | --- | --- | --- | --- |
| `capture-only` | `supported` | ... | ... | ... |
```

Add one unambiguous toolchain support-policy table that identifies the supported Elixir/OTP/PostgreSQL floor and the min/current/latest CI lanes. Label current/latest as tested-on evidence where they do not declare support.

### `CHANGELOG.md` (Unreleased breaking change)

**Analog:** `CHANGELOG.md` (tracked)

The Unreleased section is human-owned and separates breaking changes from highlights.

**Breaking entry pattern** (lines 20-48):

```markdown
## Unreleased — highlights

### Breaking changes

- `Threadline.Job.context_opts/2` now rejects unsupported `extra` keys and
  malformed context IDs with `ArgumentError`; integer IDs are converted to
  strings. Required action: remove unsupported extras and provide supported IDs.
```

Add the PostgreSQL 15 minimum change under this Unreleased breaking-changes heading and state the adopter action clearly. Phase 237 will later assemble the final 1.0.0 changelog.

### `test/partition_weights.txt` (regenerated measurements)

**Analog:** `test/partition_weights.txt` (tracked)

This is generated sorted data, not hand-maintained logic. Preserve its comment header and `<milliseconds> <test/path_test.exs>` row format. The authoritative producer is `bin/ci-test-partitions --write-weights` (tracked); its `write_weights/0` writes a temporary file, checks a nonempty measurement set, and atomically replaces the destination (lines 480-528). Regenerate after phase test churn so the focused doc contract added in this phase also receives a measured entry.

## Shared Patterns

### Source-derived support claims

**Sources:** `mix.exs` lines 39-46; `.github/workflows/ci.yml` lines 600-616; `guides/upgrade-path.md` lines 50-64. Keep declared package support, CI evidence, and adopter wording aligned. Existing project policy expects documentation contracts to pin that alignment.

### Contract-test failure controls

**Source:** `test/threadline/ci_topology_contract_test.exs` lines 269-334 and 343-451; `test/threadline/ci_coverage_doc_contract_test.exs` lines 76-102. Express checks as focused assertions over input text, make source scans non-vacuous, and mutate the source or fixture to show the regression is caught.

### Weight generation and completeness

**Sources:** `bin/ci-test-partitions` lines 18-30, 354-367, 480-528; `test/partition_weights.txt`. The runner intentionally gives unweighted files a median fallback and separately enforces exactly-once execution. The new permanent contract must prove measurement completeness by comparing the enumerated inventory to committed paths; keep those guarantees distinct.

## No Analog Found

None. The focused support-table test does not yet exist, but `ci_coverage_doc_contract_test.exs` is a strong same-role table contract analog.

## Metadata

**Analog search scope:** `.github/workflows`, `test/threadline`, `test`, `guides`, root `mix.exs`, `CHANGELOG.md`, and `bin/ci-test-partitions`.  
**Tracked-source gate:** All named source analogs were confirmed with `git ls-files`; no runtime mirrors are referenced.  
**Pattern extraction date:** 2026-10-07
