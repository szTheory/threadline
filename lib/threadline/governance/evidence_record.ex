defmodule Threadline.Governance.EvidenceRecord do
  @moduledoc """
  Ecto schema for the `threadline_evidence_records` table.

  Evidence rows are append-only snapshots about Threadline-owned governance
  subjects.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "threadline"

  schema "threadline_evidence_records" do
    field(:subject, :string)
    field(:subject_ref, :map)
    field(:summary_status, :string)
    field(:recorded_at, :utc_datetime_usec)
    field(:actor_ref, Threadline.Semantics.ActorRef)
    field(:provenance, :map)
    field(:detail, :map)
    field(:schema_version, :integer)
    field(:inserted_at, :utc_datetime_usec)
  end

  @required_fields ~w(
    subject
    subject_ref
    summary_status
    recorded_at
    provenance
    detail
    schema_version
  )a

  @doc false
  def changeset(record \\ %__MODULE__{}, attrs) do
    record
    |> cast(attrs, [
      :subject,
      :subject_ref,
      :summary_status,
      :recorded_at,
      :actor_ref,
      :provenance,
      :detail,
      :schema_version
    ])
    |> validate_required(@required_fields)
    |> validate_length(:subject, min: 1)
    |> validate_length(:summary_status, min: 1)
    |> validate_change(:subject_ref, &validate_map_field/2)
    |> validate_change(:provenance, &validate_map_field/2)
    |> validate_change(:detail, &validate_map_field/2)
    |> validate_number(:schema_version, greater_than: 0)
  end

  defp validate_map_field(_field, value) when is_map(value), do: []
  defp validate_map_field(field, _value), do: [{field, "must be a map"}]
end
