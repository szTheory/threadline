defmodule ThreadlinePhoenix.Demo.Seed.Support do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.{ActorRef, AuditContext}
  alias Threadline.StorageSchema
  alias ThreadlinePhoenix.HelpDesk.{Organization, Ticket, TicketReply}
  alias ThreadlinePhoenix.Repo

  @doc false
  def stamp_insert(%Ecto.Changeset{} = changeset, %DateTime{} = timestamp) do
    changeset
    |> put_schema_timestamp(:inserted_at, timestamp)
    |> put_schema_timestamp(:updated_at, timestamp)
  end

  @doc false
  def stamp_update(%Ecto.Changeset{} = changeset, %DateTime{} = timestamp) do
    put_schema_timestamp(changeset, :updated_at, timestamp)
  end

  @doc false
  def reply_and_close(
        %AuditContext{} = audit_context,
        %Organization{} = organization,
        %Ticket{} = ticket,
        reply_attrs,
        ticket_attrs,
        %DateTime{} = occurred_at
      )
      when is_map(reply_attrs) and is_map(ticket_attrs) do
    Threadline.Audit.transaction(
      Repo,
      [
        audit_context: audit_context,
        action: :ticket_replied_and_closed,
        transaction_meta: %{"organization_id" => to_string(organization.id)}
      ],
      fn ->
        reply_changeset =
          %TicketReply{ticket_id: ticket.id}
          |> TicketReply.changeset(reply_attrs)
          |> stamp_insert(occurred_at)

        with {:ok, reply} <- Repo.insert(reply_changeset),
             {:ok, updated_ticket} <-
               ticket
               |> Ticket.changeset(ticket_attrs)
               |> stamp_update(occurred_at)
               |> Repo.update() do
          %{ticket: updated_ticket, reply: reply}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end
    )
  end

  @doc false
  def put_timestamp(ctx, transaction_id, %DateTime{} = occurred_at)
      when is_binary(transaction_id) do
    timestamps = Map.put(ctx.timestamps, transaction_id, occurred_at)
    Map.put(ctx, :timestamps, timestamps)
  end

  @doc false
  def audit_context(actor_id, opts \\ []) when is_binary(actor_id) do
    kind = Keyword.get(opts, :kind, :user)
    {:ok, actor_ref} = ActorRef.new(kind, actor_id)

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
      ),
      StorageSchema.repo_opts()
    )
  end

  @doc false
  def current_audit_transaction_id do
    Repo.one(
      from(at in AuditTransaction,
        where: at.txid == fragment("txid_current()"),
        select: at.id
      ),
      StorageSchema.repo_opts()
    )
  end

  @doc false
  def stamp_org_meta!(%Organization{} = organization) do
    meta = %{"organization_id" => to_string(organization.id)}

    {count, _} =
      Repo.update_all(
        from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
        [set: [meta: meta]],
        StorageSchema.repo_opts()
      )

    if count != 1 do
      raise "expected exactly one audit transaction for txid_current(), got #{count}"
    end

    :ok
  end

  @doc false
  def stamp_org_meta(%Organization{} = organization) do
    meta = %{"organization_id" => to_string(organization.id)}

    {_count, _} =
      Repo.update_all(
        from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
        [set: [meta: meta]],
        StorageSchema.repo_opts()
      )

    :ok
  end

  @doc false
  def set_actor_guc!(actor_id, kind \\ :user)
      when is_binary(actor_id) and kind in [:user, :admin, :service_account, :job, :system] do
    {:ok, actor_ref} = ActorRef.new(kind, actor_id)

    json =
      actor_ref
      |> Threadline.Semantics.ActorRef.to_map()
      |> Jason.encode!()

    Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
  end

  @doc false
  def set_anonymous_actor_guc! do
    {:ok, actor_ref} = ActorRef.new(:anonymous)

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

  defp put_schema_timestamp(
         %Ecto.Changeset{data: %{__struct__: schema}} = changeset,
         field,
         timestamp
       ) do
    if field in schema.__schema__(:fields) do
      Ecto.Changeset.put_change(changeset, field, timestamp)
    else
      changeset
    end
  end
end
