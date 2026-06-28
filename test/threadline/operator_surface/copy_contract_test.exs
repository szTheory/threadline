if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.CopyContractTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Copy contract</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end
  end

  defmodule Threadline.OperatorSurface.CopyContractTest.Auth do
    def authorize(_), do: true
  end

  defmodule Threadline.OperatorSurface.CopyContractTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Threadline.OperatorSurface.CopyContractTest.FakeTicketReply do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "ticket_replies" do
      field(:body, :string)
    end
  end

  defmodule Threadline.OperatorSurface.CopyContractTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.CopyContractTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        repo: Threadline.Test.Repo,
        schemas: %{
          "ticket_replies" => Threadline.OperatorSurface.CopyContractTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.CopyContractTest.FakeUser
        },
        coverage_authorize_fn: &Threadline.OperatorSurface.CopyContractTest.Auth.authorize/1,
        policy_authorize_fn: &Threadline.OperatorSurface.CopyContractTest.Auth.authorize/1,
        evidence_authorize_fn: &Threadline.OperatorSurface.CopyContractTest.Auth.authorize/1,
        export_authorize_fn: &Threadline.OperatorSurface.CopyContractTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.CopyContractTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_copy_contract_key",
      signing_salt: "copy-contract"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.CopyContractTest.Router)
  end

  defmodule Threadline.OperatorSurface.CopyContractTest do
    use Threadline.DataCase, async: false
    import Phoenix.Component
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Governance.{ExportJob, RetentionRun, SavedView}
    alias Threadline.OperatorSurface.Components.SurfaceHeader
    alias Threadline.OperatorSurface.Components.UnsupportedView
    alias Threadline.OperatorSurface.Unsupported
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.UI
    alias Threadline.Semantics.ActorRef

    @endpoint Threadline.OperatorSurface.CopyContractTest.Endpoint
    @coverage %{uncovered_count: 0, last_checked_at: ~U[2026-06-04 00:00:00Z]}
    @expected_shell_groups ["Investigate", "Audit readiness", "Evidence & exports"]
    @expected_home_jobs ["Find what changed", "Check audit readiness", "Use evidence and exports"]
    @allowed_evidence_verdict_terms ["Proven", "Inferred", "Unsupported"]
    @allowed_proof_contexts ["proof history"]
    @allowed_code_contexts ["code", "advanced details", "error details", "tooltips"]
    @camel_case_model_names ~w(AuditTransaction AuditChange AuditAction ActorRef)
    @title_case_state_leaks [
      "Invalid Actor Reference",
      "Action Denied",
      "Unsupported View",
      "Transaction Not Found"
    ]
    @long_correlation_id "corr_00000000-0000-4000-8000-000000000179-threadline-copy-contract"

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.CopyContractTest.Endpoint,
        secret_key_base: "c" |> String.duplicate(64),
        live_view: [signing_salt: "c" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.CopyContractTest.Layouts]
      )

      original_interval = Application.get_env(:threadline, :coverage_poll_ms)
      Application.put_env(:threadline, :coverage_poll_ms, 5_000)

      on_exit(fn ->
        if original_interval do
          Application.put_env(:threadline, :coverage_poll_ms, original_interval)
        else
          Application.delete_env(:threadline, :coverage_poll_ms)
        end
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Threadline.Test.Repo.delete_all(SavedView)
      Threadline.Test.Repo.delete_all(ExportJob)
      Threadline.Test.Repo.delete_all(RetentionRun)

      {:ok, actor_ref} = ActorRef.new(:user, "copy-contract-operator")

      conn =
        build_conn()
        |> Plug.Test.init_test_session(
          threadline_actor_ref: Jason.encode!(ActorRef.to_map(actor_ref))
        )

      {:ok, conn: conn}
    end

    test "shell nav exposes only the D-01 visible group labels" do
      html = render_shell()

      assert shell_group_labels(html) == @expected_shell_groups
      assert shell_theme_labels(html) == ["Theme"]
      assert html =~ ~s|href="/audit"|
      assert html =~ ~s|data-testid="operator-nav-overview"|
      assert html =~ ~s|data-testid="operator-nav-timeline"|
      assert html =~ ~s|data-testid="operator-nav-coverage"|
      assert html =~ ~s|data-testid="operator-nav-evidence"|
      assert html =~ ~s|data-testid="operator-nav-policy"|
      assert html =~ ~s|data-testid="operator-nav-retention"|
      assert html =~ ~s|data-testid="operator-nav-exports"|
    end

    test "Home job-card titles are the D-01 task-led labels", %{conn: conn} do
      html = render_home(conn)

      assert home_job_titles(html) == @expected_home_jobs
      assert html =~ ~s|href="/audit/timeline"|
      assert html =~ ~s|href="/audit/coverage"|
      assert html =~ ~s|href="/audit/evidence"|
      assert html =~ ~s|href="/audit/policy/redaction"|
      assert html =~ ~s|href="/audit/policy/retention"|
      assert html =~ ~s|href="/audit/exports"|
    end

    test "primary shell and Home copy avoid unsafe vocabulary while keeping allowed contexts documented",
         %{conn: conn} do
      text =
        [render_shell(), render_home(conn)]
        |> Enum.map(&visible_text/1)
        |> Enum.join("\n")

      assert @allowed_evidence_verdict_terms == ["Proven", "Inferred", "Unsupported"]
      assert @allowed_proof_contexts == ["proof history"]
      assert "advanced details" in @allowed_code_contexts

      refute text =~ "!"

      for leak <- @title_case_state_leaks do
        refute text =~ leak
      end

      for model <- @camel_case_model_names do
        refute text =~ model
      end

      refute text =~ ~r/\b(Prove|proofs?|Proof)\b/
    end

    test "copy affordances bind every visible short ref to the full forensic value" do
      assigns = %{value: @long_correlation_id}

      html =
        rendered_to_string(~H"""
        <UI.ref value={@value} kind="correlation" copy_label="Copy correlation id" />
        """)

      visible =
        Threadline.OperatorSurface.Presentation.ref(@long_correlation_id, kind: :correlation).visible

      copy_targets = extract_copy_targets(html)

      assert visible != @long_correlation_id
      assert html =~ visible
      assert copy_targets != []
      assert Enum.all?(copy_targets, &(&1 == @long_correlation_id))
      refute Enum.member?(copy_targets, visible)
    end

    test "shared unsupported descriptors use sentence-case unavailable and permission copy" do
      descriptor_expectations = [
        {:coverage_unavailable, "Coverage unavailable",
         "Coverage is unavailable in this support lane"},
        {:policy_redaction_unavailable, "Redaction policy unavailable",
         "Redaction policy status is unavailable in this support lane"},
        {:evidence_unavailable, "Evidence unavailable",
         "Evidence is unavailable in this support lane"},
        {:retention_unavailable, "Retention history unavailable",
         "Retention history is unavailable in this support lane"}
      ]

      for {key, title, body} <- descriptor_expectations do
        descriptor = Unsupported.descriptor(key)
        html = render_component(&UnsupportedView.unsupported_view/1, %{descriptor: descriptor})

        assert descriptor.title == title
        assert html =~ title
        assert html =~ body
        assert html =~ "This is not a permissions issue."
        refute html =~ "Unsupported View"
      end

      denied = Unsupported.export_denied_descriptor()
      denied_html = render_component(&UnsupportedView.unsupported_view/1, %{descriptor: denied})

      assert denied.title == "Export access needed"
      assert denied_html =~ "You do not have access to exports."
      assert denied_html =~ "export_authorize_fn"
      refute denied_html =~ "Action Denied"
    end

    test "presentation status labels keep evidence verdicts but use sentence-case fallback" do
      assert Presentation.status_label(:proven) == "Proven"
      assert Presentation.status_label(:inferred_posture) == "Inferred"
      assert Presentation.status_label(:unsupported) == "Unsupported"
      assert Presentation.status_label(:custom_review_state) == "Custom review state"
    end

    defp render_shell do
      render_component(&SurfaceHeader.surface_header/1, %{
        coverage: @coverage,
        base_path: "/audit",
        coverage_enabled: true,
        policy_enabled: true,
        evidence_enabled: true,
        exports_enabled: true,
        current: nil,
        scoped: true
      })
    end

    defp render_home(conn) do
      {:ok, _view, html} = live(conn, "/audit")
      html
    end

    defp shell_group_labels(html) do
      ~r/<section[^>]*class="[^"]*\btl-shell-nav__group\b(?![^"]*\btl-theme-picker\b)[^"]*"[^>]*>.*?<h2[^>]*class="[^"]*\btl-shell-nav__label\b[^"]*"[^>]*>(.*?)<\/h2>/s
      |> Regex.scan(html)
      |> Enum.map(fn [_, label] -> normalize_text(label) end)
    end

    defp shell_theme_labels(html) do
      ~r/<legend[^>]*class="[^"]*\btl-shell-nav__label\b[^"]*"[^>]*>(.*?)<\/legend>/s
      |> Regex.scan(html)
      |> Enum.map(fn [_, label] -> normalize_text(label) end)
    end

    defp home_job_titles(html) do
      ~r/<h2[^>]*class="[^"]*\btl-home__card-title\b[^"]*"[^>]*>(.*?)<\/h2>/s
      |> Regex.scan(html)
      |> Enum.map(fn [_, label] -> normalize_text(label) end)
    end

    defp visible_text(html) do
      html
      |> String.replace(~r/<script.*?<\/script>/s, " ")
      |> String.replace(~r/<style.*?<\/style>/s, " ")
      |> String.replace(~r/<[^>]+>/, " ")
      |> normalize_text()
    end

    defp normalize_text(value) do
      value
      |> html_unescape()
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    end

    defp extract_copy_targets(html) do
      Regex.scan(~r/data-tl-copy="([^"]*)"/, html)
      |> Enum.map(fn [_, value] -> html_unescape(value) end)
    end

    defp html_unescape(value) do
      value
      |> String.replace("&amp;", "&")
      |> String.replace("&lt;", "<")
      |> String.replace("&gt;", ">")
      |> String.replace("&quot;", "\"")
      |> String.replace("&#39;", "'")
    end
  end
end
