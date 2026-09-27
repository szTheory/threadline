defmodule Threadline.CiAllDedupContractTest do
  @moduledoc """
  Guards `ci.all` against running the same test files twice and against a second,
  hand-listed definition of which contract tests matter.

  `mix test` file discovery (every `*_test.exs` under `test/`), run by `verify.test`,
  is the single definition of the default suite. This contract reads the alias tree at
  runtime from `Threadline.MixProject.project()[:aliases]` (never a regex over `mix.exs`)
  and expands string aliases recursively, treating function-capture aliases as opaque.

  One exemption: a ci.all test leaf that is `test <one _test.exs path> --only TAG`, with
  exactly one `--only`, no `--include`, and TAG among the tags `test/test_helper.exs`
  excludes by default, is not a duplicate run. It selects only tests `verify.test` never
  runs. The excluded tags are read from the `:default_test_excludes` app-env key the
  helper writes, which Mix CLI filters (a `file:LINE` path, `--only`, `--exclude`) cannot
  overwrite, unlike ExUnit's live exclude list. Today that leaf is
  `verify.dialyzer_slice`, which must run after the dev PLT exists.
  """
  use ExUnit.Case, async: true

  # Assembled so this file's own text never contains the retired alias name as a literal.
  @retired_alias "verify." <> "doc_contract"

  describe "the live alias tree" do
    test "the retired hand-listed doc-contract alias does not exist" do
      assert validate_retired_absent(aliases()) == :ok
    end

    test "exactly one ci.all step, verify.test, runs test files" do
      assert validate_single_test_step(aliases(), default_excluded_tags()) == :ok
    end

    test "no alias is a test command over two or more explicit .exs paths" do
      assert validate_no_multi_path_test(aliases()) == :ok
    end

    test "ci.all is non-empty and contains verify.test" do
      assert validate_ci_all_present(aliases()) == :ok
    end
  end

  describe "detector self-test (synthetic alias trees)" do
    test "a ci.all with two test-running steps is rejected, naming both chains" do
      synthetic = [
        "verify.test": ["test"],
        "verify.extra": ["test test/a_test.exs"],
        "ci.all": ["verify.format", "verify.test", "verify.extra"],
        "verify.format": ["format --check-formatted"]
      ]

      assert {:error, msg} = validate_single_test_step(synthetic, [])
      assert msg =~ "ci.all -> verify.test"
      assert msg =~ "ci.all -> verify.extra"
    end

    test "a test-running step reached through `cmd env … mix TASK` is still counted" do
      synthetic = [
        "verify.test": ["test"],
        "verify.hidden": ["test test/a_test.exs"],
        "ci.all": ["verify.test", "cmd env MIX_ENV=test mix verify.hidden"]
      ]

      assert {:error, msg} = validate_single_test_step(synthetic, [])
      assert msg =~ "verify.hidden"
    end

    test "a ci.all whose only test step is not verify.test is rejected" do
      synthetic = ["verify.other": ["test"], "ci.all": ["verify.other"]]

      assert {:error, msg} = validate_single_test_step(synthetic, [])
      assert msg =~ "verify.test"
    end

    test "function-capture aliases are opaque leaves" do
      synthetic = [
        "verify.test": ["test"],
        "verify.example": &Function.identity/1,
        "ci.all": ["verify.test", "verify.example"]
      ]

      assert validate_single_test_step(synthetic, []) == :ok
    end

    test "an alias listing two explicit .exs paths is rejected" do
      synthetic = [x: ["test a_test.exs b_test.exs"], "ci.all": ["verify.test"]]

      assert {:error, msg} = validate_no_multi_path_test(synthetic)
      assert msg =~ "x"
      assert msg =~ "a_test.exs"
    end

    test "a single-path focused test alias is allowed" do
      synthetic = ["verify.focused": ["test test/a_test.exs"]]

      assert validate_no_multi_path_test(synthetic) == :ok
    end

    test "the retired alias reappearing is rejected" do
      synthetic = [{@retired_alias, ["test a_test.exs"]}]

      assert {:error, msg} = validate_retired_absent(synthetic)
      assert msg =~ @retired_alias
    end

    test "an empty or missing ci.all is rejected" do
      assert {:error, _} = validate_ci_all_present("ci.all": [])
      assert {:error, _} = validate_ci_all_present("verify.test": ["test"])
      assert {:error, _} = validate_ci_all_present("ci.all": ["verify.format"])
    end

    test "a single-file --only leaf over a default-excluded tag is not a duplicate run" do
      assert validate_single_test_step(slice_tree("test test/a_test.exs --only live_dialyzer"), [
               "live_dialyzer"
             ]) == :ok
    end

    test "the same leaf is rejected when its tag is not default-excluded" do
      assert {:error, msg} =
               validate_single_test_step(
                 slice_tree("test test/a_test.exs --only live_dialyzer"),
                 []
               )

      assert msg =~ "verify.slice"
    end

    test "an --only leaf over a tag that is not default-excluded is rejected" do
      assert {:error, msg} =
               validate_single_test_step(
                 slice_tree("test test/a_test.exs --only other_tag"),
                 ["live_dialyzer"]
               )

      assert msg =~ "verify.slice"
    end

    test "--include in place of --only is rejected" do
      assert {:error, msg} =
               validate_single_test_step(
                 slice_tree("test test/a_test.exs --include live_dialyzer"),
                 ["live_dialyzer"]
               )

      assert msg =~ "verify.slice"
    end

    test "a single-file leaf without --only is rejected" do
      assert {:error, msg} =
               validate_single_test_step(slice_tree("test test/a_test.exs"), ["live_dialyzer"])

      assert msg =~ "verify.slice"
    end

    test "a second --only naming a non-excluded tag is rejected" do
      assert {:error, msg} =
               validate_single_test_step(
                 slice_tree("test test/a_test.exs --only live_dialyzer --only other_tag"),
                 ["live_dialyzer"]
               )

      assert msg =~ "verify.slice"
    end

    test "two paths plus --only over an excluded tag is rejected" do
      assert {:error, msg} =
               validate_single_test_step(
                 slice_tree("test test/a_test.exs test/b_test.exs --only live_dialyzer"),
                 ["live_dialyzer"]
               )

      assert msg =~ "verify.slice"
    end

    test "a TAG:value --only form compares the tag before the value" do
      assert validate_single_test_step(
               slice_tree("test test/a_test.exs --only live_dialyzer:true"),
               ["live_dialyzer"]
             ) == :ok
    end

    test "excluded_tag_names normalizes tuple and bare-atom exclude entries" do
      names = excluded_tag_names([:test, {:live_dialyzer, true}])

      assert names == ["test", "live_dialyzer"]

      assert validate_single_test_step(
               slice_tree("test test/a_test.exs --only live_dialyzer"),
               names
             ) == :ok
    end

    test "excluded_tag_names raises on an unknown exclude shape" do
      assert_raise FunctionClauseError, fn -> excluded_tag_names(["live_dialyzer"]) end
    end

    test "an alias cycle raises instead of looping" do
      synthetic = ["a.b": ["c.d"], "c.d": ["a.b"], "ci.all": ["a.b"]]

      assert_raise ArgumentError, ~r/cycle/, fn -> validate_single_test_step(synthetic, []) end
    end
  end

  test "this contract never references the planning directory" do
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  defp aliases, do: Threadline.MixProject.project()[:aliases]

  # test/test_helper.exs stores the one exclude binding it passes to ExUnit under this
  # app-env key. ExUnit's live exclude list is not read here: Mix's `test` task
  # re-configures it after the helper runs (for `mix test path_test.exs:LINE` it becomes
  # `[:test]`), so it cannot be trusted to hold the suite's default excludes.
  # `fetch_env!` raises when the key is unset, so a helper that stops writing it fails
  # loudly instead of silently rejecting the exemption.
  defp default_excluded_tags,
    do: excluded_tag_names(Application.fetch_env!(:threadline, :default_test_excludes))

  # The two shapes an exclude list holds: `{tag, value}` tuples and bare atoms (what
  # `--exclude slow` and line filters produce). Anything else raises on purpose.
  defp excluded_tag_names(excludes), do: Enum.map(excludes, &excluded_tag_name/1)

  defp excluded_tag_name({tag, _value}) when is_atom(tag), do: to_string(tag)
  defp excluded_tag_name(tag) when is_atom(tag), do: to_string(tag)

  defp slice_tree(leaf) do
    [
      "verify.test": ["test"],
      "verify.slice": [leaf],
      "ci.all": ["verify.test", "cmd env MIX_ENV=test mix verify.slice"]
    ]
  end

  # Alias names are compared as strings so the synthetic trees in the self-test need no
  # dynamically built atoms.
  defp names(aliases), do: Enum.map(aliases, fn {name, _entries} -> to_string(name) end)

  defp lookup(aliases, name) do
    Enum.find_value(aliases, :error, fn {key, entries} ->
      if to_string(key) == name, do: {:ok, entries}
    end)
  end

  defp ci_all_steps(aliases) do
    case lookup(aliases, "ci.all") do
      {:ok, steps} -> List.wrap(steps)
      :error -> []
    end
  end

  defp validate_retired_absent(aliases) do
    if @retired_alias in names(aliases) do
      {:error,
       "mix.exs defines #{@retired_alias} again: a hand-listed test subset is a second, " <>
         "drift-prone definition of which contract tests matter; `verify.test` runs them all"}
    else
      :ok
    end
  end

  defp validate_ci_all_present(aliases) do
    steps = ci_all_steps(aliases)

    cond do
      steps == [] ->
        {:error, "ci.all is missing or empty, so every guard over it would pass vacuously"}

      "verify.test" not in steps ->
        {:error, "ci.all must contain verify.test, got: #{inspect(steps)}"}

      true ->
        :ok
    end
  end

  defp validate_single_test_step(aliases, excluded_tags) do
    steps = ci_all_steps(aliases)

    test_steps =
      for step <- steps,
          chains = test_chains(step, aliases),
          chains != [],
          not Enum.all?(chains, &disjoint_tagged_leaf?(List.last(&1), excluded_tags)),
          do: {step, chains}

    case test_steps do
      [{"verify.test", _}] ->
        :ok

      other ->
        detail =
          other
          |> Enum.flat_map(fn {_step, chains} -> chains end)
          |> Enum.map_join("\n  ", &Enum.join(["ci.all" | &1], " -> "))

        {:error,
         "exactly one ci.all step (verify.test) may expand to a `test` command; found " <>
           "#{length(other)}:\n  #{detail}"}
    end
  end

  defp validate_no_multi_path_test(aliases) do
    offenders =
      for {name, entries} <- aliases,
          is_list(entries),
          entry <- entries,
          is_binary(entry),
          test_command?(entry),
          paths = entry |> String.split() |> Enum.filter(&String.ends_with?(&1, ".exs")),
          length(paths) >= 2,
          do: "#{name}: #{Enum.join(paths, " ")}"

    if offenders == [] do
      :ok
    else
      {:error,
       "an alias runs `test` over a hand-listed set of files, which drifts from " <>
         "`mix test` discovery:\n  " <> Enum.join(offenders, "\n  ")}
    end
  end

  # Returns every alias chain from `step` that ends in a `test` command. Each chain is
  # the list of alias names walked, ending with the leaf command.
  defp test_chains(step, aliases) do
    step
    |> expand(aliases, [])
    |> Enum.filter(fn {_chain, leaf} -> is_binary(leaf) and test_command?(leaf) end)
    |> Enum.map(fn {chain, leaf} -> chain ++ [leaf] end)
  end

  # Expands one alias step into `{chain, leaf}` pairs. A string whose first word is an
  # alias key recurses into that alias; `cmd … mix TASK args` recurses on `TASK args`;
  # a function capture is an opaque leaf; anything else is a leaf command.
  defp expand(step, _aliases, seen) when is_function(step), do: [{Enum.reverse(seen), :opaque}]

  defp expand(step, aliases, seen) when is_binary(step) do
    [head | rest] = String.split(step)

    cond do
      head == "cmd" ->
        case Enum.drop_while(rest, &(&1 != "mix")) do
          ["mix", task | args] -> expand(Enum.join([task | args], " "), aliases, seen)
          _ -> [{Enum.reverse(seen), step}]
        end

      head in seen ->
        raise ArgumentError, "alias cycle: #{Enum.join(Enum.reverse([head | seen]), " -> ")}"

      true ->
        case lookup(aliases, head) do
          {:ok, entries} ->
            entries |> List.wrap() |> Enum.flat_map(&expand(&1, aliases, [head | seen]))

          :error ->
            [{Enum.reverse(seen), step}]
        end
    end
  end

  defp test_command?(command), do: hd(String.split(command)) == "test"

  # A leaf that selects only tests `verify.test` never runs: `test`, exactly one
  # `_test.exs` path and exactly one `--only TAG` pair (TAG compared before any `:value`
  # suffix), nothing else, no `--include`, and TAG default-excluded by the test helper.
  defp disjoint_tagged_leaf?(leaf, excluded_tags) do
    case String.split(leaf) do
      ["test" | rest] ->
        paths = Enum.filter(rest, &String.ends_with?(&1, "_test.exs"))
        only_tags = only_tags(rest)

        length(rest) == 3 and length(paths) == 1 and "--include" not in rest and
          match?([_], only_tags) and
          (only_tags |> hd() |> String.split(":") |> hd()) in excluded_tags

      _ ->
        false
    end
  end

  defp only_tags(["--only", tag | rest]), do: [tag | only_tags(rest)]
  defp only_tags([_ | rest]), do: only_tags(rest)
  defp only_tags([]), do: []
end
