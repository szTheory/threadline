if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive.Sections do
    @moduledoc false

    use Phoenix.Component

    alias Phoenix.LiveView.JS
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
                <.link
                  :for={story <- @stories}
                  class={story_link_class(story, @selected_story)}
                  patch={Paths.story_path(@stress_path, story, @filter_category, @filter_status, @selected_theme, @selected_viewport)}
                >
                  <span class="tl-stress__story-id"><%= story.id %></span>
                  <span class="tl-stress__story-meta"><%= story.category %> / <%= story.status %></span>
                  <span class="tl-stress__story-fixture"><%= story.fixture_key %></span>
                </.link>
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

    attr(:overlay_fixture_state, :string, default: "ready")

    def ui_matrix(assigns) do
      ~H"""
                <div class="tl-stress__ui-matrix tl-mt-8 tl-space-y-8">
                  <h3>Primitives Matrix</h3>
                  
                  <.ui_matrix_actions />

                  <.ui_matrix_display />

                  <.ui_matrix_data />

                  <.ui_matrix_forms />

                  <.ui_matrix_overlays overlay_fixture_state={@overlay_fixture_state} />
                </div>
      """
    end

    defp ui_matrix_actions(assigns) do
      ~H"""
                  <div class="tl-space-y-4">
                    <h4>Buttons</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.Actions.button>Default</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button variant="primary">Primary</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button variant="quiet-primary">Quiet Primary</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button variant="danger">Danger</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button variant="ghost">Ghost</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.icon_button>X</Threadline.OperatorSurface.UI.Actions.icon_button>
                      
                      <!-- Interaction matrix -->
                      <Threadline.OperatorSurface.UI.Actions.button class="hover">Hover</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button class="focus-visible">Focus-Visible</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button class="active">Active/Pressed</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button disabled>Disabled</Threadline.OperatorSurface.UI.Actions.button>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Links</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.Actions.link href="#">Deep Link</Threadline.OperatorSurface.UI.Actions.link>
                      <Threadline.OperatorSurface.UI.Actions.link variant="back" href="#">Back Link</Threadline.OperatorSurface.UI.Actions.link>
                      <!-- Interaction matrix -->
                      <Threadline.OperatorSurface.UI.Actions.link href="#" class="hover">Hover</Threadline.OperatorSurface.UI.Actions.link>
                      <Threadline.OperatorSurface.UI.Actions.link href="#" class="focus-visible">Focus-Visible</Threadline.OperatorSurface.UI.Actions.link>
                    </div>
                  </div>
      """
    end

    defp ui_matrix_display(assigns) do
      ~H"""
                  <div class="tl-space-y-4">
                    <h4>Badges</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.Display.badge variant="neutral">Neutral</Threadline.OperatorSurface.UI.Display.badge>
                      <Threadline.OperatorSurface.UI.Display.badge variant="info">Info</Threadline.OperatorSurface.UI.Display.badge>
                      <Threadline.OperatorSurface.UI.Display.badge variant="success">Success</Threadline.OperatorSurface.UI.Display.badge>
                      <Threadline.OperatorSurface.UI.Display.badge variant="warning">Warning</Threadline.OperatorSurface.UI.Display.badge>
                      <Threadline.OperatorSurface.UI.Display.badge variant="danger">Danger</Threadline.OperatorSurface.UI.Display.badge>
                      <Threadline.OperatorSurface.UI.Display.badge variant="accent">Accent</Threadline.OperatorSurface.UI.Display.badge>
                      <Threadline.OperatorSurface.UI.Display.badge variant="muted">Muted</Threadline.OperatorSurface.UI.Display.badge>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Alerts</h4>
                    <div class="tl-flex tl-flex-col tl-gap-4">
                      <Threadline.OperatorSurface.UI.Display.alert variant="info">Info alert</Threadline.OperatorSurface.UI.Display.alert>
                      <Threadline.OperatorSurface.UI.Display.alert variant="success">Success alert</Threadline.OperatorSurface.UI.Display.alert>
                      <Threadline.OperatorSurface.UI.Display.alert variant="warning">Warning alert</Threadline.OperatorSurface.UI.Display.alert>
                      <Threadline.OperatorSurface.UI.Display.alert variant="error">Error alert</Threadline.OperatorSurface.UI.Display.alert>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Misc Atoms</h4>
                    <div class="tl-flex tl-gap-4 tl-items-center">
                      <Threadline.OperatorSurface.UI.Display.spinner />
                      <Threadline.OperatorSurface.UI.Display.avatar src="" alt="Avatar" />
                    </div>
                    <Threadline.OperatorSurface.UI.Display.divider />
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Cards & Tiles</h4>
                    <div class="tl-grid tl-grid-cols-2 tl-gap-4">
                      <Threadline.OperatorSurface.UI.Display.card>
                        <:title>Card Title</:title>
                        <:meta>Meta info</:meta>
                        Card body content
                        <:actions>
                          <Threadline.OperatorSurface.UI.Actions.button>Action</Threadline.OperatorSurface.UI.Actions.button>
                        </:actions>
                      </Threadline.OperatorSurface.UI.Display.card>
                      
                      <Threadline.OperatorSurface.UI.Display.stat_tile label="Total Users" value="1,234" />
                    </div>
                  </div>
      """
    end

    defp ui_matrix_data(assigns) do
      ~H"""
                  <div class="tl-space-y-4">
                    <h4>Empty & Error States</h4>
                    <div class="tl-grid tl-grid-cols-2 tl-gap-4">
                      <Threadline.OperatorSurface.UI.Data.empty_state>
                        <:title>No data</:title>
                        Try adjusting filters.
                      </Threadline.OperatorSurface.UI.Data.empty_state>
                      <Threadline.OperatorSurface.UI.Data.error_state>
                        <:title>Loading failed</:title>
                        Could not reach database.
                      </Threadline.OperatorSurface.UI.Data.error_state>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Data Display</h4>
                    <div class="tl-space-y-4">
                      <Threadline.OperatorSurface.UI.Display.ref
                        value="chg_00000000-0000-4000-8000-000000000176/correlation/abcdef0123456789"
                        kind="correlation"
                        copy_label="Copy correlation id"
                      />

                      <Threadline.OperatorSurface.UI.Display.kv>
                        <:item key="Correlation">corr-176</:item>
                        <:item key="Actor">operator@example.invalid</:item>
                      </Threadline.OperatorSurface.UI.Display.kv>

                      <Threadline.OperatorSurface.UI.Data.data_table
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
                      </Threadline.OperatorSurface.UI.Data.data_table>
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Data States</h4>
                    <div class="tl-space-y-4">
                      <Threadline.OperatorSurface.UI.Data.stale_banner as_of="2026-06-16 23:59 UTC" />
                      <Threadline.OperatorSurface.UI.Data.loading_state />
                      <Threadline.OperatorSurface.UI.Data.data_state reason={:no_data} />
                      <Threadline.OperatorSurface.UI.Data.data_state reason={:unauthorized} />
                      <Threadline.OperatorSurface.UI.Data.data_state reason={:source_down} />
                      <Threadline.OperatorSurface.UI.Data.data_state reason={:redacted} />
                      <Threadline.OperatorSurface.UI.Data.data_state reason={:pruned} as_of="2026-05-01" />
                    </div>
                  </div>
      """
    end

    defp ui_matrix_forms(assigns) do
      ~H"""
                  <div class="tl-space-y-4">
                    <h4>Forms</h4>
                    <div class="tl-flex tl-flex-col tl-gap-4">
                      <Threadline.OperatorSurface.UI.Form.field id="stress-text" name="text_field" label="Text Field" type="text" value="Sample text" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-textarea" name="textarea_field" label="Textarea Field" type="textarea" value="Sample text" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-select" name="select_field" label="Select Field" type="select" options={["Option 1", "Option 2"]} />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-search" name="search_field" label="Search Field" type="search" value="audit changes" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-checkbox" name="checkbox_field" label="Checkbox Field" type="checkbox" value="true" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-radio" name="radio_field" label="Radio Field" type="radio" value="true" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-switch" name="switch_field" label="Switch Field" type="switch" value="true" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-date" name="date_field" label="Date Field" type="date" value="2026-06-16" />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-error" name="error_field" label="Error Field" type="text" value="Bad input" errors={["This field is required"]} help_text="Please enter a valid value." />
                      <Threadline.OperatorSurface.UI.Form.field id="stress-disabled" name="disabled_field" label="Disabled Field" type="text" value="Can't touch this" disabled />
                      <div class="tl-field">
                        <label class="tl-label" for="stress-combobox">Combobox Field</label>
                        <Threadline.OperatorSurface.UI.Form.combobox
                          id="stress-combobox"
                          name="combobox_field"
                          value="Option 1"
                          options={[{"Option 1", "option_1"}, {"Option 2", "option_2"}]}
                        />
                      </div>
                      <Threadline.OperatorSurface.UI.Form.error_summary
                        id="stress-error-summary"
                        errors={[{"stress-error", "Error Field is required"}]}
                      />
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Data Panel</h4>
                    <Threadline.OperatorSurface.UI.Data.data_panel id="stress-data-panel" aria-label="Stress data panel">
                      <:data>
                        <Threadline.OperatorSurface.UI.Data.data_table
                          rows={[
                            %{status: "ready", rows: "24", at: "2026-06-16T12:00:00Z"}
                          ]}
                        >
                          <:col :let={r} label="Status"><%= r.status %></:col>
                          <:col :let={r} label="Rows"><%= r.rows %></:col>
                          <:col :let={r} label="Date"><%= r.at %></:col>
                        </Threadline.OperatorSurface.UI.Data.data_table>
                      </:data>
                    </Threadline.OperatorSurface.UI.Data.data_panel>
                  </div>
      """
    end

    attr(:overlay_fixture_state, :string, default: "ready")

    defp ui_matrix_overlays(assigns) do
      ~H"""
                  <div class="tl-space-y-4">
                    <h4>Overlays & Disclosures</h4>
                    <div class="tl-flex tl-gap-4 tl-flex-wrap">
                      <Threadline.OperatorSurface.UI.Overlay.tooltip id="stress-tooltip">
                        <:trigger>
                          <Threadline.OperatorSurface.UI.Actions.button>Hover Tooltip</Threadline.OperatorSurface.UI.Actions.button>
                        </:trigger>
                        Tooltip content
                      </Threadline.OperatorSurface.UI.Overlay.tooltip>

                      <Threadline.OperatorSurface.UI.Overlay.popover id="stress-popover">
                        <:trigger>
                          <Threadline.OperatorSurface.UI.Actions.button>Click Popover</Threadline.OperatorSurface.UI.Actions.button>
                        </:trigger>
                        Popover content
                      </Threadline.OperatorSurface.UI.Overlay.popover>

                      <Threadline.OperatorSurface.UI.Overlay.dropdown id="stress-dropdown">
                        <:trigger>
                          <span class="tl-button tl-button--secondary">Dropdown Menu</span>
                        </:trigger>
                        <button type="button" role="menuitem" class="tl-button tl-button--compact tl-button--secondary">
                          View stress details
                        </button>
                        <button type="button" role="menuitem" class="tl-button tl-button--compact tl-button--ghost">
                          Copy stress link
                        </button>
                      </Threadline.OperatorSurface.UI.Overlay.dropdown>
                    </div>
                    
                    <Threadline.OperatorSurface.UI.Overlay.accordion id="stress-accordion" title="Accordion Section">
                      Accordion inner content
                    </Threadline.OperatorSurface.UI.Overlay.accordion>
                    
                    <Threadline.OperatorSurface.UI.Page.tabs>
                      <:tab active>Tab 1</:tab>
                      <:tab>Tab 2</:tab>
                    </Threadline.OperatorSurface.UI.Page.tabs>

                    <Threadline.OperatorSurface.UI.Page.segmented_control>
                      <:segment active>Seg 1</:segment>
                      <:segment>Seg 2</:segment>
                    </Threadline.OperatorSurface.UI.Page.segmented_control>

                    <div class="tl-flex tl-gap-4">
                      <Threadline.OperatorSurface.UI.Actions.button phx-click={JS.push_focus() |> Threadline.OperatorSurface.UI.Overlay.show_modal("stress-modal")}>Show Modal</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Actions.button phx-click={JS.push_focus() |> Threadline.OperatorSurface.UI.Overlay.show_drawer("stress-drawer")}>Show Drawer</Threadline.OperatorSurface.UI.Actions.button>
                      
                      <Threadline.OperatorSurface.UI.Overlay.modal id="stress-modal">
                        <h2 id="stress-modal-title" class="tl-modal__title">Stress modal</h2>
                        <p id="stress-modal-description" class="tl-modal__body">
                          Modal content for rendered accessibility checks.
                        </p>
                        <Threadline.OperatorSurface.UI.Actions.button
                          variant="primary"
                          phx-click={Threadline.OperatorSurface.UI.Overlay.hide_modal("stress-modal")}
                          data-tl-initial-focus
                        >
                          Confirm stress modal
                        </Threadline.OperatorSurface.UI.Actions.button>
                      </Threadline.OperatorSurface.UI.Overlay.modal>
                      
                      <Threadline.OperatorSurface.UI.Overlay.drawer id="stress-drawer">
                        <h2 id="stress-drawer-title" class="tl-modal__title">Stress drawer</h2>
                        <p id="stress-drawer-description" class="tl-modal__body">
                          Drawer content for rendered accessibility checks.
                        </p>
                        <Threadline.OperatorSurface.UI.Actions.button
                          phx-click={Threadline.OperatorSurface.UI.Overlay.hide_drawer("stress-drawer")}
                          data-tl-initial-focus
                        >
                          Close stress drawer
                        </Threadline.OperatorSurface.UI.Actions.button>
                      </Threadline.OperatorSurface.UI.Overlay.drawer>
                      
                      <Threadline.OperatorSurface.UI.Actions.button
                        :if={@overlay_fixture_state != "removed"}
                        id="stress-edge-opener"
                        phx-click={JS.push_focus() |> Threadline.OperatorSurface.UI.Overlay.show_drawer("stress-edge")}
                      >Open overlay edge cases</Threadline.OperatorSurface.UI.Actions.button>
                      <Threadline.OperatorSurface.UI.Overlay.drawer id="stress-edge">
                        <h2 id="stress-edge-title">Overlay edge cases</h2>
                        <p id="stress-edge-description">Mounted patch state: <span id="stress-edge-state">{@overlay_fixture_state}</span></p>
                        <div :if={@overlay_fixture_state == "ready"}>
                          <Threadline.OperatorSurface.UI.Actions.button data-tl-initial-focus phx-click="overlay-fixture" phx-value-state="empty">Remove dialog controls</Threadline.OperatorSurface.UI.Actions.button>
                          <Threadline.OperatorSurface.UI.Actions.button phx-click="overlay-fixture" phx-value-state="disabled">Disable dialog controls</Threadline.OperatorSurface.UI.Actions.button>
                          <Threadline.OperatorSurface.UI.Actions.button phx-click="overlay-fixture" phx-value-state="removed">Remove opener</Threadline.OperatorSurface.UI.Actions.button>
                          <Threadline.OperatorSurface.UI.Overlay.dropdown id="stress-nested">
                            <:trigger>Drawer actions</:trigger>
                            <button type="button" role="menuitem">Inspect evidence</button>
                          </Threadline.OperatorSurface.UI.Overlay.dropdown>
                        </div>
                        <button :if={@overlay_fixture_state == "disabled"} disabled>Unavailable action</button>
                        <p :if={@overlay_fixture_state != "ready"} phx-mounted={JS.focus(to: "#stress-edge-content")} data-tl-patch-focus>
                          Dialog updated; press Escape to close.
                        </p>
                      </Threadline.OperatorSurface.UI.Overlay.drawer>

                      <Threadline.OperatorSurface.UI.Overlay.toast id="stress-toast" kind="info" title="Toast Title">
                        Toast message body
                      </Threadline.OperatorSurface.UI.Overlay.toast>
                    </div>
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
