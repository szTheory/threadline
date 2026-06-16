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
      group.action-bar.reserved
      group.filter-bar.reserved
      group.kv-list.reserved
      group.pagination.reserved
      group.status-strip.reserved
      group.timeline-list.reserved
      page.actor.reserved
      page.coverage.reserved
      page.evidence.reserved
      page.exports.reserved
      page.home.reserved
      page.redaction.reserved
      page.retention.reserved
      page.row-history.reserved
      page.shell.reserved
      page.timeline.reserved
      page.transaction.reserved
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
      assert StressFixtures.viewports() == [320, 375, 768, 1024, 1440]
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

      assert denied_html =~ "Permission denied"
      assert denied_html =~ "restricted data"
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

    defp assert_reserved_story!(story_id, phase) do
      assert {:ok, story} = StressFixtures.by_id(story_id)
      assert story.status == "reserved", "#{story_id} must remain a reserved Phase 171 baseline"
      assert story.owner_phase == phase, "#{story_id} must be owned by Phase #{phase}"
      assert story.metadata.reserved_for_phase == phase
      assert story.data.reserved_for_phase == phase
    end

    defp string_list?(values), do: is_list(values) and Enum.all?(values, &is_binary/1)
    defp integer_list?(values), do: is_list(values) and Enum.all?(values, &is_integer/1)
  end
end
