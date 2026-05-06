if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface do
    @moduledoc """
    Namespace for the Threadline operator surface — the opt-in mountable
    LiveView surface that turns Threadline's investigation contracts into
    one-click answers for documented support questions.

    *Available since 0.4.0.*

    This module is gated at file scope on `Code.ensure_loaded?(Phoenix.LiveView)`
    and only compiles when `:phoenix_live_view` is present in the consumer's
    deps. Capture-only adopters who install `:threadline` without
    `:phoenix_live_view` will not have this module loaded and will not see
    it in their hexdocs build.

    Mount the surface from a host Phoenix router using the
    `Threadline.OperatorSurface.Router` macro (shipping in v0.4.0).
    """

    @moduledoc since: "0.4.0"
  end
end
