defmodule Threadline.Governance.RetentionRun do
  @moduledoc """
  Ecto schema for the `threadline_retention_runs` table.

  Represents an execution of the retention policy pruning process.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "threadline"

  schema "threadline_retention_runs" do
    field(:status, :string)
    field(:deleted_count, :integer)
    field(:duration_ms, :integer)
    field(:error_message, :string)
    field(:started_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(run \\ %__MODULE__{}, attrs) do
    run
    |> cast(attrs, [
      :status,
      :deleted_count,
      :duration_ms,
      :error_message,
      :started_at,
      :completed_at
    ])
    |> validate_required([:status])
  end
end
