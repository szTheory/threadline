if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.EvidenceLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.EvidenceLiveTest.Auth do
    def authorize(_mirror), do: Application.get_env(:threadline, :test_allow_evidence, true)
    def authorize_exports(_mirror), do: Application.get_env(:threadline, :test_allow_exports, true)
  end

  defmodule Threadline.OperatorSurface.EvidenceLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.EvidenceLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        evidence_authorize_fn: &Threadline.OperatorSurface.EvidenceLiveTest.Auth.authorize/1,
        export_authorize_fn: &Threadline.OperatorSurface.EvidenceLiveTest.Auth.authorize_exports/1,
        repo: Threadline.Test.Repo
      )
    end
  end

  defmodule Threadline.OperatorSurface.EvidenceLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "3v1d3nc3"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.EvidenceLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.EvidenceLiveTest do
    use Threadline.DataCase

    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Governance.EvidenceRecord

    @endpoint Threadline.OperatorSurface.EvidenceLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.EvidenceLiveTest.Endpoint,
        secret_key_base: "e" |> String.duplicate(64),
        live_view: [signing_salt: "e" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.EvidenceLiveTest.Layouts]
      )

      Application.put_env(:threadline, :test_allow_evidence, true)
      Application.put_env(:threadline, :test_allow_exports, true)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Repo.delete_all(EvidenceRecord)
      {:ok, conn: build_conn()}
    end

    defp insert_evidence(attrs) do
      defaults = %{
        subject: "retention_run",
        subject_ref: %{"run_id" => Ecto.UUID.generate()},
        summary_status: "completed",
        recorded_at: ~U[2026-05-26 12:00:00.000000Z],
        provenance: %{"writer" => "threadline", "entrypoint" => "test"},
        detail: %{"deleted_count" => 2},
        schema_version: 1
      }

      %EvidenceRecord{}
      |> EvidenceRecord.changeset(Map.merge(defaults, Map.new(attrs)))
      |> Repo.insert!()
    end

    describe "mount /audit/evidence" do
      test "renders unsupported state when evidence access is disabled", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_evidence, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_evidence, true) end)

        {:ok, _view, html} = live(conn, "/audit/evidence")

        assert html =~ "Unsupported View"
        assert html =~ "Evidence view unavailable."
        assert html =~ "mix threadline.evidence.show"
        refute html =~ "What can Threadline prove right now?"
      end

      test "renders the overview-first landing page with shared verdict labels", %{conn: conn} do
        insert_evidence(
          subject: "retention_run",
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: ~U[2026-05-26 12:00:00.000000Z],
          summary_status: "completed",
          detail: %{"deleted_count" => 2}
        )

        insert_evidence(
          subject: "redaction_policy",
          subject_ref: %{"policy" => "default"},
          recorded_at: ~U[2026-05-26 12:01:00.000000Z],
          summary_status: "configured",
          detail: %{"policy_status" => "configured"}
        )

        insert_evidence(
          subject: "support_scope_posture",
          subject_ref: %{"scope" => "support"},
          recorded_at: ~U[2026-05-26 12:02:00.000000Z],
          summary_status: "unsupported",
          detail: %{
            "claim_assessment" => %{
              "status" => "unsupported",
              "reason" => "host_owned_authorization"
            }
          }
        )

        {:ok, _view, html} = live(conn, "/audit/evidence")

        assert html =~ "What can Threadline prove right now?"
        assert html =~ ~s|href="/audit/evidence"|
        assert html =~ "Open proof history"
        assert html =~ "Proven"
        assert html =~ "Inferred"
        assert html =~ "Unsupported"

        assert html =~ "tl-secondary-ref"
        assert html =~ ~s(title="{&quot;run_id&quot;:&quot;ret-run-1&quot;}")
      end

      test "renders failed export evidence as presentation-only failure context", %{conn: conn} do
        insert_evidence(
          subject: "export_delivery",
          subject_ref: %{"export_id" => "export-123"},
          summary_status: "failed",
          detail: %{"error" => "runtime unavailable"}
        )

        {:ok, _view, html} = live(conn, "/audit/evidence")

        assert html =~ "Failed export evidence"
        assert html =~ "export_delivery"
        assert html =~ "Open proof history"

        refute html =~
                 ">Unsupported</span>\n                          <span>Failed export evidence"
      end

      test "opens proof history before support navigation", %{conn: conn} do
        insert_evidence(
          subject: "export_delivery",
          subject_ref: %{"export_id" => "export-123"},
          summary_status: "completed",
          detail: %{"status" => "completed"}
        )

        {:ok, _view, html} = live(conn, "/audit/evidence")

        assert html =~ "Open proof history"
        assert html =~ "Open exports"

        [card_support_position | _] =
          html
          |> :binary.matches("Open exports")
          |> Enum.reverse()

        assert :binary.match(html, "Open proof history") < card_support_position
      end

      test "renders carry-to-exports link for the current proof history context", %{conn: conn} do
        insert_evidence(
          subject: "export_delivery",
          subject_ref: %{"export_id" => "export-123"},
          summary_status: "completed",
          detail: %{"status" => "completed"}
        )

        subject_ref_json = URI.encode_www_form(~s({"export_id":"export-123"}))

        {:ok, _view, html} =
          live(
            conn,
            "/audit/evidence?subject=export_delivery&subject_ref_json=#{subject_ref_json}&mode=history"
          )

        assert html =~ "Carry to Exports"
        assert html =~ ~s|data-earned-flow="EF3"|
        assert html =~ ~s|data-persona="P3"|
        assert html =~ ~s|data-jtbd="J6"|
        assert html =~ ~s|href="/audit/exports?|
        assert html =~ "source=evidence"
        assert html =~ "subject=export_delivery"
        assert html =~ "mode=history"
        assert html =~ "subject_ref_json="
        refute html =~ "unknown="
        refute html =~ "from="
        refute html =~ "to="
        refute html =~ "table="
        refute html =~ "correlation_id="
      end

      test "carries only available proof-context keys from subject-only Evidence filters", %{
        conn: conn
      } do
        insert_evidence(
          subject: "retention_run",
          subject_ref: %{"run_id" => "ret-run-1"},
          detail: %{"deleted_count" => 2}
        )

        {:ok, _view, html} = live(conn, "/audit/evidence?subject=retention_run")

        assert html =~ "Carry to Exports"
        assert html =~ "source=evidence"
        assert html =~ "subject=retention_run"
        refute html =~ "subject_ref_json="
        refute html =~ "mode="
      end

      test "hides carry-to-exports when export access is disabled", %{conn: conn} do
        Application.put_env(:threadline, :test_allow_exports, false)
        on_exit(fn -> Application.put_env(:threadline, :test_allow_exports, true) end)

        insert_evidence(
          subject: "export_delivery",
          subject_ref: %{"export_id" => "export-123"},
          summary_status: "completed",
          detail: %{"status" => "completed"}
        )

        {:ok, _view, html} = live(conn, "/audit/evidence?subject=export_delivery")

        refute html =~ "Carry to Exports"
        refute html =~ "source=evidence"
        refute html =~ ~s|href="/audit/exports?|
      end

      test "subject query param narrows to one subject family", %{conn: conn} do
        insert_evidence(
          subject: "retention_run",
          subject_ref: %{"run_id" => "ret-run-1"},
          detail: %{"deleted_count" => 2}
        )

        insert_evidence(
          subject: "redaction_policy",
          subject_ref: %{"policy" => "default"},
          detail: %{"policy_status" => "configured"}
        )

        {:ok, _view, html} = live(conn, "/audit/evidence?subject=retention_run")

        assert html =~ "Back to latest for retention_run"
        assert html =~ "retention_run"
        refute html =~ "redaction_policy"
      end

      test "history drill-down stays on the mounted route and renders append-only history", %{
        conn: conn
      } do
        insert_evidence(
          subject: "retention_run",
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: ~U[2026-05-26 12:00:00.000000Z],
          summary_status: "completed",
          detail: %{"deleted_count" => 1}
        )

        insert_evidence(
          subject: "retention_run",
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: ~U[2026-05-26 12:05:00.000000Z],
          summary_status: "completed",
          detail: %{"deleted_count" => 2}
        )

        subject_ref_json = URI.encode_www_form(~s({"run_id":"ret-run-1"}))

        {:ok, _view, html} =
          live(
            conn,
            "/audit/evidence?subject=retention_run&subject_ref_json=#{subject_ref_json}&mode=history"
          )

        assert html =~ "Viewing append-only history for one evidence subject reference."
        assert html =~ "May 26, 12:05 PM UTC"
        assert html =~ "May 26, 12:00 PM UTC"
        assert html =~ "2026-05-26T12:05:00.000000Z"
      end

      test "renders the locked empty-state copy when no records exist", %{conn: conn} do
        {:ok, _view, html} = live(conn, "/audit/evidence")

        assert html =~ "No evidence records yet"
        assert html =~ "mix threadline.evidence.show"
        assert html =~ "Threadline.Evidence"
      end
    end
  end
end
