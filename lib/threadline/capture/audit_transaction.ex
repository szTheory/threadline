defmodule Threadline.Capture.AuditTransaction do
  @moduledoc """
  An `AuditTransaction` groups row changes from one database transaction; it is not a request or an action.

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
    `threadline.actor_ref` GUC when it is set inside the same database
    transaction as the audited writes (see `Threadline.Plug` for the bridge
    pattern).
  - `:action_id` — optional FK to `Threadline.Semantics.AuditAction`. Set
    when you call `Threadline.record_action/2` and link semantic intent to
    captured rows.
  - `:source` — free-form string identifying the application subsystem, for
    example `"web"` or `"oban"`.

  ## Relationships

  - `has_many :changes, Threadline.Capture.AuditChange` — the row mutations
    captured in this transaction.
  - `:action_id` — optional foreign key to an `audit_actions` row. The
    capture schema does not declare an Ecto association to
    `Threadline.Semantics.AuditAction` (capture must not own semantics-layer
    concerns). The virtual `:action` field is filled by Threadline's read
    functions (`Threadline.transaction_context/2`, `Threadline.incident_bundle/2`,
    and the other investigation helpers) via a hidden batched hydrate step —
    it is `nil` until one of those functions hydrates it, never an Ecto
    association.

  ## Setup

  Run `mix threadline.install` to generate the migration that creates this
  table, then `mix threadline.gen.triggers` to register capture triggers on
  your application tables. See [guides/domain-reference.md](guides/domain-reference.md)
  for the full domain model.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc """
  A database transaction that groups captured row changes.

  The virtual `:action` is a hydrated `Threadline.Semantics.AuditAction`; nil until hydrated.
  """
  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          txid: integer(),
          occurred_at: DateTime.t(),
          source: String.t() | nil,
          meta: Threadline.json_map() | nil,
          actor_ref: Threadline.Semantics.ActorRef.t() | nil,
          action_id: Ecto.UUID.t() | nil,
          action: Threadline.Semantics.AuditAction.t() | nil,
          changes: [Threadline.Capture.AuditChange.t()] | Ecto.Association.NotLoaded.t(),
          __meta__: Ecto.Schema.Metadata.t()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_transactions" do
    # PostgreSQL transaction ID used by the trigger to group changes safely under
    # PgBouncer transaction-mode pooling.
    field(:txid, :integer)
    field(:occurred_at, :utc_datetime_usec)
    field(:source, :string)
    field(:meta, :map)

    # Actor and semantic-action context are additive and nullable; capture works
    # without either.
    field(:actor_ref, Threadline.Semantics.ActorRef)

    field(:action_id, :binary_id)
    field(:action, :any, virtual: true, default: nil)

    has_many(:changes, Threadline.Capture.AuditChange, foreign_key: :transaction_id)
  end

  @doc false
  def changeset(transaction \\ %__MODULE__{}, attrs) do
    transaction
    |> cast(attrs, [:txid, :occurred_at, :source, :meta, :actor_ref, :action_id])
  end
end
