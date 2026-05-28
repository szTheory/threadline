defmodule Threadline.ExamplePhoenixSchemasMountContractTest do
  use ExUnit.Case, async: true

  alias Threadline.GettingStartedFixtures

  test "example router operator mount maps help-desk tables for row history (D-14)" do
    mount =
      GettingStartedFixtures.extract!(
        "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
        "operator-surface-mount"
      )

    assert mount =~ "schemas:"
    assert mount =~ "\"tickets\" => ThreadlinePhoenix.HelpDesk.Ticket"
    assert mount =~ "\"ticket_replies\" => ThreadlinePhoenix.HelpDesk.TicketReply"
  end
end
