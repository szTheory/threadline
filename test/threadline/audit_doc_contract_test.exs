defmodule Threadline.AuditDocContractTest do
  use ExUnit.Case, async: true

  alias Threadline.GettingStartedFixtures

  test "audit.ex locks audit-transaction-helper marker" do
    snippet =
      GettingStartedFixtures.extract!("lib/threadline/audit.ex", "audit-transaction-helper")

    assert String.contains?(snippet, "Threadline.Audit.transaction")
    assert String.contains?(snippet, "audit_context:")
    assert String.contains?(snippet, "action:")
  end

  test "getting-started guide documents helper as recommended write path" do
    doc = File.read!("guides/getting-started-saas.md")

    assert String.contains?(doc, "Threadline.Audit.transaction/3")
    assert String.contains?(doc, "recommended write path")
  end
end
