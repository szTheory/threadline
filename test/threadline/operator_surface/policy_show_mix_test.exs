defmodule Threadline.OperatorSurface.PolicyShowMixTest do
  use Threadline.DataCase

  import ExUnit.CaptureIO

  alias Threadline.Capture.TriggerSQL

  @drift_table "threadline_policy_show_bravo"
  @introspect_table "threadline_policy_show_charlie"
  @match_table "threadline_policy_show_delta"
  @all_tables [@drift_table, @introspect_table, @match_table]

  setup_all do
    Enum.each(@all_tables, fn table ->
      Repo.query!("DROP TABLE IF EXISTS #{table}")

      Repo.query!("""
      CREATE TABLE #{table} (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        email text NOT NULL,
        password_hash text NOT NULL,
        display_name text NOT NULL DEFAULT ''
      )
      """)
    end)

    on_exit(fn ->
      Enum.each(@all_tables, fn table ->
        Repo.query!(TriggerSQL.drop_trigger(table))
        Repo.query!(TriggerSQL.drop_function_for_table(table))
        Repo.query!("DROP TABLE IF EXISTS #{table}")
      end)
    end)

    :ok
  end

  setup do
    original = Application.get_env(:threadline, :trigger_capture)

    Application.put_env(:threadline, :trigger_capture,
      tables: %{
        @drift_table => [mask: ["email"], mask_placeholder: "[REDACTED]"],
        @introspect_table => [],
        @match_table => [exclude: ["password_hash"], mask: ["email"]]
      }
    )

    Enum.each(@all_tables, fn table ->
      Repo.query!(TriggerSQL.drop_trigger(table))
      Repo.query!(TriggerSQL.drop_function_for_table(table))
    end)

    Repo.query!(
      TriggerSQL.install_function_for_table(@drift_table,
        mask: ["email"],
        mask_placeholder: "[DIFFERENT]",
        store_changed_from: true
      )
    )

    Repo.query!(TriggerSQL.create_trigger(@drift_table, :per_table))

    Repo.query!("""
    CREATE OR REPLACE FUNCTION threadline_capture_changes_#{@introspect_table}()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $threadline_trigger$
    BEGIN
      RETURN NEW;
    END;
    $threadline_trigger$
    """)

    Repo.query!(TriggerSQL.create_trigger(@introspect_table, :per_table))

    Repo.query!(
      TriggerSQL.install_function_for_table(@match_table,
        exclude: ["password_hash"],
        mask: ["email"],
        store_changed_from: true
      )
    )

    Repo.query!(TriggerSQL.create_trigger(@match_table, :per_table))

    Mix.Task.reenable("threadline.policy.show")

    on_exit(fn ->
      Enum.each(@all_tables, fn table ->
        Repo.query!(TriggerSQL.drop_trigger(table))
        Repo.query!(TriggerSQL.drop_function_for_table(table))
      end)

      if is_nil(original) do
        Application.delete_env(:threadline, :trigger_capture)
      else
        Application.put_env(:threadline, :trigger_capture, original)
      end
    end)

    :ok
  end

  describe "mix threadline.policy.show" do
    test "prints the locked columns, statuses, rerun hint, and canonical row order" do
      output =
        capture_io(fn ->
          Mix.Tasks.Threadline.Policy.Show.run([])
        end)

      assert output =~
               ~r/^Policy drift: \d+ drift detected, \d+ could not introspect, \d+ config matches deployed$/m

      assert output =~ ~r/^TABLE\s{2,}STATUS\s{2,}CONFIG\s{2,}DEPLOYED\s{2,}HINT\s*$/m
      assert output =~ "Drift detected"
      assert output =~ "Could not introspect"
      assert output =~ "Config matches deployed"
      assert output =~ "Rerun `mix threadline.gen.triggers` and apply the migration."
      assert output =~ "do not assume capture is aligned."

      bravo_index = byte_index(output, @drift_table)
      charlie_index = byte_index(output, @introspect_table)
      delta_index = byte_index(output, @match_table)

      assert bravo_index < charlie_index
      assert charlie_index < delta_index
    end

    test "returns success even when drift exists and never prints sample values" do
      output =
        capture_io(fn ->
          assert :ok = Mix.Tasks.Threadline.Policy.Show.run([])
        end)

      refute output =~ "alice@example.com"
    end

    test "--json emits the stable top-level contract and exact status enums" do
      output =
        capture_io(fn ->
          Mix.Tasks.Threadline.Policy.Show.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      assert parsed |> Map.keys() |> Enum.sort() ==
               [
                 "config_matches_deployed",
                 "could_not_introspect",
                 "drift_detected",
                 "schema",
                 "tables",
                 "total_tables"
               ]

      assert parsed["schema"] == "public"
      assert is_integer(parsed["total_tables"])
      assert parsed["total_tables"] >= 3
      assert is_integer(parsed["drift_detected"])
      assert is_integer(parsed["could_not_introspect"])
      assert is_integer(parsed["config_matches_deployed"])

      rows_by_table = Map.new(parsed["tables"], &{&1["table"], &1})

      assert Enum.map(parsed["tables"], & &1["table"])
             |> Enum.filter(&(&1 in @all_tables)) == [
               @drift_table,
               @introspect_table,
               @match_table
             ]

      assert rows_by_table[@drift_table]["status"] == "drift_detected"
      assert rows_by_table[@introspect_table]["status"] == "could_not_introspect"
      assert rows_by_table[@match_table]["status"] == "config_matches_deployed"

      for row <- parsed["tables"] do
        assert row |> Map.keys() |> Enum.sort() ==
                 ["configured", "deployed", "diff", "hint", "status", "table", "warning"]

        assert row["configured"] |> Map.keys() |> Enum.sort() ==
                 ["exclude", "mask", "mask_placeholder"]

        assert row["diff"] |> Map.keys() |> Enum.sort() == [
                 "exclude_only_in_config",
                 "exclude_only_in_deployed",
                 "mask_only_in_config",
                 "mask_only_in_deployed",
                 "placeholder_mismatch"
               ]
      end

      refute output =~ "alice@example.com"
      refute output =~ "hunter2"
    end
  end

  defp byte_index(haystack, needle) do
    case :binary.match(haystack, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected #{inspect(needle)} in output")
    end
  end
end
