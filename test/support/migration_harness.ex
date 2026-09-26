defmodule Threadline.Test.MigrationHarness do
  @moduledoc """
  Runs a migration written by `mix threadline.gen.triggers` the way an adopter
  does: the generated file is compiled and applied with `Ecto.Migrator`, so its
  statements run in one DDL transaction and any WARNING PostgreSQL returns is
  logged by `ecto_sql`, as it is during `mix ecto.migrate`.

  Catalog helpers identify triggers and functions by catalog names, never by
  the text rendering of a `regprocedure`, which varies with `search_path`.
  Table names are sent as text and cast, because Postgrex encodes a bare
  `regclass` parameter as an oid.
  """

  import ExUnit.CaptureLog

  require Logger

  alias Mix.Tasks.Threadline.Gen.Triggers
  alias Threadline.StorageSchema
  alias Threadline.Test.Repo

  @migrations "priv/repo/migrations"

  @doc "Runs the generator in `tmp` and returns the one migration file it wrote."
  def generate!(tmp, args) do
    before = migration_files(tmp)
    File.cd!(tmp, fn -> Triggers.run(args) end)

    case migration_files(tmp) -- before do
      [file] -> file
      other -> raise "expected one new migration file, got: #{inspect(other)}"
    end
  end

  @doc "Every migration file in `tmp`'s migrations directory."
  def migration_files(tmp) do
    [tmp, @migrations, "*.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort()
  end

  @doc """
  Applies the migration's `up` through `Ecto.Migrator.up/4` and returns
  `{result, log}`, where `log` holds what was logged at warning level or above.
  A `Postgrex.Error` raised by the migration propagates.
  """
  def migrate_up(file), do: migrate(file, :up)

  @doc "Rolls the migration back through `Ecto.Migrator.down/4`; see `migrate_up/1`."
  def migrate_down(file), do: migrate(file, :down)

  defp migrate(file, direction) do
    module = load!(file)
    version = version(file)
    parent = self()

    log =
      with_warnings_logged(fn ->
        capture_log([level: :warning], fn ->
          result = apply(Ecto.Migrator, direction, [Repo, version, module])
          send(parent, {__MODULE__, :result, result})
        end)
      end)

    receive do
      {__MODULE__, :result, result} -> {result, log}
    end
  end

  # capture_log/2 sees only what Logger lets through. Code run earlier in the
  # suite can raise the global level (a `--json` mix task sets :error), which
  # would hide the WARNINGs a migration logs.
  defp with_warnings_logged(fun) do
    previous = Logger.level()

    if Logger.compare_levels(previous, :warning) == :gt do
      Logger.configure(level: :warning)

      try do
        fun.()
      after
        Logger.configure(level: previous)
      end
    else
      fun.()
    end
  end

  @doc "Forgets each migration's version and unloads its compiled module."
  def cleanup!(files) do
    for file <- files do
      Repo.query!("DELETE FROM schema_migrations WHERE version = $1", [version(file)])

      if module = module_name(file) do
        :code.purge(module)
        :code.delete(module)
      end
    end

    :ok
  end

  # Reuses the module when it is already loaded (for example by migrate_up
  # before migrate_down), so a rollback runs the exact code that was applied.
  defp load!(file) do
    module = module_name(file)

    if module && Code.ensure_loaded?(module) do
      module
    else
      [{module, _binary}] = Code.compile_file(file)
      module
    end
  end

  defp module_name(file) do
    case Regex.run(~r/defmodule\s+([A-Za-z0-9_.]+)\s+do/, File.read!(file)) do
      [_, name] -> Module.concat([name])
      nil -> nil
    end
  end

  defp version(file) do
    {version, "_" <> _} = file |> Path.basename() |> Integer.parse()
    version
  end

  @doc "The `{schema, function}` the table's Threadline trigger calls, or `nil`."
  def trigger_function(schema, table) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT n.nspname, p.proname
        FROM pg_trigger t
        JOIN pg_proc p ON p.oid = t.tgfoid
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE t.tgrelid = $1::text::regclass
          AND NOT t.tgisinternal
          AND t.tgname LIKE 'threadline_audit_%'
        """,
        [regclass_text(schema, table)]
      )

    case rows do
      [] -> nil
      [[nsp, proname]] -> {nsp, proname}
    end
  end

  @doc "`[{tgname, tgenabled}]` for every Threadline trigger on the table."
  def threadline_triggers(schema, table) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT t.tgname, t.tgenabled::text
        FROM pg_trigger t
        WHERE t.tgrelid = $1::text::regclass
          AND NOT t.tgisinternal
          AND t.tgname LIKE 'threadline_audit_%'
        ORDER BY t.tgname
        """,
        [regclass_text(schema, table)]
      )

    Enum.map(rows, fn [name, enabled] -> {name, enabled} end)
  end

  @doc "Sorted `\"schema.table\"` of every table whose trigger calls the storage-schema function."
  def function_users(proname) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT DISTINCT tn.nspname || '.' || c.relname
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace tn ON tn.oid = c.relnamespace
        JOIN pg_proc p ON p.oid = t.tgfoid
        JOIN pg_namespace pn ON pn.oid = p.pronamespace
        WHERE pn.nspname = $1 AND p.proname = $2
        ORDER BY 1
        """,
        [StorageSchema.get(), proname]
      )

    Enum.map(rows, &hd/1)
  end

  @doc "Whether the storage schema has a function of that name."
  def function_exists?(proname) do
    %{rows: [[count]]} =
      Repo.query!(
        """
        SELECT count(*)
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1 AND p.proname = $2
        """,
        [StorageSchema.get(), proname]
      )

    count > 0
  end

  @doc "The storage-schema function's definition from `pg_get_functiondef`."
  def function_definition(proname) do
    %{rows: [[definition]]} =
      Repo.query!(
        """
        SELECT pg_get_functiondef(p.oid)
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1 AND p.proname = $2
        """,
        [StorageSchema.get(), proname]
      )

    definition
  end

  defp regclass_text(schema, table),
    do: StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)
end
