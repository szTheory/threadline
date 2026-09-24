defmodule Threadline.OperatorSurface.GatingTest do
  use ExUnit.Case, async: true

  describe "operator surface gating" do
    test "modules are conditionally loaded based on Phoenix.LiveView availability" do
      if Code.ensure_loaded?(Phoenix.LiveView) do
        assert Code.ensure_loaded?(Threadline.OperatorSurface.Router)
        assert Code.ensure_loaded?(Threadline.OperatorSurface.Auth)
      else
        refute Code.ensure_loaded?(Threadline.OperatorSurface.Router)
        refute Code.ensure_loaded?(Threadline.OperatorSurface.Auth)
      end
    end
  end
end

if Code.ensure_loaded?(Phoenix.LiveView) and Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.GatingTest.ExportsDisabledRouter do
    use Threadline.OperatorSurfaceTest.Router

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_disabled",
        exports: false,
        evidence_authorize_fn: &__MODULE__.evidence_auth/1
      )
    end

    def evidence_auth(_mirror), do: true
  end

  defmodule Threadline.OperatorSurface.GatingTest.ExportsDisabledEndpoint do
    # No Plug.Parsers in this endpoint, as before the migration to the shared
    # template.
    use Threadline.OperatorSurfaceTest.Endpoint,
      router: Threadline.OperatorSurface.GatingTest.ExportsDisabledRouter,
      parsers: false
  end

  defmodule Threadline.OperatorSurface.ExportFeatureGatingTest do
    use ExUnit.Case, async: false

    use Threadline.OperatorSurfaceCase,
      endpoint: Threadline.OperatorSurface.GatingTest.ExportsDisabledEndpoint

    setup_all do
      start_endpoint!(@endpoint)
      :ok
    end

    test "exports-disabled LiveView route renders unsupported view without export controls" do
      {:ok, _view, html} =
        build_conn()
        |> live("/audit_disabled/exports?table=posts&from=2026-05-01T00:00")

      assert html =~ "Export access needed"
      assert html =~ "You do not have access to exports."
      refute html =~ "Queue Timeline export"
      refute html =~ "Download export"
      refute html =~ ~s|data-testid="operator-nav-exports"|
    end

    test "exports-disabled mount omits direct HTTP export routes" do
      routes = Phoenix.Router.routes(Threadline.OperatorSurface.GatingTest.ExportsDisabledRouter)

      refute Enum.any?(routes, &(&1.path == "/audit_disabled/exports/download/:job_id"))
      refute Enum.any?(routes, &String.starts_with?(&1.path, "/audit_disabled/exports/changes."))
    end
  end
end
