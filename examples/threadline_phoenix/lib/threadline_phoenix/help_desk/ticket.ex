defmodule ThreadlinePhoenix.HelpDesk.Ticket do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tickets" do
    field(:number, :integer)
    field(:status, :string, default: "open")
    field(:closed_at, :utc_datetime)

    belongs_to(:organization, ThreadlinePhoenix.HelpDesk.Organization)
    belongs_to(:assignee, ThreadlinePhoenix.HelpDesk.Agent)
    has_many(:ticket_replies, ThreadlinePhoenix.HelpDesk.TicketReply)

    timestamps(type: :utc_datetime)
  end

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:number, :status, :closed_at])
    |> validate_required([:number, :status, :organization_id])
    |> unique_constraint([:organization_id, :number])
  end
end
