defmodule ThreadlinePhoenix.HelpDesk.TicketReply do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ticket_replies" do
    field(:body, :string)
    field(:internal_note_body, :string)

    belongs_to(:ticket, ThreadlinePhoenix.HelpDesk.Ticket)

    timestamps(type: :utc_datetime)
  end

  def changeset(reply, attrs) do
    reply
    |> cast(attrs, [:body, :internal_note_body])
    |> validate_required([:body, :ticket_id])
  end
end
