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

  defmodule Threadline.OperatorSurface.ExportControllerTest.ScopedRouter do
    use Phoenix.Router
    import Ecto.Query
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html", "csv", "json"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_scoped",
        authorize_fn: &__MODULE__.auth/1,
        scope_query_fn: &__MODULE__.scope_operator_query/3
      )
    end

    def auth(_mirror), do: {:ok, %{source: "support"}}

    def scope_operator_query(query, %{source: source}, %{surface: :export}) do
      where(query, [_ac, at], at.source == ^source)
    end

    def scope_operator_query(query, _scope, _context), do: query
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.DeniedRouter do
    use Phoenix.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html", "csv", "json"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_denied",
        export_authorize_fn: &__MODULE__.export_auth/1
      )
    end

    def export_auth(_mirror), do: {:error, :unauthorized}
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

  defmodule Threadline.OperatorSurface.ExportControllerTest.ScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_export_scoped_key",
      signing_salt: String.duplicate("y", 8)
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason)
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ExportControllerTest.ScopedRouter)
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.DeniedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_export_denied_key",
      signing_salt: String.duplicate("d", 8)
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason)
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ExportControllerTest.DeniedRouter)
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest do
    @moduledoc false
    # async: false — Threadline does NOT use SQL Sandbox; tests share a real DB
    # and clean up between cases (test/support/data_case.ex documents the why).
    use ExUnit.Case, async: false

    import Phoenix.ConnTest
    import Plug.Conn, only: [get_resp_header: 2, assign: 3]

    alias Threadline.Capture.{AuditChange, AuditTransaction}
    alias Threadline.Governance.ExportJob

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo Threadline.Test.Repo

    defmodule RemoteStorageStub do
      @behaviour Threadline.Storage

      @impl true
      def init(_opts), do: :ok

      @impl true
      def put(_content, _opts), do: {:error, :unsupported}

      @impl true
      def get(_file_id), do: {:error, :unsupported}

      @impl true
      def path(_file_id), do: {:error, :not_local}

      @impl true
      def download_url(file_id, opts \\ []) do
        case Keyword.get(opts, :test_download_result, :ok) do
          :ok -> {:ok, "https://downloads.example.test/#{file_id}"}
          :error -> {:error, :presign_failed}
        end
      end

      @impl true
      def delete(_file_id), do: :ok
    end

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

    test "GET /audit/exports/changes.csv with small window returns 200 + CSV iodata", %{
      conn: conn
    } do
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

    # ---- Download path ----

    describe "GET /audit/exports/download/:job_id" do
      setup do
        @repo.delete_all(ExportJob)
        previous_storage_adapter = Application.get_env(:threadline, :storage_adapter)
        previous_remote_opts = Application.get_env(:threadline, RemoteStorageStub)

        Application.put_env(:threadline, :storage_adapter, Threadline.Storage.Local)
        Application.delete_env(:threadline, RemoteStorageStub)

        on_exit(fn ->
          if previous_storage_adapter do
            Application.put_env(:threadline, :storage_adapter, previous_storage_adapter)
          else
            Application.delete_env(:threadline, :storage_adapter)
          end

          if previous_remote_opts do
            Application.put_env(:threadline, RemoteStorageStub, previous_remote_opts)
          else
            Application.delete_env(:threadline, RemoteStorageStub)
          end
        end)

        # Ensure priv/threadline_exports directory exists for Local storage
        priv_dir = :code.priv_dir(:threadline) || "priv"
        export_dir = Path.join([to_string(priv_dir), "threadline_exports"])
        File.mkdir_p!(export_dir)

        {:ok, export_dir: export_dir}
      end

      test "returns 200 and serves the file if valid and authorized", %{
        conn: conn,
        export_dir: export_dir
      } do
        job_id = Ecto.UUID.generate()
        file_name = "#{job_id}.csv"
        file_path = Path.join(export_dir, file_name)
        File.write!(file_path, "col1,col2\n1,2")

        job =
          @repo.insert!(%ExportJob{
            id: job_id,
            status: "completed",
            query_params: %{"format" => "csv"},
            file_path: file_name,
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"}
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 200
        assert response(conn, 200) == "col1,col2\n1,2"
        [disposition] = get_resp_header(conn, "content-disposition")
        assert disposition =~ ~s|filename="#{file_name}"|
      end

      test "returns a backend-native redirect for configured remote storage", %{conn: conn} do
        Application.put_env(:threadline, :storage_adapter, RemoteStorageStub)

        job =
          @repo.insert!(%ExportJob{
            status: "completed",
            query_params: %{"format" => "csv"},
            file_path: "remote-export.csv",
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"},
            expires_at:
              DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.truncate(:microsecond)
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 302
        assert get_resp_header(conn, "location") == ["https://downloads.example.test/remote-export.csv"]
      end

      test "returns 404 if actor_ref does not match (IDOR protection)", %{
        conn: conn,
        export_dir: export_dir
      } do
        job_id = Ecto.UUID.generate()
        file_name = "#{job_id}.csv"
        file_path = Path.join(export_dir, file_name)
        File.write!(file_path, "col1,col2\n1,2")

        job =
          @repo.insert!(%ExportJob{
            id: job_id,
            status: "completed",
            query_params: %{"format" => "csv"},
            file_path: file_name,
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"}
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "456"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 404
        assert response(conn, 404) =~ "Export not found"
      end

      test "returns 422 if job is not completed", %{conn: conn} do
        job =
          @repo.insert!(%ExportJob{
            status: "processing",
            query_params: %{"format" => "csv"},
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"}
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 422
        assert response(conn, 422) =~ "Export not ready or failed"
      end

      test "returns 404 if file does not exist locally", %{conn: conn} do
        job =
          @repo.insert!(%ExportJob{
            status: "completed",
            query_params: %{"format" => "csv"},
            file_path: "non_existent.csv",
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"}
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 404
        assert response(conn, 404) =~ "Export download is not available"
      end

      test "returns 404 when remote download URL generation fails", %{conn: conn} do
        Application.put_env(:threadline, :storage_adapter, RemoteStorageStub)
        Application.put_env(:threadline, RemoteStorageStub, test_download_result: :error)

        job =
          @repo.insert!(%ExportJob{
            status: "completed",
            query_params: %{"format" => "csv"},
            file_path: "remote-export.csv",
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"},
            expires_at:
              DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.truncate(:microsecond)
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 404
        assert response(conn, 404) =~ "Export download is not available"
      end

      test "returns 400 if job_id is invalid", %{conn: conn} do
        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/not-a-uuid")

        assert conn.status == 400
        assert response(conn, 400) =~ "Invalid job ID"
      end

      test "returns 410 when a completed export has expired", %{conn: conn} do
        job =
          @repo.insert!(%ExportJob{
            status: "completed",
            query_params: %{"format" => "csv"},
            file_path: "expired.csv",
            actor_ref: %Threadline.Semantics.ActorRef{type: :user, id: "123"},
            expires_at:
              DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:microsecond)
          })

        conn =
          conn
          |> assign(:threadline_actor_ref, %Threadline.Semantics.ActorRef{type: :user, id: "123"})
          |> get("/audit/exports/download/#{job.id}")

        assert conn.status == 410
        assert response(conn, 410) =~ "no longer available"
      end
    end
  end

  defmodule Threadline.OperatorSurface.ExportControllerScopedTest do
    @moduledoc false
    use ExUnit.Case, async: false

    import Phoenix.ConnTest

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.ExportControllerTest.ScopedEndpoint
    @repo Threadline.Test.Repo

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: String.duplicate("y", 64),
        live_view: [signing_salt: String.duplicate("y", 8)],
        render_errors: [view: Threadline.OperatorSurface.ExportControllerTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      @repo.delete_all(AuditChange)
      @repo.delete_all(AuditTransaction)
      {:ok, conn: build_conn()}
    end

    test "scoped export only returns rows allowed by scope_query_fn", %{conn: conn} do
      seed_changes!(1, table: "support_posts", source: "support")
      seed_changes!(1, table: "admin_posts", source: "admin")

      conn =
        get(conn, "/audit_scoped/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

      body = response(conn, 200)

      assert body =~ "support_posts"
      refute body =~ "admin_posts"
    end

    defp seed_changes!(n, opts) when n > 0 do
      table = Keyword.fetch!(opts, :table)
      source = Keyword.get(opts, :source, "support")

      txn =
        @repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now(),
            source: source
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
  end

  defmodule Threadline.OperatorSurface.ExportControllerDeniedTest do
    @moduledoc false
    use ExUnit.Case, async: false

    import Phoenix.ConnTest

    @endpoint Threadline.OperatorSurface.ExportControllerTest.DeniedEndpoint

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: String.duplicate("d", 64),
        live_view: [signing_salt: String.duplicate("d", 8)],
        render_errors: [view: Threadline.OperatorSurface.ExportControllerTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    test "direct export denial returns a plain-text 403 forbidden response", %{conn: conn} do
      conn =
        get(
          conn,
          "/audit_denied/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00&table=posts"
        )

      assert conn.status == 403
      assert response(conn, 403) == "forbidden"
    end

    setup do
      {:ok, conn: build_conn()}
    end
  end
end
