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

    alias Phoenix.LiveView.JS
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

                <div :if={show_ui_matrix?(@selected_story)} class="tl-stress__ui-matrix tl-mt-8 tl-space-y-8">
                  <h3>Primitives Matrix</h3>
                  
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
                      
                      <Threadline.OperatorSurface.UI.Overlay.toast id="stress-toast" kind="info" title="Toast Title">
                        Toast message body
                      </Threadline.OperatorSurface.UI.Overlay.toast>
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
