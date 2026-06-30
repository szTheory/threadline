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
  defmodule Threadline.OperatorSurface.GatingTest.Layouts do
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

  defmodule Threadline.OperatorSurface.GatingTest.ExportsDisabledRouter do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.GatingTest.Layouts, :root}
      )
    end

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
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_gating_exports_disabled",
      signing_salt: "gAtInG"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.GatingTest.ExportsDisabledRouter)
  end

  defmodule Threadline.OperatorSurface.ExportFeatureGatingTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.GatingTest.ExportsDisabledEndpoint

    setup_all do
      Application.put_env(:threadline, @endpoint,
        secret_key_base: "g" |> String.duplicate(64),
        live_view: [signing_salt: "g" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.GatingTest.Layouts]
      )

      start_supervised!(@endpoint)
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
