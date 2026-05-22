if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.RetentionHistoryLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "r3t3nt10n"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.RetentionHistoryLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest do
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Governance.RetentionRun

    @endpoint Threadline.OperatorSurface.RetentionHistoryLiveTest.Endpoint

    setup_all do
      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.RetentionHistoryLiveTest.Endpoint,
        secret_key_base: "r" |> String.duplicate(64),
        live_view: [signing_salt: "r" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.RetentionHistoryLiveTest.Layouts]
      )

      original_interval = Application.get_env(:threadline, :retention_poll_ms)
      Application.put_env(:threadline, :retention_poll_ms, 5_000)

      on_exit(fn ->
        if original_interval do
          Application.put_env(:threadline, :retention_poll_ms, original_interval)
        else
          Application.delete_env(:threadline, :retention_poll_ms)
        end
      end)

      start_supervised!(@endpoint)

      # Start the pruner since we interact with it, but configure it so it doesn't poll often
      start_supervised!(
        {Threadline.Retention.Pruner, repo: Threadline.Test.Repo, interval_ms: :timer.hours(24)}
      )

      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(RetentionRun)

      original_retention = Application.get_env(:threadline, :retention)

      Application.put_env(
        :threadline,
        :retention,
        Keyword.put(original_retention || [], :enabled, true)
      )

      on_exit(fn ->
        if original_retention do
          Application.put_env(:threadline, :retention, original_retention)
        else
          Application.delete_env(:threadline, :retention)
        end
      end)

      {:ok, conn: build_conn()}
    end

    describe "retention history live view" do
      test "shows empty state when no runs exist", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/policy/retention")
        assert html =~ "No Retention History"
        assert html =~ "Run Pruning Batch"
      end

      test "displays existing retention runs in a table", %{conn: conn} do
        # Insert a run
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "completed",
          deleted_count: 100,
          duration_ms: 1500,
          started_at: DateTime.add(now, -10, :second),
          completed_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        refute html =~ "No Retention History"
        assert html =~ "completed"
        assert html =~ "100"
        # Or formatted, depending on implementation
        assert html =~ "1500"
      end

      test "Run Pruning Batch CTA triggers GenServer.cast asynchronously", %{conn: conn} do
        {:ok, view, html} = live(conn, "/audit/policy/retention")

        # Click the button
        assert html =~ "Run Pruning Batch"

        # ensure no active runs initially
        assert Threadline.Test.Repo.aggregate(RetentionRun, :count) == 0

        # simulate click
        view
        |> element("button", "Run Pruning Batch")
        |> render_click()

        # The GenServer cast happens asynchronously.
        # We can wait a little bit or try to see if a run starts in the DB.
        # But `handle_event` might also show a flash or just return.
        # Let's check that the table updates with a running run or at least a run is created.

        # We'll assert that a DB record was created by the Pruner after some time
        # wait a bit for gen server to process
        :timer.sleep(100)
        assert Threadline.Test.Repo.aggregate(RetentionRun, :count) > 0
      end

      test "page auto-refreshes periodically", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")

        # Send refresh message directly to trigger it
        send(view.pid, :refresh)

        # Should not crash and render successfully
        assert render(view) =~ "Run Pruning Batch"
      end
    end
  end
end
