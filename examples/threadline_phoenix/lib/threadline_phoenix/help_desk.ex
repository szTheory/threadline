defmodule ThreadlinePhoenix.HelpDesk do
  @moduledoc """
  Help-desk domain schemas and write APIs for the Threadline Phoenix example app.

  Capture wiring and semantic actions ship in Plan 02 (`105-02`).
  """

  alias ThreadlinePhoenix.HelpDesk.Agent
  alias ThreadlinePhoenix.HelpDesk.OrgMembership
  alias ThreadlinePhoenix.HelpDesk.Organization
  alias ThreadlinePhoenix.HelpDesk.Ticket
  alias ThreadlinePhoenix.HelpDesk.TicketReply

  @schemas [Organization, OrgMembership, Agent, Ticket, TicketReply]

  @doc false
  def schemas, do: @schemas
end
