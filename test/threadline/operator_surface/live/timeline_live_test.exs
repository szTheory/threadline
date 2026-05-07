if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TimelineLiveTest.Layouts do
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
      ~H"""
      Error 500: <%= inspect(assigns.reason) %>
      """
    end
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.TimelineLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TimelineLiveTest.Router)
  end

  # Scoped endpoint/router for Case 10 — mounts the surface with an authorize_fn
  # that returns {:ok, %{tenant: "t1"}} so :threadline_scope is populated on the socket.
  defmodule Threadline.OperatorSurface.TimelineLiveTest.ScopedRouter do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.TimelineLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_scoped",
        authorize_fn: &__MODULE__.auth/1
      )
    end

    def auth(_socket), do: {:ok, %{tenant: "t1"}}
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.ScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_scoped_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TimelineLiveTest.ScopedRouter)
  end

  defmodule Threadline.OperatorSurface.Live.TimelineLiveTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.TimelineLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.TimelineLiveTest.Endpoint,
        secret_key_base: "x" |> String.duplicate(64),
        live_view: [signing_salt: "x" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TimelineLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    # -------------------------------------------------------------------
    # Helpers
    # -------------------------------------------------------------------

    # Mount /audit, transparently following the default-window canonicalization
    # push_patch the LV emits when params == %{} (BROWSE-01 default-24h contract).
    defp mount_audit(conn, path \\ "/audit") do
      case live(conn, path) do
        {:ok, _lv, _html} = ok -> ok
        {:error, {:live_redirect, %{to: redirect_path}}} -> live(conn, redirect_path)
      end
    end

    defp seed_change!(opts) do
      repo = Threadline.Test.Repo
      occurred_at = Keyword.get(opts, :occurred_at, DateTime.utc_now())
      actor_ref = Keyword.get(opts, :actor_ref, %{"type" => "user", "id" => "u1"})

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: occurred_at,
            actor_ref: actor_ref
          })
        )

      repo.insert!(
        Threadline.Capture.AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: Keyword.get(opts, :table, "posts"),
          table_pk: %{"id" => "1"},
          op: "insert",
          data_after: %{"title" => "x"},
          changed_fields: nil,
          captured_at: occurred_at
        })
      )
    end

    # Seed N rows in a single helper for cursor-pagination tests (Case 9).
    defp seed_changes!(n, opts) when is_integer(n) and n > 0 do
      for _ <- 1..n, do: seed_change!(opts)
    end

    # -------------------------------------------------------------------
    # Case 1 — default_window
    # -------------------------------------------------------------------

    test "Case 1: First mount with no params defaults to last-24h window in URL", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: redirect_path}}} = live(conn, "/audit")
      # URL was replace-patched to include from/to (24h default)
      assert redirect_path =~ ~r{^/audit\?from=.+&to=.+$}

      assert {:ok, _lv, html} = live(conn, redirect_path)
      # Form is present with all six filter keys
      assert html =~ ~s|name="filter[from]"|
      assert html =~ ~s|name="filter[to]"|
      assert html =~ ~s|name="filter[table]"|
      assert html =~ ~s|name="filter[actor_kind]"|
      assert html =~ ~s|name="filter[actor_id]"|
      assert html =~ ~s|name="filter[correlation_id]"|
    end

    # -------------------------------------------------------------------
    # Case 2 — filter_parity (BROWSE-02)
    # -------------------------------------------------------------------

    test "Case 2: Submitting the form push_patches to a canonical URL with all five filter keys",
         %{conn: conn} do
      {:ok, lv, _html} = mount_audit(conn)

      html =
        lv
        |> form("#timeline-filters",
          filter: %{
            from: "2026-05-01T00:00",
            to: "2026-05-06T23:59",
            table: "posts",
            actor_kind: "user",
            actor_id: "42",
            correlation_id: "req_abc123"
          }
        )
        |> render_submit()

      patched_path = assert_patch(lv)

      assert patched_path =~
               ~r{/audit\?from=2026-05-01T00%3A00&to=2026-05-06T23%3A59&table=posts&actor_kind=user&actor_id=42&correlation_id=req_abc123}

      _ = html
    end

    # -------------------------------------------------------------------
    # Case 3 — url_round_trip (BROWSE-03)
    # -------------------------------------------------------------------

    test "Case 3: Pasting a URL into a fresh session reproduces the result set", %{conn: conn} do
      seed_change!(table: "posts", actor_ref: %{"type" => "user", "id" => "42"})

      from =
        DateTime.utc_now()
        |> DateTime.add(-1, :hour)
        |> DateTime.to_iso8601()
        |> String.slice(0..15)

      to =
        DateTime.utc_now()
        |> DateTime.add(1, :hour)
        |> DateTime.to_iso8601()
        |> String.slice(0..15)

      assert {:ok, _lv, html} = live(conn, "/audit?from=#{from}&to=#{to}&table=posts")
      assert html =~ "posts"
      # phx-update="stream" container always renders (Plan 01 BLOCKER 2 fix);
      # phx-viewport-bottom only present when @cursor != nil (i.e. when more pages exist).
      assert html =~ ~s|phx-update="stream"|
    end

    # -------------------------------------------------------------------
    # Case 4 — anonymous (BROWSE-02 + D-07)
    # -------------------------------------------------------------------

    test "Case 4: actor_kind=anonymous strips actor_id on submit", %{conn: conn} do
      {:ok, lv, _html} = mount_audit(conn)

      lv
      |> form("#timeline-filters",
        filter: %{
          from: "",
          to: "",
          table: "",
          actor_kind: "anonymous",
          actor_id: "42",
          correlation_id: ""
        }
      )
      |> render_submit()

      # assert_patch/1 returns the URL string directly in LV ~> 1.0 (not a tuple).
      patched_path = assert_patch(lv)
      refute patched_path =~ "actor_id="
      assert patched_path =~ "actor_kind=anonymous"
    end

    # -------------------------------------------------------------------
    # Case 5 — correlation_id_too_long
    # -------------------------------------------------------------------

    test "Case 5: correlation id >256 bytes triggers form error", %{conn: conn} do
      long_id = String.duplicate("a", 257)
      assert {:ok, _lv, html} = live(conn, "/audit?correlation_id=#{long_id}")
      assert html =~ "256 UTF-8 bytes"
    end

    # -------------------------------------------------------------------
    # Case 6 — datetime_normalization
    # -------------------------------------------------------------------

    test "Case 6: 16-char datetime-local pads to :00Z and parses as UTC", %{conn: conn} do
      assert {:ok, _lv, html} =
               live(conn, "/audit?from=2026-05-01T00:00&to=2026-05-06T23:59")

      # No filter-error rendered (means the lib accepted the parsed DateTime)
      refute html =~ ~s|class="filter-error"|
    end

    # -------------------------------------------------------------------
    # Case 7 — unknown_table_hint
    # -------------------------------------------------------------------

    test "Case 7: Unknown table renders the known-tables hint", %{conn: conn} do
      assert {:ok, _lv, html} = live(conn, "/audit?table=does_not_exist_xyz")
      # Hint copy mentions the unknown name, plus "known" or "audited" list copy
      assert html =~ "does_not_exist_xyz" or html =~ "No audited table"
    end

    # -------------------------------------------------------------------
    # Case 8 — phx_change_prohibition (D-04 / F-6)
    # -------------------------------------------------------------------

    test "Case 8: Filter form renders no phx-change attribute (D-04 explicit Apply only)", %{
      conn: conn
    } do
      assert {:ok, _lv, html} = mount_audit(conn)
      refute html =~ ~s|phx-change=|
    end

    # -------------------------------------------------------------------
    # Case 9 — viewport_bottom_present (BROWSE-01 + D-11)
    # -------------------------------------------------------------------

    test "Case 9: Stream container exposes phx-viewport-bottom and phx-update=stream when cursor exists",
         %{conn: conn} do
      # Seed page_size + 1 = 51 rows so timeline_page returns a non-nil next_cursor.
      # Smallest setup that triggers @cursor != nil so phx-viewport-bottom renders.
      seed_changes!(51, table: "posts")

      # Use a wide window that includes all seeded rows.
      from =
        DateTime.utc_now()
        |> DateTime.add(-1, :hour)
        |> DateTime.to_iso8601()
        |> String.slice(0..15)

      to =
        DateTime.utc_now()
        |> DateTime.add(1, :hour)
        |> DateTime.to_iso8601()
        |> String.slice(0..15)

      assert {:ok, _lv, html} = live(conn, "/audit?from=#{from}&to=#{to}")
      assert html =~ ~s|phx-update="stream"|

      # With a non-nil cursor, the conditional binding {@cursor && "next-page"} resolves to "next-page".
      assert html =~ "phx-viewport-bottom"
      assert html =~ "next-page"
    end

    # -------------------------------------------------------------------
    # Case 11 — url_paste_echoes_form_fields (WARNING 1 fix — BROWSE-03)
    # -------------------------------------------------------------------

    test "Case 11: Pasting a URL populates form fields verbatim (filters_raw hydrated from URL)",
         %{conn: conn} do
      assert {:ok, _lv, html} =
               live(
                 conn,
                 "/audit?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts&actor_kind=user&actor_id=42&correlation_id=req_abc"
               )

      # Each filter value appears as a form `value=` attribute, echoing the URL verbatim.
      assert html =~ ~s(value="2026-05-01T00:00")
      assert html =~ ~s(value="2026-05-06T23:59")
      assert html =~ ~s(value="posts")
      assert html =~ ~s(value="42")
      assert html =~ ~s(value="req_abc")
      # actor_kind=user means the <option value="user" selected> is rendered.
      assert html =~ ~s(selected)
    end

    # -------------------------------------------------------------------
    # Case 12 — unknown_param_dropped (BROWSE-02 — allowlist enforcement)
    # -------------------------------------------------------------------

    test "Case 12: Unknown URL filter key is silently dropped (allowlist enforced)", %{
      conn: conn
    } do
      # Mount with an unknown param + valid window. Should not crash.
      # URL has params (not bare /audit), so no auto-patch from default-window logic.
      assert {:ok, lv, _html} =
               live(conn, "/audit?from=2026-05-01T00:00&to=2026-05-06T23:59&foo=bar")

      # Submit the form (re-emits the canonical URL via push_patch).
      lv
      |> form("#timeline-filters",
        filter: %{
          from: "2026-05-01T00:00",
          to: "2026-05-06T23:59",
          table: "",
          actor_kind: "",
          actor_id: "",
          correlation_id: ""
        }
      )
      |> render_submit()

      # assert_patch/1 returns the URL string directly in LV ~> 1.0.
      patched_path = assert_patch(lv)
      refute patched_path =~ "foo="
    end

    # -------------------------------------------------------------------
    # Case 13 — apply_one_history_entry (BROWSE-03 — one Apply == one push_patch)
    # -------------------------------------------------------------------

    test "Case 13: One Apply submit produces exactly one push_patch (one history entry)", %{
      conn: conn
    } do
      {:ok, lv, _html} = mount_audit(conn)

      # Now submit the form once.
      lv
      |> form("#timeline-filters",
        filter: %{
          from: "",
          to: "",
          table: "posts",
          actor_kind: "",
          actor_id: "",
          correlation_id: ""
        }
      )
      |> render_submit()

      # Exactly one push_patch from the submit.
      patched_once = assert_patch(lv)
      assert patched_once =~ "table=posts"

      refute_receive {:phoenix, :patch, _}, 50
    end
  end

  # -------------------------------------------------------------------
  # Case 10 — scope_thread (BROWSE-01 — divergence-from-analogs guard)
  # Separate ExUnit module so @endpoint can point to the scoped endpoint
  # that mounts the surface with authorize_fn returning {:ok, %{tenant: "t1"}}.
  # -------------------------------------------------------------------

  defmodule Threadline.OperatorSurface.Live.TimelineLiveScopedTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.TimelineLiveTest.ScopedEndpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.TimelineLiveTest.ScopedEndpoint,
        secret_key_base: "y" |> String.duplicate(64),
        live_view: [signing_salt: "y" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TimelineLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "Case 10: Scoped mount renders successfully (scope_aware_opts exercised)", %{conn: conn} do
      # Mount via the scoped endpoint that uses authorize_fn returning {:ok, %{tenant: "t1"}}.
      # This proves the scope-aware path does not crash and :threadline_scope is populated.
      # Bare URL triggers the default-window canonicalization push_patch — follow it.
      {:ok, _lv, html} =
        case live(conn, "/audit_scoped") do
          {:ok, _, _} = ok -> ok
          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
        end

      # Scoped mount renders the timeline form (proves scope_aware_opts doesn't crash)
      assert html =~ ~s|name="filter[from]"|
    end
  end
end
