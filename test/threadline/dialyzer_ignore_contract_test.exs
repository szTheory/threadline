defmodule Threadline.DialyzerIgnoreContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @mix_path Path.join(@root, "mix.exs")
  @triage_path Path.join(@root, ".planning/phases/199-decouple/199-DIALYZER-TRIAGE.md")
  @fixture_paths ~w(
    critic-tooling.json
    query-storage.json
    export-investigation.json
    operator-boundaries.json
    operator-liveviews.json
  )
  |> Enum.map(&Path.join([@root, "test/fixtures/dialyzer", &1]))
  @required_plt_apps ~w(mix ex_unit phoenix phoenix_live_view phoenix_html phoenix_pubsub oban ex_aws ex_aws_s3 hackney sweet_xml)a
  @warning_origin_cap 14

  test "five source fixtures form the exact 40-warning and 22-origin partition" do
    fixtures = Enum.map(@fixture_paths, &(&1 |> File.read!() |> Jason.decode!()))
    warning_ids = for fixture <- fixtures, warning <- fixture["warnings"], do: warning["id"]
    origins = Enum.flat_map(fixtures, & &1["authorized_origins"])

    assert Enum.sort(warning_ids) == Enum.map(1..40, &"W#{String.pad_leading("#{&1}", 2, "0")}")
    assert length(warning_ids) == length(Enum.uniq(warning_ids))
    assert length(origins) == 22
    assert length(origins) == length(Enum.uniq(origins))

    refute File.read!(__ENV__.file) =~ ".planning"
  end

  test "ignore ratchet rejects broad filters before the ceiling check" do
    assert {:error, message} = validate_warning_origins(["lib/**/*.ex"])
    assert message =~ "exact"
  end

  test "full optional-app Dialyzer configuration and sealed first analysis are present" do
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

    assert File.exists?(@triage_path),
           "the first raw full-build analysis must be sealed before warning-origin edits"

    triage = File.read!(@triage_path)
    origins = sealed_warning_origins!(triage)

    assert length(origins) <= @warning_origin_cap
    assert length(origins) == length(Enum.uniq(origins))
    assert triage =~ ~r/Raw output SHA-256: `[0-9a-f]{64}`/
    assert triage =~ ~r/Initial warning count: `\d+`/
  end

  test "warning-origin scope rejects a fifteenth distinct source path" do
    fourteen = for index <- 1..14, do: "lib/warning_origin_#{index}.ex"
    assert :ok = validate_warning_origins(fourteen)

    assert {:error, message} = validate_warning_origins(fourteen ++ ["lib/warning_origin_15.ex"])
    assert message =~ "15 distinct warning-origin source files"
    assert message =~ "re-plan"
  end

  defp sealed_warning_origins!(triage) do
    case Regex.run(
           ~r/<!-- warning-origins:start -->\n(?<paths>.*?)<!-- warning-origins:end -->/s,
           triage,
           capture: :all_names
         ) do
      [paths] ->
        paths
        |> String.split("\n", trim: true)
        |> Enum.map(fn line ->
          case Regex.run(~r/^- `([^`]+)`$/, line) do
            [_, path] ->
              path

            _ ->
              flunk("sealed warning-origin entry is not an exact source path: #{inspect(line)}")
          end
        end)

      _ ->
        flunk("triage must contain one sealed warning-origin block")
    end
  end

  defp validate_warning_origins(paths) do
    count = paths |> Enum.uniq() |> length()

    if count <= @warning_origin_cap do
      :ok
    else
      {:error,
       "raw analysis discovered #{count} distinct warning-origin source files; stop without source edits and re-plan/re-slice Phase 199"}
    end
  end
end
