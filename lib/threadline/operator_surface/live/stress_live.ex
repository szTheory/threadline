if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Phoenix.LiveView.JS
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
      # Ledger-backed product stories PLUS the graded-ladder oracle fixtures (D-12).
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

                <div :if={show_refute_matrix?(@selected_story)} class="tl-stress__ui-matrix tl-mt-8 tl-space-y-6" data-testid="refute-matrix">
                  <p style="font-size: var(--tl-font-size-label); font-weight: 600; color: var(--tl-color-muted); margin: 0 0 var(--tl-space-4) 0;">Phase 195 Refute Twin — design principle under test</p>

                  <%!-- Twin 1: Rhythm — section spacing (graded ladder; scenario content) --%>
                  <div :if={refute_twin(@selected_story) == :rhythm} class="tl-space-y-0">
                    <section
                      :for={{{heading, body}, i} <- Enum.with_index(refute_rhythm_sections(@selected_story))}
                      style={refute_rhythm_style(@selected_story, i)}
                      class="tl-stress-refute__section"
                    >
                      <h2 style="font-size: var(--tl-font-size-heading); font-weight: 600; margin: 0 0 var(--tl-space-2) 0;"><%= heading %></h2>
                      <p style="font-size: var(--tl-font-size-body); color: var(--tl-color-text); margin: 0;"><%= body %></p>
                    </section>
                  </div>

                  <%!-- Twin 2: Density (card-section-wrap) — card doctrine --%>
                  <div :if={refute_twin(@selected_story) == :density_card}>
                    <div style={refute_card_wrap_style(@selected_story)}>
                      <h2 style="font-size: var(--tl-font-size-title); font-weight: 700; margin: 0 0 var(--tl-space-3) 0;">Coverage summary</h2>
                      <p style="font-size: var(--tl-font-size-body); color: var(--tl-color-text); margin: 0 0 var(--tl-space-2) 0;">3 of 12 tables have trigger coverage. 9 tables are uncovered.</p>
                      <ul style="font-size: var(--tl-font-size-body); color: var(--tl-color-muted); padding-left: var(--tl-space-4); margin: 0;">
                        <li>audit_transactions — covered</li>
                        <li>audit_changes — covered</li>
                        <li>users — uncovered</li>
                      </ul>
                    </div>
                  </div>

                  <%!-- Twin 3: Hierarchy — visual weight progression --%>
                  <div :if={refute_twin(@selected_story) == :hierarchy} class="tl-space-y-3">
                    <div style={"padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);"}>
                      <p style={refute_hierarchy_meta_style(@selected_story)}>Operator / Timeline</p>
                      <h1 style={refute_hierarchy_title_style(@selected_story)}>Audit timeline</h1>
                      <h2 style={refute_hierarchy_subtitle_style(@selected_story)}>Last 30 days</h2>
                      <p style={refute_hierarchy_body_style(@selected_story)}>View, filter, and export change records for audited tables in this schema.</p>
                    </div>
                  </div>

                  <%!-- Twin 4: Typography — graded type-scale collapse (scenario copy) --%>
                  <div :if={refute_twin(@selected_story) == :typography} class="tl-space-y-3">
                    <div style="padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);">
                      <p
                        :for={{role, text} <- refute_typography_lines(@selected_story)}
                        style={refute_typography_role_style(@selected_story, role)}
                      ><%= text %></p>
                    </div>
                  </div>

                  <%!-- Twin 5: Brand fidelity — accent job discipline.
                       Polished: standard card (no structural accent stripe — thread-blue is
                       the default action color and needs no extra signaling).
                       Flawed: ember left-border accent on the action card — ember belongs to
                       diff-emphasis, not primary-action structure (wrong semantic job). --%>
                  <div :if={refute_twin(@selected_story) == :brand_fidelity} class="tl-space-y-3">
                    <% {brand_heading, brand_body, brand_note} = refute_brand_lines(@selected_story) %>
                    <div style={refute_action_card_style(@selected_story)}>
                      <h2 style="font-size: var(--tl-font-size-heading); font-weight: 600; margin: 0 0 var(--tl-space-3) 0; color: var(--tl-color-text);"><%= brand_heading %></h2>
                      <p style="font-size: var(--tl-font-size-body); color: var(--tl-color-text); margin: 0 0 var(--tl-space-4) 0;"><%= brand_body %></p>
                      <p :if={brand_note} style="font-size: var(--tl-font-size-sm); color: var(--tl-color-muted); margin: 0 0 var(--tl-space-4) 0;"><%= brand_note %></p>
                      <div style="display: flex; gap: var(--tl-space-3);">
                        <button style={refute_brand_button_style(@selected_story)} type="button">Export CSV</button>
                        <button style="background: transparent; color: var(--tl-color-muted); border: 1px solid var(--tl-color-border); padding: var(--tl-space-2) var(--tl-space-4); border-radius: var(--tl-radius-sm); font-size: var(--tl-font-size-label); cursor: pointer;" type="button">Cancel</button>
                      </div>
                    </div>
                  </div>

                  <%!-- Twin (new): Color contrast — one-hue-one-job discipline (graded) --%>
                  <div :if={refute_twin(@selected_story) == :color_contrast} class="tl-space-y-3">
                    <div style="padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);">
                      <div
                        :for={{label, text, role} <- refute_color_rows(@selected_story)}
                        style={"display: flex; gap: var(--tl-space-3); align-items: center; padding: var(--tl-space-2) 0 var(--tl-space-2) var(--tl-space-3); border-left: 3px solid #{refute_color_accent(@selected_story, role)}; margin-bottom: var(--tl-space-2);"}
                      >
                        <div style={"width: 10px; height: 10px; border-radius: 2px; background: #{refute_color_accent(@selected_story, role)};"}></div>
                        <span style="font-size: var(--tl-font-size-label); color: var(--tl-color-muted); min-width: 72px;"><%= label %></span>
                        <span style="font-size: var(--tl-font-size-body); color: var(--tl-color-text);"><%= text %></span>
                      </div>
                      <button style={"margin-top: var(--tl-space-2); background: #{refute_color_accent(@selected_story, :action)}; color: var(--tl-color-bg); border: none; padding: var(--tl-space-2) var(--tl-space-4); border-radius: var(--tl-radius-sm); font-size: var(--tl-font-size-label); font-weight: 600; cursor: pointer;"} type="button">Apply</button>
                    </div>
                  </div>

                  <%!-- Twin 6: Density (chrome-bloat) — signal-to-chrome ratio --%>
                  <div :if={refute_twin(@selected_story) == :density_chrome} class="tl-space-y-3">
                    <div style="padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);">
                      <h2 style="font-size: var(--tl-font-size-heading); font-weight: 600; margin: 0 0 var(--tl-space-4) 0;">Retention settings</h2>
                      <div class="tl-space-y-4">
                        <div>
                          <label style="display: block; font-size: var(--tl-font-size-label); font-weight: 600; margin-bottom: var(--tl-space-1); color: var(--tl-color-text);">Retention window</label>
                          <input type="text" value="90" style="width: 100%; padding: var(--tl-space-2) var(--tl-space-3); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-sm); background: var(--tl-color-bg); color: var(--tl-color-text); font-size: var(--tl-font-size-body); margin: 0;" />
                          <%= if refute_pole(@selected_story) == :flawed do %>
                            <p style="font-size: var(--tl-font-size-sm); color: var(--tl-color-muted); margin: var(--tl-space-1) 0 0 0;">Enter the number of days to retain audit records. Records older than this value will be permanently deleted when the next prune runs. The minimum is 7 days and the maximum is 3650 days (10 years).</p>
                          <% end %>
                        </div>
                        <div>
                          <label style="display: block; font-size: var(--tl-font-size-label); font-weight: 600; margin-bottom: var(--tl-space-1); color: var(--tl-color-text);">Prune schedule</label>
                          <input type="text" value="weekly" style="width: 100%; padding: var(--tl-space-2) var(--tl-space-3); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-sm); background: var(--tl-color-bg); color: var(--tl-color-text); font-size: var(--tl-font-size-body); margin: 0;" />
                          <%= if refute_pole(@selected_story) == :flawed do %>
                            <p style="font-size: var(--tl-font-size-sm); color: var(--tl-color-muted); margin: var(--tl-space-1) 0 0 0;">Choose how often to run automatic pruning. Daily runs every night at 2 AM UTC. Weekly runs every Sunday at 2 AM UTC. Monthly runs on the first of each month at 2 AM UTC.</p>
                          <% end %>
                        </div>
                        <div>
                          <label style="display: block; font-size: var(--tl-font-size-label); font-weight: 600; margin-bottom: var(--tl-space-1); color: var(--tl-color-text);">Notify on prune</label>
                          <input type="checkbox" style="margin: 0 var(--tl-space-2) 0 0;" />
                          <%= if refute_pole(@selected_story) == :flawed do %>
                            <span style="font-size: var(--tl-font-size-sm); color: var(--tl-color-muted);">When enabled, an email notification is sent to all operator-role users after each prune operation completes, listing the number of records deleted and the tables affected.</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </div>

                  <%!-- Twin 7: Veto-ordering — off-token raw-hex accent.
                       The diff rows use a border-left accent in ember (token) vs #e8a246 (raw hex).
                       Border colors are not captured in color_pairs; no WCAG contrast violation.
                       Plan 06 token-parity veto detects the raw-hex in the flawed pole's DOM. --%>
                  <div :if={refute_twin(@selected_story) == :veto_ordering} class="tl-space-y-3">
                    <div style="padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);">
                      <h2 style="font-size: var(--tl-font-size-heading); font-weight: 600; margin: 0 0 var(--tl-space-3) 0; color: var(--tl-color-text);">Row diff</h2>
                      <p style="font-size: var(--tl-font-size-body); color: var(--tl-color-text); margin: 0 0 var(--tl-space-3) 0;">Changed field values for this audit event.</p>
                      <div style="display: flex; gap: var(--tl-space-2); flex-direction: column;">
                        <div style={refute_veto_accent_style(@selected_story)}>
                          <span style="font-size: var(--tl-font-size-label); color: var(--tl-color-muted); min-width: 80px;">email</span>
                          <span style="font-size: var(--tl-font-size-body); color: var(--tl-color-text);">before@example.invalid → after@example.invalid</span>
                        </div>
                        <div style={refute_veto_accent_style(@selected_story)}>
                          <span style="font-size: var(--tl-font-size-label); color: var(--tl-color-muted); min-width: 80px;">role</span>
                          <span style="font-size: var(--tl-font-size-body); color: var(--tl-color-text);">member → admin</span>
                        </div>
                      </div>
                    </div>
                  </div>
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
                      <Threadline.OperatorSurface.UI.field id="stress-search" name="search_field" label="Search Field" type="search" value="audit changes" />
                      <Threadline.OperatorSurface.UI.field id="stress-checkbox" name="checkbox_field" label="Checkbox Field" type="checkbox" value="true" />
                      <Threadline.OperatorSurface.UI.field id="stress-radio" name="radio_field" label="Radio Field" type="radio" value="true" />
                      <Threadline.OperatorSurface.UI.field id="stress-switch" name="switch_field" label="Switch Field" type="switch" value="true" />
                      <Threadline.OperatorSurface.UI.field id="stress-date" name="date_field" label="Date Field" type="date" value="2026-06-16" />
                      <Threadline.OperatorSurface.UI.field id="stress-error" name="error_field" label="Error Field" type="text" value="Bad input" errors={["This field is required"]} help_text="Please enter a valid value." />
                      <Threadline.OperatorSurface.UI.field id="stress-disabled" name="disabled_field" label="Disabled Field" type="text" value="Can't touch this" disabled />
                      <div class="tl-field">
                        <label class="tl-label" for="stress-combobox">Combobox Field</label>
                        <Threadline.OperatorSurface.UI.combobox
                          id="stress-combobox"
                          name="combobox_field"
                          value="Option 1"
                          options={[{"Option 1", "option_1"}, {"Option 2", "option_2"}]}
                        />
                      </div>
                      <Threadline.OperatorSurface.UI.error_summary
                        id="stress-error-summary"
                        errors={[{"stress-error", "Error Field is required"}]}
                      />
                    </div>
                  </div>

                  <div class="tl-space-y-4">
                    <h4>Data Panel</h4>
                    <Threadline.OperatorSurface.UI.data_panel id="stress-data-panel" aria-label="Stress data panel">
                      <:data>
                        <Threadline.OperatorSurface.UI.data_table
                          rows={[
                            %{status: "ready", rows: "24", at: "2026-06-16T12:00:00Z"}
                          ]}
                        >
                          <:col :let={r} label="Status"><%= r.status %></:col>
                          <:col :let={r} label="Rows"><%= r.rows %></:col>
                          <:col :let={r} label="Date"><%= r.at %></:col>
                        </Threadline.OperatorSurface.UI.data_table>
                      </:data>
                    </Threadline.OperatorSurface.UI.data_panel>
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
                          <span class="tl-button tl-button--secondary">Dropdown Menu</span>
                        </:trigger>
                        <button type="button" role="menuitem" class="tl-button tl-button--compact tl-button--secondary">
                          View stress details
                        </button>
                        <button type="button" role="menuitem" class="tl-button tl-button--compact tl-button--ghost">
                          Copy stress link
                        </button>
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
                      <Threadline.OperatorSurface.UI.button phx-click={JS.push_focus() |> Threadline.OperatorSurface.UI.show_modal("stress-modal")}>Show Modal</Threadline.OperatorSurface.UI.button>
                      <Threadline.OperatorSurface.UI.button phx-click={JS.push_focus() |> Threadline.OperatorSurface.UI.show_drawer("stress-drawer")}>Show Drawer</Threadline.OperatorSurface.UI.button>
                      
                      <Threadline.OperatorSurface.UI.modal id="stress-modal">
                        <h2 id="stress-modal-title" class="tl-modal__title">Stress modal</h2>
                        <p id="stress-modal-description" class="tl-modal__body">
                          Modal content for rendered accessibility checks.
                        </p>
                        <Threadline.OperatorSurface.UI.button
                          variant="primary"
                          phx-click={Threadline.OperatorSurface.UI.hide_modal("stress-modal")}
                          data-tl-initial-focus
                        >
                          Confirm stress modal
                        </Threadline.OperatorSurface.UI.button>
                      </Threadline.OperatorSurface.UI.modal>
                      
                      <Threadline.OperatorSurface.UI.drawer id="stress-drawer">
                        <h2 id="stress-drawer-title" class="tl-modal__title">Stress drawer</h2>
                        <p id="stress-drawer-description" class="tl-modal__body">
                          Drawer content for rendered accessibility checks.
                        </p>
                        <Threadline.OperatorSurface.UI.button
                          phx-click={Threadline.OperatorSurface.UI.hide_drawer("stress-drawer")}
                          data-tl-initial-focus
                        >
                          Close stress drawer
                        </Threadline.OperatorSurface.UI.button>
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

    # Phase 195 Plan 03: refute-twin render helpers.
    # Each twin pair (polished + flawed) renders via show_refute_matrix? + a per-twin block.

    defp show_refute_matrix?(%{category: "refute"}), do: true
    defp show_refute_matrix?(_story), do: false

    defp refute_twin(%{data: data}) when is_map(data), do: Map.get(data, :twin)
    defp refute_twin(_), do: nil

    defp refute_pole(%{data: data}) when is_map(data), do: Map.get(data, :pole)
    defp refute_pole(_), do: nil

    # Phase 195 D-12: severity rung for a graded-ladder story. Binary twins carry no
    # :rung, so they map back to the two extremes (flawed → :r2 "bad", polished → :r4)
    # keeping the existing pole render byte-identical.
    defp refute_rung(%{data: %{rung: rung}}) when not is_nil(rung), do: rung
    defp refute_rung(%{data: %{pole: :flawed}}), do: :r2
    defp refute_rung(_), do: :r4

    # Twin 1: Rhythm — the flaw is UNEVEN vertical cadence, NOT spacing magnitude.
    # Uniform spacing at any size still reads as coherent rhythm (the critic correctly
    # rates it fine), so severity is graded by how ERRATIC the between-section gaps are:
    #   r4 even (coherent) → r3 one gap off → r2 alternating → r1 wildly erratic.
    # Erratic gaps break BOTH vertical_cadence_coherence AND grouping_by_proximity
    # (related items no longer consistently closer than unrelated). All gaps are on-grid
    # --tl-space-* tokens, so every rung passes MODE A + MODE B (gestalt flaw only).
    defp refute_rhythm_style(story, index) do
      gap = rhythm_gap(refute_rung(story), rem(index, 3))

      "padding: var(--tl-space-3) 0 0 0; margin-bottom: #{gap}; border-bottom: 1px solid var(--tl-color-border);"
    end

    # Per-(rung, section-index) between-section gap. Variance across the sequence is the
    # cadence signal, spread so all four rungs separate (the critic saturates to "fail"
    # if bad ≈ broken, so bad must stay readable):
    #   r4 [16,16,16] even · r3 [16,24,16] one mild bump · r2 [12,32,16] one clear
    #   deviation (still breathable) · r1 [4,48,8] cramped-then-floating (broken).
    defp rhythm_gap(:r4, _), do: "var(--tl-space-4)"
    defp rhythm_gap(:r3, 1), do: "var(--tl-space-6)"
    defp rhythm_gap(:r3, _), do: "var(--tl-space-4)"
    defp rhythm_gap(:r2, 0), do: "var(--tl-space-3)"
    defp rhythm_gap(:r2, 1), do: "var(--tl-space-8)"
    defp rhythm_gap(:r2, _), do: "var(--tl-space-4)"
    defp rhythm_gap(:r1, 0), do: "var(--tl-space-1)"
    defp rhythm_gap(:r1, 1), do: "var(--tl-space-12)"
    defp rhythm_gap(:r1, _), do: "var(--tl-space-2)"

    # Distinct per-scenario content for the graded rhythm ladder (avoids pseudo-
    # replication: each scenario is genuinely different operator copy). Binary twins and
    # any unlisted scenario fall back to the original three-section reference content.
    defp refute_rhythm_sections(story) do
      case Map.get(story.data, :scenario) do
        "coverage" ->
          [
            {"Trigger coverage", "3 of 12 audited tables have live trigger coverage."},
            {"Uncovered", "9 tables have no capture wired — enable before the next audit."},
            {"Last checked", "Coverage recomputed 2026-07-01 during the nightly sweep."}
          ]

        "retention" ->
          [
            {"Retention window", "Audit records are retained for 90 days by policy."},
            {"Next prune", "The scheduled prune runs 2026-09-30 at 02:00 UTC."},
            {"Redaction", "2 fields are masked at rest under the current redaction rule."}
          ]

        "exports" ->
          [
            {"Recent exports", "4 CSV exports generated in the last 30 days."},
            {"Largest", "The March export covered 18,204 change records."},
            {"Delivery", "Exports are delivered to the operator inbox, never emailed."}
          ]

        "evidence" ->
          [
            {"Evidence status", "Proof records are current as of 2026-07-01."},
            {"Open chains", "1 evidence chain awaits a countersignature."},
            {"Integrity", "All captured hashes verified on the last integrity run."}
          ]

        "actor" ->
          [
            {"Actor", "Changes attributed to admin@example.com via the console."},
            {"Intent", "Role change recorded with an explicit operator reason."},
            {"Correlation", "Tied to request req_9f2 across the job boundary."}
          ]

        _ ->
          [
            {"Audit activity", "24 changes captured in the last 30 days for this schema."},
            {"Evidence status", "Proof records current as of 2026-07-01."},
            {"Retention", "Retention window: 90 days. Next prune: 2026-09-30."}
          ]
      end
    end

    # Twin 2: Density (card-section-wrap) — polished is a plain div, flaw wraps in .tl-card styles.
    # Nesting depth stays ≤ 2 (content in card); passes the depth-3 ceiling.
    defp refute_card_wrap_style(story) do
      case refute_pole(story) do
        :flawed ->
          "padding: var(--tl-space-4); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md); background: var(--tl-color-bg);"

        _ ->
          "padding: var(--tl-space-4);"
      end
    end

    # Twin 3: Hierarchy — polished has clear weight/size progression; flaw shares font-weight:500.
    # Type-size count stays above the floor in both poles (three distinct sizes used).
    defp refute_hierarchy_meta_style(story) do
      case refute_pole(story) do
        :flawed ->
          # label (14px): browser default p margin = 14px (off spacing scale) — zero top explicitly
          "font-size: var(--tl-font-size-label); font-weight: 500; color: var(--tl-color-muted); margin: 0 0 var(--tl-space-1) 0;"

        _ ->
          # xs (12px): browser default p margin = 12px (on scale), still zero for consistency
          "font-size: var(--tl-font-size-xs); font-weight: 400; color: var(--tl-color-muted); margin: 0 0 var(--tl-space-1) 0; text-transform: uppercase; letter-spacing: 0.04em;"
      end
    end

    defp refute_hierarchy_title_style(story) do
      case refute_pole(story) do
        :flawed ->
          # h1 title (24px): browser default h1 margin-top ~16px — zero explicitly
          "font-size: var(--tl-font-size-title); font-weight: 500; color: var(--tl-color-text); margin: 0 0 var(--tl-space-1) 0;"

        _ ->
          "font-size: var(--tl-font-size-title); font-weight: 700; color: var(--tl-color-text); margin: 0 0 var(--tl-space-1) 0;"
      end
    end

    defp refute_hierarchy_subtitle_style(story) do
      case refute_pole(story) do
        :flawed ->
          # h2 heading (20px): browser default margin-top = 0.83em = 16.6px (off scale) — zero explicitly
          "font-size: var(--tl-font-size-heading); font-weight: 500; color: var(--tl-color-text); margin: 0 0 var(--tl-space-2) 0;"

        _ ->
          # h2 body (16px): browser default margin-top = 0.83em = 13.28px (off scale) — zero explicitly
          "font-size: var(--tl-font-size-body); font-weight: 500; color: var(--tl-color-muted); margin: 0 0 var(--tl-space-2) 0;"
      end
    end

    defp refute_hierarchy_body_style(story) do
      case refute_pole(story) do
        :flawed ->
          # p heading (20px): browser default p margin = 20px (on scale) — passes, but zero for clarity
          "font-size: var(--tl-font-size-heading); font-weight: 500; color: var(--tl-color-text); margin: 0;"

        _ ->
          # p body (16px): browser default p margin = 16px (on scale) — passes, but zero for clarity
          "font-size: var(--tl-font-size-body); font-weight: 400; color: var(--tl-color-text); margin: 0;"
      end
    end

    # Twin 4: Typography — graded type-scale collapse. r4 renders a full 6-step scale
    # (distinct roles, size tracks importance); worse rungs progressively collapse the
    # scale so BOTH scored dimensions degrade together — role_differentiation AND
    # scale_expresses_hierarchy — keeping min()-rollup signal on both dims (the rhythm
    # lesson: never leave a dimension as a noise floor). r1 is near-flat (no hierarchy).
    # Every size is a --tl-font-size-* token (type-size count stays above the MODE-B floor).
    @typo_scale %{
      r4: %{
        display: {"display", 700},
        title: {"title", 600},
        heading: {"heading", 600},
        body: {"body", 400},
        label: {"label", 500},
        meta: {"xs", 400}
      },
      r3: %{
        display: {"title", 700},
        title: {"title", 600},
        heading: {"heading", 500},
        body: {"body", 400},
        label: {"label", 500},
        meta: {"sm", 400}
      },
      r2: %{
        display: {"heading", 600},
        title: {"heading", 500},
        heading: {"body", 500},
        body: {"body", 400},
        label: {"sm", 500},
        meta: {"sm", 400}
      },
      r1: %{
        display: {"body", 500},
        title: {"body", 500},
        heading: {"body", 500},
        body: {"body", 400},
        label: {"sm", 400},
        meta: {"sm", 400}
      }
    }

    defp refute_typography_role_style(story, role) do
      {size, weight} = @typo_scale |> Map.fetch!(refute_rung(story)) |> Map.fetch!(role)

      "font-size: var(--tl-font-size-#{size}); font-weight: #{weight}; color: var(--tl-color-text); margin: 0 0 var(--tl-space-2) 0;"
    end

    # Distinct per-scenario copy across the six type roles (pseudo-replication honesty).
    defp refute_typography_lines(story) do
      {display, body, meta} =
        case Map.get(story.data, :scenario) do
          "coverage" ->
            {"Coverage", "3 of 12 audited tables have live trigger coverage.",
             "Recomputed 2026-07-01"}

          "retention" ->
            {"Retention", "Records are retained for 90 days; next prune 2026-09-30.", "Policy v4"}

          "exports" ->
            {"Exports", "4 CSV exports generated in the last 30 days.", "Largest 18,204 rows"}

          "evidence" ->
            {"Evidence", "Proof records current; 1 chain awaits countersignature.",
             "Integrity OK"}

          "actor" ->
            {"Actor", "Change attributed to admin@example.com via console.", "req_9f2"}

          _ ->
            {"Audit activity", "24 changes captured in the last 30 days for this schema.",
             "Updated 2026-07-01"}
        end

      [
        {:display, display},
        {:title, "Operator surface"},
        {:heading, "Last 30 days"},
        {:body, body},
        {:label, "STATUS"},
        {:meta, meta}
      ]
    end

    # Twin 5: Brand fidelity — accent job discipline.
    # Polished: standard action card (no structural accent stripe). Thread-blue is the
    # default action color and needs no additional accent signaling.
    # Flawed: ember left-border stripe on the action card. Ember (--tl-color-ember) belongs
    # to diff-emphasis / change-signal jobs, not primary-action structure. Wrong semantic job.
    # Border-left color is not captured in color_pairs, so no MODE-A WCAG violation fires.
    # The semantic-role flaw is visible to the gestalt lens but passes all mechanical gates.
    # Graded card frame: worse rungs pile brand accent tokens onto jobs they don't own
    # (ember = diff-emphasis, iris = secondary highlight — neither is action-card chrome).
    defp refute_action_card_style(story) do
      base =
        "padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);"

      case refute_rung(story) do
        :r4 ->
          base

        :r3 ->
          base <> " border-left: 3px solid var(--tl-color-ember);"

        :r2 ->
          base <> " border-left: 3px solid var(--tl-color-ember);"

        :r1 ->
          base <>
            " border-left: 5px solid var(--tl-color-ember); border-top: 3px solid var(--tl-color-iris);"
      end
    end

    # Primary action button: thread-blue owns the action job; worse rungs mis-job ember onto it.
    defp refute_brand_button_style(story) do
      bg =
        case refute_rung(story) do
          :r4 -> "var(--tl-color-thread-blue)"
          :r3 -> "var(--tl-color-thread-blue)"
          _ -> "var(--tl-color-ember)"
        end

      "background: #{bg}; color: var(--tl-color-bg); border: none; padding: var(--tl-space-2) var(--tl-space-4); border-radius: var(--tl-radius-sm); font-size: var(--tl-font-size-label); font-weight: 600; cursor: pointer;"
    end

    # Copy voice by (rung, scenario): r4/r3 operational; r2 adds a chatty line; r1 is
    # marketing/apologetic + emoji (off the Threadline register). Drives register_voice_fit.
    defp refute_brand_lines(story) do
      {heading, body} =
        case Map.get(story.data, :scenario) do
          "coverage" ->
            {"Coverage summary", "3 of 12 audited tables have trigger coverage."}

          "retention" ->
            {"Retention settings", "Records retained 90 days; next prune 2026-09-30."}

          "evidence" ->
            {"Evidence chain", "Proof records current as of 2026-07-01."}

          "actor" ->
            {"Actor detail", "Change attributed to admin@example.com via console."}

          "timeline" ->
            {"Audit timeline", "24 changes captured in the last 30 days."}

          _ ->
            {"Export audit records", "Download a CSV of audit changes for the last 90 days."}
        end

      note =
        case refute_rung(story) do
          :r2 ->
            "This should only take a moment — thanks for your patience!"

          :r1 ->
            "You're all set! Everything looks great. 🎉 Powerful, seamless audit exports await."

          _ ->
            nil
        end

      {heading, body, note}
    end

    # Twin (new): Color contrast — one-hue-one-job discipline (graded). Degrades BOTH scored
    # dims together: color_as_signal (does colour map to meaning?) AND accent_job_discipline
    # (is each hue reserved for its documented job?). r4 = one hue per job (blue=action,
    # ember=change, cyan=info); r3 mild creep; r2 reuses one hue across two jobs; r1 scrambles
    # every hue so colour stops meaning anything. Accents are border-left + a plain <div>
    # swatch (neither is in the color_pairs text selector) so every rung passes WCAG MODE-A —
    # this is a gestalt colour-semantics flaw, not a contrast violation (D-03 partition).
    defp refute_color_accent(story, role) do
      case {refute_rung(story), role} do
        {:r4, :action} -> "var(--tl-color-thread-blue)"
        {:r4, :change} -> "var(--tl-color-ember)"
        {:r4, :info} -> "var(--tl-color-signal-cyan)"
        {:r3, :action} -> "var(--tl-color-thread-blue)"
        {:r3, :change} -> "var(--tl-color-ember)"
        {:r3, :info} -> "var(--tl-color-iris)"
        {:r2, :action} -> "var(--tl-color-thread-blue)"
        {:r2, :change} -> "var(--tl-color-ember)"
        {:r2, :info} -> "var(--tl-color-thread-blue)"
        {:r1, :action} -> "var(--tl-color-signal-cyan)"
        {:r1, :change} -> "var(--tl-color-iris)"
        {:r1, :info} -> "var(--tl-color-ember)"
      end
    end

    # Distinct per-scenario rows for the colour-signal twin (pseudo-replication honesty).
    defp refute_color_rows(story) do
      case Map.get(story.data, :scenario) do
        "coverage" ->
          [
            {"Action", "Enable trigger coverage", :action},
            {"Change", "3 tables newly covered", :change},
            {"Info", "9 tables remain uncovered", :info}
          ]

        "retention" ->
          [
            {"Action", "Run prune now", :action},
            {"Change", "Window 120 → 90 days", :change},
            {"Info", "Next prune 2026-09-30", :info}
          ]

        "diff" ->
          [
            {"Action", "Approve change", :action},
            {"Change", "role: member → admin", :change},
            {"Info", "Actor admin@example.com", :info}
          ]

        "evidence" ->
          [
            {"Action", "Countersign chain", :action},
            {"Change", "Hash re-verified", :change},
            {"Info", "1 chain pending", :info}
          ]

        "actor" ->
          [
            {"Action", "Attribute change", :action},
            {"Change", "Intent recorded", :change},
            {"Info", "Correlation req_9f2", :info}
          ]

        _ ->
          [
            {"Action", "Export audit records", :action},
            {"Change", "24 changes captured", :change},
            {"Info", "Retention window 90 days", :info}
          ]
      end
    end

    # Twin 7: Veto-ordering — off-token raw-hex accent.
    # Each diff row is wrapped in a div with a left-border accent: ember token (polished) vs
    # raw hex #e8a246 (flawed). Border-left is not in the color_pairs selector so no WCAG
    # contrast MODE-A violation fires here. The raw hex trips the token-parity veto at the
    # panel layer (Plan 06), which fires AFTER mechanical gates pass (correct veto ordering).
    defp refute_veto_accent_style(story) do
      case refute_pole(story) do
        :flawed ->
          # off-token raw hex (Ember-alike; not a CSS variable reference) — veto fires in Plan 06
          "display: flex; gap: var(--tl-space-3); align-items: center; padding-left: var(--tl-space-2); border-left: 3px solid #e8a246; margin-bottom: var(--tl-space-2);"

        _ ->
          "display: flex; gap: var(--tl-space-3); align-items: center; padding-left: var(--tl-space-2); border-left: 3px solid var(--tl-color-ember); margin-bottom: var(--tl-space-2);"
      end
    end
  end
end
