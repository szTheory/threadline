defmodule Mix.Tasks.Threadline.IncidentTest do
  use Threadline.DataCase

  import ExUnit.CaptureIO

  alias Threadline.Capture.{AuditChange, AuditTransaction}

  @repo Threadline.Test.Repo

  setup do
    txn =
      @repo.insert!(
        AuditTransaction.changeset(%{
          txid: System.unique_integer([:positive]),
          occurred_at: DateTime.utc_now(),
          actor_ref: %{"type" => "user", "id" => "u1"}
        }),
        repo_opts()
      )

    change =
      @repo.insert!(
        AuditChange.changeset(%{
          table_schema: "public",
          table_name: "test_incident_table",
          table_pk: %{"id" => "1"},
          op: "insert",
          data_after: %{"id" => "1", "name" => "test"},
          captured_at: DateTime.utc_now(),
          transaction_id: txn.id
        }),
        repo_opts()
      )

    {:ok, %{txn: txn, change: change}}
  end

  test "prints incident bundle in human-readable format", %{txn: txn} do
    out =
      capture_io(fn ->
        Mix.Tasks.Threadline.Incident.run([txn.id])
      end)

    assert out =~ "Transaction: #{txn.id}"
    assert out =~ "Actor:"
    assert out =~ "insert test_incident_table (PK: %{\"id\" => \"1\"})"
  end

  test "prints incident bundle in JSON format", %{txn: txn} do
    out =
      capture_io(fn ->
        Mix.Tasks.Threadline.Incident.run([txn.id, "--json"])
      end)

    parsed = Jason.decode!(out)
    assert parsed["transaction"]["id"] == txn.id
    assert parsed["transaction"]["actor_ref"]["id"] == "u1"
    assert length(parsed["changes"]) == 1

    first_change = hd(parsed["changes"])
    assert first_change["audit_change"]["op"] == "insert"
    assert first_change["audit_change"]["table_name"] == "test_incident_table"
  end

  test "raises when transaction is not found" do
    missing_id = Ecto.UUID.generate()

    assert_raise Mix.Error, ~r/transaction not found: #{missing_id}/, fn ->
      capture_io(fn ->
        Mix.Tasks.Threadline.Incident.run([missing_id])
      end)
    end
  end

  test "raises when transaction id is missing" do
    assert_raise Mix.Error, ~r/requires exactly one argument/, fn ->
      Mix.Tasks.Threadline.Incident.run([])
    end
  end
end
