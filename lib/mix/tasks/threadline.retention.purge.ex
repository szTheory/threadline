defmodule Mix.Tasks.Threadline.Retention.Purge do
  @shortdoc "Runs Threadline.Retention.purge/1 (batched retention delete; use --dry-run first)"

  @moduledoc """
  Delegates to `Threadline.Retention.purge/1` after loading application config and
  starting the configured Ecto repo (same resolution pattern as `mix threadline.verify_coverage`).

  ## Configuration

  Purge is a no-op (Mix **raises**) unless **`config :threadline, :retention, enabled: true`**
  and the rest of the map passes `Threadline.Retention.Policy.validate_config!/1`.

  ## Flags

  - **`--batch-size`** — rows per delete pass (default `500` in `purge/1`).
  - **`--max-batches`** — safety cap on outer iterations.
  - **`--dry-run`** — counts eligible `audit_changes` / empty `audit_transactions` only; **no deletes**.
  - **`--execute`** — **required when `MIX_ENV=prod`**, in addition to `enabled: true`, so production
    crons cannot delete data from a mistyped command alone.

  ## Examples

      mix threadline.retention.purge --dry-run
      mix threadline.retention.purge --batch-size 200 --max-batches 50

  Production (after explicit config review):

      MIX_ENV=prod mix threadline.retention.purge --execute --batch-size 500
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [
          batch_size: :integer,
          max_batches: :integer,
          dry_run: :boolean,
          execute: :boolean
        ],
        aliases: [d: :dry_run]
      )

    if Mix.env() == :prod and opts[:execute] != true do
      Mix.raise(
        "threadline.retention.purge: in MIX_ENV=prod pass --execute to confirm this destructive operation."
      )
    end

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    purge_opts =
      [repo: repo, dry_run: opts[:dry_run] == true]
      |> maybe_put(:batch_size, opts[:batch_size])
      |> maybe_put(:max_batches, opts[:max_batches])

    case Threadline.Retention.purge(purge_opts) do
      {:error, :disabled} ->
        Mix.raise(
          "threadline.retention.purge: retention purge is disabled — set config :threadline, :retention, enabled: true."
        )

      summary ->
        Mix.shell().info(inspect(summary, pretty: true, limit: :infinity))
    end
  end

  defp maybe_put(kw, _k, nil), do: kw
  defp maybe_put(kw, k, v), do: Keyword.put(kw, k, v)

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise(
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run retention purge."
        )

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
