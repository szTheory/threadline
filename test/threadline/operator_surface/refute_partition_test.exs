if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RefutePartitionTest do
    @moduledoc """
    Partition-rule guard for the Phase 195 refute-test battery (CRITIC-02, D-03).

    Proves that:
      1. The refute manifest (.planning/refute/refute-set.json) is well-formed and lists
         all required twin fields.
      2. Every gestalt twin has committed scorecards for both poles.
      3. Every gestalt twin's FLAWED scorecard PASSES all mechanical gates (MODE A + MODE B),
         confirming the flaw isolates only what the critic can catch — not mechanics.
      4. The veto-ordering twin has NO committed flawed scorecard (exercised at the panel
         layer in Plan 06, not the mechanical layer).
      5. The veto-ordering twin's evidence_note documents the off-token raw hex the panel
         veto (Plan 06 panel.ts) will trip.
      6. No refute twin_id or cell_id appears in golden-set.json — the refute set is disjoint
         from the golden set (no teaching-to-the-test).
    """
    use ExUnit.Case, async: true

    alias Threadline.OperatorSurface.MechanicalChecker

    @refute_manifest ".planning/refute/refute-set.json"
    @scorecard_dir ".planning/scorecards"
    @golden_set ".planning/golden/golden-set.json"

    @required_item_keys ~w(
      class
      evidence_note
      expected_direction
      flawed_cell_id
      polished_cell_id
      target_lens
      twin_id
    )

    # ── manifest shape ────────────────────────────────────────────────────────

    test "refute manifest exists, has version and non-empty items array" do
      assert File.exists?(@refute_manifest),
             "#{@refute_manifest} not found — run plan 195-03 Task 2 to create it"

      m = manifest()
      assert is_binary(m["version"]) and m["version"] != "",
             "#{@refute_manifest} must have a non-empty version string"

      assert is_list(m["items"]) and length(m["items"]) > 0,
             "#{@refute_manifest} items must be a non-empty array"
    end

    test "every manifest item carries the required fields with non-empty values" do
      for item <- items() do
        for key <- @required_item_keys do
          assert Map.has_key?(item, key),
                 "refute-set.json item #{item["twin_id"] || "UNKNOWN"} is missing required key: #{key}"

          assert is_binary(item[key]) and item[key] != "",
                 "refute-set.json item #{item["twin_id"] || "UNKNOWN"} has blank/nil #{key}: #{inspect(item[key])}"
        end
      end
    end

    test "every item's class is gestalt or veto_ordering" do
      valid_classes = ~w(gestalt veto_ordering)

      for item <- items() do
        assert item["class"] in valid_classes,
               "refute-set.json item #{item["twin_id"]} has invalid class #{inspect(item["class"])}; must be one of #{inspect(valid_classes)}"
      end
    end

    # ── scorecard existence ───────────────────────────────────────────────────

    test "every gestalt twin has committed scorecards for both poles (all 6 breakpoints)" do
      breakpoints = ~w(dark-375 dark-768 dark-1280 light-375 light-768 light-1280)

      for item <- gestalt_items() do
        for bp <- breakpoints do
          for pole_id <- [item["polished_cell_id"], item["flawed_cell_id"]] do
            path = scorecard_path("#{pole_id}__#{bp}")

            assert File.exists?(path),
                   "gestalt twin #{item["twin_id"]} #{pole_id} scorecard missing for #{bp}: #{path}"
          end
        end
      end
    end

    # ── partition rule D-03 ───────────────────────────────────────────────────

    test "gestalt flawed scorecards pass all mechanical gates (partition rule D-03)" do
      # Copy gestalt flawed scorecards into a temp dir and run the full mechanical
      # checker over only those files. The refute entries have no floor entries in
      # mechanical_floors; only absolute ceilings apply (card_nesting_depth > 3,
      # distinct_accent_hue_count > 3). A violation here means the flaw bleeds into
      # mechanical territory — that would make it a mechanical test, not a critic test
      # (D-03 breach).
      tmp_dir = Path.join(System.tmp_dir!(), "refute-partition-#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)

      try do
        for item <- gestalt_items() do
          flawed_prefix = item["flawed_cell_id"]

          Path.wildcard(Path.join(@scorecard_dir, "#{flawed_prefix}__*.json"))
          |> Enum.each(fn src ->
            File.copy!(src, Path.join(tmp_dir, Path.basename(src)))
          end)
        end

        case MechanicalChecker.run(scorecard_dir: tmp_dir) do
          {:ok, []} ->
            :ok

          {:error, violations} ->
            flunk(
              "Gestalt flawed scorecards have mechanical violations — D-03 partition rule breach.\n" <>
                "These flaws must pass all mechanical gates (they test what the critic catches, not mechanics).\n\n" <>
                Enum.map_join(violations, "\n", fn v ->
                  v = if is_struct(v), do: Map.from_struct(v), else: v
                  "  #{v[:cell_id]}: MODE #{v[:mode]} #{v[:metric]} #{v[:selector]}\n" <>
                    "    expected: #{v[:expected]}, got: #{v[:observed]}\n" <>
                    "    fix: #{v[:fix]}"
                end)
            )
        end
      after
        File.rm_rf!(tmp_dir)
      end
    end

    # ── veto-ordering twin invariants ─────────────────────────────────────────

    test "veto-ordering twin exists in the manifest" do
      assert veto_item() != nil,
             "#{@refute_manifest} must include exactly one item with class: veto_ordering"
    end

    test "veto-ordering flawed pole has NO committed scorecard (exercised at panel layer, not mechanical)" do
      item = veto_item()
      assert item != nil, "veto_ordering item missing from manifest"

      breakpoints = ~w(dark-375 dark-768 dark-1280 light-375 light-768 light-1280)

      for bp <- breakpoints do
        path = scorecard_path("#{item["flawed_cell_id"]}__#{bp}")

        refute File.exists?(path),
               "veto-ordering flawed scorecard must NOT be committed — it exercises the " <>
                 "Plan 06 panel-layer veto, not the mechanical checker gate.\n" <>
                 "Found: #{path}\n" <>
                 "Remove this file and re-run verify.capture (with the flawed pole excluded from the REFUTE_STORIES band)."
      end
    end

    test "veto-ordering polished pole has committed scorecards (polished pole is a valid mechanical baseline)" do
      item = veto_item()
      assert item != nil, "veto_ordering item missing from manifest"

      for bp <- ~w(dark-1280 light-1280) do
        path = scorecard_path("#{item["polished_cell_id"]}__#{bp}")

        assert File.exists?(path),
               "veto-ordering polished scorecard must exist for #{bp}: #{path}"
      end
    end

    test "veto-ordering evidence_note documents the off-token raw hex accent" do
      item = veto_item()
      assert item != nil, "veto_ordering item missing from manifest"

      note = item["evidence_note"]
      assert is_binary(note) and note != "",
             "veto-ordering twin must have a non-empty evidence_note"

      # The note must reference the specific raw hex that Plan 06's token-parity veto
      # will detect in the live DOM (border-left: 3px solid #e8a246 on the diff row).
      assert String.contains?(note, "#e8a246") or
               (String.contains?(note, "raw") and String.contains?(note, "hex")) or
               String.contains?(note, "off-token"),
             "veto-ordering evidence_note must document the off-token raw hex (e.g. #e8a246): #{inspect(note)}"
    end

    # ── partition integrity — refute disjoint from golden ────────────────────

    test "no refute twin_id or cell_id appears in golden-set.json (no teaching-to-the-test)" do
      unless File.exists?(@golden_set) do
        # golden-set.json may not exist yet — it is created in a later plan.
        # When it does not exist there is nothing to be disjoint from.
        :ok
      else
        golden_text = File.read!(@golden_set)
        golden = Jason.decode!(golden_text)
        golden_cell_ids =
          (golden["items"] || [])
          |> Enum.flat_map(fn item ->
            [item["cell_id"], item["twin_id"]]
          end)
          |> Enum.reject(&is_nil/1)
          |> MapSet.new()

        for item <- items() do
          ids_to_check = [item["twin_id"], item["polished_cell_id"], item["flawed_cell_id"]]

          for id <- ids_to_check do
            refute MapSet.member?(golden_cell_ids, id),
                   "refute id #{inspect(id)} appears in #{@golden_set} — " <>
                     "refute must be disjoint from golden (no teaching-to-the-test)"

            # Belt-and-suspenders: raw text scan for any embedded reference.
            refute String.contains?(golden_text, id),
                   "refute id #{inspect(id)} appears as text in #{@golden_set} — " <>
                     "refute must be disjoint from golden"
          end
        end
      end
    end

    # ── helpers ───────────────────────────────────────────────────────────────

    defp manifest, do: @refute_manifest |> File.read!() |> Jason.decode!()
    defp items, do: manifest()["items"]
    defp gestalt_items, do: Enum.filter(items(), &(&1["class"] == "gestalt"))
    defp veto_item, do: Enum.find(items(), &(&1["class"] == "veto_ordering"))
    defp scorecard_path(cell_id), do: Path.join(@scorecard_dir, "#{cell_id}.json")
  end
end
