defmodule Threadline.SourceSizeContractTest do
  @moduledoc """
  Size and structure contract for `lib/`.

  Four rules, each enforced against the real tree and proven by synthetic
  planted violations:

    * File length: every `lib/**/*.{ex,css}` file has at most `@file_limit`
      lines (newline count, the same number `wc -l` prints).
    * Function length: every `def`/`defp`/`defmacro`/`defmacrop` clause in
      `lib/**/*.ex` spans at most `@function_limit` lines. Clauses are measured
      one at a time from the parsed AST (`do` line through `end` line) and the
      longest clause per name/arity is reported; clauses are never summed.
    * Separator banners: a `#` comment made of rule characters (`---`, `===`,
      `───`, `***`) stands in for a real module or function boundary. Each file
      that still has banners must match `@banner_exceptions` exactly.
    * No `.heex` templates and no `embed_templates` in `lib/`: moving markup out
      of `.ex` files would satisfy the length limits without making anything
      more legible.

  Every exception is an exact pin. A measured value above its pin means the
  code grew and must be split; a measured value below its pin means the pin is
  stale and must be lowered or deleted. Either way the change lands in a
  reviewed diff, so an exception cannot silently outlive its reason.
  """

  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  @file_glob "lib/**/*.{ex,css}"
  @source_glob "lib/**/*.ex"
  @template_glob "lib/**/*.heex"

  @file_limit 800
  @function_limit 120

  @banner ~r/^\s*#\s*(-{3,}|={3,}|─{3,}|\*{3,})/u
  @embed_templates ~r/\bembed_templates\b/
  @planning_vocabulary ~r/Phase \d|STRUCT-\d|\bD-\d{2}\b/

  @splitting "oversized; being split into cohesive modules"

  @file_exceptions %{
    "lib/threadline/operator_surface/stress_fixtures.ex" =>
      {980,
       "declarative fixture data tables; excluded from the Hex package (mix.exs exclude_patterns)"}
  }

  @function_exceptions %{
    {"lib/threadline/operator_surface/live/actor_live.ex", :render, 1} => {149, @splitting},
    {"lib/threadline/operator_surface/live/coverage_live.ex", :render, 1} => {135, @splitting},
    {"lib/threadline/operator_surface/live/start_live.ex", :render, 1} => {190, @splitting},
    {"lib/threadline/operator_surface/live/transaction_live.ex", :render, 1} => {183, @splitting}
  }

  @banner_exceptions %{
    "lib/threadline/operator_surface/controllers/export_controller.ex" => 9,
    "lib/threadline/operator_surface/live/coverage_live.ex" => 3,
    "lib/threadline/operator_surface/live/start_live.ex" => 6,
    "lib/threadline/semantics/actor_ref.ex" => 3
  }

  describe "file length" do
    test "the real tree matches the file exceptions exactly" do
      assert :ok = validate_files(scan(@file_glob), @file_exceptions)
    end

    test "an oversized file needs an exact exception and a stale one fails" do
      big = [{"lib/big.css", lines(801)}]

      assert {:error, message} = validate_files(big, %{})
      assert message =~ "lib/big.css has 801 lines"

      assert :ok = validate_files(big, %{"lib/big.css" => {801, @splitting}})

      stale = [{"lib/big.css", lines(850)}]
      assert {:error, message} = validate_files(stale, %{"lib/big.css" => {900, @splitting}})
      assert message =~ "stale"

      assert {:error, message} = validate_files(stale, %{"lib/big.css" => {820, @splitting}})
      assert message =~ "grew"

      small = [{"lib/small.ex", lines(800)}]
      assert {:error, message} = validate_files(small, %{"lib/small.ex" => {800, @splitting}})
      assert message =~ "stale"

      assert {:error, message} = validate_files(small, %{"lib/gone.ex" => {900, @splitting}})
      assert message =~ "lib/gone.ex"

      assert {:error, message} = validate_files(big, %{"lib/big.css" => {801, "Phase 9"}})
      assert message =~ "reason"
    end

    test "an empty scan set fails instead of passing vacuously" do
      assert {:error, message} = validate_files([], %{})
      assert message =~ "pass vacuously"
    end
  end

  describe "function length" do
    test "the real tree matches the function exceptions exactly" do
      assert :ok = validate_functions(scan(@source_glob), @function_exceptions)
    end

    test "a 121-line clause fails without an exact exception" do
      files = [{"lib/long.ex", module_source([clause("big", "x", 121)])}]

      assert {:error, message} = validate_functions(files, %{})
      assert message =~ "lib/long.ex big/1 has a 121-line clause"

      assert :ok = validate_functions(files, %{{"lib/long.ex", :big, 1} => {121, @splitting}})

      assert {:error, message} =
               validate_functions(files, %{{"lib/long.ex", :big, 1} => {140, @splitting}})

      assert message =~ "stale"
    end

    test "clauses are measured one at a time, never summed" do
      source =
        module_source([
          clause("run", ":a", 60),
          clause("run", ":b", 50),
          clause("run", ":c", 40)
        ])

      files = [{"lib/multi.ex", source}]

      assert %{{"lib/multi.ex", :run, 1} => 60} = measure_functions(files)
      assert :ok = validate_functions(files, %{})
    end

    test "a guarded head is measured under its own name and arity" do
      source = module_source([clause("f", "x", 5, "when is_integer(x)"), "  defp g, do: 1\n"])

      assert %{{"lib/guard.ex", :f, 1} => 5, {"lib/guard.ex", :g, 0} => 1} =
               measure_functions([{"lib/guard.ex", source}])
    end

    test "an empty scan set fails instead of passing vacuously" do
      assert {:error, message} = validate_functions([], %{})
      assert message =~ "pass vacuously"
    end
  end

  describe "separator banners" do
    test "the real tree matches the banner register exactly" do
      assert :ok = validate_banners(scan(@source_glob), @banner_exceptions)
    end

    test "banner comments are counted and string literals are ignored" do
      rule = "# " <> String.duplicate("-", 10)

      source = """
      defmodule Banner do
        #{rule}
        # plain prose comment
        def run, do: "#{rule}"
        # ===
        # ─── section ───
        # ***
      end
      """

      files = [{"lib/banner.ex", source}]

      assert %{"lib/banner.ex" => 4} = count_banners(files)
      assert {:error, message} = validate_banners(files, %{})
      assert message =~ "lib/banner.ex has 4 separator banner"
      assert :ok = validate_banners(files, %{"lib/banner.ex" => 4})

      assert {:error, message} = validate_banners(files, %{"lib/banner.ex" => 5})
      assert message =~ "stale"

      clean = [{"lib/clean.ex", "defmodule Clean do\n  # prose\nend\n"}]
      assert {:error, message} = validate_banners(clean, %{"lib/clean.ex" => 1})
      assert message =~ "stale"
    end

    test "an empty scan set fails instead of passing vacuously" do
      assert {:error, message} = validate_banners([], %{})
      assert message =~ "pass vacuously"
    end
  end

  describe "templates" do
    test "lib has no heex templates and no embed_templates calls" do
      assert :ok = validate_templates(template_paths(), scan(@source_glob))
    end

    test "a heex file or an embed_templates call fails" do
      clean = [{"lib/view.ex", "defmodule View do\nend\n"}]

      assert {:error, message} = validate_templates(["lib/view/index.html.heex"], clean)
      assert message =~ "lib/view/index.html.heex"

      embedded = [{"lib/view.ex", "defmodule View do\n  embed_templates \"view/*\"\nend\n"}]
      assert {:error, message} = validate_templates([], embedded)
      assert message =~ "lib/view.ex"

      assert :ok = validate_templates([], clean)
    end
  end

  test "this contract never references the planning directory" do
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  defp scan(glob) do
    @root
    |> Path.join(glob)
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&{Path.relative_to(&1, @root), File.read!(&1)})
  end

  defp template_paths do
    @root
    |> Path.join(@template_glob)
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, @root))
    |> Enum.sort()
  end

  defp line_count(source), do: source |> :binary.matches("\n") |> length()

  defp measure_functions(files) do
    for {path, source} <- files,
        {name, arity, length} <- clauses!(path, source),
        reduce: %{} do
      acc -> Map.update(acc, {path, name, arity}, length, &max(&1, length))
    end
  end

  defp clauses!(path, source) do
    case Code.string_to_quoted(source, token_metadata: true, columns: true, file: path) do
      {:ok, ast} ->
        {_ast, clauses} = Macro.prewalk(ast, [], &collect_clause/2)
        clauses

      {:error, _reason} ->
        fail!("#{path} does not parse, so its function lengths cannot be measured")
    end
  end

  defp collect_clause({kind, meta, [head | _]} = node, acc)
       when kind in [:def, :defp, :defmacro, :defmacrop] and is_list(meta) do
    length =
      case meta[:end] do
        nil -> 1
        end_meta -> end_meta[:line] - meta[:line] + 1
      end

    {name, arity} = name_arity(head)
    {node, [{name, arity, length} | acc]}
  end

  defp collect_clause(node, acc), do: {node, acc}

  defp name_arity({:when, _, [head | _]}), do: name_arity(head)
  defp name_arity({name, _, args}) when is_list(args), do: {clause_name(name), length(args)}
  defp name_arity({name, _, _context}), do: {clause_name(name), 0}
  defp name_arity(other), do: {Macro.to_string(other), 0}

  defp clause_name(name) when is_atom(name), do: name
  defp clause_name(name), do: Macro.to_string(name)

  defp count_banners(files) do
    files
    |> Enum.map(fn {path, source} -> {path, banner_count!(path, source)} end)
    |> Enum.reject(fn {_path, count} -> count == 0 end)
    |> Map.new()
  end

  defp banner_count!(path, source) do
    case Code.string_to_quoted_with_comments(source, file: path) do
      {:ok, _ast, comments} -> Enum.count(comments, &Regex.match?(@banner, &1.text))
      {:error, _reason} -> fail!("#{path} does not parse, so its comments cannot be read")
    end
  end

  defp validate_files(files, exceptions) do
    demand_non_empty!(files, @file_glob)
    validate_reasons!(exceptions)

    measured = Map.new(files, fn {path, source} -> {path, line_count(source)} end)

    measured
    |> compare_exact(exceptions, @file_limit, fn path, value ->
      "#{path} has #{value} lines, over the #{@file_limit}-line limit, and has no exception. " <>
        "Split it into cohesive modules."
    end)
    |> report!("file length")
  catch
    {:contract_error, message} -> {:error, message}
  end

  defp validate_functions(files, exceptions) do
    demand_non_empty!(files, @source_glob)
    validate_reasons!(exceptions)

    files
    |> measure_functions()
    |> compare_exact(exceptions, @function_limit, fn {path, name, arity}, value ->
      "#{path} #{name}/#{arity} has a #{value}-line clause, over the #{@function_limit}-line " <>
        "limit, and has no exception. Extract function components or private helpers."
    end)
    |> report!("function length")
  catch
    {:contract_error, message} -> {:error, message}
  end

  defp validate_banners(files, exceptions) do
    demand_non_empty!(files, @source_glob)

    for {path, count} <- exceptions do
      demand!(
        is_integer(count) and count > 0,
        "banner exception #{path} must pin a positive integer"
      )
    end

    files
    |> count_banners()
    |> compare_exact(Map.new(exceptions, fn {path, count} -> {path, {count, nil}} end), 0, fn
      path, value ->
        "#{path} has #{value} separator banner comment(s) and no banner exception. " <>
          "Replace each banner with a real module or function boundary."
    end)
    |> report!("separator banners")
  catch
    {:contract_error, message} -> {:error, message}
  end

  defp validate_templates(template_paths, files) do
    heex = Enum.map(template_paths, &"#{&1} is a .heex template")

    embedded =
      for {path, source} <- files, Regex.match?(@embed_templates, source) do
        "#{path} calls embed_templates"
      end

    report!(
      heex ++ embedded,
      "templates (keep markup in ~H inside .ex modules; moving it out games the length limits)"
    )
  catch
    {:contract_error, message} -> {:error, message}
  end

  # Measured values must equal their pins exactly. Keys over the limit need a pin;
  # a pin whose key is missing, back under the limit, or measured differently fails.
  defp compare_exact(measured, exceptions, limit, missing_message) do
    unpinned =
      for {key, value} <- Enum.sort(measured),
          value > limit,
          not Map.has_key?(exceptions, key),
          do: missing_message.(key, value)

    pinned =
      exceptions
      |> Enum.sort()
      |> Enum.map(fn {key, {pin, _reason}} ->
        pin_problem(key, pin, Map.get(measured, key), limit)
      end)
      |> Enum.reject(&is_nil/1)

    unpinned ++ pinned
  end

  defp pin_problem(key, _pin, nil, _limit),
    do: "exception #{inspect(key)} names nothing the scan measured; delete it (stale)"

  defp pin_problem(key, _pin, measured, limit) when measured <= limit,
    do:
      "exception #{inspect(key)} is stale: measured #{measured}, at or under the limit " <>
        "#{limit}; delete the pin"

  defp pin_problem(_key, pin, pin, _limit), do: nil

  defp pin_problem(key, pin, measured, _limit) when measured < pin,
    do:
      "exception #{inspect(key)} is stale: pinned #{pin}, measured #{measured}; lower or delete the pin"

  defp pin_problem(key, pin, measured, _limit),
    do:
      "exception #{inspect(key)} grew: pinned #{pin}, measured #{measured}; split it, do not raise the pin"

  defp validate_reasons!(exceptions) do
    for {key, {count, reason}} <- exceptions do
      demand!(
        is_integer(count) and count > 0,
        "exception #{inspect(key)} must pin a positive integer"
      )

      demand!(
        is_binary(reason) and String.trim(reason) != "" and
          not Regex.match?(@planning_vocabulary, reason),
        "exception #{inspect(key)} needs a reason in plain terms, without planning references"
      )
    end

    :ok
  end

  defp demand_non_empty!(files, glob) do
    demand!(
      files != [],
      "the scanned file set is empty. A broken #{glob} glob would let this contract " <>
        "pass vacuously, which is worse than having no gate at all."
    )
  end

  defp report!([], _rule), do: :ok

  defp report!(problems, rule) do
    fail!("#{rule}:\n  " <> Enum.join(problems, "\n  "))
  end

  defp lines(count), do: String.duplicate("x\n", count)

  defp module_source(clauses), do: "defmodule Synthetic do\n" <> Enum.join(clauses) <> "end\n"

  # A clause spanning exactly `total` lines: head, `total - 2` body lines, `end`.
  defp clause(name, arg, total, guard \\ nil) do
    head = Enum.join(Enum.reject(["  def #{name}(#{arg})", guard, "do"], &is_nil/1), " ")
    head <> "\n" <> String.duplicate("    :ok\n", total - 2) <> "  end\n"
  end

  defp demand!(true, _message), do: :ok
  defp demand!(false, message), do: fail!(message)
  defp fail!(message), do: throw({:contract_error, message})
end
