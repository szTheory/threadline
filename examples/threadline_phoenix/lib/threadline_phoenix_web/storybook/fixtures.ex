defmodule ThreadlinePhoenixWeb.Storybook.Fixtures do
  @moduledoc false

  alias Threadline.OperatorSurface.StressFixtures

  @theme_modes ~w(dark light system)

  @ugly_cases ~w(
    long_id
    long_string
    non_ascii
    null_fields
    mixed_severity
    permission_denied
    stale
    reconnecting
    pagination_boundary
    timezone_boundary
    disabled
    error
    empty
    zero_count
  )

  @stress_story_allowlist %{
    "empty" => "state.empty",
    "error" => "state.unavailable-down",
    "mixed_severity" => "state.mixed-severity",
    "null_fields" => "state.null-fields",
    "pagination_boundary" => "state.pagination-boundary",
    "permission_denied" => "state.permission-denied",
    "reconnecting" => "state.stale-reconnecting",
    "stale" => "state.stale",
    "timezone_boundary" => "state.timezone-boundary",
    "zero_count" => "state.empty"
  }

  @group_story_allowlist %{
    "data_panel" => "group.data-panel.current",
    "detail_header" => "group.detail-header.current",
    "modal_destructive" => "group.modal-destructive.current",
    "offline" => "group.offline.current",
    "permission_denied" => "group.permission-denied.current",
    "toolbar" => "group.toolbar.current"
  }

  @samples %{
    "long_id" =>
      "chg_00000000-0000-4000-8000-182182182182/correlation/" <>
        String.duplicate("threadline-", 8),
    "long_string" =>
      "Audit Transaction retained 147 Audit Changes after a support operator reopened " <>
        "the incident and requested an Evidence export for a second reviewer.",
    "non_ascii" => "Actor Zoe Nunez compared subject 東京-42 and reason Revision reçue à 09:45.",
    "null_fields" => %{previous: nil, current: "policy.retention_window_days", rendered: "null"},
    "mixed_severity" => [
      %{label: "Coverage", severity: "success", count: 18},
      %{label: "Retention", severity: "warning", count: 2},
      %{label: "Redaction", severity: "danger", count: 1}
    ],
    "permission_denied" => %{
      heading: "You do not have access to this audit data",
      capability: "audit:read"
    },
    "stale" => %{as_of: "2026-06-27 01:12:00Z", object_label: "Timeline entries"},
    "reconnecting" => %{status: "reconnecting", disabled: true},
    "pagination_boundary" => %{shown: 50, match_count: 10_001, has_older: true, has_newer: false},
    "timezone_boundary" => %{
      utc: "2026-06-27T01:12:00Z",
      local: "2026-06-26 21:12 America/New_York"
    },
    "disabled" => %{disabled: true, reason: "Refresh is disabled while source is reconnecting"},
    "error" => %{title: "Could not load audit data", logs_label: "operator logs"},
    "empty" => %{title: "No audit changes yet", count: 0},
    "zero_count" => %{count: 0, label: "0 matching changes"}
  }

  @doc false
  def theme_modes do
    stress_modes = StressFixtures.theme_modes()
    Enum.filter(@theme_modes, &(&1 in stress_modes))
  end

  @doc false
  def ugly_cases, do: @ugly_cases

  @doc false
  def sample(case_name) when is_binary(case_name), do: Map.fetch!(@samples, case_name)

  @doc false
  def group_story_ids, do: @group_story_allowlist |> Map.values() |> Enum.sort()

  @doc false
  def group_sample(key) when is_binary(key) do
    story_id = Map.fetch!(@group_story_allowlist, key)
    {:ok, story} = StressFixtures.by_id(story_id)
    {:ok, assigns} = StressFixtures.assigns_for(story_id)

    %{
      story_id: story_id,
      fixture_key: story.fixture_key,
      title: Map.get(assigns, :title, story.scenario),
      body: Map.get(assigns, :body, story.data.summary),
      cases: story.cases,
      surface: story.metadata[:surface]
    }
  end

  @doc false
  def component_assigns("primitives") do
    %{
      button: %{primary_label: "Open Audit Transaction", disabled_label: "Refresh disabled"},
      icon_button: %{label: "Copy Audit Change reference"},
      link: %{href: "/audit", label: "Return to Timeline"},
      badge: %{variants: ~w(info warning danger success neutral)},
      alert: %{body: sample("long_string")},
      ref: %{value: sample("long_id")},
      pager: sample("pagination_boundary"),
      stat_tile: %{label: "Audit Changes", value: "10,000+"},
      stress: stress_assigns("mixed_severity")
    }
  end

  def component_assigns("forms") do
    %{
      field: %{name: "audit_action", label: "Audit Action", value: "ticket.reopened"},
      help: "Use the exact Audit Action name when filtering.",
      error: "Choose a valid retention policy before confirming.",
      checkbox: %{name: "include_redacted", label: "Include redacted values", checked: false},
      radio: %{name: "export_format", options: ["CSV", "NDJSON"]},
      switch: %{name: "show_stale", label: "Show stale Timeline entries", checked: true},
      select: %{name: "severity", options: ["info", "warning", "danger"]},
      textarea: %{name: "reason", value: sample("non_ascii")},
      combobox: %{name: "actor", value: "support.operator@example.invalid"},
      disabled: sample("disabled"),
      stress: stress_assigns("error")
    }
  end

  def component_assigns("states") do
    %{
      empty: sample("empty"),
      no_data: %{reason: :no_data},
      permission: sample("permission_denied"),
      loading: %{reason: :loading},
      stale: sample("stale"),
      source_down: %{reason: :source_down, logs_label: "operator logs"},
      redacted: %{reason: :redacted},
      pruned: %{reason: :pruned, as_of: "2026-06-01"},
      null_fields: sample("null_fields"),
      pagination_boundary: sample("pagination_boundary"),
      timezone_boundary: sample("timezone_boundary"),
      stress: stress_assigns("permission_denied")
    }
  end

  def component_assigns("foundations") do
    %{
      themes: theme_modes(),
      density: ~w(compact default spacious),
      radius: ~w(3px 4px 6px 8px),
      motion: ~w(120ms 180ms 240ms),
      typography_sample: sample("non_ascii"),
      long_string: sample("long_string")
    }
  end

  def component_assigns(:primitives), do: component_assigns("primitives")
  def component_assigns(:forms), do: component_assigns("forms")
  def component_assigns(:states), do: component_assigns("states")
  def component_assigns(:foundations), do: component_assigns("foundations")

  defp stress_assigns(case_name) do
    case_name
    |> stress_story_id!()
    |> StressFixtures.assigns_for()
    |> case do
      {:ok, assigns} -> assigns
      {:error, _reason} -> %{}
    end
  end

  defp stress_story_id!(case_name), do: Map.fetch!(@stress_story_allowlist, case_name)
end
