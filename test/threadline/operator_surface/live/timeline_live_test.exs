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

  defmodule Threadline.OperatorSurface.TimelineLiveTest.ActorRouter do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    alias Threadline.Semantics.ActorRef

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)
      plug(:put_test_actor)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.TimelineLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_actor",
        actor_fn: &__MODULE__.actor_fn/1,
        authorize_fn: &__MODULE__.auth/1
      )
    end

    def put_test_actor(conn, _opts) do
      Plug.Conn.assign(conn, :current_user, %{id: "actor-1", role: :admin})
    end

    def actor_fn(conn) do
      case conn.assigns[:current_user] do
        %{id: id} -> %ActorRef{type: :user, id: to_string(id)}
        _ -> nil
      end
    end

    def auth(_socket), do: :ok
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
    import Ecto.Query
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
        authorize_fn: &__MODULE__.auth/1,
        scope_query_fn: &__MODULE__.scope_operator_query/3
      )
    end

    def auth(_socket), do: {:ok, %{source: "support", user_id: "op1"}}

    def scope_operator_query(query, %{source: source}, %{surface: :timeline}) do
      where(query, [_ac, at], at.source == ^source)
    end

    def scope_operator_query(query, _scope, _context), do: query
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.SupportScopedRouter do
    use Phoenix.Router
    import Ecto.Query
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

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_support",
        authorize_fn: &__MODULE__.auth/1,
        export_authorize_fn: &__MODULE__.export_auth/1,
        scope_query_fn: &__MODULE__.scope_operator_query/3
      )
    end

    def auth(_socket), do: {:ok, %{access: :support_read_only, organization_id: "org_123"}}
    def export_auth(_mirror), do: {:error, :unauthorized}

    def scope_operator_query(query, %{organization_id: org_id}, %{surface: :timeline}) do
      where(query, [_ac, at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
    end

    def scope_operator_query(query, _scope, _context), do: query
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

  defmodule Threadline.OperatorSurface.TimelineLiveTest.SupportScopedEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_support_scoped_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TimelineLiveTest.SupportScopedRouter)
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.ActorEndpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_actor_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TimelineLiveTest.ActorRouter)
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.FailingQueueAdapter do
    @behaviour Threadline.ExportQueue

    @impl true
    def init(_opts), do: :ok

    @impl true
    def enqueue(_job_id, _opts \\ []), do: {:error, :supervisor_not_started}
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.SuccessfulQueueAdapter do
    @behaviour Threadline.ExportQueue

    @impl true
    def init(_opts), do: :ok

    @impl true
    def enqueue(_job_id, _opts \\ []), do: :ok
  end

  defmodule Threadline.OperatorSurface.Live.TimelineLiveTest do
    use ExUnit.Case, async: false
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

      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.TimelineLiveTest.SupportScopedEndpoint,
        secret_key_base: "z" |> String.duplicate(64),
        live_view: [signing_salt: "z" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TimelineLiveTest.Layouts]
      )

      start_supervised!(Threadline.OperatorSurface.TimelineLiveTest.SupportScopedEndpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(Threadline.Governance.SavedView)
      Threadline.Test.Repo.delete_all(Threadline.Governance.ExportJob)
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    # -------------------------------------------------------------------
    # Helpers
    # -------------------------------------------------------------------

    # Mount /audit, transparently following the default-window canonicalization
    # push_patch the LV emits when params == %{} (BROWSE-01 default-24h contract).
    defp mount_audit(conn, path \\ "/audit/timeline") do
      case live(conn, path) do
        {:ok, _lv, _html} = ok -> ok
        {:error, {:live_redirect, %{to: redirect_path}}} -> live(conn, redirect_path)
      end
    end

    defp seed_change!(opts) do
      repo = Threadline.Test.Repo
      occurred_at = Keyword.get(opts, :occurred_at, DateTime.utc_now())
      actor_ref = Keyword.get(opts, :actor_ref, %{"type" => "user", "id" => "u1"})
      correlation_id = Keyword.get(opts, :correlation_id)

      action =
        if correlation_id do
          repo.insert!(
            Threadline.Semantics.AuditAction.changeset(%{
              name: "timeline.test",
              actor_ref: actor_ref,
              status: "ok",
              correlation_id: correlation_id
            })
          )
        end

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: occurred_at,
            actor_ref: actor_ref,
            source: Keyword.get(opts, :source, "support"),
            action_id: action && action.id
          })
        )

      repo.insert!(
        Threadline.Capture.AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: Keyword.get(opts, :table, "posts"),
          table_pk: %{"id" => "1"},
          op: Keyword.get(opts, :op, "insert"),
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

    # Bulk seed via Repo.insert_all/3 — much faster than 5_001+ individual seed_change!/1
    # calls. Pattern source: RESEARCH §P-10 lines 1004-1033. Uses a unique table name so
    # the inserted rows do NOT pollute other tests' filter windows.
    defp bulk_seed_changes!(n, opts) when n > 0 and is_list(opts) do
      repo = Threadline.Test.Repo
      table = Keyword.fetch!(opts, :table)

      txn =
        repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
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

      # Insert in batches of 1_000 to stay under PG's bind-parameter limit.
      changes
      |> Enum.chunk_every(1_000)
      |> Enum.each(fn chunk -> repo.insert_all(Threadline.Capture.AuditChange, chunk) end)
    end

    # -------------------------------------------------------------------
    # Case 1 — default_window
    # -------------------------------------------------------------------

    test "Case 1: First mount with no params defaults to last-24h window in URL", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: redirect_path}}} = live(conn, "/audit/timeline")
      # URL was replace-patched to include from/to (24h default)
      assert redirect_path =~ ~r{^/audit/timeline\?from=.+&to=.+$}

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
               ~r{/audit/timeline\?from=2026-05-01T00%3A00&to=2026-05-06T23%3A59&table=posts&actor_kind=user&actor_id=42&correlation_id=req_abc123}

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

      assert {:ok, _lv, html} = live(conn, "/audit/timeline?from=#{from}&to=#{to}&table=posts")
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

    test "F-404: anonymous actor kind explains why actor id is disabled", %{conn: conn} do
      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?actor_kind=anonymous&actor_id=ignored")

      assert html =~ ~s|id="filter-actor-id"|
      assert html =~ ~s|disabled|
      assert html =~ "n/a for anonymous"
    end

    # -------------------------------------------------------------------
    # Case 5 — correlation_id_too_long
    # -------------------------------------------------------------------

    test "Case 5: correlation id >256 bytes triggers form error", %{conn: conn} do
      long_id = String.duplicate("a", 257)
      assert {:ok, _lv, html} = live(conn, "/audit/timeline?correlation_id=#{long_id}")
      assert html =~ "Timeline filters could not be applied. Fix the highlighted value, then apply filters again."
      assert html =~ "256 UTF-8 bytes"
    end

    # -------------------------------------------------------------------
    # Case 6 — datetime_normalization
    # -------------------------------------------------------------------

    test "Case 6: 16-char datetime-local pads to :00Z and parses as UTC", %{conn: conn} do
      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?from=2026-05-01T00:00&to=2026-05-06T23:59")

      # No error alert rendered (means the lib accepted the parsed DateTime)
      refute html =~ ~s|class="tl-alert tl-alert--error"|
    end

    # -------------------------------------------------------------------
    # Case 7 — unknown_table_hint
    # -------------------------------------------------------------------

    test "Case 7: Unknown table renders the known-tables hint", %{conn: conn} do
      assert {:ok, _lv, html} = live(conn, "/audit/timeline?table=does_not_exist_xyz")
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

      assert {:ok, _lv, html} = live(conn, "/audit/timeline?from=#{from}&to=#{to}")
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
                 "/audit/timeline?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts&actor_kind=user&actor_id=42&correlation_id=req_abc"
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
               live(conn, "/audit/timeline?from=2026-05-01T00:00&to=2026-05-06T23:59&foo=bar")

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

      # Guard: no *second* patch follows. Use a window wide enough that a stray
      # late patch on a loaded CI runner is reliably caught (50ms was too short
      # to be a meaningful negative assertion).
      refute_receive {:phoenix, :patch, _}, 300
    end

    # -------------------------------------------------------------------
    # Case 14 — history_round_trip (BROWSE-03 — back-button equivalent)
    # -------------------------------------------------------------------
    # Browser back-button == GET to a previously-visited URL. In a connected LV,
    # that is `render_patch(lv, prior_url)` — same path the browser would take
    # when popping its history stack and re-issuing the prior URL.
    #
    # Test: A → B → re-patch to A → assert form fields + URL state restored.

    test "Case 14: Re-patching to a prior URL restores prior filter state (back-button equivalent)",
         %{conn: conn} do
      # Mount with filter A (table=posts).
      {:ok, lv, html_a} = live(conn, "/audit/timeline?table=posts")
      assert html_a =~ ~s(value="posts")

      # Apply filter B (table=users) via form submit — adds a history entry.
      lv
      |> form("#timeline-filters",
        filter: %{
          from: "",
          to: "",
          table: "users",
          actor_kind: "",
          actor_id: "",
          correlation_id: ""
        }
      )
      |> render_submit()

      patched_b = assert_patch(lv)
      assert patched_b =~ "table=users"

      # Simulate browser back to filter A by patching to A's URL.
      html_after_back = render_patch(lv, "/audit/timeline?table=posts")

      # Form repopulates with filter A; B's value is gone.
      assert html_after_back =~ ~s(value="posts")
      refute html_after_back =~ ~s(value="users")

      # Result set re-queried with filter A (no error rendered).
      refute html_after_back =~ ~s|class="tl-alert tl-alert--error"|
    end

    # -------------------------------------------------------------------
    # Case 15 — three download anchors render (EXPO-03)
    # Plan-supplied numbering 12-15; renumbered to 15-18 because Cases 12,
    # 13, 14 are already taken by Phase 64's BROWSE tests in this file.
    # -------------------------------------------------------------------

    test "Case 15: Three download anchors render with canonical hrefs reflecting current filter state",
         %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, "/audit/timeline?from=2026-05-01T00:00&to=2026-05-06T23:59&table=posts")

      # All three compact labels present (D-22, Plan 04 doc-contract pinned)
      assert html =~ ">CSV<"
      assert html =~ ">JSON<"
      assert html =~ ">NDJSON<"

      # All three hrefs include the canonical filter querystring; HEEx
      # escapes & to &amp; in attribute values, so match the prefix only.
      assert html =~ ~s|href="/audit/exports/changes.csv?|
      assert html =~ ~s|href="/audit/exports/changes.json?|
      assert html =~ ~s|href="/audit/exports/changes.ndjson?|

      # Filter params present in the canonicalized querystring
      assert html =~ "from=2026-05-01T00%3A00"
      assert html =~ "table=posts"

      # `download` attribute present on each anchor (PR #2611 — keeps LV
      # socket alive on click). Match label content (handles whitespace
      # between attributes).
      download_anchors =
        Regex.scan(~r{<a [^>]*\bdownload\b[^>]*>\s*(CSV|JSON|NDJSON)\s*</a>}s, html)

      assert length(download_anchors) == 3
    end

    test "EF3: filtered Timeline carries allowed context to Exports", %{conn: conn} do
      {:ok, _lv, html} =
        live(
          conn,
          "/audit/timeline?from=2026-05-01T00:00&to=2026-05-06T23:59&table=ticket_replies&correlation_id=req_ef3"
        )

      assert html =~ "Carry to Exports"
      assert html =~ ~s|data-earned-flow="EF3"|
      assert html =~ ~s|data-persona="P3"|
      assert html =~ ~s|data-jtbd="J6"|
      assert html =~ ~s|href="/audit/exports?|
      assert html =~ "from=2026-05-01T00%3A00"
      assert html =~ "to=2026-05-06T23%3A59"
      assert html =~ "table=ticket_replies"
      assert html =~ "correlation_id=req_ef3"
      refute html =~ "subject_ref_json"
    end

    # -------------------------------------------------------------------
    # Case 16 — match-count status line renders (EXPO-04 / D-17)
    # -------------------------------------------------------------------

    test "Case 16: Match-count status line renders with the visible/total count format",
         %{conn: conn} do
      table = "posts_count_status_#{System.unique_integer([:positive])}"
      for _ <- 1..7, do: seed_change!(table: table)

      {:ok, _lv, html} =
        live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2099-01-01T00:00&table=#{table}")

      # The status line uses the compact operator format.
      assert html =~ ~r/\d+ shown · 7 matches · current filter window/
      # Wrapper class is present for the doc-contract test
      assert html =~ "tl-status"
    end

    # -------------------------------------------------------------------
    # Case 17 — informational truncation banner at counts in (5_000, 10_001)
    # (EXPO-04 / D-18 band 1)
    # -------------------------------------------------------------------

    @tag :slow
    test "Case 17: Informational truncation banner renders when count > 5,000 and < 10,001",
         %{conn: conn} do
      table = "bulk_band_info_#{System.unique_integer([:positive])}"
      bulk_seed_changes!(5_001, table: table)

      {:ok, _lv, html} =
        live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2099-01-01T00:00&table=#{table}")

      assert html =~ "Large export — will stream in chunks."
      refute html =~ "Truncated to first 10,000 rows"
      assert html =~ "tl-alert--info"
    end

    # -------------------------------------------------------------------
    # Case 18 — warning truncation banner at counts >= 10_001
    # (EXPO-04 / D-18 band 2; "10,000+" approximation in count line)
    # -------------------------------------------------------------------

    @tag :slow
    test "Case 18: Warning truncation banner renders at counts >= 10,001 with '10,000+' approximation",
         %{conn: conn} do
      table = "bulk_band_warn_#{System.unique_integer([:positive])}"
      # Seed exactly the cap value so count_matching's :cap clamps at 10_001.
      bulk_seed_changes!(10_001, table: table)

      {:ok, _lv, html} =
        live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2099-01-01T00:00&table=#{table}")

      assert html =~ "Truncated to first 10,000 rows"
      # Status line shows the cap approximation (not the literal integer).
      assert html =~ "10,000+"
      assert html =~ "tl-alert--warning"
      # Bands are mutually exclusive — band 1 must NOT render at the cap.
      refute html =~ "Large export — will stream in chunks."
    end

    test "F-401: empty Timeline uses locked recovery copy", %{conn: conn} do
      table = "empty_timeline_#{System.unique_integer([:positive])}"

      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2020-01-02T00:00&table=#{table}")

      assert html =~ "No captured changes match this window"

      assert html =~
               "Widen the time range, or clear the table filter to search every audited table. Scoped views only show records you are authorized to see."
    end

    test "F-402: future-window empty state explains data exists outside the selected window",
         %{conn: conn} do
      table = "future_window_#{System.unique_integer([:positive])}"
      seed_change!(table: table, occurred_at: DateTime.utc_now() |> DateTime.add(-60, :second))

      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?from=2099-01-01T00:00&to=2099-01-02T00:00&table=#{table}")

      assert html =~ "No captured changes in this time window"

      assert html =~
               "This window has no matching changes, but Threadline has audit data outside it. Move the window back toward recent activity or clear filters."
    end

    test "F-401: scoped empty state keeps authorized-record caveat", %{conn: conn} do
      table = "scoped_empty_#{System.unique_integer([:positive])}"

      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2020-01-02T00:00&table=#{table}")

      assert html =~ "Scoped views only show records you are authorized to see."
    end

    test "F-403: dense Timeline renders filter summary and rows before demoted journey legend",
         %{conn: conn} do
      table = "dense_order_#{System.unique_integer([:positive])}"
      seed_change!(table: table)

      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2099-01-01T00:00&table=#{table}")

      assert html =~ ~s|class="tl-filter-summary"|
      assert html =~ ~s|data-testid="timeline-row"|
      assert html =~ ~s|class="tl-journey--legend"|

      assert :binary.match(html, ~s|class="tl-filter-summary"|) != :nomatch
      {row_index, _} = :binary.match(html, ~s|data-testid="timeline-row"|)
      {legend_index, _} = :binary.match(html, ~s|class="tl-journey--legend"|)
      assert row_index < legend_index

      refute html =~ ~r/tl-card[^"]*[^>]*>\s*(FIND|EXPLAIN|PACKAGE)/i
    end

    test "F-405: long table and correlation refs are middle-truncated with titles and copy",
         %{conn: conn} do
      table = "threadline_extremely_long_schema_table_name_for_mobile_pressure_checks"
      correlation_id = "corr_" <> String.duplicate("abcdef1234567890", 8)
      seed_change!(table: table, correlation_id: correlation_id)

      assert {:ok, _lv, html} =
               live(conn, "/audit/timeline?from=2020-01-01T00:00&to=2099-01-01T00:00&table=#{table}")

      table_ref = Threadline.OperatorSurface.Presentation.secondary_ref(table, 30)
      correlation_ref = Threadline.OperatorSurface.Presentation.secondary_ref(correlation_id, 34)

      assert html =~ ~s|title="#{table}"|
      assert html =~ table_ref.visible
      assert html =~ ~s|title="#{correlation_id}"|
      assert html =~ correlation_ref.visible
      assert html =~ ~s|data-tl-copy="#{correlation_id}"|
      assert html =~ ~s|aria-label="Copy correlation id"|
    end

    test "standard mount without actor_fn does not expose actor-owned saved views", %{conn: conn} do
      {:ok, _lv, html} = mount_audit(conn, "/audit/timeline?table=posts")

      refute html =~ "save-view-form"
      refute html =~ "Saved Views:"
    end

    # -------------------------------------------------------------------
    # surface header (Phase 66)
    # -------------------------------------------------------------------

    describe "surface header (Phase 66)" do
      test "does not render the surface badge linking to /audit/coverage when coverage is disabled",
           %{
             conn: conn
           } do
        {:ok, _view, html} = mount_audit(conn)

        assert html =~ ~s|class="tl-topbar"|
        refute html =~ ~s|href="/audit/coverage"|
      end

      test "datalist excludes uncovered and expected_uncovered tuple variants", %{conn: conn} do
        # Pitfall 10 regression — Phase 66's additive third tuple variant
        # (`:expected_uncovered`) MUST NOT leak through TimelineLive's existing
        # datalist consumer. The datalist must contain ONLY `:covered` table
        # names. The mount/3 helper at timeline_live.ex:30-35 pattern-matches
        # `{:covered, name} -> [name]; _ -> []`, which is the contract this
        # test guards against future relaxation.
        #
        # Test environment fixtures (verified via Threadline.Health.trigger_coverage/1):
        #   - {:covered,             "threadline_ci_coverage_canary"}  # has Threadline trigger
        #   - {:uncovered,           "threadline_verify_cov_uncovered"} # no trigger, not baseline
        #   - {:expected_uncovered,  "schema_migrations"}               # baseline tuple
        #
        # The datalist must contain `threadline_ci_coverage_canary` (covered)
        # AND must NOT contain `threadline_verify_cov_uncovered` (uncovered)
        # AND must NOT contain `schema_migrations` (expected_uncovered).

        {:ok, _view, html} = mount_audit(conn)

        # Positive: at least one covered table appears in the datalist.
        assert html =~
                 ~r/<datalist[^>]*id="audited-tables"[^>]*>.*?<option value="threadline_ci_coverage_canary".*?<\/datalist>/s

        # Pitfall 10 negative assertions — the datalist MUST NOT include the
        # `:uncovered` table OR the `:expected_uncovered` baseline name.
        # These regexes scope the negative assertion to the datalist region
        # so the literals can legitimately appear elsewhere (e.g. in surface
        # header counts or in error copy) without false-positive failure.
        refute html =~
                 ~r/<datalist[^>]*id="audited-tables"[^>]*>.*?<option value="threadline_verify_cov_uncovered".*?<\/datalist>/s

        refute html =~
                 ~r/<datalist[^>]*id="audited-tables"[^>]*>.*?<option value="schema_migrations".*?<\/datalist>/s
      end
    end
  end

  defmodule Threadline.OperatorSurface.Live.TimelineLiveActorBackedTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.TimelineLiveTest.ActorEndpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.TimelineLiveTest.ActorEndpoint,
        secret_key_base: "z" |> String.duplicate(64),
        live_view: [signing_salt: "z" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TimelineLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(Threadline.Governance.SavedView)
      Threadline.Test.Repo.delete_all(Threadline.Governance.ExportJob)
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    defp mount_actor_audit(conn, path) do
      case live(conn, path) do
        {:ok, _lv, _html} = ok -> ok
        {:error, {:live_redirect, %{to: redirect_path}}} -> live(conn, redirect_path)
      end
    end

    test "default actor_fn mount path exposes actor-owned saved views", %{conn: conn} do
      {:ok, lv, _html} = mount_actor_audit(conn, "/audit_actor/timeline?table=posts")

      assert render(lv) =~ "Save View"

      lv
      |> form("#save-view-form", %{name: "Actor View"})
      |> render_submit()

      assert render(lv) =~ "Actor View"

      view =
        Threadline.Test.Repo.get_by!(Threadline.Governance.SavedView,
          name: "Actor View"
        )

      assert view.name == "Actor View"
      assert view.filters["table"] == "posts"
      assert view.actor_ref == %Threadline.Semantics.ActorRef{type: :user, id: "actor-1"}
    end
  end

  # -------------------------------------------------------------------
  # Case 10 — scope_thread (BROWSE-01 — divergence-from-analogs guard)
  # Separate ExUnit module so @endpoint can point to the scoped endpoint
  # that mounts the surface with authorize_fn returning {:ok, %{tenant: "t1"}}.
  # -------------------------------------------------------------------

  defmodule Threadline.OperatorSurface.Live.TimelineLiveScopedTest do
    use ExUnit.Case, async: false
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
      Threadline.Test.Repo.delete_all(Threadline.Governance.SavedView)
      Threadline.Test.Repo.delete_all(Threadline.Governance.ExportJob)
      {:ok, conn: Phoenix.ConnTest.build_conn()}
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
            actor_ref: actor_ref,
            source: Keyword.get(opts, :source, "support")
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

    test "Case 10: Scoped mount only renders rows allowed by scope_query_fn", %{conn: conn} do
      occurred_at = DateTime.utc_now() |> DateTime.add(-60, :second)
      seed_change!(table: "support_posts", source: "support", occurred_at: occurred_at)
      seed_change!(table: "admin_posts", source: "admin", occurred_at: occurred_at)

      {:ok, _lv, html} =
        case live(conn, "/audit_scoped/timeline?table=support_posts") do
          {:ok, _, _} = ok -> ok
          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
        end

      assert html =~ "support_posts"
      refute html =~ "admin_posts"
    end

    test "Case 11: Operator can save, apply, and delete a view", %{conn: conn} do
      {:ok, lv, _html} =
        case live(conn, "/audit_scoped/timeline?table=support_posts") do
          {:ok, _, _} = ok -> ok
          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
        end

      # Submit the save form
      lv
      |> form("#save-view-form", %{name: "My Support View"})
      |> render_submit()

      # View appears in the list
      assert render(lv) =~ "My Support View"

      # Apply view
      # Since we don't have a specific ID, let's pull it from the DB
      view =
        Threadline.Test.Repo.get_by!(Threadline.Governance.SavedView,
          name: "My Support View"
        )

      assert view.name == "My Support View"
      assert view.filters["table"] == "support_posts"

      # Click apply
      lv |> element("button[phx-click=\"apply-view\"]") |> render_click()

      # Ensure it's active
      assert render(lv) =~ "support_posts"

      # Click delete
      lv |> element("button[phx-click=\"delete-view\"]") |> render_click()

      # Ensure it's deleted
      refute render(lv) =~ "My Support View"
      refute Threadline.Test.Repo.get_by(Threadline.Governance.SavedView, name: "My Support View")
    end

    test "Case 12: Request Background Export enqueues job and redirects", %{conn: conn} do
      original_adapter = Application.get_env(:threadline, :export_queue_adapter)

      Application.put_env(
        :threadline,
        :export_queue_adapter,
        Threadline.OperatorSurface.TimelineLiveTest.SuccessfulQueueAdapter
      )

      on_exit(fn ->
        if original_adapter do
          Application.put_env(:threadline, :export_queue_adapter, original_adapter)
        else
          Application.delete_env(:threadline, :export_queue_adapter)
        end
      end)

      {:ok, lv, _html} =
        case live(conn, "/audit_scoped/timeline?table=support_posts") do
          {:ok, _, _} = ok -> ok
          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
        end

      # Initial state
      initial_jobs = Threadline.Test.Repo.all(Threadline.Governance.ExportJob)

      # Click the export button
      lv |> element("button", "Queue export") |> render_click()

      # Assert redirected to /audit_scoped/exports
      assert_redirect(lv, "/audit_scoped/exports")

      # Job is inserted
      jobs = Threadline.Test.Repo.all(Threadline.Governance.ExportJob)
      assert length(jobs) == length(initial_jobs) + 1
      job = hd(jobs -- initial_jobs)
      assert job.status == "pending"
      assert job.query_params["table"] == "support_posts"
      assert job.actor_ref.type == :user
      # the user_id mapped to actor_ref
      assert job.actor_ref.id == "op1"
    end

    test "background export failure preserves the row and surfaces the error", %{conn: conn} do
      original_adapter = Application.get_env(:threadline, :export_queue_adapter)

      Application.put_env(
        :threadline,
        :export_queue_adapter,
        Threadline.OperatorSurface.TimelineLiveTest.FailingQueueAdapter
      )

      on_exit(fn ->
        if original_adapter do
          Application.put_env(:threadline, :export_queue_adapter, original_adapter)
        else
          Application.delete_env(:threadline, :export_queue_adapter)
        end
      end)

      {:ok, lv, _html} =
        case live(conn, "/audit_scoped/timeline?table=support_posts") do
          {:ok, _, _} = ok -> ok
          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
        end

      _html = lv |> element("button", "Queue export") |> render_click()

      [job] = Threadline.Test.Repo.all(Threadline.Governance.ExportJob)
      assert job.status == "failed"
      assert job.error_message =~ "built-in export runtime is unavailable"
      assert %DateTime{} = job.expires_at
      assert job.query_params["table"] == "support_posts"
      assert render(lv) =~ "Queue export"
      assert render(lv) =~ "support_posts"
    end
  end
end

if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLiveExportVisibilityTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.TimelineLiveTest.SupportScopedEndpoint

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: "z" |> String.duplicate(64),
        live_view: [signing_salt: "z" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.TimelineLiveTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    test "support-scoped mounts hide export affordances when export auth denies access" do
      conn = Phoenix.ConnTest.build_conn()

      {:ok, _lv, html} =
        case live(conn, "/audit_support/timeline?table=support_posts") do
          {:ok, _, _} = ok -> ok
          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
        end

      refute html =~ "Queue export"
      refute html =~ ">CSV<"
      refute html =~ ">JSON<"
      refute html =~ ">NDJSON<"
      refute html =~ "Carry to Exports"
    end
  end
end
