defmodule Mix.Tasks.Threadline.Gen.RowHistoryIndex do
  @shortdoc "Generates a non-blocking migration that adds the row-history index"

  @moduledoc """
  Generates an Ecto migration that adds `audit_changes_row_history_idx` to an
  existing Threadline install.

  Run this once, after upgrading to a release that ships this task, if your
  install predates it. A new install already gets the index from
  `mix threadline.install`; this task exists for adopters upgrading from an
  earlier release.

  ## Usage

      mix threadline.gen.row_history_index

  Writes one migration using `CREATE INDEX CONCURRENTLY IF NOT EXISTS`, so it
  never blocks writes to `audit_changes` while it builds, even on a large,
  hot table. Run `mix ecto.migrate` to apply it.

  ## If the concurrent build fails partway

  A concurrent index build interrupted mid-way — the migration is killed, the
  connection drops, a duplicate is detected — leaves an INVALID index behind
  in PostgreSQL. `IF NOT EXISTS` then treats that INVALID index as already
  present and skips it on a retry, so the fix and a retry look like nothing
  happened. Drop the invalid index first, then rerun `mix ecto.migrate`:

      DROP INDEX CONCURRENTLY IF EXISTS <storage_schema>.audit_changes_row_history_idx;

  Rolling back the generated migration drops the index the same
  non-blocking way, with `DROP INDEX CONCURRENTLY IF EXISTS`.

  ## If you cannot run this task

  The raw SQL, run against your configured storage schema, is the fallback:

      CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_changes_row_history_idx
        ON <storage_schema>.audit_changes
        (table_schema, table_name, table_pk, captured_at DESC, id DESC);

  ## Options

  * `--migrations-path` — directory the migration is written to, used as given
    relative to the current directory. The repo is not loaded.
  * `--repo` / `-r` — one repo; the migration goes to that repo's migrations
    directory, the same place `mix threadline.install` writes.

  Without `--migrations-path` or `--repo`, the task uses the first repo in
  `:ecto_repos` and its `:priv` setting. A configured repo that cannot be
  loaded falls back to `priv/repo/migrations`, with a warning naming it.

  ## Rerunning

  Running this task again when a migration ending in
  `_threadline_row_history_index.exs` already exists in the directory writes
  nothing; it prints the existing file's path instead.
  """

  use Mix.Task
  import Mix.Generator

  alias Threadline.Capture.RowHistoryIndexSQL
  alias Threadline.Mix.{MigrationsPath, MigrationVersion}
  alias Threadline.StorageSchema

  @rerun_suffix "_threadline_row_history_index.exs"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.config", [])

    opts = parse_opts!(args)
    path = MigrationsPath.resolve(opts)

    case existing_migration(path) do
      nil ->
        write_migration!(path)

      file ->
        Mix.shell().info(
          "A row-history index migration already exists: #{file}. " <>
            "Nothing written; run `mix ecto.migrate` if it has not been applied yet."
        )
    end
  end

  defp parse_opts!(args) do
    {opts, _rest, invalid} =
      OptionParser.parse(args,
        strict: [migrations_path: :string, repo: :keep],
        aliases: [r: :repo]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{inspect(invalid)}")
    end

    opts
  end

  # Ecto discovers migrations by "<version>_<name>.exs"; this only needs to
  # find a prior run of this task, by its fixed name suffix, in any
  # subdirectory (mirroring MigrationVersion.existing/1's own wildcard).
  defp existing_migration(path) do
    [path, "**", "*#{@rerun_suffix}"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort()
    |> List.first()
  end

  defp write_migration!(path) do
    File.mkdir_p!(path)
    [version] = MigrationVersion.next(path, 1)
    file = Path.join(path, "#{version}_threadline_row_history_index.exs")

    create_file(file, migration_content())

    Mix.shell().info("Run `mix ecto.migrate` to install the index.")
  end

  # Frozen at generation time, exactly like every other Threadline-generated
  # migration: StorageSchema.get() is read now, not when `mix ecto.migrate`
  # eventually runs this file.
  defp migration_content do
    storage_schema = StorageSchema.get()
    opts = [storage_schema: storage_schema]
    qualified_index = StorageSchema.qualify(storage_schema, RowHistoryIndexSQL.index_name())

    """
    defmodule ThreadlineRowHistoryIndex do
      use Ecto.Migration

      @disable_ddl_transaction true
      @disable_migration_lock true

      # A concurrent build interrupted mid-way (killed migration, dropped
      # connection, duplicate key) leaves an INVALID index behind, which
      # `IF NOT EXISTS` then treats as already present and skips on a retry.
      # If `mix ecto.migrate` reports this migration failed, drop the
      # invalid index before rerunning it:
      #   DROP INDEX CONCURRENTLY IF EXISTS #{qualified_index};
      def up do
        execute(#{inspect(RowHistoryIndexSQL.create_concurrently_sql(opts), printable_limit: :infinity, limit: :infinity)})
      end

      def down do
        execute(#{inspect(RowHistoryIndexSQL.drop_concurrently_sql(opts), printable_limit: :infinity, limit: :infinity)})
      end
    end
    """
  end
end
