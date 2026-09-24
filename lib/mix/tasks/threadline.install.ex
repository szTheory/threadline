defmodule Mix.Tasks.Threadline.Install do
  @shortdoc "Generates Threadline audit schema migration"

  @moduledoc """
  Generates an Ecto migration file for the Threadline audit schema.

  ## Usage

      mix threadline.install

  The generated migration creates the `audit_transactions` and `audit_changes`
  tables plus the `threadline_capture_changes()` PL/pgSQL trigger function.

  Run `mix ecto.migrate` after generation to apply the migration.

  Running the task a second time prints a warning and exits without overwriting.
  """

  use Mix.Task
  import Mix.Generator

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config", [])

    path = migrations_path()
    File.mkdir_p!(path)

    written =
      [
        generate(
          path,
          "_threadline_audit_schema.exs",
          "Threadline audit schema migration",
          &Threadline.Capture.Migration.migration_content/0
        ),
        generate(
          path,
          "_threadline_semantics_schema.exs",
          "Threadline semantics schema migration",
          &Threadline.Semantics.Migration.migration_content/0
        ),
        generate(
          path,
          "_threadline_governance_schema.exs",
          "Threadline governance schema migration",
          &Threadline.Governance.Migration.migration_content/0
        )
      ]
      |> Enum.reject(&is_nil/1)

    if written != [] do
      Mix.shell().info("Run `mix ecto.migrate` to apply the migration(s).")
    end

    recommend_dedicated_storage_schema(written)
  end

  # Returns the path of the migration it wrote, or nil when one already exists.
  defp generate(path, suffix, label, content_fun) do
    if existing_migration?(path, suffix) do
      Mix.shell().info("#{label} already exists — skipping.")
      nil
    else
      file = Path.join(path, "#{timestamp()}#{suffix}")
      create_file(file, content_fun.())
      file
    end
  end

  # The storage schema is frozen into the migrations at generation time.
  # Threadline defaults to the host's `public` schema because it cannot detect
  # where an existing install put its audit tables, which means a new install
  # gets no schema isolation unless it opts in. This advice runs AFTER
  # generation and names the files it just wrote: re-running the task skips any
  # migration that already exists, so "set the key and re-run" alone would leave
  # the config pointing at a dedicated schema while the generated migrations
  # still target `public`. When nothing was written (an existing install), the
  # advice is withheld — `public` is exactly what such an install already has.
  defp recommend_dedicated_storage_schema([]), do: :ok

  defp recommend_dedicated_storage_schema(written) do
    if is_nil(Application.get_env(:threadline, :storage_schema)) do
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

      Existing installs need no action: `public` is the default precisely so an
      upgrade keeps reading the tables it already has.
      """)
    end
  end

  defp migrations_path do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> then(fn app ->
      app_env = Application.get_env(app, :ecto_repos, [])

      case app_env do
        [repo | _] ->
          repo_migrations_path(repo)

        [] ->
          "priv/repo/migrations"
      end
    end)
  rescue
    _ -> "priv/repo/migrations"
  end

  # Called inside migrations_path/0, so its rescue still covers a raising repo.
  defp repo_migrations_path(repo) do
    case repo.config()[:priv] do
      nil ->
        Path.join(
          "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}",
          "migrations"
        )

      p ->
        Path.join(p, "migrations")
    end
  end

  defp existing_migration?(path, suffix) do
    path
    |> File.ls!()
    |> Enum.any?(&String.ends_with?(&1, suffix))
  rescue
    _ -> false
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: "0#{i}"
  defp pad(i), do: "#{i}"
end
