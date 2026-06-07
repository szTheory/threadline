defmodule Threadline.Governance.ExportJob do
  @moduledoc """
  Ecto schema for the `threadline_export_jobs` table.

  Represents an asynchronous background job to export audit data to a file.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @schema_prefix "threadline"

  schema "threadline_export_jobs" do
    field(:status, :string)
    field(:query_params, :map)
    field(:actor_ref, Threadline.Semantics.ActorRef)
    field(:file_path, :string)
    field(:error_message, :string)
    field(:started_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job \\ %__MODULE__{}, attrs) do
    job
    |> cast(attrs, [
      :status,
      :query_params,
      :actor_ref,
      :file_path,
      :error_message,
      :started_at,
      :completed_at,
      :expires_at
    ])
    |> validate_required([:status, :query_params])
  end
end
