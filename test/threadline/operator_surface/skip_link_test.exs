if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.SkipLinkTest.Layouts do
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

  defmodule Threadline.OperatorSurface.SkipLinkTest.Auth do
    def authorize(_), do: true
  end

  defmodule Threadline.OperatorSurface.SkipLinkTest.FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Threadline.OperatorSurface.SkipLinkTest.FakeTicketReply do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "ticket_replies" do
      field(:body, :string)
    end
  end

  defmodule Threadline.OperatorSurface.SkipLinkTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.SkipLinkTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        repo: Threadline.Test.Repo,
        schemas: %{
          "ticket_replies" => Threadline.OperatorSurface.SkipLinkTest.FakeTicketReply,
          "users" => Threadline.OperatorSurface.SkipLinkTest.FakeUser
        },
        coverage_authorize_fn: &Threadline.OperatorSurface.SkipLinkTest.Auth.authorize/1,
        policy_authorize_fn: &Threadline.OperatorSurface.SkipLinkTest.Auth.authorize/1,
        evidence_authorize_fn: &Threadline.OperatorSurface.SkipLinkTest.Auth.authorize/1,
        export_authorize_fn: &Threadline.OperatorSurface.SkipLinkTest.Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.SkipLinkTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_skip_link_key",
      signing_salt: "skip-link"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.SkipLinkTest.Router)
  end

  defmodule Threadline.OperatorSurface.SkipLinkTest do
    @moduledoc """
    NAV-04 / D-26 GREEN regression lock — every operator page's skip-link target.

    Mounts each operator LiveView page and asserts its `<main id="tl-main">` carries
    `tabindex="-1"`, which is what makes the "Skip to main content" link able to move
    keyboard focus into the page body.

    Expected state at Wave 0 (this plan, 175-01):
      * GREEN today — all pages already carry the attribute (verified across the 10
        operator routes). This test stands as a regression lock so a future page can't
        silently drop the skip-link focus target.

    stress_live is dev/test-only and intentionally excluded.
    """
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.SkipLinkTest.Endpoint

    # Each operator page at its simplest reachable URL. Drill-down pages are mounted
    # with a non-existent id so they render their not-found state — which still wraps
    # content in <main id="tl-main" tabindex="-1">.
    @pages [
      {"Home", "/audit"},
      {"Timeline", "/audit/timeline"},
      {"Coverage", "/audit/coverage"},
      {"Evidence", "/audit/evidence"},
      {"Redaction", "/audit/policy/redaction"},
      {"Retention", "/audit/policy/retention"},
      {"Exports", "/audit/exports"},
      {"Row history", "/audit/rows/ticket_replies/missing-record"},
      {"Transaction", "/audit/transactions/00000000-0000-0000-0000-000000000000"},
      {"Actor", "/audit/actors/user/no_events_ever"}
    ]

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.SkipLinkTest.Endpoint,
        secret_key_base: "k" |> String.duplicate(64),
        live_view: [signing_salt: "k" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.SkipLinkTest.Layouts]
      )

      Application.put_env(:threadline, :coverage_poll_ms, 5_000)

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    for {name, path} <- @pages do
      test "#{name} (#{path}) renders <main id=tl-main tabindex=-1> (NAV-04/D-26)", %{conn: conn} do
        html = mount_html(conn, unquote(path))

        main = main_tag!(html)
        assert main =~ ~s|id="tl-main"|
        assert main =~ ~s|tabindex="-1"|
      end
    end

    # Some pages (e.g. Timeline) canonicalize their URL on mount via a live_redirect;
    # follow one hop so we render the destination's <main>.
    defp mount_html(conn, path) do
      case live(conn, path) do
        {:ok, _lv, html} -> html
        {:error, {:live_redirect, %{to: to}}} -> mount_html(conn, to)
      end
    end

    defp main_tag!(html) do
      case Regex.run(~r/<main[^>]*id="tl-main"[^>]*>/, html) do
        [tag] -> tag
        nil -> flunk("expected <main id=\"tl-main\"> in rendered page:\n#{html}")
      end
    end
  end
end
