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
  default global `threadline_capture_changes()` trigger body **unless** the table
  has `:exclude` / `:mask` rules under `config :threadline, :trigger_capture` (see
  README).

  ## Redaction (`config :threadline, :trigger_capture`)

  At task start the host app config is loaded (`Mix.Task.run("app.config", [])`).
  Per-table entries under `:tables` may set `:exclude`, `:mask`, optional
  `:mask_placeholder`, `:store_changed_from`, and `:except_columns`. Overlap
  between `:exclude` and `:mask` is validated with `Threadline.Capture.RedactionPolicy`
  before writing the migration.

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
  recursive loops (D-10, CAP-10).
  """

  use Mix.Task
  import Mix.Generator

  alias Threadline.Capture.RedactionPolicy
  alias Threadline.Capture.TriggerSQL

  @audit_tables ~w(audit_transactions audit_changes)

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

    forbidden = Enum.filter(tables, &(&1 in @audit_tables))

    if forbidden != [] do
      Mix.raise(
        "Cannot install audit triggers on Threadline's own tables: #{Enum.join(forbidden, ", ")}. " <>
          "This would cause a recursive audit loop (CAP-10)."
      )
    end

    cli_store_changed_from = Keyword.get(opts, :store_changed_from, false)

    cli_except_columns =
      opts
      |> Keyword.get(:except_columns, "")
      |> parse_except_columns()

    capture_tables = load_trigger_capture_tables()
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

      table_suffix = tables |> Enum.join("_")
      file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")

      create_file(file, migration_content(table_specs))
      Mix.shell().info("Run `mix ecto.migrate` to install the triggers.")
    end
  end

  defp load_trigger_capture_tables do
    case Application.get_env(:threadline, :trigger_capture) do
      nil ->
        %{}

      kw when is_list(kw) ->
        kw |> Keyword.get(:tables, %{}) |> normalize_tables_map()

      _ ->
        %{}
    end
  end

  defp normalize_tables_map(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), normalize_table_entry(v)}
      {k, v} when is_binary(k) -> {k, normalize_table_entry(v)}
    end)
  end

  defp normalize_table_entry(v) when is_list(v), do: v
  defp normalize_table_entry(v) when is_map(v), do: Enum.into(v, [])

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

  defp migration_content(table_specs) do
    function_ups =
      table_specs
      |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
      |> Enum.map(fn {t, %{opts: opts}} ->
        sql = TriggerSQL.install_function_for_table(t, opts)
        "    execute #{inspect(sql)}"
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    trigger_ups =
      table_specs
      |> Enum.map(fn {t, %{needs_per_table: per?}} ->
        trig =
          if per?,
            do: TriggerSQL.create_trigger(t, :per_table),
            else: TriggerSQL.create_trigger(t)

        "    execute #{inspect(trig)}"
      end)
      |> Enum.join("\n\n")

    trigger_downs =
      table_specs
      |> Enum.map(fn {t, _} ->
        "    execute #{inspect(TriggerSQL.drop_trigger(t))}"
      end)
      |> Enum.join("\n\n")

    function_downs =
      table_specs
      |> Enum.filter(fn {_t, %{needs_per_table: n?}} -> n? end)
      |> Enum.map(fn {t, _} ->
        "    execute #{inspect(TriggerSQL.drop_function_for_table(t))}"
      end)
      |> Enum.join("\n\n")

    tables = Enum.map(table_specs, &elem(&1, 0))
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
