defmodule Threadline.Retention do
  @moduledoc """
  Batched retention purge for `audit_changes` and empty `audit_transactions`.

  Requires **`config :threadline, :retention`** with **`enabled: true`** before any
  destructive run (see `Threadline.Retention.Policy`). Callers must pass **`repo:`**
  explicitly, matching `Threadline.Query` conventions.

  Cutoff is derived from `Threadline.Retention.Policy.cutoff_utc_datetime_usec!/0`
  unless you pass **`cutoff:`** (UTC `DateTime`, microsecond) for a stricter window
  than policy alone (operators only — must be **older** than the policy cutoff).
  """

  require Logger

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Retention.Policy

  @typedoc "Accumulator returned by `purge/1` on success (counts are cumulative)."
  @type purge_result :: %{
          deleted_changes: non_neg_integer(),
          deleted_transactions: non_neg_integer(),
          batches_run: non_neg_integer()
        }

  @doc """
  Deletes captured changes older than the retention cutoff in batches, then removes
  orphan `audit_transactions` when `delete_empty_transactions` is true in config.

  ## Options

  - **`:repo`** — required `Ecto.Repo`.
  - **`:batch_size`** — max rows per delete pass (default `500`).
  - **`:max_batches`** — max outer iterations, each consisting of one change batch
    plus orphan draining (default `10_000`).
  - **`:dry_run`** — when `true`, no deletes; returns counts of rows that **would**
    match delete predicates (`:deleted_changes` / `:deleted_transactions` are
    those counts, `:batches_run` is `0`).

  Returns `{:error, :disabled}` when `:retention` → `enabled` is not `true`.
  Successful calls return a result map (see `purge_result/0`).
  """
  @spec purge(keyword()) :: purge_result() | {:error, :disabled}
  def purge(opts) when is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)
    batch_size = Keyword.get(opts, :batch_size, 500)
    max_batches = Keyword.get(opts, :max_batches, 10_000)
    dry_run? = Keyword.get(opts, :dry_run, false)

    retention_kw = Application.get_env(:threadline, :retention) || []
    policy = Policy.resolve!(retention_kw)

    if policy.enabled != true do
      {:error, :disabled}
    else
      policy_cutoff = Policy.cutoff_utc_datetime_usec!()
      cutoff = resolve_cutoff(Keyword.get(opts, :cutoff), policy_cutoff)

      if dry_run? do
        dry_run_result(repo, cutoff, policy)
      else
        purge_loop(
          repo,
          cutoff,
          batch_size,
          max_batches,
          policy.delete_empty_transactions
        )
      end
    end
  end

  defp resolve_cutoff(nil, policy_cutoff), do: policy_cutoff

  defp resolve_cutoff(%DateTime{} = requested, policy_cutoff) do
    if DateTime.compare(requested, policy_cutoff) == :gt do
      raise ArgumentError,
            "retention: optional :cutoff must be at or before the policy cutoff (stricter retention only), got a newer timestamp"
    end

    requested
  end

  defp dry_run_result(repo, cutoff, policy) do
    eligible_changes =
      repo.one(from(ac in AuditChange, where: ac.captured_at < ^cutoff, select: count(ac.id)))

    eligible_txns =
      if policy.delete_empty_transactions do
        repo.one(
          from(at in AuditTransaction,
            where:
              fragment(
                "NOT EXISTS (SELECT 1 FROM audit_changes c WHERE c.transaction_id = ?)",
                at.id
              ),
            select: count(at.id)
          )
        )
      else
        0
      end

    %{
      deleted_changes: eligible_changes,
      deleted_transactions: eligible_txns,
      batches_run: 0,
      dry_run: true
    }
  end

  defp purge_loop(repo, cutoff, batch_size, max_batches, delete_empty?) do
    {total_changes, total_txns, batches} =
      Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
        n1 = delete_change_batch(repo, cutoff, batch_size)

        n2 =
          if delete_empty? do
            drain_orphan_batches(repo, batch_size)
          else
            0
          end

        tc = tc + n1
        tt = tt + n2

        Logger.info("threadline retention purge batch",
          deleted_changes: n1,
          deleted_transactions: n2,
          batch: idx,
          total_changes: tc,
          total_transactions: tt
        )

        if n1 == 0 and n2 == 0 do
          {:halt, {tc, tt, idx}}
        else
          {:cont, {tc, tt, idx}}
        end
      end)

    %{deleted_changes: total_changes, deleted_transactions: total_txns, batches_run: batches}
  end

  defp delete_change_batch(repo, cutoff, batch_size) do
    subq =
      from(ac in AuditChange,
        where: ac.captured_at < ^cutoff,
        select: ac.id,
        limit: ^batch_size
      )

    {n, _} =
      repo.delete_all(
        from(ac in AuditChange,
          where: ac.id in subquery(subq)
        )
      )

    n
  end

  defp drain_orphan_batches(repo, batch_size), do: drain_orphans(0, repo, batch_size)

  defp drain_orphans(acc, repo, batch_size) do
    subq =
      from(at in AuditTransaction,
        where:
          fragment(
            "NOT EXISTS (SELECT 1 FROM audit_changes c WHERE c.transaction_id = ?)",
            at.id
          ),
        select: at.id,
        limit: ^batch_size
      )

    case repo.delete_all(from(at in AuditTransaction, where: at.id in subquery(subq))) do
      {0, _} -> acc
      {n, _} -> drain_orphans(acc + n, repo, batch_size)
    end
  end
end
