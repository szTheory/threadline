if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.ExportStatusLiveTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end
  end

  defmodule Threadline.OperatorSurface.ExportStatusLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.ExportStatusLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        export_authorize_fn: &Threadline.OperatorSurface.ExportStatusLiveTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.ExportStatusLiveTest.Auth do
    def authorize(_mirror), do: Application.get_env(:threadline, :test_allow_exports, true)
  end

  defmodule Threadline.OperatorSurface.ExportStatusLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "eXp0rT"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.ExportStatusLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.ExportStatusLiveTest do
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Governance.ExportJob
    alias Threadline.Semantics.ActorRef

    @endpoint Threadline.OperatorSurface.ExportStatusLiveTest.Endpoint

    setup_all do
      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.ExportStatusLiveTest.Endpoint,
        secret_key_base: "e" |> String.duplicate(64),
        live_view: [signing_salt: "e" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.ExportStatusLiveTest.Layouts]
      )

      original_interval = Application.get_env(:threadline, :export_status_poll_ms)
      original_allow_exports = Application.get_env(:threadline, :test_allow_exports)
      Application.put_env(:threadline, :export_status_poll_ms, 5_000)
      Application.put_env(:threadline, :test_allow_exports, true)

      on_exit(fn ->
        if original_interval do
          Application.put_env(:threadline, :export_status_poll_ms, original_interval)
        else
          Application.delete_env(:threadline, :export_status_poll_ms)
        end

        if is_nil(original_allow_exports) do
          Application.delete_env(:threadline, :test_allow_exports)
        else
          Application.put_env(:threadline, :test_allow_exports, original_allow_exports)
        end
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(ExportJob)

      {:ok, actor_ref} = ActorRef.new(:user, "123")
      session_actor = Jason.encode!(ActorRef.to_map(actor_ref))

      conn = build_conn() |> Plug.Test.init_test_session(threadline_actor_ref: session_actor)

      {:ok, conn: conn, actor_ref: actor_ref}
    end

    describe "export status live view" do
      test "renders a generic denied fallback when the current state is not safely exportable", %{
        conn: conn
      } do
        Application.put_env(:threadline, :test_allow_exports, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_exports, true) end)

        {:ok, _view, html} = live(conn, "/audit/exports?table=posts&actor_kind=user&actor_id=42")
        assert html =~ "Action Denied"
        assert html =~ "explicit host authorization for exports"
        assert html =~ "mix threadline.export --dry-run"
        refute html =~ "--actor_id"
        refute html =~ "--table 'posts'"
        refute html =~ "--table posts"
        refute html =~ "No Export Jobs"
      end

      test "renders an exact denied fallback when table and range filters are safely representable",
           %{conn: conn} do
        Application.put_env(:threadline, :test_allow_exports, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_exports, true) end)

        {:ok, _view, html} =
          live(
            conn,
            "/audit/exports?table=posts&from=2026-05-01T00:00:00Z&to=2026-05-06T23:59:00Z"
          )

        assert html =~ "Action Denied"
        assert html =~ "mix threadline.export --dry-run"
        assert html =~ "--table &#39;posts&#39;"
        assert html =~ "--from &#39;2026-05-01T00:00:00Z&#39;"
        assert html =~ "--to &#39;2026-05-06T23:59:00Z&#39;"
        refute html =~ "No Export Jobs"
      end

      test "shows empty state when no jobs exist", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/exports")
        assert html =~ "No Export Jobs"
        assert html =~ "Open timeline"
      end

      test "displays existing jobs for the actor", %{conn: conn, actor_ref: actor_ref} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %ExportJob{}
        |> ExportJob.changeset(%{
          status: "pending",
          query_params: %{"table" => "users"},
          actor_ref: actor_ref,
          started_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/exports")

        refute html =~ "No Export Jobs"
        assert html =~ "Queued"
        assert html =~ "users"
        assert html =~ "Preparing download"
      end

      test "does not display jobs for other actors", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        {:ok, other_actor} = ActorRef.new(:user, "456")

        %ExportJob{}
        |> ExportJob.changeset(%{
          status: "pending",
          query_params: %{"table" => "users"},
          actor_ref: other_actor,
          started_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/exports")

        assert html =~ "No Export Jobs"
      end

      test "shows download link when completed", %{conn: conn, actor_ref: actor_ref} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        job =
          %ExportJob{}
          |> ExportJob.changeset(%{
            status: "completed",
            query_params: %{"table" => "users"},
            actor_ref: actor_ref,
            started_at: now,
            completed_at: now,
            file_path: "users-export.csv",
            expires_at: DateTime.add(now, 600, :second)
          })
          |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/exports")

        assert html =~ "Completed"
        assert html =~ "Download"
        assert html =~ "Expires"
        assert html =~ "datetime="
        assert html =~ "/audit/exports/download/#{job.id}"
      end

      test "shows preparing download placeholder for non-ready exports", %{
        conn: conn,
        actor_ref: actor_ref
      } do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %ExportJob{}
        |> ExportJob.changeset(%{
          status: "running",
          query_params: %{"table" => "users"},
          actor_ref: actor_ref,
          started_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/exports")

        assert html =~ "Preparing download"
        refute html =~ "Download Export"
      end

      test "hides the download action for expired completed exports", %{
        conn: conn,
        actor_ref: actor_ref
      } do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %ExportJob{}
        |> ExportJob.changeset(%{
          status: "completed",
          query_params: %{"table" => "users"},
          actor_ref: actor_ref,
          started_at: now,
          completed_at: now,
          file_path: "expired-export.csv",
          expires_at: DateTime.add(now, -60, :second)
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/exports")

        refute html =~ "Download Export"
        assert html =~ "Expired"
      end

      test "shows the persisted failure reason for failed jobs", %{
        conn: conn,
        actor_ref: actor_ref
      } do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %ExportJob{}
        |> ExportJob.changeset(%{
          status: "failed",
          query_params: %{"table" => "users"},
          actor_ref: actor_ref,
          started_at: now,
          error_message:
            "Background export could not start because the built-in export runtime is unavailable."
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/exports")

        assert html =~ "Failed"
        assert html =~ "built-in export runtime is unavailable"
      end
    end
  end
end
