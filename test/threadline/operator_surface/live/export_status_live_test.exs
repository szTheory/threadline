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

  defmodule Threadline.OperatorSurface.ExportStatusLiveTest.SuccessfulQueueAdapter do
    @behaviour Threadline.ExportQueue

    @impl true
    def init(_opts), do: :ok

    @impl true
    def enqueue(_job_id, _opts \\ []), do: :ok
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
        assert html =~ "Export access needed"
        assert html =~ "You do not have access to exports."
        assert html =~ "export_authorize_fn"
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

        assert html =~ "Export access needed"
        assert html =~ "mix threadline.export --dry-run"
        assert html =~ "--table &#39;posts&#39;"
        assert html =~ "--from &#39;2026-05-01T00:00:00Z&#39;"
        assert html =~ "--to &#39;2026-05-06T23:59:00Z&#39;"
        refute html =~ "No Export Jobs"
      end

      test "shows empty state when no jobs exist", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/exports")
        assert html =~ "What&#39;s ready to hand off?"
        assert html =~ "No export jobs queued"
        assert html =~ "Open timeline"
      end

      test "renders carried Timeline export context with canonical allowed filters", %{conn: conn} do
        {:ok, _view, html} =
          live(
            conn,
            "/audit/exports?table=ticket_replies&correlation_id=req_ef3&from=2026-05-01T00:00&to=2026-05-06T23:59&unknown=drop_me"
          )

        assert html =~ "Timeline export context"
        assert html =~ "Exports handoff"
        assert html =~ ~s|data-testid="timeline-export-context"|
        assert html =~ ~s|data-earned-flow="EF3"|
        assert html =~ ~s|data-persona="P3"|
        assert html =~ ~s|data-jtbd="J6"|
        assert html =~ "table"
        assert html =~ "ticket_replies"
        assert html =~ "correlation_id"
        assert html =~ "req_ef3"
        assert html =~ "from"
        assert html =~ "2026-05-01T00:00"
        assert html =~ "to"
        assert html =~ "2026-05-06T23:59"
        assert html =~ "Queue Timeline export"
        refute html =~ "unknown"
        refute html =~ "drop_me"
        refute html =~ "subject_ref_json"
      end

      test "invalid carried Timeline context is visible and cannot queue a job", %{conn: conn} do
        {:ok, view, html} = live(conn, "/audit/exports?from=not-a-date")

        assert html =~ "Timeline export context"
        assert html =~ "Timeline export context could not be applied"
        refute html =~ "Queue Timeline export"

        assert_raise ArgumentError, fn ->
          view |> element("button", "Queue Timeline export") |> render_click()
        end

        assert Threadline.Test.Repo.all(ExportJob) == []
      end

      test "denied exports ignore forged Timeline context queue events", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_exports, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_exports, true) end)

        {:ok, view, html} =
          live(conn, "/audit/exports?table=ticket_replies&correlation_id=req_ef3")

        assert html =~ "Export access needed"
        refute html =~ "Queue Timeline export"

        render_click(view, "queue_timeline_export_context", %{})

        assert Threadline.Test.Repo.all(ExportJob) == []
      end

      test "renders carried Evidence proof context separately from Timeline exports", %{
        conn: conn
      } do
        subject_ref_json = URI.encode_www_form(~s({"export_id":"export-123"}))

        {:ok, _view, html} =
          live(
            conn,
            "/audit/exports?source=evidence&subject=export_delivery&mode=history&subject_ref_json=#{subject_ref_json}"
          )

        assert html =~ "Evidence proof context"
        assert html =~ "Proof handoff"
        assert html =~ ~s|data-testid="evidence-export-context"|
        assert html =~ ~s|data-earned-flow="EF3"|
        assert html =~ ~s|data-persona="P3"|
        assert html =~ ~s|data-jtbd="J6"|
        assert html =~ "export_delivery"
        assert html =~ "history"
        assert html =~ "export-123"
        assert html =~ ~s|href="/audit/evidence?|
        assert html =~ "subject=export_delivery"
        assert html =~ "subject_ref_json="
        assert html =~ "mode=history"
        assert html =~ "Reopen Evidence proof"
        refute html =~ "Queue Timeline export"
        refute html =~ ~s|data-testid="timeline-export-context"|
      end

      test "rejects invalid Evidence proof context without creating ExportJobs", %{conn: conn} do
        for {query, message} <- [
              {"source=evidence&subject=not_supported", "Unsupported evidence subject"},
              {"source=evidence&subject=export_delivery&mode=archive",
               "Unsupported evidence mode"},
              {"source=evidence&subject_ref_json=%7Bbad", "Invalid subject_ref_json"},
              {"source=evidence&subject_ref_json=%7B%22export_id%22%3A%22123%22%7D",
               "subject_ref_json requires a subject filter"},
              {"source=evidence&subject=export_delivery&mode=history",
               "History drill-down requires subject_ref_json"},
              {"source=evidence&subject=export_delivery&unexpected=param",
               "Unsupported Evidence proof context parameter"}
            ] do
          {:ok, _view, html} = live(conn, "/audit/exports?#{query}")

          assert html =~ "Evidence proof context could not be applied"
          assert html =~ message
          refute html =~ "Reopen Evidence proof"
          refute html =~ "Queue Timeline export"
        end

        assert Threadline.Test.Repo.all(ExportJob) == []
      end

      test "does not pass Evidence proof params into Timeline file export hrefs", %{conn: conn} do
        subject_ref_json = URI.encode_www_form(~s({"export_id":"export-123"}))

        {:ok, _view, html} =
          live(
            conn,
            "/audit/exports?source=evidence&subject=export_delivery&mode=history&subject_ref_json=#{subject_ref_json}"
          )

        refute html =~ "/exports/changes.csv"
        refute html =~ "/exports/changes.json"
        refute html =~ "/exports/changes.ndjson"
        refute html =~ "/exports/changes.csv?subject_ref_json"
        refute html =~ "/exports/changes.json?subject_ref_json"
        refute html =~ "/exports/changes.ndjson?subject_ref_json"
      end

      test "queueing carried Timeline context creates an actor-owned canonical ExportJob", %{
        conn: conn,
        actor_ref: actor_ref
      } do
        original_adapter = Application.get_env(:threadline, :export_queue_adapter)

        Application.put_env(
          :threadline,
          :export_queue_adapter,
          Threadline.OperatorSurface.ExportStatusLiveTest.SuccessfulQueueAdapter
        )

        on_exit(fn ->
          if original_adapter do
            Application.put_env(:threadline, :export_queue_adapter, original_adapter)
          else
            Application.delete_env(:threadline, :export_queue_adapter)
          end
        end)

        {:ok, view, _html} =
          live(
            conn,
            "/audit/exports?table=ticket_replies&correlation_id=req_ef3&from=2026-05-01T00:00&to=2026-05-06T23:59&unknown=drop_me"
          )

        view |> element("button", "Queue Timeline export") |> render_click()

        assert_redirect(view, "/audit/exports")

        [job] = Threadline.Test.Repo.all(ExportJob)
        assert job.status == "pending"
        assert job.actor_ref == actor_ref

        assert job.query_params == %{
                 "from" => "2026-05-01T00:00",
                 "to" => "2026-05-06T23:59",
                 "table" => "ticket_replies",
                 "correlation_id" => "req_ef3"
               }
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

        refute html =~ "No export jobs queued"
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

        assert html =~ "No export jobs queued"
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
        assert html =~ "Ready to hand off"
        assert html =~ "Download export"
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
        refute html =~ "Download export"
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

        refute html =~ "Download export"
        assert html =~ "Export expired"
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
        assert html =~ "Needs attention"
        assert html =~ "Export failed."
        assert html =~ "Reopen source search"
        assert html =~ "built-in export runtime is unavailable"
      end

      test "groups exports by readiness in operator order with secondary refs", %{
        conn: conn,
        actor_ref: actor_ref
      } do
        now = DateTime.utc_now() |> DateTime.truncate(:second)
        long_correlation = "corr-" <> String.duplicate("abc123", 8)

        [
          %{
            status: "completed",
            query_params: %{"table" => "users", "correlation_id" => long_correlation},
            file_path: "ready.csv",
            expires_at: DateTime.add(now, 600, :second),
            started_at: DateTime.add(now, -10, :second),
            completed_at: DateTime.add(now, -5, :second)
          },
          %{
            status: "running",
            query_params: %{"table" => "users"},
            started_at: DateTime.add(now, -20, :second)
          },
          %{
            status: "failed",
            query_params: %{"table" => "users"},
            started_at: DateTime.add(now, -30, :second),
            error_message: "runtime unavailable"
          },
          %{
            status: "completed",
            query_params: %{"table" => "users"},
            file_path: "expired.csv",
            expires_at: DateTime.add(now, -60, :second),
            started_at: DateTime.add(now, -40, :second),
            completed_at: DateTime.add(now, -35, :second)
          },
          %{
            status: "completed",
            query_params: %{"table" => "users"},
            started_at: DateTime.add(now, -50, :second),
            completed_at: DateTime.add(now, -45, :second)
          }
        ]
        |> Enum.each(fn attrs ->
          %ExportJob{}
          |> ExportJob.changeset(Map.put(attrs, :actor_ref, actor_ref))
          |> Threadline.Test.Repo.insert!()
        end)

        {:ok, _view, html} = live(conn, "/audit/exports")

        assert html =~ "Ready to hand off"
        assert html =~ "Preparing"
        assert html =~ "Needs attention"
        assert html =~ "Unavailable"
        assert html =~ "Download export"
        assert html =~ "Preparing download"
        assert html =~ "Export expired"
        assert html =~ "File unavailable"
        assert html =~ "tl-secondary-ref"
        assert html =~ long_correlation

        # Export filters now render as a kv <dl>: the key is the <dt> and the full
        # value is recoverable via UI.ref (title + data-tl-copy bind the FULL value).
        assert html =~ ~s(class="tl-kv)
        assert html =~ ~s(correlation_id</dt>)
        assert html =~ ~s(title="#{long_correlation}")
        assert html =~ ~s(data-tl-copy="#{long_correlation}")

        assert String.contains?(html, "Ready to hand off") and
                 String.contains?(html, "Preparing") and
                 String.contains?(html, "Needs attention") and
                 String.contains?(html, "Unavailable")
      end
    end
  end
end
