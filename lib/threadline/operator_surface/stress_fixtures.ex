defmodule Threadline.OperatorSurface.StressFixtures do
  @moduledoc false

  @required_cases ~w(
    empty
    error
    high_count
    long_id
    long_string
    many
    mixed_severity
    non_ascii
    null_fields
    one
    pagination_boundary
    permission_denied
    reconnecting
    stale
    timezone_boundary
    warning
    zero_count
  )

  @theme_modes ["dark", "light", "system"]
  @viewports [320, 375, 768, 1024, 1280, 1440]

  @foundation_stories [
    {"foundation.color", "foundation.color.tokens", "Color token groups", ["mixed_severity"]},
    {"foundation.density", "foundation.density.scale", "Density and control rhythm", ["many"]},
    {"foundation.motion", "foundation.motion.tokens", "Motion duration and reduced-motion lane",
     ["stale", "reconnecting"]},
    {"foundation.radius", "foundation.radius.tokens", "Radius scale", ["one"]},
    {"foundation.shadow", "foundation.shadow.tokens", "Shadow and elevation scale", ["warning"]},
    {"foundation.spacing", "foundation.spacing.tokens", "Spacing scale", ["many"]},
    {"foundation.typography", "foundation.typography.tokens", "Typography scale",
     ["long_string", "non_ascii"]},
    {"foundation.z-index", "foundation.z-index.tokens", "Layering scale",
     ["high_count", "long_id"]}
  ]

  @primitive_stories [
    {"primitive.icon.reserved", "primitive.icon.reserved", "Icon primitive reserved baseline"},
    {"primitive.logo.reserved", "primitive.logo.reserved", "Logo primitive reserved baseline"},
    {"primitive.unsupported-view.reserved", "primitive.unsupported-view.reserved",
     "Unsupported view primitive reserved baseline"}
  ]

  @current_form_control_stories [
    {"form-control.checkbox.current", "form.checkbox.current",
     "Checkbox control current baseline", ["one", "disabled", "error"]},
    {"form-control.date-range.current", "form.date_range.current",
     "Date range control current baseline", ["one", "disabled", "error"]},
    {"form-control.input.current", "form.input.current", "Input control current baseline",
     ["one", "disabled", "error"]},
    {"form-control.radio.current", "form.radio.current", "Radio control current baseline",
     ["one", "disabled", "error"]},
    {"form-control.search.current", "form.search.current", "Search control current baseline",
     ["one", "disabled", "error"]},
    {"form-control.select.current", "form.select.current", "Select control current baseline",
     ["one", "disabled", "error"]},
    {"form-control.textarea.current", "form.textarea.current",
     "Textarea control current baseline", ["one", "disabled", "error"]}
  ]

  # GROUP-01: the 12 recurring component configurations audited as cohesive units on
  # /audit/__stress. The 6 prior reserved baselines (action-bar, filter-bar, kv-list,
  # pagination, status-strip, timeline-list) are remapped/absorbed into these 12 — see
  # the per-story `absorbs` notes below. Each carries a `surface` tag (`:live` |
  # `:reference`) so Phase 178 (page-stress) knows which groups ship on a real page (D-07).
  # Reference-only configs (drawer+form, tabs+subviews) have no live page consumer this
  # phase — the stress story IS the canonical reference assembly (D-06b / Deferred Ideas).
  @group_stories [
    {"group.page-header.current", "group.page_header.current",
     "Page header + actions + breadcrumbs", :live},
    {"group.toolbar.current", "group.toolbar.current",
     "Toolbar + search + filters + sort (absorbs filter-bar)", :live},
    {"group.data-panel.current", "group.data_panel.current",
     "Table + empty + loading + pagination (absorbs pagination, timeline-list)", :live},
    {"group.stats-chart-table.current", "group.stats_chart_table.current",
     "Stat cards + chart + table (absorbs status-strip)", :live},
    {"group.detail-header.current", "group.detail_header.current",
     "Detail header + metadata + actions (absorbs kv-list)", :live},
    {"group.modal-destructive.current", "group.modal_destructive.current",
     "Modal confirm + destructive action", :live},
    {"group.drawer-form.reference", "group.drawer_form.reference",
     "Drawer + form (reference-only — no live page, D-07)", :reference},
    {"group.toast-update.current", "group.toast_update.current", "Toast + state update", :live},
    {"group.tabs-subviews.reference", "group.tabs_subviews.reference",
     "Tabs + subviews (reference-only — no live page, D-07)", :reference},
    {"group.empty-cta.current", "group.empty_cta.current",
     "Empty + CTA (absorbs action-bar action-cluster semantics)", :live},
    {"group.permission-denied.current", "group.permission_denied.current",
     "Permission denied group", :live},
    {"group.offline.current", "group.offline.current",
     "Reconnect / offline banner + disabled actions", :live}
  ]

  # PAGE-01 / D-04: each of the 11 operator pages is audited across the 7 audit
  # paths (happy/empty/loading/error/permission/boundary/advanced) via deterministic
  # DB-free static fixtures on /audit/__stress. The 11 prior `page.<x>.reserved`
  # baselines are CONVERTED here (no orphaned reserved id — the 177-05 group
  # precedent): each page subject becomes 7 fixture-backed CURRENT path stories, and
  # the two pre-existing baselines (page.home.happy, page.timeline.empty) are
  # absorbed as the home/happy and timeline/empty cells.
  #
  # Honesty contract (D-01/D-03): this Tier A cartesian proves the FULL structural
  # matrix (page × path × theme × viewport renders, carries data-state, no
  # loud-fail). The genuinely-live loading/reconnect flows are proven by the
  # real-LiveView Tier B specs (Plans 01/05), NOT these static fixtures.
  @page_subjects ~w(
    actor
    coverage
    evidence
    exports
    home
    redaction
    retention
    row-history
    shell
    timeline
    transaction
  )

  # The 7 audit paths each page is fixture-backed across, mapped onto the
  # @required_cases ugly-data vocabulary. Each path's cases satisfy the page-story
  # conversion contract (stress_fixtures_test PAGE-01 @page_path_cases).
  @page_paths [
    {"happy", ["one", "many", "mixed_severity"]},
    {"empty", ["empty", "zero_count"]},
    {"loading", ["reconnecting", "stale"]},
    {"error", ["error"]},
    {"permission", ["permission_denied"]},
    {"boundary", ["pagination_boundary", "timezone_boundary"]},
    {"advanced", ["non_ascii", "null_fields"]}
  ]

  # The two pre-existing fixture-backed baselines (Phase 171, score 62). Their
  # ledger ids/fixture_keys are reused verbatim as the home/happy and
  # timeline/empty cells so no id is orphaned.
  @page_baseline_cells %{
    {"home", "happy"} => "page.home.happy",
    {"timeline", "empty"} => "page.timeline.empty"
  }

  @state_stories [
    {"state.empty", "state.empty", "Empty audit result", ["empty", "zero_count"]},
    {"state.many", "state.many", "Dense audit result list", ["many", "high_count"]},
    {"state.mixed-severity", "state.mixed_severity", "Mixed severity audit result",
     ["mixed_severity", "error", "warning"]},
    {"state.null-fields", "state.null_fields", "Null field rendering", ["null_fields"]},
    {"state.one", "state.one", "Single audit result", ["one"]},
    {"state.pagination-boundary", "state.pagination_boundary", "Pagination boundary",
     ["pagination_boundary"]},
    {"state.stale-reconnecting", "state.stale_reconnecting", "Stale and reconnecting state",
     ["stale", "reconnecting"]},
    {"state.timezone-boundary", "state.timezone_boundary", "Timezone boundary state",
     ["timezone_boundary"]}
  ]

  # Phase 176 data-display components + DATA-03 data-state taxonomy. Each new UI unit
  # (ref/kv/data_table) and each typed data-state is audited in isolation on /audit/__stress
  # (the 173/174/175 pattern) before any page adopts it.
  @data_display_stories [
    {"state.ref.current", "state.ref.current", "Forensic ref copy affordance",
     ["long_id", "non_ascii"]},
    {"state.kv.current", "state.kv.current", "Single-record key/value display", ["one"]},
    {"state.data-table.current", "state.data_table.current", "Responsive data table",
     ["many", "mixed_severity"]},
    {"state.loading", "state.loading", "Loading data-state", ["one"]},
    {"state.stale", "state.stale", "Stale banner above last-good data", ["stale"]},
    {"state.no-data", "state.no_data", "No-data (filter excluded) data-state", ["empty"]},
    {"state.permission", "state.permission", "Permission-denied data-state",
     ["permission_denied"]},
    {"state.unavailable-down", "state.unavailable_down", "Unavailable — source down data-state",
     ["error"]},
    {"state.unavailable-redacted", "state.unavailable_redacted",
     "Unavailable — redacted data-state", ["non_ascii"]},
    {"state.unavailable-pruned", "state.unavailable_pruned", "Unavailable — pruned data-state",
     ["timezone_boundary"]}
  ]

  @reserved_copy "This baseline records the current issue; do not fix it in Phase 171."

  @doc """
  Returns every canonical stress story sorted by string ID.
  """
  def all do
    stories()
  end

  @doc """
  Looks up a stress story by stable string ID.
  """
  def by_id(id) when is_binary(id) do
    case Map.fetch(story_index(), id) do
      {:ok, story} -> {:ok, story}
      :error -> :error
    end
  end

  def by_id(_), do: :error

  @doc """
  Returns sorted category names present in the registry.
  """
  def categories do
    stories()
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def required_cases, do: @required_cases
  def theme_modes, do: @theme_modes
  def viewports, do: @viewports

  @doc """
  Returns component-ready assigns for a story or story ID.
  """
  def assigns_for(id) when is_binary(id) do
    case by_id(id) do
      {:ok, story} -> assigns_for(story)
      :error -> {:error, :unknown_story}
    end
  end

  def assigns_for(%{id: "primitive.surface-header.current"}) do
    {:ok,
     %{
       coverage: %{uncovered_count: 0, last_checked_at: ~U[2026-06-14 00:00:00Z]},
       base_path: "/audit",
       error: nil,
       coverage_enabled: true,
       policy_enabled: true,
       evidence_enabled: true,
       exports_enabled: true,
       current: :start,
       scoped: true
     }}
  end

  def assigns_for(%{id: "state.permission-denied"}) do
    {:ok,
     %{
       title: "Audit object access needed",
       body:
         "You do not have access to this audit object. The audit object exists; your account needs `audit.read`.",
       fallback_label: "Fixture",
       fallback_value: "state.permission_denied",
       base_path: "/audit"
     }}
  end

  def assigns_for(%{status: "reserved"} = story) do
    phase = story.metadata.reserved_for_phase

    {:ok,
     %{
       title: "Reserved stress story",
       body: "Reserved for Phase #{phase}. #{@reserved_copy}",
       fallback_label: "Story",
       fallback_value: story.id,
       base_path: "/audit"
     }}
  end

  def assigns_for(%{} = story) do
    {:ok,
     %{
       title: story.scenario,
       body: Map.get(story.data, :summary, "Synthetic stress fixture for #{story.id}."),
       fallback_label: "Fixture",
       fallback_value: story.fixture_key,
       base_path: "/audit"
     }}
  end

  def assigns_for(_), do: {:error, :unknown_story}

  defp stories do
    [
      foundation_story_maps(),
      current_primitive_story(),
      reserved_story_maps(@primitive_stories, "primitive", 171),
      form_control_story_maps(),
      group_story_maps(),
      page_story_maps(),
      state_story_maps(),
      data_display_story_maps(),
      permission_denied_story(),
      folded_todo_stories()
    ]
    |> List.flatten()
    |> Enum.sort_by(& &1.id)
  end

  defp story_index do
    Map.new(stories(), fn story -> {story.id, story} end)
  end

  defp foundation_story_maps do
    Enum.map(@foundation_stories, fn {id, fixture_key, scenario, cases} ->
      story(%{
        id: id,
        kind: "foundation",
        category: "foundation",
        scenario: scenario,
        fixture_key: fixture_key,
        cases: cases,
        status: "baseline",
        data: %{
          token_group: String.replace_prefix(id, "foundation.", ""),
          sample_values: synthetic_values(cases),
          summary: "Synthetic #{scenario} pressure fixture."
        }
      })
    end)
  end

  defp current_primitive_story do
    story(%{
      id: "primitive.surface-header.current",
      kind: "primitive",
      category: "primitive",
      scenario: "Current operator surface header",
      fixture_key: "primitive.surface_header.current",
      cases: ["one"],
      status: "current",
      data: %{
        base_path: "/audit",
        current: "start",
        scoped: true,
        summary: "Synthetic current shell header with enabled operator destinations."
      },
      metadata: %{component: "SurfaceHeader.surface_header/1"}
    })
  end

  defp form_control_story_maps do
    Enum.map(@current_form_control_stories, fn {id, fixture_key, scenario, cases} ->
      story(%{
        id: id,
        kind: "form_control",
        category: "form_control",
        scenario: scenario,
        fixture_key: fixture_key,
        cases: cases,
        status: "current",
        data: %{
          summary: "Synthetic #{scenario} pressure fixture."
        }
      })
    end)
  end

  defp group_story_maps do
    Enum.map(@group_stories, fn {id, fixture_key, scenario, surface} ->
      group_story(id, fixture_key, scenario, surface)
    end)
  end

  defp group_story(id, fixture_key, scenario, surface) when surface in [:live, :reference] do
    story(%{
      id: id,
      kind: "group",
      category: "group",
      scenario: scenario,
      fixture_key: fixture_key,
      cases: group_cases(id),
      status: "current",
      owner_phase: 177,
      data: %{
        surface: surface,
        summary: group_summary(id, scenario)
      },
      metadata: %{owner_phase: 177, surface: surface}
    })
  end

  defp group_summary("group.modal-destructive.current", _scenario) do
    "Prune retention window permanently? This permanently deletes audit records older than the retention window. Type `default` to confirm."
  end

  defp group_summary(_id, scenario) do
    "Phase 177 #{scenario} audited as a unit on /audit/__stress."
  end

  defp group_cases("group.data-panel.current"), do: ["empty", "stale", "error"]
  defp group_cases("group.toolbar.current"), do: ["error"]
  defp group_cases("group.stats-chart-table.current"), do: ["mixed_severity"]
  defp group_cases("group.detail-header.current"), do: ["null_fields"]
  defp group_cases("group.modal-destructive.current"), do: ["warning"]
  defp group_cases("group.toast-update.current"), do: ["one"]
  defp group_cases("group.empty-cta.current"), do: ["empty", "zero_count"]
  defp group_cases("group.permission-denied.current"), do: ["permission_denied"]
  defp group_cases("group.offline.current"), do: ["reconnecting", "stale"]
  defp group_cases("group.tabs-subviews.reference"), do: ["one"]
  defp group_cases("group.drawer-form.reference"), do: ["one"]
  defp group_cases(_id), do: ["one"]

  defp state_story_maps do
    Enum.map(@state_stories, fn {id, fixture_key, scenario, cases} ->
      story(%{
        id: id,
        kind: "state",
        category: "state",
        scenario: scenario,
        fixture_key: fixture_key,
        cases: cases,
        status: "baseline",
        data: state_data(id, cases)
      })
    end)
  end

  defp data_display_story_maps do
    Enum.map(@data_display_stories, fn {id, fixture_key, scenario, cases} ->
      story(%{
        id: id,
        kind: "state",
        category: "state",
        scenario: scenario,
        fixture_key: fixture_key,
        cases: cases,
        status: "current",
        owner_phase: 176,
        data: %{
          id: id,
          cases: cases,
          summary: data_display_summary(id, scenario)
        },
        metadata: %{owner_phase: 176}
      })
    end)
  end

  defp data_display_summary("state.stale", _scenario) do
    "Could not refresh - showing last known audit data from 2026-06-16 23:59 UTC. Retry."
  end

  defp data_display_summary("state.unavailable-down", _scenario) do
    "Audit source is temporarily unavailable. This is not a permissions issue. Retry, then check operator logs."
  end

  defp data_display_summary("state.unavailable-redacted", _scenario) do
    "This field was redacted by the redaction policy. This is not a permissions issue. Check the redaction policy before relying on this view."
  end

  defp data_display_summary("state.unavailable-pruned", _scenario) do
    "This audit history was permanently pruned by the retention window. This is not a permissions issue. Check the retention window before relying on this view."
  end

  defp data_display_summary(_id, scenario) do
    "Phase 176 #{scenario} audited in isolation on /audit/__stress."
  end

  defp page_story_maps do
    for subject <- @page_subjects, {path, cases} <- @page_paths do
      {id, fixture_key, status, owner_phase} = page_cell_identity(subject, path)

      story(%{
        id: id,
        kind: "page",
        category: "page",
        scenario: page_scenario(subject, path),
        fixture_key: fixture_key,
        cases: cases,
        status: status,
        owner_phase: owner_phase,
        data: page_data(id, cases),
        metadata: %{page_subject: subject, page_path: path}
      })
    end
  end

  # The two Phase 171 baselines keep their exact ids/fixture_keys and `baseline`
  # status; every other cell is a Phase 178 fixture-backed `current` page story.
  defp page_cell_identity(subject, path) do
    case Map.get(@page_baseline_cells, {subject, path}) do
      nil ->
        {"page.#{subject}.#{path}", "page.#{page_fixture_subject(subject)}.#{path}", "current",
         178}

      baseline_id ->
        {baseline_id, baseline_id, "baseline", 171}
    end
  end

  # Fixture keys use underscores for multi-word subjects (row-history -> row_history).
  defp page_fixture_subject(subject), do: String.replace(subject, "-", "_")

  defp page_scenario(subject, path) do
    "#{page_subject_label(subject)} page #{path} path"
  end

  defp page_subject_label("row-history"), do: "Row history"
  defp page_subject_label("shell"), do: "Operator shell"

  defp page_subject_label(subject) do
    subject |> String.replace("-", " ") |> String.capitalize()
  end

  defp permission_denied_story do
    story(%{
      id: "state.permission-denied",
      kind: "state",
      category: "state",
      scenario: "Audit object access needed",
      fixture_key: "state.permission_denied",
      cases: ["permission_denied"],
      status: "baseline",
      data: %{
        message:
          "You do not have access to this audit object. The audit object exists; your account needs `audit.read`.",
        actor_id: "usr_00000000-0000-4000-8000-000000000171",
        restricted_table: "billing_adjustments"
      },
      metadata: %{component: "UnsupportedView.unsupported_view/1"}
    })
  end

  defp folded_todo_stories do
    [
      reserved_story(
        "future.theme-picker-idiomatic-ui",
        "future.theme_picker.idiomatic_ui",
        "Runtime theme picker states reserved baseline",
        "future_reserved",
        175
      ),
      reserved_story(
        "footgun.coverage-schema-card-declutter",
        "footgun.coverage_schema.card_declutter",
        "Coverage schema nested-card baseline",
        "footgun",
        176
      ),
      reserved_story(
        "footgun.transaction-page-left-push-desktop",
        "footgun.transaction_page.left_push_desktop",
        "Transaction page desktop centering baseline",
        "footgun",
        178
      )
    ]
  end

  defp reserved_story_maps(entries, kind, phase) do
    Enum.map(entries, fn {id, fixture_key, scenario} ->
      reserved_story(id, fixture_key, scenario, kind, phase)
    end)
  end

  defp reserved_story(id, fixture_key, scenario, kind, phase) do
    story(%{
      id: id,
      kind: kind,
      category: category_for(kind),
      scenario: scenario,
      fixture_key: fixture_key,
      cases: ["warning"],
      status: "reserved",
      owner_phase: phase,
      data: %{
        reserved_for_phase: phase,
        note: "Reserved for Phase #{phase}. #{@reserved_copy}",
        synthetic_reference: "stress-#{String.replace(id, ".", "-")}"
      },
      metadata: %{reserved_for_phase: phase}
    })
  end

  defp story(attrs) do
    id = Map.fetch!(attrs, :id)

    %{
      id: id,
      kind: Map.fetch!(attrs, :kind),
      category: Map.fetch!(attrs, :category),
      scenario: Map.fetch!(attrs, :scenario),
      fixture_key: Map.fetch!(attrs, :fixture_key),
      ledger_id: Map.get(attrs, :ledger_id, id),
      cases: Map.fetch!(attrs, :cases) |> Enum.sort(),
      themes: @theme_modes,
      viewports: @viewports,
      owner_phase: Map.get(attrs, :owner_phase, 171),
      status: Map.fetch!(attrs, :status),
      data: Map.fetch!(attrs, :data),
      metadata:
        %{
          synthetic: true,
          source: "Threadline.OperatorSurface.StressFixtures"
        }
        |> Map.merge(Map.get(attrs, :metadata, %{}))
    }
  end

  defp category_for("form_control"), do: "form_control"
  defp category_for("future_reserved"), do: "future_reserved"
  defp category_for(kind), do: kind

  defp synthetic_values(cases) do
    %{
      long_id:
        "chg_00000000-0000-4000-8000-171171171171/correlation/" <> String.duplicate("a", 72),
      long_string:
        "support.operator@example.invalid requested retention evidence for " <>
          String.duplicate("transaction boundary ", 8),
      non_ascii: "Zoë Ångström reviewed 東京 retention proof",
      cases: cases
    }
  end

  defp state_data("state.empty", _cases) do
    %{
      rows: [],
      count: 0,
      summary: "No stress rows registered for this synthetic query."
    }
  end

  defp state_data("state.one", _cases) do
    %{
      rows: [synthetic_change(1, "update")],
      count: 1,
      summary: "Exactly one synthetic change."
    }
  end

  defp state_data("state.many", _cases) do
    rows = Enum.map(1..25, &synthetic_change(&1, "insert"))

    %{
      rows: rows,
      count: length(rows),
      total_count: 10_000,
      summary: "Dense synthetic result set with a high count."
    }
  end

  defp state_data("state.mixed-severity", _cases) do
    %{
      severity: %{
        error: %{count: 2, label: "Render failure"},
        warning: %{count: 5, label: "Baseline debt"},
        info: %{count: 8, label: "Neutral coverage"}
      },
      summary: "Mixed error, warning, and informational audit states."
    }
  end

  defp state_data("state.null-fields", _cases) do
    %{
      before: %{email: nil, timezone: nil},
      after: %{email: "zoe.audit@example.invalid", timezone: "Etc/UTC"},
      summary: "Null fields become explicit display values."
    }
  end

  defp state_data("state.pagination-boundary", _cases) do
    %{
      page: 50,
      per_page: 25,
      total_pages: 50,
      total_count: 1_250,
      has_next: false,
      has_previous: true,
      summary: "Last page boundary with no next page."
    }
  end

  defp state_data("state.stale-reconnecting", _cases) do
    %{
      stale: true,
      reconnecting: true,
      checked_at: "2026-06-14T23:59:30Z",
      summary:
        "Data may be stale. Reconnect or refresh before treating this audit state as current."
    }
  end

  defp state_data("state.timezone-boundary", _cases) do
    %{
      utc: "2026-03-08T06:59:59Z",
      local: "2026-03-08 01:59:59 America/New_York",
      next_local: "2026-03-08 03:00:00 America/New_York",
      summary: "Synthetic daylight-saving boundary fixture."
    }
  end

  defp state_data(id, cases) do
    %{
      id: id,
      cases: cases,
      summary: "Synthetic state fixture."
    }
  end

  defp page_data("page.home.happy", cases) do
    %{
      id: "page.home.happy",
      cases: cases,
      summary: "Home page happy path with synthetic lookup launchers and coverage status."
    }
  end

  defp page_data("page.timeline.empty", cases) do
    %{
      id: "page.timeline.empty",
      cases: cases,
      rows: [],
      summary: "Timeline empty state with no captured changes matching this synthetic window."
    }
  end

  defp page_data("page.evidence.happy", cases) do
    %{
      id: "page.evidence.happy",
      cases: cases,
      summary:
        "Evidence shows the current audit posture. Open proof history only for append-only evidence detail."
    }
  end

  defp page_data("page.retention.happy", cases) do
    %{
      id: "page.retention.happy",
      cases: cases,
      summary:
        "Retention window status names the permanent pruning consequence; review before running another prune."
    }
  end

  defp page_data(id, cases) do
    %{
      id: id,
      cases: cases,
      summary: "Synthetic per-page path fixture for #{id} (PAGE-01 Tier A structural cell)."
    }
  end

  defp synthetic_change(index, operation) do
    padded = index |> Integer.to_string() |> String.pad_leading(4, "0")

    %{
      id: "chg_00000000-0000-4000-8000-00000000#{padded}",
      operation: operation,
      table: "audit_subjects",
      actor: "operator-#{padded}@example.invalid",
      changed_at:
        "2026-06-14T12:#{rem(index, 60) |> Integer.to_string() |> String.pad_leading(2, "0")}:00Z"
    }
  end
end
