defmodule ThreadlinePhoenix.Demo.Seed.Temporal do
  @moduledoc false

  alias ThreadlinePhoenix.Repo

  @doc false
  @spec run(map()) :: map()
  def run(%{timestamps: timestamps} = ctx) when map_size(timestamps) > 0 do
    Enum.each(timestamps, fn {transaction_id, occurred_at} ->
      tx_bin = Ecto.UUID.dump!(transaction_id)

      Repo.query!(
        "UPDATE audit_transactions SET occurred_at = $1 WHERE id = $2",
        [occurred_at, tx_bin]
      )

      Repo.query!(
        "UPDATE audit_changes SET captured_at = $1 WHERE transaction_id = $2",
        [occurred_at, tx_bin]
      )
    end)

    ctx
  end

  def run(ctx), do: ctx
end
