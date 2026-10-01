defmodule Threadline.PropertyScaleContractTest do
  @moduledoc """
  PROP-08 (D-11): pins the `THREADLINE_PROPERTY_SCALE` run-budget wiring end
  to end, so a later edit that silently drops the scale, hard-codes
  `max_runs`, or sets the knob somewhere it shouldn't fails a fast local test
  rather than only being noticed when the weekly Flake Detection lane quietly
  stops running deeper than per-PR CI.

  Covers, per D-11:
    (a) `Threadline.Test.PropertyRuns.parse_scale/1`, `pure/1`, `db/1` at
        scales 1 and 5;
    (b) the workflow YAML, parsed with `YamlElixir` rather than matched by
        regex: exactly one step across both workflows (the one whose `run`
        invokes `mix verify.flake`, in flake-detection.yml) sets the env var,
        pinned to `"5"`; `ci.yml` never sets or references it;
    (c) a source scan: every `check all(...)` in `test/**/*_property_test.exs`
        carries `max_runs:` that resolves (directly, or through an `@max_runs`
        attribute) to a `PropertyRuns.pure/1` call with a literal base in
        150..200 or a `PropertyRuns.db/1` call with a literal base in 1..20;
    (d) `CONTRIBUTING.md` names the variable.

  Never mutates the OS environment variable this module reads: this file runs
  concurrently with every other test, including the properties this contract
  pins the budget for, and a mutated env would race all of them.
  """

  use ExUnit.Case, async: true

  alias Threadline.Test.PropertyRuns

  @repo_root File.cwd!()
  @flake_workflow_path Path.join(@repo_root, ".github/workflows/flake-detection.yml")
  @ci_workflow_path Path.join(@repo_root, ".github/workflows/ci.yml")
  @contributing_path Path.join(@repo_root, "CONTRIBUTING.md")
  @env_var PropertyRuns.env_var()

  # ---------------------------------------------------------------------
  # (a) parse_scale/1, pure/1, db/1 unit pins
  # ---------------------------------------------------------------------

  describe "PropertyRuns.parse_scale/1, pure/1, db/1 (D-07, D-11a)" do
    test "nil (unset) gives scale 1" do
      assert PropertyRuns.parse_scale(nil) == 1
    end

    test "the literal integers 1 and 10 are accepted" do
      assert PropertyRuns.parse_scale("1") == 1
      assert PropertyRuns.parse_scale("10") == 10
    end

    for bad <- ["", "0", "-1", "5x", "5.0", "11"] do
      test "rejects #{inspect(bad)}, naming the variable and the range" do
        bad = unquote(bad)

        assert_raise ArgumentError, ~r/THREADLINE_PROPERTY_SCALE/, fn ->
          PropertyRuns.parse_scale(bad)
        end

        assert_raise ArgumentError, ~r/1\.\.10/, fn ->
          PropertyRuns.parse_scale(bad)
        end
      end
    end

    test "pure/db arithmetic mirrors base x scale (pure) and base x min(scale, 3) (db)" do
      # Pure helper functions, never touching the OS environment — mirrors
      # the real pure/1, db/1 bodies at explicit scales.
      pure_at = fn base, scale -> base * scale end
      db_at = fn base, scale -> base * min(scale, 3) end

      assert pure_at.(200, 1) == 200
      assert pure_at.(200, 5) == 1000
      assert db_at.(20, 1) == 20
      assert db_at.(20, 5) == 60
    end

    test "PropertyRuns.pure/1 equals base times the current (unmutated) scale" do
      assert PropertyRuns.pure(200) == 200 * PropertyRuns.scale()
      assert PropertyRuns.db(20) == 20 * min(PropertyRuns.scale(), 3)
    end
  end

  # ---------------------------------------------------------------------
  # (b) workflow YAML — parsed, not regex-matched
  # ---------------------------------------------------------------------

  # Every place in `yaml` that sets `var`, each tagged with whether its
  # owning step's `run:` invokes `mix verify.flake` — so callers can tell
  # "set on the right step" from "set somewhere else entirely".
  defp env_settings(yaml, var) do
    jobs = yaml["jobs"] || %{}

    workflow_setting =
      case get_in(yaml, ["env", var]) do
        nil -> []
        value -> [%{location: "workflow env", value: value, owns_verify_flake?: false}]
      end

    job_settings =
      for {job_name, job} <- jobs,
          value = get_in(job, ["env", var]),
          not is_nil(value) do
        %{location: "job #{job_name} env", value: value, owns_verify_flake?: false}
      end

    step_settings =
      for {job_name, job} <- jobs,
          step <- job["steps"] || [],
          value = get_in(step, ["env", var]),
          not is_nil(value) do
        %{
          location: "job #{job_name} step #{step["id"] || step["name"]}",
          value: value,
          owns_verify_flake?: runs_verify_flake?(step)
        }
      end

    workflow_setting ++ job_settings ++ step_settings
  end

  defp runs_verify_flake?(step) do
    is_binary(step["run"]) and String.contains?(step["run"], "mix verify.flake")
  end

  defp ci_run_mentions_var?(yaml, var) do
    jobs = yaml["jobs"] || %{}

    Enum.any?(jobs, fn {_name, job} ->
      Enum.any?(job["steps"] || [], fn step ->
        is_binary(step["run"]) and String.contains?(step["run"], "#{var}=")
      end)
    end)
  end

  defp owning_violations([%{value: "5"}]), do: []

  defp owning_violations([%{value: other_value}]) do
    [
      "the step running mix verify.flake must set #{@env_var} to \"5\", got " <>
        inspect(other_value)
    ]
  end

  defp owning_violations([]) do
    ["no step running mix verify.flake sets #{@env_var} in flake-detection.yml"]
  end

  defp owning_violations(many) do
    [
      "expected exactly one step running mix verify.flake to set #{@env_var}, found " <>
        "#{length(many)}"
    ]
  end

  defp other_violations([]), do: []

  defp other_violations(settings) do
    [
      "#{@env_var} must only be set on the step running mix verify.flake, also found: " <>
        inspect(Enum.map(settings, & &1.location))
    ]
  end

  defp ci_env_violations([]), do: []

  defp ci_env_violations(settings) do
    ["ci.yml must never set #{@env_var}, found: " <> inspect(Enum.map(settings, & &1.location))]
  end

  defp ci_run_violations(ci) do
    if ci_run_mentions_var?(ci, @env_var) do
      ["ci.yml must never reference #{@env_var} in a run: step"]
    else
      []
    end
  end

  @doc false
  def flake_violations(flake_yaml, ci_yaml) do
    flake = YamlElixir.read_from_string!(flake_yaml)
    ci = YamlElixir.read_from_string!(ci_yaml)

    {owning, other} = Enum.split_with(env_settings(flake, @env_var), & &1.owns_verify_flake?)

    owning_violations(owning) ++
      other_violations(other) ++
      ci_env_violations(env_settings(ci, @env_var)) ++ ci_run_violations(ci)
  end

  describe "flake-detection.yml / ci.yml wiring (D-09, D-11b)" do
    test "the step running mix verify.flake sets THREADLINE_PROPERTY_SCALE to \"5\", nowhere else" do
      flake_yaml = File.read!(@flake_workflow_path)
      ci_yaml = File.read!(@ci_workflow_path)

      assert flake_violations(flake_yaml, ci_yaml) == []
    end

    @flake_env_block "        env:\n          THREADLINE_PROPERTY_SCALE: \"5\"\n"
    @compile_step "      - name: Compile (warnings as errors)\n" <>
                    "        if: steps.gate.outputs.decision == 'run'\n" <>
                    "        run: mix compile --warnings-as-errors\n"
    @compile_step_with_env "      - name: Compile (warnings as errors)\n" <>
                             "        if: steps.gate.outputs.decision == 'run'\n" <>
                             "        env:\n" <>
                             "          THREADLINE_PROPERTY_SCALE: \"5\"\n" <>
                             "        run: mix compile --warnings-as-errors\n"

    test "mutation controls each produce a violation and each changes the input" do
      flake_yaml = File.read!(@flake_workflow_path)
      ci_yaml = File.read!(@ci_workflow_path)

      assert String.contains?(flake_yaml, @flake_env_block)
      assert String.contains?(flake_yaml, @compile_step)

      mutation_controls = [
        {"misspelled key",
         String.replace(
           flake_yaml,
           "THREADLINE_PROPERTY_SCALE: \"5\"",
           "THREADLINE_PROPERTY_SCALEX: \"5\""
         ), ci_yaml},
        {"moved to the compile step",
         flake_yaml
         |> String.replace(@flake_env_block, "")
         |> String.replace(@compile_step, @compile_step_with_env), ci_yaml},
        {"value set to \"1\"",
         String.replace(
           flake_yaml,
           "THREADLINE_PROPERTY_SCALE: \"5\"",
           "THREADLINE_PROPERTY_SCALE: \"1\""
         ), ci_yaml},
        {"env deleted", String.replace(flake_yaml, @flake_env_block, ""), ci_yaml},
        {"set in ci.yml", flake_yaml,
         String.replace(ci_yaml, "jobs:\n", "env:\n  THREADLINE_PROPERTY_SCALE: \"5\"\njobs:\n")}
      ]

      for {label, mutated_flake, mutated_ci} <- mutation_controls do
        refute mutated_flake == flake_yaml and mutated_ci == ci_yaml,
               "#{label}: control did not change the input"

        assert flake_violations(mutated_flake, mutated_ci) != [],
               "#{label} must produce a violation"
      end
    end
  end

  # ---------------------------------------------------------------------
  # (c) source scan — AST, not regex
  # ---------------------------------------------------------------------

  # Matches a literal-integer call to `PropertyRuns.pure(n)` / `.db(n)`, at
  # any alias depth (`PropertyRuns.pure(n)` or
  # `Threadline.Test.PropertyRuns.pure(n)`), returning the literal `n`.
  defp property_runs_call_value({{:., _, [{:__aliases__, _, mod_parts}, fun]}, _, [n]}, fun)
       when is_integer(n) do
    if List.last(mod_parts) == :PropertyRuns, do: {:ok, n}, else: :error
  end

  defp property_runs_call_value(_ast, _fun), do: :error

  defp attribute_reference?({:@, _, [{:max_runs, _, nil}]}), do: true
  defp attribute_reference?(_ast), do: false

  defp collect_max_runs_attrs(ast) do
    {_ast, attrs} =
      Macro.prewalk(ast, [], fn
        {:@, _, [{:max_runs, _, [value_ast]}]} = node, acc -> {node, [value_ast | acc]}
        node, acc -> {node, acc}
      end)

    attrs
  end

  defp collect_checks(ast) do
    {_ast, checks} =
      Macro.prewalk(ast, [], fn
        {:check, meta, [{:all, _, args} | _rest]} = node, acc ->
          {node, [{meta[:line], args} | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(checks)
  end

  defp extract_max_runs(args) do
    with last when is_list(last) <- List.last(args),
         true <- Keyword.keyword?(last),
         {:ok, value_ast} <- Keyword.fetch(last, :max_runs) do
      {:ok, value_ast}
    else
      _ -> :missing
    end
  end

  # Resolves `value_ast` to a pure/db base (direct call, or through one level
  # of `@max_runs` indirection) and classifies it against the committed
  # ranges. `seen` guards against a self-referential `@max_runs` definition.
  defp classify_max_runs(value_ast, attrs, seen \\ []) do
    case property_runs_call_value(value_ast, :pure) do
      {:ok, n} -> range_result(n, 150..200, "pure base")
      :error -> classify_db_or_attribute(value_ast, attrs, seen)
    end
  end

  defp classify_db_or_attribute(value_ast, attrs, seen) do
    case property_runs_call_value(value_ast, :db) do
      {:ok, n} -> range_result(n, 1..20, "db base")
      :error -> classify_attribute_reference(value_ast, attrs, seen)
    end
  end

  defp classify_attribute_reference(value_ast, attrs, seen) do
    cond do
      not attribute_reference?(value_ast) ->
        {:error,
         "max_runs: is not a literal PropertyRuns.pure(n)/.db(n) call or an @max_runs reference"}

      value_ast in seen ->
        {:error, "@max_runs attribute reference cycle"}

      attrs == [] ->
        {:error, "max_runs: references @max_runs, but no @max_runs attribute was found"}

      true ->
        resolve_any_attr(attrs, value_ast, seen)
    end
  end

  defp resolve_any_attr(attrs, value_ast, seen) do
    Enum.reduce_while(attrs, {:error, "no @max_runs definition resolved"}, fn attr, _acc ->
      case classify_max_runs(attr, attrs, [value_ast | seen]) do
        :ok -> {:halt, :ok}
        error -> {:cont, error}
      end
    end)
  end

  defp range_result(n, range, label) do
    if n in range, do: :ok, else: {:error, "#{label} #{n} is outside #{inspect(range)}"}
  end

  defp check_violation(path, {line, args}, attrs) do
    case extract_max_runs(args) do
      :missing ->
        ["#{path}:#{line}: check all(...) has no max_runs:"]

      {:ok, value_ast} ->
        case classify_max_runs(value_ast, attrs) do
          :ok -> []
          {:error, reason} -> ["#{path}:#{line}: #{reason}"]
        end
    end
  end

  defp source_violations_for(path, source) do
    case Code.string_to_quoted(source) do
      {:ok, ast} ->
        attrs = collect_max_runs_attrs(ast)
        ast |> collect_checks() |> Enum.flat_map(&check_violation(path, &1, attrs))

      {:error, _loc, message} ->
        ["#{path}: could not parse as Elixir source (#{message})"]
    end
  end

  @doc false
  def source_violations(path_to_source) do
    Enum.flat_map(path_to_source, fn {path, source} -> source_violations_for(path, source) end)
  end

  defp property_test_sources do
    @repo_root
    |> Path.join("test/**/*_property_test.exs")
    |> Path.wildcard()
    |> Map.new(fn path -> {path, File.read!(path)} end)
  end

  describe "every property's max_runs: routes through PropertyRuns (D-10, D-11c)" do
    test "every check all(...) in test/**/*_property_test.exs is in range" do
      sources = property_test_sources()

      assert map_size(sources) >= 6,
             "expected at least 6 *_property_test.exs files, found #{map_size(sources)}"

      assert source_violations(sources) == []
    end

    @fixture_valid """
    defmodule FixtureValid do
      use ExUnitProperties
      alias Threadline.Test.PropertyRuns

      property "p" do
        check all(x <- gen(), max_runs: PropertyRuns.pure(200)) do
          :ok
        end
      end
    end
    """

    @fixture_literal_300 """
    defmodule FixtureBadLiteral do
      use ExUnitProperties

      property "p" do
        check all(x <- gen(), max_runs: 300) do
          :ok
        end
      end
    end
    """

    @fixture_missing_max_runs """
    defmodule FixtureMissingMaxRuns do
      use ExUnitProperties

      property "p" do
        check all(x <- gen()) do
          :ok
        end
      end
    end
    """

    test "mutation controls: a fixture source with a bare literal max_runs is caught" do
      refute @fixture_literal_300 == @fixture_valid, "control did not change the input"

      assert source_violations(%{"fixture_300.exs" => @fixture_valid}) == []

      assert source_violations(%{"fixture_300.exs" => @fixture_literal_300}) != [],
             "a literal max_runs: 300 (not routed through PropertyRuns) must be a violation"
    end

    test "mutation controls: a fixture source with no max_runs at all is caught" do
      refute @fixture_missing_max_runs == @fixture_valid, "control did not change the input"

      assert source_violations(%{"fixture_missing.exs" => @fixture_missing_max_runs}) != [],
             "a check all(...) with no max_runs: at all must be a violation"
    end
  end

  # ---------------------------------------------------------------------
  # (d) CONTRIBUTING.md names the variable
  # ---------------------------------------------------------------------

  describe "CONTRIBUTING.md documents the knob (D-13, D-11d)" do
    test "CONTRIBUTING.md names THREADLINE_PROPERTY_SCALE" do
      assert File.read!(@contributing_path) =~ @env_var
    end
  end
end
