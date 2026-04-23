defmodule Threadline.Capture.AuditTransaction do
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
