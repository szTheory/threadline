defmodule Mix.Tasks.Threadline.Gen.Triggers do
  @shortdoc "Generates an Ecto migration that installs audit triggers on tables"

  @moduledoc """
  Generates an Ecto migration that installs Threadline audit triggers on the
  specified tables.

  ## Usage

      mix threadline.gen.triggers --tables users
      mix threadline.gen.triggers --tables users,posts,comments

  Each invocation produces one migration file containing `CREATE TRIGGER`
  statements for all listed tables. Run `mix ecto.migrate` to apply.

  The trigger calls `threadline_capture_changes()`, which must already be
  installed via `mix threadline.install`.

  With before-values capture for opted-in tables:

      mix threadline.gen.triggers --tables posts --store-changed-from
      mix threadline.gen.triggers --tables posts --store-changed-from --except-columns secret_token,internal_score

  That emits per-table functions `threadline_capture_changes_<table>()` and wires
  triggers to them. Migrations generated without `--store-changed-from` keep the
  default global `threadline_capture_changes()` trigger body.

  ## Options

    * `--tables` — comma-separated list of table names (required)
    * `--store-changed-from` — emit per-table capture functions that persist sparse
      `changed_from` JSON on UPDATE (default: off)
    * `--except-columns` — comma-separated column names excluded from both
      `changed_fields` and `changed_from` when `--store-changed-from` is set
      (alphanumeric and underscore only)

  ## Guards

  The task exits non-zero if `audit_transactions` or `audit_changes` is in the
  table list. Installing audit triggers on Threadline's own tables would cause
  recursive loops (D-10, CAP-10).
  """

  use Mix.Task
  import Mix.Generator

  @audit_tables ~w(audit_transactions audit_changes)

  @column_name ~r/^[A-Za-z0-9_]+$/

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          tables: :string,
          store_changed_from: :boolean,
          except_columns: :string
        ]
      )

    tables =
      opts
      |> Keyword.get(:tables, "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)

    if tables == [] do
      Mix.raise("--tables is required. Example: mix threadline.gen.triggers --tables users,posts")
    end

    forbidden = Enum.filter(tables, &(&1 in @audit_tables))

    if forbidden != [] do
      Mix.raise(
        "Cannot install audit triggers on Threadline's own tables: #{Enum.join(forbidden, ", ")}. " <>
          "This would cause a recursive audit loop (CAP-10)."
      )
    end

    store_changed_from = Keyword.get(opts, :store_changed_from, false)

    except_columns =
      opts
      |> Keyword.get(:except_columns, "")
      |> parse_except_columns()

    path = "priv/repo/migrations"
    File.mkdir_p!(path)

    table_suffix = tables |> Enum.join("_")
    file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")

    create_file(file, migration_content(tables, store_changed_from, except_columns))
    Mix.shell().info("Run `mix ecto.migrate` to install the triggers.")
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

  defp migration_content(tables, store_changed_from, except_columns) do
    function_ups =
      if store_changed_from do
        tables
        |> Enum.map(fn t ->
          sql =
            Threadline.Capture.TriggerSQL.install_function_for_table(t,
              store_changed_from: true,
              except_columns: except_columns
            )

          "    execute #{inspect(sql)}"
        end)
        |> Enum.join("\n\n")
      else
        ""
      end

    trigger_ups =
      tables
      |> Enum.map(fn t ->
        trig =
          if store_changed_from,
            do: Threadline.Capture.TriggerSQL.create_trigger(t, :per_table),
            else: Threadline.Capture.TriggerSQL.create_trigger(t)

        "    execute #{inspect(trig)}"
      end)
      |> Enum.join("\n\n")

    trigger_downs =
      tables
      |> Enum.map(fn t ->
        "    execute #{inspect(Threadline.Capture.TriggerSQL.drop_trigger(t))}"
      end)
      |> Enum.join("\n\n")

    function_downs =
      if store_changed_from do
        tables
        |> Enum.map(fn t ->
          "    execute #{inspect(Threadline.Capture.TriggerSQL.drop_function_for_table(t))}"
        end)
        |> Enum.join("\n\n")
      else
        ""
      end

    module_name = "ThreadlineTriggers#{Enum.map_join(tables, "", &Macro.camelize/1)}"

    up_body =
      [function_ups, trigger_ups]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    down_parts =
      [trigger_downs, function_downs]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    """
    defmodule #{module_name} do
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

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"
end
