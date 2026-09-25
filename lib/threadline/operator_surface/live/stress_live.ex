if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive do
    @moduledoc false

    use Phoenix.LiveView

    # This dev/test-only design-system stress harness renders form controls as component
    # fixtures, so it explicitly declares a has-forms policy even though it is not a
    # shipped operator page. The declaration keeps form-policy validation structural
    # instead of relying on a path-based exception.
    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
    @ui_form_policy {:has_forms, "stress harness renders form controls as fixtures"}

    alias Threadline.OperatorSurface.Live.StressLive.Paths
    alias Threadline.OperatorSurface.Live.StressLive.Sections
    alias Threadline.OperatorSurface.StressFixtures

    @category_allowlist StressFixtures.categories()
    @status_allowlist ~w(baseline current reserved)
    @theme_allowlist StressFixtures.theme_modes()
    @viewport_allowlist StressFixtures.viewports() |> Enum.map(&Integer.to_string/1)

    def mount(_params, session, socket) do
      ledger_entries = validate_ledger_entries!(session)

      {:ok,
       socket
       |> assign(:base_path, "/audit")
       |> assign(:stress_path, "/audit/__stress")
       |> assign(:status_allowlist, @status_allowlist)
       |> assign(:ledger_error, nil)
       |> assign(:ledger_entries, ledger_entries)
       |> assign(:stories, [])
       |> assign(:categories, [])
       |> assign(:selected_story, nil)
       |> assign(:selected_entry, nil)
       |> assign(:selected_assigns, nil)
       |> assign(:selected_theme, "dark")
       |> assign(:selected_viewport, "1024")
       |> assign(:filter_category, nil)
       |> assign(:filter_status, nil)}
    end

    defp validate_ledger_entries!(%{"threadline_stress_ledger_entries" => entries})
         when is_list(entries) and entries != [] do
      if Enum.all?(entries, &is_map/1) do
        entries
      else
        invalid_ledger_session!()
      end
    end

    defp validate_ledger_entries!(_session), do: invalid_ledger_session!()

    defp invalid_ledger_session! do
      raise ArgumentError, """
      Threadline stress session ledger entries must be a non-empty list of maps.
      Recovery: mix test test/threadline/operator_surface/stress_router_test.exs
      """
    end

    def handle_params(params, uri, socket) do
      ledger_entries = socket.assigns.ledger_entries
      # Ledger-backed product stories plus the graded-ladder oracle fixtures.
      # The latter are dev/test-only validation cells with no ledger entry — surfaced
      # here purely so the graded capture lane can render + screenshot them.
      stories =
        (ledger_stories(ledger_entries) ++ StressFixtures.graded_stories())
        |> Enum.uniq_by(& &1.id)
        |> Enum.sort_by(& &1.id)

      categories = stories |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()

      filter_category = allow(params["category"], @category_allowlist)
      filter_status = allow(params["status"], @status_allowlist)
      selected_theme = allow(params["theme"], @theme_allowlist) || socket.assigns.threadline_theme
      selected_viewport = allow(params["viewport"], @viewport_allowlist) || "1024"

      visible_stories =
        stories
        |> filter_by(:category, filter_category)
        |> filter_by(:status, filter_status)

      selected_story = selected_story(params["story"], stories, visible_stories)
      selected_entry = ledger_entry_for(ledger_entries, selected_story)
      selected_assigns = selected_assigns(selected_story)

      {:noreply,
       socket
       |> assign(:base_path, Paths.base_path(uri))
       |> assign(:stress_path, Paths.stress_path(uri))
       |> assign(:status_allowlist, @status_allowlist)
       |> assign(:ledger_error, nil)
       |> assign(:ledger_entries, ledger_entries)
       |> assign(:stories, visible_stories)
       |> assign(:categories, categories)
       |> assign(:selected_story, selected_story)
       |> assign(:selected_entry, selected_entry)
       |> assign(:selected_assigns, selected_assigns)
       |> assign(:selected_theme, selected_theme)
       |> assign(:selected_viewport, selected_viewport)
       |> assign(:filter_category, filter_category)
       |> assign(:filter_status, filter_status)}
    end

    def render(assigns) do
      ~H"""
      <Threadline.OperatorSurface.UI.Page.shell
        theme={@selected_theme}
        header_theme={@threadline_theme}
        coverage={@threadline_coverage}
        base_path={@base_path}
        error={@threadline_coverage_error}
        coverage_enabled={@threadline_coverage_enabled}
        policy_enabled={@threadline_policy_enabled}
        evidence_enabled={@threadline_evidence_enabled}
        exports_enabled={@threadline_exports_enabled}
        current={:stress}
        scoped={not is_nil(assigns[:threadline_scope])}
        main_class="tl-page tl-stress"
        data-testid="stress-lab"
      >
          <Sections.page_header clear_path={Paths.clear_path(@stress_path)} />

          <section :if={@ledger_error} class="tl-alert tl-alert--error" role="alert">
            Stress story could not render. Check the fixture shape, story assigns, and route gate, then rerun the audit.
          </section>

          <Sections.ledger_metrics selected_story={@selected_story} selected_entry={@selected_entry} />

          <div class="tl-stress__layout">
            <Sections.story_sidebar
              categories={@categories}
              filter_category={@filter_category}
              filter_status={@filter_status}
              status_allowlist={@status_allowlist}
              stories={@stories}
              selected_story={@selected_story}
              selected_theme={@selected_theme}
              selected_viewport={@selected_viewport}
              stress_path={@stress_path}
            />

            <section class="tl-stress__preview" data-testid="stress-preview" aria-label="Selected stress story preview">
              <%= if @selected_story do %>
                <Sections.story_details
                  selected_story={@selected_story}
                  selected_entry={@selected_entry}
                  selected_assigns={@selected_assigns}
                  selected_theme={@selected_theme}
                  selected_viewport={@selected_viewport}
                />

                <Sections.refute_matrix :if={show_refute_matrix?(@selected_story)} selected_story={@selected_story} />

                <Sections.ui_matrix :if={show_ui_matrix?(@selected_story)} />
              <% else %>
                <div class="tl-empty tl-empty--unsupported" data-testid="stress-empty-state" role="status">
                  <h2 class="tl-empty__title">No stress stories registered</h2>
                  <p class="tl-empty__body">
                    Add a fixture-backed story to the stress registry so this category can be audited.
                  </p>
                </div>
              <% end %>
            </section>
          </div>
      </Threadline.OperatorSurface.UI.Page.shell>
      """
    end

    defp ledger_stories(entries) do
      entries
      |> Enum.map(& &1["story_id"])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.flat_map(fn story_id ->
        case StressFixtures.by_id(story_id) do
          {:ok, story} -> [story]
          :error -> []
        end
      end)
      |> Enum.sort_by(& &1.id)
    end

    defp selected_story(story_id, _stories, visible_stories) do
      with story_id when is_binary(story_id) <-
             allow(story_id, Enum.map(visible_stories, & &1.id)),
           {:ok, story} <- StressFixtures.by_id(story_id) do
        story
      else
        _ -> List.first(visible_stories)
      end
    end

    defp selected_assigns(nil), do: {:error, :unknown_story}
    defp selected_assigns(story), do: StressFixtures.assigns_for(story)

    defp ledger_entry_for(_entries, nil), do: nil

    defp ledger_entry_for(entries, story) do
      Enum.find(entries, fn entry -> entry["story_id"] == story.id end)
    end

    defp filter_by(stories, _field, nil), do: stories

    defp filter_by(stories, field, value),
      do: Enum.filter(stories, &(Map.get(&1, field) == value))

    defp allow(value, allowed) when is_binary(value) do
      if value in allowed, do: value, else: nil
    end

    defp allow(_value, _allowed), do: nil

    defp show_ui_matrix?(%{category: category})
         when category in ~w(foundation primitive form_control group state),
         do: true

    defp show_ui_matrix?(_story), do: false

    defp show_refute_matrix?(%{category: "refute"}), do: true
    defp show_refute_matrix?(_story), do: false
  end
end
