defmodule ThreadlinePhoenix.Demo.Seed.RetentionTail do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Evidence
  alias Threadline.Health
  alias Threadline.Retention
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Repo

  @org_y_backdate_days 90

  # Derived by grepping every `Manifest.epoch()` call site under
  # `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/` and taking the
  # most-negative (furthest-in-the-past) day offset applied to `audit_transactions` /
  # `audit_changes` timestamps for an organization OTHER than org Y
  # (`offboarded-co`). The two seeders that establish this bound:
  #
  #   - `personas.ex:99`  — `setup_ts = DateTime.add(Manifest.epoch(), -21, :day)`
  #   - `temporal.ex:37`  — the same `-21` day offset, used as the fallback
  #     backdate for any untracked null-actor transaction
  #
  # `filler.ex`'s `Support.random_days_ago_timestamp/0` only ever produces `0..13`
  # days back (`:rand.uniform(14) - 1`), so it never reaches this bound. No other
  # seeder writes an audit-table timestamp further back than `-21` days for a
  # non-org-Y organization. (A prior version of this comment cited a "-14 day"
  # filler bound — that number was never the true minimum; the guard below is the
  # source of truth going forward, not this prose.)
  @earliest_other_org_epoch_offset_days 21

  # `Threadline.Retention.purge/1` is a library-level GLOBAL age-based delete
  # (no per-organization scoping — see `lib/threadline/retention.ex`). Its
  # default cutoff is derived from the REAL wall clock at call time (`now -
  # keep_days`), never from this demo's frozen `Manifest.epoch()`. Left to that
  # default, every org's epoch-anchored fiction (hero close/delete, the
  # leaving-agent window, the globex sample) gets swept up as collateral
  # damage once real time drifts more than `keep_days` past the epoch — which
  # it now has (198-round4-demo-seed.md root-cause confirmation). Passing an
  # explicit `:cutoff` anchored to the demo's own epoch (a stricter-than-policy
  # override the library documents and supports) keeps the purge scoped to
  # what the demo narrative actually intends to remove: `offboarded-co`'s
  # `-90 day` backdated footprint. The chosen offset (`-60 days` from epoch)
  # sits strictly between org Y's `-90 day` backdate (still purged) and the
  # true earliest other-org epoch-anchored offset of `-21 days` (see
  # `@earliest_other_org_epoch_offset_days` above — `personas.ex:99` and
  # `temporal.ex:37` — comfortably preserved with a 39-day margin).
  @retention_purge_cutoff_days_before_epoch 60

  # Compile-time invariant guard (WR-03). The correctness of this module rests
  # entirely on `@retention_purge_cutoff_days_before_epoch` sitting STRICTLY
  # between `@earliest_other_org_epoch_offset_days` and `@org_y_backdate_days`.
  # Equality on either side gives zero margin and must fail the build, not pass
  # it — a cutoff exactly at the earliest other-org offset would purge that
  # org's rows too; a cutoff exactly at org Y's backdate would leave org Y's
  # footprint un-purged (surfacing later as a confusing "org Y not empty"
  # assertion instead of naming the real cause here). This is a build-time
  # `raise`, not a comment, so the invariant cannot silently drift from the
  # numbers it is meant to protect.
  unless @earliest_other_org_epoch_offset_days < @retention_purge_cutoff_days_before_epoch and
           @retention_purge_cutoff_days_before_epoch < @org_y_backdate_days do
    raise CompileError,
      description: """
      RetentionTail cutoff invariant violated (WR-03): \
      @retention_purge_cutoff_days_before_epoch must sit STRICTLY between \
      @earliest_other_org_epoch_offset_days and @org_y_backdate_days (equal is a \
      violation, not a pass). Got \
      earliest_other_org_epoch_offset_days=#{@earliest_other_org_epoch_offset_days}, \
      retention_purge_cutoff_days_before_epoch=#{@retention_purge_cutoff_days_before_epoch}, \
      org_y_backdate_days=#{@org_y_backdate_days}. Fix the offending module attribute in \
      #{__ENV__.file} before recompiling.
      """
  end

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    org_y_id = Manifest.org_id(:offboarded_co)
    backdate_org_y_audit!(org_y_id)

    prior_retention_env = Application.get_env(:threadline, :retention)
    enable_retention!()

    purge_result =
      try do
        case Retention.purge(repo: Repo, cutoff: retention_purge_cutoff()) do
          {:error, :disabled} ->
            raise "demo retention purge requires :threadline retention enabled"

          result when is_map(result) ->
            result
        end
      rescue
        e in ArgumentError ->
          reraise_clock_skew_error(e, __STACKTRACE__)
      after
        # Disarm the env landmine (WR-05). `enable_retention!/0` writes a global
        # `keep_days` policy that any LATER `Retention.purge/1` call (an Oban job,
        # a mix task, a follow-on seed step, a host application in the same VM)
        # would otherwise inherit with no explicit `:cutoff` — reproducing the
        # exact collateral-deletion bug this module exists to fix, anchored to
        # this demo's ~90-day-stale epoch fiction instead of real data. Restored
        # on both the success and failure paths via `after`.
        Application.put_env(:threadline, :retention, prior_retention_env || [])
      end

    assert_other_orgs_survived!(org_y_id)
    record_evidence!(org_y_id, purge_result)
    assert_org_y_audit_empty!(org_y_id)

    ctx
  end

  # See the module-attribute comment above `@retention_purge_cutoff_days_before_epoch`.
  defp retention_purge_cutoff do
    DateTime.add(Manifest.epoch(), -@retention_purge_cutoff_days_before_epoch, :day)
  end

  # Makes `Threadline.Retention.Policy`'s latent `resolve_cutoff/2` raise legible
  # (WR-03). That raise fires when the frozen, epoch-anchored requested cutoff is
  # newer than the wall-clock-derived policy cutoff — which only happens when the
  # machine's real clock reads earlier than `Manifest.epoch()` minus roughly
  # `@org_y_backdate_days - @retention_purge_cutoff_days_before_epoch` days
  # (clock skew), not from any error in this module's own arithmetic. We do NOT
  # widen `keep_days` to dodge this — that would re-arm the WR-05 hazard the
  # `after` block in `run/1` exists to prevent.
  defp reraise_clock_skew_error(%ArgumentError{} = e, stacktrace) do
    requested_cutoff = retention_purge_cutoff()
    policy_cutoff = Threadline.Retention.Policy.cutoff_utc_datetime_usec!()

    reraise %ArgumentError{
              message: """
              RetentionTail purge cutoff rejected by Threadline.Retention — likely clock \
              skew, not a bug in this seeder (#{Exception.message(e)}).

              requested (epoch-anchored) cutoff: #{inspect(requested_cutoff)}
              policy (wall-clock-derived) cutoff: #{inspect(policy_cutoff)}

              The requested cutoff is only newer than the policy cutoff when this \
              machine's system clock reads earlier than roughly \
              #{Manifest.epoch() |> DateTime.add(-(@org_y_backdate_days - @retention_purge_cutoff_days_before_epoch), :day) |> inspect()}. \
              Check the system clock.
              """
            },
            stacktrace
  end

  @doc false
  @spec org_y_audit_change_count(binary()) :: non_neg_integer()
  def org_y_audit_change_count(org_id) when is_binary(org_id) do
    Repo.aggregate(org_y_audit_changes_query(org_id), :count)
  end

  defp backdate_org_y_audit!(org_id) do
    backdated_at = DateTime.add(Manifest.epoch(), -@org_y_backdate_days, :day)

    Repo.query!(
      """
      UPDATE threadline.audit_transactions at
      SET occurred_at = $1
      WHERE at.meta->>'organization_id' = $2
      """,
      [backdated_at, org_id]
    )

    Repo.query!(
      """
      UPDATE threadline.audit_changes ac
      SET captured_at = $1
      FROM threadline.audit_transactions at
      WHERE ac.transaction_id = at.id
        AND at.meta->>'organization_id' = $2
      """,
      [backdated_at, org_id]
    )
  end

  defp enable_retention! do
    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 30,
      delete_empty_transactions: true
    )
  end

  defp record_evidence!(org_y_id, %{deleted_changes: deleted_changes} = purge_result) do
    run_id = Manifest.evidence_run_id(:offboarded_retention)

    retention_run_ref = %{
      "run_id" => run_id,
      "org_slug" => Manifest.org_slug(:offboarded_co),
      "organization_id" => org_y_id
    }

    {:ok, _} =
      Evidence.record_retention_run(
        retention_run_ref,
        %{
          summary_status: "completed",
          detail: %{
            "deleted_changes" => deleted_changes,
            "deleted_transactions" => purge_result.deleted_transactions,
            "narrative" => "org Y offboard"
          }
        },
        repo: Repo
      )

    {:ok, _} =
      Evidence.record_retention_policy(
        Manifest.evidence_subject_ref(:retention_policy),
        %{
          summary_status: "active",
          detail: %{
            "enabled" => true,
            "keep_days" => 30,
            "scope" => "global_age"
          }
        },
        repo: Repo
      )

    {:ok, _} =
      Evidence.record_redaction_policy(
        Manifest.evidence_subject_ref(:redaction_policy),
        %{
          summary_status: "active",
          detail: %{
            "masked_fields" => ["ticket_replies.internal_note_body"],
            "source" => "trigger_capture"
          }
        },
        repo: Repo
      )

    coverage = Health.trigger_coverage(repo: Repo)

    {:ok, _} =
      Evidence.record_trigger_coverage(
        Manifest.evidence_subject_ref(:trigger_coverage),
        %{
          summary_status: "snapshot",
          detail: trigger_coverage_detail(coverage)
        },
        repo: Repo
      )

    record_verdict_spread!(retention_run_ref)

    :ok
  end

  # D1 — make the evidence overview show all three verdicts and a real
  # drill-down history. Inferred already comes from the posture subjects above
  # (retention_policy / redaction_policy); here we add an explicit Proven and
  # Unsupported (via detail.claim_assessment.status), plus two earlier states
  # for the offboard run so its subject_ref history renders pending -> running
  # -> completed. All recorded_at are epoch-relative for determinism.
  defp record_verdict_spread!(retention_run_ref) do
    now = Manifest.epoch()

    {:ok, _} =
      Evidence.record_export_delivery(
        %{"export_id" => "acme-4521-close", "format" => "csv"},
        %{
          summary_status: "completed",
          recorded_at: usec(DateTime.add(now, -18, :minute)),
          detail: %{
            "claim_assessment" => %{
              "status" => "proven",
              "reason" => "Export artifact written and checksum verified."
            }
          }
        },
        repo: Repo
      )

    {:ok, _} =
      Evidence.record_export_delivery(
        %{"export_id" => "expired-demo-export", "format" => "ndjson"},
        %{
          summary_status: "failed",
          recorded_at: usec(DateTime.add(now, -10, :day)),
          detail: %{
            "claim_assessment" => %{
              "status" => "unsupported",
              "reason" => "Destination unreachable during the demo window; delivery unverifiable."
            }
          }
        },
        repo: Repo
      )

    for {status, days} <- [{"pending", -90}, {"running", -2}] do
      {:ok, _} =
        Evidence.record_retention_run(
          retention_run_ref,
          %{
            summary_status: status,
            recorded_at: usec(DateTime.add(now, days, :day)),
            detail: %{"narrative" => "org Y offboard", "phase" => status}
          },
          repo: Repo
        )
    end

    :ok
  end

  defp usec(%DateTime{} = dt), do: %{dt | microsecond: {0, 6}}

  defp trigger_coverage_detail(coverage) when is_list(coverage) do
    covered = Enum.count(coverage, &match?({:covered, _}, &1))
    uncovered = Enum.count(coverage, &match?({:uncovered, _}, &1))
    expected = Enum.count(coverage, &match?({:expected_uncovered, _}, &1))

    %{
      "covered_count" => covered,
      "uncovered_count" => uncovered,
      "expected_uncovered_count" => expected
    }
  end

  defp assert_org_y_audit_empty!(org_id) do
    count = org_y_audit_change_count(org_id)

    if count != 0 do
      raise "expected org Y audit footprint to be purged, found #{count} audit_changes"
    end
  end

  # Direct cross-org survival assertion (WR-05). `assert_org_y_audit_empty!/1`
  # only proves the purge bit org Y; nothing previously proved it did NOT also
  # bite every other organization — `Retention.purge/1` is a globally
  # time-scoped `DELETE`, not org-scoped (see `lib/threadline/retention.ex`
  # lines ~131-164), so cross-org preservation is a coincidence of epoch
  # offsets, not a constraint the library enforces. The org-scoping predicate
  # mirrors `org_y_audit_changes_query/1` below: `audit_transactions.meta` is
  # stamped with `"organization_id" => to_string(org.id)` by
  # `Support.stamp_org_meta!/1` (see `seed/support.ex`), so we filter on the
  # same JSON key here rather than inventing a new shape.
  defp assert_other_orgs_survived!(org_y_id) do
    count = other_org_audit_change_count(org_y_id)

    if count == 0 do
      raise """
      retention purge (cutoff=#{inspect(retention_purge_cutoff())}) deleted every \
      non-org-Y audit change — expected other organizations' epoch-anchored audit \
      history to survive the purge, found zero. This is the round-4 \
      collateral-deletion regression's exact signature: the cutoff swept every \
      organization instead of only offboarded-co.
      """
    end
  end

  defp other_org_audit_change_count(org_y_id) when is_binary(org_y_id) do
    Repo.aggregate(other_org_audit_changes_query(org_y_id), :count)
  end

  defp other_org_audit_changes_query(org_y_id) do
    from(ac in AuditChange,
      join: at in AuditTransaction,
      on: ac.transaction_id == at.id,
      where: fragment("?->>'organization_id' is not null", at.meta),
      where: fragment("?->>'organization_id' != ?", at.meta, ^org_y_id)
    )
  end

  defp org_y_audit_changes_query(org_id) do
    from(ac in AuditChange,
      join: at in AuditTransaction,
      on: ac.transaction_id == at.id,
      where: fragment("?->>'organization_id' = ?", at.meta, ^org_id)
    )
  end
end
