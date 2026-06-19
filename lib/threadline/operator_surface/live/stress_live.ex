if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Threadline.OperatorSurface.StressFixtures

    @ledger_path ".planning/design-system-ledger.json"
    @category_allowlist StressFixtures.categories()
    @status_allowlist ~w(baseline current reserved)
    @theme_allowlist StressFixtures.theme_modes()
    @viewport_allowlist StressFixtures.viewports() |> Enum.map(&Integer.to_string/1)

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:base_path, "/audit")
       |> assign(:stress_path, "/audit/__stress")
       |> assign(:status_allowlist, @status_allowlist)
       |> assign(:ledger_error, nil)
       |> assign(:ledger_entries, [])
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

    def handle_params(params, uri, socket) do
      {ledger_entries, ledger_error} = load_ledger_entries()
      stories = ledger_stories(ledger_entries)
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
       |> assign(:base_path, base_path(uri))
       |> assign(:stress_path, stress_path(uri))
       |> assign(:status_allowlist, @status_allowlist)
       |> assign(:ledger_error, ledger_error)
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
      <Threadline.OperatorSurface.UI.shell
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
          <header class="tl-page__header tl-stress__header">
            <div>
              <p class="tl-page__meta">Internal stress lab</p>
              <h1 class="tl-page__title">Operator surface stress audit</h1>
              <p class="tl-page__lede">
                Fixture-backed stories, ledger scores, and screenshot status for the current audit baseline.
              </p>
            </div>
            <a class="tl-button tl-button--secondary tl-button--compact" href={clear_path(@stress_path)}>
              Clear filters
            </a>
          </header>

          <section :if={@ledger_error} class="tl-alert tl-alert--error" role="alert">
            Stress story could not render. Check the fixture shape, story assigns, and route gate, then rerun the audit.
          </section>

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

          <div class="tl-stress__layout">
            <aside class="tl-stress__sidebar" aria-label="Stress filters and stories">
              <nav class="tl-stress__category-nav" data-testid="stress-category-nav" aria-label="Stress categories">
                <a class={category_link_class(nil, @filter_category)} href={filter_path(@stress_path, nil, @filter_status)}>
                  All
                </a>
                <a
                  :for={category <- @categories}
                  class={category_link_class(category, @filter_category)}
                  href={filter_path(@stress_path, category, @filter_status)}
                  aria-current={if @filter_category == category, do: "page", else: nil}
                >
                  <%= category %>
                </a>
              </nav>

              <div class="tl-stress__filters" aria-label="Status filters">
                <a
                  :for={status <- @status_allowlist}
                  class={status_link_class(status, @filter_status)}
                  href={filter_path(@stress_path, @filter_category, status)}
                >
                  <%= status %>
                </a>
                <a class="tl-button tl-button--ghost tl-button--compact" data-testid="stress-clear-filters" href={clear_path(@stress_path)}>
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
                  href={story_path(@stress_path, story, @filter_category, @filter_status, @selected_theme, @selected_viewport)}
                >
                  <span class="tl-stress__story-id"><%= story.id %></span>
                  <span class="tl-stress__story-meta"><%= story.category %> / <%= story.status %></span>
                  <span class="tl-stress__story-fixture"><%= story.fixture_key %></span>
                </a>
              </div>
            </aside>

            <section class="tl-stress__preview" data-testid="stress-preview" aria-label="Selected stress story preview">
              <%= if @selected_story do %>
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
                    <dt>Owner phase</dt>
                    <dd><%= owner_phase(@selected_entry, @selected_story) %></dd>
                  </div>
                  <div>
                    <dt>Status</dt>
                    <dd><%= status(@selected_entry, @selected_story) %></dd>
                  </div>
                </dl>

                <div class="tl-stress__fixture-preview">
                  <%= preview_copy(@selected_story, @selected_assigns) %>
                </div>

                <div :if={show_ui_matrix?(@selected_story)} class="tl-stress__ui-matrix tl-mt-8 tl-space-y-8">
                  <h3>Phase 173 Primitives Matrix</h3>
                  
                  <div class="tl-space-y-4">
                    <h4>Buttons</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.button>Default</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button variant="primary">Primary</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button variant="quiet-primary">Quiet Primary</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button variant="danger">Danger</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button variant="ghost">Ghost</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.icon_button>X</Threadline.OperatorSurface.UI.icon_button>
                      
                      <!-- Interaction matrix -->
                      <Threadline.OperatorSurface.UI.button class="hover">Hover</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button class="focus-visible">Focus-Visible</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button class="active">Active/Pressed</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button disabled>Disabled</Threadline.OperatorSurface.UI.button>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Links</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.link href="#">Deep Link</Threadline.OperatorSurface.UI.link>
                      <Threadline.OperatorSurface.UI.link variant="back" href="#">Back Link</Threadline.OperatorSurface.UI.link>
                      <!-- Interaction matrix -->
                      <Threadline.OperatorSurface.UI.link href="#" class="hover">Hover</Threadline.OperatorSurface.UI.link>
                      <Threadline.OperatorSurface.UI.link href="#" class="focus-visible">Focus-Visible</Threadline.OperatorSurface.UI.link>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Badges</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.badge variant="neutral">Neutral</Threadline.OperatorSurface.UI.badge>
                      <Threadline.OperatorSurface.UI.badge variant="info">Info</Threadline.OperatorSurface.UI.badge>
                      <Threadline.OperatorSurface.UI.badge variant="success">Success</Threadline.OperatorSurface.UI.badge>
                      <Threadline.OperatorSurface.UI.badge variant="warning">Warning</Threadline.OperatorSurface.UI.badge>
                      <Threadline.OperatorSurface.UI.badge variant="danger">Danger</Threadline.OperatorSurface.UI.badge>
                      <Threadline.OperatorSurface.UI.badge variant="accent">Accent</Threadline.OperatorSurface.UI.badge>
                      <Threadline.OperatorSurface.UI.badge variant="muted">Muted</Threadline.OperatorSurface.UI.badge>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Alerts</h4>
                    <div class="tl-flex tl-flex-col tl-gap-4">
                      <Threadline.OperatorSurface.UI.alert variant="info">Info alert</Threadline.OperatorSurface.UI.alert>
                      <Threadline.OperatorSurface.UI.alert variant="success">Success alert</Threadline.OperatorSurface.UI.alert>
                      <Threadline.OperatorSurface.UI.alert variant="warning">Warning alert</Threadline.OperatorSurface.UI.alert>
                      <Threadline.OperatorSurface.UI.alert variant="error">Error alert</Threadline.OperatorSurface.UI.alert>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Misc Atoms</h4>
                    <div class="tl-flex tl-gap-4 tl-items-center">
                      <Threadline.OperatorSurface.UI.spinner />
                      <Threadline.OperatorSurface.UI.avatar src="" alt="Avatar" />
                    </div>
                    <Threadline.OperatorSurface.UI.divider />
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Cards & Tiles</h4>
                    <div class="tl-grid tl-grid-cols-2 tl-gap-4">
                      <Threadline.OperatorSurface.UI.card>
                        <:title>Card Title</:title>
                        <:meta>Meta info</:meta>
                        Card body content
                        <:actions>
                          <Threadline.OperatorSurface.UI.button>Action</Threadline.OperatorSurface.UI.button>
                        </:actions>
                      </Threadline.OperatorSurface.UI.card>
                      
                      <Threadline.OperatorSurface.UI.stat_tile label="Total Users" value="1,234" />
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Empty & Error States</h4>
                    <div class="tl-grid tl-grid-cols-2 tl-gap-4">
                      <Threadline.OperatorSurface.UI.empty_state>
                        <:title>No data</:title>
                        Try adjusting filters.
                      </Threadline.OperatorSurface.UI.empty_state>
                      <Threadline.OperatorSurface.UI.error_state>
                        <:title>Loading failed</:title>
                        Could not reach database.
                      </Threadline.OperatorSurface.UI.error_state>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Phase 176 Data Display</h4>
                    <div class="tl-space-y-4">
                      <Threadline.OperatorSurface.UI.ref
                        value="chg_00000000-0000-4000-8000-000000000176/correlation/abcdef0123456789"
                        kind="correlation"
                        copy_label="Copy correlation id"
                      />

                      <Threadline.OperatorSurface.UI.kv>
                        <:item key="Correlation">corr-176</:item>
                        <:item key="Actor">operator@example.invalid</:item>
                      </Threadline.OperatorSurface.UI.kv>

                      <Threadline.OperatorSurface.UI.data_table
                        rows={[
                          %{status: "completed", rows: "1,234", at: "2026-06-16T12:00:00Z"},
                          %{status: "failed", rows: "0", at: "2026-06-16T13:00:00Z"}
                        ]}
                        row_status={fn r -> r.status end}
                      >
                        <:col :let={r} label="Status"><%= r.status %></:col>
                        <:col :let={r} label="Deleted rows"><%= r.rows %></:col>
                        <:col :let={r} label="Date"><%= r.at %></:col>
                        <:action>Actions</:action>
                      </Threadline.OperatorSurface.UI.data_table>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Phase 176 Data States (DATA-03 taxonomy)</h4>
                    <div class="tl-space-y-4">
                      <Threadline.OperatorSurface.UI.stale_banner as_of="2026-06-16 23:59 UTC" />
                      <Threadline.OperatorSurface.UI.loading_state />
                      <Threadline.OperatorSurface.UI.data_state reason={:no_data} />
                      <Threadline.OperatorSurface.UI.data_state reason={:unauthorized} />
                      <Threadline.OperatorSurface.UI.data_state reason={:source_down} />
                      <Threadline.OperatorSurface.UI.data_state reason={:redacted} />
                      <Threadline.OperatorSurface.UI.data_state reason={:pruned} as_of="2026-05-01" />
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Forms</h4>
                    <div class="tl-flex tl-flex-col tl-gap-4">
                      <Threadline.OperatorSurface.UI.field id="stress-text" name="text_field" label="Text Field" type="text" value="Sample text" />
                      <Threadline.OperatorSurface.UI.field id="stress-textarea" name="textarea_field" label="Textarea Field" type="textarea" value="Sample text" />
                      <Threadline.OperatorSurface.UI.field id="stress-select" name="select_field" label="Select Field" type="select" options={["Option 1", "Option 2"]} />
                      <Threadline.OperatorSurface.UI.field id="stress-checkbox" name="checkbox_field" label="Checkbox Field" type="checkbox" value="true" />
                      <Threadline.OperatorSurface.UI.field id="stress-radio" name="radio_field" label="Radio Field" type="radio" value="true" />
                      <Threadline.OperatorSurface.UI.field id="stress-switch" name="switch_field" label="Switch Field" type="switch" value="true" />
                      <Threadline.OperatorSurface.UI.field id="stress-date" name="date_field" label="Date Field" type="date" value="2026-06-16" />
                      <Threadline.OperatorSurface.UI.field id="stress-error" name="error_field" label="Error Field" type="text" value="Bad input" errors={["This field is required"]} help_text="Please enter a valid value." />
                      <Threadline.OperatorSurface.UI.field id="stress-disabled" name="disabled_field" label="Disabled Field" type="text" value="Can't touch this" disabled />
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Overlays & Disclosures</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.tooltip id="stress-tooltip">
                        <:trigger>
                          <Threadline.OperatorSurface.UI.button>Hover Tooltip</Threadline.OperatorSurface.UI.button>
                        </:trigger>
                        Tooltip content
                      </Threadline.OperatorSurface.UI.tooltip>

                      <Threadline.OperatorSurface.UI.popover id="stress-popover">
                        <:trigger>
                          <Threadline.OperatorSurface.UI.button>Click Popover</Threadline.OperatorSurface.UI.button>
                        </:trigger>
                        Popover content
                      </Threadline.OperatorSurface.UI.popover>

                      <Threadline.OperatorSurface.UI.dropdown id="stress-dropdown">
                        <:trigger>
                          <Threadline.OperatorSurface.UI.button>Dropdown Menu</Threadline.OperatorSurface.UI.button>
                        </:trigger>
                        Dropdown content
                      </Threadline.OperatorSurface.UI.dropdown>
                    </div>
                    
                    <Threadline.OperatorSurface.UI.accordion id="stress-accordion" title="Accordion Section">
                      Accordion inner content
                    </Threadline.OperatorSurface.UI.accordion>
                    
                    <Threadline.OperatorSurface.UI.tabs>
                      <:tab active>Tab 1</:tab>
                      <:tab>Tab 2</:tab>
                    </Threadline.OperatorSurface.UI.tabs>

                    <Threadline.OperatorSurface.UI.segmented_control>
                      <:segment active>Seg 1</:segment>
                      <:segment>Seg 2</:segment>
                    </Threadline.OperatorSurface.UI.segmented_control>

                    <div class="tl-flex tl-gap-4">
                      <Threadline.OperatorSurface.UI.button phx-click={Threadline.OperatorSurface.UI.show_modal("stress-modal")}>Show Modal</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button phx-click={Threadline.OperatorSurface.UI.show_drawer("stress-drawer")}>Show Drawer</Threadline.OperatorSurface.UI.button>
                      
                      <Threadline.OperatorSurface.UI.modal id="stress-modal">
                        Modal Content
                      </Threadline.OperatorSurface.UI.modal>
                      
                      <Threadline.OperatorSurface.UI.drawer id="stress-drawer">
                        Drawer Content
                      </Threadline.OperatorSurface.UI.drawer>
                      
                      <Threadline.OperatorSurface.UI.toast id="stress-toast" kind="info" title="Toast Title">
                        Toast message body
                      </Threadline.OperatorSurface.UI.toast>
                    </div>
                  </div>
                </div>
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
      </Threadline.OperatorSurface.UI.shell>
      """
    end

    defp load_ledger_entries do
      case ledger_path() do
        nil ->
          {[], "missing ledger"}

        path ->
          try do
            entries = path |> File.read!() |> Jason.decode!() |> Map.fetch!("entries")
            {entries, nil}
          rescue
            _ -> {[], "invalid ledger"}
          end
      end
    end

    defp ledger_path do
      [
        @ledger_path,
        Path.join(["..", "..", @ledger_path])
      ]
      |> Enum.map(&Path.expand/1)
      |> Enum.find(&File.exists?/1)
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

    defp base_path(uri) do
      uri
      |> URI.parse()
      |> Map.get(:path)
      |> case do
        path when is_binary(path) -> String.replace_suffix(path, "/__stress", "")
        _ -> "/audit"
      end
    end

    defp stress_path(uri) do
      uri
      |> URI.parse()
      |> Map.get(:path)
      |> case do
        path when is_binary(path) -> path
        _ -> "/audit/__stress"
      end
    end

    defp clear_path(stress_path), do: stress_path

    defp filter_path(stress_path, category, status) do
      query =
        %{}
        |> maybe_put("category", category)
        |> maybe_put("status", status)
        |> URI.encode_query()

      if query == "", do: clear_path(stress_path), else: "#{stress_path}?#{query}"
    end

    defp story_path(stress_path, story, category, status, theme, viewport) do
      query =
        %{"story" => story.id}
        |> maybe_put("category", category)
        |> maybe_put("status", status)
        |> maybe_put("theme", theme)
        |> maybe_put("viewport", viewport)
        |> URI.encode_query()

      "#{stress_path}?#{query}"
    end

    defp maybe_put(map, _key, nil), do: map
    defp maybe_put(map, key, value), do: Map.put(map, key, value)

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

    defp owner_phase(nil, story), do: story.owner_phase
    defp owner_phase(entry, _story), do: entry["owner_phase"]

    defp status(nil, story), do: story.status
    defp status(entry, _story), do: entry["status"]

    defp preview_copy(_story, {:ok, assigns}) do
      assigns[:body] || assigns[:title] || "Synthetic stress fixture."
    end

    defp preview_copy(story, _assigns) do
      Map.get(story.data, :summary, "Synthetic stress fixture.")
    end

    defp show_ui_matrix?(%{category: category})
         when category in ~w(foundation primitive form_control group state),
         do: true

    defp show_ui_matrix?(_story), do: false
  end
end
