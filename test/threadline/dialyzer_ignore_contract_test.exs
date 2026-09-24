defmodule Threadline.DialyzerIgnoreContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @mix_path Path.join(@root, "mix.exs")
  @ignore_path Path.join(@root, ".dialyzer_ignore.exs")
  @fixture_dir Path.join(@root, "test/fixtures/dialyzer")
  @readme_path Path.join(@fixture_dir, "README.md")

  @fixture_specs [
    {"critic-tooling.json", "critic-tooling", ~w(W01 W02 W05)},
    {"query-storage.json", "query-storage", ~w(W03 W04 W33 W34 W35 W36 W37 W38 W39 W40)},
    {"export-investigation.json", "export-investigation",
     ~w(W06 W07 W08 W09 W10 W11 W12 W13 W14 W15 W16 W17 W18 W19 W20)},
    {"operator-boundaries.json", "operator-boundaries", ~w(W21 W30 W31 W27 W28 W29 W32)},
    {"operator-liveviews.json", "operator-liveviews", ~w(W22 W23 W24 W25 W26)}
  ]

  @required_plt_apps ~w(mix ex_unit phoenix phoenix_live_view phoenix_html phoenix_pubsub oban ex_aws ex_aws_s3 req sweet_xml)a
  @sealed_output_sha256 "12c1164ae38a943a738b339d2758e866c51b284444480585e80d5d591169c3e6"
  @empty_output_sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  @raw_command "MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status"
  @warning_ceiling 0

  test "five source fixtures form the exact 40-warning and 22-origin partition" do
    fixtures = load_fixtures!()

    assert :ok = validate_contract(fixtures, File.read!(@ignore_path), @warning_ceiling)

    warning_ids = for fixture <- fixtures, warning <- fixture["warnings"], do: warning["id"]
    origins = Enum.flat_map(fixtures, & &1["authorized_origins"])

    assert Enum.sort(warning_ids) == Enum.map(1..40, &"W#{String.pad_leading("#{&1}", 2, "0")}")
    assert length(origins) == 22

    assert Enum.all?(fixtures, fn fixture ->
             Enum.all?(fixture["warnings"], &(&1["disposition"] == "fixed"))
           end)

    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  test "ignore ratchet rejects broad filters before the ceiling check" do
    fixtures = load_fixtures!()

    assert {:error, message} = validate_contract(fixtures, "[~r/lib\\/.*/]", @warning_ceiling)
    assert message =~ "literal exact tuple"

    assert {:error, message} =
             validate_contract(
               fixtures,
               commented_source([{"lib/**/*.ex", "warning"}]),
               @warning_ceiling
             )

    assert message =~ "wildcards"
  end

  test "full optional-app Dialyzer configuration keeps every strict warning class enabled" do
    mix_source = File.read!(@mix_path)

    assert mix_source =~
             ~s({:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}),
           "Dialyxir must be an explicit dev/test-only non-runtime dependency"

    project = Threadline.MixProject.project()
    dialyzer = Keyword.fetch!(project, :dialyzer)

    assert Enum.sort(Keyword.fetch!(dialyzer, :plt_add_apps)) == Enum.sort(@required_plt_apps)
    assert Enum.sort(Keyword.fetch!(dialyzer, :flags)) == [:extra_return, :unmatched_returns]
    refute :unknown in Keyword.get(dialyzer, :remove_defaults, [])
    assert Keyword.fetch!(dialyzer, :ignore_warnings) == ".dialyzer_ignore.exs"
    assert Keyword.fetch!(dialyzer, :list_unused_filters)
  end

  test "fixture documentation preserves provenance, update commands, and the zero ceiling" do
    readme = File.read!(@readme_path)

    for phrase <- [
          "40 warnings",
          "22 distinct warning origins",
          "may only decrease",
          "must never increase",
          @raw_command,
          "bin/verify-dialyzer-slice",
          "mix dialyzer --list-unused-filters"
        ] do
      assert readme =~ phrase
    end
  end

  test "duplicate, uncommented, malformed, and over-ceiling filters fail closed" do
    fixtures = make_irreducible(load_fixtures!(), "W01")
    source = ignore_source(fixtures)
    [entry] = ignore_entries(fixtures)

    assert {:error, message} = validate_contract(fixtures, commented_source([entry, entry]), 2)
    assert message =~ "duplicate"

    {file, description} = entry
    uncommented = "[\n  {#{inspect(file)}, #{inspect(description)}}\n]"
    assert {:error, message} = validate_contract(fixtures, uncommented, 1)
    assert message =~ "exactly one comment"

    assert {:error, message} = validate_contract(fixtures, "[exact_filter()]", 1)
    assert message =~ "literal exact tuple"

    for malformed <- [~s(["warning description only"]), ~s(["lib/file_only.ex"])] do
      assert {:error, malformed_message} = validate_contract(fixtures, malformed, 1)
      assert malformed_message =~ "literal exact tuple"
    end

    assert {:error, message} = validate_contract(fixtures, source, 0)
    assert message =~ "ceiling of 0"
  end

  test "fixed-warning and unknown-warning filters are forbidden" do
    fixtures = load_fixtures!()
    warning = find_warning!(fixtures, "W01")
    fixed_entry = {warning["origin"]["path"], warning["raw_line"]}

    assert {:error, message} = validate_contract(fixtures, commented_source([fixed_entry]), 1)
    assert message =~ "fixed warning W01"

    unknown_entry = {"lib/not_authorized.ex", "unknown warning"}

    assert {:error, message} = validate_contract(fixtures, commented_source([unknown_entry]), 1)
    assert message =~ "unknown warning"
  end

  test "missing origins and unused filters are rejected independently" do
    fixtures = load_fixtures!()
    [first | rest] = fixtures
    [_removed | remaining_origins] = first["authorized_origins"]
    mutated = [Map.put(first, "authorized_origins", remaining_origins) | rest]

    assert {:error, message} = validate_contract(mutated, "[]", @warning_ceiling)
    assert message =~ "authorized origins"

    assert {:error, message} =
             validate_contract(fixtures, "[]", @warning_ceiling, ["stale filter"])

    assert message =~ "unused filter"
  end

  test "empty ignore list passes only while every warning remains fixed" do
    fixtures = load_fixtures!()
    assert :ok = validate_contract(fixtures, "[]", @warning_ceiling)

    fixtures = make_irreducible(fixtures, "W01")

    assert {:error, message} = validate_contract(fixtures, "[]", 1)
    assert message =~ "missing exact filter for irreducible warning W01"
  end

  test "irreducible filters require exact tuples and actionable adjacent comments" do
    fixtures = make_irreducible(load_fixtures!(), "W01")
    source = ignore_source(fixtures)

    assert :ok = validate_contract(fixtures, source, 1)

    assert {:error, message} =
             validate_contract(fixtures, String.replace(source, "Remove when:", "Revisit:"), 1)

    assert message =~ "actionable comment"

    duplicate_comment = String.replace(source, "  # Rationale:", "  # duplicate\n  # Rationale:")
    assert {:error, message} = validate_contract(fixtures, duplicate_comment, 1)
    assert message =~ "exactly one comment"
  end

  defp load_fixtures! do
    Enum.map(@fixture_specs, fn {filename, _slice, _warning_ids} ->
      @fixture_dir
      |> Path.join(filename)
      |> File.read!()
      |> Jason.decode!()
    end)
  end

  defp validate_contract(fixtures, ignore_source, ceiling, unused_filters \\ []) do
    validate_fixtures!(fixtures)
    {entries, entry_lines, source_lines} = parse_ignore_source!(ignore_source)

    reject_broad_entries!(entries)
    demand!(length(entries) == length(Enum.uniq(entries)), "duplicate exact ignore tuple")
    reject_unused_filters!(unused_filters)

    warnings = Enum.flat_map(fixtures, & &1["warnings"])
    validate_entries!(entries, entry_lines, source_lines, warnings)

    demand!(
      length(entries) <= ceiling,
      "ignore count exceeds the ratchet ceiling of #{ceiling}"
    )

    :ok
  catch
    {:contract_error, message} -> {:error, message}
  end

  defp validate_fixtures!(fixtures) do
    demand!(length(fixtures) == length(@fixture_specs), "exactly five fixtures are required")

    Enum.zip(fixtures, @fixture_specs)
    |> Enum.each(fn {fixture, {_filename, expected_slice, expected_ids}} ->
      demand!(fixture["schema_version"] == 1, "#{expected_slice} schema_version must be 1")
      demand!(fixture["slice"] == expected_slice, "fixture slice order or name changed")
      demand!(fixture["sealed_run"]["warning_count"] == 40, "sealed warning count must remain 40")

      demand!(
        fixture["sealed_run"]["output_sha256"] == @sealed_output_sha256,
        "sealed raw-output provenance changed"
      )

      demand!(
        fixture["post_analysis"]["command"] == @raw_command,
        "post-analysis command changed"
      )

      demand!(
        fixture["post_analysis"]["authorized_output_sha256"] == @empty_output_sha256,
        "post-analysis output must remain empty"
      )

      origins = fixture["authorized_origins"]
      warnings = fixture["warnings"]

      demand!(
        origins == Enum.sort(origins),
        "#{expected_slice} authorized origins must be sorted"
      )

      demand!(length(origins) == length(Enum.uniq(origins)), "duplicate authorized origin")

      demand!(
        Enum.map(warnings, & &1["id"]) == expected_ids,
        "#{expected_slice} warning IDs changed"
      )

      warning_origins =
        warnings |> Enum.map(&get_in(&1, ["origin", "path"])) |> Enum.uniq() |> Enum.sort()

      demand!(
        warning_origins == origins,
        "#{expected_slice} warnings must cover its authorized origins exactly"
      )

      Enum.each(warnings, &validate_warning!(&1, origins))
    end)

    warnings = Enum.flat_map(fixtures, & &1["warnings"])
    origins = Enum.flat_map(fixtures, & &1["authorized_origins"])
    expected_ids = Enum.map(1..40, &"W#{String.pad_leading("#{&1}", 2, "0")}")

    demand!(
      Enum.sort(Enum.map(warnings, & &1["id"])) == expected_ids,
      "warning IDs must be W01-W40"
    )

    demand!(length(warnings) == 40, "fixture union must contain exactly 40 warnings")
    demand!(length(origins) == 22, "fixture union must contain exactly 22 authorized origins")

    demand!(
      length(origins) == length(Enum.uniq(origins)),
      "authorized origins must be slice-disjoint"
    )
  end

  defp validate_warning!(warning, origins) do
    required = ~w(id class origin raw_line disposition evidence)

    demand!(
      Enum.all?(required, &Map.has_key?(warning, &1)),
      "warning record is missing a required field"
    )

    demand!(warning["class"] =~ ~r/^warn_/, "#{warning["id"]} has an invalid warning class")

    demand!(
      warning["disposition"] in ~w(fixed irreducible),
      "#{warning["id"]} has an invalid disposition"
    )

    demand!(
      is_binary(warning["evidence"]) and warning["evidence"] != "",
      "warning evidence is required"
    )

    path = warning["origin"]["path"]
    line = warning["origin"]["line"]
    demand!(path in origins, "#{warning["id"]} is outside its authorized origins")
    demand!(is_integer(line) and line > 0, "#{warning["id"]} requires a positive origin line")

    demand!(
      String.contains?(warning["raw_line"], path),
      "#{warning["id"]} raw line lost origin provenance"
    )

    if warning["disposition"] == "fixed" do
      forbidden = ~w(ignore_tuple rationale removal_trigger upstream)

      demand!(
        Enum.all?(forbidden, &(not Map.has_key?(warning, &1))),
        "fixed warning #{warning["id"]} carries ignore metadata"
      )
    else
      tuple = warning["ignore_tuple"]
      demand!(is_map(tuple), "irreducible warning #{warning["id"]} requires ignore_tuple")

      demand!(
        is_binary(tuple["file"]),
        "irreducible warning #{warning["id"]} requires an exact file"
      )

      demand!(
        is_binary(tuple["warning_description"]),
        "irreducible warning #{warning["id"]} requires an exact warning description"
      )

      demand!(
        present?(warning["rationale"]),
        "irreducible warning #{warning["id"]} requires rationale"
      )

      demand!(
        present?(warning["removal_trigger"]),
        "irreducible warning #{warning["id"]} requires removal_trigger"
      )
    end
  end

  defp parse_ignore_source!(source) do
    {ast, comments} =
      case Code.string_to_quoted_with_comments(source, columns: true) do
        {:ok, ast, comments} -> {ast, comments}
        {:error, error} -> fail!("ignore file is not valid Elixir: #{inspect(error)}")
      end

    demand!(is_list(ast), "ignore file must be one literal list")

    entries =
      Enum.map(ast, fn
        {file, description} when is_binary(file) and is_binary(description) ->
          {file, description}

        _other ->
          fail!("every ignore entry must be a literal exact tuple")
      end)

    source_lines = String.split(source, "\n")

    entry_lines =
      source_lines
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _line_number} -> String.starts_with?(String.trim(line), "{") end)
      |> Enum.map(&elem(&1, 1))

    demand!(
      length(entry_lines) == length(entries),
      "each exact tuple must occupy its own source line"
    )

    demand!(length(comments) == length(entries), "each exact tuple must have exactly one comment")

    {entries, entry_lines, source_lines}
  end

  defp reject_broad_entries!(entries) do
    Enum.each(entries, fn {file, description} ->
      wildcard? = Enum.any?(["*", "?", "[", "]"], &String.contains?(file, &1))

      demand!(not wildcard?, "ignore file paths must be exact and cannot contain wildcards")
      demand!(file != "" and description != "", "ignore tuple values must be non-empty")
    end)
  end

  defp reject_unused_filters!([]), do: :ok

  defp reject_unused_filters!(filters) do
    fail!("Dialyzer reported an unused filter: #{inspect(filters)}")
  end

  defp validate_entries!(entries, entry_lines, source_lines, warnings) do
    warnings_by_tuple =
      Map.new(warnings, fn warning ->
        {{warning["origin"]["path"], warning["raw_line"]}, warning}
      end)

    irreducible = Enum.filter(warnings, &(&1["disposition"] == "irreducible"))
    expected_entries = Enum.map(irreducible, &warning_tuple!/1)

    Enum.each(entries, fn entry ->
      case Map.get(warnings_by_tuple, entry) do
        %{"disposition" => "fixed", "id" => id} ->
          fail!("fixed warning #{id} must not have a filter")

        nil ->
          demand!(entry in expected_entries, "ignore tuple targets an unknown warning")

        _irreducible ->
          :ok
      end
    end)

    Enum.each(irreducible, fn warning ->
      demand!(
        warning_tuple!(warning) in entries,
        "missing exact filter for irreducible warning #{warning["id"]}"
      )
    end)

    demand!(
      entries == expected_entries,
      "ignore entries must follow the sealed fixture order exactly"
    )

    Enum.zip(entries, entry_lines)
    |> Enum.each(fn {entry, line_number} ->
      warning = Enum.find(irreducible, &(warning_tuple!(&1) == entry))
      previous_line = source_lines |> Enum.at(line_number - 2, "") |> String.trim()
      expected_comment = actionable_comment(warning)

      demand!(
        previous_line == expected_comment,
        "each irreducible tuple needs its actionable comment on the immediately preceding line"
      )
    end)
  end

  defp warning_tuple!(warning) do
    tuple = warning["ignore_tuple"]
    {tuple["file"], tuple["warning_description"]}
  end

  defp actionable_comment(warning) do
    base = "# Rationale: #{warning["rationale"]} Remove when: #{warning["removal_trigger"]}"

    case warning["upstream"] do
      upstream when is_binary(upstream) and upstream != "" -> "#{base} Upstream: #{upstream}"
      _ -> base
    end
  end

  defp make_irreducible(fixtures, warning_id) do
    Enum.map(fixtures, fn fixture ->
      warnings = Enum.map(fixture["warnings"], &make_warning_irreducible(&1, warning_id))
      Map.put(fixture, "warnings", warnings)
    end)
  end

  defp make_warning_irreducible(%{"id" => warning_id} = warning, warning_id) do
    warning
    |> Map.put("disposition", "irreducible")
    |> Map.put("ignore_tuple", %{
      "file" => warning["origin"]["path"],
      "warning_description" => warning["raw_line"]
    })
    |> Map.put("rationale", "The sealed warning has no sound local source correction.")
    |> Map.put("removal_trigger", "Remove after the upstream type contract is corrected.")
  end

  defp make_warning_irreducible(warning, _warning_id), do: warning

  defp ignore_source(fixtures) do
    irreducible =
      fixtures
      |> Enum.flat_map(& &1["warnings"])
      |> Enum.filter(&(&1["disposition"] == "irreducible"))

    body =
      Enum.map_join(irreducible, ",\n", fn warning ->
        {file, description} = warning_tuple!(warning)
        "  #{actionable_comment(warning)}\n  {#{inspect(file)}, #{inspect(description)}}"
      end)

    "[\n#{body}\n]"
  end

  defp commented_source(entries) do
    body =
      Enum.map_join(entries, ",\n", fn {file, description} ->
        "  # Rationale: synthetic control Remove when: synthetic control is removed.\n" <>
          "  {#{inspect(file)}, #{inspect(description)}}"
      end)

    "[\n#{body}\n]"
  end

  defp ignore_entries(fixtures) do
    fixtures
    |> Enum.flat_map(& &1["warnings"])
    |> Enum.filter(&(&1["disposition"] == "irreducible"))
    |> Enum.map(&warning_tuple!/1)
  end

  defp find_warning!(fixtures, warning_id) do
    fixtures
    |> Enum.flat_map(& &1["warnings"])
    |> Enum.find(&(&1["id"] == warning_id))
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
  defp demand!(true, _message), do: :ok
  defp demand!(false, message), do: fail!(message)
  defp fail!(message), do: throw({:contract_error, message})
end
