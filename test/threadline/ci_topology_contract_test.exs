defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "verify-pgbouncer-topology:")
    assert String.contains?(yaml, "POOL_MODE: transaction")
    assert String.contains?(yaml, "AUTH_TYPE: scram-sha-256")
    assert String.contains?(yaml, "THREADLINE_PGBOUNCER_TOPOLOGY: \"1\"")
    assert String.contains?(yaml, "mix verify.topology")
    assert String.contains?(yaml, "priv/ci/topology_bootstrap.exs")
    assert String.contains?(yaml, "edoburu/pgbouncer:")
  end

  test "ci.all alias does not include verify.bench" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.bench\"")
  end

  test "ci.all alias does not include verify.release" do
    mix_exs = read_rel!(["mix.exs"])

    assert mix_exs =~ "\"ci.all\": ["

    [_, ci_all_block] = String.split(mix_exs, "\"ci.all\": [")
    [ci_all_list | _] = String.split(ci_all_block, "]")

    refute String.contains?(ci_all_list, "\"verify.release\"")
  end

  test "mix aliases expose the named support-lane proof entrypoints" do
    mix_exs = read_rel!(["mix.exs"])

    assert String.contains?(mix_exs, "\"verify.compile_no_optional\":")
    assert String.contains?(mix_exs, "\"compile --no-optional-deps --warnings-as-errors\"")
    assert String.contains?(mix_exs, "\"verify.test\": [\"test\"]")
    assert String.contains?(mix_exs, "\"verify.example\": &verify_example/1")

    assert String.contains?(mix_exs, "\"verify.doc_contract\": [")
    assert String.contains?(mix_exs, "test test/threadline/readme_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/how_threadline_works_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/operator_surface_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/upgrade_path_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/getting_started_saas_doc_contract_test.exs")
    assert String.contains?(mix_exs, "test/threadline/audit_doc_contract_test.exs")

    assert String.contains?(
             mix_exs,
             "test/threadline/integration_contracts_doc_contract_test.exs"
           )

    assert String.contains?(mix_exs, "test/threadline/example_phoenix_readme_contract_test.exs")

    # v1_23_charter_doc_contract_test.exs was deleted in Phase 198 (D-06) as
    # genuinely obsolete, and dropped from the verify.doc_contract alias in the
    # same commit. Asserting a deleted file is still listed would have forced the
    # alias to reference a path that no longer exists.
    refute String.contains?(mix_exs, "test/threadline/v1_23_charter_doc_contract_test.exs")
  end

  test "ci.all keeps capture-only and phoenix-surface proof steps in order" do
    mix_exs = read_rel!(["mix.exs"])

    assert [_, ci_block] =
             Regex.run(~r/"ci\.all":\s*\[\s*\n((?:.*\n)*?)\s*\]/, mix_exs),
           "expected mix.exs to declare a multiline ci.all list"

    {pos_compile_strict, _} = :binary.match(ci_block, "\"compile --warnings-as-errors\"")
    {pos_compile_no_optional, _} = :binary.match(ci_block, "\"verify.compile_no_optional\"")
    {pos_verify_test, _} = :binary.match(ci_block, "\"verify.test\"")
    {pos_verify_threadline, _} = :binary.match(ci_block, "\"verify.threadline\"")
    {pos_verify_example, _} = :binary.match(ci_block, "\"verify.example\"")
    {pos_verify_doc_contract, _} = :binary.match(ci_block, "\"verify.doc_contract\"")

    assert pos_compile_strict < pos_compile_no_optional
    assert pos_compile_no_optional < pos_verify_test
    assert pos_verify_test < pos_verify_threadline
    assert pos_verify_threadline < pos_verify_example
    assert pos_verify_example < pos_verify_doc_contract
  end

  test "ci workflow exposes the documented support-lane job ids" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert Regex.match?(~r/^  verify-compile-no-optional:/m, yaml)
    assert Regex.match?(~r/^  verify-test:/m, yaml)
    assert Regex.match?(~r/^  verify-docs:/m, yaml)
  end

  test "verify-test job runs the phoenix-surface and sigra-reference proof path" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "- name: Run tests")
    assert String.contains?(yaml, "run: mix verify.test")
    assert String.contains?(yaml, "- name: Verify Threadline trigger coverage")
    assert String.contains?(yaml, "run: mix verify.threadline")
    assert String.contains?(yaml, "- name: Verify Threadline Phoenix example")
    assert String.contains?(yaml, "run: mix verify.example")
    assert String.contains?(yaml, "- name: Doc contract tests")
    assert String.contains?(yaml, "run: mix verify.doc_contract")
  end

  # Globs BOTH extensions on purpose. GitHub Actions honours .yaml as well as
  # .yml, so a guard that only globbed .yml could be defeated by a rename.
  defp workflow_paths do
    @repo_root
    |> Path.join(".github/workflows/*.{yml,yaml}")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end

  # GREEN-09 / D-24 / D-25 resurrection guard.
  #
  # Globs every workflow rather than naming ui-critic.yml, so re-introducing the
  # paid lane under ANY filename is caught. The needle is built by concatenation
  # because this file is itself read by nothing that scans for it — but the
  # concatenation also keeps a naive `grep -rl ANTHROPIC .github/` gate honest if
  # this guard is ever moved under .github/.
  test "no workflow references the paid critic API key (GREEN-09 resurrection guard)" do
    needle = "ANTHROPIC" <> "_API_KEY"
    paths = workflow_paths()

    refute paths == [],
           "found no workflow files to scan — the glob is broken, and a broken glob " <>
             "would launder a false pass for this guard"

    for path <- paths do
      refute String.contains?(read_rel!([path]), needle),
             "#{path} references #{needle} — the paid critic lane must stay structurally " <>
               "unreachable from CI (GREEN-09). Deleting the workflow, not defaulting its " <>
               "score input to false, is what satisfies this requirement."
    end
  end

  # GREEN-10 / D-26 / D-25 resurrection guard.
  #
  # Asserts LIST EQUALITY against a one-element list, not a count and not a bare
  # refutation. A count would pass if the one publish path moved to the wrong
  # workflow; a refutation would pass vacuously if the glob returned nothing.
  # Both failure modes are real and both are excluded by equality.
  test "exactly one workflow invokes the Hex publish command (GREEN-10 resurrection guard)" do
    publishers =
      Enum.filter(workflow_paths(), fn path ->
        String.contains?(read_rel!([path]), "mix hex.publish")
      end)

    assert publishers == [".github/workflows/release.yml"],
           "expected exactly one publish path, release.yml, but found: " <>
             inspect(publishers) <>
             ". release.yml is the only workflow carrying the five pre-publish gates " <>
             "(CI-green poll, hard needs:, verify-release-shape + hex.build, the " <>
             "already-published idempotency skip, and post-publish verification). A second " <>
             "publish path races it and wins, because publishing is irreversible in effect " <>
             "and the gated path polls for up to 30 minutes."
  end

  test "adoption pilot backlog carries CI topology contract marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "CI-PGBOUNCER-TOPOLOGY-CONTRACT")
  end

  test "adoption pilot backlog carries STG host topology template marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
  end

  test "adoption pilot backlog carries STG audited path rubric marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end

  # --- Phase 198-21 / D-42 merge-gate self-guarding contracts ---------------
  #
  # `.github/rulesets/main.json` names only the single aggregate context
  # `CI required`, so it structurally cannot detect a lane quietly dropped
  # from `ci-required`'s `needs:` list — the ruleset stays byte-identical
  # while the guarantee behind it shrinks. These two tests derive the merge
  # gate's real membership and its required-context singleton from source, in
  # both directions, so that narrowing is a red test rather than an invisible
  # YAML edit.

  @ci_required_roster_heading "### `ci-required` needs: roster"

  # Isolates the `ci-required:` job block. `ci-required` is the final job in
  # `ci.yml`'s `jobs:` map, so everything after the marker belongs to it.
  defp ci_required_block do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    case String.split(yaml, "\n  ci-required:\n", parts: 2) do
      [_, tail] ->
        tail

      _ ->
        flunk(
          "could not find a \"  ci-required:\" job in .github/workflows/ci.yml — " <>
            "the derive source for the merge-gate roster contract is broken"
        )
    end
  end

  defp ci_required_needs do
    block = ci_required_block()

    case Regex.run(~r/    needs:\n((?:      - .+\n)+)/, block) do
      [_, items] ->
        items
        |> String.split("\n", trim: true)
        |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

      nil ->
        []
    end
  end

  defp strip_comment_lines(block) do
    block
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  defp documented_needs_section do
    contributing = read_rel!(["CONTRIBUTING.md"])

    assert String.contains?(contributing, @ci_required_roster_heading),
           "CONTRIBUTING.md has no \"#{@ci_required_roster_heading}\" heading — the " <>
             "documented side of the merge-gate roster contract is missing entirely."

    contributing
    |> String.split(@ci_required_roster_heading, parts: 2)
    |> List.last()
    |> String.split(~r/\n#+ /, parts: 2)
    |> List.first()
  end

  defp documented_needs_roster do
    documented_needs_section()
    |> then(&Regex.scan(~r/^- `([a-z0-9-]+)`$/m, &1))
    |> Enum.map(fn [_, id] -> id end)
  end

  test "ci-required's needs: roster matches CONTRIBUTING.md in both drift directions and stays non-vacuous" do
    actual = ci_required_needs()
    documented = documented_needs_roster()

    assert length(actual) >= 10,
           "ci-required's derived needs: list has only #{length(actual)} entr" <>
             "#{if length(actual) == 1, do: "y", else: "ies"} (#{inspect(actual)}) — fewer " <>
             "than ten is a broken derive, not a real narrowing, and must fail loudly rather " <>
             "than silently asserting nothing while still reporting success."

    missing_from_docs = actual -- documented

    assert missing_from_docs == [],
           "ci-required requires #{inspect(missing_from_docs)} but CONTRIBUTING.md's " <>
             "\"#{@ci_required_roster_heading}\" roster omits it — the docs have drifted " <>
             "behind the pipeline."

    undocumented_extra = documented -- actual

    assert undocumented_extra == [],
           "CONTRIBUTING.md's \"#{@ci_required_roster_heading}\" roster claims " <>
             "#{inspect(undocumented_extra)} but ci-required no longer requires it in " <>
             ".github/workflows/ci.yml — this is the silent-narrowing case D-42 exists to " <>
             "catch: a needs: entry was removed without a matching documented roster edit."

    stripped = strip_comment_lines(ci_required_block())

    if Regex.match?(~r/^\s*allowed-skips:/m, stripped) or
         Regex.match?(~r/^\s*allowed-failures:/m, stripped) do
      section = documented_needs_section()

      assert String.contains?(section, "allowed-skips decision:") or
               String.contains?(section, "allowed-failures decision:"),
             "ci-required's alls-green step now carries allowed-skips or allowed-failures, " <>
               "but the \"#{@ci_required_roster_heading}\" section records no decision " <>
               "citation for it — an allowed failure launders a red lane into a green gate " <>
               "(D-09) and must be documented, not silently introduced."
    end
  end

  test "the ruleset's sole required status check is byte-exact with ci-required's emitted name" do
    ruleset =
      [".github", "rulesets", "main.json"]
      |> read_rel!()
      |> Jason.decode!()

    required_status_checks_rule =
      Enum.find(ruleset["rules"], fn rule -> rule["type"] == "required_status_checks" end)

    refute is_nil(required_status_checks_rule),
           ".github/rulesets/main.json has no required_status_checks rule at all"

    contexts = required_status_checks_rule["parameters"]["required_status_checks"]

    assert length(contexts) == 1,
           "expected exactly one required status check context in " <>
             ".github/rulesets/main.json, found #{length(contexts)}: #{inspect(contexts)}. " <>
             "A second required context reintroduces the enumeration hazard D-08 replaced " <>
             "with a single aggregate gate."

    [%{"context" => context}] = contexts

    assert context === "CI required",
           "expected the ruleset's required status check context to be the exact literal " <>
             "\"CI required\", got #{inspect(context)} — GitHub matches required checks on " <>
             "exact string, never case-insensitively or trimmed."

    yaml = read_rel!([".github", "workflows", "ci.yml"])

    job_name =
      case Regex.run(~r/\n  ci-required:\n    name: (.+)\n/, yaml) do
        [_, name] -> name
        nil -> flunk("could not find ci-required's \"    name:\" line in ci.yml")
      end

    assert job_name === context,
           "ci-required's emitted name: (#{inspect(job_name)}) no longer matches the " <>
             "ruleset's sole required context (#{inspect(context)}) — GitHub matches " <>
             "required checks on the exact emitted job name (D-08), so this mismatch would " <>
             "make the required check permanently unsatisfiable."
  end
end
