defmodule Threadline.RepoContractScopeContractTest do
  @moduledoc """
  CI-03 lane scope contract (Phase 247, D-10).

  Repo-file contract tests carry the module tag `:repo_contract`: their outcome
  does not depend on the Elixir/OTP/PostgreSQL toolchain, so CI runs them on
  the current lane only. The mechanism is file filtering in
  `bin/ci-test-partitions` (`THREADLINE_TEST_SCOPE=toolchain`), routed from the
  `verify-test` matrix to the min and latest rows. It is deliberately not an
  ExUnit exclude: local `mix test` and the current lane run every test, and
  `test/test_helper.exs` keeps exactly its two sanctioned excludes
  (`Threadline.ZeroSkipsContractTest`).

  Three rules, each a pure checker with a mutation control:

    * `doc-sentence`: `CONTRIBUTING.md`'s `## CI Coverage` section states the
      scope, so the honest-default docs say which tests skip which lanes.
    * `scope-rows`: `test-scope: toolchain` sits on exactly the `min` and
      `latest` verify-test include rows, and the `Run tests` step passes it as
      `THREADLINE_TEST_SCOPE`. A `current` row with the scope would run no repo
      contract anywhere.
    * `filter-literal`: the script's tag regex is exactly the whole-line form
      of the tag this file carries, so a renamed tag cannot silently stop the
      filter (dropping nothing) or diverge from the tagged files.

  Phase 247-07 adds the D-09 classification directions beside these checkers.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @repo_root File.cwd!()
  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @ci_yml Path.join(@repo_root, ".github/workflows/ci.yml")
  @script Path.join(@repo_root, "bin/ci-test-partitions")
  @self_source Path.join(@repo_root, "test/threadline/repo_contract_scope_contract_test.exs")

  @coverage_heading "## CI Coverage"
  @scope_lanes ["latest", "min"]
  @scope_env "${{ matrix.test-scope }}"

  # Assembled at runtime: a literal tag line in a string here would be one more
  # place the tag text lives, and 247-07's classification scan reads sources.
  def tag_line, do: "@" <> "moduletag :" <> "repo_contract"

  def doc_sentence do
    "Repo-file contract tests (`#{tag_line()}`: their outcome does not depend on " <>
      "the Elixir/OTP/PostgreSQL toolchain) run only on the current lane in CI: " <>
      "`bin/ci-test-partitions` drops them on the min and latest lanes " <>
      "(`THREADLINE_TEST_SCOPE=toolchain`), while local `mix test` and the " <>
      "current lane run every test."
  end

  def expected_filter_literal, do: "^[[:space:]]*" <> tag_line() <> "[[:space:]]*$"

  # --- rule doc-sentence -------------------------------------------------------

  def coverage_section(contributing) do
    case String.split(contributing, @coverage_heading, parts: 2) do
      [_, rest] -> rest |> String.split(~r/\n## /, parts: 2) |> List.first()
      _ -> nil
    end
  end

  def doc_sentence_errors(contributing) do
    case coverage_section(contributing) do
      nil ->
        ["rule=doc-sentence: CONTRIBUTING.md has no `#{@coverage_heading}` section"]

      section ->
        if String.contains?(squish(section), doc_sentence()) do
          []
        else
          [
            "rule=doc-sentence: the `#{@coverage_heading}` section must state the lane scope: " <>
              doc_sentence()
          ]
        end
    end
  end

  defp squish(text), do: text |> String.split() |> Enum.join(" ")

  # --- rule scope-rows ---------------------------------------------------------

  def scope_rows_errors(ci_yml) do
    with {:ok, doc} <- parse_yaml(ci_yml),
         %{} = job <- get_in(doc, ["jobs", "verify-test"]) || :no_job do
      row_errors(get_in(job, ["strategy", "matrix", "include"])) ++
        env_errors(Map.get(job, "steps"))
    else
      {:error, message} -> ["rule=scope-rows: ci.yml does not parse: #{message}"]
      _ -> ["rule=scope-rows: ci.yml has no verify-test job"]
    end
  end

  defp row_errors(rows) when is_list(rows) and rows != [] do
    scoped =
      rows
      |> Enum.filter(&(is_map(&1) and Map.has_key?(&1, "test-scope")))

    bad_values =
      for row <- scoped,
          row["test-scope"] != "toolchain",
          do:
            "rule=scope-rows: lane #{inspect(row["lane"])} has test-scope #{inspect(row["test-scope"])}"

    lanes = scoped |> Enum.map(& &1["lane"]) |> Enum.sort()

    lane_errors =
      if lanes == @scope_lanes do
        []
      else
        [
          "rule=scope-rows: test-scope must sit on exactly the min and latest include rows, " <>
            "got #{inspect(lanes)}"
        ]
      end

    bad_values ++ lane_errors
  end

  defp row_errors(_), do: ["rule=scope-rows: verify-test has no matrix include rows"]

  defp env_errors(steps) when is_list(steps) do
    case Enum.filter(steps, &(is_map(&1) and &1["name"] == "Run tests")) do
      [step] ->
        if get_in(step, ["env", "THREADLINE_TEST_SCOPE"]) == @scope_env do
          []
        else
          ["rule=scope-rows: the Run tests step must set THREADLINE_TEST_SCOPE: #{@scope_env}"]
        end

      found ->
        ["rule=scope-rows: expected one verify-test `Run tests` step, found #{length(found)}"]
    end
  end

  defp env_errors(_), do: ["rule=scope-rows: verify-test has no steps"]

  defp parse_yaml(text) do
    {:ok, YamlElixir.read_from_string!(text, merge_anchors: true)}
  rescue
    error -> {:error, Exception.message(error)}
  end

  # --- rule filter-literal -----------------------------------------------------

  def filter_literal(script) do
    case Regex.run(~r/^REPO_CONTRACT_TAG_RE='([^'\n]*)'$/m, script) do
      [_, literal] -> literal
      _ -> nil
    end
  end

  def filter_literal_errors(script) do
    case filter_literal(script) do
      nil ->
        ["rule=filter-literal: bin/ci-test-partitions has no REPO_CONTRACT_TAG_RE='...' line"]

      literal ->
        if literal == expected_filter_literal() and
             String.contains?(script, ~s("$REPO_CONTRACT_TAG_RE")) do
          []
        else
          [
            "rule=filter-literal: REPO_CONTRACT_TAG_RE must be #{inspect(expected_filter_literal())} " <>
              "and be used by the filter, got #{inspect(literal)}"
          ]
        end
    end
  end

  # --- live ----------------------------------------------------------------------

  test "rule doc-sentence: CONTRIBUTING CI Coverage states the lane scope" do
    assert doc_sentence_errors(File.read!(@contributing)) == []
  end

  test "rule scope-rows: test-scope toolchain on min and latest only, routed to Run tests" do
    assert scope_rows_errors(File.read!(@ci_yml)) == []
  end

  test "rule filter-literal: the script filters on exactly this tag's whole-line form" do
    script = File.read!(@script)
    assert filter_literal_errors(script) == []

    # The literal is a working regex for this file's own tag line (POSIX
    # classes read the same in grep -E and PCRE).
    regex = Regex.compile!(filter_literal(script), "m")

    assert Regex.match?(regex, File.read!(@self_source)),
           "the filter must match this file's tag line"

    refute Regex.match?(regex, "  " <> tag_line() <> "s\n")
  end

  # --- mutation controls -------------------------------------------------------

  test "mutation control doc-sentence: removing the sentence turns the rule red" do
    original = File.read!(@contributing)

    mutated =
      original
      |> String.split("\n\n")
      |> Enum.reject(&(squish(&1) == doc_sentence()))
      |> Enum.join("\n\n")

    refute mutated == original, "doc-sentence control did not change the input"
    assert Enum.any?(doc_sentence_errors(mutated), &String.starts_with?(&1, "rule=doc-sentence"))
  end

  test "mutation controls scope-rows: wrong lanes or a dropped env turn the rule red" do
    ci = File.read!(@ci_yml)

    controls = [
      {"test-scope added to the current row",
       String.replace(
         ci,
         "          - lane: current\n",
         "          - lane: current\n            test-scope: toolchain\n"
       )},
      {"test-scope removed from the latest row",
       String.replace(
         ci,
         ~s(            otp: "29.1.1"\n            test-scope: toolchain\n),
         ~s(            otp: "29.1.1"\n)
       )},
      {"Run tests env dropped",
       String.replace(ci, "          THREADLINE_TEST_SCOPE: #{@scope_env}\n", "")}
    ]

    for {control, mutated} <- controls do
      refute mutated == ci, "#{control} control did not change the input"

      assert Enum.any?(scope_rows_errors(mutated), &String.starts_with?(&1, "rule=scope-rows")),
             "#{control} must make rule scope-rows fail"
    end
  end

  test "mutation control filter-literal: a renamed tag in the script turns the rule red" do
    script = File.read!(@script)
    mutated = String.replace(script, ":repo_contract[[:space:]]", ":repo_contracts[[:space:]]")
    refute mutated == script, "filter-literal control did not change the input"

    assert Enum.any?(
             filter_literal_errors(mutated),
             &String.starts_with?(&1, "rule=filter-literal")
           )
  end
end
