defmodule Threadline.AuditTransaction do
  @moduledoc """
  Groups row-level changes captured within a single database transaction.

  An AuditTransaction is not the same as a request or action — it represents
  the atomic unit of change at the PostgreSQL level.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "audit_transactions" do
    field(:occurred_at, :utc_datetime_usec)
    field(:actor_type, :string)
    field(:actor_id, :string)
    field(:meta, :map, default: %{})

    has_many(:changes, Threadline.AuditChange, foreign_key: :transaction_id)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @required_fields ~w(occurred_at)a
  @optional_fields ~w(actor_type actor_id meta)a

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
