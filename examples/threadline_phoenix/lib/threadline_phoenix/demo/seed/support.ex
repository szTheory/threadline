defmodule ThreadlinePhoenix.Demo.Seed.Support do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.ActorRef
  alias ThreadlinePhoenix.HelpDesk.Organization
  alias ThreadlinePhoenix.Repo

  @doc false
  def put_timestamp(ctx, transaction_id, %DateTime{} = occurred_at)
      when is_binary(transaction_id) do
    timestamps = Map.put(ctx.timestamps, transaction_id, occurred_at)
    Map.put(ctx, :timestamps, timestamps)
  end

  @doc false
  def audit_context(user_id, opts \\ []) when is_binary(user_id) do
    {:ok, actor_ref} = ActorRef.new(:user, user_id)

    %Threadline.Semantics.AuditContext{
      actor_ref: actor_ref,
      correlation_id: Keyword.get(opts, :correlation_id),
      request_id: Keyword.get(opts, :request_id, "demo-seed")
    }
  end

  @doc false
  def current_audit_transaction_id! do
    Repo.one!(
      from(at in AuditTransaction,
        where: at.txid == fragment("txid_current()"),
        select: at.id
      )
    )
  end

  @doc false
  def stamp_org_meta!(%Organization{} = organization) do
    meta = %{"organization_id" => to_string(organization.id)}

    {count, _} =
      Repo.update_all(
        from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
        set: [meta: meta]
      )

    if count != 1 do
      raise "expected exactly one audit transaction for txid_current(), got #{count}"
    end

    :ok
  end

  @doc false
  def set_actor_guc!(user_id) when is_binary(user_id) do
    {:ok, actor_ref} = ActorRef.new(:user, user_id)

    json =
      actor_ref
      |> Threadline.Semantics.ActorRef.to_map()
      |> Jason.encode!()

    Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
  end

  @doc false
  def days_ago_timestamp(days_ago) when is_integer(days_ago) and days_ago >= 0 do
    ThreadlinePhoenix.Demo.Manifest.epoch()
    |> DateTime.add(-days_ago, :day)
  end

  @doc false
  def random_days_ago_timestamp do
    days_ago = :rand.uniform(14) - 1
    days_ago_timestamp(days_ago)
  end
end
