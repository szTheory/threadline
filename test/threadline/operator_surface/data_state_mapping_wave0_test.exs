defmodule Threadline.OperatorSurface.DataStateMappingWave0Test do
  @moduledoc """
  Wave-0 RED until Plan 02/03 (DATA-03 / D-13..D-16).

  The page author must preserve the server's TYPED `:failed` reason all the way
  to the view and branch it into DISTINCT data-states — permission ≠ no-data ≠
  unavailable — each rendering a distinct icon SHAPE and heading (no-color-alone,
  UI-SPEC §"Data-State Taxonomy"). These three forensic distinctions must never
  collapse to a generic "something went wrong" (D-16):

    * permission   = exists, you can't see it          (lock/shield, role=alert)
    * no-data      = exists, your filter excluded it    (funnel, role=status)
    * unavailable  = NOT a permissions issue — down /   (plug/cloud-off / eye-off
                     redacted / pruned                    / archive)

  This test asserts a `UI.data_state/1` dispatcher maps each typed reason to the
  correct component (icon + heading + role). It is RED today: no `data_state/1`
  exists, `empty_state/1` lacks the `no_data`/`permission`/`unavailable` variants,
  and there is no async typed-reason dispatch in the surface. It turns GREEN when
  Plan 02/03 land the components and variants.
  """
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Threadline.OperatorSurface.UI

  # {reason, role, heading_fragment} — locked from UI-SPEC §"Data-State Taxonomy"
  # and §"Copywriting Contract".
  @cases [
    {:unauthorized, "alert", "don't have access"},
    {:source_down, "alert", "temporarily unavailable"},
    {:redacted, "status", "withheld by policy"},
    {:pruned, "status", "Removed under retention"},
    {:no_data, "status", "No changes match"},
    {:boom, "alert", "Could not load"}
  ]

  defp render_state(reason) do
    assigns = %{reason: reason}

    rendered_to_string(~H"""
    <UI.data_state reason={@reason} />
    """)
  end

  describe "typed reason → distinct data-state (DATA-03)" do
    test "each typed reason renders its locked role + heading" do
      for {reason, role, heading} <- @cases do
        html = render_state(reason)

        assert html =~ ~s(role="#{role}"),
               "reason #{inspect(reason)} should carry role=#{role}"

        assert html =~ heading,
               "reason #{inspect(reason)} should render heading fragment #{inspect(heading)}"
      end
    end

    test "permission, no-data and unavailable never collapse to the same icon/heading" do
      permission = render_state(:unauthorized)
      no_data = render_state(:no_data)
      down = render_state(:source_down)
      redacted = render_state(:redacted)
      pruned = render_state(:pruned)

      # Distinct headings (the load-bearing forensic distinction, D-16).
      headings =
        [permission, no_data, down, redacted, pruned]
        |> Enum.map(&extract_heading/1)

      assert length(Enum.uniq(headings)) == length(headings),
             "permission/no-data/down/redacted/pruned must each render a distinct heading"

      # Distinct icon shapes (no-color-alone): each maps to a different glyph.
      assert permission =~ "tl-icon"
      assert no_data =~ "tl-icon"

      icons =
        [permission, no_data, down, redacted, pruned]
        |> Enum.map(&extract_icon_signature/1)

      assert length(Enum.uniq(icons)) == length(icons),
             "permission/no-data/down/redacted/pruned must each render a distinct icon shape"
    end

    test "unavailable states explicitly state they are NOT a permissions issue" do
      for reason <- [:source_down, :redacted, :pruned] do
        assert render_state(reason) =~ "not a permissions issue",
               "unavailable reason #{inspect(reason)} must state it is not a permissions issue"
      end
    end
  end

  # Pull the first <path d="..."> sequence as a cheap icon-shape signature.
  defp extract_icon_signature(html) do
    Regex.scan(~r/<path[^>]*\bd="([^"]*)"/, html)
    |> Enum.map(fn [_, d] -> d end)
    |> Enum.join("|")
  end

  defp extract_heading(html) do
    case Regex.run(~r/<h[1-6][^>]*>(.*?)<\/h[1-6]>/s, html) do
      [_, inner] -> inner |> String.replace(~r/<[^>]+>/, "") |> String.trim()
      _ -> html
    end
  end
end
