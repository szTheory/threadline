if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.BreadcrumbTest.Layouts do
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

  defmodule Threadline.OperatorSurface.BreadcrumbTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.BreadcrumbTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.BreadcrumbTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_breadcrumb_key",
      signing_salt: "breadcrumb"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.BreadcrumbTest.Router)
  end

  defmodule Threadline.OperatorSurface.BreadcrumbTest do
    @moduledoc """
    NAV-01 / D-12 / D-13 drill-down breadcrumb trail regression guard.

    Drives the real drill-down LiveView (actor window, which renders the breadcrumb
    trail today) and asserts the *target* breadcrumb contract:
      * landmark is `<nav aria-label="Breadcrumb">` (NOT the legacy "Investigation path"),
      * the root link is labelled "Timeline",
      * the final/current segment is plain text and never carries `aria-current="page"`
        on the breadcrumb itself,
      * across the whole page render there is exactly one `aria-current="page"` (the nav
        link in the shell), never zero and never two.

    aria_current_count idiom copied from `surface_header_test.exs`.
    """
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest
    import Threadline.StorageSchemaCase

    alias Threadline.Capture.AuditTransaction

    @endpoint Threadline.OperatorSurface.BreadcrumbTest.Endpoint

    setup_all do
      Application.put_env(:threadline, Threadline.OperatorSurface.BreadcrumbTest.Endpoint,
        secret_key_base: "b" |> String.duplicate(64),
        live_view: [signing_salt: "b" |> String.duplicate(8)],
        render_errors: [view: Threadline.OperatorSurface.BreadcrumbTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "drill-down trail is a Breadcrumb landmark rooted at Timeline (NAV-01/D-12)" do
      conn = build_conn()

      Threadline.Test.Repo.insert!(
        AuditTransaction.changeset(%{
          txid: :rand.uniform(1_000_000_000),
          occurred_at: DateTime.utc_now(),
          actor_ref: %{"type" => "user", "id" => "breadcrumb_actor"}
        }),
        repo_opts()
      )

      {:ok, _lv, html} = live(conn, "/audit/actors/user/breadcrumb_actor")

      # NAV-01 current landmark label; the legacy "Investigation path" label stays retired.
      assert html =~ ~s|<nav aria-label="Breadcrumb"|
      refute html =~ ~s|aria-label="Investigation path"|

      # Root of the trail links back to Timeline.
      assert html =~ "Timeline"
    end

    test "exactly one aria-current=page across the page; never on the trail segment (NAV-01/D-13)" do
      conn = build_conn()

      Threadline.Test.Repo.insert!(
        AuditTransaction.changeset(%{
          txid: :rand.uniform(1_000_000_000),
          occurred_at: DateTime.utc_now(),
          actor_ref: %{"type" => "user", "id" => "breadcrumb_current"}
        }),
        repo_opts()
      )

      {:ok, _lv, html} = live(conn, "/audit/actors/user/breadcrumb_current")

      # Single source of truth for current location: the shell nav link only.
      assert aria_current_count(html) == 1

      # The breadcrumb landmark itself must not carry aria-current on its final segment.
      trail = breadcrumb_landmark(html)
      refute trail =~ ~s|aria-current="page"|
    end

    defp aria_current_count(html) do
      # The page embeds the full operator stylesheet inline via <Style.css />, and that
      # CSS contains the literal selector text `[aria-current="page"]`. Strip the
      # <style> block first so we only count real DOM attributes, not stylesheet text
      # (WR-02): otherwise the count is satisfied even when no nav link is current.
      html
      |> String.replace(~r/<style.*?<\/style>/s, "")
      |> then(&Regex.scan(~r/aria-current="page"/, &1))
      |> length()
    end

    defp breadcrumb_landmark(html) do
      case Regex.run(~r/<nav aria-label="Breadcrumb".*?<\/nav>/s, html) do
        [trail] ->
          trail

        # Legacy fallback keeps the aria-current assertion pointed at the same region
        # if the landmark label regresses; the primary assertion above still fails.
        nil ->
          case Regex.run(~r/<nav[^>]*aria-label="Investigation path".*?<\/nav>/s, html) do
            [legacy] -> legacy
            nil -> ""
          end
      end
    end
  end
end
