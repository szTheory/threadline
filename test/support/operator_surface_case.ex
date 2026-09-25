if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurfaceTest.Layouts do
    @moduledoc """
    Root layout and error view shared by the operator-surface test endpoints.

    Every test router built with `Threadline.OperatorSurfaceTest.Router` renders
    its pages inside `root/1`, and every endpoint started through
    `Threadline.OperatorSurfaceCase.start_endpoint!/2` renders errors with it.
    """

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

  defmodule Threadline.OperatorSurfaceTest.Router do
    @moduledoc """
    Router template for operator-surface tests.

    `use Threadline.OperatorSurfaceTest.Router` defines a Phoenix router with a
    `:browser` pipeline (accepts, session, live flash, and the shared root
    layout). The using module then writes its own `scope` and
    `threadline_operator_surface(...)` mount, plus any helper functions the mount
    options capture with `&__MODULE__.fun/n`. The mount stays in each test file
    because the path and options differ from file to file.

    Options:

      * `:accepts` - formats for the `:accepts` plug (default `["html"]`)
      * `:browser_plugs` - extra function plugs (atoms) added to the `:browser`
        pipeline after the root layout, in order. The using module defines them.
    """

    defmacro __using__(opts) do
      accepts = Keyword.get(opts, :accepts, ["html"])
      browser_plugs = Keyword.get(opts, :browser_plugs, [])

      extra_plugs =
        for plug_name <- browser_plugs do
          quote do
            plug(unquote(plug_name))
          end
        end

      quote do
        use Phoenix.Router
        import Phoenix.LiveView.Router
        require Threadline.OperatorSurface.Router

        pipeline :browser do
          plug(:accepts, unquote(accepts))
          plug(:fetch_session)
          plug(:fetch_live_flash)
          plug(:put_root_layout, html: {Threadline.OperatorSurfaceTest.Layouts, :root})
          unquote_splicing(extra_plugs)
        end
      end
    end
  end

  defmodule Threadline.OperatorSurfaceTest.Endpoint do
    @moduledoc """
    Endpoint template for operator-surface tests.

    `use Threadline.OperatorSurfaceTest.Endpoint, router: MyRouter` defines a
    Phoenix endpoint with a cookie session, `Plug.Parsers`, method override,
    `Plug.Head`, and the given router. The session cookie key is derived from
    the endpoint module name, so each endpoint gets its own key.

    Options:

      * `:router` - the router module to plug last (required)
      * `:parsers` - `Plug.Parsers` parsers (default `[:json]`); `false` leaves
        `Plug.Parsers` out of the endpoint entirely
      * `:json_decoder` - JSON decoder for `Plug.Parsers`
        (default `Phoenix.json_library()`)
      * `:signing_salt` - session cookie signing salt (default a constant)
    """

    defmacro __using__(opts) do
      router = Keyword.fetch!(opts, :router)
      parsers = Keyword.get(opts, :parsers, [:json])
      json_decoder = Keyword.get(opts, :json_decoder, quote(do: Phoenix.json_library()))
      signing_salt = Keyword.get(opts, :signing_salt, "v8q+QWvj")

      parsers_plug =
        if parsers do
          quote do
            plug(Plug.Parsers,
              parsers: unquote(parsers),
              pass: ["*/*"],
              json_decoder: unquote(json_decoder)
            )
          end
        end

      quote do
        use Phoenix.Endpoint, otp_app: :threadline

        @session_options [
          store: :cookie,
          key: "_" <> String.replace(Macro.underscore(__MODULE__), "/", "_"),
          signing_salt: unquote(signing_salt)
        ]

        plug(Plug.Session, @session_options)
        plug(:fetch_session)
        unquote(parsers_plug)
        plug(Plug.MethodOverride)
        plug(Plug.Head)
        plug(unquote(router))
      end
    end
  end

  defmodule Threadline.OperatorSurfaceCase do
    @moduledoc """
    Shared setup for tests that drive an operator-surface test endpoint.

    `use Threadline.OperatorSurfaceCase, endpoint: MyEndpoint` imports
    `Phoenix.ConnTest` and `Phoenix.LiveViewTest`, sets `@endpoint`, and imports
    `start_endpoint!/2`. It is not an `ExUnit.CaseTemplate`: each test module
    keeps its own `use Threadline.DataCase` or `use ExUnit.Case` line with its
    own `async:` flag.
    """

    defmacro __using__(opts) do
      endpoint = Keyword.fetch!(opts, :endpoint)

      quote do
        import Phoenix.ConnTest
        import Phoenix.LiveViewTest
        import Threadline.OperatorSurfaceCase, only: [start_endpoint!: 1, start_endpoint!: 2]

        @endpoint unquote(endpoint)
      end
    end

    @doc """
    Configures `endpoint` and starts it under the test supervisor.

    The endpoint's application env (secret key base, LiveView signing salt,
    error view, merged with `extra_env`) is set before the endpoint starts, and
    the previous env is restored on exit. Call it from `setup_all` or `setup`.
    """
    def start_endpoint!(endpoint, extra_env \\ []) do
      previous = Application.fetch_env(:threadline, endpoint)

      env =
        Keyword.merge(
          [
            secret_key_base: String.duplicate("x", 64),
            live_view: [signing_salt: String.duplicate("x", 8)],
            render_errors: [view: Threadline.OperatorSurfaceTest.Layouts]
          ],
          extra_env
        )

      Application.put_env(:threadline, endpoint, env)

      ExUnit.Callbacks.on_exit(fn ->
        case previous do
          {:ok, value} -> Application.put_env(:threadline, endpoint, value)
          :error -> Application.delete_env(:threadline, endpoint)
        end
      end)

      ExUnit.Callbacks.start_supervised!(endpoint)
    end
  end
end
