defmodule Threadline.Semantics.AuditAction do
  @moduledoc """
  An `AuditAction` is an application-level event that records who did what and why.

  An `AuditAction` represents a semantic application-level event — who did
  what and why. It is distinct from `AuditTransaction` (which groups DB-level
  row changes produced by triggers) and may be linked to one or more
  transactions via `audit_transactions.action_id`.

  ## Name convention

  Action names use the `"<category>.<verb>"` pattern, for example:

  - `"member.role_changed"`
  - `"order.placed"`
  - `"account.deactivated"`
  - `"document.archived"`

  The `:category` and `:verb` fields store the components separately so you
  can filter by either dimension in queries.

  ## Stable 1.x fields

  The stable struct fields for 1.x are `id`, `name`, `actor_ref`, `status`,
  `reason`, `correlation_id`, and `inserted_at`. The `t()` type may gain fields;
  this list does not make every current schema field a promise. An
  `AuditAction` remains a semantic application event, distinct from the
  database-transaction grouping in `AuditTransaction`.

  ## Usage

  Create actions via `Threadline.record_action/2`, which inserts the semantic
  row using the provided `:repo`. Linking captured transactions to an action is
  handled separately when you associate `audit_transactions.action_id`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc "A persisted semantic action linked to one or more captured database transactions."
  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          name: String.t(),
          actor_ref: Threadline.Semantics.ActorRef.t(),
          status: :ok | :error,
          verb: String.t() | nil,
          category: String.t() | nil,
          reason: String.t() | nil,
          comment: String.t() | nil,
          correlation_id: String.t() | nil,
          request_id: String.t() | nil,
          job_id: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          __meta__: Ecto.Schema.Metadata.t()
        }

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
