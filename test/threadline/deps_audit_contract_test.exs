defmodule Threadline.DepsAuditContractTest do
  @moduledoc """
  Wiring contract for the SUP-02 supply-chain gate: the `verify-deps-audit`
  CI job must exist, run both `mix verify.deps_audit` and
  `bin/verify-deps-audit --self-test`, carry no `if:`/`continue-on-error`/
  `services:`, be listed in the job-id header and in `ci-required`'s
  `needs:`, never appear in an `allowed-skips`/`allowed-failures` list, be
  mirrored in `ci.all` and in CONTRIBUTING.md's roster, and no workflow file
  may ever set `HEX_IGNORE_ADVISORIES` or `HEX_IGNORE_RETIREMENTS`.

  Local private helpers only — deliberately does not import from other test
  modules, per the same-commit roster rule's isolation convention.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @job_id "verify-deps-audit"

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

    assert_non_empty =
      case files do
        [] -> flunk("no .github/workflows/*.{yml,yaml} files found — the scan cannot be vacuous")
        list -> list
      end

    assert_non_empty
  end

  test "verify-deps-audit job exists, runs both required commands, and carries no weakening" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    job = job_block(yaml, @job_id)

    assert job != nil,
           "#{@job_id} is missing from .github/workflows/ci.yml — the required supply-chain gate is gone"

    assert String.contains?(job, "mix verify.deps_audit"),
           "#{@job_id} no longer runs `mix verify.deps_audit`"

    assert String.contains?(job, "bin/verify-deps-audit --self-test"),
           "#{@job_id} no longer runs `bin/verify-deps-audit --self-test`, the required negative proof"

    refute Regex.match?(~r/^\s*if:/m, strip_comment_lines(job)),
           "#{@job_id} acquired a job-level `if:` — a conditionally skipped required job needs an " <>
             "allowed-skips entry, which launders a red gate into a green merge"

    refute String.contains?(strip_comment_lines(job), "continue-on-error"),
           "#{@job_id} acquired `continue-on-error` — that silently launders a red gate into green"

    refute String.contains?(strip_comment_lines(job), "services:"),
           "#{@job_id} acquired a `services:` block — the gate needs no database"
  end

  test "verify-deps-audit is in the job-id header, ci-required's needs:, and never allowed-skips" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(~r/^# Job id contract[^\n]*\n#[^\n]*#{@job_id}/m, yaml),
           "the job-id contract header no longer lists #{@job_id}"

    assert @job_id in ci_required_needs(yaml),
           "#{@job_id} is not in ci-required's needs: — outside the single required check it is " <>
             "merely advisory"

    refute @job_id in allowed_skip_or_failure_items(yaml),
           "#{@job_id} appears in an allowed-skips or allowed-failures list, laundering a red " <>
             "gate into a green merge"
  end

  test "no workflow file ever sets HEX_IGNORE_ADVISORIES or HEX_IGNORE_RETIREMENTS" do
    for file <- workflow_files() do
      contents = File.read!(file)

      refute Regex.match?(~r/HEX_IGNORE_(ADVISORIES|RETIREMENTS)/, contents),
             "#{Path.relative_to(file, @repo_root)} references HEX_IGNORE_ADVISORIES or " <>
               "HEX_IGNORE_RETIREMENTS — this is the exact env-var bypass the gate refuses"
    end
  end

  test "ci.all includes verify.deps_audit exactly once and the alias still shells with no args" do
    mix_exs = read_rel!(["mix.exs"])

    assert ci_all_entries(mix_exs) |> Enum.count(&(&1 == "verify.deps_audit")) == 1,
           "ci.all must invoke verify.deps_audit exactly once"

    assert String.contains?(mix_exs, "\"verify.deps_audit\": &verify_deps_audit/1"),
           "mix.exs no longer declares the verify.deps_audit alias"

    assert Regex.match?(
             ~r/defp verify_deps_audit\(_args\) do\s*\n\s*case Mix\.shell\(\)\.cmd\("bin\/verify-deps-audit"\)/,
             mix_exs
           ),
           "verify_deps_audit/1 no longer shells to bin/verify-deps-audit with no arguments"
  end

  test "CONTRIBUTING.md roster and List 1 table document verify-deps-audit" do
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert String.contains?(contributing, "- `#{@job_id}`"),
           "CONTRIBUTING.md's roster bullet list is missing `- \`#{@job_id}\`` — the docs have drifted"

    assert String.contains?(contributing, "| `#{@job_id}` |"),
           "CONTRIBUTING.md's job table is missing a `| \`#{@job_id}\` |` row — the docs have drifted"
  end
end
