if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.CriticTrustTest do
    use ExUnit.Case, async: true

    @ledger_path ".planning/design-system-ledger.json"
    @golden_set_path ".planning/golden/golden-set.json"
    @synthetic_set_path ".planning/golden/synthetic-set.json"
    @scorecards_dir ".planning/scorecards"
    @critic_scores_dir ".planning/critic-scores"
    @critique_path "CRITIQUE.md"
    @rubrics_dir "examples/threadline_phoenix/e2e/critic/rubrics"

    @critic_lenses ~w(
      hierarchy
      density
      rhythm
      typography
      color_contrast
      brand_fidelity
    )

    # ── Frozen gate panel membership (GATE-04, 196-D2) ────────────────────────────
    # The blocking panel = the 4 validated lenses; hierarchy/color_contrast are advisory
    # only (never auto-block). This is the recorded human sign-off (196-CONTEXT.md#196-D2):
    # a silent membership change fails the frozen-constant equality below and requires
    # both editing these constants AND an appended ledger sign-off.
    @blocking_panel ~w(brand_fidelity density typography rhythm)
    @advisory_panel ~w(hierarchy color_contrast)

    # ── Frozen ratchet baselines (GATE-04, 196-D4/196-D5) ────────────────────────
    # Committed snapshot of the quality-bar floors. A DOWNWARD move of any value
    # below its baseline (or removal of a guarded id) requires a matching appended
    # `ratchet.signoffs` entry — a silent target/floor drop fails the no-silent-drop
    # clause below. Upward moves are always allowed (>=). Vacuous-safe: baseline ==
    # current == seeded values, signoffs [] → every `>=` holds, no signoff required.
    @baseline_trust_floors %{
      "brand_fidelity" => 0.85,
      "density" => 0.78,
      "typography" => 0.72,
      "rhythm" => 0.72
    }

    # Frozen snapshot of ratchet.minimum_scores (committed baseline). Silent lowering
    # of any id below these — or deletion of an id — trips the no-silent-drop clause
    # unless a target_change/ratchet_bump signoff records the exact new value.
    @baseline_minimum_scores %{
      "footgun.coverage-schema-card-declutter" => 25,
      "footgun.transaction-page-left-push-desktop" => 25,
      "form-control.checkbox.current" => 35,
      "form-control.date-range.current" => 35,
      "form-control.input.current" => 35,
      "form-control.radio.current" => 35,
      "form-control.search.current" => 35,
      "form-control.select.current" => 35,
      "form-control.textarea.current" => 35,
      "foundation.color" => 62,
      "foundation.density" => 62,
      "foundation.motion" => 62,
      "foundation.radius" => 62,
      "foundation.shadow" => 62,
      "foundation.spacing" => 62,
      "foundation.typography" => 62,
      "foundation.z-index" => 62,
      "future.theme-picker-idiomatic-ui" => 20,
      "group.data-panel.current" => 62,
      "group.detail-header.current" => 62,
      "group.drawer-form.reference" => 62,
      "group.empty-cta.current" => 62,
      "group.modal-destructive.current" => 62,
      "group.offline.current" => 62,
      "group.page-header.current" => 62,
      "group.permission-denied.current" => 62,
      "group.stats-chart-table.current" => 62,
      "group.tabs-subviews.reference" => 62,
      "group.toast-update.current" => 62,
      "group.toolbar.current" => 62,
      "page.actor.advanced" => 62,
      "page.actor.boundary" => 62,
      "page.actor.empty" => 62,
      "page.actor.error" => 62,
      "page.actor.happy" => 62,
      "page.actor.loading" => 62,
      "page.actor.permission" => 62,
      "page.coverage.advanced" => 62,
      "page.coverage.boundary" => 62,
      "page.coverage.empty" => 62,
      "page.coverage.error" => 62,
      "page.coverage.happy" => 62,
      "page.coverage.loading" => 62,
      "page.coverage.permission" => 62,
      "page.evidence.advanced" => 62,
      "page.evidence.boundary" => 62,
      "page.evidence.empty" => 62,
      "page.evidence.error" => 62,
      "page.evidence.happy" => 62,
      "page.evidence.loading" => 62,
      "page.evidence.permission" => 62,
      "page.exports.advanced" => 62,
      "page.exports.boundary" => 62,
      "page.exports.empty" => 62,
      "page.exports.error" => 62,
      "page.exports.happy" => 62,
      "page.exports.loading" => 62,
      "page.exports.permission" => 62,
      "page.home.advanced" => 62,
      "page.home.boundary" => 62,
      "page.home.empty" => 62,
      "page.home.error" => 62,
      "page.home.happy" => 72,
      "page.home.loading" => 62,
      "page.home.permission" => 62,
      "page.redaction.advanced" => 62,
      "page.redaction.boundary" => 62,
      "page.redaction.empty" => 62,
      "page.redaction.error" => 62,
      "page.redaction.happy" => 62,
      "page.redaction.loading" => 62,
      "page.redaction.permission" => 62,
      "page.retention.advanced" => 62,
      "page.retention.boundary" => 62,
      "page.retention.empty" => 62,
      "page.retention.error" => 62,
      "page.retention.happy" => 62,
      "page.retention.loading" => 62,
      "page.retention.permission" => 62,
      "page.row-history.advanced" => 62,
      "page.row-history.boundary" => 62,
      "page.row-history.empty" => 62,
      "page.row-history.error" => 62,
      "page.row-history.happy" => 62,
      "page.row-history.loading" => 62,
      "page.row-history.permission" => 62,
      "page.shell.advanced" => 62,
      "page.shell.boundary" => 62,
      "page.shell.empty" => 62,
      "page.shell.error" => 62,
      "page.shell.happy" => 62,
      "page.shell.loading" => 62,
      "page.shell.permission" => 62,
      "page.timeline.advanced" => 62,
      "page.timeline.boundary" => 62,
      "page.timeline.empty" => 72,
      "page.timeline.error" => 62,
      "page.timeline.happy" => 62,
      "page.timeline.loading" => 62,
      "page.timeline.permission" => 62,
      "page.transaction.advanced" => 62,
      "page.transaction.boundary" => 62,
      "page.transaction.empty" => 62,
      "page.transaction.error" => 62,
      "page.transaction.happy" => 62,
      "page.transaction.loading" => 62,
      "page.transaction.permission" => 62,
      "primitive.icon.reserved" => 35,
      "primitive.logo.reserved" => 35,
      "primitive.surface-header.current" => 72,
      "primitive.unsupported-view.reserved" => 35,
      "state.empty" => 62,
      "state.many" => 62,
      "state.mixed-severity" => 62,
      "state.null-fields" => 62,
      "state.one" => 62,
      "state.pagination-boundary" => 62,
      "state.permission-denied" => 62,
      "state.stale-reconnecting" => 62,
      "state.timezone-boundary" => 62
    }

    # Append-only pin of the known-good ratchet.signoffs set (currently empty). Every
    # object listed here must remain present in the live array — signoffs are never
    # rewritten or dropped. When a real signoff is appended, add it here too.
    @known_signoffs []

    @lens_required_fields ~w(
      spearman
      auc
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

    # Persona labels used in CRITIQUE.md rows (one row per cell × persona).
    @scorecard_personas ~w(p1 p2 p3 p4 p5 all)

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

    test "every validated critic_trust lens meets the full statistical trust bar" do
      # Vacuously passes while all lenses have validated: false.
      # When a lens is promoted to validated: true, this gate enforces the per-lens bar:
      #   spearman >= 0.7 — rank correlation oracle-severity vs critic score [PRIMARY GATE]
      #   n >= 20         — minimum sample size
      #   auc / alpha / raw_agreement — recorded companions only; NOT gated (D-12 rev v2)
      #   model_id == "claude-opus-4-8" — single model pin
      #   golden_rubric_version == "<lens>@<semver>+<sha8>" where sha8 is recomputed
      #     from the current disk bytes of rubrics/<lens>.md (rubric-hash freshness)
      critic_trust = ledger()["critic_trust"]

      for lens <- @critic_lenses do
        lens_data = Map.fetch!(critic_trust, lens)

        if lens_data["validated"] == true do
          spearman = lens_data["spearman"]
          n = lens_data["n"]
          model_id = lens_data["model_id"]
          golden_rubric_version = lens_data["golden_rubric_version"]

          assert is_number(spearman) and spearman >= 0.7,
                 "critic_trust[#{lens}] validated but spearman #{inspect(spearman)} < 0.7 (ranking bar)"

          assert is_integer(n) and n >= 20,
                 "critic_trust[#{lens}] validated but n=#{n} < 20 (sample-size bar)"

          # D-12 rev v2: auc/alpha/raw_agreement are reported-only companions, NOT gates
          # (ρ is the trust bar). Assert they are recorded, but never threshold them.
          assert is_number(lens_data["auc"]),
                 "critic_trust[#{lens}] validated but auc #{inspect(lens_data["auc"])} is not recorded"

          assert model_id == "claude-opus-4-8",
                 "critic_trust[#{lens}] model_id mismatch: expected \"claude-opus-4-8\", got #{inspect(model_id)}"

          # Rubric-hash freshness: the sha8 in golden_rubric_version must match
          # the sha8 computed from current rubric bytes. A rubric bump
          # auto-invalidates the lens until it is re-scored.
          assert is_binary(golden_rubric_version),
                 "critic_trust[#{lens}] validated but golden_rubric_version is nil"

          rubric_path = Path.join(@rubrics_dir, "#{lens}.md")
          stamped_sha8 = extract_sha8_from_version(golden_rubric_version)

          # While a rubric is unstamped (placeholder "00000000"), the sha8 freshness
          # sub-check is vacuous — the dedicated rubric-hash guard covers stamped
          # rubrics. Once stamped, the stamped sha8 must match the normalised disk hash
          # (sha8 field set to placeholder), matching the header-stamping convention.
          if File.exists?(rubric_path) and stamped_sha8 != "00000000" do
            normalised = normalise_sha8(File.read!(rubric_path), "00000000")
            disk_sha8 = sha8_of_string(normalised)

            assert stamped_sha8 == disk_sha8,
                   "critic_trust[#{lens}] rubric-hash mismatch: " <>
                     "golden_rubric_version stamped sha8 #{inspect(stamped_sha8)} " <>
                     "!= recomputed sha8 from disk #{inspect(disk_sha8)}. " <>
                     "The rubric has changed since validation — set validated:false " <>
                     "and re-score (T-195-11)."
          end
        end
      end
    end

    # ── Panel-membership freeze (GATE-04, 196-D2) ────────────────────────────────
    # The critic_panel block is the append-only recorded sign-off of which lenses block
    # vs advise. Freeze membership against the module constants and cross-check it against
    # the per-lens critic_trust validated flags: every blocking lens must be validated,
    # every advisory lens must not be. A silent panel change (promotion/demotion) without
    # a matching ledger edit + sign-off fails here. Vacuous-safe: the seeded block already
    # matches the frozen constants and the current validated flags.

    test "critic_panel block freezes blocking/advisory membership and agrees with validated flags" do
      ledger = ledger()
      critic_panel = ledger["critic_panel"]

      assert is_map(critic_panel),
             "#{@ledger_path} is missing top-level 'critic_panel' block (GATE-04 baseline)"

      assert critic_panel["blocking"] == @blocking_panel,
             "critic_panel.blocking drifted: expected #{inspect(@blocking_panel)}, " <>
               "got #{inspect(critic_panel["blocking"])}. A panel-membership change requires " <>
               "editing @blocking_panel AND an appended ledger sign-off (GATE-04, 196-D2)."

      assert critic_panel["advisory"] == @advisory_panel,
             "critic_panel.advisory drifted: expected #{inspect(@advisory_panel)}, " <>
               "got #{inspect(critic_panel["advisory"])}."

      critic_trust = ledger["critic_trust"]

      for lens <- @blocking_panel do
        assert critic_trust[lens]["validated"] == true,
               "blocking lens #{lens} must be validated:true in critic_trust (GATE-04): " <>
                 "an unvalidated lens cannot block."
      end

      for lens <- @advisory_panel do
        assert critic_trust[lens]["validated"] == false,
               "advisory lens #{lens} must be validated:false in critic_trust (GATE-04): " <>
                 "a validated lens must not sit on the advisory panel without a sign-off."
      end
    end

    # ── GATE-04 append-only guards: no silent target/floor drop (196-D5) ──────────
    # The quality bar can only move DOWN behind a recorded, append-only signoff.
    # For every frozen baseline floor (critic_panel.trust_floors + ratchet.minimum_scores),
    # the current value must be >= its committed baseline UNLESS a matching
    # target_change/ratchet_bump signoff records the exact new (lower) value. A silent
    # drop — or the outright removal of a guarded id — turns this clause red.
    # Vacuous-safe: at seed, current == baseline and signoffs == [], so every >= holds.

    test "no silent trust-floor drop below the committed baseline without a signoff (GATE-04, 196-D5)" do
      ledger = ledger()
      trust_floors = get_in(ledger, ["critic_panel", "trust_floors"]) || %{}
      signoffs = get_in(ledger, ["ratchet", "signoffs"]) || []

      for {lens, baseline} <- @baseline_trust_floors do
        current = trust_floors[lens]

        assert is_number(current),
               "critic_panel.trust_floors[#{lens}] is missing (baseline #{baseline}) — a blocking-lens " <>
                 "floor was removed; this needs a target_change/ratchet_bump signoff (GATE-04, 196-D5)."

        unless current >= baseline do
          assert signoff_records_drop?(signoffs, ~w(target_change ratchet_bump), lens, current),
                 "critic_panel.trust_floors[#{lens}] dropped from committed baseline #{baseline} to " <>
                   "#{current} with no matching target_change/ratchet_bump signoff whose after=#{current}. " <>
                   "A silent quality-bar drop is blocked (GATE-04, 196-D5)."
        end
      end
    end

    test "no silent ratchet.minimum_scores drop below the committed baseline without a signoff (GATE-04, 196-D5)" do
      ledger = ledger()
      minimum_scores = get_in(ledger, ["ratchet", "minimum_scores"]) || %{}
      signoffs = get_in(ledger, ["ratchet", "signoffs"]) || []

      for {id, baseline} <- @baseline_minimum_scores do
        current = minimum_scores[id]

        assert is_number(current),
               "ratchet.minimum_scores[#{id}] is missing (baseline #{baseline}) — a guarded score floor " <>
                 "was removed; a downward/removal move needs a target_change/ratchet_bump signoff (GATE-04, 196-D5)."

        unless current >= baseline do
          assert signoff_records_drop?(signoffs, ~w(target_change ratchet_bump), id, current),
                 "ratchet.minimum_scores[#{id}] dropped from committed baseline #{baseline} to #{current} " <>
                   "with no matching target_change/ratchet_bump signoff whose after=#{current}. " <>
                   "A silent quality-bar drop is blocked (GATE-04, 196-D5)."
        end
      end
    end

    # ── GATE-04 append-only guard: no fixture/oracle-cell removal (196-D4) ────────
    # The synthetic true-north oracle can only shrink behind a recorded fixture_removal
    # signoff. Guards: (a) the synthetic set's item count never drops below the recorded
    # oracle_inventory.synthetic_item_count, and (b) every recorded held_out_id stays
    # present in the synthetic set. Vacuous-safe: recorded count == 144 == actual,
    # held_out_ids == [] at seed.

    test "no silent oracle/fixture removal below the recorded inventory without a signoff (GATE-04, 196-D4)" do
      ledger = ledger()
      oracle_inventory = get_in(ledger, ["critic_panel", "oracle_inventory"]) || %{}
      recorded_count = oracle_inventory["synthetic_item_count"]
      recorded_held_out = oracle_inventory["held_out_ids"] || []
      signoffs = get_in(ledger, ["ratchet", "signoffs"]) || []

      assert is_integer(recorded_count),
             "critic_panel.oracle_inventory.synthetic_item_count is missing or non-integer (GATE-04, 196-D4)."

      assert File.exists?(@synthetic_set_path),
             "critic_panel.oracle_inventory records #{recorded_count} synthetic items but " <>
               "#{@synthetic_set_path} is missing — the true-north oracle cannot silently vanish (GATE-04, 196-D4)."

      syn = synthetic_set()
      actual_count = length(syn["items"] || [])

      unless actual_count >= recorded_count do
        assert Enum.any?(signoffs, &(&1["kind"] == "fixture_removal")),
               "synthetic-set item count #{actual_count} < recorded oracle_inventory.synthetic_item_count " <>
                 "#{recorded_count} with no fixture_removal signoff — the oracle inventory cannot silently " <>
                 "shrink (GATE-04, 196-D4)."
      end

      actual_held_out = syn["held_out_ids"] || []

      for held_out <- recorded_held_out do
        unless held_out in actual_held_out do
          assert signoff_records_removal?(signoffs, held_out),
                 "recorded held_out_id #{inspect(held_out)} is no longer present in the synthetic set " <>
                   "held_out_ids with no fixture_removal signoff recording it — the frozen true-north " <>
                   "slice cannot silently lose cells (GATE-04, 196-D4)."
        end
      end
    end

    # ── GATE-04 append-only enforcement: signoffs never rewritten/dropped ─────────

    test "ratchet.signoffs is append-only — every pinned known-good signoff is still present (GATE-04)" do
      signoffs = get_in(ledger(), ["ratchet", "signoffs"]) || []

      assert is_list(signoffs),
             "ratchet.signoffs must be an array (the append-only sign-off home)."

      for pinned <- @known_signoffs do
        assert pinned in signoffs,
               "a previously-committed ratchet.signoffs entry disappeared: #{inspect(pinned)}. " <>
                 "Sign-offs are append-only and must never be rewritten or dropped (GATE-04)."
      end
    end

    # ── Provenance / honest-oracle guards (D-12) ─────────────────────────────────
    # The synthetic twin oracle (D-12) lets a lens validate against constructed
    # graded-twin labels instead of human labels. That is a WEAKER epistemic object
    # (it proves the critic tracks known-severity flaws monotonically, NOT that it
    # matches human taste), so every validated lens must carry an honest, non-null
    # provenance marker — no silent/unlabeled promotions.

    test "ledger has a sibling critic_trust_provenance block with the fixed field set" do
      provenance = ledger()["critic_trust_provenance"]
      assert is_map(provenance), "#{@ledger_path} missing sibling 'critic_trust_provenance' block"

      assert provenance |> Map.keys() |> Enum.sort() ==
               Enum.sort(~w(oracle set_version generated_from)),
             "critic_trust_provenance field set drifted: got #{inspect(Map.keys(provenance))}"
    end

    test "any validated lens requires a non-null provenance oracle (no unlabeled promotion)" do
      ledger = ledger()
      critic_trust = ledger["critic_trust"]
      oracle = get_in(ledger, ["critic_trust_provenance", "oracle"])

      any_validated? = Enum.any?(@critic_lenses, &(critic_trust[&1]["validated"] == true))

      if any_validated? do
        assert oracle in ["human", "synthetic"],
               "a lens is validated:true but critic_trust_provenance.oracle is #{inspect(oracle)} " <>
                 "— every promotion must record which oracle produced it (D-12)"
      end
    end

    test "a synthetic oracle is honestly recorded and backed by the synthetic set" do
      provenance = ledger()["critic_trust_provenance"]

      if provenance["oracle"] == "synthetic" do
        assert provenance["generated_from"] == "graded-twin-ladder",
               "synthetic oracle must record generated_from: \"graded-twin-ladder\", " <>
                 "got #{inspect(provenance["generated_from"])}"

        assert File.exists?(@synthetic_set_path),
               "provenance claims a synthetic oracle but #{@synthetic_set_path} is missing"

        set = @synthetic_set_path |> File.read!() |> Jason.decode!()

        assert set["golden_source"] == "synthetic",
               "#{@synthetic_set_path} must declare golden_source: \"synthetic\" (D-12 honesty)"
      end
    end

    # ── Rubric-hash freshness guard ───────────────────────────────────────────────
    # Recomputes each rubric's sha8 from disk and asserts it matches the sha8
    # stamped in the rubric file header. This guard fires for EVERY existing
    # rubric file (not just validated lenses) — a header sha8 mismatch means
    # the file was edited but the header was not re-stamped by `critic rubric bump`.

    test "each rubric file's header sha8 matches the sha8 of its disk bytes" do
      # The header format is: <!-- lens: <l> | version: <v> | sha8: <h> -->
      # The sha8 in the header is computed from the file bytes with the sha8
      # field set to the placeholder 00000000 (so the hash is stable).
      # Plan-05 lands `critic rubric lint` which stamps the real hash;
      # Plan-04 implements the guard that will catch drift after stamping.
      # While all sha8 values are 00000000 (placeholder), this test is vacuous
      # for actual hash verification but asserts the header is parseable and
      # the format is correct.
      for lens <- @critic_lenses do
        rubric_path = Path.join(@rubrics_dir, "#{lens}.md")

        if File.exists?(rubric_path) do
          content = File.read!(rubric_path)

          # Parse the header: <!-- lens: X | version: Y | sha8: Z -->
          header_sha8 = extract_header_sha8(content)

          assert is_binary(header_sha8),
                 "rubric #{rubric_path} is missing a parseable sha8 in the header comment"

          # When sha8 is a real hash (not the 00000000 placeholder), verify it
          # matches the sha8 computed from the file bytes (with the sha8 field
          # normalised to 00000000 so the hash is self-consistent).
          if header_sha8 != "00000000" do
            normalised_content = normalise_sha8(content, "00000000")
            disk_sha8 = sha8_of_string(normalised_content)

            assert header_sha8 == disk_sha8,
                   "rubric #{lens}.md header sha8 #{inspect(header_sha8)} does not match " <>
                     "the sha8 of disk bytes (with placeholder) #{inspect(disk_sha8)}. " <>
                     "Run `critic rubric lint` to re-stamp (T-195-11)."
          end
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

    # ── Held-out guard ────────────────────────────────────────────────────────────
    # held_out_ids are the Phase-196 true-north slice — they must never appear
    # in golden-set items (the labeling + agreement pool). Contamination would
    # teach-to-the-test (FWD-2 from PITFALLS.md).

    test "no held_out_id appears in golden-set items (frozen true-north must stay separate)" do
      gs = golden_set()
      held_out_ids = gs["held_out_ids"]
      item_cell_ids = Enum.map(gs["items"], & &1["cell_id"])

      for held_out <- held_out_ids do
        refute held_out in item_cell_ids,
               "golden-set held_out_id #{inspect(held_out)} was found in 'items' — " <>
                 "held-out cells are the Phase-196 true-north slice and must never " <>
                 "be included in the labeling pool (FWD-2)"
      end
    end

    # ── Prefix-exemplar disjointness guard ───────────────────────────────────────
    # Each rubric's ## Anchors block names one pass-pole and one fail-pole
    # (by cell-id) that are embedded in the prompt's cached prefix as few-shot
    # calibration examples. These poles must NEVER overlap with golden mid-range
    # items or held_out_ids — teaching-to-the-test would inflate α (D-05, T-195-12).

    test "rubric pole cell-ids are disjoint from golden mid-range items and held_out_ids" do
      gs = golden_set()
      # D-12: the synthetic oracle validates the critic on graded rungs, so the rubric
      # anchor poles must be disjoint from BOTH the human golden set AND the synthetic
      # set (else the few-shot poles would be graded — teaching-to-the-test on the exact
      # calibration exemplars). The intermediate rungs the rubric never showed are the
      # held-out interpolation cells that carry the real signal.
      syn = synthetic_set()
      held_out_ids = (gs["held_out_ids"] || []) ++ (syn["held_out_ids"] || [])

      mid_range_ids =
        Enum.map(gs["items"], & &1["cell_id"]) ++ Enum.map(syn["items"], & &1["cell_id"])

      forbidden_ids = MapSet.new(held_out_ids ++ mid_range_ids)

      for lens <- @critic_lenses do
        rubric_path = Path.join(@rubrics_dir, "#{lens}.md")

        if File.exists?(rubric_path) do
          pole_ids = extract_pole_ids(rubric_path)

          for pole_id <- pole_ids do
            refute MapSet.member?(forbidden_ids, pole_id),
                   "rubric #{lens} pole #{inspect(pole_id)} appears in golden mid-range " <>
                     "or held_out_ids — this teaches-to-the-test and inflates α (D-05, T-195-12)"
          end
        end
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

    # ── CRITIQUE.md guards ────────────────────────────────────────────────────────

    test "CRITIQUE.md does not contain forbidden external tool names" do
      # Guard with File.exists? so the absence of CRITIQUE.md is a vacuous pass.
      if File.exists?(@critique_path) do
        critique = File.read!(@critique_path)

        for term <- @forbidden_terms do
          refute String.contains?(critique, term),
                 "#{@critique_path} contains forbidden external tool name: #{inspect(term)}"
        end
      end
    end

    test "CRITIQUE.md has one row per (cell_id × persona) for every scored cell (vacuous until Plan 07)" do
      # Vacuously passes while CRITIQUE.md does not exist (Plan 07 creates it via report.ts).
      # When CRITIQUE.md exists AND critic-scores/ is non-empty, assert one row
      # per (cell_id × persona) is a substring — mirrors the DESIGN-SYSTEM.md
      # freshness guard in stress_ledger_test.exs.
      if File.exists?(@critique_path) and File.dir?(@critic_scores_dir) do
        critique = File.read!(@critique_path)

        scored_cell_ids =
          Path.wildcard(Path.join(@critic_scores_dir, "*/"))
          |> Enum.map(&Path.basename/1)
          |> Enum.sort()

        for cell_id <- scored_cell_ids, persona <- @scorecard_personas do
          # Each row begins with the cell_id and persona columns
          row_prefix = "| `#{cell_id}` | #{persona} |"

          assert String.contains?(critique, row_prefix),
                 "#{@critique_path} is stale: missing row for #{cell_id} × #{persona}. " <>
                   "Run `mix verify.ui_critique` to regenerate."
        end
      end
    end

    # ── Helpers ──────────────────────────────────────────────────────────────────

    defp ledger, do: @ledger_path |> File.read!() |> Jason.decode!()
    defp golden_set, do: @golden_set_path |> File.read!() |> Jason.decode!()

    # True iff some append-only signoff justifies a downward move: its `kind` is one of
    # the accepted kinds, it targets `id`, and its recorded `after` equals the new value.
    defp signoff_records_drop?(signoffs, kinds, id, new_value) when is_list(signoffs) do
      Enum.any?(signoffs, fn s ->
        s["kind"] in kinds and signoff_targets?(s, id) and s["after"] == new_value
      end)
    end

    defp signoff_records_drop?(_, _, _, _), do: false

    # True iff some fixture_removal signoff records the removal of `id` (via a single
    # `id`/`target` field or a `removed_ids`/`ids` list).
    defp signoff_records_removal?(signoffs, id) when is_list(signoffs) do
      Enum.any?(signoffs, fn s ->
        s["kind"] == "fixture_removal" and signoff_targets?(s, id)
      end)
    end

    defp signoff_records_removal?(_, _), do: false

    # A signoff "targets" `id` if it names it in any of the accepted single-value or
    # list-valued target fields.
    defp signoff_targets?(s, id) do
      id in [s["id"], s["target"], s["lens"]] or
        id in (s["ids"] || []) or
        id in (s["targets"] || []) or
        id in (s["removed_ids"] || [])
    end

    # Synthetic twin oracle set (D-12); absent → an empty set (vacuous guards).
    defp synthetic_set do
      if File.exists?(@synthetic_set_path) do
        @synthetic_set_path |> File.read!() |> Jason.decode!()
      else
        %{"items" => [], "held_out_ids" => []}
      end
    end

    # Extract the sha8 from a golden_rubric_version string like "hierarchy@1.0.0+ab3f1234"
    defp extract_sha8_from_version(version) when is_binary(version) do
      case String.split(version, "+") do
        [_prefix, sha8] -> sha8
        _ -> nil
      end
    end

    defp extract_sha8_from_version(_), do: nil

    # Compute sha8 of a binary string.
    defp sha8_of_string(content) when is_binary(content) do
      :crypto.hash(:sha256, content)
      |> Base.encode16(case: :lower)
      |> String.slice(0, 8)
    end

    # Replace the sha8 value in a rubric header with a normalised placeholder.
    # This allows computing a self-consistent hash (the hash of the file content
    # with the sha8 field zeroed out).
    defp normalise_sha8(content, placeholder) when is_binary(content) do
      Regex.replace(~r/(\|\s*sha8:\s*)[0-9a-f]{8}/, content, "\\1#{placeholder}")
    end

    # Parse the sha8 value from the rubric file's HTML comment header:
    # <!-- lens: X | version: Y | sha8: HHHHHHHH -->
    defp extract_header_sha8(content) when is_binary(content) do
      case Regex.run(~r/<!--.*sha8:\s*([0-9a-f]+).*-->/, content) do
        [_, sha8] -> sha8
        _ -> nil
      end
    end

    # Parse the pass-pole and fail-pole cell-ids from a rubric's ## Anchors block.
    # Pattern: **Pass pole:** `<cell_id>`  or  **Fail pole:** `<cell_id>`
    defp extract_pole_ids(rubric_path) do
      content = File.read!(rubric_path)

      Regex.scan(~r/\*\*(?:Pass|Fail) pole:\*\*\s+`([^`]+)`/, content)
      |> Enum.map(fn [_, cell_id] -> cell_id end)
    end
  end
end
