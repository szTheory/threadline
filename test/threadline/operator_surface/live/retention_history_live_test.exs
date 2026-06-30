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

    import Threadline.OperatorSurface.RefCopyContract

    alias Threadline.Governance.RetentionRun
    alias Threadline.Retention.Pruner
    alias Threadline.Semantics.AuditAction

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
        assert html =~ "Retention history unavailable"
        assert html =~ "Retention history is unavailable in this support lane"
        assert html =~ "This is not a permissions issue."
        assert html =~ "mix threadline.retention.purge --dry-run"
        refute html =~ "Run retention prune"
      end

      test "shows empty state when no runs exist", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/policy/retention")
        assert html =~ "Retention window"
        assert html =~ "No retention runs yet"
        assert html =~ "Configure a retention window"
        assert html =~ "mix threadline.retention.purge --dry-run"
        assert html =~ "Run retention prune"
        assert html =~ "tl-button--secondary tl-button--danger"

        # The destructive prune is now a server-enforced T3 type-to-confirm flow
        # (D-21): the client-only data-confirm is gone, and the modal form is
        # mounted only after the operator opens the destructive action.
        refute html =~ "data-confirm"
        refute html =~ "phx-submit=\"prune_now\""
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
        assert html =~ "Latest completed run"
      end

      test "renders one focused retention window health summary without a duplicate trust rail", %{
        conn: conn
      } do
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

        assert html =~ ~s|aria-label="Retention window health"|
        assert html =~ "Latest run"
        assert html =~ "Latest completed run"
        assert html =~ "Rows deleted"
        assert html =~ "Failures"
        assert html =~ "Pruning permanently deletes older audit records by policy"
        refute html =~ "tl-trust-rail"
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
        assert html =~ "retention window is healthy"
        assert html =~ "Pruning permanently deletes older audit records by policy"
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
        assert html =~ "Pruning permanently deletes older audit records by policy"
        refute html =~ "Latest run succeeded"
      end

      test "Run retention prune CTA triggers the supervised runtime path", %{conn: conn} do
        {:ok, view, html} = live(conn, "/audit/policy/retention")

        # The CTA opens the T3 confirm modal; the actual prune is the type-to-confirm
        # form submission (server-enforced, D-21).
        assert html =~ "Run retention prune"

        # ensure no active runs initially
        assert Threadline.Test.Repo.aggregate(RetentionRun, :count) == 0
        assert Pruner.started?()

        # Type the canonical policy name and submit the server-enforced form.
        modal_html = open_prune_modal(view)
        assert modal_html =~ "older than the retention window for policy"
        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: "default"})

        assert_eventually(fn ->
          Threadline.Test.Repo.aggregate(RetentionRun, :count) > 0
        end)
      end

      test "locks destructive flow labels, consequence copy, and modal focus affordances", %{
        conn: conn
      } do
        {:ok, view, html} = live(conn, "/audit/policy/retention")

        assert html =~ "Retention window"
        assert html =~ "Run retention prune"

        modal_html = open_prune_modal(view)

        assert modal_html =~ "Prune retention window permanently?"
        assert modal_html =~ "This permanently deletes audit records older than the retention window"
        assert modal_html =~ "it cannot be undone"
        assert modal_html =~ "Type the policy name <code>default</code> to confirm"
        assert modal_html =~ "Keep retention window"
        assert modal_html =~ "Prune records permanently"
        assert modal_html =~ ~s|role="dialog"|
        assert modal_html =~ ~s|aria-modal="true"|
        assert modal_html =~ "data-tl-initial-focus"
        assert modal_html =~ "data-tl-mutating"
      end

      test "renders only the page-level destructive retention prune entry", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "completed",
          deleted_count: 3,
          duration_ms: 80,
          started_at: DateTime.add(now, -5, :second),
          completed_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        assert occurrences(html, "Run retention prune") == 1
        refute html =~ "Prune records permanently"
      end

      test "no bulk multi-select / select-all-over-destructive control exists (D-19)", %{
        conn: conn
      } do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "completed",
          deleted_count: 3,
          duration_ms: 80,
          started_at: DateTime.add(now, -5, :second),
          completed_at: now
        })
        |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        refute html =~ ~s(type="checkbox"),
               "no per-row/select-all checkbox over the destructive prune (D-19)"

        refute html =~ "select-all"
        refute html =~ "select_all"
      end

      test "page auto-refreshes periodically", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")

        # Send refresh message directly to trigger it
        send(view.pid, :refresh)

        # Should not crash and render successfully
        assert render(view) =~ "Run retention prune"
      end

      test "latest completed context is separate from newest failed run", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        completed =
          %RetentionRun{}
          |> RetentionRun.changeset(%{
            status: "completed",
            deleted_count: 10,
            duration_ms: 250,
            started_at: DateTime.add(now, -120, :second),
            completed_at: DateTime.add(now, -110, :second)
          })
          |> Threadline.Test.Repo.insert!()

        failed =
          %RetentionRun{}
          |> RetentionRun.changeset(%{
            status: "failed",
            started_at: DateTime.add(now, -10, :second)
          })
          |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        assert html =~ "Latest run"
        assert html =~ "Failed"
        assert html =~ "Latest completed run"
        assert html =~ Calendar.strftime(completed.completed_at, "%Y")
        assert html =~ ~s(href="#runs-#{failed.id}")
        assert html =~ "tl-target-row"
        assert html =~ "No rows deleted"
        assert html =~ "No duration yet"
      end
    end

    # -----------------------------------------------------------------------
    # DATA-04 / D-20/D-21. The destructive prune is the only real destructive backend
    # in the surface. These tests assert the load-bearing T3 fail-closed contract:
    # no client-only `data-confirm`, server-side type-to-confirm, event-time authz
    # re-check, scope-filtered query, and `AuditAction` recording for the destructive
    # action itself.
    # -----------------------------------------------------------------------
    describe "T3 destructive prune — server-side fail-closed enforcement" do
      defp count_audit_actions do
        Threadline.Test.Repo.aggregate(AuditAction, :count, :id)
      end

      test "the canonical confirmation token is never shipped to the client", %{conn: conn} do
        {:ok, view, html} = live(conn, "/audit/policy/retention")

        # The client-only data-confirm string is the footgun this plan removes:
        # a real T3 modal types the policy NAME and the canonical token stays
        # server-side (re-fetched at action time, never embedded in the DOM).
        refute html =~ "data-confirm",
               "client-only data-confirm must be replaced by a server-enforced type-to-confirm modal (D-21)"

        refute html =~ "phx-submit=\"prune_now\"",
               "T3 prune form must not be mounted until the destructive action is opened"

        modal_html = open_prune_modal(view)

        assert modal_html =~ "phx-submit",
               "T3 prune must be a <form phx-submit> type-to-confirm, not a bare phx-click"

        assert modal_html =~ "Prune records permanently"
      end

      test "a forged confirmation token fails closed and performs no prune", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")

        before = count_audit_actions()
        open_prune_modal(view)

        # An attacker-supplied wrong token must be rejected server-side
        # (secure_compare against the DB-canonical policy name).
        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: "not-the-policy-name"})

        assert Threadline.Test.Repo.aggregate(RetentionRun, :count) == 0,
               "a forged token must not trigger a prune"

        assert count_audit_actions() == before,
               "a forged token must not produce a prune nor an audited destructive action"
      end

      test "a forged confirmation token flashes the locked mismatch copy", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")

        open_prune_modal(view)

        html =
          render_submit(form(view, "form[phx-submit=prune_now]"), %{
            confirm: "not-the-policy-name"
          })

        assert html =~ "Could not prune - confirmation did not match."
      end

      test "a forged phx-value scope fails closed", %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")
        open_prune_modal(view)

        # phx-value-id is an untrusted client claim; a forged scope must be
        # re-checked + scope-filtered server-side and fail closed.
        render_submit(form(view, "form[phx-submit=prune_now]"), %{
          confirm: "forged",
          id: "00000000-0000-0000-0000-000000000000"
        })

        assert Threadline.Test.Repo.aggregate(RetentionRun, :count) == 0,
               "a forged scope must fail closed"
      end

      test "prune is refused when policy authorization is absent", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_policy, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_policy, true) end)

        # With authz absent the page renders the unsupported view and exposes no
        # prune affordance at all — the default path is refusal (fail closed).
        {:ok, _view, html} = live(conn, "/audit/policy/retention")
        refute html =~ "phx-submit=\"prune_now\""
        refute html =~ "Run retention prune"
      end

      test "a valid type-to-confirm prune records an AuditAction for the destructive action",
           %{conn: conn} do
        {:ok, view, _html} = live(conn, "/audit/policy/retention")

        before = count_audit_actions()

        # The canonical policy name the operator must type (D-21). The handler
        # re-fetches this server-side; the test discovers it from the rendered
        # confirmation prompt rather than hardcoding a constant.
        policy_name = view |> open_prune_modal() |> canonical_policy_name()

        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: policy_name})

        assert_eventually(fn -> Threadline.Test.Repo.aggregate(RetentionRun, :count) > 0 end)

        assert count_audit_actions() > before,
               "a successful destructive prune must record an AuditAction (domain §9.3.4)"
      end

      defp canonical_policy_name(html) do
        case Regex.run(~r/type the policy name [`"]?([a-z0-9_-]+)[`"]?/i, html) do
          [_, name] -> name
          _ -> "default"
        end
      end

      defp open_prune_modal(view) do
        html = render_click(element(view, "button", "Run retention prune"))

        assert html =~ "Prune retention window permanently?"
        assert html =~ "phx-submit=\"prune_now\""

        html
      end

      defp occurrences(haystack, needle) do
        haystack
        |> String.split(needle)
        |> length()
        |> Kernel.-(1)
      end
    end

    # -----------------------------------------------------------------------
    # DATA-01 / D-02, Pitfall 4. Cross-page copy contract: the rendered copy target
    # must carry the EXACT full value, never the truncated visible text. Retention run
    # identifiers use `UI.ref/1`, which binds `data-tl-copy={ref.full}`.
    # -----------------------------------------------------------------------
    describe "ref copy-equals-full contract" do
      test "rendered run reference copies the full value, not the truncated text", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        run =
          %RetentionRun{}
          |> RetentionRun.changeset(%{
            status: "completed",
            deleted_count: 7,
            duration_ms: 100,
            started_at: DateTime.add(now, -5, :second),
            completed_at: now
          })
          |> Threadline.Test.Repo.insert!()

        {:ok, _view, html} = live(conn, "/audit/policy/retention")

        full = "retention_run/#{run.id}"

        assert_copy_equals_full(html, full: full)
        refute_copy_truncated(html, full: full)
      end
    end
  end
end
