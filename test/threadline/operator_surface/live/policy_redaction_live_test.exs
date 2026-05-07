if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.PolicyRedactionLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.PolicyRedactionLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.PolicyRedactionLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.PolicyRedactionLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "p0l1cy"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.PolicyRedactionLiveTest.Router)
  end

  defmodule Threadline.OperatorSurface.PolicyRedactionLiveTest do
    use ExUnit.Case, async: false

    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    alias Threadline.Capture.{AuditChange, AuditTransaction, TriggerSQL}
    alias Threadline.Policy.RedactionPresenter
    alias Threadline.Semantics.AuditAction
    alias Threadline.Test.Repo

    @endpoint Threadline.OperatorSurface.PolicyRedactionLiveTest.Endpoint

    @alpha "threadline_policy_redaction_alpha"
    @bravo "threadline_policy_redaction_bravo"
    @charlie "threadline_policy_redaction_charlie"
    @delta "threadline_policy_redaction_delta"

    @tables [@alpha, @bravo, @charlie, @delta]

    setup_all do
      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.PolicyRedactionLiveTest.Endpoint,
        secret_key_base: "p" |> String.duplicate(64),
        live_view: [signing_salt: "p" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.PolicyRedactionLiveTest.Layouts]
      )

      Enum.each(@tables, fn table ->
        Repo.query!("DROP TRIGGER IF EXISTS threadline_audit_#{table} ON #{table}")
        Repo.query!(TriggerSQL.drop_function_for_table(table))
        Repo.query!("DROP TABLE IF EXISTS #{table}")
      end)

      Enum.each(@tables, &create_table!/1)

      on_exit(fn ->
        Enum.each(@tables, fn table ->
          Repo.query!("DROP TRIGGER IF EXISTS threadline_audit_#{table} ON #{table}")
          Repo.query!(TriggerSQL.drop_function_for_table(table))
          Repo.query!("DROP FUNCTION IF EXISTS threadline_capture_changes_#{table}()")
          Repo.query!("DROP TABLE IF EXISTS #{table}")
        end)
      end)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      Repo.delete_all(AuditChange)
      Repo.delete_all(AuditTransaction)
      Repo.delete_all(AuditAction)

      original = Application.get_env(:threadline, :trigger_capture)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{
          @alpha => [exclude: ["password_hash"], mask: ["email"], mask_placeholder: "[MASKED]"],
          @bravo => [mask: ["email"], mask_placeholder: "[MASKED]"],
          @charlie => [mask: ["email"]],
          @delta => [mask: ["email"]]
        }
      )

      reset_table!(@alpha)
      reset_table!(@bravo)
      reset_table!(@charlie)
      reset_table!(@delta)

      install_match_trigger!(@alpha,
        exclude: ["password_hash"],
        mask: ["email"],
        mask_placeholder: "[MASKED]"
      )

      install_match_trigger!(@bravo,
        mask: ["email"],
        mask_placeholder: "[DEPLOYED]",
        store_changed_from: true
      )

      install_unintrospectable_trigger!(@charlie)

      on_exit(fn ->
        reset_table!(@alpha)
        reset_table!(@bravo)
        reset_table!(@charlie)
        reset_table!(@delta)

        if is_nil(original) do
          Application.delete_env(:threadline, :trigger_capture)
        else
          Application.put_env(:threadline, :trigger_capture, original)
        end
      end)

      {:ok, conn: build_conn()}
    end

    describe "mount /audit/policy/redaction" do
      test "renders presenter-driven sections in locked order with safe detail copy", %{
        conn: conn
      } do
        {:ok, _view, html} = live(conn, "/audit/policy/redaction")
        report = RedactionPresenter.build(repo: Repo, schema: "public")

        assert html =~ "Policy redaction drift"
        assert section_titles(html) == expected_section_titles(report)

        assert section_tables(html, section_heading(report, :drift_detected)) ==
                 Enum.map(report.grouped[:drift_detected], & &1.table)

        assert section_tables(html, section_heading(report, :could_not_introspect)) ==
                 Enum.map(report.grouped[:could_not_introspect], & &1.table)

        assert section_tables(html, section_heading(report, :config_matches_deployed)) ==
                 Enum.map(report.grouped[:config_matches_deployed], & &1.table)

        assert html =~ "Drift detected"
        assert html =~ "Could not introspect"
        assert html =~ "Config matches deployed"

        assert html =~ "Configured redaction does not match deployed trigger SQL."
        assert html =~ "Could not inspect deployed trigger SQL."
        assert html =~ "Configured redaction matches deployed trigger redaction."
        assert html =~ "No deployed Threadline trigger found for configured table."
        assert html =~ "Deployed trigger SQL did not match the expected Threadline trigger shape."

        assert html =~ "<th>Configured</th>"
        assert html =~ "<th>Deployed</th>"
        assert html =~ "<th>mask placeholder</th>"
        assert html =~ "[MASKED]"
        assert html =~ "[DEPLOYED]"
        assert html =~ "password_hash"
        assert html =~ "email"
        assert html =~ "not available"
        assert html =~ "not used"

        assert Enum.member?(Enum.map(report.grouped[:drift_detected], & &1.table), @bravo)
        assert Enum.member?(Enum.map(report.grouped[:drift_detected], & &1.table), @delta)

        assert Enum.member?(Enum.map(report.grouped[:could_not_introspect], & &1.table), @charlie)

        assert Enum.member?(
                 Enum.map(report.grouped[:config_matches_deployed], & &1.table),
                 @alpha
               )

        Enum.each(report.tables, fn row ->
          assert html =~ row.table
          assert html =~ row.hint

          if row.warning do
            assert html =~ row.warning
          end

          assert html =~ status_label(row.status)
        end)

        refute html =~ "alice@example.com"
        refute html =~ "super-secret"
      end
    end

    defp create_table!(table) do
      Repo.query!("""
      CREATE TABLE #{table} (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        email text NOT NULL,
        password_hash text NOT NULL,
        display_name text NOT NULL DEFAULT ''
      )
      """)
    end

    defp reset_table!(table) do
      Repo.query!("DROP TRIGGER IF EXISTS threadline_audit_#{table} ON #{table}")
      Repo.query!(TriggerSQL.drop_function_for_table(table))
      Repo.query!("DROP FUNCTION IF EXISTS threadline_capture_changes_#{table}()")
    end

    defp install_match_trigger!(table, opts) do
      sql =
        TriggerSQL.install_function_for_table(table,
          exclude: Keyword.get(opts, :exclude, []),
          mask: Keyword.get(opts, :mask, []),
          mask_placeholder: Keyword.get(opts, :mask_placeholder, "[REDACTED]"),
          store_changed_from: Keyword.get(opts, :store_changed_from, true)
        )

      Repo.query!(sql)
      Repo.query!(TriggerSQL.create_trigger(table, :per_table))
    end

    defp install_unintrospectable_trigger!(table) do
      Repo.query!("""
      CREATE OR REPLACE FUNCTION threadline_capture_changes_#{table}()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        RETURN NEW;
      END;
      $$;
      """)

      Repo.query!("""
      CREATE TRIGGER threadline_audit_#{table}
      AFTER INSERT OR UPDATE OR DELETE ON #{table}
      FOR EACH ROW
      EXECUTE FUNCTION threadline_capture_changes_#{table}();
      """)
    end

    defp section_titles(html) do
      Regex.scan(~r/<h3>([^<]+)<\/h3>/, html, capture: :all_but_first)
      |> List.flatten()
    end

    defp expected_section_titles(report) do
      [
        section_heading(report, :drift_detected),
        section_heading(report, :could_not_introspect),
        section_heading(report, :config_matches_deployed)
      ]
    end

    defp section_heading(report, status) do
      count = Map.fetch!(report.summary, status)
      "#{status_label(status)} (#{count})"
    end

    defp section_tables(html, heading) do
      [_, body] =
        Regex.run(
          ~r/<h3>#{Regex.escape(heading)}<\/h3><\/div><div class="policy-redaction-rows">(.+?)<\/div><\/section>/s,
          html
        )

      Regex.scan(~r/class="policy-redaction-table">([^<]+)</, body, capture: :all_but_first)
      |> List.flatten()
    end

    defp status_label(:drift_detected), do: "Drift detected"
    defp status_label(:could_not_introspect), do: "Could not introspect"
    defp status_label(:config_matches_deployed), do: "Config matches deployed"
  end
end
