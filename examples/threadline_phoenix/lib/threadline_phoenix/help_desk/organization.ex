defmodule ThreadlinePhoenix.HelpDesk.Organization do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "organizations" do
    field(:slug, :string)
    field(:name, :string)

    has_many(:org_memberships, ThreadlinePhoenix.HelpDesk.OrgMembership)
    has_many(:agents, ThreadlinePhoenix.HelpDesk.Agent)
    has_many(:tickets, ThreadlinePhoenix.HelpDesk.Ticket)

    timestamps(type: :utc_datetime)
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:slug, :name])
    |> validate_required([:slug, :name])
    |> unique_constraint(:slug)
  end
end
