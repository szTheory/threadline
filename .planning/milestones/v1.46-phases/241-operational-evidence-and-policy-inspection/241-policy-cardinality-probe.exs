ExUnit.start(autorun: false)

defmodule Threadline.Phase241PolicyCardinalityProbe do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias Threadline.Capture.TriggerSQL
  alias Threadline.OperatorSurface.Live.PolicyRedactionLive
  alias Threadline.Policy.RedactionPresenter

  test "zero configured and deployed tables are empty rather than match assurance" do
    report = RedactionPresenter.build_report(%{}, [])
    assert report.tables == []
    html = render_report(report)
    assert html =~ "No configured policy to compare"
    assert html =~ "No configured redaction policies were found for this inspection."
    refute html =~ "Configured policy matches deployed trigger policy"
  end

  test "one long table and normalized policy value remain complete in disclosure" do
    table = "table_" <> String.duplicate("x", 57)
    column = "column_" <> String.duplicate("y", 56)
    placeholder = "NORMALIZED_" <> String.duplicate("SAFE_", 30)
    policy = [mask: [column], mask_placeholder: placeholder]

    report =
      RedactionPresenter.build_report(%{table => policy}, [
        %{
          table: table,
          function_name: "threadline_capture_changes_#{table}",
          function_language: "plpgsql",
          function_source:
            TriggerSQL.install_function_for_table(table, policy) <>
              "\n-- raw-source-cardinality-canary-241"
        }
      ])

    assert [%{status: :config_matches_deployed}] = report.tables
    html = render_report(report)
    assert html =~ table
    assert html =~ column
    assert html =~ placeholder
    refute html =~ "raw-source-cardinality-canary-241"
    assert html =~ "<details"
    assert html =~ "data-label=\"Configured\""
    assert html =~ "data-label=\"Deployed\""
  end

  test "multiple configured tables with no deployment are drift, never all clear" do
    report = RedactionPresenter.build_report(%{"alpha" => [], "bravo" => [mask: ["email"]]}, [])
    assert report.summary.drift_detected == 2
    html = render_report(report)
    assert html =~ "alpha"
    assert html =~ "bravo"
    assert html =~ "No deployed Threadline trigger found for configured table."
    refute html =~ "Configured policy matches deployed trigger policy"
  end

  defp render_report(report) do
    {:ok, socket} = PolicyRedactionLive.mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    sections =
      Enum.map(report.grouped, fn {status, rows} ->
        %{status: status, rows: rows, title: Atom.to_string(status)}
      end)

    socket =
      Phoenix.Component.assign(socket,
        base_path: "/audit",
        report: report,
        sections: sections,
        threadline_theme: :dark,
        threadline_coverage: %{uncovered_count: 0},
        threadline_coverage_error: nil,
        threadline_coverage_enabled: false,
        threadline_policy_enabled: true,
        threadline_evidence_enabled: false,
        threadline_exports_enabled: false
      )

    socket.assigns |> PolicyRedactionLive.render() |> rendered_to_string()
  end
end

result = ExUnit.run()
if result.failures > 0, do: System.halt(1)
