defmodule Threadline.Semantics.AuditAction do
  @moduledoc """
  Ecto schema for the `audit_actions` table.

  An AuditAction represents a semantic application-level event: who did what
  and why. It is distinct from `AuditTransaction` (which groups DB-level row
  changes) and may be linked to one or more transactions via
  `audit_transactions.action_id`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_actions" do
    field(:name, :string)
    field(:actor_ref, Threadline.Semantics.ActorRef)
    field(:status, Ecto.Enum, values: [ok: "ok", error: "error"])
    field(:verb, :string)
    field(:category, :string)
    field(:reason, :string)
    field(:comment, :string)
    field(:correlation_id, :string)
    field(:request_id, :string)
    field(:job_id, :string)

    has_many(:transactions, Threadline.Capture.AuditTransaction, foreign_key: :action_id)

    timestamps(inserted_at: :inserted_at, updated_at: false, type: :utc_datetime_usec)
  end

  @required_fields ~w(name actor_ref status)a
  @optional_fields ~w(verb category reason comment correlation_id request_id job_id)a

  @doc false
  def changeset(action \\ %__MODULE__{}, attrs) do
    action
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
