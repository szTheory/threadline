if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressLedgerTest do
    use ExUnit.Case, async: true

    alias Threadline.OperatorSurface.StressFixtures

    @ledger_path ".planning/design-system-ledger.json"
    @design_system_path "DESIGN-SYSTEM.md"
    @synthetic_set_path ".planning/golden/synthetic-set.json"

    @top_level_keys ~w(
      critic_panel
      critic_trust
      critic_trust_provenance
      cube_axes
      entries
      mechanical_auto_apply
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
      refute
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
      "Future Reserved Cases",
      "Capture Matrix",
      "Scorecard Cube"
    ]

    @scorecard_personas ~w(P1 P2 P3 P4 P5)

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

      # Refute twins carry null scores by contract (D-04) and are covered by the
      # dedicated refute sub-contract test below — never silently exempt.
      for entry <- ledger["entries"], entry["kind"] != "refute" do
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

    test "refute entries carry null scores (D-04) and never leak into the ratchet" do
      ledger = ledger()
      refute_entries = Enum.filter(ledger["entries"], &(&1["kind"] == "refute"))
      refute_ids = MapSet.new(refute_entries, & &1["id"])

      assert refute_entries != [],
             "#{@ledger_path} must carry the Phase 195 refute-twin entries"

      for entry <- refute_entries do
        id = entry["id"]

        # D-04: an unscored/vetoed fixture is null, NEVER 0 — a 0 would poison
        # min() rollups and read as "scored bad" instead of "not scored".
        assert is_nil(entry["current_score"]),
               "#{id} refute current_score must be null (D-04 null-never-0), got #{inspect(entry["current_score"])}"

        assert is_nil(entry["legacy_score"]),
               "#{id} refute legacy_score must be null (D-04 null-never-0), got #{inspect(entry["legacy_score"])}"

        assert entry["ratchet_score"] == 0,
               "#{id} refute ratchet_score must be 0, got #{inspect(entry["ratchet_score"])}"

        assert is_integer(entry["target_score"]),
               "#{id} refute target_score must be an integer"

        assert entry["status"] == "current",
               "#{id} refute status must be \"current\", got #{inspect(entry["status"])}"

        assert entry["owner_phase"] == 195,
               "#{id} refute owner_phase must be 195, got #{inspect(entry["owner_phase"])}"
      end

      # The null-score allowance can never leak into the ratchet.
      ratchet = ledger["ratchet"]

      for id <- ratchet["locked_ids"] do
        refute MapSet.member?(refute_ids, id),
               "refute entry #{id} must not appear in ratchet.locked_ids"
      end

      for {id, _minimum} <- ratchet["minimum_scores"] do
        refute MapSet.member?(refute_ids, id),
               "refute entry #{id} must not appear in ratchet.minimum_scores"
      end

      for signoff <- Map.get(ratchet, "signoffs", []), id <- refute_ids do
        refute String.starts_with?(signoff["cell_key"], id),
               "refute entry #{id} must not appear in any ratchet.signoffs cell_key"
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
      graded_ids = MapSet.new(StressFixtures.graded_stories(), & &1.id)

      # Graded-ladder stories are dev/test-only oracle fixtures — registered in the
      # synthetic oracle set (guard below), never in the product ratchet ledger.
      # Binary refute twins stay ledger-registered and round-trip like every story.
      for story <- StressFixtures.all(), not MapSet.member?(graded_ids, story.id) do
        assert Map.has_key?(by_id, story.ledger_id),
               "stress story #{story.id} ledger_id #{story.ledger_id} is missing from #{@ledger_path}"

        entry = by_id[story.ledger_id]
        assert entry["story_id"] == story.id, "#{entry["id"]} story_id must match #{story.id}"
        assert entry["fixture_key"] == story.fixture_key
      end
    end

    test "graded-ladder stories are registered in the synthetic oracle set" do
      synthetic_set = @synthetic_set_path |> File.read!() |> Jason.decode!()
      cell_ids = Enum.map(synthetic_set["items"], & &1["cell_id"])
      graded = StressFixtures.graded_stories()

      assert graded != [], "StressFixtures.graded_stories/0 must not be empty"

      # D-12: the graded ladder's registry is the synthetic oracle set, not the
      # ledger — every graded story must back at least one oracle cell
      # ({story_id}__{theme}-{breakpoint}).
      for story <- graded do
        assert Enum.any?(cell_ids, &String.starts_with?(&1, "#{story.id}__")),
               "graded story #{story.id} has no #{@synthetic_set_path} item with a cell_id prefixed #{story.id}__"
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

      # Tier C pixel allowlist stays bounded at exactly 3 (MECH-05). Tier A mechanical
      # coverage grows via committed scorecards, NOT by expanding the pixel-diff lane.
      assert length(allowlist["ci"]) == 3,
             "#{@ledger_path} Tier C ci screenshot allowlist must stay bounded at exactly 3 entries, got #{length(allowlist["ci"])}"

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

      # Refute twins are capture substrate, not design-system inventory —
      # DESIGN-SYSTEM.md deliberately carries no refute rows.
      for entry <- entries(), entry["kind"] != "refute" do
        row = inventory_row(entry)

        assert String.contains?(markdown, row),
               "#{@design_system_path} is stale for #{entry["id"]}; missing row #{inspect(row)}"
      end
    end

    test "Scorecard Cube projection is fresh for every page-entry × persona row" do
      markdown = design_system()

      for entry <- entries(), entry["kind"] == "page", persona <- @scorecard_personas do
        row = scorecard_row(entry, persona)

        assert String.contains?(markdown, row),
               "#{@design_system_path} Scorecard Cube is stale for #{entry["id"]} × #{persona}; missing row #{inspect(row)}"
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

    test "current_score is the min of rated cells, else the ratchet watermark (rollup integrity)" do
      # Refute twins are all-null by contract (D-04) — rollup covered by the refute
      # sub-contract test (current_score must be nil, never a watermark integer).
      for entry <- entries(), entry["kind"] != "refute" do
        id = entry["id"]
        scores = entry["scores"] || %{}

        rated_currents =
          scores
          |> Map.values()
          |> Enum.map(& &1["current"])
          |> Enum.reject(&is_nil/1)

        if rated_currents == [] do
          assert entry["current_score"] == entry["ratchet_score"],
                 "#{id} has no rated cells; current_score #{entry["current_score"]} must equal ratchet_score #{entry["ratchet_score"]} (scalar is the watermark, no unearned gain)"
        else
          assert entry["current_score"] == Enum.min(rated_currents),
                 "#{id} current_score #{entry["current_score"]} must equal min of rated cell currents #{inspect(rated_currents)}"
        end
      end
    end

    test "per-cell scores can only ratchet upward unless the entry has an explicit reset" do
      ledger = ledger()
      reset_ids = Map.keys(Map.get(ledger["ratchet"], "resets", %{}))

      for entry <- ledger["entries"] do
        id = entry["id"]
        scores = entry["scores"] || %{}

        for {cell_key, cell} <- scores do
          current = cell["current"]
          floor = cell["floor"] || 0

          if not is_nil(current) and current < floor do
            assert id in reset_ids,
                   "#{id} cell #{cell_key}: current #{current} is below floor #{floor} without a ratchet reset"

            assert is_binary(entry["reset_rationale"]) and entry["reset_rationale"] != "",
                   "#{id} cell #{cell_key}: current #{current} below floor #{floor} without a non-empty reset_rationale"
          end
        end
      end
    end

    test "a score increase carries a File.exists?-true evidence_ref for every cited cell" do
      ledger = ledger()
      valid_cell_keys = valid_cell_keys(ledger["cube_axes"])

      # is_integer/1 is load-bearing: under Elixir term ordering `nil > 0` is true,
      # so a null current_score (refute twins, D-04) would masquerade as a score
      # increase without it. Refute twins are additionally excluded by kind — their
      # null-score contract lives in the refute sub-contract test.
      for entry <- ledger["entries"],
          entry["kind"] != "refute",
          is_integer(entry["current_score"]),
          entry["current_score"] > entry["ratchet_score"] do
        id = entry["id"]
        ref = entry["evidence_ref"]

        assert is_map(ref) and map_size(ref) > 0,
               "#{id} has a score increase but evidence_ref is not a non-empty cell-keyed map"

        for {cell_key, path} <- ref do
          assert cell_key in valid_cell_keys,
                 "#{id} evidence_ref cell key #{inspect(cell_key)} is not declared in cube_axes"

          assert is_binary(path) and path != "",
                 "#{id} evidence_ref[#{cell_key}] must be a non-empty repo-relative path string"

          assert File.exists?(path),
                 "#{id} evidence_ref[#{cell_key}] path does not exist: #{inspect(path)}"
        end
      end
    end

    test "cube_axes declares the frozen lens order and every entry carries the valid cell set" do
      ledger = ledger()
      cube_axes = ledger["cube_axes"]
      cube_lenses = Enum.map(cube_axes["lenses"], & &1["slug"])

      assert cube_lenses == ~w(hierarchy density rhythm typography color_contrast brand_fidelity),
             "cube_axes lenses must match the D-01 frozen vocabulary in fixed order, got #{inspect(cube_lenses)}"

      valid_cell_keys = valid_cell_keys(cube_axes)

      for entry <- ledger["entries"] do
        id = entry["id"]
        cell_keys = entry["scores"] |> Map.keys() |> Enum.sort()

        assert cell_keys == valid_cell_keys,
               "#{id} cube cell keys #{inspect(cell_keys)} do not match the cube_axes valid set #{inspect(valid_cell_keys)}"
      end
    end

    test "mechanical-authority cells do not carry signoff floor bumps" do
      ledger = ledger()
      auto_lenses = ~w(density rhythm typography color_contrast brand_fidelity)
      signoffs = Map.get(ledger["ratchet"], "signoffs", [])

      for signoff <- signoffs do
        lens = signoff["cell_key"] |> String.split(".") |> List.last()

        refute lens in auto_lenses,
               "signoff for #{signoff["cell_key"]} targets a mechanical-authority lens; auto lenses ratchet automatically, not via signoff"
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

    defp scorecard_row(entry, persona) do
      scores = entry["scores"] || %{}

      cell = fn key ->
        case scores[key] do
          %{"current" => current} when not is_nil(current) -> to_string(current)
          _ -> "—"
        end
      end

      "| `#{entry["id"]}` | #{persona} | #{cell.("#{persona}.hierarchy")} | #{cell.("#{persona}.density")} | #{cell.("all.rhythm")} | #{cell.("all.typography")} | #{cell.("all.color_contrast")} | #{cell.("all.brand_fidelity")} | #{entry["current_score"]} |"
    end

    defp valid_cell_keys(cube_axes) do
      personas = Enum.map(cube_axes["personas"], & &1["slug"])
      lenses = Enum.map(cube_axes["lenses"], & &1["slug"])
      invariant_lenses = ~w(rhythm typography color_contrast brand_fidelity)

      persona_keyed =
        for p <- personas, l <- lenses, l not in invariant_lenses, do: "#{p}.#{l}"

      invariant_keyed = for l <- invariant_lenses, do: "all.#{l}"

      Enum.sort(persona_keyed ++ invariant_keyed)
    end
  end
end
