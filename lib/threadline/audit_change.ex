defmodule Threadline.AuditChange do
  @moduledoc """
  One row mutation in one audited table, captured by a PostgreSQL trigger.

  Each AuditChange belongs to an AuditTransaction and records the operation
  type, affected table, primary key, resulting data, and which fields changed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "audit_changes" do
    field(:table_schema, :string)
    field(:table_name, :string)
    field(:table_pk, :string)
    field(:op, Ecto.Enum, values: [:insert, :update, :delete])
    field(:data_after, :map)
    field(:changed_fields, {:array, :string}, default: [])
    field(:captured_at, :utc_datetime_usec)

    belongs_to(:transaction, Threadline.AuditTransaction)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @required_fields ~w(table_schema table_name table_pk op captured_at)a
  @optional_fields ~w(data_after changed_fields transaction_id)a

  def changeset(change, attrs) do
    change
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:op, [:insert, :update, :delete])
    |> foreign_key_constraint(:transaction_id)
  end
end
