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

  ## Options

    * `--tables` — comma-separated list of table names (required)

  ## Guards

  The task exits non-zero if `audit_transactions` or `audit_changes` is in the
  table list. Installing audit triggers on Threadline's own tables would cause
  recursive loops (D-10, CAP-10).
  """

  use Mix.Task
  import Mix.Generator

  @audit_tables ~w(audit_transactions audit_changes)

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [tables: :string])

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

    path = "priv/repo/migrations"
    File.mkdir_p!(path)

    table_suffix = tables |> Enum.join("_")
    file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")

    create_file(file, migration_content(tables))
    Mix.shell().info("Run `mix ecto.migrate` to install the triggers.")
  end

  defp migration_content(tables) do
    trigger_ups =
      tables
      |> Enum.map(fn t ->
        "    execute #{inspect(Threadline.Capture.TriggerSQL.create_trigger(t))}"
      end)
      |> Enum.join("\n\n")

    trigger_downs =
      tables
      |> Enum.map(fn t ->
        "    execute #{inspect(Threadline.Capture.TriggerSQL.drop_trigger(t))}"
      end)
      |> Enum.join("\n\n")

    module_name = "ThreadlineTriggers#{Enum.map_join(tables, "", &Macro.camelize/1)}"

    """
    defmodule #{module_name} do
      use Ecto.Migration

      def up do
    #{trigger_ups}
      end

      def down do
    #{trigger_downs}
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
