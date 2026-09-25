if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.BreadcrumbTest.Router do
    use Threadline.OperatorSurfaceTest.Router

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.BreadcrumbTest.Endpoint do
    use Threadline.OperatorSurfaceTest.Endpoint,
      router: Threadline.OperatorSurface.BreadcrumbTest.Router
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

    use Threadline.OperatorSurfaceCase,
      endpoint: Threadline.OperatorSurface.BreadcrumbTest.Endpoint

    import Threadline.StorageSchemaCase

    alias Threadline.Capture.AuditTransaction
    alias Threadline.Test.Repo

    setup_all do
      start_endpoint!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "drill-down trail is a Breadcrumb landmark rooted at Timeline (NAV-01/D-12)" do
      conn = build_conn()

      Repo.insert!(
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

      Repo.insert!(
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
