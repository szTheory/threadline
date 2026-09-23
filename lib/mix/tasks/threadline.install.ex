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

    recommend_dedicated_storage_schema()

    path = migrations_path()
    File.mkdir_p!(path)

    capture_written =
      if existing_capture_migration?(path) do
        Mix.shell().info("Threadline audit schema migration already exists — skipping.")
        false
      else
        file = Path.join(path, "#{timestamp()}_threadline_audit_schema.exs")
        create_file(file, Threadline.Capture.Migration.migration_content())
        true
      end

    semantics_written =
      if existing_semantics_migration?(path) do
        Mix.shell().info("Threadline semantics schema migration already exists — skipping.")
        false
      else
        file = Path.join(path, "#{timestamp()}_threadline_semantics_schema.exs")
        create_file(file, Threadline.Semantics.Migration.migration_content())
        true
      end

    governance_written =
      if existing_governance_migration?(path) do
        Mix.shell().info("Threadline governance schema migration already exists — skipping.")
        false
      else
        file = Path.join(path, "#{timestamp()}_threadline_governance_schema.exs")
        create_file(file, Threadline.Governance.Migration.migration_content())
        true
      end

    if capture_written or semantics_written or governance_written do
      Mix.shell().info("Run `mix ecto.migrate` to apply the migration(s).")
    end
  end

  # The storage schema is frozen into the migrations this task is about to
  # generate, so this is the last moment a NEW install can make the choice
  # cheaply. Threadline defaults to the host's `public` schema because it
  # cannot detect where an existing install put its audit tables, which means a
  # new install gets no schema isolation unless it opts in here.
  defp recommend_dedicated_storage_schema do
    if is_nil(Application.get_env(:threadline, :storage_schema)) do
      Mix.shell().info("""

      No `:storage_schema` is configured, so Threadline-owned tables and trigger
      functions will be generated into your `public` schema.

      For a NEW install a dedicated schema is recommended:

          config :threadline, storage_schema: "threadline"

      Add that to `config/config.exs` and re-run `mix threadline.install` if you
      want it. The choice is frozen at generation time — changing the key later
      does not move objects the generated migrations already created, so moving
      afterwards is deliberate migration work.

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
          # Structural debt: priv case inside app-env case — extract priv-path resolution
          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          case repo.config()[:priv] do
            nil ->
              Path.join(
                "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}",
                "migrations"
              )

            p ->
              Path.join(p, "migrations")
          end

        [] ->
          "priv/repo/migrations"
      end
    end)
  rescue
    _ -> "priv/repo/migrations"
  end

  defp existing_capture_migration?(path) do
    path
    |> File.ls!()
    |> Enum.any?(&String.ends_with?(&1, "_threadline_audit_schema.exs"))
  rescue
    _ -> false
  end

  defp existing_semantics_migration?(path) do
    path
    |> File.ls!()
    |> Enum.any?(&String.ends_with?(&1, "_threadline_semantics_schema.exs"))
  rescue
    _ -> false
  end

  defp existing_governance_migration?(path) do
    path
    |> File.ls!()
    |> Enum.any?(&String.ends_with?(&1, "_threadline_governance_schema.exs"))
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
