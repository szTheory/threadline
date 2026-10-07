defmodule Threadline.Capture.PublicSQLContractTest do
  @moduledoc """
  Pins the SQL names adopters rely on and the production source paths that use
  them. Expected names are literals, independent of the implementation.
  """

  use ExUnit.Case, async: true

  alias Threadline.Capture.Naming

  @actor_guc "threadline.actor_ref"
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

  test "production actor GUC writes and generated SQL reads use the pinned literal" do
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
    actor_path = "lib/threadline/audit.ex"

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
    writer_sql = "SELECT set_config('#{@actor_guc}', $1::text, true)"
    audit_queries = literal_query_arguments(sources["lib/threadline/audit.ex"])
    plug_queries = literal_query_arguments(sources["lib/threadline/plug.ex"])

    assert Enum.count(audit_queries, &(&1 == writer_sql)) == 1,
           "Threadline.Audit must set the actor GUC once inside its transaction"

    refute Enum.any?(plug_queries, &String.contains?(&1, "set_config('#{@actor_guc}'")),
           "Threadline.Plug must not set the actor GUC outside the audited transaction"

    for sql <- [
          Threadline.Capture.TriggerSQL.install_function(),
          Threadline.Capture.TriggerSQL.install_function_for_table("posts",
            store_changed_from: true,
            except_columns: []
          )
        ] do
      executable_sql = String.replace(sql, ~r/--[^\r\n]*/, "")

      assert executable_sql =~
               "NULLIF(current_setting('#{@actor_guc}', true), '')::jsonb",
             "generated capture SQL must read the pinned actor GUC in the transaction insert"
    end
  end

  defp literal_query_arguments(source) do
    ast = Code.string_to_quoted!(source)

    {_ast, queries} =
      Macro.prewalk(ast, [], fn
        {{:., _, [_receiver, :query!]}, _, [query | _]} = node, acc when is_binary(query) ->
          {node, [query | acc]}

        node, acc ->
          {node, acc}
      end)

    queries
  end

  defp assert_named_call_sites!(sources, name, expected) do
    actual =
      sources
      |> Enum.map(fn {path, source} -> {path, named_call_count(source, name)} end)
      |> Enum.reject(fn {_path, count} -> count == 0 end)
      |> Map.new()

    assert actual == expected,
           "#{name} production call sites changed; expected=#{inspect(expected)} " <>
             "actual=#{inspect(actual)}"
  end

  defp named_call_count(source, name) do
    ast = Code.string_to_quoted!(source)
    function = name |> String.split(".") |> List.last() |> String.to_existing_atom()

    {_ast, count} =
      Macro.prewalk(ast, 0, fn
        {{:., _, [{:__aliases__, _, parts}, ^function]}, _, _} = node, acc
        when is_list(parts) ->
          {node, if(List.last(parts) == :Naming, do: acc + 1, else: acc)}

        node, acc ->
          {node, acc}
      end)

    count
  end
end
