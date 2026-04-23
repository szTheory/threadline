defmodule Threadline.Capture.AuditChange do
  @moduledoc """
  Ecto schema for the `audit_changes` table.

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
  and `.planning/phases/01-capture-foundation/gate-01-01.md` for the capture
  contract.
  """

  use Ecto.Schema
  import Ecto.Changeset

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
