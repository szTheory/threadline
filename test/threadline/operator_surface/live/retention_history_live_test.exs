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

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        policy_authorize_fn: &Threadline.OperatorSurface.RetentionHistoryLiveTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Auth do
    def authorize(_mirror), do: Application.get_env(:threadline, :test_allow_policy, true)
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
    alias Threadline.Retention.Pruner

    @endpoint Threadline.OperatorSurface.RetentionHistoryLiveTest.Endpoint

    defp start_application_supervisor! do
      retention = Application.get_env(:threadline, :retention, [])

      opts =
        [repo: Threadline.Test.Repo]
        |> Keyword.merge(Keyword.take(retention, [:interval_ms, :sleep_ms]))

      start_supervised!({Threadline.Retention.Pruner, opts})
    end

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
      Application.put_env(:threadline, :test_allow_policy, true)

      :ok
    end

    setup do
      stop_named_process!(Pruner)
      Threadline.Test.Repo.delete_all(RetentionRun)

      original_retention = Application.get_env(:threadline, :retention)

      Application.put_env(
        :threadline,
        :retention,
        (original_retention || [])
        |> Keyword.put(:enabled, true)
        |> Keyword.put(:interval_ms, :timer.hours(24))
        |> Keyword.put(:sleep_ms, 0)
      )

      on_exit(fn ->
        if original_retention do
          Application.put_env(:threadline, :retention, original_retention)
        else
          Application.delete_env(:threadline, :retention)
        end
      end)

      start_application_supervisor!()

      {:ok, conn: build_conn()}
    end

    describe "retention history live view" do
      test "renders unsupported state when policy access is disabled", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_policy, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_policy, true) end)

        {:ok, _view, html} = live(conn, "/audit/policy/retention")
        assert html =~ "Unsupported View"
        assert html =~ "Retention history is not available"
        assert html =~ "mix threadline.retention.purge --dry-run"
        refute html =~ "Run prune now"
      end

      test "shows empty state when no runs exist", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/policy/retention")
        assert html =~ "No Retention History"
        assert html =~ "Run prune now"
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

      test "shows a success alert when latest run succeeded with no failures", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "completed",
          deleted_count: 42,
          duration_ms: 500,
          started_at: DateTime.add(now, -5, :second),
          completed_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        assert html =~ "Latest run succeeded"
        refute html =~ "Review the latest status and failure count"
      end

      test "shows a warning alert when a run has failed", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "failed",
          started_at: DateTime.add(now, -5, :second)
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        assert html =~ "Review the latest status and failure count"
        refute html =~ "Latest run succeeded"
      end

      test "Run prune now CTA triggers the supervised runtime path", %{conn: conn} do
        {:ok, view, html} = live(conn, "/audit/policy/retention")

        # Click the button
        assert html =~ "Run prune now"

        # ensure no active runs initially
        assert Threadline.Test.Repo.aggregate(RetentionRun, :count) == 0
        assert Pruner.started?()

        # simulate click
        view
        |> element("button", "Run prune now")
        |> render_click()

        assert_eventually(fn ->
          Threadline.Test.Repo.aggregate(RetentionRun, :count) > 0
        end)
      end

      test "page auto-refreshes periodically", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")

        # Send refresh message directly to trigger it
        send(view.pid, :refresh)

        # Should not crash and render successfully
        assert render(view) =~ "Run prune now"
      end
    end
  end
end
