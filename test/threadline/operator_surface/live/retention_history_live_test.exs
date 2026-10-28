if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Router do
    use Threadline.OperatorSurfaceTest.Router

    alias Threadline.OperatorSurface.RetentionHistoryLiveTest.Auth

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        actor_fn: &Auth.actor/1,
        policy_authorize_fn: &Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Auth do
    def actor(_conn), do: %Threadline.Semantics.ActorRef{type: :user, id: "operator-1"}
    def authorize(_mirror), do: Application.get_env(:threadline, :test_allow_policy, true)
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.FailingReadRepo do
    def all(_query, _opts), do: raise("private storage detail")
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest.Endpoint do
    use Threadline.OperatorSurfaceTest.Endpoint,
      router: Threadline.OperatorSurface.RetentionHistoryLiveTest.Router
  end

  defmodule Threadline.OperatorSurface.RetentionHistoryLiveTest do
    use Threadline.DataCase, async: false
    import Ecto.Query

    use Threadline.OperatorSurfaceCase,
      endpoint: Threadline.OperatorSurface.RetentionHistoryLiveTest.Endpoint

    import Threadline.OperatorSurface.RefCopyContract

    alias Threadline.Governance.RetentionRun
    alias Threadline.OperatorSurface.Live.RetentionHistoryLive
    alias Threadline.Retention.Pruner
    alias Threadline.Semantics.AuditAction

    @worker_supervisor Threadline.OperatorSurface.RetentionHistoryLiveTest.WorkerSupervisor
    @pruner_lock_key :erlang.phash2("threadline_retention_pruner")

    defp live_retention(conn) do
      {:ok, view, _initial_html} = live(conn, "/audit/policy/retention")
      {:ok, view, render(view)}
    end

    defp start_application_supervisor! do
      retention = Application.get_env(:threadline, :retention, [])

      opts =
        [repo: Threadline.Test.Repo]
        |> Keyword.merge(Keyword.take(retention, [:interval_ms, :sleep_ms]))

      start_supervised!({Task.Supervisor, name: @worker_supervisor})
      pruner = start_supervised!({Threadline.Retention.Pruner, opts})

      # Match Task.start's unlinked caller contract while giving ExUnit ownership
      # of workers that may still be purging when this test ends. The interval
      # is 24 h (setup), so no scheduled run can start before this seam is set.
      :sys.replace_state(pruner, fn state ->
        %{state | task_start: &Task.Supervisor.start_child(@worker_supervisor, &1)}
      end)

      pruner
    end

    setup_all do
      original_interval = Application.get_env(:threadline, :retention_poll_ms)
      Application.put_env(:threadline, :retention_poll_ms, 5_000)

      on_exit(fn ->
        if original_interval do
          Application.put_env(:threadline, :retention_poll_ms, original_interval)
        else
          Application.delete_env(:threadline, :retention_poll_ms)
        end
      end)

      start_endpoint!(@endpoint)
      Application.put_env(:threadline, :test_allow_policy, true)

      :ok
    end

    setup do
      stop_named_process!(Pruner)
      Repo.delete_all(RetentionRun, repo_opts())

      # on_exit runs after ExUnit has stopped the test-owned Pruner and its workers,
      # so a killed worker's queued or running run cannot outlive the test.
      on_exit(fn -> Repo.delete_all(RetentionRun, repo_opts()) end)

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

        {:ok, _view, html} = live_retention(conn)
        assert html =~ "Retention history unavailable"
        assert html =~ "Retention history is unavailable in this support lane"
        assert html =~ "This is not a permissions issue."
        assert html =~ "mix threadline.retention.purge --dry-run"
        refute html =~ "Prune now"
      end

      test "shows empty state when no runs exist", %{conn: conn} do
        {:ok, _view, html} = live_retention(conn)
        assert html =~ "Retention window"
        assert html =~ "No retention runs"

        assert html =~
                 "A run will appear here after a confirmed prune or scheduled retention operation."

        assert html =~ "configured Threadline storage schema"
        assert html =~ "Prune now"
        assert html =~ "tl-button--secondary"
        refute html =~ "tl-button--secondary tl-button--danger"

        # The destructive prune is now a server-enforced T3 type-to-confirm flow
        # (D-21): the client-only data-confirm is gone, and the modal form is
        # mounted only after the operator opens the destructive action.
        refute html =~ "data-confirm"
        refute html =~ "phx-submit=\"prune_now\""
      end

      test "a successful persisted read advances the mutation freshness marker", %{conn: conn} do
        {:ok, view, initial_html} = live_retention(conn)
        initial_revision = mutation_revision(initial_html)

        send(view.pid, :refresh)

        assert_eventually(fn ->
          revision = mutation_revision(render(view))
          is_binary(revision) and revision != initial_revision
        end)
      end

      test "a failed history read stays distinct from empty and offers refresh", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)

        :sys.replace_state(view.pid, fn state ->
          update_in(state.socket.assigns, fn assigns ->
            Map.put(assigns, :threadline_repo, FailingReadRepo)
          end)
        end)

        send(view.pid, :refresh)

        assert_eventually(fn ->
          html = render(view)

          html =~ "Retention history could not be loaded" and
            html =~ "Refresh retention history" and not (html =~ "No retention runs")
        end)
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
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        refute html =~ "No Retention History"
        assert html =~ "completed"
        assert html =~ "100"
        # Or formatted, depending on implementation
        assert html =~ "1500"
        assert html =~ "Latest completed run"
      end

      test "renders one focused retention window health summary without a duplicate trust rail",
           %{
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
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        assert html =~ ~s|aria-label="Retention window health"|
        assert html =~ "Latest run"
        assert html =~ "Latest completed run"
        assert html =~ "Rows deleted in recent runs"
        assert html =~ "Failures"
        # Density (196-06): the banner restatement of the destructive warning is gone;
        # the type-to-confirm modal owns that copy at the point of action.
        refute html =~ "Pruning permanently deletes older audit records by policy"
        refute html =~ "tl-trust-rail"
      end

      # Density (196-06): the success/warning status alerts and the "Retention window
      # destructive action" self-label were removed — the stat cards carry the health
      # signal (status + failure count with danger state) and the type-to-confirm modal
      # carries the destructive warning at the point of action.
      test "carries run health in the stat cards, not a status alert (healthy)", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "completed",
          deleted_count: 42,
          duration_ms: 500,
          started_at: DateTime.add(now, -5, :second),
          completed_at: now
        })
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        assert html =~ "Retention window health"
        assert html =~ "Failures"
        refute html =~ "retention window is healthy"
        refute html =~ "Latest run succeeded"
        refute html =~ "Review the latest status and failure count"
        refute html =~ "Retention window destructive action"
      end

      test "carries run health in the stat cards, not a status alert (failed run)", %{conn: conn} do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "failed",
          started_at: DateTime.add(now, -5, :second)
        })
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        assert html =~ ~s(data-status="danger")
        refute html =~ "Review the latest status and failure count"
        refute html =~ "Latest run succeeded"
        refute html =~ "Retention window destructive action"
      end

      test "shows partial deletion with a safe category and never renders raw failure detail", %{
        conn: conn
      } do
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        %RetentionRun{}
        |> RetentionRun.changeset(%{
          status: "failed",
          deleted_count: 1,
          duration_ms: 250,
          error_message: "injected database detail: secret host and query",
          started_at: DateTime.add(now, -5, :second),
          completed_at: now
        })
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        assert html =~
                 "Retention prune failed (prune error). 1 row was deleted before the failure."

        assert html =~
                 "Review this run and resolve the reported category before starting another prune."

        refute html =~ "secret host"
        refute html =~ "injected database detail"
      end

      test "Prune now CTA triggers the supervised runtime path", %{conn: conn} do
        {:ok, view, html} = live_retention(conn)

        # The CTA opens the T3 confirm modal; the actual prune is the type-to-confirm
        # form submission (server-enforced, D-21).
        assert html =~ "Prune now"

        # ensure no active runs initially
        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0
        assert Pruner.started?()

        # Type the canonical policy name and submit the server-enforced form.
        modal_html = open_prune_modal(view)
        assert modal_html =~ "configured Threadline storage schema"
        assert modal_html =~ "strictly older than the policy cutoff"
        assert modal_html =~ "current operator or tenant scope does not limit this prune"
        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: "default"})

        assert render(view) =~ "Prune request accepted. Follow its persisted status here."

        assert_eventually(fn ->
          Repo.aggregate(RetentionRun, :count, repo_opts()) > 0
        end)
      end

      test "locks destructive flow labels, consequence copy, and modal focus affordances", %{
        conn: conn
      } do
        {:ok, view, html} = live_retention(conn)

        assert html =~ "Retention window"
        assert html =~ "Prune now"

        modal_html = open_prune_modal(view)

        assert modal_html =~ "Prune retained audit data?"

        assert modal_html =~
                 "At execution, it removes AuditChange rows strictly older than the policy cutoff"

        assert modal_html =~ "This action cannot be undone."
        assert modal_html =~ "Type the policy name “<code>default</code>” to confirm"
        assert modal_html =~ "Keep audit data"
        assert modal_html =~ "Prune now"
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
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        assert occurrences(html, "Prune now") == 1
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
        |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        refute html =~ ~s(type="checkbox"),
               "no per-row/select-all checkbox over the destructive prune (D-19)"

        refute html =~ "select-all"
        refute html =~ "select_all"
      end

      test "mount, refresh, and termination keep exactly one owned timer", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)

        mounted_socket = :sys.get_state(view.pid).socket
        mounted_ref = mounted_socket.assigns.threadline_retention_timer_ref
        assert is_reference(mounted_ref)
        assert is_integer(Process.read_timer(mounted_ref))

        send(view.pid, :refresh)

        refreshed_socket = :sys.get_state(view.pid).socket
        refreshed_ref = refreshed_socket.assigns.threadline_retention_timer_ref
        assert is_reference(refreshed_ref)
        refute refreshed_ref == mounted_ref
        assert Process.read_timer(mounted_ref) == false
        assert is_integer(Process.read_timer(refreshed_ref))

        assert render(view) =~ "Prune now"

        assert :ok =
                 RetentionHistoryLive.terminate(
                   :normal,
                   refreshed_socket
                 )

        assert Process.read_timer(refreshed_ref) == false
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
          |> Repo.insert!(repo_opts())

        failed =
          %RetentionRun{}
          |> RetentionRun.changeset(%{
            status: "failed",
            started_at: DateTime.add(now, -10, :second)
          })
          |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        assert html =~ "Latest run"
        assert html =~ "Failed"
        assert html =~ "Latest completed run"
        assert html =~ Calendar.strftime(completed.completed_at, "%Y")
        assert html =~ ~s(href="#runs-#{failed.id}")
        assert html =~ "tl-target-row"
        assert html =~ "No rows deleted"
        assert html =~ "No duration yet"
      end

      test "source contract: retention reads and destructive audit use resolved storage opts" do
        source = File.read!("lib/threadline/operator_surface/live/retention_history_live.ex")

        assert source =~ "|> repo.all(storage_opts(socket))"
        assert source =~ "order_by: [desc: r.inserted_at]"
        assert source =~ "storage_schema: StorageSchema.get()"
      end

      test "shows configured-storage retention runs and ignores default-storage sentinels", %{
        conn: conn
      } do
        ensure_storage_schema!("audit")
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        with_storage_schema("audit", fn ->
          audit_run =
            %RetentionRun{}
            |> RetentionRun.changeset(%{
              status: "completed",
              deleted_count: 11,
              duration_ms: 120,
              started_at: DateTime.add(now, -5, :second),
              completed_at: now
            })
            |> Repo.insert!(repo_opts("audit"))

          threadline_run =
            %RetentionRun{}
            |> RetentionRun.changeset(%{
              status: "failed",
              deleted_count: 99,
              duration_ms: 900,
              started_at: DateTime.add(now, -1, :second),
              completed_at: now
            })
            |> Repo.insert!(repo_opts("threadline"))

          {:ok, _view, html} = live_retention(conn)

          assert html =~ "retention_run/#{audit_run.id}"
          refute html =~ "retention_run/#{threadline_run.id}"
        end)
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
        Repo.aggregate(AuditAction, :count, :id, repo_opts())
      end

      test "the canonical confirmation token is never shipped to the client", %{conn: conn} do
        {:ok, view, html} = live_retention(conn)

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

        assert modal_html =~ "Prune now"
      end

      test "a forged confirmation token fails closed and performs no prune", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)

        before = count_audit_actions()
        open_prune_modal(view)

        # An attacker-supplied wrong token must be rejected server-side
        # (secure_compare against the DB-canonical policy name).
        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: "not-the-policy-name"})

        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0,
               "a forged token must not trigger a prune"

        assert count_audit_actions() == before,
               "a forged token must not produce a prune nor an audited destructive action"
      end

      test "a forged confirmation token stays in the dialog with corrective feedback", %{
        conn: conn
      } do
        {:ok, view, _html} = live_retention(conn)

        open_prune_modal(view)

        html =
          render_submit(form(view, "form[phx-submit=prune_now]"), %{
            confirm: "not-the-policy-name"
          })

        assert html =~ "id=\"prune-confirm\""
        assert html =~ "The policy name did not match. Check the exact name and try again."
      end

      test "an empty confirmation stays in place and performs no prune", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)

        before_actions = count_audit_actions()
        open_prune_modal(view)

        html = render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: ""})

        assert html =~ "id=\"prune-confirm\""
        assert html =~ "required"
        assert html =~ "The policy name did not match. Check the exact name and try again."
        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0
        assert count_audit_actions() == before_actions
      end

      test "a forged phx-value scope fails closed", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)
        open_prune_modal(view)

        # phx-value-id is an untrusted client claim; a forged scope must be
        # re-checked + scope-filtered server-side and fail closed.
        render_submit(form(view, "form[phx-submit=prune_now]"), %{
          confirm: "forged",
          id: "00000000-0000-0000-0000-000000000000"
        })

        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0,
               "a forged scope must fail closed"
      end

      test "an active persisted run disables and rejects a repeated prune event", %{conn: conn} do
        now = DateTime.utc_now()
        run = Repo.insert!(%RetentionRun{status: "running", started_at: now}, repo_opts())

        {:ok, view, _html} = live_retention(conn)

        assert_eventually(fn -> render(view) =~ run.id end)
        render_click(view, "open_prune_modal", %{})
        assert has_element?(view, "button[data-tl-mutating][disabled]", "Prune now")

        before_actions = count_audit_actions()

        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: "default"})

        assert render(view) =~
                 "A retention prune is already in progress. Follow its persisted status here."

        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 1
        assert count_audit_actions() == before_actions
      end

      test "prune is refused when policy authorization is absent", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_policy, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_policy, true) end)

        # With authz absent the page renders the unsupported view and exposes no
        # prune affordance at all — the default path is refusal (fail closed).
        {:ok, _view, html} = live_retention(conn)
        refute html =~ "phx-submit=\"prune_now\""
        refute html =~ "Prune now"
      end

      test "event-time authorization revocation prevents audit and prune", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_policy, true)
        {:ok, view, _html} = live_retention(conn)

        before_actions = count_audit_actions()
        policy_name = view |> open_prune_modal() |> canonical_policy_name()

        Application.put_env(:threadline, :test_allow_policy, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_policy, true) end)

        html = render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: policy_name})

        assert html =~
                 "You are not authorized to start this retention prune. Refresh the history or contact your administrator."

        refute html =~ "policy name did not match"
        assert count_audit_actions() == before_actions
        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0
      end

      test "missing accountable actor prevents audit and prune", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)
        before_actions = count_audit_actions()
        policy_name = view |> open_prune_modal() |> canonical_policy_name()

        :sys.replace_state(view.pid, fn state ->
          update_in(state.socket.assigns, &Map.delete(&1, :threadline_actor_ref))
        end)

        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: policy_name})

        assert count_audit_actions() == before_actions
        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0
      end

      test "audit persistence failure prevents the prune and returns safe feedback", %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)
        before_actions = count_audit_actions()

        :sys.replace_state(view.pid, fn state ->
          update_in(state.socket.assigns, fn assigns ->
            Map.put(assigns, :threadline_actor_ref, %Threadline.Semantics.ActorRef{
              type: :user,
              id: ""
            })
          end)
        end)

        open_prune_modal(view)

        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: "default"})

        assert_eventually(fn ->
          render(view) =~ "Prune could not start because its audit record could not be saved."
        end)

        assert count_audit_actions() == before_actions
        assert Repo.aggregate(RetentionRun, :count, repo_opts()) == 0
      end

      test "a valid type-to-confirm prune records an AuditAction for the destructive action",
           %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)

        before = count_audit_actions()

        # The canonical policy name the operator must type (D-21). The handler
        # re-fetches this server-side; the test discovers it from the rendered
        # confirmation prompt rather than hardcoding a constant.
        policy_name = view |> open_prune_modal() |> canonical_policy_name()

        render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: policy_name})

        assert count_audit_actions() == before + 1,
               "an accepted prune request must be audited before the asynchronous backend starts"

        action =
          Repo.one!(
            from(a in AuditAction, order_by: [desc: a.inserted_at], limit: 1),
            repo_opts()
          )

        assert action.actor_ref == %Threadline.Semantics.ActorRef{
                 type: :user,
                 id: "operator-1"
               }

        assert_eventually(fn ->
          Repo.aggregate(RetentionRun, :count, repo_opts()) > 0
        end)

        assert count_audit_actions() == before + 1,
               "the backend run must not duplicate the operator-request audit action"
      end

      test "an accepted prune's worker is owned by this test and cannot outlive it",
           %{conn: conn} do
        {:ok, view, _html} = live_retention(conn)
        policy_name = view |> open_prune_modal() |> canonical_policy_name()

        # While the pruner's advisory lock is held here, the accepted worker
        # waits for it instead of purging, so its owner can be observed. A worker
        # that outlives this test runs the orphan sweep under a later test.
        with_advisory_lock_held(Repo, @pruner_lock_key, fn ->
          render_submit(form(view, "form[phx-submit=prune_now]"), %{confirm: policy_name})

          assert_eventually(fn -> Repo.aggregate(RetentionRun, :count, repo_opts()) > 0 end)

          assert_eventually(
            fn -> Task.Supervisor.children(@worker_supervisor) != [] end,
            message: "the accepted retention worker must belong to the test supervisor"
          )
        end)
      end

      defp canonical_policy_name(html) do
        case Regex.run(~r/type the policy name [`"]?([a-z0-9_-]+)[`"]?/i, html) do
          [_, name] -> name
          _ -> "default"
        end
      end

      defp open_prune_modal(view) do
        html = render_click(element(view, "button", "Prune now"))

        assert html =~ "Prune retained audit data?"
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
    # identifiers use `UI.Display.ref/1`, which binds `data-tl-copy={ref.full}`.
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
          |> Repo.insert!(repo_opts())

        {:ok, _view, html} = live_retention(conn)

        full = "retention_run/#{run.id}"

        assert_copy_equals_full(html, full: full)
        refute_copy_truncated(html, full: full)
      end
    end

    defp mutation_revision(html) do
      case Regex.run(~r/data-tl-mutation-revision="([^"]+)"/, html) do
        [_, revision] -> revision
        _ -> nil
      end
    end
  end
end
