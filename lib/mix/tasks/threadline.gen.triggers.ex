defmodule Mix.Tasks.Threadline.Gen.Triggers do
  @shortdoc "Generates an Ecto migration that installs audit triggers on tables"

  @moduledoc """
  Generates an Ecto migration that installs Threadline audit triggers on the
  specified tables.

  ## Usage

      mix threadline.gen.triggers --tables users
      mix threadline.gen.triggers --tables users,posts,comments

  Each invocation writes one migration whose statements create or replace the
  audit trigger on each listed table (`CREATE OR REPLACE TRIGGER`, PostgreSQL 14
  or later). Run `mix ecto.migrate` to apply.

  The trigger calls `threadline_capture_changes()`, which must already be
  installed via `mix threadline.install`.

  With before-values capture for opted-in tables:

      mix threadline.gen.triggers --tables posts --store-changed-from
      mix threadline.gen.triggers --tables posts --store-changed-from --except-columns secret_token,internal_score

  That emits per-table functions `threadline_capture_changes_<table>()` and wires
  triggers to them. Migrations generated without `--store-changed-from` keep the
  default global `threadline_capture_changes()` trigger body **unless** the table
  has `:exclude` / `:mask` rules under `config :threadline, :trigger_capture` (see
  README).

  ## Redaction (`config :threadline, :trigger_capture`)

  At task start the host app config is loaded (`Mix.Task.run("app.config", [])`).
  Per-table entries under `:tables` may set `:exclude`, `:mask`, optional
  `:mask_placeholder`, `:store_changed_from`, and `:except_columns`. Overlap
  between `:exclude` and `:mask` is validated before writing the migration.

  ## Rerunning

  Run the task again for tables that already have a trigger migration, for
  example after changing `:trigger_capture` redaction rules or to clear a
  `Drift detected` status. It writes a new migration with a numbered name, such
  as `threadline_triggers_posts_2`, and a matching numbered module. The new
  migration replaces the trigger in place, so capture has no gap.

  A table that returns to the default trigger also drops its leftover per-table
  capture function. That drop never cascades. On a table that never had one,
  PostgreSQL prints a harmless NOTICE that the function does not exist. The
  drop is skipped when `threadline_capture_changes_<table>` is longer than
  PostgreSQL's 63-byte identifier limit, because the truncated name can belong
  to another table's function.

  Rolling back a rerun migration keeps capture on for the tables it re-pointed.
  Rolling back does not restore the earlier capture policy: the trigger keeps the
  policy the rerun installed. If the rerun had removed redaction rules, a rolled
  back rerun leaves capture running unredacted until you regenerate, and
  `mix threadline.policy.show` flags the mismatch. The generated `down` says the
  same in a comment. To stop capturing a table, write a migration that drops its
  trigger.

  ## Options

  * `--tables` — comma-separated list of table names (required)
  * `--store-changed-from` — emit per-table capture functions that persist sparse
    `changed_from` JSON on UPDATE (default: off)
  * `--except-columns` — comma-separated column names excluded from both
    `changed_fields` and `changed_from` when `--store-changed-from` is set
    (alphanumeric and underscore only). Merged with `:except_columns` from config.
  * `--dry-run` — print `table=… exclude=… mask=…` per table and skip writing a migration

  ## Guards

  The task exits non-zero if `audit_transactions` or `audit_changes` is in the
  table list. Installing audit triggers on Threadline's own tables would cause
  recursive loops in the audit tables themselves.
  """

  use Mix.Task
  import Mix.Generator

  alias Threadline.Capture.{RedactionPolicy, TriggerCaptureConfig, TriggerSQL}
  alias Threadline.Mix.{MigrationVersion, TriggerMigration}
  alias Threadline.StorageSchema

  @column_name ~r/^[A-Za-z0-9_]+$/

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.config", [])

    {opts, _rest, invalid} =
      OptionParser.parse(args,
        strict: [
          tables: :string,
          store_changed_from: :boolean,
          except_columns: :string,
          dry_run: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{inspect(invalid)}")
    end

    tables =
      opts
      |> Keyword.get(:tables, "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    if tables == [] do
      Mix.raise("--tables is required. Example: mix threadline.gen.triggers --tables users,posts")
    end

    forbidden = Enum.filter(tables, &StorageSchema.threadline_table?/1)

    if forbidden != [] do
      Mix.raise(
        "Cannot install audit triggers on Threadline's own tables: #{Enum.join(forbidden, ", ")}. " <>
          "This would cause a recursive audit loop."
      )
    end

    cli_store_changed_from = Keyword.get(opts, :store_changed_from, false)

    cli_except_columns =
      opts
      |> Keyword.get(:except_columns, "")
      |> parse_except_columns()

    capture_tables = TriggerCaptureConfig.load()
    dry_run? = Keyword.get(opts, :dry_run, false)

    table_specs =
      Enum.map(tables, fn table ->
        {table,
         build_table_capture_spec(
           table,
           cli_store_changed_from,
           cli_except_columns,
           capture_tables
         )}
      end)

    if dry_run? do
      Enum.each(table_specs, fn {table, spec} ->
        o = spec.opts
        exclude = Keyword.get(o, :exclude, [])
        mask = Keyword.get(o, :mask, [])
        Mix.shell().info("table=#{table} exclude=#{inspect(exclude)} mask=#{inspect(mask)}")
      end)

      Mix.shell().info("[dry-run] no migration file written")
    else
      path = "priv/repo/migrations"
      File.mkdir_p!(path)

      # Versioned after every migration already in the directory, so running
      # this right after `mix threadline.install` cannot repeat a version when
      # both write here. Install resolves the repo's own migrations path, so
      # with a custom `:priv`, or a repo module not named `Repo`, it writes to
      # a different directory.
      [version] = MigrationVersion.next(path, 1)
      scan = TriggerMigration.scan(path)
      suffixes = Enum.map(tables, &StorageSchema.host_table_suffix/1)
      {name, module} = TriggerMigration.resolve_name(suffixes, scan)
      file = Path.join(path, "#{version}_#{name}.exs")

      # Read before the new file is written, so only earlier migrations count.
      rerun_tables =
        Enum.filter(
          tables,
          &TriggerMigration.rerun?(StorageSchema.host_table_suffix(&1), scan.sources)
        )

      create_file(file, migration_content(table_specs, module, rerun_tables))

      if rerun_tables != [] do
        Mix.shell().info(
          "These tables already have a Threadline trigger migration: " <>
            Enum.join(rerun_tables, ", ") <>
            ". Rolling back the new migration keeps their capture on."
        )
      end

      Mix.shell().info("Run `mix ecto.migrate` to install the triggers.")
    end
  end

  defp build_table_capture_spec(table, cli_store_changed_from, cli_except_columns, capture_tables) do
    entry = Map.get(capture_tables, table, [])

    exclude = Keyword.get(entry, :exclude, [])
    mask = Keyword.get(entry, :mask, [])
    cfg_store_changed_from = Keyword.get(entry, :store_changed_from, false)
    cfg_except = Keyword.get(entry, :except_columns, [])

    merged_except = (cli_except_columns ++ cfg_except) |> Enum.uniq()
    store_changed_from = cli_store_changed_from or cfg_store_changed_from

    opts =
      [
        store_changed_from: store_changed_from,
        except_columns: merged_except,
        exclude: exclude,
        mask: mask
      ]
      |> maybe_put_mask_placeholder(Keyword.get(entry, :mask_placeholder))

    if exclude != [] or mask != [] do
      RedactionPolicy.validate!(opts)
    end

    needs_per_table = store_changed_from or exclude != [] or mask != []

    %{needs_per_table: needs_per_table, opts: opts}
  end

  defp maybe_put_mask_placeholder(kw, nil), do: kw

  defp maybe_put_mask_placeholder(kw, placeholder) when is_binary(placeholder) do
    Keyword.put(kw, :mask_placeholder, placeholder)
  end

  defp parse_except_columns(""), do: []

  defp parse_except_columns(raw) do
    raw
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn col ->
      if Regex.match?(@column_name, col) do
        col
      else
        Mix.raise(
          "--except-columns must list alphanumeric/underscore column names only; invalid: #{inspect(col)}"
        )
      end
    end)
  end

  defp migration_content(table_specs, module, rerun_tables) do
    function_ups =
      table_specs
      |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
      |> Enum.map(fn {t, %{opts: opts}} ->
        sql = TriggerSQL.install_function_for_table(t, opts)
        "    execute #{inspect(sql)}"
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    # A table on the default trigger drops any per-table capture function left
    # by an earlier migration. The drop comes after the trigger is re-pointed
    # and does not cascade, so it fails loudly instead of removing a trigger
    # that still uses the function. It is skipped when the function name is
    # longer than 63 bytes: PostgreSQL would truncate it, and the truncated
    # name can belong to another table's live per-table function.
    trigger_ups =
      Enum.map_join(table_specs, "\n\n", fn
        {t, %{needs_per_table: true}} ->
          "    execute #{inspect(TriggerSQL.create_trigger(t, :per_table))}"

        {t, %{needs_per_table: false}} ->
          "    execute #{inspect(TriggerSQL.create_trigger(t))}" <> orphan_function_drop(t)
      end)

    # Rolling back only undoes what this migration was first to install. A
    # table that already had a trigger migration keeps its trigger, because
    # the earlier migration is still applied and still expects capture on.
    first_run_specs = Enum.reject(table_specs, fn {t, _} -> t in rerun_tables end)

    trigger_downs =
      Enum.map_join(first_run_specs, "\n\n", fn {t, _} ->
        "    execute #{inspect(TriggerSQL.drop_trigger(t))}"
      end)

    function_downs =
      first_run_specs
      |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
      |> Enum.map_join("\n\n", fn {t, _} ->
        "    execute #{inspect(TriggerSQL.drop_function_for_table(t))}"
      end)

    up_body =
      [function_ups, trigger_ups]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    down_parts =
      [rerun_rollback_comment(rerun_tables), trigger_downs, function_downs]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    """
    defmodule #{module} do
      use Ecto.Migration

      def up do
    #{up_body}
      end

      def down do
    #{down_parts}
      end
    end
    """
  end

  defp orphan_function_drop(table) do
    if TriggerSQL.per_table_function_fits?(table) do
      "\n\n    execute #{inspect(TriggerSQL.drop_orphan_function_for_table(table))}"
    else
      ""
    end
  end

  defp rerun_rollback_comment([]), do: ""

  defp rerun_rollback_comment(rerun_tables) do
    [
      "This migration replaced the audit trigger of #{Enum.join(rerun_tables, ", ")} in place.",
      "Rolling it back does not restore the earlier capture policy.",
      "Capture stays on with the policy this migration installed. To stop",
      "capturing a table, write a migration that drops its trigger, or roll back",
      "the migration that first installed it.",
      "If this migration removed redaction rules, rolling it back leaves capture",
      "running with them removed, so capture continues unredacted until you",
      "regenerate the trigger migration. `mix threadline.policy.show` and the",
      "redaction drift view flag that mismatch."
    ]
    |> Enum.map_join("\n", &("    # " <> &1))
  end
end
