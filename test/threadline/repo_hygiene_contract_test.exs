defmodule Threadline.RepoHygieneContractTest do
  @moduledoc """
  Wiring contract for the HYG-02 tracked-text local-path guard: the
  `verify-repo-hygiene` CI job must exist, run both `bin/verify-repo-hygiene`
  and `bin/verify-repo-hygiene --self-test`, carry no `if:`/
  `continue-on-error`/`services:`/`actions/cache`/`setup-beam`, be listed in
  the job-id header and in `ci-required`'s `needs:`, never appear in an
  `allowed-skips`/`allowed-failures` list, be mirrored in `ci.all` (after
  `verify.deps_audit` and before the strict compile step) and in
  CONTRIBUTING.md's roster, and no workflow file may ever reference
  `REPO_HYGIENE_` (the guard's own test-only env seam), which would let a
  workflow edit redirect or narrow the scan without touching the gate script
  itself.

  Local private helpers only — deliberately does not import from other test
  modules, per the same-commit roster rule's isolation convention.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @job_id "verify-repo-hygiene"

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  # Splits ci.yml on "\n  <id>:\n" and cuts the block at the next top-level
  # job key (two-space-indented `key:` line), or end of file.
  defp job_block(yaml, id) do
    case String.split(yaml, "\n  #{id}:\n", parts: 2) do
      [_, tail] ->
        case Regex.split(~r/\n  [a-z0-9-]+:\n/, tail, parts: 2) do
          [body | _] -> body
          [] -> tail
        end

      _ ->
        nil
    end
  end

  defp ci_required_needs(yaml) do
    case Regex.run(~r/\n  ci-required:\n[\s\S]*?    needs:\n((?:      - .+\n)+)/, yaml) do
      [_, items] ->
        items
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end

  defp ci_all_entries(mix_exs) do
    case Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs) do
      [_, block] -> Regex.scan(~r/"([^"]+)"/, block) |> Enum.map(&List.last/1)
      nil -> []
    end
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  defp allowed_skip_or_failure_items(yaml) do
    yaml
    |> strip_comment_lines()
    |> then(&Regex.scan(~r/^\s*allowed-(?:skips|failures):\s*\n((?:\s*- .+\n)*)/m, &1))
    |> Enum.flat_map(fn [_, items] -> String.split(items, "\n", trim: true) end)
    |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))
  end

  defp workflow_files do
    files = Path.wildcard(Path.join(@repo_root, ".github/workflows/*.{yml,yaml}"))

    case files do
      [] -> flunk("no .github/workflows/*.{yml,yaml} files found — the scan cannot be vacuous")
      list -> list
    end
  end

  # The env-var test seam a workflow edit could otherwise abuse to redirect or
  # narrow the scan without touching bin/verify-repo-hygiene itself.
  defp forbidden_hygiene_surface(text) do
    ~r/REPO_HYGIENE_/
    |> Regex.scan(text)
    |> List.flatten()
    |> Enum.uniq()
  end

  test "forbidden_hygiene_surface/1 is non-vacuous: finds the token in a synthetic positive, nothing in a benign snippet" do
    positive = """
    jobs:
      verify-repo-hygiene:
        env:
          REPO_HYGIENE_ROOT: /tmp/x
          REPO_HYGIENE_ALLOWLIST: /tmp/y
    """

    assert forbidden_hygiene_surface(positive) == ["REPO_HYGIENE_"]

    benign = """
    jobs:
      verify-repo-hygiene:
        steps:
          - run: bin/verify-repo-hygiene
          - run: bin/verify-repo-hygiene --self-test
    """

    assert forbidden_hygiene_surface(benign) == []
  end

  test "verify-repo-hygiene job exists, runs both required commands, and carries no weakening" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    job = job_block(yaml, @job_id)

    assert job != nil,
           "#{@job_id} is missing from .github/workflows/ci.yml — the required repo-hygiene gate is gone"

    assert String.contains?(job, "bin/verify-repo-hygiene"),
           "#{@job_id} no longer runs bin/verify-repo-hygiene"

    assert String.contains?(job, "bin/verify-repo-hygiene --self-test"),
           "#{@job_id} no longer runs bin/verify-repo-hygiene --self-test, the required negative proof"

    stripped = strip_comment_lines(job)

    refute Regex.match?(~r/^\s*if:/m, stripped),
           "#{@job_id} acquired a job-level `if:` — a conditionally skipped required job needs an " <>
             "allowed-skips entry, which launders a red gate into a green merge"

    refute String.contains?(stripped, "continue-on-error"),
           "#{@job_id} acquired `continue-on-error` — that silently launders a red gate into green"

    refute String.contains?(stripped, "services:"),
           "#{@job_id} acquired a `services:` block — the gate needs no database"

    refute String.contains?(stripped, "actions/cache"),
           "#{@job_id} acquired an actions/cache step — the guard needs no dependency cache"

    refute String.contains?(stripped, "setup-beam"),
           "#{@job_id} acquired an erlef/setup-beam step — the guard is pure git/bash/perl and needs no BEAM"
  end

  test "the mutation controls actually catch what they claim to" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])
    job = job_block(yaml, @job_id)
    stripped = strip_comment_lines(job)

    for {name, mutated} <- [
          {"job block removed", nil},
          {"if: added", stripped <> "\n    if: always()\n"},
          {"continue-on-error added", stripped <> "\n    continue-on-error: true\n"},
          {"services: added", stripped <> "\n    services:\n      postgres:\n"},
          {"actions/cache added", stripped <> "\n      - uses: actions/cache@v5\n"},
          {"setup-beam added", stripped <> "\n      - uses: erlef/setup-beam@v1\n"}
        ] do
      case name do
        "job block removed" ->
          assert job_block(String.replace(yaml, "\n  #{@job_id}:\n", "\n  _removed_:\n"), @job_id) ==
                   nil,
                 "control #{name} did not change the input"

        _ ->
          refute mutated == stripped, "control #{name} did not change the input"

          mutated_job_ok? =
            !Regex.match?(~r/^\s*if:/m, mutated) and
              !String.contains?(mutated, "continue-on-error") and
              !String.contains?(mutated, "services:") and
              !String.contains?(mutated, "actions/cache") and
              !String.contains?(mutated, "setup-beam")

          refute mutated_job_ok?, "#{name} mutation must make the weakening assertions fail"
      end
    end
  end

  test "verify-repo-hygiene is in the job-id header, ci-required's needs:, and never allowed-skips" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(~r/^# Job id contract[^\n]*\n#[^\n]*#{@job_id}/m, yaml),
           "the job-id contract header no longer lists #{@job_id}"

    assert @job_id in ci_required_needs(yaml),
           "#{@job_id} is not in ci-required's needs: — outside the single required check it is " <>
             "merely advisory"

    refute @job_id in allowed_skip_or_failure_items(yaml),
           "#{@job_id} appears in an allowed-skips or allowed-failures list, laundering a red " <>
             "gate into a green merge"

    # Non-vacuity control: a needs: list missing our entry must fail the assertion above.
    mutated_needs = ci_required_needs(String.replace(yaml, "- #{@job_id}\n", ""))
    refute @job_id in mutated_needs, "removing the needs: entry mutation did not change the input"
  end

  test "no workflow file references the REPO_HYGIENE_ test-only env seam" do
    for file <- workflow_files() do
      contents = File.read!(file)
      found = forbidden_hygiene_surface(contents)

      assert found == [],
             "#{Path.relative_to(file, @repo_root)} references #{inspect(found)} — this is the " <>
               "REPO_HYGIENE_ test-only seam that would let a workflow edit redirect or narrow " <>
               "the scan without touching bin/verify-repo-hygiene itself"
    end
  end

  test "ci.all includes verify.repo_hygiene exactly once, between verify.deps_audit and the strict compile" do
    mix_exs = read_rel!(["mix.exs"])
    entries = ci_all_entries(mix_exs)

    assert Enum.count(entries, &(&1 == "verify.repo_hygiene")) == 1,
           "ci.all must invoke verify.repo_hygiene exactly once"

    deps_audit_index = Enum.find_index(entries, &(&1 == "verify.deps_audit"))
    repo_hygiene_index = Enum.find_index(entries, &(&1 == "verify.repo_hygiene"))
    compile_index = Enum.find_index(entries, &(&1 == "compile --warnings-as-errors"))

    assert deps_audit_index && repo_hygiene_index && compile_index,
           "expected verify.deps_audit, verify.repo_hygiene and the strict compile step all in ci.all"

    assert repo_hygiene_index > deps_audit_index,
           "verify.repo_hygiene must come after verify.deps_audit in ci.all"

    assert repo_hygiene_index < compile_index,
           "verify.repo_hygiene must come before the strict compile step in ci.all"

    assert String.contains?(mix_exs, "\"verify.repo_hygiene\": &verify_repo_hygiene/1"),
           "mix.exs no longer declares the verify.repo_hygiene alias"

    assert Regex.match?(
             ~r/defp verify_repo_hygiene\(_args\) do\s*\n\s*case Mix\.shell\(\)\.cmd\("bin\/verify-repo-hygiene"\)/,
             mix_exs
           ),
           "verify_repo_hygiene/1 no longer shells to bin/verify-repo-hygiene with no arguments"

    # Non-vacuity control: an alias call carrying an argument must fail the assertion above.
    original_call = "Mix.shell().cmd(\"bin/verify-repo-hygiene\")"
    mutated_call = "Mix.shell().cmd(\"bin/verify-repo-hygiene\", [\"--extra\"])"
    mutated = String.replace(mix_exs, original_call, mutated_call)

    refute Regex.match?(
             ~r/defp verify_repo_hygiene\(_args\) do\s*\n\s*case Mix\.shell\(\)\.cmd\("bin\/verify-repo-hygiene"\)/,
             mutated
           ),
           "the alias-arg mutation did not change the input"
  end

  test "CONTRIBUTING.md roster and job table document verify-repo-hygiene" do
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert String.contains?(contributing, "- `#{@job_id}`"),
           "CONTRIBUTING.md's roster bullet list is missing `- \`#{@job_id}\`` — the docs have drifted"

    assert String.contains?(contributing, "| `#{@job_id}` |"),
           "CONTRIBUTING.md's job table is missing a `| \`#{@job_id}\` |` row — the docs have drifted"

    # Non-vacuity control: removing the bullet/row must fail the assertions above.
    mutated =
      contributing
      |> String.replace("- `#{@job_id}`\n", "")
      |> String.replace(~r/\| `#{@job_id}` \|.*\n/, "")

    refute String.contains?(mutated, "- `#{@job_id}`"),
           "the roster-bullet-removal mutation did not change the input"

    refute String.contains?(mutated, "| `#{@job_id}` |"),
           "the table-row-removal mutation did not change the input"
  end
end
