defmodule Threadline.Capture.AuditTransaction do
  @moduledoc """
  Ecto schema for the `audit_transactions` table.

  An `AuditTransaction` groups every row mutation that occurred within a single
  PostgreSQL transaction. Records are created automatically by the capture
  triggers installed by `mix threadline.gen.triggers` — application code does
  not insert them directly.

  ## Key fields

  - `:txid` — the PostgreSQL transaction ID, used by the trigger to group
    concurrent changes safely under PgBouncer transaction-mode pooling.
  - `:occurred_at` — timestamp when the transaction committed (microsecond
    precision).
  - `:actor_ref` — who performed the writes. Populated from the
    `threadline.actor_ref` GUC when it is set inside the same
    `Ecto.Repo.transaction/1` as the audited writes (see `Threadline.Plug`
    for the bridge pattern).
  - `:action_id` — optional FK to `Threadline.Semantics.AuditAction`. Set
    when you call `Threadline.record_action/2` and link semantic intent to
    captured rows.
  - `:source` — free-form string identifying the application subsystem, for
    example `"web"` or `"oban"`.

  ## Relationships

  - `has_many :changes, Threadline.Capture.AuditChange` — the row mutations
    captured in this transaction.
  - `belongs_to :action, Threadline.Semantics.AuditAction` — optional
    semantic label for this transaction.

  ## Setup

  Run `mix threadline.install` to generate the migration that creates this
  table, then `mix threadline.gen.triggers` to register capture triggers on
  your application tables. See [guides/domain-reference.md](guides/domain-reference.md)
  for the full domain model.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_transactions" do
    # Internal: PostgreSQL transaction ID used by trigger for PgBouncer-safe grouping (D-06)
    field(:txid, :integer)
    field(:occurred_at, :utc_datetime_usec)
    field(:source, :string)
    field(:meta, :map)

    # Phase 2 additions — both nullable (CTX-04: capture works without context)
    field(:actor_ref, Threadline.Semantics.ActorRef)

    @compile {:no_warn_undefined, Threadline.Semantics.AuditAction}
    belongs_to(:action, Threadline.Semantics.AuditAction)

    has_many(:changes, Threadline.Capture.AuditChange, foreign_key: :transaction_id)
  end

  @doc false
  def changeset(transaction \\ %__MODULE__{}, attrs) do
    transaction
    |> cast(attrs, [:txid, :occurred_at, :source, :meta, :actor_ref, :action_id])
  end
end
