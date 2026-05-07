if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportControllerTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end

    def render("500.html", assigns) do
      ~H"Error 500: <%= inspect(assigns.reason) %>"
    end
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.Router do
    use Phoenix.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      # NOTE: extends Phase 64's `["html"]` to include csv + json formats so
      # response_content_type/2 lookups for :csv / :json succeed.
      plug(:accepts, ["html", "csv", "json"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_export_key",
      signing_salt: String.duplicate("x", 8)
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason)
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ExportControllerTest.Router)
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest do
    @moduledoc false
    # async: false — Threadline does NOT use SQL Sandbox; tests share a real DB
    # and clean up between cases (test/support/data_case.ex documents the why).
    use ExUnit.Case, async: false

    import Phoenix.ConnTest
    import Plug.Conn, only: [get_resp_header: 2]

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo Threadline.Test.Repo

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: String.duplicate("x", 64),
        live_view: [signing_salt: String.duplicate("x", 8)],
        render_errors: [view: Threadline.OperatorSurface.ExportControllerTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      # Honest cleanup — same as DataCase, FK order. Threadline does NOT use
      # SQL Sandbox; cleanup happens in setup before each test.
      @repo.delete_all(AuditChange)
      @repo.delete_all(AuditTransaction)

      if Code.ensure_loaded?(Threadline.Semantics.AuditAction) do
        @repo.delete_all(Threadline.Semantics.AuditAction)
      end

      {:ok, conn: build_conn()}
    end

    # ---- Iodata path: count <= 5_000 ----

    test "GET /audit/exports/changes.csv with small window returns 200 + CSV iodata", %{conn: conn} do
      seed_changes!(10, table: "posts")

      from = "2020-01-01T00:00"
      to = "2099-01-01T00:00"

      conn = get(conn, "/audit/exports/changes.csv?from=#{from}&to=#{to}&table=posts")

      assert conn.status == 200
      assert response_content_type(conn, :csv) =~ "text/csv"

      [disposition] = get_resp_header(conn, "content-disposition")
      assert disposition =~ ~r/attachment; filename="threadline-changes-/
      assert disposition =~ ~r/filename\*=UTF-8''/

      [cache_control] = get_resp_header(conn, "cache-control")
      assert cache_control == "no-store"

      body = response(conn, 200)
      # RFC 4180: header row + 10 data rows; no BOM.
      refute String.starts_with?(body, "\xEF\xBB\xBF")
      lines = String.split(body, "\r\n", trim: true)
      assert length(lines) == 11
    end

    test "GET /audit/exports/changes.json with small window returns 200 + parseable JSON",
         %{conn: conn} do
      seed_changes!(5, table: "posts")

      from = "2020-01-01T00:00"
      to = "2099-01-01T00:00"

      conn = get(conn, "/audit/exports/changes.json?from=#{from}&to=#{to}&table=posts")

      assert conn.status == 200
      [content_type] = get_resp_header(conn, "content-type")
      assert content_type == "application/json; charset=utf-8"

      body = response(conn, 200)
      assert {:ok, decoded} = Jason.decode(body)
      assert is_map(decoded)
      assert is_list(decoded["changes"])
      assert length(decoded["changes"]) == 5
    end

    test "GET /audit/exports/changes.ndjson with small window returns 200 + per-line JSON",
         %{conn: conn} do
      seed_changes!(3, table: "posts")

      from = "2020-01-01T00:00"
      to = "2099-01-01T00:00"

      conn = get(conn, "/audit/exports/changes.ndjson?from=#{from}&to=#{to}&table=posts")

      assert conn.status == 200
      [content_type] = get_resp_header(conn, "content-type")
      assert content_type == "application/x-ndjson; charset=utf-8"

      body = response(conn, 200)

      lines = body |> String.split("\n", trim: true)
      assert length(lines) == 3

      for line <- lines do
        assert {:ok, _} = Jason.decode(line)
      end
    end

    # ---- Chunked path (D-27, EXPO-05 — load-bearing) ----

    @tag :slow
    test "GET /audit/exports/changes.csv with >5,000 rows returns 200 + chunked transfer state",
         %{conn: conn} do
      # D-27 mandates >5,000 rows for chunked-path coverage. 5,001 keeps test under ~250ms locally.
      bulk_seed_changes!(5_001, table: "posts")

      from = "2020-01-01T00:00"
      to = "2099-01-01T00:00"

      conn = get(conn, "/audit/exports/changes.csv?from=#{from}&to=#{to}&table=posts")

      assert conn.status == 200
      assert response_content_type(conn, :csv) =~ "text/csv"

      # Plug.Test stitches chunks into a single binary response in conn.resp_body.
      # The transport-state assertion proves the controller chose the chunked branch.
      assert conn.state == :chunked

      body = conn.resp_body
      lines = String.split(body, "\r\n", trim: true)
      # 1 header + 5,001 data rows
      assert length(lines) >= 5_001
    end

    # ---- 422 on invalid filter (EXPO-03 re-validation contract) ----

    test "GET with invalid datetime filter returns 422 plain text", %{conn: conn} do
      conn = get(conn, "/audit/exports/changes.csv?from=not-a-date")

      assert conn.status == 422
      [content_type] = get_resp_header(conn, "content-type")
      assert content_type =~ "text/plain"
      assert response(conn, 422) =~ "invalid"
    end

    # ---- Empty window — header-only CSV (RFC 4180 valid) ----

    test "GET with no matching rows returns 200 + header-only CSV (RFC 4180 valid)", %{conn: conn} do
      from = "2020-01-01T00:00"
      to = "2020-01-02T00:00"

      conn = get(conn, "/audit/exports/changes.csv?from=#{from}&to=#{to}&table=does_not_exist")

      assert conn.status == 200
      body = response(conn, 200)
      lines = String.split(body, "\r\n", trim: true)
      # Header only — no data rows
      assert length(lines) == 1
    end

    # ---- Helpers ----

    defp seed_changes!(n, opts) when n > 0 do
      table = Keyword.fetch!(opts, :table)

      txn =
        @repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      for i <- 1..n do
        @repo.insert!(
          AuditChange.changeset(%{
            transaction_id: txn.id,
            table_schema: "public",
            table_name: table,
            table_pk: %{"id" => "#{i}"},
            op: "insert",
            data_after: %{"i" => i},
            captured_at: now
          })
        )
      end
    end

    defp bulk_seed_changes!(n, opts) when n > 0 do
      # Bulk insert via Repo.insert_all/3 — much faster than n individual changesets.
      # Pattern source: timeline_live_test.exs `bulk_seed_changes!/2` (Plan 03).
      # Batches at 1_000 rows per call to stay under PG's 65_535 bind-parameter limit.
      table = Keyword.fetch!(opts, :table)

      txn =
        @repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
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

      changes
      |> Enum.chunk_every(1_000)
      |> Enum.each(fn chunk -> @repo.insert_all(AuditChange, chunk) end)
    end
  end
end
