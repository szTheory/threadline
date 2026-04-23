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
    path = migrations_path()
    File.mkdir_p!(path)

    if existing_migration?(path) do
      Mix.shell().info("Threadline audit schema migration already exists — skipping.")
    else
      file = Path.join(path, "#{timestamp()}_threadline_audit_schema.exs")
      create_file(file, Threadline.Capture.Migration.migration_content())
      Mix.shell().info("Run `mix ecto.migrate` to apply the migration.")
    end
  end

  defp migrations_path do
    Mix.Project.config()
    |> Keyword.get(:app)
    |> then(fn app ->
      app_env = Application.get_env(app, :ecto_repos, [])

      case app_env do
        [repo | _] ->
          priv =
            case repo.config()[:priv] do
              nil -> "priv/#{repo |> Module.split() |> List.last() |> Macro.underscore()}"
              p -> p
            end

          Path.join(priv, "migrations")

        [] ->
          "priv/repo/migrations"
      end
    end)
  rescue
    _ -> "priv/repo/migrations"
  end

  defp existing_migration?(path) do
    path
    |> File.ls!()
    |> Enum.any?(&String.ends_with?(&1, "_threadline_audit_schema.exs"))
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
