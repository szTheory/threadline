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
  @viewports [320, 375, 768, 1024, 1440]

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

  @group_stories [
    {"group.action-bar.reserved", "group.action_bar.reserved",
     "Action bar group reserved baseline"},
    {"group.filter-bar.reserved", "group.filter_bar.reserved",
     "Filter bar group reserved baseline"},
    {"group.kv-list.reserved", "group.kv_list.reserved",
     "Key-value list group reserved baseline"},
    {"group.pagination.reserved", "group.pagination.reserved",
     "Pagination group reserved baseline"},
    {"group.status-strip.reserved", "group.status_strip.reserved",
     "Status strip group reserved baseline"},
    {"group.timeline-list.reserved", "group.timeline_list.reserved",
     "Timeline list group reserved baseline"}
  ]

  @page_stories [
    {"page.actor.reserved", "page.actor.reserved", "Actor page reserved baseline"},
    {"page.coverage.reserved", "page.coverage.reserved", "Coverage page reserved baseline"},
    {"page.evidence.reserved", "page.evidence.reserved", "Evidence page reserved baseline"},
    {"page.exports.reserved", "page.exports.reserved", "Exports page reserved baseline"},
    {"page.home.reserved", "page.home.reserved", "Home page reserved baseline"},
    {"page.redaction.reserved", "page.redaction.reserved", "Redaction page reserved baseline"},
    {"page.retention.reserved", "page.retention.reserved", "Retention page reserved baseline"},
    {"page.row-history.reserved", "page.row_history.reserved",
     "Row history page reserved baseline"},
    {"page.shell.reserved", "page.shell.reserved", "Operator shell reserved baseline"},
    {"page.timeline.reserved", "page.timeline.reserved", "Timeline page reserved baseline"},
    {"page.transaction.reserved", "page.transaction.reserved",
     "Transaction page reserved baseline"}
  ]

  @current_page_stories [
    {"page.home.happy", "page.home.happy", "Home page happy path", ["one", "mixed_severity"]},
    {"page.timeline.empty", "page.timeline.empty", "Timeline page empty state",
     ["empty", "zero_count"]}
  ]

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
       title: "Permission denied",
       body:
         "Permission denied. This state proves the operator can distinguish restricted data from empty data.",
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
      reserved_story_maps(@group_stories, "group", 177),
      current_page_story_maps(),
      reserved_story_maps(@page_stories, "page", 178),
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
          summary: "Phase 176 #{scenario} audited in isolation on /audit/__stress."
        },
        metadata: %{owner_phase: 176}
      })
    end)
  end

  defp current_page_story_maps do
    Enum.map(@current_page_stories, fn {id, fixture_key, scenario, cases} ->
      story(%{
        id: id,
        kind: "page",
        category: "page",
        scenario: scenario,
        fixture_key: fixture_key,
        cases: cases,
        status: "baseline",
        data: page_data(id, cases)
      })
    end)
  end

  defp permission_denied_story do
    story(%{
      id: "state.permission-denied",
      kind: "state",
      category: "state",
      scenario: "Permission denied state",
      fixture_key: "state.permission_denied",
      cases: ["permission_denied"],
      status: "baseline",
      data: %{
        message:
          "Permission denied. This state proves the operator can distinguish restricted data from empty data.",
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
