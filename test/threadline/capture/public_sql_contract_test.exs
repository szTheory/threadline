defmodule Threadline.Capture.PublicSQLContractTest do
  @moduledoc """
  Pins the SQL names adopters rely on and the production source paths that use
  them. Expected names are literals, independent of the implementation.
  """

  use ExUnit.Case, async: true

  alias Threadline.Capture.Naming

  @actor_guc "threadline.actor_ref"
  @actor_call_sites %{
    "lib/threadline/audit.ex" => 1,
    "lib/threadline/plug.ex" => 1,
    "lib/threadline/capture/trigger_sql.ex" => 2
  }
  @function_name_call_sites %{
    "lib/mix/tasks/threadline.gen.triggers.ex" => 4,
    "lib/threadline/capture/trigger_sql.ex" => 1
  }
  @trigger_name_call_sites %{
    "lib/threadline/capture/trigger_sql.ex" => 1,
    "lib/threadline/capture/primary_key_sql.ex" => 1,
    "lib/threadline/health/trigger_findings.ex" => 1
  }

  test "actor GUC and per-table function names match literal public values" do
    assert @actor_guc == "threadline.actor_ref"

    for {table, expected} <- [
          {"posts", "threadline_capture_changes_posts"},
          {"billing.invoices", "threadline_capture_changes_billing_invoices_9bba11019407"},
          {
            "customer_subscription_line_items_archive",
            "threadline_capture_changes_customer_subscription_l_3b9be56c3c45"
          }
        ] do
      assert Naming.function_name(table) == expected,
             "Naming.function_name(#{inspect(table)}) changed from its public SQL name"
    end
  end

  test "production actor GUC reads and writes use the pinned literal" do
    sources = source_files()
    assert_actor_call_sites!(sources)
  end

  test "trigger creation and cleanup use Naming's pinned public schemes" do
    sources = source_files()
    assert_named_call_sites!(sources, "Naming.function_name", @function_name_call_sites)
    assert_named_call_sites!(sources, "Naming.trigger_name", @trigger_name_call_sites)
  end

  test "renamed actor and naming source call sites are caught" do
    sources = source_files()
    actor_path = "lib/threadline/plug.ex"

    renamed_actor =
      Map.update!(sources, actor_path, &String.replace(&1, @actor_guc, "threadline.actor_ref_v2"))

    assert_raise ExUnit.AssertionError, fn ->
      assert_actor_call_sites!(renamed_actor)
    end

    function_path = "lib/threadline/capture/trigger_sql.ex"

    renamed_function =
      Map.update!(
        sources,
        function_path,
        &String.replace(&1, "Naming.function_name(", "Renamed.function_name(")
      )

    assert_raise ExUnit.AssertionError, fn ->
      assert_named_call_sites!(
        renamed_function,
        "Naming.function_name",
        @function_name_call_sites
      )
    end
  end

  defp source_files do
    Path.wildcard("lib/**/*.ex")
    |> Enum.sort()
    |> Map.new(fn path -> {path, File.read!(path)} end)
  end

  defp assert_actor_call_sites!(sources) do
    actual =
      sources
      |> Enum.map(fn {path, source} ->
        matches =
          Regex.scan(
            ~r/(?:current_setting|set_config)\s*\(\s*['"]threadline\.actor_ref['"]/,
            source
          )

        {path, length(matches)}
      end)
      |> Enum.reject(fn {_path, count} -> count == 0 end)
      |> Map.new()

    assert actual == @actor_call_sites,
           "actor GUC production call sites changed; expected=#{inspect(@actor_call_sites)} " <>
             "actual=#{inspect(actual)}"
  end

  defp assert_named_call_sites!(sources, name, expected) do
    pattern = Regex.compile!(Regex.escape(name) <> "\\s*\\(")

    actual =
      sources
      |> Enum.map(fn {path, source} -> {path, length(Regex.scan(pattern, source))} end)
      |> Enum.reject(fn {_path, count} -> count == 0 end)
      |> Map.new()

    assert actual == expected,
           "#{name} production call sites changed; expected=#{inspect(expected)} " <>
             "actual=#{inspect(actual)}"
  end
end
