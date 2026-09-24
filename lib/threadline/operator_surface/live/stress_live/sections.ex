if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive.Sections do
    @moduledoc false

    use Phoenix.Component

    alias Threadline.OperatorSurface.Live.StressLive.Paths

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

    attr(:selected_story, :map, required: true)
    attr(:selected_entry, :map, required: true)

    def ledger_metrics(assigns) do
      ~H"""
          <section class="tl-stress__metrics" aria-label="Selected story ledger status">
            <article class="tl-stress__metric">
              <span class="tl-stress__metric-label">Story</span>
              <strong class="tl-stress__mono" data-testid="stress-story-id"><%= story_id(@selected_story) %></strong>
            </article>
            <article class="tl-stress__metric">
              <span class="tl-stress__metric-label">Current score</span>
              <strong data-testid="stress-ledger-score"><%= score(@selected_entry, "current_score") %></strong>
            </article>
            <article class="tl-stress__metric">
              <span class="tl-stress__metric-label">Target score</span>
              <strong data-testid="stress-target-score"><%= score(@selected_entry, "target_score") %></strong>
            </article>
            <article class="tl-stress__metric">
              <span class="tl-stress__metric-label">Screenshot status</span>
              <strong data-testid="stress-screenshot-status"><%= screenshot_status(@selected_entry) %></strong>
            </article>
          </section>
      """
    end

    attr(:categories, :list, required: true)
    attr(:filter_category, :string, required: true)
    attr(:filter_status, :string, required: true)
    attr(:status_allowlist, :list, required: true)
    attr(:stories, :list, required: true)
    attr(:selected_story, :map, required: true)
    attr(:selected_theme, :string, required: true)
    attr(:selected_viewport, :string, required: true)
    attr(:stress_path, :string, required: true)

    def story_sidebar(assigns) do
      ~H"""
            <aside class="tl-stress__sidebar" aria-label="Stress filters and stories">
              <nav class="tl-stress__category-nav" data-testid="stress-category-nav" aria-label="Stress categories">
                <a class={category_link_class(nil, @filter_category)} href={Paths.filter_path(@stress_path, nil, @filter_status)}>
                  All
                </a>
                <a
                  :for={category <- @categories}
                  class={category_link_class(category, @filter_category)}
                  href={Paths.filter_path(@stress_path, category, @filter_status)}
                  aria-current={if @filter_category == category, do: "page", else: nil}
                >
                  <%= category %>
                </a>
              </nav>

              <div class="tl-stress__filters" aria-label="Status filters">
                <a
                  :for={status <- @status_allowlist}
                  class={status_link_class(status, @filter_status)}
                  href={Paths.filter_path(@stress_path, @filter_category, status)}
                >
                  <%= status %>
                </a>
                <a class="tl-button tl-button--ghost tl-button--compact" data-testid="stress-clear-filters" href={Paths.clear_path(@stress_path)}>
                  Clear filters
                </a>
              </div>

              <div class="tl-stress__story-list" data-testid="stress-story-list">
                <div
                  :if={@stories == []}
                  class="tl-empty tl-empty--unsupported"
                  data-testid="stress-empty-state"
                  role="status"
                >
                  <h2 class="tl-empty__title">No stress stories registered</h2>
                  <p class="tl-empty__body">
                    Add a fixture-backed story to the stress registry so this category can be audited.
                  </p>
                </div>
                <a
                  :for={story <- @stories}
                  class={story_link_class(story, @selected_story)}
                  href={Paths.story_path(@stress_path, story, @filter_category, @filter_status, @selected_theme, @selected_viewport)}
                >
                  <span class="tl-stress__story-id"><%= story.id %></span>
                  <span class="tl-stress__story-meta"><%= story.category %> / <%= story.status %></span>
                  <span class="tl-stress__story-fixture"><%= story.fixture_key %></span>
                </a>
              </div>
            </aside>
      """
    end

    attr(:selected_story, :map, required: true)
    attr(:selected_entry, :map, required: true)
    attr(:selected_assigns, :any, required: true)
    attr(:selected_theme, :string, required: true)
    attr(:selected_viewport, :string, required: true)

    def story_details(assigns) do
      ~H"""
                <div class="tl-stress__preview-header">
                  <div>
                    <p class="tl-page__meta"><%= @selected_story.category %> / <%= @selected_story.status %></p>
                    <h2 class="tl-stress__preview-title"><%= @selected_story.scenario %></h2>
                  </div>
                  <span class="tl-chip tl-chip--info"><%= @selected_theme %> / <%= @selected_viewport %>px</span>
                </div>

                <dl class="tl-stress__ledger-table" aria-label="Ledger item metadata">
                  <div>
                    <dt>Fixture key</dt>
                    <dd class="tl-stress__mono"><%= @selected_story.fixture_key %></dd>
                  </div>
                  <div>
                    <dt>Ledger item</dt>
                    <dd class="tl-stress__mono"><%= ledger_id(@selected_entry) %></dd>
                  </div>
                  <div>
                    <dt>Origin cohort</dt>
                    <dd><%= origin_cohort(@selected_entry, @selected_story) %></dd>
                  </div>
                  <div>
                    <dt>Status</dt>
                    <dd><%= status(@selected_entry, @selected_story) %></dd>
                  </div>
                </dl>

                <div class="tl-stress__fixture-preview">
                  <%= preview_copy(@selected_story, @selected_assigns) %>
                </div>
      """
    end

    defp category_link_class(category, current) do
      ["tl-stress__category-link", category == current && "tl-stress__category-link--active"]
    end

    defp status_link_class(status, current) do
      ["tl-chip", status == current && "tl-chip--info"]
    end

    defp story_link_class(story, selected_story) do
      [
        "tl-stress__story-link",
        selected_story && story.id == selected_story.id && "tl-stress__story-link--active"
      ]
    end

    defp story_id(nil), do: "none"
    defp story_id(story), do: story.id

    defp score(nil, _key), do: "unreported"
    defp score(entry, key), do: entry |> Map.get(key, "unreported") |> to_string()

    defp screenshot_status(nil), do: "unreported"

    defp screenshot_status(entry) do
      case entry["screenshot_baseline_refs"] do
        refs when is_list(refs) and refs != [] ->
          "#{length(refs)} attached"

        _ ->
          "No screenshot baseline is attached to this stress cell yet. Add it to the bounded allowlist before claiming pixel coverage."
      end
    end

    defp ledger_id(nil), do: "unreported"
    defp ledger_id(entry), do: entry["id"]

    defp origin_cohort(nil, story), do: story.origin_cohort
    defp origin_cohort(entry, _story), do: entry["origin_cohort"]

    defp status(nil, story), do: story.status
    defp status(entry, _story), do: entry["status"]

    defp preview_copy(_story, {:ok, assigns}) do
      assigns[:body] || assigns[:title] || "Synthetic stress fixture."
    end

    defp preview_copy(story, _assigns) do
      Map.get(story.data, :summary, "Synthetic stress fixture.")
    end
  end
end
