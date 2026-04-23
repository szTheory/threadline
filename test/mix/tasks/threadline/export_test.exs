defmodule Mix.Tasks.Threadline.ExportTest do
  use Threadline.DataCase

  import ExUnit.CaptureIO

  alias Threadline.Capture.{AuditChange, AuditTransaction}

  @repo Threadline.Test.Repo

  test "dry-run prints matching row count without raising" do
    tname = "mix_export_task_#{:erlang.unique_integer([:positive])}"

    txn =
      @repo.insert!(
        AuditTransaction.changeset(%{
          txid: System.unique_integer([:positive]),
          occurred_at: DateTime.utc_now()
        })
      )

    @repo.insert!(
      AuditChange.changeset(%{
        table_schema: "public",
        table_name: tname,
        table_pk: %{"id" => "1"},
        op: "insert",
        data_after: %{},
        captured_at: DateTime.utc_now(),
        transaction_id: txn.id
      })
    )

    out =
      capture_io(fn ->
        Mix.Tasks.Threadline.Export.run(["--dry-run", "--table", tname])
      end)

    assert out =~ "matching_rows=1"
    assert out =~ "count"
  end
end
