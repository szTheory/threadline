defmodule ThreadlinePhoenix.HelpDesk.Agent do
  @moduledoc """
  Help-desk agent linked to a human user.

  Set `organization_id` and `user_id` programmatically — do not cast them from
  untrusted params.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "agents" do
    field(:user_id, :string)
    field(:display_name, :string)

    belongs_to(:organization, ThreadlinePhoenix.HelpDesk.Organization)
    has_many(:assigned_tickets, ThreadlinePhoenix.HelpDesk.Ticket, foreign_key: :assignee_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [:display_name])
    |> validate_required([:user_id, :organization_id])
    |> unique_constraint([:organization_id, :user_id])
  end
end
