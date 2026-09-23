if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive.Sections do
    @moduledoc false

    use Phoenix.Component

    attr(:clear_path, :string, required: true)

    def page_header(assigns) do
      ~H"""
          <header class="tl-page__header tl-stress__header">
            <div>
              <p class="tl-page__meta">Internal stress lab</p>
              <h1 class="tl-page__title">Operator surface stress audit</h1>
              <p class="tl-page__lede">
                Fixture-backed stories, ledger scores, and screenshot status for the current audit baseline.
              </p>
            </div>
            <a class="tl-button tl-button--secondary tl-button--compact" href={@clear_path}>
              Clear filters
            </a>
          </header>
      """
    end
  end
end
