defmodule Threadline.PublicOptionsContractTest do
  @moduledoc false
  use ExUnit.Case, async: false

  @task_flags %{
    "threadline.continuity" => %{flags: ~w(dry_run table), aliases: %{"d" => "dry_run"}},
    "threadline.evidence.show" => %{
      flags: ~w(json subject subject_ref_json latest history from to limit),
      aliases: %{}
    },
    "threadline.export" => %{
      flags: ~w(output format json_format max_rows dry_run table from to actor_json),
      aliases: %{"o" => "output"}
    },
    "threadline.gen.row_history_index" => %{
      flags: ~w(migrations_path repo),
      aliases: %{"r" => "repo"}
    },
    "threadline.gen.triggers" => %{
      flags: ~w(tables store_changed_from except_columns dry_run migrations_path repo),
      aliases: %{"r" => "repo"}
    },
    "threadline.health.coverage" => %{flags: ~w(json schema strict all_schemas), aliases: %{}},
    "threadline.incident" => %{flags: ~w(json), aliases: %{}},
    "threadline.install" => %{flags: ~w(migrations_path repo), aliases: %{"r" => "repo"}},
    "threadline.policy.show" => %{flags: ~w(json schema), aliases: %{}},
    "threadline.retention.purge" => %{
      flags: ~w(batch_size max_batches dry_run execute),
      aliases: %{"d" => "dry_run"}
    },
    "threadline.verify_coverage" => %{flags: ~w(schema), aliases: %{}},
    # This task forwards arguments to Mix's test task and has no Threadline-owned flags.
    "threadline.verify_topology" => %{flags: [], aliases: %{}}
  }

  @operator_options ~w(authorize_fn actor_fn adopter_acknowledges_unauthenticated exports scope_query_fn export_authorize_fn coverage_authorize_fn policy_authorize_fn evidence_authorize_fn theme repo schemas)a

  @mounted_routes [
    "LIVE /",
    "LIVE /timeline",
    "LIVE /evidence",
    "LIVE /coverage",
    "LIVE /exports",
    "LIVE /policy/redaction",
    "LIVE /policy/retention",
    "LIVE /rows/:table/:record_id",
    "LIVE /transactions/:id",
    "LIVE /transactions/:id/history/:table/:record_id",
    "LIVE /actors/:kind/:id",
    "POST /theme",
    "GET /exports/changes.csv",
    "GET /exports/changes.json",
    "GET /exports/changes.ndjson",
    "GET /exports/download/:job_id"
  ]

  @documented_mount_routes [
    "/audit/transactions/:id",
    "/audit/actors/:kind/:id",
    "/audit/rows/:table/:pk",
    "/audit/coverage",
    "/audit/policy/redaction"
  ]

  defp assert_exact_set!(actual, expected, label) do
    added = MapSet.difference(actual, expected) |> Enum.sort()
    removed = MapSet.difference(expected, actual) |> Enum.sort()

    assert added == [] and removed == [],
           "#{label} drift: added=#{inspect(added)} removed=#{inspect(removed)}"
  end

  test "every shipped Threadline Mix task has a literal accepted-flag pin" do
    files =
      Path.wildcard("lib/mix/tasks/threadline*.ex") ++
        Path.wildcard("lib/mix/tasks/threadline/**/*.ex")

    actual_inventory =
      Map.new(files, fn path ->
        task = task_name(path)
        {task, parse_options!(File.read!(path), path)}
      end)

    assert_exact_set!(
      Map.keys(actual_inventory) |> MapSet.new(),
      Map.keys(@task_flags) |> MapSet.new(),
      "Threadline Mix task inventory"
    )

    for {task, expected} <- @task_flags do
      actual = Map.fetch!(actual_inventory, task)
      assert_exact_set!(MapSet.new(actual.flags), MapSet.new(expected.flags), "#{task} flags")

      assert actual.aliases == expected.aliases,
             "#{task} aliases drift: expected=#{inspect(expected.aliases)} actual=#{inspect(actual.aliases)}"
    end
  end

  test "flag pin control reports a removed flag and an unpinned task" do
    assert_raise ExUnit.AssertionError,
                 ~r/task flags control drift: added=\[\] removed=\["schema"\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(["json"]),
                     MapSet.new(["json", "schema"]),
                     "task flags control"
                   )
                 end

    assert_raise ExUnit.AssertionError,
                 ~r/task inventory control drift: added=\["threadline.new_task"\] removed=\[\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(Map.keys(@task_flags) ++ ["threadline.new_task"]),
                     MapSet.new(Map.keys(@task_flags)),
                     "task inventory control"
                   )
                 end
  end

  test "operator router options and mounted route templates remain explicitly pinned" do
    router = File.read!("lib/threadline/operator_surface/router.ex")

    option_sources =
      [
        router,
        File.read!("lib/threadline/operator_surface/auth.ex"),
        File.read!("lib/threadline/operator_surface/session_plug.ex"),
        File.read!("lib/threadline/operator_surface/export_auth_plug.ex")
      ]

    source_options =
      option_sources
      |> Enum.flat_map(fn source ->
        Regex.scan(~r/Keyword\.(?:has_key\?|get)\(opts,\s*:(\w+)/, source,
          capture: :all_but_first
        )
      end)
      |> List.flatten()
      |> Enum.reject(&(&1 == "theme_path"))
      |> Enum.uniq()
      |> MapSet.new()

    router_docs =
      Regex.scan(~r/@(?:moduledoc|doc) """(.*?)"""/s, router, capture: :all_but_first)
      |> List.flatten()
      |> Enum.join("\n")

    guide = File.read!("guides/operator-surface.md")

    expected_options = MapSet.new(Enum.map(@operator_options, &Atom.to_string/1))

    assert_exact_set!(source_options, expected_options, "operator macro option keys")

    for option <- expected_options do
      assert Regex.match?(~r/`?:#{option}`?|\b#{option}:/, router_docs <> guide),
             "operator docs no longer mention the #{inspect(option)} option"
    end

    actual_routes =
      Regex.scan(~r/\b(live|post|get)\("([^"]+)"/, router, capture: :all_but_first)
      |> Enum.map(fn [method, route] -> "#{String.upcase(method)} #{route}" end)
      |> MapSet.new()
      |> expand_export_scope_routes()

    assert_exact_set!(actual_routes, MapSet.new(@mounted_routes), "operator mount routes")

    for route <- @documented_mount_routes do
      assert String.contains?(guide, route), "operator guide no longer documents #{route}"
    end

    assert String.contains?(guide, "live(\"/transactions/:id/history/:table/:record_id\"")
  end

  test "route pin control reports a removed route and a changed route" do
    expected = MapSet.new(@mounted_routes)

    assert_raise ExUnit.AssertionError,
                 ~r/route control drift: added=\[\] removed=\["LIVE \/evidence"\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(@mounted_routes -- ["LIVE /evidence"]),
                     expected,
                     "route control"
                   )
                 end

    assert_raise ExUnit.AssertionError,
                 ~r/route control drift: added=\["GET \/new"\] removed=\[\]/,
                 fn ->
                   assert_exact_set!(
                     MapSet.new(@mounted_routes ++ ["GET /new"]),
                     expected,
                     "route control"
                   )
                 end
  end

  defp expand_export_scope_routes(routes) do
    Enum.map(routes, fn
      "GET /changes.csv" -> "GET /exports/changes.csv"
      "GET /changes.json" -> "GET /exports/changes.json"
      "GET /changes.ndjson" -> "GET /exports/changes.ndjson"
      "GET /download/:job_id" -> "GET /exports/download/:job_id"
      route -> route
    end)
    |> MapSet.new()
  end

  defp task_name(path) do
    path
    |> Path.relative_to("lib/mix/tasks/")
    |> String.replace_suffix(".ex", "")
    |> String.replace("/", ".")
  end

  defp parse_options!(source, path) do
    strict =
      case Regex.run(~r/strict:\s*\[(.*?)\]/s, source, capture: :all_but_first) do
        [body] ->
          Regex.scan(~r/(\w+)\s*:\s*:(?:boolean|string|integer|keep)/, body,
            capture: :all_but_first
          )
          |> List.flatten()

        nil ->
          []
      end

    aliases =
      case Regex.run(~r/aliases:\s*\[(.*?)\]/s, source, capture: :all_but_first) do
        [body] ->
          Regex.scan(~r/(\w+)\s*:\s*:(\w+)/, body, capture: :all_but_first)
          |> Map.new(fn [short, long] -> {short, long} end)

        nil ->
          %{}
      end

    if String.contains?(source, "OptionParser.parse") and
         not Regex.match?(~r/strict:\s*\[/, source) do
      flunk("#{path} parses options without an explicit strict flag list")
    end

    %{flags: strict, aliases: aliases}
  end
end
