defmodule Mix.Tasks.Threadline.Install do
  @shortdoc "Generates Threadline audit schema migration"

  @moduledoc """
  Generates an Ecto migration file for the Threadline audit schema.

  ## Usage

      mix threadline.install
      mix threadline.install --migrations-path priv/audit/migrations
      mix threadline.install --repo MyApp.AuditRepo

  ## Options

    * `--migrations-path PATH` - write the migrations to `PATH`, used as given
      and relative to the current directory. The repo is not loaded.
    * `--repo REPO` / `-r REPO` - the Ecto repo whose migrations directory to
      use. Give it once: Threadline's audit tables live in one repo.

  Without either option the directory is the first repo in your app's
  `:ecto_repos`: its `:priv` setting joined with `migrations`, or
  `priv/<repo name>/migrations` when `:priv` is unset. With no repo
  configured it is `priv/repo/migrations`. A configured repo that cannot be
  loaded also falls back to `priv/repo/migrations`, with a warning naming it.

  Unknown flags raise an error instead of being ignored. Positional arguments
  are ignored, so choose a directory or repo only with `--migrations-path` or
  `--repo`.

  In an umbrella, run the task from the child app's directory.

  The generated migration creates the `audit_transactions` and `audit_changes`
  tables plus the `threadline_capture_changes()` PL/pgSQL trigger function.

  Run `mix ecto.migrate` after generation to apply the migration.

  Running the task a second time prints a warning and exits without overwriting.
  """

  use Mix.Task
  import Mix.Generator

  alias Threadline.Mix.{MigrationsPath, MigrationVersion}

  # Written in this order, so each family's version sorts after the one before.
  @families [
    {"_threadline_audit_schema.exs", "Threadline audit schema migration",
     &Threadline.Capture.Migration.migration_content/0},
    {"_threadline_semantics_schema.exs", "Threadline semantics schema migration",
     &Threadline.Semantics.Migration.migration_content/0},
    {"_threadline_governance_schema.exs", "Threadline governance schema migration",
     &Threadline.Governance.Migration.migration_content/0}
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.config", [])

    {opts, _rest, invalid} =
      OptionParser.parse(args,
        strict: [migrations_path: :string, repo: :keep],
        aliases: [r: :repo]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{inspect(invalid)}")
    end

    path = MigrationsPath.resolve(opts)
    File.mkdir_p!(path)

    pending = Enum.reject(@families, fn {suffix, _, _} -> existing_migration?(path, suffix) end)

    # Every version is chosen before anything is written, so the files this
    # run creates can never share a version with each other or with a
    # migration already in the directory.
    versions = MigrationVersion.next(path, length(pending))

    {results, []} =
      Enum.map_reduce(@families, versions, fn {suffix, label, content_fun} = family, remaining ->
        if family in pending do
          [version | rest] = remaining
          {generate(path, version <> suffix, content_fun), rest}
        else
          Mix.shell().info("#{label} already exists — skipping.")
          {:skipped, remaining}
        end
      end)

    written = for {:written, file} <- results, do: file

    if written != [] do
      Mix.shell().info("Run `mix ecto.migrate` to apply the migration(s).")
    end

    recommend_storage_schema(results)
  end

  # Writes one migration under its full file name and reports the path written.
  defp generate(path, filename, content_fun) do
    file = Path.join(path, filename)
    create_file(file, content_fun.())
    {:written, file}
  end

  # The storage schema is frozen into the migrations at generation time.
  # Threadline defaults to the host's `public` schema because it cannot detect
  # where an existing install put its audit tables, which means a new install
  # gets no schema isolation unless it opts in. This advice runs AFTER
  # generation and has three branches:
  #
  #   * A fresh install (every migration written by this run) gets the
  #     dedicated-schema recipe, naming the files it just wrote: re-running
  #     the task skips any migration that already exists, so "set the key and
  #     re-run" alone would leave the config pointing at a dedicated schema
  #     while the generated migrations still target `public`.
  #   * A partial re-run (some migrations were already present) is told to
  #     keep `public`: the migrations already there target it, so switching
  #     now would split Threadline's tables across two schemas.
  #   * When nothing was written, or the key is configured, there is no advice.
  defp recommend_storage_schema(results) do
    written = for {:written, file} <- results, do: file

    cond do
      not is_nil(Application.get_env(:threadline, :storage_schema)) -> :ok
      written == [] -> :ok
      Enum.all?(results, &match?({:written, _}, &1)) -> recommend_dedicated_schema(written)
      true -> keep_public_schema()
    end
  end

  defp recommend_dedicated_schema(written) do
    files = Enum.map_join(written, "\n", &"    #{&1}")

    Mix.shell().info("""

    No `:storage_schema` is configured, so the migrations above put
    Threadline-owned tables and trigger functions in your `public` schema.

    For a NEW install a dedicated schema is recommended. To switch BEFORE
    running `mix ecto.migrate`:

      1. Delete the migration files this run just generated:

    #{files}

      2. Add to `config/config.exs`:

            config :threadline, storage_schema: "threadline"

      3. Re-run `mix threadline.install`.

    Deleting them first matters: the task skips any Threadline migration that
    already exists, so re-running without deleting would keep the `public`
    migrations while your config points at the dedicated schema. After
    `mix ecto.migrate` has run, moving schemas is deliberate migration work.
    """)
  end

  defp keep_public_schema do
    Mix.shell().info("""

    Existing Threadline migrations were found, so the new migration(s) above
    target `public` to match them. Keep `:storage_schema` unset.

    Setting `storage_schema: "threadline"` now would split Threadline's tables
    across two schemas. To move to a dedicated schema, delete ALL Threadline
    migrations before the first `mix ecto.migrate`, set the key, and re-run
    `mix threadline.install`. After migrating, moving schemas is deliberate
    migration work.
    """)
  end

  # Recursive, like Ecto's migrator and MigrationVersion.existing_versions/1, so
  # a Threadline migration a host moved into a subdirectory still counts.
  defp existing_migration?(path, suffix) do
    Path.wildcard(Path.join([path, "**", "*" <> suffix])) != []
  end
end
