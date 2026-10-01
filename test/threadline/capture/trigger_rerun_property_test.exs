defmodule Threadline.Capture.TriggerRerunPropertyTest do
  @moduledoc """
  DB-backed property proving that any chain of 1-4 real
  `mix threadline.gen.triggers` runs -- any mix of default and per-table
  modes -- rolls back to zero orphaned capture functions. Every iteration
  applies real DDL through `Ecto.Migrator` against the live Postgres
  catalog, so `max_runs` is capped at 20 rather than the hundreds a pure
  property affords. `@max_runs` is a named attribute so a later phase's
  environment-driven scale knob can swap it in one line.
  """

  use Threadline.DataCase, async: false
  use ExUnitProperties

  import Threadline.Test.TriggerRunGenerators

  alias Threadline.Capture.Naming
  alias Threadline.StorageSchema
  alias Threadline.Test.MigrationHarness, as: Harness

  @max_runs 20

  property "a random chain of 1-4 runs rolls back to zero new orphaned capture functions" do
    check all(runs <- run_sequence(), max_runs: @max_runs) do
      n = System.unique_integer([:positive, :monotonic])
      table = "trp_" <> Integer.to_string(n)

      tmp =
        Path.join(
          System.tmp_dir!(),
          "threadline-trigger-rerun-property-" <> Integer.to_string(n)
        )

      File.mkdir_p!(tmp)

      previous_shell = Mix.shell()
      previous_capture = Application.fetch_env(:threadline, :trigger_capture)
      Mix.shell(Mix.Shell.Process)

      Repo.query!("""
      CREATE TABLE IF NOT EXISTS #{table} (
        id     bigserial PRIMARY KEY,
        name   text,
        secret text,
        notes  text
      )
      """)

      baseline = Harness.orphan_capture_functions()

      try do
        files =
          Enum.map(runs, fn run ->
            cfg =
              case run do
                :default -> []
                {:per_table, :store_changed_from} -> []
                {:per_table, :exclude} -> [exclude: ["notes"]]
                {:per_table, :mask} -> [mask: ["secret"]]
              end

            Application.put_env(:threadline, :trigger_capture, tables: %{table => cfg})

            args =
              if match?({:per_table, :store_changed_from}, run) do
                ["--tables", table, "--store-changed-from"]
              else
                ["--tables", table]
              end

            file = Harness.generate!(tmp, args)
            assert {:ok, _log} = Harness.migrate_up(file)
            file
          end)

        {nsp, fname} = Harness.trigger_function("public", table)
        assert nsp == StorageSchema.get()

        if List.last(runs) == :default do
          assert fname == "threadline_capture_changes"
        else
          assert String.starts_with?(fname, "threadline_capture_changes_")
        end

        assert Harness.orphan_capture_functions() -- baseline == []

        files
        |> Enum.reverse()
        |> Enum.reduce(length(files), fn file, remaining ->
          assert {:ok, _} = Harness.migrate_down(file)

          if remaining > 1 do
            assert Harness.trigger_function("public", table) == {nsp, fname}
            assert Harness.orphan_capture_functions() -- baseline == []
          else
            assert Harness.threadline_triggers("public", table) == []
            assert Harness.orphan_capture_functions() -- baseline == []
          end

          remaining - 1
        end)
      after
        Harness.cleanup!(Harness.migration_files(tmp))
        Repo.query!("DROP TABLE IF EXISTS #{table} CASCADE")

        Repo.query!(
          "DROP FUNCTION IF EXISTS " <>
            StorageSchema.function(Naming.function_name(table)) <> "()"
        )

        Mix.shell(previous_shell)

        case previous_capture do
          {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
          :error -> Application.delete_env(:threadline, :trigger_capture)
        end

        File.rm_rf!(tmp)

        drain_mix_shell_messages()
      end
    end
  end

  defp drain_mix_shell_messages do
    receive do
      {:mix_shell, _, _} -> drain_mix_shell_messages()
    after
      0 -> :ok
    end
  end
end
