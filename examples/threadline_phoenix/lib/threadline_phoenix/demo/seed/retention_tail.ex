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

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    org_y_id = Manifest.org_id(:offboarded_co)
    backdate_org_y_audit!(org_y_id)
    enable_retention!()

    purge_result =
      case Retention.purge(repo: Repo) do
        {:error, :disabled} ->
          raise "demo retention purge requires :threadline retention enabled"

        result when is_map(result) ->
          result
      end

    record_evidence!(org_y_id, purge_result)
    assert_org_y_audit_empty!(org_y_id)

    ctx
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

  defp org_y_audit_changes_query(org_id) do
    from(ac in AuditChange,
      join: at in AuditTransaction,
      on: ac.transaction_id == at.id,
      where: fragment("?->>'organization_id' = ?", at.meta, ^org_id)
    )
  end
end
