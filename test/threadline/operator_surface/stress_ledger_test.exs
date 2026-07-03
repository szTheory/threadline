if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressLedgerTest do
    use ExUnit.Case, async: true

    alias Threadline.OperatorSurface.StressFixtures

    @ledger_path ".planning/design-system-ledger.json"
    @design_system_path "DESIGN-SYSTEM.md"

    @top_level_keys ~w(
      cube_axes
      entries
      mechanical_floors
      phase
      ratchet
      ratchet_rule
      required_inventory
      screenshot_allowlist
      version
    )

    @entry_keys ~w(
      category
      current_score
      fixture_key
      id
      kind
      legacy_score
      notes
      owner_phase
      ratchet_score
      scores
      screenshot_baseline_refs
      source
      status
      story_id
      stress_path
      target_score
    )

    @optional_entry_keys ~w(evidence_ref reset_rationale reserved_for_phase)

    @allowed_kinds ~w(
      form_control
      footgun
      foundation
      future_reserved
      group
      page
      primitive
      state
    )

    @design_sections [
      "Ratchet Rule",
      "Foundations",
      "Primitives",
      "Form Controls",
      "Groups",
      "Pages",
      "Known Footguns",
      "Future Reserved Cases"
    ]

    @forbidden_terms [
      "---",
      "PhoenixStorybook",
      "Tailwind",
      "Chromatic",
      "Percy",
      "Applitools",
      "Lost Pixel",
      "immutable ledger"
    ]

    test "ledger JSON has the required top-level shape" do
      ledger = ledger()

      assert sorted_keys(ledger) == @top_level_keys,
             "#{@ledger_path} top-level keys drifted: #{inspect(sorted_keys(ledger))}"

      assert is_list(ledger["entries"]), "#{@ledger_path} entries must be an array"
      assert is_map(ledger["ratchet"]), "#{@ledger_path} ratchet must be an object"
    end

    test "ledger entries are sorted and use only the contracted keys" do
      entries = entries()
      ids = Enum.map(entries, & &1["id"])
      allowed_keys = Enum.sort(@entry_keys ++ @optional_entry_keys)

      assert ids == Enum.sort(ids),
             "#{@ledger_path} entries must be sorted by id for deterministic review"

      for entry <- entries do
        assert sorted_keys(entry) -- allowed_keys == [],
               "#{entry["id"]} has unsupported keys: #{inspect(sorted_keys(entry) -- allowed_keys)}"

        assert @entry_keys -- sorted_keys(entry) == [],
               "#{entry["id"]} is missing required keys: #{inspect(@entry_keys -- sorted_keys(entry))}"

        assert entry["kind"] in @allowed_kinds,
               "#{entry["id"]} kind #{inspect(entry["kind"])} is not an allowed ledger kind"
      end
    end

    test "scores can only ratchet upward unless an explicit reset is recorded" do
      ledger = ledger()
      reset_ids = Map.get(ledger["ratchet"], "resets", [])

      for entry <- ledger["entries"] do
        id = entry["id"]

        assert is_integer(entry["current_score"]), "#{id} current_score must be an integer"
        assert is_integer(entry["target_score"]), "#{id} target_score must be an integer"
        assert is_integer(entry["ratchet_score"]), "#{id} ratchet_score must be an integer"

        assert entry["target_score"] >= entry["current_score"],
               "#{id} target_score must be greater than or equal to current_score"

        if entry["current_score"] < entry["ratchet_score"] do
          assert id in reset_ids,
                 "#{id} lowered current_score below ratchet_score without being listed in ratchet.resets"

          assert is_binary(entry["reset_rationale"]) and entry["reset_rationale"] != "",
                 "#{id} lowered current_score below ratchet_score without a reset_rationale"
        else
          assert entry["current_score"] >= entry["ratchet_score"],
                 "#{id} current_score must be greater than or equal to ratchet_score"
        end
      end
    end

    test "locked IDs and minimum scores are enforced" do
      ledger = ledger()
      by_id = entries_by_id(ledger["entries"])

      for id <- ledger["ratchet"]["locked_ids"] do
        assert Map.has_key?(by_id, id), "locked ledger ID #{id} is missing from entries"
      end

      for {id, minimum_score} <- ledger["ratchet"]["minimum_scores"] do
        assert Map.has_key?(by_id, id), "minimum score ledger ID #{id} is missing from entries"

        assert by_id[id]["current_score"] >= minimum_score,
               "#{id} current_score #{by_id[id]["current_score"]} is below ratchet minimum #{minimum_score}"
      end
    end

    test "fixture registry stories are present in the ledger and link back by story and fixture key" do
      by_id = entries_by_id(entries())

      for story <- StressFixtures.all() do
        assert Map.has_key?(by_id, story.ledger_id),
               "stress story #{story.id} ledger_id #{story.ledger_id} is missing from #{@ledger_path}"

        entry = by_id[story.ledger_id]
        assert entry["story_id"] == story.id, "#{entry["id"]} story_id must match #{story.id}"
        assert entry["fixture_key"] == story.fixture_key
      end
    end

    test "ledger-owned fixture references round-trip through StressFixtures" do
      for entry <- entries(), fixture_backed_entry?(entry) do
        assert {:ok, story} = StressFixtures.by_id(entry["story_id"]),
               "#{entry["id"]} story_id #{inspect(entry["story_id"])} does not resolve"

        assert story.ledger_id == entry["id"],
               "#{entry["id"]} does not match fixture story ledger_id #{story.ledger_id}"

        assert story.fixture_key == entry["fixture_key"],
               "#{entry["id"]} fixture_key #{inspect(entry["fixture_key"])} does not match story"

        case StressFixtures.assigns_for(story) do
          {:ok, assigns} ->
            assert is_map(assigns), "#{entry["id"]} assigns_for/1 must return a map"

          {:error, reason} ->
            assert entry["status"] == "reserved",
                   "#{entry["id"]} assigns_for/1 failed with #{inspect(reason)} but is not reserved"

            assert is_integer(entry["reserved_for_phase"]),
                   "#{entry["id"]} reserved entries must include reserved_for_phase"
        end
      end
    end

    test "screenshot allowlist references real ledger entries and named review dimensions" do
      ledger = ledger()
      by_id = entries_by_id(ledger["entries"])
      allowlist = ledger["screenshot_allowlist"]

      assert sorted_keys(allowlist) == ["ci", "local_review"],
             "#{@ledger_path} screenshot_allowlist must contain ci and local_review arrays"

      for lane <- ["ci", "local_review"], item <- allowlist[lane] do
        assert Map.has_key?(by_id, item["ledger_id"]),
               "screenshot #{lane} allowlist references unknown ledger_id #{inspect(item["ledger_id"])}"

        for key <- ~w(story_id theme viewport baseline_ref) do
          assert Map.has_key?(item, key),
                 "screenshot #{lane} allowlist item #{inspect(item)} is missing #{key}"
        end
      end
    end

    test "DESIGN-SYSTEM projection contains deterministic inventory sections" do
      markdown = design_system()

      for section <- @design_sections do
        assert String.contains?(markdown, "## #{section}"),
               "#{@design_system_path} is missing deterministic section #{section}"
      end
    end

    test "DESIGN-SYSTEM projection is fresh for every ledger row" do
      markdown = design_system()

      for entry <- entries() do
        row = inventory_row(entry)

        assert String.contains?(markdown, row),
               "#{@design_system_path} is stale for #{entry["id"]}; missing row #{inspect(row)}"
      end
    end

    test "ledger and markdown avoid frontmatter and banned external/service copy" do
      ledger_source = File.read!(@ledger_path)
      markdown = design_system()

      for source <- [ledger_source, markdown] do
        refute String.starts_with?(source, "---\n"),
               "ledger and #{@design_system_path} must not use YAML frontmatter"

        for term <- @forbidden_terms -- ["---"] do
          refute source =~ term, "ledger projection must not contain forbidden term #{term}"
        end
      end
    end

    defp ledger, do: @ledger_path |> File.read!() |> Jason.decode!()
    defp design_system, do: File.read!(@design_system_path)
    defp entries, do: ledger()["entries"]
    defp sorted_keys(map), do: map |> Map.keys() |> Enum.sort()
    defp entries_by_id(entries), do: Map.new(entries, fn entry -> {entry["id"], entry} end)

    defp fixture_backed_entry?(entry) do
      entry["story_id"] != "" or entry["fixture_key"] != "" or entry["stress_path"] != ""
    end

    defp inventory_row(entry) do
      "| `#{entry["id"]}` | #{entry["status"]} | #{entry["current_score"]} | #{entry["target_score"]} |"
    end
  end
end
