defmodule Threadline.CredoConfigContractTest do
  @moduledoc """
  Source-resident contract for the Credo config and its config comments.

  The config shape half pins `.credo.exs` as upstream scaffolding plus exactly
  three `extra:` deltas over Credo's embedded defaults, with `disabled: []` and no
  `enabled:` key, so the default check set can never be replaced or quietly shrunk.

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

  alias Credo.Check.Params

  @root Path.expand("../..", __DIR__)
  @scan_glob "{lib,test}/**/*.{ex,exs}"

  @successor "Phase 204 / STRUCT-07"
  @register %{
    Credo.Check.Refactor.Nesting => {19, "Phase 204 / STRUCT-07"},
    Credo.Check.Refactor.CyclomaticComplexity => {9, "Phase 204 / STRUCT-07"}
  }
  @ceiling 28
  @historical_max 46

  @registered_checks [Credo.Check.Refactor.CyclomaticComplexity, Credo.Check.Refactor.Nesting]
  @allowed_instruction "disable-for-next-line"
  @debt_prefix "# Structural debt: "
  # Assembled so this file's own text never contains a literal suppression comment.
  @comment_head "# " <> "credo:"
  @ratchet_message "fix it (prefer `with`/early return); adding a disable requires raising the register in review."

  @credo_config Path.join(@root, ".credo.exs")
  @upstream_config Path.join([Mix.Project.deps_path(), "credo", ".credo.exs"])

  # The only deltas over Credo's embedded defaults, compared exactly and in order.
  @deltas [
    {Credo.Check.Design.TagTODO, [exit_status: 0]},
    {Credo.Check.Readability.ModuleDoc, [ignore_names: [], ignore_modules_using: []]},
    {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
     [
       metadata_keys: [
         :deleted_changes,
         :deleted_transactions,
         :batch,
         :total_changes,
         :total_transactions
       ]
     ]}
  ]
  @min_default_checks 69
  # Delta param keys may be the check's own params or these Credo builtins (exit_status etc.).
  @credo_builtin_params [:category, :exit_status, :files, :priority, :tags]
  @header_version ~r/^# Scaffolding copied from credo (\S+) deps\/credo\/\.credo\.exs; checks are deltas over Credo's embedded defaults — do not add enabled:$/m

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

  describe "config shape (GATE-01)" do
    test "the config source has no :enabled key anywhere" do
      ast = @credo_config |> File.read!() |> Code.string_to_quoted!()

      {_ast, enabled_keys} =
        Macro.prewalk(ast, [], fn
          {{:__block__, _, [:enabled]}, _value} = node, acc -> {node, [node | acc]}
          {:enabled, _value} = node, acc -> {node, [node | acc]}
          node, acc -> {node, acc}
        end)

      assert enabled_keys == [],
             "`.credo.exs` must not contain an `enabled:` key: it replaces Credo's " <>
               "embedded defaults wholesale, so the gate would lint almost nothing (GATE-01)."
    end

    test "the evaluated config is strict, deltas-only, and disables nothing" do
      %{checks: checks} = config = project_config()

      assert config.strict == true
      assert Map.keys(checks) -- [:extra, :disabled] == []

      assert Map.get(checks, :disabled) == [],
             "`disabled:` must be `[]` (GATE-01): a listed check is silently dropped from " <>
               "the gate, including a default that a Credo release promotes."

      assert Map.get(checks, :extra) == @deltas
    end

    test "the non-checks scaffolding equals upstream except strict" do
      {%{configs: [upstream]} = upstream_top, _binding} = Code.eval_file(@upstream_config)
      {project_top, _binding} = Code.eval_file(@credo_config)
      config = project_config()

      assert Map.keys(project_top) == Map.keys(upstream_top)

      # A shrunk `files:` (dropping test/, or an `excluded:` subtree), a plugin that
      # injects or alters checks, or a required custom check would all narrow the
      # gate without touching `checks:`, so every non-checks key is pinned to the
      # upstream scaffolding. Regexes are compared by source and options because
      # compiled patterns are not guaranteed to compare equal across OTP releases.
      assert config.name == "default"
      assert config.plugins == []
      assert config.requires == []

      assert normalize_regexes(config.files) == normalize_regexes(upstream.files),
             "`files:` must equal the upstream scaffolding: narrowing `included:` or " <>
               "widening `excluded:` silently removes code from the gate (GATE-01)."

      # `strict` is the one legitimate divergence: upstream ships `false`, and the
      # project pins `true` so bare `mix credo` equals the CI gate.
      assert config.strict == true

      assert normalize_regexes(Map.drop(config, [:checks, :strict])) ==
               normalize_regexes(Map.drop(upstream, [:checks, :strict]))
    end

    test "every delta re-parameterizes an upstream default and the default set is not shrunk" do
      upstream = upstream_checks()
      enabled = Enum.map(upstream.enabled, &elem(&1, 0))
      disabled = Enum.map(upstream.disabled, &elem(&1, 0))

      assert length(enabled) >= @min_default_checks

      for {mod, _params} <- @deltas do
        assert mod in enabled, "#{inspect(mod)} is not an upstream default check"
        refute mod in disabled, "#{inspect(mod)} is an upstream opt-in check"
      end
    end

    test "every delta param key is a check param or a pinned Credo builtin" do
      assert @credo_builtin_params -- Params.builtin_param_names() == []

      for delta <- @deltas do
        assert :ok = validate_delta_params(delta)
      end

      assert {:error, message} =
               validate_delta_params({Credo.Check.Design.TagTODO, [exit_statuss: 0]})

      assert message =~ "exit_statuss"
    end

    test "the header cites the loaded Credo version" do
      case Application.load(:credo) do
        :ok -> :ok
        {:error, {:already_loaded, :credo}} -> :ok
      end

      loaded = to_string(Application.spec(:credo, :vsn))

      header =
        @credo_config |> File.read!() |> String.split("\n") |> Enum.take(3) |> Enum.join("\n")

      assert [_, cited] = Regex.run(@header_version, header),
             "`.credo.exs` must open with the scaffolding header comment"

      assert cited == loaded,
             "`.credo.exs` cites credo #{cited} but #{loaded} is loaded: " <>
               "re-diff the scaffolding and bump the header"
    end

    test "the verify.credo alias is pinned" do
      assert @root |> Path.join("mix.exs") |> File.read!() =~
               ~s("verify.credo": ["credo --strict"])
    end
  end

  defp project_config do
    {%{configs: configs}, _binding} = Code.eval_file(@credo_config)
    assert [config] = configs
    config
  end

  defp normalize_regexes(%Regex{} = regex), do: {:regex, Regex.source(regex), Regex.opts(regex)}

  defp normalize_regexes(%{} = map), do: Map.new(map, fn {k, v} -> {k, normalize_regexes(v)} end)

  defp normalize_regexes(list) when is_list(list), do: Enum.map(list, &normalize_regexes/1)
  defp normalize_regexes(other), do: other

  defp upstream_checks do
    {%{configs: [%{checks: checks}]}, _binding} = Code.eval_file(@upstream_config)
    checks
  end

  defp validate_delta_params({mod, params}) do
    Code.ensure_loaded!(mod)

    case Keyword.keys(params) -- (mod.param_names() ++ @credo_builtin_params) do
      [] -> :ok
      unknown -> {:error, "#{inspect(mod)} has unknown params #{inspect(unknown)}"}
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
