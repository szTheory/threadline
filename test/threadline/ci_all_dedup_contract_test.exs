defmodule Threadline.CiAllDedupContractTest do
  @moduledoc """
  Guards `ci.all` against running the same test files twice and against a second,
  hand-listed definition of which contract tests matter.

  `mix test` file discovery (every `*_test.exs` under `test/`), run by `verify.test`,
  is the single definition. This contract reads the alias tree at runtime from
  `Threadline.MixProject.project()[:aliases]` (never a regex over `mix.exs`) and
  expands string aliases recursively, treating function-capture aliases as opaque.
  """
  use ExUnit.Case, async: true

  # Assembled so this file's own text never contains the retired alias name as a literal.
  @retired_alias "verify." <> "doc_contract"

  describe "the live alias tree" do
    test "the retired hand-listed doc-contract alias does not exist" do
      assert validate_retired_absent(aliases()) == :ok
    end

    test "exactly one ci.all step, verify.test, runs test files" do
      assert validate_single_test_step(aliases()) == :ok
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

      assert {:error, msg} = validate_single_test_step(synthetic)
      assert msg =~ "ci.all -> verify.test"
      assert msg =~ "ci.all -> verify.extra"
    end

    test "a test-running step reached through `cmd env … mix TASK` is still counted" do
      synthetic = [
        "verify.test": ["test"],
        "verify.hidden": ["test test/a_test.exs"],
        "ci.all": ["verify.test", "cmd env MIX_ENV=test mix verify.hidden"]
      ]

      assert {:error, msg} = validate_single_test_step(synthetic)
      assert msg =~ "verify.hidden"
    end

    test "a ci.all whose only test step is not verify.test is rejected" do
      synthetic = ["verify.other": ["test"], "ci.all": ["verify.other"]]

      assert {:error, msg} = validate_single_test_step(synthetic)
      assert msg =~ "verify.test"
    end

    test "function-capture aliases are opaque leaves" do
      synthetic = [
        "verify.test": ["test"],
        "verify.example": &Function.identity/1,
        "ci.all": ["verify.test", "verify.example"]
      ]

      assert validate_single_test_step(synthetic) == :ok
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

    test "an alias cycle raises instead of looping" do
      synthetic = ["a.b": ["c.d"], "c.d": ["a.b"], "ci.all": ["a.b"]]

      assert_raise ArgumentError, ~r/cycle/, fn -> validate_single_test_step(synthetic) end
    end
  end

  test "this contract never references the planning directory" do
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  defp aliases, do: Threadline.MixProject.project()[:aliases]

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

  defp validate_single_test_step(aliases) do
    steps = ci_all_steps(aliases)

    test_steps =
      for step <- steps,
          chains = test_chains(step, aliases),
          chains != [],
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
end
