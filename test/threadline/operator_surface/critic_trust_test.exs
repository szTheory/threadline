if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.CriticTrustTest do
    use ExUnit.Case, async: true

    @ledger_path ".planning/design-system-ledger.json"
    @golden_set_path ".planning/golden/golden-set.json"
    @scorecards_dir ".planning/scorecards"
    @critique_path "CRITIQUE.md"

    @critic_lenses ~w(
      hierarchy
      density
      rhythm
      typography
      color_contrast
      brand_fidelity
    )

    @lens_required_fields ~w(
      alpha
      ci95
      golden_rubric_version
      model_id
      n
      pairwise_acc
      raw_agreement
      validated
    )

    # External SaaS visual-diff tool names and other terms that must never appear
    # in committed CRITIQUE.md output. Mirror the stress_ledger_test forbidden-terms guard.
    @forbidden_terms [
      "Chromatic",
      "Percy",
      "Applitools",
      "Lost Pixel",
      "Pixeleye",
      "BackstopJS",
      "Argos",
      "Happo"
    ]

    # ── Ledger critic_trust block shape ──────────────────────────────────────────

    test "design-system-ledger.json has a critic_trust top-level block" do
      ledger = ledger()
      assert Map.has_key?(ledger, "critic_trust"),
             "#{@ledger_path} is missing top-level 'critic_trust' block"
    end

    test "critic_trust block has exactly the 6 frozen lenses" do
      critic_trust = ledger()["critic_trust"]
      assert is_map(critic_trust), "critic_trust must be a JSON object"

      actual_lenses = critic_trust |> Map.keys() |> Enum.sort()

      assert actual_lenses == Enum.sort(@critic_lenses),
             "critic_trust lenses drifted: expected #{inspect(Enum.sort(@critic_lenses))}, got #{inspect(actual_lenses)}"
    end

    test "every critic_trust lens has the required field set" do
      critic_trust = ledger()["critic_trust"]

      for lens <- @critic_lenses do
        lens_data = Map.fetch!(critic_trust, lens)
        actual_fields = lens_data |> Map.keys() |> Enum.sort()

        assert actual_fields == Enum.sort(@lens_required_fields),
               "critic_trust[#{lens}] field set drifted: expected #{inspect(Enum.sort(@lens_required_fields))}, got #{inspect(actual_fields)}"
      end
    end

    test "every validated critic_trust lens meets the statistical trust bar" do
      # Vacuously passes while all lenses have validated: false.
      # When a lens is promoted to validated: true (Plan 04+), this gate enforces
      # Krippendorff α ≥ 0.67, N ≥ 20, raw_agreement ≥ 0.80, model_id == "claude-opus-4-8".
      critic_trust = ledger()["critic_trust"]

      for lens <- @critic_lenses do
        lens_data = Map.fetch!(critic_trust, lens)

        if lens_data["validated"] == true do
          alpha = lens_data["alpha"]
          n = lens_data["n"]
          raw_agreement = lens_data["raw_agreement"]
          model_id = lens_data["model_id"]

          assert is_number(alpha) and alpha >= 0.67,
                 "critic_trust[#{lens}] validated but alpha #{inspect(alpha)} < 0.67 (Krippendorff bar)"

          assert is_integer(n) and n >= 20,
                 "critic_trust[#{lens}] validated but n=#{n} < 20 (sample-size bar)"

          assert is_number(raw_agreement) and raw_agreement >= 0.80,
                 "critic_trust[#{lens}] validated but raw_agreement #{inspect(raw_agreement)} < 0.80"

          assert model_id == "claude-opus-4-8",
                 "critic_trust[#{lens}] model_id mismatch: expected \"claude-opus-4-8\", got #{inspect(model_id)}"
        end
      end
    end

    # ── Golden set structure ──────────────────────────────────────────────────────

    test "golden-set.json parses and has the required top-level fields" do
      gs = golden_set()
      assert Map.has_key?(gs, "version"), "golden-set.json missing 'version'"
      assert Map.has_key?(gs, "model_pin"), "golden-set.json missing 'model_pin'"
      assert Map.has_key?(gs, "held_out_ids"), "golden-set.json missing 'held_out_ids'"
      assert Map.has_key?(gs, "items"), "golden-set.json missing 'items'"
      assert is_list(gs["items"]), "golden-set.json 'items' must be an array"
      assert is_list(gs["held_out_ids"]), "golden-set.json 'held_out_ids' must be an array"
    end

    test "every golden-set item resolves cell_id to an existing scorecard and has consistent r1/r2 evidence" do
      # Vacuously passes while items: [] (empty skeleton).
      # When items are populated (Plan 06+), this gate enforces:
      # - cell_id → .planning/scorecards/<cell_id>.json exists
      # - r1.evidence and r2.evidence are non-empty strings
      # - r1.verdict == r2.verdict (reconciled before golden promotion)
      items = golden_set()["items"]

      for item <- items do
        cell_id = item["cell_id"]
        scorecard_path = Path.join(@scorecards_dir, "#{cell_id}.json")

        assert File.exists?(scorecard_path),
               "golden-set item #{inspect(item["id"])}: scorecard #{inspect(scorecard_path)} does not exist"

        r1 = item["r1"] || %{}
        r2 = item["r2"] || %{}

        assert is_binary(r1["evidence"]) and r1["evidence"] != "",
               "golden-set item #{inspect(item["id"])}: r1.evidence is empty or missing"

        assert is_binary(r2["evidence"]) and r2["evidence"] != "",
               "golden-set item #{inspect(item["id"])}: r2.evidence is empty or missing"

        assert r1["verdict"] == r2["verdict"],
               "golden-set item #{inspect(item["id"])}: r1.verdict #{inspect(r1["verdict"])} != r2.verdict #{inspect(r2["verdict"])} (not reconciled)"
      end
    end

    # ── Separation of concerns: critic-scores vs scorecards ──────────────────────

    test "no scorecard file in .planning/scorecards/ references .planning/critic-scores" do
      # Assert the critic never writes output under the committed scorecard tree.
      # The critic writes under .planning/critic-scores/ (gitignored); the capture
      # pipeline writes under .planning/scorecards/ (committed).
      if File.dir?(@scorecards_dir) do
        scorecard_files = Path.wildcard(Path.join(@scorecards_dir, "*.json"))

        for path <- scorecard_files do
          content = File.read!(path)

          refute String.contains?(content, ".planning/critic-scores"),
                 "#{path} references .planning/critic-scores/ — scorecards and critic output must remain separate"
        end
      end
    end

    # ── CRITIQUE.md freshness guard (vacuous until Plan 07 lands report.ts) ──────

    test "CRITIQUE.md does not contain forbidden external tool names" do
      # TODO(Plan-07): upgrade to row-per-(cell_id × persona) freshness assertion
      # after report.ts lands and CRITIQUE.md is generated from critic-scores/.
      # Guard with File.exists? so the absence of CRITIQUE.md is a vacuous pass.
      if File.exists?(@critique_path) do
        critique = File.read!(@critique_path)

        for term <- @forbidden_terms do
          refute String.contains?(critique, term),
                 "#{@critique_path} contains forbidden external tool name: #{inspect(term)}"
        end
      end
    end

    # ── Rubric-hash freshness guard (vacuous until Plan 05 lands rubrics/) ────────

    test "validated lens golden_rubric_version matches rubric file hash (vacuous when no rubric files)" do
      # TODO(Plan-05): replace with real rubric hash check once critic/rubrics/*.md land.
      # For now: any lens with validated: true and a non-nil golden_rubric_version should
      # have a matching rubric file. Guarded by File.exists? so absence is a vacuous pass.
      critic_trust = ledger()["critic_trust"]

      for lens <- @critic_lenses do
        lens_data = Map.fetch!(critic_trust, lens)

        if lens_data["validated"] == true do
          rubric_path = "examples/threadline_phoenix/e2e/critic/rubrics/#{lens}.md"
          golden_rubric_version = lens_data["golden_rubric_version"]

          if File.exists?(rubric_path) and not is_nil(golden_rubric_version) do
            # Rubric version format: "<lens>@<semver>+<sha8>" — sha8 is the hash of the file's bytes.
            # The full assertion (sha8 match) is deferred to Plan 05 when the rubric lint CLI lands.
            assert is_binary(golden_rubric_version) and String.contains?(golden_rubric_version, lens),
                   "critic_trust[#{lens}] golden_rubric_version #{inspect(golden_rubric_version)} does not reference #{lens}"
          end
        end
      end
    end

    # ── Helpers ──────────────────────────────────────────────────────────────────

    defp ledger, do: @ledger_path |> File.read!() |> Jason.decode!()
    defp golden_set, do: @golden_set_path |> File.read!() |> Jason.decode!()
  end
end
