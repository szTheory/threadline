defmodule Mix.Tasks.Threadline.Incident do
  @shortdoc "Displays what happened in a transaction (human-readable or JSON)"

  @moduledoc """
  Loads application config, starts the configured Ecto repo, and fetches
  the incident bundle for a given transaction ID.

  ## Arguments

  - **`transaction_id`** (required) — The ID of the transaction to query.

  ## Flags

  - **`--json`** — Output the incident bundle as JSON, suppressing Elixir Logger output.
    Useful for piping to tools like `jq`.

  ## Examples

      mix threadline.incident 12345
      mix threadline.incident 12345 --json | jq .
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, args, _} = OptionParser.parse(argv, strict: [json: :boolean])

    transaction_id =
      case args do
        [id] -> id
        _ -> Mix.raise("threadline.incident requires exactly one argument: the transaction_id")
      end

    if opts[:json] do
      require Logger
      Logger.configure(level: :error)
    end

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    case Threadline.incident_bundle(transaction_id, repo: repo) do
      {:ok, bundle} ->
        if opts[:json] do
          IO.puts(Jason.encode!(bundle_to_map(bundle)))
        else
          print_human_readable(bundle)
        end

      {:error, :not_found} ->
        Mix.raise("threadline.incident: transaction not found: #{transaction_id}")
    end
  end

  defp print_human_readable(bundle) do
    IO.puts("Transaction: #{bundle.transaction.id}")

    actor_str =
      if bundle.transaction.actor_ref,
        do: inspect(Threadline.Semantics.ActorRef.to_map(bundle.transaction.actor_ref)),
        else: "nil"

    IO.puts("Actor: #{actor_str}")
    IO.puts("Changes:")

    for change <- bundle.changes do
      audit_change = change.linked_change.audit_change
      pk_str = if audit_change.table_pk, do: inspect(audit_change.table_pk), else: "none"
      IO.puts("  - #{audit_change.op} #{audit_change.table_name} (PK: #{pk_str})")
    end
  end

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise(
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run incident task."
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

  defp bundle_to_map(bundle) do
    %{
      transaction: transaction_to_map(bundle.transaction),
      action: action_to_map(bundle.action),
      changes: Enum.map(bundle.changes, &incident_change_to_map/1)
    }
  end

  defp transaction_to_map(tx) do
    actor_map = if tx.actor_ref, do: Threadline.Semantics.ActorRef.to_map(tx.actor_ref), else: nil

    %{
      id: tx.id,
      txid: tx.txid,
      occurred_at: tx.occurred_at,
      source: tx.source,
      meta: tx.meta,
      actor_ref: actor_map
    }
  end

  defp action_to_map(nil), do: nil

  defp action_to_map(action) do
    %{
      id: action.id,
      name: action.name,
      status: action.status,
      correlation_id: action.correlation_id,
      request_id: action.request_id
    }
  end

  defp incident_change_to_map(change) do
    audit_change = change.linked_change.audit_change

    %{
      audit_change: %{
        id: audit_change.id,
        table_schema: audit_change.table_schema,
        table_name: audit_change.table_name,
        table_pk: audit_change.table_pk,
        op: audit_change.op,
        data_after: audit_change.data_after,
        changed_fields: audit_change.changed_fields,
        changed_from: audit_change.changed_from,
        captured_at: audit_change.captured_at
      },
      change_diff: change.change_diff
    }
  end
end
