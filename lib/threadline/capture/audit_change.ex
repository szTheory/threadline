defmodule Threadline.Capture.AuditChange do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_changes" do
    belongs_to(:transaction, Threadline.Capture.AuditTransaction, foreign_key: :transaction_id)

    field(:table_schema, :string)
    field(:table_name, :string)
    field(:table_pk, :map)
    field(:op, :string)
    field(:data_after, :map)
    field(:changed_fields, {:array, :string})
    field(:captured_at, :utc_datetime_usec)
  end
end
