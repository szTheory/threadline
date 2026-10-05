defmodule Threadline.Capture.AuditChange do
  @moduledoc """
  An `AuditChange` is one row mutation in one audited table.

  An `AuditChange` records a single row-level mutation (`INSERT`, `UPDATE`,
  or `DELETE`) on an audited table. Records are created automatically by
  PostgreSQL triggers; you do not insert them from application code.

  Each `AuditChange` belongs to exactly one `AuditTransaction`. Multiple
  changes in the same database transaction share a `transaction_id`.

  ## Key fields

  - `:table_schema` / `:table_name` — the schema and table where the mutation
    occurred.
  - `:table_pk` — primary key of the mutated row, stored as a JSON map so
    composite keys are supported.
  - `:op` — `"INSERT"`, `"UPDATE"`, or `"DELETE"`.
  - `:data_after` — full row snapshot after the mutation (nil for deletes).
  - `:changed_fields` — list of column names that changed (populated for
    updates; nil for inserts and deletes).
  - `:changed_from` — sparse JSON map of prior column values on UPDATE when a
    per-table opt-in capture function is installed; otherwise nil.
  - `:captured_at` — trigger execution timestamp (microsecond precision).

  ## Relationships

  - `belongs_to :transaction, Threadline.Capture.AuditTransaction` — the DB
    transaction that produced this change.

  ## Setup

  Triggers are installed per table by `mix threadline.gen.triggers`, which emits
  SQL calling `threadline_capture_changes()` from `mix threadline.install`. See
  [guides/domain-reference.md](guides/domain-reference.md) for the domain model
  for the capture
  contract.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc """
  One persisted row mutation with its captured table, row key, operation, and JSON snapshots.

  `:data_after` is nil for deletes, and `:changed_fields` is nil when no update fields were captured.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          transaction_id: Ecto.UUID.t() | nil,
          transaction: Threadline.Capture.AuditTransaction.t() | Ecto.Association.NotLoaded.t(),
          table_schema: String.t(),
          table_name: String.t(),
          table_pk: Threadline.json_map(),
          op: String.t(),
          data_after: Threadline.json_map() | nil,
          changed_fields: [String.t()] | nil,
          changed_from: Threadline.json_map() | nil,
          captured_at: DateTime.t(),
          __meta__: Ecto.Schema.Metadata.t()
        }

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
    field(:changed_from, :map)
    field(:captured_at, :utc_datetime_usec)
  end

  @doc false
  def changeset(change \\ %__MODULE__{}, attrs) do
    change
    |> cast(attrs, [
      :table_schema,
      :table_name,
      :table_pk,
      :op,
      :data_after,
      :changed_fields,
      :changed_from,
      :captured_at,
      :transaction_id
    ])
  end
end
