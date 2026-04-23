defmodule Threadline.AuditAction do
  @moduledoc """
  A semantic application-level event (e.g. `member.role_changed`).

  AuditActions live in the semantics layer — they bind actor, intent,
  correlation IDs, and provenance to a named action. Actions are not changes;
  transactions are not requests; users are not always the actor.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @timestamps_opts [type: :utc_datetime_usec]

  schema "audit_actions" do
    field :name, :string
    field :actor_type, :string
    field :actor_id, :string
    field :status, :string
    field :verb, :string
    field :category, :string
    field :reason, :string
    field :comment, :string
    field :correlation_id, :string
    field :request_id, :string
    field :job_id, :string
    field :meta, :map, default: %{}

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @required_fields ~w(name actor_type actor_id status)a
  @optional_fields ~w(verb category reason comment correlation_id request_id job_id meta)a

  def changeset(action, attrs) do
    action
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
