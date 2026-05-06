if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TransactionLiveTest.Layouts do
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

  defmodule Threadline.OperatorSurface.TransactionLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_live_flash
      plug :put_root_layout, html: {Threadline.OperatorSurface.TransactionLiveTest.Layouts, :root}
    end

    scope "/" do
      pipe_through :browser
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "v8q+QWvj"
    ]

    plug Plug.Session, @session_options
    plug :fetch_session
    plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library()
    plug Plug.MethodOverride
    plug Plug.Head
    plug Threadline.OperatorSurface.TransactionLiveTest.Router
  end

  defmodule Threadline.OperatorSurface.TransactionLiveTest do
    use ExUnit.Case, async: true
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.TransactionLiveTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.TransactionLiveTest.Endpoint, [
        secret_key_base: "x" |> String.duplicate(64),
        render_errors: [view: Threadline.OperatorSurface.TransactionLiveTest.Layouts]
      ])
      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "Case 1: Renders explicit not-found state for missing transaction ID", %{conn: conn} do
      uuid = Ecto.UUID.generate()
      assert {:ok, _lv, html} = live(conn, "/audit/transactions/#{uuid}")
      assert html =~ "Transaction Not Found - The requested transaction ID does not exist or has been purged by the retention policy."
    end
  end
end
