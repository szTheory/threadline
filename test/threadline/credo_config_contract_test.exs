defmodule Threadline.CredoConfigContractTest do
  @moduledoc """
  Source-resident contract for Credo config comments.

  The structural register counts every per-site Credo suppression of
  `Credo.Check.Refactor.Nesting` and `Credo.Check.Refactor.CyclomaticComplexity`
  in `lib/` and `test/`. Each site carries a `# Structural debt: <reason>` line
  directly above its per-line disable, and the register names the successor that
  drains it: Phase 204 (STRUCT-07), which ratchets the register toward 0.

  The scanned count must equal the register exactly. A ceiling alone would leave
  slack: fixing one site in place would let a new, unreviewed disable land in the
  freed slot. Exact equality means adding a disable fails until the register is
  raised in a reviewed diff, and removing one fails until the register is lowered
  to match. `@ceiling` is the register sum, and it may never exceed the literal
  `@historical_max`.

  Discovery mirrors Credo: only real comments are read (via
  `Code.string_to_quoted_with_comments/1`), matched with Credo's own config-comment
  regex. Synthetic negative sources below are string literals, so neither Credo nor
  this scan treats them as suppressions.
  """

  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @scan_glob "{lib,test}/**/*.{ex,exs}"

  @successor "Phase 204 / STRUCT-07"
  @register %{
    Credo.Check.Refactor.Nesting => {25, "Phase 204 / STRUCT-07"},
    Credo.Check.Refactor.CyclomaticComplexity => {16, "Phase 204 / STRUCT-07"}
  }
  @ceiling 41
  @historical_max 46

  @registered_checks [Credo.Check.Refactor.CyclomaticComplexity, Credo.Check.Refactor.Nesting]
  @allowed_instruction "disable-for-next-line"
  @debt_prefix "# Structural debt: "
  # Assembled so this file's own text never contains a literal suppression comment.
  @comment_head "# " <> "credo:"
  @ratchet_message "fix it (prefer `with`/early return); adding a disable requires raising the register in review."

  describe "structural register (GATE-02)" do
    test "the real tree matches the register exactly and the ceiling is pinned" do
      files = scanned_files()

      assert :ok = validate_register(files, @register, @ceiling)

      assert @ceiling == @register |> Map.values() |> Enum.map(&elem(&1, 0)) |> Enum.sum()
      assert @ceiling <= @historical_max
      assert @historical_max == 46

      assert Enum.all?(Map.values(@register), fn {_count, successor} ->
               successor == @successor
             end)

      planning_directory = "." <> "planning"
      refute File.read!(__ENV__.file) =~ planning_directory
    end

    test "one extra or one missing disable fails exact equality" do
      {nesting, _} = Map.fetch!(@register, Credo.Check.Refactor.Nesting)
      {complexity, _} = Map.fetch!(@register, Credo.Check.Refactor.CyclomaticComplexity)

      exact = [
        synthetic("lib/nesting.ex", List.duplicate(pair("Nesting"), nesting)),
        synthetic("lib/complexity.ex", List.duplicate(pair("CyclomaticComplexity"), complexity))
      ]

      assert :ok = validate_register(exact, @register, @ceiling)

      extra = exact ++ [synthetic("lib/extra.ex", [pair("Nesting")])]
      assert {:error, message} = validate_register(extra, @register, @ceiling)
      assert message =~ "adding a disable requires raising the register in review"
      assert message =~ "scanned #{nesting + 1}"

      missing = [
        synthetic("lib/nesting.ex", List.duplicate(pair("Nesting"), nesting - 1)),
        synthetic("lib/complexity.ex", List.duplicate(pair("CyclomaticComplexity"), complexity))
      ]

      assert {:error, message} = validate_register(missing, @register, @ceiling)
      assert message =~ "adding a disable requires raising the register in review"
      assert message =~ "scanned #{nesting - 1}"
    end

    test "every other config-comment form is rejected" do
      register = zero_register()

      forms = [
        "disable-for-this-file",
        "disable-for-lines:3 Credo.Check.Refactor.Nesting",
        "disable-for-previous-line Credo.Check.Refactor.Nesting",
        "disable-for-next-line",
        "disable-for-next-line Credo.Check.Readability.ModuleDoc",
        "disable-for-next-line Credo.Check.Refactor.Nesting extract later",
        "enable-for-next-line Credo.Check.Refactor.Nesting",
        "enable-for-rest-of-file"
      ]

      for form <- forms do
        source =
          synthetic("lib/form.ex", ["    #{@debt_prefix}reason\n    #{@comment_head}#{form}\n"])

        assert {:error, message} = validate_register([source], register, 0),
               "expected #{inspect(form)} to be rejected"

        assert message =~ "lib/form.ex:"
        assert message =~ "only the per-line form"
      end
    end

    test "a disable without an adjacent Structural debt line fails" do
      register = register_with(1, 0)

      blank_gap = "    #{@debt_prefix}reason\n\n    #{disable("Nesting")}\n"
      wrong_prefix = "    # Debt: reason\n    #{disable("Nesting")}\n"
      empty_reason = "    # Structural debt:   \n    #{disable("Nesting")}\n"
      no_line = "    #{disable("Nesting")}\n"

      for body <- [blank_gap, wrong_prefix, empty_reason, no_line] do
        assert {:error, message} =
                 validate_register([synthetic("lib/adjacent.ex", [body])], register, 1),
               "expected #{inspect(body)} to fail adjacency"

        assert message =~ "Structural debt"
        assert message =~ "lib/adjacent.ex:"
      end
    end

    test "an empty scan fails, and a zero-disable scan validates against a zero register" do
      assert {:error, message} = validate_register([], zero_register(), 0)
      assert message =~ "scanned file set is empty"

      clean = [synthetic("lib/clean.ex", [])]
      assert :ok = validate_register(clean, zero_register(), 0)
      assert {:error, _message} = validate_register(clean, register_with(1, 0), 1)
    end

    test "the register shape, ceiling sum, and historical max are enforced" do
      clean = [synthetic("lib/clean.ex", [])]

      assert {:error, message} = validate_register(clean, zero_register(), 1)
      assert message =~ "ceiling"

      over = register_with(@historical_max + 1, 0)
      assert {:error, message} = validate_register(clean, over, @historical_max + 1)
      assert message =~ "historical max"

      unnamed = Map.put(zero_register(), Credo.Check.Refactor.Nesting, {0, ""})
      assert {:error, message} = validate_register(clean, unnamed, 0)
      assert message =~ "successor"

      extra_check = Map.put(zero_register(), Credo.Check.Readability.ModuleDoc, {0, @successor})
      assert {:error, message} = validate_register(clean, extra_check, 0)
      assert message =~ "exactly"
    end

    test "offenders are listed sorted by path and line" do
      files = [
        synthetic("test/b.exs", ["    #{disable("Nesting")}\n"]),
        synthetic("lib/z.ex", ["    #{disable("Nesting")}\n", "    #{disable("Nesting")}\n"]),
        synthetic("lib/a.ex", ["    #{disable("Nesting")}\n"])
      ]

      assert {:error, message} = validate_register(files, register_with(4, 0), 4)

      offenders = Regex.scan(~r/(lib|test)\/[a-z]+\.exs?:\d+/, message) |> Enum.map(&hd/1)
      assert offenders == ["lib/a.ex:3", "lib/z.ex:3", "lib/z.ex:4", "test/b.exs:3"]
    end

    test "validation is a pure function of source text and a doubled pair counts twice" do
      doubled = [synthetic("lib/doubled.ex", [pair("Nesting"), pair("Nesting")])]

      first = validate_register(doubled, register_with(1, 0), 1)
      assert first == validate_register(doubled, register_with(1, 0), 1)
      assert {:error, message} = first
      assert message =~ "scanned 2"

      assert :ok = validate_register(doubled, register_with(2, 0), 2)
    end

    test "suppression text inside a string literal is invisible to the scan" do
      literal = "    _ = #{inspect(disable("Nesting"))}\n"

      assert :ok = validate_register([synthetic("lib/literal.ex", [literal])], zero_register(), 0)
    end
  end

  defp scanned_files do
    @root
    |> Path.join(@scan_glob)
    |> Path.wildcard()
    |> Enum.map(&{Path.relative_to(&1, @root), File.read!(&1)})
  end

  defp validate_register(files, register, ceiling) do
    demand!(
      files != [],
      "the scanned file set is empty. A broken #{@scan_glob} glob would let this " <>
        "register pass vacuously, which is worse than having no gate at all."
    )

    validate_register_shape!(register, ceiling)

    entries =
      files
      |> Enum.flat_map(fn {path, source} -> config_comments!(path, source) end)
      |> Enum.sort_by(&{&1.path, &1.line})

    reject_offenders!(
      Enum.reject(entries, &(&1.check != nil)),
      "only the per-line form `#{@allowed_instruction} Credo.Check.Refactor.Nesting` or " <>
        "`#{@allowed_instruction} Credo.Check.Refactor.CyclomaticComplexity`, with nothing " <>
        "after the check name, is allowed"
    )

    reject_offenders!(
      Enum.reject(entries, & &1.annotated?),
      "each disable needs a `#{@debt_prefix}<reason>` line directly above it, with a " <>
        "non-empty reason"
    )

    counts = Enum.frequencies_by(entries, & &1.check)

    for check <- @registered_checks do
      {expected, successor} = Map.fetch!(register, check)
      actual = Map.get(counts, check, 0)

      demand!(
        actual == expected,
        "#{inspect(check)}: scanned #{actual} per-site disables, the register " <>
          "(#{successor}) says #{expected}. " <> @ratchet_message
      )
    end

    :ok
  catch
    {:contract_error, message} -> {:error, message}
  end

  defp validate_register_shape!(register, ceiling) do
    demand!(
      is_map(register) and Enum.sort(Map.keys(register)) == @registered_checks,
      "the register must name exactly #{inspect(@registered_checks)}"
    )

    for {check, value} <- register do
      demand!(
        match?({count, _} when is_integer(count) and count >= 0, value),
        "#{inspect(check)}: the register count must be a non-negative integer"
      )

      {_count, successor} = value

      demand!(
        is_binary(successor) and String.trim(successor) != "",
        "#{inspect(check)}: the register must name a successor"
      )
    end

    sum = register |> Map.values() |> Enum.map(&elem(&1, 0)) |> Enum.sum()

    demand!(
      is_integer(ceiling) and ceiling == sum,
      "the ceiling #{inspect(ceiling)} must equal the register sum #{sum}"
    )

    demand!(
      ceiling <= @historical_max,
      "the ceiling #{ceiling} exceeds the historical max of #{@historical_max}"
    )
  end

  defp config_comments!(path, source) do
    with true <- source =~ config_comment_format(),
         {:ok, _ast, comments} <- Code.string_to_quoted_with_comments(source) do
      lines = String.split(source, "\n")

      for %{text: text, line: line} <- comments,
          [_, instruction, params] <- [Regex.run(config_comment_format(), text)] do
        %{
          path: path,
          line: line,
          check: registered_check(instruction, params),
          annotated?: annotated?(lines, line)
        }
      end
    else
      false ->
        []

      {:error, _reason} ->
        fail!("#{path} does not parse, so its config comments cannot be verified")
    end
  end

  defp registered_check(@allowed_instruction, params) do
    Enum.find(@registered_checks, &(params == inspect(&1)))
  end

  defp registered_check(_instruction, _params), do: nil

  defp annotated?(_lines, line) when line < 2, do: false

  defp annotated?(lines, line) do
    case lines |> Enum.at(line - 2, "") |> String.trim_leading() do
      @debt_prefix <> reason -> String.trim(reason) != ""
      _other -> false
    end
  end

  defp reject_offenders!([], _rule), do: :ok

  defp reject_offenders!(offenders, rule) do
    listed = Enum.map_join(offenders, ", ", &"#{&1.path}:#{&1.line}")
    fail!("#{rule}. Offenders: #{listed}. " <> @ratchet_message)
  end

  # Credo's own config-comment regex (Credo.Check.ConfigCommentFinder).
  defp config_comment_format, do: ~r/#\s*credo\:([\w\-\:]+)\s*(.*)/im

  defp zero_register, do: register_with(0, 0)

  defp register_with(nesting, complexity) do
    %{
      Credo.Check.Refactor.Nesting => {nesting, @successor},
      Credo.Check.Refactor.CyclomaticComplexity => {complexity, @successor}
    }
  end

  defp disable(check), do: "#{@comment_head}#{@allowed_instruction} Credo.Check.Refactor.#{check}"

  defp pair(check), do: "    #{@debt_prefix}extract the nested branch\n    #{disable(check)}\n"

  defp synthetic(path, bodies) do
    {path,
     "defmodule Synthetic do\n  def run(x) do\n" <> Enum.join(bodies) <> "    x\n  end\nend\n"}
  end

  defp demand!(true, _message), do: :ok
  defp demand!(false, message), do: fail!(message)
  defp fail!(message), do: throw({:contract_error, message})
end
