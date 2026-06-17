defmodule Threadline.OperatorSurface.SurfaceHeaderCspTest do
  @moduledoc """
  Wave 0 RED scaffold for NAV-03 / NAV-04 / D-27 — the CSP source-string guard.

  This is the standing CSP gate for Phase 175 (Plans 02–04): the operator-surface
  shell header must carry zero inline `on*=` event handlers (CSP-proof, no
  `script-src 'unsafe-inline'` requirement) and the theme picker must post to
  the base-path `/theme` route carrying a `_csrf_token`.

  Expected state at Wave 0 (this plan, 175-01):
    * RED — `surface_header.ex` still ships `onclick=` (skip-link L34, nav-toggle L74)
      and `onchange=` (theme radios L110/114/118). The `refute` assertions below FAIL
      until Plan 02 replaces those handlers with CSP-safe alternatives.
    * GREEN — the form already posts to `/theme` and renders `_csrf_token`; those two
      `assert` lines pass today and stay as regression locks.

  Idiom copied from `style_contract_test.exs` (@path + File.read! + String.contains?).
  """
  use ExUnit.Case, async: true

  @header_path "lib/threadline/operator_surface/components/surface_header.ex"

  # Inline event-handler attribute names the shell must never carry. The two
  # currently present (onclick/onchange) are the RED targets; the rest broaden
  # the guard so a future handler in any form can't slip past Plan 02 (T-175-01).
  @inline_handlers ~w(
    onclick= onchange= oninput= onsubmit= onload= onfocus= onblur=
    onkeydown= onkeyup= onkeypress= onmouseover= onmouseout= onmousedown=
    onmouseup= ontoggle= onreset= onscroll=
  )

  test "shell header source carries no inline on*= event handlers (NAV-03/NAV-04/D-27)" do
    src = File.read!(@header_path)

    for handler <- @inline_handlers do
      refute String.contains?(src, handler),
             "surface_header.ex must not contain the inline handler `#{handler}` (CSP-proof shell)"
    end

    # Broad catch for any other `on<word>=` attribute the explicit list misses.
    refute Regex.match?(~r/\son[a-z]+\s*=\s*["']/i, src),
           "surface_header.ex must not contain any inline on*= event handler attribute"
  end

  test "theme picker posts to /theme with a CSRF token (NAV-03 GREEN regression lock)" do
    src = File.read!(@header_path)

    assert String.contains?(src, "/theme"),
           "theme picker form must post to the base-path /theme route"

    assert String.contains?(src, "_csrf_token"),
           "theme picker form must carry a hidden _csrf_token input"
  end
end
