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
    @transaction_live_path "lib/threadline/operator_surface/live/transaction_live.ex"
    @row_history_live_path "lib/threadline/operator_surface/live/row_history_live.ex"
    @row_history_component_path "lib/threadline/operator_surface/live/row_history_component.ex"
    @actor_live_path "lib/threadline/operator_surface/live/actor_live.ex"
    @evidence_live_path "lib/threadline/operator_surface/live/evidence_live.ex"
    @export_status_live_path "lib/threadline/operator_surface/live/export_status_live.ex"
    @policy_redaction_live_path "lib/threadline/operator_surface/live/policy_redaction_live.ex"
    @retention_live_path "lib/threadline/operator_surface/live/retention_history_live.ex"

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
      Threadline.Test.Repo.delete_all(SavedView, repo_opts())
      Threadline.Test.Repo.delete_all(ExportJob, repo_opts())
      Threadline.Test.Repo.delete_all(RetentionRun, repo_opts())

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

    test "primary Timeline copy keeps incident-pressure vocabulary calm and domain-specific",
         %{conn: conn} do
      seed_timeline_change!()
      text = conn |> render_timeline() |> visible_text()

      for expected <- [
            "Timeline",
            "Audit readiness",
            "Matching changes",
            "current result set",
            "Open transaction",
            "Carry to Exports",
            "Queue export"
          ] do
        assert text =~ expected
      end

      refute text =~ "!"

      for unsafe <- [
            "robust",
            "seamless",
            "powerful",
            "SIEM",
            "immutable ledger",
            "compliance suite",
            "event sourcing",
            "raw storage",
            "trigger function",
            "query engine"
          ] do
        refute String.contains?(String.downcase(text), String.downcase(unsafe)),
               "Timeline primary copy leaked unsafe framing: #{unsafe}"
      end
    end

    test "primary Coverage copy answers readiness without generic Timeline or completion overclaims",
         %{conn: conn} do
      text = conn |> render_coverage() |> visible_text()

      for expected <- [
            "Audit coverage",
            # 197-02 density edit: the verdict panel's "Selected schema readiness"
            # eyebrow and "selected schema: …" meta line were removed; readiness
            # naming lives in the page subtitle and the header's "Schema:" meta.
            "Selected-schema audit readiness",
            "Schema:",
            "Needs capture",
            "Expected gap",
            "Add capture",
            "View activity"
          ] do
        assert text =~ expected
      end

      for unsafe <- [
            "capture is complete",
            "complete timeline answers",
            "Open Timeline",
            "Timeline can answer from every tracked table",
            "Timeline results may be incomplete for these tables",
            "rerun the timeline search"
          ] do
        refute String.contains?(String.downcase(text), String.downcase(unsafe)),
               "Coverage primary copy leaked retired readiness framing: #{unsafe}"
      end
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

    test "Retention source locks Phase 186 destructive-flow labels and state copy" do
      source = retention_source()

      for expected <- [
            ~s(open_label: "Run retention prune"),
            ~s(title: "Prune retention window permanently?"),
            ~s(cancel_label: "Keep retention window"),
            ~s(submit_label: "Prune records permanently"),
            ~s(mismatch_flash: "Could not prune - confirmation did not match."),
            ~s|aria-label="Retention window health"|,
            "Retention runtime is not started.",
            "No retention runs yet",
            "Configure a retention window",
            "mix threadline.retention.purge --dry-run"
          ] do
        assert source =~ expected
      end

      refute source =~ "Could not prune — confirmation did not match."
      refute source =~ ">Cancel<"
      refute source =~ "data-confirm"
    end

    test "Retention source keeps one policy-level destructive action path" do
      source = retention_source()
      row_action_block = retention_table_action_block(source)

      assert occurrences(source, ~s(open_label: "Run retention prune")) == 1
      assert occurrences(source, ~s(submit_label: "Prune records permanently")) == 1
      assert occurrences(source, ~s(phx-submit="prune_now")) == 1

      refute row_action_block =~ "open_prune_modal"
      refute row_action_block =~ "Prune records permanently"
      refute row_action_block =~ "tl-button--danger"

      assert row_action_block =~ "Review evidence"
      assert source =~ ~s(data-testid="retention-runs-table")
      assert source =~ ~s(data-testid="retention-runs-table-el")

      for forbidden <- ["@tailwind", "shadcn", "Heroicons", ~s(phx-value-id=)] do
        refute source =~ forbidden
      end
    end

    test "Phase 186 detail source locks H1/detail title distinctions and actor atom safety" do
      transaction = source(@transaction_live_path)
      row_route = source(@row_history_live_path)
      row_drawer = source(@row_history_component_path)
      actor = source(@actor_live_path)

      assert transaction =~ ~s(title="Transaction")
      assert transaction =~ ~s(<UI.detail_header title={transaction_title}>)
      assert transaction =~ ~S|defp transaction_detail_title(%{id: id}) do|
      assert transaction =~ ~S|"Transaction #{Presentation.short_id(id, 12)}"|
      assert transaction =~ ~S|defp transaction_detail_title(_), do: "Transaction"|

      assert row_route =~ ~s(title="Row history")

      assert row_route =~
               ~S|<UI.detail_header title={row_history_detail_title(@table, @record_id)}>|

      assert row_route =~ ~S|defp row_history_detail_title(table, record_id) do|
      assert row_route =~ ~S|"#{table} / #{Presentation.short_id(record_id, 14)}"|

      assert row_drawer =~ ~s(data-testid="row-history-drawer")

      assert row_drawer =~
               ~S|Row history: <%= @table %> / <%= Presentation.short_id(@record_id, 14) %>|

      assert actor =~ ~s(title="Actor activity")
      assert actor =~ ~S|<UI.detail_header title={actor_detail_title(@actor_ref)}>|
      assert actor =~ ~S|defp safe_actor_kind(kind) when is_binary(kind) do|
      assert actor =~ ~S|Enum.find(@actor_kinds, &(Atom.to_string(&1) == kind))|
      refute actor =~ "String.to_atom("
    end

    test "Phase 186 governance source locks focused copy and redaction remains non-destructive" do
      evidence = source(@evidence_live_path)
      redaction = source(@policy_redaction_live_path)
      retention = retention_source()

      assert evidence =~ ~s(<:title>No evidence records yet</:title>)

      assert evidence =~
               "Threadline has not recorded evidence for this selection yet. Use mix threadline.evidence.show or the Threadline.Evidence API to confirm the current evidence record, then narrow by subject if needed."

      assert evidence =~ ~s(aria-label="Evidence workflow summary")
      assert evidence =~ "Carry to Exports"

      assert redaction =~ ~s(aria-label="Redaction policy posture")

      assert redaction =~
               "Configured redaction policy matches deployed trigger policy for every introspected table. Continue to Evidence for the latest evidence record."

      assert redaction =~
               ~S|defp empty_section_label(:drift_detected), do: "No redaction drift detected."|

      for forbidden <- [
            "Prune records permanently",
            "Run retention prune",
            "Apply redaction",
            "Preview redaction",
            "Test redaction"
          ] do
        refute redaction =~ forbidden
      end

      assert retention =~ ~s(mismatch_flash: "Could not prune - confirmation did not match.")
    end

    test "Phase 186 export source locks real completed downloads and non-ready status text" do
      source = source(@export_status_live_path)
      download_attrs = export_download_attrs_block(source)
      actions_block = export_job_actions_block(source)
      status_label_block = export_job_status_label_block(source)

      assert download_attrs =~ ~s(href: "\#{base_path}/exports/download/\#{job.id}")
      assert download_attrs =~ ~s(class: "tl-button tl-button--primary tl-button--compact")
      refute download_attrs =~ "aria-disabled"
      refute download_attrs =~ "tabindex"
      refute download_attrs =~ "data-tl-mutating"

      assert actions_block =~ "Presentation.export_downloadable?(job)"
      assert actions_block =~ "Download export"

      assert actions_block =~
               ~S|<span class="tl-hint" role="status"><%= export_job_status_label(job) %></span>|

      for label <- ["Queued", "Processing", "Failed", "Export expired", "File unavailable"] do
        assert status_label_block =~ label
      end
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

    defp render_timeline(conn) do
      path = "/audit/timeline?from=2020-01-01T00:00&to=2020-01-02T00:00&table=ticket_replies"

      case live(conn, path) do
        {:ok, _view, html} -> html
        {:error, {:live_redirect, %{to: redirect_path}}} -> conn |> live(redirect_path) |> elem(2)
      end
    end

    defp render_coverage(conn) do
      {:ok, _view, html} = live(conn, "/audit/coverage")
      html
    end

    defp retention_source do
      source(@retention_live_path)
    end

    defp source(path), do: File.read!(path)

    defp retention_table_action_block(source) do
      case String.split(source, ~s(<:action :let={{_dom_id, _run}}>), parts: 2) do
        [_before, rest] ->
          rest |> String.split("</:action>", parts: 2) |> hd()

        _ ->
          flunk("Retention table action block not found")
      end
    end

    defp occurrences(haystack, needle) do
      haystack
      |> String.split(needle)
      |> length()
      |> Kernel.-(1)
    end

    defp export_download_attrs_block(source) do
      source
      |> String.split("defp download_link_attrs", parts: 2)
      |> List.last()
      |> String.split("defp group_jobs", parts: 2)
      |> List.first()
    end

    defp export_job_actions_block(source) do
      [before_predicate, after_predicate] =
        String.split(source, "Presentation.export_downloadable?(job)", parts: 2)

      before_actions =
        before_predicate
        |> String.split(~s(<div class="tl-job__actions">))
        |> List.last()

      after_actions =
        after_predicate
        |> String.split("</div>", parts: 2)
        |> List.first()

      before_actions <> "Presentation.export_downloadable?(job)" <> after_actions
    end

    defp export_job_status_label_block(source) do
      source
      |> String.split("defp export_job_status_label", parts: 2)
      |> List.last()
      |> String.split("defp download_link_attrs", parts: 2)
      |> List.first()
    end

    defp seed_timeline_change! do
      occurred_at = ~U[2020-01-01 12:00:00Z]

      txn =
        Threadline.Test.Repo.insert!(
          Threadline.Capture.AuditTransaction.changeset(%{
            txid: System.unique_integer([:positive]),
            occurred_at: occurred_at,
            actor_ref: %{"type" => "user", "id" => "copy-contract-operator"},
            source: "support"
          }),
          repo_opts()
        )

      Threadline.Test.Repo.insert!(
        Threadline.Capture.AuditChange.changeset(%{
          transaction_id: txn.id,
          table_schema: "public",
          table_name: "ticket_replies",
          table_pk: %{"id" => "copy-contract-row"},
          op: "insert",
          data_after: %{"body" => "copy contract row"},
          changed_fields: nil,
          captured_at: occurred_at
        }),
        repo_opts()
      )
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
