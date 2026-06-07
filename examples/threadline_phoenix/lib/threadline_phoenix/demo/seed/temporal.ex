defmodule ThreadlinePhoenix.Demo.Seed.Temporal do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Repo

  @doc false
  @spec run(map()) :: map()
  def run(%{timestamps: timestamps} = ctx) when map_size(timestamps) > 0 do
    Enum.each(timestamps, fn {transaction_id, occurred_at} ->
      tx_bin = Ecto.UUID.dump!(transaction_id)

      Repo.query!(
        "UPDATE threadline.audit_transactions SET occurred_at = $1 WHERE id = $2",
        [occurred_at, tx_bin]
      )

      Repo.query!(
        "UPDATE threadline.audit_changes SET captured_at = $1 WHERE transaction_id = $2",
        [occurred_at, tx_bin]
      )
    end)

    backdate_untracked_null_actor_transactions(Map.keys(timestamps))
    ctx
  end

  def run(ctx) do
    backdate_untracked_null_actor_transactions([])
    ctx
  end

  defp backdate_untracked_null_actor_transactions(timestamped_ids) do
    setup_ts = DateTime.add(Manifest.epoch(), -21, :day)

    query =
      from(at in AuditTransaction,
        where: is_nil(at.actor_ref),
        where: at.id not in ^timestamped_ids,
        select: at.id
      )

    ids = Repo.all(query)

    if ids != [] do
      Repo.update_all(
        from(at in AuditTransaction, where: at.id in ^ids),
        set: [occurred_at: setup_ts]
      )

      Repo.update_all(
        from(ac in AuditChange, where: ac.transaction_id in ^ids),
        set: [captured_at: setup_ts]
      )
    end

    :ok
  end
end
