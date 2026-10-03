if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportControllerTelemetryTest.ClosedChunkAdapter do
    @moduledoc """
    A `Plug.Conn.Adapter` that delegates every callback to
    `Plug.Adapters.Test.Conn` EXCEPT `chunk/2`, which always returns
    `{:error, :closed}` — simulating a client that disconnected mid-stream
    (the shape Plug adapters report for a gone client).
    """

    @behaviour Plug.Conn.Adapter

    alias Plug.Adapters.Test.Conn, as: TestAdapter

    defdelegate send_resp(state, status, headers, body), to: TestAdapter
    defdelegate send_file(state, status, headers, path, offset, length), to: TestAdapter
    defdelegate send_chunked(state, status, headers), to: TestAdapter
    defdelegate read_req_body(state, opts \\ []), to: TestAdapter
    defdelegate inform(state, status, headers), to: TestAdapter
    defdelegate upgrade(state, protocol, opts), to: TestAdapter
    defdelegate push(state, path, headers), to: TestAdapter
    defdelegate get_peer_data(payload), to: TestAdapter
    defdelegate get_sock_data(payload), to: TestAdapter
    defdelegate get_ssl_data(payload), to: TestAdapter
    defdelegate get_http_protocol(payload), to: TestAdapter

    def chunk(_state, _body), do: {:error, :closed}
  end

  defmodule Threadline.OperatorSurface.ExportControllerTelemetryTest do
    @moduledoc """
    TELE-01: the chunked operator-surface download emits exactly one export
    outcome event after its `reduce_while`, including on a client
    disconnect. Calls `ExportController.csv/2` directly (no router/endpoint)
    with a hand-built `Plug.Test` conn, so the `:client_closed` case can swap
    in `ClosedChunkAdapter` for `Plug.Adapters.Test.Conn`.

    `async: false` — Threadline does NOT use SQL Sandbox; each test cleans up
    its own seeded rows by table name (`test/support/data_case.ex` documents
    the why).
    """
    use ExUnit.Case, async: false

    import Plug.Conn, only: [assign: 3]
    import Plug.Test, only: [conn: 2]
    import Threadline.StorageSchemaCase
    import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

    alias Threadline.Capture.{AuditChange, AuditTransaction}
    alias Threadline.OperatorSurface.Controllers.ExportController
    alias Threadline.OperatorSurface.ExportControllerTelemetryTest.ClosedChunkAdapter

    @repo Threadline.Test.Repo
    @export_events [[:threadline, :export, :completed], [:threadline, :export, :failed]]

    setup do
      on_exit(fn ->
        @repo.delete_all(AuditChange, repo_opts())
        @repo.delete_all(AuditTransaction, repo_opts())
      end)

      :ok
    end

    test "more than 5,000 matching rows, clean stream: exactly one :completed, no :failed" do
      table = bulk_seed!(5_001)
      ref = attach_telemetry!(@export_events)

      conn = ExportController.csv(direct_conn(), %{"table" => table})

      assert conn.state == :chunked

      assert_receive {[:threadline, :export, :completed], ^ref, measurements, metadata}
      assert measurements.row_count == 5_001
      assert metadata.format == :csv
      assert metadata.truncated == false

      refute_receive {[:threadline, :export, :failed], ^ref, _measurements, _metadata}
    end

    @tag :slow
    test "more than 10,000 matching rows: :completed with row_count 10,000 and truncated true" do
      table = bulk_seed!(10_001)
      ref = attach_telemetry!(@export_events)

      conn = ExportController.csv(direct_conn(), %{"table" => table})

      assert conn.state == :chunked

      assert_receive {[:threadline, :export, :completed], ^ref, measurements, metadata}
      assert measurements.row_count == 10_000
      assert metadata.truncated == true

      refute_receive {[:threadline, :export, :failed], ^ref, _measurements, _metadata}
    end

    test "a chunk write error emits exactly one :failed with error_kind :client_closed" do
      table = bulk_seed!(5_001)
      ref = attach_telemetry!(@export_events)

      conn = ExportController.csv(closed_conn(), %{"table" => table})

      assert_receive {[:threadline, :export, :failed], ^ref, measurements, metadata}
      assert measurements.row_count == 0
      assert metadata.format == :csv
      assert metadata.error_kind == :client_closed
      assert metadata.exception == nil

      refute_receive {[:threadline, :export, :completed], ^ref, _measurements, _metadata}

      # No crash: the controller still finishes the (best-effort) suffix emit.
      assert conn.state == :chunked
    end

    test "5,000 or fewer rows: exactly one :completed from the eager path, not two" do
      table = bulk_seed!(10)
      ref = attach_telemetry!(@export_events)

      conn = ExportController.csv(direct_conn(), %{"table" => table})

      refute conn.state == :chunked
      assert conn.status == 200

      assert_receive {[:threadline, :export, :completed], ^ref, measurements, metadata}
      assert measurements.row_count == 10
      assert metadata.format == :csv

      refute_receive {[:threadline, :export, :completed], ^ref, _measurements, _metadata}
      refute_receive {[:threadline, :export, :failed], ^ref, _measurements, _metadata}
    end

    # ---- Helpers ----

    defp direct_conn do
      :get
      |> conn("/exports/changes.csv")
      |> assign(:threadline_repo, @repo)
    end

    defp closed_conn do
      conn = direct_conn()
      {_adapter, state} = conn.adapter
      %{conn | adapter: {ClosedChunkAdapter, state}}
    end

    defp bulk_seed!(n) when n > 0 do
      table = "export_controller_telemetry_#{System.unique_integer([:positive])}"

      txn =
        @repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          }),
          repo_opts()
        )

      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      changes =
        for i <- 1..n do
          %{
            id: Ecto.UUID.generate(),
            transaction_id: txn.id,
            table_schema: "public",
            table_name: table,
            table_pk: %{"id" => "#{i}"},
            op: "insert",
            data_after: %{"i" => i},
            captured_at: now
          }
        end

      # Insert in batches of 1_000 to stay under PG's bind-parameter limit.
      changes
      |> Enum.chunk_every(1_000)
      |> Enum.each(fn chunk ->
        @repo.insert_all(AuditChange, chunk, repo_opts())
      end)

      table
    end
  end
end
