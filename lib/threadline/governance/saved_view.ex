defmodule Threadline.Governance.SavedView do
  @moduledoc """
  Ecto schema for the `threadline_saved_views` table.

  Represents a saved view (filter set) for the Threadline operator surface.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "threadline_saved_views" do
    field(:name, :string)
    field(:actor_ref, Threadline.Semantics.ActorRef)
    field(:filters, :map)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(view \\ %__MODULE__{}, attrs) do
    view
    |> cast(attrs, [
      :name,
      :actor_ref,
      :filters
    ])
    |> validate_required([:name, :actor_ref, :filters])
  end
end
