if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressFixturesTest do
    use ExUnit.Case, async: true
    import Phoenix.LiveViewTest

    alias Threadline.OperatorSurface.Components.SurfaceHeader
    alias Threadline.OperatorSurface.Components.UnsupportedView
    alias Threadline.OperatorSurface.StressFixtures

    @source_path "lib/threadline/operator_surface/stress_fixtures.ex"

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

    @required_inventory_story_ids ~w(
      footgun.coverage-schema-card-declutter
      footgun.transaction-page-left-push-desktop
      form-control.checkbox.current
      form-control.date-range.current
      form-control.input.current
      form-control.radio.current
      form-control.search.current
      form-control.select.current
      form-control.textarea.current
      foundation.color
      foundation.density
      foundation.motion
      foundation.radius
      foundation.shadow
      foundation.spacing
      foundation.typography
      foundation.z-index
      future.theme-picker-idiomatic-ui
      group.data-panel.current
      group.detail-header.current
      group.drawer-form.reference
      group.empty-cta.current
      group.modal-destructive.current
      group.offline.current
      group.page-header.current
      group.permission-denied.current
      group.stats-chart-table.current
      group.tabs-subviews.reference
      group.toast-update.current
      group.toolbar.current
      page.actor.advanced
      page.actor.boundary
      page.actor.empty
      page.actor.error
      page.actor.happy
      page.actor.loading
      page.actor.permission
      page.coverage.advanced
      page.coverage.boundary
      page.coverage.empty
      page.coverage.error
      page.coverage.happy
      page.coverage.loading
      page.coverage.permission
      page.evidence.advanced
      page.evidence.boundary
      page.evidence.empty
      page.evidence.error
      page.evidence.happy
      page.evidence.loading
      page.evidence.permission
      page.exports.advanced
      page.exports.boundary
      page.exports.empty
      page.exports.error
      page.exports.happy
      page.exports.loading
      page.exports.permission
      page.home.advanced
      page.home.boundary
      page.home.empty
      page.home.error
      page.home.happy
      page.home.loading
      page.home.permission
      page.redaction.advanced
      page.redaction.boundary
      page.redaction.empty
      page.redaction.error
      page.redaction.happy
      page.redaction.loading
      page.redaction.permission
      page.retention.advanced
      page.retention.boundary
      page.retention.empty
      page.retention.error
      page.retention.happy
      page.retention.loading
      page.retention.permission
      page.row-history.advanced
      page.row-history.boundary
      page.row-history.empty
      page.row-history.error
      page.row-history.happy
      page.row-history.loading
      page.row-history.permission
      page.shell.advanced
      page.shell.boundary
      page.shell.empty
      page.shell.error
      page.shell.happy
      page.shell.loading
      page.shell.permission
      page.timeline.advanced
      page.timeline.boundary
      page.timeline.empty
      page.timeline.error
      page.timeline.happy
      page.timeline.loading
      page.timeline.permission
      page.transaction.advanced
      page.transaction.boundary
      page.transaction.empty
      page.transaction.error
      page.transaction.happy
      page.transaction.loading
      page.transaction.permission
      primitive.icon.reserved
      primitive.logo.reserved
      primitive.surface-header.current
      primitive.unsupported-view.reserved
      state.empty
      state.many
      state.mixed-severity
      state.null-fields
      state.one
      state.pagination-boundary
      state.permission-denied
      state.stale-reconnecting
      state.timezone-boundary
    )

    test "required_cases returns the DS-04 ugly-data matrix in sorted order" do
      assert StressFixtures.required_cases() == @required_cases
    end

    test "theme modes and viewport matrix are fixed" do
      assert StressFixtures.theme_modes() == ["dark", "light", "system"]
      assert StressFixtures.viewports() == [320, 375, 768, 1024, 1280, 1440]
    end

    test "every story exposes the canonical fixture contract" do
      stories = StressFixtures.all()

      refute stories == []

      for story <- stories do
        assert is_binary(story.id), "story id must be a string: #{inspect(story)}"
        assert is_binary(story.kind), "#{story.id} kind must be a string"
        assert is_binary(story.category), "#{story.id} category must be a string"
        assert is_binary(story.scenario), "#{story.id} scenario must be a string"
        assert is_binary(story.fixture_key), "#{story.id} fixture_key must be a string"
        assert is_binary(story.ledger_id), "#{story.id} ledger_id must be a string"
        assert string_list?(story.cases), "#{story.id} cases must be a list of strings"
        assert string_list?(story.themes), "#{story.id} themes must be a list of strings"
        assert integer_list?(story.viewports), "#{story.id} viewports must be a list of integers"
        assert is_integer(story.owner_phase), "#{story.id} owner_phase must be an integer"
        assert is_binary(story.status), "#{story.id} status must be a string"
        assert is_map(story.data), "#{story.id} data must be a map"
        assert is_map(story.metadata), "#{story.id} metadata must be a map"
      end
    end

    test "story IDs and ledger IDs are unique sorted stable strings" do
      stories = StressFixtures.all()
      ids = Enum.map(stories, & &1.id)
      ledger_ids = Enum.map(stories, & &1.ledger_id)

      assert ids == Enum.sort(ids), "StressFixtures.all/0 must be sorted by string id"
      assert ids == Enum.uniq(ids), "duplicate story ids: #{inspect(ids -- Enum.uniq(ids))}"
      assert ledger_ids == Enum.uniq(ledger_ids), "duplicate ledger ids are not allowed"

      for story <- stories do
        assert {:ok, ^story} = StressFixtures.by_id(story.id)
      end

      assert StressFixtures.by_id("not-a-story") == :error
    end

    test "DS-04 case coverage is complete" do
      covered =
        StressFixtures.all()
        |> Enum.flat_map(& &1.cases)
        |> MapSet.new()

      for required_case <- @required_cases do
        assert MapSet.member?(covered, required_case),
               "missing DS-04 stress fixture case: #{required_case}"
      end
    end

    test "folded todos are future-owned reserved baseline stories" do
      assert_reserved_story!("future.theme-picker-idiomatic-ui", 175)
      assert_reserved_story!("footgun.coverage-schema-card-declutter", 176)
      assert_reserved_story!("footgun.transaction-page-left-push-desktop", 178)
    end

    test "fixture registry source stays synthetic and package-free" do
      source = File.read!(@source_path)

      forbidden = [
        "ThreadlinePhoenix",
        "Repo.",
        "Ecto.Query",
        "String.to_atom",
        "PhoenixStorybook",
        "Tailwind"
      ]

      for term <- forbidden do
        refute source =~ term, "stress fixture source must not reference #{term}"
      end

      refute source =~ "npmjs.com", "stress fixture source must not reference package registries"

      refute source =~ "hex.pm/packages",
             "stress fixture source must not reference package registries"

      refute source =~ "pypi.org", "stress fixture source must not reference package registries"
    end

    test "representative adapters render existing component shapes" do
      assert {:ok, header_assigns} =
               StressFixtures.assigns_for("primitive.surface-header.current")

      header_html = render_component(&SurfaceHeader.surface_header/1, header_assigns)

      assert header_html =~ ~s|data-testid="operator-header"|

      assert {:ok, denied_assigns} = StressFixtures.assigns_for("state.permission-denied")

      denied_html = render_component(&UnsupportedView.unsupported_view/1, denied_assigns)

      assert denied_html =~ "Audit object access needed"
      assert denied_html =~ "You do not have access to this audit object."
      assert denied_html =~ "account needs `audit.read`"
    end

    test "Phase 179 copy-state evidence uses final state grammar without story churn" do
      expectations = [
        {"state.permission-denied",
         [
           "You do not have access to this audit object.",
           "The audit object exists; your account needs `audit.read`."
         ]},
        {"state.unavailable-down",
         [
           "Audit source is temporarily unavailable.",
           "This is not a permissions issue.",
           "Retry, then check operator logs."
         ]},
        {"state.unavailable-redacted",
         [
           "This field was redacted by the redaction policy.",
           "This is not a permissions issue."
         ]},
        {"state.unavailable-pruned",
         [
           "This audit history was permanently pruned by the retention window.",
           "This is not a permissions issue."
         ]},
        {"state.stale",
         [
           "Could not refresh - showing last known audit data",
           "Retry."
         ]},
        {"page.evidence.happy",
         [
           "Evidence shows the current audit posture.",
           "Open proof history only for append-only evidence detail."
         ]},
        {"page.retention.happy",
         [
           "Retention window status names the permanent pruning consequence",
           "review before running another prune"
         ]},
        {"group.modal-destructive.current",
         [
           "Prune retention window permanently?",
           "This permanently deletes audit records older than the retention window.",
           "Type `default` to confirm."
         ]}
      ]

      for {story_id, required_copy} <- expectations do
        assert {:ok, story} = StressFixtures.by_id(story_id)
        copy = fixture_copy(story)

        for expected <- required_copy do
          assert copy =~ expected,
                 "#{story_id} must render Phase 179 copy #{inspect(expected)}; got #{inspect(copy)}"
        end
      end

      assert {:ok, evidence_story} = StressFixtures.by_id("page.evidence.happy")

      evidence_copy =
        evidence_story
        |> fixture_copy()
        |> String.replace("proof history", "")

      refute evidence_copy =~ ~r/\bproofs?\b/i
    end

    test "fixture registry exposes every planned ledger inventory story" do
      story_ids =
        StressFixtures.all()
        |> Enum.map(& &1.id)
        |> MapSet.new()

      for story_id <- @required_inventory_story_ids do
        assert MapSet.member?(story_ids, story_id),
               "missing planned ledger inventory stress story: #{story_id}"
      end
    end

    @live_group_story_ids ~w(
      group.data-panel.current
      group.detail-header.current
      group.empty-cta.current
      group.modal-destructive.current
      group.offline.current
      group.page-header.current
      group.permission-denied.current
      group.stats-chart-table.current
      group.toast-update.current
      group.toolbar.current
    )

    @reference_group_story_ids ~w(
      group.drawer-form.reference
      group.tabs-subviews.reference
    )

    test "GROUP-01 maps the 12 configurations to current group stories with a surface tag" do
      group_stories =
        StressFixtures.all()
        |> Enum.filter(&(&1.category == "group"))

      assert length(group_stories) == 12,
             "GROUP-01 requires exactly 12 group configurations, got #{length(group_stories)}"

      for story <- group_stories do
        assert story.status == "current", "#{story.id} group story must be status current"
        assert story.owner_phase == 177, "#{story.id} group story must be owned by Phase 177"

        assert story.data.surface in [:live, :reference],
               "#{story.id} must carry a surface tag in [:live, :reference]"

        assert story.metadata.surface == story.data.surface,
               "#{story.id} surface tag must match between data and metadata"
      end

      refute Enum.any?(group_stories, &String.ends_with?(&1.id, ".reserved")),
             "no orphaned reserved group ids may remain after the GROUP-01 remap"
    end

    test "the live/reference split matches the GROUP-01 mapping" do
      by_surface =
        StressFixtures.all()
        |> Enum.filter(&(&1.category == "group"))
        |> Enum.group_by(& &1.data.surface, & &1.id)

      assert Enum.sort(by_surface[:live]) == Enum.sort(@live_group_story_ids)
      assert Enum.sort(by_surface[:reference]) == Enum.sort(@reference_group_story_ids)
    end

    # --- Phase 178 (PAGE-01 / D-04): 77 current page-path story ratchet --------
    #
    # The 11 page subjects must stay fixture-backed across the 7 audit paths
    # (happy/empty/loading/error/permission/boundary/advanced). This assertion locks
    # the converted current-story shape so a page subject cannot silently regress to
    # a reserved baseline or lose one of the path fixtures.
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

    # The 7 audit paths each page must eventually be fixture-backed across (D-04).
    # The cases vocabulary maps onto this taxonomy; a converted page story must carry
    # cases covering each path's representative fixture case.
    @page_path_cases %{
      "happy" => ~w(one many mixed_severity),
      "empty" => ~w(empty zero_count),
      "loading" => ~w(reconnecting stale),
      "error" => ~w(error),
      "permission" => ~w(permission_denied),
      "boundary" => ~w(pagination_boundary timezone_boundary long_id long_string high_count),
      "advanced" => ~w(non_ascii null_fields mixed_severity)
    }

    test "PAGE-01 (D-04): each of the 11 page subjects is a fixture-backed CURRENT 7-path story" do
      stories = StressFixtures.all()

      page_stories_by_subject =
        stories
        |> Enum.filter(&(&1.category == "page"))
        |> Enum.group_by(fn story ->
          # "page.actor.reserved" / "page.timeline.empty" -> subject "actor"/"timeline"
          case String.split(story.id, ".") do
            ["page", subject | _] -> subject
            _ -> nil
          end
        end)

      for subject <- @page_subjects do
        subject_stories = Map.get(page_stories_by_subject, subject, [])

        refute subject_stories == [],
               "PAGE-01: page subject #{subject} must have at least one page story (D-04)"

        # D-04: the page must stay converted off the reserved baseline. A subject
        # that only carries `.reserved` (status "reserved") stories has regressed.
        converted =
          Enum.filter(subject_stories, fn story -> story.status != "reserved" end)

        refute converted == [],
               "PAGE-01: page subject #{subject} is still a RESERVED baseline — it must expose fixture-backed current/baseline path stories (D-04)"

        # The converted page story/stories must cover all 7 audit paths via their
        # fixture cases.
        covered_cases =
          converted
          |> Enum.flat_map(& &1.cases)
          |> MapSet.new()

        for {path, representative_cases} <- @page_path_cases do
          assert Enum.any?(representative_cases, &MapSet.member?(covered_cases, &1)),
                 "PAGE-01: page subject #{subject} must be fixture-backed for the '#{path}' path (one of #{inspect(representative_cases)}); got cases #{inspect(MapSet.to_list(covered_cases))} (D-04)"
        end
      end
    end

    defp assert_reserved_story!(story_id, phase) do
      assert {:ok, story} = StressFixtures.by_id(story_id)
      assert story.status == "reserved", "#{story_id} must remain a reserved Phase 171 baseline"
      assert story.owner_phase == phase, "#{story_id} must be owned by Phase #{phase}"
      assert story.metadata.reserved_for_phase == phase
      assert story.data.reserved_for_phase == phase
    end

    defp fixture_copy(story) do
      assign_copy =
        case StressFixtures.assigns_for(story) do
          {:ok, assigns} -> [assigns[:title], assigns[:body]]
          {:error, _reason} -> []
        end

      data_copy = [story.scenario, story.data[:summary], story.data[:message]]

      (assign_copy ++ data_copy)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.join("\n")
    end

    defp string_list?(values), do: is_list(values) and Enum.all?(values, &is_binary/1)
    defp integer_list?(values), do: is_list(values) and Enum.all?(values, &is_integer/1)
  end
end
