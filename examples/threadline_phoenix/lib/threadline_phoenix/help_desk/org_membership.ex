defmodule ThreadlinePhoenix.HelpDesk.OrgMembership do
  @moduledoc """
  Organization membership with auth role.

  Set `organization_id` and `user_id` programmatically in context APIs — do not cast
  them from external params.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles ["agent", "support"]

  schema "org_memberships" do
    field(:user_id, :string)
    field(:role, :string)

    belongs_to(:organization, ThreadlinePhoenix.HelpDesk.Organization)

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role])
    |> validate_required([:role, :organization_id, :user_id])
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:organization_id, :user_id])
  end
end
