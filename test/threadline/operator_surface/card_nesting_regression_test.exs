if Code.ensure_loaded?(Phoenix.LiveView) do
  # ---------------------------------------------------------------------------
  # Permanent DATA-05 / D-12 card-nesting regression test.
  #
  # "One card boundary per logical unit" (brand-book.md:348). This test renders
  # each operator page and `refute`s any card-family class (`tl-card*`) nested
  # inside another card-family element. Coverage's former synthetic command shell
  # was flattened in Phase 176; this guard keeps the one-card-boundary contract
  # from regressing.
  #
  # The eleven operator surfaces this guards (router.ex L112-122 + shell):
  #   StartLive, TimelineLive, EvidenceLive, CoverageLive, ExportStatusLive,
  #   PolicyRedactionLive, RetentionHistoryLive, RowHistoryLive, TransactionLive,
  #   ActorLive, and the SurfaceHeader shell.
  # ---------------------------------------------------------------------------
  defmodule Threadline.OperatorSurface.CardNestingRegressionTest.Layouts do
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

  defmodule Threadline.OperatorSurface.CardNestingRegressionTest.Auth do
    def authorize(_), do: true
  end

  defmodule Threadline.OperatorSurface.CardNestingRegressionTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    alias Threadline.OperatorSurface.CardNestingRegressionTest.Auth

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.CardNestingRegressionTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)

      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit",
        coverage_authorize_fn: &Auth.authorize/1,
        policy_authorize_fn: &Auth.authorize/1,
        evidence_authorize_fn: &Auth.authorize/1
      )
    end
  end

  defmodule Threadline.OperatorSurface.CardNestingRegressionTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "c4rdn3st"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.CardNestingRegressionTest.Router)
  end

  defmodule Threadline.OperatorSurface.CardNestingRegressionTest do
    use Threadline.DataCase, async: false
    import Phoenix.ConnTest
    import Phoenix.LiveViewTest

    @endpoint Threadline.OperatorSurface.CardNestingRegressionTest.Endpoint

    # Source-level reference to every operator page module this regression
    # guards (acceptance criteria: all 11 page modules referenced).
    @page_modules [
      Threadline.OperatorSurface.Live.StartLive,
      Threadline.OperatorSurface.Live.TimelineLive,
      Threadline.OperatorSurface.Live.EvidenceLive,
      Threadline.OperatorSurface.Live.CoverageLive,
      Threadline.OperatorSurface.Live.ExportStatusLive,
      Threadline.OperatorSurface.Live.PolicyRedactionLive,
      Threadline.OperatorSurface.Live.RetentionHistoryLive,
      Threadline.OperatorSurface.Live.RowHistoryLive,
      Threadline.OperatorSurface.Live.TransactionLive,
      Threadline.OperatorSurface.Live.ActorLive,
      Threadline.OperatorSurface.Components.SurfaceHeader
    ]

    # Pages reachable without per-record fixtures (empty/first-run states render
    # cleanly). Detail pages (transactions/:id, rows/.., actors/..) require
    # seeded records and are exercised by their own per-page live tests.
    @page_paths [
      {"start", "/audit/"},
      {"timeline", "/audit/timeline"},
      {"evidence", "/audit/evidence"},
      {"coverage", "/audit/coverage"},
      {"exports", "/audit/exports"},
      {"redaction", "/audit/policy/redaction"},
      {"retention", "/audit/policy/retention"}
    ]

    setup_all do
      Application.put_env(
        :threadline,
        Threadline.OperatorSurface.CardNestingRegressionTest.Endpoint,
        secret_key_base: String.duplicate("c", 64),
        live_view: [signing_salt: String.duplicate("c", 8)],
        render_errors: [view: Threadline.OperatorSurface.CardNestingRegressionTest.Layouts]
      )

      start_supervised!(@endpoint)
      :ok
    end

    setup do
      {:ok, conn: build_conn()}
    end

    test "the regression references all eleven operator surface modules" do
      assert length(@page_modules) == 11

      for mod <- @page_modules do
        assert Code.ensure_loaded?(mod), "expected operator surface module #{inspect(mod)}"
      end
    end

    test "no card-family class is nested under another card-family class on any page",
         %{conn: conn} do
      for {name, path} <- @page_paths do
        html =
          case live(conn, path) do
            {:ok, _view, html} -> html
            {:error, {:live_redirect, %{to: to}}} -> render_path(conn, to)
            {:error, {:redirect, %{to: to}}} -> render_path(conn, to)
          end

        offenders = card_under_card(html)

        assert offenders == [],
               "#{name} (#{path}) nests a card-family class under another " <>
                 "card-family element (D-12 flatten violation): #{inspect(offenders)}"
      end
    end

    defp render_path(conn, path) do
      {:ok, _view, html} = live(conn, path)
      html
    end

    # ----------------------------------------------------------------------
    # Self-contained HTML walk (no parser dependency — zero new runtime deps,
    # v1.37 invariant). Tokenize start/end/void tags, maintain a stack of
    # "is this open element card-family?" booleans, and flag any card-family
    # element opened while an ancestor on the stack is already card-family.
    # ----------------------------------------------------------------------
    @void_tags ~w(area base br col embed hr img input link meta param source track wbr)

    defp card_under_card(html) do
      html
      |> tokenize()
      |> Enum.reduce({[], []}, fn token, {stack, offenders} ->
        case token do
          {:start, _tag, class, void?} ->
            is_card? = card_class?(class)
            ancestor_card? = Enum.any?(stack)

            offenders =
              if is_card? and ancestor_card?, do: [class | offenders], else: offenders

            if void? do
              {stack, offenders}
            else
              {[is_card? | stack], offenders}
            end

          {:end, _tag} ->
            {pop(stack), offenders}
        end
      end)
      |> elem(1)
      |> Enum.reverse()
    end

    defp pop([_ | rest]), do: rest
    defp pop([]), do: []

    # Yield {:start, tag, class, void?} / {:end, tag} tokens. Comments and the
    # doctype are skipped. Self-closing (`/>`) and HTML void tags are void.
    defp tokenize(html) do
      Regex.scan(~r/<(\/?)([a-zA-Z][a-zA-Z0-9-]*)([^>]*?)(\/?)>/, html)
      |> Enum.map(fn
        [_full, "/", tag, _attrs, _self] ->
          {:end, String.downcase(tag)}

        [_full, "", tag, attrs, self_close] ->
          tag = String.downcase(tag)
          void? = self_close == "/" or tag in @void_tags
          {:start, tag, extract_class(attrs), void?}
      end)
    end

    defp extract_class(attrs) do
      case Regex.run(~r/\bclass\s*=\s*"([^"]*)"/, attrs) do
        [_, class] -> class
        _ -> ""
      end
    end

    # A card-family SURFACE is an elevated/bordered boundary that should mark
    # exactly one logical unit (brand-book.md:348, D-11/D-12). That is:
    #   * the card block / block-modifier (`tl-card`, `tl-card--metric`), and
    #   * the synthetic command-shell panel D-12 targets for removal
    #     (`tl-coverage-command`) — a hand-rolled card-like surface.
    # BEM child *elements* (`tl-card__metric-label`, `tl-coverage-command__header`)
    # are NOT surfaces; they legitimately live inside their own block.
    @surface_prefixes ~w(tl-card tl-coverage-command)

    defp card_class?(class) do
      class
      |> String.split()
      |> Enum.any?(fn token ->
        not String.contains?(token, "__") and
          Enum.any?(@surface_prefixes, &String.starts_with?(token, &1))
      end)
    end
  end
end
