defmodule Mix.Tasks.Threadline.Continuity do
  @shortdoc "Brownfield capture cutover — honest T0; see guides/brownfield-continuity.md"

  @moduledoc """
  Brownfield capture cutover helper — honest T0 semantics (see `guides/brownfield-continuity.md`).

  There is **no pre-trigger history**: `audit_changes` remains empty until the first
  trigger-backed mutation after capture is installed.

  ## Usage

      mix threadline.continuity --dry-run
      mix threadline.continuity --table my_app_table

  With `--dry-run`, prints the cutover explanation only (no database writes).

  With `--table`, validates the table exists in `public` and appears as `{:covered, _}`
  in `Threadline.Health.trigger_coverage/1`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [dry_run: :boolean, table: :string],
        aliases: [d: :dry_run]
      )

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    if opts[:dry_run] do
      {:ok, text} = Threadline.Continuity.explain_cutover(repo: repo)
      Mix.shell().info(text)
      Mix.shell().info("")
      Mix.shell().info("(dry-run — no pre-trigger history; no writes performed.)")
    else
      {:ok, text} = Threadline.Continuity.explain_cutover(repo: repo)
      Mix.shell().info(text)
      Mix.shell().info("")

      case opts[:table] do
        nil ->
          Mix.shell().info(
            "Tip: pass `--table <name>` to assert capture readiness, or `--dry-run` for explanation only."
          )

        table ->
          Threadline.Continuity.assert_capture_ready!(table, repo: repo)

          Mix.shell().info(
            "Table #{inspect(table)} is already covered by Threadline capture (capture ready)."
          )
      end
    end
  end

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise("Threadline: set :ecto_repos in config — no Ecto repository is configured.")

      [repo | _] ->
        repo
    end
  end

  defp ensure_repo_started!(repo) do
    case repo.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, reason} -> Mix.raise("Could not start #{inspect(repo)}: #{inspect(reason)}")
    end
  end
end
