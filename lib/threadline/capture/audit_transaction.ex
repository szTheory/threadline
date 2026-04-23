defmodule Threadline.Capture.AuditTransaction do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_transactions" do
    # Internal: PostgreSQL transaction ID used by trigger for PgBouncer-safe grouping (D-06)
    field(:txid, :integer)
    field(:occurred_at, :utc_datetime_usec)
    field(:source, :string)
    field(:meta, :map)

    has_many(:changes, Threadline.Capture.AuditChange, foreign_key: :transaction_id)
  end
end
