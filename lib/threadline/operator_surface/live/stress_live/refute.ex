if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StressLive.Refute do
    @moduledoc false

    # Refute-twin render helpers: copy and inline styles for each twin pair
    # (polished + flawed) and for the graded-ladder rungs rendered by the stress lab.

    def twin(%{data: data}) when is_map(data), do: Map.get(data, :twin)
    def twin(_), do: nil

    defp pole(%{data: data}) when is_map(data), do: Map.get(data, :pole)
    defp pole(_), do: nil

    # Severity rung for a graded-ladder story. Binary twins carry no
    # :rung, so they map back to the two extremes (flawed → :r2 "bad", polished → :r4)
    # keeping the existing pole render byte-identical.
    defp rung(%{data: %{rung: rung}}) when not is_nil(rung), do: rung
    defp rung(%{data: %{pole: :flawed}}), do: :r2
    defp rung(_), do: :r4

    # Twin 1: Rhythm — the flaw is UNEVEN vertical cadence, NOT spacing magnitude.
    # Uniform spacing at any size still reads as coherent rhythm (the critic correctly
    # rates it fine), so severity is graded by how ERRATIC the between-section gaps are:
    #   r4 even (coherent) → r3 one gap off → r2 alternating → r1 wildly erratic.
    # Erratic gaps break BOTH vertical_cadence_coherence AND grouping_by_proximity
    # (related items no longer consistently closer than unrelated). All gaps are on-grid
    # --tl-space-* tokens, so every rung passes MODE A + MODE B (gestalt flaw only).
    def rhythm_style(story, index) do
      gap = rhythm_gap(rung(story), rem(index, 3))

      "padding: var(--tl-space-3) 0 0 0; margin-bottom: #{gap}; border-bottom: 1px solid var(--tl-color-border);"
    end

    # Per-(rung, section-index) between-section gap. Variance across the sequence is the
    # cadence signal, spread so all four rungs separate (the critic saturates to "fail"
    # if bad ≈ broken, so bad must stay readable):
    #   r4 [16,16,16] even · r3 [16,24,16] one mild bump · r2 [12,32,16] one clear
    #   deviation (still breathable) · r1 [4,48,8] cramped-then-floating (broken).
    defp rhythm_gap(:r4, _), do: "var(--tl-space-4)"
    defp rhythm_gap(:r3, 1), do: "var(--tl-space-6)"
    defp rhythm_gap(:r3, _), do: "var(--tl-space-4)"
    defp rhythm_gap(:r2, 0), do: "var(--tl-space-3)"
    defp rhythm_gap(:r2, 1), do: "var(--tl-space-8)"
    defp rhythm_gap(:r2, _), do: "var(--tl-space-4)"
    defp rhythm_gap(:r1, 0), do: "var(--tl-space-1)"
    defp rhythm_gap(:r1, 1), do: "var(--tl-space-12)"
    defp rhythm_gap(:r1, _), do: "var(--tl-space-2)"

    # Distinct per-scenario content for the graded rhythm ladder (avoids pseudo-
    # replication: each scenario is genuinely different operator copy). Binary twins and
    # any unlisted scenario fall back to the original three-section reference content.
    def rhythm_sections(story) do
      case Map.get(story.data, :scenario) do
        "coverage" ->
          [
            {"Trigger coverage", "3 of 12 audited tables have live trigger coverage."},
            {"Uncovered", "9 tables have no capture wired — enable before the next audit."},
            {"Last checked", "Coverage recomputed 2026-07-01 during the nightly sweep."}
          ]

        "retention" ->
          [
            {"Retention window", "Audit records are retained for 90 days by policy."},
            {"Next prune", "The scheduled prune runs 2026-09-30 at 02:00 UTC."},
            {"Redaction", "2 fields are masked at rest under the current redaction rule."}
          ]

        "exports" ->
          [
            {"Recent exports", "4 CSV exports generated in the last 30 days."},
            {"Largest", "The March export covered 18,204 change records."},
            {"Delivery", "Exports are delivered to the operator inbox, never emailed."}
          ]

        "evidence" ->
          [
            {"Evidence status", "Proof records are current as of 2026-07-01."},
            {"Open chains", "1 evidence chain awaits a countersignature."},
            {"Integrity", "All captured hashes verified on the last integrity run."}
          ]

        "actor" ->
          [
            {"Actor", "Changes attributed to admin@example.com via the console."},
            {"Intent", "Role change recorded with an explicit operator reason."},
            {"Correlation", "Tied to request req_9f2 across the job boundary."}
          ]

        _ ->
          [
            {"Audit activity", "24 changes captured in the last 30 days for this schema."},
            {"Evidence status", "Proof records current as of 2026-07-01."},
            {"Retention", "Retention window: 90 days. Next prune: 2026-09-30."}
          ]
      end
    end

    # Twin 2: Density (card-section-wrap) — polished is a plain div, flaw wraps in .tl-card styles.
    # Nesting depth stays ≤ 2 (content in card); passes the depth-3 ceiling.
    def card_wrap_style(story) do
      case pole(story) do
        :flawed ->
          "padding: var(--tl-space-4); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md); background: var(--tl-color-bg);"

        _ ->
          "padding: var(--tl-space-4);"
      end
    end

    # Twin 3: Hierarchy — graded visual-weight/size cascade mirrors the @typo_scale shape.
    # r4 gives a clear meta < body < subtitle < title size+weight progression so one
    # element (the title) owns the emphasis budget; worse rungs progressively flatten the
    # cascade until r1 is near-uniform (nothing dominates). Both scored dims degrade together
    # — entry_point_clarity/scan_path AND emphasis_discipline — keeping min()-rollup signal on
    # each (the rhythm lesson: never leave a dimension a noise floor). Every size is a
    # --tl-font-size-* token and ≥2 distinct sizes render at every rung, so all four rungs pass
    # MODE A + MODE B (gestalt flaw only). Binary twins map flawed→r2, polished→r4 via
    # rung/1, so the polished/flawed poles remain gestalt-flaw-only as before.
    # WIDENED 2026-07-28 (rescue attempt): the first ladder crushed the critic into a 65-75
    # band (ρ0.086) — rungs too subtle to grade in a clipped card. This spreads the rungs to the
    # maximum on-token contrast range so separability is unambiguous: r4 is a commanding
    # display(32px)/700 title over a full 4-size descent; r1's "title" is NOT larger than body
    # (both 16px, weight 500 vs 400) with only meta(xs) breaking the flat — near-zero hierarchy.
    # If the critic still can't order THIS, it's a capability ceiling, not ladder subtlety.
    # Every rung still renders >=2 distinct --tl-font-size-* tokens (MODE-B floor).
    @hierarchy_scale %{
      r4: %{
        meta: {"xs", 400},
        title: {"display", 700},
        subtitle: {"heading", 600},
        body: {"body", 400}
      },
      r3: %{
        meta: {"xs", 400},
        title: {"title", 700},
        subtitle: {"heading", 500},
        body: {"body", 400}
      },
      r2: %{
        meta: {"label", 500},
        title: {"heading", 600},
        subtitle: {"body", 500},
        body: {"body", 400}
      },
      r1: %{meta: {"xs", 400}, title: {"body", 500}, subtitle: {"body", 400}, body: {"body", 400}}
    }

    def hierarchy_role_style(story, role) do
      {size, weight} = @hierarchy_scale |> Map.fetch!(rung(story)) |> Map.fetch!(role)
      color = if role == :meta, do: "var(--tl-color-muted)", else: "var(--tl-color-text)"

      "font-size: var(--tl-font-size-#{size}); font-weight: #{weight}; color: #{color}; margin: 0 0 var(--tl-space-2) 0;"
    end

    # Distinct per-scenario hierarchy copy (pseudo-replication honesty; mirrors the rhythm ladder).
    def hierarchy_lines(story) do
      case Map.get(story.data, :scenario) do
        "coverage" ->
          %{
            meta: "Operator / Coverage",
            title: "Trigger coverage",
            subtitle: "3 of 12 tables",
            body: "9 audited tables have no capture wired — enable before the next audit."
          }

        "retention" ->
          %{
            meta: "Operator / Retention",
            title: "Retention policy",
            subtitle: "90-day window",
            body: "The next scheduled prune runs 2026-09-30 at 02:00 UTC."
          }

        "exports" ->
          %{
            meta: "Operator / Exports",
            title: "Recent exports",
            subtitle: "Last 30 days",
            body: "4 CSV exports generated; the largest covered 18,204 change records."
          }

        "evidence" ->
          %{
            meta: "Operator / Evidence",
            title: "Evidence status",
            subtitle: "As of 2026-07-01",
            body: "Proof records are current; 1 evidence chain awaits a countersignature."
          }

        "actor" ->
          %{
            meta: "Operator / Actor",
            title: "Change attribution",
            subtitle: "admin@example.com",
            body: "Role change recorded with an explicit operator reason via the console."
          }

        _ ->
          %{
            meta: "Operator / Timeline",
            title: "Audit timeline",
            subtitle: "Last 30 days",
            body: "View, filter, and export change records for audited tables in this schema."
          }
      end
    end

    # Twin 6: Density (chrome-bloat) graded ladder. Worse rungs pile help-text chrome onto more
    # fields (signal_to_chrome falls) AND flatten the primary "Save changes" button toward the
    # secondary Cancel (task_primary_prominence falls) — both scored dims degrade together (the
    # rhythm lesson: never leave a dimension a noise floor). All sizes/spacing stay on --tl-*
    # tokens so every rung passes MODE A + MODE B (gestalt flaw only). Binary twins map
    # flawed→r2, polished→r4 via rung/1.
    # WIDENED 2026-07-28 (rescue): the first ladder scored ρ0.55 — separable but not enough.
    # Amplify both dims to their extremes so good-vs-bad density is unambiguous. signal_to_chrome:
    # r4 is pure signal (0 help, no intro) while r1/r2 add a verbose intro-chrome paragraph ON TOP
    # of per-field help. task_primary_prominence: the Save CTA collapses from a commanding accent
    # fill (label/700) to a thin ghost peer of Cancel (sm/400). `intro_chrome` gates the extra
    # top-of-form chrome block in the render.
    @density_ladder %{
      r4: %{help_fields: 0, intro_chrome: false, primary_size: "label", primary_weight: 700},
      r3: %{help_fields: 1, intro_chrome: false, primary_size: "label", primary_weight: 600},
      r2: %{help_fields: 2, intro_chrome: true, primary_size: "sm", primary_weight: 500},
      r1: %{help_fields: 3, intro_chrome: true, primary_size: "sm", primary_weight: 400}
    }

    def density_config(story), do: Map.fetch!(@density_ladder, rung(story))

    # r4 is a filled accent primary that clearly outranks Cancel; worse rungs desaturate it
    # toward a plain bordered control until r1 is visually a peer of Cancel (prominence lost).
    # Fills pair accent/surface backgrounds with bg-/text-color foregrounds (documented safe
    # pairings) so contrast holds at every rung.
    def density_primary_style(story) do
      cfg = density_config(story)

      {bg, color, border} =
        case rung(story) do
          r when r in [:r4, :r3] ->
            {"var(--tl-color-accent)", "var(--tl-color-bg)", "none"}

          :r2 ->
            {"var(--tl-color-surface-raised)", "var(--tl-color-text)",
             "1px solid var(--tl-color-border)"}

          :r1 ->
            {"transparent", "var(--tl-color-muted)", "1px solid var(--tl-color-border)"}
        end

      "background: #{bg}; color: #{color}; border: #{border}; padding: var(--tl-space-2) var(--tl-space-4); " <>
        "border-radius: var(--tl-radius-sm); font-size: var(--tl-font-size-#{cfg.primary_size}); font-weight: #{cfg.primary_weight}; cursor: pointer;"
    end

    # Distinct per-scenario form content (pseudo-replication honesty). Each row is
    # {label, value, help}; help renders only on the first `help_fields` rows per rung.
    def density_fields(story) do
      case Map.get(story.data, :scenario) do
        "coverage" ->
          %{
            title: "Coverage settings",
            rows: [
              {"Watched schema", "public",
               "Choose which database schema Threadline monitors for trigger coverage across every audited table."},
              {"Uncovered alert", "on",
               "Alert operator-role users whenever an audited table is found without live trigger coverage during the nightly sweep."},
              {"Recheck cadence", "nightly",
               "How often coverage is recomputed. Nightly recomputes every table at 02:00 UTC; hourly suits high-churn schemas."}
            ]
          }

        "exports" ->
          %{
            title: "Export settings",
            rows: [
              {"Default format", "CSV",
               "The format new exports use. CSV is portable to spreadsheets; JSON preserves nested change payloads verbatim."},
              {"Delivery target", "operator inbox",
               "Where finished exports are delivered. Exports stay inside Threadline and are never emailed to external addresses."},
              {"Row cap", "50000",
               "The maximum rows a single export may contain. Larger result sets are split across sequential export jobs."}
            ]
          }

        "evidence" ->
          %{
            title: "Evidence settings",
            rows: [
              {"Hash algorithm", "SHA-256",
               "The digest used to seal each captured change into its evidence chain. SHA-256 is the audited default."},
              {"Countersign", "required",
               "Whether an evidence chain must be countersigned by a second operator before it is treated as closed."},
              {"Integrity sweep", "daily",
               "How often stored hashes are re-verified against the change records to detect tampering at rest."}
            ]
          }

        "actor" ->
          %{
            title: "Actor settings",
            rows: [
              {"Attribution source", "console",
               "Where actor identity is read from for console-initiated changes: the authenticated session user."},
              {"Require reason", "on",
               "Whether an explicit operator reason must accompany privileged actions such as role changes."},
              {"Correlation window", "15m",
               "How long related requests and jobs are tied to one actor across the job boundary before a new correlation begins."}
            ]
          }

        "activity" ->
          %{
            title: "Activity settings",
            rows: [
              {"Window", "30 days",
               "The span of change activity summarized on the operator home surface for this schema."},
              {"Group by", "table",
               "How captured changes are grouped in the activity roll-up: by audited table, by actor, or by day."},
              {"Idle notice", "off",
               "Whether to surface a notice when an audited table records no changes across the full activity window."}
            ]
          }

        _ ->
          %{
            title: "Retention settings",
            rows: [
              {"Retention window", "90",
               "The number of days audit records are retained. Records older than this are permanently deleted on the next prune (min 7, max 3650)."},
              {"Prune schedule", "weekly",
               "How often automatic pruning runs. Daily runs nightly at 02:00 UTC; weekly runs Sundays; monthly runs on the first."},
              {"Notify on prune", "on",
               "When enabled, operator-role users receive an email after each prune listing the records deleted and tables affected."}
            ]
          }
      end
    end

    # Twin 4: Typography — graded type-scale collapse. r4 renders a full 6-step scale
    # (distinct roles, size tracks importance); worse rungs progressively collapse the
    # scale so BOTH scored dimensions degrade together — role_differentiation AND
    # scale_expresses_hierarchy — keeping min()-rollup signal on both dims (the rhythm
    # lesson: never leave a dimension as a noise floor). r1 is near-flat (no hierarchy).
    # Every size is a --tl-font-size-* token (type-size count stays above the MODE-B floor).
    @typo_scale %{
      r4: %{
        display: {"display", 700},
        title: {"title", 600},
        heading: {"heading", 600},
        body: {"body", 400},
        label: {"label", 500},
        meta: {"xs", 400}
      },
      r3: %{
        display: {"title", 700},
        title: {"title", 600},
        heading: {"heading", 500},
        body: {"body", 400},
        label: {"label", 500},
        meta: {"sm", 400}
      },
      r2: %{
        display: {"heading", 600},
        title: {"heading", 500},
        heading: {"body", 500},
        body: {"body", 400},
        label: {"sm", 500},
        meta: {"sm", 400}
      },
      r1: %{
        display: {"body", 500},
        title: {"body", 500},
        heading: {"body", 500},
        body: {"body", 400},
        label: {"sm", 400},
        meta: {"sm", 400}
      }
    }

    def typography_role_style(story, role) do
      {size, weight} = @typo_scale |> Map.fetch!(rung(story)) |> Map.fetch!(role)

      "font-size: var(--tl-font-size-#{size}); font-weight: #{weight}; color: var(--tl-color-text); margin: 0 0 var(--tl-space-2) 0;"
    end

    # Distinct per-scenario copy across the six type roles (pseudo-replication honesty).
    def typography_lines(story) do
      {display, body, meta} =
        case Map.get(story.data, :scenario) do
          "coverage" ->
            {"Coverage", "3 of 12 audited tables have live trigger coverage.",
             "Recomputed 2026-07-01"}

          "retention" ->
            {"Retention", "Records are retained for 90 days; next prune 2026-09-30.", "Policy v4"}

          "exports" ->
            {"Exports", "4 CSV exports generated in the last 30 days.", "Largest 18,204 rows"}

          "evidence" ->
            {"Evidence", "Proof records current; 1 chain awaits countersignature.",
             "Integrity OK"}

          "actor" ->
            {"Actor", "Change attributed to admin@example.com via console.", "req_9f2"}

          _ ->
            {"Audit activity", "24 changes captured in the last 30 days for this schema.",
             "Updated 2026-07-01"}
        end

      [
        {:display, display},
        {:title, "Operator surface"},
        {:heading, "Last 30 days"},
        {:body, body},
        {:label, "STATUS"},
        {:meta, meta}
      ]
    end

    # Twin 5: Brand fidelity — accent job discipline.
    # Polished: standard action card (no structural accent stripe). Thread-blue is the
    # default action color and needs no additional accent signaling.
    # Flawed: ember left-border stripe on the action card. Ember (--tl-color-ember) belongs
    # to diff-emphasis / change-signal jobs, not primary-action structure. Wrong semantic job.
    # Border-left color is not captured in color_pairs, so no MODE-A WCAG violation fires.
    # The semantic-role flaw is visible to the gestalt lens but passes all mechanical gates.
    # Graded card frame: worse rungs pile brand accent tokens onto jobs they don't own
    # (ember = diff-emphasis, iris = secondary highlight — neither is action-card chrome).
    def action_card_style(story) do
      base =
        "padding: var(--tl-space-4); background: var(--tl-color-bg); border: 1px solid var(--tl-color-border); border-radius: var(--tl-radius-md);"

      case rung(story) do
        :r4 ->
          base

        :r3 ->
          base <> " border-left: 3px solid var(--tl-color-ember);"

        :r2 ->
          base <> " border-left: 3px solid var(--tl-color-ember);"

        :r1 ->
          base <>
            " border-left: 5px solid var(--tl-color-ember); border-top: 3px solid var(--tl-color-iris);"
      end
    end

    # Primary action button: thread-blue owns the action job; worse rungs mis-job ember onto it.
    #
    # The foreground is paired with the CHOSEN background rather than with the theme.
    # `var(--tl-color-bg)` (the previous value) and `var(--tl-color-on-accent)` both flip
    # with the theme while these accent backgrounds do not, so in light mode either one
    # puts near-white text on Ember (#FF8A5B) — 2.2:1, a MODE-A WCAG failure the checker
    # reports against the `button` selector on the three
    # `refute.brand-fidelity.mis-jobbed-accent.flawed__light-*` cells.
    #
    # That violation is not this twin's intended flaw. A flawed pole must stay
    # mechanically clean so its flaw is isolated to perception (mis-jobbing Ember onto the
    # action job) rather than leaking into the mechanical gate. Ember is a light mid-tone
    # in both themes, so it always needs dark ink; thread-blue keeps the semantic
    # on-accent token, which is what that token is calibrated for.
    def brand_button_style(story) do
      {bg, fg} =
        case rung(story) do
          :r4 -> {"var(--tl-color-thread-blue)", "var(--tl-color-on-accent)"}
          :r3 -> {"var(--tl-color-thread-blue)", "var(--tl-color-on-accent)"}
          _ -> {"var(--tl-color-ember)", "var(--tl-color-threadline-black)"}
        end

      "background: #{bg}; color: #{fg}; border: none; padding: var(--tl-space-2) var(--tl-space-4); border-radius: var(--tl-radius-sm); font-size: var(--tl-font-size-label); font-weight: 600; cursor: pointer;"
    end

    # Copy voice by (rung, scenario): r4/r3 operational; r2 adds a chatty line; r1 is
    # marketing/apologetic + emoji (off the Threadline register). Drives register_voice_fit.
    # Structural debt: complexity 10 — split brand_lines/1 into a copy table
    # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
    def brand_lines(story) do
      {heading, body} =
        case Map.get(story.data, :scenario) do
          "coverage" ->
            {"Coverage summary", "3 of 12 audited tables have trigger coverage."}

          "retention" ->
            {"Retention settings", "Records retained 90 days; next prune 2026-09-30."}

          "evidence" ->
            {"Evidence chain", "Proof records current as of 2026-07-01."}

          "actor" ->
            {"Actor detail", "Change attributed to admin@example.com via console."}

          "timeline" ->
            {"Audit timeline", "24 changes captured in the last 30 days."}

          _ ->
            {"Export audit records", "Download a CSV of audit changes for the last 90 days."}
        end

      note =
        case rung(story) do
          :r2 ->
            "This should only take a moment — thanks for your patience!"

          :r1 ->
            "You're all set! Everything looks great. 🎉 Powerful, seamless audit exports await."

          _ ->
            nil
        end

      {heading, body, note}
    end

    # Twin (new): Color contrast — one-hue-one-job discipline (graded). Degrades BOTH scored
    # dims together: color_as_signal (does colour map to meaning?) AND accent_job_discipline
    # (is each hue reserved for its documented job?). r4 = one hue per job (blue=action,
    # ember=change, cyan=info); r3 mild creep; r2 reuses one hue across two jobs; r1 scrambles
    # every hue so colour stops meaning anything. Accents are border-left + a plain <div>
    # swatch (neither is in the color_pairs text selector) so every rung passes WCAG MODE-A —
    # this is a gestalt colour-semantics flaw, not a contrast violation.
    # Structural debt: complexity 13 — split color_accent/2 into a rung table
    # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
    def color_accent(story, role) do
      case {rung(story), role} do
        {:r4, :action} -> "var(--tl-color-thread-blue)"
        {:r4, :change} -> "var(--tl-color-ember)"
        {:r4, :info} -> "var(--tl-color-signal-cyan)"
        {:r3, :action} -> "var(--tl-color-thread-blue)"
        {:r3, :change} -> "var(--tl-color-ember)"
        {:r3, :info} -> "var(--tl-color-iris)"
        # WIDENED 2026-07-28: r2 was only ~1-wrong (info collided with action), too close to r3.
        # Now r2 is a clean 2-wrong — change AND info both mis-jobbed to iris (a hue collision that
        # also breaks color_as_signal), giving a monotonic mis-job gradient r4=0 < r3=1 < r2=2 < r1=3.
        {:r2, :action} -> "var(--tl-color-thread-blue)"
        {:r2, :change} -> "var(--tl-color-iris)"
        {:r2, :info} -> "var(--tl-color-iris)"
        {:r1, :action} -> "var(--tl-color-signal-cyan)"
        {:r1, :change} -> "var(--tl-color-iris)"
        {:r1, :info} -> "var(--tl-color-ember)"
      end
    end

    # Distinct per-scenario rows for the colour-signal twin (pseudo-replication honesty).
    def color_rows(story) do
      case Map.get(story.data, :scenario) do
        "coverage" ->
          [
            {"Action", "Enable trigger coverage", :action},
            {"Change", "3 tables newly covered", :change},
            {"Info", "9 tables remain uncovered", :info}
          ]

        "retention" ->
          [
            {"Action", "Run prune now", :action},
            {"Change", "Window 120 → 90 days", :change},
            {"Info", "Next prune 2026-09-30", :info}
          ]

        "diff" ->
          [
            {"Action", "Approve change", :action},
            {"Change", "role: member → admin", :change},
            {"Info", "Actor admin@example.com", :info}
          ]

        "evidence" ->
          [
            {"Action", "Countersign chain", :action},
            {"Change", "Hash re-verified", :change},
            {"Info", "1 chain pending", :info}
          ]

        "actor" ->
          [
            {"Action", "Attribute change", :action},
            {"Change", "Intent recorded", :change},
            {"Info", "Correlation req_9f2", :info}
          ]

        _ ->
          [
            {"Action", "Export audit records", :action},
            {"Change", "24 changes captured", :change},
            {"Info", "Retention window 90 days", :info}
          ]
      end
    end

    # Twin 7: Veto-ordering — off-token raw-hex accent.
    # Each diff row is wrapped in a div with a left-border accent: ember token (polished) vs
    # raw hex #e8a246 (flawed). Border-left is not in the color_pairs selector so no WCAG
    # contrast MODE-A violation fires here. The raw hex trips the token-parity veto at the
    # panel layer, which fires after mechanical gates pass (correct veto ordering).
    def veto_accent_style(story) do
      case pole(story) do
        :flawed ->
          # Off-token raw hex (Ember-alike; not a CSS variable reference) triggers the panel veto.
          "display: flex; gap: var(--tl-space-3); align-items: center; padding-left: var(--tl-space-2); border-left: 3px solid #e8a246; margin-bottom: var(--tl-space-2);"

        _ ->
          "display: flex; gap: var(--tl-space-3); align-items: center; padding-left: var(--tl-space-2); border-left: 3px solid var(--tl-color-ember); margin-bottom: var(--tl-space-2);"
      end
    end
  end
end
